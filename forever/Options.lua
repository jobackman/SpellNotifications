-- SpellNotifications on WoW Forever: settings.
-- Options > AddOns > SpellNotifications, or /snf. Saved account-wide in SpellNotificationsForeverDB.
local _, addon = ...

local DEFAULTS = {
	missSoundSpells = false,  -- optional miss sound for your spells
	missSoundAuto = false,    -- optional miss sound for your auto attacks (melee swing, Auto Shot)
	debug = false,            -- /snf debug: record the combat lines (forever/CombatLines.lua)
}

-- read when needed (no copy kept): a missing key is its default
function addon.Opt(key)
	local db = SpellNotificationsForeverDB
	if type(db) ~= "table" or db[key] == nil then return DEFAULTS[key] end
	return db[key]
end

local function SetOpt(key, value)
	if type(SpellNotificationsForeverDB) ~= "table" then SpellNotificationsForeverDB = {} end
	SpellNotificationsForeverDB[key] = value
end

local de = (GetLocale and GetLocale() == "deDE")
local TEXT = de and {
	sub = "Einstellungen für WoW Forever",
	head = "Fehlschlag-Sound (thud.mp3)",
	missSoundSpells = "Sound, wenn einer deiner Zauber verfehlt (Ausweichen, Parieren, Widerstehen, ...)",
	missSoundAuto = "Sound, wenn dein Auto-Angriff verfehlt (Nahkampf und Auto-Schuss)",
	on = "an", off = "aus",
	debugOn = "Aufzeichnung AN: kurz kämpfen (Nahkampf + ein Zauber), dann /reload. /snf debug schaltet sie wieder aus.",
	debugOff = "Aufzeichnung AUS (gelöscht).",
} or {
	sub = "Settings for WoW Forever",
	head = "Miss sound (thud.mp3)",
	missSoundSpells = "Sound when one of your spells misses (dodge, parry, resist, ...)",
	missSoundAuto = "Sound when your auto attack misses (melee and Auto Shot)",
	on = "on", off = "off",
	debugOn = "Recording ON: fight briefly (melee + one spell), then /reload. /snf debug turns it off again.",
	debugOff = "Recording OFF (cleared).",
}
local ORDER = { "missSoundSpells", "missSoundAuto" }

local frame, category
local checks = {}

local function Refresh()
	for _, c in ipairs(checks) do c:SetChecked(addon.Opt(c.key) and true or false) end
end

local function Build()
	if frame then return end
	frame = CreateFrame("Frame", "SpellNotificationsForeverOptions", UIParent)
	frame:Hide()
	local title = frame:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
	title:SetPoint("TOPLEFT", 16, -16)
	title:SetText("SpellNotifications")
	local sub = frame:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
	sub:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -6)
	sub:SetText(TEXT.sub)
	local head = frame:CreateFontString(nil, "ARTWORK", "GameFontNormal")
	head:SetPoint("TOPLEFT", 16, -66)
	head:SetText(TEXT.head)
	local y = -88
	for _, key in ipairs(ORDER) do
		local c = CreateFrame("CheckButton", nil, frame, "UICheckButtonTemplate")
		c:SetPoint("TOPLEFT", 16, y)
		c.key = key
		c.label = type(c.Text) == "table" and c.Text or frame:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
		c.label:ClearAllPoints()
		c.label:SetPoint("LEFT", c, "RIGHT", 4, 0)
		c.label:SetFontObject("GameFontHighlight")
		c.label:SetText(TEXT[key])
		c:SetScript("OnClick", function(self) SetOpt(self.key, self:GetChecked() and true or false) end)
		checks[#checks + 1] = c
		y = y - 28
	end
	frame:SetScript("OnShow", Refresh)
	if Settings and Settings.RegisterCanvasLayoutCategory and Settings.RegisterAddOnCategory then
		category = Settings.RegisterCanvasLayoutCategory(frame, "SpellNotifications")
		Settings.RegisterAddOnCategory(category)
	end
end

local function Open()
	Build()
	if Settings and Settings.OpenToCategory and category then
		Settings.OpenToCategory(category.GetID and category:GetID() or category.ID)
	end
	Refresh()
end

-- the page is made at login so it is in the AddOns list; nothing runs after that
local f = CreateFrame("Frame")
f:RegisterEvent("PLAYER_LOGIN")
f:SetScript("OnEvent", function(self)
	self:UnregisterAllEvents()
	pcall(Build)
end)

SLASH_SPELLNOTIFICATIONSFOREVER1 = "/snf"
SlashCmdList.SPELLNOTIFICATIONSFOREVER = function(msg)
	msg = (msg or ""):lower():match("^%s*(.-)%s*$")
	-- "/snf auto" / "/snf spells" switch one option; anything else opens the page
	local key = (msg == "auto" and "missSoundAuto") or (msg == "spells" and "missSoundSpells") or nil
	if msg == "debug" then
		local on = not addon.Opt("debug")
		SetOpt("debug", on)
		if not on then SpellNotificationsForeverDB.debugLog = nil end
		print("|cff80ff00SpellNotifications:|r " .. (on and TEXT.debugOn or TEXT.debugOff))
		if on and addon.CombatLines then addon.CombatLines.Debug("debug on, lines so far " .. addon.CombatLines.linesSeen) end
	elseif key then
		SetOpt(key, not addon.Opt(key))
		Refresh()
		print("|cff80ff00SpellNotifications:|r " .. TEXT[key] .. ": " .. (addon.Opt(key) and TEXT.on or TEXT.off))
	else
		Open()
	end
end

addon.Options = { Open = Open, Build = Build, _Frame = function() return frame end, _Checks = function() return checks end }
