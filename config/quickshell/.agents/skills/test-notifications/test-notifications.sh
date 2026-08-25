#!/usr/bin/env bash
set -Eeuo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_DIR="$(cd -- "$SCRIPT_DIR/../../.." && pwd)"
OUTPUT_DIR="${QUICKSHELL_NOTIFICATION_TEST_DIR:-/tmp/quickshell-preview/notifications-tests}"
CASE_NAME="all"

TEST_IDS=()
SENDER_PIDS=()
MONITOR_PIDS=()
LAST_ID=""
INITIAL_CURSOR_X=""
INITIAL_CURSOR_Y=""
INITIAL_MONITOR=""
OTHER_MONITOR=""
QS_PID=""
FULLSCREEN_ACTIVE=0
RELOAD_FILE="$CONFIG_DIR/home/widgets/notifications/NotificationService.qml"
RELOAD_BACKUP=""

usage() {
  cat <<EOF
Usage: $(basename "$0") [options]

Options:
  --case NAME          Run one case or all (default: all)
                       preflight basic expiry persistent-close replacement
                       markup image actions urgencies hover clear-all routing
                       fullscreen reload interactions all
  --output-dir PATH    Store screenshots and monitor output there
  -h, --help           Show this help
EOF
}

fail() {
  printf 'FAIL: %s\n' "$*" >&2
  exit 1
}

require_command() {
  command -v "$1" >/dev/null 2>&1 || fail "required command not found: $1"
}

case_needs_hyprland() {
  case "$CASE_NAME" in
    actions | clear-all | fullscreen | hover | interactions | reload | routing | all)
      return 0
      ;;
    *)
      return 1
      ;;
  esac
}

case_needs_clicks() {
  case "$CASE_NAME" in
    actions | clear-all | interactions | all)
      return 0
      ;;
    *)
      return 1
      ;;
  esac
}

move_cursor() {
  local x="$1"
  local y="$2"

  hyprctl dispatch "hl.dsp.cursor.move({ x = $x, y = $y })" >/dev/null
}

restore_pointer() {
  if [[ -n "$INITIAL_CURSOR_X" && -n "$INITIAL_CURSOR_Y" ]]; then
    move_cursor "$INITIAL_CURSOR_X" "$INITIAL_CURSOR_Y"
  fi
}

focus_monitor() {
  local monitor="$1"

  hyprctl dispatch "hl.dsp.focus({ monitor = \"$monitor\" })" >/dev/null
  for _ in $(seq 1 30); do
    if [[ "$(hyprctl monitors -j | jq -r '.[] | select(.focused == true) | .name' | head -n 1)" == "$monitor" ]]; then
      return 0
    fi
    sleep 0.1
  done

  fail "Hyprland did not focus monitor $monitor"
}

