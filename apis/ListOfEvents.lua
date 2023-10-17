local events = {}
local eventsPrivate = {}

eventsPrivate.craftOsEvents = {}

eventsPrivate.craftOsEvents[1] = "alarm"
eventsPrivate.craftOsEvents[2] = "char"
eventsPrivate.craftOsEvents[3] = "computer_command"
eventsPrivate.craftOsEvents[4] = "disk"
eventsPrivate.craftOsEvents[5] = "disk_eject"
eventsPrivate.craftOsEvents[6] = "file_transfer"
eventsPrivate.craftOsEvents[7] = "http_check"
eventsPrivate.craftOsEvents[8] = "http_failure"
eventsPrivate.craftOsEvents[9] = "http_success"
eventsPrivate.craftOsEvents[10] = "key"
eventsPrivate.craftOsEvents[11] = "key_up"
eventsPrivate.craftOsEvents[12] = "modem_message"
eventsPrivate.craftOsEvents[13] = "monitor_resize"
eventsPrivate.craftOsEvents[14] = "monitor_touch"
eventsPrivate.craftOsEvents[15] = "mouse_click"
eventsPrivate.craftOsEvents[16] = "mouse_drag"
eventsPrivate.craftOsEvents[17] = "mouse_scroll"
eventsPrivate.craftOsEvents[18] = "mouse_up"
eventsPrivate.craftOsEvents[19] = "paste"
eventsPrivate.craftOsEvents[20] = "peripheral"
eventsPrivate.craftOsEvents[21] = "peripheral_detach"
eventsPrivate.craftOsEvents[22] = "rednet_message"
eventsPrivate.craftOsEvents[23] = "redstone"
eventsPrivate.craftOsEvents[24] = "speaker_audio_empty"
eventsPrivate.craftOsEvents[25] = "task_complete"
eventsPrivate.craftOsEvents[26] = "term_resize"
eventsPrivate.craftOsEvents[27] = "terminate"
eventsPrivate.craftOsEvents[28] = "timer"
eventsPrivate.craftOsEvents[29] = "turtle_inventory"
eventsPrivate.craftOsEvents[30] = "websocket_closed"
eventsPrivate.craftOsEvents[31] = "websocket_failure"
eventsPrivate.craftOsEvents[32] = "websocket_message"
eventsPrivate.craftOsEvents[33] = "websocket_success"

function events.isEventFromCraftOs(eventString)
    local isFromCraftOs = false

    for _, value in pairs(eventsPrivate.craftOsEvents) do
        if value == eventString then
            isFromCraftOs = true
            break
        end
    end

    return isFromCraftOs
end

function events.isEventNotFromCraftOs(eventString)
    local isNotFromCraftOs = true

    if events.isEventFromCraftOs(eventString) == false then
        isNotFromCraftOs = false
    end

    return isNotFromCraftOs
end

function events.IsEventFromGraphicalOs(eventString)
    local doesEventStartWith = "graphicalOS_"

    return string.sub(eventString, 1, string.len(doesEventStartWith)) == doesEventStartWith
end

function events.IsEventNotFromGraphicalOs(eventString)
    local isNotFromGraphicalOs = true

    if events.IsEventFromGraphicalOs(eventString) then
        isNotFromGraphicalOs = false
    end

    return isNotFromGraphicalOs
end

function events.createGraphicalOsEventString(eventString)
    local newEventString = "graphicalOS_" .. eventString

    return newEventString
end

return events