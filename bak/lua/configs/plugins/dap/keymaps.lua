map = require("utils.keybinds").map

local map = require("utils.keybinds").map

-- Debugger (<leader>d group)

map("n", "<leader>dt", function()
    require("dap").toggle_breakpoint()
end, { desc = "Toggle Breakpoint", nowait = true })

map("n", "<leader>dc", function()
    require("dap").continue()
end, { desc = "Continue", nowait = true })

map("n", "<leader>di", function()
    require("dap").step_into()
end, { desc = "Step Into", nowait = true })

map("n", "<leader>do", function()
    require("dap").step_over()
end, { desc = "Step Over", nowait = true })

map("n", "<leader>du", function()
    require("dap").step_out()
end, { desc = "Step Out", nowait = true })

map("n", "<leader>dr", function()
    require("dap").repl.open()
end, { desc = "Open REPL", nowait = true })

map("n", "<leader>dl", function()
    require("dap").run_last()
end, { desc = "Run Last", nowait = true })

map("n", "<leader>dq", function()
    require("dap").terminate()
    require("dapui").close()
    require("nvim-dap-virtual-text").toggle()
end, { desc = "Terminate", nowait = true })

map("n", "<leader>db", function()
    require("dap").list_breakpoints()
end, { desc = "List Breakpoints", nowait = true })

map("n", "<leader>de", function()
    require("dap").set_exception_breakpoints({ "all" })
end, { desc = "Set Exception Breakpoints", nowait = true })
