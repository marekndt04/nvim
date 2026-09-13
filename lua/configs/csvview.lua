local csvview = require("csvview")

csvview.setup({
    parser = {
        comments = { "#", "//" },
    },
    view = {
        display_mode = "border",
        header_lnum = true,
        sticky_header = {
            enabled = true,
            separator = "─",
        },
    },
    keymaps = {
        -- text objects for selecting fields
        textobject_field_inner = { "if", mode = { "o", "x" } },
        textobject_field_outer = { "af", mode = { "o", "x" } },
        -- Excel-like navigation, only active while csvview is enabled
        jump_next_field_end = { "<Tab>", mode = { "n", "v" } },
        jump_prev_field_end = { "<S-Tab>", mode = { "n", "v" } },
        jump_next_row = { "<Enter>", mode = { "n", "v" } },
        jump_prev_row = { "<S-Enter>", mode = { "n", "v" } },
    },
})

local function enable_if_needed(bufnr)
    if not csvview.is_enabled(bufnr) then
        csvview.enable(bufnr)
    end
end

-- open csv/tsv files already in tabular view instead of raw text
vim.api.nvim_create_autocmd("FileType", {
    group = vim.api.nvim_create_augroup("CsvViewAutoEnable", { clear = true }),
    pattern = { "csv", "tsv" },
    callback = function(args)
        enable_if_needed(args.buf)
    end,
})

-- the FileType event that lazy-loaded this module fires before the autocmd
-- above exists, so handle buffers that are already open
for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
    local filetype = vim.bo[bufnr].filetype
    if filetype == "csv" or filetype == "tsv" then
        enable_if_needed(bufnr)
    end
end

local map = vim.keymap.set
map("n", "<leader>cv", "<cmd>CsvViewToggle<CR>", { desc = "Toggle CSV tabular view" })
map("n", "<leader>ci", "<cmd>CsvViewInfo<CR>", { desc = "CSV buffer info" })
