#!/usr/bin/env bash
# egg.sh – a simple tmux session launcher
set -euo pipefail

SESSION_NAME="${1:-workspace}"
LAYOUT_FILE="${2:-egg.conf}"

TMUX_BIN="$(command -v tmux || true)"
[[ -n "$TMUX_BIN" ]] || { echo "tmux not found." >&2; exit 1; }

attach_or_switch() {
  "$TMUX_BIN" attach-session -t "$SESSION_NAME" 2>/dev/null \
    || "$TMUX_BIN" switch-client -t "$SESSION_NAME"
  exit 0
}

simple_tmux() {
  if "$TMUX_BIN" has-session -t "$SESSION_NAME" 2>/dev/null; then
    attach_or_switch
  else
    "$TMUX_BIN" new-session -d -s "$SESSION_NAME"
    attach_or_switch
  fi
}

expand_path() {
  [[ $1 =~ ^~ ]] && printf '%s' "${1/#\~/$HOME}" || printf '%s' "$1"
}

[[ -f "$LAYOUT_FILE" ]] || simple_tmux

mapfile -t LINES < <(
  grep -vE '^\s*($|#)' "$LAYOUT_FILE" |
  sed 's/[[:space:]]*:[[:space:]]*/:/'
)

(( ${#LINES[@]} )) || simple_tmux

first_done=0
for line in "${LINES[@]}"; do
  IFS=':' read -r RAW_NAME REST <<<"$line"
  NAME="$(xargs <<<"$RAW_NAME")"

  REST="${REST#"${REST%%[![:space:]]*}"}"
  if [[ -z "$REST" ]]; then
    PATH_TOKEN="./"
    CMD=""
  else
    PATH_TOKEN="${REST%%[[:space:]]*}"
    CMD="${REST#"$PATH_TOKEN"}"
    CMD="${CMD#"${CMD%%[![:space:]]*}"}"
  fi
  PATH_EXPANDED="$(expand_path "$PATH_TOKEN")"

  if (( first_done == 0 )); then
    "$TMUX_BIN" new-session -d -s "$SESSION_NAME" -n "$NAME" -c "$PATH_EXPANDED"
    first_done=1
  else
    "$TMUX_BIN" new-window -t "$SESSION_NAME" -n "$NAME" -c "$PATH_EXPANDED"
  fi

  # Handle command splitting on && for vertical panes
  if [[ -n "$CMD" ]]; then
    # Split commands on && and trim whitespace
    IFS='&&' read -ra COMMANDS <<<"$CMD"
    
    # Execute first command in the main pane
    if [[ -n "${COMMANDS[0]}" ]]; then
      FIRST_CMD="$(xargs <<<"${COMMANDS[0]}")"
      [[ -n "$FIRST_CMD" ]] && "$TMUX_BIN" send-keys -t "${SESSION_NAME}:${NAME}" -- "$FIRST_CMD" C-m
    fi
    
    # Create vertical panes for additional commands
    for ((i=1; i<${#COMMANDS[@]}; i++)); do
      SPLIT_CMD="$(xargs <<<"${COMMANDS[i]}")"
      if [[ -n "$SPLIT_CMD" ]]; then
        "$TMUX_BIN" split-window -h -t "${SESSION_NAME}:${NAME}" -c "$PATH_EXPANDED"
        "$TMUX_BIN" send-keys -t "${SESSION_NAME}:${NAME}" -- "$SPLIT_CMD" C-m
      fi
    done
  fi
done

"$TMUX_BIN" select-window -t "${SESSION_NAME}:0"
attach_or_switch
