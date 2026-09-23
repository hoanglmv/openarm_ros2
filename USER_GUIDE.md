# CẨM NANG HƯỚNG DẪN SỬ DỤNG REPOSITORY OPENARM ROS 2
*(Comprehensive User & Developer Guide)*

---

Chào mừng bạn đến với **OpenArm ROS 2** — gói phần mềm tích hợp ROS 2 chính thức cho hệ thống cánh tay robot dạng người **OpenArm** (phát triển bởi Enactic, Inc.).

Tài liệu này sẽ hướng dẫn bạn từ cơ bản đến nâng cao: hiểu rõ năng lực của hệ thống, khởi chạy mô phỏng 3D, lập kế hoạch chuyển động với MoveIt 2, điều khiển qua dòng lệnh/code Python, và triển khai trên robot phần cứng thật.

---

## MỤC LỤC
1. [Repo này dùng để làm gì?](#1-repo-này-dùng-để-làm-gì)
2. [Cấu trúc hệ thống & Robot](#2-cấu-trúc-hệ-thống--robot)
3. [Khởi chạy nhanh qua Docker (Quickstart)](#3-khởi-chạy-nhanh-qua-docker-quickstart)
4. [Hướng dẫn sử dụng giao diện 3D RViz2 + MoveIt](#4-hướng-dẫn-sử-dụng-giao-diện-3d-rviz2--moveit)
5. [Điều khiển bằng dòng lệnh (ROS 2 CLI)](#5-điều-khiển-bằng-dòng-lệnh-ros-2-cli)
6. [Viết mã lập trình điều khiển (Python API)](#6-viết-mã-lập-trình-điều-khiển-python-api)
7. [Kết nối và điều khiển robot thật (Hardware via CAN Bus)](#7-kết-nối-và-điều-khiển-robot-thật-hardware-via-can-bus)
8. [Xử lý sự cố thường gặp (Troubleshooting)](#8-xử-lý-sự-cố-thường-gặp-troubleshooting)

---

## 1. Repo này dùng để làm gì?

Repository `openarm_ros2` là **bộ não trung tâm điều khiển phần mềm** cho OpenArm. Bạn có thể làm được những việc sau:

- 🎮 **Mô phỏng 3D trực quan**: Xem mô hình 3D hai cánh tay robot chuyển động trong không gian ảo qua RViz2 hoặc MuJoCo.
- 📐 **Lập kế hoạch chuyển động (Motion Planning)**: Tự động tính toán đường đi mượt mà từ điểm A đến B, tự né va chạm giữa 2 tay hoặc với vật cản xung quanh bằng **MoveIt 2**.
- 🦾 **Điều khiển vị trí, vận tốc, mô-men (Impedance/Compliance Control)**: Nhờ giao thức điều khiển MIT mode và `ros2_control` chạy ở tần số cao (**750 Hz**).
- 🤖 **Huấn luyện AI & Teleoperation**: Thu thập dữ liệu góc khớp, vị trí đầu gắp để phục vụ bài toán **Imitation Learning (Học bắt chước)**, **Physical AI**, hoặc điều khiển từ xa bằng kính VR / tay cầm phụ trợ.
- 🔌 **Cắm chạy trực tiếp trên robot thật**: Giao tiếp trực tiếp với động cơ DaMiao (DM Series) qua giao diện mạng CAN-FD.

---

## 2. Cấu trúc hệ thống & Robot

Robot OpenArm hỗ trợ cả cấu hình một tay và hai tay (Bimanual):
- **Cánh tay trái (Left Arm)**: 7 bậc tự do (DOF) + 1 ngón kẹp (Gripper).
- **Cánh tay phải (Right Arm)**: 7 bậc tự do (DOF) + 1 ngón kẹp (Gripper).
- **Tổng cộng**: 16 khớp chuyển động độc lập.
- **Hỗ trợ 2 thế hệ**:
  - `openarm_v1.0`: Thế hệ 1.
  - `openarm_v2.0`: Thế hệ 2 (khớp vai và cánh tay tối ưu hóa mô-men).

---

## 3. Khởi chạy nhanh qua Docker (Quickstart)

Hệ thống đã được đóng gói sẵn trong Docker image `openarm-tested:latest` (hoặc build từ `.docker/Dockerfile.dev`).

### Bước 1: Cho phép ứng dụng trong Docker xuất giao diện đồ họa lên màn hình
Mở một terminal trên máy host (WSL2 hoặc Ubuntu):
```bash
xhost +local:root
```

### Bước 2: Khởi chạy Giao diện 3D RViz2 + MoveIt (Chế độ mô phỏng)
Chạy lệnh sau:
```bash
docker run -it --rm \
  --env DISPLAY=$DISPLAY \
  --volume /tmp/.X11-unix:/tmp/.X11-unix \
  --network=host \
  openarm-tested:latest \
  bash -c "source /opt/ros/humble/setup.bash && source /overlay_ws/install/setup.bash && ros2 launch openarm_bimanual_moveit_config demo.launch.py arm_type:=openarm_v2.0 use_fake_hardware:=true"
```
*(Cửa sổ RViz2 sẽ xuất hiện với đầy đủ mô hình 2 cánh tay robot và panel MoveIt như trong hình ảnh bạn thấy).*

> **Lưu ý**: Nếu bạn muốn chạy thế hệ v1.0, chỉ cần đổi tham số `arm_type:=openarm_v1.0`.

---

## 4. Hướng dẫn sử dụng giao diện 3D RViz2 + MoveIt

Khi giao diện RViz mở lên:

### 4.1. Kéo thả đầu gắp và Lập kế hoạch chuyển động (Plan & Execute)
1. Ở panel bên trái dưới tab **MotionPlanning**, chuyển sang tab **Planning**.
2. Chọn nhóm cần điều khiển trong mục **Planning Group**:
   - `left_arm`: Cánh tay trái (7 khớp)
   - `right_arm`: Cánh tay phải (7 khớp)
   - `dual_arm`: Cả 2 cánh tay cùng lúc
   - `left_gripper` / `right_gripper`: Bộ kẹp
3. Trên màn hình 3D, bạn sẽ thấy một **vòng tròn điều hướng (Interactive Marker)** với các mũi tên xanh, đỏ, vàng xuất hiện ở đầu gắp:
   - Dùng chuột trái kéo các mũi tên để di chuyển vị trí $(X, Y, Z)$.
   - Kéo các vòng cung để xoay hướng đầu kẹp (Roll, Pitch, Yaw).
   - Mô hình màu xanh mờ thể hiện vị trí đích (**Goal State**).
4. Nhấn nút **Plan**: MoveIt sẽ tính toán quỹ đạo chuyển động tránh tự va chạm. Đường màu cam/vàng sẽ mô phỏng cánh tay chuyển động thử.
5. Nhấn nút **Execute**: Cánh tay robot ảo sẽ chuyển động thật theo quỹ đạo vừa tính.
6. Hoặc nhấn trực tiếp **Plan & Execute** để robot tự tính toán và di chuyển ngay lập tức.

### 4.2. Đưa robot về các tư thế mặc định (Stored States)
- Vào tab **Planning** $\rightarrow$ phần **Select Goal State**.
- Chọn các trạng thái có sẵn:
  - `<current>`: Vị trí hiện tại
  - `<random valid>`: Một vị trí ngẫu nhiên không va chạm
  - `home` / `ready` / `zero`: Các tư thế chuẩn đã định nghĩa trước
- Nhấn **Plan & Execute**.

---

## 5. Điều khiển bằng dòng lệnh (ROS 2 CLI)

Mở một terminal mới (vào container đang chạy bằng lệnh `docker exec -it <container_id> bash` hoặc chạy docker mới):

### 5.1. Xem trạng thái các bộ điều khiển
```bash
ros2 control list_controllers
```
Kết quả hiển thị 5 controllers đang ở trạng thái `active`:
- `joint_state_broadcaster` (Gửi telemetry 750 Hz)
- `left_joint_trajectory_controller`
- `right_joint_trajectory_controller`
- `left_gripper_controller`
- `right_gripper_controller`

### 5.2. Đọc trạng thái vị trí các khớp robot
```bash
ros2 topic echo /joint_states --once
```

### 5.3. Gửi lệnh góc khớp trực tiếp tới cánh tay trái
Gửi lệnh góc quay (đơn vị: radian) đến 7 khớp của tay trái:
```bash
ros2 topic pub --once /left_joint_trajectory_controller/joint_trajectory trajectory_msgs/msg/JointTrajectory "{
  joint_names: [
    'openarm_left_joint1',
    'openarm_left_joint2',
    'openarm_left_joint3',
    'openarm_left_joint4',
    'openarm_left_joint5',
    'openarm_left_joint6',
    'openarm_left_joint7'
  ],
  points: [{
    positions: [0.2, -0.3, 0.4, 0.8, -0.1, 0.5, -0.2],
    time_from_start: { sec: 2, nanosec: 0 }
  }]
}"
```
*Bạn sẽ quan sát thấy cánh tay trái trên RViz di chuyển từ từ đến vị trí góc khớp này trong vòng 2 giây.*

### 5.4. Đóng / Mở bộ kẹp (Gripper)
Gửi lệnh action đóng kẹp ngón tay:
```bash
ros2 action send_goal /left_gripper_controller/gripper_cmd control_msgs/action/GripperCommand "{command: {position: 0.04, max_effort: 10.0}}"
```

---

## 6. Viết mã lập trình điều khiển (Python API)

Dưới đây là một ví dụ script Python đơn giản sử dụng ROS 2 để điều khiển cánh tay chuyển động theo chu kỳ:

```python
#!/usr/bin/env python3
import rclpy
from rclpy.node import Node
from trajectory_msgs.msg import JointTrajectory, JointTrajectoryPoint
from builtin_interfaces.msg import Duration

class OpenArmCommander(Node):
    def __init__(self):
        super().__init__('openarm_commander')
        self.publisher_ = self.create_publisher(
            JointTrajectory, 
            '/left_joint_trajectory_controller/joint_trajectory', 
            10
        )
        self.timer = self.create_timer(3.0, self.send_goal)
        self.step = 0

    def send_goal(self):
        msg = JointTrajectory()
        msg.joint_names = [f'openarm_left_joint{i}' for i in range(1, 8)]
        
        point = JointTrajectoryPoint()
        if self.step % 2 == 0:
            point.positions = [0.0, -0.5, 0.3, 1.0, 0.0, 0.3, 0.0]
        else:
            point.positions = [0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0]
            
        point.time_from_start = Duration(sec=2, nanosec=0)
        msg.points.append(point)
        
        self.publisher_.publish(msg)
        self.get_logger().info(f'Sent goal step {self.step}')
        self.step += 1

def main():
    rclpy.init()
    node = OpenArmCommander()
    rclpy.spin(node)
    node.destroy_node()
    rclpy.shutdown()

if __name__ == '__main__':
    main()
```

---

## 7. Kết nối và điều khiển robot thật (Hardware via CAN Bus)

Khi bạn có phần cứng OpenArm vật lý kết nối với máy tính qua USB-CAN adapter (như Candlelight hoặc CANable):

### Bước 1: Khởi tạo giao diện CAN-FD trên hệ điều hành Linux máy host
Robot sử dụng giao thức CAN-FD với baudrate 1M / data bitrate 5M:
```bash
# Thiết lập cho tay phải (can0)
sudo ip link set can0 type can bitrate 1000000 dbitrate 5000000 fd on
sudo ip link set can0 up

# Thiết lập cho tay trái (can1)
sudo ip link set can1 type can bitrate 1000000 dbitrate 5000000 fd on
sudo ip link set can1 up
```

### Bước 2: Khởi chạy ROS 2 kết nối trực tiếp phần cứng
```bash
docker run -it --rm --privileged --network=host \
  openarm-tested:latest \
  bash -c "source /opt/ros/humble/setup.bash && source /overlay_ws/install/setup.bash && ros2 launch openarm_bringup openarm.bimanual.launch.py arm_type:=openarm_v2.0 use_fake_hardware:=false right_can_interface:=can0 left_can_interface:=can1"
```

> ⚠️ **Quy tắc an toàn phần cứng (Safety Rules)**:
> 1. Luôn để sẵn **nút dừng khẩn cấp (E-Stop)** trong tầm tay.
> 2. Đảm bảo xung quanh cánh tay có bán kính an toàn ít nhất **1 mét** không có người hoặc vật dễ vỡ.
> 3. Trong lần đầu cấp điện, kiểm tra chiều quay từng khớp ở vận tốc cực thấp trước khi chạy quỹ đạo MoveIt.

---

## 8. Xử lý sự cố thường gặp (Troubleshooting)

| Vấn đề | Nguyên nhân | Cách khắc phục |
| :--- | :--- | :--- |
| **Không mở được cửa sổ RViz2** | Lỗi phân quyền X11 hoặc thiếu biến `DISPLAY` | Chạy lệnh `xhost +local:root` trên máy host trước khi chạy Docker. Kiểm tra `echo $DISPLAY` (thường là `:0`). |
| **MoveIt báo lỗi "No solution found"** | Điểm đặt Goal State nằm ngoài tầm với hoặc bị tự va chạm | Thu nhỏ vùng dịch chuyển, kéo marker vào vùng không gian mở trước mặt robot. |
| **Khớp robot bị giật hoặc rung** | Tần số 750 Hz đòi hỏi phản hồi thời gian thực nhưng Linux thường có jitter | Cài đặt nhân Linux có bản vá **PREEMPT_RT** để ổn định chu kỳ điều khiển. |
| **Không tìm thấy cổng CAN (`can0: No such device`)** | Chưa cắm mạch chuyển đổi USB-to-CAN hoặc chưa bật module `vcan`/`can` | Chạy `lsusb` kiểm tra thiết bị, sau đó gõ `sudo modprobe can && sudo modprobe can_raw`. |

---
*Tài liệu được biên soạn và chuẩn hóa bởi Antigravity AI Assistant.*
