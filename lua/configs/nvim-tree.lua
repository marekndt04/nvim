require("nvim-tree").setup({
    filters = {
        dotfiles = true,
    },
    -- follow cwd changes (project switching via neovim-project)
    sync_root_with_cwd = true,
    respect_buf_cwd = true,
})

vim.api.nvim_create_autocmd("VimEnter", {
    callback = function()
        if vim.fn.argc() == 0 then
            require("nvim-tree.api").tree.open()
        end
    end,
})

-- sessions never contain the tree (NvimTree is in autosave_ignore_filetypes),
-- so reopen it after neovim-project restores a session
vim.api.nvim_create_autocmd("User", {
    pattern = "SessionLoadPost",
    callback = function()
        require("nvim-tree.api").tree.open()
        vim.cmd("wincmd p")
    end,
})

local map = vim.keymap.set
map("n", "<leader>e", ":NvimTreeToggle<CR>", { desc = "Toggle NvimTree" })
