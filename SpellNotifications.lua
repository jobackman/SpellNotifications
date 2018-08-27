--[[
grounding totem similar to reflect
killing blow for warr only
display what my intervene takes
revenge stun proc, warlock nightfall glyph
imp hs, hs glyph
warlock eradication (spell haste)
druid aoe taunt and dk/pal taunt etc
mage spell steal like sham purge
2 diff type of dispell resists

warnings on adrenaline rush
reckless
shield wall
retal if rogue

3/13 13:54:39.633  UNIT_DIED,0x0000000000000000,nil,0x80000000,0xF13000172504787F,"Grounding Totem",0x2111
totem dying, add totem stomp warnings for all diff events

--NEW
spell reflects on others, intervenes
check for event for when i remove ice block/divine shield and add a normal dispel mssg for shatter
sudden death proc for colossus
--]]

local _
local reflected = {}
local duration
local warnOP
local warnCS

function SpellNotifications_OnLoad(self)
local _,class = UnitClass("player")
self:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED");
self:RegisterEvent("UNIT_HEALTH");
self:RegisterEvent("PLAYER_TARGET_CHANGED");
self:RegisterEvent("PLAYER_REGEN_DISABLED"); -- enter combat
self:RegisterEvent("PLAYER_REGEN_ENABLED"); -- leave combat
self:RegisterEvent("PLAYER_ENTERING_WORLD");
self:RegisterEvent("ACTIONBAR_UPDATE_STATE");
end

function SpellNotifications_OnEvent(event,...)

local currentSpec = GetSpecialization()
local currentSpecName = currentSpec and select(2, GetSpecializationInfo(currentSpec)) or "None"

local timeStamp, event, hideCaster, sourceGUID, sourceName, sourceFlags, sourceRaidFlags, destGUID, destName, destFlags, destRaidFlags = select(1,...)
--        1        2       3           4            5           6              7              8        9          10          11

-- Category: General

if (event=="SPELL_CAST_SUCCESS") then
	if bit.band(sourceFlags, COMBATLOG_OBJECT_REACTION_FRIENDLY) <= 0 then
		local spellName = select(13,...)
		if destName ~= nil then
			if (spellName == "Scatter Shot" or spellName == "Intimidation" or spellName == "Lullaby" or spellName == "Bad Manner" or spellName == "Web Wrap") and (destName == "Zileazx" or destName == "Zilea" or destName == "Thingtworyan" or destName == "Mydadsbutt" or destName == "Sodahz" or destName == "Thingtwotwo" or (string.find(destName,"Grave")) or (string.find(destName,"Vile")) or destName == "Bwinthehouse" or destName == "Coreygunz" or destName == "Veller") then
				SpellNotifications_Print(string.upper(spellName).."!","purple","large")
				SpellNotifications_PlaySound("train")
			end
		end
	end
end

if (event=="SPELL_AURA_APPLIED") then
	if bit.band(sourceFlags, COMBATLOG_OBJECT_REACTION_FRIENDLY) <= 0 then
		local spellName = select(13,...)
		if destName ~= nil then
			if spellName == "Bad Manner" and (destName == "Starshipx" or destName == "Zilea" or destName == "Taylorswift" or destName == "Mydadsbutt" or destName == "Sodahz" or destName == "Kollektiv" or (string.find(destName,"Grave")) or (string.find(destName,"Vile")) or destName == "Bwinthehouse" or destName == "Coreygunz" or destName == "Veller") then
				SpellNotifications_Print(string.upper(spellName).."!","purple","large")
				SpellNotifications_PlaySound("train")
			end
		end
	end
end

if (event=="SPELL_AURA_APPLIED") then
	if bit.band(sourceFlags, COMBATLOG_OBJECT_REACTION_FRIENDLY) <= 0 then
		local spellName = select(13,...)
		if destName ~= nil then
			if spellName == "Predatory Swiftness" then
				--SpellNotifications_Print(string.upper(spellName).."!","orange","large")
				--SpellNotifications_PlaySound("train")
			end
		end
	end
