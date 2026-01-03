--[[
  GEMINI HUB TSB - VIP STRONG (v3.5)
  - Bản nâng cấp "mạnh hơn, dài, nặng, đầy đủ"
  - Tất cả tính năng client-side trừ phần remote-forging (bị đóng/mặc định tắt)
  - Hướng dẫn: upload file .lua lên GitHub public, lấy raw và load bằng executor có HttpGet
--]]

-- ===== SERVICES =====
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local Lighting = game:GetService("Lighting")
local HttpService = game:GetService("HttpService")
local UserInput = game:GetService("UserInputService")

local LocalPlayer = Players.LocalPlayer

-- Virtual input (may differ per executor)
local ok_vim, VIM = pcall(function() return game:GetService("VirtualInputManager") end)
VIM = ok_vim and VIM or nil

-- ===== UI LIB (Fluent) with fallback =====
local Fluent
do
    local ok, lib = pcall(function()
        return loadstring(game:HttpGet("https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua"))()
    end)
    if ok and lib then
        Fluent = lib
    else
        -- minimal fallback object to avoid nil errors
        Fluent = {}
        function Fluent:Notify(tbl) print("[GeminiNotify] "..(tbl.Title or "")..": "..(tbl.Content or "")) end
        function Fluent:CreateWindow(opts)
            return {
                AddTab = function() return {
                    AddToggle = function() return { OnChanged = function() end } end,
                    AddSlider = function() return { OnChanged = function() end } end,
                    AddButton = function() end,
                    AddDropdown = function() return { OnChanged = function() end } end
                } end
            }
        end
        warn("Fluent load failed — running with fallback UI (limited).")
    end
end

-- SaveManager optional
local SaveManager
pcall(function()
    SaveManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/SaveManager.lua"))()
end)

-- ===== SETTINGS =====
local Settings = {
    Version = "3.5-STRONG",
    CombatMaster = false,

    -- Aim
    AimAssist = false,
    AimSmoothing = 8,
    AimPredict = true,          -- dự đoán theo velocity
    AimProjectileSpeed = 120,   -- approximate projectile speed (tweak per game)
    AimMaxAngle = 90,           -- degrees

    -- Target lock
    TargetLock = false,
    LockPriority = "closest",   -- "closest" or "lowhp" or "fov"

    -- Swing
    AutoSwing = false,
    AutoSwingInterval = 0.18,
    AutoSwingJitter = 0.06,

    -- Reach
    ReachEnabled = false,
    ReachDistance = 16,
    LegacyReach = false,        -- risky (resize HRP)
    LegacyReachSize = 14,
    AggressiveLegacy = false,   -- attempt restore & respawn enforcement

    -- Block
    AutoBlock = false,
    AutoBlockRange = 14,
    AutoBlockVelThreshold = 7,
    BlockCooldown = 0.12,

    -- ESP
    ESP = false,
    ESP_Distance = 150,

    -- Anti-detect
    Randomize = true,
    Jitter = 0.015,

    -- Performance
    LoopInterval = 0.09, -- base loop
}

-- ===== UTIL FUNCTIONS =====
local function rand(a,b) return a + math.random()*(b-a) end
local function clamp(x,a,b) if x<a then return a elseif x>b then return b else return x end end
local function safeCall(fn,...) local ok,res = pcall(fn,...) if not ok then warn(res) end return ok,res end

local function notify(title,content,sec)
    pcall(function() Fluent:Notify({Title = title or "Gemini", Content = content or "", Duration = sec or 4}) end)
end

-- ===== WINDOW & TABS =====
local Window = Fluent:CreateWindow({
    Title = "Gemini VIP | TSB - STRONG",
    SubTitle = "v3.5 Strong Edition",
    Size = UDim2.fromOffset(720, 620),
    Acrylic = true,
    Theme = "Dark",
    MinimizeKey = Enum.KeyCode.RightControl
})

local Tabs = {
    Combat = Window:AddTab({Title="Combat", Icon="swords"}),
    Visual = Window:AddTab({Title="Visual", Icon="eye"}),
    Optimize = Window:AddTab({Title="Optimize", Icon="cpu"}),
    Misc = Window:AddTab({Title="Misc", Icon="settings"})
}

