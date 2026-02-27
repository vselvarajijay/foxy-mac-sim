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

# --- Open Gazebo (noVNC in browser) ---
echo "Opening Gazebo viewer in browser..."
open "http://localhost:8080"

# --- Open Foxglove with connection, then layout ---
# Connection is applied via deep link (layout JSON does not persist connection in export).
echo "Opening Foxglove Desktop (connected to ws://localhost:9090)..."
open "foxglove://open?ds=rosbridge-websocket&ds.url=ws%3A%2F%2Flocalhost%3A9090"
sleep 2
if [[ -f "$FOXY_LAYOUT" ]]; then
  echo "Loading layout: config/foxy_layout.json"
  open -a "Foxglove" "$FOXY_LAYOUT" 2>/dev/null || open -a "Foxglove Studio" "$FOXY_LAYOUT" 2>/dev/null || true
fi

# --- Teleop handoff ---
echo ""
echo "Terminal is now the steering wheel. Use teleop_twist_keyboard (e.g. press I for forward)."
echo "Press Ctrl+C to stop teleop; run 'docker compose down' to stop the stack."
echo ""
exec docker exec -it foxy-sim bash -c "source /opt/ros/humble/setup.bash && ros2 run teleop_twist_keyboard teleop_twist_keyboard"
