require("nvchad.options")

-- add yours here!

local o = vim.o

-- Indenting
o.shiftwidth = 4
o.tabstop = 4
o.softtabstop = 4

vim.opt.spell = true
vim.opt.spelllang = { "en_gb" }

-- Diagnostics UI: inline messages + underlines
vim.diagnostic.config({
    underline = true,
    virtual_text = { spacing = 2, prefix = "●" },
    signs = true,
    severity_sort = true,
    update_in_insert = false,
})

-- TERM=xterm-256color has no undercurl capability, so squiggles are silently
-- dropped; use plain underline instead (renders in any terminal)
vim.api.nvim_create_autocmd("ColorScheme", {
    callback = function()
        for _, severity in ipairs({ "Error", "Warn", "Info", "Hint" }) do
            local group = "DiagnosticUnderline" .. severity
            local hl = vim.api.nvim_get_hl(0, { name = group })
            hl.undercurl = nil
            hl.underline = true
            vim.api.nvim_set_hl(0, group, hl)
        end
    end,
})
vim.schedule(function()
    vim.cmd("doautocmd ColorScheme")
end)
