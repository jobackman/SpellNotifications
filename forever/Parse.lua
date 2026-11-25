-- Combat log line reader for SpellNotifications on WoW Forever.
-- Taken from BattleText Forever 1.41.0 by severd8 (MIT License, see LICENSE-BattleTextForever.txt), unchanged
-- except where marked "SN:". Forever gives addons no combat log events; this reads the finished lines of the
-- Combat Log window (event COMBAT_LOG_MESSAGE) instead.

-- BattleText Forever: reads the game's combat log lines.
--
-- WoW: Forever doesn't let addons listen to the combat log itself. What an addon
-- does get is each finished line of the Combat Log window. On screen it reads
--
--   Your Claw hit Bristleback Hunter Faust 50 Physical. (Critical)
--
-- and underneath, every part is a link that says what it is:
--
--   |Hunit:<guid>:<name>|hYour|h |Hspell:16827:0:SPELL_DAMAGE|hClaw|h
--   |Haction:SPELL_DAMAGE|hhit|h |Hunit:<guid>:<name>|hBristleback Hunter Faust|h 50 Physical. (Critical)
--
-- The links are read first: they name the event, the spell and who is who, in
-- any language. If a line ever arrives without them, the words are read instead.
-- The other creature's name is scrambled by the game, so it's never used.

local _, ns = ...
local Parser = {}
ns.Parser = Parser

-- What each combat log event is shown as
local EVENT_KIND = {
    SWING_DAMAGE = "damage", RANGE_DAMAGE = "damage", SPELL_DAMAGE = "damage", SPELL_PERIODIC_DAMAGE = "damage",
    SPELL_BUILDING_DAMAGE = "damage", DAMAGE_SHIELD = "damage", DAMAGE_SPLIT = "damage",
    ENVIRONMENTAL_DAMAGE = "damage",
    SWING_MISSED = "miss", RANGE_MISSED = "miss", SPELL_MISSED = "miss", SPELL_PERIODIC_MISSED = "miss",
    DAMAGE_SHIELD_MISSED = "miss",
    SPELL_HEAL = "heal", SPELL_PERIODIC_HEAL = "heal", SPELL_BUILDING_HEAL = "heal",
    SPELL_ENERGIZE = "energize", SPELL_PERIODIC_ENERGIZE = "energize",
    PARTY_KILL = "kill", UNIT_DIED = "died", UNIT_DESTROYED = "died", UNIT_DISSIPATES = "died",
    SPELL_INTERRUPT = "interrupt", SPELL_DISPEL = "dispel", SPELL_STOLEN = "dispel",
}
-- The same list in a fixed order, for reading the words
local EVENT_ORDER = {
    "SWING_DAMAGE", "RANGE_DAMAGE", "SPELL_DAMAGE", "SPELL_PERIODIC_DAMAGE", "SPELL_BUILDING_DAMAGE",
    "DAMAGE_SHIELD", "DAMAGE_SPLIT", "ENVIRONMENTAL_DAMAGE",
    "SWING_MISSED", "RANGE_MISSED", "SPELL_MISSED", "SPELL_PERIODIC_MISSED", "DAMAGE_SHIELD_MISSED",
    "SPELL_HEAL", "SPELL_PERIODIC_HEAL", "SPELL_BUILDING_HEAL", "SPELL_ENERGIZE", "SPELL_PERIODIC_ENERGIZE",
    "PARTY_KILL", "UNIT_DIED", "UNIT_DESTROYED", "UNIT_DISSIPATES",
    "SPELL_INTERRUPT", "SPELL_DISPEL", "SPELL_STOLEN",
}
local MISS_EVENTS = { "SWING_MISSED", "RANGE_MISSED", "SPELL_MISSED", "SPELL_PERIODIC_MISSED", "DAMAGE_SHIELD_MISSED" }
-- The ways an attack can fail, and the game's word for each in a combat log line
local MISS_WORDS = {
    MISS = "Missed", DODGE = "Dodged", PARRY = "Parried", BLOCK = "Blocked", RESIST = "Resisted",
    ABSORB = "Absorbed", IMMUNE = "Immune", EVADE = "Evaded", DEFLECT = "Deflected", REFLECT = "Reflected",
    MISFIRE = "Misfired",
}
-- The game spells two of them both ways in its text keys
local MISS_KEYS = {
    MISS = { "MISS" }, DODGE = { "DODGE" }, PARRY = { "PARRY" }, BLOCK = { "BLOCK" }, RESIST = { "RESIST" },
    ABSORB = { "ABSORB" }, IMMUNE = { "IMMUNE" }, EVADE = { "EVADE", "EVADED" }, DEFLECT = { "DEFLECT", "DEFLECTED" },
    REFLECT = { "REFLECT" }, MISFIRE = { "MISFIRE" },
}
local AMOUNT_RESULTS = { blocked = "BLOCK", absorbed = "ABSORB", resisted = "RESIST", overkill = "OVERKILLING",
    overheal = "OVERHEALING" }

