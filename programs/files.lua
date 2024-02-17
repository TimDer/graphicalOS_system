local files = {}
local windowWidth, windowHeight = term.getSize()
local miniWindowPosX = 0
local miniWindowPosY = 0
if windowWidth == 26 then
    miniWindowPosX = 12
elseif windowWidth == 39 then
    miniWindowPosX = 6
    miniWindowPosY = 2
end

files.gframework = require "/graphicalOS_system/apis/gframework"

files.gframework.term.setBackgroundColor(32768)

files.settings = {
    openAsKernel = true,
    mainItemGroup = files.gframework.createItemGroup(),
    createFileWindowItemGroup = files.gframework.createItemGroup(),
    deleteFileOrFolderItemGroup = files.gframework.createItemGroup(),
    renameFileOrFolderItemGroup = files.gframework.createItemGroup()
}

files.moveFile = {
    moveFileOrFolder = {
        location = "",
        fileOrFolderName = "",
        isClipboardEmpty = true,
        isCopy = false
    },

    paste = function ()
        if files.moveFile.moveFileOrFolder.isClipboardEmpty == false then
            local source = files.moveFile.moveFileOrFolder.location
            local destination = files.currentDirectory .. "/" .. files.moveFile.moveFileOrFolder.fileOrFolderName

            if files.moveFile.moveFileOrFolder.isCopy then
                fs.copy(source, destination)
            else
                fs.move(source, destination)
            end

            files.moveFile.moveFileOrFolder.location = ""
            files.moveFile.moveFileOrFolder.fileOrFolderName = ""
            files.moveFile.moveFileOrFolder.isClipboardEmpty = true
            files.moveFile.moveFileOrFolder.isCopy = false

            files.changeDirectory(files.currentDirectory)
            files.displayMessage("Success")
        else
            files.displayMessage("Error: Select a file or folder to move or copy")
        end
    end,

    move = function (isCopy)
        files.moveFile.moveFileOrFolder.fileOrFolderName = files.selectedFile.fileName
        files.moveFile.moveFileOrFolder.location = files.selectedFile.filePath
        files.moveFile.moveFileOrFolder.isClipboardEmpty = false
        
        if type(isCopy) == "boolean" then
            files.moveFile.moveFileOrFolder.isCopy = isCopy
        else
            files.moveFile.moveFileOrFolder.isCopy = false
        end
        
        files.displayMessage("Added to clipboard")
    end
}

files.displayMessage = function (messageString)
    files.mainFileBrowser.resizeFileBrowser(1, 3, windowWidth, windowHeight - 2)
    files.messageBox.setDisplayAllowed(true)
    files.fileManagerMessage.setDisplayAllowed(true)
    files.fileManagerMessage.setLabelName(messageString)
    files.gframework.timer.addTimer(2, function ()
        files.mainFileBrowser.resizeFileBrowser(1, 2, windowWidth, windowHeight - 1)
        files.messageBox.setDisplayAllowed(false)
        files.fileManagerMessage.setDisplayAllowed(false)
        files.fileManagerMessage.setLabelName("")
        files.gframework.draw()
    end)
end

files.openProgram = function (programName, pathToFile, openAsKernel)
    files.gframework.kernelEventHandler.kernelMethods.AddProgram(
        programName,
        pathToFile,
        openAsKernel,
        files.gframework.kernelEventHandler.kernelMethods.createWindow(
            files.gframework.kernelEventHandler.kernelData.rootTerm,
            1,
            2,
            windowWidth,
            windowHeight
        )
    )
end

files.limitFileNameLength = function (pathString)
    local newFilePath = ""

    if string.len(pathString) > 18 then
        newFilePath = string.sub(pathString, 1, 15) .. "..."
    else
        newFilePath = pathString
    end

    return newFilePath
end

files.createFileMiniWindow = function ()
    local isFile = true
    
    files.createFileWindow = files.settings.createFileWindowItemGroup.createMiniWindow("Create file", 16 - miniWindowPosX, 6 - miniWindowPosY, 20, 5, 128)
    files.createFileWindow.setOnWindowClose(function ()
        files.settings.mainItemGroup.excludeFromExecution(false)
        files.gframework.draw()
        files.changeDirectory(files.currentDirectory)
    end)
    files.createFileWindow.setOnWindowOpen(function ()
        files.settings.mainItemGroup.excludeFromExecution(true)
        files.settings.createFileWindowItemGroup.excludeFromExecution(false)
        files.settings.createFileWindowItemGroup.draw()
        files.gframework.term.screenBuffer.draw()
    end)
    files.settings.createFileWindowItemGroup.createRadioButton(
        files.gframework.createRadioButtonItem("File", 17 - miniWindowPosX, 10 - miniWindowPosY, 256, 128, 1, true, function (status)
            isFile = true
        end),
        files.gframework.createRadioButtonItem("Folder", 25 - miniWindowPosX, 10 - miniWindowPosY, 256, 128, 1, false, function (status)
            isFile = false
        end)
    )
    files.settings.createFileWindowItemGroup.createReadBar(17 - miniWindowPosX, 8 - miniWindowPosY, 18, 256, 1, function (fileName)
        if fs.exists(files.currentDirectory .. "/" .. fileName) == false then
            if isFile then
                local createFile = io.open(files.currentDirectory .. "/" .. fileName, "w")
                createFile:close()
                files.gframework.topBar.addFunctionAtTheEnd(files.createFileWindow.closeWindow)
            elseif isFile == false then
                fs.makeDir(files.currentDirectory .. "/" .. fileName)
                files.gframework.topBar.addFunctionAtTheEnd(files.createFileWindow.closeWindow)
            end
        end
    end)
    files.settings.createFileWindowItemGroup.excludeFromExecution(true)
