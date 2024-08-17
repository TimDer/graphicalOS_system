local graphicalOs = require "/graphicalOS_system/main"

-- Clear the screen
term.clear()

-- Prepare the OS
graphicalOs.graphicalOsRootSettings.prepareGraphicalOsForBoot()

-- Get the current term to stop the os later
graphicalOs.stopTheOs.getCurrentTerm(term.current())

-- Backup configuration incase of an emergency
-- graphicalOs.kernel.addProgramToList("Shell", "/graphicalOS_system/programs/shell/main.lua", true)
-- graphicalOs.kernel.addProgramToList("Files", "/graphicalOS_system/programs/files.lua", true)
-- graphicalOs.kernel.AddTask("Desktop", "/graphicalOS_system/programs/Desktop/main.lua", true)

-- Load programs and tasks from the settings file
graphicalOs.kernel.loadProgramsAndTasksFromSettingsFile(false)

-- Start the desktop ENV
graphicalOs.kernel.runKernel()

-- End of the OS, clearing screen here
graphicalOs.stopTheOs.stopTheOs()