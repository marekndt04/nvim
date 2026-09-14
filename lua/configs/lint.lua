local lint = require("lint")

-- mason.nvim (which prepends its bin to PATH) loads at VeryLazy — after
-- neovim-project restores sessions at startup. Prepend it here so linters
-- resolve when BufEnter fires during session restore.
vim.env.PATH = vim.fn.stdpath("data") .. "/mason/bin:" .. vim.env.PATH

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

vim.api.nvim_create_autocmd({ "BufEnter", "BufWritePost", "InsertLeave" }, {
    callback = function()
        lint.try_lint()
    end,
})
