local Forgeframe = CreateFrame("Frame")
Forgeframe:RegisterEvent("PLAYER_LOGIN")
Forgeframe:SetScript("OnEvent", function()
    InitializeTalentTree()
    InitializeTooltips()

    ezCollections.Collections.OwnedItems.Enabled = true;
    ezCollections.Collections.Skins.Enabled = true;
    ezCollections.Collections.TakenQuests.Enabled = true;
    ezCollections.Collections.RewardedQuests.Enabled = true;
    ezCollections.Collections.Toys.Enabled = true;

    PushForgeMessage(ForgeTopic.COLLECTION_INIT, "-1");
end)