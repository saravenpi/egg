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

  # Handle command splitting with mixed separators (&&, &&v, &&h)
  if [[ -n "$CMD" ]]; then
    # Parse commands with different separators
    parse_commands() {
      local input="$1"
      local -a commands=()
      local -a split_types=()
      
      # Replace separators with unique markers to preserve split type info
      local marked_input
      marked_input="${input//&&h/§H§}"
      marked_input="${marked_input//&&v/§V§}"
      marked_input="${marked_input//&&/§V§}"  # Default && becomes vertical
      
      # Split on markers and rebuild command/split_type arrays
      IFS='§' read -ra PARTS <<<"$marked_input"
      local cmd=""
      local split_type=""
      
      for part in "${PARTS[@]}"; do
        if [[ "$part" == "H" ]]; then
          split_type="h"
        elif [[ "$part" == "V" ]]; then
          split_type="v"
        else
          if [[ -n "$cmd" ]]; then
            commands+=("$cmd")
            split_types+=("$split_type")
          fi
          cmd="$part"
        fi
      done
      
      # Add the last command
      if [[ -n "$cmd" ]]; then
        commands+=("$cmd")
        split_types+=("$split_type")
      fi
      
      # Execute first command in the main pane
      if [[ -n "${commands[0]}" ]]; then
        local first_cmd
        first_cmd="$(xargs <<<"${commands[0]}")"
        [[ -n "$first_cmd" ]] && "$TMUX_BIN" send-keys -t "${SESSION_NAME}:${NAME}" -- "$first_cmd" C-m
      fi
      
      # Create panes for additional commands
      for ((i=1; i<${#commands[@]}; i++)); do
        local split_cmd
        split_cmd="$(xargs <<<"${commands[i]}")"
        if [[ -n "$split_cmd" ]]; then
          local split_flag="-h"  # Default to vertical split (side by side)
          [[ "${split_types[i]}" == "h" ]] && split_flag="-v"  # Horizontal split (stacked)
          
          "$TMUX_BIN" split-window "$split_flag" -t "${SESSION_NAME}:${NAME}" -c "$PATH_EXPANDED"
          "$TMUX_BIN" send-keys -t "${SESSION_NAME}:${NAME}" -- "$split_cmd" C-m
        fi
      done
    }
    
    parse_commands "$CMD"
  fi
done

"$TMUX_BIN" select-window -t "${SESSION_NAME}:0"
attach_or_switch
