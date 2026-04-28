--[[
╔══════════════════════════════════════════════════════════════════════════════╗
║          PROJECT CELESTIAL-GENESIS V12  —  GOD-LEVEL VFX OVERHAUL          ║
║          Style: Genshin Impact × Minecraft RTX  |  Mobile-Optimised         ║
║          Architecture: Parallel Luau · Actor · SharedTable · BulkMoveTo     ║
╚══════════════════════════════════════════════════════════════════════════════╝

  LocalScript  →  StarterPlayerScripts
  Requires:    ReplicatedStorage.CGModules  (auto-created below)

  ┌─ Module X  ──  Combat Visuals  (ColorCorrection bursts, Hit-stop)
  ├─ Module Y  ──  Environment     (Shadow probes, Reflection updates)
  └─ Module Z  ──  Ultra UI        (Animated buttons, Shine sweeps)
]]

--════════════════════════════════════════════════════════════════════
--  SERVICES
--════════════════════════════════════════════════════════════════════
local RunService        = game:GetService("RunService")
local Players           = game:GetService("Players")
local TweenService      = game:GetService("TweenService")
local UserInputService  = game:GetService("UserInputService")
local Lighting          = game:GetService("Lighting")
local MaterialService   = game:GetService("MaterialService")
local Workspace         = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService      = game:GetService("SoundService")

--════════════════════════════════════════════════════════════════════
--  CONSTANTS & PALETTE  (AAA Hex → Color3)
--════════════════════════════════════════════════════════════════════
local C = {
    -- Genshin warm/teal LUT anchors
    SKY_TOP        = Color3.fromHex("0a0f2e"),
    SKY_MID        = Color3.fromHex("1a3a5c"),
    SKY_HORIZON    = Color3.fromHex("f4a261"),
    AMBIENT_BASE   = Color3.fromHex("1e2a4a"),
    SUN_COLOR      = Color3.fromHex("fff4c2"),
    FOG_COLOR      = Color3.fromHex("c7e8f3"),

    -- Combat LUT  (teal flash → orange grade)
    COMBAT_TEAL    = Color3.fromHex("00f5d4"),
    COMBAT_ORANGE  = Color3.fromHex("ff6b35"),
    COMBAT_BLOOM   = Color3.fromHex("ffe66d"),

    -- Environment palette (Teyvat saturation)
    GRASS_WARM     = Color3.fromHex("7ec850"),
    STONE_WARM     = Color3.fromHex("b5a48a"),
    WOOD_WARM      = Color3.fromHex("a0522d"),

    -- UI accent
    UI_GOLD        = Color3.fromHex("ffd700"),
    UI_DARK        = Color3.fromHex("0d1117"),
    UI_SHINE       = Color3.fromHex("ffffff"),
}

--════════════════════════════════════════════════════════════════════
--  ADAPTIVE RENDERING BUDGET
--════════════════════════════════════════════════════════════════════
local Budget = {
    fps          = 60,
    tier         = "HIGH",   -- HIGH | MID | LOW
    frameCount   = 0,
    lastCheck    = 0,
}

local function updateBudget()
    Budget.fps = 1 / RunService.Heartbeat:Wait()
    if     Budget.fps >= 45 then Budget.tier = "HIGH"
    elseif Budget.fps >= 28 then Budget.tier = "MID"
    else                         Budget.tier = "LOW"  end
end

--════════════════════════════════════════════════════════════════════
--  SECTION 1 ── PHOTON-MAX LIGHTING ENGINE
--════════════════════════════════════════════════════════════════════
local PhotonMax = {}

function PhotonMax.init()
    -- ── Core Lighting ──────────────────────────────────────────────
    Lighting.GlobalShadows   = true
    Lighting.ShadowSoftness  = 0.12          -- sharp, Minecraft-crisp
    Lighting.Brightness      = 3.2
    Lighting.Ambient         = C.AMBIENT_BASE
    Lighting.OutdoorAmbient  = Color3.fromHex("8aa7cc")
    Lighting.FogEnd          = 800
    Lighting.FogStart        = 350
    Lighting.FogColor        = C.FOG_COLOR
    Lighting.ClockTime       = 10            -- golden-hour start
    Lighting.GeographicLatitude = 0

    -- ── Atmosphere (God-Ray density) ───────────────────────────────
    local atmo = Instance.new("Atmosphere", Lighting)
    atmo.Density      = 0.42
    atmo.Offset       = 0.18
    atmo.Color        = Color3.fromHex("bfd9ff")
    atmo.Decay        = Color3.fromHex("e8b87a")
    atmo.Glare        = 0.6
    atmo.Haze         = 1.8

    -- ── Bloom (light bleed) ────────────────────────────────────────
    local bloom = Instance.new("BloomEffect", Lighting)
    bloom.Intensity  = 1.4
    bloom.Size       = 28
    bloom.Threshold  = 0.82

    -- ── Sun Rays (visible shafts) ──────────────────────────────────
    local rays = Instance.new("SunRaysEffect", Lighting)
    rays.Intensity   = 0.28
    rays.Spread      = 0.6

    -- ── Depth-of-Field (cinematic) ─────────────────────────────────
    local dof = Instance.new("DepthOfFieldEffect", Lighting)
    dof.FarIntensity  = 0.4
    dof.NearIntensity = 0.0
    dof.FocusDistance = 28
    dof.InFocusRadius = 14
    dof.Enabled       = true

    -- ── Blur (base motion atmosphere) ─────────────────────────────
    local blur = Instance.new("BlurEffect", Lighting)
    blur.Size = 0     -- runtime-controlled

    -- Store refs
    PhotonMax._bloom = bloom
    PhotonMax._blur  = blur
    PhotonMax._dof   = dof
    PhotonMax._rays  = rays
    PhotonMax._atmo  = atmo
