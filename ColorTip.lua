-- ColorTip
-- Dynamic (class & reaction) tooltip border & tooltip healthbar color.
-- Players: name=class, healthbar=class, border top=reaction, sides=gradient, bottom=class
-- NPCs:    healthbar=reaction, border=uniform reaction

local function ReactionColor(unit)
    if UnitIsDead(unit) then return 0.7, 0.7, 0.7 end
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

local function ClassColor(unit)
    if not UnitIsPlayer(unit) then return nil end
    local _, class = UnitClass(unit)
    if class then
        local r, g, b = GetClassColor(class)
        if r then return r, g, b end
    end
end

local function SetBorderAsymmetric(ns, tr, tg, tb, br, bg, bb)
    ns.TopEdge:SetVertexColor(tr, tg, tb)
    ns.TopLeftCorner:SetVertexColor(tr, tg, tb)
    ns.TopRightCorner:SetVertexColor(tr, tg, tb)
    ns.BottomEdge:SetVertexColor(br, bg, bb)
    ns.BottomLeftCorner:SetVertexColor(br, bg, bb)
    ns.BottomRightCorner:SetVertexColor(br, bg, bb)
    ns.LeftEdge:SetVertexColor(1, 1, 1, 1)
    ns.RightEdge:SetVertexColor(1, 1, 1, 1)
    ns.LeftEdge:SetGradient("VERTICAL", CreateColor(br, bg, bb), CreateColor(tr, tg, tb))
    ns.RightEdge:SetGradient("VERTICAL", CreateColor(br, bg, bb), CreateColor(tr, tg, tb))
end

GameTooltip:HookScript("OnUpdate", function()
    if not UnitExists("mouseover") then return end
    local rr, rg, rb = ReactionColor("mouseover")
    local cr, cg, cb = ClassColor("mouseover")
    local ns = GameTooltip.NineSlice
    if cr then
        GameTooltipStatusBarTexture:SetVertexColor(cr, cg, cb)
        if ns then SetBorderAsymmetric(ns, rr, rg, rb, cr, cg, cb) end
    else
        GameTooltipStatusBarTexture:SetVertexColor(rr, rg, rb)
        if ns then ns:SetBorderColor(rr, rg, rb) end
    end
end)

TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Unit, function(tooltip, data)
    if tooltip ~= GameTooltip or not data then return end
    local unit = data.unitToken
    if not unit and UnitExists("mouseover") then unit = "mouseover" end
    if not unit or not UnitIsPlayer(unit) then return end
    local cr, cg, cb = ClassColor(unit)
    if cr then GameTooltipTextLeft1:SetTextColor(cr, cg, cb) end
end)

local WHITE = CreateColor(1, 1, 1)

GameTooltip:HookScript("OnHide", function()
    GameTooltipTextLeft1:SetTextColor(1, 1, 1)
    local ns = GameTooltip.NineSlice
    if ns then
        ns.TopEdge:SetVertexColor(1, 1, 1)
        ns.TopLeftCorner:SetVertexColor(1, 1, 1)
        ns.TopRightCorner:SetVertexColor(1, 1, 1)
        ns.BottomEdge:SetVertexColor(1, 1, 1)
        ns.BottomLeftCorner:SetVertexColor(1, 1, 1)
        ns.BottomRightCorner:SetVertexColor(1, 1, 1)
        ns.LeftEdge:SetGradient("VERTICAL", WHITE, WHITE)
        ns.RightEdge:SetGradient("VERTICAL", WHITE, WHITE)
    end
end)
