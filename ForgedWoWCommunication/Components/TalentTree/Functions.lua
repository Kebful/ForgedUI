function HideMainWindow()
    if TalentTreeWindow:IsShown() then
        TalentTreeWindow:Hide()
        ForgedWoWMicrobarButton:SetButtonState("NORMAL");
    end
end

function ToggleMainWindow()
    if TalentTreeWindow:IsShown() then
        TalentTreeWindow:Hide()
        PlaySound("TalentScreenClose");
        ForgedWoWMicrobarButton:SetButtonState("NORMAL");
    else
        TalentTreeWindow:Show()
        PlaySound("TalentScreenOpen");
        ForgedWoWMicrobarButton:SetButtonState("PUSHED", 1);
    end
    if SpellBookFrame:IsShown() then
        SpellBookFrame:Hide();
    end
    if PVPParentFrame:IsShown() then
        PVPParentFrame:Hide();
    end
    if FriendsFrame:IsShown() then
        FriendsFrame:Hide();
    end
end

TalentTreeWindow:HookScript("OnHide", function()
    ForgedWoWMicrobarButton:SetButtonState("NORMAL");
end)

function FindTabInForgeSpell(tabId)
    for _, page in ipairs(TalentTree.FORGE_SPELLS_PAGES) do
        for _, tab in pairs(page) do
            if tonumber(tab.Id) == tonumber(tabId) then
                return tab;
            end
        end
    end
end

function FindExistingTab(tabId)
    for _, tab in ipairs(TalentTree.FORGE_TABS) do
        if tonumber(tab.Id) == tonumber(tabId) then
            return tab;
        end
    end
    return FindTabInForgeSpell(tabId);
end

function UpdateTalentCurrentView()
    if not TalentTree.FORGE_SELECTED_TAB then
        return;
    end
    local CurrentTab = FindExistingTab(TalentTree.FORGE_SELECTED_TAB.Id);
    if CurrentTab then
        if CurrentTab.TalentType == CharacterPointType.FORGE_SKILL_TREE then
            InitializeViewFromGrid(TalentTreeWindow.GridForgeSkill, CurrentTab.Talents, CurrentTab.Id, 465);
        else
            InitializeViewFromGrid(TalentTreeWindow.GridTalent, CurrentTab.Talents, CurrentTab.Id, 392);
        end
    end
end

function FindTalent(talentId, talents)
    for _, talent in pairs(talents) do
        if talent.SpellId == talentId then
            return talent;
        end
    end
end

function UpdateTalent(tabId, talents)
    if not talents then
        return;
    end
    for spellId, rank in pairs(talents) do
        local tab = FindExistingTab(tabId)
        if tab then
            local talent = FindTalent(spellId, tab.Talents)
            local ColumnIndex = tonumber(talent.ColumnIndex);
            local RowIndex = tonumber(talent.RowIndex);
            if tab.TalentType == CharacterPointType.FORGE_SKILL_TREE then
                RankUpTalent(TalentTreeWindow.GridForgeSkill.Talents[ColumnIndex][RowIndex], rank, talent, tabId)
            else
                RankUpTalent(TalentTreeWindow.GridTalent.Talents[ColumnIndex][RowIndex], rank, talent, tabId)
            end
        end
    end
end

function RankUpTalent(frame, rank, talent, tabId)
    if frame then
        frame.RankText:SetText(CurrentRankSpell(rank) .. "/" .. talent.NumberOfRanks);
        local CurrentRank, SpellId, NextSpellId = GetSpellIdAndNextRank(tabId, talent);
        if IsUnlocked(CurrentRank, talent.NumberOfRanks) then
            frame.Border:SetBackdrop({

                bgFile = CONSTANTS.UI.BORDER_UNLOCKED
            })
        else
            if CurrentRank ~= -1 then
                frame.TextureIcon:SetDesaturated(nil);
                frame.Border:SetBackdrop({
                    bgFile = CONSTANTS.UI.BORDER_ACTIVE
                })
                if talent.ExclusiveWith[1] then
                    frame.Exclusivity:Show();
                end
            else
                if CurrentRank < 1 then
                    frame.TextureIcon:SetDesaturated(1);
                    frame.Border:SetBackdrop({
                        bgFile = CONSTANTS.UI.BORDER_LOCKED
                    })
                else
                    frame.Border:SetBackdrop({
                        bgFile = CONSTANTS.UI.BORDER_ACTIVE
                    })
                end
                if talent.ExclusiveWith[1] then
                    frame.Exclusivity:Hide();
                end
            end
        end
        frame:HookScript("OnEnter", function()
            CreateTooltip(talent, SpellId, NextSpellId, frame, CurrentRank);
        end)
        if frame.IsTooltipActive then
            CreateTooltip(talent, SpellId, NextSpellId, frame, CurrentRank);
        end
    end
end

function UpdateOldTabTalents(newTab)
    local oldTab = FindExistingTab(newTab.Id);
    if oldTab then
        oldTab.Talents = newTab.Talents;
    end
end

function GetStrByCharacterPointType(talentType)
    if talentType == CharacterPointType.RACIAL_TREE then
        return "racial";
    end
    if talentType == CharacterPointType.PRESTIGE_TREE then
        return "prestige";
    end
    if talentType == CharacterPointType.TALENT_SKILL_TREE then
        return "talent";
    end
    if talentType == CharacterPointType.FORGE_SKILL_TREE then
        return "forge";
    end
end

function GetPositionXY(frame)
    local position = {
        x = 0,
        y = 0
    }
    local _, _, _, xOfs, yOfs = frame:GetPoint();
    position.x = xOfs;
    position.y = yOfs;
    return position;
end

function IsNodeUnlocked(talent, CurrentRank)
    return CurrentRank ~= -1 or IsUnlocked(CurrentRank, tonumber((talent.NumberOfRanks)))
end

