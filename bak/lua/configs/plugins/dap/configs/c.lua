return {
    {
        name = "Launch file (integrated terminal)",
        type = "cppdbg",
        request = "launch",
        program = function()
            return vim.fn.input("Path to executable: ", vim.fn.getcwd() .. "/", "file")
        end,
        cwd = "${workspaceFolder}",
        stopAtEntry = false,
        MIMode = "gdb",
        miDebuggerPath = "/usr/bin/gdb",
        externalConsole = false,
        setupCommands = {
            {
                description = "Enable pretty printing",
                text = "-enable-pretty-printing",
                ignoreFailures = false,
            },
        },
    },

    {
        name = "Launch file (external terminal)",
        type = "cppdbg",
        request = "launch",
        program = function()
            return vim.fn.input("Path to executable: ", vim.fn.getcwd() .. "/", "file")
        end,
        cwd = "${workspaceFolder}",
        stopAtEntry = false,
        MIMode = "gdb",
        miDebuggerPath = "/usr/bin/gdb",
        -- IMPORTANT: open an external terminal window for program stdout/stderr
        externalConsole = true,
        setupCommands = {
            {
                description = "Enable pretty printing",
                text = "-enable-pretty-printing",
                ignoreFailures = false,
            },
        },
    },
}
