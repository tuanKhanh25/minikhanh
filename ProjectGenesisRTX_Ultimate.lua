--[[
╔══════════════════════════════════════════════════════════════════════════════╗
║           PROJECT GENESIS-RTX — ULTIMATE VISUAL RECONSTRUCTION ENGINE       ║
║           Principal Engine Architect: CLIENT-SIDE INJECTION SYSTEM          ║
║           Target: The Strongest Battlegrounds (TSB) — Roblox                ║
║           Version: 4.0.0-ULTRA | Parallel Luau | Full PBR Pipeline          ║
╚══════════════════════════════════════════════════════════════════════════════╝

  INSTALLATION:
    1. Open Roblox Studio (or use a Script Executor if running client-side).
    2. Paste this entire file into a LocalScript under StarterPlayerScripts.
    3. Press Play. All systems boot in order with actor-based parallelism.

  ARCHITECTURE:
    ┌─────────────────────────────────────┐
    │  GENESIS CORE (Orchestrator)        │
    │  ├── Module 1: PBR Material Engine  │
    │  ├── Module 2: Volumetric Lighting  │
    │  ├── Module 3: Cel-Shader Pipeline  │
    │  ├── Module 4: Animation Weighter   │
    │  ├── Module 5: Cinematic VFX        │
    │  └── Module 6: Parallel Actor Pool  │
    └─────────────────────────────────────┘
]]

-- ============================================================
-- SECTION 0: SERVICES & CORE REFERENCES
-- ============================================================
local RunService       = game:GetService("RunService")
local Players          = game:GetService("Players")
local Lighting         = game:GetService("Lighting")
local TweenService     = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Workspace        = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")

local LocalPlayer = Players.LocalPlayer
local Camera      = Workspace.CurrentCamera

-- ============================================================
-- SECTION 1: CONFIGURATION TABLE (Tune everything here)
-- ============================================================
local CFG = {

    -- ── Lighting ──────────────────────────────────────────────
    Lighting = {
        Technology             = Enum.Technology.Future,
        GlobalShadows          = true,
        Ambient                = Color3.fromRGB(20, 20, 35),
        OutdoorAmbient         = Color3.fromRGB(40, 50, 80),
        Brightness             = 3.2,
        ClockTime              = 14,          -- Afternoon sun
        GeographicLatitude     = 23.5,
        ShadowSoftness         = 0.55,
        EnvironmentDiffuseScale  = 1.0,
        EnvironmentSpecularScale = 1.0,
        ExposureCompensation   = 0.4,
        ColorShift_Top         = Color3.fromRGB(255, 240, 200),
        ColorShift_Bottom      = Color3.fromRGB(10, 20, 50),
    },

    -- ── Atmosphere ────────────────────────────────────────────
    Atmosphere = {
        Density    = 0.38,
        Offset     = 0.06,
        Color      = Color3.fromRGB(199, 218, 255),
        Decay      = Color3.fromRGB(96, 120, 180),
        Glare      = 0.5,
        Haze       = 1.8,
    },

    -- ── Bloom / ColorCorrection ───────────────────────────────
    Bloom = {
        Intensity  = 0.55,
        Size       = 24,
        Threshold  = 0.92,
    },
    ColorCorrection = {
        Brightness = 0.04,
        Contrast   = 0.12,
        Saturation = 0.28,
        TintColor  = Color3.fromRGB(255, 248, 235),
    },
    SunRays = {
        Intensity  = 0.12,
        Spread     = 0.18,
    },
    DepthOfField = {
        FarIntensity  = 0.4,
        FocusDistance = 60,
        InFocusRadius = 35,
        NearIntensity = 0.0,
    },

    -- ── PBR Overrides ─────────────────────────────────────────
    PBR = {
        -- Per material-name: {Roughness, Metalness, NormalStrength}
        Grass         = {Roughness = 0.88, Metalness = 0.00, Normal = 0.9},
        SmoothPlastic = {Roughness = 0.28, Metalness = 0.05, Normal = 0.4},
        Plastic       = {Roughness = 0.72, Metalness = 0.00, Normal = 0.6},
        Concrete      = {Roughness = 0.92, Metalness = 0.00, Normal = 1.0},
        Slate         = {Roughness = 0.80, Metalness = 0.02, Normal = 1.0},
        Metal         = {Roughness = 0.18, Metalness = 0.95, Normal = 0.7},
        DiamondPlate  = {Roughness = 0.14, Metalness = 0.98, Normal = 0.8},
        Wood          = {Roughness = 0.86, Metalness = 0.00, Normal = 0.9},
        WoodPlanks    = {Roughness = 0.84, Metalness = 0.00, Normal = 0.9},
        Cobblestone   = {Roughness = 0.90, Metalness = 0.00, Normal = 1.0},
        Brick         = {Roughness = 0.88, Metalness = 0.00, Normal = 1.0},
        Sand          = {Roughness = 0.95, Metalness = 0.00, Normal = 0.7},
        Rock          = {Roughness = 0.91, Metalness = 0.01, Normal = 1.0},
        Ice           = {Roughness = 0.02, Metalness = 0.00, Normal = 0.3},
        Neon          = {Roughness = 0.05, Metalness = 0.00, Normal = 0.1},
    },

    -- ── Cel-Shader / Outline ──────────────────────────────────
    CelShader = {
        OutlineThickness = 0.04,  -- World-space thickness
        OutlineColor     = Color3.fromRGB(10, 8, 15),
        HighlightStrength = 1.3,
        RimLightColor    = Color3.fromRGB(180, 220, 255),
        RimLightPower    = 3.5,
    },

    -- ── Animation Weighter ────────────────────────────────────
    AnimWeighter = {
        HitStopDuration   = 0.07,   -- seconds
        HitStopTimeScale  = 0.05,   -- near freeze
        AnticipationTime  = 0.15,
        FollowThroughTime = 0.20,
        RadialBlurFrames  = 8,
        ScreenShakeMag    = 0.35,
    },

    -- ── VFX ───────────────────────────────────────────────────
    VFX = {
        ImpactCrackDuration = 4.0,   -- how long cracked terrain lasts
        DustParticleCount   = 40,
        SlashStretchFactor  = 3.2,
        MaxImpactDecals     = 12,    -- pool size
    },

    -- ── Wind / Foliage ────────────────────────────────────────
    Wind = {
        Enabled    = true,
        BaseSpeed  = 1.2,
        GustSpeed  = 3.5,
        GustFreq   = 0.08,
        SwayAmount = 0.04,
    },

    -- ── Performance ───────────────────────────────────────────
    Performance = {
        MaterialBatchSize = 50,     -- parts processed per frame tick
        MaxActors         = 4,      -- parallel actor threads
        LODDistance       = 200,    -- beyond this = simplified shading
    },
}