-- ===== FLOATING BUTTON (PlayerGui safe) =====
do
    local pg = LocalPlayer:WaitForChild("PlayerGui")
    local sg = Instance.new("ScreenGui")
    sg.Name = "GeminiVIP_Float"
    sg.ResetOnSpawn = false
    sg.Parent = pg

    local btn = Instance.new("TextButton")
    btn.Size = UDim2.fromOffset(50,50)
    btn.Position = UDim2.fromScale(0.02,0.5)
    btn.AnchorPoint = Vector2.new(0,0.5)
    btn.Text = "G"
    btn.Font = Enum.Font.GothamBold
    btn.TextScaled = true
    btn.BackgroundColor3 = Color3.fromRGB(120,30,255)
    btn.TextColor3 = Color3.new(1,1,1)
    btn.Parent = sg
    local uic = Instance.new("UICorner", btn)
    uic.CornerRadius = UDim.new(1,0)

    local visible = true
    btn.MouseButton1Click:Connect(function()
        visible = not visible
        pcall(function()
            if Fluent.SetVisibility then Fluent:SetVisibility(visible) else notify("Gemini", "UI toggled: "..tostring(visible)) end
        end)
    end)
end

-- ===== BUILD UI CONTROLS (bind to Settings) =====
Tabs.Combat:AddToggle("CombatMaster",{Title="Combat Master", Default = Settings.CombatMaster})
:OnChanged(function(v) Settings.CombatMaster = v end)

Tabs.Combat:AddToggle("AimAssist",{Title="Aim Assist (safe)", Default = Settings.AimAssist})
:OnChanged(function(v) Settings.AimAssist = v end)
Tabs.Combat:AddSlider("AimSmooth",{Title="Aim Smoothing", Default = Settings.AimSmoothing, Min=1,Max=30,Rounding=1})
:OnChanged(function(v) Settings.AimSmoothing = v end)
Tabs.Combat:AddToggle("AimPredict",{Title="Predict Target (velocity)", Default = Settings.AimPredict})
:OnChanged(function(v) Settings.AimPredict = v end)
Tabs.Combat:AddSlider("ProjectileSpeed",{Title="Projectile Speed (est.)", Default = Settings.AimProjectileSpeed, Min=30,Max=1000})
:OnChanged(function(v) Settings.AimProjectileSpeed = v end)

Tabs.Combat:AddToggle("TargetLock",{Title="Target Lock (follow)", Default = Settings.TargetLock})
:OnChanged(function(v) Settings.TargetLock = v end)
Tabs.Combat:AddDropdown("LockPriority",{Title="Lock Priority", Default = Settings.LockPriority, Options = {"closest","lowhp","fov"}})
:OnChanged(function(v) Settings.LockPriority = v end)

Tabs.Combat:AddToggle("AutoSwing",{Title="Auto Swing (humanized)", Default = Settings.AutoSwing})
:OnChanged(function(v) Settings.AutoSwing = v end)
Tabs.Combat:AddSlider("SwingInterval",{Title="Swing Interval", Default=Settings.AutoSwingInterval, Min=0.06, Max=0.6, Rounding=2})
:OnChanged(function(v) Settings.AutoSwingInterval = v end)
Tabs.Combat:AddSlider("SwingJitter",{Title="Swing Jitter", Default=Settings.AutoSwingJitter, Min=0, Max=0.2, Rounding=3})
:OnChanged(function(v) Settings.AutoSwingJitter = v end)

