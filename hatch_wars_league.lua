-- language: Luau, file: auto_doors_and_manor_hatch.lua, runtime: Potassium / Roblox Client, target: HatchWar
-- Auto Join + Doors 1-8 Knock + 100% Giant Candy Chest Breaker + Trick Boss Solver + Dynamic Max Hatch + 3D Blackout Optimizer

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Stats = game:GetService("Stats")
local VirtualInputManager = game:GetService("VirtualInputManager")
local lp = Players.LocalPlayer

local network = ReplicatedStorage:WaitForChild("Network")
local invokeCustom = network:WaitForChild("Instancing_InvokeCustomFromClient")
local customEggsRemote = network:WaitForChild("CustomEggs_Hatch")
local clickRemote = network:FindFirstChild("Click")
local playAnimRemote = network:FindFirstChild("Eggs_PlayOpenAnimation")
local joinPetBulkRemote = network:FindFirstChild("Breakables_JoinPetBulk")
local playerDamageRemote = network:FindFirstChild("Breakables_PlayerDealDamage")

local lib = ReplicatedStorage:WaitForChild("Library")
local Client = lib:WaitForChild("Client")

local CurrencyCmds = require(Client.CurrencyCmds)
local Gamepasses = require(Client.Gamepasses)
local MasteryCmds = require(Client.MasteryCmds)
local BreakableFrontend = require(Client.BreakableFrontend)
local PlayerPet = require(Client.PlayerPet)

local RETURN_CFRAME = CFrame.new(
    7540.966309, 16.419149, 21965.199219,
    0.999178, -0.000000, 0.040542,
    0.000000, 1.000000, 0.000000,
    -0.040542, -0.000000, 0.999178
)

local DEFAULT_DOOR_COSTS = {
    [1] = 1000000,
    [2] = 1500000,
    [3] = 2000000,
    [4] = 2500000,
    [5] = 3000000,
    [6] = 4000000,
    [7] = 5000000,
    [8] = 6000000
}

-- ============================================================================
-- 0. 3D RENDER OPTIMIZER & BLACKOUT UI (Safe from center auto-clicks)
-- ============================================================================
local is3dEnabled = false

