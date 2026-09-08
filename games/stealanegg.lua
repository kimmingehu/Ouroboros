-- Steal an Egg - Direct CFrame Movement (Bypasses all speed limits)
-- Walk and Fly both use CFrame manipulation. Game cannot override.

local player = game.Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid")
local root = character:WaitForChild("HumanoidRootPart")
local mouse = player:GetMouse()
local runService = game:GetService("RunService")
local userInputService = game:GetService("UserInputService")
local camera = workspace.CurrentCamera

-- Multipliers
local walkMult = 1
local flyMult = 1
local flying = false

-- Base speeds (units per second)
local BASE_WALK = 20
local BASE_FLY = 50

-- WASD + Space/Shift
local keys = {W=false, S=false, A=false, D=false, Space=false, Shift=false}

-- Godmode
local function godmode(char)
    local h = char:FindFirstChild("Humanoid")
    if h then
        h.MaxHealth = math.huge
        h.Health = math.huge
        h.BreakJointsOnDeath = false
    end
end
godmode(character)
player.CharacterAdded:Connect(function(char)
    character = char
    humanoid = char:WaitForChild("Humanoid")
    root = char:WaitForChild("HumanoidRootPart")
    godmode(char)
end)

-- Fly toggle
local function toggleFly()
    flying = not flying
    -- Update UI button
    local btn = player.PlayerGui:FindFirstChild("EggStealUI") and 
                player.PlayerGui.EggStealUI:FindFirstChild("MainFrame") and
                player.PlayerGui.EggStealUI.MainFrame:FindFirstChild("FlyToggle")
    if btn then
        btn.Text = flying and "Fly ON" or "Fly OFF"
        btn.BackgroundColor3 = flying and Color3.new(0.2, 0.5, 0.2) or Color3.new(0.3, 0.3, 0.3)
    end
end

-- Key tracking
local function onKey(input, state)
    if input.UserInputType ~= Enum.UserInputType.Keyboard then return end
    local k = input.KeyCode
    if k == Enum.KeyCode.W then keys.W = state end
    if k == Enum.KeyCode.S then keys.S = state end
    if k == Enum.KeyCode.A then keys.A = state end
    if k == Enum.KeyCode.D then keys.D = state end
    if k == Enum.KeyCode.Space then keys.Space = state end
    if k == Enum.KeyCode.LeftShift then keys.Shift = state end
end
userInputService.InputBegan:Connect(function(i) onKey(i, true) end)
userInputService.InputEnded:Connect(function(i) onKey(i, false) end)

-- Main movement loop (CFrame based)
runService.Heartbeat:Connect(function(deltaTime)
    if not character or not root or not humanoid then return end

    -- 1. Walking (only when not flying)
    if not flying then
        local cf = camera.CFrame
        local forward = cf.LookVector
        local right = cf.RightVector
        forward = Vector3.new(forward.X, 0, forward.Z).Unit
        right = Vector3.new(right.X, 0, right.Z).Unit

        local move = Vector3.new(0, 0, 0)
        if keys.W then move = move + forward end
        if keys.S then move = move - forward end
        if keys.A then move = move - right end
        if keys.D then move = move + right end

        if move.Magnitude > 0.01 then
            local speed = BASE_WALK * walkMult
            local step = move.Unit * speed * deltaTime
            root.CFrame = root.CFrame + step
            -- Keep character upright
            root.CFrame = CFrame.new(root.Position, root.Position + forward)
        end
    end

    -- 2. Flying (when enabled)
    if flying then
        local cf = camera.CFrame
        local forward = cf.LookVector
        local right = cf.RightVector
        local up = cf.UpVector
        forward = Vector3.new(forward.X, 0, forward.Z).Unit
        right = Vector3.new(right.X, 0, right.Z).Unit

        local move = Vector3.new(0, 0, 0)
        if keys.W then move = move + forward end
        if keys.S then move = move - forward end
        if keys.A then move = move - right end
        if keys.D then move = move + right end
        if keys.Space then move = move + up end
        if keys.Shift then move = move - up end

        if move.Magnitude > 0.01 then
            local speed = BASE_FLY * flyMult
            local step = move.Unit * speed * deltaTime
            root.CFrame = root.CFrame + step
        end
    end
end)

-- F key toggle fly
mouse.KeyDown:Connect(function(k)
    if k:lower() == "f" then toggleFly() end
end)

-- Auto Steal (big eggs first)
local function getEggs()
    local eggs = {}
    for _, obj in pairs(workspace:GetDescendants()) do
        if obj.Name:find("Egg") and obj:IsA("BasePart") then
            local size = obj.Size.X * obj.Size.Y * obj.Size.Z
            table.insert(eggs, {obj = obj, size = size})
        end
    end
    table.sort(eggs, function(a, b) return a.size > b.size end)
    return eggs
