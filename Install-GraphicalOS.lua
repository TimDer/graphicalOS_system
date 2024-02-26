-- GraphicalOS installer

local ginstaller = {}

ginstaller.downloadFileFromGithub = function (uri)
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

ginstaller.setupFolders = function ()
    fs.makeDir("/graphicalOS_system")
    fs.makeDir("/graphicalOS_system/apis")
    fs.makeDir("/graphicalOS_system/programs")
    fs.makeDir("/graphicalOS_system/programs/Desktop")
    fs.makeDir("/graphicalOS_system/programs/shell")
    fs.makeDir("/graphicalOS_system/programs/shell/commands")
end

ginstaller.baseFiles = function ()
    ginstaller.downloadFileFromGithub("/kernel.lua")
    ginstaller.downloadFileFromGithub("/main.lua")
    ginstaller.downloadFileFromGithub("/startup.lua")
end

ginstaller.installFileBrowser = function ()
    ginstaller.downloadFileFromGithub("/programs/files.lua")
end

ginstaller.installShell = function ()
    ginstaller.downloadFileFromGithub("/programs/shell/completionFunctions.lua")
    ginstaller.downloadFileFromGithub("/programs/shell/main.lua")
    ginstaller.downloadFileFromGithub("/programs/shell/commands/gsettings.lua")
    ginstaller.downloadFileFromGithub("/programs/shell/commands/rungraphicalos.lua")
end

ginstaller.installDesktopEnv = function ()
    ginstaller.downloadFileFromGithub("/programs/Desktop/draw.lua")
    ginstaller.downloadFileFromGithub("/programs/Desktop/main.lua")
    ginstaller.downloadFileFromGithub("/programs/Desktop/startmenu.lua")
    ginstaller.downloadFileFromGithub("/programs/Desktop/taskbar.lua")
end

ginstaller.installApis = function ()
    ginstaller.downloadFileFromGithub("/apis/ListOfEvents.lua")
    ginstaller.downloadFileFromGithub("/apis/gframework.lua")
    ginstaller.downloadFileFromGithub("/apis/kernelEventHandler.lua")
    ginstaller.downloadFileFromGithub("/apis/settings.lua")
    ginstaller.downloadFileFromGithub("/apis/stop.lua")
    ginstaller.downloadFileFromGithub("/apis/uuid.lua")
end

ginstaller.run = function ()
    if fs.isDir("/graphicalOS_system") == false then
        ginstaller.setupFolders()
        ginstaller.baseFiles()
        ginstaller.installFileBrowser()
        ginstaller.installShell()
        ginstaller.installDesktopEnv()
        ginstaller.installApis()

        shell.run("/graphicalOS_system/programs/shell/commands/gsettings.lua startup true")
    end
end

ginstaller.run()