end


if (event=="SPELL_CAST_SUCCESS") then
	if bit.band(sourceFlags, COMBATLOG_OBJECT_REACTION_FRIENDLY) <= 0 then
		local spellName = select(13,...)
		if (spellName=="Dark Soul: Knowledge") and IsActiveBattlefieldArena() then
			SpellNotifications_Print("Warlock is going HAM!","orange","large")
			SpellNotifications_PlaySound("train")
		end
	end
end

if (event=="SPELL_DISPEL") then
	if bit.band(sourceFlags, COMBATLOG_OBJECT_AFFILIATION_MINE) > 0 then
		local spellName = select(16,...)
		if bit.band(destFlags, COMBATLOG_OBJECT_REACTION_FRIENDLY) > 0 then
			SpellNotifications_Print("Dispelled "..spellName..".","white","small") -- friendly target
		else
			SpellNotifications_Print("Dispelled "..spellName..".","yellow","small") -- enemy target
		end
	end
end

if (event=="SPELL_STOLEN") then
	if bit.band(sourceFlags, COMBATLOG_OBJECT_AFFILIATION_MINE) > 0 then
		local spellName = select(16,...)
		SpellNotifications_Print("Stole "..spellName..".","yellow","small") -- enemy target
	end
end


-- Category: Warrior

if (currentSpecName=="Arms") and (UnitLevel("player") >= 81) then
	if InCombatLockdown() then
		if IsUsableSpell("Overpower") and (warnOP == true or warnOP == nil) then
			SpellNotifications_PlaySound("cling")
			warnOP = false
		elseif not IsUsableSpell("Overpower") then
			warnOP = true
		end
		_,duration = GetSpellCooldown("Colossus Smash")
		if (duration == 0) and (warnCS == true or warnCS == nil) then
			SpellNotifications_PlaySound("ding")
			warnCS = false
		elseif (duration >= 2) then
			warnCS = true
		end
		if (event=="SPELL_AURA_APPLIED") then
			if bit.band(destFlags, COMBATLOG_OBJECT_AFFILIATION_MINE) > 0 then
				local spellName = select(13,...)
				if (spellName=="Sudden Death") and (warnCS == true or warnCS == nil) then
					SpellNotifications_PlaySound("ding")
					warnCS = false
				end
			end
		end
	end
end

if (event=="SPELL_AURA_APPLIED") then
	if bit.band(destFlags, COMBATLOG_OBJECT_AFFILIATION_MINE) > 0 then
		local spellName = select(13,...)
		if (spellName=="Avatar") then
			if IsActiveBattlefieldArena() and UnitInParty("Valrathz") then
				--SendChatMessage("Frenzy me!!!", "WHISPER", nil, "Valrathz");
			end
		end
	end
end








--cleanupmarker






