local type = "rainglow/"
local theme = "bold"
-- local theme = "pastel-contrast"

theme = type .. theme .. ".vim"

-- Source the vim file directly
vim.cmd("source " .. vim.fn.stdpath("config") .. "/lua/configs/theme/themes/" .. theme)
