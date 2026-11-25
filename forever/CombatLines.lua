-- SpellNotifications on WoW Forever.
-- Forever gives addons no COMBAT_LOG_EVENT_UNFILTERED, so the original handlers never run. The same notifications
-- come from what Forever does give, the way BattleText Forever reads the fight:
--   * COMBAT_LOG_MESSAGE: every finished line of the Combat Log window, read by forever/Parse.lua (from BattleText
--     Forever, MIT). The game sends these lines while its Combat Log filter is on; it turns them off whenever the
--     Combat Log window hides, so they are turned back on (C_CombatLog.SetFilteredEventsEnabled).
--   * UNIT_SPELLCAST_INTERRUPTED right after one of your own interrupts, if no line said it.
--   * your pet's health, if no line said it died.
-- Not possible on Forever: "Grounded ..." (the game scrambles other creatures' names in the lines, and the
-- original knows the totem only by its name) and Mass Spell Reflection (not in the game).
-- Everything is events; nothing runs per frame.
local _, addon = ...
-- the real combat log is there (not Forever): the original handlers in SpellNotifications.lua do the work
if CombatLogGetCurrentEventInfo then return end
local Parser = addon.Parser
local CL = {}
addon.CombatLines = CL

local GetTime, pcall, type = GetTime, pcall, type
local function IsSecret(v) return issecretvalue ~= nil and issecretvalue(v) == true end

local function Guid(unit)
	local ok, g = pcall(UnitGUID, unit)
	if ok and not IsSecret(g) and type(g) == "string" then return g end
end

-- the player's interrupts on Forever (Classic Era based), every rank matched by name - from the Forever client data
-- (spells with the interrupt effect that a player learns): Kick, Pummel, Shield Bash, Counterspell,
-- Earth Shock, Spell Lock (felhunter), plus Silence (priest talent), Feral Charge (Bear) and Forever's own Feral
-- Charge, Rebuke and Skull Bash
local INTERRUPTS = { 1766, 6552, 72, 2139, 8042, 19244, 15487, 16979, 1238122, 425609, 410176 }
local interruptName

local function SpellName(id)
	if C_Spell and C_Spell.GetSpellName then
		local ok, n = pcall(C_Spell.GetSpellName, id)
		if ok and not IsSecret(n) and type(n) == "string" then return n end
	end
end

local function IsInterrupt(spellID)
	if not interruptName then
		interruptName = {}
		for _, id in ipairs(INTERRUPTS) do
			local n = SpellName(id)
			if n then interruptName[n] = true end
		end
	end
	if IsSecret(spellID) or type(spellID) ~= "number" then return false end
	local n = SpellName(spellID)
	return n ~= nil and interruptName[n] == true
end

-- the original only reports misses on these units (data/TargetGuids.lua)
local function Tracked(guid)
	if not guid then return false end
	for _, unit in ipairs(addon.TargetGuids()) do
		if Guid(unit) == guid then return true end
	end
	return false
end

-- what was said lately, so a fallback does not say it again
local said = {}
local function Say(key, text, color, size)
	local now = GetTime()
	if said[key] and now - said[key] < 1.5 then return end
	said[key] = now
	addon.print(text, color, size)
end

-- Optional (off by default, /snf): a sound for every miss of one of your spells (Parry, Block, Miss, Dodge, Immune,
-- Evade, Deflect, Reflect, Resist - not Absorb) and/or of your auto attacks. Plays the addon's own thud.mp3.
local missSoundAt = -100
function CL.MissSound()
	local now = GetTime()
	if now - missSoundAt < 0.15 then return end   -- a Multi-Shot's several misses: one sound
	missSoundAt = now
	CL.Debug("miss sound")
	addon.playSound("thud")
end

local petGUID, petDeadAt = nil, -100
local function PetDied()
	if GetTime() - petDeadAt < 5 then return end
	petDeadAt = GetTime()
	addon.print("Pet dead.", addon.Colors().RED, addon.Sizes().LARGE)
	addon.playSound("buzz")
end