if (event=="SPELL_AURA_APPLIED") or (event=="SPELL_AURA_APPLIED_DOSE") or (event=="SPELL_EXTRA_ATTACKS") then
	if bit.band(destFlags, COMBATLOG_OBJECT_AFFILIATION_MINE) > 0 then
		local spellId,spellName = select(12,...)
		if (event=="SPELL_AURA_APPLIED_DOSE") then
			amount = select(14,...)
		end

		--Death Knight
		if (spellName=="Killing Machine") then
			--SpellNotifications_Print("Killing Machine!","green","large") -- or say icy touch maybe
			--SpellNotifications_PlaySound("cling")
		elseif (spellName=="Freezing Fog") then
			--SpellNotifications_Print("Howling Blast!","blue","large")
			--SpellNotifications_PlaySound("ding")
		elseif (spellName=="Death Trance!") then
			--SpellNotifications_Print("Death Coil!","green","large")
			--SpellNotifications_PlaySound("ding")

		--Druid
		elseif (spellId==48517) then
			--SpellNotifications_Print("Wrath!","green","large")
			--SpellNotifications_PlaySound("ding")
		elseif (spellId==48518) or (spellName=="Wrath of Elune") then
			--SpellNotifications_Print("Starfire!","green","large")
			--SpellNotifications_PlaySound("ding")
		elseif (spellName=="Nature's Grace") then
			--SpellNotifications_PlaySound("cling")
		elseif (spellName=="Shooting Stars") and (class=="DRUID") then
			--SpellNotifications_Print("Clearcast!","green","large")
			SpellNotifications_PlaySound("ding")

		--Hunter
		elseif (spellName=="Lock and Load") then
			--SpellNotifications_Print("Arcane Shot!","green","large") -- maybe say lock n load for explosive shot also
			--SpellNotifications_PlaySound("ding")

		--Mage
		elseif (spellName=="Clearcasting") and (class=="MAGE") then
			--SpellNotifications_Print("Clearcast!","green","large")
			--SpellNotifications_PlaySound("cling")
		elseif (spellName=="Fingers of Frost") then
			--SpellNotifications_Print("Fingers of Frost!","blue","large")
			SpellNotifications_PlaySound("cling")
		elseif (spellName=="Fireball!") then
			--SpellNotifications_Print("Fireball!","orange","large")
			--SpellNotifications_PlaySound("ding")
		elseif (spellName=="Firestarter") then
			--SpellNotifications_Print("Flamestrike!","orange","large")
			--SpellNotifications_PlaySound("ding")
		elseif (spellName=="Hot Streak") then
			--SpellNotifications_Print("Pyroblast!","orange","large")
			--SpellNotifications_PlaySound("ding")
		elseif (spellName=="Missile Barrage") then
			--SpellNotifications_Print("Arcane Missiles!","green","large")
			--SpellNotifications_PlaySound("ding")

		--Paladin

		--Priest

		--Rogue
		elseif (spellName=="Sword Specialization") or (spellName=="Hand of Justice") or (string.find(spellName,"Thrash")) then
			--SpellNotifications_PlaySound("cling")

		--Shaman
		elseif (spellName=="Maelstrom Weapon") and (amount==5) and (event=="SPELL_AURA_APPLIED_DOSE") then
			--SpellNotifications_Print("Maelstrom!","green","large")
			--SpellNotifications_PlaySound("ding")

		--Warlock
		elseif (spellName=="Shadow Trance") then
			--SpellNotifications_Print("Shadow Bolt!","purple","large")
			SpellNotifications_PlaySound("ding")
		elseif (spellName=="Backlash") or (spellName=="Molten Core") then
			--SpellNotifications_Print("Incinerate!","orange","large")
			--SpellNotifications_PlaySound("ding")

		--Warrior
		elseif (spellName=="Sword and Board") then
			--SpellNotifications_Print("Shield Slam!","green","large")
			--SpellNotifications_PlaySound("ding")
		elseif (spellName=="Slam!") then
			--SpellNotifications_Print("Slam!","green","large")
			--SpellNotifications_PlaySound("ding")
		elseif (spellName=="Sudden Death") then
			--SpellNotifications_Print("Execute!","green","large")
			--SpellNotifications_PlaySound("cling")
		elseif spellName=="Taste for Blood" then
			--SpellNotifications_Print("Overpower!","green","large")
			--SpellNotifications_PlaySound("ding")

		end
	end
end



