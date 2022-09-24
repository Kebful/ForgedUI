local Forgeframe = CreateFrame("Frame")
Forgeframe:RegisterEvent("PLAYER_LOGIN")
Forgeframe:SetScript("OnEvent", function()
	_G["RANGESLOT"] = "Ranged";
    -- InitializeTalentTree()
    -- InitializeTooltips()
     -- print(dump(GetItemStats("item:50731")))

    PaperDollItemsFrame.flyoutSettings = {
		onClickFunc = ForgePaperDollFrameItemFlyoutButton_OnClick,
		getItemsFunc = ForgePaperDollFrameItemFlyout_GetItems,
		postGetItemsFunc = ForgePaperDollFrameItemFlyout_PostGetItems,
		hasPopouts = true,
		parent = PaperDollFrame,
		anchorX = 0,
		anchorY = -3,
		verticalAnchorX = 0,
		verticalAnchorY = 0,
	};

    local b = CreateFrame("ItemButton", "CharacterRangeSlot", CharacterSecondaryHandSlot:GetParent(), "PaperDollItemSlotButtonTemplate", 18);
    b:SetScript("OnLoad", ForgePaperDollItemSlotButton_OnLoad)
    b:SetScript("OnEnter", ForgePaperDollItemSlotButton_OnEnter)
    b:SetPoint("TOPLEFT", CharacterSecondaryHandSlot, "TOPRIGHT", 5, 0)
    local tex = b:CreateTexture("CharacterRangeSlotBackground", "BACKGROUND", "Char-Slot-Bottom-Right", 1)
    tex:SetPoint("TOPLEFT", "CharacterRangeSlot", "TOPRIGHT")
    
end)

function ForgePaperDollFrameItemFlyout_GetItems(paperDollItemSlot, itemTable)
	GetInventoryItemsForSlot(paperDollItemSlot, itemTable);
end

function ForgePaperDollFrameItemFlyout_PostGetItems(itemSlotButton, itemDisplayTable, numItems)
	if (PaperDollEquipmentManagerPane:IsShown() and (PaperDollEquipmentManagerPane.selectedSetID or GearManagerDialogPopup:IsShown())) then
		if ( not itemSlotButton.ignored ) then
			tinsert(itemDisplayTable, 1, EQUIPMENTFLYOUT_IGNORESLOT_LOCATION);
		else
			tinsert(itemDisplayTable, 1, EQUIPMENTFLYOUT_UNIGNORESLOT_LOCATION);
		end
		numItems = numItems + 1;
	end
	if ( GetInventoryItemTexture("player", itemSlotButton:GetID()) ~= nil ) then
		tinsert(itemDisplayTable, 1, EQUIPMENTFLYOUT_PLACEINBAGS_LOCATION);
		numItems = numItems + 1;
	end
	return numItems;
end

function ForgePaperDollFrameItemFlyoutButton_OnClick(self)
	if ( self.location == EQUIPMENTFLYOUT_IGNORESLOT_LOCATION ) then
		PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON);
		local slot = EquipmentFlyoutFrame.button;
		C_EquipmentSet.IgnoreSlotForSave(slot:GetID());
		slot.ignored = true;
		ForgePaperDollItemSlotButton_Update(slot);
		EquipmentFlyout_Show(slot);
		PaperDollEquipmentManagerPaneSaveSet:Enable();
	elseif ( self.location == EQUIPMENTFLYOUT_UNIGNORESLOT_LOCATION ) then
		PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON);
		local slot = EquipmentFlyoutFrame.button;
		C_EquipmentSet.UnignoreSlotForSave(slot:GetID());
		slot.ignored = nil;
		ForgePaperDollItemSlotButton_Update(slot);
		EquipmentFlyout_Show(slot);
		PaperDollEquipmentManagerPaneSaveSet:Enable();
	elseif ( self.location == EQUIPMENTFLYOUT_PLACEINBAGS_LOCATION ) then
		if ( UnitAffectingCombat("player") and not INVSLOTS_EQUIPABLE_IN_COMBAT[EquipmentFlyoutFrame.button:GetID()] ) then
			UIErrorsFrame:AddMessage(ERR_CLIENT_LOCKED_OUT, 1.0, 0.1, 0.1, 1.0);
			return;
		end
		local action = EquipmentManager_UnequipItemInSlot(EquipmentFlyoutFrame.button:GetID());
		EquipmentManager_RunAction(action);
	elseif ( self.location ) then
		if ( UnitAffectingCombat("player") and not INVSLOTS_EQUIPABLE_IN_COMBAT[EquipmentFlyoutFrame.button:GetID()] ) then
			UIErrorsFrame:AddMessage(ERR_CLIENT_LOCKED_OUT, 1.0, 0.1, 0.1, 1.0);
			return;
		end
		local action = EquipmentManager_EquipItemByLocation(self.location, self.id);
		EquipmentManager_RunAction(action);
	end