---------------------------------------------------------------------------
-- one line of the Combat Log window
---------------------------------------------------------------------------
-- /snf debug: the raw lines and how they were read, kept in SpellNotificationsForeverDB.debugLog (last 300)
-- until it is turned off, so they can be read from the WTF folder after a /reload
function CL.Debug(text)
	if not addon.Opt("debug") then return end
	local db = SpellNotificationsForeverDB
	if type(db) ~= "table" then return end
	local log = db.debugLog
	if type(log) ~= "table" then log = {}; db.debugLog = log end
	log[#log + 1] = ("%.2f %s"):format(GetTime() % 10000, text)
	if #log > 330 then
		local kept = {}
		for i = #log - 299, #log do kept[#kept + 1] = log[i] end
		db.debugLog = kept
	end
end
local function Show(v)
	if IsSecret(v) then return "(secret)" end
	return tostring(v)
end

CL.linesSeen = 0
function CL.OnLine(message, _, _, _, order)
	local oldest = Enum and Enum.CombatLogMessageOrder and Enum.CombatLogMessageOrder.Oldest
	if oldest ~= nil and not IsSecret(order) and order == oldest then return end   -- old lines replayed on a refill
	CL.linesSeen = CL.linesSeen + 1
	if IsSecret(message) or type(message) ~= "string" or message:find("|K", 1, true) then   -- hidden by the game
		CL.hiddenAt = GetTime()
		CL.Debug("hidden " .. Show(message))
		return
	end
	CL.readableAt = GetTime()
	local ok, info = pcall(Parser.Parse, Parser, message)
	if addon.Opt("debug") then
		if not ok then CL.Debug("ERROR " .. tostring(info) .. " <- " .. message)
		elseif not info then CL.Debug("unread " .. message)
		else
			CL.Debug(("read kind=%s event=%s fromMe=%s toMe=%s melee=%s miss=%s spell=%s src=%s dest=%s me=%s <- %s"):format(
				Show(info.kind), Show(info.event), Show(info.fromMe), Show(info.toMe), Show(info.melee), Show(info.missType),
				Show(info.spell), Show(info.srcGUID), Show(info.destGUID), Show(Parser.playerGUID), message))
		end
	end
	if not ok or not info then return end
	local colors, sizes = addon.Colors(), addon.Sizes()
	local myPet = petGUID or Guid("pet")
	local fromPet = myPet ~= nil and info.srcGUID == myPet

	if info.kind == "interrupt" and (info.fromMe or fromPet) then
		local what = info.extraSpell or "a spell"
		Say("interrupt", "Interrupted " .. what .. ".", colors.GREEN, sizes.SMALL)

	elseif info.kind == "dispel" and info.fromMe then
		local what = info.extraSpell or "a spell"
		if info.stolen then
			addon.print("Stole " .. what .. ".", colors.YELLOW, sizes.SMALL)
		else
			-- a debuff taken off is a friend's (white), a buff taken off an enemy's (yellow), as the original colours them
			addon.print("Dispelled " .. what .. ".", info.aura == "BUFF" and colors.YELLOW or colors.WHITE, sizes.SMALL)
		end

	elseif info.kind == "miss" then
		local spellLine = info.spell and not info.melee and (info.event == nil or info.event == "SPELL_MISSED")
		-- the sound can also be had for your auto attacks (melee swing, Auto Shot); the message stays spells only, like
		-- the original
		local autoAttack = info.melee or info.event == "SWING_MISSED" or info.event == "RANGE_MISSED"
		local wanted = (spellLine and addon.Opt("missSoundSpells")) or (autoAttack and addon.Opt("missSoundAuto"))
		if info.fromMe and wanted and info.missType ~= "ABSORB" then CL.MissSound() end
		if info.fromMe and spellLine and info.missType ~= "ABSORB" and Tracked(info.destGUID) then
			local how = addon.MissTypes()[info.missType] or "missed"
			local text, color = CL.MissText(info.spell, how, info.school)
			addon.print(text, color, sizes.LARGE)
		elseif info.toMe and info.missType == "REFLECT" and info.spell then
			addon.print("Reflected " .. info.spell .. ".", colors.WHITE, sizes.SMALL)
		end

	elseif info.kind == "died" and myPet and (info.destGUID == myPet or info.srcGUID == myPet) then
		-- "X dies." names the one who died before the action word, so the reader may file it as the source
		PetDied()
	end
end

---------------------------------------------------------------------------
-- misses without a readable line
---------------------------------------------------------------------------
-- On Forever the game hides the whole text of the lines ("|Ky1878|k", seen with /snf debug), so
-- nothing above can read them. What is still there: UNIT_COMBAT says your target dodged/parried/... something, and
-- a hidden line arriving with it says it was something you did (the Combat Log shows "My actions"; your pet has no
-- lines there). Whether it was a spell or an auto attack: PLAYER_SWING (your swings and Auto Shots) and your last
-- cast. The same way BattleText Forever (MIT) tells your hits from others'.
local AVOID = { MISS = true, DODGE = true, PARRY = true, BLOCK = true, RESIST = true, IMMUNE = true, EVADE = true,
	DEFLECT = true, REFLECT = true }
local WITH_LINE = 0.35      -- a hidden line this close to the miss (before or after) makes it yours
local SWING_CLOSE = 0.25    -- a swing of yours this close before it: an auto attack
local CAST_CLOSE = 1.6      -- a cast of yours this long before it (a shot's flight): a spell
CL.hiddenAt, CL.readableAt, CL.swingAt, CL.castAt = -100, -100, -100, -100
CL.castName = nil

-- name: what the swing was ("Melee", or the cast's name: Auto Shot, Shoot, Throw)
function CL.OnSwing(name)
	CL.swingAt, CL.swingName = GetTime(), name or CL.MELEE
	CL.Debug("swing " .. CL.swingName)
end
CL.MELEE = "Melee"

-- auto attacks that come as a cast: Auto Shot, Shoot (wand, bow, gun, crossbow), Throw
local AUTO_CASTS = { [75] = true, [5019] = true, [3018] = true, [7918] = true, [7919] = true, [2764] = true }
function CL.OnCast(spellID)
	if IsSecret(spellID) or type(spellID) ~= "number" then return end
	if AUTO_CASTS[spellID] then
		CL.rangedName = SpellName(spellID) or CL.rangedName
		return CL.OnSwing(CL.rangedName)
	end
	CL.castAt, CL.castName = GetTime(), SpellName(spellID)
	CL.Debug("cast " .. tostring(CL.castName or spellID))
end

-- the spell's name in its school's colour, the rest of the message white. The school comes with UNIT_COMBAT (arcane
-- blue, the others in WoW's usual school colours). A mix of schools takes the first one found; no school known: gold.
local SCHOOL_COLORS = {
	{ 64, "4d9fff" },   -- Arcane: blue
	{ 4, "ff8000" },    -- Fire: orange
	{ 16, "80ffff" },   -- Frost: light blue
	{ 8, "4dff4d" },    -- Nature: green
	{ 32, "a080ff" },   -- Shadow: violet
	{ 2, "ffe680" },    -- Holy: light yellow
	{ 1, "ffd100" },    -- Physical: gold
}
function CL.SchoolHex(school)
	if not IsSecret(school) and type(school) == "number" and school > 0 then
		for _, sc in ipairs(SCHOOL_COLORS) do
			if bit and bit.band and bit.band(school, sc[1]) ~= 0 then return sc[2] end
		end
	end
	return "ffd100"
end
-- Evaded and immune: the whole message red, as the original shows them
CL.RED_HOW = { evaded = true, immune = true }
function CL.MissText(spellName, how, school)
	if CL.RED_HOW[how] then return spellName .. " " .. how .. ".", addon.Colors().RED end
	return "|cff" .. CL.SchoolHex(school) .. spellName .. "|r " .. how .. ".", addon.Colors().WHITE
end

local function Decide(at, missType, school)
	-- a readable line around it: the line said it already (CL.OnLine)
	if math.abs(CL.readableAt - at) <= WITH_LINE then return CL.Debug("unit miss: a readable line has it") end
	if math.abs(CL.hiddenAt - at) > WITH_LINE then return CL.Debug("unit miss: no line of yours with it (not yours)") end
	local sinceCast, sinceSwing = at - CL.castAt, at - CL.swingAt
	-- a cast right with it is the spell (Raptor Strike / Heroic Strike come with a swing); else a swing right with
	-- it; else a cast a moment before (a shot's flight); else an auto attack
	local spell = sinceCast >= 0 and sinceCast <= SWING_CLOSE
	local auto = not spell and sinceSwing >= 0 and sinceSwing <= SWING_CLOSE
	if not (spell or auto) then spell = sinceCast >= 0 and sinceCast <= CAST_CLOSE end
	if not spell then auto = true end
	CL.Debug(("unit miss %s -> %s"):format(missType, auto and "auto attack" or ("spell " .. tostring(CL.castName))))
	local wanted = (spell and addon.Opt("missSoundSpells")) or (auto and addon.Opt("missSoundAuto"))
	if wanted and missType ~= "ABSORB" then CL.MissSound() end
	local how = addon.MissTypes()[missType] or "missed"
	if spell and CL.castName then
		-- like the original's message for a spell of yours on your target
		local text, color = CL.MissText(CL.castName, how, school)
		addon.print(text, color, addon.Sizes().LARGE)
	elseif auto and CL.RED_HOW[how] then
		-- a mob that evades (or is immune) when you hit it: said in red for auto attacks too
		local text, color = CL.MissText(CL.swingName or CL.MELEE, how, school)
		addon.print(text, color, addon.Sizes().LARGE)
	end
end

-- the units the original reports misses on (data/TargetGuids.lua), without you, your pet and your group
local WATCHED = { target = true, focus = true, targettarget = true, pettarget = true, mouseover = true,
	mouseovertarget = true, arena1 = true, arena2 = true, arena3 = true, arena4 = true, arena5 = true }
local lastAt, lastAction = -1, nil
function CL.OnUnitCombat(unit, action, school)
	if IsSecret(unit) or type(unit) ~= "string" then return end
	if unit == "player" then return CL.OnPlayerCombat(action) end
	if IsSecret(action) or type(action) ~= "string" or not AVOID[action] or not WATCHED[unit] then return end
	local ok, same = pcall(UnitIsUnit, unit, "player")
	if ok and same == true then return end
	local at = GetTime()
	-- one miss seen under two names (your target is also your mouseover): once
	if at == lastAt and action == lastAction then return end
	lastAt, lastAction = at, action
	CL.Debug("UNIT_COMBAT " .. unit .. " " .. action .. " school " .. Show(school))
	-- the line may come just after the event: decided a moment later
	C_Timer.After(WITH_LINE, function() Decide(at, action, school) end)
end

---------------------------------------------------------------------------
-- dispels and reflects without a readable line
---------------------------------------------------------------------------
-- Dispels: the original says "Dispelled <aura>." (white on a friend, yellow on an enemy). Without the lines, the
-- auras on the unit are noted right before your dispel goes off (UNIT_SPELLCAST_SENT) and looked at again just after
-- it: the one that went is what you dispelled. If the game keeps the auras from addons (it can in instances), nothing
-- is said. Player dispels on Forever from the client data (effect "dispel", class skills): Dispel Magic,
-- Cleanse, Purify, Remove Curse, Remove Lesser Curse, Cure Poison, Cure Disease, Purge, Tranquilizing Shot, Shield
-- Slam; every rank by name. (No Spellsteal on Forever; Abolish Poison/Disease and Improved Mend Pet cleanse over time.)
local DISPELS = { 527, 4987, 1152, 2782, 475, 526, 8946, 528, 2870, 370, 19801, 23922 }
local dispelName
local function IsDispel(spellID)
	if not dispelName then
		dispelName = {}
		for _, id in ipairs(DISPELS) do
			local n = SpellName(id)
			if n then dispelName[n] = true end
		end
	end
	if IsSecret(spellID) or type(spellID) ~= "number" then return false end
	local n = SpellName(spellID)
	return n ~= nil and dispelName[n] == true
end
CL.IsDispel = IsDispel

local function AuraNames(unit, filter)
	local names = {}
	for i = 1, 40 do
		local name
		if C_UnitAuras and C_UnitAuras.GetAuraDataByIndex then
			local ok, data = pcall(C_UnitAuras.GetAuraDataByIndex, unit, i, filter)
			if not ok then return nil end
			if not data then break end
			if IsSecret(data) then return nil end
			name = data.name
		elseif UnitAura then
			local ok, n = pcall(UnitAura, unit, i, filter)
			if not ok then return nil end
			if n == nil then break end
			name = n
		else
			return nil
		end
		if IsSecret(name) then return nil end
		if type(name) == "string" then names[name] = (names[name] or 0) + 1 end
	end
	return names
end

-- the unit a dispel lands on: an enemy target (its buffs), a friendly target (its debuffs), or you
local function DispelUnit()
	if UnitExists and UnitExists("target") then
		local ok, enemy = pcall(UnitCanAttack, "player", "target")
		if ok and not IsSecret(enemy) then return "target", enemy == true end
		return nil
	end
	return "player", false
end

local pendingDispel
function CL.OnSent(spellID, castGUID)
	if not IsDispel(spellID) then return end
	local unit, enemy = DispelUnit()
	if not unit then return end
	local filter = enemy and "HELPFUL" or "HARMFUL"
	local before = AuraNames(unit, filter)
	pendingDispel = before and { unit = unit, enemy = enemy, filter = filter, before = before, guid = Guid(unit),
		cast = (not IsSecret(castGUID)) and castGUID or nil, at = GetTime() } or nil
	CL.Debug("dispel sent on " .. unit .. (before and "" or " (auras hidden)"))
end

function CL.OnDispelCast(spellID, castGUID)
	local p = pendingDispel
	if not p or not IsDispel(spellID) or GetTime() - p.at > 3 then return end
	if p.cast and not IsSecret(castGUID) and castGUID ~= p.cast then return end
	pendingDispel = nil
	C_Timer.After(0.25, function()
		if Guid(p.unit) ~= p.guid then return end      -- the target changed meanwhile
		local after = AuraNames(p.unit, p.filter)
		if not after then return end
		for name, n in pairs(p.before) do
			if (after[name] or 0) < n then
				addon.print("Dispelled " .. name .. ".", p.enemy and addon.Colors().YELLOW or addon.Colors().WHITE,
					addon.Sizes().SMALL)
				return
			end
		end
	end)
end

-- Reflected at you: "Reflected <spell>." (white). UNIT_COMBAT says you reflected something; the spell is the one your
-- target or focus was casting
local enemyCast, enemyCastAt = nil, -100
function CL.OnEnemyCast(spellID)
	if IsSecret(spellID) or type(spellID) ~= "number" then return end
	enemyCast, enemyCastAt = SpellName(spellID), GetTime()
end
function CL.OnPlayerCombat(action)
	if IsSecret(action) or action ~= "REFLECT" then return end
	local what = (GetTime() - enemyCastAt < 4) and enemyCast or nil
	Say("reflect", "Reflected " .. (what or "a spell") .. ".", addon.Colors().WHITE, addon.Sizes().SMALL)
end

---------------------------------------------------------------------------
-- keeping the lines coming
---------------------------------------------------------------------------
local function KeepFlowing()
	if C_CombatLog and C_CombatLog.SetFilteredEventsEnabled then pcall(C_CombatLog.SetFilteredEventsEnabled, true) end
end

local hooked
local function HookLogWindow()
	local log = _G.COMBATLOG or _G.ChatFrame2
	if hooked or not (log and log.HookScript) then return end
	hooked = true
	log:HookScript("OnHide", KeepFlowing)
end

---------------------------------------------------------------------------
-- fallbacks and events
---------------------------------------------------------------------------
local myInterruptAt = -100
local f = CreateFrame("Frame")
for _, ev in ipairs({ "PLAYER_LOGIN", "PLAYER_ENTERING_WORLD", "PLAYER_REGEN_DISABLED", "PLAYER_REGEN_ENABLED",
	"COMBAT_LOG_MESSAGE", "UNIT_SPELLCAST_INTERRUPTED", "UNIT_PET", "ADDON_LOADED" }) do
	pcall(f.RegisterEvent, f, ev)
end
pcall(f.RegisterUnitEvent, f, "UNIT_SPELLCAST_SUCCEEDED", "player", "pet")
pcall(f.RegisterEvent, f, "UNIT_COMBAT")
pcall(f.RegisterUnitEvent, f, "UNIT_SPELLCAST_SENT", "player")
pcall(f.RegisterUnitEvent, f, "UNIT_SPELLCAST_START", "target", "focus")
pcall(f.RegisterUnitEvent, f, "UNIT_SPELLCAST_CHANNEL_START", "target", "focus")
pcall(f.RegisterEvent, f, "PLAYER_SWING")
pcall(f.RegisterUnitEvent, f, "UNIT_HEALTH", "pet")

local hinted, linesAtFight = false, 0
f:SetScript("OnEvent", function(_, event, a1, a2, a3, a4, a5)
	if event == "COMBAT_LOG_MESSAGE" then
		CL.OnLine(a1, a2, a3, a4, a5)
	elseif event == "UNIT_COMBAT" then
		CL.OnUnitCombat(a1, a2, a5)
	elseif event == "PLAYER_SWING" then
		-- swing type 0/1: main/off hand; otherwise a ranged swing (named after your last Auto Shot/Shoot/Throw)
		local ranged = not IsSecret(a2) and type(a2) == "number" and a2 ~= 0 and a2 ~= 1
		CL.OnSwing(ranged and (CL.rangedName or "Auto Shot") or CL.MELEE)
	elseif event == "UNIT_SPELLCAST_SENT" then
		CL.OnSent(a4, a3)
	elseif event == "UNIT_SPELLCAST_START" or event == "UNIT_SPELLCAST_CHANNEL_START" then
		CL.OnEnemyCast(a3)
	elseif event == "UNIT_SPELLCAST_SUCCEEDED" then
		if IsInterrupt(a3) then myInterruptAt = GetTime() end
		if a1 == "player" then CL.OnCast(a3); CL.OnDispelCast(a3, a2) end
		if a1 ~= "player" and a1 ~= "pet" then CL.OnEnemyCast(a3) end
	elseif event == "UNIT_SPELLCAST_INTERRUPTED" then
		-- a cast of the unit we interrupted, stopped within half a second of our interrupt; said only if no line did
		if GetTime() - myInterruptAt > 0.6 or IsSecret(a1) or a1 == "player" or a1 == "pet" then return end
		local what = (not IsSecret(a3) and type(a3) == "number") and SpellName(a3) or nil
		myInterruptAt = -100
		C_Timer.After(0.3, function()
			Say("interrupt", "Interrupted " .. (what or "a spell") .. ".", addon.Colors().GREEN, addon.Sizes().SMALL)
		end)
	elseif event == "UNIT_PET" or event == "UNIT_HEALTH" then
		local g = Guid("pet")
		if g then petGUID = g end
		if event == "UNIT_HEALTH" and petGUID then
			local ok, dead = pcall(UnitIsDead, "pet")
			if ok and not IsSecret(dead) and dead == true then PetDied() end
		end
	elseif event == "PLAYER_REGEN_DISABLED" then
		KeepFlowing()
		linesAtFight = CL.linesSeen
		CL.Debug("fight start, lines so far " .. CL.linesSeen)
	elseif event == "PLAYER_REGEN_ENABLED" then
		CL.Debug("fight end, lines in this fight " .. (CL.linesSeen - linesAtFight))
		-- a whole fight without one line: the game's Combat Log filter never loaded this session
		if not hinted and CL.linesSeen == linesAtFight and CL.linesSeen == 0 then
			hinted = true
			print("|cff80ff00SpellNotifications:|r click the Combat Log chat tab once so the game sends its combat lines "
				.. "(the miss notifications need them).")
		end
	elseif event == "ADDON_LOADED" then
		if a1 == "Blizzard_CombatLog" then HookLogWindow() end
	else   -- PLAYER_LOGIN, PLAYER_ENTERING_WORLD
		HookLogWindow()
		KeepFlowing()
		CL.Debug(event .. ": C_CombatLog " .. tostring(C_CombatLog ~= nil) .. ", SetFilteredEventsEnabled "
			.. tostring(C_CombatLog ~= nil and C_CombatLog.SetFilteredEventsEnabled ~= nil) .. ", locale " .. tostring(GetLocale and GetLocale()))
		local g = Guid("pet")
		if g then petGUID = g end
	end
end)
