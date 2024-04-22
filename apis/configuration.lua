local configuration = {}
configuration.public = {}
configuration.Private = {}

configuration.Private.jsonLoader = require "/graphicalOS_system/apis/json"

configuration.Private.kernelSettings = {
    errorHandlingProgramOrTask = function (name, pathToProgram, useKernelEvents, x, y, width, height, func)
        if type(name) == "string" and type(pathToProgram) == "string" and shell.resolveProgram(pathToProgram) ~= nil and type(useKernelEvents) == "boolean" and type(x) == "number" and type(y) == "number" and type(width) == "number" and type(height) == "number" then
            if type(func) == "function" then
                func()
            end
        elseif type(name) ~= "string" then
            error("Error: The 'name' property need to be a string", 0)
        elseif type(pathToProgram) ~= "string" then
            error("Error: The 'pathToProgram' property need to be a string", 0)
        elseif shell.resolveProgram(pathToProgram) == nil then
            error("Error: The program you entered does not exist", 0)
        elseif type(useKernelEvents) ~= "boolean" then
            error("Error: the 'useKernelEvents' property need to be a boolean", 0)
        elseif type(x) == "number" or type(y) == "number" or type(width) == "number" or type(height) == "number" then
            error("Error: The 'processWindow' properties need to be a number type", 0)
        end
    end,

    checkIfTaskOrProgramExistsInSettingsFile = function (settingType, pathToProgram, func)
        if type(func) == "function" then
            local newPathToProgram = pathToProgram
            if string.sub(newPathToProgram, #newPathToProgram, #newPathToProgram) == "/" then
                newPathToProgram = string.sub(newPathToProgram, 1, #newPathToProgram - 1)
            end
 
            if shell.resolveProgram("/graphicalOS_data/user_data/settings.bin") ~= nil then
                if configuration.public.kernelSettings.settingsFile.data.kernel[settingType] ~= nil and configuration.public.kernelSettings.settingsFile.data.kernel[settingType][newPathToProgram] ~= nil then
                    func(newPathToProgram)
                elseif configuration.public.kernelSettings.settingsFile.data.kernel[settingType] == nil then
                    error("Error: Incorect settings type", 0)
                else
                    error("Error: That program or task is not configured", 0)
                end
            else
                error("Error: No settings found", 0)
            end
        end
    end,

    listProgramsAndTasks = function (listType)
        if configuration.public.kernelSettings.settingsFile.data.kernel[listType] ~= nil then
            for key, value in pairs(configuration.public.kernelSettings.settingsFile.data.kernel[listType]) do
                print(key)
            end
        end
    end
}
configuration.public.kernelSettings = {
    settingsFile = configuration.Private.jsonLoader.readFile("/graphicalOS_data/user_data/settings.bin"),

    createConfigurationFileIfItDoesNotExists = function ()
        if shell.resolveProgram("/graphicalOS_data/user_data/settings.bin") == nil then
            configuration.public.kernelSettings.settingsFile.data = {
                kernel = {
                    listOfPrograms = {},
                    listOfTasks = {},
                    startupPrograms = {},
                    startupTasks = {}
                }
            }

            configuration.public.kernelSettings.settingsFile.save()
        end
    end,

    addTaskToList = function (name, pathToProgram, useKernelEvents)
        configuration.public.kernelSettings.createConfigurationFileIfItDoesNotExists()

        configuration.Private.kernelSettings.errorHandlingProgramOrTask(name, pathToProgram, useKernelEvents, 1, 1, 1, 1, function ()
            local newPathToProgram = "/" .. shell.resolveProgram(pathToProgram)
            
            configuration.public.kernelSettings.settingsFile.data.kernel.listOfTasks[newPathToProgram] = {
                name = name,
                pathToProgram = newPathToProgram,
                useKernelEvents = useKernelEvents
            }
        end)
    end,

    addProgramToList = function (name, pathToProgram, useKernelEvents, x, y, width, height)
        configuration.public.kernelSettings.createConfigurationFileIfItDoesNotExists()

        configuration.Private.kernelSettings.errorHandlingProgramOrTask(name, pathToProgram, useKernelEvents, x, y, width, height, function ()
            local newPathToProgram = "/" .. shell.resolveProgram(pathToProgram)

            configuration.public.kernelSettings.settingsFile.data.kernel.listOfPrograms[newPathToProgram] = {
                name = name,
                pathToProgram = newPathToProgram,
                useKernelEvents = useKernelEvents,
                x = x,
                y = y,
                width = width,
                height = height
            }
        end)
    end,

    AddTask = function (name, pathToProgram, useKernelEvents)
        configuration.public.kernelSettings.createConfigurationFileIfItDoesNotExists()

        configuration.Private.kernelSettings.errorHandlingProgramOrTask(name, pathToProgram, useKernelEvents, 1, 1, 1, 1, function ()
            local newPathToProgram = "/" .. shell.resolveProgram(pathToProgram)

            configuration.public.kernelSettings.settingsFile.data.kernel.startupTasks[newPathToProgram] = {
                name = name,
                pathToProgram = newPathToProgram,
                useKernelEvents = useKernelEvents
            }
        end)
    end,

    AddProgram = function (name, pathToProgram, useKernelEvents, x, y, width, height)
        configuration.public.kernelSettings.createConfigurationFileIfItDoesNotExists()

        configuration.Private.kernelSettings.errorHandlingProgramOrTask(name, pathToProgram, useKernelEvents, x, y, width, height, function ()
            local newPathToProgram = "/" .. shell.resolveProgram(pathToProgram)

            configuration.public.kernelSettings.settingsFile.data.kernel.startupPrograms[newPathToProgram] = {
                name = name,
                pathToProgram = newPathToProgram,
                useKernelEvents = useKernelEvents,
                x = x,
                y = y,
                width = width,
                height = height
            }
        end)
    end,

    removeProgramFromList = function (pathToProgram)
        configuration.Private.kernelSettings.checkIfTaskOrProgramExistsInSettingsFile("listOfPrograms", pathToProgram, function (newPathToProgram)
            configuration.public.kernelSettings.settingsFile.data.kernel.listOfPrograms[newPathToProgram] = nil
        end)
    end,

    removeTask = function (pathToProgram)
        configuration.Private.kernelSettings.checkIfTaskOrProgramExistsInSettingsFile("startupTasks", pathToProgram, function (newPathToProgram)
            configuration.public.kernelSettings.settingsFile.data.kernel.startupTasks[newPathToProgram] = nil
        end)
    end,

    removeProgram = function (pathToProgram)
        configuration.Private.kernelSettings.checkIfTaskOrProgramExistsInSettingsFile("startupPrograms", pathToProgram, function (newPathToProgram)
            configuration.public.kernelSettings.settingsFile.data.kernel.startupPrograms[newPathToProgram] = nil
        end)
    end,

    removeTaskFromList = function (pathToProgram)
        configuration.Private.kernelSettings.checkIfTaskOrProgramExistsInSettingsFile("listOfTasks", pathToProgram, function (newPathToProgram)
            configuration.public.kernelSettings.settingsFile.data.kernel.listOfTasks[newPathToProgram] = nil
        end)
    end,

    listOfTheProgramList = function ()
        configuration.Private.kernelSettings.listProgramsAndTasks("listOfPrograms")
    end,

    listOfTheStartupPrograms = function ()
        configuration.Private.kernelSettings.listProgramsAndTasks("startupPrograms")
    end,

    listOfTheTaskList = function ()
        configuration.Private.kernelSettings.listProgramsAndTasks("listOfTasks")
    end,

    listOfTheStartupTasks = function ()
        configuration.Private.kernelSettings.listProgramsAndTasks("startupTasks")
    end,

    save = function ()
        configuration.public.kernelSettings.settingsFile.save()
    end
}

return configuration.public