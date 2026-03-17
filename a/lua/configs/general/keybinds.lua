-- map helper
local kb = require("utils.keybinds")

-- remove highlighting
kb.map(
    "n",
    "<C-l>",
    [[ (&hls && v:hlsearch ? ':nohls' : ':set hls')."\n" <BAR> redraw<CR>]],
    { silent = true, expr = true }
)

-- save on ctrl s
kb.map("n", "<C-S>", ":w<cr>@s", { silent = true })
kb.map("i", "<C-S>", function()
    -- Exit insert mode
    vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<Esc>", true, false, true), "n", true)
    -- Save the file
    vim.cmd("w")
    -- Re-enter insert mode
    vim.api.nvim_feedkeys("i", "n", true)
end, { silent = true })

----------------------------
----- terminal stuff i guess
----------------------------

-- exit terminal insert mode
kb.map("t", "<C-X>", "<C-\\><C-n>", { silent = true })
kb.map("n", "<C-X>", ":x<cr>", { silent = true })

-- open terminal in vertical split
kb.map("n", "vt", function()
    vim.cmd("vsplit")
    vim.cmd("terminal")
end, { desc = "Vertical terminal" })

-- open terminal in horizontal split
kb.map("n", "vht", function()
    vim.cmd("split") -- corrected command
    vim.cmd("terminal")
end, { desc = "Horizontal terminal" })

local terminals = {
    vertical = { buf = nil, win = nil },
    horizontal = { buf = nil, win = nil },
}

local function toggle_terminal(direction)
    local term = terminals[direction]

    -- If window exists → close it
    if term.win and vim.api.nvim_win_is_valid(term.win) then
        vim.api.nvim_win_close(term.win, true)
        term.win = nil
        return
    end

    -- Open split
    if direction == "vertical" then
        vim.cmd("vsplit")
    else
        vim.cmd("split")
    end

    term.win = vim.api.nvim_get_current_win()

    -- Create terminal buffer if needed
    if not term.buf or not vim.api.nvim_buf_is_valid(term.buf) then
        vim.cmd("terminal")
        term.buf = vim.api.nvim_get_current_buf()
    else
        vim.api.nvim_win_set_buf(term.win, term.buf)
    end

    vim.cmd("startinsert")
end

kb.map({ "n", "t" }, "<C-n>", function()
    toggle_terminal("vertical")
end, { desc = "Toggle terminal (vertical)" })

kb.map({ "n", "t" }, "<C-h>n", function()
    toggle_terminal("horizontal")
end, { desc = "Toggle terminal (horizontal)" })



-------------------------------

-- todo implement hotkey hook
-- temp:
-- execute macro for key after this combo
kb.map("n", "<C-a>", function()
    -- Prompt for a single key without needing Enter
    vim.api.nvim_echo({ { "Press macro register:", "Normal" } }, false, {})
    local reg = vim.fn.getchar() -- gets the keycode
    reg = vim.fn.nr2char(reg)    -- convert keycode to character

    -- Run the macro if a key was pressed
    if reg ~= "" then
        vim.api.nvim_feedkeys("@" .. reg, "n", true)
    end
end, { silent = true })

-- Requires which-key or can be done with normal maps using <C-h>x style
kb.map("n", "<C-h>x", ":Hex<CR>", { desc = "Run :Hex command", silent = true })
kb.map("n", "<C-v>x", ":Vex<CR>", { desc = "Run :Vex command", silent = true })
kb.map("n", "<C-e>x", ":Ex<CR>", { desc = "Run :Ex command", silent = true })