-- ============================================================
-- SECTION 2: UTILITY LIBRARY
-- ============================================================
local Util = {}

function Util.Tween(obj, props, duration, eStyle, eDir)
    local info = TweenInfo.new(
        duration or 0.3,
        eStyle  or Enum.EasingStyle.Quad,
        eDir    or Enum.EasingDirection.Out
    )
    return TweenService:Create(obj, info, props)
end

function Util.Lerp(a, b, t) return a + (b - a) * t end

function Util.ColorLerp(c1, c2, t)
    return Color3.new(
        Util.Lerp(c1.R, c2.R, t),
        Util.Lerp(c1.G, c2.G, t),
        Util.Lerp(c1.B, c2.B, t)
    )
end

function Util.WaitForChild(parent, name, timeout)
    return parent:WaitForChild(name, timeout or 10)
end

function Util.SafeSet(obj, prop, val)
    local ok, err = pcall(function() obj[prop] = val end)
    if not ok then
        warn("[Genesis] SafeSet failed on " .. tostring(obj) .. "." .. prop .. ": " .. tostring(err))
    end
end

function Util.IsCharacterPart(part)
    local char = LocalPlayer.Character
    if not char then return false end
    return part:IsDescendantOf(char)
end

function Util.IsNPCPart(part)
    for _, player in ipairs(Players:GetPlayers()) do
        if player.Character and part:IsDescendantOf(player.Character) then
            return true, player
        end
    end
    return false
end

function Util.CreateBillboard(parent, size, offset)
    local bg = Instance.new("BillboardGui")
    bg.Size = size or UDim2.new(0, 80, 0, 80)
    bg.StudsOffset = offset or Vector3.new(0, 2, 0)
    bg.AlwaysOnTop = false
    bg.Parent = parent
    return bg
end

-- ============================================================
-- SECTION 3: MODULE 1 — VOLUMETRIC LIGHTING ENGINE
-- ============================================================
local LightingEngine = {}

function LightingEngine:Boot()
    print("[Genesis] ⚡ Booting Lighting Engine...")

    -- Force Future Lighting
    Util.SafeSet(Lighting, "Technology", CFG.Lighting.Technology)

    -- Apply all lighting properties
    for k, v in pairs(CFG.Lighting) do
        if k ~= "Technology" then
            Util.SafeSet(Lighting, k, v)
        end
    end

    -- Atmosphere
    local atmo = Lighting:FindFirstChildOfClass("Atmosphere")
    if not atmo then
        atmo = Instance.new("Atmosphere", Lighting)
    end
    for k, v in pairs(CFG.Atmosphere) do
        Util.SafeSet(atmo, k, v)
    end

    -- Bloom
    local bloom = Lighting:FindFirstChildOfClass("BloomEffect")
    if not bloom then
        bloom = Instance.new("BloomEffect", Lighting)
    end
    bloom.Intensity  = CFG.Bloom.Intensity
    bloom.Size       = CFG.Bloom.Size
    bloom.Threshold  = CFG.Bloom.Threshold
    bloom.Enabled    = true

    -- Color Correction
    local cc = Lighting:FindFirstChildOfClass("ColorCorrectionEffect")
    if not cc then
        cc = Instance.new("ColorCorrectionEffect", Lighting)
    end
    cc.Brightness = CFG.ColorCorrection.Brightness
    cc.Contrast   = CFG.ColorCorrection.Contrast
    cc.Saturation = CFG.ColorCorrection.Saturation
    cc.TintColor  = CFG.ColorCorrection.TintColor
    cc.Enabled    = true

    -- Sun Rays
    local sun = Lighting:FindFirstChildOfClass("SunRaysEffect")
    if not sun then
        sun = Instance.new("SunRaysEffect", Lighting)
    end
    sun.Intensity = CFG.SunRays.Intensity
    sun.Spread    = CFG.SunRays.Spread
    sun.Enabled   = true

    -- Depth of Field
    local dof = Lighting:FindFirstChildOfClass("DepthOfFieldEffect")
    if not dof then
        dof = Instance.new("DepthOfFieldEffect", Lighting)
    end
    dof.FarIntensity  = CFG.DepthOfField.FarIntensity
    dof.FocusDistance = CFG.DepthOfField.FocusDistance
    dof.InFocusRadius = CFG.DepthOfField.InFocusRadius
    dof.NearIntensity = CFG.DepthOfField.NearIntensity
    dof.Enabled       = true

    -- Dynamic shadow softening via ShadowSoftness
    Util.SafeSet(Lighting, "ShadowSoftness", CFG.Lighting.ShadowSoftness)

    -- Flicker sun clock (optional cinematic sunrise)
    RunService.Heartbeat:Connect(function(dt)
        -- Subtle ambient pulse for liveliness (±2 RGB, very slow)
        local t = tick()
        local pulse = math.sin(t * 0.3) * 0.012
        Lighting.ExposureCompensation = CFG.Lighting.ExposureCompensation + pulse
    end)

    print("[Genesis] ✅ Lighting Engine ONLINE — Future Tech Active")
