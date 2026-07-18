# Personal Config Notice  
This is **my personal modified version** of the Lua configuration for [NvChad](https://github.com/NvChad/NvChad).  
It builds on the official NvChad setup and includes custom changes tailored to my preferences.

## Personal notes
- Be careful when installing `neovim`, as different package managers may provide different current stable versions. In my case, Ubuntu `apt` installed 0.6.x, while the recommended stable version available via `appimage` was 0.11.x.
- Many `neovim` functionalities and features require `npm`, install it right after the `neovim` installation.
```
        sudo apt update
        sudo apt install -y nodejs npm
        # and python if u missed it ;)
        sudo apt install -y python3-pip python3-venv
```
- Make sure you're using the latest version of node.js. In my case, an outdated version caused issues with pyright initialization—some JavaScript features were broken or outdated. Keep this in mind.
- The next important step is to install other useful packages, I did that using this command: `sudo apt install gcc ripgrep unzip xclip`
    - `gcc` – GNU C/C++ compiler  
    - `ripgrep` – Fast text searcher  
    - `unzip` – Extract `.zip` archives  
    - `xclip` – Clipboard access in terminal (This one is especially useful because it syncs the clipboard between Ctrl+C and yank operations.)
- The remaining configuration was based on the [ProgrammingRainbow](https://github.com/ProgrammingRainbow/NvChad-2.5?tab=readme-ov-file).
  

## Git setup

Git integration is built around [lazygit](https://github.com/jesseduffield/lazygit) running in a floating terminal via [toggleterm.nvim](https://github.com/akinsho/toggleterm.nvim), plus `gitsigns.nvim` (bundled with NvChad) for in-buffer indicators.

### Installation

lazygit is a standalone binary, managed by neither Lazy nor Mason:

```
brew install lazygit
```

The toggleterm plugin itself installs via `:Lazy sync` (spec in `lua/plugins/init.lua`, config in `lua/configs/toggleterm.lua`).

### Keymaps

| Key | Mode | Action |
|---|---|---|
| `<leader>gg` | normal | Open/toggle the lazygit float |
| `<A-g>` | terminal | Hide the float from inside lazygit (state preserved) |

Quitting lazygit with `q` closes the float entirely (`close_on_exit`). Don't bind lazygit toggles to `<leader>`-prefixed keys in terminal mode — space is lazygit's stage key, and the mapping timeout breaks it.

### Truecolor fix

Neovim strips `COLORTERM` from embedded terminals ([neovim#10836](https://github.com/neovim/neovim/issues/10836)), which breaks lazygit's truecolor detection — the diff pane loses its red/green coloring. The lazygit terminal in `lua/configs/toggleterm.lua` re-injects it via `env = { COLORTERM = "truecolor" }`. Keep this if the terminal setup ever changes.

### Untracked files hidden (PyCharm-style workflow)

Global git config hides untracked files from `git status` and therefore from lazygit's Files panel, mimicking PyCharm's "show only changed files" view:

```
git config --global status.showUntrackedFiles no
```

Consequences:

- New files must be added explicitly: `git add <path>` from a shell, or in lazygit press `Ctrl+b` → "show only untracked files", stage, then `Ctrl+b` → reset filter.
- Full status ad hoc: `git status -unormal`.
- Per-repo override (always show untracked): `git config status.showUntrackedFiles normal`.
- Undo globally: `git config --global --unset status.showUntrackedFiles`.

For personal scratch files (notes, throwaway scripts) that should never show up at all, use the repo-local, never-committed ignore file `.git/info/exclude`.

## Project management

Projects are managed by [neovim-project](https://github.com/coffebar/neovim-project) (spec in `lua/plugins/init.lua`, config in `lua/configs/neovim-project.lua`), backed by [neovim-session-manager](https://github.com/Shatur/neovim-session-manager) for per-project sessions (open tabs/buffers restored on return — PyCharm-style "reopen where I left off").

Project discovery patterns: `~/workspace/*` plus `~/.config/nvim`.

### Keymaps and commands

| Key / Command | Action |
|---|---|
| `<leader>fp` | Project picker, most recent first |
| `<leader>fP` | Reopen previous project session |
| `:NeovimProjectDiscover` | Find project by config patterns |
| `:NeovimProjectHistory` | Pick from recently opened projects |
| `Ctrl+d` in picker | Forget project + delete its session |

### Behavior notes

- Sessions save automatically on quit and on project switch.
- Starting nvim inside a project directory loads that project's session; starting elsewhere loads the most recent session (`last_session_on_startup`). The `nvim` shell function's `cd $PWD` is therefore still meaningful — it selects which project session auto-loads.
- Opening the same project in two nvim instances causes session-file overwrites — avoid; parallel *different* projects are fine.
- Opening a project in a new window is not supported by the plugin — use a new iTerm window + `nvim` in the project dir instead.
- `NvimTree` and `toggleterm` buffers are excluded from session saves (`session_manager_opts.autosave_ignore_filetypes`) to avoid broken layouts on restore.

### File explorer follows project switches

nvim-tree is configured (`lua/configs/nvim-tree.lua`) with `sync_root_with_cwd`, `respect_buf_cwd`, and `update_focused_file.update_root` so its root re-anchors when neovim-project changes the cwd. Without these, the tree keeps showing the previous project after a switch.

### Terminal title follows the project

`lua/options.lua` sets `title` + `titlestring` (`nvim — <cwd basename>`), so the iTerm title bar shows the active project name and updates on project switch. If the title bar shows the launch command instead, set the iTerm profile's Title to "Session Name" (Settings → Profiles → General).

## Markdown rendering

In-buffer markdown rendering is handled by [markview.nvim](https://github.com/OXY2DEV/markview.nvim) (spec in `lua/plugins/init.lua`, `priority = 49`, `lazy = false`).

- `<leader>mm` toggles rendering (keymap in `lua/autocmds.lua`).

