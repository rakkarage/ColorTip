-- ColorTip
-- Dynamic (class & reaction) tooltip border & tooltip healthbar color.

local function ReactionColor(unit)
    if UnitIsPlayer("mouseover") then
        local _, englishClass = UnitClass("mouseover")
        return GetClassColor(englishClass)
    end
    if UnitIsDead(unit) then
        return 0.7, 0.7, 0.7
    end
    local reaction = UnitReaction(unit, "player")
    if reaction then
        if reaction >= 5 then
            return 0.0118, 0.5686, 0.1098
        elseif reaction == 4 then
            return 0.7961, 0.6196, 0.0118
        else
            return 0.6627, 0.2627, 0.1922
        end
    end
    return 1.0, 1.0, 1.0
end

GameTooltip:HookScript("OnUpdate", function()
    if UnitExists("mouseover") then
        local r, g, b = ReactionColor("mouseover")
        GameTooltipStatusBarTexture:SetVertexColor(r, g, b)
        local ns = GameTooltip.NineSlice
        if ns then
            ns:SetBorderColor(r, g, b)
        end
    end
end)

TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Unit, function(tooltip, data)
    if tooltip ~= GameTooltip then return end
    local _, unit = tooltip:GetUnit()
    if not unit then return end
    if UnitIsPlayer(unit) then
        local _, englishClass = UnitClass(unit)
        local r, g, b = GetClassColor(englishClass)
        GameTooltipTextLeft1:SetTextColor(r, g, b)
    end
end)

GameTooltip:HookScript("OnHide", function()
    GameTooltipTextLeft1:SetTextColor(1, 1, 1)
    local ns = GameTooltip.NineSlice
    if ns then
        ns:SetBorderColor(1, 1, 1)
    end
end)
