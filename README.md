# 🏆 FPGA Ethernet Transmission System - National First Prize Project

2025 年全国大学生嵌入式芯片与系统设计竞赛安路 FPGA 赛题国家级一等奖作品开源。

本项目基于安路 HX4S20C 开发板，完成了主板、副板和 PC 上位机之间的 UDP 通信，并实现 TF 卡图片读取、OV5640 摄像头采集、SDRAM 帧缓存、FPGA 实时图像处理、千兆以太网传输和 HDMI 显示。

## 1. 项目功能

系统主要包含三类设备：

```text
主板 Main
副板 Secondary
PC Python 上位机
```

主要功能包括：

* 副板通过 UDP 向主板发送 LED、数码管控制指令；
* 副板从 TF 卡读取图片，并通过 UDP 发送到主板；
* 主板接收图像后写入 SDRAM，并通过 HDMI 显示；
* 主板读取 TF 卡图片，通过 UDP 发送到 PC；
* 主板采集 OV5640 摄像头图像，通过 UDP 实时发送到 PC；
* 摄像头图像可在 FPGA 中进行多种实时图像处理；
* PC 上位机支持发送图片、接收图像、实时显示和保存图像。

---

## 2. 主板与副板交互

主板和副板通过 RGMII 千兆以太网连接，使用 UDP 协议传输控制命令和图像数据。

### 2.1 控制命令传输

```text
副板按键
   ↓
UDP 控制命令
   ↓
主板 UDP 接收
   ↓
LED / 数码管显示
```

### 2.2 TF 卡图片传输

```text
副板 TF 卡
   ↓
图片读取
   ↓
SDRAM 缓存
   ↓
UDP 发送
   ↓
主板 UDP 接收
   ↓
SDRAM 缓存
   ↓
HDMI 显示
```

### 2.3 主板与 PC 交互

```text
主板 TF 卡或 OV5640 摄像头
   ↓
SDRAM 帧缓存
   ↓
FPGA 图像处理
   ↓
UDP 图像分包
   ↓
PC 上位机接收与显示
```

PC 也可以通过 UDP 向 FPGA 发送一张 640×480 图片，再由 FPGA 写入 SDRAM并通过 HDMI 显示。

---

## 3. 主板工作模式

主板最终顶层文件为：

```text
Main/q3q4/top_dual_udp.v
```

通过两个拨码开关选择工作模式：

| mode_sw_1 | mode_sw_0 | 工作模式                         |
| --------: | --------: | ---------------------------- |
|         0 |         0 | TF 卡 → SDRAM → UDP 发送        |
|         0 |         1 | 摄像头 → SDRAM → 图像处理 → UDP 发送  |
|         1 |         0 | UDP 接收 → SDRAM → HDMI/LED 显示 |
|         1 |         1 | 保留模式                         |

主板相关按键：

| 按键     | 功能            |
| ------ | ------------- |
| `key1` | 系统复位          |
| `key2` | 触发 TF 卡图片读取   |
| `key3` | 调节当前图像处理模式的参数 |
| `key4` | 切换图像处理模式      |

亮度和饱和度模式下，可使用 `key3` 调节参数。

---

## 4. FPGA 图像处理功能

摄像头模式支持以下图像处理效果：

1. 原始 RGB 图像
2. 灰度化
3. 二值化
4. 颜色反相
5. 红色通道提取
6. 色彩量化
7. 复古色 Sepia
8. 亮度调节
9. 饱和度调节
10. Sobel 边缘检测
11. Sobel 反相
12. 浮雕效果
13. 热力图
14. 腐蚀
15. 膨胀
16. 形态学边缘提取

其中 Sobel、浮雕、腐蚀和膨胀等处理使用行缓存构建邻域窗口，其余部分主要采用像素流流水线处理。

核心图像处理和 UDP 发送控制代码位于：

```text
Main/q3q4/import/udp_cam_ctrl.v
```

---

## 5. 开发环境

### FPGA 环境

