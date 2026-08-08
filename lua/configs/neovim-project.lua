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
            -- plugin defaults, plus NvimTree so tree windows aren't saved into sessions
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
