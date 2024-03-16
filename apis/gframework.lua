local gframework = {}
local gframeworkPrivate = {}

gframework.kernelEventHandler = require "/graphicalOS_system/apis/kernelEventHandler"

gframeworkPrivate.backgroundColor = 1
gframeworkPrivate.hasBlinkNotBeenSet = true

gframeworkPrivate.term = {}
gframework.term = {
    setBackgroundColor = function (colorNumber)
        gframeworkPrivate.backgroundColor = colorNumber
    end,

    setCursorBlink = function (bool)
        if gframeworkPrivate.hasBlinkNotBeenSet == true and bool == true then
            gframeworkPrivate.hasBlinkNotBeenSet = false
            gframework.term.screenBuffer.setCursorBlink(bool)
        elseif bool == false then
            gframeworkPrivate.hasBlinkNotBeenSet = true
            gframework.term.screenBuffer.setCursorBlink(bool)
        end
    end,

    termBackup = function ()
        local currentPosX, currentPosY = gframework.term.screenBuffer.getCursorPos()
    
        return {
            backgroundColor = gframework.term.screenBuffer.getBackgroundColor(),
            textColor = gframework.term.screenBuffer.getTextColor(),
            X = currentPosX,
            Y = currentPosY
        }
    end,

    termReset = function (backup)
        gframework.term.screenBuffer.setBackgroundColor(backup.backgroundColor)
        gframework.term.screenBuffer.setTextColor(backup.textColor)
        gframework.term.screenBuffer.setCursorPos(backup.X, backup.Y)
    end,

    termBackupReset = function (func)
        local oldTermData = gframework.term.termBackup()
        if type(func) == "function" then
            func()
        end
        gframework.term.termReset(oldTermData)
    end,

    createDraw = function (func)
        return function ()
            gframework.term.termBackupReset(function ()
                if type(func) == "function" then
                    func()
                end
            end)
        end
    end,

    createScreenBuffer = function (currentTerm)
        local buffer = {}

        buffer.screenBufferPrivate = {
            currentBuffer = {},
            previousBuffer = {},

            currentBlinkBuffer = {
                isCursorBlinkSet = false,
            },

            previousBlinkBuffer = {
                isCursorBlinkSet = false,
            },
        
            currentTerm = currentTerm,
            cursorPosX = 1,
            cursorPosY = 1,
            textColor = 1,
            backgroundColor = 32768
        }
        buffer.screenBuffer = {
            getSize = function ()
                local height = #buffer.screenBufferPrivate.currentBuffer
                local width = #buffer.screenBufferPrivate.currentBuffer[height]

                return width, height
            end,
        
            setCursorBlink = function (setCursorBlinkBool)
                if type(setCursorBlinkBool) == "boolean" then
                    buffer.screenBufferPrivate.currentBlinkBuffer.isCursorBlinkSet = setCursorBlinkBool
                end
            end,
            
            getCursorBlink = function ()
                return buffer.screenBufferPrivate.currentBlinkBuffer.isCursorBlinkSet
            end,
        
            clearLine = function ()
                for indexPosX = 1, #buffer.screenBufferPrivate.currentBuffer[buffer.screenBufferPrivate.cursorPosY], 1 do
                    buffer.screenBufferPrivate.currentBuffer[buffer.screenBufferPrivate.cursorPosY][indexPosX] = {
                        textColor = buffer.screenBufferPrivate.textColor,
                        backgroundColor = buffer.screenBufferPrivate.backgroundColor,
                        char = " "
                    }
                end
            end,
        
            clear = function ()
                local xSize, ySize = buffer.screenBufferPrivate.currentTerm.getSize()

                for indexPosY = 1, ySize, 1 do
                    if buffer.screenBufferPrivate.currentBuffer[indexPosY] == nil then
                        buffer.screenBufferPrivate.currentBuffer[indexPosY] = {}
                    end

                    if buffer.screenBufferPrivate.previousBuffer[indexPosY] == nil then
                        buffer.screenBufferPrivate.previousBuffer[indexPosY] = {}
                    end

                    for indexPosX = 1, xSize, 1 do
                        if buffer.screenBufferPrivate.previousBuffer[indexPosY][indexPosX] == nil then
                            buffer.screenBufferPrivate.previousBuffer[indexPosY][indexPosX] = {
                                textColor = 1,
                                backgroundColor = 32768,
                                char = " "
                            }
                        end

                        if buffer.screenBufferPrivate.currentBuffer[indexPosY][indexPosX] == nil then
                            buffer.screenBufferPrivate.currentBuffer[indexPosY][indexPosX] = {
                                textColor = 1,
                                backgroundColor = 32768,
                                char = " "
                            }
                        else
                            buffer.screenBufferPrivate.currentBuffer[indexPosY][indexPosX].char = " "
                            buffer.screenBufferPrivate.currentBuffer[indexPosY][indexPosX].backgroundColor = buffer.screenBufferPrivate.backgroundColor
                            buffer.screenBufferPrivate.currentBuffer[indexPosY][indexPosX].textColor = buffer.screenBufferPrivate.textColor
                        end
                    end
                end
            end,
        
            setBackgroundColor = function (backgroundColor)
                buffer.screenBufferPrivate.backgroundColor = backgroundColor
            end,
            
            getBackgroundColor = function ()
                return buffer.screenBufferPrivate.backgroundColor
            end,
            
            setTextColor = function (textColorNum)
                buffer.screenBufferPrivate.textColor = textColorNum
            end,
        
            getTextColor = function ()
                return buffer.screenBufferPrivate.textColor
            end,
            
            setCursorPos = function (posX, posY)
                buffer.screenBufferPrivate.cursorPosX = posX
                buffer.screenBufferPrivate.cursorPosY = posY
            end,
            
            getCursorPos = function ()
                return buffer.screenBufferPrivate.cursorPosX, buffer.screenBufferPrivate.cursorPosY
            end,
            
            write = function (writeStringToBuffer)
                if writeStringToBuffer ~= "" then
                    for indexPosX = buffer.screenBufferPrivate.cursorPosX, buffer.screenBufferPrivate.cursorPosX + string.len(writeStringToBuffer) - 1, 1 do
                        buffer.screenBufferPrivate.currentBuffer[buffer.screenBufferPrivate.cursorPosY][indexPosX] = {
                            textColor = buffer.screenBufferPrivate.textColor,
                            backgroundColor = buffer.screenBufferPrivate.backgroundColor,
                            char = string.sub(writeStringToBuffer, indexPosX - (buffer.screenBufferPrivate.cursorPosX - 1), indexPosX - (buffer.screenBufferPrivate.cursorPosX - 1))
                        }
                    end

                    local width, height = buffer.screenBuffer.getSize()
                    local newPosX = buffer.screenBufferPrivate.cursorPosX + string.len(writeStringToBuffer)

                    if newPosX <= width then
                        buffer.screenBufferPrivate.cursorPosX = newPosX
                    end
                end
            end,
            
            draw = function ()
                for indexPosY = 1, #buffer.screenBufferPrivate.currentBuffer, 1 do
                    if buffer.screenBufferPrivate.previousBuffer[indexPosY] == nil then
                        buffer.screenBufferPrivate.previousBuffer[indexPosY] = {}
                    end

                    for indexPosX = 1, #buffer.screenBufferPrivate.currentBuffer[indexPosY], 1 do
                        if buffer.screenBufferPrivate.previousBuffer[indexPosY][indexPosX] == nil then
                            buffer.screenBufferPrivate.previousBuffer[indexPosY][indexPosX] = {}
                        end

                        local drawToScreen = false

                        if buffer.screenBufferPrivate.previousBuffer[indexPosY][indexPosX].textColor ~= buffer.screenBufferPrivate.currentBuffer[indexPosY][indexPosX].textColor then
                            drawToScreen = true
                        end

                        if buffer.screenBufferPrivate.previousBuffer[indexPosY][indexPosX].backgroundColor ~= buffer.screenBufferPrivate.currentBuffer[indexPosY][indexPosX].backgroundColor or drawToScreen == true then
                            drawToScreen = true
                        end

                        if buffer.screenBufferPrivate.currentBuffer[indexPosY][indexPosX].char ~= buffer.screenBufferPrivate.previousBuffer[indexPosY][indexPosX].char then
                            drawToScreen = true
                        end

                        if drawToScreen then
                            buffer.screenBufferPrivate.currentTerm.setCursorPos(indexPosX, indexPosY)
                            buffer.screenBufferPrivate.currentTerm.setTextColor(buffer.screenBufferPrivate.currentBuffer[indexPosY][indexPosX].textColor)
                            buffer.screenBufferPrivate.currentTerm.setBackgroundColor(buffer.screenBufferPrivate.currentBuffer[indexPosY][indexPosX].backgroundColor)
                            buffer.screenBufferPrivate.currentTerm.write(buffer.screenBufferPrivate.currentBuffer[indexPosY][indexPosX].char)
                        end

                        buffer.screenBufferPrivate.previousBuffer[indexPosY][indexPosX] = {
                            textColor = buffer.screenBufferPrivate.currentBuffer[indexPosY][indexPosX].textColor,
                            backgroundColor = buffer.screenBufferPrivate.currentBuffer[indexPosY][indexPosX].backgroundColor,
                            char = buffer.screenBufferPrivate.currentBuffer[indexPosY][indexPosX].char
                        }
                    end
                end

                if buffer.screenBufferPrivate.currentBlinkBuffer.isCursorBlinkSet == true then
                    buffer.screenBufferPrivate.currentTerm.setCursorPos(buffer.screenBufferPrivate.cursorPosX, buffer.screenBufferPrivate.cursorPosY)
                    buffer.screenBufferPrivate.currentTerm.setCursorBlink(buffer.screenBufferPrivate.currentBlinkBuffer.isCursorBlinkSet)
                elseif buffer.screenBufferPrivate.currentBlinkBuffer.isCursorBlinkSet ~= buffer.screenBufferPrivate.previousBlinkBuffer.isCursorBlinkSet then
                    buffer.screenBufferPrivate.currentTerm.setCursorBlink(false)
                end

                buffer.screenBufferPrivate.previousBlinkBuffer.isCursorBlinkSet = buffer.screenBufferPrivate.currentBlinkBuffer.isCursorBlinkSet
            end
        }
        
        buffer.screenBuffer.clear()

        return buffer.screenBuffer
    end
}
gframework.term.screenBuffer = gframework.term.createScreenBuffer(term.current())

