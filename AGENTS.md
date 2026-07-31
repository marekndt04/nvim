# Neovim Config — Agent Manual

This is a personal NvChad v2.5-based config. This document describes the **conventions** used so any agent can add or modify plugin configurations consistently.

Always follow these conventions verbatim. Do not introduce alternative styles (e.g. `opts = {}` for plugins that already have a dedicated config file).

---

## 1. Directory layout

```
init.lua                 # bootstrap (lazy.nvim + NvChad), do not touch unless asked
lazy-lock.json           # lockfile, do not edit manually
lua/
├── chadrc.lua           # NvChad theme/UI overrides
├── options.lua          # vim.o / vim.opt settings
├── mappings.lua         # global keymaps (loaded via vim.schedule)
├── autocmds.lua         # autocommands + buffer/markview keymaps
├── plugins/
│   └── init.lua         # SINGLE plugin spec file (lazy.nvim format)
└── configs/
    ├── lazy.lua         # lazy.nvim setup options
    ├── lspconfig.lua    # LSP server configuration
    ├── mason-lspconfig.lua
    ├── lint.lua
    ├── mason-lint.lua
    ├── conform.lua
    ├── mason-conform.lua
    ├── dap.lua
    ├── dap-ui.lua
    ├── dap-python.lua
    ├── mason-dap.lua
    ├── treesitter.lua
    ├── nvim-tree.lua
    ├── toggleterm.lua   # floating terminal + lazygit integration
    └── neovim-project.lua # project/session manager (projects under ~/workspace)
```

**Rule:** every non-trivial plugin gets its own file in `lua/configs/<plugin-name>.lua`. The `lua/plugins/init.lua` only contains the lazy spec and a `config` function that `require`s that file.

---

## 2. Plugin specification style (`lua/plugins/init.lua`)

All plugins live in a single returned table. Indentation is **4 spaces** (per `.stylua.toml`).

### 2.1 Standard plugin (with separate config file)

Use this form whenever the plugin needs any configuration beyond defaults:

```lua
{
    "author/plugin-name",
    event = "BufReadPre",            -- or other lazy trigger
    dependencies = { "dep/plugin" }, -- only if needed
    config = function()
        require("configs.plugin-name")
    end,
},
```

- **Always** use `config = function() require("configs.<name>") end`. Do **not** use `opts = { ... }` in this file when the plugin has its own config module.
- The filename in `configs/` matches the plugin's short name (e.g. `nvim-lspconfig` → `configs/lspconfig.lua`, `conform.nvim` → `configs/conform.lua`).

### 2.2 Trivial plugin (no config file)

Only when the plugin literally needs no setup, inline `opts = {}` is acceptable:

```lua
{
    "okuuva/auto-save.nvim",
    cmd = "ASToggle",
    event = { "InsertLeave", "TextChanged" },
    opts = {},
},
```

### 2.3 Extending an NvChad-provided plugin

`init.lua` imports `nvchad.plugins` *before* `plugins`, so a second spec for a plugin NvChad already ships composes with NvChad's instead of replacing it. Extend its options with an `opts` **function** — lazy calls it with NvChad's merged opts as the second argument:

```lua
{
    "nvim-telescope/telescope.nvim",
    opts = function(_, opts)
        opts.defaults = opts.defaults or {}
        opts.defaults.some_option = value
        opts.pickers = vim.tbl_deep_extend("force", opts.pickers or {}, { ... })
        return opts
    end,
},
```

- This is the exception to §2.1. Do **not** write `config = function() require("configs.telescope") end` for these — a `config` function replaces NvChad's wholesale, so its prompt icons, layout, and `extensions_list` would have to be restated by hand. §2.1 governs plugins this config owns outright.
- A plain `opts = { ... }` table is fine for adding independent keys (lazy deep-merges it), but list-like values such as `vimgrep_arguments` are replaced as a unit — use the function form whenever the new value has to be derived from, or merged into, what NvChad set.
- Verify a merge did what you expect without launching the UI:

