-- Đợi game tải xong hoàn toàn dữ liệu người chơi
if not game:IsLoaded() then game.Loaded:Wait() end

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Lighting = game:GetService("Lighting")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

-- CẤU HÌNH HỆ THỐNG (lazy hub v2.5)
local AimbotEnabled = true
local EspEnabled = true
local FpsOptimizeEnabled = false
local ShowFpsEnabled = true
local SpeedHackEnabled = false
local JumpHackEnabled = false 
local DoubleJumpEnabled = false 

local FOV_RADIUS = 70 
local TARGET_PART = "Head"
local SMOOTHNESS = 0.35 
local SliderValue = 50       
local JumpSliderValue = 50   

local currentTarget = nil
local espStorage = {}

-- Khởi tạo vòng tròn FOV bằng Drawing API
local FOVCircle = Drawing.new("Circle")
FOVCircle.Thickness = 1.5
FOVCircle.Filled = false
FOVCircle.Radius = FOV_RADIUS
FOVCircle.Visible = true

------------------------------------------------------------------------
-- LOGIC TÍNH NĂNG: DOUBLE JUMP (NHẢY 2 LẦN)
------------------------------------------------------------------------
local canDoubleJump = false
local hasDoubleJumped = false

local function getHumanoid()
    local character = LocalPlayer.Character
    return character and character:FindFirstChildOfClass("Humanoid")
end

UserInputService.JumpRequest:Connect(function()
    if not DoubleJumpEnabled then return end
    local humanoid = getHumanoid()
    local rootPart = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    
    if humanoid and rootPart and humanoid.Health > 0 then
        if canDoubleJump and not hasDoubleJumped then
            hasDoubleJumped = true
            local jumpPowerFactor = JumpHackEnabled and calculateJumpPower(50, JumpSliderValue) or humanoid.JumpPower
            if jumpPowerFactor == 0 then jumpPowerFactor = 50 end
            
            rootPart.AssemblyLinearVelocity = Vector3.new(rootPart.AssemblyLinearVelocity.X, jumpPowerFactor * 1.1, rootPart.AssemblyLinearVelocity.Z)
        end
    end
end)

RunService.Heartbeat:Connect(function()
    local humanoid = getHumanoid()
    if humanoid then
        if humanoid.FloorMaterial == Enum.Material.Air then
            canDoubleJump = true
        else
            canDoubleJump = false
            hasDoubleJumped = false
        end
    end
end)

------------------------------------------------------------------------
-- 1. CORE LOGIC: ESP MODE & AIMBOT
------------------------------------------------------------------------
local function createESP(player)
    if player == LocalPlayer then return end
    local function applyESP(character)
        if not character then return end
        local highlight = character:FindFirstChild("ESPHighlight") or Instance.new("Highlight")
        highlight.Name = "ESPHighlight"
        highlight.FillColor = Color3.fromRGB(255, 0, 100)
        highlight.FillTransparency = 0.6
        highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
        highlight.Adornee = character
        highlight.Enabled = EspEnabled
        highlight.Parent = character
        
        local head = character:WaitForChild("Head", 5)
        if head then
            local billboard = character:FindFirstChild("ESPTag") or Instance.new("BillboardGui")
            billboard.Name = "ESPTag"
            billboard.Adornee = head
            billboard.Size = UDim2.new(0, 120, 0, 40)
            billboard.StudsOffset = Vector3.new(0, 2.5, 0)
            billboard.AlwaysOnTop = true
            billboard.Enabled = EspEnabled
            
            local textLabel = billboard:FindFirstChild("TextLabel") or Instance.new("TextLabel")
            textLabel.Name = "TextLabel"
            textLabel.Size = UDim2.new(1, 0, 1, 0)
            textLabel.BackgroundTransparency = 1
            textLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
            textLabel.TextStrokeTransparency = 0
            textLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
            textLabel.Font = Enum.Font.Arcade
            textLabel.TextSize = 10
            textLabel.Text = player.DisplayName or player.Name
            textLabel.Parent = billboard
            billboard.Parent = character
        end
        espStorage[player] = character
    end
    player.CharacterAdded:Connect(applyESP)
    if player.Character then applyESP(player.Character) end
end

local function removeESP(player)
    if espStorage[player] then
        local char = espStorage[player]
        if char:FindFirstChild("ESPHighlight") then char.ESPHighlight:Destroy() end
        if char:FindFirstChild("ESPTag") then char.ESPTag:Destroy() end
        espStorage[player] = nil
    end
