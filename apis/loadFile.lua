local loadFile = {}
local loadFilePrivate = {}

loadFilePrivate.settings = require "/graphicalOS_system/apis/settings"
loadFilePrivate.requireModule = dofile("/rom/modules/main/cc/require.lua").make

loadFilePrivate.getEnv = function (environment, pathToProgram)
    environment.shell = shell
    environment.multishell = multishell
    environment.require, environment.package = loadFilePrivate.requireModule(environment, pathToProgram)

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

loadFile.startProgram = function (pathToProgram, env)
    pathToProgram = "/" .. shell.resolveProgram(pathToProgram)

    local fileString = loadFilePrivate.readFile(pathToProgram)
    local environment = loadFilePrivate.getEnv(env, pathToProgram)

    local func = load(
        fileString,
        "@" .. pathToProgram,
        nil,
        environment
    )

    func()
end

return loadFile