Tabs.Combat:AddToggle("Reach",{Title="Reach Assist (client-side)", Default = Settings.ReachEnabled})
:OnChanged(function(v) Settings.ReachEnabled = v end)
Tabs.Combat:AddSlider("ReachDist",{Title="Reach Distance", Default=Settings.ReachDistance, Min=6, Max=40, Rounding=1})
:OnChanged(function(v) Settings.ReachDistance = v end)
Tabs.Combat:AddToggle("LegacyReach",{Title="Legacy Reach (resize HRP) [RISKY]", Default = Settings.LegacyReach})
:OnChanged(function(v) Settings.LegacyReach = v end)
Tabs.Combat:AddSlider("LegacySize",{Title="Legacy HRP Size", Default=Settings.LegacyReachSize, Min=2, Max=40, Rounding=1})
:OnChanged(function(v) Settings.LegacyReachSize = v end)
Tabs.Combat:AddToggle("AggressiveLegacy",{Title="Aggressive Legacy Restore", Default = Settings.AggressiveLegacy})
:OnChanged(function(v) Settings.AggressiveLegacy = v end)

Tabs.Combat:AddToggle("AutoBlock",{Title="Smart Auto Block", Default=Settings.AutoBlock})
:OnChanged(function(v) Settings.AutoBlock = v end)
Tabs.Combat:AddSlider("BlockRange",{Title="Auto Block Range", Default=Settings.AutoBlockRange, Min=4, Max=30})
:OnChanged(function(v) Settings.AutoBlockRange = v end)
Tabs.Combat:AddSlider("BlockVel",{Title="Block Vel Threshold", Default=Settings.AutoBlockVelThreshold, Min=1, Max=40})
:OnChanged(function(v) Settings.AutoBlockVelThreshold = v end)

-- Visual
Tabs.Visual:AddToggle("ESP",{Title="ESP (Highlight+Billboard)", Default = Settings.ESP})
:OnChanged(function(v) Settings.ESP = v end)
Tabs.Visual:AddSlider("ESPRange",{Title="ESP Range", Default=Settings.ESP_Distance, Min=20, Max=500})
:OnChanged(function(v) Settings.ESP_Distance = v end)

-- Optimize / Misc
Tabs.Optimize:AddButton({Title="Apply Selective Lag Fix (chunked)", Description="Safe & chunked", Callback = function()
    if Settings.LagFixApplied then notify("Gemini","Lag fix already applied") return end
    Settings.LagFixApplied = true
    notify("Gemini","Applying Lag Fix...",3)
    spawn(function()
        local list = {}
        for _,v in ipairs(Workspace:GetDescendants()) do
            if v:IsA("ParticleEmitter") or v:IsA("Trail") or v:IsA("Beam") then
                table.insert(list, {t="p", o=v})
            elseif v:IsA("Decal") or v:IsA("Texture") then
                table.insert(list,{t="d", o=v})
            end
            if #list >= 800 then break end
        end
        for i,info in ipairs(list) do
            pcall(function()
                if info.t == "p" and info.o:IsA("ParticleEmitter") then
                    info.o.Rate = math.max(1, (info.o.Rate or 12)/6)
                    info.o.Lifetime = NumberRange.new(0.04,0.08)
                elseif info.t == "p" and (info.o:IsA("Trail") or info.o:IsA("Beam")) then
                    info.o.Enabled = false
                elseif info.t == "d" then
                    info.o:Destroy()
                end
            end)
            if i % 60 == 0 then task.wait(0.04) end
        end
        pcall(function() Lighting.GlobalShadows=false Lighting.ExposureCompensation=0.45 end)
        notify("Gemini","Lag Fix Complete",4)
    end)
end})

if SaveManager then
    pcall(function()
        SaveManager:SetLibrary(Fluent)
        SaveManager:BuildConfigSection(Tabs.Misc)
    end)
else
    Tabs.Misc:AddButton({Title="SaveManager Unavailable (HttpGet blocked)"})
end

-- ===== TARGET / UTILITIES =====
local function getHumanoid(p)
    if not p or not p.Character then return nil end
    return p.Character:FindFirstChildOfClass("Humanoid")
end

local function getHRP(p)
    if not p or not p.Character then return nil end
    return p.Character:FindFirstChild("HumanoidRootPart")
end

local function getPlayersInRange(range)
    local out = {}
    if not LocalPlayer.Character or not getHRP(LocalPlayer) then return out end
    local myPos = getHRP(LocalPlayer).Position
    for _,p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and p.Character and getHRP(p) then
            local d = (getHRP(p).Position - myPos).Magnitude
            if d <= (range or 9999) then table.insert(out, {player=p,dist=d}) end
        end
    end
    return out
