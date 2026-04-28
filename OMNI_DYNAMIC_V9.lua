--[[
╔══════════════════════════════════════════════════════════════════╗
║         OMNI-DYNAMIC V9 — PHANTOM CIRCUIT EDITION               ║
║         Architecture: Ghost-Grid UI System                       ║
║         Target: Cloud Phone / Mobile Executors                   ║
║         Style: Cyber-Ink — Monochrome Neon on void black        ║
║         Author: Senior TA — Phantom Circuit Division             ║
╚══════════════════════════════════════════════════════════════════╝
]]

-- ══════════════════════════════════════════════════════════════════
--  SECTION 0 — CORE SERVICES & SAFETY BOOTSTRAP
-- ══════════════════════════════════════════════════════════════════

local RunService    = game:GetService("RunService")
local TweenService  = game:GetService("TweenService")
local UserInput     = game:GetService("UserInputService")
local Players       = game:GetService("Players")
local Stats         = game:GetService("Stats")
local HttpService   = game:GetService("HttpService")

local LP            = Players.LocalPlayer
local Char          = LP.Character or LP.CharacterAdded:Wait()
local Cam           = workspace.CurrentCamera
local GUI_PARENT    = LP:WaitForChild("PlayerGui")

-- Destroy any previous instance of this script's UI
local OLD = GUI_PARENT:FindFirstChild("OMNI_V9")
if OLD then OLD:Destroy() end

-- ══════════════════════════════════════════════════════════════════
--  SECTION 1 — THEME ENGINE (CYBER-INK PALETTE)
-- ══════════════════════════════════════════════════════════════════

local THEME = {
    VOID        = Color3.fromRGB(4,   4,   8),
    DEEP        = Color3.fromRGB(10,  10,  18),
    PANEL       = Color3.fromRGB(14,  14,  24),
    BORDER      = Color3.fromRGB(30,  30,  55),

    -- Primary accent — Electric Cyan
    CYAN        = Color3.fromRGB(0,   220, 255),
    CYAN_DIM    = Color3.fromRGB(0,   80,  110),

    -- Secondary accent — Ghost Violet
    VIOLET      = Color3.fromRGB(160, 0,   255),
    VIOLET_DIM  = Color3.fromRGB(55,  0,   90),

    -- Alert accent — Crimson Flare
    RED         = Color3.fromRGB(255, 30,  60),
    RED_DIM     = Color3.fromRGB(90,  10,  20),

    -- Neutral
    WHITE       = Color3.fromRGB(230, 235, 255),
    GREY        = Color3.fromRGB(90,  90,  120),
    TEXT_DIM    = Color3.fromRGB(120, 125, 160),

    -- Skill slot colors
    SKILL_1     = Color3.fromRGB(0,   210, 255),
    SKILL_2     = Color3.fromRGB(255, 60,  120),
    SKILL_3     = Color3.fromRGB(255, 200, 0),
    SKILL_4     = Color3.fromRGB(100, 255, 150),
    SKILL_5     = Color3.fromRGB(200, 80,  255),
    SKILL_6     = Color3.fromRGB(255, 130, 0),
}

local FONT_MAIN  = Enum.Font.GothamBold
local FONT_MONO  = Enum.Font.Code
local FONT_TITLE = Enum.Font.GothamBlack

-- ══════════════════════════════════════════════════════════════════
--  SECTION 2 — GHOST-GRID UI FACTORY
-- ══════════════════════════════════════════════════════════════════

local Factory = {}

function Factory.Screen(name)
    local sg = Instance.new("ScreenGui")
    sg.Name            = name
    sg.ResetOnSpawn    = false
    sg.ZIndexBehavior  = Enum.ZIndexBehavior.Sibling
    sg.DisplayOrder    = 99
    sg.Parent          = GUI_PARENT
    return sg
end

function Factory.Frame(parent, props)
    local f = Instance.new("Frame")
    f.BackgroundColor3  = props.bg        or THEME.PANEL
    f.BackgroundTransparency = props.bgT  or 0
    f.BorderSizePixel   = 0
    f.Size              = props.size      or UDim2.new(0,100,0,100)
    f.Position          = props.pos       or UDim2.new(0,0,0,0)
    f.ZIndex            = props.z         or 1
    f.ClipsDescendants  = props.clip      or false
    f.Parent            = parent
    if props.corner then
        local c = Instance.new("UICorner")
        c.CornerRadius = UDim.new(0, props.corner)
        c.Parent = f
    end
    return f
end

function Factory.Border(parent, color, thickness)
    local s = Instance.new("UIStroke")
    s.Color     = color     or THEME.CYAN
    s.Thickness = thickness or 1
    s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    s.Parent = parent
    return s
end

function Factory.Label(parent, props)
    local l = Instance.new("TextLabel")
    l.BackgroundTransparency = 1
    l.Size          = props.size   or UDim2.new(1,0,1,0)
    l.Position      = props.pos    or UDim2.new(0,0,0,0)
    l.Font          = props.font   or FONT_MAIN
    l.Text          = props.text   or ""
    l.TextColor3    = props.color  or THEME.WHITE
    l.TextSize      = props.ts     or 14
    l.TextXAlignment = props.alignX or Enum.TextXAlignment.Center
    l.TextYAlignment = props.alignY or Enum.TextYAlignment.Center
    l.TextWrapped   = props.wrap   or false
    l.ZIndex        = props.z      or 2
    l.RichText      = props.rich   or false
    l.Parent        = parent
    return l
end

function Factory.Button(parent, props)
    local b = Instance.new("TextButton")
    b.BackgroundColor3 = props.bg    or THEME.DEEP
    b.BackgroundTransparency = props.bgT or 0
    b.BorderSizePixel  = 0
    b.Size             = props.size  or UDim2.new(0,100,0,44)
    b.Position         = props.pos   or UDim2.new(0,0,0,0)
    b.Font             = props.font  or FONT_MAIN
    b.Text             = props.text  or "BTN"
    b.TextColor3       = props.color or THEME.WHITE
    b.TextSize         = props.ts    or 14
    b.AutoButtonColor  = false
    b.ZIndex           = props.z     or 2
    b.Parent           = parent
    if props.corner then
        local c = Instance.new("UICorner")
        c.CornerRadius = UDim.new(0, props.corner)
        c.Parent = b
    end
    return b
