local kernel = {}
local kernelPrivate = {}

kernelPrivate.listOfEvents = require "/graphicalOS_system/apis/ListOfEvents"
kernelPrivate.UuidGenerator = require "/graphicalOS_system/apis/uuid"

--[[
    {
        uuid = {
            uuid: string
            taskType: "programs" | "tasks"
            isProgramCurrentlyActive: boolean -- only applies if taskType is a program
            useKernelEvents: boolean
            processWindow: {
                window: window API
                startX: number
                startY: number
            }
            coroutine: coroutine
        }
    }
]]
kernelPrivate.coroutines = {}
kernelPrivate.coroutines.programs = {}
kernelPrivate.coroutines.tasks = {}

--[[
    {
        uuid = {
            name: string
            pathToProgramOrTask: string
            useKernelEvents: boolean
        }
    }
]]
kernelPrivate.listOfProgramsAndTasks = {}
kernelPrivate.listOfProgramsAndTasks.tasks = {}
kernelPrivate.listOfProgramsAndTasks.programs = {}

kernelPrivate.rootTerm = term.current()

kernelPrivate.areThereAnyTasks = false
kernelPrivate.areThereAnyPrograms = false

kernelPrivate.programOrTaskRedrawEvent = false

-------------------------------------------------------------------------------------------------
-- Event functions

function kernelPrivate.setCurrentRunningProgram(uuid)
    local doesUuidExist = false

    if kernelPrivate.coroutines.programs[uuid] ~= nil then
        doesUuidExist = true
        kernelPrivate.programOrTaskRedrawEvent = true

        for key, value in pairs(kernelPrivate.coroutines.programs) do
            kernelPrivate.coroutines.programs[value.uuid].isProgramCurrentlyActive = false
        end

        kernelPrivate.coroutines.programs[uuid].isProgramCurrentlyActive = true
    end

    return doesUuidExist
end

function kernelPrivate.closeTaskOrProgram(programOrTaskUuid)
    if kernelPrivate.coroutines.programs[programOrTaskUuid] ~= nil then
        kernelPrivate.coroutines.programs[programOrTaskUuid] = nil
        kernelPrivate.programOrTaskRedrawEvent = true
        return true
    elseif kernelPrivate.coroutines.tasks[programOrTaskUuid] ~= nil then
        kernelPrivate.coroutines.tasks[programOrTaskUuid] = nil
        kernelPrivate.programOrTaskRedrawEvent = true
        return true
    end

    return false
end

function kernelPrivate.getListOfRunningTasksAndPrograms()
    local listOfCoroutines = {}

    listOfCoroutines.tasks = {}
    listOfCoroutines.programs = {}

    for coroutinesKey, coroutinesValue in pairs(kernelPrivate.coroutines) do
        for key, value in pairs(kernelPrivate.coroutines[coroutinesKey]) do
            listOfCoroutines[coroutinesKey][value.uuid] = {}
            listOfCoroutines[coroutinesKey][value.uuid].uuid = value.uuid
            listOfCoroutines[coroutinesKey][value.uuid].isProgramCurrentlyActive = value.isProgramCurrentlyActive
        end
    end

    return listOfCoroutines
end

function kernelPrivate.getCurrentRunningProgramUuid()
    local uuidString = "";

    for key, value in pairs(kernelPrivate.coroutines.programs) do
        if value.isProgramCurrentlyActive then
            uuidString = value.uuid
            break
        end
    end

    return uuidString
end

function kernelPrivate.eventRedrawKernelWindow(programOrTaskUuid)
    if kernelPrivate.coroutines.programs[programOrTaskUuid] ~= nil then
        kernelPrivate.coroutines.programs[programOrTaskUuid].processWindow.window.redraw()
        return true
    elseif kernelPrivate.coroutines.tasks[programOrTaskUuid] ~= nil then
        kernelPrivate.coroutines.tasks[programOrTaskUuid].processWindow.window.redraw()
        return true
    end

    return false
end

function kernelPrivate.detectWhichEventtypeToUse(programOrTaskValue, craftOsEvents)
    if programOrTaskValue.useKernelEvents == true then
        return craftOsEvents,
               kernel.AddTask,
               kernel.AddProgram,
               kernel.createWindow,
               kernelPrivate.rootTerm,
               kernelPrivate.getListOfRunningTasksAndPrograms,
               kernelPrivate.eventRedrawKernelWindow,
               programOrTaskValue.uuid,
               programOrTaskValue.isProgramCurrentlyActive,
               kernelPrivate.closeTaskOrProgram,
               kernelPrivate.getCurrentRunningProgramUuid,
               kernelPrivate.setCurrentRunningProgram,
               kernelPrivate.listOfProgramsAndTasks
    end

    return table.unpack(craftOsEvents)
