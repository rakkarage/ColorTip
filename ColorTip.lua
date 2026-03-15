-- ColorTip
-- Dynamic (class & reaction) tooltip border & tooltip healthbar color.

local function ReactionColor(unit)
    if UnitIsDead(unit) then
        return 0.7, 0.7, 0.7
    end
    local reaction = UnitReaction(unit, "player")
    if reaction then
        if reaction >= 5 then
            return 0.3, 0.7, 0.3
        elseif reaction == 4 then
            return 0.7, 0.7, 0.3
        else
            return 0.7, 0.3, 0.3
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

GameTooltip:HookScript("OnHide", function()
    local ns = GameTooltip.NineSlice
    if ns then
        ns:SetBorderColor(1, 1, 1)
    end
end)