function DrawNode(startPosition, endPosition, parentFrame, parent, offSet, talent, CurrentRank, previousSpell)
    local x1 = startPosition.x;
    local x2 = endPosition.x;
    local y1 = startPosition.y;
    local y2 = endPosition.y;
    local length = math.sqrt(((x2 - x1) * (x2 - x1)) + ((y2 - y1) * (y2 - y1)));
    local cx = ((x1 + x2) / 2) - (length / 2);
    local cy = ((y1 + y2) / 2) - (5 / 2);
    local angle = math.atan2((y1 - y2), (x1 - x2)) * (180 / math.pi);
    if not parentFrame.node[talent.SpellId] then
        parentFrame.node[talent.SpellId] = CreateFrame("Frame", parentFrame.node[talent.SpellId], parent);
        parentFrame.node[talent.SpellId]:SetSize(length, 10);
        parentFrame.node[talent.SpellId]:SetPoint("LEFT", cx + offSet + 7, cy + 5);
        if IsNodeUnlocked(talent, CurrentRank) then
            parentFrame.node[talent.SpellId]:SetBackdrop({
                bgFile = CONSTANTS.UI.CONNECTOR
            })
        else
            parentFrame.node[talent.SpellId]:SetBackdrop({
                bgFile = CONSTANTS.UI.CONNECTOR_DISABLED
            })
        end
        parentFrame.node[talent.SpellId].animation = parentFrame.node[talent.SpellId]:CreateAnimationGroup()
        parentFrame.node[talent.SpellId].animation.spin = parentFrame.node[talent.SpellId].animation:CreateAnimation(
            "Rotation")
        parentFrame.node[talent.SpellId].animation.spin:SetOrder(1)
        parentFrame.node[talent.SpellId].animation.spin:SetDuration(0)
        parentFrame.node[talent.SpellId].animation.spin:SetDegrees(angle)
        parentFrame.node[talent.SpellId].animation.spin:SetEndDelay(999999)
        parentFrame.node[talent.SpellId].animation:Play()
    else
        if IsNodeUnlocked(talent, CurrentRank) then
            parentFrame.node[talent.SpellId]:SetBackdrop({
                bgFile = CONSTANTS.UI.CONNECTOR
            })
        else
            parentFrame.node[talent.SpellId]:SetBackdrop({
                bgFile = CONSTANTS.UI.CONNECTOR_DISABLED
            })
        end
        parentFrame.node[talent.SpellId].animation:Stop()
        parentFrame.node[talent.SpellId].animation:Play()
    end
end

function Tablelength(T)
    local count = 0
    for _ in pairs(T) do
        count = count + 1
    end
    return count
end

function SplitSpellsByChunk(array, nb)
    local chunks = {};
    local i = 1;
    for index, value in ipairs(array) do
        if chunks[i] == nil then
            chunks[i] = {};
        end
        table.insert(chunks[i], value);
        if Tablelength(chunks[i]) > nb then
            i = i + 1
        end
    end
    return chunks
end

function SelectTab(tab)
    if TalentTree.FORGE_SELECTED_TAB then
        if TalentTreeWindow.TabsLeft.Spec[TalentTree.FORGE_SELECTED_TAB.Id] then
            TalentTreeWindow.TabsLeft.Spec[TalentTree.FORGE_SELECTED_TAB.Id]:SetButtonState("NORMAL");
        end
    end
    TalentTree.FORGE_SELECTED_TAB = tab;
    TalentTreeWindow.TabsLeft.Spec[TalentTree.FORGE_SELECTED_TAB.Id]:SetButtonState("PUSHED", 1);
    if tab.TalentType == CharacterPointType.SKILL_PAGE then
        ShowTypeTalentPoint(CharacterPointType.FORGE_SKILL_TREE, "forge")
        TalentTreeWindow.SpellBook:Show();
    else
        TalentTreeWindow.SpellBook:Hide();
    end
    if tab.TalentType == CharacterPointType.RACIAL_TREE or tab.TalentType == CharacterPointType.TALENT_SKILL_TREE or
        tab.TalentType == CharacterPointType.PRESTIGE_TREE then
        InitializeGridForTalent();
        if tab.Talents then
            InitializeViewFromGrid(TalentTreeWindow.GridTalent, tab.Talents, tab.Id, 392);
        end
        TalentTreeWindow.GridTalent:Show();
    else
        TalentTreeWindow.GridTalent:Hide();
    end
    local strTalentType = GetStrByCharacterPointType(tab.TalentType);
    if tab.TalentType == CharacterPointType.RACIAL_TREE then
        ShowTypeTalentPoint(CharacterPointType.RACIAL_TREE, strTalentType)
    end
    if tab.TalentType == CharacterPointType.PRESTIGE_TREE then
        ShowTypeTalentPoint(CharacterPointType.PRESTIGE_TREE, strTalentType)
    end
    if tab.TalentType == CharacterPointType.TALENT_SKILL_TREE then
        ShowTypeTalentPoint(CharacterPointType.TALENT_SKILL_TREE, strTalentType)
    end

    TalentTreeWindow.Container:SetBackdrop({
        bgFile = PATH .. "tabBG\\" .. tab.Background
    });
end

function GetPointByCharacterPointType(type, resetTalents)
    for _, talent in pairs(FORGE_ACTIVE_SPEC.TalentPoints) do
        if tonumber(type) == tonumber(talent.CharacterPointType) then
            if resetTalents then
                talent.AvailablePoints = CalculateAvailablePoints()
            end
            return talent;
        end
    end
end

function CalculateAvailablePoints()
    -- Calculate the available talent points based on the player's level
    -- Get the player's level
    local playerLevel = UnitLevel("player")

    -- Determine the base talent points based on the player's level
    local basePoints = playerLevel >= 10 and (playerLevel - 9) or 0

    -- Return the calculated base talent points
    return basePoints
end

function ShowTypeTalentPoint(CharacterPointType, str)
    local talent = GetPointByCharacterPointType(tostring(CharacterPointType));
    TalentTreeWindow.PointsBottomLeft.Points:SetText(talent.AvailablePoints .. " " .. str .. " points")
end

function GetPointSpendByTabId(id)
    for tabId, points in pairs(FORGE_ACTIVE_SPEC.PointsSpent) do
        if tabId == id then
            return points;
        end
    end
end

function InitializePreviewSpecialization(tabId)
    TalentTreeWindow.SpecializationPreview = CreateFrame("Frame", TalentTreeWindow.SpecializationPreview,
        TalentTreeWindow)
    TalentTreeWindow.SpecializationPreview:SetSize(40, 40);
end

