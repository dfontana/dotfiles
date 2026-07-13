"""
smart_split.py — context-aware pane split.

If the focused window has a zmx_session user var (set by zp when opening a
remote session), opens a new zmx pane via `zp --from <session>` so the new
session starts in the origin session's cwd. Otherwise opens a plain local
split — identical to the old launch --cwd=current behaviour, with no overhead.

Usage in kitty.conf:
    map cmd+shift+p>h kitten kittens/smart_split.py hsplit
    map cmd+shift+p>v kitten kittens/smart_split.py vsplit
"""

import shlex

from kittens.tui.handler import result_handler


def main(args):
    pass


@result_handler(no_ui=True)
def handle_result(args, answer, target_window_id, boss):
    location = args[1] if len(args) > 1 else 'hsplit'
    w = boss.window_id_map.get(target_window_id)
    zmx_session = (w.user_vars.get('zmx_session', '') if w else '')

    if zmx_session:
        cmd = f'zp --from {shlex.quote(zmx_session)}'
        boss.call_remote_control(w, ('launch', f'--location={location}', 'zsh', '-ic', cmd))
    else:
        boss.call_remote_control(w, ('launch', f'--location={location}', '--cwd=current'))
