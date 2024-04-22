-- GraphicalOS installer

local ginstaller = {}

ginstaller.downloader = function ()
    local downloader = {}

    downloader.downloadFileFromGithub = function (uri)
        if type(uri) == "string" then
            local request = http.get("https://raw.githubusercontent.com/TimDer/graphicalOS_system/main" .. uri)

            term.setTextColor(16384)
            term.write("Download: ")
            
            term.setTextColor(1)
            print("/graphicalOS_system" .. uri)

            local gosFile = fs.open("/graphicalOS_system" .. uri, "w")
            gosFile.write(request.readAll())
            gosFile.close()
        else
            error("File downloader requires a string", 1)
        end
    end

    downloader.setupFolders = function ()
        fs.makeDir("/graphicalOS_system")
        fs.makeDir("/graphicalOS_system/apis")
        fs.makeDir("/graphicalOS_system/programs")
        fs.makeDir("/graphicalOS_system/programs/Desktop")
        fs.makeDir("/graphicalOS_system/programs/shell")
        fs.makeDir("/graphicalOS_system/programs/shell/commands")
    end

    downloader.baseFiles = function ()
        downloader.downloadFileFromGithub("/kernel.lua")
        downloader.downloadFileFromGithub("/main.lua")
        downloader.downloadFileFromGithub("/startup.lua")
    end

    downloader.installFileBrowser = function ()
        downloader.downloadFileFromGithub("/programs/files.lua")
    end

    downloader.installShell = function ()
        downloader.downloadFileFromGithub("/programs/shell/completionFunctions.lua")
        downloader.downloadFileFromGithub("/programs/shell/main.lua")
        downloader.downloadFileFromGithub("/programs/shell/commands/kernel.lua")
        downloader.downloadFileFromGithub("/programs/shell/commands/gsettings.lua")
    end

    downloader.installDesktopEnv = function ()
        downloader.downloadFileFromGithub("/programs/Desktop/draw.lua")
        downloader.downloadFileFromGithub("/programs/Desktop/main.lua")
        downloader.downloadFileFromGithub("/programs/Desktop/startmenu.lua")
        downloader.downloadFileFromGithub("/programs/Desktop/taskbar.lua")
    end

    downloader.installApis = function ()
        downloader.downloadFileFromGithub("/apis/ListOfEvents.lua")
        downloader.downloadFileFromGithub("/apis/gframework.lua")
        downloader.downloadFileFromGithub("/apis/kernelEventHandler.lua")
        downloader.downloadFileFromGithub("/apis/settings.lua")
        downloader.downloadFileFromGithub("/apis/stop.lua")
        downloader.downloadFileFromGithub("/apis/uuid.lua")
        downloader.downloadFileFromGithub("/apis/ascii.lua")
        downloader.downloadFileFromGithub("/apis/json.lua")
        downloader.downloadFileFromGithub("/apis/loadFile.lua")
        downloader.downloadFileFromGithub("/apis/configuration.lua")
    end

    downloader.run = function ()
        term.clear()
        term.setCursorPos(1, 1)
        
        if fs.isDir("/graphicalOS_system") == false then
            downloader.setupFolders()
            downloader.baseFiles()
            downloader.installFileBrowser()
            downloader.installShell()
            downloader.installDesktopEnv()
            downloader.installApis()

            shell.run("/graphicalOS_system/programs/shell/commands/gsettings.lua startup true")
        end
    end

    downloader.run()
end

ginstaller.downloaderUI = function (uiList)
    local ui = {}

    ui.isRunning = true

    ui.installerList = uiList

    ui.draw = function ()
        local sizeX, sizeY = term.getSize()
        
        term.clear()
        term.setCursorPos(2, 1)
        term.write("GraphicalOS Installer")

        for sizePosX = 1, sizeX, 1 do
            term.setCursorPos(sizePosX, 2)
            term.write("-")
        end

        for key, value in pairs(ui.installerList) do
            term.setCursorPos(3, 3 + key)

            if value.selected then
                term.write("> " .. value.name)
            else
                term.write("  " .. value.name)
            end
        end
    end

    ui.getSelectedNum = function ()
        local selectedNum = 1

        for key, value in pairs(ui.installerList) do
            if value.selected then
                selectedNum = key
            end
        end

        return selectedNum
    end

    ui.selectAction = function (events)
        local selectedNum = ui.getSelectedNum()
        ui.installerList[selectedNum].selected = false

        if events[2] == 264 and selectedNum < #ui.installerList then
            selectedNum = selectedNum + 1
        elseif events[2] == 265 and selectedNum > 1 then
            selectedNum = selectedNum - 1
        end

        ui.installerList[selectedNum].selected = true

        ui.draw()
    end

    ui.runAction = function ()
        local selectedNum = ui.getSelectedNum()

        ui.isRunning = false
        ui.installerList[selectedNum].action()
    end

    ui.run = function ()
        ui.draw()

        while ui.isRunning do
            local events = {os.pullEventRaw()}

            if events[1] == "key" then
                if events[2] == 265 or events[2] == 264 then
                    ui.selectAction(events)
                elseif events[2] == 257 or events[2] == 335 then
                    ui.runAction()
                end
            end
        end
    end

    ui.run()
end

ginstaller.runAll = function ()
    local runner = {}

    runner.actionTaken = ""

    runner.quitAction = {
        name = "Quit",
        selected = false,
        action = function ()
            term.clear()
            term.setCursorPos(1, 1)

            runner.actionTaken = "quit"
        end
    }

    ginstaller.downloaderUI(
        {
            {
                name = "Install",
                selected = true,
                action = function ()
                    ginstaller.downloader()

                    runner.actionTaken = "install"
                end
            },
            runner.quitAction
        }
    )

    if runner.actionTaken == "install" then
        ginstaller.downloaderUI(
            {
                {
                    name = "Reboot",
                    selected = true,
                    action = function ()
                        os.reboot()
                    end
                },
                runner.quitAction
            }
        )
    end
end

ginstaller.runAll()