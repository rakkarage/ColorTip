-- 🎨 ColorTip: Dynamic (class & reaction) tooltip name, border, and status bar.

local _, ns = ...

ns.ColorTip = {}
local ColorTip = ns.ColorTip

local COLOR_ALLIED_GUILD = { r = 1, g = 0.85, b = 0.1 }
local COLOR_OTHER_GUILD = { r = 0.75, g = 0.6, b = 0.15 }

ColorTip.lastR, ColorTip.lastG, ColorTip.lastB = 1, 1, 1
ColorTip.lastRR, ColorTip.lastRG, ColorTip.lastRB = nil, nil, nil

function GetReactionColor(unit)
	local reaction = UnitReaction(unit, "player")
	if reaction then
		local c = FACTION_BAR_COLORS[reaction]
		if c then return c.r, c.g, c.b end
	end
end

function ColorTip:UpdateTooltipColors(tooltip)
	if tooltip ~= GameTooltip then return end

	local _, unit = tooltip:GetUnit()
	local border = tooltip.NineSlice

	local isSecret = unit and issecretvalue(unit)
	local isUnit = not isSecret and unit and UnitExists(unit)

	if isUnit then
		if UnitIsPlayer(unit) then
			local _, classId = UnitClass(unit)
			if classId then self.lastR, self.lastG, self.lastB = GetClassColor(classId) end
			self.lastRR, self.lastRG, self.lastRB = GetReactionColor(unit)

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
							line:SetTextColor(self.lastR, self.lastG, self.lastB)
						elseif faction and text == faction then
							line:SetTextColor(self.lastRR or self.lastR, self.lastRG or self.lastG, self.lastRB or self.lastB)
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
			self.lastRR, self.lastRG, self.lastRB = nil, nil, nil
			local r, g, b = GetReactionColor(unit)
			if r then
				self.lastR, self.lastG, self.lastB = r, g, b
			else
				self.lastR, self.lastG, self.lastB = 1, 1, 1
			end
		end
	end

	local isFading = tooltip:GetAlpha() > 0 and (self.lastRR or (self.lastR ~= 1 or self.lastG ~= 1 or self.lastB ~= 1))

	if isUnit or isFading then
		if border then
			if self.lastRR then
				border.TopEdge:SetVertexColor(self.lastRR, self.lastRG, self.lastRB)
				border.TopLeftCorner:SetVertexColor(self.lastRR, self.lastRG, self.lastRB)
				border.TopRightCorner:SetVertexColor(self.lastRR, self.lastRG, self.lastRB)
				border.BottomEdge:SetVertexColor(self.lastR, self.lastG, self.lastB)
				border.BottomLeftCorner:SetVertexColor(self.lastR, self.lastG, self.lastB)
				border.BottomRightCorner:SetVertexColor(self.lastR, self.lastG, self.lastB)
				border.LeftEdge:SetGradient("VERTICAL", CreateColor(self.lastR, self.lastG, self.lastB), CreateColor(self.lastRR, self.lastRG, self.lastRB))
				border.RightEdge:SetGradient("VERTICAL", CreateColor(self.lastR, self.lastG, self.lastB), CreateColor(self.lastRR, self.lastRG, self.lastRB))
			else
				border:SetBorderColor(self.lastR, self.lastG, self.lastB)
			end
		end

		GameTooltipTextLeft1:SetTextColor(self.lastRR or self.lastR, self.lastRG or self.lastG, self.lastRB or self.lastB)

		if GameTooltipStatusBar then
			local tex = GameTooltipStatusBar:GetStatusBarTexture()
			if tex then tex:SetVertexColor(self.lastR, self.lastG, self.lastB) end
		end
	end
end

function ColorTip:ForceReset(tooltip)
	if tooltip ~= GameTooltip then return end
	self.lastR, self.lastG, self.lastB = 1, 1, 1
	self.lastRR, self.lastRG, self.lastRB = nil, nil, nil
	local border = tooltip.NineSlice
	if border then border:SetBorderColor(1, 1, 1) end
	if GameTooltipStatusBar then
		local tex = GameTooltipStatusBar:GetStatusBarTexture()
		if tex then tex:SetVertexColor(1, 1, 1) end
	end
end

TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Unit, function(...) ColorTip:UpdateTooltipColors(...) end)
GameTooltip:HookScript("OnUpdate", function(...) ColorTip:UpdateTooltipColors(...) end)

TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Item, function(...) ColorTip:ForceReset(...) end)
TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Spell, function(...) ColorTip:ForceReset(...) end)
TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Action, function(...) ColorTip:ForceReset(...) end)
TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Object, function(...) ColorTip:ForceReset(...) end)