end

for _, p in ipairs(Players:GetPlayers()) do createESP(p) end
Players.PlayerAdded:Connect(createESP)
Players.PlayerRemoving:Connect(removeESP)

local function updateESPLoop()
    for player, character in pairs(espStorage) do
        if character and character:FindFirstChild("ESPHighlight") and character:FindFirstChild("ESPTag") then
            character.ESPHighlight.Enabled = EspEnabled
            character.ESPTag.Enabled = EspEnabled
            if EspEnabled and character:FindFirstChild("Head") and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Head") then
                local dist = math.round((character.Head.Position - LocalPlayer.Character.Head.Position).Magnitude)
                character.ESPTag.TextLabel.Text = string.format("%s\n[%s M]", string.upper(player.DisplayName or player.Name), dist)
            end
        else espStorage[player] = nil end
    end
end

local function checkLineOfSight(character, targetPart)
    if not LocalPlayer.Character or not targetPart then return false end
    local raycastParams = RaycastParams.new()
    raycastParams.FilterType = Enum.RaycastFilterType.Exclude
    raycastParams.FilterDescendantsInstances = {LocalPlayer.Character, character}
    local raycastResult = workspace:Raycast(Camera.CFrame.Position, targetPart.Position - Camera.CFrame.Position, raycastParams)
    return raycastResult == nil
end

local function getClosestPlayer()
    local closestPlayer, shortestDistance = nil, math.huge
    local screenCenter = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character then
            local targetPart = player.Character:FindFirstChild(TARGET_PART)
            local humanoid = player.Character:FindFirstChildOfClass("Humanoid")
            if targetPart and humanoid and humanoid.Health > 0 and checkLineOfSight(player.Character, targetPart) then
                local screenPos, onScreen = Camera:WorldToViewportPoint(targetPart.Position)
                if onScreen then
                    local distanceToCenter = (Vector2.new(screenPos.X, screenPos.Y) - screenCenter).Magnitude
                    if distanceToCenter <= FOV_RADIUS and distanceToCenter < shortestDistance then
                        closestPlayer = player
                        shortestDistance = distanceToCenter
                    end
                end
            end
        end
    end
    return closestPlayer
end

------------------------------------------------------------------------
-- 2. CORE LOGIC: THUẬT TOÁN VÀ VÒNG LẶP HỆ THỐNG
------------------------------------------------------------------------
function calculateWalkSpeed(value)
    if value == 50 then return 16
    elseif value > 50 then return 16 + ((value - 50) / 50) * (80 - 16)
    else return 3.2 + ((value - 1) / 49) * (16 - 3.2) end
end

function calculateJumpPower(baseValue, sliderVal)
    if sliderVal == 50 then
        return baseValue
    elseif sliderVal > 50 then
        local factor = 1 + ((sliderVal - 50) / 50) * 4 
        return baseValue * factor
    else
        local factor = 0.2 + ((sliderVal - 1) / 49) * 0.8 
        return baseValue * factor
    end
end

local FpsFrame
local fpsLabel
local fpsCount = 0
local lastUpdate = os.clock()

RunService.Heartbeat:Connect(function()
    fpsCount = fpsCount + 1
    local now = os.clock()
    if now - lastUpdate >= 1 then
        if fpsLabel then fpsLabel.Text = "FPS: " .. tostring(fpsCount) end
        fpsCount = 0
        lastUpdate = now
    end
end)

local MainMenu
local TitleBar
local MiniButton
local MiniStroke
local AuthorLabel

