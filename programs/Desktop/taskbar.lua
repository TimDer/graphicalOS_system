local taskbar = {}
local taskbarPrivate = {}

taskbarPrivate.kernelEventHandler = require "/graphicalOS_system/apis/kernelEventHandler"
taskbarPrivate.rootTermWidth = 0
taskbarPrivate.rootTermHeight = 0
taskbarPrivate.event = ""
taskbarPrivate.button = ""
taskbarPrivate.X = 0
taskbarPrivate.Y = 0
taskbarPrivate.amountOfActivePrograms = 0
taskbarPrivate.currentActivePage = 0

--[[
    {
        uuid = {
            name: string
            programUuid: string
            orderNumber: number
        }
    }
]]
taskbarPrivate.listActivePrograms = {}

--[[
    {
        number: string ---> programUuid
    }
]]
taskbarPrivate.listActiveProgramsOrder = {}

--[[
    {
        number: pageStartNum
    }
]]
taskbarPrivate.taskbarPages = {}

function taskbarPrivate.calculatePageNumbers()
    local pageNumber = 1

    if taskbarPrivate.amountOfActivePrograms ~= 0 then
        taskbarPrivate.taskbarPages = {}

        table.insert(taskbarPrivate.taskbarPages, pageNumber)
        local createPageNum = taskbarPrivate.taskBarGetEndNumberDependingOnTheWidthOfTheTaskBar(pageNumber)
        pageNumber = createPageNum.lastNumberOfPage + 1

        if createPageNum.usedBreak then
            for index = 1, #taskbarPrivate.listActiveProgramsOrder, 1 do
                if index == pageNumber then
                    table.insert(taskbarPrivate.taskbarPages, pageNumber)
                    pageNumber = createPageNum.lastNumberOfPage + 1
                end

                createPageNum = taskbarPrivate.taskBarGetEndNumberDependingOnTheWidthOfTheTaskBar(pageNumber)
            end
        end
    end
end

function taskbarPrivate.taskBarGetEndNumberDependingOnTheWidthOfTheTaskBar(startNum)
    local returnValue = {}

    returnValue.usedBreak = false
    returnValue.cursorPos = 11
    returnValue.lastNumberOfPage = startNum

    if returnValue.lastNumberOfPage > 0 and returnValue.lastNumberOfPage <= #taskbarPrivate.listActiveProgramsOrder then
        for i = returnValue.lastNumberOfPage, #taskbarPrivate.listActiveProgramsOrder do
            local uuid = taskbarPrivate.listActiveProgramsOrder[i]
            returnValue.cursorPos = returnValue.cursorPos + string.len(taskbarPrivate.listActivePrograms[uuid].name) + 1
    
            if returnValue.cursorPos >= (taskbarPrivate.rootTermWidth - 1) then
                returnValue.usedBreak = true
                break
            end
    
            returnValue.lastNumberOfPage = i
        end
    end

    return returnValue
end

function taskbar.drawTaskbar()
    local backupBackgroundColor = term.getBackgroundColor()

    -- Clear taskbar
    term.setBackgroundColor(256)
    for i = 10, taskbarPrivate.rootTermWidth do
        term.setCursorPos(i, taskbarPrivate.rootTermHeight)
        term.write(" ")
    end
    term.setBackgroundColor(backupBackgroundColor)
    
    -- Back btn
    term.setBackgroundColor(512)
    term.setCursorPos(10, taskbarPrivate.rootTermHeight)
    term.write("<")
    term.setBackgroundColor(backupBackgroundColor)
    
    -- Programs
    local cursorPos = 11
    if taskbarPrivate.amountOfActivePrograms ~= 0 then
        local endNum = taskbarPrivate.taskBarGetEndNumberDependingOnTheWidthOfTheTaskBar(taskbarPrivate.taskbarPages[taskbarPrivate.currentActivePage])
        for i = taskbarPrivate.taskbarPages[taskbarPrivate.currentActivePage], endNum.lastNumberOfPage do
            local uuid = taskbarPrivate.listActiveProgramsOrder[i]
            term.setBackgroundColor(32)
            term.setCursorPos(cursorPos, taskbarPrivate.rootTermHeight)
            term.write(taskbarPrivate.listActivePrograms[uuid].name)
            term.setBackgroundColor(backupBackgroundColor)
            cursorPos = cursorPos + string.len(taskbarPrivate.listActivePrograms[uuid].name) + 1
        end
    end

    -- Next btn
    term.setBackgroundColor(512)
    term.setCursorPos(taskbarPrivate.rootTermWidth, taskbarPrivate.rootTermHeight)
    term.write(">")
    term.setBackgroundColor(backupBackgroundColor)
end