-- The game's text in English, used by the offline tests and if a string is ever missing
local FALLBACK = {
    UNIT_YOU_SOURCE = "You", UNIT_YOU_SOURCE_POSSESSIVE = "Your",
    UNIT_YOU_DEST = "You", UNIT_YOU_DEST_POSSESSIVE = "Your",
    ACTION_SWING = "Melee",
    ACTION_SWING_DAMAGE = "hit", ACTION_RANGE_DAMAGE = "hit", ACTION_SPELL_DAMAGE = "hit",
    ACTION_SPELL_PERIODIC_DAMAGE = "damaged", ACTION_SPELL_BUILDING_DAMAGE = "strikes",
    ACTION_DAMAGE_SHIELD = "damages", ACTION_DAMAGE_SPLIT = "shared damage",
    ACTION_ENVIRONMENTAL_DAMAGE = "damaged",
    ACTION_SWING_MISSED = "missed", ACTION_RANGE_MISSED = "missed", ACTION_SPELL_MISSED = "missed",
    ACTION_SPELL_PERIODIC_MISSED = "missed", ACTION_DAMAGE_SHIELD_MISSED = "missed",
    ACTION_SPELL_HEAL = "healed", ACTION_SPELL_PERIODIC_HEAL = "healed", ACTION_SPELL_BUILDING_HEAL = "repaired",
    ACTION_SPELL_ENERGIZE = "energized", ACTION_SPELL_PERIODIC_ENERGIZE = "energized",
    ACTION_PARTY_KILL = "killed", ACTION_UNIT_DIED = "died", ACTION_UNIT_DESTROYED = "destroyed",
    ACTION_UNIT_DISSIPATES = "dissipates",
    ACTION_SPELL_INTERRUPT = "interrupted", ACTION_SPELL_DISPEL = "dispelled", ACTION_SPELL_STOLEN = "stole",
    ACTION_SPELL_DISPEL_BUFF = "dispelled", ACTION_SPELL_DISPEL_DEBUFF = "cleansed",
    ACTION_SPELL_MISSED_RESIST = "resisted", ACTION_SPELL_MISSED_REFLECT = "reflected",
    TEXT_MODE_A_STRING_RESULT_CRITICAL = "(Critical)", TEXT_MODE_A_STRING_RESULT_CRITICAL_SPELL = "(Critical)",
    TEXT_MODE_A_STRING_RESULT_GLANCING = "(Glancing)", TEXT_MODE_A_STRING_RESULT_CRUSHING = "(Crushing)",
    TEXT_MODE_A_STRING_RESULT_BLOCK = "(%s Blocked)", TEXT_MODE_A_STRING_RESULT_ABSORB = "(%s Absorbed)",
    TEXT_MODE_A_STRING_RESULT_RESIST = "(%s Resisted)", TEXT_MODE_A_STRING_RESULT_OVERKILLING = "(%s Overkill)",
    TEXT_MODE_A_STRING_RESULT_OVERHEALING = "(%s Overhealed)",
}

