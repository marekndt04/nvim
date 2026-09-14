require "nvchad.mappings"

-- add yours here

local map = vim.keymap.set

map("n", ";", ":", { desc = "CMD enter command mode" })
map("i", "jk", "<ESC>")

map("n", "<leader>cp", function()
    local path = vim.fn.expand("%:p")
    vim.fn.setreg("+", path)
    vim.notify("Copied: " .. path)
end, { desc = "Copy absolute file path" })

map("n", "<leader>cr", function()
    local path = vim.fn.expand("%")
    vim.fn.setreg("+", path)
    vim.notify("Copied: " .. path)
end, { desc = "Copy relative file path" })

-- <C-w>d is the built-in equivalent but scopes to the whole line
map("n", "<leader>dd", function()
    vim.diagnostic.open_float({ scope = "cursor" })
end, { desc = "Diagnostic under cursor" })

-- map({ "n", "i", "v" }, "<C-s>", "<cmd> w <cr>")