gframework.tableContains = function (t_table, contains)
    local returnValue = false

    if type(t_table) == "table" then
        for key, value in pairs(t_table) do
            if value == contains then
                returnValue = true
                break
            end
        end
    end

    return returnValue
end

gframework.action = {
    createCoroutineAction = function (customCoroutineFunc)
        local createItemGroupAction = {}
    
        createItemGroupAction.coroutine = coroutine.create(function ()
            while true do
                customCoroutineFunc()
            end
        end)
    
        createItemGroupAction.func = function (events)
            local isOk, param = coroutine.resume(createItemGroupAction.coroutine, table.unpack(events))
    
            if not isOk then
                error(param, 1)
            end
        end
    
        return createItemGroupAction
    end,

    createAction = function (action)
        return gframework.action.createCoroutineAction(function ()
            local events = {os.pullEventRaw()}
    
            if type(action) == "function" then
                action(events)
            end
        end)
    end
}

gframework.createRadioButtonItem = function (radioButtonName, radioButtonPosX, radioButtonPosY, radioButtonBackgroundColor, radioButtonLabelBackgroundColor, radioButtonTextColor, checked, actionFunc)
    local radioButtonItem = {}

    radioButtonItem.checked = checked
    radioButtonItem.radioButtonPosX = radioButtonPosX
    radioButtonItem.radioButtonPosY = radioButtonPosY

    radioButtonItem.draw = gframework.term.createDraw(function ()
        gframework.term.screenBuffer.setBackgroundColor(radioButtonLabelBackgroundColor)
        gframework.term.screenBuffer.setTextColor(radioButtonTextColor)
        gframework.term.screenBuffer.setCursorPos(radioButtonPosX + 2, radioButtonPosY)
        gframework.term.screenBuffer.write(radioButtonName)

        gframework.term.screenBuffer.setBackgroundColor(radioButtonBackgroundColor)
        gframework.term.screenBuffer.setCursorPos(radioButtonPosX, radioButtonPosY)
        if radioButtonItem.checked == true then
            gframework.term.screenBuffer.write("X")
        else
            gframework.term.screenBuffer.write(" ")
        end
    end)

    radioButtonItem.action = function (events)
        if type(actionFunc) == "function" then
            actionFunc()
        end
    end

    return radioButtonItem
end