local function initBlackoutGui()
    local guiParent = (gethui and gethui()) or game:GetService("CoreGui") or lp:WaitForChild("PlayerGui")
    local existing = guiParent:FindFirstChild("RenderOptimizerGui")
    if existing then existing:Destroy() end

    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "RenderOptimizerGui"
    screenGui.ResetOnSpawn = false
    screenGui.IgnoreGuiInset = true
    screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    screenGui.Parent = guiParent

    local bg = Instance.new("Frame")
    bg.Name = "BlackoutFrame"
    bg.Size = UDim2.new(1, 0, 1, 0)
    bg.BackgroundColor3 = Color3.fromRGB(8, 8, 10)
    bg.BorderSizePixel = 0
    bg.Active = false
    bg.Visible = not is3dEnabled
    bg.Parent = screenGui

    -- Центр экрана: некликабельный инфо-блок (тапы автокликера проходят насквозь)
    local centerInfo = Instance.new("Frame")
    centerInfo.Name = "CenterInfo"
    centerInfo.Size = UDim2.new(0, 380, 0, 100)
    centerInfo.Position = UDim2.new(0.5, -190, 0.5, -50)
    centerInfo.BackgroundColor3 = Color3.fromRGB(18, 18, 22)
    centerInfo.BorderSizePixel = 0
    centerInfo.Active = false
    centerInfo.Parent = bg

    local centerCorner = Instance.new("UICorner")
    centerCorner.CornerRadius = UDim.new(0, 10)
    centerCorner.Parent = centerInfo

    local centerStroke = Instance.new("UIStroke")
    centerStroke.Color = Color3.fromRGB(38, 38, 48)
    centerStroke.Thickness = 1
    centerStroke.Parent = centerInfo

    local titleLabel = Instance.new("TextLabel")
    titleLabel.Size = UDim2.new(1, 0, 0, 30)
    titleLabel.Position = UDim2.new(0, 0, 0, 12)
    titleLabel.BackgroundTransparency = 1
    titleLabel.Text = "HATCHWAR SUITE ACTIVE"
    titleLabel.TextColor3 = Color3.fromRGB(240, 240, 250)
    titleLabel.Font = Enum.Font.GothamBold
    titleLabel.TextSize = 16
    titleLabel.Active = false
    titleLabel.Parent = centerInfo

    local statLabel = Instance.new("TextLabel")
    statLabel.Name = "StatLabel"
    statLabel.Size = UDim2.new(1, 0, 0, 24)
    statLabel.Position = UDim2.new(0, 0, 0, 42)
    statLabel.BackgroundTransparency = 1
    statLabel.TextColor3 = Color3.fromRGB(150, 150, 165)
    statLabel.Font = Enum.Font.Gotham
    statLabel.TextSize = 13
    statLabel.Text = "RAM: checking..."
    statLabel.Active = false
    statLabel.Parent = centerInfo

    local hintLabel = Instance.new("TextLabel")
    hintLabel.Size = UDim2.new(1, 0, 0, 20)
    hintLabel.Position = UDim2.new(0, 0, 0, 68)
    hintLabel.BackgroundTransparency = 1
    hintLabel.Text = "Кнопка переключения 3D в правом верхнем углу ↗"
    hintLabel.TextColor3 = Color3.fromRGB(100, 100, 120)
    hintLabel.Font = Enum.Font.Gotham
    hintLabel.TextSize = 11
    hintLabel.Active = false
    hintLabel.Parent = centerInfo

    -- Кнопка переключения в ПРАВОМ ВЕРХНЕМ УГЛУ (полная защита от центрального тапа босса)
    local cornerToggleBtn = Instance.new("TextButton")
    cornerToggleBtn.Name = "CornerToggleBtn"
    cornerToggleBtn.Size = UDim2.new(0, 210, 0, 42)
    cornerToggleBtn.Position = UDim2.new(1, -225, 0, 15)
    cornerToggleBtn.BackgroundColor3 = Color3.fromRGB(24, 24, 30)
    cornerToggleBtn.TextColor3 = Color3.fromRGB(255, 75, 75)
    cornerToggleBtn.Font = Enum.Font.GothamBold
    cornerToggleBtn.TextSize = 13
    cornerToggleBtn.Text = "3D RENDER: OFF\n[ Click to Enable 3D ]"
    cornerToggleBtn.AutoButtonColor = true
    cornerToggleBtn.Parent = screenGui

    local cornerBtnRadius = Instance.new("UICorner")
    cornerBtnRadius.CornerRadius = UDim.new(0, 8)
    cornerBtnRadius.Parent = cornerToggleBtn

    local cornerBtnStroke = Instance.new("UIStroke")
    cornerBtnStroke.Color = Color3.fromRGB(255, 75, 75)
    cornerBtnStroke.Thickness = 1.2
    cornerBtnStroke.Parent = cornerToggleBtn

    local function applyRenderState(enabled)
        is3dEnabled = enabled
        pcall(function()
            RunService:Set3dRenderingEnabled(enabled)
        end)
        bg.Visible = not enabled

        if enabled then
            cornerToggleBtn.TextColor3 = Color3.fromRGB(75, 255, 130)
            cornerToggleBtn.Text = "3D RENDER: ON\n[ Click to Disable 3D ]"
            cornerBtnStroke.Color = Color3.fromRGB(75, 255, 130)
        else
            cornerToggleBtn.TextColor3 = Color3.fromRGB(255, 75, 75)
            cornerToggleBtn.Text = "3D RENDER: OFF\n[ Click to Enable 3D ]"
            cornerBtnStroke.Color = Color3.fromRGB(255, 75, 75)
        end
    end

    cornerToggleBtn.MouseButton1Click:Connect(function()
        applyRenderState(not is3dEnabled)
    end)

    task.spawn(function()
        while screenGui.Parent do
            local mem = math.floor(Stats:GetTotalMemoryUsageMb())
            statLabel.Text = string.format("Client RAM: %d MB | Lua Heap: %d KB", mem, gcinfo())
            task.wait(1.5)
        end
    end)

    applyRenderState(false)
