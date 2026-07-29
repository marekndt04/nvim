local options = {
    formatters_by_ft = {
        lua = { "stylua" },
        python = { "isort", "black" },
    },
    -- Precedence for settings in pyproject.toml
    -- formatters = {
    --     -- Python
    --     black = {
    --         prepend_args = {
    --             "--fast",
    --             "--line-length",
    --             "50",
    --         },
    --     },
    --     isort = {
    --         prepend_args = {
    --             "--profile",
    --             "black",
    --         },
    --     },
    -- },
    -- Opt a project out of format-on-save with a `.noautoformat` file in its root.
    format_on_save = function(bufnr)
        if vim.fs.root(bufnr, ".noautoformat") then
            return
        end
        -- These options will be passed to conform.format()
        return {
            timeout_ms = 500,
            lsp_fallback = true,
        }
    end,
}

require("conform").setup(options)
