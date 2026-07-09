local presets = require("markview.presets")

-- Swap preset names to test different visuals, then :e any .md file.
-- headings: simple | marker | label | slanted | arrowed | glow | glow_center
-- tables: none | single | double | rounded | solid
-- horizontal_rules: thin | thick | double | dashed | dotted | solid | arrowed
require("markview").setup({
    markdown = {
        headings = presets.headings.slanted,
        tables = presets.tables.rounded,
        horizontal_rules = presets.horizontal_rules.thin,
    },
})
