-- ------------------------------- --
local _, ILM = ...
-- ------ ILM common cache ------- --
local LOG       = ILM.LOG
local CONSTANTS = ILM.CONSTANTS
local UTILS     = ILM.UTILS
-- ------------------------------- --

local SharedMedia = LibStub("LibSharedMedia-3.0")

local DEFAULT_TEXTURE_NAME = "ILM Default"
local DEFAULT_TEXTURE = "Interface\\AddOns\\IneptLootManager\\Media\\Bars\\Ruben.tga"
local DEFAULT_WIDTH = 320
local DEFAULT_HEIGHT = 120

local whoamiGUID = UTILS.whoamiGUID()

local BiddingManagerGUI = {}

-- ==================
-- Database / Config
-- ==================
local function InitializeDB(self)
    self.db = ILM.MODULES.Database:GUI('bidding', {
        location = {nil, nil, "CENTER", 0, 0},
        barWidth = 340,
        barHeight = 25,
        barFontSize = 12,
        barTexture = DEFAULT_TEXTURE_NAME,
        hideInCombat = true,
        autoOpen = true,
    })
end

local function StoreLocation(self)
    if self.frame then
        self.db.location = { self.frame:GetPoint() }
        self.db.location[2] = nil
    end
end

local function RestoreLocation(self)
    if self.db.location then
        self.frame:ClearAllPoints()
        self.frame:SetPoint(self.db.location[3] or "CENTER", UIParent, self.db.location[3] or "CENTER", self.db.location[4] or 0, self.db.location[5] or 0)
    end
end

-- ==================
-- Colour Palette
-- ==================
local COLOURS = {
    bg          = { 0.08, 0.08, 0.10, 0.92 },
    border      = { 0.40, 0.35, 0.25, 0.80 },
    accent      = { 0.85, 0.65, 0.13, 1.00 },  -- gold
    text        = { 0.90, 0.90, 0.88, 1.00 },
    textMuted   = { 0.55, 0.55, 0.52, 1.00 },
    btnBid      = { 0.15, 0.55, 0.15, 1.00 },
    btnBidHover = { 0.20, 0.70, 0.20, 1.00 },
    btnPass     = { 0.50, 0.12, 0.12, 1.00 },
    btnPassHover= { 0.65, 0.18, 0.18, 1.00 },
    btnUndo     = { 0.60, 0.50, 0.10, 1.00 },
    btnUndoHover= { 0.75, 0.62, 0.15, 1.00 },
    inputBg     = { 0.12, 0.12, 0.14, 1.00 },
    inputBorder = { 0.30, 0.30, 0.28, 0.60 },
    statusBid   = { 0.27, 0.93, 0.27, 1.00 },  -- green
    statusPass  = { 0.55, 0.55, 0.52, 1.00 },   -- grey
    statusDeny  = { 0.93, 0.70, 0.13, 1.00 },  -- gold
}

-- ==================
-- Helpers
-- ==================
local function SetBackdrop(frame, bgColour, borderColour)
    if not frame.SetBackdrop then
        Mixin(frame, BackdropTemplateMixin)
    end
    frame:SetBackdrop({
        bgFile = "Interface\\BUTTONS\\WHITE8X8",
        edgeFile = "Interface\\BUTTONS\\WHITE8X8",
        edgeSize = 1,
        insets = { left = 1, right = 1, top = 1, bottom = 1 },
    })
    frame:SetBackdropColor(unpack(bgColour))
    frame:SetBackdropBorderColor(unpack(borderColour))
end

local function CreateButton(parent, text, width, height, colour, hoverColour)
    local btn = CreateFrame("Button", nil, parent, "BackdropTemplate")
    btn:SetSize(width, height)
    SetBackdrop(btn, colour, { 0.25, 0.25, 0.23, 0.60 })

    btn.label = btn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    btn.label:SetPoint("CENTER")
    btn.label:SetText(text)
    btn.label:SetTextColor(0.95, 0.95, 0.93, 1)

    btn:SetScript("OnEnter", function(self)
        self:SetBackdropColor(unpack(hoverColour))
    end)
    btn:SetScript("OnLeave", function(self)
        self:SetBackdropColor(unpack(colour))
    end)

    -- Click feedback
    btn:SetScript("OnMouseDown", function(self)
        self.label:SetPoint("CENTER", 0, -1)
    end)
    btn:SetScript("OnMouseUp", function(self)
        self.label:SetPoint("CENTER", 0, 0)
    end)

    return btn