```text
开发板：安路 HX4S20C
FPGA：EG4S20BG256
开发工具：Anlogic TD 6.2
硬件语言：Verilog HDL
摄像头：OV5640
网络接口：RGMII 千兆以太网
视频输出：HDMI
外部存储：SDRAM、TF/SD 卡
```

### PC 上位机环境

```text
Python 3
OpenCV
NumPy
Pillow
Tkinter
Socket
Threading
Queue
```

---

## 6. 仓库目录

```text
FPGA-ANLU-National-First-Prize
│
├─ Main
│  ├─ q3q4
│  │  ├─ q4.al
│  │  ├─ top_dual_udp.v
│  │  ├─ src
│  │  └─ import
│  └─ line_ram_640x8.v
│
├─ Secondary
│  ├─ prj
│  │  └─ UDP_EXAMPLE
│  └─ al_ip
│
├─ lab_ex_4_tf_sdram_etnernet_pc
│  └─ TF 卡、SDRAM 和以太网基础工程
│
├─ lab_ex_6_tf_sdram_hdmi
│  └─ TF 卡、SDRAM 和 HDMI 基础工程
│
├─ Host computer.py
│  └─ Python 综合上位机
│
├─ 赛题 PPT
├─ 经验分享 PPT
└─ README.md
```

主要目录说明：

* `Main`：主板工程和最终整合代码；
* `Secondary`：副板工程；
* `src`：主要源代码；
* `import`：导入工程的 Verilog 文件和 IP 核；
* `lab_ex_4`、`lab_ex_6`：比赛开发过程中使用的基础实验工程；
* `Host computer.py`：PC 综合上位机。

---

## 7. FPGA 工程入口

### 7.1 主板

使用 Anlogic TD 6.2 打开：

```text
Main/q3q4/q4.al
```

最终顶层模块：

```text
top_dual_udp
```

顶层文件：

```text
Main/q3q4/top_dual_udp.v
```

### 7.2 副板

使用 Anlogic TD 6.2 打开：

```text
Secondary/prj/UDP_EXAMPLE/UDP_EXAMPLE.al
```

副板主要顶层文件：

```text
Secondary/prj/UDP_EXAMPLE/import/UDP_Example_Top.v
```

副板主要完成：

* LED 和数码管控制命令发送；
* TF 卡图片读取；
* SDRAM 图片缓存；
* UDP 图片发送；
* 与主板进行点对点以太网通信。

---

## 8. IP 核和缺失文件处理

由于不同电脑中的工程路径不同，打开工程时可能提示找不到部分 IP 核或 `.v` 文件。

可以优先在以下目录查找：

```text
Main/q3q4/import
Main/q3q4/src
Main
Secondary/al_ip
Secondary/prj/UDP_EXAMPLE/import
lab_ex_4_tf_sdram_etnernet_pc
lab_ex_6_tf_sdram_hdmi
```

行缓存 IP 位于：

```text
Main/line_ram_640x8.v
Main/line_ram_640x8_1.v
```

如果 TD 无法自动识别文件，可以通过工程的 `Add Source` 或 `Add Existing File` 功能重新导入。

PLL、FIFO、SDRAM 和行缓存等 IP 核在不同 TD 环境下可能需要重新生成。

---

## 9. 网络配置

### 9.1 主板与副板连接

推荐配置：

```text
主板 IP：192.168.240.1
副板 IP：192.168.240.2
子网掩码：255.255.255.0
```

主板和副板通过网线直接连接，或者连接到同一个千兆交换机。

### 9.2 主板与 PC 连接

推荐配置：

```text
FPGA IP：192.168.240.1
PC IP：192.168.240.2
子网掩码：255.255.255.0
```

在 Windows 中，需要手动设置有线网卡 IPv4 地址。

注意：副板和 PC 默认都可能使用 `192.168.240.2`。进行 PC 调试时，不要让副板和 PC 同时使用相同 IP 地址。

不同实验工程中的 IP 地址和 UDP 端口可能存在差异，使用前请检查：