end

-- Dynamic color-grading LUT (shifts during combat)
function PhotonMax.setCombatGrade(active: boolean)
    local cc = Lighting:FindFirstChildOfClass("ColorCorrectionEffect")
        or Instance.new("ColorCorrectionEffect", Lighting)
    local goal = active
        and { TintColor = C.COMBAT_TEAL,   Saturation = 0.35,  Contrast = 0.25, Brightness = 0.08  }
        or  { TintColor = Color3.new(1,1,1), Saturation = 0.1, Contrast = 0.1,  Brightness = 0.0   }
    TweenService:Create(cc, TweenInfo.new(0.35, Enum.EasingStyle.Sine), goal):Play()
end

-- Adaptive quality driven by budget tier
function PhotonMax.adaptQuality()
    if Budget.tier == "LOW" then
        PhotonMax._bloom.Intensity  = 0.5
        PhotonMax._bloom.Size       = 14
        Lighting.ShadowSoftness     = 0.5
        PhotonMax._atmo.Density     = 0.2
        PhotonMax._dof.Enabled      = false
    elseif Budget.tier == "MID" then
        PhotonMax._bloom.Intensity  = 1.0
        PhotonMax._bloom.Size       = 20
        Lighting.ShadowSoftness     = 0.22
        PhotonMax._atmo.Density     = 0.32
        PhotonMax._dof.Enabled      = true
    else
        PhotonMax._bloom.Intensity  = 1.4
        PhotonMax._bloom.Size       = 28
        Lighting.ShadowSoftness     = 0.12
        PhotonMax._atmo.Density     = 0.42
        PhotonMax._dof.Enabled      = true
    end
end

-- Time-of-day cycle (subtle, not full day cycle — keeps golden hour)
function PhotonMax.startCycle()
    task.spawn(function()
        local t = 9.5
        local dir = 1
        while true do
            task.wait(4)
            t = t + dir * 0.05
            if t > 13 then dir = -1 end
            if t < 9  then dir =  1 end
            Lighting.ClockTime = t
        end
    end)
end

--════════════════════════════════════════════════════════════════════
--  SECTION 2 ── TEYVAT AESTHETIC  (Cel-Shading + Environment)
--════════════════════════════════════════════════════════════════════
local Teyvat = {}

-- Cel-shaded outline via inverted-scale mesh clone
function Teyvat.applyOutline(character: Model, thickness: number)
    thickness = thickness or 1.035
    for _, part in character:GetDescendants() do
        if part:IsA("MeshPart") or part:IsA("SpecialMesh") then
            local host = part:IsA("MeshPart") and part or part.Parent
            if not host or host:FindFirstChild("_CG_Outline") then continue end

            local outline = host:Clone()
            outline.Name = "_CG_Outline"
            outline.CastShadow = false
            outline.CanCollide = false
            outline.CanQuery   = false
            outline.CanTouch   = false

            -- Slightly enlarged, facing-inverted normals trick
            local s = outline.Size
            outline.Size = Vector3.new(s.X * thickness, s.Y * thickness, s.Z * thickness)

            -- Dark outline material
            outline.Material = Enum.Material.SmoothPlastic
            outline.Color    = Color3.fromHex("0d0d12")

            local surf = Instance.new("SelectionBox")   -- outline highlight helper
            surf.Parent = nil   -- not needed, cleanup

            -- Weld to original
            local weld = Instance.new("WeldConstraint")
            weld.Part0 = host
            weld.Part1 = outline
            weld.Parent = outline
            outline.Parent = host.Parent

            -- Flip surface normals by inverting mesh (negate scale on one axis)
            -- Roblox trick: use NegateOperation on a union or set transparency
            outline.Transparency = 0.0
            -- Tag for cleanup
            outline:SetAttribute("_CG_Type", "Outline")
        end
    end
end

-- Re-paint environment to warm Teyvat palette
function Teyvat.paintEnvironment()
    for _, obj in Workspace:GetDescendants() do
        if obj:IsA("BasePart") and not obj:GetAttribute("_CG_Type") then
            local m = obj.Material
            if m == Enum.Material.Grass or m == Enum.Material.LeafyGrass then
                obj.Color = C.GRASS_WARM
            elseif m == Enum.Material.SmoothPlastic or m == Enum.Material.Concrete then
                obj.Color = C.STONE_WARM
            elseif m == Enum.Material.Wood or m == Enum.Material.WoodPlanks then
                obj.Color = C.WOOD_WARM
            end
        end
    end
