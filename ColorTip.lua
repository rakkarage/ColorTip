-- 🎨 ColorTip: Dynamic (class & reaction) tooltip name, border, and status bar.

local _lastColorR, _lastColorG, _lastColorB = 1, 1, 1
local _lastReactionR, _lastReactionG, _lastReactionB = nil, nil, nil
local _hasUnitColors = false
local _startupRefreshUntil = 0
local _applyGeneration = 0
local _debugEnabled = false
local _debugUpdateGeneration = -1

local COLOR_ALLIED_GUILD = { r = 0.8, g = 0.8, b = 0.85 }
local COLOR_OTHER_GUILD = { r = 0.6, g = 0.6, b = 0.65 }
local COLOR_BAR_BG = { r = 0.05, g = 0.05, b = 0.05, a = 0.9 }

local CustomStatusBar = CreateFrame("StatusBar", nil, GameTooltip)
CustomStatusBar:SetAllPoints(GameTooltipStatusBar)
CustomStatusBar:SetFrameLevel(GameTooltipStatusBar:GetFrameLevel() + 1)
CustomStatusBar:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
CustomStatusBar:Hide()

local CustomStatusBarBG = CustomStatusBar:CreateTexture(nil, "BACKGROUND")
CustomStatusBarBG:SetAllPoints()
CustomStatusBarBG:SetColorTexture(COLOR_BAR_BG.r, COLOR_BAR_BG.g, COLOR_BAR_BG.b, COLOR_BAR_BG.a)

local function GetReactionColor(unit)
	local reaction = UnitReaction(unit, "player")
	if reaction then
		local c = FACTION_BAR_COLORS[reaction]
		if c then return c.r, c.g, c.b end
	end
	return 1, 1, 1
end