function InitializeTalentLeft()
    if TalentTreeWindow.TabsLeft then
        return;
    end
    TalentTreeWindow.TabsLeft = CreateFrame("Frame", TalentTreeWindow.TabsLeft, TalentTreeWindow);
    TalentTreeWindow.TabsLeft:SetFrameLevel(5);
    TalentTreeWindow.TabsLeft:SetSize(846, 846);
    TalentTreeWindow.TabsLeft:SetPoint("CENTER", -220, 612)
    TalentTreeWindow.TabsLeft.Spec = {};
    local y = 0;
    for index, tab in ipairs(TalentTree.FORGE_TABS) do
        local name, rank, icon, castTime, minRange, maxRange, spellID = GetSpellInfo(tab.SpellIconId)
        local pointsSpent = GetPointSpendByTabId(tab.Id);
        TalentTreeWindow.TabsLeft.Spec[tab.Id] = CreateFrame("Button", TalentTreeWindow.TabsLeft.Spec[tab.Id],
            TalentTreeWindow.TabsLeft);
        TalentTreeWindow.TabsLeft.Spec[tab.Id]:SetPoint("LEFT", -25, y);
        TalentTreeWindow.TabsLeft.Spec[tab.Id]:SetSize(220, 70);

        TalentTreeWindow.TabsLeft.Spec[tab.Id].Button = CreateFrame("Button", TalentTreeWindow.TabsLeft.Spec[tab.Id],
            TalentTreeWindow.TabsLeft);
        TalentTreeWindow.TabsLeft.Spec[tab.Id].Button:SetPoint("LEFT", -25, y);
        TalentTreeWindow.TabsLeft.Spec[tab.Id].Button:SetFrameLevel(2000)
        TalentTreeWindow.TabsLeft.Spec[tab.Id].Button:SetSize(220, 70);
        TalentTreeWindow.TabsLeft.Spec[tab.Id].Title = TalentTreeWindow.TabsLeft.Spec[tab.Id]:CreateFontString()
        TalentTreeWindow.TabsLeft.Spec[tab.Id].Title:SetFont("Fonts\\FRIZQT__.TTF", 12, "OUTLINE")
        TalentTreeWindow.TabsLeft.Spec[tab.Id].Title:SetPoint("LEFT", 55, -3)
        TalentTreeWindow.TabsLeft.Spec[tab.Id].Title:SetText(tab.Name)
        TalentTreeWindow.TabsLeft.Spec[tab.Id].TextureNormal =
            TalentTreeWindow.TabsLeft.Spec[tab.Id]:CreateTexture("$parentNormalTexture", "ARTWORK");
        TalentTreeWindow.TabsLeft.Spec[tab.Id].TextureNormal:SetTexCoord(0, 0.625, 0.265625, 0);
        TalentTreeWindow.TabsLeft.Spec[tab.Id].TextureNormal:SetAllPoints();
        TalentTreeWindow.TabsLeft.Spec[tab.Id].TextureNormal:SetTexture(CONSTANTS.UI.SPECIALIZATION_BUTTON_BG_NORMAL)
        TalentTreeWindow.TabsLeft.Spec[tab.Id].TextureHighligted =
            TalentTreeWindow.TabsLeft.Spec[tab.Id]:CreateTexture("SetHighlightTexture", "ARTWORK");
        TalentTreeWindow.TabsLeft.Spec[tab.Id].TextureHighligted:SetAllPoints();
        TalentTreeWindow.TabsLeft.Spec[tab.Id].TextureHighligted:SetTexture(CONSTANTS.UI
                                                                                .SPECIALIZATION_BUTTON_BG_HOVER_OR_PUSHED)
        TalentTreeWindow.TabsLeft.Spec[tab.Id].TextureHighligted:SetTexCoord(0, 0.625, 0.265625, 0);

        TalentTreeWindow.TabsLeft.Spec[tab.Id].LockedTexture =
            TalentTreeWindow.TabsLeft.Spec[tab.Id]:CreateTexture("$parentNormalTexture", "ARTWORK");
        TalentTreeWindow.TabsLeft.Spec[tab.Id].LockedTexture:SetAllPoints();
        TalentTreeWindow.TabsLeft.Spec[tab.Id].LockedTexture:SetTexture(CONSTANTS.UI.SPECIALIZATION_BUTTON_BG_DISABLED)
        TalentTreeWindow.TabsLeft.Spec[tab.Id].LockedTexture:SetTexCoord(0, 0.625, 0.265625, 0);

        TalentTreeWindow.TabsLeft.Spec[tab.Id]:SetNormalTexture(TalentTreeWindow.TabsLeft.Spec[tab.Id].TextureNormal)
        TalentTreeWindow.TabsLeft.Spec[tab.Id]:SetHighlightTexture(
            TalentTreeWindow.TabsLeft.Spec[tab.Id].TextureHighligted)
        TalentTreeWindow.TabsLeft.Spec[tab.Id]:SetPushedTexture(TalentTreeWindow.TabsLeft.Spec[tab.Id].TextureHighligted)
        TalentTreeWindow.TabsLeft.Spec[tab.Id]:SetDisabledTexture(TalentTreeWindow.TabsLeft.Spec[tab.Id].LockedTexture)

        TalentTreeWindow.TabsLeft.Spec[tab.Id].Icon = CreateFrame("Frame", TalentTreeWindow.TabsLeft.Spec[tab.Id].Icon,
            TalentTreeWindow.TabsLeft.Spec[tab.Id]);
        TalentTreeWindow.TabsLeft.Spec[tab.Id].Icon:SetPoint("LEFT", 12, -1)
        TalentTreeWindow.TabsLeft.Spec[tab.Id].Icon:SetFrameLevel(9);
        TalentTreeWindow.TabsLeft.Spec[tab.Id].Icon:SetSize(32, 32);

        TalentTreeWindow.TabsLeft.Spec[tab.Id].Icon.Texture =
            TalentTreeWindow.TabsLeft.Spec[tab.Id].Icon:CreateTexture("$parentNormalTexture", "ARTWORK");
        TalentTreeWindow.TabsLeft.Spec[tab.Id].Icon.Texture:SetAllPoints();
        SetPortraitToTexture(TalentTreeWindow.TabsLeft.Spec[tab.Id].Icon.Texture, icon)

        TalentTreeWindow.TabsLeft.Spec[tab.Id].Circle = CreateFrame("Button",
            TalentTreeWindow.TabsLeft.Spec[tab.Id].Circle, TalentTreeWindow.TabsLeft.Spec[tab.Id]);
        TalentTreeWindow.TabsLeft.Spec[tab.Id].Circle:SetPoint("LEFT", 5, -19)
        TalentTreeWindow.TabsLeft.Spec[tab.Id].Circle:SetFrameLevel(10);
        TalentTreeWindow.TabsLeft.Spec[tab.Id].Circle:SetSize(80, 80);
        TalentTreeWindow.TabsLeft.Spec[tab.Id].Circle:SetBackdrop({
            bgFile = CONSTANTS.UI.SPEC_RING
        });
        if tab.TalentType ~= CharacterPointType.SKILL_PAGE then
            TalentTreeWindow.TabsLeft.Spec[tab.Id].Points = CreateFrame("Button",
                TalentTreeWindow.TabsLeft.Spec[tab.Id].Points, TalentTreeWindow.TabsLeft.Spec[tab.Id].Circle);
            TalentTreeWindow.TabsLeft.Spec[tab.Id].Points:SetPoint("BOTTOM", 0, 32)
            TalentTreeWindow.TabsLeft.Spec[tab.Id].Points:SetFrameLevel(12);
            TalentTreeWindow.TabsLeft.Spec[tab.Id].Points:SetSize(18, 18);
            TalentTreeWindow.TabsLeft.Spec[tab.Id].Points:SetBackdrop({
                bgFile = CONSTANTS.UI.RING_POINTS
            });
            TalentTreeWindow.TabsLeft.Spec[tab.Id].Points.Text =
                TalentTreeWindow.TabsLeft.Spec[tab.Id].Points:CreateFontString();
            TalentTreeWindow.TabsLeft.Spec[tab.Id].Points.Text:SetFont("Fonts\\FRIZQT__.TTF", 9, "OUTLINE")
            TalentTreeWindow.TabsLeft.Spec[tab.Id].Points.Text:SetPoint("CENTER", 0, 0)
            TalentTreeWindow.TabsLeft.Spec[tab.Id].Points.Text:SetText("0");
            if pointsSpent then
                TalentTreeWindow.TabsLeft.Spec[tab.Id].Points.Text:SetText(pointsSpent);
            end
        end
        TalentTreeWindow.TabsLeft.Spec[tab.Id].Button:SetScript("OnClick", function()
            SelectTab(tab);
        end)
        y = y - 60;
    end