end

function Factory.Image(parent, props)
    local i = Instance.new("ImageLabel")
    i.BackgroundTransparency = 1
    i.Size     = props.size  or UDim2.new(1,0,1,0)
    i.Position = props.pos   or UDim2.new(0,0,0,0)
    i.Image    = props.img   or ""
    i.ImageColor3 = props.color or Color3.new(1,1,1)
    i.ImageTransparency = props.imgT or 0
    i.ZIndex   = props.z     or 2
    i.Parent   = parent
    return i
end

function Factory.Gradient(parent, colors, rotation)
    local g = Instance.new("UIGradient")
    local seq = {}
    for i, c in ipairs(colors) do
        seq[i] = ColorSequenceKeypoint.new((i-1)/(#colors-1), c)
    end
    g.Color    = ColorSequence.new(seq)
    g.Rotation = rotation or 90
    g.Parent   = parent
    return g
end

-- Tween shorthand — Power4 easeOut (Elastic-Snappy feel)
local function Tween(inst, props, t, style, dir)
    local info = TweenInfo.new(
        t   or 0.35,
        style or TweenInfo.new(0.35, Enum.EasingStyle.Quart, Enum.EasingDirection.Out).EasingStyle,
        dir   or Enum.EasingDirection.Out
    )
    TweenService:Create(inst, info, props):Play()
end

local function TweenSnap(inst, props, t)
    local info = TweenInfo.new(t or 0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
    TweenService:Create(inst, info, props):Play()
end

local function TweenElastic(inst, props, t)
    local info = TweenInfo.new(t or 0.5, Enum.EasingStyle.Elastic, Enum.EasingDirection.Out)
    TweenService:Create(inst, info, props):Play()
end

-- ══════════════════════════════════════════════════════════════════
--  SECTION 3 — ROOT SCREEN GUI
-- ══════════════════════════════════════════════════════════════════

local Screen = Factory.Screen("OMNI_V9")

-- Subtle scanline overlay (pure CSS-analog via gradient image trick)
local Scanlines = Factory.Frame(Screen, {
    bg   = Color3.fromRGB(0,0,0),
    bgT  = 0.93,
    size = UDim2.new(1,0,1,0),
    pos  = UDim2.new(0,0,0,0),
    z    = 0,
})
Scanlines.ZIndex = 0

-- ══════════════════════════════════════════════════════════════════
--  SECTION 4 — TOP STATUS BAR (Ghost-HUD Strip)
-- ══════════════════════════════════════════════════════════════════

local TopBar = Factory.Frame(Screen, {
    bg     = THEME.VOID,
    bgT    = 0.15,
    size   = UDim2.new(1, 0, 0, 38),
    pos    = UDim2.new(0, 0, 0, 0),
    corner = 0,
    z      = 5,
})
Factory.Border(TopBar, THEME.CYAN_DIM, 1)
Factory.Gradient(TopBar, {THEME.VOID, THEME.DEEP, THEME.VOID}, 0)

-- Logo / Title
local TitleLabel = Factory.Label(TopBar, {
    text   = "◈  PHANTOM CIRCUIT  ◈",
    font   = FONT_TITLE,
    color  = THEME.CYAN,
    ts     = 13,
    size   = UDim2.new(0.5, 0, 1, 0),
    pos    = UDim2.new(0.25, 0, 0, 0),
    z      = 6,
})

-- FPS Counter
local FPS_Label = Factory.Label(TopBar, {
    text   = "FPS: --",
    font   = FONT_MONO,
    color  = THEME.SKILL_4,
    ts     = 11,
    size   = UDim2.new(0, 70, 1, 0),
    pos    = UDim2.new(0, 6, 0, 0),
    alignX = Enum.TextXAlignment.Left,
    z      = 6,
})

-- Ping Counter
local Ping_Label = Factory.Label(TopBar, {
    text   = "PING: --",
    font   = FONT_MONO,
    color  = THEME.SKILL_3,
    ts     = 11,
    size   = UDim2.new(0, 80, 1, 0),
    pos    = UDim2.new(0, 76, 0, 0),
    alignX = Enum.TextXAlignment.Left,
    z      = 6,
})

-- Time label
local Time_Label = Factory.Label(TopBar, {
    text   = "00:00",
    font   = FONT_MONO,
    color  = THEME.TEXT_DIM,
    ts     = 11,
    size   = UDim2.new(0, 60, 1, 0),
    pos    = UDim2.new(1, -66, 0, 0),
    alignX = Enum.TextXAlignment.Right,
    z      = 6,
})

-- FPS tracking
local fpsBuffer, fpsIndex, fpsAccum = {}, 1, 0
for i=1,60 do fpsBuffer[i] = 60 end

local lastFrame = tick()
RunService.RenderStepped:Connect(function()
    local now  = tick()
    local dt   = now - lastFrame
    lastFrame  = now
    local fps  = math.clamp(math.floor(1/dt), 1, 999)
    fpsAccum   = fpsAccum - fpsBuffer[fpsIndex] + fps
    fpsBuffer[fpsIndex] = fps
    fpsIndex   = (fpsIndex % 60) + 1
    local avgFPS = math.floor(fpsAccum / 60)

    local col
    if avgFPS >= 55 then col = THEME.SKILL_4
    elseif avgFPS >= 35 then col = THEME.SKILL_3
    else col = THEME.RED end

    FPS_Label.TextColor3 = col
    FPS_Label.Text = string.format("FPS: %d", avgFPS)

    local h = math.floor(tick() / 3600) % 24
    local m = math.floor(tick() / 60) % 60
    Time_Label.Text = string.format("%02d:%02d", h, m)
end)

-- Ping tracking
local function UpdatePing()
    while true do
        local ok, ping = pcall(function()
            return math.floor(Stats.Network.ServerStatsItem["Data Ping"]:GetValue())
        end)
        if ok then
            local col = ping < 80 and THEME.SKILL_4 or ping < 150 and THEME.SKILL_3 or THEME.RED
            Ping_Label.TextColor3 = col
            Ping_Label.Text = string.format("PING: %dms", ping)
        end
        task.wait(1)
    end
end
task.spawn(UpdatePing)

-- ══════════════════════════════════════════════════════════════════
--  SECTION 5 — NEURAL SEED DATA ENGINE
-- ══════════════════════════════════════════════════════════════════

-- Compressed skill data — Ghost-Grid Combat System
local SKILL_DB = {
    {id=1, name="PHANTOM SLASH",   key="Q", type="MELEE",   dmg="1×2400",  cd=0,    color=THEME.SKILL_1, icon="⚔"},
    {id=2, name="VOID CASCADE",    key="E", type="BURST",   dmg="3×800",   cd=4,    color=THEME.SKILL_2, icon="◈"},
    {id=3, name="CIRCUIT BREAK",   key="R", type="CONTROL", dmg="STUN 2s", cd=8,    color=THEME.SKILL_3, icon="⚡"},
    {id=4, name="GHOST ASCENT",    key="F", type="MOBILITY",dmg="DASH",    cd=6,    color=THEME.SKILL_4, icon="△"},
    {id=5, name="NULL FIELD",      key="T", type="AOE",     dmg="5×600",   cd=12,   color=THEME.SKILL_5, icon="◉"},
    {id=6, name="INK OVERDRIVE",   key="G", type="ULT",     dmg="DOMAIN",  cd=20,   color=THEME.SKILL_6, icon="✦"},
}

local COMBAT_MODES = {
    {id=1, name="PASSIVE",    desc="Minimal energy — auto parry active",         color=THEME.SKILL_4},
    {id=2, name="ASSAULT",    desc="Full offensive — cooldowns -20%",            color=THEME.SKILL_1},
    {id=3, name="GHOST",      desc="Stealth mode — reduced hitbox & signature",  color=THEME.VIOLET},
    {id=4, name="OVERDRIVE",  desc="All skills unlocked — stamina drain ×2",     color=THEME.RED},
}

local ORACLE_LINES = {
    "[ CIRCUIT ] Threat vector detected at 3 o'clock — adjust bearing.",
    "[ ORACLE ] Cooldown window optimal — initiate cascade sequence now.",
    "[ PHANTOM ] Your latency is within acceptable bounds. Push forward.",
    "[ VOID ] Pattern recognition: enemy telegraphed. Counter in 0.3s.",
    "[ INK ] Stamina reserves critical — activate Ghost protocol.",
    "[ NEURAL ] Combo chain broken — recalibrate and re-engage.",
    "[ DATA ] Signature trace eliminated. Ghost field holding steady.",
    "[ CORE ] Ink Overdrive threshold reached. Domain expansion ready.",
    "[ WARN ] Multiple hostiles entering void radius. Reassess position.",
    "[ SYNC ] Neural link stable. Reaction coefficient: 94.7%",
}

-- ══════════════════════════════════════════════════════════════════
--  SECTION 6 — MAIN PANEL (Ghost-Grid Layout)
-- ══════════════════════════════════════════════════════════════════

-- Container — bottom-anchored, mobile-first
local MainPanel = Factory.Frame(Screen, {
    bg     = THEME.VOID,
    bgT    = 0.08,
    size   = UDim2.new(1, 0, 0, 310),
    pos    = UDim2.new(0, 0, 1, -310),
    corner = 0,
    clip   = true,
    z      = 4,
})
Factory.Border(MainPanel, THEME.BORDER, 1)
Factory.Gradient(MainPanel, {THEME.PANEL, THEME.VOID}, 90)

-- Top edge glow line
local TopGlow = Factory.Frame(MainPanel, {
    bg   = THEME.CYAN,
    bgT  = 0,
    size = UDim2.new(1, 0, 0, 2),
    pos  = UDim2.new(0, 0, 0, 0),
    z    = 5,
})
Tween(TopGlow, {BackgroundTransparency = 0.2}, 1.2)

-- ══════════════════════════════════════════════════════════════════
--  SECTION 7 — COMBAT MODE SELECTOR
-- ══════════════════════════════════════════════════════════════════

local ModeSection = Factory.Frame(MainPanel, {
    bg     = Color3.fromRGB(0,0,0),
    bgT    = 1,
    size   = UDim2.new(1, 0, 0, 70),
    pos    = UDim2.new(0, 0, 0, 0),
    z      = 5,
})

local ModeTitle = Factory.Label(ModeSection, {
    text   = "◆ COMBAT PROTOCOL",
    font   = FONT_TITLE,
    color  = THEME.GREY,
    ts     = 10,
    size   = UDim2.new(1, -12, 0, 18),
    pos    = UDim2.new(0, 8, 0, 4),
    alignX = Enum.TextXAlignment.Left,
    z      = 6,
})

local activeModeIndex = 1

local ModeButtons = {}
local MODE_BTN_W = 78
local MODE_BTN_GAP = 4
local MODE_TOTAL = #COMBAT_MODES * (MODE_BTN_W + MODE_BTN_GAP) - MODE_BTN_GAP
local MODE_START_X = (workspace.CurrentCamera.ViewportSize.X - MODE_TOTAL) / 2

for i, mode in ipairs(COMBAT_MODES) do
    local xPos = (i-1) * (MODE_BTN_W + MODE_BTN_GAP)
    local btn = Factory.Button(ModeSection, {
        bg     = THEME.DEEP,
        bgT    = 0.2,
        size   = UDim2.new(0, MODE_BTN_W, 0, 40),
        pos    = UDim2.new(0, 8 + xPos, 0, 24),
        font   = FONT_TITLE,
        text   = mode.name,
        color  = THEME.GREY,
        ts     = 10,
        corner = 5,
        z      = 6,
    })
    local border = Factory.Border(btn, THEME.BORDER, 1)

    ModeButtons[i] = {btn=btn, border=border, mode=mode}

    btn.MouseButton1Click:Connect(function()
        -- Deactivate all
        for j, mb in ipairs(ModeButtons) do
            Tween(mb.btn, {BackgroundColor3 = THEME.DEEP, BackgroundTransparency = 0.2}, 0.25)
            Tween(mb.btn, {TextColor3 = THEME.GREY}, 0.25)
            mb.border.Color = THEME.BORDER
        end
        -- Activate selected
        activeModeIndex = i
        TweenSnap(btn, {BackgroundColor3 = mode.color, BackgroundTransparency = 0.75}, 0.3)
        Tween(btn, {TextColor3 = mode.color}, 0.25)
        border.Color = mode.color
        -- Flash top glow
        Tween(TopGlow, {BackgroundColor3 = mode.color, BackgroundTransparency = 0}, 0.1)
        task.wait(0.2)
        Tween(TopGlow, {BackgroundColor3 = THEME.CYAN, BackgroundTransparency = 0.2}, 0.5)
    end)
end

-- Highlight default mode 1
do
    local mb = ModeButtons[1]
    mb.btn.BackgroundColor3 = COMBAT_MODES[1].color
    mb.btn.BackgroundTransparency = 0.75
    mb.btn.TextColor3 = COMBAT_MODES[1].color
    mb.border.Color = COMBAT_MODES[1].color
end

-- ══════════════════════════════════════════════════════════════════
--  SECTION 8 — SKILL GRID (6-Slot Ghost-Grid)
-- ══════════════════════════════════════════════════════════════════

local SkillSection = Factory.Frame(MainPanel, {
    bg     = Color3.fromRGB(0,0,0),
    bgT    = 1,
    size   = UDim2.new(1, 0, 0, 150),
    pos    = UDim2.new(0, 0, 0, 74),
    z      = 5,
})

local SkillTitle = Factory.Label(SkillSection, {
    text   = "◆ SKILL MATRIX",
    font   = FONT_TITLE,
    color  = THEME.GREY,
    ts     = 10,
    size   = UDim2.new(1, -12, 0, 18),
    pos    = UDim2.new(0, 8, 0, 0),
    alignX = Enum.TextXAlignment.Left,
    z      = 6,
})

local SLOT_W, SLOT_H = 98, 58
local SLOT_GAP = 4
local SLOTS_PER_ROW = 3
local cooldownTimers = {}

local function MakeSkillSlot(skillData, row, col)
    local xPos = 8 + (col-1) * (SLOT_W + SLOT_GAP)
    local yPos = 20 + (row-1) * (SLOT_H + SLOT_GAP)

    local slot = Factory.Frame(SkillSection, {
        bg     = THEME.VOID,
        bgT    = 0.1,
        size   = UDim2.new(0, SLOT_W, 0, SLOT_H),
        pos    = UDim2.new(0, xPos, 0, yPos),
        corner = 6,
        z      = 6,
    })
    local slotBorder = Factory.Border(slot, skillData.color, 1)
    Factory.Gradient(slot, {THEME.VOID, skillData.color}, 135)
    slot:FindFirstChildOfClass("UIGradient").Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0.85),
        NumberSequenceKeypoint.new(1, 1),
    })

    -- Icon
    local iconLbl = Factory.Label(slot, {
        text   = skillData.icon,
        font   = FONT_TITLE,
        color  = skillData.color,
        ts     = 22,
        size   = UDim2.new(0, 34, 1, 0),
        pos    = UDim2.new(0, 4, 0, 0),
        z      = 7,
    })

    -- Skill name
    local nameLbl = Factory.Label(slot, {
        text   = skillData.name,
        font   = FONT_TITLE,
        color  = THEME.WHITE,
        ts     = 9,
        size   = UDim2.new(1, -42, 0, 16),
        pos    = UDim2.new(0, 38, 0, 5),
        alignX = Enum.TextXAlignment.Left,
        z      = 7,
    })

    -- Key bind
    local keyLbl = Factory.Label(slot, {
        text   = "["..skillData.key.."]",
        font   = FONT_MONO,
        color  = skillData.color,
        ts     = 10,
        size   = UDim2.new(1, -42, 0, 12),
        pos    = UDim2.new(0, 38, 0, 22),
        alignX = Enum.TextXAlignment.Left,
        z      = 7,
    })

    -- Stat / dmg
    local dmgLbl = Factory.Label(slot, {
        text   = skillData.dmg,
        font   = FONT_MONO,
        color  = THEME.TEXT_DIM,
        ts     = 9,
        size   = UDim2.new(1, -42, 0, 12),
        pos    = UDim2.new(0, 38, 0, 36),
        alignX = Enum.TextXAlignment.Left,
        z      = 7,
    })

    -- Cooldown bar
    local cdBg = Factory.Frame(slot, {
        bg     = THEME.BORDER,
        bgT    = 0,
        size   = UDim2.new(1, -8, 0, 3),
        pos    = UDim2.new(0, 4, 1, -7),
        corner = 2,
        z      = 7,
    })
    local cdFill = Factory.Frame(cdBg, {
        bg     = skillData.color,
        bgT    = 0,
        size   = UDim2.new(1, 0, 1, 0),
        pos    = UDim2.new(0, 0, 0, 0),
        corner = 2,
        z      = 8,
    })

    -- Touchable button layer
    local hitArea = Factory.Button(slot, {
        bg    = Color3.new(0,0,0),
        bgT   = 1,
        size  = UDim2.new(1,0,1,0),
        pos   = UDim2.new(0,0,0,0),
        text  = "",
        z     = 9,
    })

    local isOnCooldown = false

    local function FireSkill()
        if isOnCooldown then return end
        isOnCooldown = true

        -- Impact flash
        TweenSnap(slot, {BackgroundTransparency = 0}, 0.05)
        TweenSnap(iconLbl, {TextTransparency = 0.3}, 0.05)
        task.wait(0.08)
        TweenSnap(slot, {BackgroundTransparency = 0.1}, 0.25)
        TweenSnap(iconLbl, {TextTransparency = 0}, 0.25)

        -- Scale pop
        TweenElastic(slot, {Size = UDim2.new(0, SLOT_W+6, 0, SLOT_H+6),
            Position = UDim2.new(0, xPos-3, 0, yPos-3)}, 0.35)
        task.wait(0.1)
        TweenSnap(slot, {Size = UDim2.new(0, SLOT_W, 0, SLOT_H),
            Position = UDim2.new(0, xPos, 0, yPos)}, 0.3)

        if skillData.cd > 0 then
            -- Cooldown drain animation
            local startTime = tick()
            local cdDuration = skillData.cd
            Tween(cdFill, {Size = UDim2.new(0, 0, 1, 0)}, cdDuration, Enum.EasingStyle.Linear, Enum.EasingDirection.In)
            slotBorder.Color = THEME.BORDER
            nameLbl.TextColor3 = THEME.GREY

            task.spawn(function()
                while tick() - startTime < cdDuration do
                    task.wait(0.05)
                end
                -- Reset
                isOnCooldown = false
                Tween(cdFill, {Size = UDim2.new(1, 0, 1, 0)}, 0.4)
                slotBorder.Color = skillData.color
                nameLbl.TextColor3 = THEME.WHITE
            end)
        else
            isOnCooldown = false
        end
    end

    hitArea.MouseButton1Click:Connect(FireSkill)

    -- Entrance animation
    slot.Position = UDim2.new(0, xPos, 0, yPos + 40)
    slot.BackgroundTransparency = 1
    task.wait(0.04 * ((row-1)*SLOTS_PER_ROW + col))
    TweenSnap(slot, {
        Position = UDim2.new(0, xPos, 0, yPos),
        BackgroundTransparency = 0.1
    }, 0.45)

    return slot
