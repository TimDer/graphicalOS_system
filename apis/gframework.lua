local gframework = {}
local gframeworkPrivate = {}

gframework.kernelEventHandler = require "/graphicalOS_system/apis/kernelEventHandler"

gframeworkPrivate.backgroundColor = 1
gframeworkPrivate.hasBlinkNotBeenSet = true

gframework.term = {
    setBackgroundColor = function (colorNumber)
        gframeworkPrivate.backgroundColor = colorNumber
    end,

    setCursorBlink = function (bool)
        if gframeworkPrivate.hasBlinkNotBeenSet == true and bool == true then
            gframeworkPrivate.hasBlinkNotBeenSet = false
            term.setCursorBlink(bool)
        elseif bool == false then
            gframeworkPrivate.hasBlinkNotBeenSet = true
            term.setCursorBlink(bool)
        end
    end,

    termBackup = function ()
        local currentPosX, currentPosY = term.getCursorPos()
    
        return {
            backgroundColor = term.getBackgroundColor(),
            textColor = term.getTextColor(),
            X = currentPosX,
            Y = currentPosY,
            term = term.current()
        }
    end,

    termReset = function (backup)
        term.setBackgroundColor(backup.backgroundColor)
        term.setTextColor(backup.textColor)
        term.setCursorPos(backup.X, backup.Y)
        term.redirect(backup.term)
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
    end
}

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

gframework.createAction = function (action)
    return coroutine.create(function ()
        while true do
            local events = {os.pullEventRaw()}

            if type(action) == "function" then
                action(events)
            end
        end
    end)
end

