require("nvchad.autocmds")
local map = vim.keymap.set
local opts = { noremap = true, silent = true }

-- Insert mode escape shortcut
-- map("i", "jk", "<ESC>", opts)

-- :bnext/:bprevious walk buffer numbers, which diverge from the visible tab order
local tabufline = require("nvchad.tabufline")
map("n", "<A-k>", tabufline.next, { desc = "Buffer goto next" })
map("n", "<A-j>", tabufline.prev, { desc = "Buffer goto prev" })

-- toggle preview
map("n", "<leader>mt", ":Markview splitOpen<CR>", opts)
map("n", "<leader>mx", ":Markview splitClose<CR>", opts)
map("n", "<leader>mm", ":Markview toggle<CR>", opts)
