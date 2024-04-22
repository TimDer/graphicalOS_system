local gSettings = {}
gSettings.args = {...}
gSettings.settingsApi = require "/graphicalOS_system/apis/settings"
gSettings.configuration = require "/graphicalOS_system/apis/configuration"

gSettings.commands = {
    startup = function ()
        local function changeStartupStatus(startupWithGui)
            local replaceStartupFileContentsWith = "shell.run(\"/graphicalOS_system/startup.lua\")"
            if startupWithGui == false then
                replaceStartupFileContentsWith = "shell.run(\"/graphicalOS_system/legacyShellStartup.lua\")"
            end
        
            local createStartupFile = function ()
                local startupFileWrite = fs.open("/startup.lua", "w")
                startupFileWrite.write(replaceStartupFileContentsWith)
                startupFileWrite.close()
            end
        
            if gSettings.settingsApi.file_exists("/startup.lua") then
                local startupFileRead = fs.open("/startup.lua", "r")
                local dataFromStartupFile = startupFileRead.readLine()
                if dataFromStartupFile == "shell.run(\"/graphicalOS_system/startup.lua\")" or dataFromStartupFile == "shell.run(\"/graphicalOS_system/legacyShellStartup.lua\")" then
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

    setProgramActionGroups = function ()
        return {
            {
                name = "programName",
                displayName = "Program name: "
            },
            {
                name = "kernelEventHandler",
                displayName = "Kernel event handler (y/n): "
            },
            {
                name = "x",
                displayName = "X position: "
            },
            {
                name = "y",
                displayName = "Y position: "
            },
            {
                name = "width",
                displayName = "Width from X position: "
            },
            {
                name = "height",
                displayName = "Height from Y position: "
            },
        }
    end,

    setTaskActionGroups = function ()
        return {
            {
                name = "taskName",
                displayName = "Program name: "
            },
            {
                name = "kernelEventHandler",
                displayName = "Kernel event handler (y/n): "
            }
        }
    end,

    checkForErrors = function (returnValue)
        if returnValue.kernelEventHandler ~= nil then
            if returnValue.kernelEventHandler == "y" or returnValue.kernelEventHandler == "Y" then
                returnValue.kernelEventHandler = true
            elseif returnValue.kernelEventHandler == "n" or returnValue.kernelEventHandler == "N" then
                returnValue.kernelEventHandler = false
            elseif type(returnValue.kernelEventHandler) ~= "boolean" then
                error("Error: only y/n is accepted", 0)
            end
        end

        if returnValue.x ~= nil then
            if type(returnValue.x) == "string" and tonumber(returnValue.x) ~= nil then
                returnValue.x = tonumber(returnValue.x)
            elseif type(returnValue.x) ~= "number" then
                error("Error: The X position has to be a number", 0)
            end
        end

        if returnValue.y ~= nil then
            if type(returnValue.y) == "string" and tonumber(returnValue.y) ~= nil then
                returnValue.y = tonumber(returnValue.y)
            elseif type(returnValue.y) ~= "number" then
                error("Error: The X position has to be a number", 0)
            end
        end

        if returnValue.width ~= nil then
            if type(returnValue.width) == "string" and tonumber(returnValue.width) ~= nil then
                returnValue.width = tonumber(returnValue.width)
            elseif type(returnValue.width) ~= "number" then
                error("Error: The X position has to be a number", 0)
            end
        end

        if returnValue.height ~= nil then
            if type(returnValue.height) == "string" and tonumber(returnValue.height) ~= nil then
                returnValue.height = tonumber(returnValue.height)
            elseif type(returnValue.height) ~= "number" then
                error("Error: The X position has to be a number", 0)
            end
        end

        return returnValue
    end,

    getProperties = function (actionGroup)
        local returnValue = {}

        local posX, posY = term.getCursorPos()
        local sizeX, sizeY = term.getSize()

        local plusPosYNum = 0
        for key, value in pairs(actionGroup) do
            term.setCursorPos(1, posY + plusPosYNum)
            term.write(value.displayName)
            term.setCursorPos(#value.displayName + 1, posY + plusPosYNum)
            returnValue[value.name] = read()

            if posY + plusPosYNum < sizeY then
                plusPosYNum = plusPosYNum + 1
            end
        end

        returnValue = gSettings.commands.checkForErrors(returnValue)

        return returnValue
    end,

    addProgramToSettingsFile = function (func)
        if type(func) == "function" then
            local file = gSettings.args[4]
            if file ~= nil then
                local readProperties = gSettings.commands.getProperties(gSettings.commands.setProgramActionGroups())
                func(
                    readProperties.programName,
                    file,
                    readProperties.kernelEventHandler,
                    readProperties.x,
                    readProperties.y,
                    readProperties.width,
                    readProperties.height
                )
                gSettings.configuration.kernelSettings.save()
                print("Done!")
            else
                print("Error")
            end
        end
    end,

    addTaskToSettingsFile = function (func)
        if type(func) == "function" then
            local file = gSettings.args[4]
            if file ~= nil then
                local readProperties = gSettings.commands.getProperties(gSettings.commands.setTaskActionGroups())
                func(
                    readProperties.taskName,
                    file,
                    readProperties.kernelEventHandler
                )
                gSettings.configuration.kernelSettings.save()
                print("Done!")
            else
                print("Error")
            end
        end
    end,

    commands = {
        add = {
            program = {
                startup = function ()
                    gSettings.commands.addProgramToSettingsFile(gSettings.configuration.kernelSettings.AddProgram)
                end,
                list = function ()
                    gSettings.commands.addProgramToSettingsFile(gSettings.configuration.kernelSettings.addProgramToList)
                end
            },
            task = {
                startup = function ()
                    gSettings.commands.addTaskToSettingsFile(gSettings.configuration.kernelSettings.AddTask)
                end,
                list = function ()
                    gSettings.commands.addTaskToSettingsFile(gSettings.configuration.kernelSettings.addTaskToList)
                end
            }
        },
        remove = {
            program = {
                startup = function ()
                    gSettings.configuration.kernelSettings.removeProgram(gSettings.args[4])
                    gSettings.configuration.kernelSettings.save()
                end,
                list = function ()
                    gSettings.configuration.kernelSettings.removeProgramFromList(gSettings.args[4])
                    gSettings.configuration.kernelSettings.save()
                end
            },
            task = {
                startup = function ()
                    gSettings.configuration.kernelSettings.removeTask(gSettings.args[4])
                    gSettings.configuration.kernelSettings.save()
                end,
                list = function ()
                    gSettings.configuration.kernelSettings.removeTaskFromList(gSettings.args[4])
                    gSettings.configuration.kernelSettings.save()
                end
            }
        },
        list = {
            program = {
                startup = function ()
                    gSettings.configuration.kernelSettings.listOfTheStartupPrograms()
                end,
                list = function ()
                    gSettings.configuration.kernelSettings.listOfTheProgramList()
                end
            },
            task = {
                startup = function ()
                    gSettings.configuration.kernelSettings.listOfTheStartupTasks()
                end,
                list = function ()
                    gSettings.configuration.kernelSettings.listOfTheTaskList()
                end
            }
        }
    },

    run = function ()
        local command = {}
        if next(gSettings.args) ~= nil then
            command = gSettings.commands.commands
            for index = 1, #gSettings.args, 1 do
                if command[gSettings.args[index]] ~= nil then
                    command = command[gSettings.args[index]]
                    if type(command) == "function" then
                        break
                    end
                else
                    command = {}
                    break
                end
            end
        end

        if type(command) == "function" then
            command()
        end

        gSettings.commands.startup()
    end
}

gSettings.commands.run()