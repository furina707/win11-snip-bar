#include <gtk/gtk.h>
#include <gtk4-layer-shell.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <libgen.h>

typedef enum {
    ACTION_NONE = 0,
    ACTION_RECT,
    ACTION_WINDOW,
    ACTION_FULL,
    ACTION_DELAY,
    ACTION_RECORD
} SnipAction;

static SnipAction g_action = ACTION_NONE;
static int g_rec_seconds = 0;
static GtkWidget *g_time_label = NULL;

static const char *CSS_DATA =
    "window.pill-window {"
    "    background-color: transparent;"
    "}"
    ".pill-container {"
    "    background-color: rgba(28, 28, 34, 0.94);"
    "    border: 1px solid rgba(255, 255, 255, 0.18);"
    "    border-radius: 28px;"
    "    padding: 6px 14px;"
    "    box-shadow: 0 10px 36px rgba(0, 0, 0, 0.55);"
    "}"
    ".pill-btn {"
    "    background: transparent;"
    "    border: none;"
    "    border-radius: 20px;"
    "    padding: 7px 16px;"
    "    color: #f3f3f3;"
    "    font-size: 14px;"
    "    font-weight: 500;"
    "    transition: all 120ms ease;"
    "}"
    ".pill-btn:hover {"
    "    background-color: rgba(255, 255, 255, 0.16);"
    "    color: #ffffff;"
    "}"
    ".pill-btn:active {"
    "    background-color: rgba(255, 255, 255, 0.26);"
    "    transform: scale(0.96);"
    "}"
    ".pill-sep {"
    "    background-color: rgba(255, 255, 255, 0.20);"
    "    margin: 5px 6px;"
    "}"
    ".pill-record-btn {"
    "    color: #ff6b6b;"
    "}"
    ".pill-record-btn:hover {"
    "    background-color: rgba(255, 80, 80, 0.22);"
    "    color: #ff8888;"
    "}"
    "/* 录屏控制栏浮动药丸样式 */"
    ".rec-container {"
    "    background-color: rgba(24, 24, 30, 0.95);"
    "    border: 1px solid rgba(255, 75, 75, 0.45);"
    "    border-radius: 26px;"
    "    padding: 5px 12px;"
    "    box-shadow: 0 10px 32px rgba(0, 0, 0, 0.6);"
    "}"
    ".rec-time {"
    "    color: #ff5555;"
    "    font-size: 14px;"
    "    font-weight: 700;"
    "    padding: 0 10px 0 4px;"
    "}"
    ".rec-stop-btn {"
    "    background-color: #e81123;"
    "    color: #ffffff;"
    "    border: none;"
    "    border-radius: 18px;"
    "    padding: 6px 14px;"
    "    font-size: 13px;"
    "    font-weight: 600;"
    "    transition: background-color 120ms ease;"
    "}"
    ".rec-stop-btn:hover {"
    "    background-color: #f12b3c;"
    "}"
    ".rec-stop-btn:active {"
    "    background-color: #c50f1f;"
    "}";

static gboolean on_key_pressed(GtkEventControllerKey *controller,
                               guint keyval,
                               guint keycode,
                               GdkModifierType state,
                               gpointer user_data) {
    if (keyval == GDK_KEY_Escape) {
        GtkWindow *win = GTK_WINDOW(user_data);
        gtk_window_close(win);
        return TRUE;
    }
    return FALSE;
}

static void on_btn_clicked(GtkButton *btn, gpointer user_data) {
    SnipAction act = (SnipAction)GPOINTER_TO_INT(user_data);
    g_action = act;
    GtkWidget *toplevel = GTK_WIDGET(gtk_widget_get_root(GTK_WIDGET(btn)));
    if (GTK_IS_WINDOW(toplevel)) {
        gtk_window_close(GTK_WINDOW(toplevel));
    }
}

