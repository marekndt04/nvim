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
    -- No format_on_save: per-project pre-commit hooks and make targets own
    -- formatting, and black/isort defaults would rewrap ruff projects.
}

require("conform").setup(options)
