-- YBA Delta: AutoFarm + Smart Pickup + AutoSell + AutoPlay + AutoRecover
-- Зберігає налаштування, показує статус у GUI
-- Якщо щось не бере — дивись лог внизу вікна

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local HttpService = game:GetService("HttpService")
local Workspace = game:GetService("Workspace")
local TeleportService = game:GetService("TeleportService")
local Vim = game:GetService("VirtualInputManager")

-- ===== Config =====
local ConfigFile = "YBA_Config.json"
local Config = {
  AutoFarm = true,
  AutoSell = true,
  AutoPlay = true,
  AutoRejoin = true,
  CollectDelay = 0.25,
  HopDistance = 150,        -- макс. дистанція для телепорту на предмет
  NamesHint = { "arrow","rok","roka","mask","rib","corpse","fruit","pure","lucky" }, -- фільтр назв
}

-- load config
pcall(function()
  if isfile and isfile(ConfigFile) then
    local t = HttpService:JSONDecode(readfile(ConfigFile))
    for k,v in pairs(t) do if Config[k] ~= nil then Config[k] = v end end
  end
end)
local function SaveCfg() pcall(function() writefile(ConfigFile, HttpService:JSONEncode(Config)) end) end

-- ===== GUI =====
local pg = LocalPlayer:WaitForChild("PlayerGui")
local gui = Instance.new("ScreenGui")
gui.Name = "YBA_AIO"
gui.ResetOnSpawn = false
gui.Parent = pg

local frame = Instance.new("Frame", gui)
frame.Size = UDim2.new(0, 280, 0, 260)
frame.Position = UDim2.new(0, 12, 0.25, 0)
frame.BackgroundColor3 = Color3.fromRGB(30,30,30)
frame.Active = true
frame.Draggable = true
frame.BorderSizePixel = 0

local title = Instance.new("TextLabel", frame)
title.Size = UDim2.new(1,0,0,28)
title.BackgroundColor3 = Color3.fromRGB(45,45,45)
title.TextColor3 = Color3.new(1,1,1)
title.Text = "YBA Δ — AutoFarm / Sell / Recover"
title.Font = Enum.Font.SourceSansSemibold
title.TextSize = 15

local function mkToggle(y, label, key)
  local b = Instance.new("TextButton", frame)
  b.Size = UDim2.new(1,-14,0,30)
  b.Position = UDim2.new(0,7,0,y)
  local function refresh()
    b.BackgroundColor3 = Config[key] and Color3.fromRGB(0,160,0) or Color3.fromRGB(160,0,0)
    b.Text = label..": "..(Config[key] and "ON" or "OFF")
    b.TextColor3 = Color3.new(1,1,1); b.Font = Enum.Font.SourceSansSemibold; b.TextSize = 14
  end
  refresh()
  b.MouseButton1Click:Connect(function()
    Config[key] = not Config[key]; SaveCfg(); refresh()
  end)
end

mkToggle(36,"AutoFarm","AutoFarm")
mkToggle(72,"AutoSell","AutoSell")
mkToggle(108,"AutoPlay","AutoPlay")
mkToggle(144,"AutoRejoin","AutoRejoin")

local status = Instance.new("TextLabel", frame)
status.Size = UDim2.new(1,-14,0,18)
status.Position = UDim2.new(0,7,0,180)
status.BackgroundTransparency = 1
status.TextColor3 = Color3.new(1,1,1)
status.Font = Enum.Font.Code
status.TextXAlignment = Enum.TextXAlignment.Left
status.TextSize = 14
status.Text = "Статус: очікування..."

local logBox = Instance.new("TextLabel", frame)
logBox.Size = UDim2.new(1,-14,0,54)
logBox.Position = UDim2.new(0,7,0,200)
logBox.BackgroundColor3 = Color3.fromRGB(20,20,20)
logBox.TextColor3 = Color3.fromRGB(200,255,200)
logBox.Font = Enum.Font.Code
logBox.TextXAlignment = Enum.TextXAlignment.Left
logBox.TextYAlignment = Enum.TextYAlignment.Top
logBox.TextWrapped = true
logBox.TextSize = 13
logBox.Text = "Лог:\n"
local function log(msg)
  logBox.Text = ("Лог:\n%s"):format(msg)
