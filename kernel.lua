local kernel = {}
local kernelPrivate = {}

kernelPrivate.listOfEvents = require "/graphicalOS_system/apis/ListOfEvents"
kernelPrivate.UuidGenerator = require "/graphicalOS_system/apis/uuid"
kernelPrivate.jsonFileLoader = require "/graphicalOS_system/apis/json"

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

kernelPrivate.listOfStartupProgramsLaunchPrograms = true
kernelPrivate.listOfStartupPrograms = {}
--[[
    {
        number = {
            name: string
            programPath: string
            useKernelEvents: boolean
        }
    }
]]
kernelPrivate.listOfStartupPrograms.list = {}
function kernelPrivate.listOfStartupPrograms.startPrograms(x, y, width, height)
    if kernelPrivate.listOfStartupProgramsLaunchPrograms == true then
        for key, value in ipairs(kernelPrivate.listOfStartupPrograms.list) do
            kernel.AddProgram(value.name, value.programPath, value.useKernelEvents, kernel.createWindow(
                kernelPrivate.rootTerm,
                x,
                y,
                width,
                height
            ))
        end

        kernelPrivate.listOfStartupProgramsLaunchPrograms = false
    end
end

kernelPrivate.rootTerm = term.current()

kernelPrivate.areThereAnyTasks = false
kernelPrivate.areThereAnyPrograms = false

kernelPrivate.programOrTaskRedrawEvent = false

kernelPrivate.termResizeEventPreviousValues = {
    rootTermHeight = 0,
    rootTermWidth = 0
}

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
    elseif uuid == "" then
        for key, value in pairs(kernelPrivate.coroutines.programs) do
            if value.isProgramCurrentlyActive then
                kernelPrivate.coroutines.programs[key].isProgramCurrentlyActive = false
            end
        end
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
            listOfCoroutines[coroutinesKey][value.uuid].name = value.name
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

function kernelPrivate.detectWhichEventtypeToUse(programOrTaskValue, craftOsEvents)
    if programOrTaskValue.useKernelEvents == true then
        return craftOsEvents,
               kernel.AddTask,
               kernel.AddProgram,
               kernel.createWindow,
               kernelPrivate.rootTerm,
               kernelPrivate.getListOfRunningTasksAndPrograms,
               programOrTaskValue.uuid,
               programOrTaskValue.isProgramCurrentlyActive,
               kernelPrivate.closeTaskOrProgram,
               kernelPrivate.getCurrentRunningProgramUuid,
               kernelPrivate.setCurrentRunningProgram,
               kernelPrivate.listOfProgramsAndTasks,
               kernelPrivate.listOfStartupPrograms
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
    local rootWidth, rootHeight = kernelPrivate.rootTerm.getSize()
    kernelPrivate.redirectTermToTheDesignatedWindow(value.processWindow)
    local runCoroutine = true
    local taskWidth, taskHeight = value.processWindow.window.getSize()

    if taskWidth ~= rootWidth or taskHeight ~= rootHeight then
        value.processWindow.window.reposition(value.processWindow.startX, value.processWindow.startY, rootWidth, rootHeight)
    end

    if  value.useKernelEvents == false and
        (
            events[1] == kernelPrivate.listOfEvents.createGraphicalOsEventString("redraw_all") or
            events[1] == kernelPrivate.listOfEvents.createGraphicalOsEventString("start_startup_programs")
        ) then
        runCoroutine = false
    end

    if value.isFirstRun == true then
        value.isFirstRun = false
        kernelPrivate.programOrTaskRedrawEvent = true
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

function kernelPrivate.blockXandYPosition(events, processWindow)
    local returnValue = true
    local xSize, ySize = processWindow.window.getSize()

    if events[1] == "mouse_click" or events[1] == "mouse_drag" or events[1] == "mouse_scroll" or events[1] == "mouse_up" then
        if (events[3] >= processWindow.startX and events[4] >= processWindow.startY and events[3] <= xSize + (processWindow.startX - 1) and events[4] <= ySize + (processWindow.startY - 1)) == false then
            returnValue = false
        end
    end

    return returnValue
