#!/bin/bash
# Wait for VNC display, then launch TurtleBot3 Gazebo sim.
# Publishes /tf, /odom, /scan; subscribes to /cmd_vel.
set -e
export DISPLAY=:1
export TURTLEBOT3_MODEL=burger
source /opt/ros/humble/setup.bash
# Give VNC and noVNC time to start so DISPLAY=:1 is available
sleep 20
exec ros2 launch turtlebot3_gazebo turtlebot3_world.launch.py
