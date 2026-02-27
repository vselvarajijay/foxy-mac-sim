# Foxy Mac Sim

A zero-click macOS robotics workstation: run one script to get Gazebo in the browser, Foxglove Desktop connected to ROS, and your terminal as a teleop “steering wheel.”

## One-command flow

```bash
./start.sh
```

Within about 60 seconds you get:

- **Browser:** Gazebo simulation (noVNC) at [http://localhost:8080](http://localhost:8080)
- **Foxglove Desktop:** Connected to `ws://localhost:9090` (rosbridge), with a layout for `/cmd_vel`, `/odom`, `/tf`, `/scan`
- **Terminal:** Arrow-key teleop — use **arrow keys** (or **I/J/K/L**) to move the robot; telemetry updates in Foxglove

## Prerequisites

- **Docker Desktop** — installed and **running**. [Get Docker](https://docs.docker.com/get-docker/)
- **Foxglove Desktop** — installed in `/Applications` as `Foxglove.app` or `Foxglove Studio.app`. [Download Foxglove](https://foxglove.dev/download)

`start.sh` checks both and prints the links above if something is missing.

## What’s in the stack

- **Docker:** One container (`foxy-sim`) based on [Tiryoh/ros2-desktop-vnc](https://github.com/Tiryoh/docker-ros2-desktop-vnc) (ROS 2 Humble, Gazebo, noVNC), plus:
  - **TurtleBot3 Burger** in Gazebo (small indoor world). The sim publishes `/tf`, `/odom`, `/scan` and subscribes to `/cmd_vel`, so Foxglove can render the robot and lidar without “frame not found.”
  - `rosbridge_suite` on port **9090** (Foxglove)
  - Arrow-key teleop (publishes to `/cmd_vel` via `docker exec` from `start.sh`)
- **Host:** Gazebo via browser at **8080**, Foxglove via deep link to **localhost:9090**, layout in `config/foxy_layout.json`

**Apple Silicon (M1/M2/M3):** The image uses `platform: linux/amd64` so the Gazebo + TurtleBot3 sim runs under emulation. It may be slower than on Intel Macs; if you hit issues, ensure Docker Desktop has enough memory and CPU.

## Stop and rebuild

- **Stop:** `docker compose down`
- **Rebuild image:** `docker compose build --no-cache` then `./start.sh` again

## Troubleshooting

- **Ports in use:** If 8080 or 9090 are already in use, change the port mappings in `docker-compose.yml` (and, for 9090, the Foxglove connection URL in `start.sh`).
- **Foxglove “Connection failed”:** Wait until the container is healthy (script waits for this). If it still fails, run `docker compose logs foxy-sim` and confirm rosbridge is listening on 9090.
- **Layout panels empty:** Connect to `ws://localhost:9090` first (the script does this via deep link). To load the layout: open the **Layouts** menu (top bar) → **Import from file…** → choose `config/foxy_layout.json`. (Do **not** use File → Open or drag the file in—that tries to open it as data and will show “Unsupported extension: .json”.) Topics to add if needed: `/cmd_vel`, `/odom`, `/tf`, `/scan`.
- **Layout "incompatible":** If Foxglove says the layout file is incompatible, the JSON format may not match your Foxglove version. Create a compatible layout once: with the sim running and Foxglove connected, add a 3D panel (with Grid layer, frame `odom`, and URDF layer, topic `/robot_description`), Raw Messages (`/cmd_vel`), and Plot panels; enable 3D topics `/scan`, `/tf`, `/robot_description`. Then use the layout menu → **Export…** and save over `config/foxy_layout.json`. Future imports will work.

### Foxglove 3D: no robot model or ground grid or ground grid

The layout is configured to load the **robot model from the `/robot_description` topic** (published by the sim) and to show the **grid** and **laser scan** (`/scan`). If you still see only TF axes and no robot:

1. In Foxglove, select the **3D** panel and open its settings (gear icon or click the panel title).
2. **Ground grid:** In the left sidebar, find **Scene** or **Layers**. Click **Add layer** → **Grid**. Set **Frame** to `odom`, **Size** to 20, **Divisions** to 20. You should see a gray floor grid.
3. **Robot model:** Click **Add layer** → **URDF**. Set **Source** to **Topic**, **Topic** to `/robot_description`. The TurtleBot should appear (possibly as simple shapes if meshes are not resolved).
4. **Laser scan:** In the same 3D panel settings, under **Topics**, ensure `/scan` is enabled so the lidar points (and obstacles) show.

**If the 3D panel shows no “Custom layers” (Grid, URDF) after importing the layout:** Some Foxglove versions ignore custom layers from hand‑edited layout JSON. Add them once manually (steps 2–3 above), then use the layout’s **Export…** and save the file over `config/foxy_layout.json`. Future runs will then load the layers correctly.

If the robot still does not appear, the sim may not have finished starting; wait for Gazebo to fully load, then reload the layout. Foxglove may not resolve `package://` mesh paths over rosbridge; the 3D view will still show transforms and `/scan`.

**Environment (walls, buildings):** The full Gazebo world is only visible in the **browser** at [http://localhost:8080](http://localhost:8080) (noVNC). In Foxglove, the **laser scan** (`/scan`) shows obstacles as points in 3D.
