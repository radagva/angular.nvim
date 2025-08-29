local config = require("angular.config")
local utils = require("angular.utils")

local ui = {}

function ui.select_schematic(schematics_list, on_select)
	local items = {}

	for _, schematic in ipairs(schematics_list) do
		table.insert(items, {
			value = schematic.name,
			label = schematic.name,
			description = schematic.description or "No description available",
		})
	end

	table.sort(items, function(a, b)
		return a.value < b.value
	end)

	vim.ui.select(items, {
		prompt = "Select Angular schematic:",
		format_item = function(item)
			return string.format("%-15s %s", item.value, item.description)
		end,
	}, function(selected)
		if selected then
			on_select(selected.value)
		else
			on_select(nil)
		end
	end)
end

function ui.show_schematics_list(schematics_list, on_schematic_select)
	-- Create a formatted list with index numbers
	local formatted_schematics = {}
	for i, schematic in ipairs(schematics_list) do
		table.insert(formatted_schematics, {
			index = i,
			name = schematic.name,
			description = schematic.description or "No description",
		})
	end

	-- Sort alphabetically by name
	table.sort(formatted_schematics, function(a, b)
		return a.name < b.name
	end)

	-- Create display lines with numbers
	local lines = {}
	for i, schematic in ipairs(formatted_schematics) do
		table.insert(lines, string.format("%2d. %-15s - %s", i, schematic.name, schematic.description))
	end

	local buf = vim.api.nvim_create_buf(false, true)
	local width = math.floor(vim.o.columns * config.config.ui.width)
	local height = math.floor(vim.o.lines * config.config.ui.height)
	local col = math.floor((vim.o.columns - width) / 2)
	local row = math.floor((vim.o.lines - height) / 2)

	local win = vim.api.nvim_open_win(buf, true, {
		relative = "editor",
		width = width,
		height = height,
		col = col,
		row = row,
		style = "minimal",
		border = config.config.ui.border,
		title = "Available Angular Schematics (select with number)",
	})

	vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
	vim.api.nvim_buf_set_option(buf, "modifiable", false)
	vim.api.nvim_buf_set_option(buf, "filetype", "markdown")

	-- Store data in buffer variables
	vim.api.nvim_buf_set_var(buf, "angular_schematics_list", formatted_schematics)
	vim.api.nvim_buf_set_var(buf, "on_schematic_select", on_schematic_select)
	vim.api.nvim_buf_set_var(buf, "window_id", win)

	-- Create helper functions for key mappings
	local function create_select_function(index)
		return string.format("<cmd>lua require('angular.ui')._select_schematic_by_index(%d, %d)<CR>", buf, index)
	end

	local function create_number_input_function()
		return string.format("<cmd>lua require('angular.ui')._prompt_schematic_number(%d)<CR>", buf)
	end

	-- Set keymaps with string commands
	local opts = { noremap = true, silent = true, buffer = buf }

	-- Number keys 1-9 for selection
	for i = 1, 9 do
		if i <= #formatted_schematics then
			vim.api.nvim_buf_set_keymap(buf, "n", tostring(i), create_select_function(i), opts)
		end
	end

	-- For numbers beyond 9, use prompt
	if #formatted_schematics > 9 then
		vim.api.nvim_buf_set_keymap(buf, "n", "0", create_number_input_function(), opts)
	end

	-- Navigation and exit keys
	vim.api.nvim_buf_set_keymap(buf, "n", "q", "<cmd>q<CR>", opts)
	vim.api.nvim_buf_set_keymap(buf, "n", "<ESC>", "<cmd>q<CR>", opts)
	vim.api.nvim_buf_set_keymap(buf, "n", "<CR>", create_number_input_function(), opts)

	-- Add help text
	local help_lines = {
		"",
		"Press number to select schematic",
		"Press <Enter> for number input",
		"Press q or <ESC> to quit",
	}

	vim.api.nvim_buf_set_lines(buf, #lines, #lines + #help_lines, false, help_lines)
	vim.api.nvim_buf_add_highlight(buf, -1, "Comment", #lines, 0, -1)
end

function ui._select_schematic_by_index(buf, index)
	local ok, schematics_list = pcall(vim.api.nvim_buf_get_var, buf, "angular_schematics_list")
	local ok2, callback = pcall(vim.api.nvim_buf_get_var, buf, "on_schematic_select")
	local ok3, win = pcall(vim.api.nvim_buf_get_var, buf, "window_id")

	if ok and ok2 and ok3 and schematics_list[index] then
		local selected_schematic = schematics_list[index].name
		vim.api.nvim_win_close(win, true)
		callback(selected_schematic)
	end
end

function ui._prompt_schematic_number(buf)
	local ok, schematics_list = pcall(vim.api.nvim_buf_get_var, buf, "angular_schematics_list")
	local ok2, callback = pcall(vim.api.nvim_buf_get_var, buf, "on_schematic_select")
	local ok3, win = pcall(vim.api.nvim_buf_get_var, buf, "window_id")

	if ok and ok2 and ok3 then
		vim.ui.input({
			prompt = "Enter schematic number (1-" .. #schematics_list .. "): ",
		}, function(input)
			if input then
				local num = tonumber(input)
				if num and num >= 1 and num <= #schematics_list then
					local selected_schematic = schematics_list[num].name
					vim.api.nvim_win_close(win, true)
					callback(selected_schematic)
				end
			end
		end)
	end
end

function ui.prompt_schematic_options(schematic_name, on_complete)
	vim.ui.input({
		prompt = "Enter name/path for "
			.. schematic_name
			.. " (e.g., 'my-"
			.. schematic_name
			.. "' or 'path/to/"
			.. schematic_name
			.. "'): ",
		default = ui._get_default_name(schematic_name),
	}, function(name_input)
		if not name_input or name_input == "" then
			on_complete(nil)
			return
		end

		local options = { name = name_input }

		ui._prompt_additional_options(schematic_name, options, on_complete)
	end)
end

function ui._get_default_name(schematic_name)
	local defaults = {
		component = "my-component",
		service = "my-service",
		directive = "my-directive",
		pipe = "my-pipe",
		guard = "my-guard",
		interceptor = "my-interceptor",
		resolver = "my-resolver",
		class = "my-class",
		interface = "my-interface",
	}

	return defaults[schematic_name] or schematic_name
end

function ui._prompt_additional_options(schematic_name, options, on_complete)
	if schematic_name == "component" then
		ui._prompt_component_options(options, on_complete)
	elseif schematic_name == "service" then
		ui._prompt_service_options(options, on_complete)
	elseif schematic_name == "module" then
		ui._prompt_module_options(options, on_complete)
	else
		-- For other schematics, just use the name
		on_complete(options)
	end
end

function ui._prompt_component_options(options, on_complete)
	vim.ui.select({
		{ value = "css", label = "CSS" },
		{ value = "scss", label = "SCSS" },
		{ value = "sass", label = "SASS" },
		{ value = "less", label = "LESS" },
	}, {
		prompt = "Select style format:",
		format_item = function(item)
			return item.label
		end,
	}, function(style)
		options.style = style.value

		utils.multi_select(
			{
				{ value = "skip-tests", label = "Skip tests" },
				{ value = "flat", label = "Flat structure (no folder)" },
				{ value = "inline-template", label = "Inline template" },
				{ value = "inline-style", label = "Inline style" },
			},
			"Component Options",
			function(selected_options)
				for _, opt in ipairs(selected_options or {}) do
					options[opt] = true
				end

				on_complete(options)
			end
		)
	end)
end

function ui._prompt_service_options(options, on_complete)
	vim.ui.select({ "Yes", "No" }, {
		prompt = "Skip tests?",
		format_item = function(item)
			return item
		end,
	}, function(skip_tests)
		options.skipTests = skip_tests == "Yes"

		vim.ui.select({ "Yes", "No" }, {
			prompt = "Flat structure (no folder)?",
			format_item = function(item)
				return item
			end,
		}, function(flat)
			options.flat = flat == "Yes"
			on_complete(options)
		end)
	end)
end

function ui._prompt_module_options(options, on_complete)
	vim.ui.select({ "Yes", "No" }, {
		prompt = "Create routing module?",
		format_item = function(item)
			return item
		end,
	}, function(routing)
		options.routing = routing == "Yes"
		on_complete(options)
	end)
end

return ui
