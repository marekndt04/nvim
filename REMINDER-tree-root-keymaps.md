# Reminder: NvimTree root keymaps for exploring library packages

## Goal

After `gd` into a venv library (e.g. `from django.db import whatever`), be able to
re-root the file explorer at the library's directory on demand, explore its files,
then return the explorer to the project root.

## Context / decisions made

- `update_focused_file = { enable = true, update_root = true }` was **removed** from
  `lua/configs/nvim-tree.lua` — it made the tree root jump automatically on every
  buffer switch, showing a confusing partial package directory after `gd`.
- oil.nvim was considered as an exploration alternative and **rejected** — no extra
  plugin; solve it with nvim-tree keymaps instead.
- nvim-tree's built-in `Ctrl+]` doesn't help: it roots at the node under the *tree
  cursor*, not the buffer's file. On the root header line it goes up to the parent
  (that's why it landed on `~/workspace`). The venv is also hidden by the
  `dotfiles = true` filter and too deep to navigate manually.

## Implementation plan

All changes in `lua/configs/nvim-tree.lua` (keymap section at the bottom, next to
the existing `<leader>e` mapping).

### 1. Root tree at current file's location

Pick one variant:

**A. Immediate directory of the current file**

```lua
map("n", "<leader>ed", function()
    require("nvim-tree.api").tree.change_root(vim.fn.expand("%:p:h"))
end, { desc = "Root NvimTree at current file's directory" })
```

**B. site-packages top (fall back to immediate dir outside a venv)**

```lua
map("n", "<leader>ed", function()
    local dir = vim.fn.expand("%:p:h")
    local site_packages = dir:match("(.*/site%-packages)")
    require("nvim-tree.api").tree.change_root(site_packages or dir)
end, { desc = "Root NvimTree at site-packages (or file's dir)" })
```

### 2. Return to project root

```lua
map("n", "<leader>ew", function()
    require("nvim-tree.api").tree.change_root(vim.fn.getcwd())
end, { desc = "Root NvimTree back at project" })
```

Works because neovim-project keeps the cwd at the project root; `sync_root_with_cwd`
stays as-is for project switching.

### 3. Update README

Add the two keymaps to the keymap tables in `README.md` and a short note under
"File explorer follows project switches" explaining the on-demand re-rooting.

## Testing

1. Open a project, `gd` into a venv library symbol (e.g. Django model import).
2. `<leader>ed` → tree roots at the library dir (variant B: at `site-packages`).
3. Explore with `-` (root up) / `Ctrl+]` on a directory node (root down).
4. `<leader>ew` → tree back at the project root.
5. Switch projects via `<leader>fp` → tree still follows the new project cwd.
