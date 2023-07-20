-- Fix gossips with code entry prompt not correctly submitting said code if closed by pressing Enter
do
    StaticPopupDialogs["GOSSIP_ENTER_CODE"].EditBoxOnEnterPressed = function(self, data)
        local parent = self:GetParent();
        SelectGossipOption(data, parent.editBox:GetText(), true);
        parent:Hide();
    end
end

-- Fix AceGUI's Dropdown widgets having their text on the same ARTWORK drawlayer as the rest of the widget's textures, leading to embedded textures in the text (|T...|t) to sometimes fall behind the widget
-- This issue is not exclusive to AceGUI and happens to any control that inherits from UIDropDownMenuTemplate, but in my case I need a fix specifically for AceConfig/AceGUI
do
    local registry = LibStub("AceGUI-3.0").WidgetRegistry;
    local old = registry["Dropdown"];
    if old then
        registry["Dropdown"] = function()
            local self = old();
            self.text:SetDrawLayer("OVERLAY");
            return self;
        end
    end
end

-- Fix InterfaceOptionsFrame_OpenToCategory not actually opening the category (and not even scrolling to it)
-- Taken from addon BlizzBugsSuck (https://www.wowinterface.com/downloads/info17002-BlizzBugsSuck.html) and edited to not be global
do
	local function get_panel_name(panel)
		local tp = type(panel)
		local cat = INTERFACEOPTIONS_ADDONCATEGORIES
		if tp == "string" then
			for i = 1, #cat do
				local p = cat[i]
				if p.name == panel then
					if p.parent then
						return get_panel_name(p.parent)
					else
						return panel
					end
				end
			end
		elseif tp == "table" then
			for i = 1, #cat do
				local p = cat[i]
				if p == panel then
					if p.parent then
						return get_panel_name(p.parent)
					else
						return panel.name
					end
				end
			end
		end
	end

	--[[local]] function InterfaceOptionsFrame_OpenToCategory_Fix(panel)
		if doNotRun or InCombatLockdown() then return end
		local panelName = get_panel_name(panel)
		if not panelName then return end -- if its not part of our list return early
		local noncollapsedHeaders = {}
		local shownpanels = 0
		local mypanel
		local t = {}
		local cat = INTERFACEOPTIONS_ADDONCATEGORIES
		for i = 1, #cat do
			local panel = cat[i]
			if not panel.parent or noncollapsedHeaders[panel.parent] then
				if panel.name == panelName then
					panel.collapsed = true
					t.element = panel
					InterfaceOptionsListButton_ToggleSubCategories(t)
					noncollapsedHeaders[panel.name] = true
					mypanel = shownpanels + 1
				end
				if not panel.collapsed then
					noncollapsedHeaders[panel.name] = true
				end
				shownpanels = shownpanels + 1
			end
		end
		local Smin, Smax = InterfaceOptionsFrameAddOnsListScrollBar:GetMinMaxValues()
		if shownpanels > 15 and Smin < Smax then
			local val = (Smax/(shownpanels-15))*(mypanel-2)
			InterfaceOptionsFrameAddOnsListScrollBar:SetValue(val)
		end
		doNotRun = true
		InterfaceOptionsFrame_OpenToCategory(panel)
		doNotRun = false
	end

	--hooksecurefunc("InterfaceOptionsFrame_OpenToCategory", InterfaceOptionsFrame_OpenToCategory_Fix)
end