local function DebugLog(event, ...)
	if not _debugEnabled then return end

	local parts = { "|cff33ff99ColorTip|r", string.format("[%.3f]", GetTime()), event }
	for i = 1, select("#", ...) do
		local value = select(i, ...)
		if issecretvalue(value) then
			parts[#parts + 1] = "<secret>"
		else
			parts[#parts + 1] = tostring(value)
		end
	end
	print(table.concat(parts, " "))
end

local function StripColorCodes(text)
	if not text then return nil end
	if issecretvalue(text) then return nil end
	text = text:gsub("|c%x%x%x%x%x%x%x%x", "")
	text = text:gsub("|r", "")
	return text
end

local function GetTooltipLineText(line)
	if not line then return nil, false end

	local text = line:GetText()
	if not text then return nil, false end
	if issecretvalue(text) then return nil, true end

	return StripColorCodes(text), false
end

local function GetTooltipLineDebugText(line)
	local text, isSecret = GetTooltipLineText(line)
	if isSecret then
		return "<secret>"
	end
	return tostring(text)
end

local function GetOwnerName(tooltip)
	local owner = tooltip and tooltip:GetOwner()
	if not owner then return "nil" end
	return owner.GetName and owner:GetName() or tostring(owner)
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

local function ApplyTitleColor(r, g, b)
	if not GameTooltipTextLeft1 then return end
	local text = GameTooltipTextLeft1:GetText()
	if not text or issecretvalue(text) then return end

	text = StripColorCodes(text)
	if not text or text == "" then return end

	GameTooltipTextLeft1:SetFormattedText("|cff%02x%02x%02x%s|r", r * 255, g * 255, b * 255, text)
	DebugLog("title", string.format("rgb=%.2f,%.2f,%.2f", r, g, b), "text=" .. text)
end

local function SyncCustomStatusBar()
	if not _hasUnitColors or not GameTooltipStatusBar or not GameTooltipStatusBar:IsShown() then
		CustomStatusBar:Hide()
		return
	end

	local minValue, maxValue = GameTooltipStatusBar:GetMinMaxValues()
	local value = GameTooltipStatusBar:GetValue()
	CustomStatusBar:SetMinMaxValues(minValue, maxValue)
	CustomStatusBar:SetValue(value)
	CustomStatusBar:SetStatusBarColor(_lastColorR, _lastColorG, _lastColorB)
	CustomStatusBar:Show()
	local barText
	if issecretvalue(minValue) or issecretvalue(maxValue) or issecretvalue(value) then
		barText = "min/max/value=<secret>"
	else
		barText = string.format("min=%.0f max=%.0f value=%.0f", minValue or 0, maxValue or 0, value or 0)
	end

	DebugLog("bar", barText, string.format("rgb=%.2f,%.2f,%.2f", _lastColorR, _lastColorG, _lastColorB))
end

local function ResetState()
	_lastColorR, _lastColorG, _lastColorB = 1, 1, 1
	_lastReactionR, _lastReactionG, _lastReactionB = nil, nil, nil
	_hasUnitColors = false
	_startupRefreshUntil = 0
	_applyGeneration = _applyGeneration + 1
	_debugUpdateGeneration = -1
	CustomStatusBar:Hide()
end

local function ApplyCachedColors(tooltip)
	if not _hasUnitColors then return end

	local border = tooltip.NineSlice
	local r, g, b = _lastColorR, _lastColorG, _lastColorB
	local rr, rg, rb = _lastReactionR or r, _lastReactionG or g, _lastReactionB or b

	ApplyTitleColor(rr, rg, rb)

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

	SyncCustomStatusBar()
end

local function ScheduleRefreshes(tooltip)
	local generation = _applyGeneration
	for _, delay in ipairs({ 0, 0.02, 0.05 }) do
		C_Timer.After(delay, function()
			if generation ~= _applyGeneration then return end
			if tooltip ~= GameTooltip or not tooltip:IsShown() or tooltip:GetAlpha() <= 0.1 then return end
			ApplyCachedColors(tooltip)
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
	DebugLog(
		"apply",
		"owner=" .. GetOwnerName(tooltip),
		"unit=" .. tostring(unit),
		"token=" .. tostring(data and data.unitToken),
		"isPlayer=" .. tostring(isPlayer),
		"line1=" .. GetTooltipLineDebugText(GameTooltipTextLeft1)
	)

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

	ApplyCachedColors(tooltip)
	ScheduleRefreshes(tooltip)
end

local function RefreshOwnerUnitTooltip(tooltip)
	local unit = GetOwnerUnit(tooltip)
	if not unit then return end

	DebugLog("ownerrefresh", "owner=" .. GetOwnerName(tooltip), "ownerUnit=" .. tostring(unit))
	ApplyColors(tooltip, nil)
end

TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Unit, function(tooltip, data)
	ApplyColors(tooltip, data)
end)

GameTooltip:HookScript("OnUpdate", function(tooltip)
	if tooltip:IsShown() and tooltip:GetAlpha() > 0.1 and (_hasUnitColors or GetTime() < _startupRefreshUntil) then
		if _debugEnabled and _debugUpdateGeneration ~= _applyGeneration then
			_debugUpdateGeneration = _applyGeneration
			DebugLog("update", "owner=" .. GetOwnerName(tooltip), "alpha=" .. string.format("%.2f", tooltip:GetAlpha()))
		end
		ApplyCachedColors(tooltip)
	else
		RefreshOwnerUnitTooltip(tooltip)
	end
end)

GameTooltip:HookScript("OnShow", function(tooltip)
	DebugLog("show", "owner=" .. GetOwnerName(tooltip), "line1=" .. GetTooltipLineDebugText(GameTooltipTextLeft1))
	RefreshOwnerUnitTooltip(tooltip)
	ApplyCachedColors(tooltip)
	ScheduleRefreshes(tooltip)
end)

GameTooltip:HookScript("OnHide", function(tooltip)
	DebugLog("hide", "owner=" .. GetOwnerName(tooltip))
	ResetState()
end)

GameTooltip:HookScript("OnTooltipCleared", function(tooltip)
	if tooltip == GameTooltip then
		DebugLog("cleared", "owner=" .. GetOwnerName(tooltip))
		ResetState()
	end
end)

if GameTooltipStatusBar then
	GameTooltipStatusBar:HookScript("OnShow", function()
		DebugLog("barshow")
		SyncCustomStatusBar()
	end)

	GameTooltipStatusBar:HookScript("OnHide", function()
		DebugLog("barhide")
		CustomStatusBar:Hide()
	end)

	GameTooltipStatusBar:HookScript("OnMinMaxChanged", function()
		SyncCustomStatusBar()
	end)

	GameTooltipStatusBar:HookScript("OnValueChanged", function()
		if _hasUnitColors then
			SyncCustomStatusBar()
		end
	end)
end

SLASH_COLORTIPDEBUG1 = "/colortipdebug"
SLASH_COLORTIPDEBUG2 = "/ctdebug"
SlashCmdList["COLORTIPDEBUG"] = function()
	_debugEnabled = not _debugEnabled
	DebugLog("debug", "enabled")
	if not _debugEnabled then
		print("|cff33ff99ColorTip|r debug disabled")
	end
end
