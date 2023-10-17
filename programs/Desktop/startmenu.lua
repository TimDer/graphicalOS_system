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



function startmenu.setProperties(event, button, X, Y, rootTermWidth, rootTermHeight, kernelEventHandler, taskbar, exitToDesktop)
    startmenuPrivate.Event = event
    startmenuPrivate.button = button
    startmenuPrivate.X = X
    startmenuPrivate.Y = Y
    startmenuPrivate.rootTermWidth = rootTermWidth
    startmenuPrivate.rootTermHeight = rootTermHeight
    startmenuPrivate.kernelEventHandler = kernelEventHandler
    startmenuPrivate.taskbar = taskbar
    startmenuPrivate.exitToDesktop = exitToDesktop
end

return startmenu