monitor_geometry() {
  local monitor="$1"

  hyprctl monitors -j | jq -r --arg monitor "$monitor" '
    .[]
    | select(.name == $monitor)
    | [
        .x,
        .y,
        (if ((.transform // 0) % 2) == 1 then .height else .width end),
        (if ((.transform // 0) % 2) == 1 then .width else .height end)
      ]
    | @tsv'
}

monitor_has_fullscreen() {
  local monitor="$1"
  local monitor_id

  monitor_id="$(hyprctl monitors -j |
    jq -r --arg monitor "$monitor" '.[] | select(.name == $monitor) | .id')"
  [[ "$monitor_id" =~ ^[0-9]+$ ]] || return 1
  hyprctl clients -j |
    jq -e --argjson monitor_id "$monitor_id" \
      'any(.[]; .monitor == $monitor_id and (.fullscreen // 0) > 0)' >/dev/null
}

notification_layer() {
  local monitor="$1"
  local layers

  layers="$(hyprctl layers -j 2>/dev/null)" || return 0
  jq -c --arg monitor "$monitor" '
    [
      .[$monitor].levels["3"][]?
      | select(
          .namespace == "quickshell"
          and .w >= 300
          and .w <= 500
          and .h > 30
          and .alpha > 0.01
        )
    ]
    | if length == 0 then empty else .[-1] end' <<<"$layers"
}

notification_layer_any() {
  local monitor="$1"
  local layers

  layers="$(hyprctl layers -j 2>/dev/null)" || return 0
  jq -c --arg monitor "$monitor" '
    [
      .[$monitor].levels["3"][]?
      | select(
          .namespace == "quickshell"
          and .w >= 300
          and .w <= 500
          and .h > 30
        )
    ]
    | if length == 0 then empty else .[-1] end' <<<"$layers"
}

wait_for_notification_layer() {
  local monitor="$1"
  local layer

  for _ in $(seq 1 50); do
    layer="$(notification_layer "$monitor")"
    if [[ -n "$layer" ]]; then
      printf '%s\n' "$layer"
      return 0
    fi
    sleep 0.1
  done

  return 1
}

wait_for_notification_layer_absent() {
  local monitor="$1"

  for _ in $(seq 1 50); do
    if [[ -z "$(notification_layer_any "$monitor")" ]]; then
      return 0
    fi
    sleep 0.1
  done

  return 1
}

wait_for_notification_height_greater() {
  local monitor="$1"
  local previous="$2"
  local layer
  local height
  local stable_height=-1
  local stable_count=0

  for _ in $(seq 1 50); do
    layer="$(notification_layer "$monitor")"
    if [[ -n "$layer" ]]; then
      height="$(jq -r '.h' <<<"$layer")"
      if ((height > previous)); then
        if ((height == stable_height)); then
          stable_count=$((stable_count + 1))
        else
          stable_height="$height"
          stable_count=1
        fi
        if ((stable_count >= 3)); then
          printf '%s\n' "$layer"
          return 0
        fi
      fi
    fi
    sleep 0.1
  done

  return 1
}

assert_clean_surface() {
  local monitor
  local layer

  while read -r monitor; do
    [[ -n "$monitor" ]] || continue
    layer="$(notification_layer_any "$monitor")"
    [[ -z "$layer" ]] ||
      fail "a notification surface already exists on $monitor; refusing to touch unknown notifications"
  done < <(hyprctl monitors -j | jq -r '.[].name')
}

wait_for_all_notification_layers_absent() {
  local monitor
  local visible

  for _ in $(seq 1 50); do
    visible=0
    while read -r monitor; do
      [[ -n "$monitor" ]] || continue
      if [[ -n "$(notification_layer_any "$monitor")" ]]; then
        visible=1
        break
      fi
    done < <(hyprctl monitors -j | jq -r '.[].name')
    if ((visible == 0)); then
      return 0
    fi
    sleep 0.1
  done

  return 1
}

start_close_monitor() {
  local path="$1"
  local duration="${2:-6s}"

  rm -f "$path"
  timeout "$duration" gdbus monitor \
    --session \
    --dest org.freedesktop.Notifications \
    --object-path /org/freedesktop/Notifications \
    >"$path" 2>&1 &
  MONITOR_PIDS+=("$!")
  sleep 0.3
}

stop_last_monitor() {
  local index=$((${#MONITOR_PIDS[@]} - 1))
  local pid="${MONITOR_PIDS[$index]:-}"

  if [[ -n "$pid" ]] && kill -0 "$pid" 2>/dev/null; then
    kill "$pid" 2>/dev/null || true
    wait "$pid" 2>/dev/null || true
  fi
  MONITOR_PIDS[index]=""
}

wait_for_signal() {
  local path="$1"
  local pattern="$2"
  local seconds="${3:-6}"
  local deadline=$((SECONDS + seconds))

  while ((SECONDS <= deadline)); do
    if [[ -f "$path" ]] && grep -Fq -- "$pattern" "$path"; then
      return 0
    fi
    sleep 0.1
  done

  return 1
}

report_monitor_failure() {
  local path="$1"

  printf '%s\n' "--- monitor output: $path ---" >&2
  if [[ -f "$path" ]]; then
    tail -n 40 "$path" >&2
  else
    printf '%s\n' '(monitor output was not created)' >&2
  fi
}

send_notification() {
  LAST_ID="$(notify-send -p "$@")"
  [[ "$LAST_ID" =~ ^[0-9]+$ ]] ||
    fail "notify-send did not return a numeric ID: $LAST_ID"
  TEST_IDS+=("$LAST_ID")
  printf 'notification id: %s\n' "$LAST_ID"
}

send_action_notification() {
  local output="$1"
  local resident="$2"
  local action_key="$3"
  local action_text="$4"
  local summary="$5"
  local body="$6"
  local hints="{}"
  local result
  local id

  if [[ "$resident" == true ]]; then
    hints="{'resident': <true>}"
  fi

  result="$(gdbus call \
    --session \
    --dest org.freedesktop.Notifications \
    --object-path /org/freedesktop/Notifications \
    --method org.freedesktop.Notifications.Notify \
    quickshell-notification-tests \
    0 \
    '' \
    "$summary" \
    "$body" \
    "['$action_key', '$action_text']" \
    "$hints" \
    0)"
  printf '%s\n' "$result" >"$output"
  id="$(sed -n 's/.*uint32 \([0-9][0-9]*\).*/\1/p' <<<"$result")"

  [[ "$id" =~ ^[0-9]+$ ]] || {
    report_monitor_failure "$output"
    fail "gdbus action sender did not return a numeric notification ID"
  }
  TEST_IDS+=("$id")
  LAST_ID="$id"
  printf 'notification id: %s\n' "$id"
}

close_notification() {
  local id="$1"

  busctl --user call \
    org.freedesktop.Notifications \
    /org/freedesktop/Notifications \
    org.freedesktop.Notifications CloseNotification u "$id" \
    >/dev/null 2>&1 || true
}

capture_screen() {
  local name="$1"
  local path="$OUTPUT_DIR/$name"

  grimblast save screen "$path" >/dev/null
  [[ -s "$path" ]] || fail "screen capture is empty: $path"
  printf 'capture: %s\n' "$path"
}

click_current_pointer() {
  python3 - <<'PY'
import fcntl
import os
import struct
import time

UI_SET_EVBIT = 0x40045564
UI_SET_KEYBIT = 0x40045565
UI_SET_RELBIT = 0x40045566
UI_DEV_CREATE = 0x5501
UI_DEV_DESTROY = 0x5502
EV_KEY = 0x01
EV_REL = 0x02
EV_SYN = 0x00
SYN_REPORT = 0
BTN_LEFT = 0x110
REL_X = 0x00
REL_Y = 0x01

fd = os.open('/dev/uinput', os.O_WRONLY | os.O_NONBLOCK)
try:
    for request, value in ((UI_SET_EVBIT, EV_KEY), (UI_SET_EVBIT, EV_REL),
                           (UI_SET_KEYBIT, BTN_LEFT), (UI_SET_RELBIT, REL_X),
                           (UI_SET_RELBIT, REL_Y)):
        fcntl.ioctl(fd, request, value)
    device = struct.pack('80sHHHHI' + 'i' * 256,
                         b'quickshell notification test mouse',
                         0x03, 0x1234, 0x5678, 1, 0, *([0] * 256))
    os.write(fd, device)
    fcntl.ioctl(fd, UI_DEV_CREATE)
    time.sleep(0.2)

    def emit(event_type, code, value):
        now = time.time()
        seconds = int(now)
        micros = int((now - seconds) * 1_000_000)
        os.write(fd, struct.pack('=qqHHi', seconds, micros,
                                 event_type, code, value))

    emit(EV_KEY, BTN_LEFT, 1)
    emit(EV_SYN, SYN_REPORT, 0)
    emit(EV_KEY, BTN_LEFT, 0)
    emit(EV_SYN, SYN_REPORT, 0)
    time.sleep(0.2)
finally:
    try:
        fcntl.ioctl(fd, UI_DEV_DESTROY)
    finally:
        os.close(fd)
PY
}

click_at() {
  local x="$1"
  local y="$2"

  move_cursor "$x" "$y"
  sleep 0.5
  click_current_pointer
  sleep 0.3
}

click_notification_expand() {
  local layer="$1"
  local x=$(($(jq -r '.x' <<<"$layer") + $(jq -r '.w' <<<"$layer") - 68))
  local y=$(($(jq -r '.y' <<<"$layer") + 66))

  click_at "$x" "$y"
}

click_notification_action() {
  local layer="$1"
  local x=$(($(jq -r '.x' <<<"$layer") + 36))
  local y=$(($(jq -r '.y' <<<"$layer") + $(jq -r '.h' <<<"$layer") - 20))

  click_at "$x" "$y"
}

click_notification_default_action() {
  local layer="$1"
  local x=$(($(jq -r '.x' <<<"$layer") + 120))
  local y=$(($(jq -r '.y' <<<"$layer") + 66))

  click_at "$x" "$y"
}

click_clear_all() {
  local layer="$1"
  local x=$(($(jq -r '.x' <<<"$layer") + $(jq -r '.w' <<<"$layer") - 45))
  local y=$(($(jq -r '.y' <<<"$layer") + 24))

  click_at "$x" "$y"
}

move_cursor_outside_stack() {
  local monitor="$1"
  local geometry
  local monitor_x
  local monitor_y
  local monitor_height

  geometry="$(monitor_geometry "$monitor")"
  read -r monitor_x monitor_y _ monitor_height <<<"$geometry"
  move_cursor "$((monitor_x + 20))" "$((monitor_y + monitor_height / 2))"
}

fullscreen_state() {
  hyprctl activewindow -j 2>/dev/null | jq -r '.fullscreen // 0' 2>/dev/null ||
    printf '0\n'
}

wait_for_fullscreen_state() {
  local expected="$1"
  local state

  for _ in $(seq 1 40); do
    state="$(fullscreen_state)"
    if [[ "$expected" == on && "$state" != 0 ]]; then
      return 0
    fi
    if [[ "$expected" == off && "$state" == 0 ]]; then
      return 0
    fi
    sleep 0.1
  done

  return 1
}

reload_event_count() {
  qs log --pid "$QS_PID" --tail 500 2>/dev/null |
    grep -c 'Reloading configuration' || true
}

qs_process_is_present() {
  qs list --all --json 2>/dev/null |
    jq -e --arg pid "$QS_PID" 'any(.[]; (.pid | tostring) == $pid)' >/dev/null
}

restore_reload_file() {
  if [[ -z "$RELOAD_BACKUP" ]]; then
    return 0
  fi

  if [[ -f "$RELOAD_BACKUP" ]]; then
    cp -- "$RELOAD_BACKUP" "$RELOAD_FILE"
    touch -r "$RELOAD_BACKUP" "$RELOAD_FILE"
    rm -f "$RELOAD_BACKUP"
  fi
  RELOAD_BACKUP=""
}

preflight() {
  local owner_process

  require_command qs
  require_command notify-send
  require_command busctl
  require_command gdbus
  require_command grimblast
  require_command timeout

  if [[ "$CASE_NAME" == all || "$CASE_NAME" == image ]]; then
    require_command magick
  fi

  if case_needs_hyprland; then
    require_command hyprctl
    require_command jq
  fi

  if case_needs_clicks; then
    require_command python3
    [[ -w /dev/uinput ]] ||
      fail "/dev/uinput is not writable; refusing to synthesize notification clicks"
  fi

  if [[ "$CASE_NAME" == reload || "$CASE_NAME" == all || "$CASE_NAME" == interactions ]]; then
    [[ -f "$RELOAD_FILE" ]] || fail "reload target does not exist: $RELOAD_FILE"
    require_command cp
    require_command mktemp
    require_command touch
  fi

  printf '%s\n' '--- Quickshell instances ---'
  qs list --all --json

  owner_process="$(busctl --user list 2>/dev/null |
    awk '$1 == "org.freedesktop.Notifications" && !found { print $3; found = 1 }')"
  [[ "$owner_process" == qs ]] ||
    fail "org.freedesktop.Notifications is owned by '$owner_process', not qs"

  if pgrep -x dunst >/dev/null 2>&1; then
    fail "Dunst is running; stop it before running native-server tests"
  fi

  if case_needs_hyprland; then
    INITIAL_CURSOR_X="$(hyprctl cursorpos -j | jq -r '.x')"
    INITIAL_CURSOR_Y="$(hyprctl cursorpos -j | jq -r '.y')"
    INITIAL_MONITOR="$(hyprctl monitors -j |
      jq -r '.[] | select(.focused == true) | .name' | head -n 1)"
    OTHER_MONITOR="$(hyprctl monitors -j |
      jq -r --arg initial "$INITIAL_MONITOR" '.[] | select(.name != $initial) | .name' |
      head -n 1)"

    [[ "$INITIAL_CURSOR_X" =~ ^-?[0-9]+$ && "$INITIAL_CURSOR_Y" =~ ^-?[0-9]+$ ]] ||
      fail "could not save the current pointer position"
    [[ -n "$INITIAL_MONITOR" ]] || fail "could not determine the focused monitor"

    QS_PID="$(qs list --all --json |
      jq -r --arg path "$CONFIG_DIR/home/shell.qml" \
        '.[] | select(.config_path == $path) | .pid' | head -n 1)"
    [[ "$QS_PID" =~ ^[0-9]+$ ]] ||
      fail "could not identify the existing shell process for $CONFIG_DIR/home/shell.qml"
  fi

  printf '%s\n' 'PASS: existing qs owns org.freedesktop.Notifications and Dunst is stopped'
  if [[ -n "$INITIAL_MONITOR" ]]; then
    printf 'saved pointer: %s,%s; focused monitor: %s\n' \
      "$INITIAL_CURSOR_X" "$INITIAL_CURSOR_Y" "$INITIAL_MONITOR"
  fi
}

cleanup() {
  set +e

  restore_reload_file

  if ((FULLSCREEN_ACTIVE)); then
    if [[ "$(fullscreen_state)" != 0 ]]; then
      hyprctl dispatch 'hl.dsp.window.fullscreen()' >/dev/null 2>&1 || true
    fi
    FULLSCREEN_ACTIVE=0
  fi

  for id in "${TEST_IDS[@]}"; do
    close_notification "$id"
  done

  for pid in "${SENDER_PIDS[@]}" "${MONITOR_PIDS[@]}"; do
    if [[ -n "$pid" ]] && kill -0 "$pid" 2>/dev/null; then
      kill "$pid" 2>/dev/null
      wait "$pid" 2>/dev/null
    fi
  done

  if [[ -n "$INITIAL_MONITOR" ]]; then
    hyprctl dispatch "hl.dsp.focus({ monitor = \"$INITIAL_MONITOR\" })" >/dev/null 2>&1 || true
  fi
  restore_pointer
}

trap cleanup EXIT INT TERM

while [[ $# -gt 0 ]]; do
  case "$1" in
    --case)
      [[ $# -ge 2 ]] || fail "--case requires a value"
      CASE_NAME="$2"
      shift 2
      ;;
    --output-dir)
      [[ $# -ge 2 ]] || fail "--output-dir requires a path"
      OUTPUT_DIR="$2"
      shift 2
      ;;
    -h | --help)
      usage
      exit 0
      ;;
    *)
      fail "unknown argument: $1"
      ;;
  esac
done

mkdir -p "$OUTPUT_DIR"

case_basic() {
  printf '%s\n' 'CASE basic: normal summary/body display'
  send_notification -t 5000 'Quickshell basic test' 'Summary and body'
  sleep 0.7
  capture_screen basic.png
  close_notification "$LAST_ID"
  if [[ -n "$INITIAL_MONITOR" ]]; then
    wait_for_all_notification_layers_absent ||
      fail 'basic notification surface remained visible after close'
  fi
  printf '%s\n' 'EXPECTED: one visible top-right card contains the supplied summary and body.'
}

case_expiry() {
  local monitor_file="$OUTPUT_DIR/expiry-monitor.txt"
  local id

  printf '%s\n' 'CASE expiry: positive millisecond timeout'
  start_close_monitor "$monitor_file"
  send_notification -t 1200 'Quickshell expiry test' 'Expected Expired close reason'
  id="$LAST_ID"

  if ! wait_for_signal "$monitor_file" "NotificationClosed (uint32 $id, uint32 1)" 6; then
    report_monitor_failure "$monitor_file"
    fail "notification $id did not emit Expired close reason; see $monitor_file"
  fi
  stop_last_monitor
  printf '%s\n' 'PASS: D-Bus close reason 1 (Expired) observed'
  printf '%s\n' 'EXPECTED: the 1200ms timeout expires automatically without pointer input.'
}

case_persistent_close() {
  local monitor_file="$OUTPUT_DIR/persistent-close-monitor.txt"
  local id

  printf '%s\n' 'CASE persistent-close: native CloseNotification'
  start_close_monitor "$monitor_file"
  send_notification -t 0 'Quickshell persistent test' 'Will be closed natively'
  id="$LAST_ID"
  sleep 0.6
  close_notification "$id"

  if ! wait_for_signal "$monitor_file" "NotificationClosed (uint32 $id, uint32 3)" 6; then
    report_monitor_failure "$monitor_file"
    fail "notification $id did not emit CloseRequested reason; see $monitor_file"
  fi
  stop_last_monitor
  if [[ -n "$INITIAL_MONITOR" ]]; then
    wait_for_all_notification_layers_absent ||
      fail 'persistent notification surface remained visible after close'
  fi
  printf '%s\n' 'PASS: D-Bus close reason 3 (CloseRequested) observed'
  printf '%s\n' 'EXPECTED: -t 0 remains active until the explicit native close.'
}

case_replacement() {
  local id

  printf '%s\n' 'CASE replacement: in-place update'
  send_notification -t 0 'Replacement first' 'Original body'
  id="$LAST_ID"
  sleep 0.3
  notify-send -r "$id" -t 3500 \
    'Replacement updated' \
    'Updated body with a longer replacement payload'
  sleep 0.6
  capture_screen replacement.png
  close_notification "$id"
  if [[ -n "$INITIAL_MONITOR" ]]; then
    wait_for_all_notification_layers_absent ||
      fail 'replacement notification surface remained visible after close'
  fi
  printf '%s\n' 'EXPECTED: one card is updated in place, keeps its list position, and shows the replacement content.'
}

case_markup() {
  printf '%s\n' 'CASE markup: rich body and hyperlink'
  send_notification -t 6000 'Markup and hyperlink' \
    '<b>Bold</b> and <i>italic</i> with <a href="https://example.com">a link</a>'
  sleep 0.7
  capture_screen markup.png
  close_notification "$LAST_ID"
  if [[ -n "$INITIAL_MONITOR" ]]; then
    wait_for_all_notification_layers_absent ||
      fail 'markup notification surface remained visible after close'
  fi
  printf '%s\n' 'EXPECTED: bold, italic, and an underlined link are visible; no browser is opened by this script.'
}

case_image() {
  local image_path="$OUTPUT_DIR/notification.png"

  printf '%s\n' 'CASE image: regular image-path hint'
  magick -size 640x360 gradient:'#d7827e-#286983' "$image_path"
  send_notification -t 5000 \
    -h "string:image-path:$image_path" \
    'Regular image test' \
    'Image should replace the collapsed app icon'
  sleep 0.8
  capture_screen image.png
  close_notification "$LAST_ID"
  if [[ -n "$INITIAL_MONITOR" ]]; then
    wait_for_all_notification_layers_absent ||
      fail 'image notification surface remained visible after close'
  fi
  printf '%s\n' 'EXPECTED: the generated image appears as the collapsed 32x32 leading preview.'
}

case_actions() {
  local monitor_file="$OUTPUT_DIR/actions-monitor.txt"
  local action_output="$OUTPUT_DIR/action-result.txt"
  local resident_output="$OUTPUT_DIR/resident-action-result.txt"
  local default_output="$OUTPUT_DIR/default-action-result.txt"
  local monitor="$INITIAL_MONITOR"
  local id
  local layer
  local collapsed_height

  printf '%s\n' 'CASE actions: expansion, non-resident action, resident action, and default action'
  assert_clean_surface

  start_close_monitor "$monitor_file" 12s
  send_action_notification "$action_output" false later Later \
    'Action expansion test' \
    'Expand this card to reveal the Later action.'
  id="$LAST_ID"
  layer="$(wait_for_notification_layer "$monitor")" || {
    report_monitor_failure "$monitor_file"
    fail "action notification $id did not become visible on $monitor"
  }
  collapsed_height="$(jq -r '.h' <<<"$layer")"
  click_notification_expand "$layer"
  layer="$(wait_for_notification_height_greater "$monitor" "$collapsed_height")" || {
    report_monitor_failure "$monitor_file"
    fail "action notification $id did not expand"
  }
  capture_screen actions.png
  click_notification_action "$layer"

  if ! wait_for_signal "$monitor_file" "ActionInvoked (uint32 $id, 'later')" 6; then
    report_monitor_failure "$monitor_file"
    fail "non-resident action was not invoked for notification $id"
  fi
  if ! wait_for_signal "$monitor_file" "NotificationClosed (uint32 $id, uint32 2)" 6; then
    report_monitor_failure "$monitor_file"
    fail "non-resident action did not close notification $id with Dismissed reason"
  fi
  stop_last_monitor
  wait_for_notification_layer_absent "$monitor" ||
    fail "non-resident action notification surface remained visible"
  printf '%s\n' 'PASS: expansion and non-resident action invocation emitted ActionInvoked and Dismissed'

  start_close_monitor "$monitor_file" 12s
  send_action_notification "$resident_output" true later Later \
    'Resident action test' \
    'Resident notifications remain after their action is invoked.'
  id="$LAST_ID"
  layer="$(wait_for_notification_layer "$monitor")" || {
    report_monitor_failure "$monitor_file"
    fail "resident action notification $id did not become visible"
  }
  collapsed_height="$(jq -r '.h' <<<"$layer")"
  click_notification_expand "$layer"
  layer="$(wait_for_notification_height_greater "$monitor" "$collapsed_height")" ||
    fail "resident action notification $id did not expand"
  click_notification_action "$layer"

  if ! wait_for_signal "$monitor_file" "ActionInvoked (uint32 $id, 'later')" 6; then
    report_monitor_failure "$monitor_file"
    fail "resident action was not invoked for notification $id"
  fi
  sleep 0.8
  if grep -Fq -- "NotificationClosed (uint32 $id," "$monitor_file"; then
    report_monitor_failure "$monitor_file"
    fail "resident notification $id closed when its action was invoked"
  fi
  close_notification "$id"
  if ! wait_for_signal "$monitor_file" "NotificationClosed (uint32 $id, uint32 3)" 6; then
    report_monitor_failure "$monitor_file"
    fail "resident notification $id did not close after explicit native close"
  fi
  stop_last_monitor
  wait_for_notification_layer_absent "$monitor" ||
    fail 'resident action notification surface remained visible after native close'
  printf '%s\n' 'PASS: resident action invocation retained the notification until native close'

  start_close_monitor "$monitor_file" 12s
  send_action_notification "$default_output" false default Open \
    'Default action test' \
    'Clicking the card invokes its default action.'
  id="$LAST_ID"
  layer="$(wait_for_notification_layer "$monitor")" || {
    report_monitor_failure "$monitor_file"
    fail "default action notification $id did not become visible"
  }
  click_notification_default_action "$layer"

  if ! wait_for_signal "$monitor_file" "ActionInvoked (uint32 $id, 'default')" 6; then
    report_monitor_failure "$monitor_file"
    fail "default action was not invoked for notification $id"
  fi
  if ! wait_for_signal "$monitor_file" "NotificationClosed (uint32 $id, uint32 2)" 6; then
    report_monitor_failure "$monitor_file"
    fail "default action did not close notification $id with Dismissed reason"
  fi
  stop_last_monitor
  wait_for_notification_layer_absent "$monitor" ||
    fail "default action notification surface remained visible"
  restore_pointer
  printf '%s\n' 'PASS: default action invocation emitted ActionInvoked and Dismissed'
}

case_urgencies() {
  local low normal critical

  printf '%s\n' 'CASE urgencies: low, normal, critical styling and order'
  send_notification -t 0 -u low 'Low urgency test' 'Muted accent'
  low="$LAST_ID"
  send_notification -t 0 -u normal 'Normal urgency test' 'Rose accent'
  normal="$LAST_ID"
  send_notification -t 0 -u critical 'Critical urgency test' 'Love accent; persistent by default'
  critical="$LAST_ID"
  sleep 0.8
  capture_screen urgencies.png
  close_notification "$low"
  close_notification "$normal"
  close_notification "$critical"
  if [[ -n "$INITIAL_MONITOR" ]]; then
    wait_for_all_notification_layers_absent ||
      fail 'urgency notification surface remained visible after close'
  fi
  printf '%s\n' 'EXPECTED: low uses muted styling, normal rose, critical love; newest cards are at the bottom of one stack.'
}

case_hover() {
  local monitor_file="$OUTPUT_DIR/hover-monitor.txt"
  local monitor="$INITIAL_MONITOR"
  local layer
  local id

  printf '%s\n' 'CASE hover: pause while hovered, resume after leaving'
  assert_clean_surface
  focus_monitor "$monitor"
  start_close_monitor "$monitor_file" 12s
  send_notification -t 2500 'Hover pause test' 'The timeout must pause while the drawer is hovered.'
  id="$LAST_ID"
  layer="$(wait_for_notification_layer "$monitor")" || {
    report_monitor_failure "$monitor_file"
    fail "hover notification $id did not become visible"
  }
  move_cursor \
    "$(($(jq -r '.x' <<<"$layer") + $(jq -r '.w' <<<"$layer") / 2))" \
    "$(($(jq -r '.y' <<<"$layer") + $(jq -r '.h' <<<"$layer") / 2))"
  sleep 3.5

  if grep -Fq -- "NotificationClosed (uint32 $id," "$monitor_file"; then
    report_monitor_failure "$monitor_file"
    fail "hovered notification $id closed before the pointer left the drawer"
  fi

  move_cursor_outside_stack "$monitor"
  if ! wait_for_signal "$monitor_file" "NotificationClosed (uint32 $id, uint32 1)" 8; then
    report_monitor_failure "$monitor_file"
    fail "notification $id did not resume and expire after leaving the drawer"
  fi
  stop_last_monitor
  wait_for_notification_layer_absent "$monitor" ||
    fail 'hover notification surface remained visible after expiry'
  restore_pointer
  printf '%s\n' 'PASS: hover paused expiry and leaving the drawer resumed it with Expired close reason'
}

case_clear_all() {
  local monitor_file="$OUTPUT_DIR/clear-all-monitor.txt"
  local monitor="$INITIAL_MONITOR"
  local layer
  local first second third

  printf '%s\n' 'CASE clear-all: header button dismisses every test notification'
  assert_clean_surface
  focus_monitor "$monitor"
  start_close_monitor "$monitor_file" 12s
  send_notification -t 0 'Clear-all one' 'First persistent notification'
  first="$LAST_ID"
  send_notification -t 0 'Clear-all two' 'Second persistent notification'
  second="$LAST_ID"
  send_notification -t 0 'Clear-all three' 'Third persistent notification'
  third="$LAST_ID"
  layer="$(wait_for_notification_layer "$monitor")" || {
    report_monitor_failure "$monitor_file"
    fail 'clear-all notifications did not become visible'
  }
  click_clear_all "$layer"

  for id in "$first" "$second" "$third"; do
    if ! wait_for_signal "$monitor_file" "NotificationClosed (uint32 $id, uint32 2)" 6; then
      report_monitor_failure "$monitor_file"
      fail "clear-all did not dismiss notification $id"
    fi
  done
  if ! wait_for_notification_layer_absent "$monitor"; then
    fail 'clear-all left a notification surface visible'
  fi
  stop_last_monitor
  restore_pointer
  printf '%s\n' 'PASS: clear-all dismissed all three test cards through the native notification objects'
}

case_routing() {
  local monitor_file="$OUTPUT_DIR/routing-monitor.txt"
  local target="$OTHER_MONITOR"
  local layer
  local id

  printf '%s\n' 'CASE routing: focused-monitor notification placement'
  if [[ -z "$target" ]]; then
    printf '%s\n' 'SKIP: monitor routing needs at least two active monitors.'
    return 0
  fi
  if monitor_has_fullscreen "$target"; then
    printf '%s\n' "SKIP: monitor routing target $target is fullscreen; refusing to disturb it."
    return 0
  fi

  assert_clean_surface
  focus_monitor "$target"
  start_close_monitor "$monitor_file" 8s
  send_notification -t 0 'Monitor routing test' "Routed to focused monitor $target"
  id="$LAST_ID"
  layer="$(wait_for_notification_layer "$target")" || {
    report_monitor_failure "$monitor_file"
    fail "notification $id did not route to focused monitor $target"
  }
  if [[ -n "$(notification_layer "$INITIAL_MONITOR")" ]]; then
    fail "notification $id appeared on $INITIAL_MONITOR instead of only $target"
  fi
  close_notification "$id"
  if ! wait_for_notification_layer_absent "$target"; then
    fail "routed notification surface remained visible on $target"
  fi
  stop_last_monitor
  focus_monitor "$INITIAL_MONITOR"
  restore_pointer
  printf '%s\n' "PASS: notification $id rendered on focused monitor $target and not $INITIAL_MONITOR"
}

case_fullscreen() {
  local monitor_file="$OUTPUT_DIR/fullscreen-monitor.txt"
  local monitor="$INITIAL_MONITOR"
  local active_window
  local initial_fullscreen
  local layer
  local id

  printf '%s\n' 'CASE fullscreen: suppress while fullscreen, reveal after leaving fullscreen'
  assert_clean_surface
  focus_monitor "$monitor"
  active_window="$(hyprctl activewindow -j)"
  initial_fullscreen="$(jq -r '.fullscreen // 0' <<<"$active_window")"
  if [[ "$(jq -r '.address // empty' <<<"$active_window")" == "" ]]; then
    printf '%s\n' 'SKIP: fullscreen coverage needs an active window.'
    return 0
  fi
  if [[ "$initial_fullscreen" != 0 ]]; then
    printf '%s\n' 'SKIP: refusing to toggle an already-fullscreen active window.'
    return 0
  fi

  start_close_monitor "$monitor_file" 12s
  hyprctl dispatch 'hl.dsp.window.fullscreen()' >/dev/null
  FULLSCREEN_ACTIVE=1
  wait_for_fullscreen_state on || fail 'active window did not enter fullscreen'
  sleep 0.5
  send_notification -t 0 'Fullscreen suppression test' 'This card should appear after fullscreen ends.'
  id="$LAST_ID"
  sleep 0.8
  if [[ -n "$(notification_layer "$monitor")" ]]; then
    fail "notification $id was visible while fullscreen was active"
  fi
  capture_screen fullscreen-suppressed.png

  hyprctl dispatch 'hl.dsp.window.fullscreen()' >/dev/null
  wait_for_fullscreen_state off || fail 'active window did not leave fullscreen'
  FULLSCREEN_ACTIVE=0
  layer="$(wait_for_notification_layer "$monitor")" || {
    report_monitor_failure "$monitor_file"
    fail "queued notification $id did not reveal after fullscreen ended"
  }
  capture_screen fullscreen-revealed.png
  close_notification "$id"
  wait_for_notification_layer_absent "$monitor" ||
    fail 'fullscreen-revealed notification surface remained visible after close'
  stop_last_monitor
  restore_pointer
  printf '%s\n' 'PASS: queued notification stayed suppressed in fullscreen and revealed after fullscreen ended'
}

case_reload() {
  local monitor="$INITIAL_MONITOR"
  local monitor_file="$OUTPUT_DIR/reload-monitor.txt"
  local layer
  local before
  local after
  local id

  printf '%s\n' 'CASE reload: retain active notification across QML hot reload'
  assert_clean_surface
  focus_monitor "$monitor"
  start_close_monitor "$monitor_file" 12s
  send_notification -t 0 'Hot reload retention test' 'This active card must survive a normal QML reload.'
  id="$LAST_ID"
  layer="$(wait_for_notification_layer "$monitor")" || {
    report_monitor_failure "$monitor_file"
    fail "reload notification $id did not become visible"
  }

  before="$(reload_event_count)"
  RELOAD_BACKUP="$(mktemp)"
  cp -- "$RELOAD_FILE" "$RELOAD_BACKUP"
  touch -r "$RELOAD_FILE" "$RELOAD_BACKUP"
  printf '\n' >>"$RELOAD_FILE"

  after="$before"
  for _ in $(seq 1 60); do
    after="$(reload_event_count)"
    if ((after > before)); then
      break
    fi
    if ! qs_process_is_present; then
      fail "the existing qs process disappeared during hot reload"
    fi
    sleep 0.1
  done
  if ((after <= before)); then
    report_monitor_failure "$monitor_file"
    fail 'touching the existing QML tree did not produce a hot reload'
  fi
  if ! qs_process_is_present; then
    fail 'hot reload changed the existing qs process identity'
  fi

  restore_reload_file
  sleep 0.8
  if [[ -z "$(notification_layer "$monitor")" ]]; then
    fail "notification $id was lost during or after hot reload"
  fi
  if grep -Fq -- "NotificationClosed (uint32 $id," "$monitor_file"; then
    report_monitor_failure "$monitor_file"
    fail "notification $id closed during hot reload"
  fi
  capture_screen reload.png
  close_notification "$id"
  wait_for_notification_layer_absent "$monitor" ||
    fail 'hot-reload notification surface remained visible after close'
  stop_last_monitor
  restore_pointer
  printf '%s\n' "PASS: existing qs pid $QS_PID hot-reloaded and retained notification $id"
}

case_interactions() {
  case_hover
  case_actions
  case_clear_all
  case_routing
  case_fullscreen
  case_reload
}

run_case() {
  case "$1" in
    preflight)
      preflight
      ;;
    basic)
      case_basic
      ;;
    expiry)
      case_expiry
      ;;
    persistent-close)
      case_persistent_close
      ;;
    replacement)
      case_replacement
      ;;
    markup)
      case_markup
      ;;
    image)
      case_image
      ;;
    actions)
      case_actions
      ;;
    urgencies)
      case_urgencies
      ;;
    hover)
      case_hover
      ;;
    clear-all)
      case_clear_all
      ;;
    routing)
      case_routing
      ;;
    fullscreen)
      case_fullscreen
      ;;
    reload)
      case_reload
      ;;
    interactions)
      case_interactions
      ;;
    all)
      preflight
      case_basic
      case_expiry
      case_persistent_close
      case_replacement
      case_markup
      case_image
      case_actions
      case_urgencies
      case_interactions
      ;;
    *)
      fail "unknown case: $1"
      ;;
  esac
}

preflight
if [[ "$CASE_NAME" == all ]]; then
  case_basic
  case_expiry
  case_persistent_close
  case_replacement
  case_markup
  case_image
  case_actions
  case_urgencies
  case_interactions
elif [[ "$CASE_NAME" != preflight ]]; then
  run_case "$CASE_NAME"
fi

printf '%s\n' "PASS: notification test case '$CASE_NAME' completed"
