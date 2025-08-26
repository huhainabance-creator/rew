-- Автоматичний збір і продаж предметів + перезаходження та збереження налаштувань

local Settings = {
    AutoCollect = true,
    AutoSell = true,
    AutoRejoin = true,
}

-- Збереження налаштувань (локально)
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

-- Автоматичне натискання кнопки Play
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

-- Автоматичний збір предметів
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

-- Автоматичний продаж предметів (приклад, треба адаптувати під вашу інвентарну систему)
function AutoSellItems()
    while Settings.AutoSell do
        local backpack = game.Players.LocalPlayer.Backpack
        for _, item in pairs(backpack:GetChildren()) do
            if item:IsA("Tool") then
                -- Приклад: Викликати RemoteEvent для продажу
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

-- Перезаходження при краші
game:GetService("Players").LocalPlayer.OnTeleport:Connect(function(State)
    if State == Enum.TeleportState.Failed and Settings.AutoRejoin then
        wait(2)
        game:GetService("TeleportService"):Teleport(game.PlaceId)
    end
end)

-- Ініціалізація скрипта
LoadSettings()
spawn(AutoPlay)
spawn(AutoCollectItems)
spawn(AutoSellItems)

-- Можна додати GUI для налаштувань, якщо потрібно
