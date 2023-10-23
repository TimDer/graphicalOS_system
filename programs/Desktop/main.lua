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

function desktopApplication.startBtnClick(event, button, X, Y)
    if event == "mouse_click" then
        if Y == rootTermHeight and X >= 1 and X <= 9 then
            desktopApplication.taskbar.startProgram("Shell", "/graphicalOS_system/programs/testProgram/main.lua", false)
        end
    end
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

function desktopApplication.redrawEvent()
    local currentRunningProgramUuid = desktopApplication.kernelEventHandler.kernelMethods.getCurrentRunningProgramUuid()

    if currentRunningProgramUuid == "" then
        desktopApplication.exitToDesktop()
    elseif currentRunningProgramUuid ~= "" then
        desktopApplication.draw.drawWindow("Name", rootTermHeight - 1, rootTermWidth)
    end
end

function desktopApplication.terminateEvent(event)
    desktopApplication.closeProgram(event[1], "", 0, 0)
end

function desktopApplication.runDesktop()
    desktopApplication.draw.setWindowHeightAndWidthCurrentTerm(rootTermWidth, rootTermHeight)
    desktopApplication.draw.drawDesktop()
    desktopApplication.taskbar.setProperties("", "", 0, 0, rootTermWidth, rootTermHeight, desktopApplication.kernelEventHandler)
    desktopApplication.taskbar.drawTaskbar()
    desktopApplication.kernelEventHandler.setKernelRedrawEvent(desktopApplication.redrawEvent)
    desktopApplication.kernelEventHandler.setKernelTerminateEvent(desktopApplication.terminateEvent)
    
    while true do
        local event, button, X, Y = desktopApplication.kernelEventHandler.pullKernelEvent()

        desktopApplication.taskbar.setProperties(event, button, X, Y, rootTermWidth, rootTermHeight, desktopApplication.kernelEventHandler)
        desktopApplication.startmenu.setProperties(event, button, X, Y, rootTermWidth, rootTermHeight, desktopApplication.kernelEventHandler, desktopApplication.taskbar)

        desktopApplication.startBtnClick(event, button, X, Y)
        desktopApplication.closeProgram(event, button, X, Y)
        desktopApplication.taskbar.selectProgramUuid()
        
    end
end

desktopApplication.runDesktop()