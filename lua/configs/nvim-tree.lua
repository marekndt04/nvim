require("nvim-tree").setup({
    filters = {
        dotfiles = true,
    },
})

vim.api.nvim_create_autocmd("VimEnter", {
    callback = function()
        if vim.fn.argc() == 0 then
            require("nvim-tree.api").tree.open()
        end
    end,
})

local map = vim.keymap.set
map("n", "<leader>e", ":NvimTreeToggle<CR>", { desc = "Toggle NvimTree" })
