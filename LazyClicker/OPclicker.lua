
-- Đợi game tải xong hoàn toàn dữ liệu người chơi
if not game:IsLoaded() then game.Loaded:Wait() end

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")
local VirtualInputManager = game:GetService("VirtualInputManager")

-- BIẾN CẤU HÌNH & TRẠNG THÁI
getgenv().AutoClick = false
local targets = {} -- Danh sách chứa các điểm chạm {frame, number, delay}

------------------------------------------------------------------------
-- LOGIC VÒNG TUẦN HOÀN CÁC ĐIỂM CHẠM - V2.0.5 (X:45, Y:45)
------------------------------------------------------------------------
task.spawn(function()
    while true do
        if getgenv().AutoClick and #targets > 0 then
            for _, targetData in ipairs(targets) do
                if not getgenv().AutoClick then break end
                pcall(function()
                    local frame = targetData.frame
                    
                    -- Lấy thông tin vị trí và kích thước thực tế của điểm chạm
                    local absPos = frame.AbsolutePosition
                    local absSize = frame.AbsoluteSize
                    
                    -- TÂM GỐC CỦA FRAME
                    local clickX = absPos.X + (absSize.X / 2)
                    local clickY = absPos.Y + (absSize.Y / 2)
                    
                    -- TINH CHỈNH TỌA ĐỘ V2.0.5: X = 45, Y = 45
                    local TOPBAR_OFFSET_Y = 45   
                    local SIDE_OFFSET_X   = 45   
                    
                    clickX = clickX + SIDE_OFFSET_X
                    clickY = clickY + TOPBAR_OFFSET_Y
                    
                    -- Thực hiện giả lập click chuẩn xác tuyệt đối vào tâm
                    VirtualInputManager:SendMouseButtonEvent(clickX, clickY, 0, true, game, 0)
                    task.wait(0.01)
                    VirtualInputManager:SendMouseButtonEvent(clickX, clickY, 0, false, game, 0)
                end)
                task.wait(targetData.delay or 0.05)
            end
        else
            task.wait(0.1)
        end
    end
end)

------------------------------------------------------------------------
-- HỆ THỐNG DRAGGING (KÉO THẢ CHO MỌI KHUNG)
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

------------------------------------------------------------------------
-- GIAO DIỆN PANEL CHÍNH & CÁC NÚT ĐIỀU KHIỂN
------------------------------------------------------------------------
if PlayerGui:FindFirstChild("LazyClickerAppGui") then PlayerGui.LazyClickerAppGui:Destroy() end

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "LazyClickerAppGui"
ScreenGui.Parent = PlayerGui
ScreenGui.ResetOnSpawn = false

-- Thanh điều khiển chính
local ControlPanel = Instance.new("Frame")
ControlPanel.Name = "ControlPanel"
ControlPanel.Size = UDim2.new(0, 240, 0, 65) 
ControlPanel.Position = UDim2.new(0.5, -120, 0.1, 0)
ControlPanel.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
ControlPanel.BorderSizePixel = 0
ControlPanel.Active = true
ControlPanel.Parent = ScreenGui

local PanelCorner = Instance.new("UICorner")
PanelCorner.CornerRadius = UDim.new(0, 8)
PanelCorner.Parent = ControlPanel

local PanelStroke = Instance.new("UIStroke")
PanelStroke.Name = "PanelStroke"
PanelStroke.Color = Color3.fromRGB(80, 80, 80)
PanelStroke.Thickness = 2
PanelStroke.Parent = ControlPanel

-- Tên menu "lazy clicker v2.0.5"
local TitleLabel = Instance.new("TextLabel")
TitleLabel.Size = UDim2.new(0, 160, 0, 20)
TitleLabel.Position = UDim2.new(0, 8, 0, 2)
TitleLabel.BackgroundTransparency = 1
TitleLabel.Font = Enum.Font.Arcade
TitleLabel.Text = "lazy clicker v2.0.5"
TitleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
TitleLabel.TextSize = 12
TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
TitleLabel.Parent = ControlPanel

-- Các nút chức năng trên Control Panel
local function createControlBtn(name, text, posX, color)
    local btn = Instance.new("TextButton")
    btn.Name = name
    btn.Size = UDim2.new(0, 40, 0, 35)
    btn.Position = UDim2.new(0, posX, 0, 24)
    btn.BackgroundColor3 = color or Color3.fromRGB(50, 50, 50)
    btn.Font = Enum.Font.Arcade
    btn.Text = text
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.TextSize = 14
    btn.BorderSizePixel = 0
    btn.Parent = ControlPanel
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)
    return btn
end

