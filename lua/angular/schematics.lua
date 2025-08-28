local config = require("angular.config")
local ui = require("angular.ui")
local utils = require("angular.utils")

local schematics = {}

function schematics.setup()
	if config.config.auto_commands then
		schematics._create_autocommands()
	end
end

function schematics.run_schematic()
	local available_schematics = schematics._get_available_schematics()
	if not available_schematics then
		return
	end

	ui.select_schematic(available_schematics, function(selected)
		if selected then
			schematics._prompt_schematic_options(selected)
		end
	end)
end

function schematics.list_schematics()
	local available_schematics = schematics._get_available_schematics()
	if not available_schematics then
		return
	end

	ui.show_schematics_list(available_schematics)
end

function schematics.create_component()
	schematics._run_specific_schematic("component")
end

function schematics.create_service()
	schematics._run_specific_schematic("service")
end

function schematics.create_module()
	schematics._run_specific_schematic("module")
end

function schematics.create_directive()
	schematics._run_specific_schematic("directive")
end

function schematics.create_pipe()
	schematics._run_specific_schematic("pipe")
end

function schematics._get_available_schematics()
	if not utils.is_angular_project() then
		vim.notify("Not in an Angular project", vim.log.levels.WARN)
		return nil
	end

	local common_schematics = {
		{ name = "component", description = "Create an Angular component" },
		{ name = "service", description = "Create an Angular service" },
		{ name = "directive", description = "Create an Angular directive" },
		{ name = "pipe", description = "Create an Angular pipe" },
		{ name = "guard", description = "Create an Angular route guard" },
		{ name = "interceptor", description = "Create an Angular HTTP interceptor" },
		{ name = "resolver", description = "Create an Angular route resolver" },
		{ name = "class", description = "Create a simple class" },
		{ name = "interface", description = "Create an interface" },
		{ name = "application", description = "Create a new application" },
		{ name = "library", description = "Create a library" },
	}

	local custom_schematics = schematics._get_custom_schematics()
	return vim.tbl_extend("force", common_schematics, custom_schematics or {})
end

function schematics._get_custom_schematics()
	return {}
end

function schematics._run_specific_schematic(schematic_type)
	if not utils.is_angular_project() then
		vim.notify("Not in an Angular project", vim.log.levels.WARN)
		return
	end

	ui.prompt_schematic_options(schematic_type, function(options)
		if options then
			schematics._execute_schematic(schematic_type, options)
		end
	end)
end

function schematics._prompt_schematic_options(schematic_name)
	ui.prompt_schematic_options(schematic_name, function(options)
		if options then
			schematics._execute_schematic(schematic_name, options)
		end
	end)
end

function schematics._execute_schematic(schematic_name, options)
	local cmd_parts = { config.config.angular_cli, "generate", schematic_name }

	-- Add the name/path as the first parameter
	if options.name and options.name ~= "" then
		table.insert(cmd_parts, options.name)
		options.name = nil -- Remove from options to avoid duplicate
	end

	-- Add other options
	for key, value in pairs(options) do
		if value ~= "" and value ~= nil then
			if type(value) == "boolean" then
				if value then
					table.insert(cmd_parts, "--" .. key)
				end
			else
				table.insert(cmd_parts, "--" .. key)
				table.insert(cmd_parts, tostring(value))
			end
		end
	end

	-- Add dry-run first for safety during testing
	if config.config.dry_run then
		table.insert(cmd_parts, "--dry-run")
		vim.notify("DRY RUN: " .. table.concat(cmd_parts, " "), vim.log.levels.WARN)
		return
	end

	local cmd = table.concat(cmd_parts, " ")
	vim.notify("Running: " .. cmd, vim.log.levels.INFO)

	vim.fn.jobstart(cmd, {
		on_exit = function(_, code)
			if code == 0 then
				vim.notify("Schematic executed successfully", vim.log.levels.INFO)
				vim.cmd("checktime") -- Refresh buffers
			else
				vim.notify("Schematic failed with code: " .. code, vim.log.levels.ERROR)
			end
		end,
		cwd = vim.fn.getcwd(),
	})
end

return schematics
