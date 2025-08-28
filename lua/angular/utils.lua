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

return M
