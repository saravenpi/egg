# 🥚 egg — one-shot(tmux) layout hatcher

> Crack it open and happy coding !

`egg` reads a **tiny layout file** and instantly **hatches** a complete `tmux` session: one tab per line, each optionally running its own command.
Perfect for jumping into a project with editor, server, build, logs… already peeled and ready.

---

## Features

* **Zero dependencies** (Bash ≥ 4 + `tmux`)
* Reads a **minimal, comment-friendly** layout syntax
  `tab_name : path/to/dir [command …]`
* Falls back to a blank session if no `egg.yml` is found
* Auto-attaches (or switches) whether you’re already inside tmux or not
* Names the session in one keystroke: `egg mysession`

---

## Installation

Paste this one line in your terminal:
```bash
curl -fsSL https://raw.githubusercontent.com/saravenpi/egg/main/install.sh | bash
```

Optional quality-of-life:

```bash
alias e='egg' # one letter, endless convenience
```

---

## Layout syntax

A layout file is a list of tabs, one per line.
```conf
# tab_name : path/to/dir [optional command]
editor: . nvim
server: ./backend python -m http.server
```

*   **Colon separates** the tab name from the rest of the line.
*   The **first word** after the colon is the **directory** where commands will run.
*   **Anything after the directory** is the command to execute.

### Splitting Panes

Chain commands to split a tab into multiple panes. `egg` uses special separators for this:

*   `&&` or `&&v`: Creates a **vertical split** (a new pane to the right).
*   `&&h`: Creates a **horizontal split** (a new pane below).

The first command runs in the initial pane. Each subsequent command splits the *most recently created pane*.

**Example:**
```conf
# One tab with editor, git, and system monitor
dev: . nvim &&v git status &&h btm
```
This creates a `dev` tab with `nvim` on the left, `git status` in a pane on the right, and `btm` in a pane below `git status`.

---

## Usage

```bash
# In your project root (with egg.yml)
egg my-session

# Use a custom layout file
egg my-session ./path/to/layout.yml

# No layout file? `egg` creates a blank session
egg scratch
```

If you're already in a `tmux` session, `egg` will switch to the hatched session. If not, it will attach to it.

---

## Demo

**1. Simple two-tab layout:**
```bash
echo -e "code: .
logs: /var/log" > egg.yml
egg my-project
```
This gives you a `tmux` session with a `code` tab (in the current directory) and a `logs` tab.

**2. Single tab with split panes:**
```bash
echo "dev: . nvim &&v git status &&h btm" > egg.yml
egg my-dev-env
```
This creates one `dev` tab, split into three panes for your editor, git, and a monitoring tool, with each command running automatically.

---


## Compatibility

* Tested on Bash 4+ (Linux) and macOS (zsh/ Bash shim).
* Requires tmux ≥ 2.1 (for `switch-client`).

---

## License

MIT — see `LICENSE` file.

---

## Why “egg”?

Because it **lays** down your whole workspace in one command,
and because “*hatching sessions*” sounded cooler than “tmux-layout-launcher-thing”.

Crack it open and happy coding! 🐣
