local graphicalOsRootSettings = {}

graphicalOsRootSettings.user_data_dir = "/graphicalOS_data/user_data"
graphicalOsRootSettings.programs_dir = "/graphicalOS_data/programs"
graphicalOsRootSettings.user_profile_dir = "/graphicalOS_data/users"
graphicalOsRootSettings.settings_start_dir = "/graphicalOS_data/system-programs/settings/start"

graphicalOsRootSettings.file_exists = function(name)
    local f=io.open(name,"r")
    if f~=nil then
        io.close(f) 
        return true
    else
        return false
    end
end

graphicalOsRootSettings.delete_file_exists = function(name)
    if graphicalOsRootSettings.file_exists(name) then
        fs.delete(name)
    end
end

graphicalOsRootSettings.prepareGraphicalOsForBoot = function()
    term.clear()
    term.setBackgroundColor(8)
    term.setTextColor(1)

    if fs.isDir("/graphicalOS_data") == false then
        fs.makeDir("/graphicalOS_data")
        fs.makeDir("/graphicalOS_data/user_data")
        fs.makeDir("/graphicalOS_data/programs")
        fs.makeDir("/graphicalOS_data/users")
    end
end

return graphicalOsRootSettings