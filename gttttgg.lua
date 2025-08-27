--== YBA Delta — Only AutoFarm (увімкнено за замовчуванням) ==--

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local LocalPlayer = Players.LocalPlayer
local HttpService = game:GetService("HttpService")

-- ====== Конфіг ======
local Config = {
    AutoFarm = true,            -- увімкнено одразу
    CollectDelay = 0.28,       -- пауза після спроби підбору
    HopDistance = 9999,         -- необмежено (телепорт на предмет)
    NamesHint = { "arrow","rok","roha","mask","fruit","stand","sword","part","item" } -- додай свої підказки якщо треба
}
-- ======================

-- Сервіс VirtualInputManager (фолбек для натискання E)
local Vim
pcall(function() Vim = game:GetService("VirtualInputManager") end)

-- Просте GUI
local playerGui = LocalPlayer:WaitForChild("PlayerGui")
local screenGui = Instance.new("ScreenGui", playerGui)
screenGui.Name = "YBA_AutoFarmOnly"
screenGui.ResetOnSpawn = false

local frame = Instance.new("Frame", screenGui)
frame.Size = UDim2.new(0, 240, 0, 120)
frame.Position = UDim2.new(0, 12, 0.28, 0)
frame.BackgroundColor3 = Color3.fromRGB(30,30,30)
frame.BorderSizePixel = 0
frame.Active = true
frame.Draggable = true

local title = Instance.new("TextLabel", frame)
title.Size = UDim2.new(1,0,0,28)
title.Position = UDim2.new(0,0,0,0)
title.BackgroundColor3 = Color3.fromRGB(42,42,42)
title.Text = "YBA AutoFarm — Only"
title.TextColor3 = Color3.new(1,1,1)
title.Font = Enum.Font.SourceSansSemibold
title.TextSize = 15

local toggleBtn = Instance.new("TextButton", frame)
toggleBtn.Size = UDim2.new(1,-16,0,32)
toggleBtn.Position = UDim2.new(0,8,0,36)
toggleBtn.Font = Enum.Font.SourceSans
toggleBtn.TextSize = 14

local status = Instance.new("TextLabel", frame)
status.Size = UDim2.new(1,-16,0,20)
status.Position = UDim2.new(0,8,0,76)
status.BackgroundTransparency = 1
status.TextColor3 = Color3.fromRGB(200,200,200)
status.Text = "Статус: очікування..."
status.Font = Enum.Font.Code
status.TextSize = 14

local log = Instance.new("TextLabel", frame)
log.Size = UDim2.new(1,-16,0,16)
log.Position = UDim2.new(0,8,0,96)
log.BackgroundTransparency = 1
log.TextColor3 = Color3.fromRGB(160,255,160)
log.Font = Enum.Font.Code
log.TextSize = 13
log.Text = "Лог: —"

local function refreshToggle()
    toggleBtn.BackgroundColor3 = Config.AutoFarm and Color3.fromRGB(0,150,0) or Color3.fromRGB(150,0,0)
    toggleBtn.Text = "AutoFarm: " .. (Config.AutoFarm and "ON" or "OFF")
end

toggleBtn.MouseButton1Click:Connect(function()
    Config.AutoFarm = not Config.AutoFarm
    refreshToggle()
end)
refreshToggle()

local function setStatus(s)
    status.Text = "Статус: " .. tostring(s)
end
local function setLog(s)
    log.Text = "Лог: " .. tostring(s)
end

-- ======= Хелпери =======
local function hrp()
    local c = LocalPlayer.Character
    if c then return c:FindFirstChild("HumanoidRootPart") end
end

local function str_find_any(s, arr)
    if not s then return false end
    s = string.lower(tostring(s))
    for _,k in ipairs(arr) do
        if s:find(string.lower(k), 1, true) then return true end
    end
    return false
end

local function findPrimaryPart(inst)
    if not inst then return nil end
    if inst:IsA("BasePart") then return inst end
    if inst.PrimaryPart and inst.PrimaryPart:IsA("BasePart") then return inst.PrimaryPart end
    for _,d in ipairs(inst:GetDescendants()) do
        if d:IsA("BasePart") then return d end
    end
    return nil
