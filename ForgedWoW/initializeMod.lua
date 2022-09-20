local Forgeframe = CreateFrame("Frame")
Forgeframe:RegisterEvent("PLAYER_LOGIN")
Forgeframe:SetScript("OnEvent", function()
    InitializeTalentTree()
    InitializeTooltips()
    GetItemStats(
end)