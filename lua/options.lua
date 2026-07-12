require("nvchad.options")

-- add yours here!

local o = vim.o

-- Indenting
o.shiftwidth = 4
o.tabstop = 4
o.softtabstop = 4

vim.opt.spell = true
vim.opt.spelllang = { "en_gb" }

-- Terminal window title follows the current project (cwd basename)
o.title = true
o.titlestring = "nvim — %{fnamemodify(getcwd(), ':t')}"
