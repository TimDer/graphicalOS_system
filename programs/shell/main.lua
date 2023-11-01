shell.setDir("/")

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
    elseif command == "clear" then
        shell.run(command)
    else
        shell.run( command )
    end
end