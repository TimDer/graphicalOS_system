local uuid = {}
local uuidPrivate = {}

uuidPrivate.usedUuids = {}
uuidPrivate.stringOfCharacters = "abcdefghijklmnopqrstuvwxyz-ABCDEFGHIJKLMNOPQRSTUVWXYZ_0123456789=!@#$%^&*()+:><.,"
uuidPrivate.addToTimerNumber = 1
uuidPrivate.oldTimerState = os.time()

function uuidPrivate.getTimer(ostimer)
    local newOstimer = tostring(ostimer)

    local newOstimerLength = string.len(newOstimer)
    local returnString = ""
    for i = 1, newOstimerLength do
        local addToReturn = string.sub(newOstimer, i, i)
        if addToReturn ~= "." then
            returnString = returnString .. addToReturn
        end
    end

    return tonumber(returnString)
end

function uuidPrivate.randomCharacter()
    local stringOfCharactersLength = string.len(uuidPrivate.stringOfCharacters)

    local ostimer = os.time()
    if uuidPrivate.getTimer(ostimer) > uuidPrivate.getTimer(uuidPrivate.oldTimerState) then
        uuidPrivate.addToTimerNumber = 1
        uuidPrivate.oldTimerState = ostimer
    end

    math.randomseed(uuidPrivate.addToTimerNumber + uuidPrivate.getTimer(os.time()))
    math.random()
    local characterNum = math.random(stringOfCharactersLength)

    uuidPrivate.addToTimerNumber = uuidPrivate.addToTimerNumber + 1

    return string.sub(uuidPrivate.stringOfCharacters, characterNum, characterNum)
end

function uuidPrivate.isUuidAlreadyInUse(returnUuid)
    local inUseReturn = true

    if returnUuid == "" then
        inUseReturn = true
    elseif next(uuidPrivate.usedUuids) == nil then
        inUseReturn = false
    elseif uuidPrivate.usedUuids[returnUuid] then
        inUseReturn = true
    end

    return inUseReturn
end

function uuid.CreateUuid(uuidLength)
    local returnUuid = ""
    local isUuidInUse = uuidPrivate.isUuidAlreadyInUse(returnUuid)

    while isUuidInUse do
        for i = 1, uuidLength do
            returnUuid = returnUuid .. uuidPrivate.randomCharacter()
        end

        if uuidPrivate.isUuidAlreadyInUse() then
            returnUuid = ""
        else
            isUuidInUse = false
        end
    end

    return returnUuid
end

return uuid