```
nvim --headless -c "lua local p = require('lazy.core.config').plugins['telescope.nvim']
  vim.print(require('lazy.core.plugin').values(p, 'opts'))" -c 'qa!'
```

### 2.4 Lazy-loading triggers (pick the lightest one that works)

- `event = { "BufReadPre", "BufNewFile" }` — LSP, linters, treesitter
- `event = "BufWritePre"` — formatters (conform)
- `event = "VeryLazy"` — mason-* bridges, auxiliary tools
- `ft = "python"` — language-specific tools
- `cmd = "SomeCmd"` — command-triggered plugins
- `lazy = false` — only when strictly required (e.g. `markview.nvim`)

### 2.5 Dependencies

Use `dependencies = { ... }` for hard requirements. Mason bridge plugins always depend on their underlying plugin:

```lua
dependencies = { "nvim-lint" },     -- mason-nvim-lint
dependencies = { "conform.nvim" },  -- mason-conform
dependencies = { "nvim-lspconfig" },-- mason-lspconfig
```

---

## 3. Config file patterns (`lua/configs/*.lua`)

Each file is self-contained and **does its own `require("plugin").setup(...)`**. Do **not** return a table from these files — they are side-effecting modules.

### 3.1 LSP (`configs/lspconfig.lua`)

Pattern:
1. Pull NvChad defaults (`on_attach`, `on_init`, `capabilities`).
2. Append server names to `lspconfig.servers` (this list drives `mason-lspconfig` install).
3. For servers using only defaults, iterate `default_servers` and call `vim.lsp.config(name, { on_attach, on_init, capabilities })`.
4. For servers needing custom settings, call `vim.lsp.config(name, { on_attach, on_init, capabilities, settings = { ... } })` explicitly.

**Adding a new LSP server:**
- Add its name to the `lspconfig.servers` table.
- If defaults are fine, add it to `default_servers`.
- Otherwise add an explicit `vim.lsp.config("name", { ... })` block at the bottom.

Mason will pick it up automatically via `configs/mason-lspconfig.lua` — do not touch that file.

The pyright block has a custom `root_dir` function — **keep it when editing that block**. It has
three branches: (1) marker walk via `vim.fs.root` (normal project files); (2) no markers found →
reuse the root of the already-running pyright client, so library/stdlib buffers opened via
go-to-definition join the project workspace and `gd` keeps working inside site-packages
(poetry venvs live outside the project tree, so those files never have markers); (3) fallback to
the file's own directory. Removing the function or replacing it with plain `root_markers`
reintroduces the bug where navigation dies one level deep into dependencies.

The bottom of the file holds an `LspAttach` autocmd that highlights every reference of the
symbol under the cursor (`textDocument/documentHighlight` on `CursorHold`/`CursorHoldI`,
cleared on `CursorMoved`/`CursorMovedI`, per-buffer augroup). Its delay is `updatetime`,
set in `options.lua` — the two are coupled, change them together. Keep new server
registrations above this block.

### 3.2 Linting (`configs/lint.lua`)

- Configure `lint.linters_by_ft = { <ft> = { "linter1", "linter2" } }`.
- Tweak existing linters via `lint.linters.<name>.args` if needed.
- The autocmd that triggers `lint.try_lint()` is already wired — do not duplicate it.
- `configs/mason-lint.lua` auto-installs everything in `linters_by_ft`. Do not edit it when adding linters.
- The `vim.env.PATH` prepend at the top of the file is **required** — `mason.nvim` only adds its
  `bin` directory at `VeryLazy`, which is after neovim-project restores a session, so linters
  would not resolve for the `BufEnter` that fires during restore. Do not remove it.

### 3.3 Formatting (`configs/conform.lua`)

