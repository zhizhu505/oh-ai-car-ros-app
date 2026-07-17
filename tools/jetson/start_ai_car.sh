#!/usr/bin/env bash
set -euo pipefail

CONTAINER=agitated_panini
RUNTIME=/home/jetson/ai-car-runtime

chmod 666 /dev/ttyUSB* 2>/dev/null || true
ln -sf /dev/ttyUSB0 /dev/rplidar
ln -sf /dev/ttyUSB1 /dev/myserial

if ! docker inspect -f '{{.State.Running}}' "$CONTAINER" 2>/dev/null | grep -q true; then
  docker start "$CONTAINER" >/dev/null
fi

docker exec "$CONTAINER" bash -lc 'pkill -INT -f "yahboomcar_nav laser_bringup_launch.py" || true' || true
docker exec "$CONTAINER" bash -lc 'pkill -f "python3 /tmp/laser_Avoidance_app.py" || true' || true
docker exec "$CONTAINER" bash -lc 'pkill -INT -f "rosbridge_websocket_launch.xml" || true' || true
sleep 3

docker cp "$RUNTIME/laser_Avoidance_a1_X3.py" "$CONTAINER":/tmp/laser_Avoidance_app.py

HARDWARE_ENV='source /opt/ros/foxy/setup.bash; source /root/yahboomcar_ros2_ws/software/library_ws/install/setup.bash; source /root/yahboomcar_ros2_ws/yahboomcar_ws/install/setup.bash; export ROS_DOMAIN_ID=32; export ROBOT_TYPE=x3; export RPLIDAR_TYPE=a1;'

docker exec -d "$CONTAINER" bash -lc "$HARDWARE_ENV exec ros2 launch yahboomcar_nav laser_bringup_launch.py robot_type:=x3 rplidar_type:=a1 >/tmp/laser_bringup_app.log 2>&1"
sleep 8
docker exec -d "$CONTAINER" bash -lc 'source /opt/ros/foxy/setup.bash; export ROS_DOMAIN_ID=32; exec python3 /tmp/laser_Avoidance_app.py >/tmp/avoidance_app.log 2>&1'
sleep 3
docker exec -d "$CONTAINER" bash -lc 'source /opt/ros/foxy/setup.bash; export ROS_DOMAIN_ID=32; exec ros2 launch rosbridge_server rosbridge_websocket_launch.xml port:=9090 >/tmp/rosbridge_app.log 2>&1'
sleep 5

ss -ltn | grep -q ':9090 '
