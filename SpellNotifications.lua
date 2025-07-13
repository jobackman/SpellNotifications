--[[
	Version 2.0 maintained by LucyON & Oscarwizyo
]]

local _, addon = ...
SpellNotifications = addon

local reflected = {}
local ME, FRIENDLY, PET

-- Helper function to check if a GUID matches any of our tracked targets
local function isTrackedTarget(guid)
    local targetGuids = addon.TargetGuids()
    for _, target in ipairs(targetGuids) do
        if guid == UnitGUID(target) then
            return true
        end
    end
    return false
end

-- Helper function to get spell school name
local function getSpellSchoolName(extraSchool)
    local spellSchool = addon.SpellSchools()[extraSchool]
    return spellSchool or "unknown spell school"
end

-- Handle interrupt events
local function handleInterrupt(sourceFlags)
    if bit.band(sourceFlags, ME) > 0 then
        local extraSchool = select(17, CombatLogGetCurrentEventInfo())
        local spellSchool = getSpellSchoolName(extraSchool)
        addon.print("Interrupted " .. string.lower(spellSchool) .. ".", addon.Colors().GREEN, addon.Sizes().SMALL)
    end
end

-- Handle dispel events
local function handleDispel(sourceFlags, destFlags)
    if bit.band(sourceFlags, ME) > 0 then
        local spellName = select(16, CombatLogGetCurrentEventInfo())
        local color = bit.band(destFlags, FRIENDLY) > 0 and addon.Colors().WHITE or addon.Colors().YELLOW
        addon.print("Dispelled " .. spellName .. ".", color, addon.Sizes().SMALL)
    end
end

-- Handle spell steal events
local function handleSpellSteal(sourceFlags)
    if bit.band(sourceFlags, ME) > 0 then
        local spellName = select(16, CombatLogGetCurrentEventInfo())
        addon.print("Stole " .. spellName .. ".", addon.Colors().YELLOW, addon.Sizes().SMALL)
    end
end

-- Handle pet death events
local function handlePetDeath(event, destFlags)
    local isDeathEvent = event == "UNIT_DIED" or event == "UNIT_DESTROYED" or event == "UNIT_DISSIPATES"
    if isDeathEvent and bit.band(destFlags, ME) > 0 and bit.band(destFlags, PET) > 0 then
        addon.print("Pet dead.", addon.Colors().RED, addon.Sizes().LARGE)
        addon.playSound("buzz")
    end
end

-- Handle spell reflection tracking
local function handleSpellReflection(event, sourceFlags, destGUID)
    if (event == "SPELL_AURA_APPLIED" or event == "SPELL_AURA_REMOVED") and bit.band(sourceFlags, ME) > 0 then
        local spellName = select(13, CombatLogGetCurrentEventInfo())
        if spellName == "Mass Spell Reflection" then
            reflected[destGUID] = (event == "SPELL_AURA_APPLIED")
        end
    end
end

-- Handle reflected spell misses
local function handleReflectedMiss(destFlags, destGUID)
    if bit.band(destFlags, ME) <= 0 then
        local spellName, _, missType = select(13, CombatLogGetCurrentEventInfo())
        if missType == "REFLECT" and reflected[destGUID] then
            addon.print("Reflected " .. spellName .. ".", addon.Colors().BLUE, addon.Sizes().SMALL)
        end
    end
end

-- Handle spell misses on player
local function handlePlayerSpellMissOnPlayer(destFlags, destName)
    if bit.band(destFlags, ME) > 0 then
        local spellName, _, missType = select(13, CombatLogGetCurrentEventInfo())
        if missType == "REFLECT" then
            addon.print("Reflected " .. spellName .. ".", addon.Colors().WHITE, addon.Sizes().SMALL)
        elseif destName == "Grounding Totem" then
            addon.print("Grounded " .. spellName .. ".", addon.Colors().WHITE, addon.Sizes().SMALL)
        end
    end
end

-- Handle grounding totem damage
local function handleGroundingDamage(destFlags, destName)
    if bit.band(destFlags, ME) > 0 then
        local spellName = select(13, CombatLogGetCurrentEventInfo())
        if destName == "Grounding Totem" then
            addon.print("Grounded " .. spellName .. ".", addon.Colors().WHITE, addon.Sizes().SMALL)
        end
    end
end

-- Handle spell misses by player
local function handlePlayerSpellMiss(destGUID, destName)
    if isTrackedTarget(destGUID) then
        local spellName, _, missType = select(13, CombatLogGetCurrentEventInfo())
        local resistMethod = addon.MissTypes()[missType]

        if missType == "ABSORB" then
            return
        elseif destName == "Grounding Totem" then
            resistMethod = "grounded"
        elseif missType == "REFLECT" then
            resistMethod = "reflected"
        elseif resistMethod == nil then
            resistMethod = "missed"
        end

        local color = (resistMethod == "immune" or resistMethod == "evaded") and addon.Colors().RED or addon.Colors().WHITE
        addon.print(spellName .. " " .. resistMethod .. ".", color, addon.Sizes().LARGE)
    end
end

function SpellNotifications.OnLoad(self)
	self:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
	self:RegisterEvent("UNIT_HEALTH")
	self:RegisterEvent("PLAYER_TARGET_CHANGED")
	self:RegisterEvent("PLAYER_REGEN_DISABLED") -- enter combat
	self:RegisterEvent("PLAYER_REGEN_ENABLED") -- leave combat
	self:RegisterEvent("PLAYER_ENTERING_WORLD")
	self:RegisterEvent("ACTIONBAR_UPDATE_STATE")
end

function SpellNotifications.OnEvent(event)
    local timeStamp, event, hideCaster, sourceGUID, sourceName, sourceFlags, sourceRaidFlags, 
          destGUID, destName, destFlags, destRaidFlags = CombatLogGetCurrentEventInfo()
    
    local size = addon.Sizes()
    local color = addon.Colors()
    local affiliation = addon.Affiliations()
    ME, FRIENDLY, PET = affiliation.MINE, affiliation.FRIENDLY, affiliation.PET

    -- Handle different event types
    if event == "SPELL_INTERRUPT" then
        handleInterrupt(sourceFlags)
    elseif event == "SPELL_DISPEL" then
        handleDispel(sourceFlags, destFlags)
    elseif event == "SPELL_STOLEN" then
        handleSpellSteal(sourceFlags)
    elseif event == "UNIT_DIED" or event == "UNIT_DESTROYED" or event == "UNIT_DISSIPATES" then
        handlePetDeath(event, destFlags)
    elseif event == "SPELL_AURA_APPLIED" or event == "SPELL_AURA_REMOVED" then
        handleSpellReflection(event, sourceFlags, destGUID)
	elseif event == "SPELL_MISSED" then
		if bit.band(sourceFlags, ME) > 0 then
			handlePlayerSpellMiss(destGUID, destName)
		elseif bit.band(destFlags, ME) > 0 then
			handlePlayerSpellMissOnPlayer(destFlags, destName)
		elseif bit.band(destFlags, ME) <= 0 then
			handleReflectedMiss(destFlags, destGUID)
		end
    elseif event == "SPELL_DAMAGE" then
        handleGroundingDamage(destFlags, destName)
    end
end