end

-- ===== Helpers =====
local function hrp()
  local c = LocalPlayer.Character
  if c then return c:FindFirstChild("HumanoidRootPart") end
end

local function str_find_any(s, arr)
  s = string.lower(tostring(s))
  for _,k in ipairs(arr) do if s:find(k) then return true end end
  return false
end

-- Універсальний підбір предмета
local function tryPickupFor(modelOrPart)
  local c = LocalPlayer.Character
  if not c then return false,"no char" end
  local root = hrp(); if not root then return false,"no hrp" end

  -- знайти «частину» для телепорту
  local part = nil
  if modelOrPart:IsA("BasePart") then part = modelOrPart
  elseif modelOrPart:IsA("Model") then
    part = modelOrPart.PrimaryPart
    if not part then
      for _,d in ipairs(modelOrPart:GetDescendants()) do
        if d:IsA("BasePart") then part = d break end
      end
    end
  end
  if not part then return false,"no part" end

  pcall(function() root.CFrame = part.CFrame + Vector3.new(0,3,0) end)

  -- 1) ProximityPrompt
  local prompt = nil
  for _,d in ipairs((modelOrPart:IsA("Model") and modelOrPart:GetDescendants() or modelOrPart:GetChildren())) do
    if d:IsA("ProximityPrompt") then prompt = d break end
  end
  if prompt then
    if typeof(fireproximityprompt) == "function" then
      fireproximityprompt(prompt)
      log("ProximityPrompt ✔ ("..(prompt.ObjectText or prompt.Name)..")")
      return true,"prompt"
    else
      -- емулюємо клавішу E біля предмета
      Vim:SendKeyEvent(true, Enum.KeyCode.E, false, game)
      task.wait(0.12)
      Vim:SendKeyEvent(false, Enum.KeyCode.E, false, game)
      log("E-press ✔ (нема fireproximityprompt)")
      return true,"E"
    end
  end

  -- 2) ClickDetector
  local cd = (modelOrPart:IsA("Model") and modelOrPart:FindFirstChildOfClass("ClickDetector"))
             or (part and part:FindFirstChildOfClass("ClickDetector"))
  if cd and typeof(fireclickdetector) == "function" then
    fireclickdetector(cd)
    log("ClickDetector ✔")
    return true,"click"
  end

  -- 3) Дотик
  if typeof(firetouchinterest) == "function" then
    firetouchinterest(root, part, 0)
    firetouchinterest(root, part, 1)
    log("Touch ✔")
    return true,"touch"
  end

  return false,"no method"
end

-- Пошук кандидатів на предмети (різні мапи/патчі)
local function iterItems()
  local list = {}
  local parentCandidates = {
    Workspace:FindFirstChild("Item_Spawns") and Workspace.Item_Spawns:FindFirstChild("Items"),
    Workspace:FindFirstChild("ItemSpawns"),
    Workspace:FindFirstChild("Items"),
    Workspace:FindFirstChild("Entities"),
    Workspace
  }
  for _,parent in ipairs(parentCandidates) do
    if parent and parent:IsA("Instance") then
      for _,v in ipairs(parent:GetDescendants()) do
        if (v:IsA("Model") or v:IsA("BasePart")) and v.Parent ~= LocalPlayer.Character then
          local name = v.Name or ""
          if str_find_any(name, Config.NamesHint) then
            table.insert(list, v)
          else
            -- якщо є Prompt з назвою — теж беремо
            local pp = v:FindFirstChildOfClass("ProximityPrompt")
            if pp and str_find_any(pp.ObjectText or pp.Name, Config.NamesHint) then
              table.insert(list, v)
            end
          end
        end
      end
      if #list > 0 then return list end
    end
  end
  return list
end

-- АвтоPlay (меню)
local function autoPlayOnce()
  if not Config.AutoPlay then return end
  task.spawn(function()
    task.wait(4)
    local clicked = false
    pcall(function()
      for _,b in ipairs(game:GetDescendants()) do
        if b:IsA("TextButton") and b.Text and string.lower(b.Text):find("play") then
          if typeof(firesignal) == "function" then firesignal(b.MouseButton1Click)
          else pcall(function() b.MouseButton1Click:Fire() end) end
          clicked = true; break
        end
      end
    end)
    status.Text = clicked and "Статус: натиснув Play" or "Статус: не знайшов Play"
  end)
