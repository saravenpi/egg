#!/usr/bin/env bash
# install-egg.sh – installs the “egg” tmux launcher so you can just type `egg`.
set -euo pipefail

SCRIPT_NAME="egg"
SRC_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SRC_PATH="${SRC_DIR}/egg.sh"

[[ -f "$SRC_PATH" ]] || {
  echo "ERROR: egg.sh not found next to install script." >&2; exit 1; }

command -v tmux >/dev/null || {
  echo "WARNING: tmux is not in PATH. egg will install, but won’t run until tmux is available." >&2; }

choose_target_dir() {
  for dir in /usr/local/bin /usr/bin "$HOME/.local/bin"; do
    [[ -d "$dir" && -w "$dir" ]] && { echo "$dir"; return; }
  done
  # try sudo install into /usr/local/bin if user can sudo non-interactively
  if command -v sudo >/dev/null && sudo -n true 2>/dev/null; then
    echo "SUDO:/usr/local/bin"
  fi
}

TARGET="$(choose_target_dir)"
[[ -n "$TARGET" ]] || { echo "ERROR: no writable install directory found." >&2; exit 1; }

install_to() {
  local dir="$1"
  local dest="$dir/$SCRIPT_NAME"
  mkdir -p "$dir"
  install -m 755 "$SRC_PATH" "$dest"
  echo "✔ Installed to $dest"
}

if [[ "$TARGET" == SUDO:* ]]; then
  sudo_dir="${TARGET#SUDO:}"
  sudo install -m 755 "$SRC_PATH" "$sudo_dir/$SCRIPT_NAME"
  echo "✔ Installed to $sudo_dir/$SCRIPT_NAME (via sudo)"
else
  install_to "$TARGET"
fi

if [[ "$TARGET" == "$HOME/.local/bin" ]]; then
  for shell_rc in "$HOME/.bashrc" "$HOME/.zshrc"; do
    if [[ -f "$shell_rc" && ! $(grep -F "$HOME/.local/bin" "$shell_rc") ]]; then
      echo 'export PATH="$PATH:$HOME/.local/bin"' >> "$shell_rc"
      echo "➕ Added ~/.local/bin to PATH in $shell_rc"
    fi
  done
fi

echo -e "\n🎉  Done!  Open a new terminal (or source your shell profile) and run:  egg mysession"

