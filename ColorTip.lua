-- ColorTip: Colors tooltips by unit type and class

local COLOR_ALLIED_GUILD = { r = 1, g = 0.85, b = 0.1 }   -- Player's own guild
local COLOR_OTHER_GUILD = { r = 0.75, g = 0.6, b = 0.15 } -- Other guilds

local lastR, lastG, lastB = 1, 1, 1
local lastRR, lastRG, lastRB = nil, nil, nil

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
	local ns = tooltip.NineSlice

	local isSecret = unit and issecretvalue(unit)
	local isUnit = not isSecret and unit and UnitExists(unit)

	if isUnit then
		if UnitIsPlayer(unit) then
			local _, classId = UnitClass(unit)
			if classId then lastR, lastG, lastB = GetClassColor(classId) end
			lastRR, lastRG, lastRB = GetReactionColor(unit)

			local class = classId and (LOCALIZED_CLASS_NAMES_MALE[classId] or LOCALIZED_CLASS_NAMES_FEMALE[classId])
			local faction = UnitFactionGroup(unit)
			local playerGuild = GetGuildInfo("player")
			local unitGuild = GetGuildInfo(unit)

			-- Color player info lines (class, faction, guild) in tooltips.
			-- NOTE: Only processes lines 2-6 which typically contain secondary info.
			-- Lines outside this range are not recolored, by design.
			for i = 2, 6 do
				local line = _G["GameTooltipTextLeft" .. i]
				if line then
					local text = line:GetText()
					if text and not issecretvalue(text) then
						if class and text:find(class, 1, true) then
							line:SetTextColor(lastR, lastG, lastB)
						elseif faction and text == faction then
							line:SetTextColor(lastRR or lastR, lastRG or lastG, lastRB or lastB)
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
			lastRR, lastRG, lastRB = nil, nil, nil
			lastR, lastG, lastB = GetReactionColor(unit)
		end
	end

	local isFading = tooltip:GetAlpha() > 0 and (lastRR or (lastR ~= 1 or lastG ~= 1 or lastB ~= 1))

	if isUnit or isFading then
		if ns then
			if lastRR then
				ns.TopEdge:SetVertexColor(lastRR, lastRG, lastRB)
				ns.TopLeftCorner:SetVertexColor(lastRR, lastRG, lastRB)
				ns.TopRightCorner:SetVertexColor(lastRR, lastRG, lastRB)
				ns.BottomEdge:SetVertexColor(lastR, lastG, lastB)
				ns.BottomLeftCorner:SetVertexColor(lastR, lastG, lastB)
				ns.BottomRightCorner:SetVertexColor(lastR, lastG, lastB)
				ns.LeftEdge:SetGradient("VERTICAL", CreateColor(lastR, lastG, lastB), CreateColor(lastRR, lastRG, lastRB))
				ns.RightEdge:SetGradient("VERTICAL", CreateColor(lastR, lastG, lastB), CreateColor(lastRR, lastRG, lastRB))
			else
				ns:SetBorderColor(lastR, lastG, lastB)
			end
		end

		GameTooltipTextLeft1:SetTextColor(lastRR or lastR, lastRG or lastG, lastRB or lastB)

		if GameTooltipStatusBar then
			local tex = GameTooltipStatusBar:GetStatusBarTexture()
			if tex then tex:SetVertexColor(lastR, lastG, lastB) end
		end
	end
end

local function ForceReset(tooltip)
	if tooltip ~= GameTooltip then return end
	lastR, lastG, lastB = 1, 1, 1
	lastRR, lastRG, lastRB = nil, nil, nil
	local ns = tooltip.NineSlice
	if ns then ns:SetBorderColor(1, 1, 1) end
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
