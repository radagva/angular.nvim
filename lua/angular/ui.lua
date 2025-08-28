local config = require("angular.config")

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

function ui.show_schematics_list(schematics_list)
	local lines = {}
	for _, schematic in ipairs(schematics_list) do
		table.insert(lines, string.format("%-15s - %s", schematic.name, schematic.description or "No description"))
	end

	table.sort(lines)

	local buf = vim.api.nvim_create_buf(false, true)
	local width = math.floor(vim.o.columns * config.config.ui.width)
	local height = math.floor(vim.o.lines * config.config.ui.height)
	local col = math.floor((vim.o.columns - width) / 2)
	local row = math.floor((vim.o.lines - height) / 2)

	local _ = vim.api.nvim_open_win(buf, true, {
		relative = "editor",
		width = width,
		height = height,
		col = col,
		row = row,
		style = "minimal",
		border = config.config.ui.border,
		title = "Available Angular Schematics",
	})

	vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
	vim.api.nvim_buf_set_option(buf, "modifiable", false)
	vim.api.nvim_buf_set_option(buf, "filetype", "markdown")

	local opts = { noremap = true, silent = true }
	vim.api.nvim_buf_set_keymap(buf, "n", "q", "<cmd>q<CR>", opts)
	vim.api.nvim_buf_set_keymap(buf, "n", "<ESC>", "<cmd>q<CR>", opts)
	vim.api.nvim_buf_set_keymap(buf, "n", "<CR>", "<cmd>q<CR>", opts)
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

		vim.ui.select({ "Yes", "No" }, {
			prompt = "Skip tests?",
			format_item = function(item)
				return item
			end,
		}, function(skip_tests)
			options["skip-tests"] = skip_tests == "Yes"

			vim.ui.select({ "Yes", "No" }, {
				prompt = "Flat structure (no folder)?",
				format_item = function(item)
					return item
				end,
			}, function(flat)
				vim.ui.select({ "Yes", "No" }, {
					prompt = "Inline template (no html file)",
					format_item = function(item)
						return item
					end,
				}, function(template)
					options["inline-template"] = template == "Yes"
					on_complete(options)
				end)
			end)
		end)
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
