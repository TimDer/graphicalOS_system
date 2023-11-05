local args = {...}
local settingsApi = require "/graphicalOS_system/apis/settings"

local function changeStartupStatus(startupWithGui)
    local replaceStartupFileContentsWith = "shell.run(\"/graphicalOS_system/startup.lua\")"
    if startupWithGui == false then
        replaceStartupFileContentsWith = "shell.run(\"/graphicalOS_system/programs/shell/main.lua nogui\")"
    end

    local startupFileRead = fs.open("/startup.lua", "r")
    local dataFromStartupFile = startupFileRead.readLine()
    if dataFromStartupFile == "shell.run(\"/graphicalOS_system/startup.lua\")" or dataFromStartupFile == "shell.run(\"/graphicalOS_system/programs/shell/main.lua nogui\")" then
        local startupFileWrite = fs.open("/startup.lua", "w")
        startupFileWrite.write(replaceStartupFileContentsWith)
        startupFileWrite.close()
    else
        print("Can not edit a custom startup file")
    end
    startupFileRead.close()
end

if args[1] == "startup" and args[2] == "true" then
    changeStartupStatus(true)
end

if args[1] == "startup" and args[2] == "false" then
    changeStartupStatus(false)
end

if args[1] == "startup" and args[2] == "status" then
    if settingsApi.file_exists("/startup.lua") then
        local startupFile = fs.open("/startup.lua", "r")

        local dataFromStartupFile = startupFile.readLine()
        if dataFromStartupFile == "shell.run(\"/graphicalOS_system/startup.lua\")" then
            print("Startup status: true")
        elseif dataFromStartupFile == "shell.run(\"/graphicalOS_system/programs/shell/main.lua nogui\")" then
            print("Startup status: false")
        else
            print("There is a custom startup file")
        end

        startupFile.close()
    end
end