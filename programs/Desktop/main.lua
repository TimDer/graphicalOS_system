local desktopApplication = {}

desktopApplication.kernelEventHandler = require "/graphicalOS_system/apis/kernelEventHandler"
desktopApplication.draw = require "/graphicalOS_system/programs/Desktop/draw"
desktopApplication.taskbar = require "/graphicalOS_system/programs/Desktop/taskbar"
desktopApplication.startmenu = require "/graphicalOS_system/programs/Desktop/startmenu"

local rootTermWidth, rootTermHeight = term.getSize()

function desktopApplication.exitToDesktop()
    desktopApplication.draw.drawDesktop()
    desktopApplication.taskbar.drawTaskbar()
end

function desktopApplication.closeProgram(event, button, X, Y)
    if event == "mouse_click" or event == "terminate" then
        if (Y == 1 and X == rootTermWidth) or event == "terminate" then
            desktopApplication.taskbar.closeProgram(
                desktopApplication.kernelEventHandler.kernelMethods.getCurrentRunningProgramUuid()
            )
            desktopApplication.exitToDesktop()
        end
    end
end

function desktopApplication.minimiseProgram(event, button, X, Y)
    if event == "mouse_click" or event == "terminate" then
        if (Y == 1 and X == (rootTermWidth - 1)) or event == "terminate" then
            desktopApplication.kernelEventHandler.kernelMethods.setCurrentRunningProgram("")
            desktopApplication.exitToDesktop()
        end
    end
end

function desktopApplication.redrawEvent()
    local currentRunningProgramUuid = desktopApplication.kernelEventHandler.kernelMethods.getCurrentRunningProgramUuid()
    desktopApplication.taskbar.updateTaskBarProgramListIfTheKernelHasMore()

    if currentRunningProgramUuid == "" then
        desktopApplication.exitToDesktop()
    elseif currentRunningProgramUuid ~= "" then
        desktopApplication.draw.drawWindow(desktopApplication.taskbar.getNameByUuid(currentRunningProgramUuid), rootTermHeight - 1, rootTermWidth)
    end
end

function desktopApplication.termResizeEvent(craftOsEvents)
    local width, height = term.getSize()
    rootTermWidth = width
    rootTermHeight = height
    desktopApplication.draw.setWindowHeightAndWidthCurrentTerm(rootTermWidth, rootTermHeight)
    desktopApplication.draw.drawDesktop()
    desktopApplication.taskbar.setProperties(craftOsEvents[1], craftOsEvents[2], craftOsEvents[3], craftOsEvents[4], rootTermWidth, rootTermHeight, desktopApplication.kernelEventHandler)
    desktopApplication.taskbar.drawTaskbar()
    desktopApplication.redrawEvent()
end

function desktopApplication.startStartupPrograms()
    desktopApplication.kernelEventHandler.listOfStartupPrograms.startPrograms(1, 2, rootTermWidth, rootTermHeight - 2)
end

function desktopApplication.terminateEvent(event)
    desktopApplication.closeProgram(event[1], "", 0, 0)
end

function desktopApplication.runDesktop()
    desktopApplication.draw.setWindowHeightAndWidthCurrentTerm(rootTermWidth, rootTermHeight)
    desktopApplication.draw.drawDesktop()
    desktopApplication.taskbar.setProperties("", "", 0, 0, rootTermWidth, rootTermHeight, desktopApplication.kernelEventHandler)
    desktopApplication.taskbar.drawTaskbar()
    desktopApplication.kernelEventHandler.setKernelTermResizeEvent(desktopApplication.termResizeEvent)
    desktopApplication.kernelEventHandler.setKernelRedrawEvent(desktopApplication.redrawEvent)
    desktopApplication.kernelEventHandler.setKernelTerminateEvent(desktopApplication.terminateEvent)
    desktopApplication.kernelEventHandler.setProgramStarterAtStartup(desktopApplication.startStartupPrograms)
    
    while true do
        local event, button, X, Y = desktopApplication.kernelEventHandler.pullKernelEvent()

        desktopApplication.taskbar.setProperties(event, button, X, Y, rootTermWidth, rootTermHeight, desktopApplication.kernelEventHandler)
        desktopApplication.startmenu.setProperties(event, button, X, Y, rootTermWidth, rootTermHeight, desktopApplication.kernelEventHandler, desktopApplication.taskbar, desktopApplication.exitToDesktop)

        desktopApplication.startmenu.startBtnClick()
        desktopApplication.closeProgram(event, button, X, Y)
        desktopApplication.minimiseProgram(event, button, X, Y)
        desktopApplication.taskbar.selectProgramUuid()
        
    end
end

desktopApplication.runDesktop()