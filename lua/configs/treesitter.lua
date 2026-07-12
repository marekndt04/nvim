require("nvim-treesitter").install({
    "bash",
    "fish",
    "lua",
    "luadoc",
    "markdown",
    "markdown_inline",
    "printf",
    "python",
    "toml",
    "vim",
    "vimdoc",
    "yaml",
})

vim.api.nvim_create_autocmd("FileType", {
    pattern = { "sh", "bash", "fish", "lua", "markdown", "python", "toml", "vim", "yaml" },
    callback = function(args)
        vim.treesitter.start(args.buf)
        vim.bo[args.buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
    end,
})