gframework.createRadioButtonItem = function (radioButtonName, radioButtonPosX, radioButtonPosY, radioButtonBackgroundColor, radioButtonLabelBackgroundColor, radioButtonTextColor, checked, actionFunc)
    local radioButtonItem = {}

    radioButtonItem.checked = checked
    radioButtonItem.radioButtonPosX = radioButtonPosX
    radioButtonItem.radioButtonPosY = radioButtonPosY

    radioButtonItem.draw = gframework.term.createDraw(function ()
        term.setBackgroundColor(radioButtonLabelBackgroundColor)
        term.setTextColor(radioButtonTextColor)
        term.setCursorPos(radioButtonPosX + 2, radioButtonPosY)
        term.write(radioButtonName)

        term.setBackgroundColor(radioButtonBackgroundColor)
        term.setCursorPos(radioButtonPosX, radioButtonPosY)
        if radioButtonItem.checked == true then
            term.write("X")
        else
            term.write(" ")
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

    itemGroup.createFileBrowserBox = function (fileBrowserBoxPath, fileBrowserBoxPosX, fileBrowserBoxPosY, fileBrowserBoxWidth, fileBrowserBoxHeight, backBtnEnabled)
        local fileBrowserBoxItem = {}
        local fileBrowserBoxReturn = {}

        local xSize, ySize = term.getSize()

        fileBrowserBoxItem.currentPath = fileBrowserBoxPath
        fileBrowserBoxItem.sizeX = xSize
        fileBrowserBoxItem.sizeY = ySize
        fileBrowserBoxItem.directoryTable = {}
        fileBrowserBoxItem.directoryTableCurrentTopKey = 0
        fileBrowserBoxItem.selectedFileOrFolder = 0
        fileBrowserBoxItem.isDoubleClickEnabled = false
        fileBrowserBoxItem.isBackBtnEnabled = backBtnEnabled

        fileBrowserBoxItem.fileBrowserBoxOnFileChange = function (file, isAFolder) end
        fileBrowserBoxItem.fileBrowserBoxDoubleClick = function (file, isAFolder) end

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
            term.setBackgroundColor(256)

            for indexHeight = fileBrowserBoxPosY, fileBrowserBoxPosY + fileBrowserBoxHeight - 1, 1 do
                for indexWidth = fileBrowserBoxPosX, fileBrowserBoxPosX + fileBrowserBoxWidth - 1, 1 do
                    term.setCursorPos(indexWidth, indexHeight)
                    term.write(" ")
                end

                term.setBackgroundColor(1)
            end

            local pathPlusPosX = 0
            if fileBrowserBoxItem.isBackBtnEnabled == true then
                pathPlusPosX = 2
                term.setBackgroundColor(128)
                term.setCursorPos(fileBrowserBoxPosX, fileBrowserBoxPosY)
                term.write("<-")
            end

            term.setBackgroundColor(256)
            term.setCursorPos(fileBrowserBoxPosX + pathPlusPosX, fileBrowserBoxPosY)
            term.write(string.sub(fileBrowserBoxItem.currentPath, 1, fileBrowserBoxItem.sizeX - 2))

            if fileBrowserBoxItem.directoryTableCurrentTopKey ~= 0 then
                term.setBackgroundColor(1)
                term.setTextColor(32768)
                
                for fileIndex = fileBrowserBoxItem.directoryTableCurrentTopKey, fileBrowserBoxItem.directoryTableCurrentTopKey + fileBrowserBoxHeight - 2, 1 do
                    if fileBrowserBoxItem.directoryTable[fileIndex] == nil then
                        break
                    end

                    if fileBrowserBoxItem.selectedFileOrFolder == fileIndex then
                        for selectedIndexPosX = fileBrowserBoxPosX, fileBrowserBoxPosX + fileBrowserBoxWidth - 1, 1 do
                            term.setCursorPos(selectedIndexPosX, fileBrowserBoxPosY + fileIndex - (fileBrowserBoxItem.directoryTableCurrentTopKey - 1))
                            term.setBackgroundColor(2048)
                            term.write(" ")
                        end
                    else
                        term.setBackgroundColor(1)
                    end

                    term.setCursorPos(fileBrowserBoxPosX, fileBrowserBoxPosY + fileIndex - (fileBrowserBoxItem.directoryTableCurrentTopKey - 1))
                    if fileBrowserBoxItem.directoryTable[fileIndex].type == "folder" then
                        term.write("[=] " .. fileBrowserBoxItem.directoryTable[fileIndex].name)
                    else
                        term.write("[+] " .. fileBrowserBoxItem.directoryTable[fileIndex].name)
                    end
                end
            end
        end)
        fileBrowserBoxItem.unselectItem = function (events)
            if (events[4] >= fileBrowserBoxPosY + 1 and events[4] <= fileBrowserBoxPosY + fileBrowserBoxHeight - 1) == false then
                local redrawFileBox = false
                if fileBrowserBoxItem.selectedFileOrFolder >= 1 then
                    redrawFileBox = true
                end

                fileBrowserBoxItem.selectedFileOrFolder = 0

                if redrawFileBox then
                    fileBrowserBoxItem.draw()
                end
            end
        end

        fileBrowserBoxItem.clickOnFile = function (events)
            if events[4] >= fileBrowserBoxPosY + 1 and events[4] <= fileBrowserBoxPosY + fileBrowserBoxHeight - 1 and fileBrowserBoxItem.directoryTableCurrentTopKey >= 1 then
                for fileIndex = fileBrowserBoxItem.directoryTableCurrentTopKey, fileBrowserBoxItem.directoryTableCurrentTopKey + fileBrowserBoxHeight - 2, 1 do
                    if fileBrowserBoxItem.directoryTable[fileIndex] == nil then
                        break
                    end

                    if (fileIndex - (fileBrowserBoxItem.directoryTableCurrentTopKey - 1)) == events[4] - fileBrowserBoxPosY then
                        fileBrowserBoxItem.selectedFileOrFolder = fileIndex
                        fileBrowserBoxItem.draw()

                        local ifIsAFolder = false
                        if fileBrowserBoxItem.directoryTable[fileIndex].type == "folder" then
                            ifIsAFolder = true
                        end

                        local pathTofileOrFolder = "/"
                        if fileBrowserBoxItem.currentPath ~= "/" then
                            pathTofileOrFolder = fileBrowserBoxItem.currentPath .. "/" .. fileBrowserBoxItem.directoryTable[fileIndex].name
                        else
                            pathTofileOrFolder = "/" .. fileBrowserBoxItem.directoryTable[fileIndex].name
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

        fileBrowserBoxItem.action = gframework.createAction(function (events)
            if events[1] == "mouse_scroll" and #fileBrowserBoxItem.directoryTable >= (fileBrowserBoxHeight - 1) then
                if events[3] >= fileBrowserBoxPosX and events[3] <= fileBrowserBoxPosX + fileBrowserBoxWidth - 1 and events[4] >= fileBrowserBoxPosY + 1 and events[4] <= fileBrowserBoxPosY + fileBrowserBoxHeight - 1 then
                    if events[2] == -1 and fileBrowserBoxItem.directoryTableCurrentTopKey - 1 >= 1 then
                        fileBrowserBoxItem.directoryTableCurrentTopKey = fileBrowserBoxItem.directoryTableCurrentTopKey - 1
                        fileBrowserBoxItem.draw()
                    elseif events[2] == 1 and fileBrowserBoxItem.directoryTableCurrentTopKey + 1 <= #fileBrowserBoxItem.directoryTable - fileBrowserBoxHeight + 2 then
                        fileBrowserBoxItem.directoryTableCurrentTopKey = fileBrowserBoxItem.directoryTableCurrentTopKey + 1
                        fileBrowserBoxItem.draw()
                    end
                end
            elseif events[1] == "mouse_click" then
                if events[3] >= fileBrowserBoxPosX and events[3] <= fileBrowserBoxPosX + fileBrowserBoxWidth - 1 and events[4] >= fileBrowserBoxPosY and events[4] <= fileBrowserBoxPosY + fileBrowserBoxHeight - 1 then
                    fileBrowserBoxItem.clickOnFile(events)
                end

                if events[3] >= fileBrowserBoxPosX and events[3] <= fileBrowserBoxPosX + 1 and events[4] == fileBrowserBoxPosY then
                    if type(fileBrowserBoxItem.fileBrowserBoxDoubleClick) == "function" and fileBrowserBoxItem.isBackBtnEnabled == true then
                        fileBrowserBoxItem.fileBrowserBoxDoubleClick("/" .. shell.resolve(fileBrowserBoxItem.currentPath .. "/.."), true)
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

        table.insert(itemGroup.items, fileBrowserBoxItem)
        return fileBrowserBoxReturn
    end
    
    itemGroup.createButton = function (nameString, X, Y, margin, backgroundColor, textColor, actionFunc)
        local button = {}
        local buttonPrivate = {}

        button.startX = X
        button.Y = Y
        button.endX = X + string.len(nameString) - 1

        button.marginStartX = button.startX - margin
        button.marginStartY = button.Y - margin
        button.marginEndX = button.endX + margin
        button.marginEndY = button.Y + margin

        button.draw = gframework.term.createDraw(function ()
            term.setCursorPos(button.startX, button.Y)
            term.setBackgroundColor(backgroundColor)
            term.setTextColor(textColor)
            for indexLineY = button.marginStartY, button.marginEndY, 1 do
                for indexLineX = button.marginStartX, button.marginEndX, 1 do
                    term.setCursorPos(indexLineX, indexLineY)
                    term.write(" ")
                end
            end
            
            term.setCursorPos(button.startX, button.Y)
            term.write(nameString)
        end)

        button.action = gframework.createAction(function (events)
            if events[1] == "mouse_click" then
                if events[3] >= button.marginStartX and events[3] <= button.marginEndX and events[4] >= button.marginStartY and events[4] <= button.marginEndY then
                    actionFunc()
                end
            end
        end)

        table.insert(itemGroup.items, button)
    end

    itemGroup.createBox = function (boxPosX, boxPosY, boxColor, boxWidth, boxHight)
        local boxItem = {}

        boxItem.draw = gframework.term.createDraw(function ()
            term.setBackgroundColor(boxColor)

            for indexPosY = boxPosY, boxPosY + boxHight - 1, 1 do
                for indexPosX = boxPosX, boxPosX + boxWidth - 1, 1 do
                    term.setCursorPos(indexPosX, indexPosY)
                    term.write(" ")
                end
            end
        end)

        table.insert(itemGroup.items, boxItem)
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

        radioButtonItem.action = gframework.createAction(function (events)
            local currentCheckedKey = radioButtonItem.getCurrentCheckedKey()
            local newChecked = radioButtonItem.changeCurrentCheckedKey(currentCheckedKey, events)

            if newChecked.radioButtonHasChanged then
                radioButtonItem.draw()
                radioButtonItem.buttonsList[newChecked.radioButtonChangedToKey].action()
            end
        end)

        table.insert(itemGroup.items, radioButtonItem)
    end

    itemGroup.createCheckBox = function (checkBoxName, checkBoxPosX, checkBoxPosY, checkBoxBackgroundColor, checkBoxLabelBackgroundColor, checkBoxTextColor, checked, actionFunc)
        local checkBoxItem = {}

        checkBoxItem.checked = checked

        checkBoxItem.draw = gframework.term.createDraw(function ()
            term.setBackgroundColor(checkBoxLabelBackgroundColor)
            term.setTextColor(checkBoxTextColor)
            term.setCursorPos(checkBoxPosX + 2, checkBoxPosY)
            term.write(checkBoxName)

            term.setBackgroundColor(checkBoxBackgroundColor)
            term.setCursorPos(checkBoxPosX, checkBoxPosY)
            if checkBoxItem.checked == true then
                term.write("#")
            else
                term.write(" ")
            end
        end)

        checkBoxItem.action = gframework.createAction(function (events)
            if events[1] == "mouse_click" then
                if events[3] == checkBoxPosX and events[4] == checkBoxPosY then
                    if checkBoxItem.checked == true then
                        checkBoxItem.checked = false
                        checkBoxItem.draw()
                    else
                        checkBoxItem.checked = true
                        checkBoxItem.draw()
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

        labelItem.draw = gframework.term.createDraw(function ()
            if labelItem.labelDisplayAllowed == true then
                term.setBackgroundColor(labelBackgroundColor)
                term.setTextColor(labelTextColor)
                term.setCursorPos(labelPosX, labelPosY)
                term.write(labelName)
            end
        end)

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
            term.setCursorPos(readBarPosX, readBarPosY)
            term.setBackgroundColor(readBarBackgroundColor)
            term.setTextColor(readBarTextColor)
            for i = readBarPosX, readBarPosX + readBarWidth - 1, 1 do
                term.setCursorPos(i, readBarPosY)
                term.write(" ")
            end

            local startNum = readBarItem.getStartReadBarNumber()
            term.setCursorPos(readBarPosX, readBarPosY)
            term.write( string.sub(readBarItem.readString, startNum, string.len(readBarItem.readString)) )
        end)

        readBarItem.openOrCloseReadBar = function (events)
            if events[1] == "mouse_click" then
                local ifClickInReadBar = (events[3] >= readBarPosX and events[3] <= readBarPosX + readBarWidth - 1 and events[4] == readBarPosY)

                if ifClickInReadBar then
                    if readBarItem.isReadBarOpen == false then
                        readBarItem.oldTermData = gframework.term.termBackup()
                    end
                    readBarItem.isReadBarOpen = true
                    term.setTextColor(readBarTextColor)
                    term.setCursorPos(readBarPosX + readBarItem.getCursorBlinkPos(), readBarPosY)
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
                term.setCursorPos(readBarPosX + readBarItem.getCursorBlinkPos(), readBarPosY)
            end
        end

        readBarItem.action = gframework.createAction(function (events)
            if gframeworkPrivate.hasBlinkNotBeenSet == true then
                readBarItem.openOrCloseReadBar(events)
                readBarItem.typeKeysIntoTheInput(events)
            else
                readBarItem.isReadBarOpen = false
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
                    coroutine.resume(value.action, table.unpack(events))
                end
            end
        end
    end

    return itemGroup
end

gframeworkPrivate.topBar = {
    excludeItemGroupsFromExecutionTable = {},
    isMenuOpen = false
}
gframework.topBar = {
    menus = {},
    openMenuId = 0,
    
    settings = {
        backgroundColor = 256,
        textColor = 1
    },

    createTopBarMenuItem = function (itemName, func)
        return {
            name = itemName,
            func = func
        }
    end,

    createTopBarMenu = function (menuName, ...)
        table.insert(gframework.topBar.menus, {
            name = menuName,
            items = {...}
        })
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
            term.setCursorPos(1, 1)
            term.setBackgroundColor(gframework.topBar.settings.backgroundColor)
            term.setTextColor(gframework.topBar.settings.textColor)
            term.clearLine()
        
            if next(gframework.topBar.menus) ~= nil then
                local titlePosX = 2
                for menuKey, menuValue in pairs(gframework.topBar.menus) do
                    if type(menuValue.name) == "string" then
                        term.setCursorPos(titlePosX, 1)
                        term.write(menuValue.name)
        
                        if menuKey == gframework.topBar.openMenuId then
                            local longestString = string.len(menuValue.name)
                            for itemKey, itemValue in pairs(gframework.topBar.menus[menuKey].items) do
                                if string.len(itemValue.name) > longestString then
                                    longestString = string.len(itemValue.name)
                                end
                            end

                            for itemKey, itemValue in pairs(gframework.topBar.menus[menuKey].items) do
                                for menuBackgroundPosX = titlePosX - 1, titlePosX + longestString, 1 do
                                    term.setCursorPos(menuBackgroundPosX, itemKey + 1)
                                    term.write(" ")
                                end

                                term.setCursorPos(titlePosX, itemKey + 1)
                                term.write(itemValue.name)
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
        if gframeworkPrivate.topBar.isMenuOpen == true then
            gframework.topBar.blockItemGroup(false)
            gframework.draw()
        end

        if gframework.topBar.openMenuId == 0 and next(gframework.topBar.menus) ~= nil then
            gframeworkPrivate.topBar.isMenuOpen = false
        end
    end,

    action = function (events)
        if next(gframework.topBar.menus) ~= nil then
            if events[1] == "mouse_click" then
                local drawFunc = function ()
                    gframework.topBar.blockItemGroup(false)
                    gframework.draw()
                    gframework.topBar.blockItemGroup(true)
                end
    
                if events[4] == 1 then
                    gframework.topBar.blockItemGroup(true)
    
                    local titlePosX = 2
                    for key, value in pairs(gframework.topBar.menus) do
                        if type(value.name) == "string" then
                            if events[3] >= titlePosX and events[3] <= titlePosX + string.len(value.name) - 1 then
                                gframework.topBar.openMenuId = key
                                gframeworkPrivate.topBar.isMenuOpen = true
                                drawFunc()
                                break
                            else
                                gframework.topBar.openMenuId = 0
                                drawFunc()
                            end
    
                            titlePosX = titlePosX + string.len(value.name) + 1
                        end
                    end
                else
                    if gframework.topBar.openMenuId ~= 0 then
                        gframework.topBar.blockItemGroup(true)
                        local menuPosX = 2
                        for key, value in pairs(gframework.topBar.menus) do
                            if key == gframework.topBar.openMenuId then
                                break
                            end

                            menuPosX = menuPosX + string.len(value.name) + 1
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
        term.setCursorPos(1, 1)
        term.setBackgroundColor(gframeworkPrivate.backgroundColor)
        term.clear()
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
end

gframework.run = function (...)
    local itemGroups = {...}

    gframework.draw(...)

    if next(itemGroups) == nil and next(gframeworkPrivate.collectedGroupItems) ~= nil then
        itemGroups = gframeworkPrivate.collectedGroupItems
    end

    while true do
        local events = {gframework.kernelEventHandler.pullKernelEvent()}

        if events[1] ~= "timer" then
            gframework.topBar.action(events)
        
            for key, value in pairs(itemGroups) do
                if type(value) == "table" and value.run ~= nil and value.blockItemGroupForTopBar == false then
                    value.run(events)
                end
            end

            gframework.topBar.endAction()
        else
            gframework.timer.action(events)
        end
        

        gframeworkPrivate.hasBlinkNotBeenSet = true
    end
end

return gframework