end

local function chooseTarget(range, priority)
    local candidates = getPlayersInRange(range)
    if #candidates == 0 then return nil, nil end
    if priority == "lowhp" then
        local best, bestHP, bestDist = nil, math.huge, math.huge
        for _,c in ipairs(candidates) do
            local hum = getHumanoid(c.player)
            local hp = hum and hum.Health or math.huge
            if hp < bestHP then bestHP = hp best = c.player bestDist = c.dist end
        end
        return best, bestDist
    elseif priority == "fov" then
        -- choose by view angle (best effort)
        local cam = workspace.CurrentCamera
        local best, bestAngle, bestDist = nil, math.huge, math.huge
        for _,c in ipairs(candidates) do
            local dir = (getHRP(c.player).Position - cam.CFrame.Position).Unit
            local forward = cam.CFrame.LookVector
            local angle = math.deg(math.acos(clamp(forward:Dot(dir), -1, 1)))
            if angle < Settings.AimMaxAngle and angle < bestAngle then best = c.player bestAngle=angle bestDist=c.dist end
        end
        return best, bestDist
    else
        -- closest
        table.sort(candidates, function(a,b) return a.dist < b.dist end)
        return candidates[1].player, candidates[1].dist
    end
end

-- Predictive aim: estimate where target will be after travel time
local function predictPosition(targetHRP, projectileSpeed, originPos)
    if not targetHRP then return nil end
    local vel = targetHRP.Velocity or Vector3.new()
    local relative = targetHRP.Position - originPos
    local distance = relative.Magnitude
    local travelTime = projectileSpeed > 1 and (distance / projectileSpeed) or 0
    return targetHRP.Position + vel * travelTime
end

-- Smoothly aim camera to look at position (local only)
spawn(function()
    local cam = workspace.CurrentCamera
    while true do
        if Settings.CombatMaster and Settings.AimAssist and cam and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
            local origin = cam.CFrame.Position
            local targetPlayer, dist = chooseTarget(Settings.ReachDistance or 20, Settings.LockPriority)
            local chosen = (Settings.TargetLock and targetPlayer) and targetPlayer or targetPlayer
            if chosen and chosen.Character and chosen.Character:FindFirstChild("HumanoidRootPart") then
                local targetHRP = chosen.Character.HumanoidRootPart
                local aimPos = (Settings.AimPredict and predictPosition(targetHRP, Settings.AimProjectileSpeed, origin)) or (targetHRP.Position + Vector3.new(0,1.5,0))
                if aimPos then
                    local desired = CFrame.new(origin, aimPos)
                    -- apply jitter for anti-detect
                    local jitter = Settings.Randomize and rand(-Settings.Jitter, Settings.Jitter) or 0
                    desired = desired * CFrame.Angles(jitter, jitter, 0)
                    local smooth = clamp(Settings.AimSmoothing,1,60)
                    cam.CFrame = cam.CFrame:Lerp(desired, 1/smooth)
                end
            end
        end
        task.wait(0.011)
    end
end)

-- ===== AUTO SWING (humanized) =====
spawn(function()
    while true do
        if Settings.CombatMaster and Settings.AutoSwing then
            local target, dist = chooseTarget(Settings.ReachDistance or 16, Settings.LockPriority)
            if target and dist and dist <= (Settings.ReachDistance or 16) then
                pcall(function()
                    -- center screen click
                    local cam = workspace.CurrentCamera
                    local cx, cy = cam.ViewportSize.X/2, cam.ViewportSize.Y/2
                    if VIM and VIM.SendMouseButtonEvent then
                        VIM:SendMouseButtonEvent(cx, cy, 0, true, game, 0)
                        task.wait(0.03)
                        VIM:SendMouseButtonEvent(cx, cy, 0, false, game, 0)
                    else
                        local vu = game:GetService("VirtualUser")
                        vu:CaptureController()
                        vu:ClickButton1(Vector2.new(0,0))
                    end
                end)
                -- interval with jitter
                local base = clamp(Settings.AutoSwingInterval, 0.04, 1)
                local jitter = Settings.AutoSwingJitter and rand(-Settings.AutoSwingJitter, Settings.AutoSwingJitter) or 0
                local waitT = base + jitter
                if Settings.Randomize then waitT = waitT + rand(-0.03, 0.03) end
                task.wait(clamp(waitT, 0.03, 2))
            else
                task.wait(0.06)
            end
        else
            task.wait(0.12)
        end
    end
end)

