# Extends Tiryoh's ROS 2 Desktop VNC (Humble) with rosbridge and teleop_twist_keyboard.
# See https://github.com/Tiryoh/docker-ros2-desktop-vnc
FROM ghcr.io/tiryoh/ros2-desktop-vnc:humble

SHELL ["/bin/bash", "-c"]

RUN apt-get update -q && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y \
    ros-humble-rosbridge-suite \
    ros-humble-teleop-twist-keyboard && \
    apt-get autoclean && \
    rm -rf /var/lib/apt/lists/*

# Rosbridge runs as its own supervisord program so it stays up with the desktop.
COPY docker/rosbridge-supervisor.conf /etc/supervisor/conf.d/rosbridge.conf
