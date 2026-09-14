require("nvim-tree").setup({
    filters = {
        dotfiles = true,
        -- shown despite being gitignored; Lua patterns matched against the full path
        exclude = { "workbench", "code_reviews", "mypy%.ini", "pyrightconfig%.json", "local%.py" },
    },
    -- follow cwd changes (project switching via neovim-project)
    sync_root_with_cwd = true,
    respect_buf_cwd = true,
})

local map = vim.keymap.set
map("n", "<leader>e", ":NvimTreeToggle<CR>", { desc = "Toggle NvimTree" })
