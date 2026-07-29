local on_attach = require("nvchad.configs.lspconfig").on_attach
local on_init = require("nvchad.configs.lspconfig").on_init
local capabilities = require("nvchad.configs.lspconfig").capabilities

local lspconfig = require("nvchad.configs.lspconfig")

lspconfig.servers = {
    "lua_ls",
    "pyright",
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

-- highlight all references of the symbol under the cursor
-- (delay controlled by 'updatetime', set in options.lua)
vim.api.nvim_create_autocmd("LspAttach", {
    callback = function(args)
        local client = vim.lsp.get_client_by_id(args.data.client_id)
        if not (client and client:supports_method("textDocument/documentHighlight")) then
            return
        end
        local group = vim.api.nvim_create_augroup("lsp_document_highlight_" .. args.buf, { clear = true })
        vim.api.nvim_create_autocmd({ "CursorHold", "CursorHoldI" }, {
            buffer = args.buf,
            group = group,
            callback = vim.lsp.buf.document_highlight,
        })
        vim.api.nvim_create_autocmd({ "CursorMoved", "CursorMovedI" }, {
            buffer = args.buf,
            group = group,
            callback = vim.lsp.buf.clear_references,
        })
    end,
})