end

function InitializeForgePoints()
    if TalentTreeWindow.PointsBottomLeft then
        return;
    end
    TalentTreeWindow.PointsBottomLeft = CreateFrame("Frame", TalentTreeWindow.PointsBottomLeft, TalentTreeWindow);
    TalentTreeWindow.PointsBottomLeft:SetSize(100, 100);
    TalentTreeWindow.PointsBottomLeft:SetFrameLevel(2000);
    TalentTreeWindow.PointsBottomLeft:SetPoint("CENTER", -375, -55);
    TalentTreeWindow.PointsBottomLeft.Points = TalentTreeWindow.PointsBottomLeft:CreateFontString()
    TalentTreeWindow.PointsBottomLeft.Points:SetFont("Fonts\\FRIZQT__.TTF", 15, "OUTLINE")
    TalentTreeWindow.PointsBottomLeft.Points:SetPoint("CENTER", -190, -24)
end

function InitializeProgressionBar()
    if not TalentTreeWindow.ProgressBarPlaceholder then
        TalentTreeWindow.ProgressBarPlaceholder = CreateFrame("Button", TalentTreeWindow.ProgressBarPlaceholder,
            TalentTreeWindow);
    end
    TalentTreeWindow.ProgressBarPlaceholder:SetSize(0, 0);
    TalentTreeWindow.ProgressBarPlaceholder:SetFrameLevel(11);
    TalentTreeWindow.ProgressBarPlaceholder:SetPoint("CENTER", 150.5, -528.5)
    TalentTreeWindow.ProgressBarPlaceholder:SetBackdrop({
        bgFile = CONSTANTS.UI.EMPTY_PROGRESS_BAR
    });
    local talent = GetPointByCharacterPointType(1);
    local progression = 0;
    local total = 0;
    if talent then
        total = tonumber(talent.Earned)
        local percentage = tonumber(talent.Earned) / tonumber(talent.MaxPoints) * 100
        progression = 7.675 * percentage
    end

    if not TalentTreeWindow.ProgressBarPlaceholder.Progression then
        TalentTreeWindow.ProgressBarPlaceholder.Progression = CreateFrame("Frame",
            TalentTreeWindow.ProgressBarPlaceholder, TalentTreeWindow);
        TalentTreeWindow.ProgressBarPlaceholder.Progression:SetFrameLevel(10);
        TalentTreeWindow.ProgressBarPlaceholder.Progression:SetPoint("LEFT", 0, 0)
        TalentTreeWindow.ProgressBarPlaceholder.Progression:SetBackdrop({
            bgFile = CONSTANTS.UI.COLORED_PROGRESS_BAR
        });
    end

    TalentTreeWindow.ProgressBarPlaceholder.Progression:SetSize(progression, 0);

    if not TalentTreeWindow.ProgressBarPlaceholder.Text then
        TalentTreeWindow.ProgressBarPlaceholder.Text = TalentTreeWindow.ProgressBarPlaceholder:CreateFontString()
        TalentTreeWindow.ProgressBarPlaceholder.Text:SetFont("Fonts\\FRIZQT__.TTF", 10, "OUTLINE")
        TalentTreeWindow.ProgressBarPlaceholder.Text:SetPoint("TOP", -100, -15)
    end

    TalentTreeWindow.ProgressBarPlaceholder.Text:SetText(total .. " / " .. talent.MaxPoints)
end