gframework.createItemGroup = function ()
    local itemGroup = {}

    --[[
        {
            draw: function
            action: function
        }
    ]]
    itemGroup.items = {}

    itemGroup.blockItemGroupForTopBar = false

    itemGroup.excludeFromExecutionBool = false
    itemGroup.excludeFromExecution = function (bool)
        if type(bool) == "boolean" then
            itemGroup.excludeFromExecutionBool = bool
        end
    end

    itemGroup.createMiniWindow = function (miniWindowName, miniWindowPosX, miniWindowPosY, miniWindowWidth, miniWindowHeight, miniWindowBackgroundColor)
        local miniWindowItem = {}
        local miniWindowReturn = {}

        miniWindowItem.onWindowClose = function () end
        miniWindowItem.onWindowOpen = function () end

        miniWindowItem.draw = gframework.term.createDraw(function ()
            gframework.term.screenBuffer.setBackgroundColor(miniWindowBackgroundColor)
            for indexPosY = miniWindowPosY, miniWindowPosY + miniWindowHeight, 1 do
                for indexPosX = miniWindowPosX, miniWindowPosX + miniWindowWidth - 1, 1 do
                    gframework.term.screenBuffer.setCursorPos(indexPosX, indexPosY)
                    gframework.term.screenBuffer.write(" ")
                end
            end
            
            gframework.term.screenBuffer.setBackgroundColor(8192)
            for indexPosX = miniWindowPosX, miniWindowPosX + miniWindowWidth - 1, 1 do
                gframework.term.screenBuffer.setCursorPos(indexPosX, miniWindowPosY)
                gframework.term.screenBuffer.write(" ")
            end
            gframework.term.screenBuffer.setBackgroundColor(16384)
            gframework.term.screenBuffer.setCursorPos(miniWindowPosX + miniWindowWidth - 1, miniWindowPosY)
            gframework.term.screenBuffer.write("X")

            gframework.term.screenBuffer.setBackgroundColor(8192)
            gframework.term.screenBuffer.setCursorPos(miniWindowPosX, miniWindowPosY)
            gframework.term.screenBuffer.write(string.sub(miniWindowName, 1, miniWindowPosX + miniWindowWidth - 6))
        end)

        miniWindowItem.action = gframework.action.createAction(function (events)
            if events[1] == "mouse_click" then
                if events[3] == miniWindowPosX + miniWindowWidth - 1 and events[4] == miniWindowPosY then
                    miniWindowReturn.closeWindow()
                end
            end
        end)

        miniWindowReturn.setOnWindowClose = function (func)
            if type(func) == "function" then
                miniWindowItem.onWindowClose = func
            end
        end

        miniWindowReturn.setOnWindowOpen = function (func)
            if type(func) == "function" then
                miniWindowItem.onWindowOpen = func
            end
        end

        miniWindowReturn.closeWindow = function ()
            itemGroup.excludeFromExecution(true)
            miniWindowItem.onWindowClose()
        end

        miniWindowReturn.openWindow = function ()
            itemGroup.excludeFromExecution(false)
            miniWindowItem.onWindowOpen()
        end

        table.insert(itemGroup.items, miniWindowItem)
        return miniWindowReturn
    end

    itemGroup.createFileBrowserBox = function (fileBrowserBoxPath, fileBrowserBoxPosX, fileBrowserBoxPosY, fileBrowserBoxWidth, fileBrowserBoxHeight, backBtnEnabled)
        local fileBrowserBoxItem = {}
        local fileBrowserBoxReturn = {}

        fileBrowserBoxItem.fileBrowserBoxPosX = fileBrowserBoxPosX
        fileBrowserBoxItem.fileBrowserBoxPosY = fileBrowserBoxPosY
        fileBrowserBoxItem.fileBrowserBoxWidth = fileBrowserBoxWidth
        fileBrowserBoxItem.fileBrowserBoxHeight = fileBrowserBoxHeight

        fileBrowserBoxItem.currentPath = fileBrowserBoxPath
        fileBrowserBoxItem.directoryTable = {}
        fileBrowserBoxItem.directoryTableCurrentTopKey = 0
        fileBrowserBoxItem.selectedFileOrFolder = 0
        fileBrowserBoxItem.isDoubleClickEnabled = false
        fileBrowserBoxItem.isBackBtnEnabled = backBtnEnabled

        fileBrowserBoxItem.fileBrowserBoxOnFileChange = function (file, isAFolder) end
        fileBrowserBoxItem.fileBrowserBoxDoubleClick = function (file, isAFolder) end
        fileBrowserBoxItem.fileBrowserBoxOnBackBtnClick = function (file, isAFolder) end
        fileBrowserBoxItem.onUnselectItem = function () end

        fileBrowserBoxItem.bufferLoadTheItemsInCurrentPath = function ()
            local filesAndFoldersInDirectory = fs.list(fileBrowserBoxItem.currentPath)

            fileBrowserBoxItem.directoryTable = {}

            for key, value in pairs(filesAndFoldersInDirectory) do
                if fs.isDir(fileBrowserBoxItem.currentPath .. "/" .. value) then
                    table.insert(fileBrowserBoxItem.directoryTable, {
                        type = "folder",
                        name = value
                    })
                end
            end

            for key, value in pairs(filesAndFoldersInDirectory) do
                if fs.isDir(fileBrowserBoxItem.currentPath .. "/" .. value) == false then
                    table.insert(fileBrowserBoxItem.directoryTable, {
                        type = "file",
                        name = value
                    })
                end
            end

            if #fileBrowserBoxItem.directoryTable >= 1 then
                fileBrowserBoxItem.directoryTableCurrentTopKey = 1
            else
                fileBrowserBoxItem.directoryTableCurrentTopKey = 0
            end
        end
        fileBrowserBoxItem.bufferLoadTheItemsInCurrentPath()

        fileBrowserBoxItem.draw = gframework.term.createDraw(function ()
            gframework.term.screenBuffer.setBackgroundColor(256)

            for indexHeight = fileBrowserBoxItem.fileBrowserBoxPosY, fileBrowserBoxItem.fileBrowserBoxPosY + fileBrowserBoxItem.fileBrowserBoxHeight - 1, 1 do
                for indexWidth = fileBrowserBoxItem.fileBrowserBoxPosX, fileBrowserBoxItem.fileBrowserBoxPosX + fileBrowserBoxItem.fileBrowserBoxWidth - 1, 1 do
                    gframework.term.screenBuffer.setCursorPos(indexWidth, indexHeight)
                    gframework.term.screenBuffer.write(" ")
                end

                gframework.term.screenBuffer.setBackgroundColor(1)
            end

            local pathPlusPosX = 0
            if fileBrowserBoxItem.isBackBtnEnabled == true then
                pathPlusPosX = 2
                gframework.term.screenBuffer.setBackgroundColor(128)
                gframework.term.screenBuffer.setCursorPos(fileBrowserBoxItem.fileBrowserBoxPosX, fileBrowserBoxItem.fileBrowserBoxPosY)
                gframework.term.screenBuffer.write("<-")
            end

            gframework.term.screenBuffer.setBackgroundColor(256)
            gframework.term.screenBuffer.setCursorPos(fileBrowserBoxItem.fileBrowserBoxPosX + pathPlusPosX, fileBrowserBoxItem.fileBrowserBoxPosY)
            gframework.term.screenBuffer.write(string.sub(fileBrowserBoxItem.currentPath, 1, fileBrowserBoxItem.fileBrowserBoxWidth - 2))

            if fileBrowserBoxItem.directoryTableCurrentTopKey ~= 0 then
                gframework.term.screenBuffer.setBackgroundColor(1)
                gframework.term.screenBuffer.setTextColor(32768)
                
                for fileIndex = fileBrowserBoxItem.directoryTableCurrentTopKey, fileBrowserBoxItem.directoryTableCurrentTopKey + fileBrowserBoxItem.fileBrowserBoxHeight - 2, 1 do
                    if fileBrowserBoxItem.directoryTable[fileIndex] == nil then
                        break
                    end

                    if fileBrowserBoxItem.selectedFileOrFolder == fileIndex then
                        for selectedIndexPosX = fileBrowserBoxItem.fileBrowserBoxPosX, fileBrowserBoxItem.fileBrowserBoxPosX + fileBrowserBoxItem.fileBrowserBoxWidth - 1, 1 do
                            gframework.term.screenBuffer.setCursorPos(selectedIndexPosX, fileBrowserBoxItem.fileBrowserBoxPosY + fileIndex - (fileBrowserBoxItem.directoryTableCurrentTopKey - 1))
                            gframework.term.screenBuffer.setBackgroundColor(2048)
                            gframework.term.screenBuffer.write(" ")
                        end
                    else
                        gframework.term.screenBuffer.setBackgroundColor(1)
                    end

                    gframework.term.screenBuffer.setCursorPos(fileBrowserBoxItem.fileBrowserBoxPosX, fileBrowserBoxItem.fileBrowserBoxPosY + fileIndex - (fileBrowserBoxItem.directoryTableCurrentTopKey - 1))
                    if fileBrowserBoxItem.directoryTable[fileIndex].type == "folder" then
                        gframework.term.screenBuffer.write("[=] " .. string.sub(fileBrowserBoxItem.directoryTable[fileIndex].name, 1, fileBrowserBoxItem.fileBrowserBoxWidth - 4))
                    else
                        gframework.term.screenBuffer.write("[+] " .. string.sub(fileBrowserBoxItem.directoryTable[fileIndex].name, 1, fileBrowserBoxItem.fileBrowserBoxWidth - 4))
                    end
                end
            end
        end)
        fileBrowserBoxItem.unselectItem = function (events)
            local unselectItemPos = (
                (
                    events[4] >= fileBrowserBoxItem.fileBrowserBoxPosY + 1 and
                    events[4] <= fileBrowserBoxItem.fileBrowserBoxPosY + fileBrowserBoxItem.fileBrowserBoxHeight - 1
                ) == false or
                (
                    events[3] >= fileBrowserBoxItem.fileBrowserBoxPosX + fileBrowserBoxItem.fileBrowserBoxWidth or
                    events[4] >= fileBrowserBoxItem.fileBrowserBoxPosY + fileBrowserBoxItem.fileBrowserBoxHeight or
                    events[3] <= fileBrowserBoxItem.fileBrowserBoxPosX - 1 or
                    events[4] <= fileBrowserBoxItem.fileBrowserBoxPosY - 1
                )
            )

            if unselectItemPos then
                local redrawFileBox = false
                if fileBrowserBoxItem.selectedFileOrFolder >= 1 then
                    redrawFileBox = true
                end

                fileBrowserBoxItem.selectedFileOrFolder = 0

                if redrawFileBox then
                    fileBrowserBoxItem.draw()
                    gframework.term.screenBuffer.draw()
                    fileBrowserBoxItem.onUnselectItem()
                end
            end
        end

        fileBrowserBoxItem.clickOnFile = function (events)
            if events[4] >= fileBrowserBoxItem.fileBrowserBoxPosY + 1 and events[4] <= fileBrowserBoxItem.fileBrowserBoxPosY + fileBrowserBoxItem.fileBrowserBoxHeight - 1 and fileBrowserBoxItem.directoryTableCurrentTopKey >= 1 then
                for fileIndex = fileBrowserBoxItem.directoryTableCurrentTopKey, fileBrowserBoxItem.directoryTableCurrentTopKey + fileBrowserBoxItem.fileBrowserBoxHeight - 2, 1 do
                    if fileBrowserBoxItem.directoryTable[fileIndex] == nil then
                        break
                    end

                    if (fileIndex - (fileBrowserBoxItem.directoryTableCurrentTopKey - 1)) == events[4] - fileBrowserBoxItem.fileBrowserBoxPosY then
                        fileBrowserBoxItem.selectedFileOrFolder = fileIndex
                        fileBrowserBoxItem.draw()

                        local ifIsAFolder = false
                        if fileBrowserBoxItem.directoryTable[fileIndex].type == "folder" then
                            ifIsAFolder = true
                        end

                        local pathTofileOrFolder = {}
                        pathTofileOrFolder.path = "/"
                        pathTofileOrFolder.fileOrFolder = fileBrowserBoxItem.directoryTable[fileIndex].name
                        if fileBrowserBoxItem.currentPath ~= "/" then
                            pathTofileOrFolder.path = fileBrowserBoxItem.currentPath .. "/" .. fileBrowserBoxItem.directoryTable[fileIndex].name
                        else
                            pathTofileOrFolder.path = "/" .. fileBrowserBoxItem.directoryTable[fileIndex].name
                        end

                        if fileBrowserBoxItem.isDoubleClickEnabled == true then
                            if type(fileBrowserBoxItem.fileBrowserBoxDoubleClick) == "function" then
                                fileBrowserBoxItem.fileBrowserBoxDoubleClick(pathTofileOrFolder, ifIsAFolder)
                            end
                        else
                            if type(fileBrowserBoxItem.fileBrowserBoxOnFileChange) == "function" then
                                fileBrowserBoxItem.fileBrowserBoxOnFileChange(pathTofileOrFolder, ifIsAFolder)
                            end
                            fileBrowserBoxItem.isDoubleClickEnabled = true
                            gframework.timer.addTimer(0.2, function ()
                                fileBrowserBoxItem.isDoubleClickEnabled = false
                            end)
                        end

                        break
                    end
                end
            end
        end

        fileBrowserBoxItem.action = gframework.action.createAction(function (events)
            if events[1] == "mouse_scroll" and #fileBrowserBoxItem.directoryTable >= (fileBrowserBoxItem.fileBrowserBoxHeight - 1) then
                if events[3] >= fileBrowserBoxItem.fileBrowserBoxPosX and events[3] <= fileBrowserBoxItem.fileBrowserBoxPosX + fileBrowserBoxItem.fileBrowserBoxWidth - 1 and events[4] >= fileBrowserBoxItem.fileBrowserBoxPosY + 1 and events[4] <= fileBrowserBoxItem.fileBrowserBoxPosY + fileBrowserBoxItem.fileBrowserBoxHeight - 1 then
                    if events[2] == -1 and fileBrowserBoxItem.directoryTableCurrentTopKey - 1 >= 1 then
                        fileBrowserBoxItem.directoryTableCurrentTopKey = fileBrowserBoxItem.directoryTableCurrentTopKey - 1
                        fileBrowserBoxItem.draw()
                        gframework.term.screenBuffer.draw()
                    elseif events[2] == 1 and fileBrowserBoxItem.directoryTableCurrentTopKey + 1 <= #fileBrowserBoxItem.directoryTable - fileBrowserBoxItem.fileBrowserBoxHeight + 2 then
                        fileBrowserBoxItem.directoryTableCurrentTopKey = fileBrowserBoxItem.directoryTableCurrentTopKey + 1
                        fileBrowserBoxItem.draw()
                        gframework.term.screenBuffer.draw()
                    end
                end
            elseif events[1] == "mouse_click" then
                if events[3] >= fileBrowserBoxItem.fileBrowserBoxPosX and events[3] <= fileBrowserBoxItem.fileBrowserBoxPosX + fileBrowserBoxItem.fileBrowserBoxWidth - 1 and events[4] >= fileBrowserBoxItem.fileBrowserBoxPosY and events[4] <= fileBrowserBoxItem.fileBrowserBoxPosY + fileBrowserBoxItem.fileBrowserBoxHeight - 1 then
                    fileBrowserBoxItem.clickOnFile(events)
                end

                if events[3] >= fileBrowserBoxItem.fileBrowserBoxPosX and events[3] <= fileBrowserBoxItem.fileBrowserBoxPosX + 1 and events[4] == fileBrowserBoxItem.fileBrowserBoxPosY then
                    if type(fileBrowserBoxItem.fileBrowserBoxDoubleClick) == "function" and fileBrowserBoxItem.isBackBtnEnabled == true then
                        local backBtnPath = "/" .. shell.resolve(fileBrowserBoxItem.currentPath .. "/..")
                        if backBtnPath ~= "/.." then
                            fileBrowserBoxItem.fileBrowserBoxOnBackBtnClick(backBtnPath, true)
                        end
                    end
                end

                fileBrowserBoxItem.unselectItem(events)
            end
        end)

        fileBrowserBoxReturn.changeDirectory = function (changeDirectoryPath)
            fileBrowserBoxItem.isDoubleClickEnabled = false
            fileBrowserBoxItem.selectedFileOrFolder = 0
            fileBrowserBoxItem.directoryTableCurrentTopKey = 0
            fileBrowserBoxItem.directoryTable = {}
            fileBrowserBoxItem.currentPath = changeDirectoryPath

            fileBrowserBoxItem.bufferLoadTheItemsInCurrentPath()
            fileBrowserBoxItem.draw()
            gframework.term.screenBuffer.draw()
        end

        fileBrowserBoxReturn.setBoubleClickFunc = function (func)
            if type(func) == "function" then
                fileBrowserBoxItem.fileBrowserBoxDoubleClick = func
            end
        end

        fileBrowserBoxReturn.setOnFileChangeFunc = function (func)
            if type(func) == "function" then
                fileBrowserBoxItem.fileBrowserBoxOnFileChange = func
            end
        end

        fileBrowserBoxReturn.resizeFileBrowser = function (newPosX, newPosY, newWidth, newHeight)
            fileBrowserBoxItem.fileBrowserBoxPosX = newPosX
            fileBrowserBoxItem.fileBrowserBoxPosY = newPosY
            fileBrowserBoxItem.fileBrowserBoxWidth = newWidth
            fileBrowserBoxItem.fileBrowserBoxHeight = newHeight

            fileBrowserBoxItem.draw()
            gframework.term.screenBuffer.draw()
        end

        fileBrowserBoxReturn.setBackBtnAction = function (func)
            if type(func) == "function" then
                fileBrowserBoxItem.fileBrowserBoxOnBackBtnClick = func
            end
        end

        fileBrowserBoxReturn.setOnUnselectItem = function (func)
            if type(func) == "function" then
                fileBrowserBoxItem.onUnselectItem = func
            end
        end

        table.insert(itemGroup.items, fileBrowserBoxItem)
        return fileBrowserBoxReturn
    end
    
    itemGroup.createButton = function (nameString, X, Y, margin, backgroundColor, textColor)
        local button = {}
        local buttonReturn = {}
        local buttonPrivate = {}
        button.draw = gframework.term.createDraw(function ()
            gframework.term.screenBuffer.setCursorPos(button.startX, button.Y)
            gframework.term.screenBuffer.setBackgroundColor(button.backgroundColor)
            gframework.term.screenBuffer.setTextColor(button.textColor)
            for indexLineY = button.marginStartY, button.marginEndY, 1 do
                for indexLineX = button.marginStartX, button.marginEndX, 1 do
                    gframework.term.screenBuffer.setCursorPos(indexLineX, indexLineY)
                    gframework.term.screenBuffer.write(" ")
                end
            end
            
            gframework.term.screenBuffer.setCursorPos(button.startX, button.Y)
            gframework.term.screenBuffer.write(button.btnName)
        end)

        button.action = gframework.action.createAction(function (events)
            if events[1] == "mouse_click" then
                if events[3] >= button.marginStartX and events[3] <= button.marginEndX and events[4] >= button.marginStartY and events[4] <= button.marginEndY then
                    button.onClickFunc()
                end
            end
        end)
        
        button.btnName = nameString

        buttonReturn.resetBtnProperties = function (PosX, PosY, btnMargin)
            button.startX = PosX
            button.Y = PosY
            button.endX = PosX + string.len(button.btnName) - 1

            button.btnMargin = btnMargin
            button.marginStartX = button.startX - btnMargin
            button.marginStartY = button.Y - btnMargin
            button.marginEndX = button.endX + btnMargin
            button.marginEndY = button.Y + btnMargin
        end
        buttonReturn.resetBtnProperties(X, Y, margin)

        buttonReturn.resetColors = function (backgrColor, txtColor)
            button.backgroundColor = backgrColor
            button.textColor = txtColor
        end
        buttonReturn.resetColors(backgroundColor, textColor)

        button.onClickFunc = function () end
        buttonReturn.onClick = function (func)
            if type(func) == "function" then
                button.onClickFunc = func
            end
        end

        buttonReturn.resetBtnName = function (btnName)
            button.btnName = btnName

            buttonReturn.resetBtnProperties(button.startX, button.Y, button.btnMargin)
        end
        buttonReturn.resetBtnName(nameString)

        table.insert(itemGroup.items, button)
        return buttonReturn
    end

    itemGroup.createBox = function (boxPosX, boxPosY, boxColor, boxWidth, boxHight)
        local boxItem = {}
        local boxItemReturn = {}

        boxItem.boxDisplayAllowed = true

        boxItem.draw = gframework.term.createDraw(function ()
            if boxItem.boxDisplayAllowed == true then
                gframework.term.screenBuffer.setBackgroundColor(boxColor)

                for indexPosY = boxPosY, boxPosY + boxHight - 1, 1 do
                    for indexPosX = boxPosX, boxPosX + boxWidth - 1, 1 do
                        gframework.term.screenBuffer.setCursorPos(indexPosX, indexPosY)
                        gframework.term.screenBuffer.write(" ")
                    end
                end
            end
        end)

        boxItemReturn.setDisplayAllowed = function (bool)
            if type(bool) == "boolean" then
                boxItem.boxDisplayAllowed = bool
            end
        end

        table.insert(itemGroup.items, boxItem)
        return boxItemReturn
    end

    itemGroup.createRadioButton = function (...)
        local radioButtonItem = {}

        radioButtonItem.buttonsList = {...}

        radioButtonItem.draw = gframework.term.createDraw(function ()
            for key, value in pairs(radioButtonItem.buttonsList) do
                if value.draw ~= nil then
                    value.draw()
                end
            end
        end)

        radioButtonItem.getCurrentCheckedKey = function ()
            local currentCheckedKey = 0

            if next(radioButtonItem.buttonsList) ~= nil then
                for key, value in pairs(radioButtonItem.buttonsList) do
                    if value.checked then
                        currentCheckedKey = key
                    end
                end
            end

            return currentCheckedKey
        end

        radioButtonItem.changeCurrentCheckedKey = function (currentCheckedKey, events)
            local returnValue = {}
            returnValue.radioButtonHasChanged = false
            returnValue.radioButtonChangedToKey = 0

            if currentCheckedKey ~= 0 and events[1] == "mouse_click" then
                for key, value in pairs(radioButtonItem.buttonsList) do
                    if key ~= currentCheckedKey and events[3] == value.radioButtonPosX and events[4] == value.radioButtonPosY then
                        radioButtonItem.buttonsList[currentCheckedKey].checked = false
                        radioButtonItem.buttonsList[key].checked = true
                        returnValue.radioButtonHasChanged = true
                        returnValue.radioButtonChangedToKey = key
                        break
                    end
                end
            end

            return returnValue
        end

        radioButtonItem.action = gframework.action.createAction(function (events)
            if events[1] == "mouse_click" then
                local currentCheckedKey = radioButtonItem.getCurrentCheckedKey()
                local newChecked = radioButtonItem.changeCurrentCheckedKey(currentCheckedKey, events)

                if newChecked.radioButtonHasChanged then
                    radioButtonItem.draw()
                    gframework.term.screenBuffer.draw()
                    radioButtonItem.buttonsList[newChecked.radioButtonChangedToKey].action()
                end
            end
        end)

        table.insert(itemGroup.items, radioButtonItem)
    end

    itemGroup.createCheckBox = function (checkBoxName, checkBoxPosX, checkBoxPosY, checkBoxBackgroundColor, checkBoxLabelBackgroundColor, checkBoxTextColor, checked, actionFunc)
        local checkBoxItem = {}

        checkBoxItem.checked = checked

        checkBoxItem.draw = gframework.term.createDraw(function ()
            gframework.term.screenBuffer.setBackgroundColor(checkBoxLabelBackgroundColor)
            gframework.term.screenBuffer.setTextColor(checkBoxTextColor)
            gframework.term.screenBuffer.setCursorPos(checkBoxPosX + 2, checkBoxPosY)
            gframework.term.screenBuffer.write(checkBoxName)

            gframework.term.screenBuffer.setBackgroundColor(checkBoxBackgroundColor)
            gframework.term.screenBuffer.setCursorPos(checkBoxPosX, checkBoxPosY)
            if checkBoxItem.checked == true then
                gframework.term.screenBuffer.write("#")
            else
                gframework.term.screenBuffer.write(" ")
            end
        end)

        checkBoxItem.action = gframework.action.createAction(function (events)
            if events[1] == "mouse_click" then
                if events[3] == checkBoxPosX and events[4] == checkBoxPosY then
                    if checkBoxItem.checked == true then
                        checkBoxItem.checked = false
                        checkBoxItem.draw()
                        gframework.term.screenBuffer.draw()
                    else
                        checkBoxItem.checked = true
                        checkBoxItem.draw()
                        gframework.term.screenBuffer.draw()
                    end

                    actionFunc(checkBoxItem.checked)
                end
            end
        end)

        table.insert(itemGroup.items, checkBoxItem)
    end

    itemGroup.createLabel = function (labelName, labelPosX, labelPosY, labelBackgroundColor, labelTextColor)
        local labelItem = {}
        local labelReturn = {}

        labelItem.labelDisplayAllowed = true
        labelItem.labelName = labelName

        labelItem.draw = gframework.term.createDraw(function ()
            if labelItem.labelDisplayAllowed == true then
                gframework.term.screenBuffer.setBackgroundColor(labelBackgroundColor)
                gframework.term.screenBuffer.setTextColor(labelTextColor)
                gframework.term.screenBuffer.setCursorPos(labelPosX, labelPosY)
                gframework.term.screenBuffer.write(labelItem.labelName)
            end
        end)

        labelReturn.setLabelName = function (newLabelName)
            if type(newLabelName) == "string" then
                labelItem.labelName = newLabelName
                labelItem.draw()
            end
        end

        labelReturn.setDisplayAllowed = function (bool)
            if type(bool) == "boolean" then
                labelItem.labelDisplayAllowed = bool
            end
        end

        table.insert(itemGroup.items, labelItem)
        return labelReturn
    end

    itemGroup.createCustomItem = function (item)
        if type(item) == "table" then
            table.insert(itemGroup.items, item)
        end
    end

    itemGroup.createReadBar = function (readBarPosX, readBarPosY, readBarWidth, readBarBackgroundColor, readBarTextColor, readBarActionFunc)
        local readBarItem = {}

        readBarItem.readString = ""
        readBarItem.isReadBarOpen = false
        readBarItem.oldTermData = {}

        readBarItem.getStartReadBarNumber = function ()
            local startNum = 1
            local barDisplay = string.len(readBarItem.readString) - readBarWidth + 2
            if startNum < barDisplay then
                startNum = barDisplay
            end

            return startNum
        end

        readBarItem.getCursorBlinkPos = function ()
            return string.len(
                string.sub(readBarItem.readString, readBarItem.getStartReadBarNumber(), string.len(readBarItem.readString))
            )
        end

        readBarItem.draw = gframework.term.createDraw(function ()
            gframework.term.screenBuffer.setCursorPos(readBarPosX, readBarPosY)
            gframework.term.screenBuffer.setBackgroundColor(readBarBackgroundColor)
            gframework.term.screenBuffer.setTextColor(readBarTextColor)
            for i = readBarPosX, readBarPosX + readBarWidth - 1, 1 do
                gframework.term.screenBuffer.setCursorPos(i, readBarPosY)
                gframework.term.screenBuffer.write(" ")
            end

            local startNum = readBarItem.getStartReadBarNumber()
            gframework.term.screenBuffer.setCursorPos(readBarPosX, readBarPosY)
            gframework.term.screenBuffer.write( string.sub(readBarItem.readString, startNum, string.len(readBarItem.readString)) )
        end)

        readBarItem.openOrCloseReadBar = function (events)
            if events[1] == "mouse_click" then
                local ifClickInReadBar = (events[3] >= readBarPosX and events[3] <= readBarPosX + readBarWidth - 1 and events[4] == readBarPosY)

                if ifClickInReadBar then
                    if readBarItem.isReadBarOpen == false then
                        readBarItem.oldTermData = gframework.term.termBackup()
                    end
                    readBarItem.isReadBarOpen = true
                    gframework.term.screenBuffer.setTextColor(readBarTextColor)
                    gframework.term.screenBuffer.setCursorPos(readBarPosX + readBarItem.getCursorBlinkPos(), readBarPosY)
                    gframework.term.setCursorBlink(true)
                elseif ifClickInReadBar == false then
                    if readBarItem.isReadBarOpen == true then
                        gframework.term.termReset(readBarItem.oldTermData)
                        gframework.term.setCursorBlink(false)
                    end
                    readBarItem.isReadBarOpen = false
                end
            end
        end

        readBarItem.typeKeysIntoTheInput = function (events)
            if readBarItem.isReadBarOpen and (events[1] == "char" or events[1] == "key" or events[1] == "key_up") then
                if events[1] == "char" then
                    readBarItem.readString = readBarItem.readString .. events[2]
                elseif events[1] == "key" and events[2] == 259 then
                    if readBarItem.readString ~= "" then
                        readBarItem.readString = string.sub(readBarItem.readString, 1, string.len(readBarItem.readString) - 1)
                    end
                elseif events[1] == "key" and (events[2] == 257 or events[2] == 335) then
                    local readString = readBarItem.readString
                    readBarItem.readString = ""
                    readBarItem.isReadBarOpen = false
                    gframework.term.termReset(readBarItem.oldTermData)
                    gframework.term.setCursorBlink(false)
                    if type(readBarActionFunc) == "function" then
                        gframework.term.termBackupReset(function ()
                            readBarActionFunc(readString)
                        end)
                    end
                end
                
                readBarItem.draw()
                gframework.term.screenBuffer.setCursorPos(readBarPosX + readBarItem.getCursorBlinkPos(), readBarPosY)
            end
        end

        readBarItem.action = gframework.action.createAction(function (events)
            if events[1] == "mouse_click" or events[1] == "char" or events[1] == "key" or events[1] == "key_up" then
                if gframeworkPrivate.hasBlinkNotBeenSet == true then
                    readBarItem.openOrCloseReadBar(events)
                    readBarItem.typeKeysIntoTheInput(events)
                    gframework.term.screenBuffer.draw()
                else
                    readBarItem.isReadBarOpen = false
                end
            end
        end)

        table.insert(itemGroup.items, readBarItem)
    end

    itemGroup.draw = function ()
        if next(itemGroup.items) ~= nil and itemGroup.excludeFromExecutionBool == false then
            for key, value in pairs(itemGroup.items) do
                if value.draw ~= nil then
                    gframework.term.termBackupReset(function ()
                        value.draw()
                    end)
                end
            end
        end
    end

    itemGroup.run = function (events)
        if next(itemGroup.items) ~= nil and itemGroup.excludeFromExecutionBool == false then
            for key, value in pairs(itemGroup.items) do
                if value.action ~= nil then
                    value.action.func(events)
                end
            end
        end
    end

    return itemGroup
