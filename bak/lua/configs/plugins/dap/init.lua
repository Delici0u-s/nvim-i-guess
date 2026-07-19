return function()
    local mason_dap = require("mason-nvim-dap")
    local dap = require("dap")
    local ui = require("dapui")
    local dap_virtual_text = require("nvim-dap-virtual-text")

    -- Dap Virtual Text
    dap_virtual_text.setup({})

    mason_dap.setup({
        ensure_installed = { "cppdbg", "debugpy", },
        automatic_installation = true,
        handlers = {
            function(config)
                require("mason-nvim-dap").default_setup(config)
            end,
        },
    })

    -- Configurations
    dap.defaults.fallback.external_terminal = {
        command = "alacritty",
        --   command = "/usr/bin/kitty",
        --   command = "/usr/bin/xterm",
        --   command = "/usr/bin/konsole",
        args = { "-e" },
        --   command = "/usr/bin/gnome-terminal",
        --   args = {"--", "bash", "-lc"},
    }
    -- Optional: force using external terminal for launches
    -- dap.defaults.fallback.force_external_terminal = true

    local config = function(file)
        return require("configs.plugins.dap.configs." .. file)
    end
    -- Add this configuration alongside your existing one(s)
    dap.configurations = {
        c = config("c"),
        python = config("python"),
    }

    -- Dap UI

    ui.setup()

    vim.fn.sign_define("DapBreakpoint", { text = "🛑" })

    dap.listeners.before.attach.dapui_config = ui.open
    dap.listeners.before.launch.dapui_config = ui.open
    dap.listeners.before.event_terminated.dapui_config = ui.close
    dap.listeners.before.event_exited.dapui_config = ui.close

    -- load all files in this dir aka funcname
    require("utils.auto_load").load_files_in_dir()
end
