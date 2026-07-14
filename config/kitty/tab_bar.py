"""Keep Kitty's native powerline tabs and add a right-aligned mode badge."""

from kitty.fast_data_types import Screen, get_boss
from kitty.tab_bar import (
    DrawData,
    ExtraData,
    TabBarData,
    as_rgb,
    draw_tab_with_powerline,
)


_MODE_LABELS = {
    'pane': 'PANE',
    'resize': 'RESIZE',
    'tab': 'TAB',
    'zmx': 'ZMX',
}


def _mode_badge() -> str:
    mode = get_boss().mappings.current_keyboard_mode_name
    if not mode or mode.startswith('__'):
        return ''
    return f" {_MODE_LABELS.get(mode, mode.upper())} "


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
    badge = _mode_badge() if is_last else ''
    if badge and max_tab_length <= len(badge) + 1:
        badge = ''

    native_max_length = max(1, max_tab_length - len(badge))
    end = draw_tab_with_powerline(
        draw_data,
        screen,
        tab,
        before,
        native_max_length,
        index,
        is_last,
        extra_data,
    )
    if not badge:
        return end

    if extra_data.for_layout:
        screen.draw(' ' * len(badge))
        return screen.cursor.x

    badge_start = screen.columns - len(badge)
    if screen.cursor.x > badge_start:
        return end

    screen.cursor.x = badge_start
    screen.cursor.fg = as_rgb(int(draw_data.active_fg))
    screen.cursor.bg = as_rgb(int(draw_data.active_bg))
    screen.cursor.bold = True
    screen.cursor.italic = False
    screen.draw(badge)
    return end
