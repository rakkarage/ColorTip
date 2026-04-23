-- 🎨 ColorTip: Dynamic (class & reaction) tooltip name, border, and status bar.

local _lastColorR, _lastColorG, _lastColorB = 1, 1, 1
local _lastReactionR, _lastReactionG, _lastReactionB = nil, nil, nil
local _hasUnitColors = false
local _startupRefreshUntil = 0
local _applyGeneration = 0

local COLOR_ALLIED_GUILD = { r = 0.8, g = 0.8, b = 0.85 }
local COLOR_OTHER_GUILD = { r = 0.6, g = 0.6, b = 0.65 }

local function GetReactionColor(unit)
	local reaction = UnitReaction(unit, "player")
	if reaction then
		local c = FACTION_BAR_COLORS[reaction]
		if c then return c.r, c.g, c.b end
	end
	return 1, 1, 1
end

local function StripColorCodes(text)
	if not text then return nil end
	if issecretvalue(text) then return nil end
	text = text:gsub("|c%x%x%x%x%x%x%x%x", "")
	text = text:gsub("|r", "")
	return text
end

local function GetOwnerUnit(tooltip)
	local owner = tooltip and tooltip:GetOwner()
	if not owner then return nil end

	if owner.GetAttribute then
		local ok, unit = pcall(owner.GetAttribute, owner, "unit")
		if ok and unit and not issecretvalue(unit) and UnitExists(unit) then
			return unit
		end
	end

	local unit = owner.unit
	if unit and not issecretvalue(unit) and UnitExists(unit) then
		return unit
	end

	return nil
end

local function ForceReset()
	_lastColorR, _lastColorG, _lastColorB = 1, 1, 1
	_lastReactionR, _lastReactionG, _lastReactionB = nil, nil, nil
	_hasUnitColors = false
	_startupRefreshUntil = 0
	_applyGeneration = _applyGeneration + 1

	GameTooltipStatusBarTexture:SetVertexColor(1, 1, 1)

	local border = GameTooltip.NineSlice
	if border and border.TopEdge then
		border.TopEdge:SetVertexColor(1, 1, 1)
		border.TopLeftCorner:SetVertexColor(1, 1, 1)
		border.TopRightCorner:SetVertexColor(1, 1, 1)
		border.BottomEdge:SetVertexColor(1, 1, 1)
		border.BottomLeftCorner:SetVertexColor(1, 1, 1)
		border.BottomRightCorner:SetVertexColor(1, 1, 1)
		border.LeftEdge:SetVertexColor(1, 1, 1)
		border.RightEdge:SetVertexColor(1, 1, 1)
		border:SetBorderColor(1, 1, 1)
	end
end

local function ApplyTitleColor(r, g, b)
	if not GameTooltipTextLeft1 then return end
	local text = GameTooltipTextLeft1:GetText()
	if not text or issecretvalue(text) then return end

	text = StripColorCodes(text)
	if not text or text == "" then return end

	GameTooltipTextLeft1:SetFormattedText("|cff%02x%02x%02x%s|r", r * 255, g * 255, b * 255, text)
end

local function ApplyCachedColors()
	if not _hasUnitColors then return end

	local border = GameTooltip.NineSlice
	local r, g, b = _lastColorR, _lastColorG, _lastColorB
	local rr, rg, rb = _lastReactionR or r, _lastReactionG or g, _lastReactionB or b

	ApplyTitleColor(rr, rg, rb)

	GameTooltipStatusBarTexture:SetVertexColor(r, g, b)

	if border and border.TopEdge then
		border.TopEdge:SetVertexColor(rr, rg, rb)
		border.TopLeftCorner:SetVertexColor(rr, rg, rb)
		border.TopRightCorner:SetVertexColor(rr, rg, rb)
		border.BottomEdge:SetVertexColor(r, g, b)
		border.BottomLeftCorner:SetVertexColor(r, g, b)
		border.BottomRightCorner:SetVertexColor(r, g, b)
		border.LeftEdge:SetGradient("VERTICAL", CreateColor(r, g, b), CreateColor(rr, rg, rb))
		border.RightEdge:SetGradient("VERTICAL", CreateColor(r, g, b), CreateColor(rr, rg, rb))
	end