local PlayBtn = createControlBtn("PlayBtn", "▶", 5, Color3.fromRGB(0, 160, 80))
local PlusBtn = createControlBtn("PlusBtn", "+", 50, Color3.fromRGB(50, 100, 200))
local MinusBtn = createControlBtn("MinusBtn", "-", 95, Color3.fromRGB(200, 80, 50))
local SettingBtn = createControlBtn("SettingBtn", "⚙", 140, Color3.fromRGB(100, 100, 100))
local HideBtn = createControlBtn("HideBtn", "👁", 185, Color3.fromRGB(80, 50, 150))

setupDraggable(ControlPanel, ControlPanel)

------------------------------------------------------------------------
-- NÚT NỔI THU NHỎ
------------------------------------------------------------------------
local MiniButton = Instance.new("TextButton")
MiniButton.Name = "MiniButton"
MiniButton.Size = UDim2.new(0, 45, 0, 45) 
MiniButton.Position = UDim2.new(1, -65, 0, 40)
MiniButton.Font = Enum.Font.Arcade 
MiniButton.Text = "click" 
MiniButton.TextSize = 12 
MiniButton.Visible = false
MiniButton.Active = true
MiniButton.Parent = ScreenGui

local MiniCorner = Instance.new("UICorner")
MiniCorner.CornerRadius = UDim.new(1, 0) 
MiniCorner.Parent = MiniButton

local MiniStroke = Instance.new("UIStroke")
MiniStroke.Name = "MiniStroke"
MiniStroke.Thickness = 2 
MiniStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
MiniStroke.Parent = MiniButton

setupDraggable(MiniButton, MiniButton)

HideBtn.MouseButton1Click:Connect(function()
    ControlPanel.Visible = false
    MiniButton.Visible = true
end)

MiniButton.MouseButton1Click:Connect(function()
    MiniButton.Visible = false
    ControlPanel.Visible = true
end)

------------------------------------------------------------------------
-- BẢNG SETTINGS (TỐC ĐỘ RIÊNG CHO TỪNG ĐIỂM)
------------------------------------------------------------------------
local SettingFrame = Instance.new("ScrollingFrame")
SettingFrame.Name = "SettingFrame"
SettingFrame.Size = UDim2.new(0, 240, 0, 180)
SettingFrame.Position = UDim2.new(0.5, -120, 0.25, 0)
SettingFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
SettingFrame.BorderSizePixel = 0
SettingFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
SettingFrame.ScrollBarThickness = 3
SettingFrame.Visible = false
SettingFrame.Active = true
SettingFrame.Parent = ScreenGui

local SettingCorner = Instance.new("UICorner", SettingFrame)
SettingCorner.CornerRadius = UDim.new(0, 8)
local SettingStroke = Instance.new("UIStroke", SettingFrame)
SettingStroke.Name = "SettingStroke"
SettingStroke.Thickness = 2

local SettingTitle = Instance.new("TextLabel")
SettingTitle.Size = UDim2.new(1, 0, 0, 30)
SettingTitle.BackgroundTransparency = 1
SettingTitle.Font = Enum.Font.Arcade
SettingTitle.Text = "  SPEED SETTINGS PER TARGET"
SettingTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
SettingTitle.TextSize = 11
SettingTitle.TextXAlignment = Enum.TextXAlignment.Left
SettingTitle.Parent = SettingFrame

local CloseSettingBtn = Instance.new("TextButton")
CloseSettingBtn.Size = UDim2.new(0, 220, 0, 28)
CloseSettingBtn.Position = UDim2.new(0, 10, 0, 140)
CloseSettingBtn.BackgroundColor3 = Color3.fromRGB(180, 50, 50)
CloseSettingBtn.Font = Enum.Font.Arcade
CloseSettingBtn.Text = "CLOSE SETTINGS"
CloseSettingBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
CloseSettingBtn.TextSize = 11
CloseSettingBtn.Parent = SettingFrame
Instance.new("UICorner", CloseSettingBtn).CornerRadius = UDim.new(0, 4)

setupDraggable(SettingFrame, SettingFrame)