-- ===== LEGACY REACH with restore (best-effort) =====
local modifiedHRPs = {}
local function applyLegacyToPlayer(p)
    if not p or not p.Character then return end
    local hrp = p.Character:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    if not modifiedHRPs[p.UserId] then
        modifiedHRPs[p.UserId] = {origSize = hrp.Size, origTransparency = hrp.Transparency, origCanCollide = hrp.CanCollide}
    end
    pcall(function()
        hrp.Size = Vector3.new(Settings.LegacyReachSize, Settings.LegacyReachSize, Settings.LegacyReachSize)
        hrp.CanCollide = false
        hrp.Transparency = 0.8
    end)
end

local function restoreLegacyForPlayer(p)
    if not p or not p.Character then return end
    local hrp = p.Character:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    local info = modifiedHRPs[p.UserId]
    if info then
        pcall(function()
            hrp.Size = info.origSize or hrp.Size
            hrp.Transparency = info.origTransparency or hrp.Transparency
            hrp.CanCollide = info.origCanCollide or hrp.CanCollide
        end)
        modifiedHRPs[p.UserId] = nil
    end
end

-- apply / restore loop
spawn(function()
    while true do
        if Settings.CombatMaster and Settings.ReachEnabled and Settings.LegacyReach then
            for _,p in ipairs(Players:GetPlayers()) do
                if p ~= LocalPlayer and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
                    applyLegacyToPlayer(p)
                end
            end
        else
            -- try restore best-effort
            for _,p in ipairs(Players:GetPlayers()) do
                if p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
                    restoreLegacyForPlayer(p)
                end
            end
        end
        if Settings.AggressiveLegacy and Settings.LegacyReach then
            -- attempt restore on respawn listener
            Players.PlayerAdded:Connect(function(pl) pcall(function() pl.CharacterAdded:Connect(function() if Settings.LegacyReach then applyLegacyToPlayer(pl) end end) end) end)
        end
        task.wait(0.5)
    end
end)

-- ===== SMART AUTO BLOCK (velocity + distance + simple animation heuristic) =====
spawn(function()
    local isBlocking = false
    while true do
        if Settings.CombatMaster and Settings.AutoBlock then
            local target, dist = chooseTarget(Settings.AutoBlockRange, Settings.LockPriority)
            if target and dist and dist <= Settings.AutoBlockRange then
                local hrp = getHRP(target)
                local vel = hrp and hrp.Velocity.Magnitude or 0
                -- heuristics: moving fast or lunging => likely attacking
                if vel >= Settings.AutoBlockVelThreshold then
                    if not isBlocking then
                        pcall(function() if VIM then VIM:SendKeyEvent(true, Enum.KeyCode.F, false, game) else game:GetService("VirtualUser"):CaptureController() end end)
                        isBlocking = true
                    end
                else
                    if isBlocking then
                        pcall(function() if VIM then VIM:SendKeyEvent(false, Enum.KeyCode.F, false, game) else game:GetService("VirtualUser") end end)
                        isBlocking = false
                    end
                end
            else
                if isBlocking then
                    pcall(function() if VIM then VIM:SendKeyEvent(false, Enum.KeyCode.F, false, game) end end)
                    isBlocking = false
                end
            end
        else
            -- ensure off
            pcall(function() if VIM then VIM:SendKeyEvent(false, Enum.KeyCode.F, false, game) end end)
        end
        task.wait(Settings.BlockCooldown or 0.12)
    end
end)