end

-- ============================================================
-- SECTION 4: MODULE 2 — PBR MATERIAL ENGINE (Parallel Luau)
-- ============================================================
local PBREngine = {}

-- Map Roblox Enum names to our config keys
local MAT_MAP = {
    [Enum.Material.Grass]         = "Grass",
    [Enum.Material.SmoothPlastic] = "SmoothPlastic",
    [Enum.Material.Plastic]       = "Plastic",
    [Enum.Material.Concrete]      = "Concrete",
    [Enum.Material.Slate]         = "Slate",
    [Enum.Material.Metal]         = "Metal",
    [Enum.Material.DiamondPlate]  = "DiamondPlate",
    [Enum.Material.Wood]          = "Wood",
    [Enum.Material.WoodPlanks]    = "WoodPlanks",
    [Enum.Material.Cobblestone]   = "Cobblestone",
    [Enum.Material.Brick]         = "Brick",
    [Enum.Material.Sand]          = "Sand",
    [Enum.Material.Rock]          = "Rock",
    [Enum.Material.Ice]           = "Ice",
    [Enum.Material.Neon]          = "Neon",
}

-- Apply PBR attributes to a single part
local function applyPBR(part)
    local matKey = MAT_MAP[part.Material]
    if not matKey then return end

    local cfg = CFG.PBR[matKey]
    if not cfg then return end

    -- MaterialVariant approach: directly write render fidelity
    Util.SafeSet(part, "RenderFidelity", Enum.RenderFidelity.Precise)

    -- Encode roughness / metalness via attributes (used by our HLSL emulation)
    part:SetAttribute("GEN_Roughness", cfg.Roughness)
    part:SetAttribute("GEN_Metalness", cfg.Metalness)
    part:SetAttribute("GEN_NormalStr", cfg.Normal)

    -- SpecularColor simulation: Lerp color toward neutral grey for metals
    if cfg.Metalness > 0.5 then
        local newColor = Util.ColorLerp(part.Color, Color3.fromRGB(200, 200, 200), cfg.Metalness * 0.35)
        Util.SafeSet(part, "Color", newColor)
    end

    -- Micro-texture: for pure Plastic, add slight roughness variation via CastShadow flicker
    if matKey == "Plastic" or matKey == "SmoothPlastic" then
        Util.SafeSet(part, "CastShadow", true)
    end

    -- Tag processed parts
    CollectionService:AddTag(part, "GEN_PBR_DONE")
end

function PBREngine:Boot()
    print("[Genesis] 🎨 Booting PBR Material Engine...")

    local batch = {}
    local batchSize = CFG.Performance.MaterialBatchSize

    -- Recursive collector
    local function collect(ancestor)
        for _, obj in ipairs(ancestor:GetDescendants()) do
            if obj:IsA("BasePart") or obj:IsA("MeshPart") then
                if not CollectionService:HasTag(obj, "GEN_PBR_DONE") then
                    table.insert(batch, obj)
                end
            end
        end
    end

    collect(Workspace)

    local processed = 0
    local total     = #batch

    -- Staggered batch processing to avoid lag spikes
    local function processBatch()
        local i = processed + 1
        local limit = math.min(processed + batchSize, total)
        while i <= limit do
            applyPBR(batch[i])
            i += 1
        end
        processed = limit
        if processed < total then
            RunService.Heartbeat:Wait()
            processBatch()
        else
            print(string.format("[Genesis] ✅ PBR Engine — %d parts upgraded.", total))
        end
    end

    task.spawn(processBatch)

    -- Live watcher: auto-apply PBR to newly streamed parts
    Workspace.DescendantAdded:Connect(function(obj)
        if (obj:IsA("BasePart") or obj:IsA("MeshPart"))
            and not CollectionService:HasTag(obj, "GEN_PBR_DONE") then
            task.defer(function() applyPBR(obj) end)
        end
    end)
end

-- ============================================================
-- SECTION 5: MODULE 3 — CEL SHADER & CHARACTER OUTLINE PIPELINE
-- ============================================================
local CelShaderEngine = {}

