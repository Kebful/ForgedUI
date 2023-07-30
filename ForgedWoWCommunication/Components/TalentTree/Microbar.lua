local ForgedWoWMicrobarButton = CreateFrame("Button", "ForgedWoWMicrobarButton", MainMenuBarArtFrame, "MainMenuBarMicroButton");
LoadMicroButtonTextures(ForgedWoWMicrobarButton, "Help");
ForgedWoWMicrobarButton:SetNormalTexture(CONSTANTS.UI.NORMAL_TEXTURE_BTN)
ForgedWoWMicrobarButton:SetPushedTexture(CONSTANTS.UI.PUSHED_TEXTURE_BTN)
ForgedWoWMicrobarButton.tooltipText = MicroButtonTooltipText("Forge Talents", "TOGGLETALENTS");
ForgedWoWMicrobarButton.newbieText = "View your Character, Priestige, Race and Forged Skill talents";
ForgedWoWMicrobarButton:SetFrameLevel(1000);
ForgedWoWMicrobarButton:SetFrameLevel(1000);
ForgedWoWMicrobarButton:SetPoint("CENTER","TalentMicroButton","CENTER")
ForgedWoWMicrobarButton:SetScript("OnClick", function ()
    ToggleMainWindow();
end );

hooksecurefunc("UpdateMicroButtons", function()
    if TalentTreeWindow:IsShown() then
        PlaySound("TalentScreenOpen");
        ForgedWoWMicrobarButton:SetButtonState("PUSHED", 1);
    else
        PlaySound("TalentScreenClose");
        ForgedWoWMicrobarButton:SetButtonState("NORMAL");
    end
end);