--4/27 18:22:29.177  SPELL_MISSED,0x05000000027EF48C,"Veev",0x511,0x050000000285EB2D,"Valrathlol",0x10548,1715,"Hamstring",0x1,DODGE
--1/12 20:09:21.644  SPELL_AURA_APPLIED,0x0500000003580F5F,"Veev",0x511,0xF130007F9A002B25,"Expert's Training Dummy",0x10a28,64382,"Shattering Throw",0x1,DEBUFF
if (class=="WARRIOR") then
	if (event=="SWING_MISSED") or (event=="SPELL_MISSED") then
		if bit.band(sourceFlags, COMBATLOG_OBJECT_AFFILIATION_MINE) > 0 then
			if (event=="SWING_MISSED") then
				missType = select(15,...)
			else
				missType = select(15,...)
			end
			if (missType=="DODGE") then
				--SpellNotifications_PlaySound("ding")
			end
		end
	elseif event=="SPELL_AURA_APPLIED" then
		if bit.band(sourceFlags, COMBATLOG_OBJECT_AFFILIATION_MINE) > 0 then
			local spellName = select(13,...)
			if (spellName=="Shattering Throw") then
				--SendChatMessage("Shattering Throw up on "..destName.."!", "YELL");
			end
		end
	end
end


--3/13 14:00:54.839  SPELL_PERIODIC_DAMAGE,0x000000000280B239,"V��x",0x511,0x0000000002967F3C,"Y�d�",0x10548,47857,"Drain Life",0x20,414,0,32,46,0,0,nil,nil,nil
--3/13 14:01:00.244  SPELL_PERIODIC_LEECH,0x000000000280B239,"V��x",0x511,0x0000000002967F3C,"Y�d�",0x10548,5138,"Drain Mana",0x20,389,0,389
if (event=="SPELL_CAST_SUCCESS") or (event=="SPELL_PERIODIC_DAMAGE") then
	if bit.band(sourceFlags, COMBATLOG_OBJECT_AFFILIATION_MINE) > 0 then
		local spellName = select(13,...)
		if (spellName=="Drain Soul") then
			local amount = select(15,...)
			local critical = select(21,...)
			if (event=="SPELL_CAST_SUCCESS") then
				SpellNotifications_DrainCount = 0
			elseif (event=="SPELL_PERIODIC_DAMAGE") then
				SpellNotifications_DrainCount = SpellNotifications_DrainCount + 1
				if (SpellNotifications_DrainColor=="orange") or (SpellNotifications_DrainColor==nil) then
					SpellNotifications_DrainColor = "blue"
				elseif (SpellNotifications_DrainColor=="blue") then
					SpellNotifications_DrainColor = "purple"
				elseif (SpellNotifications_DrainColor=="purple") then
					SpellNotifications_DrainColor = "red"
				elseif (SpellNotifications_DrainColor=="red") then
					SpellNotifications_DrainColor = "orange"
				end
				if critical==1 then
					SpellNotifications_Print(""..amount.."!",SpellNotifications_DrainColor,"small")
				else
					SpellNotifications_Print(""..amount.."",SpellNotifications_DrainColor,"small")
				end
				if (spellName=="Drain Soul") then
					SpellNotifications_PlaySound("bell")
				end
			end
		end
	end
end

--12/26 19:53:55.151  UNIT_DIED,0x0000000000000000,nil,0x80000000,0xF140A698C50150C4,"Czaafum",0x11111
if (event=="UNIT_DIED") then
	if bit.band(destFlags, COMBATLOG_OBJECT_AFFILIATION_MINE) > 0 then
		if bit.band(destFlags, COMBATLOG_OBJECT_TYPE_PET) > 0 then
			SpellNotifications_Print("Pet dead.","red","large")
			SpellNotifications_PlaySound("buzz")
		end
	end
end




if (event=="UNIT_HEALTH") then
	if (not SpellNotifications_ExecuteWarn) then
		if (UnitClassification("target")=="worldboss") or (UnitIsPlayer("target")) then
			if (class=="WARLOCK") then
				if (((UnitHealth("target") / UnitHealthMax("target")) * 100) <= 25) and (UnitHealth("target") > 0) then
					if (UnitClassification("target")=="worldboss") then
						RaidNotice_AddMessage(RaidBossEmoteFrame, "Drain Soul!", ChatTypeInfo["RAID_WARNING"])
						--SpellNotifications_PlaySound("lock_execute")
						SpellNotifications_PlaySound("laser")
					else
						--SpellNotifications_PlaySound("laser")
					end
					SpellNotifications_ExecuteWarn = true;
				end
			end
		end
	end
