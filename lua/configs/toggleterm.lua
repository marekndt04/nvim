require("toggleterm").setup({})

local Terminal = require("toggleterm.terminal").Terminal

local lazygit = Terminal:new({
    cmd = "lazygit",
    direction = "float",
    hidden = true,
    -- nvim strips COLORTERM from embedded terminals, breaking lazygit's
    -- truecolor detection (diff pane renders without red/green)
    env = { COLORTERM = "truecolor" },
    float_opts = {
        border = "curved",
        width = function()
            return math.floor(vim.o.columns * 0.9)
        end,
        height = function()
            return math.floor(vim.o.lines * 0.85)
        end,
    },
})

local map = vim.keymap.set
map("n", "<leader>gg", function()
    lazygit:toggle()
end, { desc = "Toggle lazygit" })
map("t", "<A-g>", function()
    lazygit:toggle()
end, { desc = "Toggle lazygit" })
