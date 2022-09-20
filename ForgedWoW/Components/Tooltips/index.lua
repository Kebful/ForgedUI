
Tooltips = {
    cache = {};
}

local function CreateFrameTooltip(i)
    return CreateFrame("GameTooltip", "SpellDescription" .. i, WorldFrame, "GameTooltipTemplate");
end

local function GetTooltipText(tooltip, id, type)
    for i = 1,15 do
        local frame = _G[tooltip:GetName() .. "TextLeft" .. i]
        local frameRight = _G[tooltip:GetName() .. "TextRight" .. i]
        local text
        local textRight
        if frame then text = frame:GetText() end
        if frameRight then textRight = frameRight:GetText() end
        if text then
            print (i, text)
        end 

        if textRight then
            print (i, textRight)
        end 
    end
end

GameTooltip:HookScript("OnTooltipSetSpell", function(self)
    local spellId = select(3, self:GetSpell())
    -- self:SetHyperlink('spell:' .. 64928)
    -- if id then GetTooltipText(self, id, "SpellID:") end
end)
