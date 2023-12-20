local args = {...}
local completionFunctions = require "/graphicalOS_system/programs/shell/completionFunctions"

shell.setDir("/")

local shellMode = "gui"
if args[1] == "nogui" then
    shellMode = args[1]
    term.clear()
    term.setTextColour(16)
    term.setCursorPos(1, 1)
    print("Graphical OS Shell")
end

local addCommandPath = ":/graphicalOS_system/programs/shell/commands"
if string.gmatch(shell.path(), addCommandPath)() == nil then
    shell.setPath(shell.path() .. addCommandPath) 
end

completionFunctions.setFunctions()
local whileShell = true

shellCommandHistory = {}
while whileShell do
    term.setBackgroundColor( 32768 )
    term.setTextColour( 16 )
    write( shell.dir() .. "> " )
    term.setTextColour( 1 )
    
    local command = read( nil, shellCommandHistory, shell.complete )
    table.insert( shellCommandHistory, command )
    if command == "exit" and shellMode == "gui" then
        print("In order to exit the shell, close the window.")
    elseif command == "exit" and shellMode == "nogui" then
        shell.run("shutdown")
    else
        shell.run( command )
    end
end