end


function ForgePaperDollItemSlotButton_OnEnter(self)
	self:RegisterEvent("MODIFIER_STATE_CHANGED");
	EquipmentFlyout_UpdateFlyout(self);
	if ( not EquipmentFlyout_SetTooltipAnchor(self) ) then
		GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
	end
	local hasItem, hasCooldown, repairCost = GameTooltip:SetInventoryItem("player", self:GetID(), nil, true);
	if ( not hasItem ) then
		local r = strupper(strsub(self:GetName(), 10));
		local text = _G[r];
		if ( self.checkRelic and UnitHasRelicSlot("player") ) then
			text = RELICSLOT;
		end                 
		GameTooltip:SetText(text);
	end
	if ( InRepairMode() and repairCost and (repairCost > 0) ) then
		GameTooltip:AddLine(REPAIR_COST, nil, nil, nil, true);
		SetTooltipMoney(GameTooltip, repairCost);
		GameTooltip:Show();
	else
		CursorUpdate(self);
	end
end

function ForgePaperDollItemSlotButton_OnLoad(self)
	self:RegisterForDrag("LeftButton");
	self:RegisterForClicks("LeftButtonUp", "RightButtonUp");
	local slotName = self:GetName();
	local subName = strsub(slotName,10);
	local id = 18
	local textureName = ""
	local checkRelic = false
	if (subName ~= "RangeSlot") then
		id, textureName, checkRelic = GetInventorySlotInfo(subName);
	end
	self:SetID(id);
	local texture = _G[slotName.."IconTexture"];
	texture:SetTexture(textureName);
	self.backgroundTextureName = textureName;
	self.checkRelic = checkRelic;
	self.UpdateTooltip = ForgePaperDollItemSlotButton_OnEnter;
	itemSlotButtons[id] = self;
	self.verticalFlyout = VERTICAL_FLYOUTS[id];

	local popoutButton = self.popoutButton;
	if ( popoutButton ) then
		if ( self.verticalFlyout ) then
			popoutButton:SetHeight(16);
			popoutButton:SetWidth(38);

			popoutButton:GetNormalTexture():SetTexCoord(0.15625, 0.84375, 0.5, 0);
			popoutButton:GetHighlightTexture():SetTexCoord(0.15625, 0.84375, 1, 0.5);
			popoutButton:ClearAllPoints();
			popoutButton:SetPoint("TOP", self, "BOTTOM", 0, 4);
		else
			popoutButton:SetHeight(38);
			popoutButton:SetWidth(16);

			popoutButton:GetNormalTexture():SetTexCoord(0.15625, 0.5, 0.84375, 0.5, 0.15625, 0, 0.84375, 0);
			popoutButton:GetHighlightTexture():SetTexCoord(0.15625, 1, 0.84375, 1, 0.15625, 0.5, 0.84375, 0.5);
			popoutButton:ClearAllPoints();
			popoutButton:SetPoint("LEFT", self, "RIGHT", -8, 0);
		end
	end
end