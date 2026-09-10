--[[
    Best Egg + Valor Estimado (estilo Lennon)
    Base do script que você mandou + tabela de índice
]]

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local UserInputService = game:GetService("UserInputService")

local LocalPlayer = Players.LocalPlayer
local Networking = ReplicatedStorage:FindFirstChild("Packages") and ReplicatedStorage.Packages:FindFirstChild("Networking")

-- ====================== TABELA DE VALORES BASE (ÍNDICE) ======================
-- Valores aproximados atualizados (setembro 2026). Tamanho multiplica em cima.
local PetIncome = {
    -- Forest
    ["Chicken"] = 1,
    ["Dog"] = 2,
    ["Bird"] = 8,
    ["Owl"] = 35,
    ["Raccoon"] = 45,
    ["Fox"] = 180,
    ["Bear"] = 240,
    ["Brr Brr Patapim"] = 1800,

    -- Lake
    ["Frog"] = 3,
    ["Duckling"] = 4,
    ["Catfish"] = 12,
    ["Turtle"] = 60,
    ["Trulimero Trulicina"] = 260,
    ["Swan"] = 320,
    ["Axolotl"] = 2800,
    ["Leviathan"] = 220000,

    -- Desert
    ["Jerboa"] = 6,
    ["Fennec"] = 18,
    ["Camel"] = 75,
    ["Snake"] = 3600,
    ["Scorpion"] = 18500,
    ["Sand Spider"] = 16000,
    ["Royal Sphinx"] = 280000,

    -- Jungle
    ["Toucan"] = 110,
    ["Chimpanzee"] = 90,
    ["Crocodile"] = 420,
    ["Gorilla"] = 4800,
    ["Orangutini Ananassini"] = 5500,
    ["Spider"] = 22000,
    ["Tiger"] = 28000,
    ["King Snake"] = 3500000,

    -- Snow
    ["Penguin"] = 140,
    ["Walrus"] = 600,
    ["Polar Bear"] = 7000,
    ["Sabertooth Tiger"] = 35000,
    ["Mammoth"] = 42000,
    ["King Mammoth"] = 400000,
    ["Yeti"] = 5000000,
    ["Ice Dragon"] = 65000000,

    -- Volcano
    ["Lava Frog"] = 850,
    ["Flaming Bull"] = 9500,
    ["Lava Iguana"] = 11000,
    ["Chillin Chilli"] = 55000,
    ["Cerberus"] = 8000000,
    ["Phoenix"] = 85000000,
    ["Lava Dragon"] = 100000000,

    -- Abyss Ocean
    ["Shark"] = 15000,
    ["Orca"] = 80000,
    ["Whale Shark"] = 700000,
    ["Beluga Whale"] = 850000,
    ["Kraken"] = 15000000,
    ["El Maja"] = 130000000,

    -- Prehistoric
    ["Ankylosaurus"] = 120000,
    ["T-Rex"] = 25000000,
    ["TRex"] = 25000000,
    ["Tralaledon"] = 32000000,
    ["Mosasaurus"] = 180000000,
    ["Bronto"] = 1500000,

    -- Cosmic
    ["Cosmic Dragon"] = 60000000,
    ["Cosmic Skeleton Boss"] = 45000000,
    ["Eternal Lunar Dragon"] = 250000000,
    ["Unicorn"] = 1000000000,

    -- Cherry Blossom / Titan
    ["Stag"] = 145000000,
    ["Oni Tiger"] = 600000000,
    ["Kitsune"] = 1800000000,
    ["Gorilla King"] = 880000000,
    ["Nightflame"] = 3000000000,
    ["Mutant Shark"] = 215000000,
}

local RARITY_ORDER = {
    Common = 1, Uncommon = 2, Rare = 3, Epic = 4,
    Legendary = 5, Mythic = 6, Cosmic = 7,
    Secret = 8, Divine = 9, Eternal = 10
}

local Config = {
    Loop = false,
    CurrentTarget = nil,
    EggList = {},
    LastUpdate = 0
}

-- ====================== FUNÇÕES ======================
local function getRemote(name)
    return Networking and Networking:FindFirstChild(name)
end

local function invoke(name, ...)
    local remote = getRemote(name)
    if not remote then return nil end
    if remote:IsA("RemoteFunction") then
        local ok, result = pcall(remote.InvokeServer, remote, ...)
        return ok and result or nil
    end
    pcall(remote.FireServer, remote, ...)
    return nil
end

local function formatValue(n)
    if n >= 1e9 then return string.format("%.2fB", n / 1e9)
    elseif n >= 1e6 then return string.format("%.2fM", n / 1e6)
    elseif n >= 1e3 then return string.format("%.1fK", n / 1e3)
    else return tostring(math.floor(n)) end
end

local function getSizeMultiplier(egg)
    -- Tenta pegar tamanho real do ovo
    local scale = egg.AssetScale or egg.Scale or egg.Size or egg.Weight
    if type(scale) == "number" and scale > 0 then
        -- Multiplicador aproximado (tamanho maior = mais valor)
        return math.clamp(scale, 0.7, 4.0)
    end

    if egg.BoundsSize then
        local mag = egg.BoundsSize.Magnitude
        if mag > 0 then
            return math.clamp(mag / 8, 0.8, 3.5) -- ajuste fino
        end
    end

    return 1.0 -- tamanho normal