end

-------------------------------------------------------------------------------------------------
-- Programs and tasks

function kernelPrivate.redirectTermToTheDesignatedWindow(processWindow)
    term.redirect(processWindow.window)
    processWindow.window.redraw()
end

function kernelPrivate.fixXandYPositioning(events, processWindow)
    if events[1] == "mouse_click" or events[1] == "mouse_drag" or events[1] == "mouse_scroll" or events[1] == "mouse_up" then
        events[3] = events[3] - (processWindow.startX - 1)
        events[4] = events[4] - (processWindow.startY - 1)
    end

    return events
end

function kernelPrivate.executeTask(value, events)
    kernelPrivate.redirectTermToTheDesignatedWindow(value.processWindow)
    local runCoroutine = true

    if value.useKernelEvents == false and events[1] == kernelPrivate.listOfEvents.createGraphicalOsEventString("redraw_all") then
        runCoroutine = false
    end

    if runCoroutine == true then
        coroutine.resume(value.coroutine, kernelPrivate.detectWhichEventtypeToUse(value, events))
    end
    
    term.redirect(kernelPrivate.rootTerm)
end

function kernelPrivate.runCoroutinesTasks(events)
    for key, value in pairs(kernelPrivate.coroutines.tasks) do
        kernelPrivate.areThereAnyTasks = true

        kernelPrivate.executeTask(value, events)

        if coroutine.status(value.coroutine) == "dead" then
            kernelPrivate.programOrTaskRedrawEvent = true
            kernelPrivate.coroutines.tasks[value.uuid] = nil
        end
    end
end

function kernelPrivate.executeProgram(value, events, isRunningInActiveMode)
    kernelPrivate.redirectTermToTheDesignatedWindow(value.processWindow)
    local runCoroutine = true
    local xSize, ySize = value.processWindow.window.getSize()
    if isRunningInActiveMode then
        value.processWindow.window.reposition(value.processWindow.startX, value.processWindow.startY, xSize, ySize)
    else
        value.processWindow.window.reposition(value.processWindow.startX, 99999999, xSize, ySize)
    end

    if value.useKernelEvents == false and events[1] == kernelPrivate.listOfEvents.createGraphicalOsEventString("redraw_all") then
        runCoroutine = false
    end

    if runCoroutine then
        coroutine.resume(value.coroutine, kernelPrivate.detectWhichEventtypeToUse(value, kernelPrivate.fixXandYPositioning(events, value.processWindow))) 
    end
    term.redirect(kernelPrivate.rootTerm)
end

function kernelPrivate.blockCoroutineByEvent(events)
    local runProgram = true

    if kernelPrivate.listOfEvents.isEventFromCraftOs(events[1]) then
        if events[1] == "mouse_click" or events[1] == "mouse_drag" or events[1] == "mouse_scroll" or events[1] == "mouse_up" or events[1] == "key_up" or events[1] == "key" or events[1] == "char" or events[1] == "terminate" then
            runProgram = false
        end
    end

    return runProgram
end

function kernelPrivate.runCoroutinesPrograms(events)
    local uuid = ""

    for key, value in pairs(kernelPrivate.coroutines.programs) do
        kernelPrivate.areThereAnyPrograms = true

        if value.isProgramCurrentlyActive and events[1] ~= "terminate" then
            uuid = value.uuid
        elseif kernelPrivate.blockCoroutineByEvent(events) and events[1] ~= "terminate" then
            kernelPrivate.executeProgram(value, events, value.isProgramCurrentlyActive)
        end

        if coroutine.status(value.coroutine) == "dead" then
            kernelPrivate.programOrTaskRedrawEvent = true
            kernelPrivate.coroutines.programs[value.uuid] = nil
        end
    end

    if uuid ~= "" then
        kernelPrivate.executeProgram(kernelPrivate.coroutines.programs[uuid], events, kernelPrivate.coroutines.programs[uuid].isProgramCurrentlyActive)

        if coroutine.status(kernelPrivate.coroutines.programs[uuid].coroutine) == "dead" then
            kernelPrivate.programOrTaskRedrawEvent = true
            kernelPrivate.coroutines.programs[uuid] = nil
        end
    end
