-- Live cache (mouseover only)
local cache = {}

local f = CreateFrame("Frame")
f:RegisterEvent("UPDATE_MOUSEOVER_UNIT")
f:SetScript("OnEvent", function()
    local u = "mouseover"
    if not UnitExists(u) then return end
    local g = UnitGUID(u)
    if not g then return end
    cache[g] = {
        guild   = GetGuildInfo(u),
        inParty = UnitInParty(u),
        faction = UnitFactionGroup(u),
    }
end)

local function ColorTooltip(tt, data)
    if not data or data.type ~= Enum.TooltipDataType.Unit then return end

    local r, g, b

    -- Class color (players)
    if data.isPlayer and data.class then
        local c = C_ClassColor.GetClassColor(data.class)
        if c then r, g, b = c.r, c.g, c.b end
    end

    -- Reaction fallback (NPCs)
    if not r then
        local reaction = data.reaction or 4
        if reaction >= 5 then
            r, g, b = 0.2, 0.8, 0.2
        elseif reaction == 4 then
            r, g, b = 0.9, 0.9, 0
        else
            r, g, b = 0.9, 0.1, 0.1
        end
    end

    local c = data.guid and cache[data.guid]

    -- Guild override
    if c and c.guild then
        r, g, b = 0.4, 1, 1
    end

    -- Party override
    if c and c.inParty then
        r, g, b = 0.8, 0.4, 1
    end

    -- Apply background
    if tt.NineSlice then
        tt.NineSlice:SetCenterColor(r, g, b)
    end

    -- Apply status bar color (HP bar)
    if tt.StatusBar and tt.StatusBar:GetStatusBarTexture() then
        tt.StatusBar:GetStatusBarTexture():SetVertexColor(r, g, b)
    end

    -- Guild label
    if c and c.guild and tt.TextLeft2 then
        tt.TextLeft2:SetTextColor(1, 0.84, 0)
        tt.TextLeft2:SetText("<" .. c.guild .. ">")
    end

    -- Strip "(Player)"
    for i = 2, 3 do
        local l = tt["TextLeft" .. i]
        if l and l:GetText() then
            l:SetText(l:GetText():gsub(" [(]Player[)]", ""))
        end
    end

    -- Strip PvP + faction
    local faction = data.faction or (c and c.faction)
    for i = 3, 6 do
        local l = tt["TextLeft" .. i]
        local rLine = tt["TextRight" .. i]
        if l and l:GetText() then
            local t = l:GetText():gsub("PvP", "")
            if faction then t = t:gsub(faction, "") end
            if t == "" then
                l:SetText(""); l:Hide()
                if rLine then
                    rLine:SetText(""); rLine:Hide()
                end
            else
                l:SetText(t)
            end
        end
    end
end

TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Unit, ColorTooltip)
