--[[
Created by Slothpala
--]]

local function GetTooltipColor()
    if UnitPlayerControlled("mouseover") then
        local _, englishClass = UnitClass("mouseover")
        return GetClassColor(englishClass)
    end

    local reaction = UnitReaction("player", "mouseover")
    if reaction then
        if reaction >= 5 then
            return 0.2, 0.8, 0.2
        elseif reaction == 4 then
            return 0.9, 0.9, 0
        else
            return 0.9, 0.1, 0.1
        end
    end

    return 1, 1, 1 -- fallback white
end

GameTooltip:HookScript("OnUpdate", function()
    if UnitExists("mouseover") then
        local r, g, b = GetTooltipColor()
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
