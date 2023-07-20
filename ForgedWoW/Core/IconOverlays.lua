local L = ezCollections.L;
ezCollections.IconOverlays = ezCollections.IconOverlays or { };
-- Code partially adapted from Peddler

local overlayTextures =
{
    Known                       = { Order = 100, "known" },
    KnownCircle                 = { Order = 150, "known_circle" },
    KnownCircleO                = { Order = 175, "known_circleo" },
    Unknown                     = { Order = 200, "unknown" },
    NotTransmogable             = { Order = 300, "not_transmogable" },
    UnknowableSoulbound         = { Order = 400, "unknowable_soulbound" },
    UnknowableSoulboundCircle   = { Order = 450, "unknowable_soulbound_circle" },
    UnknowableSoulboundCircleO  = { Order = 475, "unknowable_soulbound_circleo" },
    UnknowableByCharacter       = { Order = 500, "unknowable_by_character" },
    Questionable                = { Order = 600, "questionable" },
};
local overlayStyles =
{
    Normal      = { Order = 1, Size = 64, "" },
    Backdrop    = { Order = 2, Size = 64, "_backdrop" },
    Outline     = { Order = 3, Size = 56, "_outline" },
    Shadow      = { Order = 4, Size = 44, "_shadow" },
};
local overlayAnchors =
{
    TOPLEFT     = { Order = 1 },
    TOP         = { Order = 2 },
    TOPRIGHT    = { Order = 3 },
    LEFT        = { Order = 4 },
    CENTER      = { Order = 5 },
    RIGHT       = { Order = 6 },
    BOTTOMLEFT  = { Order = 7 },
    BOTTOM      = { Order = 8 },
    BOTTOMRIGHT = { Order = 9 },
};
local overlayLayers =
{
    Cosmetic    = "BORDER",
    Type        = "ARTWORK",
    Junk        = "OVERLAY",
}
local overlayIconInfo =
{
    Junk =
    {
        Custom = true,
        Texture = [[Interface\AddOns\ForgedWoW\UI\ContainerFrame\Bags]],
        TexCoords = { 221/256, 241/256, 72/256, 90/256 },
        Anchor = "TOPLEFT",
        SizeX = 241-221,
        SizeY = 90-72,
        OffsetX = 1,
        OffsetY = 0,
    },
    Cosmetic =
    {
        Custom = true,
        Texture = [[Interface\AddOns\ForgedWoW\UI\ContainerFrame\CosmeticIconBorder]],
        TexCoords = { 1/128, 65/128, 1/128, 65/128 },
    }
};

