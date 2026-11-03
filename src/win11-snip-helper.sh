#!/usr/bin/env bash
set -e

ACTION="${1:-rect}"
SAVE_DIR="${XDG_PICTURES_DIR:-$HOME/Pictures}/Screenshots"
mkdir -p "$SAVE_DIR"

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

        # 检查当前活动工作区是否存在可见窗口
        WIN_COUNT=$(python3 -c '
import json, subprocess
try:
    ws = json.loads(subprocess.check_output(["niri", "msg", "-j", "workspaces"]))
    f_ws = next((w["id"] for w in ws if w.get("is_focused") or w.get("is_active")), None)
    wins = json.loads(subprocess.check_output(["niri", "msg", "-j", "windows"]))
    ws_wins = [w for w in wins if w.get("workspace_id") == f_ws]
    print(len(ws_wins))
except Exception:
    print(1)
' 2>/dev/null || echo 1)

        if [ "$WIN_COUNT" -eq 0 ]; then
            # 当前没有检测到任何打开的窗口，自动回退截取全屏
            grim "$FILE"
            notify_screenshot "$FILE" "全屏截图已复制（当前无可见窗口）"
            exit 0
        fi

        # 优先使用专为 Niri 优化的智能吸附与原生窗口捕获工具 latchshot
        if command -v latchshot >/dev/null 2>&1; then
            if latchshot -o "$FILE" -c --no-notify; then
                if [ -f "$FILE" ]; then
                    notify_screenshot "$FILE"
                fi
                exit 0
            else
                # 用户按 Esc / 右键取消
                exit 0
            fi
        fi

        # 兜底：若 latchshot 不可用，调用 niri 原生 pick-window 与 screenshot-window
        WIN_INFO=$(niri msg -j pick-window 2>/dev/null || true)
        if [ -n "$WIN_INFO" ]; then
            WIN_ID=$(echo "$WIN_INFO" | grep -oP '"id":\s*\K[0-9]+' | head -n 1)
            if [ -n "$WIN_ID" ]; then
                niri msg action screenshot-window --id "$WIN_ID" --write-to-disk true --path "$FILE"
                notify_screenshot "$FILE"
                exit 0
            fi
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
