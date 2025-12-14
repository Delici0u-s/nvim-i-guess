local al = require("utils.auto_load")

-- load theme before everything else
require("configs.theme")

al.load_files_in_dir()
al.load_folders_in_dir()
