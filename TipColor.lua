ColoredTooltips_Config = ColoredTooltips_Config or {}

local default_config = {
    ENABLE      = true,
    COLOR       = true, -- Faction / class coloring
    GUILD       = true, -- Guild coloring
    PARTY       = true, -- Party coloring
    GUILDLABEL  = true,
    PLAYERLABEL = true,
    PVPLABEL    = true,
}

-- Event-driven cache for live unit info
local liveCache = {}

-- Helper: merge defaults
local function EnsureDefaults()
    for k, v in pairs(default_config) do
        if ColoredTooltips_Config[k] == nil then
            ColoredTooltips_Config[k] = v
        end
    end
end

-- Merge defaults immediately
EnsureDefaults()

-- Modern Options Frame
local function CreateOptionsFrame()
    local f = CreateFrame("Frame", "ColoredTooltipsOptions", UIParent, "UIPanelDialogTemplate")
    f:SetSize(280, 300)
    f:SetPoint("CENTER")
    f.title = f:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    f.title:SetPoint("TOP", 0, -10)
    f.title:SetText("Colored Tooltips Options")

    f.checks = {}

    local i = 0
    for key, label in pairs({
        ENABLE = "Enable Colored Tooltips",
        COLOR = "Faction / Class Coloring",
        GUILD = "Guild Coloring",
        PARTY = "Party Coloring",
        GUILDLABEL = "Guild Label",
        PLAYERLABEL = "Player Label",
        PVPLABEL = "PvP Label",
    }) do
        i = i + 1
        local cb = CreateFrame("CheckButton", "ColoredTooltipsOptionsCheck" .. i, f, "UICheckButtonTemplate")
        cb:SetPoint("TOPLEFT", 20, -30 * i)
        cb.text:SetText(label)
        cb:SetChecked(ColoredTooltips_Config[key])
        cb:SetScript("OnClick", function(self)
            ColoredTooltips_Config[key] = self:GetChecked()
        end)
        f.checks[key] = cb
    end

    UIPanelWindows["ColoredTooltipsOptions"] = { area = "center", pushable = 0, whileDead = 1 }
    return f
end

-- Create once
local OptionsFrame = CreateOptionsFrame()

-- Slash command
SLASH_COLOREDTOOLTIPS1 = "/coloredtooltips"
SLASH_COLOREDTOOLTIPS2 = "/colortool"
SlashCmdList["COLOREDTOOLTIPS"] = function()
    OptionsFrame:Show()
end

-- Event frame for caching live unit info
local EventFrame = CreateFrame("Frame")
EventFrame:RegisterEvent("UPDATE_MOUSEOVER_UNIT")
EventFrame:SetScript("OnEvent", function(self, event)
    if event == "UPDATE_MOUSEOVER_UNIT" then
        local unit = "mouseover"
        if UnitExists(unit) then
            local guid = UnitGUID(unit)
            if guid then
                liveCache[guid] = {
                    isPlayer = UnitIsPlayer(unit),
                    guild = GetGuildInfo(unit),
                    inParty = UnitInParty(unit),
                    faction = UnitFactionGroup(unit),
                }
            end
        end
    end
end)

-- Tooltip coloring callback
local function ColoredTooltips_SetBackground(tooltip, data)
    if not tooltip or not data or not ColoredTooltips_Config.ENABLE then return end
    if data.type ~= Enum.TooltipDataType.Unit then return end

    local r, g, b

    -- Use snapshot info (Retail-safe)
    if data.isPlayer and data.class then
        local color = C_ClassColor.GetClassColor(data.class)
        if color then r, g, b = color.r, color.g, color.b end
    else
        local reaction = data.reaction
        if reaction then
            if reaction >= 5 then
                r, g, b = 0.2, 0.8, 0.2          -- friendly NPC
            elseif reaction == 4 then
                r, g, b = 0.9, 0.9, 0            -- neutral NPC
            else
                r, g, b = 0.9, 0.1, 0.1          -- hostile NPC
            end
        else
            r, g, b = 1, 1, 1
        end
    end

    -- Attempt live cache overrides (guild, party)
    if data.guid and liveCache[data.guid] then
        local cache = liveCache[data.guid]
        -- Guild coloring
        if ColoredTooltips_Config.GUILD and cache.guild then
            r, g, b = 0.4, 1.0, 1.0
        end
        -- Party coloring
        if ColoredTooltips_Config.PARTY and cache.inParty then
            r, g, b = 0.8, 0.4, 1.0
        end
    end

    -- Apply color
    if tooltip.NineSlice and r then
        tooltip.NineSlice:SetCenterColor(r, g, b)
    end

    -- Labels
    if ColoredTooltips_Config.GUILDLABEL and data.guid and liveCache[data.guid] then
        local guild = liveCache[data.guid].guild
        if guild and tooltip.TextLeft2 and tooltip.TextLeft2:IsVisible() then
            tooltip.TextLeft2:SetTextColor(1, 0.84, 0)
            tooltip.TextLeft2:SetText("<" .. guild .. ">")
        end
    end

    if ColoredTooltips_Config.PLAYERLABEL then
        for i = 2, 3 do
            local line = tooltip["TextLeft" .. i]
            if line then
                local text = line:GetText()
                if text then
                    line:SetText(string.gsub(text, " [(]Player[)]", ""))
                end
            end
        end
    end

    if ColoredTooltips_Config.PVPLABEL then
        local faction = data.faction or (data.guid and liveCache[data.guid] and liveCache[data.guid].faction)
        if faction then
            for i = 3, 6 do
                local left = tooltip["TextLeft" .. i]
                local right = tooltip["TextRight" .. i]
                if left and left:GetText() then
                    local newText = string.gsub(left:GetText(), "PvP", "")
                    newText = string.gsub(newText, faction, "")
                    if newText == "" then
                        left:SetText(""); left:Hide()
                        if right then
                            right:SetText(""); right:Hide()
                        end
                    else
                        left:SetText(newText)
                    end
                end
            end
        end
    end
end

-- Hook safe callback
TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Unit, ColoredTooltips_SetBackground)
