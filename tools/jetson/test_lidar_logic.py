import importlib.util
from pathlib import Path
import sys
import types


class FakeTwist:
    def __init__(self):
        self.linear = types.SimpleNamespace(x=0.0, y=0.0, z=0.0)
        self.angular = types.SimpleNamespace(x=0.0, y=0.0, z=0.0)


class FakePublisher:
    def __init__(self):
        self.messages = []

    def publish(self, message):
        self.messages.append(message)


def install_ros_stubs():
    rclpy = types.ModuleType('rclpy')
    rclpy_node = types.ModuleType('rclpy.node')
    rclpy_node.Node = object
    geometry_msgs = types.ModuleType('geometry_msgs')
    geometry_msgs_msg = types.ModuleType('geometry_msgs.msg')
    geometry_msgs_msg.Twist = FakeTwist
    sensor_msgs = types.ModuleType('sensor_msgs')
    sensor_msgs_msg = types.ModuleType('sensor_msgs.msg')
    sensor_msgs_msg.LaserScan = object
    std_msgs = types.ModuleType('std_msgs')
    std_msgs_msg = types.ModuleType('std_msgs.msg')
    std_msgs_msg.Bool = object
    std_msgs_msg.String = object
    sys.modules.update({
        'rclpy': rclpy,
        'rclpy.node': rclpy_node,
        'geometry_msgs': geometry_msgs,
        'geometry_msgs.msg': geometry_msgs_msg,
        'sensor_msgs': sensor_msgs,
        'sensor_msgs.msg': sensor_msgs_msg,
        'std_msgs': std_msgs,
        'std_msgs.msg': std_msgs_msg,
    })


def load_controller_class():
    install_ros_stubs()
    path = Path(__file__).with_name('laser_Avoidance_a1_X3.py')
    spec = importlib.util.spec_from_file_location('lidar_controller', path)
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module.LaserAvoid


def create_controller(controller_class):
    controller = object.__new__(controller_class)
    controller.velocity_pub = FakePublisher()
    controller.follow_distance = 0.90
    controller.follow_deadband = 0.12
    controller.follow_max_distance = 2.50
    controller.rear_stop_distance = 0.35
    controller.avoid_phase = 'cruise'
    controller.last_speed = 0.0
    return controller


def assert_case(controller, front, rear, expected_phase, direction):
    controller.calculate_tracking_velocity(front, rear, front, front)
    message = controller.velocity_pub.messages[-1]
    assert controller.avoid_phase == expected_phase, (
        controller.avoid_phase, expected_phase)
    if direction == 'forward':
        assert message.linear.x > 0.0
    elif direction == 'backward':
        assert message.linear.x < 0.0
    else:
        assert message.linear.x == 0.0


def main():
    controller_class = load_controller_class()
    controller = create_controller(controller_class)
    assert_case(controller, 1.40, 1.00, 'tracking_forward', 'forward')
    assert_case(controller, 0.90, 1.00, 'tracking_hold', 'stop')
    assert_case(controller, 0.55, 1.00, 'tracking_back', 'backward')
    assert_case(controller, 0.55, 0.20, 'tracking_rear_blocked', 'stop')
    assert_case(controller, 3.00, 1.00, 'target_lost', 'stop')
    print('TRACKING_LOGIC_OK')


if __name__ == '__main__':
    main()
