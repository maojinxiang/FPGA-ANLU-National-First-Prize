import socket
import struct
import time
import threading
import queue
import numpy as np
import cv2
from tkinter import Tk, Button, Label, Frame, Entry, StringVar, messagebox, scrolledtext, Toplevel, END, IntVar, \
    Radiobutton
from tkinter import ttk  # Themed Tkinter widgets for tabs
from PIL import Image, ImageTk
from tkinter import filedialog

# ============================================================================
# 全局常量定义
# ============================================================================
# --- Q1: General UDP Control ---
DEFAULT_LOCAL_IP = "192.168.240.2"
Q1_LOCAL_PORT = 2
Q1_REMOTE_TARGET = "192.168.240.1:1"

# --- Q2: 图片发送相关 ---
SENDER_PACKET_SIZE = 1440
DEFAULT_FPGA_IP = "192.168.240.1"
SENDER_FPGA_PORT = 4

# --- Q3 & Q4 & Q5: 视频接收相关 ---
DEFAULT_HOST_IP = "192.168.240.2"
RECEIVER_HOST_PORT = 6003
RECEIVER_BUFFER_SIZE = 8192
IMG_WIDTH = 640
IMG_HEIGHT = 480
PACKET_HEADER_SIZE = 32
TOTAL_PACKETS_PER_FRAME = 1450
FRAME_TIMEOUT = 2.0  # 秒


# ============================================================================
# Q1: 通用UDP监听线程
# ============================================================================
class Q1ListenerThread(threading.Thread):
    def __init__(self, host_ip, host_port, display_callback):
        super().__init__(daemon=True)
        self.host_ip = host_ip
        self.host_port = host_port
        self.display_callback = display_callback
        self.running_event = threading.Event()
        self.sock = None

    def run(self):
        try:
            self.sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
            self.sock.bind((self.host_ip, self.host_port))
            self.sock.settimeout(1.0)
            self.running_event.set()
            print(f"[Q1-Listen] 开始监听在 {self.host_ip}:{self.host_port}")
        except Exception as e:
            print(f"[Q1-错误] 监听失败: {e}")
            messagebox.showerror("监听失败", f"无法绑定到 {self.host_ip}:{self.host_port}。\n请检查IP或端口。")
            self.display_callback(None, "error")
            return

        while self.running_event.is_set():
            try:
                data, addr = self.sock.recvfrom(1024)
                if data:
                    timestamp = time.strftime("%H:%M:%S")
                    hex_string = data.hex(' ').upper()
                    display_message = f"[{timestamp}] Recv From {addr[0]}:{addr[1]} -> {hex_string}\n"
                    self.display_callback(display_message, "data")
            except socket.timeout:
                continue
            except Exception as e:
                if self.running_event.is_set():
                    print(f"[Q1-错误] 接收数据时出错: {e}")
                break

        if self.sock:
            self.sock.close()
        print("[Q1-Listen] 监听线程已停止。")

    def stop(self):
        self.running_event.clear()


# ============================================================================
# 网络接收线程 (Q3, Q4, Q5 共用)
# ============================================================================
class UDPReceiverThread(threading.Thread):
    def __init__(self, host_ip, host_port, packet_queue, log_callback):
        super().__init__(daemon=True)
        self.host_ip = host_ip
        self.host_port = host_port
        self.packet_queue = packet_queue
        self.log = log_callback
        self.running_event = threading.Event()
        self.sock = None

    def run(self):
        try:
            self.sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
            self.sock.setsockopt(socket.SOL_SOCKET, socket.SO_RCVBUF, 16 * 1024 * 1024)
            self.sock.bind((self.host_ip, self.host_port))
            self.sock.settimeout(1.0)
            self.running_event.set()
            self.log(f"接收线程已启动，正在监听 {self.host_ip}:{self.host_port}")
        except Exception as e:
            self.log(f"[错误] 无法启动UDP接收器: {e}")
            messagebox.showerror("网络错误", f"无法绑定到 {self.host_ip}:{self.host_port}。\n请检查IP地址是否正确，或端口是否被占用。")
            return

        while self.running_event.is_set():
            try:
                data, _ = self.sock.recvfrom(RECEIVER_BUFFER_SIZE)
                if data:
                    self.packet_queue.put_nowait(data)
            except socket.timeout:
                continue
            except queue.Full:
                pass
            except Exception as e:
                if self.running_event.is_set():
                    self.log(f"[错误] 网络接收异常: {e}")
                break

        if self.sock:
            self.sock.close()
        self.log("接收线程已停止。")

    def stop(self):
        self.running_event.clear()


