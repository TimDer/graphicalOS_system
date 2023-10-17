local basicFunctions = {}

basicFunctions.runDesktop = true
basicFunctions.desktopOption = "desktop"

-- Function menu
function basicFunctions.drawStartMenu()
    basicFunctions.desktopOption = "StartMenu"

    term.setTextColor(1)
    term.setBackgroundColor(32768)
    term.setCursorPos(1,2)
    print("            ")
    term.setCursorPos(1,3)
    print(" REBOOT     ")
    term.setCursorPos(1,4)
    print(" SHUTDOWN   ")
    term.setCursorPos(1,5)
    print("            ")
    term.setCursorPos(1,6)
    print(" Programs > ")
    term.setCursorPos(1,7)
    print(" files      ")
    term.setCursorPos(1,8)
    print(" Shell      ")
    term.setCursorPos(1,9)
    print("            ")
end

function basicFunctions.btnStartMenu()
    if event == "mouse_click" then
        -- exit start menu code
            -- next to start menu
            if X>=13 and Y>=2 and button==1 then
                basicFunctions.exitToDesktop()
            -- under start menu
            elseif X>=1 and Y>=10 and button==1 then
                basicFunctions.exitToDesktop()
            -- menu bar
            elseif X>=1 and Y==1 and button==1 then
                basicFunctions.exitToDesktop()
            end
        -- /exit start menu code

        -- Programs
            -- reboot
            if X>=1 and X<=12 and Y==3 and button==1 then
                os.reboot()
            -- shutdown
            elseif X>=1 and X<=12 and Y==4 and button==1 then
                os.shutdown()
            -- Programs
            elseif X>=1 and X<=12 and Y==6 and button==1 then
                -- code
            -- files
            elseif X>=1 and X<=12 and Y==7 and button==1 then
                -- code
            -- settings
            elseif X>=1 and X<=12 and Y==8 and button==1 then
                basicFunctions.runDesktop = false
            end
        -- /Programs
    end
end
-- /Function menu

-- Functions file_exists
function basicFunctions.file_exists(name)
    local f=io.open(name,"r")
    if f~=nil then
        io.close(f) 
        return true
    else
        return false
    end
end

function basicFunctions.delete_file_exists(name)
    if basicFunctions.file_exists(name) then
        fs.delete(name)
    end
end
-- /Functions file_exists

return basicFunctions