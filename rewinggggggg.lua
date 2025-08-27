-- YBA AutoFarm + AutoSell + AutoRejoin для Delta

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local Workspace = game:GetService("Workspace")
local HttpService = game:GetService("HttpService")
local TeleportService = game:GetService("TeleportService")

local ConfigFile = "YBA_Config.json"
local Config = { AutoFarm = true, AutoSell = true, AutoPlay = true, AutoRejoin = true }

-- Завантаження конфігу
if isfile and isfile(ConfigFile) then
    local ok, data = pcall(readfile, ConfigFile)
    if ok then
        local decoded = HttpService:JSONDecode(data)
        if type(decoded) == "table" then
            for k,v in pairs(decoded) do
                Config[k] = v
            end
        end
    end
end

local function SaveConfig()
    if writefile then
        pcall(writefile, ConfigFile, HttpService:JSONEncode(Config))
    end
end

-- GUI
local ScreenGui = Instance.new("ScreenGui", LocalPlayer:WaitForChild("PlayerGui"))
ScreenGui.Name = "YBAGUI"
ScreenGui.ResetOnSpawn = false

local Frame = Instance.new("Frame", ScreenGui)
Frame.Size = UDim2.new(0, 220, 0, 220)
Frame.Position = UDim2.new(0, 20, 0.3, 0)
Frame.BackgroundColor3 = Color3.fromRGB(35, 35, 35)

local function CreateToggle(name, key, y)
    local btn = Instance.new("TextButton", Frame)
    btn.Size = UDim2.new(1, -10, 0, 30)
    btn.Position = UDim2.new(0, 5, 0, y)
    local function upd()
        btn.BackgroundColor3 = Config[key] and Color3.fromRGB(0,170,0) or Color3.fromRGB(170,0,0)
        btn.Text = name..": "..(Config[key] and "ON" or "OFF")
    end
    upd()
    btn.MouseButton1Click:Connect(function()
        Config[key] = not Config[key]
        SaveConfig()
        upd()
    end)
end

CreateToggle("AutoFarm", "AutoFarm", 10)
CreateToggle("AutoSell", "AutoSell", 50)
CreateToggle("AutoPlay", "AutoPlay", 90)
CreateToggle("AutoRejoin", "AutoRejoin", 130)

-- Кнопка закрити
local Close = Instance.new("TextButton", Frame)
Close.Size = UDim2.new(0, 30, 0, 30)
Close.Position = UDim2.new(1, -35, 0, 5)
Close.BackgroundColor3 = Color3.fromRGB(200,0,0)
Close.Text = "X"
Close.TextColor3 = Color3.fromRGB(255,255,255)
Close.MouseButton1Click:Connect(function()
    ScreenGui.Enabled = false
end)

-- Автоплей
if Config.AutoPlay then
    task.wait(5)
    pcall(function()
        for _, b in pairs(game:GetDescendants()) do
            if b:IsA("TextButton") and b.Text:lower():find("play") then
                firesignal(b.MouseButton1Click)
                break
            end
        end
    end)
end

-- Автофарм предметів
task.spawn(function()
    while task.wait(3) do
        if Config.AutoFarm and Workspace:FindFirstChild("Item_Spawns") and Workspace.Item_Spawns:FindFirstChild("Items") then
            for _, item in pairs(Workspace.Item_Spawns.Items:GetChildren()) do
                if item:IsA("Model") and item.PrimaryPart then
                    local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                    if hrp then
                        hrp.CFrame = item.PrimaryPart.CFrame + Vector3.new(0,3,0)
                        firetouchinterest(hrp, item.PrimaryPart, 0)
                        firetouchinterest(hrp, item.PrimaryPart, 1)
                        task.wait(0.3)
                    end
                end
            end
        end
    end
end)

-- Автопродаж
task.spawn(function()
    while task.wait(5) do
        if Config.AutoSell and LocalPlayer.Character then
            local remote = LocalPlayer.Character:FindFirstChild("RemoteEvent")
            if remote then
                local backpack = LocalPlayer:FindFirstChild("Backpack")
                if backpack then
                    for _, tool in pairs(backpack:GetChildren()) do
                        if tool:IsA("Tool") then
                            remote:FireServer("EndDialogue", {NPC = "Merchant", Option = "Option2", Dialogue = "Dialogue5"})
                            task.wait(0.3)
                        end
                    end
                end
            end
        end
    end
end)

-- Автоперезаход у разі крашу
game:GetService("CoreGui").RobloxPromptGui.promptOverlay.ChildAdded:Connect(function(obj)
    if Config.AutoRejoin and obj.Name == "ErrorPrompt" then
        task.wait(5)
        TeleportService:Teleport(game.PlaceId, LocalPlayer)
    end
end)