-- ===== ADVANCED ESP (Highlight + Billboard + Tracer) =====
do
    local function buildBillboard(p)
        if not p or not p.Character then return end
        local name = "GeminiVIP_BB"
        if p.Character:FindFirstChild(name) then return end
        pcall(function()
            local bb = Instance.new("BillboardGui")
            bb.Name = name
            bb.Size = UDim2.new(0,140,0,44)
            bb.StudsOffset = Vector3.new(0,2.5,0)
            bb.AlwaysOnTop = true
            bb.Parent = p.Character

            local frame = Instance.new("Frame", bb)
            frame.Size = UDim2.fromScale(1,1)
         frame.BackgroundTransparency = 0.4
            frame.BackgroundColor3 = Color3.fromRGB(0,0,0)

            local t1 = Instance.new("TextLabel", frame)
            t1.Size = UDim2.new(1,0,0.5,0)
            t1.Position = UDim2.new(0,0,0,0)
            t1.BackgroundTransparency = 1
            t1.Text = p.Name
            t1.TextScaled = true
            t1.Font = Enum.Font.GothamBold
            t1.TextColor3 = Color3.fromRGB(255,255,255)

            local t2 = Instance.new("TextLabel", frame)
            t2.Size = UDim2.new(1,0,0.5,0)
            t2.Position = UDim2.new(0,0,0.5,0)
            t2.BackgroundTransparency = 1
            t2.Text = ""
            t2.TextScaled = true
            t2.Font = Enum.Font.Gotham
            t2.TextColor3 = Color3.fromRGB(200,200,200)
            t2.Name = "InfoLabel"
        end)
    end

    spawn(function()
        while true do
            if Settings.ESP then
                for _,p in ipairs(Players:GetPlayers()) do
                    if p ~= LocalPlayer and p.Character and getHRP(p) then
                        -- highlight
                        if not p.Character:FindFirstChild("GeminiVIP_HL") then
                            pcall(function()
                                local h = Instance.new("Highlight")
                                h.Name = "GeminiVIP_HL"
                                h.FillColor = Color3.fromRGB(255,80,80)
                                h.OutlineColor = Color3.fromRGB(255,255,255)
                                h.Adornee = p.Character
                                h.Parent = p.Character
                            end)
                        end
                        -- billboard
                        if not p.Character:FindFirstChild("GeminiVIP_BB") then buildBillboard(p) end
                        local bb = p.Character:FindFirstChild("GeminiVIP_BB")
                        if bb then
                            local info = bb:FindFirstChild("InfoLabel", true) or bb:FindFirstChildWhichIsA("TextLabel", true)
                            if info and LocalPlayer.Character and getHRP(LocalPlayer) and getHRP(p) then
                                local d = (getHRP(LocalPlayer).Position - getHRP(p).Position).Magnitude
                                info.Text = string.format("%.1fm", d)
                            end
                        end
                        -- tracer (line) optional: create a Beam or Drawing (Drawing may not be available)
                    else
                        -- clean up
                        if p.Character then
                            pcall(function()
                                local hl = p.Character:FindFirstChild("GeminiVIP_HL")
                                if hl then hl:Destroy() end
                                local bb = p.Character:FindFirstChild("GeminiVIP_BB")
                                if bb then bb:Destroy() end
                            end)
                        end
                    end
                end
            else
                -- remove any existing created guis/highlights to be tidy
                for _,p in ipairs(Players:GetPlayers()) do
                    if p.Character then
                        pcall(function()
                            local hl = p.Character:FindFirstChild("GeminiVIP_HL")
                            if hl then hl:Destroy() end
                            local bb = p.Character:FindFirstChild("GeminiVIP_BB")
                            if bb then bb:Destroy() end
                        end)
                    end
                end
            end
            task.wait(1.1)
        end
    end)
end

-- ===== CLEANUP ON LEAVE / RESPAWN =====
Players.PlayerRemoving:Connect(function(p) pcall(function() modifiedHRPs[p.UserId] = nil end) end)
LocalPlayer.CharacterAdded:Connect(function(char)
    -- restore/hook as needed after respawn
    wait(1)
    if Settings.LegacyReach then
        -- apply to players again in main loop will handle
    end
end)

-- ===== INIT =====
notify("GEMINI VIP", "Loaded STRONG v3.5", 5)
print("GEMINI VIP STRONG v3.5 loaded")

-- End of file