end

local function getEggList(force)
    if not force and tick() - Config.LastUpdate < 1.4 then
        return Config.EggList
    end

    local data = invoke("RF/EggWorld/AskFieldEggSnapshot")
    if not data or type(data.Records) ~= "table" then
        return Config.EggList
    end

    local list = {}

    for _, egg in pairs(data.Records) do
        if egg.State == "Slot" and egg.Uid then
            local pos
            local slotFolder = Workspace:FindFirstChild("AreaEggSlotsClient")
            local slot = slotFolder and slotFolder:FindFirstChild(egg.Uid)
            if slot then
                local part = slot.PrimaryPart or slot:FindFirstChild("Hitbox") or slot:FindFirstChildWhichIsA("BasePart")
                if part then pos = part.Position end
            end
            if not pos then
                local cf = egg.BoundsCFrame or egg.BottomCFrame
                if cf then pos = cf.Position end
            end

            if pos then
                local rarity = egg.Rarity or egg.RarityName or egg.Tier or egg.RarityId
                if type(rarity) == "table" then
                    rarity = rarity.DisplayName or rarity._id or rarity.Name or rarity.Id
                end
                rarity = tostring(rarity or "Unknown")

                local petName = egg.PetName or egg.Species or egg.DisplayName or egg.Name or rarity
                petName = tostring(petName)

                local base = PetIncome[petName] or PetIncome[rarity] or 0
                local sizeMult = getSizeMultiplier(egg)
                local estimated = base * sizeMult

                -- Mutação básica (se existir)
                if egg.BaseMutation or (type(egg.Mutations) == "table" and next(egg.Mutations)) then
                    estimated = estimated * 1.8 -- média aproximada
                end

                table.insert(list, {
                    uid = egg.Uid,
                    rarity = rarity,
                    petName = petName,
                    rank = RARITY_ORDER[rarity] or 0,
                    pos = pos,
                    value = estimated,
                    sizeMult = sizeMult,
                    mutated = egg.BaseMutation or (type(egg.Mutations) == "table" and next(egg.Mutations) ~= nil)
                })
            end
        end
    end

    table.sort(list, function(a, b)
        if a.value ~= b.value then return a.value > b.value end
        return a.rank > b.rank
    end)

    Config.EggList = list
    Config.LastUpdate = tick()
    return list
end

local function getHRP()
    local char = LocalPlayer.Character
    return char and char:FindFirstChild("HumanoidRootPart")
end

local function teleportTo(pos)
    local hrp = getHRP()
    if hrp and pos then
        hrp.CFrame = CFrame.new(pos + Vector3.new(0, 3.5, 0))
    end
end

-- ====================== UI ======================
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "BestEggHub"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.Parent = (gethui and gethui()) or game:GetService("CoreGui")

local Main = Instance.new("Frame")
Main.Size = UDim2.fromOffset(280, 158)
Main.Position = UDim2.new(0.5, -140, 0.12, 0)
Main.BackgroundColor3 = Color3.fromRGB(16, 16, 20)
Main.BorderSizePixel = 0
Main.Parent = ScreenGui
Instance.new("UICorner", Main).CornerRadius = UDim.new(0, 12)
local stroke = Instance.new("UIStroke", Main)
stroke.Color = Color3.fromRGB(55, 55, 65)
stroke.Thickness = 1

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, -16, 0, 20)
Title.Position = UDim2.fromOffset(12, 8)
Title.BackgroundTransparency = 1
Title.Font = Enum.Font.GothamBold
Title.TextSize = 13
Title.TextColor3 = Color3.fromRGB(230, 230, 240)
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.Text = "BEST EGG HUB"
Title.Parent = Main

local BestCard = Instance.new("Frame")
BestCard.Size = UDim2.new(1, -20, 0, 54)
BestCard.Position = UDim2.fromOffset(10, 32)
BestCard.BackgroundColor3 = Color3.fromRGB(26, 26, 32)
BestCard.BorderSizePixel = 0
BestCard.Parent = Main
Instance.new("UICorner", BestCard).CornerRadius = UDim.new(0, 8)

local BestTitle = Instance.new("TextLabel")
BestTitle.Size = UDim2.new(1, -16, 0, 14)
BestTitle.Position = UDim2.fromOffset(10, 5)
BestTitle.BackgroundTransparency = 1
BestTitle.Font = Enum.Font.Gotham
BestTitle.TextSize = 11
BestTitle.TextColor3 = Color3.fromRGB(150, 150, 165)
BestTitle.TextXAlignment = Enum.TextXAlignment.Left
BestTitle.Text = "BEST EGG"
BestTitle.Parent = BestCard