end

files.deleteFileOrFolderMiniWindow = function ()
    files.deleteFileOrFolderWindow = files.settings.deleteFileOrFolderItemGroup.createMiniWindow("Delete", 16 - miniWindowPosX, 6 - miniWindowPosY, 20, 5, 128)
    files.deleteFileOrFolderWindow.setOnWindowClose(function ()
        files.settings.mainItemGroup.excludeFromExecution(false)
        files.fileOrFolderToBeDeleted.setLabelName("")
        files.changeDirectory(files.currentDirectory)
        files.gframework.draw()
        files.gframework.term.screenBuffer.draw()
    end)

    files.deleteFileOrFolderWindow.setOnWindowOpen(function ()
        files.settings.mainItemGroup.excludeFromExecution(true)
        files.settings.deleteFileOrFolderItemGroup.excludeFromExecution(false)
        files.fileOrFolderToBeDeleted.setLabelName(files.limitFileNameLength(files.selectedFile.fileName))
        files.settings.deleteFileOrFolderItemGroup.draw()
        files.gframework.term.screenBuffer.draw()
    end)

    files.fileOrFolderToBeDeleted = files.settings.deleteFileOrFolderItemGroup.createLabel("File", 17 - miniWindowPosX, 8 - miniWindowPosY, 128, 1)

    local deleteFileOrFolder = files.settings.deleteFileOrFolderItemGroup.createButton("Delete", 17 - miniWindowPosX, 10 - miniWindowPosY, 0, 16384, 1)
    deleteFileOrFolder.onClick(function ()
        fs.delete(files.currentDirectory .. "/" .. files.selectedFile.fileName)
        files.deleteFileOrFolderWindow.closeWindow()
    end)

    files.settings.deleteFileOrFolderItemGroup.excludeFromExecution(true)
end

files.renameFileOrFolderMiniWindow = function ()
    files.renameFileOrFolderWindow = files.settings.renameFileOrFolderItemGroup.createMiniWindow("Rename", 16 - miniWindowPosX, 6 - miniWindowPosY, 20, 3, 128)
    files.renameFileOrFolderWindow.setOnWindowClose(function ()
        files.settings.mainItemGroup.excludeFromExecution(false)
        files.changeDirectory(files.currentDirectory)
        files.gframework.draw()
        files.gframework.term.screenBuffer.draw()
    end)

    files.renameFileOrFolderWindow.setOnWindowOpen(function ()
        files.settings.mainItemGroup.excludeFromExecution(true)
        files.settings.renameFileOrFolderItemGroup.excludeFromExecution(false)
        files.settings.renameFileOrFolderItemGroup.draw()
        files.gframework.term.screenBuffer.draw()
    end)

    files.settings.renameFileOrFolderItemGroup.createReadBar(17 - miniWindowPosX, 8 - miniWindowPosY, 18, 256, 1, function (newFileName)
        files.gframework.topBar.addFunctionAtTheEnd(function ()
            if fs.exists(files.currentDirectory .. "/" .. newFileName) == false then
                fs.move(files.currentDirectory .. "/" .. files.selectedFile.fileName, files.currentDirectory .. "/" .. newFileName)
                files.renameFileOrFolderWindow.closeWindow()
            end
        end)
    end)

    files.settings.renameFileOrFolderItemGroup.excludeFromExecution(true)
end

