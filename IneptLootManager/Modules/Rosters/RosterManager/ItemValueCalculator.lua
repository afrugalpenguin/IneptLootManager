-- ------------------------------- --
local  _, ILM = ...
-- ------ ILM common cache ------- --
local LOG       = ILM.LOG
local CONSTANTS = ILM.CONSTANTS
local UTILS     = ILM.UTILS
-- ------------------------------- --

local DEFAULT_MULTIPLIER = {
    exponential = 0.483,
    wowpedia = 0.04
}

local DEFAULT_EXPVAR = 2.0

CONSTANTS.ITEM_VALUE_EQUATION = {
    EXPONENTIAL = 1,
    WOWPEDIA = 2
}

local equationIDtoParam = {
    [CONSTANTS.ITEM_VALUE_EQUATION.EXPONENTIAL] = "exponential",
    [CONSTANTS.ITEM_VALUE_EQUATION.WOWPEDIA] = "wowpedia",
}

local qualityModifier = {
    [2] = (function(ilvl) return (math.abs(ilvl - 4) / 2) end),
    [3] = (function(ilvl) return (math.abs(ilvl - 1.84) / 1.6) end),
    [4] = (function(ilvl) return (math.abs(ilvl - 1.3) / 1.3) end),
}

local defaultQualityModifier = (function(ilvl) return ilvl end)

local function getItemValue(quality, ilvl)
    local modifier = qualityModifier[quality] or defaultQualityModifier
    return modifier(ilvl)
end

local calculators = {
    [CONSTANTS.ITEM_VALUE_EQUATION.EXPONENTIAL] = (function(ilvl, quality, multiplier, expvar, slot_multiplier)
        return multiplier * math.pow(expvar, (ilvl/26) + (quality - 4)) * slot_multiplier
    end),
    [CONSTANTS.ITEM_VALUE_EQUATION.WOWPEDIA] = (function(ilvl, quality, multiplier, expvar, slot_multiplier)
        return math.pow(getItemValue(quality, ilvl), expvar) * multiplier * slot_multiplier
    end),
}

local function getParamFromEquationID(id)
    return equationIDtoParam[id] or 0
end

local function GetDefaultMultiplier(equation)
    return DEFAULT_MULTIPLIER[getParamFromEquationID(equation)] or 1.0
end

local function SetDefaultMultiplier(self)
    self.multiplier = GetDefaultMultiplier(self.equation)
end

local function GetDefaultSlotMultiplier(equation, slot)
    local param = getParamFromEquationID(equation)
    local slotValues = CONSTANTS.ITEM_SLOT_MULTIPLIERS[slot] or {}
    return slotValues[param] or 1.0
end

local function SetDefaultSlotMultipliers(self)
    local param = getParamFromEquationID(self.equation)
    for name, values in pairs(CONSTANTS.ITEM_SLOT_MULTIPLIERS) do
        self.slotMultipliers[name] = values[param]
    end
end

local function SetDefaultTierMultipliers(self)
    for _, tier in ipairs(CONSTANTS.SLOT_VALUE_TIERS_ORDERED) do
        self.tierMultipliers[tier] = 1.0
    end
end

local function SetCalculator(self)
    self.calculator = calculators[self.equation]
end

local ItemValueCalculator = {}
function ItemValueCalculator:New()
    local o = {}

    setmetatable(o, self)
    self.__index = self

    o.equation = CONSTANTS.ITEM_VALUE_EQUATION.EXPONENTIAL

    o.multiplier = 1.0
    o.expvar = 2.0
    SetDefaultMultiplier(o)
    o.slotMultipliers = {}
    SetDefaultSlotMultipliers(o)
    o.tierMultipliers = {}
    SetDefaultTierMultipliers(o)

    SetCalculator(o)

    return o
end

function ItemValueCalculator:GetEquation()
    return self.equation
end

function ItemValueCalculator:SetEquation(equation)
    if not CONSTANTS.ITEM_VALUE_EQUATIONS[equation] then
        LOG:Fatal("Unknown equation type")
        return
    end
    if self.equation == equation then return end
    self.equation = equation
    SetDefaultMultiplier(self)
    SetDefaultSlotMultipliers(self)
    SetCalculator(self)
end

function ItemValueCalculator:GetMultiplier()
    return self.multiplier
end

function ItemValueCalculator:SetMultiplier(multiplier)
    self.multiplier = tonumber(multiplier) or GetDefaultMultiplier(self.equation)
end

function ItemValueCalculator:GetExpvar()
    return self.expvar
end

function ItemValueCalculator:SetExpvar(expvar)
    self.expvar = tonumber(expvar) or DEFAULT_EXPVAR
end

function ItemValueCalculator:GetSlotMultiplier(slot)
    return self.slotMultipliers[slot] or 1.0
end

function ItemValueCalculator:SetSlotMultiplier(slot, multiplier)
    if not CONSTANTS.ITEM_SLOT_MULTIPLIERS[slot] then return end
    self.slotMultipliers[slot] = tonumber(multiplier) or GetDefaultSlotMultiplier(self.equation, slot)
end

function ItemValueCalculator:GetTierMultiplier(tier)
    return self.tierMultipliers[tier] or 1.0
end

function ItemValueCalculator:SetTierMultiplier(tier, multiplier)
    if not CONSTANTS.SLOT_VALUE_TIERS[tier] then return end
    self.tierMultipliers[tier] = tonumber(multiplier) or 1.0
end

