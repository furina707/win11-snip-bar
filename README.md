# win11-snip-bar

> Windows 11 风格的 Wayland 原生顶部悬浮截图与录屏工具栏，专为 Niri 及现代 Wayland 桌面打造。  
> Windows 11 style floating snipping & screen recording pill bar for Wayland (specifically tailored for Niri).

[English](#features) | [中文说明](#特性亮点)

---

## 特性亮点 / Features

- 🪟 **Win11 亚克力悬浮药丸栏 (Fluent Acrylic Pill)**  
  基于 GTK4 + GTK4 Layer Shell 的顶层浮动药丸设计，支持深色亚克力磨砂、悬停缩放与圆角阴影。
- ⚡ **原生 C 语言编译，极致低延迟 (< 1ms)**  
  完全摆脱庞大的 Python GObject 依赖，按快捷键瞬间响应，毫秒级弹出。
- 🗔 **智能窗口悬停高亮与边框提升 (Window Hover Elevation)**  
  对接 Niri IPC 动态解析各窗口坐标，鼠标移动时窗口即时呈现 **3px 微软亮蓝提升边框** 与淡蓝半透明选区高亮；**若当前工作区无窗口，自动无缝回退全屏截图**。
- ⛶ **多种截图模式**  
  支持自由矩形框选 (`slurp` + `grim`)、窗口选取、全屏直截。
- 📹 **选区录屏与状态切换**  
  原生集成 `wf-recorder`，框选区域即刻录制，按钮动态切换为 `⏹ 停止录屏`，录制结束自动保存至 `~/Videos/Captures/`。
- ✏️ **剪贴板自动复制与 Satty 批注**  
  截图完成后立即写入系统剪贴板 (`wl-copy`)，并通过桌面通知提供 “✏️ 标注编辑” 快捷操作（无缝唤起 Satty 批注箭头、文字、矩形与打码）。

---

## 依赖要求 / Dependencies

### 基础依赖 (Arch Linux)

```bash
sudo pacman -S gcc pkg-config gtk4 gtk4-layer-shell grim slurp wl-clipboard libnotify wf-recorder
```

### 推荐批注工具 (可选)

推荐安装现代批注工具 [`satty`](https://github.com/gabm/satty)：

```bash
cargo install satty --locked
# 或 AUR: paru -S satty
```

---

## 安装与构建 / Installation

克隆本项目并运行安装脚本：

```bash
git clone https://github.com/furina707/win11-snip-bar.git
cd win11-snip-bar
make install
```

默认将二进制安装至 `~/.local/bin/win11-snip-bar`，助手脚本安装至 `~/.local/lib/win11-snip-bar/`。

---

## 快捷键绑定 (Niri) / Keybindings

在你的 `~/.config/niri/config.kdl` 中添加：

```kdl
binds {
    // Windows 11 经典快捷键 Win + Shift + S
    Mod+Shift+S hotkey-overlay-title="Win11 截图栏" { spawn "win11-snip-bar"; }

    // PrintScreen 键
    Print hotkey-overlay-title="Win11 截图栏" { spawn "win11-snip-bar"; }

    // 亦支持直接传入参数（不打开工具栏直接触发）
    // Mod+Alt+S { spawn "win11-snip-bar" "--window"; }
    // Ctrl+Print { spawn "win11-snip-bar" "--full"; }
}
```

保存后执行重载：

```bash
niri msg action load-config-file
```

---

## 命令行用法 / CLI Usage

```bash
win11-snip-bar          # 唤出顶部悬浮工具条 (按 Esc 或点击 ✕ 可退出)
win11-snip-bar --rect   # 直接进入矩形区域截图
win11-snip-bar --window # 直接进入窗口高亮选取截图 (无窗口时自动全屏)
win11-snip-bar --full   # 直接全屏截图
win11-snip-bar --record # 触发区域录屏开关
```

---

## 许可证 / License

[MIT License](LICENSE) © 2026 furina707