function InitializeGridForTalent()
    if TalentTreeWindow.GridTalent then
        TalentTreeWindow.GridTalent:Hide();
    end
    TalentTreeWindow.GridTalent = CreateFrame("Frame", TalentTreeWindow.GridTalent, TalentTreeWindow.Container);
    TalentTreeWindow.GridTalent:SetPoint("LEFT", 10, 10);
    TalentTreeWindow.GridTalent:SetSize(800, 800);
    TalentTreeWindow.GridTalent:Show();
    if not TalentTreeWindow.GridTalent.Talents then
        TalentTreeWindow.GridTalent.Talents = {};
    end
    local posX = -140;
    for i = 0, 21 do
        if not TalentTreeWindow.GridTalent.Talents[i] then
            TalentTreeWindow.GridTalent.Talents[i] = {};
        end
        local posY = -260;
        for j = 0, 21 do
            if TalentTreeWindow.GridTalent.Talents[i][j] then
                TalentTreeWindow.GridTalent.Talents[i][j]:Hide();
                TalentTreeWindow.GridTalent.Talents[i][j] = nil;
                TalentTreeWindow.GridTalent.Talents[i][j].Tooltip[1]:hide();
                if TalentTreeWindow.GridTalent.Talents[i][j].Tooltip[2] then
                    TalentTreeWindow.GridTalent.Talents[i][j].Tooltip[2]:hide();
                end
            end
            TalentTreeWindow.GridTalent.Talents[i][j] = CreateFrame("Button", TalentTreeWindow.GridTalent.Talents[i][j],
                TalentTreeWindow.GridTalent);
            TalentTreeWindow.GridTalent.Talents[i][j]:SetPoint("CENTER", posX, posY)
            TalentTreeWindow.GridTalent.Talents[i][j]:SetFrameLevel(9);
            TalentTreeWindow.GridTalent.Talents[i][j]:SetSize(40, 40);

            TalentTreeWindow.GridTalent.Talents[i][j].TextureIcon =
                TalentTreeWindow.GridTalent.Talents[i][j]:CreateTexture();
            TalentTreeWindow.GridTalent.Talents[i][j].TextureIcon:SetAllPoints()

            TalentTreeWindow.GridTalent.Talents[i][j].Border = CreateFrame("Frame",
                TalentTreeWindow.GridTalent.Talents[i][j].Border, TalentTreeWindow.GridTalent.Talents[i][j])
            TalentTreeWindow.GridTalent.Talents[i][j].Border:SetFrameLevel(10);
            TalentTreeWindow.GridTalent.Talents[i][j].Border:SetPoint("CENTER", -2, 0);
            TalentTreeWindow.GridTalent.Talents[i][j].Border:SetSize(58, 58);

            TalentTreeWindow.GridTalent.Talents[i][j].Exclusivity =
                CreateFrame("Frame", TalentTreeWindow.GridTalent.Talents[i][j].Exclusivity,
                    TalentTreeWindow.GridTalent.Talents[i][j])
            TalentTreeWindow.GridTalent.Talents[i][j].Exclusivity:SetFrameLevel(12);
            TalentTreeWindow.GridTalent.Talents[i][j].Exclusivity:SetPoint("CENTER", 0, 0);
            TalentTreeWindow.GridTalent.Talents[i][j].Exclusivity:SetSize(48, 48);

            TalentTreeWindow.GridTalent.Talents[i][j].Exclusivity:SetBackdrop({
                bgFile = CONSTANTS.UI.BORDER_EXCLUSIVITY
            })
            TalentTreeWindow.GridTalent.Talents[i][j].Exclusivity:Hide();

            TalentTreeWindow.GridTalent.Talents[i][j].Ranks = CreateFrame("Frame",
                TalentTreeWindow.GridTalent.Talents[i][j].Ranks, TalentTreeWindow.GridTalent.Talents[i][j]);
            TalentTreeWindow.GridTalent.Talents[i][j].Ranks:SetFrameLevel(13);
            TalentTreeWindow.GridTalent.Talents[i][j].Ranks:SetPoint("BOTTOM", 0, -12);
            TalentTreeWindow.GridTalent.Talents[i][j].Ranks:SetSize(32, 26);
            TalentTreeWindow.GridTalent.Talents[i][j].Ranks:SetBackdrop({
                bgFile = PATH .. "rank_placeholder"
            })
            TalentTreeWindow.GridTalent.Talents[i][j].RankText =
                TalentTreeWindow.GridTalent.Talents[i][j].Ranks:CreateFontString()
            TalentTreeWindow.GridTalent.Talents[i][j].RankText:SetFont("Fonts\\FRIZQT__.TTF", 9, "OUTLINE")
            TalentTreeWindow.GridTalent.Talents[i][j].RankText:SetPoint("BOTTOM", 0, 8.5)
            TalentTreeWindow.GridTalent.Talents[i][j].node = {};
            TalentTreeWindow.GridTalent.Talents[i][j]:Hide();
            posY = posY + 60
        end
        posX = posX + 30
    end
end

function FindPreReq(spells, spellId)
    for _, spell in pairs(spells) do
        if tonumber(spell.SpellId) == spellId then
            return spell;
        end
    end
end

function InitializePreReqAndDrawNodes(spells, spellNode, children, parent, offset, CurrentRank)
    for _, pr in pairs(spellNode.Prereqs) do
        local previousSpell = FindPreReq(spells, tonumber(pr.Talent));
        local startPosition = GetPositionXY(children[tonumber(previousSpell.ColumnIndex)][tonumber(
            previousSpell.RowIndex)]);
        local endPosition = GetPositionXY(children[tonumber(spellNode.ColumnIndex)][tonumber(spellNode.RowIndex)]);
        DrawNode(endPosition, startPosition,
            children[tonumber(previousSpell.ColumnIndex)][tonumber(previousSpell.RowIndex)], parent, offset, spellNode,
            CurrentRank, previousSpell);
    end
end

function LearnTalent(tabId, spell)
    PushForgeMessage(ForgeTopic.LEARN_TALENT, tabId .. ";" .. spell.SpellId)
end

function CreateTooltip(spell, SpellId, NextSpellId, parent, CurrentRank)
    if (SpellId == nil) then
        return
    end
    FirstRankToolTip:SetOwner(parent, "ANCHOR_RIGHT");
    SecondRankToolTip:SetOwner(FirstRankToolTip, "ANCHOR_BOTTOM");
    FirstRankToolTip:SetHyperlink('spell:' .. SpellId);

    if tonumber(spell.RankCost) > 0 and (CurrentRank < tonumber(spell.NumberOfRanks)) then
        FirstRankToolTip:AddLine("Rank cost: " .. spell.RankCost, 1, 1, 1);
        FirstRankToolTip:AddLine("Required Level: " .. spell.RequiredLevel, 1, 1, 1);
    end
    if not NextSpellId and tonumber(spell.RankCost) > 0 and (CurrentRank < tonumber(spell.NumberOfRanks)) then
        FirstRankToolTip:SetSize(FirstRankToolTip:GetWidth(), FirstRankToolTip:GetHeight() + 28)
    end
    if NextSpellId then
        FirstRankToolTip:AddLine("Next rank:", 1, 1, 1);
        SecondRankToolTip:SetHyperlink('spell:' .. NextSpellId);
        SecondRankToolTip:SetBackdropBorderColor(0, 0, 0, 0);
        SecondRankToolTip:SetBackdropColor(0, 0, 0, 0);
        SecondRankToolTip:AddLine(" ")

        SecondRankToolTip:SetPoint("TOP", FirstRankToolTip, "TOP", 0, -(FirstRankToolTip:GetHeight() + 25));
        FirstRankToolTip:SetSize(FirstRankToolTip:GetWidth(),
            FirstRankToolTip:GetHeight() + SecondRankToolTip:GetHeight() + 30)
    end
end

function GetSpellIdAndNextRank(tabId, spell)
    local NextSpellId;
    local SpellId;
    local CurrentRank = 0;
    local SpellIdToFind = tostring(spell.SpellId)
    CurrentRank = tonumber(TalentTree.FORGE_TALENTS[tabId][SpellIdToFind]);
    if CurrentRank == -1 or CurrentRank == 0 then
        SpellId = tonumber(spell.Ranks["1"]);
    else
        SpellId = tonumber(spell.Ranks[tostring(CurrentRank)]);
        NextSpellId = tonumber(spell.Ranks[tostring(CurrentRank + 1)]);
    end
    return CurrentRank, SpellId, NextSpellId;
end

function IsUnlocked(CurrentRank, NumberOfRanks, NextSpellId)
    if tonumber(NumberOfRanks) == 1 and tonumber(CurrentRank) == 1 then
        return tonumber(CurrentRank) == tonumber(NumberOfRanks);
    end
    if tonumber(NumberOfRanks) > 1 then
        return tonumber(CurrentRank) == tonumber(NumberOfRanks);
    end