end

gframeworkPrivate.topBar = {
    excludeItemGroupsFromExecutionTable = {},
    isMenuOpen = false,
    unlockItemGroups = false,
    runAtTheEnd = {}
}
gframework.topBar = {
    menus = {},
    openMenuId = 0,
    
    settings = {
        backgroundColor = 256,
        textColor = 1
    },

    addFunctionAtTheEnd = function (func)
        if type(func) == "function" then
            table.insert(gframeworkPrivate.topBar.runAtTheEnd, func)
        end
    end,

    createTopBarMenuItem = function (itemName, func)
        return {
            name = itemName,
            func = func
        }
    end,

    createTopBarMenu = function (menuName, ...)
        local topBarMenu = {
            name = menuName,
            allowDisplay = true,
            items = {...}
        }
        local topBarMenuReturn = {
            allowDisplay = function (bool)
                if type(bool) == "boolean" then
                    topBarMenu.allowDisplay = bool
                    gframework.topBar.draw()
                    gframework.term.screenBuffer.draw()
                end
            end
        }

        table.insert(gframework.topBar.menus, topBarMenu)
        return topBarMenuReturn
    end,

    excludeItemGroupsFromExecution = function (...)
        local groupItems = {...}

        gframeworkPrivate.topBar.excludeItemGroupsFromExecutionTable = {}

        if next(groupItems) ~= nil then
            gframeworkPrivate.topBar.excludeItemGroupsFromExecutionTable = {}

            for key, value in pairs(groupItems) do
                table.insert(gframeworkPrivate.topBar.excludeItemGroupsFromExecutionTable, value)
            end
        end
    end,

    draw = gframework.term.createDraw(function ()
        if next(gframework.topBar.menus) ~= nil then
            gframework.term.screenBuffer.setCursorPos(1, 1)
            gframework.term.screenBuffer.setBackgroundColor(gframework.topBar.settings.backgroundColor)
            gframework.term.screenBuffer.setTextColor(gframework.topBar.settings.textColor)
            gframework.term.screenBuffer.clearLine()
        
            if next(gframework.topBar.menus) ~= nil then
                local titlePosX = 2
                for menuKey, menuValue in pairs(gframework.topBar.menus) do
                    if type(menuValue.name) == "string" and menuValue.allowDisplay == true then
                        gframework.term.screenBuffer.setCursorPos(titlePosX, 1)
                        gframework.term.screenBuffer.write(menuValue.name)
        
                        if menuKey == gframework.topBar.openMenuId then
                            local longestString = string.len(menuValue.name)
                            for itemKey, itemValue in pairs(gframework.topBar.menus[menuKey].items) do
                                if string.len(itemValue.name) > longestString then
                                    longestString = string.len(itemValue.name)
                                end
                            end

                            for itemKey, itemValue in pairs(gframework.topBar.menus[menuKey].items) do
                                for menuBackgroundPosX = titlePosX - 1, titlePosX + longestString, 1 do
                                    gframework.term.screenBuffer.setCursorPos(menuBackgroundPosX, itemKey + 1)
                                    gframework.term.screenBuffer.write(" ")
                                end

                                gframework.term.screenBuffer.setCursorPos(titlePosX, itemKey + 1)
                                gframework.term.screenBuffer.write(itemValue.name)
                            end
                        end

                        titlePosX = titlePosX + string.len(menuValue.name) + 1
                    end
                end
            end
        end
    end),

    blockItemGroup = function (bool)
        if next(gframeworkPrivate.topBar.excludeItemGroupsFromExecutionTable) ~= nil and type(bool) == "boolean" then
            for key, value in pairs(gframeworkPrivate.topBar.excludeItemGroupsFromExecutionTable) do
                gframeworkPrivate.topBar.excludeItemGroupsFromExecutionTable[key].blockItemGroupForTopBar = bool
            end
        end
    end,

    endAction = function ()
        if gframeworkPrivate.topBar.unlockItemGroups == true then
            gframework.topBar.blockItemGroup(false)
        end

        if gframeworkPrivate.topBar.isMenuOpen == true then
            gframework.draw()
        end

        if gframework.topBar.openMenuId == 0 and next(gframework.topBar.menus) ~= nil then
            gframeworkPrivate.topBar.unlockItemGroups = false
            gframeworkPrivate.topBar.isMenuOpen = false
        end

        if next(gframeworkPrivate.topBar.runAtTheEnd) ~= nil then
            for key, value in pairs(gframeworkPrivate.topBar.runAtTheEnd) do
                if type(value) == "function" then
                    value()
                end
            end

            gframeworkPrivate.topBar.runAtTheEnd = {}
        end
    end,

    clickOnMenuBar = function (events)
        local drawFunc = function ()
            gframework.topBar.blockItemGroup(false)
            gframework.draw()
            gframework.topBar.blockItemGroup(true)
        end

        gframework.topBar.blockItemGroup(true)
    
        local titlePosX = 2
        for key, value in pairs(gframework.topBar.menus) do
            if type(value.name) == "string" and value.allowDisplay == true then
                if events[3] >= titlePosX and events[3] <= titlePosX + string.len(value.name) - 1 then
                    gframework.topBar.openMenuId = key
                    gframeworkPrivate.topBar.unlockItemGroups = true
                    gframeworkPrivate.topBar.isMenuOpen = true
                    drawFunc()
                    break
                else
                    gframeworkPrivate.topBar.unlockItemGroups = true
                    gframework.topBar.openMenuId = 0
                end

                titlePosX = titlePosX + string.len(value.name) + 1
            end
        end
    end,

    clickOutsideMenuBar = function (events)
        if gframework.topBar.openMenuId ~= 0 then
            gframework.topBar.blockItemGroup(true)
            local menuPosX = 2
            for key, value in pairs(gframework.topBar.menus) do
                if value.allowDisplay == true then
                    if key == gframework.topBar.openMenuId then
                        break
                    end
    
                    menuPosX = menuPosX + string.len(value.name) + 1
                end
            end

            for key, value in pairs(gframework.topBar.menus[gframework.topBar.openMenuId].items) do
                if events[3] >= menuPosX and events[3] <= menuPosX + string.len(value.name) - 1 and events[4] == key + 1 then
                    if value.func ~= nil then
                        value.func()
                    end
                end
            end
        end

        gframework.topBar.openMenuId = 0
    end,

    action = function (events)
        if next(gframework.topBar.menus) ~= nil then
            if events[1] == "mouse_click" then
                if events[4] == 1 then
                    gframework.topBar.clickOnMenuBar(events)
                else
                    gframework.topBar.clickOutsideMenuBar(events)
                end
            end
        end
    end
}

