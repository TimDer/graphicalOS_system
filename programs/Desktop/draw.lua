local desktopApplication = {}
local desktopApplicationPrivate = {}

desktopApplicationPrivate.rootTermHeight = 0
desktopApplicationPrivate.rootTermWidth = 0

function desktopApplication.drawWindow(windowName, height, width)
    -- Window text color
    term.setTextColor(1)

    -- Window bar
    term.setCursorPos(1,1)
    term.setBackgroundColor(8192)
    term.clearLine()

    -- Window name
    term.setCursorPos(1,1)
    term.write(windowName)

    -- Minimise btn
    term.setBackgroundColor(2048)
    term.setCursorPos(width - 1, 1)
    term.write("_")

    -- Close btn
    term.setBackgroundColor(16384)
    term.setCursorPos(width, 1)
    term.write("X")

    for posIterator = 2,height
    do
        term.setCursorPos(1,posIterator)
        term.setBackgroundColor(1)
        term.clearLine()
    end
end

function desktopApplication.drawMenuBar()
    local menuBar = window.create(term.current(), 1, desktopApplicationPrivate.rootTermHeight, desktopApplicationPrivate.rootTermWidth, 1)

    menuBar.setCursorPos(1,1)
    menuBar.setBackgroundColor(256)
    menuBar.setTextColor(1)
    menuBar.clearLine()
    menuBar.setCursorPos(1,1)
    menuBar.setBackgroundColor(8192)
    menuBar.write(" [START] ")
end

function desktopApplication.drawDesktopBackground()
    local desktopWindow = window.create(term.current(), 1, 1, desktopApplicationPrivate.rootTermWidth, desktopApplicationPrivate.rootTermHeight - 1)
    
    desktopWindow.setBackgroundColor(8)
    desktopWindow.clear()
end

function desktopApplication.drawDesktop()
    -- menu bar
    desktopApplication.drawMenuBar()
    -- desktop
    desktopApplication.drawDesktopBackground()
end

function desktopApplication.setWindowHeightAndWidthCurrentTerm(width, height)
    desktopApplicationPrivate.rootTermHeight  = height
    desktopApplicationPrivate.rootTermWidth   = width
end

return desktopApplication