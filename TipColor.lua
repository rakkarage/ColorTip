--[[
Created by Slothpala
--]]

GameTooltip:HookScript("OnUpdate", function()
    if UnitPlayerControlled("mouseover") then
        local _, englishClass = UnitClass("mouseover")
        local r, g, b = GetClassColor(englishClass)
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