end

-------------------------------------------------------------------------------------------------
-- Coroutines

function kernelPrivate.runCoroutines(events)
    local collectCoroutineData = {}

    kernelPrivate.runCoroutinesTasks(events)
    kernelPrivate.runCoroutinesPrograms(events)

    return collectCoroutineData
end

function kernelPrivate.checkIfAnyTasksOrProgramsAreRunning()
    local thereAreNoTasksOrProgramsRunning = true

    if kernelPrivate.areThereAnyPrograms == true or kernelPrivate.areThereAnyTasks == true then
        kernelPrivate.areThereAnyTasks = false
        kernelPrivate.areThereAnyPrograms = false
        thereAreNoTasksOrProgramsRunning = false
    end

    return thereAreNoTasksOrProgramsRunning
end

function kernelPrivate.checkIfThereNeedsToBeARedrawEvent()
    if kernelPrivate.programOrTaskRedrawEvent then
        kernelPrivate.programOrTaskRedrawEvent = false
        os.queueEvent(kernelPrivate.listOfEvents.createGraphicalOsEventString("redraw_all"))
    end
end

function kernelPrivate.coroutineHelper()
    os.queueEvent("startKernel")
    local events = table.pack(os.pullEventRaw())
    kernelPrivate.programOrTaskRedrawEvent = false

    while true do
        kernelPrivate.runCoroutines(events)

        -- Terminate if there is nothing to run
        if kernelPrivate.checkIfAnyTasksOrProgramsAreRunning() then break end

        kernelPrivate.checkIfThereNeedsToBeARedrawEvent()
        
        events = table.pack(os.pullEventRaw())
    end
end

function kernelPrivate.createCoroutine(programTaskType, func, programIsProgramCurrentlyActive, useKernelEvents, processWindow)
    local uuid = kernelPrivate.UuidGenerator.CreateUuid(9)
    kernelPrivate.programOrTaskRedrawEvent = true

    kernelPrivate.coroutines[programTaskType][uuid] = {
        uuid = uuid,
        taskType = programTaskType,
        isProgramCurrentlyActive = programIsProgramCurrentlyActive,
        useKernelEvents = useKernelEvents,
        processWindow = processWindow,
        coroutine = coroutine.create(func)
    }
end

-------------------------------------------------------------------------------------------------
-- List of programs
function kernel.addTaskToList(taskName, taskPath, useKernelEvents)
    kernelPrivate.listOfProgramsAndTasks.tasks[kernelPrivate.UuidGenerator.CreateUuid(10)] = {
        name = taskName,
        pathToProgramOrTask = taskPath,
        useKernelEvents = useKernelEvents
    }
end

function kernel.addProgramToList(programName, programPath, useKernelEvents)
    kernelPrivate.listOfProgramsAndTasks.programs[kernelPrivate.UuidGenerator.CreateUuid(10)] = {
        name = programName,
        pathToProgramOrTask = programPath,
        useKernelEvents = useKernelEvents
    }
end

-------------------------------------------------------------------------------------------------
-- Public methods

function kernel.createWindow(parentTerm, x, y, width, height)
    local returnWindow = {}

    returnWindow.window = window.create(parentTerm, x, y, width, height)
    returnWindow.startX = x
    returnWindow.startY = y

    return returnWindow
end

function kernel.AddTask(taskPath, useKernelEvents)
    if type(taskPath) ~= "string" then
        error("You can only add strings to this method. Supplied type: " .. type(taskPath), 2)
    end

    local windowW, windowH = kernelPrivate.rootTerm.getSize()
    local taskWindow = kernel.createWindow(kernelPrivate.rootTerm, 1, 1, windowW, windowH)

    kernelPrivate.createCoroutine("tasks", function ()
        shell.run(taskPath)
    end, true, useKernelEvents, taskWindow)
end

function kernel.AddProgram(programPath, useKernelEvents, processWindow)
    if type(programPath) ~= "string" then
        error("You can only add strings to this method supplied type: " .. type(programPath), 2)
    end

    if next(kernelPrivate.coroutines.programs) ~= nil then
        for key, value in pairs(kernelPrivate.coroutines.programs) do
            value.isProgramCurrentlyActive = false
        end 
    end

    kernelPrivate.createCoroutine("programs", function ()
        shell.run(programPath)
    end, true, useKernelEvents, processWindow)
end

function kernel.runKernel()
    kernelPrivate.coroutineHelper()
end

return kernel