local function IsSecret(v) return issecretvalue ~= nil and issecretvalue(v) == true end

local function Text(key)
    local v = _G[key]
    if not IsSecret(v) and type(v) == "string" and v ~= "" then return v end
    if FALLBACK[key] then return FALLBACK[key] end
    local miss = key:match("^ACTION_[%u_]-_MISSED_(%u+)$")
    return miss and MISS_WORDS[miss] or nil
end

local function Trim(s) return (s:gsub("^%s+", ""):gsub("%s+$", "")) end
local function Escape(s) return (s:gsub("[%^%$%(%)%%%.%[%]%*%+%-%?]", "%%%0")) end
local function NoParens(s) return Trim((s:gsub("^%s*%(", ""):gsub("%)%s*$", ""))) end
local function NoBrackets(s) return Trim(s:match("^%s*%[(.*)%]%s*$") or s) end
local function ToNumber(s) return tonumber((s:gsub("[^%d]", ""))) end

-- Colour codes and icons aren't part of the words
local function Plain(s)
    s = s:gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|cn[^:|]*:", ""):gsub("|r", "")
    return (s:gsub("|T.-|t", ""):gsub("|A.-|a", ""))
end
local function NoLinks(s) return (s:gsub("|H.-|h(.-)|h", "%1")) end

