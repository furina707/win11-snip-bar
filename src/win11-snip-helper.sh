#!/usr/bin/env bash
set -e
export PATH="$HOME/.local/bin:$HOME/.cargo/bin:$PATH"

ACTION="${1:-rect}"
SAVE_DIR="${XDG_PICTURES_DIR:-$HOME/Pictures}/Screenshots"
mkdir -p "$SAVE_DIR"

notify_screenshot() {
    local file="$1"
    local title="${2:-截图已复制到剪贴板}"
    [ -f "$file" ] || return 0
    # 立即复制到剪贴板，零延迟响应
    wl-copy < "$file"
    
    # 异步弹出通知与标注入口，绝不阻塞截图主流程
    (
        local action_res
        action_res=$(notify-send -a "截图工具" -i "$file" "$title" "已保存至相册，可直接 Ctrl+V 粘贴" -t 3500 --action="edit=✏️ 标注编辑" 2>/dev/null || true)
        if [ "$action_res" = "edit" ]; then
            if command -v satty >/dev/null 2>&1; then
                satty -f "$file" --early-exit copy &
            elif command -v loupe >/dev/null 2>&1; then
                loupe "$file" &
            else
                xdg-open "$file" &
            fi
        fi
    ) &
}

case "$ACTION" in
    rect)
        FILE="$SAVE_DIR/Screenshot_$(date +%Y-%m-%d_%H-%M-%S).png"
        FREEZE_PID=""
        if command -v wayfreeze >/dev/null 2>&1; then
            wayfreeze --hide-cursor &
            FREEZE_PID=$!
            trap '[ -n "$FREEZE_PID" ] && kill "$FREEZE_PID" 2>/dev/null || true' EXIT INT TERM
            sleep 0.02
        fi
        GEO=$(slurp -b '#00000045' -c '#0078d4' -s '#0078d428' -w 2 2>/dev/null || true)
        if [ -n "$FREEZE_PID" ]; then
            kill "$FREEZE_PID" 2>/dev/null || true
            FREEZE_PID=""
        fi
        [ -n "$GEO" ] || exit 0
        grim -l 1 -g "$GEO" "$FILE"
        notify_screenshot "$FILE"
        ;;
    delay)
        notify-send -a "截图工具" -t 3000 "⏱ 3秒延时截图已启动" "请在 3 秒内打开并悬停目标二级/右键菜单..."
        sleep 3
        canberra-gtk-play -i camera-shutter 2>/dev/null || true
        FILE="$SAVE_DIR/Screenshot_$(date +%Y-%m-%d_%H-%M-%S).png"
        FREEZE_PID=""
        if command -v wayfreeze >/dev/null 2>&1; then
            wayfreeze --hide-cursor &
            FREEZE_PID=$!
            trap '[ -n "$FREEZE_PID" ] && kill "$FREEZE_PID" 2>/dev/null || true' EXIT INT TERM
            sleep 0.02
        fi
        GEO=$(slurp -b '#00000045' -c '#0078d4' -s '#0078d428' -w 2 2>/dev/null || true)
        if [ -n "$FREEZE_PID" ]; then
            kill "$FREEZE_PID" 2>/dev/null || true
            FREEZE_PID=""
        fi
        [ -n "$GEO" ] || exit 0
        grim -l 1 -g "$GEO" "$FILE"
        notify_screenshot "$FILE"
        ;;
    window)
        FILE="$SAVE_DIR/Screenshot_$(date +%Y-%m-%d_%H-%M-%S).png"

        # 发送提示：鼠标已进入窗口点选模式
        notify-send -a "截图工具" -t 2500 "🗔 请点击目标窗口进行截取" "十字准星已激活，按 Esc 或右键可取消" 2>/dev/null || true

        # 通过虚拟终端 PTY 唤起 Niri 原生 pick-window
        # 避免无终端环境时被检测到 stdin EOF 导致瞬间判定截取当前焦点窗口
        WIN_INFO=$(python3 -c '
import pty, os, subprocess, sys
try:
    master, slave = pty.openpty()
    p = subprocess.Popen(["niri", "msg", "-j", "pick-window"], stdin=slave, stdout=subprocess.PIPE, stderr=subprocess.PIPE, close_fds=True)
    os.close(slave)
    out, _ = p.communicate()
    os.close(master)
    if p.returncode == 0 and out:
        sys.stdout.buffer.write(out)
except Exception:
    pass
' 2>/dev/null || true)

        if [ -n "$WIN_INFO" ]; then
            WIN_ID=$(echo "$WIN_INFO" | grep -oP '"id":\s*\K[0-9]+' | head -n 1)
            if [ -n "$WIN_ID" ]; then
                niri msg action screenshot-window --id "$WIN_ID" --write-to-disk true --path "$FILE"
                notify_screenshot "$FILE"
                exit 0
            fi
        fi
        exit 0
        ;;
    full)
        FILE="$SAVE_DIR/Screenshot_$(date +%Y-%m-%d_%H-%M-%S).png"
        grim "$FILE"
        notify_screenshot "$FILE"
        ;;
    record)
        if pgrep -x wf-recorder >/dev/null 2>&1; then
            killall -SIGINT wf-recorder
            notify-send -a "屏幕录制" "录制已完成并保存" "已保存至视频目录 ~/Videos/Captures" -t 3000
            exit 0
        fi
        REC_DIR="${XDG_VIDEOS_DIR:-$HOME/Videos}/Captures"
        mkdir -p "$REC_DIR"
        REC_FILE="$REC_DIR/Recording_$(date +%Y-%m-%d_%H-%M-%S).mp4"
        FREEZE_PID=""
        if command -v wayfreeze >/dev/null 2>&1; then
            wayfreeze &
            FREEZE_PID=$!
            trap '[ -n "$FREEZE_PID" ] && kill "$FREEZE_PID" 2>/dev/null || true' EXIT INT TERM
            sleep 0.05
        fi
        GEO=$(slurp -b '#00000066' -c '#ff5555' -w 2 2>/dev/null || true)
        if [ -n "$FREEZE_PID" ]; then
            kill "$FREEZE_PID" 2>/dev/null || true
            FREEZE_PID=""
        fi
        [ -n "$GEO" ] || exit 0
        wf-recorder -g "$GEO" -f "$REC_FILE" &
        # 启动 Windows 11 同款顶部悬浮录屏计时与停止控制器
        win11-snip-bar --rec-bar &
        ;;
esac