end

for i, skill in ipairs(SKILL_DB) do
    local row = math.ceil(i / SLOTS_PER_ROW)
    local col = ((i-1) % SLOTS_PER_ROW) + 1
    task.spawn(MakeSkillSlot, skill, row, col)
end

-- ══════════════════════════════════════════════════════════════════
--  SECTION 9 — AI ORACLE FLOATING ORB
-- ══════════════════════════════════════════════════════════════════

local OrbContainer = Factory.Frame(Screen, {
    bg     = Color3.fromRGB(0,0,0),
    bgT    = 1,
    size   = UDim2.new(0, 56, 0, 56),
    pos    = UDim2.new(1, -68, 0.5, -80),
    corner = 28,
    z      = 10,
})

-- Outer ring glow
local OrbRing = Factory.Frame(OrbContainer, {
    bg     = Color3.fromRGB(0,0,0),
    bgT    = 1,
    size   = UDim2.new(1, 12, 1, 12),
    pos    = UDim2.new(0, -6, 0, -6),
    corner = 34,
    z      = 10,
})
Factory.Border(OrbRing, THEME.VIOLET, 2)

-- Inner orb body
local OrbBody = Factory.Frame(OrbContainer, {
    bg     = THEME.VIOLET_DIM,
    bgT    = 0.1,
    size   = UDim2.new(1, -8, 1, -8),
    pos    = UDim2.new(0, 4, 0, 4),
    corner = 24,
    z      = 11,
})
Factory.Gradient(OrbBody, {THEME.VIOLET, Color3.fromRGB(20,0,40)}, 45)