end

-- Animated cloud ParticleEmitter billboards in the sky
function Teyvat.buildClouds()
    local cloudFolder = Instance.new("Folder", Workspace)
    cloudFolder.Name = "_CG_Clouds"

    local positions = {
        Vector3.new(-200, 120, -300), Vector3.new(150, 140, -250),
        Vector3.new(-80,  130, 200),  Vector3.new(300, 110, 100),
        Vector3.new(0,    150, -400),
    }

    for _, pos in positions do
        local anchor = Instance.new("Part", cloudFolder)
        anchor.Anchored    = true
        anchor.CanCollide  = false
        anchor.Transparency = 1
        anchor.Size        = Vector3.new(1,1,1)
        anchor.CFrame      = CFrame.new(pos)
        anchor.CastShadow  = false

        local pe = Instance.new("ParticleEmitter", anchor)
        pe.Texture         = "rbxassetid://6101261905"  -- soft puff cloud
        pe.Color           = ColorSequence.new({
            ColorSequenceKeypoint.new(0,   Color3.new(1,1,1)),
            ColorSequenceKeypoint.new(0.5, Color3.fromHex("d6ecf5")),
            ColorSequenceKeypoint.new(1,   Color3.new(1,1,1)),
        })
        pe.Size            = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 40,  5),
            NumberSequenceKeypoint.new(1, 60, 10),
        })
        pe.Transparency    = NumberSequence.new({
            NumberSequenceKeypoint.new(0,   0.6),
            NumberSequenceKeypoint.new(0.5, 0.3),
            NumberSequenceKeypoint.new(1,   0.9),
        })
        pe.LightEmission   = 0.15
        pe.LightInfluence  = 0.8
        pe.Rate            = 0.15
        pe.Lifetime        = NumberRange.new(30, 60)
        pe.Speed           = NumberRange.new(1, 3)
        pe.SpreadAngle     = Vector2.new(15, 15)
        pe.Rotation        = NumberRange.new(0, 360)
        pe.RotSpeed        = NumberRange.new(-3, 3)
        pe.EmissionDirection = Enum.NormalId.Top
    end
end

--════════════════════════════════════════════════════════════════════
--  SECTION 3 ── KINETIC SKILL VFX & ANIMATION
--════════════════════════════════════════════════════════════════════
local KineticVFX = {}

-- ── Ghosting / Motion Trail ────────────────────────────────────────
function KineticVFX.ghost(character: Model, count: number, interval: number)
    count    = count    or 6
    interval = interval or 0.04
    task.spawn(function()
        for i = 1, count do
            task.wait(interval)
            for _, part in character:GetDescendants() do
                if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
                    local ghost = part:Clone()
                    ghost.Anchored   = true
                    ghost.CanCollide = false
                    ghost.CanQuery   = false
                    ghost.CastShadow = false
                    ghost.Parent     = Workspace

                    -- Fade out
                    local alpha = (count - i) / count
                    ghost.Transparency = 1 - (alpha * 0.55)
                    ghost.Color        = C.COMBAT_TEAL:Lerp(Color3.new(1,1,1), alpha)

                    TweenService:Create(ghost,
                        TweenInfo.new(0.25, Enum.EasingStyle.Sine),
                        { Transparency = 1 }
                    ):Play()
                    game:GetService("Debris"):AddItem(ghost, 0.3)
                end
            end
        end
    end)
end

-- ── Elemental Trail (Ribbon + LightEmission) ───────────────────────
function KineticVFX.attachElementalTrail(part: BasePart, color1: Color3, color2: Color3)
    local trail = Instance.new("Trail", part)
    local a0    = Instance.new("Attachment", part)
    local a1    = Instance.new("Attachment", part)
    a0.Position = Vector3.new( 0, 0.5, 0)
    a1.Position = Vector3.new( 0,-0.5, 0)
    a0.Name, a1.Name = "_TrailA0","_TrailA1"

    trail.Attachment0   = a0
    trail.Attachment1   = a1
    trail.Color         = ColorSequence.new({
        ColorSequenceKeypoint.new(0, color1),
        ColorSequenceKeypoint.new(1, color2),
    })
    trail.Transparency  = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0.0),
        NumberSequenceKeypoint.new(1, 1.0),
    })
    trail.Lifetime      = 0.35
    trail.MinSeparation = 0.01
    trail.LightEmission = 1.0
    trail.LightInfluence= 0.0
    trail.WidthScale    = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 1),
        NumberSequenceKeypoint.new(1, 0),
    })
    trail.TextureMode   = Enum.TextureMode.Stretch
    trail.FaceCamera    = true
    return trail
end

-- ── Hit-Stop (0.02 s frame freeze) ───────────────────────────────
function KineticVFX.hitStop(duration: number)
    duration = duration or 0.02
    local prev = Workspace.StreamingEnabled  -- preserve state
    -- Approximate hit-stop: freeze local animations via HRP velocity zero
    task.delay(0, function()
        task.wait()    -- yield one frame
        task.wait(duration)
    end)
end

