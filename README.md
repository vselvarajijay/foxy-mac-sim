# Foxy Mac Sim

A zero-click macOS robotics workstation: run one script to get Gazebo in the browser, Foxglove Desktop connected to ROS, and your terminal as a teleop “steering wheel.”

## One-command flow

```bash
./start.sh
```

Within about 60 seconds you get:

- **Browser:** Gazebo simulation (noVNC) at [http://localhost:8080](http://localhost:8080)
- **Foxglove Desktop:** Connected to `ws://localhost:9090` (rosbridge), with a layout for `/cmd_vel`, `/odom`, `/tf`, `/scan`
- **Terminal:** `teleop_twist_keyboard` — press **I** for forward, **J/L** for turn, etc.; robot moves in Gazebo and telemetry updates in Foxglove

## Prerequisites

- **Docker Desktop** — installed and **running**. [Get Docker](https://docs.docker.com/get-docker/)
- **Foxglove Desktop** — installed in `/Applications` as `Foxglove.app` or `Foxglove Studio.app`. [Download Foxglove](https://foxglove.dev/download)

`start.sh` checks both and prints the links above if something is missing.

## What’s in the stack

- **Docker:** One container (`foxy-sim`) based on [Tiryoh/ros2-desktop-vnc](https://github.com/Tiryoh/docker-ros2-desktop-vnc) (ROS 2 Humble, Gazebo, noVNC), plus:
  - `rosbridge_suite` on port **9090** (Foxglove)
  - `teleop_twist_keyboard` (run via `docker exec` from `start.sh`)
- **Host:** Gazebo via browser at **8080**, Foxglove via deep link to **localhost:9090**, layout in `config/foxy_layout.json`

## Stop and rebuild

- **Stop:** `docker compose down`
- **Rebuild image:** `docker compose build --no-cache` then `./start.sh` again

## Troubleshooting

- **Ports in use:** If 8080 or 9090 are already in use, change the port mappings in `docker-compose.yml` (and, for 9090, the Foxglove connection URL in `start.sh`).
- **Foxglove “Connection failed”:** Wait until the container is healthy (script waits for this). If it still fails, run `docker compose logs foxy-sim` and confirm rosbridge is listening on 9090.
- **Layout panels empty:** Connect to `ws://localhost:9090` first (the script does this via deep link). You can then use **Layouts → Import from file…** and choose `config/foxy_layout.json` if the preconfigured panels didn’t load. Topics to add: `/cmd_vel`, `/odom`, `/tf`, `/scan`.