end

local function ScheduleRefreshes()
	local generation = _applyGeneration
	for _, delay in ipairs({ 0, 0.02, 0.05 }) do
		C_Timer.After(delay, function()
			if generation ~= _applyGeneration then return end
			if not GameTooltip:IsShown() or GameTooltip:GetAlpha() <= 0.1 then return end
			ApplyCachedColors()
		end)
	end
end

local function ResolveTooltipUnit(data)
	local unit = data and data.unitToken
	if unit and not issecretvalue(unit) and UnitExists(unit) then
		return unit
	end

	unit = GetOwnerUnit(GameTooltip)
	if unit then
		return unit
	end

	if UnitExists("mouseover") then
		return "mouseover"
	end

	return nil
end

local function ApplyColors(tooltip, data)
	local unit = ResolveTooltipUnit(data)
	if not unit then return end

	local isPlayer = UnitIsPlayer(unit)
	_hasUnitColors = true
	_startupRefreshUntil = GetTime() + 0.12
	_applyGeneration = _applyGeneration + 1
	if isPlayer then
		local _, classId = UnitClass(unit)
		if classId then _lastColorR, _lastColorG, _lastColorB = GetClassColor(classId) end
		_lastReactionR, _lastReactionG, _lastReactionB = GetReactionColor(unit)

		local class = classId and (LOCALIZED_CLASS_NAMES_MALE[classId] or LOCALIZED_CLASS_NAMES_FEMALE[classId])
		local faction = UnitFactionGroup(unit)
		local playerGuild = GetGuildInfo("player")
		local unitGuild = GetGuildInfo(unit)

		for i = 2, tooltip:NumLines() do
			local line = _G["GameTooltipTextLeft" .. i]
			local text = line and line:GetText()
			if text and not issecretvalue(text) then
				if class and text:find(class, 1, true) then
					line:SetTextColor(_lastColorR, _lastColorG, _lastColorB)
				elseif faction and text == faction then
					line:SetTextColor(_lastReactionR or _lastColorR, _lastReactionG or _lastColorG, _lastReactionB or _lastColorB)
				elseif unitGuild and text:find(unitGuild, 1, true) then
					if playerGuild and unitGuild == playerGuild then
						line:SetTextColor(COLOR_ALLIED_GUILD.r, COLOR_ALLIED_GUILD.g, COLOR_ALLIED_GUILD.b)
					else
						line:SetTextColor(COLOR_OTHER_GUILD.r, COLOR_OTHER_GUILD.g, COLOR_OTHER_GUILD.b)
					end
				end
			end
		end
	else
		_lastReactionR, _lastReactionG, _lastReactionB = nil, nil, nil
		_lastColorR, _lastColorG, _lastColorB = GetReactionColor(unit)
	end

	ApplyCachedColors()
	ScheduleRefreshes()
end

local function RefreshOwnerUnitTooltip(tooltip)
	local unit = GetOwnerUnit(tooltip)
	if not unit then return end
	ApplyColors(tooltip, nil)
end

TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Unit, function(tooltip, data)
	ApplyColors(tooltip, data)
end)

GameTooltip:HookScript("OnUpdate", function(tooltip)
	if tooltip:IsShown() and tooltip:GetAlpha() > 0.1 and (_hasUnitColors or GetTime() < _startupRefreshUntil) then
		ApplyCachedColors()
	else
		RefreshOwnerUnitTooltip(tooltip)
	end
end)

GameTooltip:HookScript("OnShow", function(tooltip)
	RefreshOwnerUnitTooltip(tooltip)
	ApplyCachedColors()
	ScheduleRefreshes()
end)

GameTooltip:HookScript("OnHide", function()
	ForceReset()
end)

GameTooltip:HookScript("OnTooltipCleared", function()
	ForceReset()
end)

-- Ensure colors are reset for non-unit tooltips as well, in case of reuse after a unit tooltip.
for _, value in pairs(Enum.TooltipDataType) do
	if value ~= Enum.TooltipDataType.Unit then
		TooltipDataProcessor.AddTooltipPostCall(value, ForceReset)
	end
end
