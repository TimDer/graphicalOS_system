shell.setDir("/")

local addCommandPath = ":/graphicalOS_system/programs/shell/commands"
if string.gmatch(shell.path(), addCommandPath)() == nil then
    shell.setPath(shell.path() .. addCommandPath) 
end

local whileShell = true

shellCommandHistory = {}
while whileShell do
    term.setBackgroundColor( 32768 )
    term.setTextColour( 16 )
    write( shell.dir() .. "> " )
    term.setTextColour( 1 )
    
    local command = read( nil, shellCommandHistory, shell.complete )
    table.insert( shellCommandHistory, command )
    if command == "exit" then
        print("In order to exit the shell, close the window.")
    else
        shell.run( command )
    end
end