-- ~/.config/wezterm/wezterm.lua
-- 主配置入口。配色 / 快捷键拆到同目录的模块里，方便维护。

local wezterm = require("wezterm")
local act = wezterm.action

-- config_builder 在新版 wezterm 上提供更清晰的错误提示
local config = wezterm.config_builder()

--------------------------------------------------------------------------------
-- 配色：Nord
--------------------------------------------------------------------------------
config.color_scheme = "nord"

--------------------------------------------------------------------------------
-- 字体：MonoLisa 主字体 + Symbols Nerd Font 作为图标回退
--------------------------------------------------------------------------------
config.font = wezterm.font_with_fallback({
  { family = "MonoLisa", weight = "Medium" },
  -- 终端里的 nerd-font 图标（git 分支、文件类型等）由它兜底
  "Symbols Nerd Font Mono",
  "Apple Color Emoji",
})
config.font_size = 12.5    -- 编程向的密集字号；想更小可降到 12.0
config.line_height = 0.95  -- 行距收紧（调它对连字安全）
-- 注意：cell_width 保持 1.0。MonoLisa 带连字，改它会让 => -> != 等连字错位
config.cell_width = 1.0
-- MonoLisa 自带连字（=> -> != 等），需要时可以关掉
config.harfbuzz_features = { "calt=1", "liga=1", "clig=1" }

--------------------------------------------------------------------------------
-- 窗口：原生外观（圆角 + 投影）+ 启动最大化
--------------------------------------------------------------------------------
-- 完全不透明：交还给 macOS 原生绘制，自动获得圆角 + 投影（最接近原生 app）
-- 半透明会走 wezterm 自定义渲染，导致圆角和阴影都丢失
config.window_background_opacity = 1.0
-- 交通灯画进标签栏那一行，省掉独立标题栏高度；不带 SQUARE_CORNERS 即为圆角
config.window_decorations = "INTEGRATED_BUTTONS | RESIZE"
config.integrated_title_button_style = "MacOsNative" -- 用真正的 macOS 交通灯
config.integrated_title_button_alignment = "Left"    -- 靠左，macOS 习惯
config.window_padding = {
  left = 12,
  right = 12,
  top = 10,
  bottom = 8,
}

-- 给个足够大的初始尺寸（超出屏幕会被自动夹到屏幕大小），
-- 让窗口一出现就接近满屏，避免「先小窗后放大」的跳变
config.initial_cols = 300
config.initial_rows = 80

-- 启动时铺满桌面（最大化，保留菜单栏与窗口形态，非全屏）
wezterm.on("gui-startup", function(cmd)
  local _, _, window = wezterm.mux.spawn_window(cmd or {})
  window:gui_window():maximize()
end)

--------------------------------------------------------------------------------
-- 标签栏美化
--------------------------------------------------------------------------------
-- fancy 标签栏：为集成窗口按钮设计，会自动给交通灯预留位置并垂直居中
config.use_fancy_tab_bar = true
config.tab_bar_at_bottom = false
-- 交通灯画在标签栏里，所以标签栏必须常驻，否则单标签时窗口按钮会消失
config.hide_tab_bar_if_only_one_tab = false
config.tab_max_width = 32
config.show_new_tab_button_in_tab_bar = false
config.show_close_tab_button_in_tabs = false

-- Nord 调色板
local nord = {
  bg = "#2e3440",
  fg = "#d8dee9",
  active_bg = "#5e81ac",
  active_fg = "#eceff4",
  inactive_bg = "#3b4252",
  inactive_fg = "#81a1c1",
  hover_bg = "#434c5e",
}

-- fancy 标签栏的边框/背景/字体（决定栏高度，让它和交通灯对齐）
config.window_frame = {
  font = wezterm.font({ family = "MonoLisa", weight = "Medium" }),
  font_size = 12.0,
  active_titlebar_bg = nord.bg,
  inactive_titlebar_bg = nord.bg,
  button_bg = nord.bg,
  button_fg = nord.fg,
}