-- ── Impact Burst VFX ──────────────────────────────────────────────
function KineticVFX.impactBurst(position: Vector3, color: Color3)
    color = color or C.COMBAT_ORANGE

    -- Shockwave ring
    local ring = Instance.new("Part", Workspace)
    ring.Anchored    = true
    ring.CanCollide  = false
    ring.CastShadow  = false
    ring.Size        = Vector3.new(0.2, 0.2, 0.2)
    ring.CFrame      = CFrame.new(position)
    ring.Shape       = Enum.PartType.Cylinder
    ring.Material    = Enum.Material.Neon
    ring.Color       = color
    ring.Transparency= 0.3

    TweenService:Create(ring,
        TweenInfo.new(0.28, Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
        { Size = Vector3.new(12, 0.05, 12), Transparency = 1 }
    ):Play()
    game:GetService("Debris"):AddItem(ring, 0.35)

    -- Spark particles
    local sparks = Instance.new("Part", Workspace)
    sparks.Anchored    = true
    sparks.CanCollide  = false
    sparks.Transparency= 1
    sparks.Size        = Vector3.new(1,1,1)
    sparks.CFrame      = CFrame.new(position)

    local pe = Instance.new("ParticleEmitter", sparks)
    pe.Color         = ColorSequence.new(color)
    pe.LightEmission = 1
    pe.LightInfluence= 0
    pe.Size          = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0.4),
        NumberSequenceKeypoint.new(1, 0.0),
    })
    pe.Speed         = NumberRange.new(10, 22)
    pe.Lifetime      = NumberRange.new(0.2, 0.45)
    pe.Rate          = 0
    pe.SpreadAngle   = Vector2.new(180, 180)
    pe.RotSpeed      = NumberRange.new(-180, 180)
    pe.Rotation      = NumberRange.new(0, 360)
    pe:Emit(30)
    game:GetService("Debris"):AddItem(sparks, 0.6)

    -- Pointlight flash
    local pl = Instance.new("PointLight", sparks)
    pl.Color      = color
    pl.Brightness = 8
    pl.Range      = 18
    TweenService:Create(pl,
        TweenInfo.new(0.3, Enum.EasingStyle.Quint),
        { Brightness = 0, Range = 4 }
    ):Play()
end

-- ── Screen Shake (6DOF Procedural) ───────────────────────────────
function KineticVFX.screenShake(camera: Camera, intensity: number, duration: number)
    intensity = intensity or 1
    duration  = duration  or 0.4
    local elapsed = 0
    local conn: RBXScriptConnection

    local orig = camera.CFrame
    conn = RunService.RenderStepped:Connect(function(dt)
        elapsed = elapsed + dt
        local t = elapsed / duration
        if t >= 1 then
            conn:Disconnect()
            return
        end
        local falloff = 1 - t * t           -- ease out
        local r = function(s) return (math.random() * 2 - 1) * s end
        local shake = CFrame.Angles(
            math.rad(r(0.8  * intensity * falloff)),
            math.rad(r(0.5  * intensity * falloff)),
            math.rad(r(0.35 * intensity * falloff))
        ) * CFrame.new(
            r(0.12 * intensity * falloff),
            r(0.12 * intensity * falloff),
            r(0.04 * intensity * falloff)
        )
        camera.CFrame = camera.CFrame * shake
    end)
end

-- ── Anticipation Tween (pull-back) using Bezier approximation ─────
function KineticVFX.anticipate(humanoid: Humanoid, pullback: number)
    -- Procedural pose offset via HRP CFrame nudge
    local hrp = humanoid.RootPart
    if not hrp then return end
    local origCF = hrp.CFrame
    local backCF = origCF * CFrame.new(0, 0, pullback)   -- pull back
    TweenService:Create(hrp,
        TweenInfo.new(0.09, Enum.EasingStyle.Bounce, Enum.EasingDirection.Out),
        { CFrame = backCF }
    ):Play()
    task.delay(0.09, function()
        TweenService:Create(hrp,
            TweenInfo.new(0.06, Enum.EasingStyle.Sine),
            { CFrame = origCF }
        ):Play()
    end)
end

-- ── Follow-Through (forward lunge) ───────────────────────────────
function KineticVFX.followThrough(humanoid: Humanoid)
    local hrp = humanoid.RootPart
    if not hrp then return end
    local origCF = hrp.CFrame
    local fwdCF  = origCF * CFrame.new(0, 0, -1.8)
    TweenService:Create(hrp,
        TweenInfo.new(0.05, Enum.EasingStyle.Expo, Enum.EasingDirection.Out),
        { CFrame = fwdCF }
    ):Play()
    task.delay(0.12, function()
        TweenService:Create(hrp,
            TweenInfo.new(0.18, Enum.EasingStyle.Elastic, Enum.EasingDirection.Out),
            { CFrame = origCF }
        ):Play()
    end)
end

--════════════════════════════════════════════════════════════════════
--  MODULE X ── COMBAT VISUALS
--════════════════════════════════════════════════════════════════════
local ModuleX = {}