end

if (event=="UNIT_HEALTH") then
	if (not SpellNotifications_ExecuteWarn) then
		if (UnitClassification("target")=="worldboss") or (UnitIsPlayer("target")) then
			if (class=="WARLOCK") then
				if (((UnitHealth("target") / UnitHealthMax("target")) * 100) > 25) then
					SpellNotifications_ExecuteWarn = false;
				end
			end
		end
	end
end

if (event=="PLAYER_TARGET_CHANGED") then
	SpellNotifications_ExecuteWarn = false;
end




if (event=="SPELL_INTERRUPT") then
	if bit.band(sourceFlags, COMBATLOG_OBJECT_AFFILIATION_MINE) > 0 then
		local extraSchool = select(17,...)

		if extraSchool==1 then
			SpellSchool="Physical"
		elseif extraSchool==2 then
			SpellSchool="Holy"
		elseif extraSchool==4 then
			SpellSchool="Fire"
		elseif extraSchool==8 then
			SpellSchool="Nature"
		elseif extraSchool==16 then
			SpellSchool="Frost"
		elseif extraSchool==32 then
			SpellSchool="Shadow"
		elseif extraSchool==64 then
			SpellSchool="Arcane"
		elseif extraSchool==3 then
			SpellSchool="Holystrike"
		elseif extraSchool==5 then
			SpellSchool="Flamestrike"
		elseif extraSchool==6 then
			SpellSchool="Holyfire"
		elseif extraSchool==9 then
			SpellSchool="Stormstrike"
		elseif extraSchool==10 then
			SpellSchool="Holystorm"
		elseif extraSchool==12 then
			SpellSchool="Firestorm"
		elseif extraSchool==17 then
			SpellSchool="Froststrike"
		elseif extraSchool==18 then
			SpellSchool="Holyfrost"
		elseif extraSchool==20 then
			SpellSchool="Frostfire"
		elseif extraSchool==24 then
			SpellSchool="Froststorm"
		elseif extraSchool==33 then
			SpellSchool="Shadowstrike"
		elseif extraSchool==34 then
			SpellSchool="Twilight"
		elseif extraSchool==36 then
			SpellSchool="Shadowflame"
		elseif extraSchool==40 then
			SpellSchool="Plague"
		elseif extraSchool==48 then
			SpellSchool="Shadowfrost"
		elseif extraSchool==65 then
			SpellSchool="Spellstrike"
		elseif extraSchool==66 then
			SpellSchool="Divine"
		elseif extraSchool==68 then
			SpellSchool="Spellfire"
		elseif extraSchool==72 then
			SpellSchool="Spellstorm"
		elseif extraSchool==80 then
			SpellSchool="Spellfrost"
		elseif extraSchool==96 then
			SpellSchool="Spellshadow"
		elseif extraSchool==28 then
			SpellSchool="Elemental"
		elseif extraSchool==124 then
			SpellSchool="Chromatic"
		elseif extraSchool==126 then
			SpellSchool="Magic"
		elseif extraSchool==127 then
			SpellSchool="Chaos"
		else
			SpellSchool = "unknown spell school"
		end
		if SpellSchool==nil then
			SpellSchool = "unknown spell school"
		end
		SpellNotifications_Print("Interrupted "..string.lower(SpellSchool)..".","green","small")
	end
end