end

-- ============================================================================
-- 1. СТРУКТУРНЫЕ МОДУЛИ И ПРОВЕРКИ
-- ============================================================================
local function getHatchWar()
    local things = workspace:FindFirstChild("__THINGS")
    local container = things and things:FindFirstChild("__INSTANCE_CONTAINER")
    local active = container and container:FindFirstChild("Active")
    local hw = active and active:FindFirstChild("HatchWar")
    if hw and hw:FindFirstChild("INTERACT") and hw.INTERACT:FindFirstChild("Doors") then
        return hw
    end
    return nil
end

local function ensureInHatchWar()
    if getHatchWar() then
        return true
    end

    print("[AutoDoors] Outside HatchWar. Entering event...")

    local joinBtn = lp.PlayerGui:FindFirstChild("MainLeft", true) and lp.PlayerGui.MainLeft:FindFirstChild("JoinEvent", true)
    if joinBtn then
        local conns = (getconnections or debug.getconnections)(joinBtn.Activated)
        for _, c in ipairs(conns) do
            c:Fire()
        end
    end

    pcall(function()
        local Signal = require(lib.Signal)
        Signal.Fire("Side Button JoinEvent")
    end)

    local t0 = tick()
    while tick() - t0 < 15 do
        task.wait(0.5)
        if getHatchWar() then
            print("[AutoDoors] HatchWar loaded!")
            task.wait(1.5)
            return true
        end
    end

    return false
end

local function disableEggAnimations()
    local getconns = getconnections or debug.getconnections
    if getconns and playAnimRemote then
        for _, c in ipairs(getconns(playAnimRemote.OnClientEvent)) do
            c:Disable()
        end
    end
    local eggGui = lp.PlayerGui:FindFirstChild("EggOpenAnimation")
    if eggGui then
        eggGui.Enabled = false
    end
end

local function getCoins()
    return (CurrencyCmds and CurrencyCmds.Get and CurrencyCmds.Get("HatchWarCoins")) or 0
end

local function getMaxHatchAmount()
    local save = require(Client.Save).Get()
    if not save then return 1 end

    local totalHatch = save.EggHatchCount or 1

    if Gamepasses and Gamepasses.Owns and Gamepasses.Owns("15 Extra Eggs") then
        totalHatch = totalHatch + 15
    end

    if save.Products and save.Products["40 Extra Eggs"] then
        totalHatch = totalHatch + 40
    end

    if MasteryCmds and MasteryCmds.HasPerk and MasteryCmds.HasPerk("Eggs", "ExtraEggs") then
        local perkPower = MasteryCmds.GetPerkPower("Eggs", "ExtraEggs")
        if perkPower then
            totalHatch = totalHatch + perkPower
        end
    end

    local instancing = Client:FindFirstChild("InstancingCmds")
    if instancing then
        local inst = require(instancing).Get()
        if inst and inst.config and inst.config.MinimumEggHatch then
            if totalHatch < inst.config.MinimumEggHatch then
                totalHatch = math.floor(inst.config.MinimumEggHatch)
            end
        end
    end

    return totalHatch
end

local function getManorEggUid()
    local customCmds = require(Client.CustomEggsCmds)
    local all = customCmds.All and customCmds.All()
    if all then
        for uid, egg in pairs(all) do
            if egg._id == "Manor Egg" and egg._hatchable then
                return uid
            end
        end
    end
    return "9077ad2fd6e442dab98a04fce100a67d"
end

local function getHatchWarModules()
    local hatchWarCmds = require(Client.HatchWarCmds)
    local upvals = (debug.getupvalues or getupvalues)(hatchWarCmds.Networking)
    return upvals and upvals[2]