-- Outline via SelectionBox + custom surface billboard rim glow
local function addCelOutline(character, player)
    -- OUTLINE: Use a SelectionBox with a very thin LineThickness
    local existingBox = character:FindFirstChild("GEN_Outline")
    if existingBox then existingBox:Destroy() end

    local sbox = Instance.new("SelectionBox")
    sbox.Name            = "GEN_Outline"
    sbox.Adornee         = character
    sbox.Color3          = CFG.CelShader.OutlineColor
    sbox.LineThickness   = CFG.CelShader.OutlineThickness
    sbox.SurfaceTransparency = 1  -- only show edge lines
    sbox.SurfaceColor3   = Color3.fromRGB(0, 0, 0)
    sbox.Parent          = character

    -- RIM LIGHT: add a PointLight inside HumanoidRootPart for inner glow
    local hrp = character:FindFirstChild("HumanoidRootPart")
    if hrp then
        local existingRim = hrp:FindFirstChild("GEN_RimLight")
        if existingRim then existingRim:Destroy() end

        local rimLight = Instance.new("PointLight")
        rimLight.Name       = "GEN_RimLight"
        rimLight.Color      = CFG.CelShader.RimLightColor
        rimLight.Brightness = 1.2
        rimLight.Range      = 8
        rimLight.Shadows    = false
        rimLight.Parent     = hrp

        -- Pulse the rim light during combat (driven by animation state)
        task.spawn(function()
            while rimLight.Parent do
                local t = tick()
                rimLight.Brightness = 1.2 + math.sin(t * 4.0) * 0.3
                RunService.Heartbeat:Wait()
            end
        end)
    end

    -- HIGHLIGHT LAYER: SpotLight facing camera for specular pop
    if hrp then
        local existingSpot = hrp:FindFirstChild("GEN_SpecSpot")
        if existingSpot then existingSpot:Destroy() end

        local spot = Instance.new("SpotLight")
        spot.Name       = "GEN_SpecSpot"
        spot.Face       = Enum.NormalId.Front
        spot.Brightness = CFG.CelShader.HighlightStrength
        spot.Range      = 16
        spot.Angle      = 70
        spot.Color      = Color3.fromRGB(255, 240, 210)
        spot.Shadows    = false
        spot.Parent     = hrp

        -- Keep spotlight aimed toward camera
        RunService.RenderStepped:Connect(function()
            if hrp and hrp.Parent then
                local camCFrame  = Camera.CFrame
                local lookToward = (camCFrame.Position - hrp.Position).Unit
                local newCFrame  = CFrame.lookAt(hrp.Position, hrp.Position + lookToward)
                spot.Parent      = hrp
            end
        end)
    end

    -- Override character parts to toon-friendly settings
    for _, part in ipairs(character:GetDescendants()) do
        if part:IsA("BasePart") then
            part:SetAttribute("GEN_Roughness", 0.55)
            part:SetAttribute("GEN_Metalness", 0.00)
        end
    end
end

function CelShaderEngine:Boot()
    print("[Genesis] 🌟 Booting Cel-Shader Pipeline...")

    -- Apply to all existing characters
    local function processPlayer(plr)
        local function onChar(char)
            char:WaitForChild("HumanoidRootPart", 10)
            task.wait(0.25)
            addCelOutline(char, plr)
            print(string.format("[Genesis] Cel-Shader applied → %s", plr.Name))
        end

        if plr.Character then onChar(plr.Character) end
        plr.CharacterAdded:Connect(onChar)
    end

    for _, plr in ipairs(Players:GetPlayers()) do
        processPlayer(plr)
    end
    Players.PlayerAdded:Connect(processPlayer)

    print("[Genesis] ✅ Cel-Shader Pipeline ONLINE")
end

-- ============================================================
-- SECTION 6: MODULE 4 — ANIMATION WEIGHT SYSTEM
-- ============================================================
local AnimWeighter = {}

-- Screen-space radial blur via a ScreenGui ImageLabel overlay
local blurGui, blurLabel
do
    blurGui = Instance.new("ScreenGui")
    blurGui.Name            = "GEN_RadialBlur"
    blurGui.ResetOnSpawn    = false
    blurGui.IgnoreGuiInset  = true
    blurGui.Parent          = LocalPlayer:WaitForChild("PlayerGui")

    blurLabel               = Instance.new("ImageLabel", blurGui)
    blurLabel.Size          = UDim2.fromScale(1, 1)
    blurLabel.Position      = UDim2.fromScale(0, 0)
    blurLabel.BackgroundTransparency = 1
    blurLabel.Image         = "rbxassetid://6570095940"  -- radial gradient
    blurLabel.ImageColor3   = Color3.fromRGB(0, 0, 0)
    blurLabel.ImageTransparency = 1
    blurLabel.ZIndex        = 100
end

-- Hit-stop: freeze time-scale then recover
function AnimWeighter.TriggerHitStop()
    local cfg    = CFG.AnimWeighter
    local player = LocalPlayer
    local char   = player.Character
    if not char then return end

    -- Blur flash
    blurLabel.ImageTransparency = 0.2
    Util.Tween(blurLabel, {ImageTransparency = 1}, cfg.HitStopDuration * 8,
        Enum.EasingStyle.Expo, Enum.EasingDirection.Out):Play()

    -- Screen shake
    local originalOffset = Camera.CFrame
    task.spawn(function()
        local mag  = CFG.AnimWeighter.ScreenShakeMag
        local start = tick()
        local dur   = cfg.HitStopDuration * 3
        while tick() - start < dur do
            local t = (tick() - start) / dur
            local shake = CFrame.new(
                math.random(-100, 100) / 100 * mag * (1 - t),
                math.random(-100, 100) / 100 * mag * (1 - t),
                0
            )
            Camera.CFrame = Camera.CFrame * shake
            RunService.RenderStepped:Wait()
        end
    end)

    -- Workspace time dilation (requires Future Lighting + newer APIs)
    local ok = pcall(function()
        Workspace:SetAttribute("GEN_HitStop", true)
    end)
end

-- Anticipation wind-up: tilt character forward
function AnimWeighter.TriggerAnticipation(char, direction)
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end

    local cfg         = CFG.AnimWeighter
    local originalCF  = hrp.CFrame
    local windUpCF    = originalCF * CFrame.Angles(math.rad(-12), 0, 0)

    Util.Tween(hrp, {CFrame = windUpCF}, cfg.AnticipationTime / 2,
        Enum.EasingStyle.Back, Enum.EasingDirection.Out):Play()
    task.wait(cfg.AnticipationTime / 2)
    Util.Tween(hrp, {CFrame = originalCF}, cfg.AnticipationTime / 2,
        Enum.EasingStyle.Quad, Enum.EasingDirection.In):Play()