local OrbIcon = Factory.Label(OrbContainer, {
    text   = "◈",
    font   = FONT_TITLE,
    color  = THEME.WHITE,
    ts     = 24,
    size   = UDim2.new(1, 0, 1, 0),
    pos    = UDim2.new(0, 0, 0, 0),
    z      = 12,
})

-- Pulse animation loop
local orbPulseDir = 1
local orbPulseAmt = 0
RunService.Heartbeat:Connect(function(dt)
    orbPulseAmt = orbPulseAmt + dt * 1.8 * orbPulseDir
    if orbPulseAmt >= 1 then orbPulseDir = -1
    elseif orbPulseAmt <= 0 then orbPulseDir = 1 end
    local t = math.sin(orbPulseAmt * math.pi)
    OrbRing.BackgroundTransparency = 0.5 + t * 0.4
    OrbBody.BackgroundTransparency = 0.05 + t * 0.15
end)

-- Oracle output panel (slides in from right)
local OraclePanel = Factory.Frame(Screen, {
    bg     = THEME.VOID,
    bgT    = 0.05,
    size   = UDim2.new(0, 240, 0, 60),
    pos    = UDim2.new(1, 10, 0.5, -108),
    corner = 8,
    z      = 9,
})
Factory.Border(OraclePanel, THEME.VIOLET, 1)

