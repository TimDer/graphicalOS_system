local args = {...}
local settingsApi = require "/graphicalOS_system/apis/settings"

if args[1] == "startup" and args[2] == "true" then
    local startupFile = fs.open("/startup.lua", "w")
    startupFile.write("shell.run(\"/graphicalOS_system/example.lua\")")
    startupFile.close()
end

if args[1] == "startup" and args[2] == "false" then
    if settingsApi.file_exists("/startup.lua") then
        fs.delete("/startup.lua")
    end
end