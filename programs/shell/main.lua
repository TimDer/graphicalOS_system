local shellCommand = {}
shellCommand.gframework = require "/graphicalOS_system/apis/gframework"
shellCommand.completionFunctions = require "/graphicalOS_system/programs/shell/completionFunctions"
shellCommand.args = {...}
shellCommand.shellCommandHistory = {}
shellCommand.itemGroups = {
    terminal = shellCommand.gframework.createItemGroup()
}

shellCommand.action = {
    basics = function ()
        shell.setDir("/")

        local shellMode = "gui"
        if shellCommand.args[1] == "nogui" then
            shellMode = shellCommand.args[1]
            term.clear()
            term.setTextColour(16)
            term.setCursorPos(1, 1)
            print("Graphical OS Shell")
        end

        local addCommandPath = ":/graphicalOS_system/programs/shell/commands"
        if string.gmatch(shell.path(), addCommandPath)() == nil then
            shell.setPath(shell.path() .. addCommandPath) 
        end

        shellCommand.completionFunctions.setFunctions()

        shellCommand.gframework.term.setBackgroundColor(32768)
    end,

    insertIntoHistory = function (historyString)
        local containsCharactersOtherThanSpaces = false

        if #historyString >= 1 then
            for charIndex = 1, #historyString, 1 do
                if string.sub(historyString, charIndex, charIndex) ~= " " then
                    containsCharactersOtherThanSpaces = true
                    break
                end
            end
        end

        if containsCharactersOtherThanSpaces then
            table.insert( shellCommand.shellCommandHistory, historyString )
        end
    end,

    createTerminal = function ()
        local terminal = {}

        terminal.action = shellCommand.gframework.action.createCoroutineAction(function (events)
            term.setBackgroundColor( 32768 )
            term.setTextColour( 16 )
            write( shell.dir() .. "> " )
            term.setTextColour( 1 )
            
            local command = read( nil, shellCommand.shellCommandHistory, shell.complete )
            shellCommand.action.insertIntoHistory(command)
            
            if command == "exit" and shellMode == "gui" then
                print("In order to exit the shell, close the window.")
            elseif command == "exit" and shellMode == "nogui" then
                shell.run("shutdown")
            else
                shell.run( command )
            end
        end)

        return terminal
    end,

    startTerminal = function ()
        local terminal = shellCommand.action.createTerminal()
        terminal.action.func({})
        shellCommand.itemGroups.terminal.createCustomItem(terminal)
    end,

    run = function ()
        shellCommand.action.basics()
        shellCommand.action.startTerminal()

        shellCommand.gframework.collectItemGroups(
            shellCommand.itemGroups.terminal
        )
        shellCommand.gframework.run()
    end
}

shellCommand.action.run()

