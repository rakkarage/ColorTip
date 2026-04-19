-- 🎨 ColorTip: Dynamic (class & reaction) tooltip name, border, and status bar.

local COLOR_ALLIED_GUILD = { r = 1, g = 0.85, b = 0.1 }
local COLOR_OTHER_GUILD = { r = 0.75, g = 0.6, b = 0.15 }

local lastColorR, lastColorG, lastColorB = 1, 1, 1
local lastReactionR, lastReactionG, lastReactionB = nil, nil, nil

local function GetReactionColor(unit)
	local reaction = UnitReaction(unit, "player")
	if reaction then
		local c = FACTION_BAR_COLORS[reaction]
		if c then return c.r, c.g, c.b end
	end
end

local function SetTooltipBorderColors(border, colorR, colorG, colorB, reactionR, reactionG, reactionB)
	if not border then return end
	if reactionR then
		border.TopEdge:SetVertexColor(reactionR, reactionG, reactionB)
		border.TopLeftCorner:SetVertexColor(reactionR, reactionG, reactionB)
		border.TopRightCorner:SetVertexColor(reactionR, reactionG, reactionB)
		border.BottomEdge:SetVertexColor(colorR, colorG, colorB)
		border.BottomLeftCorner:SetVertexColor(colorR, colorG, colorB)
		border.BottomRightCorner:SetVertexColor(colorR, colorG, colorB)
		border.LeftEdge:SetGradient("VERTICAL", CreateColor(colorR, colorG, colorB), CreateColor(reactionR, reactionG, reactionB))
		border.RightEdge:SetGradient("VERTICAL", CreateColor(colorR, colorG, colorB), CreateColor(reactionR, reactionG, reactionB))
	else
		border:SetBorderColor(colorR, colorG, colorB)
	end
end

local function SetTooltipStatusBarColor(r, g, b)
	if GameTooltipStatusBar then
		local tex = GameTooltipStatusBar:GetStatusBarTexture()
		if tex then tex:SetVertexColor(r, g, b) end
	end
end

local function RepaintColors(tooltip)
	if tooltip ~= GameTooltip then return end
	local border = tooltip.NineSlice
	local hasCustomColors = tooltip:GetAlpha() > 0 and (lastReactionR or (lastColorR ~= 1 or lastColorG ~= 1 or lastColorB ~= 1))
	if not hasCustomColors then return end
	SetTooltipBorderColors(border, lastColorR, lastColorG, lastColorB, lastReactionR, lastReactionG, lastReactionB)
	SetTooltipStatusBarColor(lastColorR, lastColorG, lastColorB)
end

local function ApplyColors(tooltip, unit)
	if tooltip ~= GameTooltip then return end
	local border = tooltip.NineSlice

	if UnitIsPlayer(unit) then
		local _, classId = UnitClass(unit)
		if classId then lastColorR, lastColorG, lastColorB = GetClassColor(classId) end
		lastReactionR, lastReactionG, lastReactionB = GetReactionColor(unit)

		local class = classId and (LOCALIZED_CLASS_NAMES_MALE[classId] or LOCALIZED_CLASS_NAMES_FEMALE[classId])
		local faction = UnitFactionGroup(unit)
		local playerGuild = GetGuildInfo("player")
		local unitGuild = GetGuildInfo(unit)

		for i = 2, 6 do
			local line = _G["GameTooltipTextLeft" .. i]
			if line then
				local text = line:GetText()
				if text and not issecretvalue(text) then
					if class and text:find(class, 1, true) then
						line:SetTextColor(lastColorR, lastColorG, lastColorB)
					elseif faction and text == faction then
						line:SetTextColor(lastReactionR or lastColorR, lastReactionG or lastColorG, lastReactionB or lastColorB)
					elseif unitGuild and text:find(unitGuild, 1, true) then
						if playerGuild and unitGuild == playerGuild then
							line:SetTextColor(COLOR_ALLIED_GUILD.r, COLOR_ALLIED_GUILD.g, COLOR_ALLIED_GUILD.b)
						else
							line:SetTextColor(COLOR_OTHER_GUILD.r, COLOR_OTHER_GUILD.g, COLOR_OTHER_GUILD.b)
						end
					end
				end
			end
		end
	else
		lastReactionR, lastReactionG, lastReactionB = nil, nil, nil
		local r, g, b = GetReactionColor(unit)
		lastColorR, lastColorG, lastColorB = r or 1, g or 1, b or 1
	end

	GameTooltipTextLeft1:SetTextColor(lastReactionR or lastColorR, lastReactionG or lastColorG, lastReactionB or lastColorB)

	SetTooltipBorderColors(border, lastColorR, lastColorG, lastColorB, lastReactionR, lastReactionG, lastReactionB)
	SetTooltipStatusBarColor(lastColorR, lastColorG, lastColorB)
end

local function ForceReset(tooltip)
	if tooltip ~= GameTooltip then return end
	lastColorR, lastColorG, lastColorB = 1, 1, 1
	lastReactionR, lastReactionG, lastReactionB = nil, nil, nil
	local border = tooltip.NineSlice
	if border then border:SetBorderColor(1, 1, 1) end
	if GameTooltipStatusBar then
		local tex = GameTooltipStatusBar:GetStatusBarTexture()
		if tex then tex:SetVertexColor(1, 1, 1) end
	end
end

TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Unit, function(tooltip, data)
	local unit = (data and data.unitToken) or (UnitExists("mouseover") and "mouseover")
	if not unit then return end
	ApplyColors(tooltip, unit)
end)

GameTooltip:HookScript("OnUpdate", RepaintColors)
GameTooltip:HookScript("OnHide", ForceReset)

TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Item, ForceReset)
TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Spell, ForceReset)
TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Action, ForceReset)
TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Object, ForceReset)
