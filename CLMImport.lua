-- ------------------------------- --
local  _, ILM = ...
-- ------ ILM common cache ------- --
local LOG       = ILM.LOG
local CONSTANTS = ILM.CONSTANTS
local UTILS     = ILM.UTILS
-- ------------------------------- --

local AceGUI = LibStub("AceGUI-3.0")

-- ============================================================================
-- Minimal JSON Parser (just enough for CLM export format)
-- ============================================================================

local JSONParser = {}

function JSONParser:Parse(str)
    self.str = str
    self.pos = 1
    self:SkipWhitespace()
    local result = self:ParseValue()
    return result
end

function JSONParser:SkipWhitespace()
    local _, endPos = string.find(self.str, "^%s+", self.pos)
    if endPos then
        self.pos = endPos + 1
    end
end

function JSONParser:Peek()
    return string.sub(self.str, self.pos, self.pos)
end

function JSONParser:Next()
    local c = string.sub(self.str, self.pos, self.pos)
    self.pos = self.pos + 1
    return c
end

function JSONParser:Expect(c)
    if self:Peek() ~= c then
        error(string.format("JSON parse error at pos %d: expected '%s', got '%s'", self.pos, c, self:Peek()))
    end
    self:Next()
end

function JSONParser:ParseValue()
    self:SkipWhitespace()
    local c = self:Peek()
    if c == '"' then
        return self:ParseString()
    elseif c == '{' then
        return self:ParseObject()
    elseif c == '[' then
        return self:ParseArray()
    elseif c == 't' then
        return self:ParseLiteral("true", true)
    elseif c == 'f' then
        return self:ParseLiteral("false", false)
    elseif c == 'n' then
        return self:ParseLiteral("null", nil)
    else
        return self:ParseNumber()
    end
end