end

-- Спроба підняти предмет (ProximityPrompt -> ClickDetector -> Touch)
local function tryPickup(target)
    if not target then return false end
    local root = hrp()
    if not root then return false end

    local part = findPrimaryPart(target)
    if not part then return false end

    -- teleport near
    pcall(function() root.CFrame = part.CFrame + Vector3.new(0,3,0) end)
    task.wait(0.06)

    -- 1) ProximityPrompt
    for _,d in ipairs((target:IsA("Model") and target:GetDescendants() or target:GetChildren())) do
        if d:IsA("ProximityPrompt") then
            if type(fireproximityprompt) == "function" then
                pcall(function() fireproximityprompt(d) end)
                setLog("ProximityPrompt")
                return true
            else
                -- фолбек: натиснути E через VirtualInputManager (якщо є)
                if Vim then
                    pcall(function()
                        Vim:SendKeyEvent(true, Enum.KeyCode.E, false, game)
                        task.wait(0.08)
                        Vim:SendKeyEvent(false, Enum.KeyCode.E, false, game)
                    end)
                    setLog("E-press (VIM)")
                    return true
                end
            end
        end
    end

    -- 2) ClickDetector
    local cd = target:FindFirstChildOfClass("ClickDetector") or (part and part:FindFirstChildOfClass("ClickDetector"))
    if cd and type(fireclickdetector) == "function" then
        pcall(function() fireclickdetector(cd) end)
        setLog("ClickDetector")
        return true
    end

    -- 3) Touch
    if type(firetouchinterest) == "function" then
        pcall(function()
            firetouchinterest(root, part, 0)
            firetouchinterest(root, part, 1)
        end)
        setLog("Touch")
        return true
    end

    return false
end

-- Знаходить кандидати предметів (кілька можливих місць)
local function gatherItems()
    local out = {}
    local parents = {
        Workspace:FindFirstChild("Item_Spawns") and Workspace.Item_Spawns:FindFirstChild("Items"),
        Workspace:FindFirstChild("ItemSpawns"),
        Workspace:FindFirstChild("Items"),
        Workspace:FindFirstChild("Entities"),
        Workspace
    }
    for _,parent in ipairs(parents) do
        if parent and parent:IsA("Instance") then
            for _,v in ipairs(parent:GetDescendants()) do
                if (v:IsA("Model") or v:IsA("BasePart")) and v.Parent ~= LocalPlayer.Character then
                    local name = v.Name or ""
                    if str_find_any(name, Config.NamesHint) then
                        table.insert(out, v)
                    else
                        -- також перевірити ProximityPrompt.ObjectText
                        local pp = v:FindFirstChildOfClass("ProximityPrompt")
                        if pp and str_find_any(pp.ObjectText or pp.Name, Config.NamesHint) then
                            table.insert(out, v)
                        end
                    end
                end
            end
            if #out > 0 then return out end
        end
    end
    return out
end

-- ======= Основний цикл AutoFarm =======
task.spawn(function()
    while true do
        if Config.AutoFarm then
            local root = hrp()
            if not root then
                setStatus("чекаю на персонажа...")
                task.wait(1)
            else
                local items = gatherItems()
                if #items == 0 then
                    setStatus("нема предметів поблизу")
                    setLog("нема предметів")
                    task.wait(0.8)
                else
                    setStatus("фарм предметів ("..tostring(#items)..")")
                    for _,itm in ipairs(items) do
                        if not Config.AutoFarm then break end
                        local ok, err = pcall(function() return tryPickup(itm) end)
                        if ok and err then
                            -- успішно піднято (tryPickup повертає true)
                        end
                        task.wait(Config.CollectDelay)
                    end
                end
            end
        else
            setStatus("AutoFarm вимкнено")
        end
        task.wait(0.3)
    end
end)

-- Початковий статус
setStatus("запущено, AutoFarm: "..tostring(Config.AutoFarm))
setLog("Готово")