end

local function stealEgg(egg)
    if not egg then return end
    local remote = game:GetService("ReplicatedStorage"):FindFirstChild("StealEgg")
    if remote then remote:FireServer(egg) return end
    local cd = egg:FindFirstChildOfClass("ClickDetector")
    if cd then cd:Click() return end
    local pp = egg:FindFirstChildOfClass("ProximityPrompt")
    if pp then
        pp:InputHoldStart(player)
        wait(0.1)
        pp:InputHoldEnd(player)
    end
end

spawn(function()
    while true do
        local eggs = getEggs()
        if #eggs > 0 then stealEgg(eggs[1].obj) end
        wait(0.5)
    end
end)

-- Auto Hatch
local function hatchEgg(egg)
    if not egg then return end
    local remote = game:GetService("ReplicatedStorage"):FindFirstChild("HatchEgg")
    if remote then remote:FireServer(egg) return end
    local pp = egg:FindFirstChildOfClass("ProximityPrompt")
    if pp then
        pp:InputHoldStart(player)
        wait(0.1)
        pp:InputHoldEnd(player)
    end
end

spawn(function()
    while true do
        local inv = player:FindFirstChild("Inventory") or player.PlayerGui:FindFirstChild("Inventory")
        if inv then
            for _, item in pairs(inv:GetChildren()) do
                if item.Name:find("Egg") then hatchEgg(item) end
            end
        end
        wait(1)
    end
end)

-- -----------------------------------------------------------------
-- UI (unchanged, sliders control multipliers)
-- -----------------------------------------------------------------
local gui = Instance.new("ScreenGui")
gui.Name = "EggStealUI"
gui.Parent = player.PlayerGui
gui.ResetOnSpawn = false

local frame = Instance.new("Frame")
frame.Size = UDim2.new(0, 350, 0, 200)
frame.Position = UDim2.new(0, 20, 0, 20)
frame.BackgroundColor3 = Color3.new(0.05, 0.05, 0.05)
frame.BackgroundTransparency = 0.2
frame.BorderSizePixel = 0
frame.ClipsDescendants = true
frame.Parent = gui

local stroke = Instance.new("UIStroke")
stroke.Color = Color3.new(0.5, 1, 0.5)
stroke.Thickness = 2
stroke.Transparency = 0.1
stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
stroke.Parent = frame

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 8)
corner.Parent = frame

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, 0, 0, 24)
title.Position = UDim2.new(0, 0, 0, 0)
title.BackgroundTransparency = 1
title.Text = "Egg Steal Control"
title.TextColor3 = Color3.new(0.8, 1, 0.8)
title.TextSize = 18
title.Font = Enum.Font.GothamBold
title.Parent = frame

-- Fly slider
local flyLabel = Instance.new("TextLabel")
flyLabel.Size = UDim2.new(0.5, -5, 0, 20)
flyLabel.Position = UDim2.new(0, 5, 0, 30)
flyLabel.BackgroundTransparency = 1
flyLabel.Text = "Fly Multiplier: 1x"
flyLabel.TextColor3 = Color3.new(0.7, 1, 0.7)
flyLabel.TextSize = 13
flyLabel.Font = Enum.Font.Gotham
flyLabel.TextXAlignment = Enum.TextXAlignment.Left
flyLabel.Parent = frame

local flySlider = Instance.new("Frame")
flySlider.Size = UDim2.new(0.9, 0, 0, 16)
flySlider.Position = UDim2.new(0.05, 0, 0, 52)
flySlider.BackgroundColor3 = Color3.new(0.2, 0.2, 0.2)
flySlider.BackgroundTransparency = 0.4
flySlider.BorderSizePixel = 0
flySlider.Parent = frame
local c1 = Instance.new("UICorner"); c1.CornerRadius = UDim.new(1,0); c1.Parent = flySlider

local flyFill = Instance.new("Frame")
flyFill.Size = UDim2.new(0, 0, 1, 0)
flyFill.BackgroundColor3 = Color3.new(0.5, 1, 0.5)
flyFill.BorderSizePixel = 0
flyFill.Parent = flySlider
local c2 = Instance.new("UICorner"); c2.CornerRadius = UDim.new(1,0); c2.Parent = flyFill