local aimConnection
aimConnection = RunService.RenderStepped:Connect(function()
    FOVCircle.Position = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
    updateESPLoop()

    -- HỆ THỐNG ĐỔI MÀU LED CHROMATIC RGB
    local ledColor = Color3.fromHSV(tick() % 5 / 5, 1, 1)
    
    FOVCircle.Color = ledColor
    
    local ledBgColor = Color3.fromHSV(tick() % 5 / 5, 0.65, 0.15)
    if MainMenu then MainMenu.BackgroundColor3 = ledBgColor end
    if MiniButton then MiniButton.BackgroundColor3 = ledBgColor end

    if TitleBar then TitleBar.TextColor3 = ledColor end
    if AuthorLabel then AuthorLabel.TextColor3 = ledColor end 
    if MiniButton then MiniButton.TextColor3 = ledColor end
    if MiniStroke then MiniStroke.Color = ledColor end 

    if SpeedHackEnabled and LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid") then
        LocalPlayer.Character:FindFirstChildOfClass("Humanoid").WalkSpeed = calculateWalkSpeed(SliderValue)
    end

    if JumpHackEnabled and LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid") then
        local humanoid = LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
        if humanoid.UseJumpPower then
            humanoid.JumpPower = calculateJumpPower(50, JumpSliderValue)
        else
            humanoid.JumpHeight = calculateJumpPower(7.2, JumpSliderValue)
        end
    end

    if FpsOptimizeEnabled then
        for _, obj in ipairs(workspace:GetDescendants()) do
            if obj:IsA("ParticleEmitter") or obj:IsA("Sparkles") or obj:IsA("Smoke") then
                obj.Enabled = false
            end
        end
    end

    if not AimbotEnabled then return end

    if currentTarget then
        if currentTarget.Character and currentTarget.Character:FindFirstChild(TARGET_PART) and currentTarget.Character:FindFirstChildOfClass("Humanoid") and currentTarget.Character:FindFirstChildOfClass("Humanoid").Health > 0 then
            local targetPart = currentTarget.Character[TARGET_PART]
            local screenPos, onScreen = Camera:WorldToViewportPoint(targetPart.Position)
            local distanceToCenter = (Vector2.new(screenPos.X, screenPos.Y) - FOVCircle.Position).Magnitude
            if not onScreen or distanceToCenter > FOV_RADIUS or not checkLineOfSight(currentTarget.Character, targetPart) then
                currentTarget = nil
            end
        else currentTarget = nil end
    end

    if not currentTarget then currentTarget = getClosestPlayer() end

    if currentTarget and currentTarget.Character and currentTarget.Character:FindFirstChild(TARGET_PART) then
        Camera.CFrame = Camera.CFrame:Lerp(CFrame.lookAt(Camera.CFrame.Position, currentTarget.Character[TARGET_PART].Position), SMOOTHNESS)
    end
end)

------------------------------------------------------------------------
-- 3. GIAO DIỆN HỘP THÔNG SỐ FPS
------------------------------------------------------------------------
if PlayerGui:FindFirstChild("AimGodMenuGui") then PlayerGui.AimGodMenuGui:Destroy() end

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "AimGodMenuGui"
ScreenGui.Parent = PlayerGui
ScreenGui.ResetOnSpawn = false

FpsFrame = Instance.new("Frame")
FpsFrame.Size = UDim2.new(0, 75, 0, 25)
FpsFrame.Position = UDim2.new(0, 15, 0, 15)
FpsFrame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
FpsFrame.BackgroundTransparency = 0.55 
FpsFrame.BorderSizePixel = 0
FpsFrame.Visible = ShowFpsEnabled
FpsFrame.Parent = ScreenGui

local FpsCorner = Instance.new("UICorner")
FpsCorner.CornerRadius = UDim.new(0, 6)
FpsCorner.Parent = FpsFrame

local FpsStroke = Instance.new("UIStroke")
FpsStroke.Color = Color3.fromRGB(0, 150, 255)
FpsStroke.Thickness = 1.5
FpsStroke.Parent = FpsFrame

fpsLabel = Instance.new("TextLabel")
fpsLabel.Size = UDim2.new(1, 0, 1, 0)
fpsLabel.BackgroundTransparency = 1
fpsLabel.Font = Enum.Font.Arcade
fpsLabel.Text = "FPS: --"
fpsLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
fpsLabel.TextSize = 12
fpsLabel.Parent = FpsFrame

------------------------------------------------------------------------
-- 4. GIAO DIỆN MENU CHÍNH 2 CỘT CUỘN VUỐT
------------------------------------------------------------------------
MainMenu = Instance.new("Frame")
MainMenu.Name = "MainMenu"
MainMenu.Size = UDim2.new(0, 360, 0, 250) 
MainMenu.Position = UDim2.new(0.5, -180, 0.4, -125)
MainMenu.BorderSizePixel = 0
MainMenu.Active = true
MainMenu.Parent = ScreenGui

local MenuCorner = Instance.new("UICorner")
MenuCorner.CornerRadius = UDim.new(0, 8)
MenuCorner.Parent = MainMenu

local MenuStroke = Instance.new("UIStroke")
MenuStroke.Color = Color3.fromRGB(50, 50, 50)
MenuStroke.Thickness = 2
MenuStroke.Parent = MainMenu

