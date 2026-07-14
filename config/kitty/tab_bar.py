"""Show native tabs normally and active keyboard-mode hints in the tab bar."""

from kitty.fast_data_types import (
    Screen,
    get_boss,
    get_options,
    truncate_point_for_length,
    wcswidth,
)
from kitty.tab_bar import (
    DrawData,
    ExtraData,
    TabBarData,
    as_rgb,
    draw_tab_with_powerline,
)
from kitty.types import Shortcut


_SEPARATOR = "  "


def _keyboard_mode() -> str:
    mode = get_boss().mappings.current_keyboard_mode_name
    return "" if not mode or mode.startswith("__") else mode


def _width(text: str) -> int:
    return max(0, wcswidth(text))


def _truncate(text: str, width: int) -> str:
    return text[: truncate_point_for_length(text, width)]


def _badge(mode: str, width: int) -> str:
    label = f" {mode.upper()} "
    if _width(label) <= width:
        return label
    return _truncate(mode.upper(), width) or ("…" if width else "")


def _action_label(mode: str, definition: str, actions: tuple) -> str:
    name = definition.split(maxsplit=1)[0]
    aliases = get_options().alias_map.aliases
    if name in aliases:
        return name.removeprefix(f"{mode}_").replace("_", " ")

    substantive = [
        action
        for action in actions
        if action.func not in ("pop_keyboard_mode", "no_op")
    ]
    if not substantive:
        return ""
    return substantive[0].func.replace("_", " ")


def _hints(mode: str) -> list[tuple[str, str]]:
    mappings = get_boss().mappings
    keymap = mappings.keyboard_modes[mode].keymap
    options = get_options()
    hints = []
    seen = set()
    for key, candidates in keymap.items():
        for definition in mappings.matching_key_actions(candidates):
            actions = options.alias_map.resolve_aliases(definition.definition)
            if any(action.func == "push_keyboard_mode" for action in actions):
                continue
            label = _action_label(mode, definition.definition, actions)
            if not label:
                continue
            shortcut = (
                Shortcut((definition.trigger,) + definition.rest)
                if definition.is_sequence
                else Shortcut((key,))
            )
            key_label = shortcut.human_repr(options.kitty_mod)
            key_label = key_label.replace("shift+", "⇧").replace("left", "←")
            key_label = (
                key_label.replace("right", "→").replace("up", "↑").replace("down", "↓")
            )
            hint = (key_label, label)
            if hint not in seen:
                seen.add(hint)
                hints.append(hint)
    return hints


def _draw_mode_bar(draw_data: DrawData, screen: Screen, mode: str) -> None:
    badge = _badge(mode, screen.columns)
    badge_width = _width(badge)
    hints = _hints(mode)
    rendered = [f"{key} {label}" for key, label in hints]
    while rendered and _width(_SEPARATOR.join(rendered) + " " + badge) > screen.columns:
        rendered.pop(0)
    hints_text = _SEPARATOR.join(rendered)
    prefix = hints_text + (" " if hints_text else "")
    screen.cursor.x = max(0, screen.columns - _width(prefix) - badge_width)
    screen.cursor.fg = as_rgb(int(draw_data.inactive_fg))
    screen.cursor.bg = as_rgb(int(draw_data.default_bg))
    screen.cursor.bold = False
    screen.cursor.italic = False
    screen.draw(prefix)
    screen.cursor.fg = as_rgb(int(draw_data.active_fg))
    screen.cursor.bg = as_rgb(int(draw_data.active_bg))
    screen.cursor.bold = True
    screen.draw(badge)


def draw_tab(
    draw_data: DrawData,
    screen: Screen,
    tab: TabBarData,
    before: int,
    max_tab_length: int,
    index: int,
    is_last: bool,
    extra_data: ExtraData,
) -> int:
    mode = _keyboard_mode()
    if not mode:
        return draw_tab_with_powerline(
            draw_data, screen, tab, before, max_tab_length, index, is_last, extra_data
        )
    if is_last:
        _draw_mode_bar(draw_data, screen, mode)
    return before - 1
