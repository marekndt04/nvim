local lint = require("lint")

-- mason.nvim (which prepends its bin to PATH) loads at VeryLazy — after
-- neovim-project restores sessions at startup. Prepend it here so linters
-- resolve when BufEnter fires during session restore.
vim.env.PATH = vim.fn.stdpath("data") .. "/mason/bin:" .. vim.env.PATH

lint.linters_by_ft = {
    lua = { "luacheck" },
    python = { "mypy", "ruff" },
}

-- Prefer the project's own mypy (needed for the django-stubs plugin, which
-- must import django from the project venv); fall back to Mason's otherwise.
-- env is not additive in nvim-lint, so extend a copy of the full environment.
local project_mypy = vim.fn.getcwd() .. "/.venv-local/bin/mypy"
if vim.fn.executable(project_mypy) == 1 then
    lint.linters.mypy.cmd = project_mypy
    lint.linters.mypy.env = vim.tbl_extend("force", vim.fn.environ(), {
        WORKING_MODE = "TESTING",
    })
end

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