function JSONParser:ParseString()
    self:Expect('"')
    local result = {}
    while true do
        local c = self:Next()
        if c == '"' then
            break
        elseif c == '\\' then
            local esc = self:Next()
            if esc == '"' then result[#result+1] = '"'
            elseif esc == '\\' then result[#result+1] = '\\'
            elseif esc == '/' then result[#result+1] = '/'
            elseif esc == 'n' then result[#result+1] = '\n'
            elseif esc == 't' then result[#result+1] = '\t'
            elseif esc == 'r' then result[#result+1] = '\r'
            elseif esc == 'u' then
                -- Skip unicode escape (4 hex digits) — just output a placeholder
                -- UTF-8 chars in CLM export come through as raw bytes, not \u escapes
                self.pos = self.pos + 4
                result[#result+1] = '?'
            else
                result[#result+1] = esc
            end
        else
            result[#result+1] = c
        end
    end
    return table.concat(result)
end

function JSONParser:ParseNumber()
    local startPos = self.pos
    if self:Peek() == '-' then
        self:Next()
    end
    while string.find(self:Peek(), "^[0-9]") do
        self:Next()
    end
    if self:Peek() == '.' then
        self:Next()
        while string.find(self:Peek(), "^[0-9]") do
            self:Next()
        end
    end
    if self:Peek() == 'e' or self:Peek() == 'E' then
        self:Next()
        if self:Peek() == '+' or self:Peek() == '-' then
            self:Next()
        end
        while string.find(self:Peek(), "^[0-9]") do
            self:Next()
        end
    end
    return tonumber(string.sub(self.str, startPos, self.pos - 1))
end

function JSONParser:ParseObject()
    self:Expect('{')
    local obj = {}
    self:SkipWhitespace()
    if self:Peek() == '}' then
        self:Next()
        return obj
    end
    while true do
        self:SkipWhitespace()
        local key = self:ParseString()
        self:SkipWhitespace()
        self:Expect(':')
        local value = self:ParseValue()
        obj[key] = value
        self:SkipWhitespace()
        if self:Peek() == ',' then
            self:Next()
        else
            break
        end
    end
    self:SkipWhitespace()
    self:Expect('}')
    return obj
end

function JSONParser:ParseArray()
    self:Expect('[')
    local arr = {}
    self:SkipWhitespace()
    if self:Peek() == ']' then
        self:Next()
        return arr
    end
    while true do
        local value = self:ParseValue()
        arr[#arr+1] = value
        self:SkipWhitespace()
        if self:Peek() == ',' then
            self:Next()
        else
            break
        end
    end
    self:SkipWhitespace()
    self:Expect(']')
    return arr
end

function JSONParser:ParseLiteral(literal, value)
    for _ = 1, #literal do
        self:Next()
    end
    return value
end

-- ============================================================================
-- CLM Import Module
-- ============================================================================

local CLMImport = {}

local function ClassToUpper(class)
    if not class then return "WARRIOR" end
    return string.upper(class)
end

-- Map CLM reason strings to ILM reason constants
local REASON_MAP = {}
local function BuildReasonMap()
    REASON_MAP["On Time Bonus"]        = CONSTANTS.POINT_CHANGE_REASON.ON_TIME_BONUS
    REASON_MAP["Boss Kill Bonus"]      = CONSTANTS.POINT_CHANGE_REASON.BOSS_KILL_BONUS
    REASON_MAP["Raid Completion Bonus"]= CONSTANTS.POINT_CHANGE_REASON.RAID_COMPLETION_BONUS
    REASON_MAP["Progression Bonus"]    = CONSTANTS.POINT_CHANGE_REASON.PROGRESSION_BONUS
    REASON_MAP["Standby Bonus"]        = CONSTANTS.POINT_CHANGE_REASON.STANDBY_BONUS
    REASON_MAP["Unexcused absence"]    = CONSTANTS.POINT_CHANGE_REASON.UNEXCUSED_ABSENCE
    REASON_MAP["Correcting error"]     = CONSTANTS.POINT_CHANGE_REASON.CORRECTING_ERROR
    REASON_MAP["Manual adjustment"]    = CONSTANTS.POINT_CHANGE_REASON.MANUAL_ADJUSTMENT
    REASON_MAP["Zero-Sum award"]       = CONSTANTS.POINT_CHANGE_REASON.ZERO_SUM_AWARD
    REASON_MAP["Interval Bonus"]       = CONSTANTS.POINT_CHANGE_REASON.INTERVAL_BONUS
    REASON_MAP["Decay"]                = CONSTANTS.POINT_CHANGE_REASON.DECAY
end

function CLMImport:Initialize()
    LOG:Trace("CLMImport:Initialize()")
    BuildReasonMap()
    self:RegisterSlash()
    self._initialized = true
end

function CLMImport:RegisterSlash()
    local options = {
        import = {
            type = "execute",
            name = "Import",
            desc = ILM.L["Import standings from CLM JSON export"],
            handler = self,
            func = "Toggle",
        }
    }
    ILM.MODULES.ConfigManager:RegisterSlash(options)
end

function CLMImport:Toggle()
    if not self._initialized then return end
    if self.window and self.window:IsVisible() then
        self.window:Hide()
    else
        self:ShowWindow()
    end
end

function CLMImport:ShowWindow()
    if self.window then
        self.window:Show()
        return
    end

    local f = AceGUI:Create("Window")
    f:SetTitle("ILM - Import CLM Data")
    f:SetLayout("List")
    f:EnableResize(true)
    f:SetWidth(500)
    f:SetHeight(400)
    UTILS.MakeFrameCloseOnEsc(f.frame, "ILM_CLM_IMPORT")

    -- Instructions
    local desc = AceGUI:Create("Label")
    desc:SetText("Paste CLM JSON export below and click Import.\nImports: standings, point history, and loot history.")
    desc:SetFullWidth(true)
    f:AddChild(desc)

    -- Editbox
    local editbox = AceGUI:Create("MultiLineEditBox")
    editbox:SetLabel("")
    editbox:SetFullWidth(true)
    editbox:SetHeight(280)
    editbox:SetNumLines(15)
    editbox:DisableButton(true)
    editbox.editBox:SetMaxLetters(0)
    f:AddChild(editbox)

    -- Import button
    local btn = AceGUI:Create("Button")
    btn:SetText("Import All")
    btn:SetFullWidth(true)
    btn:SetCallback("OnClick", function()
        local text = editbox:GetText()
        if not text or text == "" then
            LOG:Warning("No JSON data pasted")
            return
        end
        self:DoImport(text)
    end)
    f:AddChild(btn)

    self.window = f
    self.editbox = editbox
end

function CLMImport:DoImport(jsonText)
    LOG:Info("Starting CLM import...")

    -- Parse JSON
    local ok, data = pcall(function() return JSONParser:Parse(jsonText) end)
    if not ok then
        LOG:Error("Failed to parse JSON: %s", tostring(data))
        print("|cffff0000ILM Import:|r Failed to parse JSON. Check the format.")
        return
    end

    -- Extract standings (required)
    local standingsData = data and data.standings
    if not standingsData or not standingsData.roster or #standingsData.roster == 0 then
        LOG:Error("No standings data found in JSON")
        print("|cffff0000ILM Import:|r No standings data found in the JSON export.")
        return
    end

    local rosterData = standingsData.roster[1]
    local rosterName = rosterData.name or "Imported"
    local players = rosterData.standings and rosterData.standings.player
    if not players or #players == 0 then
        LOG:Error("No player standings found")
        print("|cffff0000ILM Import:|r No player standings found in the roster.")
        return
    end

    -- Extract point history (optional)
    local pointHistoryEntries = {}
    if data.pointHistory and data.pointHistory.roster then
        for _, r in ipairs(data.pointHistory.roster) do
            if r.pointHistory and r.pointHistory.point then
                for _, entry in ipairs(r.pointHistory.point) do
                    pointHistoryEntries[#pointHistoryEntries+1] = entry
                end
            end
        end
    end

    -- Extract loot history (optional)
    local lootHistoryEntries = {}
    if data.lootHistory and data.lootHistory.roster then
        for _, r in ipairs(data.lootHistory.roster) do
            if r.lootHistory and r.lootHistory.item then
                for _, entry in ipairs(r.lootHistory.item) do
                    lootHistoryEntries[#lootHistoryEntries+1] = entry
                end
            end
        end
    end

    print(string.format("|cffdcb749ILM Import:|r Found %d players, %d point history entries, %d loot entries in roster '%s'.",
        #players, #pointHistoryEntries, #lootHistoryEntries, rosterName))

    -- Store parsed data for later steps
    self._importData = {
        players = players,
        rosterName = rosterName,
        pointHistory = pointHistoryEntries,
        lootHistory = lootHistoryEntries,
    }

    -- Find or create roster
    local _, roster = next(ILM.MODULES.RosterManager:GetRosters())

    if not roster then
        ILM.MODULES.RosterManager:NewRoster(CONSTANTS.POINT_TYPE.DKP, rosterName)
        C_Timer.After(0.5, function()
            local _, created = next(ILM.MODULES.RosterManager:GetRosters())
            if created then
                self:ImportAll(created)
            else
                print("|cffff0000ILM Import:|r Failed to create roster. Create one first, then retry.")
            end
        end)
    else
        self:ImportAll(roster)
    end
end

-- Build a name→GUID lookup from the standings player list
local function BuildNameToGUID(players)
    local map = {}
    for _, p in ipairs(players) do
        map[p.name] = p.guid
    end
    return map
end

function CLMImport:ImportAll(roster)
    local data = self._importData
    local players = data.players

    -- Step 1: Create profiles
    local guids = {}
    local dkpMap = {}

    for _, p in ipairs(players) do
        local guid = p.guid
        local name = UTILS.Disambiguate(p.name)
        local class = ClassToUpper(p.class)
        local dkp = tonumber(p.dkp) or 0

        ILM.MODULES.ProfileManager:NewProfile(guid, name, class)
        guids[#guids+1] = guid
        dkpMap[guid] = dkp
    end

    print(string.format("|cffdcb749ILM Import:|r Created %d profiles. Adding to roster...", #guids))

    -- Step 2: Add profiles to roster
    C_Timer.After(0.5, function()
        ILM.MODULES.RosterManager:AddProfilesToRoster(roster, guids)

        print("|cffdcb749ILM Import:|r Added to roster. Setting DKP standings...")

        -- Step 3: Set DKP standings
        C_Timer.After(0.5, function()
            local imported = 0
            for guid, dkp in pairs(dkpMap) do
                if dkp ~= 0 then
                    ILM.MODULES.PointManager:UpdatePoints(
                        roster,
                        { guid },
                        dkp,
                        CONSTANTS.POINT_CHANGE_REASON.IMPORT,
                        CONSTANTS.POINT_MANAGER_ACTION.SET,
                        "CLM Import",
                        CONSTANTS.POINT_CHANGE_TYPE.POINTS,
                        true
                    )
                    imported = imported + 1
                end
            end

            print(string.format("|cffdcb749ILM Import:|r Set DKP for %d players. Importing history...", imported))

            -- Step 4: Import point history (display only, does not change standings)
            C_Timer.After(0.5, function()
                self:ImportPointHistory(roster, data.pointHistory, BuildNameToGUID(players))

                -- Step 5: Import loot history
                C_Timer.After(0.5, function()
                    self:ImportLootHistory(roster, data.lootHistory, BuildNameToGUID(players))

                    print("|cff00ff00ILM Import:|r Complete!")
                    LOG:Info("CLM Import complete")

                    if ILM.GUI.Unified and ILM.GUI.Unified.Refresh then
                        ILM.GUI.Unified:Refresh()
                    end

                    if self.window then
                        self.window:Hide()
                    end

                    self._importData = nil
                end)
            end)
        end)
    end)
end

function CLMImport:ImportPointHistory(roster, entries, nameToGUID)
    if not entries or #entries == 0 then
        print("|cffdcb749ILM Import:|r No point history to import.")
        return
    end

    local count = 0
    for _, entry in ipairs(entries) do
        local guid = nameToGUID[entry.player]
        if guid then
            local reason = REASON_MAP[entry.reason] or CONSTANTS.POINT_CHANGE_REASON.IMPORT
            local value = tonumber(entry.dkp) or 0
            local timestamp = tonumber(entry.timestamp) or 0
            local note = entry.note or ""

            ILM.MODULES.PointManager:AddFakePointHistory(
                roster,
                { guid },
                value,
                reason,
                timestamp,
                nil,
                note,
                CONSTANTS.POINT_CHANGE_TYPE.POINTS
            )
            count = count + 1
        end
    end

    print(string.format("|cffdcb749ILM Import:|r Imported %d point history entries.", count))
end

function CLMImport:ImportLootHistory(roster, entries, nameToGUID)
    if not entries or #entries == 0 then
        print("|cffdcb749ILM Import:|r No loot history to import.")
        return
    end

    local rosterUid = roster:UID()
    local count = 0
    for _, entry in ipairs(entries) do
        local guid = nameToGUID[entry.player]
        local itemId = tonumber(entry.id)
        local value = tonumber(entry.dkp) or 0
        local timestamp = tonumber(entry.timestamp) or 0

        if guid and itemId then
            local lootEntry = ILM.MODELS.LEDGER.LOOT.Award:new(rosterUid, guid, itemId, value)
            lootEntry:setTime(timestamp)
            ILM.MODULES.LedgerManager:Submit(lootEntry, true)
            count = count + 1
        end
    end

    print(string.format("|cffdcb749ILM Import:|r Imported %d loot history entries.", count))
end

ILM.MODULES.CLMImport = CLMImport
