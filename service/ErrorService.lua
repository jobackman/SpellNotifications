local _, addon = ...

-- The game's own error texts (GlobalStrings), in the client's language. The list below (standardErrorMessages) holds
-- English word pieces but is compared with the WHOLE message, so e.g. "Not enough rage" never matched "not enough" and
-- non-English clients matched nothing; these are the exact texts the client sends. Keys a client doesn't have are
-- skipped. Left visible on purpose: "Out of ammo" (hunters need to see it).
local GAME_ERRORS = {
    "ERR_OUT_OF_RAGE", "ERR_OUT_OF_ENERGY", "ERR_OUT_OF_MANA", "ERR_OUT_OF_FOCUS",
    "SPELL_FAILED_NOT_READY", "ERR_ABILITY_COOLDOWN", "ERR_SPELL_COOLDOWN", "ERR_ITEM_COOLDOWN",
    "ERR_NO_ATTACK_TARGET", "SPELL_FAILED_TARGETS_DEAD", "ERR_BADATTACKFACING", "ERR_BADATTACKPOS",
    "SPELL_FAILED_LINE_OF_SIGHT", "SPELL_FAILED_OUT_OF_RANGE", "ERR_OUT_OF_RANGE", "SPELL_FAILED_TOO_CLOSE",
    "SPELL_FAILED_NO_COMBO_POINTS", "SPELL_FAILED_INTERRUPTED", "ERR_GENERIC_NO_TARGET", "SPELL_FAILED_BAD_TARGETS",
    "SPELL_FAILED_SPELL_IN_PROGRESS", "ERR_SPELL_FAILED_ANOTHER_IN_PROGRESS", "SPELL_FAILED_STUNNED",
    "SPELL_FAILED_NOTHING_TO_DISPEL", "SPELL_FAILED_UNIT_NOT_INFRONT", "SPELL_FAILED_MOVING", "ERR_NOT_WHILE_MOVING",
    "ERR_INVALID_ATTACK_TARGET", "SPELL_FAILED_CASTER_DEAD", "ERR_PLAYER_DEAD", "SPELL_FAILED_AFFECTING_COMBAT",
    "ERR_NOT_IN_COMBAT", "SPELL_FAILED_NOT_BEHIND", "SPELL_FAILED_PACIFIED", "SPELL_FAILED_CANT_DO_THAT_RIGHT_NOW",
}
local gameSet
local function GameErrors()
    if not gameSet then
        gameSet = {}
        for _, key in ipairs(GAME_ERRORS) do
            local text = _G[key]
            if type(text) == "string" and text ~= "" and not (issecretvalue and issecretvalue(text)) then
                gameSet[string.lower(text)] = true
            end
        end
    end
    return gameSet
end
addon.GameErrors = GameErrors

function addon.ErrorsFrame_AddMessage(self, msg, ...)
    -- a text the game hides from addons is passed on untouched (lower() on it would be an error)
    if issecretvalue and issecretvalue(msg) then return self:Original_AddMessage(msg, ...) end

    if (addon.isEmpty(msg)) then
        msg = "unknown"
    end

    local lowermsg = string.lower(msg)
    local contains = addon.tableContains
    local standardErrorMessages = addon.standardErrorMessages()

    if GameErrors()[lowermsg] or (contains(standardErrorMessages, lowermsg)) then
        return;
    end

    return self:Original_AddMessage(msg, ...);
end

function addon.HookErrorsFrame()
    local ef = _G["UIErrorsFrame"];
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