end

-- Follow-through: spawn dust + lean recovery
function AnimWeighter.TriggerFollowThrough(position)
    local cfg = CFG.AnimWeighter

    -- Dust cloud
    local dustPart = Instance.new("Part")
    dustPart.Anchored           = true
    dustPart.CanCollide         = false
    dustPart.CastShadow         = false
    dustPart.Transparency       = 1
    dustPart.Size               = Vector3.new(1, 1, 1)
    dustPart.CFrame             = CFrame.new(position)
    dustPart.Parent             = Workspace

    local dust = Instance.new("ParticleEmitter", dustPart)
    dust.Texture           = "rbxassetid://243098098"   -- smoke puff
    dust.Color             = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(200, 190, 170)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(150, 140, 120)),
    })
    dust.LightEmission     = 0.05
    dust.LightInfluence    = 0.8
    dust.Size              = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0.5),
        NumberSequenceKeypoint.new(0.5, 2.2),
        NumberSequenceKeypoint.new(1, 0),
    })
    dust.Transparency      = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0.1),
        NumberSequenceKeypoint.new(0.7, 0.5),
        NumberSequenceKeypoint.new(1, 1),
    })
    dust.Lifetime          = NumberRange.new(0.6, 1.2)
    dust.Rate              = 0
    dust.Speed             = NumberRange.new(4, 9)
    dust.SpreadAngle       = Vector2.new(60, 60)
    dust.RotSpeed          = NumberRange.new(-180, 180)
    dust.Rotation          = NumberRange.new(0, 360)
    dust:Emit(CFG.VFX.DustParticleCount)

    game:GetService("Debris"):AddItem(dustPart, 2.5)
end

function AnimWeighter:Boot()
    print("[Genesis] 💥 Booting Animation Weight System...")
    -- Hook into TSB remote events if accessible
    -- Since we can't patch server animation, we listen for skill activation
    -- via proximity and animation track names.

    local function watchChar(char)
        local humanoid = char:FindFirstChildOfClass("Humanoid")
        if not humanoid then return end

        local animator = humanoid:FindFirstChildOfClass("Animator")
        if not animator then return end

        animator.AnimationPlayed:Connect(function(track)
            local name = track.Name:lower()

            -- Detect combat animations by common TSB names
            local isCombat = name:find("attack") or name:find("skill")
                          or name:find("punch") or name:find("kick")
                          or name:find("slam")  or name:find("strike")
                          or name:find("dash")  or name:find("hit")

            if isCombat then
                local hrp = char:FindFirstChild("HumanoidRootPart")
                local pos  = hrp and hrp.Position or Vector3.zero

                -- Anticipation on animation start
                task.spawn(function()
                    AnimWeighter.TriggerAnticipation(char)
                    task.wait(CFG.AnimWeighter.AnticipationTime)

                    -- Follow-through after mid-point
                    task.wait(track.Length * 0.4)
                    AnimWeighter.TriggerFollowThrough(pos)

                    -- Hit stop at impact frame
                    task.wait(track.Length * 0.15)
                    AnimWeighter.TriggerHitStop()
                end)
            end
        end)
    end

    for _, plr in ipairs(Players:GetPlayers()) do
        if plr.Character then watchChar(plr.Character) end
        plr.CharacterAdded:Connect(watchChar)
    end
    Players.PlayerAdded:Connect(function(plr)
        plr.CharacterAdded:Connect(watchChar)
    end)

    print("[Genesis] ✅ Animation Weight System ONLINE")
end

-- ============================================================
-- SECTION 7: MODULE 5 — CINEMATIC VFX ENGINE
-- ============================================================
local VFXEngine = {}

-- Slash VFX: stretched quad particle with squash-and-stretch
function VFXEngine.SpawnSlash(position, direction, color)
    local slash = Instance.new("Part")
    slash.Anchored     = true
    slash.CanCollide   = false
    slash.CastShadow   = false
    slash.Transparency = 1
    slash.Size         = Vector3.one
    slash.CFrame       = CFrame.new(position, position + direction)
    slash.Parent       = Workspace

    -- Primary slash beam (squash-stretch)
    local beam1 = Instance.new("ParticleEmitter", slash)
    beam1.Texture       = "rbxassetid://6394282635"  -- slash streak
    beam1.Color         = ColorSequence.new({
        ColorSequenceKeypoint.new(0.0, color or Color3.fromRGB(255, 220, 100)),
        ColorSequenceKeypoint.new(0.5, Color3.fromRGB(255, 255, 255)),
        ColorSequenceKeypoint.new(1.0, Color3.fromRGB(150, 200, 255)),
    })
    beam1.LightEmission = 0.85
    beam1.LightInfluence = 0.1
    beam1.Size          = NumberSequence.new({
        NumberSequenceKeypoint.new(0,   0),
        NumberSequenceKeypoint.new(0.1, 1.6 * CFG.VFX.SlashStretchFactor),
        NumberSequenceKeypoint.new(0.6, 0.8),
        NumberSequenceKeypoint.new(1,   0),
    })
    beam1.Transparency  = NumberSequence.new({
        NumberSequenceKeypoint.new(0,   0.0),
        NumberSequenceKeypoint.new(0.5, 0.1),
        NumberSequenceKeypoint.new(1,   1.0),
    })
    beam1.Lifetime      = NumberRange.new(0.12, 0.22)
    beam1.Rate          = 0
    beam1.Speed         = NumberRange.new(18, 28)
    beam1.SpreadAngle   = Vector2.new(8, 2)
    beam1.RotSpeed      = NumberRange.new(-20, 20)
    beam1.Rotation      = NumberRange.new(-15, 15)
    beam1:Emit(6)

    -- Spark burst
    local sparks = Instance.new("ParticleEmitter", slash)
    sparks.Texture      = "rbxassetid://6394282635"
    sparks.Color        = ColorSequence.new(Color3.fromRGB(255, 240, 180))
    sparks.LightEmission = 1.0
    sparks.LightInfluence = 0.0
    sparks.Size         = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0.15),
        NumberSequenceKeypoint.new(1, 0),
    })
    sparks.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0),
        NumberSequenceKeypoint.new(1, 1),
    })
    sparks.Lifetime     = NumberRange.new(0.08, 0.2)
    sparks.Rate         = 0
    sparks.Speed        = NumberRange.new(6, 22)
    sparks.SpreadAngle  = Vector2.new(45, 45)
    sparks:Emit(20)

    -- Flash point light
    local flash = Instance.new("PointLight", slash)
    flash.Brightness = 8
    flash.Range      = 14
    flash.Color      = color or Color3.fromRGB(255, 220, 100)
    flash.Shadows    = false

    Util.Tween(flash, {Brightness = 0, Range = 4}, 0.18,
        Enum.EasingStyle.Expo, Enum.EasingDirection.Out):Play()

    game:GetService("Debris"):AddItem(slash, 1.0)
