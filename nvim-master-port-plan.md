# Plan: Port `macos-setup` improvements to `master`

Branch: `macos-setup` → target `master`
Goal: Apply OS-agnostic config improvements from `macos-setup` to `master`.

## Decisions

- Theme: keep `default-dark` on master (do NOT port `darcula-dark`).
- `.gitignore`: keep existing on master (macos branch deleted it; we don't).
- `MACOS_INSTALL.md`: do NOT add to master (Linux/Ubuntu is master's target).
- Apply method: per-file manual edits (fresh AI session will execute).

---

## Step 1 — CREATE new files

### `lua/configs/toggleterm.lua` (new, 43 lines)

Floating lazygit terminal with per-project instance recycling and COLORTERM
re-injection (nvim strips COLORTERM from embedded terminals, breaking lazygit
truecolor diff pane).

```lua
require("toggleterm").setup({})

local Terminal = require("toggleterm.terminal").Terminal

local lazygit = nil
local lazygit_dir = nil

local function toggle_lazygit()
    local cwd = vim.fn.getcwd()
    if lazygit and lazygit_dir ~= cwd then
        lazygit:shutdown()
        lazygit = nil
    end
    if not lazygit then
        lazygit = Terminal:new({
            cmd = "lazygit",
            dir = cwd,
            direction = "float",
            hidden = true,
            env = { COLORTERM = "truecolor" },
            float_opts = {
                border = "curved",
                width = function()
                    return math.floor(vim.o.columns * 0.9)
                end,
                height = function()
                    return math.floor(vim.o.lines * 0.85)
                end,
            },
        })
        lazygit_dir = cwd
    end
    lazygit:toggle()
end

local map = vim.keymap.set
map("n", "<leader>gg", toggle_lazygit, { desc = "Toggle lazygit" })
map("t", "<A-g>", toggle_lazygit, { desc = "Toggle lazygit" })
```

### `lua/configs/neovim-project.lua` (new, 27 lines)

Project/session manager. Discovery: `~/workspace/*` + `~/.config/nvim`.
`autosave_ignore_filetypes` REPLACES plugin defaults — keep the full list when
extending (includes `toggleterm` and `NvimTree` to avoid broken session
layouts).

```lua
require("neovim-project").setup({
    projects = {
        "~/workspace/*",
        "~/.config/nvim",
    },
    picker = {
        type = "telescope",
    },
    session_manager_opts = {
        autosave_ignore_filetypes = {
            "ccc-ui",
            "dap-repl",
            "dap-view",
            "dap-view-term",
            "gitcommit",
            "gitrebase",
            "qf",
            "toggleterm",
            "NvimTree",
        },
    },
})

local map = vim.keymap.set
map("n", "<leader>fp", "<cmd>NeovimProjectDiscover history<CR>", { desc = "Find projects" })
map("n", "<leader>fP", "<cmd>NeovimProjectLoadRecent<CR>", { desc = "Open previous project session" })
```

---


## Step 2 — EDIT existing files

### `lua/plugins/init.lua`

1. **nvim-treesitter spec** — add `branch` and `build` before `event`:
   ```lua
   {
       "nvim-treesitter/nvim-treesitter",
       branch = "main", -- master is frozen and broken on Neovim 0.12+
       build = ":TSUpdate", -- overrides NvChad's ":TSUpdate | TSInstallAll" (TSInstallAll is master-only)
       event = { "BufReadPre", "BufNewFile" },
       config = function()
           require("configs.treesitter")
       end,
   },
   ```

3. **Add** toggleterm spec (after the nvim-tree spec):
   ```lua
   {
       "akinsho/toggleterm.nvim",
       event = "VeryLazy",
       config = function()
           require("configs.toggleterm")
       end,
   },
   ```

4. **Add** neovim-project spec (after toggleterm):
   ```lua
   {
       "coffebar/neovim-project",
       lazy = false, -- required: discovers projects and restores sessions at startup
       priority = 100,
       dependencies = {
           "nvim-lua/plenary.nvim",
           "nvim-telescope/telescope.nvim",
           "Shatur/neovim-session-manager",
       },
       init = function()
           -- save global variables in sessions (plugin state)
           vim.opt.sessionoptions:append("globals")
       end,
       config = function()
           require("configs.neovim-project")
       end,
   },
   ```

### `lua/configs/treesitter.lua` — REPLACE entire contents

Rewritten for nvim-treesitter `main` branch (Neovim 0.12+ fix; `master` branch
is frozen/broken). No `configs` module; parsers installed explicitly and
highlighting started per-buffer via core APIs.

```lua
require("nvim-treesitter").install({
    "bash",
    "fish",
    "lua",
    "luadoc",
    "markdown",
    "markdown_inline",
    "printf",
    "python",
    "toml",
    "vim",
    "vimdoc",
    "yaml",
})

vim.api.nvim_create_autocmd("FileType", {
    pattern = { "sh", "bash", "fish", "lua", "markdown", "python", "toml", "vim", "yaml" },
    callback = function(args)
        vim.treesitter.start(args.buf)
        vim.bo[args.buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
    end,
})
```

### `lua/configs/nvim-tree.lua` — add cwd-following options

Add inside `setup({...})` after the `filters` block:

```lua
    sync_root_with_cwd = true,
    respect_buf_cwd = true,
    update_focused_file = {
        enable = true,
        update_root = true,
    },
```

These are **required** — they make the tree follow cwd changes when
neovim-project switches projects. Do not remove.

### `lua/mappings.lua` — add copy-path keymaps

Add before the commented-out `<C-s>` line:

```lua
map("n", "<leader>cp", function()
    local path = vim.fn.expand("%:p")
    vim.fn.setreg("+", path)
    vim.notify("Copied: " .. path)
end, { desc = "Copy absolute file path" })

map("n", "<leader>cr", function()
    local path = vim.fn.expand("%")
    vim.fn.setreg("+", path)
    vim.notify("Copied: " .. path)
end, { desc = "Copy relative file path" })
```

### `lua/autocmds.lua` — append Markview toggle

Append at the end of the file:

```lua
map("n", "<leader>mm", ":Markview toggle<CR>", opts)
```

### `lazy-lock.json` — replace with macos branch version

Replace the entire file with the version from the `macos-setup` branch. Key
changes:
- Adds: `neovim-project`, `neovim-session-manager`, `toggleterm.nvim`
- Bumps: `NvChad`, `gitsigns.nvim`, `markview.nvim`, `mason-lspconfig.nvim`,
  `nvim-lspconfig`, `nvim-tree.lua`, `nvim-treesitter` (now `main` branch),
  `nvim-web-devicons`

### `AGENTS.md` — doc updates

1. **Directory tree (§1)** — replace:
   ```
       └── rustacean.lua
   ```
   with:
   ```
       ├── rustacean.lua      # rustaceanvim mega-plugin (Rust LSP + DAP)
       ├── toggleterm.lua     # floating terminal + lazygit integration
       └── neovim-project.lua # project/session manager (projects under ~/workspace)
   ```

2. **§3.6 nvim-tree** — append after the `<leader>e` keymap line:
   ```
   - `sync_root_with_cwd`, `respect_buf_cwd`, and `update_focused_file.update_root` are **required** — they make the tree follow cwd changes when neovim-project switches projects. Do not remove them.
   ```

3. **After §3.7** (the rustaceanvim mega-plugin section), **add** §3.8:

   ```markdown
   ### 3.8 neovim-project (`configs/neovim-project.lua`)

   - Project/session manager (`coffebar/neovim-project` + `Shatur/neovim-session-manager`), picker via telescope.
   - Project roots: `~/workspace/*` and `~/.config/nvim` — extend the `projects` list for new locations.
   - Spec in `plugins/init.lua` must keep `lazy = false` + `priority = 100` (startup discovery/session restore) and the `init` block appending `globals` to `sessionoptions`.
   - `session_manager_opts.autosave_ignore_filetypes` **replaces** the plugin defaults — when adding a filetype, keep the existing list (includes `toggleterm` and `NvimTree` to avoid broken session layouts).
   - Keymaps `<leader>fp` (picker) and `<leader>fP` (previous session) live here.
   ```

   The existing §3.7 (rustaceanvim / language-specific "mega" plugins) stays unchanged.

4. **§6 Options and autocmds** — append after the `autocmds.lua` line:
   ```
   - `options.lua` sets `title` + `titlestring` (terminal title = `nvim — <cwd basename>`) so the iTerm title bar follows neovim-project switches — keep it.
   ```

### `README.md` — append two new sections

Append after the existing "Personal notes" section:

```markdown
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
```

> **Note (Linux):** the README mentions `brew install lazygit`. On Ubuntu, install lazygit from the GitHub release assets instead. The toggleterm config itself is OS-agnostic — only the `lazygit` binary on `$PATH` is required.

---

## Step 4 — Files NOT touched

- `.gitignore` — keep as-is on master.
- `lua/chadrc.lua` — keep `default-dark` theme (do NOT port `darcula-dark`).
- `MACOS_INSTALL.md` — do NOT create on master.
- `init.lua`, `lua/configs/lazy.lua` — do not touch.
- Mason bridge files — do not touch (auto-install from source-of-truth lists).

---

## Step 5 — Verify after applying

1. `:Lazy sync` — installs toggleterm, neovim-project, neovim-session-manager.
2. `:Mason` — confirm `debugpy` and `codelldb` remain available.
3. Open a `.py` file — LSP/diagnostics/format work.
4. `<leader>gg` — lazygit floats (requires `lazygit` binary on `$PATH`).
5. `<leader>fp` — project picker shows `~/workspace/*` entries.
6. Treesitter highlighting works (no `configs` module error on Neovim 0.12+).
7. `<leader>cp` / `<leader>cr` — copy path to clipboard.
8. `<leader>mm` — toggles Markview.
9. Terminal title shows `nvim — <cwd basename>`.

---

## Linux note: lazygit installation

The toggleterm config calls `lazygit` directly. On Ubuntu, install it from the
release assets:

```bash
LAZYGIT_VERSION=$(curl -s "https://api.github.com/repos/jesseduffield/lazygit/releases/latest" | grep -Po '"tag_name": "v\K[^"]*')
curl -Lo lazygit.tar.gz "https://github.com/jesseduffield/lazygit/releases/latest/download/lazygit_${LAZYGIT_VERSION}_Linux_x86_64.tar.gz"
tar xf lazygit.tar.gz lazygit
sudo install lazygit /usr/local/bin
rm lazygit lazygit.tar.gz
```

The repo's `.gitignore` already ignores `/lazygit` and `/lazygit.tar.gz` in case
you extract in-tree. No config change needed — just ensure `lazygit` is on
`$PATH`.