TitleBar = Instance.new("TextLabel")
TitleBar.Size = UDim2.new(1, 0, 0, 30)
TitleBar.BackgroundColor3 = Color3.fromRGB(20, 20, 20) 
TitleBar.Font = Enum.Font.Arcade
TitleBar.Text = "  lazy hub v2.5" 
TitleBar.TextSize = 13
TitleBar.TextXAlignment = Enum.TextXAlignment.Left
TitleBar.Parent = MainMenu

local TitleCorner = Instance.new("UICorner")
TitleCorner.CornerRadius = UDim.new(0, 8)
TitleCorner.Parent = TitleBar

AuthorLabel = Instance.new("TextLabel")
AuthorLabel.Name = "AuthorLabel"
AuthorLabel.Size = UDim2.new(0, 120, 0, 30)
AuthorLabel.Position = UDim2.new(0.5, -50, 0, 0) 
AuthorLabel.BackgroundTransparency = 1
AuthorLabel.Font = Enum.Font.Arcade
AuthorLabel.Text = "fps: flick" -- THAY ĐỔI THEO YÊU CẦU CỦA BẠN TẠI ĐÂY
AuthorLabel.TextSize = 12
AuthorLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
AuthorLabel.Parent = MainMenu

local CloseButton = Instance.new("TextButton")
CloseButton.Size = UDim2.new(0, 30, 0, 30)
CloseButton.Position = UDim2.new(1, -30, 0, 0)
CloseButton.BackgroundTransparency = 1
CloseButton.Font = Enum.Font.Arcade
CloseButton.Text = "-"
CloseButton.TextColor3 = Color3.fromRGB(255, 50, 50)
CloseButton.TextSize = 16
CloseButton.Parent = MainMenu

local function createColumn(name, posX)
    local scroll = Instance.new("ScrollingFrame")
    scroll.Name = name
    scroll.Size = UDim2.new(0, 165, 0, 205)
    scroll.Position = UDim2.new(0, posX, 0, 35)
    scroll.BackgroundTransparency = 1
    scroll.BorderSizePixel = 0
    scroll.CanvasSize = UDim2.new(0, 0, 0, 280) 
    scroll.ScrollBarThickness = 2
    scroll.ScrollBarImageColor3 = Color3.fromRGB(50, 50, 50)
    scroll.Parent = MainMenu
    return scroll
end

local Column1 = createColumn("ColumnLeft", 10)   
local Column2 = createColumn("ColumnRight", 185) 

local function createToggleButton(name, text, startY, isEnabled, parentCol, callback)
    local button = Instance.new("TextButton")
    button.Name = name
    button.Size = UDim2.new(0, 155, 0, 32)
    button.Position = UDim2.new(0, 2, 0, startY)
    button.BackgroundColor3 = isEnabled and Color3.fromRGB(0, 180, 80) or Color3.fromRGB(180, 40, 40)
    button.Font = Enum.Font.Arcade
    button.Text = text .. (isEnabled and ": ON" or ": OFF")
    button.TextColor3 = Color3.fromRGB(255, 255, 255)
    button.TextSize = 11
    button.BorderSizePixel = 0
    button.Parent = parentCol
    
    local btnCorner = Instance.new("UICorner")
    btnCorner.CornerRadius = UDim.new(0, 6)
    btnCorner.Parent = button
    
    local stroke = Instance.new("UIStroke")
    stroke.Color = Color3.fromRGB(0, 0, 0)
    stroke.Thickness = 1
    stroke.Parent = button
    
    button.MouseButton1Click:Connect(function()
        local newState = callback()
        button.Text = text .. (newState and ": ON" or ": OFF")
        button.BackgroundColor3 = newState and Color3.fromRGB(0, 180, 80) or Color3.fromRGB(180, 40, 40)
    end)
    return button
end

-- ==================== XẾP CỘT 1 (BÊN TRÁI) ====================
createToggleButton("AimToggle", "AIM LOCK", 5, AimbotEnabled, Column1, function()
    AimbotEnabled = not AimbotEnabled
    FOVCircle.Visible = AimbotEnabled
    return AimbotEnabled
end)

