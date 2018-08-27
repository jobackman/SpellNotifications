--[[
Variables
--]]
local addonVersion = "2.0.0"
local forceReset = false
local UnsavedVar = {}
local SavedVar
if (type(SavedVar) ~= "table") or (addonVersion ~= SavedVar["lastVersionSeen"] and forceReset) then -- set defaults
	SavedVar = {}
	SavedVar["enableAddon"] = true
end
SavedVar["lastVersionSeen"] = addonVersion

--[[
Functions
--]]
local function PlayMP3(fileName)
	PlaySoundFile("Interface\\AddOns\\SpellNotifications\\Sounds\\"..fileName..".mp3", "Master")
end

--[[
Frame Creation & Event Registration
--]]
local EventFrame = CreateFrame("Frame")
EventFrame:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")

--[[
Startup
--]]


--[[
Event Handler
--]]
EventFrame:SetScript("OnEvent", function(self,event,...)
	if (event == "COMBAT_LOG_EVENT_UNFILTERED") then
		local timeStamp, event, hideCaster, sourceGUID, sourceName, sourceFlags, sourceRaidFlags, destGUID, destName, destFlags, destRaidFlags = select(1,...)
		local spellId, spellName, spellSchool, auraType, amount, extraSpellID, extraSpellName, extraSchool
		if (event == "SPELL_CAST_SUCCESS") then
			spellId, spellName, spellSchool = select(12,...)
		elseif (event == "SPELL_AURA_APPLIED" or event == "SPELL_AURA_REMOVED") then
			spellId, spellName, spellSchool, auraType = select(12,...)
		elseif (event == "SPELL_AURA_APPLIED_DOSE") then -- 5 maelstrom stacks
			spellId, spellName, spellSchool, auraType, amount = select(12,...)
		elseif (event == "SPELL_DISPEL" or event == "SPELL_STOLEN") then
			spellId, spellName, spellSchool, extraSpellID, extraSpellName, extraSchool, auraType = select(12,...)
		elseif (event == "SPELL_INTERRUPT") then
			spellId, spellName, spellSchool, extraSpellID, extraSpellName, extraSchool = select(12,...)
		end
		
		
		
		
		--use spell ids
		

		
		
		
		
		
	end


--if take gateway, /script PlaySoundFile("Sound\\Creature\\Rotface\\IC_Rotface_Aggro01.wav")





	 if (event == "UPDATE_BATTLEFIELD_STATUS") then
	 
			local status, mapName = GetBattlefieldStatus(1)
			if (status == "confirm" and string.find(string.lower(mapName),"arena")) then
				AudioWarn("queue")
				UnsavedVar["warned"] = true
				StopWatch:SetTimer("15 second warning", 15-.5, nil, AudioWarn, 15) -- remove partial time to sync
				StopWatch:SetTimer("10 second warning", 20-.5, nil, AudioWarn, 10)
				StopWatch:SetTimer("5 second warning", 25-.5, nil, AudioWarn, 5)
				StopWatch:SetTimer("4 second warning", 26-.5, nil, AudioWarn, 4)
				StopWatch:SetTimer("3 second warning", 27-.5, nil, AudioWarn, 3)
				StopWatch:SetTimer("2 second warning", 28-.5, nil, AudioWarn, 2)
				StopWatch:SetTimer("1 second warning", 29-.5, nil, AudioWarn, 1)
				StopWatch:SetTimer("Missed queue", 30, nil, AudioWarn, "missed")
			end
			
			if (status ~= "confirm") then
				if (UnsavedVar["warned"]) then -- consider adding a 25s time check here
					--AudioWarn("missed")
				end
				SetNormalCVars()
			end
			
			if (UnsavedVar["wasInArena"] and not IsActiveBattlefieldArena()) then
				if (UnitIsGroupLeader("player")) then
					UnsavedVar["openPVPFrame"] = true
				end
			end
			UnsavedVar["wasInArena"] = IsActiveBattlefieldArena()
		
	 end
	 
	 if (event == "PLAYER_ENTERING_WORLD") then
		SetNormalCVars()
	 end
	 
	 if (event == "PLAYER_ALIVE") then
		if (UnsavedVar["openPVPFrame"]) then
			TogglePVPUI()
			UnsavedVar["openPVPFrame"] = false
		end
	 end
	 
	 if (event == "CVAR_UPDATE") then -- user manually changed vars
		GetNormalCVars()
	 end
	 
end)