end

function kernelPrivate.resizeProgramWhenResizeEventIsCalledOrWhenProgramIsSetToInActive(isRunningInActiveMode, events, rootCurrentWidth, rootCurrentHeight, xWindowSize, yWindowSize, value)
    if events[1] == "term_resize" then
        -- Calculate height
        if rootCurrentHeight ~= kernelPrivate.termResizeEventPreviousValues.rootTermHeight then
            local differentWindowSizeComparedToMainTerm = kernelPrivate.termResizeEventPreviousValues.rootTermHeight - yWindowSize
            yWindowSize = rootCurrentHeight - differentWindowSizeComparedToMainTerm
        end
        
        -- Calculate width
        if rootCurrentWidth ~= kernelPrivate.termResizeEventPreviousValues.rootTermWidth then
            local differentWindowSizeComparedToMainTerm = kernelPrivate.termResizeEventPreviousValues.rootTermWidth - xWindowSize
            xWindowSize = rootCurrentWidth - differentWindowSizeComparedToMainTerm
        end
    end

    if isRunningInActiveMode then
        value.processWindow.window.reposition(value.processWindow.startX, value.processWindow.startY, xWindowSize, yWindowSize)
    else
        value.processWindow.window.reposition(value.processWindow.startX, 99999999, xWindowSize, yWindowSize)
    end
end

function kernelPrivate.executeProgram(value, events, isRunningInActiveMode)
    local rootCurrentWidth, rootCurrentHeight = kernelPrivate.rootTerm.getSize()
    kernelPrivate.redirectTermToTheDesignatedWindow(value.processWindow)
    local runCoroutine = true
    local xWindowSize, yWindowSize = value.processWindow.window.getSize()

    kernelPrivate.resizeProgramWhenResizeEventIsCalledOrWhenProgramIsSetToInActive(isRunningInActiveMode, events, rootCurrentWidth, rootCurrentHeight, xWindowSize, yWindowSize, value)

    if value.useKernelEvents == false and
        (
            events[1] == kernelPrivate.listOfEvents.createGraphicalOsEventString("redraw_all") or
            events[1] == kernelPrivate.listOfEvents.createGraphicalOsEventString("start_startup_programs")
        ) then
        runCoroutine = false
    end

    if value.isFirstRun == true then
        value.isFirstRun = false
        kernelPrivate.programOrTaskRedrawEvent = true
    end

    if runCoroutine and kernelPrivate.blockXandYPosition(events, value.processWindow) then
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

function kernelPrivate.startTheStartupProgramsIfNotStartedAutomatically()
    if kernelPrivate.programOrTaskRedrawEvent == false and kernelPrivate.listOfStartupProgramsLaunchPrograms == true then
        os.queueEvent(kernelPrivate.listOfEvents.createGraphicalOsEventString("start_startup_programs"))
    end
end

function kernelPrivate.resetPreviousTermSizes(events)
    if events[1] == "term_resize" then
        local rootCurrentWidth, rootCurrentHeight = kernelPrivate.rootTerm.getSize()

        kernelPrivate.termResizeEventPreviousValues.rootTermHeight = rootCurrentHeight
        kernelPrivate.termResizeEventPreviousValues.rootTermWidth = rootCurrentWidth
    end
end

function kernelPrivate.coroutineHelper()
    os.queueEvent("startKernel")
    local events = table.pack(os.pullEventRaw())
    kernelPrivate.programOrTaskRedrawEvent = false

    while true do
        kernelPrivate.runCoroutines(events)

        kernelPrivate.resetPreviousTermSizes(events)

        -- Terminate if there is nothing to run
        if kernelPrivate.checkIfAnyTasksOrProgramsAreRunning() then break end

        kernelPrivate.startTheStartupProgramsIfNotStartedAutomatically()

        kernelPrivate.checkIfThereNeedsToBeARedrawEvent()
        
        events = table.pack(os.pullEventRaw())
    end
end