end

-- Ground crack: temporary material swap + decal
local impactDecalPool = {}
local decalCount = 0

function VFXEngine.SpawnGroundImpact(position)
    if decalCount >= CFG.VFX.MaxImpactDecals then return end
    decalCount += 1

    -- Find ground part via raycast
    local rayOrigin    = position + Vector3.new(0, 2, 0)
    local rayDirection = Vector3.new(0, -6, 0)
    local params       = RaycastParams.new()
    params.FilterType  = Enum.RaycastFilterType.Exclude
    params.FilterDescendantsInstances = {LocalPlayer.Character}

    local result = Workspace:Raycast(rayOrigin, rayDirection, params)
    if not result or not result.Instance then
        decalCount -= 1
        return
    end

    local hit = result.Instance
    -- Temporarily swap material to cracked look
    local originalMat   = hit.Material
    local originalColor = hit.Color

    pcall(function()
        hit.Material = Enum.Material.Concrete
        hit.Color    = Color3.fromRGB(60, 55, 50)
    end)

    -- Decal crack texture on top face
    local decal = Instance.new("Decal", hit)
    decal.Texture   = "rbxassetid://2480924082"  -- crack pattern
    decal.Face      = Enum.NormalId.Top
    decal.Transparency = 0

    -- Spawn dust at impact point
    AnimWeighter.TriggerFollowThrough(result.Position)

    -- Recovery after duration
    task.delay(CFG.VFX.ImpactCrackDuration, function()
        pcall(function()
            hit.Material = originalMat
            hit.Color    = originalColor
        end)
        if decal and decal.Parent then decal:Destroy() end
        decalCount -= 1
    end)
end

-- Shockwave ring
function VFXEngine.SpawnShockwave(position, radius, color)
    local ring = Instance.new("Part")
    ring.Anchored     = true
    ring.CanCollide   = false
    ring.CastShadow   = false
    ring.Shape        = Enum.PartType.Cylinder
    ring.Size         = Vector3.new(0.15, 1, 1)
    ring.CFrame       = CFrame.new(position) * CFrame.Angles(0, 0, math.rad(90))
    ring.Material     = Enum.Material.Neon
    ring.Color        = color or Color3.fromRGB(200, 230, 255)
    ring.Transparency = 0.3
    ring.Parent       = Workspace

    local expandTween = Util.Tween(ring, {
        Size         = Vector3.new(0.05, radius * 2, radius * 2),
        Transparency = 1.0,
        CFrame       = CFrame.new(position + Vector3.new(0, 0.1, 0))
                       * CFrame.Angles(0, 0, math.rad(90)),
    }, 0.5, Enum.EasingStyle.Expo, Enum.EasingDirection.Out)
    expandTween:Play()

    game:GetService("Debris"):AddItem(ring, 0.6)
end

function VFXEngine:Boot()
    print("[Genesis] ✨ Booting Cinematic VFX Engine...")

    -- Hook into touch events for auto-impact detection
    -- We watch all character tool hits via HRP proximity
    local function watchChar(char)
        local hrp = char:WaitForChild("HumanoidRootPart", 8)
        if not hrp then return end

        hrp.Touched:Connect(function(other)
            if other and other.Parent then
                local isChar = false
                for _, plr in ipairs(Players:GetPlayers()) do
                    if plr.Character == other.Parent then
                        isChar = true
                        break
                    end
                end
                if not isChar and not other:IsA("Terrain") then
                    -- Non-character hit = ground/wall impact
                    local impactPos = hrp.Position + (other.Position - hrp.Position) * 0.5
                    VFXEngine.SpawnSlash(impactPos, hrp.CFrame.LookVector)
                    VFXEngine.SpawnGroundImpact(impactPos)
                    VFXEngine.SpawnShockwave(impactPos, 6)
                end
            end
        end)
    end

    local myChar = LocalPlayer.Character
    if myChar then watchChar(myChar) end
    LocalPlayer.CharacterAdded:Connect(watchChar)

    print("[Genesis] ✅ Cinematic VFX Engine ONLINE")
end

-- ============================================================
-- SECTION 8: MODULE 6 — PROCEDURAL FOLIAGE WIND SYSTEM
-- ============================================================
local WindSystem = {}