end

-- ==================
-- Build the Frame
-- ==================
local function CreateUI(self)
    -- Main frame
    local f = CreateFrame("Frame", "ILM_SimpleBidding", UIParent, "BackdropTemplate")
    f:SetSize(DEFAULT_WIDTH, DEFAULT_HEIGHT)
    f:SetPoint("CENTER")
    f:SetFrameStrata("DIALOG")
    f:SetClampedToScreen(true)
    f:SetMovable(true)
    f:EnableMouse(true)
    f:RegisterForDrag("LeftButton")
    f:SetScript("OnDragStart", f.StartMoving)
    f:SetScript("OnDragStop", function(frame)
        frame:StopMovingOrSizing()
        StoreLocation(self)
    end)
    SetBackdrop(f, COLOURS.bg, COLOURS.border)
    self.frame = f

    -- Gold accent line at top
    local accent = f:CreateTexture(nil, "ARTWORK")
    accent:SetPoint("TOPLEFT", f, "TOPLEFT", 1, -1)
    accent:SetPoint("TOPRIGHT", f, "TOPRIGHT", -1, -1)
    accent:SetHeight(2)
    accent:SetColorTexture(unpack(COLOURS.accent))

    -- Title bar (draggable area)
    local titleBar = CreateFrame("Frame", nil, f)
    titleBar:SetPoint("TOPLEFT", 0, 0)
    titleBar:SetPoint("TOPRIGHT", 0, 0)
    titleBar:SetHeight(22)
    titleBar:EnableMouse(true)
    titleBar:RegisterForDrag("LeftButton")
    titleBar:SetScript("OnDragStart", function() f:StartMoving() end)
    titleBar:SetScript("OnDragStop", function()
        f:StopMovingOrSizing()
        StoreLocation(self)
    end)

    -- Title text
    local title = f:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    title:SetPoint("TOPLEFT", 8, -6)
    title:SetText(ILM.L["Bidding"])
    title:SetTextColor(unpack(COLOURS.accent))
    self.titleText = title

    -- DKP display
    local dkpText = f:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    dkpText:SetPoint("TOPRIGHT", -8, -6)
    dkpText:SetTextColor(unpack(COLOURS.textMuted))
    self.dkpText = dkpText



    -- ---- Item Row ----
    local itemRow = CreateFrame("Frame", nil, f)
    itemRow:SetPoint("TOPLEFT", 8, -24)
    itemRow:SetPoint("TOPRIGHT", -8, -24)
    itemRow:SetHeight(32)

    -- Item icon
    local icon = itemRow:CreateTexture(nil, "ARTWORK")
    icon:SetSize(28, 28)
    icon:SetPoint("LEFT", 2, 0)
    icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
    self.itemIcon = icon

    -- Item icon border (rarity colour)
    local iconBorder = CreateFrame("Frame", nil, itemRow, "BackdropTemplate")
    iconBorder:SetPoint("CENTER", icon, "CENTER")
    iconBorder:SetSize(30, 30)
    SetBackdrop(iconBorder, { 0, 0, 0, 0 }, { 0.6, 0.6, 0.6, 0.8 })
    self.iconBorder = iconBorder

    -- Item name
    local itemName = itemRow:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    itemName:SetPoint("LEFT", icon, "RIGHT", 8, 0)
    itemName:SetPoint("RIGHT", itemRow, "RIGHT", -4, 0)
    itemName:SetJustifyH("LEFT")
    itemName:SetWordWrap(false)
    self.itemName = itemName

    -- Tooltip on hover
    itemRow:EnableMouse(true)
    itemRow:SetScript("OnEnter", function()
        if self.currentItemLink then
            GameTooltip:SetOwner(itemRow, "ANCHOR_BOTTOM")
            GameTooltip:SetHyperlink(self.currentItemLink)
            GameTooltip:Show()
        end
    end)
    itemRow:SetScript("OnLeave", function() GameTooltip:Hide() end)

    -- Bid status indicator
    local statusText = f:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    statusText:SetPoint("TOPLEFT", itemRow, "BOTTOMLEFT", 2, -2)
    statusText:SetTextColor(unpack(COLOURS.textMuted))
    self.statusText = statusText

    -- ---- Bid Row ----
    local bidRow = CreateFrame("Frame", nil, f)
    bidRow:SetPoint("TOPLEFT", itemRow, "BOTTOMLEFT", 0, -16)
    bidRow:SetPoint("TOPRIGHT", itemRow, "BOTTOMRIGHT", 0, -16)
    bidRow:SetHeight(28)
    self.bidRow = bidRow

    -- Input box
    local input = CreateFrame("EditBox", "ILM_SimpleBidding_Input", bidRow, "BackdropTemplate")
    input:SetSize(120, 26)
    input:SetPoint("LEFT", 2, 0)
    input:SetAutoFocus(false)
    input:SetNumeric(true)
    input:SetMaxLetters(8)
    input:SetFontObject(GameFontHighlight)
    input:SetJustifyH("CENTER")
    SetBackdrop(input, COLOURS.inputBg, COLOURS.inputBorder)
    input:SetTextInsets(8, 8, 2, 2)
    input:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
    input:SetScript("OnEnterPressed", function()
        self:SubmitBid()
    end)
    self.bidInput = input

    -- Minimum bid label
    local inputLabel = bidRow:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    inputLabel:SetPoint("BOTTOM", input, "TOP", 0, 2)
    inputLabel:SetText(ILM.L["Bid"])
    inputLabel:SetTextColor(unpack(COLOURS.textMuted))
    self.bidLabel = inputLabel

    -- Bid button
    local bidBtn = CreateButton(bidRow, ILM.L["Bid"], 75, 26, COLOURS.btnBid, COLOURS.btnBidHover)
    bidBtn:SetPoint("LEFT", input, "RIGHT", 6, 0)
    bidBtn:SetScript("OnClick", function()
        self:SubmitBid()
    end)
    self.bidButton = bidBtn

    -- Pass button
    local passBtn = CreateButton(bidRow, ILM.L["Pass"], 75, 26, COLOURS.btnPass, COLOURS.btnPassHover)
    passBtn:SetPoint("LEFT", bidBtn, "RIGHT", 6, 0)
    passBtn:SetScript("OnClick", function()
        self:SubmitPass()
    end)
    self.passButton = passBtn


    f:Hide()
