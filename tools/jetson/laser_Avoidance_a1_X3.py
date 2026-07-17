import math
import time

import numpy as np
import rclpy
from geometry_msgs.msg import Twist
from rclpy.node import Node
from sensor_msgs.msg import LaserScan
from std_msgs.msg import Bool, String


RAD2DEG = 180.0 / math.pi


class LaserAvoid(Node):
    def __init__(self):
        super().__init__('app_lidar_controller')
        self.scan_sub = self.create_subscription(LaserScan, '/scan', self.on_scan, 10)
        self.joy_sub = self.create_subscription(Bool, '/JoyState', self.on_joy_state, 10)
        self.command_sub = self.create_subscription(
            String, '/app_cmd_receive', self.on_app_command, 10)
        self.manual_sub = self.create_subscription(
            String, '/app_manual_cmd', self.on_manual_command, 10)

        self.velocity_pub = self.create_publisher(Twist, '/cmd_vel', 10)
        self.status_pub = self.create_publisher(String, '/car_real_status', 10)
        self.alarm_pub = self.create_publisher(String, '/channel_alarm', 10)

        self.auto_enabled = False
        self.tracking_enabled = False
        self.joy_active = False
        self.normal_speed = 0.12
        self.slow_speed = 0.08
        self.current_speed_limit = self.normal_speed
        self.slowdown_distance = 0.8
        self.stop_distance = 0.4
        self.blocked_since = 0.0
        self.alarm_sent = False
        self.last_status_time = 0.0
        self.control_mode = 'idle'
        self.last_speed = 0.0
        self.avoid_phase = 'cruise'
        self.avoid_direction = 0.0
        self.phase_started = 0.0
        self.follow_distance = 0.90
        self.follow_deadband = 0.12
        self.follow_max_distance = 2.50
        self.rear_stop_distance = 0.35

        self.get_logger().info(
            'APP radar control ready: /app_cmd_receive, /car_real_status, /channel_alarm')

    def on_joy_state(self, msg):
        self.joy_active = bool(msg.data)
        if self.joy_active:
            self.stop_car()

    def on_app_command(self, msg):
        command = msg.data.strip()
        self.get_logger().info('APP command received: %s' % command)

        if command == 'start_auto':
            self.auto_enabled = True
            self.tracking_enabled = False
            self.control_mode = 'auto'
            self.reset_avoidance_phase()
        elif command == 'stop_auto':
            self.auto_enabled = False
            self.tracking_enabled = False
            self.control_mode = 'idle'
            self.reset_avoidance_phase()
            self.stop_car()
        elif command == 'manual_mode':
            self.auto_enabled = False
            self.tracking_enabled = False
            self.control_mode = 'manual'
            self.reset_avoidance_phase()
            self.stop_car()
        elif command == 'start_tracking':
            self.auto_enabled = False
            self.tracking_enabled = True
            self.control_mode = 'tracking'
            self.reset_avoidance_phase()
        elif command == 'stop_tracking':
            self.tracking_enabled = False
            self.auto_enabled = True
            self.control_mode = 'auto'
            self.reset_avoidance_phase()
            self.stop_car()
        elif command == 'slow':
            self.current_speed_limit = self.slow_speed
        elif command == 'fast':
            self.current_speed_limit = self.normal_speed
        elif command.startswith('set_front:'):
            try:
                value = float(command.split(':', 1)[1])
                if value > self.stop_distance:
                    self.slowdown_distance = value
            except ValueError:
                self.get_logger().warning('Invalid front threshold: %s' % command)

    def on_manual_command(self, msg):
        command = msg.data.strip()
        if not command.startswith('wheels:'):
            return
        try:
            wheels = [float(value) for value in command.split(':', 1)[1].split(',')]
        except ValueError:
            self.get_logger().warning('Invalid manual command: %s' % command)
            return
        if len(wheels) != 4:
            self.get_logger().warning('Invalid wheel count: %s' % command)
            return

        left_front, left_rear, right_front, right_rear = [
            max(-100.0, min(100.0, value)) for value in wheels]
        self.auto_enabled = False
        self.tracking_enabled = False
        self.control_mode = 'manual'
        self.reset_avoidance_phase()

        twist = Twist()
        twist.linear.x = (
            left_front + left_rear + right_front + right_rear) / 400.0 * 0.25
        twist.linear.y = (
            -left_front + left_rear + right_front - right_rear) / 400.0 * 0.22
        twist.angular.z = (
            -left_front - left_rear + right_front + right_rear) / 400.0 * 1.0
        self.velocity_pub.publish(twist)
        self.last_speed = abs(twist.linear.x)

    @staticmethod
    def sector_distance(ranges, angles, start_deg, end_deg):
        mask = (angles >= start_deg) & (angles <= end_deg)
        values = ranges[mask]
        values = values[np.isfinite(values) & (values > 0.05)]
        if values.size == 0:
            return 9.99
        return float(np.min(values))

    def on_scan(self, scan):
        ranges = np.asarray(scan.ranges, dtype=float)
        angles = (scan.angle_min + scan.angle_increment * np.arange(ranges.size)) * RAD2DEG

        # The X3 lidar is mounted with 180 degrees pointing forward.
        front_right = self.sector_distance(ranges, angles, 160.0, 180.0)
        front_left = self.sector_distance(ranges, angles, -180.0, -160.0)
        front = min(front_right, front_left)
        left = self.sector_distance(ranges, angles, -115.0, -65.0)
        right = self.sector_distance(ranges, angles, 65.0, 115.0)
        rear = self.sector_distance(ranges, angles, -20.0, 20.0)

        now = time.monotonic()
        occupied = front < self.slowdown_distance
        if occupied:
            if self.blocked_since == 0.0:
                self.blocked_since = now
            if now - self.blocked_since >= 5.0 and not self.alarm_sent:
                alarm = String()
                alarm.data = 'B区通道前方%.2fm检测到持续障碍，疑似通道占用' % front
                self.alarm_pub.publish(alarm)
                self.alarm_sent = True
        else:
            self.blocked_since = 0.0
            self.alarm_sent = False

        speed = self.calculate_and_publish_velocity(
            front, left, right, rear, front_left, front_right)
        if now - self.last_status_time >= 0.5:
            status = String()
            status.data = (
                'left:%.2f,right:%.2f,front:%.2f,rear:%.2f,speed:%.2f,'
                'obstacle:%s,mode:%s,phase:%s,tracking:%s'
                % (left, right, front, rear, speed,
                   'true' if occupied else 'false', self.control_mode,
                   self.avoid_phase, 'true' if self.tracking_enabled else 'false'))
            self.status_pub.publish(status)
            self.last_status_time = now

    def calculate_and_publish_velocity(
            self, front, left, right, rear, front_left, front_right):
        if self.tracking_enabled and not self.joy_active:
            return self.calculate_tracking_velocity(
                front, rear, front_left, front_right)
        if not self.auto_enabled or self.joy_active:
            return self.last_speed

        now = time.monotonic()
        if self.avoid_phase != 'cruise':
            return self.run_avoidance_phase(now, front, left, right)

        twist = Twist()
        if front <= self.stop_distance:
            open_side = max(left, right)
            if open_side < 0.55:
                self.avoid_phase = 'blocked'
                self.velocity_pub.publish(twist)
                self.last_speed = 0.0
                return self.last_speed
            self.avoid_direction = 1.0 if left > right else -1.0
            self.avoid_phase = 'turn_out'
            self.phase_started = now
            return self.run_avoidance_phase(now, front, left, right)

        speed = self.current_speed_limit
        if front < self.slowdown_distance:
            speed = min(speed, 0.06)

        twist.linear.x = speed
        if left < 2.0 and right < 2.0:
            difference = left - right
            twist.angular.z = max(-0.35, min(0.35, difference * 0.55))
        self.velocity_pub.publish(twist)
        self.last_speed = speed
        return self.last_speed

    def calculate_tracking_velocity(self, front, rear, front_left, front_right):
        twist = Twist()
        if front >= self.follow_max_distance:
            self.avoid_phase = 'target_lost'
        elif front < self.follow_distance - self.follow_deadband:
            if rear <= self.rear_stop_distance:
                self.avoid_phase = 'tracking_rear_blocked'
            else:
                error = self.follow_distance - front
                twist.linear.x = -min(0.08, max(0.035, error * 0.12))
                self.avoid_phase = 'tracking_back'
        elif front > self.follow_distance + self.follow_deadband:
            error = front - self.follow_distance
            twist.linear.x = min(0.09, max(0.035, error * 0.10))
            direction_error = front_right - front_left
            twist.angular.z = max(-0.30, min(0.30, direction_error * 0.45))
            self.avoid_phase = 'tracking_forward'
        else:
            self.avoid_phase = 'tracking_hold'

        self.velocity_pub.publish(twist)
        self.last_speed = abs(twist.linear.x)
        return self.last_speed

    def run_avoidance_phase(self, now, front, left, right):
        twist = Twist()
        elapsed = now - self.phase_started

        if self.avoid_phase == 'blocked':
            if front > self.slowdown_distance and max(left, right) > 0.55:
                self.reset_avoidance_phase()
            else:
                self.velocity_pub.publish(twist)
                self.last_speed = 0.0
                return self.last_speed

        if self.avoid_phase == 'turn_out':
            twist.linear.x = 0.02 if front > 0.25 else 0.0
            twist.angular.z = self.avoid_direction * 0.55
            if elapsed >= 0.9 or front > self.slowdown_distance + 0.2:
                self.avoid_phase = 'pass_obstacle'
                self.phase_started = now
        elif self.avoid_phase == 'pass_obstacle':
            if front <= 0.25:
                twist.angular.z = self.avoid_direction * 0.55
            else:
                twist.linear.x = min(self.current_speed_limit, 0.06)
                twist.angular.z = self.avoid_direction * 0.10
            if elapsed >= 1.4 and front > self.stop_distance:
                self.avoid_phase = 'turn_back'
                self.phase_started = now
            elif elapsed >= 4.0:
                self.avoid_phase = 'blocked'
        elif self.avoid_phase == 'turn_back':
            twist.linear.x = 0.04
            twist.angular.z = -self.avoid_direction * 0.50
            if elapsed >= 0.9:
                self.reset_avoidance_phase()

        self.velocity_pub.publish(twist)
        self.last_speed = abs(twist.linear.x)
        return self.last_speed

    def reset_avoidance_phase(self):
        self.avoid_phase = 'cruise'
        self.avoid_direction = 0.0
        self.phase_started = 0.0

    def stop_car(self):
        self.velocity_pub.publish(Twist())
        self.last_speed = 0.0


def main(args=None):
    rclpy.init(args=args)
    node = LaserAvoid()
    try:
        rclpy.spin(node)
    except KeyboardInterrupt:
        pass
    finally:
        node.stop_car()
        node.destroy_node()
        rclpy.shutdown()


if __name__ == '__main__':
    main()
