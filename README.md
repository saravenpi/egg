# 🥚 egg — one-shot(tmux) layout hatcher

> Crack it open and happy coding !

`egg` reads a **tiny layout file** and instantly **hatches** a complete `tmux` session: one tab per line, each optionally running its own command.
Perfect for jumping into a project with editor, server, build, logs… already peeled and ready.

---

## Features

* **Zero dependencies** (Bash ≥ 4 + `tmux`)
* Reads a **minimal, comment-friendly** layout syntax
  `tab_name : path/to/dir [command …]`
* Falls back to a blank session if no `egg.conf` is found
* Auto-attaches (or switches) whether you’re already inside tmux or not
* Names the session in one keystroke: `egg mysession`

---

## Installation

```bash
# Quick install
curl -fsSL https://raw.githubusercontent.com/saravenpi/egg/main/install.sh | bash
```

Optional quality-of-life:

```bash
alias e='egg' # two letters, endless convenience
```

---

## Layout syntax

```conf
# tab        path            command (optional)
editor  : ./frontend         nvim
api     : ./backend          nvim
build   : ./                 make all -j4
logs    : /var/log
```

* **Colon separates** tab name and path (spaces around it don’t matter).
* **First word** after the colon is the directory; **anything after** that is
  sent verbatim to tmux (`send-keys … C-m`), so feel free to chain arguments.

---

## Usage

```bash
# in your project root (with egg.conf present)
egg dev

# custom file
egg dev ./my-other-layout.conf

# no layout? still fine — opens / attaches a blank session
egg scratch
```

Inside tmux already? `egg` will just `switch-client` for you.
Outside? It `attach`-es right in. Simple as eggs.

---

## Demo

```bash
# minimal example
echo -e "code:.\nserver:./ python -m http.server" >egg.conf
egg demo
```

You’ll land in tmux:

```
[code]    — cwd .          — your editor maybe running
[server]  — cwd ./         — python -m http.server already spinning
```

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
