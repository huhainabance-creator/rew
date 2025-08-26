-- Простіше вікно для тесту GUI у Roblox

local player = game.Players.LocalPlayer
local gui = Instance.new("ScreenGui")
gui.Name = "YBA_AutoWindow"
gui.Parent = player:WaitForChild("PlayerGui")

local frame = Instance.new("Frame", gui)
frame.Size = UDim2.new(0, 250, 0, 180)
frame.Position = UDim2.new(0.5, -125, 0.3, 0)
frame.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
frame.BorderSizePixel = 0

local title = Instance.new("TextLabel", frame)
title.Text = "YBA Авто-Скрипт"
title.Size = UDim2.new(1, 0, 0, 30)
title.BackgroundTransparency = 1
title.TextColor3 = Color3.fromRGB(255, 255, 255)
title.Font = Enum.Font.SourceSansBold
title.TextSize = 22

local autoCollect = false
local autoSell = false
local autoRejoin = false

local collectBtn = Instance.new("TextButton", frame)
collectBtn.Text = "Авто збір предметів: ВИКЛ"
collectBtn.Size = UDim2.new(0.95, 0, 0, 30)
collectBtn.Position = UDim2.new(0.025, 0, 0, 40)
collectBtn.BackgroundColor3 = Color3.fromRGB(50, 120, 50)

collectBtn.MouseButton1Click:Connect(function()
    autoCollect = not autoCollect
    collectBtn.Text = "Авто збір предметів: " .. (autoCollect and "ВКЛ" or "ВИКЛ")
end)

local sellBtn = Instance.new("TextButton", frame)
sellBtn.Text = "Авто продаж: ВИКЛ"
sellBtn.Size = UDim2.new(0.95, 0, 0, 30)
sellBtn.Position = UDim2.new(0.025, 0, 0, 80)
sellBtn.BackgroundColor3 = Color3.fromRGB(120, 50, 50)

sellBtn.MouseButton1Click:Connect(function()
    autoSell = not autoSell
    sellBtn.Text = "Авто продаж: " .. (autoSell and "ВКЛ" or "ВИКЛ")
end)

local rejoinBtn = Instance.new("TextButton", frame)
rejoinBtn.Text = "Авто перезаходження: ВИКЛ"
rejoinBtn.Size = UDim2.new(0.95, 0, 0, 30)
rejoinBtn.Position = UDim2.new(0.025, 0, 0, 120)
rejoinBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 120)

rejoinBtn.MouseButton1Click:Connect(function()
    autoRejoin = not autoRejoin
    rejoinBtn.Text = "Авто перезаходження: " .. (autoRejoin and "ВКЛ" or "ВИКЛ")
end)

local closeBtn = Instance.new("TextButton", frame)
closeBtn.Text = "Закрити"
closeBtn.Size = UDim2.new(0.95, 0, 0, 30)
closeBtn.Position = UDim2.new(0.025, 0, 1, -35)
closeBtn.BackgroundColor3 = Color3.fromRGB(80, 80, 80)

closeBtn.MouseButton1Click:Connect(function()
    gui:Destroy()
end)
