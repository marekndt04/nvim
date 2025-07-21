require("nvchad.autocmds")
local map = vim.keymap.set
local opts = { noremap = true, silent = true }

-- Insert mode escape shortcut
-- map("i", "jk", "<ESC>", opts)

-- Alt+j → Next buffer
map("n", "<A-j>", ":bnext<CR>", opts)

-- Alt+k → Previous buffer
map("n", "<A-k>", ":bprevious<CR>", opts)