-- Reads the game's text once (after login, when it's all loaded)
function Parser:Init()
    self.your = Text("UNIT_YOU_SOURCE_POSSESSIVE")
    self.you = Text("UNIT_YOU_SOURCE")
    self.youDest = Text("UNIT_YOU_DEST")
    self.yourDest = Text("UNIT_YOU_DEST_POSSESSIVE")
    self.melee = Text("ACTION_SWING")
    self:AddSeparator(_G.LARGE_NUMBER_SEPERATOR)
    if UnitGUID then
        local ok, guid = pcall(UnitGUID, "player")
        if ok and not IsSecret(guid) and type(guid) == "string" then self.playerGUID = guid end
    end

    -- How an attack failed, by the game's word for it: "(Dodged)", "Tick Dodged", "resisted"
    self.missByText = {}
    for missType, keys in pairs(MISS_KEYS) do
        self.missByText[MISS_WORDS[missType]:lower()] = missType
        for _, event in ipairs(MISS_EVENTS) do
            for _, key in ipairs(keys) do
                local word = Text("ACTION_" .. event .. "_" .. key)
                if word and not word:find("%", 1, true) then self.missByText[NoParens(word):lower()] = missType end
            end
        end
    end

    -- For reading the words: the action words, longest first
    self.words, self.byWord = {}, {}
    local function AddWord(word, kind, missType, split)
        if not word or self.byWord[word] then return end
        local w = { text = word, kind = kind, missType = missType, split = split }
        self.byWord[word] = w
        self.words[#self.words + 1] = w
    end
    for _, event in ipairs(EVENT_ORDER) do
        AddWord(Text("ACTION_" .. event), EVENT_KIND[event], nil, event == "DAMAGE_SPLIT" or nil)
    end
    AddWord(Text("ACTION_SPELL_DISPEL_BUFF"), "dispel")
    AddWord(Text("ACTION_SPELL_DISPEL_DEBUFF"), "dispel")
    -- A spell that fails says how in place of the action: "Your Moonfire resisted X."
    for missType, keys in pairs(MISS_KEYS) do
        for _, key in ipairs(keys) do AddWord(Text("ACTION_SPELL_MISSED_" .. key), "miss", missType) end
    end
    table.sort(self.words, function(a, b)
        if #a.text ~= #b.text then return #a.text > #b.text end
        return a.text < b.text
    end)

    self.crit = { [NoParens(Text("TEXT_MODE_A_STRING_RESULT_CRITICAL"))] = true,
        [NoParens(Text("TEXT_MODE_A_STRING_RESULT_CRITICAL_SPELL"))] = true }
    self.glancing = NoParens(Text("TEXT_MODE_A_STRING_RESULT_GLANCING"))
    self.crushing = NoParens(Text("TEXT_MODE_A_STRING_RESULT_CRUSHING"))
    -- "(%s Blocked)" -> a pattern that captures the number
    self.amountPatterns = {}
    for field, key in pairs(AMOUNT_RESULTS) do
        local fmt = NoParens(Text("TEXT_MODE_A_STRING_RESULT_" .. key))
        local pattern = Escape(fmt):gsub("%%%%%d*%%?%$?[sd]", "(%%d.-)")
        self.amountPatterns[field] = "^" .. pattern .. "$"
    end
    self.ready = true
end

-- A whole number at the start of `s`, however the game groups its digits
-- ("1,234", "1.234", "1 234"). Returns the number and what follows it.
local SEPARATORS = { ",", ".", " ", "\194\160", "\226\128\175", "'" }
-- The game's own separator for this language, if it's one not listed
function Parser:AddSeparator(sep)
    if IsSecret(sep) or type(sep) ~= "string" or sep == "" then return end
    for _, known in ipairs(SEPARATORS) do
        if known == sep then return end
    end
    table.insert(SEPARATORS, 1, sep)
end
local function ReadAmount(s)
    local digits = s:match("^%d+")
    if not digits then return nil, s end
    local pos = #digits + 1
    local more = #digits <= 3
    while more do
        more = false
        for _, sep in ipairs(SEPARATORS) do
            local from = pos + #sep
            if s:sub(pos, from - 1) == sep and s:find("^%d%d%d", from) and not s:find("^%d%d%d%d", from) then
                digits = digits .. s:sub(from, from + 2)
                pos = from + 3
                more = true
                break
            end
        end
    end
    return tonumber(digits), s:sub(pos)
end

-- One note from the end of a line: "Critical", "3 Blocked", "Dodged"
function Parser:ReadNote(info, note)
    if self.crit[note] then
        info.crit = true
    elseif note == self.glancing then
        info.glancing = true
    elseif note == self.crushing then
        info.crushing = true
    else
        for field, pattern in pairs(self.amountPatterns) do
            local n = note:match(pattern)
            if n then
                info[field] = ToNumber(n)
                return
            end
        end
        local missType = self.missByText[note:lower()]
        if missType then info.noteMiss = missType end
    end
end

-- Settles how an attack failed, from everything the line said
function Parser:Finish(info, verb)
    -- A hit for nothing is a miss ("hits X for 0. (52 Absorbed)"), never "Heroic Strike 0"
    if info.kind == "damage" and info.amount == 0 then info.kind = "miss" end
    if info.kind == "miss" then
        info.missType = info.noteMiss
            or (info.blocked and "BLOCK") or (info.resisted and "RESIST") or (info.absorbed and "ABSORB")
            or (verb and self.missByText[verb:lower()]) or "MISS"
    end
    info.noteMiss = nil
    return info
end

---------------------------------------------------------------------------
-- Reading the links
---------------------------------------------------------------------------
function Parser:ParseLinks(line)
    local links, pos = {}, 1
    while true do
        local s, e, kind, data, text = line:find("|H(%a+):?(.-)|h(.-)|h", pos)
        if not s then break end
        if kind ~= "icon" then
            links[#links + 1] = { kind = kind, data = data, text = NoBrackets(Plain(text)), last = e }
        end
        pos = e + 1
    end
    -- The action ("hit", "healed") is the last action link, and names the event
    local verb
    for i = #links, 1, -1 do
        if links[i].kind == "action" then verb = i break end
    end
    if not verb then return nil end
    local event = links[verb].data
    local kind = EVENT_KIND[event]
    if not kind then return nil end

    local info = { kind = kind, event = event }
    if event:find("PERIODIC", 1, true) then info.periodic = true end
    if event == "DAMAGE_SPLIT" then info.split = true end

    local tailFrom = links[verb].last
    if kind == "dispel" then
        -- A buff or a debuff: the game words them differently ("dispelled", "cleansed")
        if event == "SPELL_STOLEN" then
            info.stolen = true
            info.aura = "BUFF"
        else
            local word, buff, debuff = links[verb].text, Text("ACTION_SPELL_DISPEL_BUFF"), Text("ACTION_SPELL_DISPEL_DEBUFF")
            if buff ~= debuff then
                if word == debuff then info.aura = "DEBUFF" elseif word == buff then info.aura = "BUFF" end
            end
        end
    end
    for i, link in ipairs(links) do
        if i < verb then
            if link.kind == "unit" then
                info.srcGUID = link.data:match("^([^:]*)")
                if link.text == self.your or link.text == self.you
                    or (self.playerGUID and info.srcGUID == self.playerGUID) then
                    info.fromMe = true
                end
            elseif link.kind == "spell" then
                if link.text ~= "" then info.spell = link.text end
                local id = tonumber(link.data:match("^(%d+)"))
                if id and id > 0 then info.spellId = id end
            elseif link.kind == "action" then
                -- A name that isn't a spell: "Melee", "Auto Shot", "Falling"
                if event:sub(1, 5) == "SWING" then
                    info.melee = true
                elseif link.text ~= "" then
                    info.spell = link.text
                end
            end
        -- SN: an interrupt names the stopped spell after the action as well ("You interrupted X's Frostbolt")
        elseif i > verb and link.kind == "spell" and (kind == "dispel" or kind == "interrupt") and not info.extraSpell then
            -- What a dispel took off: "Your Cleanse cleansed X's Corruption."
            if link.text ~= "" then info.extraSpell = link.text end
            local id = tonumber(link.data:match("^(%d+)"))
            if id and id > 0 then info.extraSpellId = id end
        elseif i > verb and link.kind == "unit" and not info.destGUID then
            info.destGUID = link.data:match("^([^:]*)")
            if link.text == self.youDest or link.text == self.yourDest
                or (self.playerGUID and info.destGUID == self.playerGUID) then
                info.toMe = true
            end
            tailFrom = link.last
        end
    end

    -- After the last name: "50 Physical. (1 Blocked) (Critical)"
    local tail = Trim(NoLinks(Plain(line:sub(tailFrom + 1))))
    local notes = tail
    if kind == "damage" or kind == "heal" or kind == "energize" then
        local amount, rest = ReadAmount(tail)
        if amount then
            info.amount = amount
            local unit, after = rest:match("^%s*(.-)%.%s*(.*)$")
            if not unit then unit, after = rest, "" end
            unit = NoParens(Trim(unit))
            if unit ~= "" then info.unit = unit end
            notes = after
        end
    end
    for note in notes:gmatch("%b()") do self:ReadNote(info, Trim(note:sub(2, -2))) end
    return self:Finish(info, links[verb].text)
end

---------------------------------------------------------------------------
-- Reading the words (a line with no links)
---------------------------------------------------------------------------
-- The action word in `text`: its position, and the word's entry.
--   atStart  the sentence has no spell, so the word comes first ("You killed ...")
--   last     take the last one found instead of the first. Your own lines have
--            your spell before the word and a scrambled name after it; anyone
--            else's have the scrambled name before it.
function Parser:FindAction(text, atStart, last)
    local bestPos, bestWord
    for _, w in ipairs(self.words) do
        local pos
        if atStart then
            if text == w.text or text:sub(1, #w.text + 1) == w.text .. " " then pos = 1 end
        else
            local from = 1
            while true do
                local s = text:find(" " .. w.text .. " ", from, true)
                if not s then break end
                pos = s + 1
                if not last then break end
                from = s + 1
            end
            if (not pos or last) and #text > #w.text and text:sub(-#w.text - 1) == " " .. w.text then
                pos = #text - #w.text + 1   -- the word ends the sentence ("... died")
            end
        end
        if pos and (not bestPos or (last and pos > bestPos) or (not last and pos < bestPos)) then
            bestPos, bestWord = pos, w
        end
    end
    return bestPos, bestWord
end

function Parser:ParseWords(line)
    line = Trim(NoLinks(Plain(line)))
    line = line:gsub("^[%d:%./%-%s]+>%s*", "")   -- a timestamp, if the Combat Log shows them
    line = line:gsub("[%[%]]", "")                -- braces around names, if it shows those
    if line == "" then return nil end

    -- Notes at the end: "(Critical)", "(3 Blocked)"
    local notes = {}
    while true do
        local head, group = line:match("^(.-)%s*(%b())%s*$")
        if not group then break end
        table.insert(notes, 1, Trim(group:sub(2, -2)))
        line = head
    end
    local main = Trim((line:gsub("%.%s*$", "")))

    local info = {}
    local rest, noSpell = main, false
    if main:sub(1, #self.your + 1) == self.your .. " " then
        info.fromMe = true
        rest = main:sub(#self.your + 2)
    elseif main:sub(1, #self.you + 1) == self.you .. " " then
        info.fromMe, noSpell = true, true
        rest = main:sub(#self.you + 2)
    end

    local pos, word = self:FindAction(rest, noSpell, not info.fromMe)
    if not pos and noSpell then
        -- "You Moonfire Immune X.": a few lines say "You" and still name a spell
        noSpell = false
        pos, word = self:FindAction(rest, false)
    end
    if not pos then return nil end
    info.kind = word.kind
    if word.split then info.split = true end

    local before = Trim(rest:sub(1, pos - 1))
    local after = Trim(rest:sub(pos + #word.text))
    if info.kind == "kill" and before ~= "" then return nil end   -- a spell's kill; "You killed" follows it
    -- With what. Someone else's line runs their name and the spell together, and
    -- the name is scrambled, so only a plain melee swing can be told apart.
    if before ~= "" then
        if before == self.melee or before:sub(-#self.melee - 1) == " " .. self.melee then
            info.melee = true
        elseif info.fromMe then
            info.spell = before
        end
    end
    -- Who it happened to, how much, and of what
    local dest, amount, unit = after:match("^(.-)%s*(%d[%d%.,]*)%s+(%D+)$")
    if not dest then dest, amount = after:match("^(.-)%s*(%d[%d%.,]*)$") end
    if not dest then dest = after end
    dest = Trim(dest)
    if amount and (info.kind == "damage" or info.kind == "heal" or info.kind == "energize") then
        info.amount = ToNumber(amount)
        if unit then
            unit = NoParens(Trim(unit))
            if unit ~= "" then info.unit = unit end
        end
    end
    if dest == self.youDest or dest == self.yourDest then info.toMe = true end

    for _, note in ipairs(notes) do self:ReadNote(info, note) end
    if word.missType then info.noteMiss = info.noteMiss or word.missType end
    return self:Finish(info, word.text)
end

---------------------------------------------------------------------------
-- Turns one combat log line into a table, or nil if it isn't something to show:
--   kind      "damage", "miss", "heal", "energize", "kill", "died", "interrupt", "dispel"
--   fromMe    you did it          toMe   it happened to you
--   spell     "Claw" (nil for a plain melee swing)      melee = true for a swing
--   spellId   16827 (from the link)
--   amount    50                  unit   "Physical" (or "Rage" for energize)
--   crit, glancing, crushing, periodic
--   blocked, absorbed, resisted, overkill, overheal     (amounts)
--   missType  "DODGE"
--   extraSpell, extraSpellId   what a dispel took off ("Corruption", 172)
--   aura      "BUFF" or "DEBUFF" (a dispel, when the game's words tell them apart)    stolen (Spellsteal)
--   srcGUID, destGUID, event     (from the links)
---------------------------------------------------------------------------
function Parser:Parse(line)
    if not self.ready then self:Init() end
    if IsSecret(line) or type(line) ~= "string" then return nil end
    if line:find("|Haction:", 1, true) then return self:ParseLinks(line) end
    return self:ParseWords(line)
end