gframework.timer = {
    items = {},

    addTimer = function (sec, func)
        if type(func) == "function" and type(sec) == "number" then
            local timerId = os.startTimer(sec)
            gframework.timer.items[timerId] = func
        end
    end,

    action = function (events)
        if events[1] == "timer" then
            if gframework.timer.items[events[2]] ~= nil then
                gframework.timer.items[events[2]]()
                gframework.timer.items[events[2]] = nil
            end
        end
    end
}

gframeworkPrivate.collectedGroupItems = {}
gframework.collectItemGroups = function (...)
    gframeworkPrivate.collectedGroupItems = table.pack(...)
end

gframework.draw = function (...)
    local itemGroups = {...}

    gframework.term.termBackupReset(function ()
        gframework.term.screenBuffer.setCursorPos(1, 1)
        gframework.term.screenBuffer.setBackgroundColor(gframeworkPrivate.backgroundColor)
        gframework.term.screenBuffer.clear()
    end)

    if next(itemGroups) == nil and next(gframeworkPrivate.collectedGroupItems) ~= nil then
        itemGroups = gframeworkPrivate.collectedGroupItems
    end

    for key, value in pairs(itemGroups) do
        if type(value) == "table" and value.draw ~= nil and value.blockItemGroupForTopBar == false then
            value.draw()
        end
    end

    gframework.topBar.draw()

    gframework.term.screenBuffer.draw()
end

gframework.run = function (...)
    local itemGroups = {...}

    gframework.draw(...)

    if next(itemGroups) == nil and next(gframeworkPrivate.collectedGroupItems) ~= nil then
        itemGroups = gframeworkPrivate.collectedGroupItems
    end

    while true do
        local events = {gframework.kernelEventHandler.pullKernelEvent()}

        gframework.topBar.action(events)
        
        for key, value in pairs(itemGroups) do
            if type(value) == "table" and value.run ~= nil and value.blockItemGroupForTopBar == false then
                value.run(events)
            end
        end

        gframework.topBar.endAction()
        
        gframework.timer.action(events)

        gframeworkPrivate.hasBlinkNotBeenSet = true
    end
end

return gframework