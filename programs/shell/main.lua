local shellCommand = {}
shellCommand.gframework = require "/graphicalOS_system/apis/gframework"
shellCommand.completionFunctions = require "/graphicalOS_system/programs/shell/completionFunctions"
shellCommand.args = {...}
shellCommand.shellCommandHistory = {}
shellCommand.shellMode = "gui"
shellCommand.itemGroups = {
    terminal = shellCommand.gframework.createItemGroup()
}

shellCommand.action = {
    basics = function ()
        shell.setDir("/")

        if shellCommand.args[1] == "nogui" then
            shellCommand.shellMode = shellCommand.args[1]
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

    completeShell = function (shellCommandString)
        if #shellCommandString > 7 and string.sub(shellCommandString, 1, 7) == "kernel " then
            shellCommandString = string.sub(shellCommandString, 8, #shellCommandString)
        end

        return shell.complete(shellCommandString)
    end,

    runProgram = function (command, isKernelProgram)
        local programCoroutine = coroutine.create(function ()
            shell.run( command )
        end)
        local events = {}

        while true do
            if isKernelProgram then
                coroutine.resume(programCoroutine, shellCommand.gframework.kernelEventHandler.returnKernelEvent(table.unpack(events)))
            else
                coroutine.resume(programCoroutine, table.unpack(events))
            end
            
            if coroutine.status(programCoroutine) == "dead" then
                break
            end

            events = {os.pullEventRaw()}
        end
    end,

    createTerminal = function ()
        local terminal = {}

        terminal.action = shellCommand.gframework.action.createCoroutineAction(function (events)
            term.setBackgroundColor( 32768 )
            term.setTextColour( 16 )
            write( shell.dir() .. "> " )
            term.setTextColour( 1 )
            
            local command = read( nil, shellCommand.shellCommandHistory, shellCommand.action.completeShell )
            shellCommand.action.insertIntoHistory(command)
            
            if command == "exit" and shellCommand.shellMode == "gui" then
                print("In order to exit the shell, close the window.")
            elseif command == "exit" and shellCommand.shellMode == "nogui" then
                shell.run("shutdown")
            elseif #command > 6 and string.sub(command, 1, 7) == "kernel " then
                shellCommand.action.runProgram(string.sub(command, 8, #command), true)
            else
                shellCommand.action.runProgram(command, false)
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