function taskbar.startProgram(programName, programPath, useKernelEvents)
    taskbarPrivate.kernelEventHandler.kernelMethods.AddProgram(
        programPath,
        useKernelEvents,
        taskbarPrivate.kernelEventHandler.kernelMethods.createWindow(
            taskbarPrivate.kernelEventHandler.kernelData.rootTerm,
            1,
            2,
            taskbarPrivate.rootTermWidth,
            taskbarPrivate.rootTermHeight - 2
        )
    )

    local programUuid = taskbarPrivate.kernelEventHandler.kernelMethods.getCurrentRunningProgramUuid()

    table.insert(taskbarPrivate.listActiveProgramsOrder, programUuid)
    taskbarPrivate.listActivePrograms[programUuid] = {
        name = programName,
        programUuid = programUuid
    }

    taskbarPrivate.amountOfActivePrograms = #taskbarPrivate.listActiveProgramsOrder
    taskbarPrivate.calculatePageNumbers()
    taskbarPrivate.currentActivePage = #taskbarPrivate.taskbarPages

    taskbar.drawTaskbar()
end

function taskbarPrivate.getProgramNumByUuid(programOrderTable, programUuid)
    local returnValue = 0

    if #programOrderTable > 0 then
        for index = 1, #programOrderTable do
            if programOrderTable[index] == programUuid then
                returnValue = index
                break
            end
        end
    end

    return returnValue
end

function taskbar.closeProgram(programUuid)
    taskbarPrivate.kernelEventHandler.kernelMethods.closeTaskOrProgram(
        programUuid
    )

    local listActiveProgramsOrderNumber = taskbarPrivate.getProgramNumByUuid(taskbarPrivate.listActiveProgramsOrder, programUuid)

    if listActiveProgramsOrderNumber ~= 0 then
        table.remove(taskbarPrivate.listActiveProgramsOrder, listActiveProgramsOrderNumber)
        taskbarPrivate.listActivePrograms[programUuid] = nil

        taskbarPrivate.taskbarPages = {}
        taskbarPrivate.calculatePageNumbers()
        if taskbarPrivate.currentActivePage > #taskbarPrivate.taskbarPages then
            taskbarPrivate.currentActivePage = taskbarPrivate.currentActivePage - 1
        end

        taskbarPrivate.amountOfActivePrograms = taskbarPrivate.amountOfActivePrograms - 1
    end

    taskbar.drawTaskbar()
end

function taskbarPrivate.clickNextBtn()
    if taskbarPrivate.X >= taskbarPrivate.rootTermWidth and taskbarPrivate.Y == taskbarPrivate.rootTermHeight then
        if taskbarPrivate.taskbarPages[taskbarPrivate.currentActivePage + 1] ~= nil then
            taskbarPrivate.currentActivePage = taskbarPrivate.currentActivePage + 1
            taskbar.drawTaskbar()
        end
    end
end

function taskbarPrivate.clickBackBtn()
    if taskbarPrivate.X == 10 and taskbarPrivate.Y == taskbarPrivate.rootTermHeight then
        if taskbarPrivate.taskbarPages[taskbarPrivate.currentActivePage - 1] ~= nil then
            taskbarPrivate.currentActivePage = taskbarPrivate.currentActivePage - 1
            taskbar.drawTaskbar()
        end
    end
end

function taskbarPrivate.clickProgramIcon()
    if taskbarPrivate.X >= 11 and taskbarPrivate.X < taskbarPrivate.rootTermWidth and taskbarPrivate.Y == taskbarPrivate.rootTermHeight then
        if taskbarPrivate.amountOfActivePrograms > 0 then
            local startProgramNum   = taskbarPrivate.taskbarPages[taskbarPrivate.currentActivePage]
            local endProgramNum     = taskbarPrivate.taskBarGetEndNumberDependingOnTheWidthOfTheTaskBar(startProgramNum).lastNumberOfPage
            local startPos          = 11
            
            for index = startProgramNum, endProgramNum do
                local uuid = taskbarPrivate.listActiveProgramsOrder[index]
                local program = taskbarPrivate.listActivePrograms[uuid]
                local programNameLength = string.len(program.name) - 1
    
                if taskbarPrivate.X >= startPos and taskbarPrivate.X <= (startPos + programNameLength) then
                    taskbarPrivate.kernelEventHandler.kernelMethods.setCurrentRunningProgram(uuid)
                end

                startPos = startPos + programNameLength + 2
            end 
        end 
    end
end

function taskbar.selectProgramUuid()
    if taskbarPrivate.event == "mouse_click" then
        if taskbarPrivate.X >= 10 and taskbarPrivate.Y == taskbarPrivate.rootTermHeight then
            taskbarPrivate.clickNextBtn()
            taskbarPrivate.clickBackBtn()
            taskbarPrivate.clickProgramIcon()
            taskbar.drawTaskbar()
        end
    end
end

function taskbar.setProperties(event, button, X, Y, rootTermWidth, rootTermHeight, kernelEventHandler)
    taskbarPrivate.kernelEventHandler = kernelEventHandler
    taskbarPrivate.rootTermWidth = rootTermWidth
    taskbarPrivate.rootTermHeight = rootTermHeight
    taskbarPrivate.event = event
    taskbarPrivate.button = button
    taskbarPrivate.X = X
    taskbarPrivate.Y = Y
end

return taskbar