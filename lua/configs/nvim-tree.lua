require("nvim-tree").setup()

local map = vim.keymap.set
map("n", "<leader>e", ":NvimTreeToggle<CR>", { desc = "Toggle NvimTree" })