local function updateSettingUI()
    for _, child in ipairs(SettingFrame:GetChildren()) do
        if child:IsA("Frame") then
            child:Destroy()
        end
    end

    local startY = 35
    for i, targetData in ipairs(targets) do
        local row = Instance.new("Frame")
        row.Size = UDim2.new(0, 220, 0, 30)
        row.Position = UDim2.new(0, 10, 0, startY)
        row.BackgroundTransparency = 1
        row.Parent = SettingFrame

        local label = Instance.new("TextLabel")
        label.Size = UDim2.new(0, 110, 0, 30)
        label.BackgroundTransparency = 1
        label.Font = Enum.Font.Arcade
        label.Text = "Target " .. i .. " Delay(s):"
        label.TextColor3 = Color3.fromRGB(200, 200, 200)
        label.TextSize = 10
        label.TextXAlignment = Enum.TextXAlignment.Left
        label.Parent = row

        local box = Instance.new("TextBox")
        box.Size = UDim2.new(0, 90, 0, 24)
        box.Position = UDim2.new(0, 125, 0, 3)
        box.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
        box.Font = Enum.Font.Arcade
        box.Text = tostring(targetData.delay)
        box.TextColor3 = Color3.fromRGB(255, 255, 255)
        box.TextSize = 11
        box.Parent = row
        Instance.new("UICorner", box).CornerRadius = UDim.new(0, 4)

        box.FocusLost:Connect(function()
            local val = tonumber(box.Text)
            if val and val > 0 then
                targetData.delay = val
            else
                box.Text = tostring(targetData.delay)
            end
        end)

        startY = startY + 35
    end

    SettingFrame.CanvasSize = UDim2.new(0, 0, 0, startY + 15)
    CloseSettingBtn.Position = UDim2.new(0, 10, 0, math.max(140, startY + 5))
end

SettingBtn.MouseButton1Click:Connect(function()
    if not SettingFrame.Visible then
        updateSettingUI()
    end
    SettingFrame.Visible = not SettingFrame.Visible
end)

CloseSettingBtn.MouseButton1Click:Connect(function()
    SettingFrame.Visible = false
end)

------------------------------------------------------------------------
-- TÍNH NĂNG TẠO / XÓA ĐIỂM CHẠM (TARGET DOTS)
------------------------------------------------------------------------
local function createTargetDot()
    local index = #targets + 1
    
    local dotFrame = Instance.new("Frame")
    dotFrame.Name = "TargetDot_" .. index
    dotFrame.Size = UDim2.new(0, 36, 0, 36)
    dotFrame.Position = UDim2.new(0.4 + math.random(-10, 10)/100, 0, 0.4 + math.random(-10, 10)/100, 0)
    dotFrame.BackgroundColor3 = Color3.fromRGB(0, 150, 255)
    dotFrame.BackgroundTransparency = 0.3
    dotFrame.BorderSizePixel = 0
    dotFrame.Active = true
    dotFrame.Parent = ScreenGui
    
    local dotCorner = Instance.new("UICorner", dotFrame)
    dotCorner.CornerRadius = UDim.new(1, 0) 
    
    local dotStroke = Instance.new("UIStroke", dotFrame)
    dotStroke.Thickness = 2
    dotStroke.Color = Color3.fromRGB(255, 255, 255)
    
    local numLabel = Instance.new("TextLabel")
    numLabel.Size = UDim2.new(1, 0, 1, 0)
    numLabel.BackgroundTransparency = 1
    numLabel.Font = Enum.Font.Arcade
    numLabel.Text = tostring(index)
    numLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    numLabel.TextSize = 14
    numLabel.Parent = dotFrame
    
    setupDraggable(dotFrame, dotFrame)
    
    table.insert(targets, {frame = dotFrame, number = index, delay = 0.05})
end

local function removeTargetDot()
    if #targets > 0 then
        local lastTarget = table.remove(targets)
        if lastTarget and lastTarget.frame then
            lastTarget.frame:Destroy()
        end
    end
end

PlusBtn.MouseButton1Click:Connect(createTargetDot)
MinusBtn.MouseButton1Click:Connect(removeTargetDot)

PlayBtn.MouseButton1Click:Connect(function()
    getgenv().AutoClick = not getgenv().AutoClick
    if getgenv().AutoClick then
        PlayBtn.Text = "⏸"
        PlayBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
    else
        PlayBtn.Text = "▶"
        PlayBtn.BackgroundColor3 = Color3.fromRGB(0, 160, 80)
    end
end)

------------------------------------------------------------------------
-- HIỆU ỨNG LED RGB CHROMATIC
------------------------------------------------------------------------
RunService.RenderStepped:Connect(function()
    local ledColor = Color3.fromHSV(tick() % 5 / 5, 1, 1)
    if ControlPanel and ControlPanel:FindFirstChild("PanelStroke") then 
        ControlPanel.PanelStroke.Color = ledColor 
    end
    if SettingFrame and SettingFrame:FindFirstChild("SettingStroke") then 
        SettingFrame.SettingStroke.Color = ledColor 
    end
    if MiniButton and MiniButton:FindFirstChild("MiniStroke") then
        MiniButton.MiniStroke.Color = ledColor
        MiniButton.TextColor3 = ledColor
    end
    if TitleLabel then
        TitleLabel.TextColor3 = ledColor
    end
end)
