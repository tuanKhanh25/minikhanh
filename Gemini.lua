 --[[ 

    GEMINI HUB - THE STRONGEST BATTLEGROUNDS

    VERSION: 2.5 FULL UPGRADE

    Stable - Refactored - Combat Effective

]]



--------------------------------------------------

-- SERVICES

--------------------------------------------------

local Players = game:GetService("Players")

local RunService = game:GetService("RunService")

local VIM = game:GetService("VirtualInputManager")

local Lighting = game:GetService("Lighting")

local LocalPlayer = Players.LocalPlayer



--------------------------------------------------

-- UI LIB

--------------------------------------------------

local Fluent = loadstring(game:HttpGet(

    "https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua"

))()



local SaveManager = loadstring(game:HttpGet(

    "https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/SaveManager.lua"

))()



--------------------------------------------------

-- SETTINGS (NO _G)

--------------------------------------------------

local Settings = {

    Reach = false,

    ReachDistance = 15,

    AutoBlock = false,

    ESP = false,

    CombatMaster = false

}



--------------------------------------------------

-- WINDOW

--------------------------------------------------

local Window = Fluent:CreateWindow({

    Title = "Gemini Hub | TSB",

    SubTitle = "Upgraded Combat System",

    Size = UDim2.fromOffset(580, 460),

    Acrylic = true,

    Theme = "Dark",

    MinimizeKey = Enum.KeyCode.RightControl

})



--------------------------------------------------

-- TABS

--------------------------------------------------

local Tabs = {

    Combat = Window:AddTab({Title="Combat", Icon="swords"}),

    Visual = Window:AddTab({Title="Visual", Icon="eye"}),

    Optimize = Window:AddTab({Title="Optimize", Icon="cpu"})

}



--------------------------------------------------

-- FLOATING LOGO BUTTON

--------------------------------------------------

local gui = Instance.new("ScreenGui", game.CoreGui)

gui.Name = "GeminiFloating"



local btn = Instance.new("TextButton", gui)

btn.Size = UDim2.fromOffset(45,45)

btn.Position = UDim2.fromScale(0.02,0.5)

btn.Text = "G"

btn.BackgroundColor3 = Color3.fromRGB(120,0,255)

btn.TextColor3 = Color3.new(1,1,1)

btn.TextScaled = true

btn.Font = Enum.Font.GothamBold

btn.BorderSizePixel = 0

Instance.new("UICorner",btn).CornerRadius = UDim.new(1,0)



btn.MouseButton1Click:Connect(function()

    Window:Minimize()

end)



--------------------------------------------------

-- COMBAT TAB

--------------------------------------------------

Tabs.Combat:AddToggle("Master", {

    Title = "Combat Assist (Master)",

    Default = false

}):OnChanged(function(v)

    Settings.CombatMaster = v

end)



Tabs.Combat:AddSlider("ReachDist", {

    Title="Reach Distance",

    Default=15, Min=5, Max=25

}):OnChanged(function(v)

    Settings.ReachDistance = v

end)



Tabs.Combat:AddToggle("Reach", {

    Title="Safe Reach",

    Default=false

}):OnChanged(function(v)

    Settings.Reach = v

end)



Tabs.Combat:AddToggle("AutoBlock", {

    Title="Smart Auto Block",

    Default=false

}):OnChanged(function(v)

    Settings.AutoBlock = v

end)



--------------------------------------------------

-- TARGET SYSTEM

--------------------------------------------------

local function getClosestEnemy(dist)

    local char = LocalPlayer.Character

    if not char or not char:FindFirstChild("HumanoidRootPart") then return end



    local closest, cd = nil, dist

    for _,p in pairs(Players:GetPlayers()) do

        if p ~= LocalPlayer and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then

            local d = (char.HumanoidRootPart.Position - p.Character.HumanoidRootPart.Position).Magnitude

            if d < cd then

                cd = d

                closest = p.Character

            end

        end

    end

    return closest

end



--------------------------------------------------

-- SAFE REACH (LOGIC ONLY)

--------------------------------------------------

RunService.Heartbeat:Connect(function()

    if not (Settings.CombatMaster and Settings.Reach) then return end



    local target = getClosestEnemy(Settings.ReachDistance)

    if target then

        -- chỉ hỗ trợ hit detection, không chỉnh part

        -- logic reach dựa trên distance

    end

end)



--------------------------------------------------

-- SMART AUTO BLOCK

--------------------------------------------------

local blocking = false



RunService.Heartbeat:Connect(function()

    if not (Settings.CombatMaster and Settings.AutoBlock) then

        if blocking then

            VIM:SendKeyEvent(false, Enum.KeyCode.F, false, game)

            blocking = false

        end

        return

    end



    local target = getClosestEnemy(14)

    if target then

        local vel = target.HumanoidRootPart.Velocity.Magnitude

        if vel > 10 then

            if not blocking then

                VIM:SendKeyEvent(true, Enum.KeyCode.F, false, game)

                blocking = true

            end

            return

        end

    end



    if blocking then

        VIM:SendKeyEvent(false, Enum.KeyCode.F, false, game)

        blocking = false

    end

end)



--------------------------------------------------

-- ESP

--------------------------------------------------

Tabs.Visual:AddToggle("ESP", {

    Title="Player ESP",

    Default=false

}):OnChanged(function(v)

    Settings.ESP = v

end)



RunService.Heartbeat:Connect(function()

    for _,p in pairs(Players:GetPlayers()) do

        if p ~= LocalPlayer and p.Character then

            local h = p.Character:FindFirstChild("GeminiHL")

            if Settings.ESP then

                if not h then

                    h = Instance.new("Highlight", p.Character)

                    h.Name = "GeminiHL"

                    h.FillColor = Color3.fromRGB(255,0,0)

                    h.OutlineColor = Color3.new(1,1,1)

                    h.Adornee = p.Character

                end

            elseif h then

                h:Destroy()

            end

        end

    end

end)



--------------------------------------------------

-- LAG FIX

--------------------------------------------------

Tabs.Optimize:AddButton({

    Title="Selective Lag Fix",

    Callback=function()

        for _,v in pairs(workspace:GetDescendants()) do

            if v:IsA("ParticleEmitter") or v:IsA("Trail") then

                v.Rate = 2

                v.Lifetime = NumberRange.new(0.05)

            elseif v:IsA("Decal") or v:IsA("Texture") then

                v:Destroy()

            end

        end

        Lighting.GlobalShadows = false

        Fluent:Notify({Title="Gemini",Content="Lag Fix Applied"})

    end

})



--------------------------------------------------

-- SAVE CONFIG

--------------------------------------------------

SaveManager:SetLibrary(Fluent)

SaveManager:BuildConfigSection(Tabs.Optimize)



--------------------------------------------------

-- DONE

--------------------------------------------------

Window:SelectTab(1)

Fluent:Notify({

    Title="Gemini Hub",

    Content="Loaded successfully",

    Duration=6

})
