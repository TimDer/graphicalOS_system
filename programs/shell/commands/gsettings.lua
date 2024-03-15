local gSettings = {}
gSettings.args = {...}
gSettings.settingsApi = require "/graphicalOS_system/apis/settings"

gSettings.commands = {
    startup = function ()
        local function changeStartupStatus(startupWithGui)
            local replaceStartupFileContentsWith = "shell.run(\"/graphicalOS_system/startup.lua\")"
            if startupWithGui == false then
                replaceStartupFileContentsWith = "shell.run(\"/graphicalOS_system/programs/shell/main.lua nogui\")"
            end
        
            local createStartupFile = function ()
                local startupFileWrite = fs.open("/startup.lua", "w")
                startupFileWrite.write(replaceStartupFileContentsWith)
                startupFileWrite.close()
            end
        
            if gSettings.settingsApi.file_exists("/startup.lua") then
                local startupFileRead = fs.open("/startup.lua", "r")
                local dataFromStartupFile = startupFileRead.readLine()
                if dataFromStartupFile == "shell.run(\"/graphicalOS_system/startup.lua\")" or dataFromStartupFile == "shell.run(\"/graphicalOS_system/programs/shell/main.lua nogui\")" then
                    createStartupFile()
                else
                    print("Can not edit a custom startup file")
                end
                startupFileRead.close()
            else
                createStartupFile()
            end
        end
        
        if gSettings.args[1] == "startup" and gSettings.args[2] == "true" then
            changeStartupStatus(true)
        end
        
        if gSettings.args[1] == "startup" and gSettings.args[2] == "false" then
            changeStartupStatus(false)
        end
        
        if gSettings.args[1] == "startup" and gSettings.args[2] == "status" then
            if gSettings.settingsApi.file_exists("/startup.lua") then
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
    end,

    run = function ()
        gSettings.commands.startup()
    end
}

gSettings.commands.run()