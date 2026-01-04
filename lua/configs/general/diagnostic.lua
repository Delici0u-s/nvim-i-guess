vim.diagnostic.config({
    virtual_text = false,  -- inline error messages
    virtual_lines = false, -- error messages in line below
    -- signs = false,        -- like disable mini symbols on right
    -- signs = {
    -- 	text = {
    -- 		[vim.diagnostic.severity.ERROR] = "",
    -- 		[vim.diagnostic.severity.WARN]  = "",
    -- 		[vim.diagnostic.severity.INFO]  = "",
    -- 		[vim.diagnostic.severity.HINT]  = "",
    -- 	},
    -- },
    update_in_insert = false, -- set to true to give warnings etc while in insert mode, but shit kinda annoying
})
