# macOS Installation Plan

This config was originally set up on Ubuntu (see `README.md`). This document describes how to install it on macOS with Homebrew.

## 1. System packages (Ubuntu `apt` → Homebrew)

```bash
brew install neovim ripgrep luarocks
brew install --cask font-jetbrains-mono-nerd-font   # or any Nerd Font, set it in your terminal
```

Translation of the Ubuntu package list:

| Ubuntu package | macOS equivalent |
|---|---|
| `neovim` (appimage, 0.11.x) | `brew install neovim` — brew ships current stable, no appimage workaround needed |
| `nodejs npm` | `brew install node` (skip if already installed) |
| `python3-pip python3-venv` | Included with `brew install python` (skip if already installed) |
| `gcc` | Xcode Command Line Tools (clang) — usually already present; treesitter compiles fine |
| `ripgrep` | `brew install ripgrep` — required by telescope/NvChad search |
| `unzip` | Built into macOS |
| `xclip` | **Not needed** — nvim uses `pbcopy`/`pbpaste` natively |
| — | `brew install luarocks` — required for Mason to build `luacheck` (common install failure without it) |

## 2. Copy the config

```bash
mkdir -p ~/.config
cp -R ~/workspace/nvim ~/.config/nvim
```

Note: this is a snapshot — changes in `~/.config/nvim` and the repo will drift apart. Re-copy (or switch to a symlink: `ln -s ~/workspace/nvim ~/.config/nvim`) to sync them later.

## 3. First launch

```bash
nvim
```

- `lazy.nvim` bootstraps itself and installs plugins from `lazy-lock.json`.
- Mason auto-installs LSPs / linters / formatters / DAP adapters via the three bridges (may take a minute; check `:Mason`).
- On the first buffer with spell enabled, nvim will prompt to download the `en_gb` spell file — accept.

## 4. Verify

- `:checkhealth` — clipboard, node, and python providers should be OK
- `:Lazy` — all plugins installed
- `:Mason` — expect: `lua-language-server`, `pyright`, `luacheck`, `mypy`, `ruff`, `stylua`, `isort`, `black`, `debugpy`
- Open a `.py` file — LSP attaches, format-on-save works

## Optional: open nvim in a new iTerm2 window

A zsh function in `~/.zshrc` makes `nvim` open in a fresh iTerm2 window (keeping the current directory and file arguments). Use `command nvim` to run it in the current window instead.

```zsh
# Open neovim in a new iTerm2 window, keeping cwd and passing file args.
# "command nvim" inside the new window bypasses this function (avoids recursion).
nvim() {
    local cmd="cd ${(qq)PWD} && command nvim ${(qq)@}"
    # Escape for the AppleScript string literal
    cmd=${cmd//\\/\\\\}
    cmd=${cmd//\"/\\\"}
    osascript >/dev/null <<EOF
tell application "iTerm"
    activate
    tell current session of (create window with default profile)
        write text "$cmd"
    end tell
end tell
EOF
}
```

## Notes

- Everything else in the config is OS-agnostic — Mason paths under `~/.local/share/nvim` are identical on macOS (e.g. the `debugpy` path in `configs/dap-python.lua`).
- Different package managers ship different neovim versions (the Ubuntu `apt` 0.6.x problem from `README.md`); Homebrew tracks current stable, so this is not an issue on macOS.