config.colors = {
  tab_bar = {
    background = nord.bg,
    active_tab = { bg_color = nord.active_bg, fg_color = nord.active_fg, intensity = "Bold" },
    inactive_tab = { bg_color = nord.inactive_bg, fg_color = nord.inactive_fg },
    inactive_tab_hover = { bg_color = nord.hover_bg, fg_color = nord.fg, italic = false },
    new_tab = { bg_color = nord.bg, fg_color = nord.inactive_fg },
    new_tab_hover = { bg_color = nord.hover_bg, fg_color = nord.fg },
  },
}

-- 标签文字：序号 + 进程/标题（fancy 标签栏自己画标签形状，这里只给内容）
wezterm.on("format-tab-title", function(tab, _tabs, _panes, _conf, _hover, max_width)
  local title = tab.tab_title
  if not title or #title == 0 then
    local proc = tab.active_pane.foreground_process_name or ""
    proc = proc:gsub("(.*[/\\])(.*)", "%2")
    title = (#proc > 0) and proc or (tab.active_pane.title or "shell")
  end

  local label = string.format("  %d  %s  ", tab.tab_index + 1, title)
  if #label > max_width then
    label = wezterm.truncate_right(label, max_width - 1) .. "…"
  end
  return label
end)

-- 右下角状态栏：模式徽标 + 工作目录 + 日期时间
wezterm.on("update-right-status", function(window, pane)
  local cells = {}

  -- 模式徽标：resize 模式 / 复制模式等激活时高亮提示
  local kt = window:active_key_table()
  if kt then
    table.insert(cells, { Foreground = { Color = nord.bg } })
    table.insert(cells, { Background = { Color = "#ebcb8b" } }) -- Nord 黄
    table.insert(cells, { Attribute = { Intensity = "Bold" } })
    table.insert(cells, { Text = string.format("  %s  ", kt:upper()) })
    table.insert(cells, "ResetAttributes")
    table.insert(cells, { Text = "  " })
  end

  local uri = pane:get_current_working_dir()
  if uri then
    local path = uri.file_path or tostring(uri)
    local cwd = path:gsub(os.getenv("HOME") or "", "~")
    table.insert(cells, { Foreground = { Color = nord.inactive_fg } })
    table.insert(cells, { Text = "  " .. cwd .. "   " })
  end

  table.insert(cells, { Foreground = { Color = nord.active_fg } })
  table.insert(cells, { Text = wezterm.strftime("  %H:%M  %m-%d") .. "  " })

  window:set_right_status(wezterm.format(cells))
end)

--------------------------------------------------------------------------------
-- 性能：GPU 渲染（Apple Silicon 走 Metal）
--------------------------------------------------------------------------------
config.front_end = "WebGpu"                       -- M4 上用 Metal，比 OpenGL 更快更省电
config.webgpu_power_preference = "HighPerformance" -- 偏好高性能 GPU
config.max_fps = 60                                -- 匹配屏幕刷新率（你的屏 60Hz），更高是浪费
-- 缓动帧率压到最低：光标闪烁/淡入淡出不再生成中间帧，终端闲置时几乎不重绘 GPU
config.animation_fps = 1

--------------------------------------------------------------------------------
-- 其它行为
--------------------------------------------------------------------------------
config.scrollback_lines = 100000   -- 更大的回滚缓冲，找历史输出更方便
config.audible_bell = "Disabled"
config.window_close_confirmation = "NeverPrompt"
-- 关标签后跳回"上一个激活过的"标签，而非相邻序号，符合直觉
config.switch_to_last_active_tab_when_closing_tab = true
config.adjust_window_size_when_changing_font_size = false
config.default_cursor_style = "BlinkingBar"
config.cursor_blink_rate = 600
-- 光标明暗硬切，不做渐变（配合 animation_fps=1，闲时 GPU 基本静默）
config.cursor_blink_ease_in = "Constant"
config.cursor_blink_ease_out = "Constant"
config.scroll_to_bottom_on_input = true
config.enable_scroll_bar = false

-- 双击选词时把这些算进单词边界（路径/参数更易整段选中）
config.selection_word_boundary = " \t\n{}[]()\"'`,;:│"

-- 可点击链接：默认 URL 规则已覆盖常见 scheme://... 形态，无需自定义
config.hyperlink_rules = wezterm.default_hyperlink_rules()

--------------------------------------------------------------------------------
-- 快捷键（leader = Ctrl+a，类 tmux）
--------------------------------------------------------------------------------
require("keys").apply(config, act, wezterm)

return config
