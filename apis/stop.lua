local returnFunctions = {}
local data = {}

function returnFunctions.stopTheOs()
    term.redirect(data.currentTerm)
    term.setBackgroundColor(32768)
    for posIterator = 1,19
    do
        term.setCursorPos(1,posIterator)
        term.clearLine()
    end
    term.setCursorPos(1,1)
end

function returnFunctions.getCurrentTerm(currentTerm)
    data.currentTerm = currentTerm
end

return returnFunctions