end

local function getDoorInfo(i)
    local modules = getHatchWarModules()
    local Doors = modules and modules.Doors
    local info = Doors and Doors.DoorInfo and Doors.DoorInfo(i)
    local cost = (info and info.cost) or DEFAULT_DOOR_COSTS[i] or 1000000
    local cooldownEnds = info and info.cooldownEnds
    local isLocked = info and info.lock
    return info, cost, cooldownEnds, isLocked
end

-- ============================================================================
-- 2. 100% ГАРАНТИРОВАННЫЙ РАДАР И ЛОМАНИЕ GIANT CANDY CHEST (ZaLupa Architecture)
-- ============================================================================
local function isCandyData(data, now)
    local attrs = data and data.clientAttributes
    return type(attrs) == "table" and attrs.CandyChest == true and data.parentID == "HatchWar"
        and not data.disableDamage and (not tonumber(attrs.Ends) or tonumber(attrs.Ends) > now)
end

local function findGiantCandyChest()
    local breakables = workspace:FindFirstChild("__THINGS") and workspace.__THINGS:FindFirstChild("Breakables")
    if not breakables then return nil end

    local now = workspace:GetServerTimeNow()

    for _, model in ipairs(breakables:GetChildren()) do
        if model:GetAttribute("ParentID") == "HatchWar" then
            local uid = model:GetAttribute("BreakableUID")
            local data = uid and BreakableFrontend.Get(uid)
            if isCandyData(data, now) then
                return {
                    Model = model,
                    UID = uid,
                    Data = data,
                    Position = model:GetPivot().Position
                }
            end
        end
    end

    for _, model in ipairs(breakables:GetChildren()) do
        local name = string.lower(model.Name)
        if (string.find(name, "candy") or string.find(name, "giant")) and not string.find(name, "boss") then
            local uid = model:GetAttribute("BreakableUID")
            local data = uid and BreakableFrontend.Get(uid)
            return {
                Model = model,
                UID = uid or tostring(model.Name),
                Data = data,
                Position = model:GetPivot().Position
            }
        end
    end

    return nil
end

local function executeCandyChestBreak(targetChest, hrp)
    local model = targetChest.Model
    local uid = targetChest.UID
    local pos = targetChest.Position or model:GetPivot().Position

    local savedReturnPos = hrp.CFrame
    print(string.format("[AutoDoors] 🍬 GIANT CANDY CHEST LOCKED (UID: %s)! Teleporting & attacking...", tostring(uid)))

    hrp.CFrame = CFrame.new(pos.X, pos.Y + 3.5, pos.Z + 5, -1, 0, 0, 0, 1, 0, 0, 0, -1)
    task.wait(0.15)

    local startAttack = tick()
    while model.Parent and getgenv().AutoDoors and (tick() - startAttack < 60) do
        local now = workspace:GetServerTimeNow()
        local liveData = uid and BreakableFrontend.Get(uid)

        if liveData and not isCandyData(liveData, now) then
            break
        end

        local myPets = PlayerPet.GetByPlayer(lp)
        local batch = {}
        if type(myPets) == "table" then
            for _, pet in pairs(myPets) do
                if not pet.destroyed and (pet.owner == lp or tostring(pet.owner) == lp.Name) then
                    pcall(function()
                        if pet.SetTargetWithoutNetworking then
                            pet:SetTargetWithoutNetworking(model)
                        end
                    end)
                    if pet.euid then
                        batch[pet.euid] = uid
                    end
                end
            end
        end

        if next(batch) and joinPetBulkRemote then
            pcall(function()
                joinPetBulkRemote:FireServer(batch)
            end)
        end

        if playerDamageRemote then
            pcall(function()
                playerDamageRemote:FireServer(uid)
            end)
        end

        if clickRemote then
            local hitPart = model:IsA("BasePart") and model or (model.PrimaryPart or model:FindFirstChildWhichIsA("BasePart"))
            if hitPart then
                for _ = 1, 3 do
                    clickRemote:FireServer(hitPart)
                end
            end
        end

        task.wait(0.08)
    end

    print("[AutoDoors] 🍬 Giant Candy Chest broken! Waiting 0.8s for loot drops...")
    task.wait(0.8)
    hrp.CFrame = savedReturnPos
    task.wait(0.2)
    return true
