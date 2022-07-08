local _, addon = ...

function addon.ErrorsFrame_AddMessage(self, msg, ...)
    
    if (addon.isEmpty(msg)) then
        msg = "unknown"
    end
    
    local lowermsg = string.lower(msg)
    local contains = addon.tableContains
    local standardErrorMessages = addon.standardErrorMessages()

    if (contains(standardErrorMessages, lowermsg)) then
        return;
    end

    return self:Original_AddMessage(msg, ...);
end

function addon.HookErrorsFrame()
    local ef = getglobal("UIErrorsFrame");
    ef.Original_AddMessage = ef.AddMessage;
    ef.AddMessage = addon.ErrorsFrame_AddMessage;
end

function addon.tableContains(tab, val)
    for index, value in ipairs(tab) do
        if value == val then
            return true
        end
    end
    return false
end
        
function addon.isEmpty(msg)
  return msg == nil or msg == ''
end

function addon.standardErrorMessages()
    return {
        "not enough", "not ready", "nothing to attack", "can't attack",
        "can't do", "unable to move", "must equip", "target is dead",
        "invalid target", "line of sight", "you are dead", "no target",
        "another action", "you are stunned", "wrong way", "out of range",
        "front of you", "you cannot attack", "too far away", "must be in",
        "too close", "requires combo", "in combat", "not in control",
        "must have", "nothing to dispel", "in an arena", "while pacified","ready",
        "interrupted"
    }
end