end

function InitializeViewFromGrid(children, spells, tabId, offset)
    for index, spell in pairs(spells) do
        local CurrentRank, SpellId, NextSpellId = GetSpellIdAndNextRank(tabId, spell);
        local name, rank, icon, castTime, minRange, maxRange, spellID = GetSpellInfo(spell.SpellId)
        local ColumnIndex = tonumber(spell.ColumnIndex);
        local RowIndex = tonumber(spell.RowIndex);
        local NumberOfRanks = tonumber(spell.NumberOfRanks);
        local frame = children.Talents[ColumnIndex][RowIndex];
        if not frame then
            return;
        end
        if IsUnlocked(CurrentRank, NumberOfRanks) then
            frame.Border:SetBackdrop({
                bgFile = CONSTANTS.UI.BORDER_UNLOCKED
            })
        else
            if CurrentRank ~= -1 then
                frame.TextureIcon:SetDesaturated(nil);
                frame.Border:SetBackdrop({
                    bgFile = CONSTANTS.UI.BORDER_ACTIVE
                })
                if spell.ExclusiveWith[1] then
                    frame.Exclusivity:Show();
                end
            else
                if CurrentRank < 1 then
                    frame.TextureIcon:SetDesaturated(1);
                    frame.Border:SetBackdrop({
                        bgFile = CONSTANTS.UI.BORDER_LOCKED
                    })
                else
                    frame.Border:SetBackdrop({
                        bgFile = CONSTANTS.UI.BORDER_ACTIVE
                    })
                end
                if spell.ExclusiveWith[1] then
                    frame.Exclusivity:Hide();
                end
            end
        end
        if spell.Prereqs then
            InitializePreReqAndDrawNodes(spells, spell, children.Talents, children, offset, CurrentRank)
        end
        frame.Init = true;
        if NumberOfRanks == 0 then
            frame:SetSize(38, 38);
            frame.Ranks:Hide();
            frame.Border:Hide();
            frame.TextureIcon:SetTexture(icon);
        else
            frame:SetScript("OnEnter", function()
                CreateTooltip(spell, SpellId, NextSpellId, frame, CurrentRank);
                frame.IsTooltipActive = true;
            end)
            frame:SetScript("OnLeave", function()
                FirstRankToolTip:Hide();
                SecondRankToolTip:Hide();
                frame.IsTooltipActive = false;
            end)
            frame.RankText:SetText(CurrentRankSpell(CurrentRank) .. "/" .. spell.NumberOfRanks)
            frame:SetScript("OnClick", function()
                LearnTalent(tabId, spell)
            end)
            SetPortraitToTexture(frame.TextureIcon, icon)
        end
        frame:Show();
    end
end

function CurrentRankSpell(CurrentRank)
    if CurrentRank == "-1" or CurrentRank == -1 then
        return 0;
    end
    return CurrentRank;
end

function InitializeMiddleSpell()
    if TalentTreeWindow.GridForgeSkill.Talents and TalentTreeWindow.GridForgeSkill.Talents[11][5].Ranks then
        TalentTreeWindow.GridForgeSkill.Talents[11][5]:SetSize(40, 40);
        TalentTreeWindow.GridForgeSkill.Talents[11][5].Ranks:Hide();
    end
end

function InitializeGridForForgeSkills()
    if TalentTreeWindow.GridForgeSkill then
        TalentTreeWindow.GridForgeSkill:Hide();
    end
    TalentTreeWindow.GridForgeSkill = CreateFrame("Frame", TalentTreeWindow.GridForgeSkill, TalentTreeWindow.Container);
    TalentTreeWindow.GridForgeSkill:SetPoint("LEFT", -375, 25);
    TalentTreeWindow.GridForgeSkill:SetSize(946, 946);
    TalentTreeWindow.GridForgeSkill.Talents = {};
    TalentTreeWindow.GridForgeSkill:Hide();
    local posX = 0;
    for i = 1, 20 do
        TalentTreeWindow.GridForgeSkill.Talents[i] = {};
        local posY = 0;
        for j = 1, 9 do
            TalentTreeWindow.GridForgeSkill.Talents[i][j] = CreateFrame("Button",
                TalentTreeWindow.GridForgeSkill.Talents[i][j], TalentTreeWindow.GridForgeSkill);
            TalentTreeWindow.GridForgeSkill.Talents[i][j]:SetPoint("CENTER", posX, posY)
            TalentTreeWindow.GridForgeSkill.Talents[i][j]:SetFrameLevel(9);
            TalentTreeWindow.GridForgeSkill.Talents[i][j]:SetSize(30, 30);
            TalentTreeWindow.GridForgeSkill.Talents[i][j].TextureIcon =
                TalentTreeWindow.GridForgeSkill.Talents[i][j]:CreateTexture();
            TalentTreeWindow.GridForgeSkill.Talents[i][j].TextureIcon:SetAllPoints()

            TalentTreeWindow.GridForgeSkill.Talents[i][j].Border =
                CreateFrame("Frame", TalentTreeWindow.GridForgeSkill.Talents[i][j].Border,
                    TalentTreeWindow.GridForgeSkill.Talents[i][j])
            TalentTreeWindow.GridForgeSkill.Talents[i][j].Border:SetFrameLevel(10);
            TalentTreeWindow.GridForgeSkill.Talents[i][j].Border:SetPoint("CENTER", 0, 0);
            TalentTreeWindow.GridForgeSkill.Talents[i][j].Border:SetSize(48, 48);

            TalentTreeWindow.GridForgeSkill.Talents[i][j].Exclusivity = CreateFrame("Frame",
                TalentTreeWindow.GridForgeSkill.Talents[i][j].Exclusivity, TalentTreeWindow.GridForgeSkill.Talents[i][j])
            TalentTreeWindow.GridForgeSkill.Talents[i][j].Exclusivity:SetFrameLevel(12);
            TalentTreeWindow.GridForgeSkill.Talents[i][j].Exclusivity:SetPoint("CENTER", 0, 0);
            TalentTreeWindow.GridForgeSkill.Talents[i][j].Exclusivity:SetSize(48, 48);
            TalentTreeWindow.GridForgeSkill.Talents[i][j].Exclusivity:SetBackdrop({
                bgFile = CONSTANTS.UI.BORDER_EXCLUSIVITY
            })
            TalentTreeWindow.GridForgeSkill.Talents[i][j].Exclusivity:Hide();

            TalentTreeWindow.GridForgeSkill.Talents[i][j].Ranks =
                CreateFrame("Frame", TalentTreeWindow.GridForgeSkill.Talents[i][j].Ranks,
                    TalentTreeWindow.GridForgeSkill.Talents[i][j]);

            TalentTreeWindow.GridForgeSkill.Talents[i][j].Ranks:SetFrameLevel(1001);
            TalentTreeWindow.GridForgeSkill.Talents[i][j].Ranks:SetPoint("BOTTOM", 0, -12);
            TalentTreeWindow.GridForgeSkill.Talents[i][j].Ranks:SetSize(32, 26);
            TalentTreeWindow.GridForgeSkill.Talents[i][j].Ranks:SetBackdrop({
                bgFile = PATH .. "rank_placeholder"
            })
            TalentTreeWindow.GridForgeSkill.Talents[i][j].RankText =
                TalentTreeWindow.GridForgeSkill.Talents[i][j].Ranks:CreateFontString()
            TalentTreeWindow.GridForgeSkill.Talents[i][j].RankText:SetFont("Fonts\\FRIZQT__.TTF", 9, "OUTLINE")
            TalentTreeWindow.GridForgeSkill.Talents[i][j].RankText:SetPoint("BOTTOM", 0, 8.5)
            TalentTreeWindow.GridForgeSkill.Talents[i][j].node = {};
            TalentTreeWindow.GridForgeSkill.Talents[i][j]:Hide()
            posY = posY + 40
        end
        posX = posX + 40
    end
