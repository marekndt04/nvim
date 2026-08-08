require("toggleterm").setup({})

local Terminal = require("toggleterm.terminal").Terminal

-- lazygit terminal is created per project root: after a cwd change
-- (neovim-project switch) the old instance is discarded, otherwise
-- lazygit keeps tracking the previous project's repo
local lazygit = nil
local lazygit_dir = nil

local function toggle_lazygit()
    local cwd = vim.fn.getcwd()
    if lazygit and lazygit_dir ~= cwd then
        lazygit:shutdown()
        lazygit = nil
    end
    if not lazygit then
        lazygit = Terminal:new({
            cmd = "lazygit",
            dir = cwd,
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
        lazygit_dir = cwd
    end
    lazygit:toggle()
end

local map = vim.keymap.set
map("n", "<leader>gg", toggle_lazygit, { desc = "Toggle lazygit" })
map("t", "<A-g>", toggle_lazygit, { desc = "Toggle lazygit" })
