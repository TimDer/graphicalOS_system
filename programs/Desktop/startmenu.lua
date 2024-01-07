local startmenu = {}
local startmenuPrivate = {}

startmenuPrivate.taskbar = require "/graphicalOS_system/programs/Desktop/taskbar"
startmenuPrivate.kernelEventHandler = require "/graphicalOS_system/apis/kernelEventHandler"
startmenuPrivate.rootTermWidth = 0
startmenuPrivate.rootTermHeight = 0
startmenuPrivate.Event = ""
startmenuPrivate.button = ""
startmenuPrivate.X = 0
startmenuPrivate.Y = 0
startmenuPrivate.exitToDesktop = function () end
startmenuPrivate.minimisedProgramUuid = ""

--[[
    {
        uuid = {
            name: string
            pathToProgramOrTask: string
            useKernelEvents: boolean
        }
    }
]]
startmenuPrivate.programs = {}

--[[
    {
        number = uuid
    }
]]
startmenuPrivate.programsList = {}

startmenu.desktopOption = "desktop"

function startmenuPrivate.drawMenu()
    startmenuPrivate.exitToDesktop()

    if startmenuPrivate.minimisedProgramUuid ~= "" then
        term.setBackgroundColor(128)
        for index = 1, (startmenuPrivate.rootTermHeight - 1), 1 do
            term.setCursorPos(1, index)
            term.clearLine()
        end

        term.setCursorPos(1, 1)
        term.setBackgroundColor(8192)
        term.clearLine()
        
        term.setCursorPos(1, 1)
        term.setTextColor(1)
        term.write(startmenuPrivate.taskbar.getNameByUuid(startmenuPrivate.minimisedProgramUuid))

        term.setCursorPos(startmenuPrivate.rootTermWidth - 1, 1)
        term.setBackgroundColor(2048)
        term.write("_")

        term.setCursorPos(startmenuPrivate.rootTermWidth, 1)
        term.setBackgroundColor(16384)
        term.write("X")
    end

    local menuHight = startmenuPrivate.getMenuHight()
    local menuWidth = startmenuPrivate.getMenuWidth()

    term.setBackgroundColor(32768)
    for hightIndex = (startmenuPrivate.rootTermHeight - 1), menuHight, -1 do
        for widthIndex = 1, menuWidth, 1 do
            term.setCursorPos(widthIndex, hightIndex)
            term.write(" ")
        end
    end

    local shutdownPos = startmenuPrivate.rootTermHeight - 2
    local rebootPos = startmenuPrivate.rootTermHeight - 3
    
    term.setTextColor(1)
    term.setCursorPos(2, shutdownPos)
    term.write("Shutdown")
    term.setCursorPos(2, rebootPos)
    term.write("Reboot")
end

function startmenuPrivate.drawMenuBtns()
    local startHeight = startmenuPrivate.rootTermHeight - 5

    term.setTextColor(1)
    for key, value in pairs(startmenuPrivate.programsList) do
        if startHeight == 1 then
            break
        end

        term.setCursorPos(2, startHeight)
        term.write(startmenuPrivate.programs[value].name)
        startHeight = startHeight - 1
    end
end

function startmenuPrivate.drawStartmenu()
    if startmenu.desktopOption == "startmenu" then
        startmenuPrivate.drawMenu()
        startmenuPrivate.drawMenuBtns()
    else
        startmenuPrivate.exitToDesktop()
    end
end

function startmenuPrivate.getMenuWidth()
    local defaultPos = 10

    for key, value in pairs(startmenuPrivate.programsList) do
        local name = startmenuPrivate.programs[value].name

        if (string.len(name) + 2) >= defaultPos then
            defaultPos = string.len(name) + 2
        end
    end

    return defaultPos
end

function startmenuPrivate.getMenuHight()
    local defaultPos = startmenuPrivate.rootTermHeight - 4

    if next(startmenuPrivate.programsList) ~= nil then
        defaultPos = defaultPos - 1

        for key, value in pairs(startmenuPrivate.programsList) do
            if defaultPos == 1 then
                break
            end

            defaultPos = defaultPos - 1
        end
    end

    return defaultPos