--9/28 20:58:34.485  SPELL_AURA_APPLIED,0x0400000005D8000F,"Veev",0x511,0x0,0x0400000005D8A13D,"Valrathz",0x512,0x0,114028,"Mass Spell Reflection",0x1,BUFF
if event=="SPELL_AURA_APPLIED" or event=="SPELL_AURA_REMOVED" then
	if bit.band(sourceFlags, COMBATLOG_OBJECT_AFFILIATION_MINE) > 0 then
		local spellName = select(13,...)
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
		local spellName,_,missType = select(13,...)
		if (missType=="REFLECT") then
			if reflected[destGUID] ~= nil then
				if reflected[destGUID] then
					SpellNotifications_Print("Reflected "..spellName..".","blue","small")
					--SendChatMessage("Reflected "..spellName..".", "WHISPER", nil, destName);
				end
			end
		end
	end
end





if (event=="SPELL_MISSED") then
	if (bit.band(destFlags, COMBATLOG_OBJECT_AFFILIATION_MINE) > 0) then
		local spellName,_,missType = select(13,...)
		if (missType=="REFLECT") then
			SpellNotifications_Print("Reflected "..spellName..".","white","small")
			--SendChatMessage("Reflected "..spellName..".", "PARTY");
		elseif (destName=="Grounding Totem") and (bit.band(destFlags, COMBATLOG_OBJECT_AFFILIATION_MINE) > 0) then
			SpellNotifications_Print("Grounded "..spellName..".","white","small")
			--SendChatMessage("Grounded "..spellName..".", "PARTY");
		end
	end
end
if (event=="SPELL_DAMAGE") then
	if bit.band(destFlags, COMBATLOG_OBJECT_AFFILIATION_MINE) > 0 then
		local spellName = select(13,...)
		if (destName=="Grounding Totem") then
			SpellNotifications_Print("Grounded "..spellName..".","white","small")
			--SendChatMessage("Grounded "..spellName..".", "PARTY");
		end
	end
end



