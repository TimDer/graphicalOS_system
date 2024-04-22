local completionFunctions = {}
local completionFunctionsPrivate = {}

function completionFunctionsPrivate.createArgumentEnding(theArgument, inputArgument)
    local returnValue = nil

    if string.len(inputArgument) <= string.len(theArgument) then
        local prepareReturnValue = string.sub(theArgument, string.len(inputArgument) + 1, string.len(theArgument))

        if theArgument == inputArgument .. prepareReturnValue then
            returnValue = prepareReturnValue
        end
    end
    
    return returnValue
end

function completionFunctionsPrivate.checkWhichArgumentToUse(inputArgument, theArguments)
    local returnValue = nil

    if type(theArguments) == "table" then
        returnValue = {}

        for key, value in pairs(theArguments) do
            local getArgumentEnd = completionFunctionsPrivate.createArgumentEnding(value, inputArgument)

            if getArgumentEnd ~= nil then
                if inputArgument .. getArgumentEnd == value then
                    table.insert(returnValue, getArgumentEnd)
                end
            end
        end

        if next(returnValue) == nil then
            returnValue = nil
        end
    end

    return returnValue
end

completionFunctionsPrivate.argumentBuilder = {}

function completionFunctionsPrivate.argumentBuilder.complete(buildArgument, index, argument, previous)
    local commandTable = completionFunctionsPrivate.argumentBuilder.build(buildArgument, 1, index, argument, previous)

    return completionFunctionsPrivate.checkWhichArgumentToUse(argument, commandTable)
end

function completionFunctionsPrivate.argumentBuilder.build(buildArgument, indexPos, index, argument, previous)
    local argumentValue = nil

    if type(buildArgument) == "function" then
        buildArgument = buildArgument()
    end

    if indexPos == index then
        argumentValue = {}
        for key, value in pairs(buildArgument) do
            table.insert(argumentValue, value.name)
        end
    elseif next(buildArgument) ~= nil then
        argumentValue = {}
        for key, value in pairs(buildArgument) do
            if value.name == previous[indexPos + 1] then
                argumentValue = completionFunctionsPrivate.argumentBuilder.build(value.arguments, indexPos + 1, index, argument, previous)
                break
            end
        end
    end

    return argumentValue
end

function completionFunctionsPrivate.argumentBuilder.createArgumentItem(name, arguments)
    return {
        name = name,
        arguments = arguments
    }
end

function completionFunctionsPrivate.argumentBuilder.folderArgument(argument, arguments, indexPos, index, previous)
    local funcTable = {}

    function funcTable.setupArguments(argument, arguments)
        local folderArgument = {}

        local filePath = "/"
        local filePathTable = {}
        for value in string.gmatch(argument, "([^/]+)") do
            table.insert(filePathTable, value)
        end
        if fs.isDir(argument) ~= true and shell.resolveProgram(argument) == nil then
            table.remove(filePathTable, #filePathTable)
        end

        if #filePathTable >= 1 then
            filePath = ""
            for key, value in pairs(filePathTable) do
                filePath = filePath .. "/" .. value
            end
        elseif #argument == 0 then
            table.insert(folderArgument, completionFunctionsPrivate.argumentBuilder.createArgumentItem(".", arguments))
            return folderArgument
        end

        if fs.isDir(filePath) then
            local itemsInPath = fs.list(filePath)

            for key, value in pairs(itemsInPath) do
                if filePath == "/" then
                    table.insert(folderArgument, completionFunctionsPrivate.argumentBuilder.createArgumentItem("/" .. value .. "/", arguments))
                else
                    table.insert(folderArgument, completionFunctionsPrivate.argumentBuilder.createArgumentItem(filePath .. "/" .. value .. "/", arguments))
                end
            end
        end

        return folderArgument
    end

    function funcTable.argumentOrPrevious(argument, arguments, indexPos, index, previous)
        if index > indexPos then
            return {completionFunctionsPrivate.argumentBuilder.createArgumentItem(previous[indexPos + 1], arguments)}
        else
            return funcTable.setupArguments(argument, arguments)
        end
    end

    return funcTable.argumentOrPrevious(argument, arguments, indexPos, index, previous)
end

function completionFunctionsPrivate.arguments(currentShell, index, argument, previous)
    local folderArgument = completionFunctionsPrivate.argumentBuilder.folderArgument(argument, {}, 4, index, previous)

    return completionFunctionsPrivate.argumentBuilder.complete(
        {
            completionFunctionsPrivate.argumentBuilder.createArgumentItem("add", {
                completionFunctionsPrivate.argumentBuilder.createArgumentItem("program", {
                    completionFunctionsPrivate.argumentBuilder.createArgumentItem("startup", folderArgument),
                    completionFunctionsPrivate.argumentBuilder.createArgumentItem("list", folderArgument),
                }),
                completionFunctionsPrivate.argumentBuilder.createArgumentItem("task", {
                    completionFunctionsPrivate.argumentBuilder.createArgumentItem("startup", folderArgument),
                    completionFunctionsPrivate.argumentBuilder.createArgumentItem("list", folderArgument),
                }),
            }),
            completionFunctionsPrivate.argumentBuilder.createArgumentItem("remove", {
                completionFunctionsPrivate.argumentBuilder.createArgumentItem("program", {
                    completionFunctionsPrivate.argumentBuilder.createArgumentItem("startup", folderArgument),
                    completionFunctionsPrivate.argumentBuilder.createArgumentItem("list", folderArgument),
                }),
                completionFunctionsPrivate.argumentBuilder.createArgumentItem("task", {
                    completionFunctionsPrivate.argumentBuilder.createArgumentItem("startup", folderArgument),
                    completionFunctionsPrivate.argumentBuilder.createArgumentItem("list", folderArgument),
                }),
            }),
            completionFunctionsPrivate.argumentBuilder.createArgumentItem("list", {
                completionFunctionsPrivate.argumentBuilder.createArgumentItem("program", {
                    completionFunctionsPrivate.argumentBuilder.createArgumentItem("startup", {}),
                    completionFunctionsPrivate.argumentBuilder.createArgumentItem("list", {}),
                }),
                completionFunctionsPrivate.argumentBuilder.createArgumentItem("task", {
                    completionFunctionsPrivate.argumentBuilder.createArgumentItem("startup", {}),
                    completionFunctionsPrivate.argumentBuilder.createArgumentItem("list", {}),
                }),
            }),
            completionFunctionsPrivate.argumentBuilder.createArgumentItem("startup", {
                completionFunctionsPrivate.argumentBuilder.createArgumentItem("true", {}),
                completionFunctionsPrivate.argumentBuilder.createArgumentItem("false", {}),
                completionFunctionsPrivate.argumentBuilder.createArgumentItem("status", {})
            })
        },
        index,
        argument,
        previous
    )
end

function completionFunctions.setFunctions()
    shell.setCompletionFunction("graphicalOS_system/programs/shell/commands/gsettings.lua", completionFunctionsPrivate.arguments)
end

return completionFunctions