function ItemValueCalculator:Calculate(ilvl, quality, slot_multiplier, rounding)
    local values = {}
    local baseValue = self.calculator(ilvl, quality, self.multiplier, self.expvar, slot_multiplier)

    for tier, tierMultiplier in pairs(self.tierMultipliers) do
        values[tier] = UTILS.round(baseValue * tierMultiplier, rounding)
    end

    return values
end

local function CalculateProxy(self, itemInfoInput, itemId, rounding)
    local _, _, itemQuality, itemLevel, _, _, _, _, itemEquipLoc, _, _, classID, subclassID = UTILS.GetItemInfo(itemInfoInput)
    if not itemQuality or not itemLevel or not itemEquipLoc then
        LOG:Warning(ILM.L["Unable to get item info from server. Please try auctioning again"])
        return nil
    end

    local equipLoc = UTILS.WorkaroundEquipLoc(classID, subclassID, itemEquipLoc)
    return self:Calculate(ILM.IndirectMap.ilvl[itemId] or itemLevel, itemQuality, self:GetSlotMultiplier(ILM.IndirectMap.slot[itemId] or equipLoc), rounding)
end

function ItemValueCalculator:CalculateFromId(itemId, rounding)
    return CalculateProxy(self, itemId, itemId, rounding)
end

function ItemValueCalculator:CalculateFromLink(itemLink, rounding)
    return CalculateProxy(self, itemLink, UTILS.GetItemIdFromLink(itemLink), rounding)
end

CONSTANTS.ITEM_VALUE_EQUATIONS = UTILS.Set({
    CONSTANTS.ITEM_VALUE_EQUATION.EXPONENTIAL,
    CONSTANTS.ITEM_VALUE_EQUATION.WOWPEDIA,
})

CONSTANTS.ITEM_VALUE_EQUATIONS_ORDERED = {
    CONSTANTS.ITEM_VALUE_EQUATION.EXPONENTIAL,
    CONSTANTS.ITEM_VALUE_EQUATION.WOWPEDIA,
}

CONSTANTS.ITEM_VALUE_EQUATIONS_GUI = {
    [CONSTANTS.ITEM_VALUE_EQUATION.EXPONENTIAL] = ILM.L["Exponential"],
    [CONSTANTS.ITEM_VALUE_EQUATION.WOWPEDIA] = ILM.L["Wowpedia"],
}

CONSTANTS.ITEM_SLOT_MULTIPLIERS = {
    ["INVTYPE_HEAD"] = {            exponential = 1.0,  wowpedia = 1.0},
    ["INVTYPE_NECK"] = {            exponential = 0.5,  wowpedia = 0.55},
    ["INVTYPE_SHOULDER"] = {        exponential = 0.75,  wowpedia = 0.777},
    ["INVTYPE_BODY"] = {            exponential = 0.0,  wowpedia = 0.0},
    ["INVTYPE_CLOAK"] = {           exponential = 0.5,  wowpedia = 0.55},
    ["INVTYPE_CHEST"] = {           exponential = 1.0,  wowpedia = 1.0},
    ["INVTYPE_ROBE"] = {            exponential = 1.0,  wowpedia = 1.0},
    ["INVTYPE_TABARD"] = {          exponential = 0.0,  wowpedia = 0.0},
    ["INVTYPE_WRIST"] = {           exponential = 0.75,  wowpedia = 0.55},
    ["INVTYPE_HAND"] = {            exponential = 0.75,  wowpedia = 0.777},
    ["INVTYPE_WAIST"] = {           exponential = 1.0,  wowpedia = 0.777},
    ["INVTYPE_LEGS"] = {            exponential = 1.0,  wowpedia = 1.0},
    ["INVTYPE_FEET"] = {            exponential = 0.75,  wowpedia = 0.777},
    ["INVTYPE_FINGER"] = {          exponential = 0.5,  wowpedia = 0.55},
    ["INVTYPE_TRINKET"] = {         exponential = 0.75,  wowpedia = 0.7},
    ["INVTYPE_WEAPON"] = {          exponential = 1.0,  wowpedia = 1.0},
    ["INVTYPE_WEAPONMAINHAND"] = {  exponential = 1.5,  wowpedia = 0.42},
    ["INVTYPE_WEAPONOFFHAND"] = {   exponential = 1.5,  wowpedia = 0.42},
    ["INVTYPE_HOLDABLE"] = {        exponential = 0.5,  wowpedia = 0.55},
    ["INVTYPE_2HWEAPON"] = {        exponential = 2.0,  wowpedia = 1.0},
    ["INVTYPE_SHIELD"] = {          exponential = 0.5,  wowpedia = 0.55},
    ["INVTYPE_RANGED"] = {          exponential = 0.5,  wowpedia = 0.42},
    ["INVTYPE_RANGEDRIGHT"] = {     exponential = 0.5,  wowpedia = 0.42},
    ["INVTYPE_NON_EQUIP"] = {       exponential = 0.0,  wowpedia = 0.0},
    ["INVTYPE_BAG"] = {             exponential = 0.0,  wowpedia = 0.0},
    ["INVTYPE_AMMO"] = {            exponential = 0.0,  wowpedia = 0.0},
    ["INVTYPE_THROWN"] = {          exponential = 0.5,  wowpedia = 0.42},
    ["INVTYPE_QUIVER"] = {          exponential = 0.5,  wowpedia = 0.42},
    ["INVTYPE_RELIC"] = {           exponential = 0.5,  wowpedia = 0.42}
}

ILM.MODELS.ItemValueCalculator = ItemValueCalculator
