# Extends Tiryoh's ROS 2 Desktop VNC (Humble) with rosbridge, teleop, and TurtleBot3 Gazebo sim.
# See https://github.com/Tiryoh/docker-ros2-desktop-vnc
FROM ghcr.io/tiryoh/ros2-desktop-vnc:humble

SHELL ["/bin/bash", "-c"]

RUN apt-get update -q && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y \
    ros-humble-rosbridge-suite \
    ros-humble-teleop-twist-keyboard \
    ros-humble-turtlebot3-simulations \
    ros-humble-turtlebot3 && \
    apt-get autoclean && \
    rm -rf /var/lib/apt/lists/*

# Rosbridge runs as its own supervisord program so it stays up with the desktop.
COPY docker/rosbridge-supervisor.conf /etc/supervisor/conf.d/rosbridge.conf

# Gazebo + TurtleBot3 launcher (runs after VNC is up; publishes /tf, /odom, /scan).
COPY docker/launch_gazebo_turtlebot3.sh /opt/foxy-mac-sim/launch_gazebo_turtlebot3.sh
RUN chmod +x /opt/foxy-mac-sim/launch_gazebo_turtlebot3.sh
COPY docker/gazebo-supervisor.conf /etc/supervisor/conf.d/gazebo.conf

# Arrow-key teleop (publishes to /cmd_vel)
COPY scripts/teleop_arrows.py /opt/foxy-mac-sim/teleop_arrows.py
RUN chmod +x /opt/foxy-mac-sim/teleop_arrows.py
