-- ~/.config/wezterm/keys.lua
-- 快捷键增强：leader = Ctrl+a（类 tmux），同时保留常用 CMD 快捷键。

local M = {}

function M.apply(config, act, wezterm)
  -- Leader 键：Ctrl+a，按下后 1 秒内接后续键
  config.leader = { key = "a", mods = "CTRL", timeout_milliseconds = 1000 }

  config.keys = {
    --------------------------------------------------------------------
    -- leader 占用了 Ctrl+a，这里把字面 Ctrl+a 还给 shell（readline 跳行首）
    --------------------------------------------------------------------
    { key = "a", mods = "LEADER|CTRL", action = act.SendKey({ key = "a", mods = "CTRL" }) },

    --------------------------------------------------------------------
    -- 分屏（leader + - / \）
    --------------------------------------------------------------------
    { key = "-", mods = "LEADER", action = act.SplitVertical({ domain = "CurrentPaneDomain" }) },
    { key = "\\", mods = "LEADER", action = act.SplitHorizontal({ domain = "CurrentPaneDomain" }) },
    -- 同时支持 CMD+d / CMD+Shift+d（类 iTerm2）
    { key = "d", mods = "CMD", action = act.SplitHorizontal({ domain = "CurrentPaneDomain" }) },
    { key = "d", mods = "CMD|SHIFT", action = act.SplitVertical({ domain = "CurrentPaneDomain" }) },

    --------------------------------------------------------------------
    -- pane 焦点切换（leader + h/j/k/l，vim 风格）
    --------------------------------------------------------------------
    { key = "h", mods = "LEADER", action = act.ActivatePaneDirection("Left") },
    { key = "j", mods = "LEADER", action = act.ActivatePaneDirection("Down") },
    { key = "k", mods = "LEADER", action = act.ActivatePaneDirection("Up") },
    { key = "l", mods = "LEADER", action = act.ActivatePaneDirection("Right") },
    -- CMD+Option+方向键 也能切
    { key = "LeftArrow", mods = "CMD|ALT", action = act.ActivatePaneDirection("Left") },
    { key = "RightArrow", mods = "CMD|ALT", action = act.ActivatePaneDirection("Right") },
    { key = "UpArrow", mods = "CMD|ALT", action = act.ActivatePaneDirection("Up") },
    { key = "DownArrow", mods = "CMD|ALT", action = act.ActivatePaneDirection("Down") },

    --------------------------------------------------------------------
    -- pane 尺寸调整（leader + Shift + h/j/k/l）
    --------------------------------------------------------------------
    { key = "H", mods = "LEADER|SHIFT", action = act.AdjustPaneSize({ "Left", 5 }) },
    { key = "J", mods = "LEADER|SHIFT", action = act.AdjustPaneSize({ "Down", 5 }) },
    { key = "K", mods = "LEADER|SHIFT", action = act.AdjustPaneSize({ "Up", 5 }) },
    { key = "L", mods = "LEADER|SHIFT", action = act.AdjustPaneSize({ "Right", 5 }) },

    -- 关闭当前 pane（leader + x）
    { key = "x", mods = "LEADER", action = act.CloseCurrentPane({ confirm = true }) },
    -- 当前 pane 全屏缩放（leader + z，类 tmux zoom）
    { key = "z", mods = "LEADER", action = act.TogglePaneZoomState },

    --------------------------------------------------------------------
    -- 标签页
    --------------------------------------------------------------------
    { key = "c", mods = "LEADER", action = act.SpawnTab("CurrentPaneDomain") },
    { key = "t", mods = "CMD", action = act.SpawnTab("CurrentPaneDomain") },
    { key = "n", mods = "LEADER", action = act.ActivateTabRelative(1) },
    { key = "p", mods = "LEADER", action = act.ActivateTabRelative(-1) },
    { key = "w", mods = "CMD", action = act.CloseCurrentTab({ confirm = true }) },

    --------------------------------------------------------------------
    -- 复制模式 / 搜索 / 命令面板
    --------------------------------------------------------------------
    { key = "[", mods = "LEADER", action = act.ActivateCopyMode },
    { key = "f", mods = "CMD", action = act.Search({ CaseInSensitiveString = "" }) },
    { key = "p", mods = "CMD|SHIFT", action = act.ActivateCommandPalette },
    -- 清屏 + 清回滚缓冲（iTerm 肌肉记忆）
    { key = "k", mods = "CMD", action = act.ClearScrollback("ScrollbackAndViewport") },

    --------------------------------------------------------------------
    -- 高效操作
    --------------------------------------------------------------------
    -- 快速选择：高亮屏上的 URL/路径/哈希等，按提示字母即可复制（leader + Space）
    { key = "Space", mods = "LEADER", action = act.QuickSelect },
    -- 可视化选择 pane：屏上显示字母，按下跳转（leader + s）
    { key = "s", mods = "LEADER", action = act.PaneSelect({ alphabet = "asdfghjkl" }) },
    -- 交换 pane 位置：选中目标后与当前 pane 互换（leader + Shift + s）
    { key = "S", mods = "LEADER|SHIFT", action = act.PaneSelect({ alphabet = "asdfghjkl", mode = "SwapWithActive" }) },
    -- 重命名当前标签（leader + ,）
    {
      key = ",",
      mods = "LEADER",
      action = act.PromptInputLine({
        description = "标签新名称：",
        action = wezterm.action_callback(function(window, _pane, line)
          if line and #line > 0 then
            window:active_tab():set_title(line)
          end
        end),
      }),
    },
    -- 进入 resize 模式：之后连续按 hjkl 调整，无需一直按住（leader + r）
    { key = "r", mods = "LEADER", action = act.ActivateKeyTable({ name = "resize", one_shot = false }) },
    -- workspace 切换器：模糊搜索已有 workspace 并跳转（类 tmux session，leader + w）
    { key = "w", mods = "LEADER", action = act.ShowLauncherArgs({ flags = "FUZZY|WORKSPACES" }) },

    -- 切换全屏（CMD+Ctrl+F，macOS 习惯）
    { key = "f", mods = "CMD|CTRL", action = act.ToggleFullScreen },
    -- 快捷字体缩放重置
    { key = "0", mods = "CMD", action = act.ResetFontSize },
  }

  --------------------------------------------------------------------
  -- key tables：resize 模式（hjkl 反复调整，Esc/Enter 退出）
  --------------------------------------------------------------------
  config.key_tables = {
    resize = {
      { key = "h", action = act.AdjustPaneSize({ "Left", 3 }) },
      { key = "j", action = act.AdjustPaneSize({ "Down", 3 }) },
      { key = "k", action = act.AdjustPaneSize({ "Up", 3 }) },
      { key = "l", action = act.AdjustPaneSize({ "Right", 3 }) },
      { key = "Escape", action = "PopKeyTable" },
      { key = "Enter", action = "PopKeyTable" },
    },
  }

  --------------------------------------------------------------------
  -- 鼠标：⌘ + 点击打开链接（不按 ⌘ 时点击只移动光标，避免误触）
  --------------------------------------------------------------------
  config.mouse_bindings = {
    {
      event = { Up = { streak = 1, button = "Left" } },
      mods = "CMD",
      action = act.OpenLinkAtMouseCursor,
    },
    -- 关闭普通左键点击时也跳转链接，避免选词误触
    {
      event = { Up = { streak = 1, button = "Left" } },
      mods = "NONE",
      action = act.CompleteSelection("ClipboardAndPrimarySelection"),
    },
  }

  -- CMD + 1..9 直接跳到对应标签
  for i = 1, 9 do
    table.insert(config.keys, {
      key = tostring(i),
      mods = "CMD",
      action = act.ActivateTab(i - 1),
    })
  end
end

return M