end

-- ==================
-- Bid / Pass Logic
-- ==================
function BiddingManagerGUI:SubmitBid()
    if not self.auctionItem then
        LOG:Debug("SimpleBiddingGUI:SubmitBid(): No auction item")
        return
    end
    local value = tonumber(self.bidInput:GetText()) or 0
    if value <= 0 then
        LOG:Debug("SimpleBiddingGUI:SubmitBid(): Invalid value %s", tostring(value))
        return
    end
    LOG:Debug("SimpleBiddingGUI:SubmitBid(): Bidding %d", value)
    ILM.MODULES.BiddingManager:Bid(self.auctionItem, value, CONSTANTS.BID_TYPE.MAIN_SPEC)
    self.bidInput:ClearFocus()
end

function BiddingManagerGUI:SubmitPass()
    if not self.auctionItem then
        LOG:Debug("SimpleBiddingGUI:SubmitPass(): No auction item")
        return
    end
    LOG:Debug("SimpleBiddingGUI:SubmitPass(): Passing")
    ILM.MODULES.BiddingManager:Pass(self.auctionItem)
    self:EnterPassedState()
end

function BiddingManagerGUI:EnterPassedState()
    -- Hide bid controls, show undo button
    self.bidInput:Hide()
    self.bidButton:Hide()
    self.passButton:Hide()
    self.bidLabel:Hide()

    if not self.undoButton then
        local undoBtn = CreateButton(self.bidRow, "Undo (3)", 160, 26, COLOURS.btnUndo, COLOURS.btnUndoHover)
        undoBtn:SetPoint("CENTER", self.bidRow, "CENTER", 0, 0)
        self.undoButton = undoBtn
    end

    self.undoButton.label:SetText("Undo (5)")
    self.undoButton:Show()
    self._passUndoRemaining = 5
    self._passDismissed = false

    self.undoButton:SetScript("OnClick", function()
        self:CancelPass()
    end)

    -- Countdown timer
    local function Tick()
        if self._passDismissed then return end
        self._passUndoRemaining = self._passUndoRemaining - 1
        if self._passUndoRemaining <= 0 then
            self:DismissAfterPass()
        else
            self.undoButton.label:SetText("Undo (" .. self._passUndoRemaining .. ")")
            C_Timer.After(1, Tick)
        end
    end
    C_Timer.After(1, Tick)
end

