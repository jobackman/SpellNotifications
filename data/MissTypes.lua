local _, addon = ...

function addon.MissTypes()
    return {
        ["REFLECT"] = "reflected",
        ["IMMUNE"] = "immune",
        ["EVADE"] = "evaded",
        ["PARRY"] = "parried",
        ["DODGE"] = "dodged",
        ["BLOCK"] = "blocked",
        ["DEFLECT"] = "deflected",
        ["RESIST"] = "resisted"
    }
end