end

function HideForgeSkills()
    InitializeGridForForgeSkills();
    TalentTreeWindow.GridForgeSkill:Hide();
    TalentTreeWindow.Container.CloseButtonForgeSkills:Hide();
    TalentTreeWindow.SpellBook:Show();
    TalentTreeWindow.TabsLeft:Show();
    TalentTreeWindow.Container:SetBackdrop({
        bgFile = CONSTANTS.UI.DEFAULT_BOOK
    })
end

function IsForgeSkillFrameActive()
    return TalentTreeWindow.GridForgeSkill:IsShown();
end

function ShowForgeSkill(tab)
    InitializeViewFromGrid(TalentTreeWindow.GridForgeSkill, tab.Talents, tab.Id, 465);
    TalentTreeWindow.GridForgeSkill:Show();
    TalentTreeWindow.SpellBook:Hide();
    TalentTreeWindow.TabsLeft:Hide();
    TalentTreeWindow.Container.CloseButtonForgeSkills:Show();
    TalentTreeWindow.Container:SetBackdrop({
        bgFile = PATH .. "SkillForge"
    });
    TalentTree.FORGE_SELECTED_TAB = tab;
end

function ShowSpellsToForge(spells)
    local posX = 0;
    local posY = 0;
    for index, spell in pairs(spells) do
        local pointsSpent = GetPointSpendByTabId(spell.Id);
        local name, rank, icon, castTime, minRange, maxRange, spellID = GetSpellInfo(spell.SpellIconId)
        if TalentTreeWindow.SpellBook.Spells[index] then
            TalentTreeWindow.SpellBook.Spells[index].Icon:Hide();
            TalentTreeWindow.SpellBook.Spells[index].Icon = nil;
            TalentTreeWindow.SpellBook.Spells[index].SpellName:Hide();
            TalentTreeWindow.SpellBook.Spells[index].SpellName = nil;
            TalentTreeWindow.SpellBook.Spells[index].Texture:Hide();
            TalentTreeWindow.SpellBook.Spells[index].Texture = nil;
        end
        TalentTreeWindow.SpellBook.Spells[index] = {};
        TalentTreeWindow.SpellBook.Spells[index].Icon = CreateFrame("Button",
            TalentTreeWindow.SpellBook.Spells[index].Icon, TalentTreeWindow.SpellBook);
        TalentTreeWindow.SpellBook.Spells[index].Icon:SetPoint("LEFT", posX, posY)
        TalentTreeWindow.SpellBook.Spells[index].Icon:SetFrameLevel(12);
        TalentTreeWindow.SpellBook.Spells[index].Icon:SetSize(36, 36);
        TalentTreeWindow.SpellBook.Spells[index].Icon:SetBackdrop({
            bgFile = icon
        });

        TalentTreeWindow.SpellBook.Spells[index].Points = CreateFrame("Button",
            TalentTreeWindow.SpellBook.Spells[index].Points, TalentTreeWindow.SpellBook.Spells[index].Icon);
        TalentTreeWindow.SpellBook.Spells[index].Points:SetPoint("BOTTOMRIGHT", 5, -5)
        TalentTreeWindow.SpellBook.Spells[index].Points:SetFrameLevel(2000);
        TalentTreeWindow.SpellBook.Spells[index].Points:SetSize(18, 18);
        TalentTreeWindow.SpellBook.Spells[index].Points:SetBackdrop({
            bgFile = CONSTANTS.UI.RING_POINTS
        });
        TalentTreeWindow.SpellBook.Spells[index].Points.Text =
            TalentTreeWindow.SpellBook.Spells[index].Points:CreateFontString();
        TalentTreeWindow.SpellBook.Spells[index].Points.Text:SetFont("Fonts\\FRIZQT__.TTF", 9, "OUTLINE")
        TalentTreeWindow.SpellBook.Spells[index].Points.Text:SetPoint("CENTER", 0, 0)
        TalentTreeWindow.SpellBook.Spells[index].Points.Text:SetText("0");
        if pointsSpent then
            TalentTreeWindow.SpellBook.Spells[index].Points.Text:SetText(pointsSpent);
        end
        TalentTreeWindow.SpellBook.Spells[index].SpellName =
            TalentTreeWindow.SpellBook.Spells[index].Icon:CreateFontString()
        TalentTreeWindow.SpellBook.Spells[index].SpellName:SetFont("Fonts\\FRIZQT__.TTF", 10)
        TalentTreeWindow.SpellBook.Spells[index].SpellName:SetSize(82, 200);
        TalentTreeWindow.SpellBook.Spells[index].SpellName:SetPoint("RIGHT", 90, 0);
        TalentTreeWindow.SpellBook.Spells[index].SpellName:SetShadowOffset(1, -1)
        TalentTreeWindow.SpellBook.Spells[index].SpellName:SetJustifyH("LEFT");
        TalentTreeWindow.SpellBook.Spells[index].SpellName:SetText(spell.Name)
        TalentTreeWindow.SpellBook.Spells[index].Texture = CreateFrame("Frame",
            TalentTreeWindow.SpellBook.Spells[index].Texture, TalentTreeWindow.SpellBook);
        TalentTreeWindow.SpellBook.Spells[index].Texture:SetPoint("LEFT", posX - 42, posY)
        TalentTreeWindow.SpellBook.Spells[index].Texture:SetFrameLevel(11);
        TalentTreeWindow.SpellBook.Spells[index].Texture:SetSize(265, 265);
        TalentTreeWindow.SpellBook.Spells[index].Texture:SetBackdrop({
            bgFile = CONSTANTS.UI.SHADOW_TEXTURE
        });

        TalentTreeWindow.SpellBook.Spells[index].Spell = CreateFrame("Button",
            TalentTreeWindow.SpellBook.Spells[index].Spell, TalentTreeWindow.SpellBook);
        TalentTreeWindow.SpellBook.Spells[index].Spell:SetPoint("LEFT", posX - 6, posY)
        TalentTreeWindow.SpellBook.Spells[index].Spell:SetFrameLevel(2000);
        TalentTreeWindow.SpellBook.Spells[index].Spell:SetSize(200, 48);

        TalentTreeWindow.SpellBook.Spells[index].Hover = CreateFrame("Frame",
            TalentTreeWindow.SpellBook.Spells[index].Hover, TalentTreeWindow.SpellBook);
        TalentTreeWindow.SpellBook.Spells[index].Hover:SetPoint("LEFT", posX - 6, posY)
        TalentTreeWindow.SpellBook.Spells[index].Hover:SetFrameLevel(3000);
        TalentTreeWindow.SpellBook.Spells[index].Hover:SetSize(48, 50);
        TalentTreeWindow.SpellBook.Spells[index].Hover:SetBackdrop({
            bgFile = PATH .. "over-btn-forge"
        });
        TalentTreeWindow.SpellBook.Spells[index].Hover:Hide();
        TalentTreeWindow.SpellBook.Spells[index].Spell:SetScript("OnClick", function()
            ShowForgeSkill(spell);
        end)

        TalentTreeWindow.SpellBook.Spells[index].Spell:SetScript("OnEnter", function()
            TalentTreeWindow.SpellBook.Spells[index].Hover:Show()
        end)

        TalentTreeWindow.SpellBook.Spells[index].Spell:SetScript("OnLeave", function()
            TalentTreeWindow.SpellBook.Spells[index].Hover:Hide()
        end)
        posY = posY - 50
        if index % 7 == 0 then
            posY = 0;
        end
        if index == 7 then
            posX = posX + 180
        end

        if index == 14 then
            posX = posX + 220
        end

        if index == 21 then
            posX = posX + 180
        end
    end
