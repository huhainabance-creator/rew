-- Скрипт з графічним вікном для управління автоматичними функціями в YBA

local Settings = {
    AutoCollect = true,
    AutoSell = true,
    AutoRejoin = true,
}

local HttpService = game:GetService("HttpService")
local SettingsFile = "YBA_Settings.json"

function SaveSettings()
    writefile(SettingsFile, HttpService:JSONEncode(Settings))
end

function LoadSettings()
    if isfile(SettingsFile) then
        local content = readfile(SettingsFile)
        Settings = HttpService:JSONDecode(content)
    end
end

function AutoPlay()
    local playBtn = nil
    repeat
        for _,v in pairs(game:GetService("Players").LocalPlayer.PlayerGui:GetDescendants()) do
            if v:IsA("TextButton") and v.Text:lower():find("play") then
                playBtn = v
                break
            end
        end
        wait(0.5)
    until playBtn
    playBtn:Activate()
end

function AutoCollectItems()
    while Settings.AutoCollect do
        for _, obj in pairs(game:GetService("Workspace"):GetChildren()) do
            if obj:IsA("Part") and obj.Name == "ItemSpawn" then
                firetouchinterest(game.Players.LocalPlayer.Character.HumanoidRootPart, obj, 0)
                wait(0.1)
                firetouchinterest(game.Players.LocalPlayer.Character.HumanoidRootPart, obj, 1)
            end
        end
        wait(2)
    end
end

function AutoSellItems()
    while Settings.AutoSell do
        local backpack = game.Players.LocalPlayer.Backpack
        for _, item in pairs(backpack:GetChildren()) do
            if item:IsA("Tool") then
                local sellEvent = game:GetService("ReplicatedStorage"):FindFirstChild("SellItemEvent")
                if sellEvent then
                    sellEvent:FireServer(item.Name)
                    wait(0.2)
                end
            end
        end
        wait(5)
    end
end

game:GetService("Players").LocalPlayer.OnTeleport:Connect(function(State)
    if State == Enum.TeleportState.Failed and Settings.AutoRejoin then
        wait(2)
        game:GetService("TeleportService"):Teleport(game.PlaceId)
    end
end)

-- GUI створення
function CreateWindow()
    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "YBA_AutoWindow"
    ScreenGui.Parent = game.Players.LocalPlayer:WaitForChild("PlayerGui")
    
    local MainFrame = Instance.new("Frame")
    MainFrame.Size = UDim2.new(0, 250, 0, 180)
    MainFrame.Position = UDim2.new(0.5, -125, 0.3, 0)
    MainFrame.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
    MainFrame.BorderSizePixel = 0
    MainFrame.Parent = ScreenGui

    local Title = Instance.new("TextLabel")
    Title.Text = "YBA Авто-Скрипт"
    Title.Size = UDim2.new(1, 0, 0, 30)
    Title.BackgroundTransparency = 1
    Title.TextColor3 = Color3.fromRGB(255, 255, 255)
    Title.Font = Enum.Font.SourceSansBold
    Title.TextSize = 22
    Title.Parent = MainFrame

    local AutoCollectBtn = Instance.new("TextButton")
    AutoCollectBtn.Text = "Авто збір предметів: " .. (Settings.AutoCollect and "ВКЛ" or "ВИКЛ")
    AutoCollectBtn.Size = UDim2.new(0.95, 0, 0, 30)
    AutoCollectBtn.Position = UDim2.new(0.025, 0, 0, 40)
    AutoCollectBtn.BackgroundColor3 = Color3.fromRGB(50, 120, 50)
    AutoCollectBtn.Parent = MainFrame

    AutoCollectBtn.MouseButton1Click:Connect(function()
        Settings.AutoCollect = not Settings.AutoCollect
        AutoCollectBtn.Text = "Авто збір предметів: " .. (Settings.AutoCollect and "ВКЛ" or "ВИКЛ")
        SaveSettings()
    end)

    local AutoSellBtn = Instance.new("TextButton")
    AutoSellBtn.Text = "Авто продаж: " .. (Settings.AutoSell and "ВКЛ" or "ВИКЛ")
    AutoSellBtn.Size = UDim2.new(0.95, 0, 0, 30)
    AutoSellBtn.Position = UDim2.new(0.025, 0, 0, 80)
    AutoSellBtn.BackgroundColor3 = Color3.fromRGB(120, 50, 50)
    AutoSellBtn.Parent = MainFrame

    AutoSellBtn.MouseButton1Click:Connect(function()
        Settings.AutoSell = not Settings.AutoSell
        AutoSellBtn.Text = "Авто продаж: " .. (Settings.AutoSell and "ВКЛ" or "ВИКЛ")
        SaveSettings()
    end)

    local AutoRejoinBtn = Instance.new("TextButton")
    AutoRejoinBtn.Text = "Авто перезаходження: " .. (Settings.AutoRejoin and "ВКЛ" or "ВИКЛ")
    AutoRejoinBtn.Size = UDim2.new(0.95, 0, 0, 30)
    AutoRejoinBtn.Position = UDim2.new(0.025, 0, 0, 120)
    AutoRejoinBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 120)
    AutoRejoinBtn.Parent = MainFrame

    AutoRejoinBtn.MouseButton1Click:Connect(function()
        Settings.AutoRejoin = not Settings.AutoRejoin
        AutoRejoinBtn.Text = "Авто перезаходження: " .. (Settings.AutoRejoin and "ВКЛ" or "ВИКЛ")
        SaveSettings()
    end)

    local CloseBtn = Instance.new("TextButton")
    CloseBtn.Text = "Закрити"
    CloseBtn.Size = UDim2.new(0.95, 0, 0, 30)
    CloseBtn.Position = UDim2.new(0.025, 0, 1, -35)
    CloseBtn.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
    CloseBtn.Parent = MainFrame

    CloseBtn.MouseButton1Click:Connect(function()
        ScreenGui:Destroy()
    end)
end

-- Запуск
LoadSettings()
CreateWindow()
spawn(AutoPlay)
spawn(function() while wait(1) do if Settings.AutoCollect then AutoCollectItems() end end end)
spawn(function() while wait(1) do if Settings.AutoSell then AutoSellItems() end end end)
