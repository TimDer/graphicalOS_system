local json = {}
local jsonPrivate = {}

jsonPrivate.ascii = require "/graphicalOS_system/apis/ascii"

jsonPrivate.readFile = function (pathToFile)
    local jsonFilePrivate = {} 
    local jsonFile = {}

    jsonFile.data = {}

    jsonFile.save = function ()
        jsonPrivate.ascii.file.save(
            jsonPrivate.ascii.convertStringToHexadecimal(
                textutils.serialiseJSON(
                    jsonFile.data
                )
            ),
            pathToFile
        )
    end

    jsonFile.openFile = function ()
        jsonFile.data = textutils.unserialiseJSON(
            jsonPrivate.ascii.convertHexadecimalToString(
                jsonPrivate.ascii.file.load(pathToFile)
            )
        )
    end

    jsonFile.openFile()

    return jsonFile
end

json.readFile = function (pathToFile)
    if type(pathToFile) == "string" then
        return jsonPrivate.readFile(pathToFile)
    else
        error("readFile requires a string, '" .. type(pathToFile) .. "' was given", 1)
    end
end

return json