end

local function checkAndAttackGiantCandyChest(hrp)
    local targetChest = findGiantCandyChest()
    if targetChest and targetChest.Model and targetChest.Model.Parent then
        return executeCandyChestBreak(targetChest, hrp)
    end
    return false
end

-- ============================================================================
-- 3. МГНОВЕННЫЙ РЕЗОЛВЕР ТРИК-БОССА (Без ложных срабатываний и пауз)
-- ============================================================================
local function handleTrickBattle()
    local modules = getHatchWarModules()
    local Boss = modules and modules.Boss
    local bossGui = lp.PlayerGui:FindFirstChild("_INSTANCES") and lp.PlayerGui._INSTANCES:FindFirstChild("HatchWarBoss")

    local function isFighting()
        if Boss and Boss.IsFighting then
            local ok, fighting = pcall(Boss.IsFighting)
            if ok and fighting == true then
                return true
            end
        end
        if bossGui and bossGui.Enabled == true then
            return true
        end
        return false
    end

    local active = false
    for _ = 1, 3 do
        if isFighting() then
            active = true
            break
        end
        task.wait(0.05)
    end

    if not active then
        return
    end

    print("[AutoDoors] Trick Battle DETECTED! Auto-tapping...")
    local startFight = tick()

    while isFighting() and (tick() - startFight < 12) do
        if VirtualInputManager then
            local cam = workspace.CurrentCamera
            local vp = cam and cam.ViewportSize or Vector2.new(800, 600)
            VirtualInputManager:SendMouseButtonEvent(vp.X / 2, vp.Y / 2, 0, true, game, 0)
            task.wait(0.015)
            VirtualInputManager:SendMouseButtonEvent(vp.X / 2, vp.Y / 2, 0, false, game, 0)
        end

        if bossGui and bossGui.Enabled and bossGui:FindFirstChild("HUD") then
            for _, btnName in ipairs({"Circle", "Left", "Right"}) do
                local btn = bossGui.HUD:FindFirstChild(btnName)
                if btn and btn.Visible then
                    local conns = (getconnections or debug.getconnections)(btn.Activated)
                    for _, c in ipairs(conns) do
                        c:Fire()
                    end
                end
            end
        end

        task.wait(0.02)
    end

    print("[AutoDoors] Trick Battle FINISHED!")
end

local function attackNearBreakables(hrp)
    local breakables = workspace.__THINGS:FindFirstChild("Breakables")
    if not breakables or not clickRemote then return end

    local target = nil
    for _, b in ipairs(breakables:GetChildren()) do
        if b:IsA("BasePart") or b:IsA("Model") then
            local part = b:IsA("BasePart") and b or b.PrimaryPart
            if part and (part.Position - hrp.Position).Magnitude < 30 then
                target = part
                break
            end
        end
    end

    if target and target.Parent then
        local t0 = tick()
        while target.Parent and (tick() - t0 < 1.5) do
            for _ = 1, 5 do
                clickRemote:FireServer(target)
            end
            task.wait(0.05)
        end
    end
end

local function hasAnyReadyAndAffordable()
    local now = os.time()
    local balance = getCoins()
    for i = 1, 8 do
        local _, cost, cooldownEnds, isLocked = getDoorInfo(i)
        local isReady = (cooldownEnds == nil or now >= cooldownEnds) and not isLocked
        if isReady and balance >= cost then
            return true, i
        end
    end
    return false, nil
end

-- ============================================================================
-- 4. СТАРТ И ОСНОВНОЙ ЦИКЛ
-- ============================================================================
getgenv().AutoDoors = true
disableEggAnimations()
initBlackoutGui()

