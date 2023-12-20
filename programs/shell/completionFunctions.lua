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
        for key, value in pairs(theArguments) do
            local getArgumentEnd = completionFunctionsPrivate.createArgumentEnding(value, inputArgument)

            if getArgumentEnd ~= nil then
                if inputArgument .. getArgumentEnd == value then
                    returnValue = getArgumentEnd
                end
            end
        end
    end

    return returnValue
end

function completionFunctionsPrivate.gsettings(currentShell, index, argument, previous)
    if index == 1 then
        local getArgumentEnd = completionFunctionsPrivate.checkWhichArgumentToUse(argument, {
            "startup"
        })

        if getArgumentEnd ~= nil then
            return { getArgumentEnd }
        end
    elseif index == 2 and previous[2] == "startup" then
        local getArgumentEnd = completionFunctionsPrivate.checkWhichArgumentToUse(argument, {
            "true",
            "false",
            "status"
        })
        
        if getArgumentEnd ~= nil then
            return { getArgumentEnd }
        end
    end

    return nil
end

function completionFunctions.setFunctions()
    shell.setCompletionFunction("graphicalOS_system/programs/shell/commands/gsettings.lua", completionFunctionsPrivate.gsettings)
end

return completionFunctions