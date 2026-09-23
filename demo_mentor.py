#!/usr/bin/env python3
"""
DEMO KỊCH BẢN CHUYỂN ĐỘNG ROBOT OPENARM DÀNH CHO MENTOR
Thực hiện chuỗi chuyển động 2 cánh tay + đóng mở gripper tự động
"""

import time
import rclpy
from rclpy.node import Node
from trajectory_msgs.msg import JointTrajectory, JointTrajectoryPoint
from control_msgs.action import GripperCommand
from rclpy.action import ActionClient
from builtin_interfaces.msg import Duration

class MentorDemo(Node):
    def __init__(self):
        super().__init__('mentor_demo_node')
        self.left_pub = self.create_publisher(
            JointTrajectory, '/left_joint_trajectory_controller/joint_trajectory', 10
        )
        self.right_pub = self.create_publisher(
            JointTrajectory, '/right_joint_trajectory_controller/joint_trajectory', 10
        )
        self.left_gripper_client = ActionClient(self, GripperCommand, '/left_gripper_controller/gripper_cmd')
        
        self.left_joints = [f'openarm_left_joint{i}' for i in range(1, 8)]
        self.right_joints = [f'openarm_right_joint{i}' for i in range(1, 8)]

    def send_left_arm(self, positions, duration_sec=2.0):
        msg = JointTrajectory()
        msg.joint_names = self.left_joints
        point = JointTrajectoryPoint()
        point.positions = [float(p) for p in positions]
        point.time_from_start = Duration(sec=int(duration_sec), nanosec=int((duration_sec % 1) * 1e9))
        msg.points.append(point)
        self.left_pub.publish(msg)

    def send_right_arm(self, positions, duration_sec=2.0):
        msg = JointTrajectory()
        msg.joint_names = self.right_joints
        point = JointTrajectoryPoint()
        point.positions = [float(p) for p in positions]
        point.time_from_start = Duration(sec=int(duration_sec), nanosec=int((duration_sec % 1) * 1e9))
        msg.points.append(point)
        self.right_pub.publish(msg)

    def trigger_gripper(self, position=0.04):
        if self.left_gripper_client.wait_for_server(timeout_sec=1.0):
            goal = GripperCommand.Goal()
            goal.command.position = position
            goal.command.max_effort = 10.0
            self.left_gripper_client.send_goal_async(goal)

def run_demo():
    rclpy.init()
    demo = MentorDemo()

    print("\n" + "="*60, flush=True)
    print("🤖 BẮT ĐẦU KỊCH BẢN DEMO TỰ ĐỘNG CHO MENTOR", flush=True)
    print("="*60, flush=True)

    # Bước 1: Tư thế chuẩn bị (Ready Stance)
    print("👉 [Bước 1/4] Nâng 2 cánh tay lên vị trí sẵn sàng thao tác (Ready Pose)...", flush=True)
    demo.send_left_arm([0.2, -0.4, 0.3, 0.8, -0.1, 0.5, -0.2], duration_sec=2.0)
    demo.send_right_arm([-0.2, -0.4, -0.3, 0.8, 0.1, 0.5, 0.2], duration_sec=2.0)
    time.sleep(2.5)

    # Bước 2: Thao tác vẫy tay trái
    print("👉 [Bước 2/4] Tay trái vẫy chào và điều chỉnh hướng cổ tay...", flush=True)
    demo.send_left_arm([0.4, -0.2, 0.5, 1.1, -0.3, 0.7, 0.3], duration_sec=1.5)
    time.sleep(1.8)
    demo.send_left_arm([0.2, -0.4, 0.3, 0.8, -0.1, 0.5, -0.2], duration_sec=1.5)
    time.sleep(1.8)

    # Bước 3: Đóng mở ngón kẹp
    print("👉 [Bước 3/4] Mở rộng bộ kẹp Gripper...", flush=True)
    demo.trigger_gripper(position=0.04)
    time.sleep(1.5)
    print("              Đóng kẹp Gripper...", flush=True)
    demo.trigger_gripper(position=0.0)
    time.sleep(1.5)

    # Bước 4: Trở về vị trí nghỉ an toàn
    print("👉 [Bước 4/4] Đưa cả hai cánh tay về vị trí an toàn (Zero Pose)...", flush=True)
    demo.send_left_arm([0.0]*7, duration_sec=2.0)
    demo.send_right_arm([0.0]*7, duration_sec=2.0)
    time.sleep(2.5)

    print("\n✅ HOÀN THÀNH KỊCH BẢN DEMO THÀNH CÔNG RỰC RỠ!", flush=True)
    print("="*60 + "\n", flush=True)

    demo.destroy_node()
    rclpy.shutdown()

if __name__ == '__main__':
    run_demo()