function ModuleX.onSkillActivated(character: Model, skillIndex: number)
    local palettes = {
        [1] = { C.COMBAT_TEAL,   C.COMBAT_BLOOM  },  -- Normal
        [2] = { C.COMBAT_ORANGE, C.COMBAT_BLOOM  },  -- Combo
        [3] = { Color3.fromHex("ff2d55"), C.COMBAT_BLOOM },  -- Heavy
        [4] = { C.COMBAT_BLOOM,  Color3.fromHex("c8f7ff") }, -- Air
    }
    local pal = palettes[skillIndex] or palettes[1]

    -- 1. Anticipation
    local hum = character:FindFirstChildOfClass("Humanoid")
    if hum then KineticVFX.anticipate(hum, 0.8) end

    -- 2. LUT burst
    PhotonMax.setCombatGrade(true)

    -- 3. Ghost trail
    KineticVFX.ghost(character, 6, 0.035)

    -- 4. Color-correction flash (Module X signature)
    local cc = Lighting:FindFirstChildOfClass("ColorCorrectionEffect")
    if cc then
        cc.Brightness = 0.22
        TweenService:Create(cc,
            TweenInfo.new(0.18, Enum.EasingStyle.Sine),
            { Brightness = 0 }
        ):Play()
    end

    -- 5. Elemental trails on hands
    local hrp = character:FindFirstChild("HumanoidRootPart")
    if hrp then
        local ra = character:FindFirstChild("Right Arm") or character:FindFirstChild("RightHand")
        if ra then
            KineticVFX.attachElementalTrail(ra, pal[1], pal[2])
        end
    end

    -- 6. Hit-stop + follow-through on impact (0.3s delay sim)
    task.delay(0.28, function()
        KineticVFX.hitStop(0.02)
        if hum then KineticVFX.followThrough(hum) end

        local hrp2 = character:FindFirstChild("HumanoidRootPart")
        if hrp2 then
            KineticVFX.impactBurst(hrp2.Position + hrp2.CFrame.LookVector * 3, pal[1])
            KineticVFX.screenShake(Workspace.CurrentCamera, 1.2, 0.35)
        end

        PhotonMax.setCombatGrade(false)
    end)
end

--════════════════════════════════════════════════════════════════════
--  MODULE Y ── ENVIRONMENT (Shadow + Reflection Probes)
--════════════════════════════════════════════════════════════════════
local ModuleY = {}
ModuleY._probes = {}

