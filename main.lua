-- graphicalOS 1.0

-- load graphicalOS functionality
local returnMethods = {}

-- Basics
returnMethods.graphicalOsRootSettings = require "/graphicalOS_system/apis/settings"
returnMethods.kernel = require "/graphicalOS_system/kernel"
returnMethods.stopTheOs = require "/graphicalOS_system/apis/stop"

return returnMethods