if (event=="SPELL_MISSED") then
	if bit.band(sourceFlags, COMBATLOG_OBJECT_AFFILIATION_MINE) > 0 then
		if (destGUID==UnitGUID("target")) or (destGUID==UnitGUID("targettarget")) or (destGUID==UnitGUID("focus")) or (destGUID==UnitGUID("player")) or (destGUID==UnitGUID("pet")) or (destGUID==UnitGUID("pettarget")) or (destGUID==UnitGUID("mouseover")) or (destGUID==UnitGUID("mouseovertarget")) or (destGUID==UnitGUID("arena1")) or (destGUID==UnitGUID("arena2")) or (destGUID==UnitGUID("arena3")) or (destGUID==UnitGUID("arena4")) or (destGUID==UnitGUID("arena5")) or (destGUID==UnitGUID("party1")) or (destGUID==UnitGUID("party2")) or (destGUID==UnitGUID("party3")) or (destGUID==UnitGUID("party4")) or (destGUID==UnitGUID("party5")) then -- makes sure dest targ wasn't some random aoe
			local spellName,_,missType = select(13,...)
			local lowspell = string.lower(spellName)

			if (string.find(lowspell,"pvp trinket")) or (string.find(lowspell,"every man for himself")) or (string.find(lowspell,"soul fragment")) or (string.find(lowspell,"chaos bane")) or (string.find(lowspell,"frostforged")) or (string.find(lowspell,"berserk")) or (string.find(lowspell,"hurricane")) or (string.find(lowspell,"power torrent")) or (string.find(lowspell,"elemental force")) or (string.find(lowspell,"lightning breath")) or (string.find(lowspell,"stormlash")) or (string.find(lowspell,"dancing steel")) or (string.find(lowspell,"lifebloom"))
			--Death Knight

			--Druid
			or (string.find(lowspell,"fury swipes"))

			--Hunter

			--Mage
			or (string.find(lowspell,"frostbite")) or ((string.find(lowspell,"deep freeze")) and missType=="IMMUNE") or (string.find(lowspell,"frost nova")) or (string.find(lowspell,"shattered barrier")) or (string.find(lowspell,"waterbolt")) or (string.find(lowspell,"chilled"))

			--Paladin
			or (string.find(lowspell,"seal of "))

			--Priest

			--Rogue
			or (string.find(lowspell," poison"))

			--Shaman
			or (string.find(lowspell,"healing stream")) or (string.find(lowspell,"earth shield")) or (string.find(lowspell,"ancestral awakening"))

			--Warlock
			or (string.find(lowspell,"torment")) or (string.find(lowspell,"shadow bite")) or (string.find(lowspell,"jinx")) or (string.find(lowspell,"dark intent")) or (string.find(lowspell,"siphon life")) or (string.find(lowspell,"fel synergy")) or (string.find(lowspell,"eradication")) or (string.find(lowspell,"nightfall")) or (string.find(lowspell,"devour magic")) or (string.find(lowspell,"shadow embrace")) or (string.find(lowspell,"doom bolt")) or (string.find(lowspell,"everlasting affliction")) or (string.find(lowspell,"immolation")) or (string.find(lowspell,"shadowsnare")) or (string.find(lowspell,"shadow and flame")) or (string.find(lowspell,"improved shadow")) or (string.find(lowspell,"felstorm")) or (string.find(lowspell,"legion strike")) or (string.find(lowspell,"pursuit")) or (string.find(lowspell,"curse of gul'dan")) or (string.find(lowspell,"fel armor")) or (string.find(lowspell,"volcanic destruction")) or (string.find(lowspell,"shadow trance"))

			--Warrior
			or ((string.find(lowspell,"shockwave")) and missType=="IMMUNE") or (string.find(lowspell,"gag order")) or (string.find(lowspell,"heroic strike")) or (string.find(lowspell,"cleave")) or (string.find(lowspell,"deep wound")) or (string.find(lowspell,"enrage")) or (string.find(lowspell,"taste for blood")) or (string.find(lowspell,"strikes of opportunity")) or (string.find(lowspell,"opportunity strike")) or ((string.find(lowspell,"taunt")) and missType=="IMMUNE") or (string.find(lowspell,"safeguard")) or (string.find(lowspell,"mortal wounds")) or (string.find(lowspell,"physical vulnerability")) or (string.find(lowspell,"second wind"))

			then
				return;
			end

			if (string.find(lowspell,"charge")) then
				spellName = "Charge"
			elseif (string.find(lowspell,"intercept")) then
				spellName = "Intercept"
			elseif (string.find(lowspell,"ravage")) then
				spellName = "Ravage"
			end
			if (missType=="ABSORB") then
				return;
			elseif (destName=="Grounding Totem") then
				ResistMethod = "grounded"
				MySpellGrounded = true;
			elseif (missType=="REFLECT") then
				ResistMethod = "reflected"
				MySpellReflected = true;
			elseif (missType=="IMMUNE") then
				ResistMethod = "immune"
			elseif (missType=="EVADE") then
				ResistMethod = "evaded"
			elseif (missType=="PARRY") then
				ResistMethod = "parried"
			elseif (missType=="DODGE") then
				ResistMethod = "dodged"
			elseif (missType=="BLOCK") then
				ResistMethod = "blocked"
			elseif (missType=="DEFLECT") then
				ResistMethod = "deflected"
			elseif (missType=="RESIST") then
				ResistMethod = "resisted"
			else
				ResistMethod = "missed"
			end

			if (ResistMethod=="immune") and (spellName=="Shattering Throw") then
				SpellNotifications_Print("Shattered!","green","small")
				return;
			end

			if (ResistMethod=="immune") or (ResistMethod=="evaded") then
				SpellNotifications_Print(""..spellName.." "..ResistMethod..".","red","large")
			else
				SpellNotifications_Print(""..spellName.." "..ResistMethod..".","white","large")
				SpellNotifications_PlaySound("thud")
			end
			if (ResistMethod ~= "immune") then
				if (spellName=="Mocking Blow") or (spellName=="Challenging Shout") or (spellName=="Taunt") or (spellName=="Growl") or (spellName=="Challenging Roar") then
					lowerspellName = string.lower(spellName)
					if (class=="WARRIOR") or (class=="DRUID") or (class=="PALADIN") or (class=="DEATHKNIGHT") then
						if (ResistMethod ~= "missed") then
							SendChatMessage("My "..lowerspellName.." was "..ResistMethod..".");
						else
							SendChatMessage("My "..lowerspellName.." "..ResistMethod..".");
						end
					end
				end
			end
		end
	end
