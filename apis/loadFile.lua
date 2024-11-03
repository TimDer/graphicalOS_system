local loadFile = {}
local loadFilePrivate = {}

loadFilePrivate.settings = require "/graphicalOS_system/apis/settings"
loadFilePrivate.requireModule = dofile("/rom/modules/main/cc/require.lua").make

loadFilePrivate.getEnv = function (environment, pathToProgram)
    local newEnvironment = {}
    newEnvironment.term = term
    newEnvironment.shell = shell
    newEnvironment.multishell = multishell
    newEnvironment.require, newEnvironment.package = loadFilePrivate.requireModule(environment, pathToProgram)

    for key, value in pairs(newEnvironment) do
        if environment[key] == nil then
            environment[key] = value
        end
    end

    return setmetatable(environment, { __index = _G })
end

loadFilePrivate.readFile = function (pathToProgram)
    if loadFilePrivate.settings.file_exists(pathToProgram) then
        local file = fs.open(pathToProgram, "r")
        local returnString = file.readAll()
        file.close()
        return returnString
    else
        error("File does not exist", 1)
    end
end

loadFilePrivate.splitCommand = function (pathToProgram)
    local results = {}
    
    local isBetweenQuotes = false
    for commandMatch in string.gmatch(pathToProgram .. "\"", "(.-)\"") do
        if isBetweenQuotes == true then
            table.insert(results, commandMatch)
        else
            for quoteMatch in string.gmatch(commandMatch, "[^ \t]+") do
                table.insert(results, quoteMatch)
            end
        end

        isBetweenQuotes = not isBetweenQuotes
    end

    return results
end

loadFilePrivate.errorHandling = function (command, env)
    if type(env) ~= "table" then
        env = {}
    end
    if type(command) ~= "string" then
        error("No such program: " .. type(command), 0)
    end

    return env
end

loadFile.runCommand = function (...)
    loadFile.startProgram(table.concat({ ... }, " "))
end

loadFile.startProgram = function (command, env)
    env = loadFilePrivate.errorHandling(command, env)

    local commandList = loadFilePrivate.splitCommand(command)
    local pathToProgram = commandList[1]

    if shell.resolveProgram(pathToProgram) ~= nil then
        pathToProgram = "/" .. shell.resolveProgram(pathToProgram)

        local fileString = loadFilePrivate.readFile(pathToProgram)
        local environment = loadFilePrivate.getEnv(env, pathToProgram)

        local func = load(
            fileString,
            "@" .. pathToProgram,
            nil,
            environment
        )

        func(table.unpack(commandList, 2))
    else
        error("No such program: " .. command, 0)
    end
end

return loadFile