return {
    {
        "rshkarin/mason-nvim-lint",
        event = "VeryLazy",
        dependencies = { "nvim-lint" },
        config = function()
            require("configs.mason-lint")
        end,
    },
    {
        "stevearc/conform.nvim",
        event = "BufWritePre",
        config = function()
            require("configs.conform")
        end,
    },

    {
        "neovim/nvim-lspconfig",
        event = { "BufReadPre", "BufNewFile" },
        config = function()
            require("nvchad.configs.lspconfig").defaults()
            require("configs.lspconfig")
        end,
    },

    {
        "nvim-treesitter/nvim-treesitter",
        branch = "main", -- master is frozen and broken on Neovim 0.12+
        build = ":TSUpdate", -- overrides NvChad's ":TSUpdate | TSInstallAll" (TSInstallAll is master-only)
        event = { "BufReadPre", "BufNewFile" },
        config = function()
            require("configs.treesitter")
        end,
    },

    {
        "zapling/mason-conform.nvim",
        event = "VeryLazy",
        dependencies = { "conform.nvim" },
        config = function()
            require("configs.mason-conform")
        end,
    },

    {
        "williamboman/mason-lspconfig.nvim",
        event = "VeryLazy",
        dependencies = { "nvim-lspconfig" },
        config = function()
            require("configs.mason-lspconfig")
        end,
    },
    {
        "okuuva/auto-save.nvim",
        -- version = '^1.0.0', -- see https://devhints.io/semver, alternatively use '*' to use the latest tagged release
        cmd = "ASToggle", -- optional for lazy loading on command
        event = { "InsertLeave", "TextChanged" }, -- optional for lazy loading on trigger events
        opts = {
            -- your config goes here
            -- or just leave it empty :)
        },
    },

    {
        "mfussenegger/nvim-lint",
        event = { "BufReadPre", "BufNewFile" },
        config = function()
            require("configs.lint")
        end,
    },

    {
        "mfussenegger/nvim-dap",
        config = function()
            require("configs.dap")
        end,
    },

    {
        "nvim-neotest/nvim-nio",
    },

    {
        "rcarriga/nvim-dap-ui",
        dependencies = {
            "mfussenegger/nvim-dap",
            "nvim-neotest/nvim-nio",
        },
        config = function()
            require("configs.dap-ui")
        end,
    },

    {
        "mfussenegger/nvim-dap-python",
        ft = "python",
        dependencies = {
            "mfussenegger/nvim-dap",
            "rcarriga/nvim-dap-ui",
        },
        config = function()
            require("configs.dap-python")
        end,
    },

    {
        "jay-babu/mason-nvim-dap.nvim",
        event = "VeryLazy",
        config = function()
            require("configs.mason-dap")
        end,
        -- For `plugins/markview.lua` users.
    },

    {
        "OXY2DEV/markview.nvim",
        lazy = false,
        -- For `nvim-treesitter` users.
        priority = 49,
    },

    {
        "nvim-tree/nvim-tree.lua",
        lazy = false, -- must load at startup: registers the VimEnter/SessionLoadPost
        -- auto-open autocmds and the <leader>e keymap (defaults.lazy is true)
        dependencies = { "nvim-tree/nvim-web-devicons" },
        config = function()
            require("configs.nvim-tree")
        end,
    },

    {
        "nvim-telescope/telescope.nvim",
        opts = function(_, opts)
            opts.defaults = opts.defaults or {}
            -- telescope's default rg args omit --hidden, so live_grep/grep_string
            -- never searched inside .gitlab-ci.yml, .flake8, .pre-commit-config.yaml
            opts.defaults.vimgrep_arguments = {
                "rg",
                "--color=never",
                "--no-heading",
                "--with-filename",
                "--line-number",
                "--column",
                "--smart-case",
                "--hidden",
                "--glob=!**/.git/*", -- .git is hidden but not gitignored, exclude it explicitly
            }
            opts.pickers = vim.tbl_deep_extend("force", opts.pickers or {}, {
                find_files = {
                    -- rg/fd skip dot-prefixed paths by default, hiding .gitlab-ci.yml & co.
                    hidden = true,
                    -- .git is hidden but not gitignored, so --hidden pulls in its
                    -- ~6000 internal files; keep them out of the picker
                    file_ignore_patterns = { "^%.git/" },
                },
            })
            return opts
        end,
    },

    {
        "akinsho/toggleterm.nvim",
        event = "VeryLazy",
        config = function()
            require("configs.toggleterm")
        end,
    },

    {
        "hat0uma/csvview.nvim",
        ft = { "csv", "tsv" },
        cmd = { "CsvViewEnable", "CsvViewDisable", "CsvViewToggle", "CsvViewInfo" },
        config = function()
            require("configs.csvview")
        end,
    },

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
}