createToggleButton("EspToggle", "ESP MODE", 42, EspEnabled, Column1, function()
    EspEnabled = not EspEnabled
    if not EspEnabled then
        for _, char in pairs(espStorage) do
            if char:FindFirstChild("ESPHighlight") then char.ESPHighlight.Enabled = false end
            if char:FindFirstChild("ESPTag") then char.ESPTag.Enabled = false end
        end
    end
    return EspEnabled
end)

local LagButton = Instance.new("TextButton")
LagButton.Name = "LagToggle"
LagButton.Size = UDim2.new(0, 155, 0, 32)
LagButton.Position = UDim2.new(0, 2, 0, 79)
LagButton.BackgroundColor3 = FpsOptimizeEnabled and Color3.fromRGB(0, 180, 80) or Color3.fromRGB(180, 40, 40)
LagButton.Font = Enum.Font.Arcade
LagButton.Text = "BOOST FPS" .. (FpsOptimizeEnabled and ": ON" or ": OFF")
LagButton.TextColor3 = Color3.fromRGB(255, 255, 255)
LagButton.TextSize = 11
LagButton.BorderSizePixel = 0
LagButton.Parent = Column1

local LagCorner = Instance.new("UICorner")
LagCorner.CornerRadius = UDim.new(0, 6)
LagCorner.Parent = LagButton

local LagStroke = Instance.new("UIStroke")
LagStroke.Color = Color3.fromRGB(0, 0, 0)
LagStroke.Thickness = 1
LagStroke.Parent = LagButton

LagButton.MouseButton1Click:Connect(function()
    FpsOptimizeEnabled = not FpsOptimizeEnabled
    LagButton.Text = "BOOST FPS" .. (FpsOptimizeEnabled and ": ON" or ": OFF")
    LagButton.BackgroundColor3 = FpsOptimizeEnabled and Color3.fromRGB(0, 180, 80) or Color3.fromRGB(180, 40, 40)
    
    task.defer(function()
        if FpsOptimizeEnabled then
            Lighting.GlobalShadows = false
            Lighting.Decoration = false
        else
            Lighting.GlobalShadows = true
            Lighting.Decoration = true
        end
    end)
end)

createToggleButton("ShowFpsToggle", "SHOW FPS", 116, ShowFpsEnabled, Column1, function()
    ShowFpsEnabled = not ShowFpsEnabled
    FpsFrame.Visible = ShowFpsEnabled
    return ShowFpsEnabled
end)

-- ==================== XẾP CỘT 2 (BÊN PHẢI) ====================
createToggleButton("SpeedToggle", "SPEED HACK", 5, SpeedHackEnabled, Column2, function()
    SpeedHackEnabled = not SpeedHackEnabled
    if not SpeedHackEnabled and LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid") then
        LocalPlayer.Character:FindFirstChildOfClass("Humanoid").WalkSpeed = 16
    end
    return SpeedHackEnabled
end)

createToggleButton("JumpToggle", "JUMP HACK", 42, JumpHackEnabled, Column2, function()
    JumpHackEnabled = not JumpHackEnabled
    if not JumpHackEnabled and LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid") then
        local humanoid = LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
        humanoid.JumpPower = 50
        humanoid.JumpHeight = 7.2
    end
    return JumpHackEnabled
end)

createToggleButton("DoubleJumpToggle", "DOUBLE JUMP", 79, DoubleJumpEnabled, Column2, function()
    DoubleJumpEnabled = not DoubleJumpEnabled
    return DoubleJumpEnabled
end)

