local config = require("angular.config")
local schematics = require("angular.schematics")

local angular = {}

function angular.setup(user_config)
	config.setup(user_config or {})
	schematics.setup()
end

function angular.run_schematic()
	schematics.run_schematic()
end

function angular:list_schematics()
	schematics.list_schematics()
end

function angular.create_component()
	schematics.create_component()
end

function angular.create_service()
	schematics.create_service()
end

function angular.create_module()
	schematics.create_module()
end

function angular.create_directive()
	schematics.create_directive()
end

function angular.create_pipe()
	schematics.create_pipe()
end

return angular
