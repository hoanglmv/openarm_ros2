#!/usr/bin/env bash
# ==============================================================================
# Script chạy demo tự động cho Mentor (Unbuffered realtime output)
# ==============================================================================

set -e

CONTAINER_ID=$(docker ps -q --filter ancestor=openarm-tested:latest | head -n 1)

if [ -z "$CONTAINER_ID" ]; then
    CONTAINER_ID=$(docker ps -q | head -n 1)
fi

if [ -z "$CONTAINER_ID" ]; then
    echo "❌ Không tìm thấy container OpenArm nào đang chạy!"
    echo "👉 Hãy đảm bảo RViz2 đang mở qua lệnh './run_openarm_moveit_can.sh'."
    exit 1
fi

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

# Dùng python3 -u (unbuffered) để terminal hiển thị log ngay lập tức theo thời gian thực
docker exec -i "$CONTAINER_ID" bash -c "source /opt/ros/humble/setup.bash && source /overlay_ws/install/setup.bash && python3 -u" < "$DIR/demo_mentor.py"