end

function startmenuPrivate.startProgram()
    local startHeight = startmenuPrivate.rootTermHeight - 5
    local menuMaxWidth = startmenuPrivate.getMenuWidth()

    for key, value in pairs(startmenuPrivate.programsList) do
        if startmenuPrivate.Y == startHeight and startmenuPrivate.X >= 2 and startmenuPrivate.X <= menuMaxWidth then
            startmenuPrivate.taskbar.startProgram(startmenuPrivate.programs[value].name, startmenuPrivate.programs[value].pathToProgramOrTask, startmenuPrivate.programs[value].useKernelEvents)
        end
        
        startHeight = startHeight - 1
    end
end

function startmenu.startBtnClick()
    if startmenuPrivate.Event == "mouse_click" then
        if (startmenuPrivate.Y == startmenuPrivate.rootTermHeight and startmenuPrivate.X >= 1 and startmenuPrivate.X <= 9) and startmenu.desktopOption == "desktop" then
            startmenuPrivate.minimisedProgramUuid = startmenuPrivate.kernelEventHandler.kernelMethods.getCurrentRunningProgramUuid()
            if startmenuPrivate.minimisedProgramUuid ~= "" then
                startmenuPrivate.kernelEventHandler.kernelMethods.setCurrentRunningProgram("")
            end

            startmenu.desktopOption = "startmenu"
            startmenuPrivate.drawStartmenu()
        elseif (startmenuPrivate.Y < startmenuPrivate.rootTermHeight and startmenuPrivate.Y >= startmenuPrivate.getMenuHight() and startmenuPrivate.X <= startmenuPrivate.getMenuWidth() and startmenuPrivate.X >= 1) == false and startmenu.desktopOption == "startmenu" then
            startmenu.desktopOption = "desktop"
            startmenuPrivate.kernelEventHandler.kernelMethods.setCurrentRunningProgram(startmenuPrivate.minimisedProgramUuid)
            startmenuPrivate.minimisedProgramUuid = ""
            startmenuPrivate.drawStartmenu()
        elseif startmenuPrivate.Y == (startmenuPrivate.rootTermHeight - 2) and startmenuPrivate.X >= 2 and startmenuPrivate.X <= 9 and startmenu.desktopOption == "startmenu" then
            os.shutdown()
        elseif startmenuPrivate.Y == (startmenuPrivate.rootTermHeight - 3) and startmenuPrivate.X >= 2 and startmenuPrivate.X <= 7 and startmenu.desktopOption == "startmenu" then
            os.reboot()
        elseif startmenuPrivate.Y <= (startmenuPrivate.rootTermHeight - 5) and startmenuPrivate.Y >= (startmenuPrivate.getMenuHight() + 1) and startmenuPrivate.X <= (startmenuPrivate.getMenuWidth() - 1) and startmenu.desktopOption == "startmenu" then
            startmenu.desktopOption = "desktop"
            startmenuPrivate.drawStartmenu()
            startmenuPrivate.startProgram()
        end
    end
end

function startmenuPrivate.setProgramsList()
    local programsList = {}

    local index = 1
    for key, value in pairs(startmenuPrivate.programs) do
        programsList[index] = key
        index = index + 1
    end

    return programsList
end

function startmenu.setProperties(event, button, X, Y, rootTermWidth, rootTermHeight, kernelEventHandler, taskbar, exitToDesktop)
    startmenuPrivate.Event = event
    startmenuPrivate.button = button
    startmenuPrivate.X = X
    startmenuPrivate.Y = Y
    startmenuPrivate.rootTermWidth = rootTermWidth
    startmenuPrivate.rootTermHeight = rootTermHeight
    startmenuPrivate.kernelEventHandler = kernelEventHandler
    startmenuPrivate.taskbar = taskbar
    startmenuPrivate.programs = startmenuPrivate.kernelEventHandler.kernelData.listOfProgramsAndTasks.programs
    startmenuPrivate.programsList = startmenuPrivate.setProgramsList()
    startmenuPrivate.exitToDesktop = exitToDesktop
end

return startmenu