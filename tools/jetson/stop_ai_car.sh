#!/usr/bin/env bash
set +e

CONTAINER=agitated_panini
ROS_ENV='source /opt/ros/foxy/setup.bash; export ROS_DOMAIN_ID=32;'

timeout 3 docker exec "$CONTAINER" bash -lc "$ROS_ENV ros2 topic pub -r 5 /app_manual_cmd std_msgs/msg/String \"{data: 'wheels:0,0,0,0'}\"" >/dev/null 2>&1
timeout 3 docker exec "$CONTAINER" bash -lc "$ROS_ENV ros2 topic pub -r 5 /app_cmd_receive std_msgs/msg/String \"{data: 'stop_auto'}\"" >/dev/null 2>&1
docker exec "$CONTAINER" bash -lc 'pkill -INT -f "rosbridge_websocket_launch.xml" || true' || true
docker exec "$CONTAINER" bash -lc 'pkill -f "python3 /tmp/laser_Avoidance_app.py" || true' || true
docker exec "$CONTAINER" bash -lc 'pkill -INT -f "yahboomcar_nav laser_bringup_launch.py" || true' || true
