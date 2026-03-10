local _, ILM = ...

local TAB_WIDTH           = 40
local TAB_HEIGHT          = 20
local BTN_WIDTH           = 150
local BTN_HEIGHT          = 22
local PANEL_PAD           = 6
local ICON_SIZE           = 16
local HIDE_DELAY          = 0.3

local hideTimer
local tab, panel

local function CancelHideTimer()
    if hideTimer then
        hideTimer:Cancel()
        hideTimer = nil
    end
end

local function ScheduleHide()
    CancelHideTimer()
    hideTimer = C_Timer.NewTimer(HIDE_DELAY, function()
        hideTimer = nil
        if panel then panel:Hide() end
    end)
end

local function ShowPanel()
    CancelHideTimer()
    if panel then panel:Show() end
end

local function HookHover(frame)
    frame:SetScript("OnEnter", function() ShowPanel() end)
    frame:SetScript("OnLeave", function() ScheduleHide() end)
end

local function CreateButton(parent, label, iconPath, onClick, yOffset)
    local btn = CreateFrame("Button", nil, parent)
    btn:SetSize(BTN_WIDTH, BTN_HEIGHT)
    btn:SetPoint("TOPLEFT", parent, "TOPLEFT", PANEL_PAD, yOffset)

    local icon = btn:CreateTexture(nil, "ARTWORK")
    icon:SetSize(ICON_SIZE, ICON_SIZE)
    icon:SetPoint("LEFT", btn, "LEFT", 4, 0)
    icon:SetTexture(iconPath)

    local text = btn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    text:SetPoint("LEFT", icon, "RIGHT", 6, 0)
    text:SetText(label)
    text:SetJustifyH("LEFT")
    btn.label = text

    local hl = btn:CreateTexture(nil, "HIGHLIGHT")
    hl:SetAllPoints()
    hl:SetColorTexture(1, 1, 1, 0.1)

    btn:SetScript("OnClick", onClick)
    HookHover(btn)

    return btn
end

local ControlPanel = {}

function ControlPanel:Initialize()
    local buttons = {
        {
            label = "ILM Window",
            icon  = "Interface\\AddOns\\IneptLootManager\\Media\\Icons\\ilm-dark-128.tga",
            func  = function() ILM.GUI.Unified:Toggle() end,
        },
        {
            label = "Bidding",
            icon  = "Interface\\Icons\\INV_Misc_Coin_01",
            func  = function() ILM.GUI.BiddingManager:Toggle() end,
        },
        {
            label    = "Auctioning",
            icon     = "Interface\\Icons\\INV_Hammer_15",
            func     = function() ILM.GUI.AuctionManager:Toggle() end,
            trusted  = true,
        },
        {
            label    = "Auction History",
            icon     = "Interface\\Icons\\INV_Misc_Note_05",
            func     = function() ILM.GUI.AuctionHistory:Toggle() end,
            trusted  = true,
        },
        {
            label    = "Award Item",
            icon     = "Interface\\Icons\\INV_Misc_Gift_02",
            func     = function() ILM.GUI.Award:Toggle() end,
            trusted  = true,
        },
        {
            label    = "Trade List",
            icon     = "Interface\\Icons\\INV_Letter_15",
            func     = function() ILM.GUI.TradeList:Toggle() end,
            trusted  = true,
        },
        {
            label = "Configuration",
            icon  = "Interface\\Icons\\Trade_Engineering",
            func  = function()
                local open = InterfaceOptionsFrame_OpenToCategory or Settings.OpenToCategory
                open("Inept Loot Manager")
                open("Inept Loot Manager")
            end,
        },
    }

    local isTrusted = ILM.MODULES.ACL:CheckLevel(ILM.CONSTANTS.ACL.LEVEL.ASSISTANT)

    if not isTrusted then
        self._initialized = true
        return
    end

    -- Filter buttons by permission
    local visibleButtons = {}
    for _, info in ipairs(buttons) do
        if not info.trusted or isTrusted then
            visibleButtons[#visibleButtons + 1] = info
        end
    end

    local panelHeight = PANEL_PAD * 2 + #visibleButtons * BTN_HEIGHT

    -- Tab (top of screen trigger)
    tab = CreateFrame("Frame", "ILMControlTab", UIParent, "BackdropTemplate")
    tab:SetSize(TAB_WIDTH, TAB_HEIGHT)
    tab:SetPoint("TOPLEFT", UIParent, "TOPLEFT", 100, 0)
    tab:SetBackdrop({
        bgFile   = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        edgeSize = 8,
        insets   = { left = 2, right = 2, top = 2, bottom = 2 },
    })
    tab:SetBackdropColor(0.1, 0.1, 0.1, 0.9)
    tab:SetFrameStrata("MEDIUM")

    local label = tab:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    label:SetPoint("CENTER")
    label:SetText("ILM")

    HookHover(tab)

    -- Panel (drops down below tab)
    panel = CreateFrame("Frame", "ILMControlPanel", UIParent, "BackdropTemplate")
    panel:SetSize(BTN_WIDTH + PANEL_PAD * 2, panelHeight)
    panel:SetPoint("TOPLEFT", tab, "BOTTOMLEFT", 0, 0)
    panel:SetBackdrop({
        bgFile   = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        edgeSize = 8,
        insets   = { left = 2, right = 2, top = 2, bottom = 2 },
    })
    panel:SetBackdropColor(0.1, 0.1, 0.1, 0.95)
    panel:SetFrameStrata("MEDIUM")
    panel:Hide()

    HookHover(panel)

    for i, info in ipairs(visibleButtons) do
        local yOff = -PANEL_PAD - (i - 1) * BTN_HEIGHT
        CreateButton(panel, info.label, info.icon, info.func, yOff)
    end

    self._initialized = true
end

function ControlPanel:IsInitialized()
    return self._initialized
end

ILM.MODULES.ControlPanel = ControlPanel