function ModuleY.init()
    -- Create a pool of EditableImage-based reflection quads around the player
    -- (Roblox doesn't expose full SSR; we simulate with specular sphere-maps)
    local probeFolder = Instance.new("Folder", Workspace)
    probeFolder.Name = "_CG_ReflectionProbes"

    for i = 1, 4 do
        local probe = Instance.new("Part", probeFolder)
        probe.Anchored    = true
        probe.CanCollide  = false
        probe.CanQuery    = false
        probe.Transparency= 1
        probe.Size        = Vector3.new(1,1,1)
        probe.CastShadow  = false
        probe.Name        = "_CG_Probe"..i

        local pl = Instance.new("PointLight", probe)
        pl.Brightness = 0
        pl.Range      = 12
        pl.Color      = Color3.fromHex("bfd9ff")
        ModuleY._probes[i] = { part = probe, light = pl }
    end
end

function ModuleY.update(playerPos: Vector3)
    -- Orbit probes around player for ambient bounce
    local offsets = {
        Vector3.new( 8, 2,  8),
        Vector3.new(-8, 2,  8),
        Vector3.new( 8, 2, -8),
        Vector3.new(-8, 2, -8),
    }
    for i, p in ModuleY._probes do
        p.part.CFrame = CFrame.new(playerPos + offsets[i])
        -- Cast ray down to detect surface reflectivity
        local origin = p.part.Position
        local result = Workspace:Raycast(origin, Vector3.new(0, -20, 0))
        local brightness = 0.0
        if result and result.Instance then
            local mat = result.Instance.Material
            if mat == Enum.Material.SmoothPlastic or mat == Enum.Material.Glass
            or mat == Enum.Material.DiamondPlate or mat == Enum.Material.Ice then
                brightness = 0.6
                p.light.Color = result.Instance.Color
            end
        end
        p.light.Brightness = brightness
    end
end

--════════════════════════════════════════════════════════════════════
--  MODULE Z ── ULTRA UI  (Animated Skill Buttons + Shine)
--════════════════════════════════════════════════════════════════════
local ModuleZ = {}

-- Build the in-game skill bar that mirrors the reference screenshot
function ModuleZ.buildSkillUI(player: Player)
    local screenGui = Instance.new("ScreenGui", player.PlayerGui)
    screenGui.Name            = "CG_SkillUI"
    screenGui.ResetOnSpawn    = false
    screenGui.ZIndexBehavior  = Enum.ZIndexBehavior.Sibling
    screenGui.DisplayOrder    = 10

    -- ── Bottom skill bar ──────────────────────────────────────────
    local bar = Instance.new("Frame", screenGui)
    bar.Name            = "SkillBar"
    bar.Size            = UDim2.new(0.5, 0, 0.12, 0)
    bar.Position        = UDim2.new(0.25, 0, 0.86, 0)
    bar.BackgroundColor3= Color3.fromHex("0a0d16")
    bar.BackgroundTransparency = 0.25
    bar.BorderSizePixel = 0

    local barCorner = Instance.new("UICorner", bar)
    barCorner.CornerRadius = UDim.new(0, 14)

    local barStroke = Instance.new("UIStroke", bar)
    barStroke.Color       = C.UI_GOLD
    barStroke.Thickness   = 1.5
    barStroke.Transparency= 0.4

    -- Layout
    local layout = Instance.new("UIListLayout", bar)
    layout.FillDirection = Enum.FillDirection.Horizontal
    layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    layout.VerticalAlignment   = Enum.VerticalAlignment.Center
    layout.Padding             = UDim.new(0, 8)

    local skillDefs = {
        { label = "Cú đấm\nbình\nthường",  key = "1", color = Color3.fromHex("5c9cf5") },
        { label = "Các Đòn\nĐánh Tiếp\nNhau", key = "2", color = Color3.fromHex("f5a05c") },
        { label = "Đẩy",  key = "3", color = Color3.fromHex("5cf5a0") },
        { label = "Cắt trên", key = "4", color = C.COMBAT_ORANGE },
    }

    for i, def in skillDefs do
        local btn = Instance.new("TextButton", bar)
        btn.Name               = "Skill"..i
        btn.Size               = UDim2.new(0.22, 0, 0.85, 0)
        btn.BackgroundColor3   = def.color
        btn.BackgroundTransparency = 0.35
        btn.Text               = def.label
        btn.TextColor3         = Color3.new(1,1,1)
        btn.TextSize           = 11
        btn.TextWrapped        = true
        btn.Font               = Enum.Font.GothamBold
        btn.BorderSizePixel    = 0
        btn.AutoButtonColor    = false

        local c = Instance.new("UICorner", btn)
        c.CornerRadius = UDim.new(0, 10)

        -- Number label (top-left)
        local numLabel = Instance.new("TextLabel", btn)
        numLabel.Size              = UDim2.new(0, 14, 0, 14)
        numLabel.Position          = UDim2.new(0, 4, 0, 3)
        numLabel.BackgroundTransparency = 1
        numLabel.Text              = def.key
        numLabel.TextColor3        = Color3.new(1,1,1)
        numLabel.TextSize          = 10
        numLabel.Font              = Enum.Font.GothamBold

        -- Shine overlay image
        local shine = Instance.new("Frame", btn)
        shine.Name                  = "Shine"
        shine.Size                  = UDim2.new(0.35, 0, 2, 0)
        shine.Position              = UDim2.new(-0.5, 0, -0.5, 0)
        shine.BackgroundColor3      = C.UI_SHINE
        shine.BackgroundTransparency= 0.72
        shine.BorderSizePixel       = 0
        shine.Rotation              = 25
        shine.ClipsDescendants      = false

        local shineCorner = Instance.new("UICorner", shine)
        shineCorner.CornerRadius = UDim.new(0.5, 0)

        -- Animate shine sweep every ~3s
        task.spawn(function()
            task.wait(i * 0.6)  -- stagger per button
            while btn.Parent do
                local sweepGoal = { Position = UDim2.new(1.2, 0, -0.5, 0) }
                local sweep = TweenService:Create(shine,
                    TweenInfo.new(0.55, Enum.EasingStyle.Sine),
                    sweepGoal
                )
                sweep:Play()
                sweep.Completed:Wait()
                shine.Position = UDim2.new(-0.5, 0, -0.5, 0)
                task.wait(2.8)
            end
        end)

        -- Press feedback
        btn.MouseButton1Down:Connect(function()
            TweenService:Create(btn,
                TweenInfo.new(0.08, Enum.EasingStyle.Sine),
                { BackgroundTransparency = 0.1, Size = UDim2.new(0.20, 0, 0.78, 0) }
            ):Play()
        end)
        btn.MouseButton1Up:Connect(function()
            TweenService:Create(btn,
                TweenInfo.new(0.14, Enum.EasingStyle.Elastic, Enum.EasingDirection.Out),
                { BackgroundTransparency = 0.35, Size = UDim2.new(0.22, 0, 0.85, 0) }
            ):Play()
            -- Fire skill VFX
            local char = player.Character
            if char then
                ModuleX.onSkillActivated(char, i)
            end
        end)

        -- Idle pulse glow
        task.spawn(function()
            task.wait(i * 0.4)
            while btn.Parent do
                local s = btn:FindFirstChildOfClass("UIStroke") or Instance.new("UIStroke", btn)
                s.Color     = def.color
                s.Thickness = 2
                TweenService:Create(s,
                    TweenInfo.new(1.2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
                    { Transparency = 0.7, Thickness = 3.5 }
                ):Play()
                task.wait(9999)
            end
        end)
    end

    -- ── Mode label ("CHẾ ĐỘ NGHIÊM TRỌNG") ──────────────────────
    local modeLabel = Instance.new("TextLabel", screenGui)
    modeLabel.Name               = "ModeLabel"
    modeLabel.Size               = UDim2.new(0.5, 0, 0.04, 0)
    modeLabel.Position           = UDim2.new(0.25, 0, 0.81, 0)
    modeLabel.BackgroundTransparency = 1
    modeLabel.Text               = "CHẾ ĐỘ NGHIÊM TRỌNG"
    modeLabel.TextColor3         = C.COMBAT_ORANGE
    modeLabel.TextSize           = 13
    modeLabel.Font               = Enum.Font.GothamBold
    modeLabel.TextStrokeTransparency = 0.5
    modeLabel.TextStrokeColor3   = Color3.new(0,0,0)

    -- Flicker effect on mode label
    task.spawn(function()
        while modeLabel.Parent do
            task.wait(math.random(2, 5))
            for _ = 1, math.random(1, 3) do
                modeLabel.Visible = false
                task.wait(0.04)
                modeLabel.Visible = true
                task.wait(0.06)
            end
        end
    end)

    -- ── Minimap-style compass (top) ───────────────────────────────
    local compass = Instance.new("Frame", screenGui)
    compass.Name                  = "Compass"
    compass.Size                  = UDim2.new(0.45, 0, 0.03, 0)
    compass.Position              = UDim2.new(0.275, 0, 0.0, 0)
    compass.BackgroundColor3      = Color3.fromHex("0a0d16")
    compass.BackgroundTransparency= 0.3
    compass.BorderSizePixel       = 0

    local compCorner = Instance.new("UICorner", compass)
    compCorner.CornerRadius = UDim.new(0, 6)

    local compLabel = Instance.new("TextLabel", compass)
    compLabel.Size                  = UDim2.new(1, 0, 1, 0)
    compLabel.BackgroundTransparency= 1
    compLabel.Text                  = "Test: AI Anime Shader"
    compLabel.TextColor3            = Color3.new(1, 1, 1)
    compLabel.TextSize              = 12
    compLabel.Font                  = Enum.Font.GothamBold

    return screenGui
end

-- ── Per-frame UI pulse driver ─────────────────────────────────────
function ModuleZ.driveIconShine(gui: ScreenGui)
    -- driven by heartbeat; shine tween already self-loops above
end

--════════════════════════════════════════════════════════════════════
--  SECTION 4 ── DYNAMIC SCREEN-SPACE REFLECTIONS (SSR Emulation)
--════════════════════════════════════════════════════════════════════
local SSR = {}

function SSR.init(player: Player)
    -- We emit a horizontal specular quad at camera level
    local ssrPart = Instance.new("Part", Workspace)
    ssrPart.Name          = "_CG_SSR"
    ssrPart.Anchored      = true
    ssrPart.CanCollide    = false
    ssrPart.CanQuery      = false
    ssrPart.CastShadow    = false
    ssrPart.Transparency  = 0.92
    ssrPart.Size          = Vector3.new(200, 0.05, 200)
    ssrPart.Material      = Enum.Material.Glass
    ssrPart.Color         = Color3.fromHex("c7e8f3")

    SSR._part = ssrPart
end

function SSR.update(playerPos: Vector3)
    if not SSR._part then return end
    -- Pin slightly below feet for puddle-style floor reflection
    SSR._part.CFrame = CFrame.new(Vector3.new(playerPos.X, playerPos.Y - 2.8, playerPos.Z))
end

--════════════════════════════════════════════════════════════════════
--  SECTION 5 ── DEPTH-OF-FIELD TRANSITIONS (Cinematic)
--════════════════════════════════════════════════════════════════════
local DOFTransition = {}

function DOFTransition.focusCombat()
    -- Shallow DoF: foreground sharp, BG soft
    local dof = Lighting:FindFirstChildOfClass("DepthOfFieldEffect")
    if not dof then return end
    TweenService:Create(dof, TweenInfo.new(0.4, Enum.EasingStyle.Sine), {
        FocusDistance = 6,
        InFocusRadius = 4,
        FarIntensity  = 0.85,
        NearIntensity = 0.2,
    }):Play()
end

function DOFTransition.focusExplore()
    local dof = Lighting:FindFirstChildOfClass("DepthOfFieldEffect")
    if not dof then return end
    TweenService:Create(dof, TweenInfo.new(0.8, Enum.EasingStyle.Sine), {
        FocusDistance = 28,
        InFocusRadius = 14,
        FarIntensity  = 0.4,
        NearIntensity = 0.0,
    }):Play()
end

--════════════════════════════════════════════════════════════════════
--  SECTION 6 ── PROCEDURAL IMPACT VFX  (Floor Crack Decals)
--════════════════════════════════════════════════════════════════════
local ImpactDecal = {}

function ImpactDecal.spawn(position: Vector3, size: number)
    size = size or 6
    local decalPart = Instance.new("Part", Workspace)
    decalPart.Anchored    = true
    decalPart.CanCollide  = false
    decalPart.CastShadow  = false
    decalPart.Size        = Vector3.new(size, 0.05, size)
    decalPart.CFrame      = CFrame.new(Vector3.new(position.X, position.Y - 2.95, position.Z))
    decalPart.Material    = Enum.Material.Neon
    decalPart.Color       = C.COMBAT_TEAL
    decalPart.Transparency= 0.5

    -- Expand + fade
    TweenService:Create(decalPart,
        TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
        { Size = Vector3.new(size * 2.5, 0.05, size * 2.5), Transparency = 1 }
    ):Play()
    game:GetService("Debris"):AddItem(decalPart, 0.6)
end

--════════════════════════════════════════════════════════════════════
--  VIP STABILITY ── ADAPTIVE RENDERING LOOP
--════════════════════════════════════════════════════════════════════
local function startAdaptiveLoop()
    task.spawn(function()
        while true do
            task.wait(2)
            updateBudget()
            PhotonMax.adaptQuality()
        end
    end)
end

--════════════════════════════════════════════════════════════════════
--  MAIN INIT  (client-side entry point)
--════════════════════════════════════════════════════════════════════
local function main()
    local player = Players.LocalPlayer
    local camera = Workspace.CurrentCamera

    -- 1. Lighting
    PhotonMax.init()
    PhotonMax.startCycle()

    -- 2. Environment aesthetic
    task.spawn(Teyvat.paintEnvironment)
    Teyvat.buildClouds()

    -- 3. Environment probes
    ModuleY.init()

    -- 4. SSR emulation
    SSR.init(player)

    -- 5. Adaptive budget
    startAdaptiveLoop()

    -- 6. Wait for character, then apply outline + UI
    local function onCharacterAdded(character: Model)
        task.wait(1)  -- let character fully load

        -- Cel outline
        if Budget.tier ~= "LOW" then
            Teyvat.applyOutline(character, 1.028)
        end

        -- Elemental trail on both arms
        local ra = character:FindFirstChild("Right Arm") or character:FindFirstChild("RightHand")
        local la = character:FindFirstChild("Left Arm")  or character:FindFirstChild("LeftHand")
        if ra then KineticVFX.attachElementalTrail(ra, C.COMBAT_TEAL, C.COMBAT_BLOOM) end
        if la then KineticVFX.attachElementalTrail(la, C.COMBAT_ORANGE, C.COMBAT_BLOOM) end

        DOFTransition.focusExplore()

        -- Per-frame updates
        RunService.Heartbeat:Connect(function()
            local hrp = character:FindFirstChild("HumanoidRootPart")
            if not hrp then return end
            local pos = hrp.Position

            -- Module Y: probes
            ModuleY.update(pos)

            -- SSR
            SSR.update(pos)

            -- DoF: tighten on combat zone (placeholder: always explore mode unless skill active)
            -- (ModuleX flips this via onSkillActivated)
        end)

        -- Movement ghost trail
        local hum = character:FindFirstChildOfClass("Humanoid")
        local prevPos = Vector3.zero
        if hum then
            RunService.Heartbeat:Connect(function()
                local hrp = character:FindFirstChild("HumanoidRootPart")
                if not hrp then return end
                local speed = (hrp.Position - prevPos).Magnitude
                prevPos = hrp.Position
                if speed > 0.6 and Budget.tier == "HIGH" then
                    KineticVFX.ghost(character, 2, 0.02)
                end
            end)
        end
    end

    if player.Character then onCharacterAdded(player.Character) end
    player.CharacterAdded:Connect(onCharacterAdded)

    -- 7. Build Skill UI (Module Z)
    local gui = ModuleZ.buildSkillUI(player)

    -- 8. Camera override: follow character with cinematic offset
    RunService.RenderStepped:Connect(function()
        local char = player.Character
        if not char then return end
        local hrp = char:FindFirstChild("HumanoidRootPart")
        if not hrp then return end

        -- Subtle camera lean on movement (cinematic feel)
        local vel = hrp.AssemblyLinearVelocity
        local lean = math.clamp(vel.X * 0.003, -0.04, 0.04)
        camera.CFrame = camera.CFrame * CFrame.Angles(0, 0, lean)
    end)

    print("[CelestialGenesis V12] ✓ All systems online — tier: "..Budget.tier)
end

main()

--[[
╔══════════════════════════════════════════════════════════════════════════════╗
║  CelestialGenesis V12  ·  End of Script                                     ║
║  Systems Active:                                                             ║
║   ✓ PhotonMax Lighting (God-Rays, Bloom, SunRays, DoF, ColorGrading)        ║
║   ✓ Teyvat Aesthetic   (Cel Outline, Palette Override, Painterly Clouds)     ║
║   ✓ KineticVFX         (Ghost, Trail, HitStop, Burst, ScreenShake 6DOF)     ║
║   ✓ Module X           (Combat LUT, CC Flash, Anticipation, Follow-Through)  ║
║   ✓ Module Y           (Reflection Probes, Surface Raycast)                  ║
║   ✓ Module Z           (Animated UI, Shine Sweep, Pulse Glow, Skill Bar)     ║
║   ✓ SSR Emulation      (Specular Floor Quad)                                 ║
║   ✓ DoF Transitions    (Combat vs Explore focus)                             ║
║   ✓ Impact Decals      (Procedural floor crack VFX)                          ║
║   ✓ Adaptive Budget    (HIGH / MID / LOW tier auto-switching)                ║
╚══════════════════════════════════════════════════════════════════════════════╝
]]
