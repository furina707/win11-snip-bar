#!/usr/bin/env bash
set -e

ACTION="${1:-rect}"
SAVE_DIR="${XDG_PICTURES_DIR:-$HOME/Pictures}/Screenshots"
mkdir -p "$SAVE_DIR"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Resolve path to niri-get-window-boxes.py
BOXES_SCRIPT=""
if [ -x "$SCRIPT_DIR/niri-get-window-boxes.py" ]; then
    BOXES_SCRIPT="$SCRIPT_DIR/niri-get-window-boxes.py"
elif [ -x "$HOME/.local/lib/niri-get-window-boxes.py" ]; then
    BOXES_SCRIPT="$HOME/.local/lib/niri-get-window-boxes.py"
elif [ -x "$HOME/.local/lib/win11-snip-bar/niri-get-window-boxes.py" ]; then
    BOXES_SCRIPT="$HOME/.local/lib/win11-snip-bar/niri-get-window-boxes.py"
elif command -v niri-get-window-boxes.py >/dev/null 2>&1; then
    BOXES_SCRIPT="niri-get-window-boxes.py"
fi

notify_screenshot() {
    local file="$1"
    local title="${2:-截图已复制到剪贴板}"
    [ -f "$file" ] || return 0
    # Copy to clipboard
    wl-copy < "$file"
    
    # Notify with action
    local action_res
    action_res=$(notify-send -a "截图工具" -i "$file" "$title" "可直接 Ctrl+V 粘贴，或点击进行标注" -t 4000 --action="edit=✏️ 标注编辑" 2>/dev/null || true)
    if [ "$action_res" = "edit" ]; then
        if command -v satty >/dev/null 2>&1; then
            satty -f "$file" --early-exit copy &
        elif command -v loupe >/dev/null 2>&1; then
            loupe "$file" &
        else
            xdg-open "$file" &
        fi
    fi
}

case "$ACTION" in
    rect)
        FILE="$SAVE_DIR/Screenshot_$(date +%Y-%m-%d_%H-%M-%S).png"
        GEO=$(slurp -b '#00000045' -c '#0078d4' -s '#0078d428' -w 2 2>/dev/null || true)
        [ -n "$GEO" ] || exit 0
        grim -g "$GEO" "$FILE"
        notify_screenshot "$FILE"
        ;;
    window)
        FILE="$SAVE_DIR/Screenshot_$(date +%Y-%m-%d_%H-%M-%S).png"
        BOXES=""
        if [ -n "$BOXES_SCRIPT" ]; then
            BOXES=$("$BOXES_SCRIPT" 2>/dev/null || true)
        fi

        if [ -n "$BOXES" ]; then
            GEO=$(echo "$BOXES" | slurp -r -b '#00000045' -B '#ffffff18' -c '#0078d4' -s '#0078d428' -w 3 2>/dev/null || true)
            if [ -n "$GEO" ]; then
                grim -g "$GEO" "$FILE"
                notify_screenshot "$FILE"
                exit 0
            else
                # 用户主动按 Esc 取消
                exit 0
            fi
        else
            # 当前没有检测到任何打开的窗口，自动回退截取全屏
            grim "$FILE"
            notify_screenshot "$FILE" "全屏截图已复制（当前无可见窗口）"
            exit 0
        fi
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
        GEO=$(slurp -b '#00000066' -c '#ff5555' -w 2 2>/dev/null || true)
        [ -n "$GEO" ] || exit 0
        wf-recorder -g "$GEO" -f "$REC_FILE" &
        notify-send -a "屏幕录制" "已开始录屏" "录制完成后再次点击截图栏录屏按钮即可结束" -t 3000
        ;;
esac
