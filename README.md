# 敏捷训练计时器 (Agility Timer)

一款面向体育敏捷性训练的计时器 App，结合节拍器与随机变向信号，帮助运动员进行反应速度与变向训练。

## 功能

- **节拍器**：40-500 BPM 可调节，带 +1/+10/-1/-10 快捷按钮
- **随机变向信号**：在指定拍数间隔内随机发出方向指令（前/后/左/右）
- **多种训练模式**：
  - 自由模式 - 不限时训练
  - 定时模式 - 到时自动结束
  - 递增模式 - BPM 逐渐加快
  - 间歇模式 - 训练/休息交替，可设组数
- **随机变速**：BPM 在设定范围内随机波动
- **提示音选项**：标准提示音 / 方向音调
- **训练统计**：训练结束后显示时间、变向次数、平均 BPM

## 技术栈

- **框架**：Flutter 3.x
- **音频**：audioplayers
- **本地存储**：sqflite
- **支持平台**：Android

## 安装

从 [Releases](../../releases) 页面下载 APK 安装到 Android 手机。

或自行构建：

```bash
git clone https://github.com/ph4ble/agility-timer.git
cd agility-timer
flutter pub get
flutter build apk --release
```

## 版本

- **V0.1** - 初始版本，包含全部核心功能

## 许可

MIT License