end

function switchPage(nextPage)
    if nextPage then
        if TalentTree.FORGE_CURRENT_PAGE + 1 > TalentTree.FORGE_MAX_PAGE then
            return;
        end
        TalentTree.FORGE_CURRENT_PAGE = TalentTree.FORGE_CURRENT_PAGE + 1;
    else
        if TalentTree.FORGE_CURRENT_PAGE - 1 < 1 then
            return;
        end
        TalentTree.FORGE_CURRENT_PAGE = TalentTree.FORGE_CURRENT_PAGE - 1;
    end
    local page = TalentTree.FORGE_SPELLS_PAGES[TalentTree.FORGE_CURRENT_PAGE];
    if page == nil then
        return;
    end
    if (TalentTree.FORGE_CURRENT_PAGE - 1) <= 0 then
        TalentTreeWindow.SpellBook.PreviousArrow:Disable();
    else
        TalentTreeWindow.SpellBook.PreviousArrow:Enable();
    end

    if TalentTree.FORGE_CURRENT_PAGE == TalentTree.FORGE_MAX_PAGE then
        TalentTreeWindow.SpellBook.NextArrow:Disable();
    else
        TalentTreeWindow.SpellBook.NextArrow:Enable();
    end
    ShowSpellsToForge(page);
end

function InitializeTabForSpellsToForge(SkillToForges)
    TalentTreeWindow.SpellBook = CreateFrame("Frame", TalentTreeWindow.SpellBook, TalentTreeWindow);
    TalentTreeWindow.SpellBook:SetPoint("CENTER", 120, 330);
    TalentTreeWindow.SpellBook:SetSize(800, 600);
    TalentTreeWindow.SpellBook.Spells = {};
    TalentTreeWindow.SpellBook:Hide();
    TalentTreeWindow.SpellBook.NextArrow = CreateFrame("Button", TalentTreeWindow.SpellBook.NextArrow,
        TalentTreeWindow.SpellBook);
    TalentTreeWindow.SpellBook.NextArrow:SetNormalTexture("Interface\\Buttons\\UI-SpellbookIcon-NextPage-Up")
    TalentTreeWindow.SpellBook.NextArrow:SetPushedTexture("Interface\\Buttons\\UI-SpellbookIcon-NextPage-Down")
    TalentTreeWindow.SpellBook.NextArrow:SetDisabledTexture("Interface\\Buttons\\UI-SpellbookIcon-NextPage-Disabled")
    TalentTreeWindow.SpellBook.NextArrow:SetPoint("BOTTOMRIGHT", -100, -40);
    TalentTreeWindow.SpellBook.NextArrow:SetFrameLevel(1000);
    TalentTreeWindow.SpellBook.NextArrow:SetSize(32, 32);
    TalentTreeWindow.SpellBook.NextArrow:SetText("Next page")
    TalentTreeWindow.SpellBook.NextArrow:SetScript("OnClick", function()
        switchPage(true);
    end)
    TalentTreeWindow.SpellBook.PreviousArrow = CreateFrame("Button", TalentTreeWindow.SpellBook.NextArrow,
        TalentTreeWindow.SpellBook);

    TalentTreeWindow.SpellBook.PreviousArrow:SetNormalTexture("Interface\\Buttons\\UI-SpellbookIcon-PrevPage-Up")
    TalentTreeWindow.SpellBook.PreviousArrow:SetPushedTexture("Interface\\Buttons\\UI-SpellbookIcon-PrevPage-Down")
    TalentTreeWindow.SpellBook.PreviousArrow:SetDisabledTexture("Interface\\Buttons\\UI-SpellbookIcon-PrevPage-Disabled")
    TalentTreeWindow.SpellBook.PreviousArrow:SetPoint("BOTTOMLEFT", 15, -40);
    TalentTreeWindow.SpellBook.PreviousArrow:SetFrameLevel(1000);
    TalentTreeWindow.SpellBook.PreviousArrow:SetSize(32, 32);
    TalentTreeWindow.SpellBook.PreviousArrow:SetText("Previous page")
    TalentTreeWindow.SpellBook.PreviousArrow:SetScript("OnClick", function()
        switchPage(false);
    end)
    TalentTree.FORGE_SPELLS_PAGES = SplitSpellsByChunk(SkillToForges, 27);
    TalentTree.FORGE_MAX_PAGE = Tablelength(TalentTree.FORGE_SPELLS_PAGES);
    switchPage(true);
end

