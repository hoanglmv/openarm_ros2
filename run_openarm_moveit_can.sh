#!/usr/bin/env bash
# ==============================================================================
# Script khởi chạy OpenArm ROS 2 với MoveIt và kết nối OpenArm CAN
# ==============================================================================

set -e

ARM_TYPE="${1:-openarm_v2.0}"
RIGHT_CAN="${2:-can0}"
LEFT_CAN="${3:-can1}"

echo "======================================================================"
echo "    KHỞI CHẠY OPENARM ROS 2 VỚI MOVEIT VÀ KẾT NỐI OPENARM CAN        "
echo "======================================================================"
echo "  - Arm Type: $ARM_TYPE"
echo "  - Right Arm CAN: $RIGHT_CAN"
echo "  - Left Arm CAN:  $LEFT_CAN"
echo "======================================================================"

# 1. Cấu hình X11 cho phép GUI hiển thị lên màn hình
echo "[1/3] Cấu hình đồ họa X11..."
xhost +local:root >/dev/null 2>&1 || true

# 2. Kiểm tra và chuẩn bị giao diện CAN
echo "[2/3] Kiểm tra giao diện CAN..."
setup_can_if_missing() {
    local iface=$1
    if ip link show "$iface" 2>/dev/null | grep -q "UP"; then
        echo "  -> Tìm thấy interface '$iface' đang hoạt động."
    else
        echo "  -> Interface '$iface' chưa bật. Đang khởi tạo virtual CAN để sẵn sàng giao tiếp..."
        sudo modprobe vcan 2>/dev/null || true
        sudo ip link add dev "$iface" type vcan 2>/dev/null || true
        sudo ip link set "$iface" up 2>/dev/null || true
        echo "  -> '$iface' đã sẵn sàng."
    fi
}

setup_can_if_missing "$RIGHT_CAN"
setup_can_if_missing "$LEFT_CAN"

# 3. Khởi chạy Docker với MoveIt và OpenArm Hardware CAN
echo "[3/3] Khởi chạy OpenArm MoveIt + CAN Interface trong Docker..."
echo "  -> Cửa sổ RViz2 sẽ xuất hiện sau khi các controller nạp xong."
echo "----------------------------------------------------------------------"

docker run -it --rm \
  --privileged \
  --network=host \
  --env DISPLAY="${DISPLAY:-:0}" \
  --volume /tmp/.X11-unix:/tmp/.X11-unix \
  openarm-tested:latest \
  bash -c "
    # Đảm bảo CAN interface tồn tại trong container network namespace
    for iface in '$RIGHT_CAN' '$LEFT_CAN'; do
      if ! ip link show \"\$iface\" >/dev/null 2>&1; then
        ip link add dev \"\$iface\" type vcan 2>/dev/null || true
        ip link set \"\$iface\" up 2>/dev/null || true
      fi
    done

    source /opt/ros/humble/setup.bash
    source /overlay_ws/install/setup.bash

    echo '>>> Đang khởi động ros2 launch MoveIt + CAN...'
    ros2 launch openarm_bimanual_moveit_config demo.launch.py \
      arm_type:=$ARM_TYPE \
      use_fake_hardware:=false \
      right_can_interface:=$RIGHT_CAN \
      left_can_interface:=$LEFT_CAN
  "
