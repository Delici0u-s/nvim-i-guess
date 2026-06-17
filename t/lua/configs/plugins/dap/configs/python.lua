return {
    -- Launch in the (nvim-dap) integrated terminal / DAP terminal
    {
        name = "Python: Launch (integrated terminal)",
        type = "python",
        command = "python3",
        request = "launch",
        program = function()
            -- default to current buffer file, prompt to override
            return vim.fn.input("Path to file: ", vim.fn.expand("%:p"), "file")
        end,
        cwd = "${workspaceFolder}",
        -- Use the integrated terminal so stdout/stderr appear in the DAP terminal
        console = "integratedTerminal",
        stopOnEntry = false,
        -- prompt for args as a simple space-separated string and split into a table
        args = function()
            local input = vim.fn.input("Args (space-separated): ")
            if input == nil or input == "" then
                return {}
            end
            return vim.split(input, "%s+", { trimempty = true })
        end,
    },

    -- Launch in an external terminal (use dap.defaults.fallback.external_terminal to control which)
    {
        name = "Python: Launch (external terminal)",
        type = "python",
        command = "python3",
        request = "launch",
        program = function()
            return vim.fn.input("Path to file: ", vim.fn.expand("%:p"), "file")
        end,
        cwd = "${workspaceFolder}",
        console = "externalTerminal",
        stopOnEntry = false,
        args = function()
            local input = vim.fn.input("Args (space-separated): ")
            if input == nil or input == "" then
                return {}
            end
            return vim.split(input, "%s+", { trimempty = true })
        end,
    },

    -- Attach to a debugpy server (run `python -m debugpy --listen 5678 --wait-for-client your_script.py`)
    {
        name = "Python: Attach (127.0.0.1:5678)",
        type = "python",
        command = "python3",
        request = "attach",
        connect = {
            host = "127.0.0.1",
            port = 5678,
        },
    },
}
