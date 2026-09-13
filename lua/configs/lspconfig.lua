local on_attach = require("nvchad.configs.lspconfig").on_attach
local on_init = require("nvchad.configs.lspconfig").on_init
local capabilities = require("nvchad.configs.lspconfig").capabilities

local lspconfig = require("nvchad.configs.lspconfig")

-- Must stay here, not options.lua: the plugin spec runs defaults() (which calls
-- vim.diagnostic.config) immediately before this file, so this gets the last
-- word. Keys omitted keep NvChad's values.
vim.diagnostic.config({
    virtual_text = false,
    severity_sort = true,
    update_in_insert = false,
})

lspconfig.servers = {
    "lua_ls",
    "pyright",
    "rust_analyzer",
}

local default_servers = {}

for _, lsp in ipairs(default_servers) do
    vim.lsp.config(lsp, {
        on_attach = on_attach,
        on_init = on_init,
        capabilities = capabilities,
    })
end

vim.lsp.config("pyright", {
    on_attach = on_attach,
    on_init = on_init,
    capabilities = capabilities,
    settings = {
        python = {
            analysis = {
                autoSearchPaths = true,
                diagnosticMode = "openFilesOnly",
                useLibraryCodeForTypes = true,
                autoImportCompletions = true,
                typeCheckingMode = "basic",
            },
        },
    },
})