function BiddingManagerGUI:CancelPass()
    self._passDismissed = true
    if self.undoButton then self.undoButton:Hide() end
    self.bidInput:Show()
    self.bidButton:Show()
    self.passButton:Show()
    self.bidLabel:Show()
    -- Re-bid with 0 to cancel the pass
    if self.auctionItem then
        ILM.MODULES.BiddingManager:CancelBid(self.auctionItem)
    end
end

function BiddingManagerGUI:DismissAfterPass()
    self._passDismissed = true
    if self.undoButton then self.undoButton:Hide() end
    self:HideDelayed()
end

function BiddingManagerGUI:ResetPassState()
    self._passDismissed = true
    if self.undoButton then self.undoButton:Hide() end
    if self.bidInput then self.bidInput:Show() end
    if self.bidButton then self.bidButton:Show() end
    if self.passButton then self.passButton:Show() end
    if self.bidLabel then self.bidLabel:Show() end
end

-- ==================
-- Item Display
-- ==================
function BiddingManagerGUI:UpdateItemDisplay()
    local item = self.auctionItem
    if not item or item.item:IsItemEmpty() then
        self.itemIcon:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark")
        self.itemName:SetText("")
        self.currentItemLink = nil
        self.iconBorder:SetBackdropBorderColor(0.6, 0.6, 0.6, 0.8)
        self.statusText:SetText("")
        return
    end

    local itemLink = item:GetItemLink()
    self.currentItemLink = itemLink

    local _, _, quality, _, _, _, _, _, _, texture = UTILS.GetItemInfo(itemLink)
    self.itemIcon:SetTexture(texture or "Interface\\Icons\\INV_Misc_QuestionMark")
    self.itemName:SetText(itemLink)

    -- Rarity border colour
    if quality then
        local r, g, b = GetItemQualityColor(quality)
        self.iconBorder:SetBackdropBorderColor(r, g, b, 1)
    end

    -- Bid status
    if item:BidAccepted() then
        self.statusText:SetText("|cff44ee44" .. ILM.L["Bid accepted!"] .. "|r")
    elseif item:BidDenied() then
        self.statusText:SetText("|cffffb020" .. ILM.L["Bid denied!"] .. "|r")
    else
        self.statusText:SetText("")
    end

    -- Pre-fill bid value and show minimum
    local bid = item:GetBid()
    local values = item:GetValues()
    local minBid = values and values[CONSTANTS.SLOT_VALUE_TIER.BASE] or 0
    if bid and bid:Value() > 0 then
        self.bidInput:SetText(tostring(bid:Value()))
    elseif minBid > 0 then
        self.bidInput:SetText(tostring(minBid))
    else
        self.bidInput:SetText("")
    end

    -- Update label with minimum
    if minBid > 0 then
        self.bidLabel:SetText("Min: " .. tostring(minBid) .. " DKP")
    else
        self.bidLabel:SetText(ILM.L["Bid"])
    end
end

-- ==================
-- DKP Display
-- ==================
function BiddingManagerGUI:UpdateDKP()
    local auction = ILM.MODULES.BiddingManager:GetAuctionInfo()
    if not auction then
        self.dkpText:SetText("")
        return
    end
    local roster = auction:GetRoster()
    if roster and roster:IsProfileInRoster(whoamiGUID) then
        local standings = roster:Standings(whoamiGUID)
        self.dkpText:SetText(tostring(standings) .. " " .. ILM.L["DKP"])
    else
        self.dkpText:SetText("")
    end
end

