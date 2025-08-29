local config = require("angular.config")

local M = {}

function M.is_angular_project()
	return vim.fn.filereadable("angular.json") == 1
end

function M.get_angular_project_root()
	local current_dir = vim.fn.getcwd()
	local dir = current_dir

	while dir ~= "/" do
		if vim.fn.filereadable(dir .. "/angular.json") == 1 then
			return dir
		end
		dir = vim.fn.fnamemodify(dir, ":h")
	end

	return nil
end

function M.get_angular_cli_version()
	if not M.is_angular_project() then
		return nil
	end

	local cmd = "ng version --json"
	local result = vim.fn.system(cmd)

	if vim.v.shell_error ~= 0 then
		return nil
	end

	local ok, version_info = pcall(vim.json.decode, result)
	if not ok then
		return nil
	end

	return version_info
end

-- Helper function to check if command exists
function M.command_exists(cmd)
	return vim.fn.executable(cmd) == 1
end

-- Safe system command execution
function M.safe_system(cmd)
	local result = vim.fn.system(cmd)
	if vim.v.shell_error ~= 0 then
		return nil, "Command failed: " .. cmd
	end
	return result, nil
end

function M.multi_select(options, prompt, on_complete)
	local selections = {}
	local formatted_options = {}

	-- Initialize selections
	for i, option in ipairs(options) do
		selections[i] = { selected = false, value = option.value, label = option.label }
		table.insert(formatted_options, string.format("[ ] %s", option.label))
	end

	local buf = vim.api.nvim_create_buf(false, true)
	local width = 50
	local height = #options + 4
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
		title = prompt,
	})

	-- Set initial content
	local lines = { "Select options:", "" }
	vim.list_extend(lines, formatted_options)
	table.insert(lines, "")
	table.insert(lines, "x: Toggle  <cr>: Confirm  q: Quit")

	vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
	vim.api.nvim_buf_set_option(buf, "modifiable", false)

	-- Store data in buffer variables
	vim.api.nvim_buf_set_var(buf, "multi_select_selections", selections)
	vim.api.nvim_buf_set_var(buf, "multi_select_options", options)
	vim.api.nvim_buf_set_var(buf, "multi_select_callback", on_complete)
	vim.api.nvim_buf_set_var(buf, "multi_select_win", win)

	-- Create helper functions for key mappings
	local function create_toggle_function()
		return string.format("<cmd>lua require('angular.utils')._toggle_multi_select(%d)<CR>", buf)
	end

	local function create_confirm_function()
		return string.format("<cmd>lua require('angular.utils')._confirm_multi_select(%d)<CR>", buf)
	end

	local function create_quit_function()
		return string.format("<cmd>lua require('angular.utils')._quit_multi_select(%d)<CR>", buf)
	end

	-- Set keymaps with string commands
	local opts = { noremap = true, silent = true }

	vim.api.nvim_buf_set_keymap(buf, "n", "x", create_toggle_function(), opts)
	vim.api.nvim_buf_set_keymap(buf, "n", "<CR>", create_confirm_function(), opts)
	vim.api.nvim_buf_set_keymap(buf, "n", "q", create_quit_function(), opts)
	vim.api.nvim_buf_set_keymap(buf, "n", "<ESC>", create_quit_function(), opts)

	-- Navigation keys
	vim.api.nvim_buf_set_keymap(buf, "n", "j", "j", opts)
	vim.api.nvim_buf_set_keymap(buf, "n", "k", "k", opts)
end

-- Helper function to toggle multi-select item
function M._toggle_multi_select(buf)
	local ok, selections = pcall(vim.api.nvim_buf_get_var, buf, "multi_select_selections")
	local ok2, win = pcall(vim.api.nvim_buf_get_var, buf, "multi_select_win")

	if ok and ok2 then
		local line = vim.api.nvim_win_get_cursor(win)[1] - 1
		if line >= 2 and line <= #selections + 1 then
			local index = line - 1
			selections[index].selected = not selections[index].selected

			-- Update display
			local new_char = selections[index].selected and "[x]" or "[ ]"
			local new_line = string.format("%s %s", new_char, selections[index].label)

			vim.api.nvim_buf_set_option(buf, "modifiable", true)
			vim.api.nvim_buf_set_lines(buf, line, line + 1, false, { new_line })
			vim.api.nvim_buf_set_option(buf, "modifiable", false)

			-- Update stored selections
			vim.api.nvim_buf_set_var(buf, "multi_select_selections", selections)

			-- Move cursor down
			vim.api.nvim_win_set_cursor(win, { line + 1, 0 })
		end
	end
end

-- Helper function to confirm multi-select
function M._confirm_multi_select(buf)
	local ok, selections = pcall(vim.api.nvim_buf_get_var, buf, "multi_select_selections")
	local ok2, callback = pcall(vim.api.nvim_buf_get_var, buf, "multi_select_callback")
	local ok3, win = pcall(vim.api.nvim_buf_get_var, buf, "multi_select_win")

	if ok and ok2 and ok3 then
		local selected_values = {}
		for _, selection in ipairs(selections) do
			if selection.selected then
				table.insert(selected_values, selection.value)
			end
		end
		vim.api.nvim_win_close(win, true)
		callback(selected_values)
	end
end

-- Helper function to quit multi-select
function M._quit_multi_select(buf)
	local ok, callback = pcall(vim.api.nvim_buf_get_var, buf, "multi_select_callback")
	local ok2, win = pcall(vim.api.nvim_buf_get_var, buf, "multi_select_win")

	if ok and ok2 then
		vim.api.nvim_win_close(win, true)
	end
end

return M