```text
Main/q3q4/top_dual_udp.v
Secondary/prj/UDP_EXAMPLE/import/UDP_Example_Top.v
Host computer.py
```

确保发送端的目标 IP、目标端口和接收端配置一致。

---

## 10. Python 上位机运行

上位机文件：

```text
Host computer.py
```

安装依赖：

```bash
pip install numpy opencv-python pillow
```

运行上位机：

```bash
python "Host computer.py"
```

上位机主要包含以下功能：

1. PC 控制 FPGA 的 LED 和数码管；
2. PC 向 FPGA 发送 640×480 静态图片；
3. 接收并保存 FPGA 发送的图片；
4. 实时显示摄像头视频和 FPGA 图像处理结果；
5. 显示接收帧率 FPS。

Tkinter 通常随 Python 一起安装。如果系统提示缺少 Tkinter，需要单独安装对应组件。

---

## 11. 图像传输格式

默认图像格式：

```text
分辨率：640 × 480
颜色格式：RGB888
单帧大小：640 × 480 × 3 = 921600 Bytes
```

FPGA 会将一帧图像拆分成多个 UDP 数据包发送。

每个数据包包含一个自定义包头，主要记录：

* 图像标识；
* 图像宽度和高度；
* 当前帧编号；
* 当前数据包编号；
* 图像数据偏移量；
* 数据包有效长度。

PC 上位机根据帧编号和包编号重新组装完整图像。如果一帧发生丢包或接收超时，上位机会丢弃当前不完整帧。

---

## 12. 快速上手

### 场景一：主板摄像头发送到 PC

1. 使用 TD 6.2 打开主板工程；
2. 确认顶层为 `top_dual_udp`；
3. 综合、布局布线并下载到主板；
4. 将模式开关设置为 `01`；
5. 连接 OV5640 摄像头；
6. 将 PC 网卡设置为 `192.168.240.2`；
7. 使用网线连接主板和 PC；
8. 运行 `Host computer.py`；
9. 打开实时视频接收页面；
10. 使用 `key4` 切换图像效果。

### 场景二：主板 TF 卡图片发送到 PC

1. 将符合要求的 BMP 图片放入 TF 卡；
2. 将 TF 卡插入主板；
3. 将模式开关设置为 `00`；
4. 启动 PC 上位机接收；
5. 按下 `key2` 触发图片读取和发送。

### 场景三：副板图片发送到主板 HDMI

1. 分别下载主板和副板工程；
2. 设置主板 IP 为 `192.168.240.1`；
3. 设置副板 IP 为 `192.168.240.2`；
4. 使用网线连接两块板卡；
5. 将主板模式设置为 `10`；
6. 将显示器连接到主板 HDMI 接口；
7. 将 TF 卡插入副板；
8. 使用副板按键触发图片读取和发送；
9. 主板接收图片并通过 HDMI 显示。

---

## 13. 当前说明

本仓库保留了比赛期间的主板、副板、基础实验和部分中间工程，因此存在以下情况：

* 部分模块在不同目录中重复；
* 部分路径仍保留原开发电脑的路径信息；
* 不同实验工程的 IP 地址和 UDP 端口不完全相同；
* 部分 IP 核可能需要重新导入或重新生成；
* 当前上位机第五个页面暂时与实时视频显示逻辑相同，尚未完整启用运动检测；
* 后续将继续整理目录和补充实物接线说明。

建议初次使用时优先从以下两个工程开始：

```text
主板：Main/q3q4/q4.al
副板：Secondary/prj/UDP_EXAMPLE/UDP_EXAMPLE.al
```

---

## 14. 参考链接

Verilog 能力测评参考：

[全国大学生嵌入式芯片与系统设计竞赛 FPGA 赛道 Verilog 能力测评](https://github.com/MrYanYe/NUECSDC_FPGA_National_Competition_Verilog_Skills_Test_V1.git)

---

## 15. 联系方式

如有问题，可以提交 GitHub Issue。

微信：

```text
thisismjxswechat
```

欢迎学习、交流和改进。