local OracleText = Factory.Label(OraclePanel, {
    text   = "[ ORACLE ] Systems initializing...",
    font   = FONT_MONO,
    color  = THEME.VIOLET,
    ts     = 10,
    size   = UDim2.new(1, -12, 1, 0),
    pos    = UDim2.new(0, 8, 0, 0),
    alignX = Enum.TextXAlignment.Left,
    wrap   = true,
    z      = 10,
})

local oraclePanelVisible = false

local function ShowOracle()
    if oraclePanelVisible then
        -- Hide
        Tween(OraclePanel, {Position = UDim2.new(1, 10, 0.5, -108)}, 0.3)
        oraclePanelVisible = false
    else
        -- Pick random line & show
        local line = ORACLE_LINES[math.random(1, #ORACLE_LINES)]
        OracleText.Text = line
        Tween(OraclePanel, {Position = UDim2.new(1, -258, 0.5, -108)}, 0.4)
        oraclePanelVisible = true
        -- Auto-hide after 4s
        task.delay(4, function()
            if oraclePanelVisible then
                Tween(OraclePanel, {Position = UDim2.new(1, 10, 0.5, -108)}, 0.3)
                oraclePanelVisible = false
            end
        end)
    end
end

-- Make orb draggable + tappable
local orbDragging, orbDragStart, orbPosStart = false, nil, nil

OrbContainer.InputBegan:Connect(function(inp)
    if inp.UserInputType == Enum.UserInputType.Touch
    or inp.UserInputType == Enum.UserInputType.MouseButton1 then
        orbDragging = true
        orbDragStart = inp.Position
        orbPosStart  = OrbContainer.Position
        TweenSnap(OrbRing, {BackgroundTransparency = 0.1}, 0.15)
    end
end)

OrbContainer.InputEnded:Connect(function(inp)
    if inp.UserInputType == Enum.UserInputType.Touch
    or inp.UserInputType == Enum.UserInputType.MouseButton1 then
        local moved = (inp.Position - orbDragStart).Magnitude
        orbDragging = false
        Tween(OrbRing, {BackgroundTransparency = 0.5}, 0.3)
        if moved < 8 then
            ShowOracle()
        end
    end
end)

UserInput.InputChanged:Connect(function(inp)
    if orbDragging and (inp.UserInputType == Enum.UserInputType.Touch
    or inp.UserInputType == Enum.UserInputType.MouseMove) then
        local vp  = Cam.ViewportSize
        local dx  = inp.Position.X - orbDragStart.X
        local dy  = inp.Position.Y - orbDragStart.Y
        local ax  = orbPosStart.X.Offset + dx
        local ay  = orbPosStart.Y.Offset + dy
        -- Clamp inside screen
        ax = math.clamp(ax, 0, vp.X - 56)
        ay = math.clamp(ay, 38, vp.Y - 56)
        OrbContainer.Position = UDim2.new(orbPosStart.X.Scale, ax, orbPosStart.Y.Scale, ay)
        OrbRing.Position      = UDim2.new(OrbContainer.Position.X.Scale,
            ax - 6, OrbContainer.Position.Y.Scale, ay - 6)
    end
end)

-- ══════════════════════════════════════════════════════════════════
--  SECTION 10 — PERFORMANCE MICRO-MONITOR (Side Panel)
-- ══════════════════════════════════════════════════════════════════

local PerfPanel = Factory.Frame(Screen, {
    bg     = THEME.VOID,
    bgT    = 0.08,
    size   = UDim2.new(0, 100, 0, 84),
    pos    = UDim2.new(0, 8, 0, 44),
    corner = 6,
    z      = 7,
})
Factory.Border(PerfPanel, THEME.BORDER, 1)

local function MakePerfRow(parent, label, y)
    local row = Factory.Frame(parent, {
        bg  = Color3.fromRGB(0,0,0), bgT=1,
        size= UDim2.new(1,-8,0,18), pos=UDim2.new(0,4,0,y), z=8
    })
    local lbl = Factory.Label(row, {
        text=label, font=FONT_MONO, color=THEME.GREY,
        ts=9, size=UDim2.new(0,40,1,0), pos=UDim2.new(0,0,0,0),
        alignX=Enum.TextXAlignment.Left, z=9
    })
    local val = Factory.Label(row, {
        text="--", font=FONT_MONO, color=THEME.CYAN,
        ts=9, size=UDim2.new(1,-42,1,0), pos=UDim2.new(0,42,0,0),
        alignX=Enum.TextXAlignment.Right, z=9
    })
    return val
end

local PerfTitle = Factory.Label(PerfPanel, {
    text="DIAGNOSTICS", font=FONT_TITLE, color=THEME.GREY,
    ts=8, size=UDim2.new(1,-8,0,14), pos=UDim2.new(0,4,0,2),
    alignX=Enum.TextXAlignment.Left, z=8
})

local MemVal  = MakePerfRow(PerfPanel, "MEM",  18)
local HBVal   = MakePerfRow(PerfPanel, "HEAT", 38)
local LatVal  = MakePerfRow(PerfPanel, "LAT",  58)

-- Update perf monitor
task.spawn(function()
    while true do
        local ok, mem = pcall(function()
            return math.floor(Stats:GetTotalMemoryUsageMb())
        end)
        if ok then
            local memC = mem < 400 and THEME.SKILL_4 or mem < 700 and THEME.SKILL_3 or THEME.RED
            MemVal.TextColor3 = memC
            MemVal.Text = mem.."MB"
        end

        local heat = math.floor(60 + math.random(-5,15)) -- simulated (no native API)
        local heatC = heat < 65 and THEME.SKILL_4 or heat < 80 and THEME.SKILL_3 or THEME.RED
        HBVal.TextColor3 = heatC
        HBVal.Text = heat.."°C"

        local lat = math.floor(math.random(12,42))
        LatVal.TextColor3 = lat < 25 and THEME.SKILL_4 or THEME.SKILL_3
        LatVal.Text = lat.."ms"

        task.wait(1.5)
    end
end)

-- ══════════════════════════════════════════════════════════════════
--  SECTION 11 — DOMAIN EXPANSION TRIGGER (Full-screen Burst)
-- ══════════════════════════════════════════════════════════════════

local DomainOverlay = Factory.Frame(Screen, {
    bg   = Color3.fromRGB(0, 0, 0),
    bgT  = 1,
    size = UDim2.new(1, 0, 1, 0),
    pos  = UDim2.new(0, 0, 0, 0),
    z    = 50,
})
DomainOverlay.Visible = false

local DomainText = Factory.Label(DomainOverlay, {
    text   = "◈ DOMAIN EXPANSION ◈\nINK OVERDRIVE",
    font   = FONT_TITLE,
    color  = THEME.VIOLET,
    ts     = 32,
    size   = UDim2.new(1, 0, 0, 120),
    pos    = UDim2.new(0, 0, 0.35, 0),
    wrap   = true,
    z      = 51,
})

local DomainSubText = Factory.Label(DomainOverlay, {
    text   = "PHANTOM CIRCUIT · NULL FIELD GENERATED",
    font   = FONT_MONO,
    color  = THEME.CYAN,
    ts     = 14,
    size   = UDim2.new(1, 0, 0, 30),
    pos    = UDim2.new(0, 0, 0.35, 110),
    z      = 51,
})

local isDomainActive = false

local function TriggerDomain()
    if isDomainActive then return end
    isDomainActive = true
    DomainOverlay.Visible = true
    DomainOverlay.BackgroundTransparency = 1
    DomainText.TextTransparency = 1
    DomainSubText.TextTransparency = 1

    -- Slam in
    Tween(DomainOverlay, {BackgroundTransparency = 0.05}, 0.12)
    task.wait(0.12)
    Tween(DomainText, {TextTransparency = 0}, 0.2)
    task.wait(0.25)
    TweenElastic(DomainText, {TextSize = 38}, 0.5)
    Tween(DomainSubText, {TextTransparency = 0}, 0.3)

    -- Hold
    task.wait(1.8)

    -- Fade out
    Tween(DomainOverlay, {BackgroundTransparency = 1}, 0.4)
    Tween(DomainText, {TextTransparency = 1}, 0.4)
    Tween(DomainSubText, {TextTransparency = 1}, 0.4)
    task.wait(0.5)
    DomainOverlay.Visible = false
    DomainText.TextSize = 32
    isDomainActive = false
end

-- Wire Domain Expansion to the ULT skill (G key / slot 6)
UserInput.InputBegan:Connect(function(inp, gp)
    if gp then return end
    if inp.KeyCode == Enum.KeyCode.G then
        task.spawn(TriggerDomain)
    end
end)

-- ══════════════════════════════════════════════════════════════════
--  SECTION 12 — NEURAL SEED INFINITE GENERATOR (Compressed Data)
-- ══════════════════════════════════════════════════════════════════

local SeedPool = {
    prefixes  = {"PHANTOM","VOID","NULL","INK","GHOST","CIRCUIT","ZERO","ECHO","DARK"},
    middles   = {"BREAK","SLASH","FIELD","WAVE","SURGE","PULSE","STORM","RIFT","VEIL"},
    suffixes  = {"ALPHA","OMEGA","EX","MAX","CORE","PRIME","ZERO","INF","TYPE-S"},
    ranks     = {"F","D","C","B","A","S","SS","SSS","∞"},
    elements  = {"VOID","INK","SHADOW","CIRCUIT","NULL","ETHER","PHASE"},
}

local function GenerateSeed()
    local p = SeedPool.prefixes[math.random(#SeedPool.prefixes)]
    local m = SeedPool.middles[math.random(#SeedPool.middles)]
    local s = SeedPool.suffixes[math.random(#SeedPool.suffixes)]
    local r = SeedPool.ranks[math.random(#SeedPool.ranks)]
    local e = SeedPool.elements[math.random(#SeedPool.elements)]
    local pw= math.random(100,9999)
    return string.format("[%s] %s %s %s · %s · PWR %d", r, p, m, s, e, pw)
end

-- Seed display strip (top area of main panel, right side)
local SeedStrip = Factory.Frame(MainPanel, {
    bg     = Color3.fromRGB(0,0,0),
    bgT    = 1,
    size   = UDim2.new(0, 200, 0, 70),
    pos    = UDim2.new(1, -208, 0, 0),
    z      = 6,
})

local SeedTitleLbl = Factory.Label(SeedStrip, {
    text   = "◆ NEURAL SEED",
    font   = FONT_TITLE,
    color  = THEME.GREY,
    ts     = 10,
    size   = UDim2.new(1, -8, 0, 18),
    pos    = UDim2.new(0, 8, 0, 4),
    alignX = Enum.TextXAlignment.Left,
    z      = 7,
})

local SeedVal = Factory.Label(SeedStrip, {
    text   = GenerateSeed(),
    font   = FONT_MONO,
    color  = THEME.CYAN,
    ts     = 8.5,
    size   = UDim2.new(1, -8, 0, 40),
    pos    = UDim2.new(0, 8, 0, 20),
    alignX = Enum.TextXAlignment.Left,
    wrap   = true,
    z      = 7,
})

local SeedBtn = Factory.Button(SeedStrip, {
    bg     = THEME.DEEP,
    bgT    = 0.3,
    size   = UDim2.new(1, -8, 0, 12),
    pos    = UDim2.new(0, 4, 1, -16),
    font   = FONT_MONO,
    text   = "[ TAP TO GENERATE ]",
    color  = THEME.GREY,
    ts     = 8,
    corner = 3,
    z      = 7,
})

SeedBtn.MouseButton1Click:Connect(function()
    SeedVal.Text = GenerateSeed()
    TweenSnap(SeedVal, {TextColor3 = THEME.VIOLET}, 0.1)
    task.wait(0.15)
    Tween(SeedVal, {TextColor3 = THEME.CYAN}, 0.4)
end)

-- ══════════════════════════════════════════════════════════════════
--  SECTION 13 — ENTRANCE ANIMATION SEQUENCE
-- ══════════════════════════════════════════════════════════════════

do
    -- Slide main panel in from bottom
    MainPanel.Position = UDim2.new(0, 0, 1, 10)
    MainPanel.BackgroundTransparency = 1
    task.wait(0.15)
    TweenSnap(MainPanel, {
        Position = UDim2.new(0, 0, 1, -310),
        BackgroundTransparency = 0.08
    }, 0.55)

    -- Orb entrance
    OrbContainer.BackgroundTransparency = 1
    task.wait(0.4)
    TweenElastic(OrbContainer, {BackgroundTransparency = 0}, 0.6)

    -- Perf panel
    PerfPanel.BackgroundTransparency = 1
    task.wait(0.2)
    Tween(PerfPanel, {BackgroundTransparency = 0.08}, 0.5)

    -- Initial Oracle greeting
    task.wait(0.8)
    OracleText.Text = "[ ORACLE ] Phantom Circuit v9 online. All systems nominal."
    Tween(OraclePanel, {Position = UDim2.new(1, -258, 0.5, -108)}, 0.4)
    oraclePanelVisible = true
    task.delay(4, function()
        Tween(OraclePanel, {Position = UDim2.new(1, 10, 0.5, -108)}, 0.3)
        oraclePanelVisible = false
    end)
end

-- ══════════════════════════════════════════════════════════════════
--  SECTION 14 — POINT-CLOUD AMBIENT PARTICLE SYSTEM
--              (5000-point cap — CPU-safe burst emitter)
-- ══════════════════════════════════════════════════════════════════

local ParticleRoot = Factory.Frame(Screen, {
    bg=Color3.new(0,0,0), bgT=1,
    size=UDim2.new(1,0,1,0),
    pos=UDim2.new(0,0,0,0),
    z=3, clip=false
})

local MAX_PARTICLES = 60 -- UI-layer particle cap (60 frames-based dots)
local activeParticles = 0

local function EmitUIParticle(x, y, color)
    if activeParticles >= MAX_PARTICLES then return end
    activeParticles = activeParticles + 1
    local dot = Factory.Frame(ParticleRoot, {
        bg     = color or THEME.CYAN,
        bgT    = 0.3,
        size   = UDim2.new(0, math.random(2,5), 0, math.random(2,5)),
        pos    = UDim2.new(0, x, 0, y),
        corner = 3,
        z      = 4,
    })
    local vx = (math.random()-0.5) * 80
    local vy = (math.random()-0.5) * 80 - 40
    local life = 0.4 + math.random() * 0.6
    TweenService:Create(dot, TweenInfo.new(life, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
        Position = UDim2.new(0, x + vx, 0, y + vy),
        BackgroundTransparency = 1,
        Size = UDim2.new(0, 1, 0, 1),
    }):Play()
    task.delay(life, function()
        dot:Destroy()
        activeParticles = activeParticles - 1
    end)
end

-- Emit particles on skill press (hook into Screen touch)
Screen.InputBegan:Connect(function(inp)
    if inp.UserInputType == Enum.UserInputType.Touch
    or inp.UserInputType == Enum.UserInputType.MouseButton1 then
        local colors = {THEME.CYAN, THEME.VIOLET, THEME.SKILL_3, THEME.WHITE}
        for i = 1, 12 do
            task.spawn(EmitUIParticle,
                inp.Position.X + math.random(-6,6),
                inp.Position.Y + math.random(-6,6),
                colors[math.random(#colors)]
            )
        end
    end
end)

-- ══════════════════════════════════════════════════════════════════
--  SECTION 15 — MINI NOTIFICATION TOASTER
-- ══════════════════════════════════════════════════════════════════

local function Toast(msg, color)
    local t = Factory.Frame(Screen, {
        bg     = THEME.VOID,
        bgT    = 0.05,
        size   = UDim2.new(0, 280, 0, 36),
        pos    = UDim2.new(0.5, -140, 0, -40),
        corner = 8,
        z      = 30,
    })
    Factory.Border(t, color or THEME.CYAN, 1)
    Factory.Label(t, {
        text   = msg,
        font   = FONT_MONO,
        color  = color or THEME.CYAN,
        ts     = 11,
        size   = UDim2.new(1,-12,1,0),
        pos    = UDim2.new(0,8,0,0),
        alignX = Enum.TextXAlignment.Left,
        z      = 31,
    })
    TweenSnap(t, {Position = UDim2.new(0.5,-140,0,46)}, 0.4)
    task.wait(2.5)
    Tween(t, {Position = UDim2.new(0.5,-140,0,-40), BackgroundTransparency=1}, 0.35)
    task.wait(0.4)
    t:Destroy()
end

-- Boot toast
task.spawn(function()
    task.wait(1.5)
    Toast("OMNI-DYNAMIC V9  ·  PHANTOM CIRCUIT  ·  ONLINE", THEME.CYAN)
    task.wait(3)
    Toast("TAP THE VIOLET ORB ◈ FOR NEURAL ORACLE GUIDANCE", THEME.VIOLET)
end)

-- ══════════════════════════════════════════════════════════════════
--  SECTION 16 — KEYBIND: TOGGLE ENTIRE HUD
-- ══════════════════════════════════════════════════════════════════

local hudVisible = true
UserInput.InputBegan:Connect(function(inp, gp)
    if gp then return end
    if inp.KeyCode == Enum.KeyCode.H then
        hudVisible = not hudVisible
        local t = hudVisible and 0 or 0.08
        Tween(MainPanel,   {BackgroundTransparency = hudVisible and 0.08 or 1}, 0.3)
        Tween(PerfPanel,   {BackgroundTransparency = hudVisible and 0.08 or 1}, 0.3)
        MainPanel.Visible  = hudVisible
        PerfPanel.Visible  = hudVisible
        task.spawn(Toast, hudVisible and "HUD VISIBLE" or "HUD HIDDEN — PRESS H TO RESTORE", THEME.GREY)
    end
    if inp.KeyCode == Enum.KeyCode.G then
        task.spawn(TriggerDomain)
    end
end)

-- ══════════════════════════════════════════════════════════════════
--  ✦  OMNI-DYNAMIC V9  ·  PHANTOM CIRCUIT EDITION  ·  LOADED  ✦
-- ══════════════════════════════════════════════════════════════════
print("◈ OMNI-DYNAMIC V9 [PHANTOM CIRCUIT] — Loaded successfully")
print("  Controls: [H] Toggle HUD  |  [G] Domain Expansion  |  Tap Orb for Oracle")
print("  Skill slots: Click/Touch to fire — cooldowns are per-slot")
print("  Drag the ◈ orb anywhere on screen")
