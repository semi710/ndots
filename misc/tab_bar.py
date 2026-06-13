from kitty.fast_data_types import Screen
from kitty.tab_bar import (
    DrawData,
    ExtraData,
    TabBarData,
    draw_title,
)


def draw_tab(
    draw_data: DrawData,
    screen: Screen,
    tab: TabBarData,
    before: int,
    max_title_length: int,
    index: int,
    is_last: bool,
    extra_data: ExtraData,
) -> int:
    # Indicator for active tab
    if tab.is_active:
        screen.draw("▎ ")  # Thin line like Neovim
    else:
        screen.draw("  ")

    # Draw only title
    draw_title(draw_data, screen, tab, index)

    # Minimal spacing
    screen.draw(" ")

    return screen.cursor.x
