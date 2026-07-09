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
    └── toggleterm.lua   # floating terminal + lazygit integration
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

### 2.3 Lazy-loading triggers (pick the lightest one that works)

- `event = { "BufReadPre", "BufNewFile" }` — LSP, linters, treesitter
- `event = "BufWritePre"` — formatters (conform)
- `event = "VeryLazy"` — mason-* bridges, auxiliary tools
- `ft = "python"` — language-specific tools
- `cmd = "SomeCmd"` — command-triggered plugins
- `lazy = false` — only when strictly required (e.g. `markview.nvim`)

### 2.4 Dependencies

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

### 3.2 Linting (`configs/lint.lua`)

- Configure `lint.linters_by_ft = { <ft> = { "linter1", "linter2" } }`.
- Tweak existing linters via `lint.linters.<name>.args` if needed.
- The autocmd that triggers `lint.try_lint()` is already wired — do not duplicate it.
- `configs/mason-lint.lua` auto-installs everything in `linters_by_ft`. Do not edit it when adding linters.

### 3.3 Formatting (`configs/conform.lua`)

- Add formatters under `options.formatters_by_ft`.
- Per-formatter overrides go in the (currently commented) `options.formatters` table — prefer `pyproject.toml`/project-level config when possible (comment in file makes this explicit).
- `format_on_save` is enabled with `timeout_ms = 500`, `lsp_fallback = true`.
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
- Includes the `<leader>e` toggle keymap.

### 3.7 Language-specific “mega” plugins

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

Do not move plugin-related autocmds (lint trigger, nvim-tree auto-open) out of their respective `configs/` files.

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
