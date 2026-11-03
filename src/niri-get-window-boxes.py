#!/usr/bin/env python3
"""
Extract visible window geometry from Niri compositor for slurp -r window selection.
Uses only Python standard library.
"""
import json
import subprocess
import sys

def main():
    try:
        focused_out = json.loads(subprocess.check_output(["niri", "msg", "-j", "focused-output"]))
        logical = focused_out.get("logical", {})
        out_x = int(logical.get("x", 0))
        out_y = int(logical.get("y", 0))
        out_w = int(logical.get("width", 1920))
        out_h = int(logical.get("height", 1080))

        workspaces = json.loads(subprocess.check_output(["niri", "msg", "-j", "workspaces"]))
        focused_ws = next((w["id"] for w in workspaces if w.get("is_focused")), None)
        if focused_ws is None:
            focused_ws = next((w["id"] for w in workspaces if w.get("is_active")), None)

        windows = json.loads(subprocess.check_output(["niri", "msg", "-j", "windows"]))
        ws_windows = [w for w in windows if w.get("workspace_id") == focused_ws]

        if not ws_windows:
            sys.exit(0)

        gap = 4
        top_bar_h = 41

        boxes = []
        columns = {}

        for w in ws_windows:
            title = (w.get("title") or w.get("app_id") or "Window").replace('"', '').replace('\n', ' ')
            layout = w.get("layout", {})
            if w.get("is_floating"):
                tile_pos = layout.get("tile_pos_in_workspace_view")
                win_size = layout.get("window_size", [800, 600])
                if tile_pos:
                    fx, fy = int(tile_pos[0]), int(tile_pos[1])
                    fw, fh = int(win_size[0]), int(win_size[1])
                    boxes.append(f"{out_x + fx},{out_y + fy} {fw}x{fh} {title}")
                continue

            pos = layout.get("pos_in_scrolling_layout", [1, 1])
            col, row = pos[0], pos[1]
            columns.setdefault(col, []).append((row, w, title))

        sorted_cols = sorted(columns.keys())
        if sorted_cols:
            col_widths = {}
            for c in sorted_cols:
                wins = columns[c]
                col_w = max(int(item[1].get("layout", {}).get("tile_size", [out_w, out_h])[0]) for item in wins)
                col_widths[c] = col_w

            total_cols_w = sum(col_widths.values()) + (len(sorted_cols) + 1) * gap
            if total_cols_w <= out_w:
                start_x = out_x + gap
            else:
                # If scrolling layout overflows, center active window's column
                active_win_id = next((w["id"] for w in ws_windows if w.get("is_focused")), None)
                active_col = next((c for c in sorted_cols if any(item[1]["id"] == active_win_id for item in columns[c])), sorted_cols[0])
                active_w = col_widths[active_col]
                start_x = out_x + (out_w - active_w) // 2
                # backtrack for preceding columns
                for c in reversed(sorted_cols):
                    if c < active_col:
                        start_x -= (col_widths[c] + gap)

            curr_x = start_x
            for c in sorted_cols:
                wins = sorted(columns[c], key=lambda item: item[0])
                col_w = col_widths[c]
                curr_y = out_y + top_bar_h
                for row, w, title in wins:
                    layout = w.get("layout", {})
                    tile_size = layout.get("tile_size", [col_w, out_h - top_bar_h - gap])
                    win_h = int(tile_size[1])
                    
                    # Ensure bounding box is within output bounds
                    bx = max(out_x, curr_x)
                    by = max(out_y + top_bar_h, curr_y)
                    bw = min(col_w, out_x + out_w - bx - gap)
                    bh = min(win_h, out_y + out_h - by - gap)
                    if bw > 20 and bh > 20:
                        boxes.append(f"{bx},{by} {bw}x{bh} {title}")
                    curr_y += win_h + gap
                curr_x += col_w + gap

        for b in boxes:
            print(b)
    except Exception:
        sys.exit(1)

if __name__ == "__main__":
    main()
