-- 🎨 ColorTip: Dynamic (class & reaction) tooltip name, border, and status bar.

local _, ns = ...

ns.ColorTip = {}
local ColorTip = ns.ColorTip

local COLOR_ALLIED_GUILD = { r = 1, g = 0.85, b = 0.1 }
local COLOR_OTHER_GUILD = { r = 0.75, g = 0.6, b = 0.15 }

ColorTip.lastR, ColorTip.lastG, ColorTip.lastB = 1, 1, 1
ColorTip.lastRR, ColorTip.lastRG, ColorTip.lastRB = nil, nil, nil

local function GetReactionColor(unit)
	local reaction = UnitReaction(unit, "player")
	if reaction then
		local c = FACTION_BAR_COLORS[reaction]
		if c then return c.r, c.g, c.b end
	end
end

local function UpdateTooltipColors(tooltip)
	if tooltip ~= GameTooltip then return end

	local _, unit = tooltip:GetUnit()
	local border = tooltip.NineSlice

	local isSecret = unit and issecretvalue(unit)
	local isUnit = not isSecret and unit and UnitExists(unit)

	if isUnit then
		if UnitIsPlayer(unit) then
			local _, classId = UnitClass(unit)
			if classId then ColorTip.lastR, ColorTip.lastG, ColorTip.lastB = GetClassColor(classId) end
			ColorTip.lastRR, ColorTip.lastRG, ColorTip.lastRB = GetReactionColor(unit)

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
							line:SetTextColor(ColorTip.lastR, ColorTip.lastG, ColorTip.lastB)
						elseif faction and text == faction then
							line:SetTextColor(ColorTip.lastRR or ColorTip.lastR, ColorTip.lastRG or ColorTip.lastG, ColorTip.lastRB or ColorTip.lastB)
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
			ColorTip.lastRR, ColorTip.lastRG, ColorTip.lastRB = nil, nil, nil
			local r, g, b = GetReactionColor(unit)
			if r then
				ColorTip.lastR, ColorTip.lastG, ColorTip.lastB = r, g, b
			else
				ColorTip.lastR, ColorTip.lastG, ColorTip.lastB = 1, 1, 1
			end
		end
	end

	local isFading = tooltip:GetAlpha() > 0 and (ColorTip.lastRR or (ColorTip.lastR ~= 1 or ColorTip.lastG ~= 1 or ColorTip.lastB ~= 1))

	if isUnit or isFading then
		if border then
			if ColorTip.lastRR then
				border.TopEdge:SetVertexColor(ColorTip.lastRR, ColorTip.lastRG, ColorTip.lastRB)
				border.TopLeftCorner:SetVertexColor(ColorTip.lastRR, ColorTip.lastRG, ColorTip.lastRB)
				border.TopRightCorner:SetVertexColor(ColorTip.lastRR, ColorTip.lastRG, ColorTip.lastRB)
				border.BottomEdge:SetVertexColor(ColorTip.lastR, ColorTip.lastG, ColorTip.lastB)
				border.BottomLeftCorner:SetVertexColor(ColorTip.lastR, ColorTip.lastG, ColorTip.lastB)
				border.BottomRightCorner:SetVertexColor(ColorTip.lastR, ColorTip.lastG, ColorTip.lastB)
				border.LeftEdge:SetGradient("VERTICAL", CreateColor(ColorTip.lastR, ColorTip.lastG, ColorTip.lastB), CreateColor(ColorTip.lastRR, ColorTip.lastRG, ColorTip.lastRB))
				border.RightEdge:SetGradient("VERTICAL", CreateColor(ColorTip.lastR, ColorTip.lastG, ColorTip.lastB), CreateColor(ColorTip.lastRR, ColorTip.lastRG, ColorTip.lastRB))
			else
				border:SetBorderColor(ColorTip.lastR, ColorTip.lastG, ColorTip.lastB)
			end
		end

		GameTooltipTextLeft1:SetTextColor(ColorTip.lastRR or ColorTip.lastR, ColorTip.lastRG or ColorTip.lastG, ColorTip.lastRB or ColorTip.lastB)

		if GameTooltipStatusBar then
			local tex = GameTooltipStatusBar:GetStatusBarTexture()
			if tex then tex:SetVertexColor(ColorTip.lastR, ColorTip.lastG, ColorTip.lastB) end
		end
	end
end

local function ForceReset(tooltip)
	if tooltip ~= GameTooltip then return end
	ColorTip.lastR, ColorTip.lastG, ColorTip.lastB = 1, 1, 1
	ColorTip.lastRR, ColorTip.lastRG, ColorTip.lastRB = nil, nil, nil
	local border = tooltip.NineSlice
	if border then border:SetBorderColor(1, 1, 1) end
	if GameTooltipStatusBar then
		local tex = GameTooltipStatusBar:GetStatusBarTexture()
		if tex then tex:SetVertexColor(1, 1, 1) end
	end
end

TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Unit, UpdateTooltipColors)
GameTooltip:HookScript("OnUpdate", UpdateTooltipColors)

TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Item, ForceReset)
TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Spell, ForceReset)
TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Action, ForceReset)
TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Object, ForceReset)
GameTooltip:HookScript("OnHide", ForceReset)
