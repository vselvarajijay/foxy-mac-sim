#!/usr/bin/env bash
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
FOXY_LAYOUT="${SCRIPT_DIR}/config/foxy_layout.json"
FOXGLOVE_DOWNLOAD="https://foxglove.dev/download"
DOCKER_INSTALL="https://docs.docker.com/get-docker/"

echo "Foxy Mac Sim – starting zero-click workstation..."

# --- Pre-flight: Docker ---
if ! docker info &>/dev/null; then
  echo "Error: Docker is not running or not installed."
  echo "Please start Docker Desktop, or install it from: ${DOCKER_INSTALL}"
  exit 1
fi
echo "  Docker: OK"

# --- Pre-flight: Foxglove Desktop ---
if [[ ! -d "/Applications/Foxglove.app" && ! -d "/Applications/Foxglove Studio.app" ]]; then
  echo "Error: Foxglove Desktop was not found in /Applications."
  echo "Please install it from: ${FOXGLOVE_DOWNLOAD}"
  exit 1
fi
echo "  Foxglove: OK"

# --- Start stack ---
echo "Starting Docker stack (ROS 2 + Gazebo + rosbridge)..."
cd "$SCRIPT_DIR"
docker compose up -d

# --- Wait for ROS bridge ready ---
echo "Waiting for ROS bridge (port 9090) to be ready..."
max_attempts=60
attempt=0
until docker inspect --format='{{.State.Health.Status}}' foxy-sim 2>/dev/null | grep -q healthy; do
  attempt=$((attempt + 1))
  if [[ $attempt -ge $max_attempts ]]; then
    echo "Error: Container did not become healthy in time. Check: docker compose logs foxy-sim"
    exit 1
  fi
  sleep 2
done
echo "  ROS bridge: ready"

# --- Wait for Gazebo + TurtleBot3 to advertise /odom (so Foxglove has frames) ---
echo "Waiting for simulation (Gazebo + TurtleBot3) to advertise /odom..."
echo "  (On first run or Apple Silicon, Gazebo may take 2–5 minutes.)"
max_odom_attempts=50
odom_attempt=0
# Use 'topic list' instead of 'topic echo' to avoid QoS mismatch; match "odom" or "/odom"
until docker exec foxy-sim bash -c "source /opt/ros/humble/setup.bash && ros2 topic list | grep -qE '^(/)?odom$'" 2>/dev/null; do
  odom_attempt=$((odom_attempt + 1))
  if [[ $odom_attempt -ge $max_odom_attempts ]]; then
    echo "Warning: /odom did not appear in time. Opening viewers anyway (Foxglove may show 'frame not found' until the sim is ready)."
    break
  fi
  echo "  (attempt $odom_attempt/$max_odom_attempts)..."
  sleep 3
done
if [[ $odom_attempt -lt $max_odom_attempts ]]; then
  echo "  Simulation: ready"
fi

# --- Open Gazebo (noVNC in browser) ---
echo "Opening Gazebo viewer in browser..."
open "http://localhost:8080"

# --- Serve layout assets (URDF) for Foxglove ---
CONFIG_PORT=8081
if command -v python3 &>/dev/null; then
  (cd "$SCRIPT_DIR/config" && python3 -m http.server $CONFIG_PORT &) 2>/dev/null || true
  sleep 1
fi

# --- Open Foxglove with connection, then prompt for layout ---
# Connection is applied via deep link. Layout must be imported via Layouts menu (not File → Open).
echo "Opening Foxglove Desktop (connected to ws://localhost:9090)..."
open "foxglove://open?ds=rosbridge-websocket&ds.url=ws%3A%2F%2Flocalhost%3A9090"
sleep 2
if [[ -f "$FOXY_LAYOUT" ]]; then
  echo "To load the 3D + teleop layout: in Foxglove choose Layouts (top bar) → Import from file… → select:"
  echo "  $FOXY_LAYOUT"
  echo "(Do not use File → Open or drag the .json file—that opens it as data and shows 'Unsupported extension: .json'.)"
fi

# --- Teleop handoff ---
echo ""
echo "Terminal is now the steering wheel. Use arrow keys (or I/J/K/L) to move the robot."
echo "Press Ctrl+C to stop teleop; run 'docker compose down' to stop the stack."
echo ""
exec docker exec -it foxy-sim bash -c "source /opt/ros/humble/setup.bash && python3 /opt/foxy-mac-sim/teleop_arrows.py"