static void on_activate(GtkApplication *app, gpointer user_data) {
    GtkWindow *win = GTK_WINDOW(gtk_application_window_new(app));
    gtk_widget_add_css_class(GTK_WIDGET(win), "pill-window");

    gtk_layer_init_for_window(win);
    gtk_layer_set_layer(win, GTK_LAYER_SHELL_LAYER_OVERLAY);
    gtk_layer_set_anchor(win, GTK_LAYER_SHELL_EDGE_TOP, TRUE);
    gtk_layer_set_margin(win, GTK_LAYER_SHELL_EDGE_TOP, 16);
    gtk_layer_set_keyboard_mode(win, GTK_LAYER_SHELL_KEYBOARD_MODE_NONE);

    // ESC to close
    GtkEventController *key_ctrl = gtk_event_controller_key_new();
    g_signal_connect(key_ctrl, "key-pressed", G_CALLBACK(on_key_pressed), win);
    gtk_widget_add_controller(GTK_WIDGET(win), key_ctrl);

    // CSS styling
    GtkCssProvider *css = gtk_css_provider_new();
    gtk_css_provider_load_from_string(css, CSS_DATA);
    gtk_style_context_add_provider_for_display(
        gdk_display_get_default(),
        GTK_STYLE_PROVIDER(css),
        GTK_STYLE_PROVIDER_PRIORITY_APPLICATION
    );
    g_object_unref(css);

    // Horizontal Pill container
    GtkWidget *box = gtk_box_new(GTK_ORIENTATION_HORIZONTAL, 4);
    gtk_widget_add_css_class(box, "pill-container");

    struct {
        const char *label;
        const char *tooltip;
        SnipAction act;
    } buttons[] = {
        {"⛶ 矩形", "矩形截图 (拖拽划选区域)", ACTION_RECT},
        {"🗔 窗口", "窗口截图 (鼠标悬停高亮边框并点击，无窗口时自动全屏)", ACTION_WINDOW},
        {"🖵 全屏", "全屏截图 (直接截取整个屏幕)", ACTION_FULL},
        {"⏱ 3秒", "3秒延时截图 (点击后有3秒时间展开右键/二级菜单或悬停提示)", ACTION_DELAY},
    };

    for (size_t i = 0; i < sizeof(buttons)/sizeof(buttons[0]); i++) {
        GtkWidget *b = gtk_button_new_with_label(buttons[i].label);
        gtk_widget_set_tooltip_text(b, buttons[i].tooltip);
        gtk_widget_add_css_class(b, "pill-btn");
        g_signal_connect(b, "clicked", G_CALLBACK(on_btn_clicked), GINT_TO_POINTER(buttons[i].act));
        gtk_box_append(GTK_BOX(box), b);
    }

    // Separator
    GtkWidget *sep = gtk_separator_new(GTK_ORIENTATION_VERTICAL);
    gtk_widget_add_css_class(sep, "pill-sep");
    gtk_box_append(GTK_BOX(box), sep);

    // Recording button
    gboolean is_rec = (system("pgrep -x wf-recorder >/dev/null 2>&1") == 0);
    const char *rec_label = is_rec ? "⏹ 停止录屏" : "📹 录屏";
    const char *rec_tip = is_rec ? "点击停止录屏并保存" : "屏幕录制 (划选区域并录制)";
    GtkWidget *rec_btn = gtk_button_new_with_label(rec_label);
    gtk_widget_set_tooltip_text(rec_btn, rec_tip);
    gtk_widget_add_css_class(rec_btn, "pill-btn");
    gtk_widget_add_css_class(rec_btn, "pill-record-btn");
    g_signal_connect(rec_btn, "clicked", G_CALLBACK(on_btn_clicked), GINT_TO_POINTER(ACTION_RECORD));
    gtk_box_append(GTK_BOX(box), rec_btn);

    // Close button
    GtkWidget *close_btn = gtk_button_new_with_label("✕");
    gtk_widget_set_tooltip_text(close_btn, "关闭 (Esc)");
    gtk_widget_add_css_class(close_btn, "pill-btn");
    g_signal_connect(close_btn, "clicked", G_CALLBACK(on_btn_clicked), GINT_TO_POINTER(ACTION_NONE));
    gtk_box_append(GTK_BOX(box), close_btn);

    gtk_window_set_child(win, box);
    gtk_window_present(win);
}

// ─── 录屏悬浮计时与停止药丸栏 ──────────────────────────────────────────────────
static gboolean on_rec_timer_tick(gpointer user_data) {
    if (system("pgrep -x wf-recorder >/dev/null 2>&1") != 0) {
        GtkWindow *win = GTK_WINDOW(user_data);
        gtk_window_close(win);
        return G_SOURCE_REMOVE;
    }
    g_rec_seconds++;
    int mins = g_rec_seconds / 60;
    int secs = g_rec_seconds % 60;
    char time_str[32];
    snprintf(time_str, sizeof(time_str), "🔴 %02d:%02d", mins, secs);
    gtk_label_set_text(GTK_LABEL(g_time_label), time_str);
    return G_SOURCE_CONTINUE;
}

static void on_rec_stop_btn_clicked(GtkButton *btn, gpointer user_data) {
    system("killall -SIGINT wf-recorder");
    GtkWindow *win = GTK_WINDOW(user_data);
    gtk_window_close(win);
    system("notify-send -a '屏幕录制' '录制已完成并保存' '已保存至视频目录 ~/Videos/Captures' -t 4000 2>/dev/null &");
}