task.spawn(function()
    local breakables = workspace:WaitForChild("__THINGS"):WaitForChild("Breakables")
    breakables.ChildAdded:Connect(function(child)
        if not getgenv().AutoDoors then return end
        task.wait(0.05)
        local uid = child:GetAttribute("BreakableUID")
        local data = uid and BreakableFrontend.Get(uid)
        local now = workspace:GetServerTimeNow()
        if isCandyData(data, now) or string.find(string.lower(child.Name), "candy") then
            local char = lp.Character
            local hrp = char and char:FindFirstChild("HumanoidRootPart")
            if hrp then
                checkAndAttackGiantCandyChest(hrp)
            end
        end
    end)
end)

task.spawn(function()
    while getgenv().AutoDoors do
        task.wait(60)
        pcall(function()
            collectgarbage("collect")
        end)
    end
end)

task.spawn(function()
    print("[AutoDoors] Suite active with protected top-corner 3D toggle button.")

    while getgenv().AutoDoors do
        if not ensureInHatchWar() then
            task.wait(2)
            continue
        end

        local hatchWar = getHatchWar()
        local doorsFolder = hatchWar and hatchWar.INTERACT:FindFirstChild("Doors")
        if not doorsFolder then
            task.wait(0.5)
            continue
        end

        local char = lp.Character or lp.CharacterAdded:Wait()
        local hrp = char:WaitForChild("HumanoidRootPart")

        checkAndAttackGiantCandyChest(hrp)

        for i = 1, 8 do
            if not getgenv().AutoDoors then break end

            checkAndAttackGiantCandyChest(hrp)

            local doorPart = doorsFolder:FindFirstChild(tostring(i))
            local _, cost, cooldownEnds, isLocked = getDoorInfo(i)
            local now = os.time()
            local balance = getCoins()

            local isReady = (cooldownEnds == nil or now >= cooldownEnds) and not isLocked
            local canAfford = balance >= cost

            if isReady and canAfford and doorPart and doorPart:IsA("BasePart") then
                print(string.format("[AutoDoors] Knocking Door %d (Cost: %d | Coins: %d)...", i, cost, balance))

                local frontPos = doorPart.Position + doorPart.CFrame.LookVector * 4
                hrp.CFrame = CFrame.new(frontPos, doorPart.Position)
                task.wait(0.28)

                local success, result = pcall(function()
                    return invokeCustom:InvokeServer("HatchWar", "HW_Doors_Knock", i)
                end)

                if success and result == true then
                    print(string.format("[AutoDoors] Door %d OPENED!", i))
                    handleTrickBattle()
                    attackNearBreakables(hrp)
                else
                    warn(string.format("[AutoDoors] Door %d knock returned: %s", i, tostring(result)))
                end

                task.wait(0.25)
            elseif isReady and not canAfford then
                print(string.format("[AutoDoors] Door %d ready, but needs %d coins (have %d).", i, cost, balance))
            end
        end

        hrp.CFrame = RETURN_CFRAME
        task.wait(0.25)

        local manorEggUid = getManorEggUid()
        local maxHatch = getMaxHatchAmount()
        local lastChestCheck = 0

        while getgenv().AutoDoors do
            local nowTick = tick()
            if nowTick - lastChestCheck > 0.6 then
                lastChestCheck = nowTick
                if checkAndAttackGiantCandyChest(hrp) then
                    hrp.CFrame = RETURN_CFRAME
                    task.wait(0.2)
                end
            end

            local hasReadyDoor, readyIndex = hasAnyReadyAndAffordable()
            if hasReadyDoor then
                print(string.format("[AutoDoors] Door %d is ready to knock! Moving...", readyIndex))
                break
            end

            pcall(function()
                customEggsRemote:InvokeServer(manorEggUid, maxHatch)
            end)
            task.wait(0.18)
        end
    end

    print("[AutoDoors] Stopped.")
end)