local dirty = true;
local function MakeOptions(key, list, formatter)
    local options = { };
    local k2i = { };
    local i2k = { };
    for key, value in ezCollections:Ordered(list, function(a, b) return a.Order < b.Order; end) do
        table.insert(options, formatter(key, value));
        i2k[#options] = key;
        k2i[key] = #options;
    end
    local handler = { };
    function handler:disabled(info) return not info.arg.Enable; end
    function handler:values(info) return options; end
    function handler:get(info) return k2i[info.arg[key]] or 0; end
    function handler:set(info, value) info.arg[key] = i2k[value]; end
    return handler;
end
ezCollections.IconOverlays.TextureOptions = MakeOptions("Texture", overlayTextures, function(key, value) return format([[|TInterface\AddOns\ForgedWoW\UI\IconOverlays\%s:22:22:0:-1|t]], unpack(value)); end);
ezCollections.IconOverlays.StyleOptions = MakeOptions("Style", overlayStyles, function(key, value) return L["Config.Integration.ItemButtons.IconOverlays.Style."..key]; end);
ezCollections.IconOverlays.AnchorOptions = MakeOptions("Anchor", overlayAnchors, function(key, value) return L["Anchor."..key]; end);

local function IsAnyIconOverlayOptionEnabled()
    return ezCollections.Config.IconOverlays.Cosmetic.Enable and ezCollections.hasCosmeticItems
        or ezCollections.Config.IconOverlays.Junk.Enable and (not ezCollections.Config.IconOverlays.Junk.Merchant or MerchantFrame:IsShown())
        or ezCollections.Config.IconOverlays.Known.Enable
        or ezCollections.Config.IconOverlays.Unknown.Enable;
end

local function MakeOverlayIconInfo(type)
    local config = ezCollections.Config.IconOverlays[type] or { };
    local texture = overlayTextures[config.Texture or ""] or { };
    local style = overlayStyles[config.Style or "Normal"] or overlayStyles["Normal"];
    local offset = config.Offset or 0;

    local info = overlayIconInfo[type];
    if not info then
        info = { };
        overlayIconInfo[type] = info;
    end

    info.Enable = config.Enable;
    if info.Custom then
        return;
    end

    info.Texture = [[Interface\AddOns\ForgedWoW\UI\IconOverlays\]]..(unpack(texture) or "")..(unpack(style) or "") or nil;
    info.Color = config.Color;
    info.Anchor = config.Anchor or "TOPRIGHT";
    info.SizeX = config.Size or 13;
    info.SizeY = info.SizeX;
    info.OffsetX = info.SizeX * (64 - style.Size) / 2 / 64;
    info.OffsetY = info.SizeY * (64 - style.Size) / 2 / 64;
    info.SizeX = info.OffsetX + info.SizeX + info.OffsetX;
    info.SizeY = info.OffsetY + info.SizeY + info.OffsetY;
    if info.Anchor:find("LEFT") or info.Anchor:find("RIGHT") then
        info.OffsetX = info.OffsetX - offset;
    else
        info.OffsetX = 0;
    end
    if info.Anchor:find("LEFT") then
        info.OffsetX = -info.OffsetX;
    end
    if info.Anchor:find("TOP") or info.Anchor:find("BOTTOM") then
        info.OffsetY = info.OffsetY - offset;
    else
        info.OffsetY = 0;
    end
    if info.Anchor:find("BOTTOM") then
        info.OffsetY = -info.OffsetY;
    end
end

local function GetOverlayType(item)
    local status = item and ezCollections:GetCollectibleStatus(item);
    if status ~= nil then
        return status and "Known" or "Unknown";
    end
end

local function UpdateOverlay(button, name, type, condition)
    local info = type and overlayIconInfo[type];
    local overlay = button.ezCollectionsOverlay and button.ezCollectionsOverlay[name];
    if info and info.Enable and condition then
        if not overlay then
            local parent = button;
            while parent and not parent:IsObjectType("Frame") do
                parent = parent:GetParent();
            end
            if not button.ezCollectionsOverlay then
                button.ezCollectionsOverlay = CreateFrame("Frame", nil, parent or button);
            end
            overlay = button.ezCollectionsOverlay:CreateTexture(nil, overlayLayers[name] or "OVERLAY");
            button.ezCollectionsOverlay[name] = overlay;
        end
        overlay:SetTexture(info.Texture);
        if info.TexCoords then
            overlay:SetTexCoord(unpack(info.TexCoords));
        end
        if info.Color then
            overlay:SetVertexColor(info.Color.r, info.Color.g, info.Color.b, info.Color.a);
        else
            overlay:SetVertexColor(1, 1, 1, 1);
        end
        if info.Anchor then
            if overlay:GetPoint() ~= info.Anchor then
                overlay:ClearAllPoints();
            end
            overlay:SetPoint(info.Anchor, button, info.Anchor, info.OffsetX, info.OffsetY);
            overlay:SetSize(info.SizeX, info.SizeY);
        else
            overlay:SetPoint("TOPLEFT", button);
            overlay:SetPoint("BOTTOMRIGHT", button);
        end
        overlay:Show();
        -- Update overlay's frame level to prevent it from falling behind parent
        local frame = button.ezCollectionsOverlay;
        local parent = frame and frame:GetParent();
        if frame and parent and frame:GetFrameLevel() <= parent:GetFrameLevel() then
            frame:SetFrameLevel(parent:GetFrameLevel() + 1);
        end
    elseif overlay then
        overlay:Hide();
    end
end

local function checkNonBagItem(itemLinkOrID, itemButton)
    if not itemButton then return; end

    if type(itemLinkOrID) == "string" then
        itemLinkOrID = itemLinkOrID and itemLinkOrID:match("item:(%d+)");
        itemLinkOrID = itemLinkOrID and tonumber(itemLinkOrID);
    end
    UpdateOverlay(itemButton, "Type", GetOverlayType(itemLinkOrID), true);
end

local function checkItem(bagNumber, slotNumber, itemButton)
    if not itemButton then return; end

    local link = GetContainerItemLink(bagNumber, slotNumber);
    local item = link and link:match("item:(%d+)");
    item = item and tonumber(item);

    local _, quality, value, isCosmetic;
    if item then
        _, _, quality, _, _, _, _, _, _, _, value = GetItemInfo(item);
        if ezCollections.Config.IconOverlays.Cosmetic.Enable and ezCollections.hasCosmeticItems and ezCollections:IsSkinSource(item) then
            local _, _, _, flags = ezCollections:GetItemTransmog("player", bagNumber, slotNumber);
            isCosmetic = flags and flags:find(ITEM_COSMETIC, 1, true);
        end
    end

    UpdateOverlay(itemButton, "Cosmetic", "Cosmetic", isCosmetic);
    UpdateOverlay(itemButton, "Junk", "Junk", quality == 0 and value ~= 0 and (not ezCollections.Config.IconOverlays.Junk.Merchant or MerchantFrame:IsShown()));
    UpdateOverlay(itemButton, "Type", GetOverlayType(item), true);
end

local nonBagHooks = { };

local addons;
local deferred = false;
local deferredBags = { };
local BAG_ALL = -2;
function ezCollections.IconOverlays:Update(bag, force, deferredCall)
    if bag and bag < -1 then
        return;
    end
    if not force and not IsAnyIconOverlayOptionEnabled() then
        return;
    end

    if not deferredCall then
        if not deferred then
            deferred = true;
            C_Timer.After(0, function()
                if deferredBags[BAG_ALL] then
                    ezCollections.IconOverlays:Update(nil, true, true);
                else
                    for bag in pairs(deferredBags) do
                        ezCollections.IconOverlays:Update(bag, true, true);
                    end
                end
                table.wipe(deferredBags);
                deferred = false;
            end);
        end
        deferredBags[bag or BAG_ALL] = true;
        return;
    end

    if dirty then
        dirty = false;
        MakeOverlayIconInfo("Cosmetic");
        MakeOverlayIconInfo("Junk");
        MakeOverlayIconInfo("Known");
        MakeOverlayIconInfo("Unknown");
    end
    for addon, funcs in pairs(addons) do
        if IsAddOnLoaded(addon) and ezCollections.Config.IconOverlays.Addons[addon] then
            if funcs.Bags then
                funcs.Bags(bag);
            end
            if funcs.Hook then
                funcs.Hook();
                funcs.Hook = nil;
            end
        end
    end

    if not bag then
        for hook in pairs(nonBagHooks) do
            hook();
        end
    end
end

function ezCollections.IconOverlays:SetOptionsDirty() dirty = true; end

function ezCollections.IconOverlays:GetAddons() return addons; end

local function Startup()
    ezCollections.IconOverlays:Update();
end
local function Hook(...)
    local numParams = select("#", ...);
    local startParam = 1;
    local parent = ...;
    if type(parent) ~= "table" then
        parent = nil;
    end
    local hook = select(numParams, ...);
    for i = parent and startParam + 1 or startParam, numParams - 1 do
        local func = select(i, ...);
        if parent then
            hooksecurefunc(parent, func, hook);
        else
            hooksecurefunc(func, hook);
        end
    end
    nonBagHooks[hook] = true;
end
local function Event(...)
    local numParams = select("#", ...);
    local hook = select(numParams, ...);
    for i = 1, numParams - 1 do
        local event = select(i, ...);
        if not ezCollections.AceAddon[event] then
            ezCollections.AceAddon[event] = hook;
            ezCollections.AceAddon:RegisterEvent(event);
        else
            hooksecurefunc(ezCollections.AceAddon, event, hook);
        end
    end
end

-- Merchant
Event("MERCHANT_SHOW", "MERCHANT_CLOSED", Startup);
Hook("MerchantFrame_Update", function()
    if MerchantFrame.selectedTab == 1 then
        for i = 1, MERCHANT_ITEMS_PER_PAGE do
            checkNonBagItem(GetMerchantItemLink(((MerchantFrame.page - 1) * MERCHANT_ITEMS_PER_PAGE) + i), _G["MerchantItem"..i.."ItemButton"]);
        end
        checkNonBagItem(GetBuybackItemLink(GetNumBuybackItems()), MerchantBuyBackItemItemButton);
    else
        for i = 1, BUYBACK_ITEMS_PER_PAGE do
            checkNonBagItem(GetBuybackItemLink(i), _G["MerchantItem"..i.."ItemButton"]);
        end
    end
end);

-- Loot
local function UpdateLootFrame()
    for i = 1, LOOTFRAME_NUMBUTTONS do
        checkNonBagItem(LootFrame.page and GetLootSlotLink((LOOTFRAME_NUMBUTTONS * (LootFrame.page - 1)) + i), _G["LootButton"..i.."IconTexture"]);
    end
end
Event("LOOT_OPENED", "LOOT_SLOT_CLEARED", "LOOT_SLOT_CHANGED", "LOOT_CLOSED", UpdateLootFrame);
Hook("LootFrame_Update", UpdateLootFrame);
local function UpdateGroupLoot()
    for i = 1, NUM_GROUP_LOOT_FRAMES do
        local frame = _G["GroupLootFrame"..i];
        if frame then
            checkNonBagItem(frame.rollID and GetLootRollItemLink(frame.rollID), _G["GroupLootFrame"..i.."IconFrame"]);
        end
    end
end
Event("START_LOOT_ROLL", UpdateGroupLoot);
Hook("GroupLootFrame_OnShow", UpdateGroupLoot);

-- Mail
Hook("OpenMailFrame_UpdateButtonPositions", function()
    for i = 1, ATTACHMENTS_MAX_RECEIVE do
        checkNonBagItem(InboxFrame.openMailID and GetInboxItemLink(InboxFrame.openMailID, i), _G["OpenMailAttachmentButton"..i]);
    end
end);

-- Quests
for i = 1, MAX_NUM_ITEMS do
    local text = _G["QuestInfoItem"..i.."Name"];
    Hook(text, "SetText", function()
        local self = text:GetParent();
        if self.rewardType == "item" then
            if QuestInfoFrame.questLog then
                checkNonBagItem(GetQuestLogItemLink(self.type, self:GetID()), _G[self:GetName().."IconTexture"]);
            else
                checkNonBagItem(GetQuestItemLink(self.type, self:GetID()), _G[self:GetName().."IconTexture"]);
            end
        end
    end);
end

-- Auction House
-- Trade Skill
-- Guild Bank
hooksecurefunc(ezCollections.AceAddon, "ADDON_LOADED", function(self, event, addon)
    local funcs = addons[addon];
    if funcs and funcs.LoadOnDemand and ezCollections.Config.IconOverlays.Addons[addon] then
        if funcs.Hook then
            funcs.Hook();
            funcs.Hook = nil;
        end
        Startup();
    end
end);

-- Addons
addons =
{
    -- Bag Addons
    ["ezCollections"] =
    {
        blizzardBagsCreated = false,
        Hook = function()
            BankFrame:HookScript("OnShow", function()
                addons.ezCollections.blizzardBagsCreated = true;
            end);
            hooksecurefunc("ContainerFrame_GenerateFrame", function(frame, size, id)
                addons.ezCollections.blizzardBagsCreated = true;
                ezCollections.IconOverlays:Update(id);
            end);
        end,
        Bags = function(bag)
            if not addons.ezCollections.blizzardBagsCreated then return; end
            for containerNumber = 1, NUM_CONTAINER_FRAMES do
                local container = _G["ContainerFrame" .. containerNumber];
                if container and container:IsShown() then
                    for slotNumber = 1, GetContainerNumSlots(container:GetID()) do
                        local itemButton = _G[container:GetName() .. "Item" .. slotNumber];
                        if itemButton then
                            checkItem(container:GetID(), itemButton:GetID(), itemButton);
                        end
                    end
                end
            end
            for slotNumber = 1, NUM_BANKGENERIC_SLOTS do
                local itemButton = _G["BankFrameItem" .. slotNumber];
                if itemButton then
                    checkItem(-1, itemButton:GetID(), itemButton);
                end
            end
        end,
    },
    ["AdiBags"] =
    {
        Hook = function()
            local AdiBags = LibStub("AceAddon-3.0"):GetAddon("AdiBags", true);
            if AdiBags then
                local buttonClass = AdiBags:GetClass("ItemButton");
                if buttonClass and buttonClass.prototype then
                    hooksecurefunc(buttonClass.prototype, "Update", function(self)
                        checkItem(self.bag, self.slot, self.IconTexture);
                    end);
                end
            end
        end,
        Bags = function(bag)
            local AdiBags = LibStub("AceAddon-3.0"):GetAddon("AdiBags", true);
            if AdiBags then
                for bagNumber = bag or -1, bag or 11 do
                    AdiBags:SendMessage("AdiBags_BagUpdated", bagNumber);
                end
            end
        end,
    },
    ["Baggins"] =
    {
        Hook = function()
            hooksecurefunc(Baggins, "UpdateItemButton", function(self, bagframe, button, bag, slot)
                checkItem(bag, slot, _G[button:GetName().."IconTexture"]);
            end);
        end,
        Bags = function(bag)
            if not bag then
                Baggins:UpdateItemButtons();
                return;
            end
            for bagid, bag2 in ipairs(Baggins.bagframes) do
                for sectionid, section in ipairs(bag2.sections) do
                    for buttonid, button in ipairs(section.items) do
                        if button:GetParent():GetID() == bag then
                            checkItem(button:GetParent():GetID(), button:GetID(), _G[button:GetName().."IconTexture"]);
                        end
                    end
                end
            end
        end,
    },
    ["Bagnon"] =
    {
        Hook = function()
            hooksecurefunc(Bagnon.ItemSlot, "Update", function(item)
                checkItem(item:GetBag(), item:GetID(), _G[item:GetName().."IconTexture"]);
            end);
        end,
        Bags = function(bag)
            if not bag then
                Bagnon.Callbacks:SendMessage("ITEM_SLOT_COLOR_UPDATE");
                return;
            end
            for bagNumber = bag or -1, bag or 11 do
                for slotNumber = 1, GetContainerNumSlots(bagNumber) do
                    Bagnon.BagEvents:SendMessage("ITEM_SLOT_UPDATE", bagNumber, slotNumber);
                end
            end
        end,
    },
    ["Bagnon_GuildBank"] =
    {
        LoadOnDemand = true,
        Hook = function()
            hooksecurefunc(Bagnon.GuildItemSlot, "Update", function(item)
                checkNonBagItem(GetGuildBankItemLink(item:GetSlot()), _G[item:GetName().."IconTexture"]);
            end);
        end,
    },
    ["BaudBag"] =
    {
        Bags = function(bag)
            for bagNumber = bag or -1, bag or 11 do
                for slotNumber = 1, GetContainerNumSlots(bagNumber) do
                    checkItem(bagNumber, slotNumber, _G["BaudBagSubBag" .. bagNumber .. "Item" .. slotNumber]);
                end
            end
        end,
    },
    ["Combuctor"] =
    {
        Hook = function()
            hooksecurefunc(Combuctor.ItemSlot, "Update", function(item)
                checkItem(item:GetBag(), item:GetID(), _G[item:GetName().."IconTexture"]);
            end);
        end,
        Bags = function(bag)
            for bagNumber = bag or -1, bag or 11 do
                for slotNumber = 1, GetContainerNumSlots(bagNumber) do
                    Combuctor.BagEvents:SendMessage("COMBUCTOR_SLOT_UPDATE", bagNumber, slotNumber);
                end
            end
        end,
    },
    ["ElvUI"] =
    {
        Hook = function()
            local E = unpack(ElvUI);
            local B = E:GetModule("Bags", true);
            local M = E:GetModule("Misc", true);

            -- Bags
            local bags, bank;
            if ElvUI_ContainerFrame then
                ElvUI_ContainerFrame:HookScript("OnShow", Startup);
                bags = true;
            end
            if ElvUI_BankContainerFrame then
                ElvUI_BankContainerFrame:HookScript("OnShow", Startup);
                bank = true;
            end

            if not bags or not bank and B then
                hooksecurefunc(B, "ContructContainerFrame", function()
                    if ElvUI_ContainerFrame and not bags then
                        ElvUI_ContainerFrame:HookScript("OnShow", Startup);
                        bags = true;
                    end
                    if ElvUI_BankContainerFrame and not bank then
                        ElvUI_BankContainerFrame:HookScript("OnShow", Startup);
                        bank = true;
                    end
                end);
            end

            -- Loot
            if M then
                Hook(M, "START_LOOT_ROLL", function()
                    for _, frame in ipairs(M.RollBars) do
                        checkNonBagItem(frame.rollID and GetLootRollItemLink(frame.rollID), frame.itemButton);
                    end
                end);
                Hook(M, "LOOT_OPENED", "LOOT_SLOT_CLEARED", "LOOT_CLOSED", function()
                    for i, frame in ipairs(ElvLootFrame.slots) do
                        checkNonBagItem(GetLootSlotLink(i), frame.icon);
                    end
                end);
            end
        end,
        Bags = function(bag)
            if not ElvUI_ContainerFrame then return; end
            for bagNumber = bag or -1, bag or 11 do
                for slotNumber = 1, GetContainerNumSlots(bagNumber) do
                    checkItem(bagNumber, slotNumber, _G["ElvUI_ContainerFrameBag" .. bagNumber .. "Slot" .. slotNumber]
                                                    or _G["ElvUI_BankContainerFrameBag" .. bagNumber .. "Slot" .. slotNumber]);
                end
            end
        end,
    },
    ["OneBag3"] =
    {
        Hook = function()
            if OneBagFrame then
                OneBagFrame:HookScript("OnShow", Startup);
            end
            if OneBankFrame then
                OneBankFrame:HookScript("OnShow", Startup);
            end
        end,
        Bags = function(bag)
            for bagNumber = bag or -1, bag or 11 do
                local bagsSlotCount = GetContainerNumSlots(bagNumber)
                for slotNumber = 1, bagsSlotCount do
                    local itemButton = _G["OneBagFrameBag" .. bagNumber .. "Item" .. bagsSlotCount - slotNumber + 1]
                                    or _G["OneBankFrameBag" .. bagNumber .. "Item" .. bagsSlotCount - slotNumber + 1]
                    if itemButton then
                        checkItem(itemButton:GetParent():GetID(), itemButton:GetID(), itemButton);
                    end
                end
            end
        end,
    },
    ["TBag"] =
    {
        updateItem = function(self)
            if not self then return; end
            local itm = TBag:GetItmFromFrame(TBag.BUTTONS, self);
            if not itm or not next(itm) then return; end
            local bag, slot = itm[TBag.I_BAG], itm[TBag.I_SLOT];
            checkItem(bag, slot, _G[self:GetName().."IconTexture"]);
        end,
        Hook = function()
            hooksecurefunc(TBag.ItemButton, "Update", addons.TBag.updateItem);
        end,
        Bags = function(bag)
            for bagNumber = bag or -1, bag or 11 do
                for slotNumber = 1, GetContainerNumSlots(bagNumber) do
                    addons.TBag.updateItem(_G[TBag:GetBagItemButtonName(bagNumber, slotNumber)]);
                end
            end
        end,
    },
    -- Other Addons
    ["Blizzard_AuctionUI"] =
    {
        LoadOnDemand = true,
        Hook = function()
            Hook("AuctionFrameBrowse_Update", function()
                for i = 1, NUM_BROWSE_TO_DISPLAY do
                    local button = _G["BrowseButton"..i];
                    checkNonBagItem(button and GetAuctionItemLink("list", (button.pos or button:GetID()) + FauxScrollFrame_GetOffset(BrowseScrollFrame)), button.Icon or _G["BrowseButton"..i.."ItemIconTexture"]);
                end
            end);
            Hook("AuctionFrameBid_Update", function()
                for i = 1, NUM_BIDS_TO_DISPLAY do
                    local button = _G["BidButton"..i];
                    checkNonBagItem(button and GetAuctionItemLink("bidder", (button.pos or button:GetID()) + FauxScrollFrame_GetOffset(BidScrollFrame)), button.Icon or _G["BidButton"..i.."ItemIconTexture"]);
                end
            end);
            Hook("AuctionFrameAuctions_Update", function()
                for i = 1, NUM_AUCTIONS_TO_DISPLAY do
                    local button = _G["AuctionsButton"..i];
                    checkNonBagItem(button and GetAuctionItemLink("owner", (button.pos or button:GetID()) + FauxScrollFrame_GetOffset(AuctionsScrollFrame)), button.Icon or _G["AuctionsButton"..i.."ItemIconTexture"]);
                end
            end);
        end,
    },
    ["Blizzard_GuildBankUI"] =
    {
        LoadOnDemand = true,
        Hook = function()
            Hook("GuildBankFrame_Update", function()
                if GuildBankFrame.mode == "bank" then
                    local tab = GetCurrentGuildBankTab();
                    for i = 1, MAX_GUILDBANK_SLOTS_PER_TAB do
                        local index = mod(i, NUM_SLOTS_PER_GUILDBANK_GROUP);
                        if ( index == 0 ) then
                            index = NUM_SLOTS_PER_GUILDBANK_GROUP;
                        end
                        local column = ceil((i-0.5)/NUM_SLOTS_PER_GUILDBANK_GROUP);
                        local button = _G["GuildBankColumn"..column.."Button"..index];
                        if button then
                            checkNonBagItem(GetGuildBankItemLink(tab, i), _G[button:GetName().."IconTexture"]);
                        end
                    end
                end
            end);
        end,
    },
    ["Blizzard_TradeSkillUI"] =
    {
        LoadOnDemand = true,
        Hook = function()
            Hook("TradeSkillFrame_SetSelection", function()
                checkNonBagItem(TradeSkillFrame.selectedSkill and GetTradeSkillItemLink(TradeSkillFrame.selectedSkill), TradeSkillSkillIcon);
                for i = 1, MAX_TRADE_SKILL_REAGENTS do
                    checkNonBagItem(TradeSkillFrame.selectedSkill and GetTradeSkillReagentItemLink(TradeSkillFrame.selectedSkill, i), _G["TradeSkillReagent"..i.."IconTexture"]);
                end
            end);
        end,
    },
    ["AdvancedTradeSkillWindow"] =
    {
        Hook = function()
            Hook("ATSWFrame_SetSelection", function()
                checkNonBagItem(ATSWFrame.selectedSkill and GetTradeSkillItemLink(ATSWFrame.selectedSkill), ATSWSkillIcon);
                for i = 1, ATSW_MAX_TRADE_SKILL_REAGENTS do
                    checkNonBagItem(ATSWFrame.selectedSkill and GetTradeSkillReagentItemLink(ATSWFrame.selectedSkill, i), _G["ATSWReagent"..i.."IconTexture"]);
                end
            end);
        end,
    },
    ["AtlasLoot"] =
    {
        LoadOnDemand = true,
        Hook = function()
            if AtlasLoot and AtlasLoot.ClearLootPageItems and AtlasLoot.RefreshLootPage and AtlasLoot.SetItemTable then
                Hook(AtlasLoot, "ClearLootPageItems", "RefreshLootPage", "SetItemTable", function()
                    if AtlasLoot.ItemFrame then
                        for i, button in ipairs(AtlasLoot.ItemFrame.ItemButtons) do
                            if button and button.item and button.info and button.info[2] and button.Frame then
                                checkNonBagItem(button.info[2], button.Frame.Icon);
                            end
                        end
                    end
                end);
            end
            if AtlasLoot_ShowItemsFrame then
                Hook("AtlasLoot_ShowItemsFrame", function(dataID, dataSource, boss, pFrame)
                    for i = 1, 40 do
                        local button = _G["AtlasLootItem_"..i];
                        if button and button.itemID and button.itemID ~= 0 and string.sub(button.itemID, 1, 1) ~= "s" then
                            checkNonBagItem(button.itemID, _G[button:GetName().."_Icon"]);
                        end
                    end
                end);
            end
        end,
    },
    ["Auc-Advanced"] =
    {
        Hook = function()
            -- Snatcher fix: GetItemIcon(outfitlink) returns nothing, while SetNormalTexture requires at least one nil parameter
            hooksecurefunc(AucSearchUI.Searchers.Snatch, "MakeGuiConfig", function(self, gui)
                local icon = self.Private.frame.icon;
                local old = icon.SetNormalTexture;
                function icon:SetNormalTexture(texture) old(self, texture or nil) end
            end);
            -- CompactUI
            if AucAdvanced.Settings.GetSetting("util.compactui.activated") then
                hooksecurefunc(AucAdvanced.Modules.Util.CompactUI.Private, "HookAH", function()
                    -- CompactUI replaces global AuctionFrameBrowse_Update with private.MyAuctionFrameUpdate so we need to hook it again
                    Hook("AuctionFrameBrowse_Update", function()
                        for i = 1, NUM_BROWSE_TO_DISPLAY do
                            local button = _G["BrowseButton"..i];
                            checkNonBagItem(button.Name:GetText(), button.Icon);
                        end
                    end);
                end);
            end
            -- Appraiser
            local private = AucAdvanced.Modules.Util.Appraiser.Private;
            hooksecurefunc(private, "CreateFrames", function()
                local frame = private.frame;
                Hook(frame, "SelectItem", "Reselect", function()
                    checkNonBagItem(frame.salebox.sig and frame.salebox.link, frame.salebox.icon);
                end);
                Hook(frame, "SetScroll", function()
                    local pos = math.floor(frame.scroller:GetValue());
                    for i = 1, 12 do
                        local item = frame.list[pos+i];
                        local button = frame.items[i];
                        checkNonBagItem(item and item[7], button.icon);
                    end
                end);
            end);
        end,
    },
    ["Auctionator"] =
    {
        Hook = function()
            hooksecurefunc("Atr_SetTextureButton", function(elementName, count, itemlink)
                checkNonBagItem(itemlink, _G[elementName]);
            end);
        end,
    },
    ["GnomishVendorShrinker"] =
    {
        Hook = function()
            -- Frames not exposed through globals or names, try to find them among children
            for _, frame in ipairs({ MerchantFrame:GetChildren() }) do
                if Round(frame:GetWidth()) == 315 and Round(frame:GetHeight()) == 294 and frame:GetScript("OnEvent") then
                    local point, parent, relativePoint, x, y = frame:GetPoint();
                    if point == "TOPLEFT" and Round(x) == 21 and Round(y) == -77 then
                        local GVS = frame;
                        for _, frame in ipairs({ GVS:GetChildren() }) do
                            if frame:IsObjectType("Button") then
                                local row = frame;
                                Hook(frame, "Show", function()
                                    if row:GetID() <= GetMerchantNumItems() then
                                        checkNonBagItem(GetMerchantItemLink(row:GetID()), row.icon);
                                    end
                                end);
                            end
                        end
                    end
                end
            end
        end,
    },
    ["XLoot"] =
    {
        Hook = function()
            Hook(XLoot, "Update", function()
                for _, button in pairs(XLoot.buttons) do
                    checkNonBagItem(button.slot and GetLootSlotLink(button.slot), _G[button:GetName().."IconTexture"]);
                end
            end);
        end,
    },
    ["XLootGroup"] =
    {
        Hook = function()
            Hook(XLootGroup, "AddGroupLoot", "CancelGroupLoot", function()
                for _, row in ipairs(XLootGroup.AA.stacks.roll.rowstack) do
                    checkNonBagItem(row.rollID and GetLootRollItemLink(row.rollID), _G[row.button:GetName().."IconTexture"]);
                end
            end);
        end,
    },
};
