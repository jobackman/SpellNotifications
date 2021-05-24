local _, addon = ...

function SpellNotifications_ErrorsFrame_AddMessage(self, msg, ...)
    local lowermsg = string.lower(msg)
    local messages = messages()

    if (contains(messages, lowermsg)) then
        return;
    end

    return self:SpellNotifications_Orig_AddMessage(msg, ...);
end

function SpellNotifications_HookErrorsFrame()
    local ef = getglobal("UIErrorsFrame");
    ef.SpellNotifications_Orig_AddMessage = ef.AddMessage;
    ef.AddMessage = SpellNotifications_ErrorsFrame_AddMessage;
end

function contains(tab, val)
    for index, value in ipairs(tab) do
        if value == val then
            return true
        end
    end
    return false
end

function messages()
    return {
        "not enough", "not ready", "nothing to attack", "can't attack",
        "can't do", "unable to move", "must equip", "target is dead",
        "invalid target", "line of sight", "you are dead", "no target",
        "another action", "you are stunned", "wrong way", "out of range",
        "front of you", "you cannot attack", "too far away","must be in",
        "too close", "requires combo","in combat","not in control",
        "must have","nothing to dispel","in an arena","while pacified","ready",
        "interrupted"
    }
end
