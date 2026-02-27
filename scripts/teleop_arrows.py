#!/usr/bin/env python3
"""
Teleop the robot with arrow keys (and I/J/K/L as fallback).
Publishes geometry_msgs/Twist to /cmd_vel.
"""
import sys
import tty
import termios

import rclpy
from rclpy.node import Node
from geometry_msgs.msg import Twist


# Arrow key escape sequences (after ESC)
ARROW_UP = "\x1b[A"
ARROW_DOWN = "\x1b[B"
ARROW_RIGHT = "\x1b[C"
ARROW_LEFT = "\x1b[D"


def get_key():
    """Read one keypress; handle arrow keys (ESC [ A/B/C/D)."""
    fd = sys.stdin.fileno()
    old = termios.tcgetattr(fd)
    try:
        tty.setraw(fd)
        ch = sys.stdin.read(1)
        if ch == "\x1b":
            # Possible arrow key: read next two bytes
            c2 = sys.stdin.read(1)
            c3 = sys.stdin.read(1)
            if c2 == "[" and c3 == "A":
                return "up"
            if c2 == "[" and c3 == "B":
                return "down"
            if c2 == "[" and c3 == "C":
                return "right"
            if c2 == "[" and c3 == "D":
                return "left"
            # Other escape sequence, return as-is for Ctrl+C etc.
            return ch + c2 + c3
        return ch
    finally:
        termios.tcsetattr(fd, termios.TCSADRAIN, old)


def main():
    rclpy.init()
    node = Node("teleop_arrows")
    pub = node.create_publisher(Twist, "/cmd_vel", 10)

    linear_speed = 0.5
    angular_speed = 1.0

    print("Teleop: Arrow keys to move, I/J/K/L also work. Ctrl+C to quit.", flush=True)
    print("  Up/Down or I/, : forward/back. Left/Right or J/L : turn.", flush=True)
    print("  Speed: linear %.2f  angular %.2f" % (linear_speed, angular_speed), flush=True)

    try:
        while rclpy.ok():
            key = get_key()
            twist = Twist()

            if key in ("up", "i", "I"):
                twist.linear.x = float(linear_speed)
            elif key in ("down", ",", "m"):
                twist.linear.x = -float(linear_speed)
            elif key in ("left", "j", "J"):
                twist.angular.z = float(angular_speed)
            elif key in ("right", "l", "L"):
                twist.angular.z = -float(angular_speed)
            elif key in ("k", "K", " "):
                twist.linear.x = 0.0
                twist.angular.z = 0.0
            elif key == "\x03":  # Ctrl+C
                break
            else:
                # Stop on unknown key
                twist.linear.x = 0.0
                twist.angular.z = 0.0

            pub.publish(twist)
            rclpy.spin_once(node, timeout_sec=0)
    except KeyboardInterrupt:
        pass
    finally:
        # Stop the robot
        pub.publish(Twist())
        node.destroy_node()
        rclpy.shutdown()


if __name__ == "__main__":
    main()