local BestName = Instance.new("TextLabel")
BestName.Size = UDim2.new(0.62, 0, 0, 22)
BestName.Position = UDim2.fromOffset(10, 24)
BestName.BackgroundTransparency = 1
BestName.Font = Enum.Font.GothamBold
BestName.TextSize = 15
BestName.TextColor3 = Color3.fromRGB(255, 255, 255)
BestName.TextXAlignment = Enum.TextXAlignment.Left
BestName.Text = "Nenhum"
BestName.Parent = BestCard

local BestValue = Instance.new("TextLabel")
BestValue.Size = UDim2.new(0.35, -8, 0, 22)
BestValue.Position = UDim2.new(0.62, 0, 0, 24)
BestValue.BackgroundTransparency = 1
BestValue.Font = Enum.Font.GothamBold
BestValue.TextSize = 14
BestValue.TextColor3 = Color3.fromRGB(90, 220, 130)
BestValue.TextXAlignment = Enum.TextXAlignment.Right
BestValue.Text = "-"
BestValue.Parent = BestCard

local TeleFrame = Instance.new("Frame")
TeleFrame.Size = UDim2.new(1, -20, 0, 44)
TeleFrame.Position = UDim2.fromOffset(10, 96)
TeleFrame.BackgroundColor3 = Color3.fromRGB(26, 26, 32)
TeleFrame.BorderSizePixel = 0
TeleFrame.Parent = Main
Instance.new("UICorner", TeleFrame).CornerRadius = UDim.new(0, 8)

local TeleLabel = Instance.new("TextLabel")
TeleLabel.Size = UDim2.new(0.5, 0, 1, 0)
TeleLabel.Position = UDim2.fromOffset(12, 0)
TeleLabel.BackgroundTransparency = 1
TeleLabel.Font = Enum.Font.GothamBold
TeleLabel.TextSize = 13
TeleLabel.TextColor3 = Color3.fromRGB(220, 220, 230)
TeleLabel.TextXAlignment = Enum.TextXAlignment.Left
TeleLabel.Text = "TELEGUIADO"
TeleLabel.Parent = TeleFrame

local LoopText = Instance.new("TextLabel")
LoopText.Size = UDim2.fromOffset(38, 18)
LoopText.Position = UDim2.new(1, -92, 0.5, -9)
LoopText.BackgroundTransparency = 1
LoopText.Font = Enum.Font.Gotham
LoopText.TextSize = 11
LoopText.TextColor3 = Color3.fromRGB(150, 150, 165)
LoopText.Text = "LOOP"
LoopText.Parent = TeleFrame

local LoopBtn = Instance.new("TextButton")
LoopBtn.Size = UDim2.fromOffset(36, 20)
LoopBtn.Position = UDim2.new(1, -48, 0.5, -10)
LoopBtn.BackgroundColor3 = Color3.fromRGB(45, 45, 55)
LoopBtn.Text = ""
LoopBtn.AutoButtonColor = false
LoopBtn.Parent = TeleFrame
Instance.new("UICorner", LoopBtn).CornerRadius = UDim.new(1, 0)

local LoopCircle = Instance.new("Frame")
LoopCircle.Size = UDim2.fromOffset(16, 16)
LoopCircle.Position = UDim2.fromOffset(2, 2)
LoopCircle.BackgroundColor3 = Color3.fromRGB(200, 200, 210)
LoopCircle.BorderSizePixel = 0
LoopCircle.Parent = LoopBtn
Instance.new("UICorner", LoopCircle).CornerRadius = UDim.new(1, 0)

-- ====================== LÓGICA ======================
local function updateUI()
    local list = getEggList(true)
    if #list == 0 then
        BestName.Text = "Nenhum ovo"
        BestValue.Text = "-"
        Config.CurrentTarget = nil
        return
    end

    local best = list[1]
    Config.CurrentTarget = best

    local name = best.petName
    if best.mutated then name = name .. " MUT" end
    BestName.Text = name
    BestValue.Text = formatValue(best.value)
end

LoopBtn.MouseButton1Click:Connect(function()
    Config.Loop = not Config.Loop
    if Config.Loop then
        LoopBtn.BackgroundColor3 = Color3.fromRGB(35, 150, 85)
        TweenService:Create(LoopCircle, TweenInfo.new(0.15), {Position = UDim2.fromOffset(18, 2)}):Play()
    else
        LoopBtn.BackgroundColor3 = Color3.fromRGB(45, 45, 55)
        TweenService:Create(LoopCircle, TweenInfo.new(0.15), {Position = UDim2.fromOffset(2, 2)}):Play()
    end
end)

BestCard.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        if Config.CurrentTarget then
            teleportTo(Config.CurrentTarget.pos)
        end
    end
end)

task.spawn(function()
    while ScreenGui.Parent do
        updateUI()
        if Config.Loop and Config.CurrentTarget then
            teleportTo(Config.CurrentTarget.pos)
        end
        task.wait(0.9)
    end
end)

-- Arrastar
local dragging, dragStart, startPos
Main.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragStart = input.Position
        startPos = Main.Position
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then dragging = false end
        end)
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        local delta = input.Position - dragStart
        Main.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
end)

print("[Best Egg Hub] Carregado com tabela de valores!")