function kernelPrivate.createCoroutine(programTaskName, programTaskType, func, programIsProgramCurrentlyActive, useKernelEvents, processWindow)
    local uuid = kernelPrivate.UuidGenerator.CreateUuid(9)
    kernelPrivate.programOrTaskRedrawEvent = true

    kernelPrivate.coroutines[programTaskType][uuid] = {
        name = programTaskName,
        uuid = uuid,
        taskType = programTaskType,
        isProgramCurrentlyActive = programIsProgramCurrentlyActive,
        isFirstRun = true,
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

function kernel.AddTask(name, taskPath, useKernelEvents)
    if type(taskPath) ~= "string" then
        error("You can only add strings to this method. Supplied type: " .. type(taskPath), 2)
    end

    local windowW, windowH = kernelPrivate.rootTerm.getSize()
    local taskWindow = kernel.createWindow(kernelPrivate.rootTerm, 1, 1, windowW, windowH)

    kernelPrivate.createCoroutine(name, "tasks", function ()
        shell.run(taskPath)

        while true do
            local events = {coroutine.yield()}
        end
    end, true, useKernelEvents, taskWindow)
end

function kernel.AddProgram(name, programPath, useKernelEvents, processWindow)
    if type(programPath) ~= "string" then
        error("You can only add strings to this method supplied type: " .. type(programPath), 2)
    end

    if next(kernelPrivate.coroutines.programs) ~= nil then
        for key, value in pairs(kernelPrivate.coroutines.programs) do
            value.isProgramCurrentlyActive = false
        end 
    end

    kernelPrivate.createCoroutine(name, "programs", function ()
        shell.run(programPath)

        while true do
            local events = {coroutine.yield()}
        end
    end, true, useKernelEvents, processWindow)
end

function kernel.AddStartupProgram(name, programPath, useKernelEvents)
    if type(programPath) ~= "string" then
        error("You can only add strings to this method supplied type: " .. type(programPath), 2)
    end

    table.insert(kernelPrivate.listOfStartupPrograms.list, {
        name = name,
        programPath = programPath,
        useKernelEvents = useKernelEvents
    })
end

function kernel.loadProgramsAndTasksFromSettingsFile(autoStartupPrograms)
    local settingsData = kernelPrivate.jsonFileLoader.readFile("/graphicalOS_data/user_data/settings.bin")

    if settingsData.data ~= nil and settingsData.data.kernel ~= nil then
        if settingsData.data.kernel.startupPrograms ~= nil then
            for key, value in pairs(settingsData.data.kernel.startupPrograms) do
                if type(autoStartupPrograms) == "boolean" and autoStartupPrograms == true then
                    kernel.AddProgram(value.name, value.pathToProgram, value.useKernelEvents, kernel.createWindow(
                        kernelPrivate.rootTerm,
                        value.x,
                        value.y,
                        value.width,
                        value.height
                    ))
                elseif type(autoStartupPrograms) == "boolean" and autoStartupPrograms == false then
                    kernel.AddStartupProgram(value.name, value.pathToProgram, value.useKernelEvents)
                end
            end
        end

        if settingsData.data.kernel.startupTasks ~= nil then
            for key, value in pairs(settingsData.data.kernel.startupTasks) do
                kernel.AddTask(value.name, value.pathToProgram, value.useKernelEvents)
            end
        end

        if settingsData.data.kernel.listOfPrograms ~= nil then
            for key, value in pairs(settingsData.data.kernel.listOfPrograms) do
                kernel.addProgramToList(value.name, value.pathToProgram, value.useKernelEvents)
            end
        end

        if settingsData.data.kernel.listOfTasks ~= nil then
            for key, value in pairs(settingsData.data.kernel.listOfTasks) do
                kernel.addTaskToList(value.name, value.pathToProgram, value.useKernelEvents)
            end
        end
    end
end
 
function kernel.runKernel()
    local xWidth, yHeight = kernelPrivate.rootTerm.getSize()

    kernelPrivate.termResizeEventPreviousValues.rootTermWidth = xWidth
    kernelPrivate.termResizeEventPreviousValues.rootTermHeight = yHeight

    kernelPrivate.coroutineHelper()
end

return kernel