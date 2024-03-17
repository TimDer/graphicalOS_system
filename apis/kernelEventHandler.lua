local kernelEventHandler = {}
local kernelEventHandlerPrivate = {}

kernelEventHandlerPrivate.listOfEvents = require "/graphicalOS_system/apis/ListOfEvents"
kernelEventHandlerPrivate.kernelRedrawEvent = function (craftOsEvents) end
kernelEventHandlerPrivate.kernelTerminateEvent = function (craftOsEvents) end

kernelEventHandlerPrivate.craftOsEvents = {}

kernelEventHandler.kernelMethods = {}
kernelEventHandler.kernelMethods.AddTask = function (name, taskPath, useKernelEvents) return end
kernelEventHandler.kernelMethods.AddProgram = function (name, programPath, useKernelEvents, processWindow) return end
kernelEventHandler.kernelMethods.createWindow = function (parentTerm, x, y, width, height) end
kernelEventHandler.kernelMethods.getListOfRunningTasksAndPrograms = function () end
kernelEventHandler.kernelMethods.closeTaskOrProgram = function (programOrTaskUuid) end
kernelEventHandler.kernelMethods.getCurrentRunningProgramUuid = function () return "" end
kernelEventHandler.kernelMethods.setCurrentRunningProgram = function (uuid) end

kernelEventHandler.kernelData = {}
kernelEventHandler.kernelData.rootTerm = term.current()
kernelEventHandler.kernelData.uuid = ""
kernelEventHandler.kernelData.isProgramCurrentlyActive = false

kernelEventHandler.kernelData.listOfProgramsAndTasks = {}
kernelEventHandler.kernelData.listOfProgramsAndTasks.tasks = {}
kernelEventHandler.kernelData.listOfProgramsAndTasks.programs = {}

function kernelEventHandler.setKernelTerminateEvent(func)
    if type(func) == "function" then
        kernelEventHandlerPrivate.kernelTerminateEvent = func
    end
end

function kernelEventHandler.setKernelRedrawEvent(func)
    if type(func) == "function" then
        kernelEventHandlerPrivate.kernelRedrawEvent = func
    end
end

function kernelEventHandler.returnKernelEvent(...)
    local newCraftOsEvents = {...}
    local returnCraftOsEvents = {}

    if #newCraftOsEvents > 0 then
        returnCraftOsEvents = newCraftOsEvents
    else
        returnCraftOsEvents = kernelEventHandlerPrivate.craftOsEvents
    end

    return returnCraftOsEvents,
           kernelEventHandler.kernelMethods.AddTask,
           kernelEventHandler.kernelMethods.AddProgram,
           kernelEventHandler.kernelMethods.createWindow,
           kernelEventHandler.kernelData.rootTerm,
           kernelEventHandler.kernelMethods.getListOfRunningTasksAndPrograms,
           kernelEventHandler.kernelData.uuid,
           kernelEventHandler.kernelData.isProgramCurrentlyActive,
           kernelEventHandler.kernelMethods.closeTaskOrProgram,
           kernelEventHandler.kernelMethods.getCurrentRunningProgramUuid,
           kernelEventHandler.kernelMethods.setCurrentRunningProgram,
           kernelEventHandler.kernelData.listOfProgramsAndTasks
end

function kernelEventHandler.pullKernelEvent()
    local newCraftOsEvents = {}

    while true do
        local craftOsEvents,
              AddTask,
              AddProgram,
              createWindow,
              rootTerm,
              getListOfRunningTasksAndPrograms,
              uuid,
              isProgramCurrentlyActive,
              closeTaskOrProgram,
              getCurrentRunningProgramUuid,
              setCurrentRunningProgram,
              listOfProgramsAndTasks = coroutine.yield()

        kernelEventHandlerPrivate.craftOsEvents = craftOsEvents
        kernelEventHandler.kernelMethods.AddTask = AddTask
        kernelEventHandler.kernelMethods.AddProgram = AddProgram
        kernelEventHandler.kernelMethods.createWindow = createWindow
        kernelEventHandler.kernelMethods.getListOfRunningTasksAndPrograms = getListOfRunningTasksAndPrograms
        kernelEventHandler.kernelMethods.closeTaskOrProgram = closeTaskOrProgram
        kernelEventHandler.kernelMethods.getCurrentRunningProgramUuid = getCurrentRunningProgramUuid
        kernelEventHandler.kernelMethods.setCurrentRunningProgram = setCurrentRunningProgram

        kernelEventHandler.kernelData.rootTerm = rootTerm
        kernelEventHandler.kernelData.uuid = uuid
        kernelEventHandler.kernelData.isProgramCurrentlyActive = isProgramCurrentlyActive
        kernelEventHandler.kernelData.listOfProgramsAndTasks = listOfProgramsAndTasks

        if craftOsEvents[1] == kernelEventHandlerPrivate.listOfEvents.createGraphicalOsEventString("redraw_all") then
            kernelEventHandlerPrivate.kernelRedrawEvent(craftOsEvents)
        elseif craftOsEvents[1] == "terminate" then
            kernelEventHandlerPrivate.kernelTerminateEvent(craftOsEvents)
        else
            newCraftOsEvents = table.move(craftOsEvents, 1, #craftOsEvents, 1, newCraftOsEvents)
            break
        end
    end

    return table.unpack(newCraftOsEvents)
end

return kernelEventHandler