end








































end










function SpellNotifications_Print(text,color,size)

	local color = string.lower(color)
	local size = string.lower(size)


if color == "blue" then
		R = 0; G = .75; B = 1
	elseif color == "green" then
		R = .5; G = 1; B = 0
	elseif color == "yellow" then
		R = 1; G = 1; B = 0
	elseif color == "orange" then
		R = 1; G = .65; B = 0
	elseif color == "red" then
		R = 1; G = 0; B = 0
	elseif color == "purple" then
		R = .93; G = .51; B = .93
	elseif color == "black" then
		R = 0; G = 0; B = 0
	else -- color == "white"
		R = 1; G = 1; B = 1
	end

	if size == "large" or size == "big" then
		ZoneTextString:SetText(text);
		PVPInfoTextString:SetText("");
		ZoneTextFrame.startTime = GetTime()
		ZoneTextFrame.fadeInTime = 0
		ZoneTextFrame.holdTime = 1
		ZoneTextFrame.fadeOutTime = 2
		ZoneTextString:SetTextColor(R,G,B);
		ZoneTextFrame:Show()
	else -- size == "small"
		UIErrorsFrame:AddMessage(text,R,G,B);
	end

end

function SpellNotifications_PlaySound(sound)
	PlaySoundFile("Interface\\AddOns\\SpellNotifications\\Sounds\\"..sound..".mp3", "Master");
end

function SpellNotifications_ErrorsFrame_AddMessage(self,msg,...)
	local lowermsg = string.lower(msg)
	if (string.find(lowermsg,"not enough")) or (string.find(lowermsg,"not ready")) or (string.find(lowermsg,"nothing to attack")) or (string.find(lowermsg,"can't attack")) or (string.find(lowermsg,"can't do")) or (string.find(lowermsg,"unable to move")) or (string.find(lowermsg,"must equip")) or (lowermsg=="interrupted") or (string.find(lowermsg,"target is dead")) or (string.find(lowermsg,"invalid target")) or (string.find(lowermsg,"line of sight")) or (string.find(lowermsg,"you are dead")) or (string.find(lowermsg,"no target")) or (string.find(lowermsg,"another action")) or (string.find(lowermsg,"you are stunned")) or (string.find(lowermsg,"wrong way")) or (string.find(lowermsg,"out of range")) or (string.find(lowermsg,"front of you")) or (string.find(lowermsg,"you cannot attack")) or (string.find(lowermsg,"too far away")) or (string.find(lowermsg,"must be in")) or (string.find(lowermsg,"too close")) or (string.find(lowermsg,"requires combo")) or (string.find(lowermsg,"in combat")) or (string.find(lowermsg,"not in control")) or (string.find(lowermsg,"must have")) or (string.find(lowermsg,"nothing to dispel")) or (string.find(lowermsg,"in an arena")) or (string.find(lowermsg,"while pacified")) then
		return;
	end
	return self:SpellNotifications_Orig_AddMessage(msg,...);
end

function SpellNotifications_HookErrorsFrame()
	local ef = getglobal("UIErrorsFrame");
	ef.SpellNotifications_Orig_AddMessage = ef.AddMessage;
	ef.AddMessage = SpellNotifications_ErrorsFrame_AddMessage;
end