-- ==================
-- Auction Order (multi-item support)
-- ==================
function BiddingManagerGUI:BuildBidOrder()
    local auction = ILM.MODULES.BiddingManager:GetAuctionInfo()
    self.auctionOrder = {}
    self.nextItem = 0
    if not auction then
        LOG:Debug("SimpleBiddingGUI:BuildBidOrder(): No auction")
        return
    end
    for uid in pairs(auction:GetItems()) do
        self.auctionOrder[#self.auctionOrder+1] = uid
    end
    LOG:Debug("SimpleBiddingGUI:BuildBidOrder(): %d items", #self.auctionOrder)
    -- Select first item
    if #self.auctionOrder > 0 then
        self:Advance()
    end
end

function BiddingManagerGUI:SetVisibleAuctionItem(auctionItem)
    self.auctionItem = auctionItem
    if self._initialized then
        self:UpdateItemDisplay()
    end
end

function BiddingManagerGUI:Advance()
    local auction = ILM.MODULES.BiddingManager:GetAuctionInfo()
    if not auction or #self.auctionOrder == 0 then return end
    self.nextItem = (self.nextItem % #self.auctionOrder) + 1
    local uid = self.auctionOrder[self.nextItem]
    local item = auction:GetItemByUID(uid)
    if item then
        self:SetVisibleAuctionItem(item)
    end
end

-- ==================
-- Timer Bar
-- ==================
local function ShowTestBar(self)
    self.testBar = ILM.MODELS.BiddingTimerBar:Test({
        anchor = self.db.barLocation,
        width = self.db.barWidth,
        height = self.db.barHeight,
        texture = self.db.barTexture,
        fontSize = self.db.barFontSize,
        fontName = self.db.barFontName,
    })
end

local function HideTestBar(self)
    if self.testBar then
        self.db.barLocation = { self.testBar:GetPoint() }
        self.testBar:Stop()
    end
    self.testBar = nil
end

local function ToggleTestBar(self)
    if ILM.MODULES.BiddingManager:IsAuctionInProgress() then return end
    if self.testBar then
        HideTestBar(self)
    else
        ShowTestBar(self)
    end
end

-- ==================
-- Config (admin-only options registered to global config panel)
-- ==================
local function CreateConfig(self)
    local options = {
        bidding_header = {
            type = "header",
            name = ILM.L["Bidding"],
            order = 70
        },
        bidding_auto_open = {
            name = ILM.L["Toggle Bidding auto-open"],
            desc = ILM.L["Toggle auto open and auto close on auction start and stop"],
            type = "toggle",
            set = function(_, v) self.db.autoOpen = v and true or false end,
            get = function() return self.db.autoOpen end,
            width = "double",
            order = 71
        },
        bidding_hide_in_combat = {
            name = ILM.L["Hide in combat"],
            desc = ILM.L["Toggle closing bidding UI when entering combat."],
            type = "toggle",
            set = function(_, v) self.db.hideInCombat = v and true or false end,
            get = function() return self.db.hideInCombat end,
            width = "double",
            order = 72
        },
        bidding_bar_header = {
            type = "header",
            name = ILM.L["Timer Bar"],
            order = 80
        },
        bidding_bar_width = {
            name = ILM.L["Width"],
            type = "range",
            min = 100, max = 600, step = 5,
            set = function(_, v) self.db.barWidth = v end,
            get = function() return self.db.barWidth end,
            order = 81
        },
        bidding_bar_height = {
            name = ILM.L["Height"],
            type = "range",
            min = 14, max = 50, step = 1,
            set = function(_, v) self.db.barHeight = v end,
            get = function() return self.db.barHeight end,
            order = 82
        },
        bidding_bar_font_size = {
            name = ILM.L["Font size"],
            type = "range",
            min = 8, max = 20, step = 1,
            set = function(_, v) self.db.barFontSize = v end,
            get = function() return self.db.barFontSize end,
            order = 83
        },
        bidding_bar_texture = {
            name = ILM.L["Texture"],
            type = "select",
            dialogControl = "LSM30_Statusbar",
            values = SharedMedia:HashTable("statusbar"),
            set = function(_, v) self.db.barTexture = v end,
            get = function() return self.db.barTexture end,
            order = 84
        },
        bidding_bar_test = {
            name = ILM.L["Toggle test bar"],
            type = "execute",
            func = function() ToggleTestBar(self) end,
            order = 85,
        },
    }
    ILM.MODULES.ConfigManager:Register(CONSTANTS.CONFIGS.GROUP.GLOBAL, options)
end

-- ==================
-- Slash Command
-- ==================
local function RegisterSlash(self)
    local options = {
        bid = {
            type = "execute",
            name = ILM.L["Bidding"],
            desc = ILM.L["Toggle Bidding window display"],
            handler = self,
            func = "Toggle",
        }
    }
    ILM.MODULES.ConfigManager:RegisterSlash(options)
end

-- ====================
-- PUBLIC INTERFACE
-- ====================
function BiddingManagerGUI:Initialize()
    LOG:Trace("BiddingManagerGUI:Initialize()")
    InitializeDB(self)
    CreateConfig(self)
    CreateUI(self)
    RegisterSlash(self)

    self.ToggleTestBar = ToggleTestBar

    ILM.MODULES.EventManager:RegisterWoWEvent({"PLAYER_LOGOUT"}, function() StoreLocation(self) end)
    ILM.MODULES.EventManager:RegisterWoWEvent({"PLAYER_REGEN_DISABLED"}, function()
        if self.db.hideInCombat then
            if self.frame:IsVisible() then
                self.showAfterCombat = true
                self:HideDelayed()
            end
        end
    end)
    ILM.MODULES.EventManager:RegisterWoWEvent({"PLAYER_REGEN_ENABLED"}, function()
        if self.showAfterCombat then
            self.showAfterCombat = nil
            if not ILM.MODULES.BiddingManager:IsAuctionInProgress() then return end
            self:ShowDelayed()
        end
    end)
    self._initialized = true
end

function BiddingManagerGUI:StartAuction()
    self:ResetPassState()
    self:BuildBidOrder()
    HideTestBar(self)

    -- Build timer bar
    local toggleCb = function() self:Toggle() end
    self.bar = ILM.MODELS.BiddingTimerBar:New(
        self.auctionItem,
        ILM.MODULES.BiddingManager:GetAuctionInfo(),
        {
            anchor = self.db.barLocation,
            width = self.db.barWidth,
            height = self.db.barHeight,
            texture = self.db.barTexture,
            fontSize = self.db.barFontSize,
            fontName = self.db.barFontName,
            callback = toggleCb,
        }
    )

    if self.db.autoOpen then
        if self.db.hideInCombat and InCombatLockdown() then
            self.showAfterCombat = true
        else
            self:Show()
        end
    end
end

function BiddingManagerGUI:EndAuction()
    self:ResetPassState()
    StoreLocation(self)
    if self.bar then
        self.bar:Stop()
    end
    self.statusText:SetText("")
end

function BiddingManagerGUI:AntiSnipe()
    if self.bar then
        self.bar:UpdateTime(ILM.MODULES.BiddingManager:GetAuctionInfo():GetAntiSnipe())
    end
end

function BiddingManagerGUI:RefreshItemList()
    -- Single-item view: pick first available item if we don't have one
    local auction = ILM.MODULES.BiddingManager:GetAuctionInfo()
    if not auction then return end
    if not self.auctionItem then
        local _, item = next(auction:GetItems())
        self.auctionItem = item
    end
    -- Rebuild order and update display
    self:BuildBidOrder()
    if self._initialized and self.frame:IsVisible() then
        self:UpdateItemDisplay()
        self:UpdateDKP()
    end
end

function BiddingManagerGUI:Refresh()
    LOG:Trace("BiddingManagerGUI:Refresh()")
    if not self._initialized then return end
    self:UpdateItemDisplay()
    self:UpdateDKP()
    if self.bar then
        self.bar:UpdateInfo(self.auctionItem)
    end
end

function BiddingManagerGUI:Toggle()
    LOG:Trace("BiddingManagerGUI:Toggle()")
    if not self._initialized then return end
    if self.frame:IsVisible() then
        self:Hide()
    else
        self:Refresh()
        self:Show()
    end
end

function BiddingManagerGUI:Show()
    LOG:Trace("BiddingManagerGUI:Show()")
    if not self._initialized then return end
    if not self.frame:IsVisible() then
        self:Refresh()
        self.frame:Show()
    end
end

function BiddingManagerGUI:Hide()
    LOG:Trace("BiddingManagerGUI:Hide()")
    if not self._initialized then return end
    if self.frame:IsVisible() then
        self.frame:Hide()
    end
end

function BiddingManagerGUI:ShowDelayed()
    LOG:Trace("BiddingManagerGUI:ShowDelayed()")
    if not self._initialized then return end
    if not self.frame:IsVisible() then
        self:Refresh()
        self.frame:Show()
        UTILS.FadeIn(self.frame, 0.3)
    end
end

function BiddingManagerGUI:HideDelayed()
    LOG:Trace("BiddingManagerGUI:HideDelayed()")
    if not self._initialized then return end
    if self.frame:IsVisible() then
        UTILS.FadeOut(self.frame, 0.3, 1, 0, {
            finishedFunc = function()
                self.frame:Hide()
                self.frame:SetAlpha(1)
            end
        })
    end
end

function BiddingManagerGUI:Reset()
    LOG:Trace("BiddingManagerGUI:Reset()")
    if self.frame then
        self.frame:ClearAllPoints()
        self.frame:SetPoint("CENTER")
        StoreLocation(self)
    end
end

-- Publish
ILM.GUI.BiddingManager = BiddingManagerGUI
