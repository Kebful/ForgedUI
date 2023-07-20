TalentTree = {
    FORGE_TABS         = {},
    FORGE_ACTIVE_SPEC  = {},
    FORGE_SPECS_TAB    = {},
    FORGE_SPEC_SLOTS   = {},
    FORGE_SELECTED_TAB = nil,
    FORGE_SPELLS_PAGES = {};
    FORGE_CURRENT_PAGE = 0;
    FORGE_MAX_PAGE     = nil;
    FORGE_TALENTS      = nil;
    INITIALIZED        = false;
}

TalentTreeWindow = CreateFrame("Frame", NULL, UIParent);
TalentTreeWindow:SetSize(1385, 1500); --- LEFT/RIGHT -- --UP/DOWN --
TalentTreeWindow:SetPoint("CENTER", 0, -250) --- LEFT/RIGHT -- --UP/DOWN --
TalentTreeWindow:SetFrameLevel(1);
TalentTreeWindow:SetBackdrop({
    bgFile = CONSTANTS.UI.MAIN_BG,
    tile = false,
});
TalentTreeWindow:Hide();
TalentTreeWindow.Container = CreateFrame("Frame", TalentTreeWindow.Container, TalentTreeWindow);
TalentTreeWindow.Container:SetSize(1370, 1500); -- Talent Tree Window's Background --
TalentTreeWindow.Container:SetPoint("CENTER", 0, 0)
TalentTreeWindow.Container:SetFrameLevel(2);
TalentTreeWindow.CloseButton = CreateFrame("Button", TalentTreeWindow.CloseButton, TalentTreeWindow, "UIPanelCloseButton")
TalentTreeWindow.CloseButton:SetSize(46, 47); --Exit Button on Upper Right--
TalentTreeWindow.CloseButton:SetPoint("TOPRIGHT", 3, -14);

TalentTreeWindow.ClassIcon = CreateFrame("Frame", TalentTreeWindow.ClassIcon, TalentTreeWindow);
TalentTreeWindow.ClassIcon:SetSize(90, 94);
TalentTreeWindow.ClassIcon:SetFrameLevel(0);
TalentTreeWindow.ClassIcon:SetPoint("TOPLEFT", 8, -4);
TalentTreeWindow.ClassIcon.Texture = TalentTreeWindow.ClassIcon:CreateTexture()
TalentTreeWindow.ClassIcon.Texture:SetAllPoints(TalentTreeWindow.ClassIcon)
SetPortraitToTexture(TalentTreeWindow.ClassIcon.Texture, CONSTANTS.classIcon[string.upper(CONSTANTS.CLASS)])

TalentTreeWindow.Container.CloseButtonForgeSkills = CreateFrame("Button",
    TalentTreeWindow.Container.CloseButtonForgeSkills, TalentTreeWindow.Container)

TalentTreeWindow.Container.CloseButtonForgeSkills:SetScript("OnClick", function()
    HideForgeSkills();
end)
TalentTreeWindow.Container.CloseButtonForgeSkills:SetSize(34, 34);
TalentTreeWindow.Container.CloseButtonForgeSkills:SetPoint("TOPRIGHT", -15, -75);
TalentTreeWindow.Container.CloseButtonForgeSkills.Circle = CreateFrame("Frame",
	TalentTreeWindow.Container.CloseButtonForgeSkills.Circle, TalentTreeWindow.Container.CloseButtonForgeSkills)
TalentTreeWindow.Container.CloseButtonForgeSkills.Circle:SetSize(40, 40);
TalentTreeWindow.Container.CloseButtonForgeSkills.Circle:SetPoint("CENTER", -1.5, -1);
TalentTreeWindow.Container.CloseButtonForgeSkills.Circle:SetBackdrop({
    bgFile = CONSTANTS.UI.BORDER_CLOSE_BTN
})
TalentTreeWindow.Container.CloseButtonForgeSkills:Hide();

TalentTreeWindow.ChoiceSpecs = CreateFrame("Frame", TalentTreeWindow.ChoiceSpecs, TalentTreeWindow.Container);
TalentTreeWindow.ChoiceSpecs:SetSize(TalentTreeWindow:GetWidth(), TalentTreeWindow:GetHeight());
TalentTreeWindow.ChoiceSpecs:SetPoint("TOP", 30, 30);
TalentTreeWindow.ChoiceSpecs:SetFrameLevel(15)
TalentTreeWindow.ChoiceSpecs:SetBackdrop({
    edgeSize = 24,
    bgFile = CONSTANTS.UI.BACKGROUND_SPECS,
})
TalentTreeWindow.ChoiceSpecs.Spec = {};
TalentTreeWindow.ChoiceSpecs:Hide();
