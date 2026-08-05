-- Khởi tạo dịch vụ và giao diện người chơi
local Players = game:GetService("Players")
local CoreGui = game:GetService("CoreGui")
local RunService = game:GetService("RunService")
local Player = Players.LocalPlayer
local PlayerGui = Player:WaitForChild("PlayerGui")

-- Trạng thái bật/tắt của tính năng
local isActiveRunning = false

-- Tạo ScreenGui chứa menu
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "AutoActivatePanelGui"
-- Ưu tiên đưa vào CoreGui nếu executor hỗ trợ, nếu không thì đưa vào PlayerGui
pcall(function()
    ScreenGui.Parent = CoreGui
end)
if not ScreenGui.Parent then
    ScreenGui.Parent = PlayerGui
end

-- Tạo khung chính (Main Frame) ở góc trên bên trái
local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Size = UDim2.new(0, 200, 0, 90)
MainFrame.Position = UDim2.new(0, 20, 0, 20)
MainFrame.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
MainFrame.BorderSizePixel = 0
MainFrame.Active = true
MainFrame.Draggable = true -- Cho phép kéo thả bảng nếu muốn
MainFrame.Parent = ScreenGui

-- Bo góc khung chính
local UICornerMain = Instance.new("UICorner")
UICornerMain.CornerRadius = UDim.new(0, 6)
UICornerMain.Parent = MainFrame

-- Tiêu đề menu ở góc trên bên trái
local TitleLabel = Instance.new("TextLabel")
TitleLabel.Name = "TitleLabel"
TitleLabel.Size = UDim2.new(1, 0, 0, 35)
TitleLabel.Position = UDim2.new(0, 0, 0, 0)
TitleLabel.BackgroundTransparency = 1
TitleLabel.Text = "Auto Activate Panel"
TitleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
TitleLabel.TextSize = 14
TitleLabel.Font = Enum.Font.GothamBold
TitleLabel.Parent = MainFrame

-- Nút Bật/Tắt (Toggle Button)
local ToggleButton = Instance.new("TextButton")
ToggleButton.Name = "ToggleButton"
ToggleButton.Size = UDim2.new(0, 180, 0, 35)
ToggleButton.Position = UDim2.new(0, 10, 0, 45)
ToggleButton.BackgroundColor3 = Color3.fromRGB(200, 50, 50) -- Màu đỏ (OFF ban đầu)
ToggleButton.BorderSizePixel = 0
ToggleButton.Text = "Activate: OFF"
ToggleButton.TextColor3 = Color3.fromRGB(255, 255, 255)
ToggleButton.TextSize = 13
ToggleButton.Font = Enum.Font.GothamSemibold
ToggleButton.Parent = MainFrame

-- Bo góc nút bấm
local UICornerButton = Instance.new("UICorner")
UICornerButton.CornerRadius = UDim.new(0, 4)
UICornerButton.Parent = ToggleButton

-- Hàm tìm kiếm và bấm nút Activate trong game
local function clickActivateButton()
    pcall(function()
        for _, gui in ipairs(PlayerGui:GetDescendants()) do
            if gui:IsA("TextButton") or gui:IsA("ImageButton") then
                local textMatch = false
                if gui:IsA("TextButton") and (string.lower(gui.Text):find("activate") or string.lower(gui.Name):find("activate")) then
                    textMatch = true
                elseif string.lower(gui.Name):find("activate") or string.lower(gui.Name):find("vip") then
                    textMatch = true
                end
                
                if textMatch then
                    for _, connection in pairs(getconnections(gui.MouseButton1Click)) do
                        connection:Fire()
                    end
                end
            end
        end
    end)
end

-- Xử lý sự kiện khi bấm nút Toggle
ToggleButton.MouseButton1Click:Connect(function()
    isActiveRunning = not isActiveRunning
    if isActiveRunning then
        ToggleButton.Text = "Activate: ON"
        ToggleButton.BackgroundColor3 = Color3.fromRGB(50, 200, 50) -- Chuyển sang màu xanh khi bật
    else
        ToggleButton.Text = "Activate: OFF"
        ToggleButton.BackgroundColor3 = Color3.fromRGB(200, 50, 50) -- Chuyển lại màu đỏ khi tắt
    end
end)

-- Vòng lặp kiểm tra liên tục khi tính năng được bật
task.spawn(function()
    while true do
        if isActiveRunning then
            clickActivateButton()
        end
        task.wait(0.2) -- Kiểm tra mỗi 0.2 giây để tối ưu hiệu năng
    end
end)