# ============================================================================
# 主应用程序
# ============================================================================
class IntegratedApp:
    def __init__(self, root):
        self.root = root
        self.root.title("FPGA 综合上位机")
        self.root.geometry("850x500")

        # --- Q1 State ---
        self.q1_listener_thread = None
        self.is_q1_listening = False

        # --- Q3/Q4/Q5 State ---
        self.receiver_thread = None
        self.is_receiving = False
        self.packet_queue = queue.Queue(maxsize=TOTAL_PACKETS_PER_FRAME * 2)
        self.frame_packets = {}
        self.current_frame_seq = -1
        self.last_packet_time = 0
        self.latest_frame_for_saving = None
        self.current_mode = None
        self.fps = 0.0
        self.last_fps_time = time.time()
        self.fps_frame_count = 0
        self.receiver_buttons = {}


        self._setup_ui()
        self.root.protocol("WM_DELETE_WINDOW", self.on_closing)

    def _setup_ui(self):
        self.notebook = ttk.Notebook(self.root)
        self.notebook.pack(pady=10, padx=10, fill="both", expand=True)

        q1_frame = ttk.Frame(self.notebook)
        q2_frame = ttk.Frame(self.notebook)
        q3_frame = ttk.Frame(self.notebook)
        q4_frame = ttk.Frame(self.notebook)
        q5_frame = ttk.Frame(self.notebook)

        self.notebook.add(q1_frame, text='  基础第一问: PC控制led/数码管  ')
        self.notebook.add(q2_frame, text='  基础第二问: 发送静态图片  ')
        self.notebook.add(q3_frame, text='  基础第三问: 接收并保存图片  ')
        self.notebook.add(q4_frame, text='  基础第四问: 实时视频查看器 & 发挥第二问ISP  ')
        self.notebook.add(q5_frame, text='  发挥三: 运动目标检测  ')

        self._setup_q1_ui(q1_frame)
        self._setup_q2_ui(q2_frame)
        self._setup_receiver_ui(q3_frame, "q3")
        self._setup_receiver_ui(q4_frame, "q4")
        self._setup_receiver_ui(q5_frame, "q5")

    def _setup_q1_ui(self, parent):
        """设置第一问的UI界面 (精确匹配截图)"""

        # --- Main Layout ---
        left_panel = ttk.Frame(parent, width=220)
        left_panel.pack(side="left", fill="y", padx=5, pady=5)

        right_panel = ttk.Frame(parent)
        right_panel.pack(side="right", fill="both", expand=True, padx=5, pady=5)

        # --- Left Panel ---
        net_settings_frame = ttk.LabelFrame(left_panel, text="网络设置")
        net_settings_frame.pack(fill="x", pady=(0, 10))
        ttk.Label(net_settings_frame, text="(1) 协议类型").pack(anchor="w", padx=5, pady=2)
        protocol_combo = ttk.Combobox(net_settings_frame, values=["UDP"], state="readonly", width=18)
        protocol_combo.set("UDP")
        protocol_combo.pack(fill="x", padx=5, pady=2)
        ttk.Label(net_settings_frame, text="(2) 本地主机地址").pack(anchor="w", padx=5, pady=2)
        self.q1_local_ip_var = StringVar(value=DEFAULT_LOCAL_IP)
        ttk.Entry(net_settings_frame, textvariable=self.q1_local_ip_var, width=20).pack(fill="x", padx=5, pady=2)
        ttk.Label(net_settings_frame, text="(3) 本地主机端口").pack(anchor="w", padx=5, pady=2)
        self.q1_local_port_var = StringVar(value=str(Q1_LOCAL_PORT))
        ttk.Entry(net_settings_frame, textvariable=self.q1_local_port_var, width=20).pack(fill="x", padx=5, pady=2)
        self.q1_open_btn = ttk.Button(net_settings_frame, text="打开", command=self._start_q1_listening)
        self.q1_open_btn.pack(pady=(10, 5), padx=5, fill='x')
        self.q1_close_btn = ttk.Button(net_settings_frame, text="关闭", state="disabled", command=self._stop_q1_listening)
        self.q1_close_btn.pack(pady=5, padx=5, fill='x')

        recv_settings_frame = ttk.LabelFrame(left_panel, text="接收设置")
        recv_settings_frame.pack(fill="x", pady=10)
        self.q1_recv_format = StringVar(value="HEX")
        ttk.Radiobutton(recv_settings_frame, text="ASCII", variable=self.q1_recv_format, value="ASCII",
                        state="disabled").pack(anchor="w", padx=5)
        ttk.Radiobutton(recv_settings_frame, text="HEX", variable=self.q1_recv_format, value="HEX").pack(anchor="w",
                                                                                                         padx=5)
        ttk.Checkbutton(recv_settings_frame, text="按日志模式显示").pack(anchor="w", padx=5)
        ttk.Checkbutton(recv_settings_frame, text="接收区自动换行").pack(anchor="w", padx=5)
        ttk.Button(recv_settings_frame, text="清除接收", command=self._clear_q1_recv_text).pack(pady=5, padx=5, fill='x')

        # --- Right Panel ---
        log_frame = ttk.LabelFrame(right_panel, text="数据日志")
        log_frame.pack(fill="both", expand=True)
        self.q1_recv_text = scrolledtext.ScrolledText(log_frame, font=("Courier New", 9), wrap="word")
        self.q1_recv_text.pack(fill="both", expand=True)
        self.q1_recv_text.configure(state='disabled')

        # --- Bottom Panel (Send Area) ---
        bottom_panel = ttk.Frame(parent)
        bottom_panel.pack(fill="x", side="bottom", padx=5, pady=5)

        send_action_frame = ttk.Frame(bottom_panel)
        send_action_frame.pack(fill="x", pady=5)

        row1_frame = ttk.Frame(send_action_frame)
        row1_frame.pack(fill='x', pady=(0, 5))
        self.q1_send_format = StringVar(value="HEX")
        ttk.Label(row1_frame, text="发送设置:").pack(side="left", padx=5)
        ttk.Radiobutton(row1_frame, text="ASCII", variable=self.q1_send_format, value="ASCII", state="disabled").pack(
            side="left")
        ttk.Radiobutton(row1_frame, text="HEX", variable=self.q1_send_format, value="HEX").pack(side="left", padx=5)

        row2_frame = ttk.Frame(send_action_frame)
        row2_frame.pack(fill='x')
        ttk.Label(row2_frame, text="远程主机:").pack(side="left")
        self.q1_remote_target_var = StringVar(value=Q1_REMOTE_TARGET)
        ttk.Entry(row2_frame, textvariable=self.q1_remote_target_var, width=22).pack(side="left", padx=5)
        self.q1_send_var = StringVar(value="")
        self.send_entry = ttk.Entry(row2_frame, textvariable=self.q1_send_var)
        self.send_entry.pack(side="left", fill="x", expand=True, padx=5)
        ttk.Button(row2_frame, text="发送", command=self._send_q1_hex_data).pack(side="right", padx=5)
        ttk.Button(row2_frame, text="清除", command=lambda: self.q1_send_var.set("")).pack(side="right", padx=5)

    def _setup_q2_ui(self, parent):
        self.q2_fpga_ip_var = StringVar(value=DEFAULT_FPGA_IP)
        self.q2_fpga_port_var = StringVar(value=str(SENDER_FPGA_PORT))
        self._create_common_net_config_frame(parent, "目标IP (FPGA):", self.q2_fpga_ip_var, "目标端口:",
                                             self.q2_fpga_port_var)
        action_frame = ttk.LabelFrame(parent, text="操作", padding=(10, 5))
        action_frame.pack(fill="both", expand=True, padx=10, pady=10)
        self.q2_status_label = ttk.Label(action_frame, text="请选择一张 640x480 的图片进行发送", width=60, anchor="center")
        self.q2_status_label.pack(pady=20)
        self.send_button = ttk.Button(action_frame, text="选择图片并发送", command=self.select_and_send_image)
        self.send_button.pack(pady=20)

    def _setup_receiver_ui(self, parent, mode):
        host_ip_var = StringVar(value=DEFAULT_HOST_IP)
        host_port_var = StringVar(value=str(RECEIVER_HOST_PORT))
        self._create_common_net_config_frame(parent, "本机IP:", host_ip_var, "监听端口:", host_port_var)
        action_frame = ttk.LabelFrame(parent, text="控制", padding=(10, 5))
        action_frame.pack(fill="both", expand=True, padx=10, pady=10)
        start_button = ttk.Button(action_frame, text="开始接收",
                                  command=lambda m=mode, ip=host_ip_var, port=host_port_var: self.start_receiving(
                                      ip.get(), int(port.get()), m))
        start_button.pack(pady=20)
        stop_button = ttk.Button(action_frame, text="停止接收", state="disabled",
                                 command=lambda: self.stop_receiving(from_button=True))
        stop_button.pack(pady=20)
        self.receiver_buttons[mode] = {'start': start_button, 'stop': stop_button}
        if mode == 'q3':
            save_button = ttk.Button(action_frame, text="保存当前帧", state="disabled", command=self.save_current_frame)
            save_button.pack(pady=20)
            self.receiver_buttons[mode]['save'] = save_button

    def _create_common_net_config_frame(self, parent, ip_label, ip_var, port_label, port_var):
        frame = ttk.LabelFrame(parent, text="网络配置", padding=(10, 5))
        frame.pack(fill="x", padx=10, pady=5)
        ttk.Label(frame, text=ip_label).grid(row=0, column=0, sticky="w", padx=5, pady=2)
        ttk.Entry(frame, textvariable=ip_var, width=20).grid(row=0, column=1, sticky="w", padx=5, pady=2)
        ttk.Label(frame, text=port_label).grid(row=1, column=0, sticky="w", padx=5, pady=2)
        ttk.Entry(frame, textvariable=port_var, width=20).grid(row=1, column=1, sticky="w", padx=5, pady=2)
        return frame

    def _start_q1_listening(self):
        if self.is_q1_listening:
            messagebox.showwarning("警告", "已在监听中。")
            return
        ip = self.q1_local_ip_var.get()
        port = int(self.q1_local_port_var.get())
        self.q1_listener_thread = Q1ListenerThread(ip, port, self._display_q1_received_data)
        self.q1_listener_thread.start()
        self.is_q1_listening = True
        self.q1_open_btn.config(state="disabled")
        self.q1_close_btn.config(state="normal")

    def _stop_q1_listening(self):
        if not self.is_q1_listening:
            return
        self.q1_listener_thread.stop()
        self.is_q1_listening = False
        self.q1_open_btn.config(state="normal")
        self.q1_close_btn.config(state="disabled")
        print("[Q1-Listen] 用户停止监听。")

    def _display_q1_received_data(self, message, status):
        def _update():
            if status == "error":
                self.q1_open_btn.config(state="normal")
                self.q1_close_btn.config(state="disabled")
                self.is_q1_listening = False
                return

            self.q1_recv_text.configure(state='normal')
            self.q1_recv_text.insert(END, message)
            self.q1_recv_text.see(END)
            self.q1_recv_text.configure(state='disabled')

        self.root.after(0, _update)

    def _clear_q1_recv_text(self):
        self.q1_recv_text.configure(state='normal')
        self.q1_recv_text.delete('1.0', END)
        self.q1_recv_text.configure(state='disabled')

    def _send_q1_hex_data(self):
        hex_string = self.q1_send_var.get().strip().replace(" ", "").replace("\n", "")
        target_str = self.q1_remote_target_var.get()
        try:
            if not hex_string:
                messagebox.showwarning("输入为空", "请输入要发送的HEX数据。")
                return

            if ":" not in target_str:
                raise ValueError("远程主机格式应为 IP:Port")
            ip, port_str = target_str.split(":")
            port = int(port_str)

            if len(hex_string) % 2 != 0:
                raise ValueError("HEX字符串长度必须为偶数")
            command_bytes = bytes.fromhex(hex_string)

            with socket.socket(socket.AF_INET, socket.SOCK_DGRAM) as sock:
                sock.sendto(command_bytes, (ip, port))
            print(f"[Q1-Send] 已发送 HEX: {hex_string.upper()} 至 {ip}:{port}")
            messagebox.showinfo("成功", f"数据已发送至 {ip}:{port}")

        except ValueError as e:
            messagebox.showerror("输入错误", f"无效的输入: {e}")
            print(f"[Q1-错误] 输入格式错误: {e}")
        except Exception as e:
            messagebox.showerror("发送失败", f"向FPGA发送指令失败: {e}")
            print(f"[Q1-错误] 发送指令失败: {e}")

    def select_and_send_image(self):
        filepath = filedialog.askopenfilename(
            title="选择一张640x480的图片",
            filetypes=[("Image Files", "*.png *.jpg *.jpeg *.bmp"), ("All files", "*.*")]
        )
        if not filepath:
            self.q2_status_label.config(text="操作已取消")
            return
        threading.Thread(target=self._send_image_thread, args=(filepath,), daemon=True).start()

    def _send_image_thread(self, filepath):
        try:
            fpga_ip = self.q2_fpga_ip_var.get()
            fpga_port = int(self.q2_fpga_port_var.get())
            self.q2_status_label.config(text=f"正在打开: {filepath.split('/')[-1]}")
            print(f"[Q2] 准备发送图片: {filepath}")
            img = Image.open(filepath).convert('RGB')
            if img.size != (IMG_WIDTH, IMG_HEIGHT):
                messagebox.showerror("尺寸错误", f"图片尺寸必须为 {IMG_WIDTH}x{IMG_HEIGHT}，当前为 {img.size[0]}x{img.size[1]}")
                self.q2_status_label.config(text="尺寸错误，请重新选择")
                print(f"[Q2-错误] 图片尺寸不匹配")
                return
            pixel_data = img.tobytes()
            with socket.socket(socket.AF_INET, socket.SOCK_DGRAM) as sock:
                total_bytes = len(pixel_data)
                bytes_sent = 0
                while bytes_sent < total_bytes:
                    chunk = pixel_data[bytes_sent: bytes_sent + SENDER_PACKET_SIZE]
                    sock.sendto(chunk, (fpga_ip, fpga_port))
                    bytes_sent += len(chunk)
                    progress = (bytes_sent / total_bytes) * 100
                    self.q2_status_label.config(text=f"正在发送... {progress:.1f}%")
            messagebox.showinfo("成功", "图片数据发送完成！")
            self.q2_status_label.config(text="发送完成！可选择下一张图片。")
            print(f"[Q2] 图片发送成功至 {fpga_ip}:{fpga_port}")
        except Exception as e:
            messagebox.showerror("错误", f"发生错误: {e}")
            self.q2_status_label.config(text=f"错误: {e}")
            print(f"[Q2-错误] {e}")

    def start_receiving(self, ip, port, mode):
        if self.is_receiving:
            if self.current_mode != mode:
                messagebox.showwarning("警告", f"请先停止 {self.current_mode.upper()} 标签页的接收任务。")
            else:
                messagebox.showwarning("警告", "接收器已在运行中。")
            return

        if self.current_mode is not None:
            messagebox.showwarning("警告", f"请先停止 {self.current_mode.upper()} 标签页的接收任务。")
            return

        self.is_receiving = True
        self.current_mode = mode
        self.frame_packets.clear()
        while not self.packet_queue.empty():
            self.packet_queue.get()
        self.receiver_thread = UDPReceiverThread(ip, port, self.packet_queue, self.log)
        self.receiver_thread.start()
        buttons = self.receiver_buttons[self.current_mode]
        buttons['start'].config(state="disabled")
        buttons['stop'].config(state="normal")
        if 'save' in buttons:
            buttons['save'].config(state="normal")
        win_title = self.get_cv_win_title()
        cv2.namedWindow(win_title, cv2.WINDOW_NORMAL)
        cv2.resizeWindow(win_title, IMG_WIDTH, IMG_HEIGHT)



        self.root.after(20, self.process_packets_and_display)

    def stop_receiving(self, from_button=False):
        if not self.is_receiving:
            return
        if from_button:
            print(f"[{self.current_mode.upper()}] 用户点击'停止接收'按钮。")

        buttons = self.receiver_buttons[self.current_mode]

        self.is_receiving = False
        if self.receiver_thread:
            self.receiver_thread.stop()
            self.receiver_thread.join(timeout=1.5)
        cv2.destroyAllWindows()


        buttons['start'].config(state="normal")
        buttons['stop'].config(state="disabled")
        if 'save' in buttons:
            buttons['save'].config(state="disabled")
        self.current_mode = None

    def process_packets_and_display(self):
        if not self.is_receiving:
            return
        try:
            if cv2.getWindowProperty(self.get_cv_win_title(), cv2.WND_PROP_VISIBLE) < 1:
                print(f"[{self.current_mode.upper()}] 检测到显示窗口已关闭，自动停止接收。")
                self.stop_receiving(from_button=False)
                return
        except cv2.error:
            if self.is_receiving:
                self.stop_receiving(from_button=False)
            return
        try:
            while not self.packet_queue.empty():
                packet = self.packet_queue.get_nowait()
                self._handle_packet(packet)
        except queue.Empty:
            pass
        if self.current_frame_seq != -1 and time.time() - self.last_packet_time > FRAME_TIMEOUT:
            print(f"超时: 帧 {self.current_frame_seq} 未收完，已丢弃。")
            self.frame_packets.clear()
            self.current_frame_seq = -1
        cv2.waitKey(1)
        self.root.after(20, self.process_packets_and_display)

    def _handle_packet(self, packet):
        try:
            if len(packet) < PACKET_HEADER_SIZE: return
            header = struct.unpack("<8I", packet[:PACKET_HEADER_SIZE])
            if header[0] != 0xAA0055FF: return
            frame_seq, packet_seq = header[5], header[6]
        except (struct.error, IndexError):
            return

        if frame_seq != self.current_frame_seq:
            if self.current_frame_seq != -1 and len(self.frame_packets) < TOTAL_PACKETS_PER_FRAME:
                print(f"警告: 帧 {self.current_frame_seq} 未收完 (仅{len(self.frame_packets)}包)，已丢弃。")
            self.current_frame_seq = frame_seq
            self.frame_packets.clear()
        self.frame_packets[packet_seq] = packet[PACKET_HEADER_SIZE:]
        self.last_packet_time = time.time()
        if len(self.frame_packets) == TOTAL_PACKETS_PER_FRAME:
            self._assemble_and_display_frame()
            self.frame_packets.clear()
            self.current_frame_seq = -1

    def _assemble_and_display_frame(self):
        # 打印收到的包序号集合，检查是否有缺失
        received_keys = sorted(self.frame_packets.keys())
        # 如果 received_keys 不是 0 到 1449 的完整序列，这里会打印错误
        if len(received_keys) != TOTAL_PACKETS_PER_FRAME:
            print(f"DEBUG: 缺包！只收到了 {len(received_keys)} 个包")
        full_frame_data = bytearray()
        for i in range(TOTAL_PACKETS_PER_FRAME):
            full_frame_data.extend(self.frame_packets.get(i, b''))
        expected_size = IMG_HEIGHT * IMG_WIDTH * 3
        if len(full_frame_data) < expected_size:
            print(f"错误：数据不完整，期望 {expected_size} 字节，实际 {len(full_frame_data)}")
            return
        final_data = full_frame_data[:expected_size]
        try:
            bgr_frame = np.frombuffer(final_data, dtype=np.uint8).reshape((IMG_HEIGHT, IMG_WIDTH, 3))

            # Q5 改为和 Q4 完全相同的显示逻辑
            display_frame = bgr_frame.copy()

            if self.current_mode == 'q3':
                display_frame = cv2.flip(bgr_frame, 0)
                self.latest_frame_for_saving = display_frame.copy()

            elif self.current_mode == 'q4' or self.current_mode == 'q5':
                # Q5 现在和 Q4 一样，只显示FPS，没有运动检测
                self.fps_frame_count += 1
                elapsed = time.time() - self.last_fps_time
                if elapsed >= 1.0:
                    self.fps = self.fps_frame_count / elapsed
                    self.last_fps_time = time.time()
                    self.fps_frame_count = 0
                fps_text = f"FPS: {self.fps:.1f}"
                cv2.putText(display_frame, fps_text, (10, 30), cv2.FONT_HERSHEY_SIMPLEX, 0.7, (0, 255, 0), 2)

            cv2.imshow(self.get_cv_win_title(), display_frame)

        except Exception as e:
            print(f"图像处理错误: {e}")



    def save_current_frame(self):
        if self.latest_frame_for_saving is None:
            messagebox.showwarning("保存失败", "当前没有有效的图像帧可以保存。")
            print("[Q3-警告] 保存失败，无可用帧。")
            return
        try:
            filepath = filedialog.asksaveasfilename(
                title="保存图像",
                defaultextension=".png",
                filetypes=[("PNG Image", "*.png"), ("JPEG Image", "*.jpg"), ("Bitmap Image", "*.bmp")],
                initialfile=f"capture_{int(time.time())}.png"
            )
            if not filepath:
                print("[Q3] 保存操作已取消。")
                return
            cv2.imwrite(filepath, self.latest_frame_for_saving)
            print(f"[Q3] 图像成功保存至: {filepath}")
            messagebox.showinfo("成功", f"图像已保存至:\n{filepath}")
        except Exception as e:
            print(f"[Q3-错误] 保存图像时发生错误: {e}")
            messagebox.showerror("保存失败", f"保存图像时出错:\n{e}")

    def get_cv_win_title(self):
        if self.current_mode == 'q3':
            return "FPGA Image Receiver (Q3: Save Frame)"
        elif self.current_mode == 'q4':
            return "FPGA Video Stream (Q4: Real-time)"
        elif self.current_mode == 'q5':
            return "FPGA Video Stream (Q5: Motion Detection)"  # 保留窗口标题
        else:
            return "FPGA Receiver"

    def log(self, message):
        print(message)

    def on_closing(self):
        if hasattr(self, 'is_q1_listening') and self.is_q1_listening:
            self.q1_listener_thread.stop()
        if self.is_receiving:
            self.stop_receiving(from_button=False)
        self.root.destroy()


# ============================================================================
# 程序入口
# ============================================================================
if __name__ == "__main__":
    root = Tk()
    app = IntegratedApp(root)
    root.mainloop()