static void on_rec_bar_activate(GtkApplication *app, gpointer user_data) {
    GtkWindow *win = GTK_WINDOW(gtk_application_window_new(app));
    gtk_widget_add_css_class(GTK_WIDGET(win), "pill-window");

    gtk_layer_init_for_window(win);
    gtk_layer_set_layer(win, GTK_LAYER_SHELL_LAYER_OVERLAY);
    gtk_layer_set_anchor(win, GTK_LAYER_SHELL_EDGE_TOP, TRUE);
    gtk_layer_set_margin(win, GTK_LAYER_SHELL_EDGE_TOP, 16);
    gtk_layer_set_keyboard_mode(win, GTK_LAYER_SHELL_KEYBOARD_MODE_NONE);

    // CSS
    GtkCssProvider *css = gtk_css_provider_new();
    gtk_css_provider_load_from_string(css, CSS_DATA);
    gtk_style_context_add_provider_for_display(
        gdk_display_get_default(),
        GTK_STYLE_PROVIDER(css),
        GTK_STYLE_PROVIDER_PRIORITY_APPLICATION
    );
    g_object_unref(css);

    GtkWidget *box = gtk_box_new(GTK_ORIENTATION_HORIZONTAL, 6);
    gtk_widget_add_css_class(box, "rec-container");

    g_time_label = gtk_label_new("🔴 00:00");
    gtk_widget_add_css_class(g_time_label, "rec-time");
    gtk_box_append(GTK_BOX(box), g_time_label);

    GtkWidget *stop_btn = gtk_button_new_with_label("⏹ 停止录制");
    gtk_widget_add_css_class(stop_btn, "rec-stop-btn");
    g_signal_connect(stop_btn, "clicked", G_CALLBACK(on_rec_stop_btn_clicked), win);
    gtk_box_append(GTK_BOX(box), stop_btn);

    // 启动 1 秒心跳定时器
    g_timeout_add_seconds(1, on_rec_timer_tick, win);

    gtk_window_set_child(win, box);
    gtk_window_present(win);
}

static const char *resolve_helper_path(char *buf, size_t buf_size) {
    char exe_path[1024];
    ssize_t len = readlink("/proc/self/exe", exe_path, sizeof(exe_path) - 1);
    if (len > 0) {
        exe_path[len] = '\0';
        char *dir = dirname(exe_path);

        snprintf(buf, buf_size, "%s/win11-snip-helper", dir);
        if (access(buf, X_OK) == 0) return buf;

        snprintf(buf, buf_size, "%s/../lib/win11-snip-bar/win11-snip-helper", dir);
        if (access(buf, X_OK) == 0) return buf;

        snprintf(buf, buf_size, "%s/../lib/win11-snip-helper", dir);
        if (access(buf, X_OK) == 0) return buf;
    }

    const char *home = getenv("HOME");
    if (home) {
        snprintf(buf, buf_size, "%s/.local/lib/win11-snip-bar/win11-snip-helper", home);
        if (access(buf, X_OK) == 0) return buf;

        snprintf(buf, buf_size, "%s/.local/lib/win11-snip-helper", home);
        if (access(buf, X_OK) == 0) return buf;
    }

    snprintf(buf, buf_size, "/usr/lib/win11-snip-bar/win11-snip-helper");
    if (access(buf, X_OK) == 0) return buf;

    snprintf(buf, buf_size, "win11-snip-helper");
    return buf;
}

int main(int argc, char **argv) {
    if (argc > 1) {
        if (strcmp(argv[1], "--rec-bar") == 0) {
            GtkApplication *app = gtk_application_new(NULL, G_APPLICATION_DEFAULT_FLAGS);
            g_signal_connect(app, "activate", G_CALLBACK(on_rec_bar_activate), NULL);
            g_application_run(G_APPLICATION(app), 0, NULL);
            g_object_unref(app);
            return 0;
        } else if (strcmp(argv[1], "--rect") == 0) g_action = ACTION_RECT;
        else if (strcmp(argv[1], "--window") == 0) g_action = ACTION_WINDOW;
        else if (strcmp(argv[1], "--full") == 0) g_action = ACTION_FULL;
        else if (strcmp(argv[1], "--delay") == 0) g_action = ACTION_DELAY;
        else if (strcmp(argv[1], "--record") == 0) g_action = ACTION_RECORD;
    }

    if (g_action == ACTION_NONE && argc == 1) {
        GtkApplication *app = gtk_application_new(NULL, G_APPLICATION_DEFAULT_FLAGS);
        g_signal_connect(app, "activate", G_CALLBACK(on_activate), NULL);
        g_application_run(G_APPLICATION(app), 0, NULL);
        g_object_unref(app);
    }

    if (g_action == ACTION_NONE) {
        return 0;
    }

    // Wait 120ms so layer surface is completely dismissed from screen before capturing
    usleep(120000);

    const char *action_str = "";
    switch (g_action) {
        case ACTION_RECT: action_str = "rect"; break;
        case ACTION_WINDOW: action_str = "window"; break;
        case ACTION_FULL: action_str = "full"; break;
        case ACTION_DELAY: action_str = "delay"; break;
        case ACTION_RECORD: action_str = "record"; break;
        default: return 0;
    }

    char helper[1024];
    resolve_helper_path(helper, sizeof(helper));

    char cmd[2048];
    snprintf(cmd, sizeof(cmd), "\"%s\" %s", helper, action_str);
    return system(cmd);
}
