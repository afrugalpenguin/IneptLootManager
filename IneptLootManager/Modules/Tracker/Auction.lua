local PRIV = ILM._TRACKER

local dataColumn = {
    name = ILM.L["Count"],
    align = "CENTER",
    width = 36
}

local function dataCallback(auction, item, name, response)
    local count = PRIV.MODULES.Tracker:GetCount(auction:GetRoster(), item:GetItemID(), name)
    return {value = count or 0}
end

local function RegisterColumn()
    ILM.GUI.AuctionManager:RegisterExternalColumn(dataColumn, dataCallback)
end

local Auction = {}
function Auction:Initialize()
    if not ILM.MODULES.ACL:IsTrusted() then return end
    if PRIV.Core:GetEnableAuctionColumn() then
        RegisterColumn()
    end
end

PRIV.MODULES.Auction = Auction
