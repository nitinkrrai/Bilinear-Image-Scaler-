# Bilinear-Image-Scaler-
Hardware-efficient Bilinear Image Scaler for FPGA deployment. Utilizes Q8.8 fixed-point arithmetic and DSP48 slices for parallel RGB processing without floating-point overhead.
# FPGA-Based High-Performance Bilinear Image Scaler 🚀


## 📌 Overview
This repository contains the RTL source code, verification environment, and Python reference models for a high-performance, hardware-efficient **Bilinear Interpolation Image Scaler**. Designed from the ground up for FPGA deployment, this core scales images in real-time without relying on external memory buffers or slow Finite State Machine (FSM) control logic. 

It is completely **parameterized**, allowing developers to set custom input and output resolutions at compile time, making it highly adaptable for embedded vision systems, display controllers, and real-time video processing pipelines.

## ✨ Key Features
* **Fully Parameterized Resolutions:** Easily scale any input resolution to any output resolution by modifying top-level Verilog parameters.
* **5-Stage Pipelined Datapath:** Achieves continuous data flow. By utilizing a widened 24-bit memory architecture for packed RGB data, the design eliminates standard FSM bottlenecks.
* **Floating-Point Elimination (Q8.8):** Utilizes **Q8.8 fixed-point arithmetic** and intelligent bit-shift operations, completely bypassing the need for costly DSP floating-point units and division logic.
* **Parallel DSP Processing:** Integrates a custom DSP core utilizing Xilinx **DSP48 slices** to process Red, Green, and Blue (RGB) channels simultaneously using pre-calculated bilinear weights.
* **Massive Throughput:** Sustains a processing rate of **1 pixel per clock cycle**.

## 📊 Performance & Verification Metrics
| Metric | Result |
| :--- | :--- |
| **Max Clock Frequency** | 160 MHz |
| **Processing Throughput** | 160 Megapixels / second |
| **Pixels Per Clock (PPC)** | 1 |
| **Verification SSIM** | 1.0000 (Near-perfect structural similarity) |
| **Verification PSNR** | 49.03 dB |

## 🏗️ Architecture Breakdown
The core is built around a custom **5-stage pipeline** to ensure data is processed efficiently:
1. **Coordinate Calculation:** Maps the target output pixel coordinates back to the source image grid.
2. **Weight Generation:** Calculates the fractional weights (dx, dy) for the four nearest neighbor pixels using Q8.8 fixed-point math.
3. **Memory Fetch:** Retrieves the packed 24-bit RGB values of the four adjacent pixels from Block RAM (BRAM).
4. **Parallel MAC (Multiply-Accumulate):