files.topBarMenus = function ()
    files.gframework.topBar.settings.backgroundColor = 128
    files.gframework.topBar.excludeItemGroupsFromExecution(files.settings.mainItemGroup)
    files.topBar = {
        filesMenu = files.gframework.topBar.createTopBarMenu(
            "File",
            files.gframework.topBar.createTopBarMenuItem("Goto programs", function ()
                files.changeDirectory("/graphicalOS_data/programs")
                files.displayMessage("Went to programs directory")
            end),
            files.gframework.topBar.createTopBarMenuItem("Goto user_data", function ()
                files.changeDirectory("/graphicalOS_data/user_data")
                files.displayMessage("Went to user_data directory")
            end),
            files.gframework.topBar.createTopBarMenuItem("Goto CraftOS programs", function ()
                files.changeDirectory("/rom/programs")
                files.displayMessage("Went to rom/programs directory")
            end),
            files.gframework.topBar.createTopBarMenuItem("Create File", function ()
                files.gframework.topBar.addFunctionAtTheEnd(function ()
                    files.createFileWindow.openWindow()
                end)
            end),
            files.gframework.topBar.createTopBarMenuItem("Paste", function ()
                files.moveFile.paste()
            end)
        ),
        openAsMenu = files.gframework.topBar.createTopBarMenu(
            "Open-As",
            files.gframework.topBar.createTopBarMenuItem("kernel", function ()
                files.settings.openAsKernel = true
            end),
            files.gframework.topBar.createTopBarMenuItem("shell", function ()
                files.settings.openAsKernel = false
            end)
        ),
        openWithMenu = files.gframework.topBar.createTopBarMenu(
            "Open-With",
            files.gframework.topBar.createTopBarMenuItem("Edit", function ()
                if files.selectedFile.isAFolder == false then
                    files.openProgram("Edit " .. "\"" .. files.selectedFile.fileName .. "\"", "edit " .. files.selectedFile.filePath, false)
                end
            end),
            files.gframework.topBar.createTopBarMenuItem("Paint", function ()
                if files.selectedFile.isAFolder == false then
                    files.openProgram("Paint " .. "\"" .. files.selectedFile.fileName .. "\"", "paint " .. files.selectedFile.filePath, false)
                end
            end)
        ),
        fileOrFolderAction = files.gframework.topBar.createTopBarMenu(
            "Action",
            files.gframework.topBar.createTopBarMenuItem("Delete", function ()
                files.gframework.topBar.addFunctionAtTheEnd(function ()
                    files.deleteFileOrFolderWindow.openWindow()
                end)
            end),
            files.gframework.topBar.createTopBarMenuItem("Rename", function ()
                files.gframework.topBar.addFunctionAtTheEnd(function ()
                    files.renameFileOrFolderWindow.openWindow()
                end)
            end),
            files.gframework.topBar.createTopBarMenuItem("Move", function ()
                files.moveFile.move(false)
            end),
            files.gframework.topBar.createTopBarMenuItem("Copy", function ()
                files.moveFile.move(true)
            end)
        )
    }
    files.topBar.openWithMenu.allowDisplay(false)
    files.topBar.fileOrFolderAction.allowDisplay(false)
end

files.MessageArea = function ()
    files.messageBox = files.settings.mainItemGroup.createBox(1, 2, 2, 51, 1)
    files.messageBox.setDisplayAllowed(false)

    files.fileManagerMessage = files.settings.mainItemGroup.createLabel("", 1, 2, 2, 32768)
    files.fileManagerMessage.setDisplayAllowed(false)
end

files.fileBrowser = function ()
    files.selectedFile = {
        filePath = "/",
        fileName = "",
        isAFolder = true
    }

    files.currentDirectory = "/graphicalOS_data"
    files.changeDirectory = function (pathToNewDirecotry)
        files.currentDirectory = pathToNewDirecotry
        files.mainFileBrowser.changeDirectory(pathToNewDirecotry)
    end

    files.mainFileBrowser = files.settings.mainItemGroup.createFileBrowserBox(files.currentDirectory, 1, 2, windowWidth, windowHeight - 1, true)
    files.mainFileBrowser.setOnFileChangeFunc(function (file, isAFolder)
        files.selectedFile.filePath = file.path
        files.selectedFile.fileName = file.fileOrFolder
        files.selectedFile.isAFolder = isAFolder

        files.topBar.fileOrFolderAction.allowDisplay(true)

        if isAFolder == false then
            files.topBar.openWithMenu.allowDisplay(true)
        else
            files.topBar.openWithMenu.allowDisplay(false)
        end
    end)
    files.mainFileBrowser.setBoubleClickFunc(function (file, isAFolder)
        files.selectedFile.filePath = "/"
        files.selectedFile.fileName = file.fileOrFolder
        files.selectedFile.isAFolder = true

        if isAFolder == false then
            files.openProgram(file.fileOrFolder, file.path, files.settings.openAsKernel)
        else
            files.changeDirectory(file.path)
            files.topBar.openWithMenu.allowDisplay(false)
            files.topBar.fileOrFolderAction.allowDisplay(false)
        end
    end)
    files.mainFileBrowser.setBackBtnAction(function (file, isAFolder)
        files.changeDirectory(file)
        files.topBar.openWithMenu.allowDisplay(false)
        files.topBar.fileOrFolderAction.allowDisplay(false)
        files.selectedFile.filePath = file
        files.selectedFile.isAFolder = isAFolder
    end)
    files.mainFileBrowser.setOnUnselectItem(function ()
        files.topBar.openWithMenu.allowDisplay(false)
        files.topBar.fileOrFolderAction.allowDisplay(false)
        files.selectedFile.filePath = "/"
        files.selectedFile.isAFolder = ""
        files.selectedFile.isAFolder = true
    end)
end

files.createFileMiniWindow()
files.deleteFileOrFolderMiniWindow()
files.renameFileOrFolderMiniWindow()
files.topBarMenus()
files.MessageArea()
files.fileBrowser()

files.gframework.collectItemGroups(
    files.settings.mainItemGroup,
    files.settings.createFileWindowItemGroup,
    files.settings.deleteFileOrFolderItemGroup,
    files.settings.renameFileOrFolderItemGroup
)
files.gframework.run()
