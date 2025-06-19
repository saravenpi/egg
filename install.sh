#!/usr/bin/env bash
# install.sh — one-step installer: makes the “egg” tmux launcher available system-wide.
set -euo pipefail
IFS=$'\n\t'

echo "→ Starting egg installer…" ; echo

SCRIPT_NAME="egg"
REPO_URL="https://github.com/saravenpi/egg.git"
RAW_EGG="https://raw.githubusercontent.com/saravenpi/egg/main/egg.sh"

command -v bash  >/dev/null || { echo "bash not found."  >&2; exit 1; }
command -v curl  >/dev/null || { echo "curl not found."  >&2; exit 1; }
command -v tmux  >/dev/null || echo "⚠ tmux not in PATH (install it later)." >&2
command -v sudo  >/dev/null || true
command -v git   >/dev/null || GIT_MISSING=1

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" 2>/dev/null || pwd)"
LOCAL_EGG="$SCRIPT_DIR/egg.sh"
TEMP_DIR="$(mktemp -d)"
cleanup() { rm -rf "$TEMP_DIR"; }
trap cleanup EXIT

if [[ -f "$LOCAL_EGG" ]]; then
  SRC_PATH="$LOCAL_EGG"
else
  echo "→ Fetching egg.sh …"
  if [[ -z "${GIT_MISSING:-}" ]]; then
    git clone --depth 1 "$REPO_URL" "$TEMP_DIR/egg" >/dev/null
    SRC_PATH="$TEMP_DIR/egg/egg.sh"
  else
    SRC_PATH="$TEMP_DIR/egg.sh"
    curl -fsSL "$RAW_EGG" -o "$SRC_PATH"
  fi
fi

[[ -f "$SRC_PATH" ]] || { echo "ERROR: could not retrieve egg.sh" >&2; exit 1; }

choose_target_dir() {
  for d in /usr/local/bin /usr/bin "$HOME/.local/bin"; do
    [[ -d "$d" && -w "$d" ]] && { echo "$d"; return; }
  done
  if command -v sudo >/dev/null && sudo -n true 2>/dev/null; then
    echo "sudo:/usr/local/bin"
  fi
}

TARGET="$(choose_target_dir)" || true
[[ -n "${TARGET:-}" ]] || { echo "ERROR: no writable install directory." >&2; exit 1; }

install_to() {
  local dir="$1"
  mkdir -p "$dir"
  install -m 755 "$SRC_PATH" "$dir/$SCRIPT_NAME"
  echo "✔ Installed to $dir/$SCRIPT_NAME"
}

if [[ "$TARGET" == sudo:* ]]; then
  sudo_dir="${TARGET#sudo:}"
  sudo install -m 755 "$SRC_PATH" "$sudo_dir/$SCRIPT_NAME"
  echo "✔ Installed to $sudo_dir/$SCRIPT_NAME (via sudo)"
else
  install_to "$TARGET"
fi

if [[ "$TARGET" == "$HOME/.local/bin" ]]; then
  for rc in "$HOME/.bashrc" "$HOME/.zshrc"; do
    if [[ -f "$rc" && ! $(grep -F "$HOME/.local/bin" "$rc") ]]; then
      echo 'export PATH="$PATH:$HOME/.local/bin"' >> "$rc"
      echo "➕ Added ~/.local/bin to PATH in $rc"
    fi
  done
fi

echo -e "\n🎉  Installation complete!"
echo "   Open a new terminal (or re-source your shell) and run:  egg mysession"
echo