end

-- ===== AutoFarm loop =====
task.spawn(function()
  while true do
    if Config.AutoFarm then
      local cands = iterItems()
      if #cands == 0 then
        status.Text = "Статус: немає предметів поблизу"
      else
        for _,it in ipairs(cands) do
          if not Config.AutoFarm then break end
          -- дистанція фільтр
          local root = hrp()
          if root then
            local part = it:IsA("Model") and (it.PrimaryPart or it:FindFirstChildWhichIsA("BasePart")) or it
            if part and (root.Position - part.Position).Magnitude <= Config.HopDistance or true then
              local ok, how = tryPickupFor(it)
              status.Text = ok and ("Статус: підібрав ("..how..")") or "Статус: не вдалось (спробую інше)"
              task.wait(Config.CollectDelay)
            end
          end
        end
      end
    end
    task.wait(0.5)
  end
end)

-- ===== AutoSell loop =====
task.spawn(function()
  while true do
    if Config.AutoSell then
      local char = LocalPlayer.Character
      local bp = LocalPlayer:FindFirstChild("Backpack")
      if char and bp then
        local remote = char:FindFirstChild("RemoteEvent")
        local hadTools = false
        for _,tool in ipairs(bp:GetChildren()) do
          if tool:IsA("Tool") then
            hadTools = true
            -- 1) Спробувати через RemoteEvent → EndDialogue (Merchant)
            local ok = false
            if remote and typeof(remote.FireServer) == "function" then
              ok = pcall(function()
                remote:FireServer("EndDialogue", { NPC = "Merchant", Option = "Option2", Dialogue = "Dialogue5" })
              end)
            end
            if ok then
              log("AutoSell: через RemoteEvent ✔")
            else
              -- 2) Fallback: знайти Merchant з ProximityPrompt і натискати E
              local merchant = nil
              for _,m in ipairs(Workspace:GetDescendants()) do
                if m:IsA("Model") and string.lower(m.Name):find("merchant") then merchant = m break end
              end
              local root = hrp()
              local mp = merchant and (merchant.PrimaryPart or merchant:FindFirstChildWhichIsA("BasePart"))
              if merchant and root and mp then
                pcall(function() root.CFrame = mp.CFrame + Vector3.new(0,3,0) end)
                -- натиснути всі промпти, що знайдемо
                for _,d in ipairs(merchant:GetDescendants()) do
                  if d:IsA("ProximityPrompt") then
                    if typeof(fireproximityprompt) == "function" then fireproximityprompt(d)
                    else Vim:SendKeyEvent(true, Enum.KeyCode.E, false, game) task.wait(0.12) Vim:SendKeyEvent(false, Enum.KeyCode.E, false, game) end
                    task.wait(0.25)
                  end
                end
                log("AutoSell: через Merchant prompts (fallback)")
              else
                log("AutoSell: не знайшов Merchant / RemoteEvent ❌")
              end
            end
            task.wait(0.35)
          end
        end
        if not hadTools then
          status.Text = "Статус: інвентар порожній (нічого продавати)"
        end
      end
    end
    task.wait(2.2)
  end
end)

-- ===== AutoRecover (краш / кік) =====
game:GetService("CoreGui").RobloxPromptGui.promptOverlay.ChildAdded:Connect(function(obj)
  if not Config.AutoRejoin then return end
  if obj.Name == "ErrorPrompt" then
    status.Text = "Статус: помилка/розрив — перезаходжу..."
    task.wait(4.5)
    pcall(function() TeleportService:Teleport(game.PlaceId, LocalPlayer) end)
  end
end)

-- ===== On spawn helpers =====
LocalPlayer.CharacterAdded:Connect(function()
  task.wait(1)
  if Config.AutoPlay then autoPlayOnce() end
end)
if Config.AutoPlay then autoPlayOnce() end

-- live status ticker
task.spawn(function()
  while true do
    status.Text = ("AF:%s  AS:%s  AP:%s  AR:%s")
      :format(tostring(Config.AutoFarm), tostring(Config.AutoSell), tostring(Config.AutoPlay), tostring(Config.AutoRejoin))
    task.wait(1.1)
  end
end)