------------------------------------------------------------------------
-- 5. CỤM ĐIỀU CHỈNH VALUE (ĐƯỢC ĐẨY XUỐNG DƯỚI TRONG CỘT 2)
------------------------------------------------------------------------
local function createValueController(title, startX, updateCallback)
    local Container = Instance.new("Frame")
    Container.Size = UDim2.new(0, 72, 0, 115)
    Container.Position = UDim2.new(0, startX, 0, 120) 
    Container.BackgroundTransparency = 1
    Container.Parent = Column2

    local Label = Instance.new("TextLabel")
    Label.Size = UDim2.new(1, 0, 0, 15)
    Label.BackgroundTransparency = 1
    Label.Font = Enum.Font.Arcade
    Label.Text = title
    Label.TextColor3 = Color3.fromRGB(200, 200, 200)
    Label.TextSize = 9
    Label.Parent = Container

    local PlusBtn = Instance.new("TextButton")
    PlusBtn.Size = UDim2.new(1, 0, 0, 22)
    PlusBtn.Position = UDim2.new(0, 0, 0, 18)
    PlusBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    PlusBtn.Font = Enum.Font.Arcade
    PlusBtn.Text = "+"
    PlusBtn.TextColor3 = Color3.fromRGB(0, 150, 255)
    PlusBtn.TextSize = 12
    PlusBtn.Parent = Container
    Instance.new("UICorner", PlusBtn).CornerRadius = UDim.new(0, 4)

    local ValueBox = Instance.new("TextBox")
    ValueBox.Size = UDim2.new(1, 0, 0, 22)
    ValueBox.Position = UDim2.new(0, 0, 0, 44)
    ValueBox.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
    ValueBox.Font = Enum.Font.Arcade
    ValueBox.Text = "50"
    ValueBox.TextColor3 = Color3.fromRGB(255, 255, 255)
    ValueBox.TextSize = 10
    ValueBox.ClearTextOnFocus = false
    ValueBox.Parent = Container
    Instance.new("UICorner", ValueBox).CornerRadius = UDim.new(0, 4)
    local stroke = Instance.new("UIStroke", ValueBox)
    stroke.Color = Color3.fromRGB(50, 50, 50)
    stroke.Thickness = 1

    local MinusBtn = Instance.new("TextButton")
    MinusBtn.Size = UDim2.new(1, 0, 0, 22)
    MinusBtn.Position = UDim2.new(0, 0, 0, 70)
    MinusBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    MinusBtn.Font = Enum.Font.Arcade
    MinusBtn.Text = "-"
    MinusBtn.TextColor3 = Color3.fromRGB(0, 150, 255)
    MinusBtn.TextSize = 12
    MinusBtn.Parent = Container
    Instance.new("UICorner", MinusBtn).CornerRadius = UDim.new(0, 4)

    local function setValue(newVal)
        local num = tonumber(newVal) or 50
        num = math.clamp(num, 1, 100) 
        ValueBox.Text = tostring(num)
        updateCallback(num)
    end

    PlusBtn.MouseButton1Click:Connect(function()
        setValue(tonumber(ValueBox.Text) + 1)
    end)

    MinusBtn.MouseButton1Click:Connect(function()
        setValue(tonumber(ValueBox.Text) - 1)
    end)

    ValueBox.FocusLost:Connect(function()
        setValue(ValueBox.Text)
    end)
end

createValueController("SPEED", 2, function(val) SliderValue = val end)
createValueController("JUMP", 78, function(val) JumpSliderValue = val end)

------------------------------------------------------------------------
-- 6. HỆ THỐNG DI CHUYỂN GIAO DIỆN (DRAGGING SYSTEM)
------------------------------------------------------------------------
local function setupDraggable(frame, triggerFrame)
    local dragging, dragInput, dragStart, startPos
    triggerFrame = triggerFrame or frame

    triggerFrame.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            dragStart = input.Position
            startPos = frame.Position
            
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then dragging = false end
            end)
        end
    end)

    triggerFrame.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseMovement then 
            dragInput = input 
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            local delta = input.Position - dragStart
            frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)
end

setupDraggable(MainMenu, TitleBar)

------------------------------------------------------------------------
-- 7. NÚT NỔI THU NHỎ
------------------------------------------------------------------------
MiniButton = Instance.new("TextButton")
MiniButton.Name = "MiniButton"
MiniButton.Size = UDim2.new(0, 45, 0, 45) 
MiniButton.Position = UDim2.new(1, -65, 0, 40)
MiniButton.Font = Enum.Font.Arcade 
MiniButton.Text = "lazy" 
MiniButton.TextSize = 14 
MiniButton.Visible = false
MiniButton.Active = true
MiniButton.Parent = ScreenGui

local MiniCorner = Instance.new("UICorner")
MiniCorner.CornerRadius = UDim.new(1, 0) 
MiniCorner.Parent = MiniButton

MiniStroke = Instance.new("UIStroke")
MiniStroke.Thickness = 2 
MiniStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
MiniStroke.Parent = MiniButton

setupDraggable(MiniButton, MiniButton)

------------------------------------------------------------------------
-- TƯƠNG TÁC ĐÓNG/MỞ MENU
------------------------------------------------------------------------
CloseButton.MouseButton1Click:Connect(function()
    MainMenu.Visible = false
    MiniButton.Visible = true
end)

MiniButton.MouseButton1Click:Connect(function()
    MiniButton.Visible = false
    MainMenu.Visible = true
end)
