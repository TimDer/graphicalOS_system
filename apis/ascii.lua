local asciiModule = {}
local asciiModulePrivate = {}

asciiModulePrivate.convertDecimalToHexadecimal = function (decimalNum)
    local result = ""

    if decimalNum < 0 then
        error("The number needs to be greater or equal to zero. \"" .. decimalNum .. "\" was given")
    elseif decimalNum == 0 then
        result = "00"
    else
        local hexCharacters = "0123456789ABCDEF"

        while decimalNum > 0 do
            local charPos = math.fmod(decimalNum, 16)
            decimalNum = math.floor(decimalNum / 16)
            result = string.sub(hexCharacters, charPos + 1, charPos + 1) .. result
        end

        if #result == 1 then
            result = "0" .. result
        end
    end

    return result
end

asciiModule.convertCharToHexadecimal = function (charSource)
    return asciiModulePrivate.convertDecimalToHexadecimal(
        string.byte(
            charSource
        )
    )
end

asciiModule.convertHexadecimalToChar = function (hexSource)
    return string.char(
        tonumber(
            hexSource,
            16
        )
    )
end

asciiModule.convertStringToHexadecimal = function (stringToHex)
    local hexTable = {}
    
    for i = 1, #stringToHex, 1 do
        table.insert(
            hexTable,
            asciiModule.convertCharToHexadecimal(
                string.sub(stringToHex, i, i)
            )
        )
    end

    return hexTable
end

asciiModule.convertHexadecimalToString = function (hexTable)
    local resultString = ""

    for key, value in pairs(hexTable) do
        resultString = resultString .. asciiModule.convertHexadecimalToChar(value)
    end

    return resultString
end

asciiModule.file = {}

asciiModule.file.save = function (hexTable, pathToFile)
    local saveStringTable = {}

    local currentStringNum = 1
    local currentStringIndex = 1
    saveStringTable[currentStringIndex] = ""

    for tableIndex = 1, #hexTable, 1 do
        if currentStringIndex > 16 then
            currentStringIndex = 1
            currentStringNum = currentStringNum + 1
            saveStringTable[currentStringNum] = ""
        end

        if saveStringTable[currentStringNum] == "" then
            saveStringTable[currentStringNum] = hexTable[tableIndex]
        else
            saveStringTable[currentStringNum] = saveStringTable[currentStringNum] .. " " .. hexTable[tableIndex]
        end
        
        currentStringIndex = currentStringIndex + 1
    end

    local file = fs.open(pathToFile, "w")
    for key, value in pairs(saveStringTable) do
        if #saveStringTable == key then
            file.write(value)
        else
            file.write(value .. "\n")
        end
    end
    file.close()
end

asciiModule.file.load = function (pathToFile)
    local tableHex = {}
    local returnHexTable = {}

    local file = fs.open(pathToFile, "r")
    local fileContentsString = string.gsub(file.readAll(), "\n", " ")
    file.close()

    for hexNum in string.gmatch(fileContentsString, "([^ ]+)") do
        table.insert(returnHexTable, hexNum)
    end

    return returnHexTable
end

return asciiModule