- Add formatters under `options.formatters_by_ft`.
- Per-formatter overrides go in the (currently commented) `options.formatters` table — prefer `pyproject.toml`/project-level config when possible (comment in file makes this explicit).
- `format_on_save` is a **function**, not a table: it returns `{ timeout_ms = 500, lsp_fallback = true }`,
  or `nil` (no formatting) when `vim.fs.root(bufnr, ".noautoformat")` finds that marker file in the
  buffer's project root. Keep the function form when changing format options — collapsing it back to a
  table drops the per-project opt-out.
- `configs/mason-conform.lua` auto-installs formatters — leave it alone.

### 3.4 DAP

- `configs/dap.lua` — generic DAP keymaps only.
- `configs/dap-ui.lua` — `dapui.setup()` plus open/close listeners. Do not add language-specific config here.
- `configs/dap-python.lua` — language-specific adapter setup using mason's `debugpy`. Follow this pattern for new language adapters: separate `configs/dap-<lang>.lua` file, gated by `ft = "<lang>"` in the plugin spec.
- `configs/mason-dap.lua` — add new adapters to `ensure_installed`.

### 3.5 Treesitter (`configs/treesitter.lua`)

- Add parsers to `options.ensure_installed`.
- Keep `highlight` and `indent` blocks as-is unless explicitly changing behavior.

### 3.6 nvim-tree (`configs/nvim-tree.lua`)

- Call `require("nvim-tree").setup({ ... })`.
- Includes a `VimEnter` autocmd that auto-opens the tree when nvim starts with no args.
- Includes a `User`/`SessionLoadPost` autocmd that reopens the tree after neovim-project restores a
  session — sessions never carry it (`NvimTree` is in `autosave_ignore_filetypes`, §3.7). It calls
  `wincmd p` afterwards so focus returns to the file window.
- Includes the `<leader>e` toggle keymap.
- The spec in `plugins/init.lua` must keep `lazy = false` — `defaults.lazy` is true, and both autocmds
  plus the keymap have to be registered before `VimEnter`/session restore fire.
- `sync_root_with_cwd` and `respect_buf_cwd` are **required** — they make the tree follow cwd changes
  when neovim-project switches projects. Do not remove them.
- `update_focused_file.update_root` was deliberately **removed**: it re-rooted the tree on every buffer
  switch, so jumping into a venv library with `gd` left the tree showing a partial package directory.
  Do not re-add it — on-demand re-rooting is the intended replacement.

### 3.7 neovim-project (`configs/neovim-project.lua`)

- Project/session manager (`coffebar/neovim-project` + `Shatur/neovim-session-manager`), picker via telescope.
- Project roots: `~/workspace/*` and `~/.config/nvim` — extend the `projects` list for new locations.
- Spec in `plugins/init.lua` must keep `lazy = false` + `priority = 100` (startup discovery/session restore) and the `init` block appending `globals` to `sessionoptions`.
- `session_manager_opts.autosave_ignore_filetypes` **replaces** the plugin defaults — when adding a filetype, keep the existing list (includes `toggleterm` and `NvimTree` to avoid broken session layouts).
- Keymaps `<leader>fp` (picker) and `<leader>fP` (previous session) live here.

### 3.8 csvview (`configs/csvview.lua`)

- Tabular virtual-text view for csv/tsv (`hat0uma/csvview.nvim`), loaded via `ft = { "csv", "tsv" }` + its commands.
- Plugin keymaps (field/row navigation, `if`/`af` text objects) go in the `keymaps` table of `setup()`, not `mappings.lua` — they must stay buffer-local to enabled buffers.
- The `FileType` autocmd auto-enables the view; the loop over `nvim_list_bufs()` after it covers the buffer whose `FileType` event lazy-loaded the plugin. Keep both.
- `<leader>cv` (toggle) and `<leader>ci` (info) live here.

### 3.9 Language-specific “mega” plugins

Some plugins (e.g. `rustaceanvim` for Rust) bypass `nvim-lspconfig` and `nvim-dap` setups. If one is added, configure it in its own file in `lua/configs/` using its native API.

