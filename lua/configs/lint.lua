local lint = require("lint")

-- No mypy: pyright already type-checks, and Mason's mypy runs in its own venv
-- so it flags every third-party import as missing.
lint.linters_by_ft = {
    lua = { "luacheck" },
    python = { "ruff" },
}

lint.linters.luacheck.args = {
    unpack(lint.linters.luacheck.args),
    "--globals",
    "love",
    "vim",
}

vim.api.nvim_create_autocmd({ "BufWritePost", "InsertLeave" }, {
    callback = function()
        lint.try_lint()
    end,
})
