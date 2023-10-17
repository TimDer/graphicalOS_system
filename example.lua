local graphicalOs = require "/graphicalOS_system/main"

-- Clear the screen
term.clear()

-- Prepare the OS
graphicalOs.graphicalOsRootSettings.prepareGraphicalOsForBoot()

-- Get the current term to stop the os later
graphicalOs.stopTheOs.getCurrentTerm(term.current())

-- Start the desktop ENV
graphicalOs.kernel.addProgramToList("Shell", "/graphicalOS_system/programs/testProgram/main.lua", false)
graphicalOs.kernel.AddTask("/graphicalOS_system/programs/Desktop/main.lua", true)
graphicalOs.kernel.runKernel()

-- End of the OS, clearing screen here
--graphicalOs.stopTheOs.stopTheOs()