local flyDrag = Instance.new("TextButton")
flyDrag.Size = UDim2.new(0, 18, 0, 18)
flyDrag.Position = UDim2.new(0, -9, 0, -1)
flyDrag.BackgroundColor3 = Color3.new(0.5, 1, 0.5)
flyDrag.BorderSizePixel = 0
flyDrag.Text = ""
flyDrag.Parent = flySlider
local c3 = Instance.new("UICorner"); c3.CornerRadius = UDim.new(1,0); c3.Parent = flyDrag

-- Walk slider
local walkLabel = Instance.new("TextLabel")
walkLabel.Size = UDim2.new(0.5, -5, 0, 20)
walkLabel.Position = UDim2.new(0, 5, 0, 80)
walkLabel.BackgroundTransparency = 1
walkLabel.Text = "Walk Multiplier: 1x"
walkLabel.TextColor3 = Color3.new(0.7, 1, 0.7)
walkLabel.TextSize = 13
walkLabel.Font = Enum.Font.Gotham
walkLabel.TextXAlignment = Enum.TextXAlignment.Left
walkLabel.Parent = frame

local walkSlider = Instance.new("Frame")
walkSlider.Size = UDim2.new(0.9, 0, 0, 16)
walkSlider.Position = UDim2.new(0.05, 0, 0, 102)
walkSlider.BackgroundColor3 = Color3.new(0.2, 0.2, 0.2)
walkSlider.BackgroundTransparency = 0.4
walkSlider.BorderSizePixel = 0
walkSlider.Parent = frame
local c4 = Instance.new("UICorner"); c4.CornerRadius = UDim.new(1,0); c4.Parent = walkSlider

local walkFill = Instance.new("Frame")
walkFill.Size = UDim2.new(0, 0, 1, 0)
walkFill.BackgroundColor3 = Color3.new(0.5, 1, 0.5)
walkFill.BorderSizePixel = 0
walkFill.Parent = walkSlider
local c5 = Instance.new("UICorner"); c5.CornerRadius = UDim.new(1,0); c5.Parent = walkFill

local walkDrag = Instance.new("TextButton")
walkDrag.Size = UDim2.new(0, 18, 0, 18)
walkDrag.Position = UDim2.new(0, -9, 0, -1)
walkDrag.BackgroundColor3 = Color3.new(0.5, 1, 0.5)
walkDrag.BorderSizePixel = 0
walkDrag.Text = ""
walkDrag.Parent = walkSlider
local c6 = Instance.new("UICorner"); c6.CornerRadius = UDim.new(1,0); c6.Parent = walkDrag

-- Fly toggle button
local flyBtn = Instance.new("TextButton")
flyBtn.Name = "FlyToggle"
flyBtn.Size = UDim2.new(0, 70, 0, 26)
flyBtn.Position = UDim2.new(0.6, 0, 0, 28)
flyBtn.BackgroundColor3 = Color3.new(0.3, 0.3, 0.3)
flyBtn.BackgroundTransparency = 0.3
flyBtn.Text = "Fly OFF"
flyBtn.TextColor3 = Color3.new(0.7, 1, 0.7)
flyBtn.TextSize = 13
flyBtn.Font = Enum.Font.GothamBold
flyBtn.BorderSizePixel = 0
flyBtn.Parent = frame
local tc = Instance.new("UICorner"); tc.CornerRadius = UDim.new(0,4); tc.Parent = flyBtn
flyBtn.MouseButton1Click:Connect(toggleFly)

-- Slider logic
local function makeSlider(slider, fill, drag, label, min, max, name, callback)
    local dragging = false
    drag.MouseButton1Down:Connect(function() dragging = true end)
    userInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
        end
    end)
    userInputService.InputChanged:Connect(function(input)
        if not dragging then return end
        if input.UserInputType ~= Enum.UserInputType.MouseMovement then return end
        local absPos = slider.AbsolutePosition
        local absSize = slider.AbsoluteSize.X
        local mouseX = userInputService:GetMouseLocation().X
        local percent = math.clamp((mouseX - absPos.X) / absSize, 0, 1)
        local value = math.round(min + percent * (max - min))
        value = math.clamp(value, min, max)
        local p = (value - min) / (max - min)
        fill.Size = UDim2.new(p, 0, 1, 0)
        drag.Position = UDim2.new(p, -9, 0, -1)
        label.Text = name .. ": " .. tostring(value) .. "x"
        callback(value)
    end)
end

makeSlider(flySlider, flyFill, flyDrag, flyLabel, 1, 100, "Fly Multiplier", function(v)
    flyMult = v
end)

makeSlider(walkSlider, walkFill, walkDrag, walkLabel, 1, 100, "Walk Multiplier", function(v)
    walkMult = v
end)

print("CFrame movement script loaded. Walk and Fly bypass all game limits.")
print("F to toggle fly. WASD to move. Space up, Shift down.")
