#!/usr/bin/env bash
# ==============================================================================
# Tiện ích gửi lệnh ROS 2 trực tiếp vào container OpenArm đang chạy
# ==============================================================================

set -e

CONTAINER_ID=$(docker ps -q --filter ancestor=openarm-tested:latest | head -n 1)

if [ -z "$CONTAINER_ID" ]; then
    CONTAINER_ID=$(docker ps -q | head -n 1)
fi

if [ -z "$CONTAINER_ID" ]; then
    echo "❌ Không tìm thấy container OpenArm nào đang chạy!"
    echo "👉 Hãy chạy './run_openarm_moveit_can.sh' ở terminal 1 trước."
    exit 1
fi

if [ "$1" == "bash" ] || [ -z "$1" ]; then
    echo ">>> Đang kết nối vào bash shell bên trong container $CONTAINER_ID..."
    docker exec -it "$CONTAINER_ID" bash -c "source /opt/ros/humble/setup.bash && source /overlay_ws/install/setup.bash && exec bash"
else
    # Sử dụng "$@" với _ để giữ nguyên chuỗi multiline và JSON không bị bash ngắt dòng
    docker exec -i "$CONTAINER_ID" bash -c 'source /opt/ros/humble/setup.bash && source /overlay_ws/install/setup.bash && exec ros2 "$@"' _ "$@"
fi
