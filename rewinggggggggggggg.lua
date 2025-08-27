-- GUI з кнопкою для авто збору предметів у YBA

local player = game.Players.LocalPlayer
local gui = Instance.new("ScreenGui")
gui.Name = "YBA_AutoWindow"
gui.Parent = player:WaitForChild("PlayerGui")

local frame = Instance.new("Frame", gui)
frame.Size = UDim2.new(0, 250, 0, 130)
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

local collectBtn = Instance.new("TextButton", frame)
collectBtn.Text = "Авто збір предметів: ВИКЛ"
collectBtn.Size = UDim2.new(0.95, 0, 0, 30)
collectBtn.Position = UDim2.new(0.025, 0, 0, 40)
collectBtn.BackgroundColor3 = Color3.fromRGB(50, 120, 50)

collectBtn.MouseButton1Click:Connect(function()
    autoCollect = not autoCollect
    collectBtn.Text = "Авто збір предметів: " .. (autoCollect and "ВКЛ" or "ВИКЛ")
end)

local closeBtn = Instance.new("TextButton", frame)
closeBtn.Text = "Закрити"
closeBtn.Size = UDim2.new(0.95, 0, 0, 30)
closeBtn.Position = UDim2.new(0.025, 0, 1, -35)
closeBtn.BackgroundColor3 = Color3.fromRGB(80, 80, 80)

closeBtn.MouseButton1Click:Connect(function()
    gui:Destroy()
end)

-- ФУНКЦІЯ АВТОМАТИЧНОГО ЗБОРУ ПРЕДМЕТІВ
spawn(function()
    while true do
        if autoCollect and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
            for _, obj in pairs(workspace:GetChildren()) do
                -- Змінити "ItemSpawn" на фактичну назву предметів у грі, якщо потрібно
                if obj:IsA("Part") and obj.Name == "ItemSpawn" then
                    pcall(function()
                        firetouchinterest(player.Character.HumanoidRootPart, obj, 0)
                        wait(0.1)
                        firetouchinterest(player.Character.HumanoidRootPart, obj, 1)
                    end)
                end
            end
        end
        wait(1.5) -- Частота перевірки (можна змінити)
    end
end)
