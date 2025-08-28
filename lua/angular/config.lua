local config = {}

local default_config = {
	angular_cli = "ng",
	ui = {
		border = "rounded",
		height = 0.8,
		width = 0.8,
	},
}

config.config = vim.deepcopy(default_config)

function config:setup(user_config)
	config.config = vim.tbl_deep_extend("force", default_config, user_config or {})
end

return config