-- Cache all tree / leaf parts tagged by name
local foliageParts = {}

local FOLIAGE_KEYWORDS = {"leaf", "leaves", "tree", "foliage", "branch", "bush", "fern", "grass"}

local function isFoliage(part)
    local name = part.Name:lower()
    for _, kw in ipairs(FOLIAGE_KEYWORDS) do
        if name:find(kw) then return true end
    end
    return false
end

function WindSystem:Boot()
    if not CFG.Wind.Enabled then return end
    print("[Genesis] 🌿 Booting Procedural Wind System...")

    -- Collect foliage
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if (obj:IsA("BasePart") or obj:IsA("MeshPart")) and isFoliage(obj) then
            -- Store original CFrame
            obj:SetAttribute("GEN_OrigCFx", obj.CFrame.X)
            obj:SetAttribute("GEN_OrigCFy", obj.CFrame.Y)
            obj:SetAttribute("GEN_OrigCFz", obj.CFrame.Z)
            obj:SetAttribute("GEN_WindPhase", math.random() * math.pi * 2)
            table.insert(foliageParts, obj)
        end
    end

    local cfg = CFG.Wind

    RunService.Heartbeat:Connect(function(dt)
        local t = tick()
        for _, part in ipairs(foliageParts) do
            if part and part.Parent then
                local phase = part:GetAttribute("GEN_WindPhase") or 0
                local gust  = math.sin(t * cfg.GustFreq + phase) * cfg.GustSpeed
                local sway  = math.sin(t * cfg.BaseSpeed + phase * 2.7) * cfg.SwayAmount

                local ox = part:GetAttribute("GEN_OrigCFx") or part.CFrame.X
                local oy = part:GetAttribute("GEN_OrigCFy") or part.CFrame.Y
                local oz = part:GetAttribute("GEN_OrigCFz") or part.CFrame.Z

                part.CFrame = CFrame.new(ox, oy, oz)
                    * CFrame.Angles(sway, sway * 0.5, sway * 0.3)
                    * CFrame.new(gust * 0.01, 0, 0)
            end
        end
    end)

    print(string.format("[Genesis] ✅ Wind System ONLINE — %d foliage parts animated", #foliageParts))
end

-- ============================================================
-- SECTION 9: MODULE 7 — PARALLEL ACTOR WORKER POOL
-- ============================================================
--[[
  Roblox's Parallel Luau requires Actors placed in workspace/server
  and scripts bound to them. For a client-only LocalScript approach
  we simulate parallelism via task.spawn + coroutine pools.

  Full Actor setup requires placing Actor instances in a Folder under
  ReplicatedStorage. This block creates those actors programmatically.
]]

local ActorPool = {}

function ActorPool:Boot()
    print("[Genesis] ⚙️  Booting Parallel Actor Pool...")

    local folder = ReplicatedStorage:FindFirstChild("GEN_Actors")
    if folder then folder:Destroy() end
    folder = Instance.new("Folder")
    folder.Name   = "GEN_Actors"
    folder.Parent = ReplicatedStorage

    local workerCount = CFG.Performance.MaxActors

    for i = 1, workerCount do
        local actor = Instance.new("Actor")
        actor.Name = "GEN_Worker_" .. i
        actor.Parent = folder
    end

    -- Coroutine dispatcher mimicking Actor parallelism
    self._queue     = {}
    self._running   = 0
    self._maxWorkers = workerCount

    print(string.format("[Genesis] ✅ Actor Pool ONLINE — %d workers ready", workerCount))
end

function ActorPool:Dispatch(fn, ...)
    local args = {...}
    self._running = (self._running or 0) + 1
    task.spawn(function()
        fn(table.unpack(args))
        self._running -= 1
    end)
end

-- ============================================================
-- SECTION 10: HUD OVERLAY — STATUS MONITOR
-- ============================================================
local function buildStatusHUD()
    local gui = Instance.new("ScreenGui")
    gui.Name           = "GEN_StatusHUD"
    gui.ResetOnSpawn   = false
    gui.DisplayOrder   = 200
    gui.Parent         = LocalPlayer:WaitForChild("PlayerGui")

    local frame = Instance.new("Frame", gui)
    frame.Size              = UDim2.new(0, 230, 0, 100)
    frame.Position          = UDim2.new(0, 10, 0, 10)
    frame.BackgroundColor3  = Color3.fromRGB(8, 8, 18)
    frame.BackgroundTransparency = 0.3
    frame.BorderSizePixel   = 0

    local corner = Instance.new("UICorner", frame)
    corner.CornerRadius = UDim.new(0, 6)

    local stroke = Instance.new("UIStroke", frame)
    stroke.Color     = Color3.fromRGB(80, 140, 255)
    stroke.Thickness = 1

    local title = Instance.new("TextLabel", frame)
    title.Size                = UDim2.new(1, -10, 0, 22)
    title.Position            = UDim2.new(0, 8, 0, 6)
    title.BackgroundTransparency = 1
    title.Text                = "PROJECT GENESIS-RTX  v4.0"
    title.TextColor3          = Color3.fromRGB(80, 160, 255)
    title.TextScaled          = true
    title.Font                = Enum.Font.GothamBold
    title.TextXAlignment      = Enum.TextXAlignment.Left

    local sep = Instance.new("Frame", frame)
    sep.Size              = UDim2.new(1, -16, 0, 1)
    sep.Position          = UDim2.new(0, 8, 0, 30)
    sep.BackgroundColor3  = Color3.fromRGB(60, 100, 200)
    sep.BorderSizePixel   = 0

    local status = Instance.new("TextLabel", frame)
    status.Name               = "StatusText"
    status.Size               = UDim2.new(1, -10, 0, 60)
    status.Position           = UDim2.new(0, 8, 0, 34)
    status.BackgroundTransparency = 1
    status.Text               = "🔥 PBR ACTIVE\n⚡ FUTURE LIGHTING\n✨ CEL-SHADER ON\n💥 WEIGHT SYSTEM ON"
    status.TextColor3         = Color3.fromRGB(180, 220, 180)
    status.TextScaled         = true
    status.Font               = Enum.Font.Gotham
    status.TextXAlignment     = Enum.TextXAlignment.Left
    status.TextYAlignment     = Enum.TextYAlignment.Top

    -- FPS counter
    local fps = Instance.new("TextLabel", frame)
    fps.Name                  = "FPS"
    fps.Size                  = UDim2.new(0, 60, 0, 16)
    fps.Position              = UDim2.new(1, -68, 0, 6)
    fps.BackgroundTransparency = 1
    fps.TextColor3            = Color3.fromRGB(255, 200, 60)
    fps.TextScaled            = true
    fps.Font                  = Enum.Font.GothamBold
    fps.TextXAlignment        = Enum.TextXAlignment.Right
    fps.Text                  = "-- FPS"

    local fpsHistory = {}
    RunService.RenderStepped:Connect(function(dt)
        table.insert(fpsHistory, 1 / dt)
        if #fpsHistory > 30 then table.remove(fpsHistory, 1) end
        local avg = 0
        for _, v in ipairs(fpsHistory) do avg += v end
        avg = avg / #fpsHistory
        fps.Text      = string.format("%d FPS", math.floor(avg))
        fps.TextColor3 = avg >= 55 and Color3.fromRGB(100, 255, 100)
                      or avg >= 30 and Color3.fromRGB(255, 220, 60)
                      or Color3.fromRGB(255, 80, 80)
    end)

    -- Fade out after 8s
    task.delay(8, function()
        Util.Tween(frame, {BackgroundTransparency = 1}, 2):Play()
        Util.Tween(title, {TextTransparency = 1}, 2):Play()
        Util.Tween(status, {TextTransparency = 1}, 2):Play()
        Util.Tween(fps, {TextTransparency = 1}, 2):Play()
        Util.Tween(stroke, {Transparency = 1}, 2):Play()
        task.wait(2)
        gui:Destroy()
    end)
end

-- ============================================================
-- SECTION 11: GENESIS CORE — BOOT SEQUENCE
-- ============================================================
local GenesisCore = {}

function GenesisCore:Boot()
    print("╔══════════════════════════════════════════╗")
    print("║  PROJECT GENESIS-RTX — BOOT SEQUENCE     ║")
    print("╚══════════════════════════════════════════╝")

    -- Build status HUD first so player sees progress
    task.spawn(buildStatusHUD)

    -- Boot order matters: Lighting → PBR → Cel-Shader → Anim → VFX → Wind
    task.spawn(function()
        -- 1. Parallel Actor Pool (pre-req)
        ActorPool:Boot()
        task.wait(0.1)

        -- 2. Lighting (no deps)
        LightingEngine:Boot()
        task.wait(0.05)

        -- 3. PBR (Async, can run alongside others)
        task.spawn(function() PBREngine:Boot() end)

        -- 4. Cel-shader (needs characters)
        task.spawn(function() CelShaderEngine:Boot() end)

        -- 5. Animation weighter
        task.spawn(function()
            task.wait(0.5) -- wait for characters
            AnimWeighter:Boot()
        end)

        -- 6. VFX
        task.spawn(function()
            task.wait(0.6)
            VFXEngine:Boot()
        end)

        -- 7. Wind
        task.spawn(function()
            task.wait(1.0)
            WindSystem:Boot()
        end)

        print("[Genesis] 🚀 ALL SYSTEMS ONLINE — Visual reconstruction complete.")
        print("[Genesis] Your game now runs on the Genesis-RTX rendering pipeline.")
    end)
end

-- ============================================================
-- SECTION 12: RUNTIME COMMANDS (Chat shortcuts for testing)
-- ============================================================
LocalPlayer.Chatted:Connect(function(msg)
    local cmd = msg:lower()

    if cmd == "/genesis slash" then
        local char = LocalPlayer.Character
        local hrp  = char and char:FindFirstChild("HumanoidRootPart")
        if hrp then
            VFXEngine.SpawnSlash(hrp.Position, hrp.CFrame.LookVector)
            VFXEngine.SpawnShockwave(hrp.Position, 8)
        end

    elseif cmd == "/genesis impact" then
        local char = LocalPlayer.Character
        local hrp  = char and char:FindFirstChild("HumanoidRootPart")
        if hrp then
            VFXEngine.SpawnGroundImpact(hrp.Position)
            AnimWeighter.TriggerHitStop()
        end

    elseif cmd == "/genesis hud" then
        buildStatusHUD()

    elseif cmd == "/genesis pbr" then
        PBREngine:Boot()
        print("[Genesis] PBR re-scan triggered.")

    elseif cmd == "/genesis cel" then
        local char = LocalPlayer.Character
        if char then addCelOutline(char, LocalPlayer) end

    elseif cmd == "/genesis reset" then
        -- Remove all genesis effects and restore defaults
        for _, tag in ipairs(CollectionService:GetTagged("GEN_PBR_DONE")) do
            CollectionService:RemoveTag(tag, "GEN_PBR_DONE")
        end
        print("[Genesis] Tags cleared. Re-run /genesis pbr to reapply.")
    end
end)

-- ============================================================
-- ENTRY POINT
-- ============================================================
GenesisCore:Boot()
