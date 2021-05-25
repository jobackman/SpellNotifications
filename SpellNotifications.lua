--[[
	Version 2.0 updated by LucyON
]]

local _, addon = ...

SpellNotifications = addon

local reflected = {}
local duration
local warnOP
local warnCS

function SpellNotifications.OnLoad(self)
	local _,class = UnitClass("player")
	self:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED");
	self:RegisterEvent("UNIT_HEALTH");
	self:RegisterEvent("PLAYER_TARGET_CHANGED");
	self:RegisterEvent("PLAYER_REGEN_DISABLED"); -- enter combat
	self:RegisterEvent("PLAYER_REGEN_ENABLED"); -- leave combat
	self:RegisterEvent("PLAYER_ENTERING_WORLD");
	self:RegisterEvent("ACTIONBAR_UPDATE_STATE");
	--@debug@
	-- ViragDevTool_AddData(addon, "SpellNotifications")
	--@end-debug@
end

function SpellNotifications.OnEvent(event)
	local timeStamp, event, hideCaster, sourceGUID, sourceName, sourceFlags, sourceRaidFlags, destGUID, destName, destFlags, destRaidFlags = CombatLogGetCurrentEventInfo()
	--        1        2       3           4            5           6              7              8        9          10          11
	local _,class = UnitClass("player")
	local size = addon.Sizes()

	if (event=="SPELL_INTERRUPT") then
		if bit.band(sourceFlags, COMBATLOG_OBJECT_AFFILIATION_MINE) > 0 then
			local extraSchool = select(17, CombatLogGetCurrentEventInfo())
			local spellSchool = addon.SpellSchools()[extraSchool]

			if spellSchool == nil then
				spellSchool = "unknown spell school"
			end
			addon.print("Interrupted "..string.lower(spellSchool)..".", "green", size.SMALL)
		end
	end

	if (event=="SPELL_DISPEL") then
		if bit.band(sourceFlags, COMBATLOG_OBJECT_AFFILIATION_MINE) > 0 then
			local spellName = select(16, CombatLogGetCurrentEventInfo());
			if bit.band(destFlags, COMBATLOG_OBJECT_REACTION_FRIENDLY) > 0 then
				addon.print("Dispelled "..spellName..".", "white", size.SMALL) -- friendly target
			else
				addon.print("Dispelled "..spellName..".", "yellow", size.SMALL) -- enemy target
			end
		end
	end

	if (event=="SPELL_STOLEN") then
		if bit.band(sourceFlags, COMBATLOG_OBJECT_AFFILIATION_MINE) > 0 then
			local spellName = select(16, CombatLogGetCurrentEventInfo());
			addon.print("Stole "..spellName..".", "yellow", size.SMALL) -- enemy target
		end
	end


	if (
		event == "UNIT_DIED" or
		event == "UNIT_DESTROYED" or
		event == "UNIT_DESTROYED"
	) then
		if bit.band(destFlags, COMBATLOG_OBJECT_AFFILIATION_MINE) > 0 then
			if bit.band(destFlags, COMBATLOG_OBJECT_TYPE_PET) > 0 then
				addon.print("Pet dead.", "red", size.LARGE)
				addon.playSound("buzz")
			end
		end
	end


	--9/28 20:58:34.485  SPELL_AURA_APPLIED,0x0400000005D8000F,"Veev",0x511,0x0,0x0400000005D8A13D,"Valrathz",0x512,0x0,114028,"Mass Spell Reflection",0x1,BUFF
	if event=="SPELL_AURA_APPLIED" or event=="SPELL_AURA_REMOVED" then
		if bit.band(sourceFlags, COMBATLOG_OBJECT_AFFILIATION_MINE) > 0 then
			local spellName = select(13, CombatLogGetCurrentEventInfo())
			if spellName=="Mass Spell Reflection" then
				if event=="SPELL_AURA_APPLIED" then
					reflected[destGUID] = true
				else
					reflected[destGUID] = false
				end
			end
		end
	end
	if (event=="SPELL_MISSED") then
		if (bit.band(destFlags, COMBATLOG_OBJECT_AFFILIATION_MINE) <= 0) then
			local spellName,_,missType = select(13, CombatLogGetCurrentEventInfo())
			if (missType=="REFLECT") then
				if reflected[destGUID] ~= nil then
					if reflected[destGUID] then
						addon.print("Reflected "..spellName..".", "blue", size.SMALL)
					end
				end
			end
		end
	end

	if (event=="SPELL_MISSED") then
		if (bit.band(destFlags, COMBATLOG_OBJECT_AFFILIATION_MINE) > 0) then
			local spellName,_,missType = select(13, CombatLogGetCurrentEventInfo())
			if (missType=="REFLECT") then
				addon.print("Reflected "..spellName..".", "white", size.SMALL)
			elseif (destName=="Grounding Totem") and (bit.band(destFlags, COMBATLOG_OBJECT_AFFILIATION_MINE) > 0) then
				addon.print("Grounded "..spellName..".", "white", size.SMALL)
			end
		end
	end
	if (event=="SPELL_DAMAGE") then
		if bit.band(destFlags, COMBATLOG_OBJECT_AFFILIATION_MINE) > 0 then
			local spellName = select(13, CombatLogGetCurrentEventInfo())
			if (destName=="Grounding Totem") then
				addon.print("Grounded "..spellName..".", "white", size.SMALL)
			end
		end
	end

	if (event=="SPELL_MISSED") then
		if bit.band(sourceFlags, COMBATLOG_OBJECT_AFFILIATION_MINE) > 0 then
			if (destGUID==UnitGUID("target")) or (destGUID==UnitGUID("targettarget")) or (destGUID==UnitGUID("focus")) or (destGUID==UnitGUID("player")) or (destGUID==UnitGUID("pet")) or (destGUID==UnitGUID("pettarget")) or (destGUID==UnitGUID("mouseover")) or (destGUID==UnitGUID("mouseovertarget")) or (destGUID==UnitGUID("arena1")) or (destGUID==UnitGUID("arena2")) or (destGUID==UnitGUID("arena3")) or (destGUID==UnitGUID("arena4")) or (destGUID==UnitGUID("arena5")) or (destGUID==UnitGUID("party1")) or (destGUID==UnitGUID("party2")) or (destGUID==UnitGUID("party3")) or (destGUID==UnitGUID("party4")) or (destGUID==UnitGUID("party5")) then -- makes sure dest targ wasn't some random aoe
				local spellName,_,missType = select(13, CombatLogGetCurrentEventInfo())

				local resistMethod = addon.MissTypes()[missType]

				if (missType=="ABSORB") then
					return;
				elseif (destName=="Grounding Totem") then
					resistMethod = "grounded"
				elseif (missType=="REFLECT") then
					resistMethod = "reflected"
				elseif resistMethod == nil then
					resistMethod = "missed"
				else
					resistMethod = "unknown"
				end

				if (resistMethod=="immune") or (resistMethod=="evaded") then
					addon.print(""..spellName.." "..resistMethod..".","red","large")
				else
					addon.print(""..spellName.." "..resistMethod..".","white","large")
				end
			end
		end
	end
end