---

## 4. Mason integration model

This config uses the **three Mason bridges**:

| Bridge | Source of truth | File |
|---|---|---|
| `mason-lspconfig` | `lspconfig.servers` (in `configs/lspconfig.lua`) | `configs/mason-lspconfig.lua` |
| `mason-nvim-lint` | `lint.linters_by_ft` (in `configs/lint.lua`) | `configs/mason-lint.lua` |
| `mason-conform` | Conform’s own registry | `configs/mason-conform.lua` |
| `mason-nvim-dap` | Hardcoded `ensure_installed` list | `configs/mason-dap.lua` |

**Important conventions:**
- `automatic_installation = false` (or `{ exclude = {} }` for DAP). Installs are derived from the canonical lists above, not from a duplicated `ensure_installed`.
- Each mason-* file has an `ignore_install = {}` table — add tool names there if a tool is unavailable on Mason but is configured manually.
- When adding a new LSP / linter / formatter, only edit the **source-of-truth** file. Never duplicate names in the mason bridge file.

---

## 5. Keymaps

- **Global keymaps that always apply** → `lua/mappings.lua` (after `require "nvchad.mappings"`).
- **Plugin-specific keymaps** → inside that plugin’s file in `lua/configs/`. Example: DAP keymaps live in `configs/dap.lua`, nvim-tree toggle in `configs/nvim-tree.lua`, markview toggles in `autocmds.lua`.
- Always use `local map = vim.keymap.set` and supply a `desc` field.

```lua
local map = vim.keymap.set
map("n", "<leader>xx", "<cmd>SomeCmd<CR>", { desc = "Short description" })
```

`<leader>` is space (set in `init.lua`).

---

## 6. Options and autocmds

- `lua/options.lua` — first line must be `require("nvchad.options")`. Append `vim.o` / `vim.opt` settings below.
- `lua/autocmds.lua` — first line must be `require("nvchad.autocmds")`. Add autocmds and a few global keymaps (buffer navigation, markview toggle) here.
- `options.lua` sets `title` + `titlestring` (terminal title = `nvim — <cwd basename>`) so the iTerm title bar follows neovim-project switches — keep it.
- `options.lua` sets `updatetime = 400` (default 4000) to drive the LSP reference highlighting in `configs/lspconfig.lua` (§3.1) — that is the delay before the highlight appears.

Do not move plugin-related autocmds (lint trigger, nvim-tree auto-open, tree reopen on session load) out of their respective `configs/` files.

---

## 7. Style rules (from `.stylua.toml`)

- 4-space indent.
- Double quotes for strings.
- Trailing commas in multi-line tables.
- `require("module")` with parentheses (not `require "module"`) **except** for the few existing NvChad-style calls in `init.lua` and `mappings.lua` — preserve those when editing, don't churn them.

---

## 8. Checklist: adding a new plugin

1. Add a spec entry to `lua/plugins/init.lua` using the standard form.
2. Create `lua/configs/<name>.lua` with the plugin’s `setup` call and any keymaps/autocmds tied to it.
3. If it’s an LSP server / linter / formatter / DAP adapter, register it in the **source-of-truth file** (see §4) — do not edit the mason bridge.
4. Restart nvim, run `:Lazy sync`, then `:Mason` to confirm installs.

## 9. Checklist: adding a new LSP server

1. Append name to `lspconfig.servers` in `configs/lspconfig.lua`.
2. Add to `default_servers` table, OR add a custom `vim.lsp.config("name", { ... })` block.
3. Done — `mason-lspconfig` auto-installs it.

## 10. Checklist: adding a new linter / formatter

- Linter: add to `lint.linters_by_ft[<ft>]` in `configs/lint.lua`.
- Formatter: add to `options.formatters_by_ft[<ft>]` in `configs/conform.lua`.
- Mason bridges handle installation automatically.
