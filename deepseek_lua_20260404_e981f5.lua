-- XENTHUB DUELS - Complete Duel Hub
-- All features in one unified panel

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer

-- ============================================
-- ANIMATED BLACK & BLUE THEME
-- ============================================
local COLORS = {
    Background = Color3.fromRGB(6, 8, 12),
    CardBg = Color3.fromRGB(12, 14, 20),
    Blue = Color3.fromRGB(0, 120, 255),
    BlueLight = Color3.fromRGB(0, 160, 255),
    BlueDark = Color3.fromRGB(0, 80, 200),
    BlueGlow = Color3.fromRGB(0, 100, 230),
    TopBar = Color3.fromRGB(0, 85, 210),
    TextWhite = Color3.fromRGB(255, 255, 255),
    TextDim = Color3.fromRGB(130, 140, 160),
    StatusGreen = Color3.fromRGB(40, 200, 64),
    StatusRed = Color3.fromRGB(255, 70, 70),
}

-- ============================================
-- TP COORDINATES (Ragdoll Recovery)
-- ============================================
local finalPos1 = Vector3.new(-483.59, -5.04, 104.24)
local finalPos2 = Vector3.new(-483.51, -5.10, 18.89)
local checkpointA = Vector3.new(-472.60, -7.00, 57.52)
local checkpointB1 = Vector3.new(-472.65, -7.00, 95.69)
local checkpointB2 = Vector3.new(-471.76, -7.00, 26.22)

-- ============================================
-- AUTO DUEL POSITIONS
-- ============================================
local POSITION_L1     = Vector3.new(-476.48, -6.28,  92.73)
local POSITION_LEND   = Vector3.new(-483.12, -4.95,  94.80)
local POSITION_LFINAL = Vector3.new(-473.38, -8.40,  22.34)
local POSITION_R1     = Vector3.new(-476.16, -6.52,  25.62)
local POSITION_REND   = Vector3.new(-483.04, -5.09,  23.14)
local POSITION_RFINAL = Vector3.new(-476.17, -7.91, 97.91)

-- ============================================
-- STATE VARIABLES
-- ============================================
local autoTpLeft = false
local autoTpRight = false
local isTeleporting = false
local hasRecovered = true

local duelConfig = { ForwardSpeed = 59, ReturnSpeed = 28 }
local AutoLeftEnabled = false
local autoLeftPhase = 1
local autoLeftConn = nil
local AutoRightEnabled = false
local autoRightPhase = 1
local autoRightConn = nil

local stealActive = false
local stealConn = nil
local animalCache = {}
local promptCache = {}
local stealCache = {}
local isStealing = false
local STEAL_R = 7

local antirag = false
local charCache = {}
local ragConns = {}
local floaton = false
local floatConn = nil
local floatSpeed = 56.1
local vertSpeed = 35
local infjump = false

local AnimalsData = {}
pcall(function()
    local rep = game:GetService("ReplicatedStorage")
    local datas = rep:FindFirstChild("Datas")
    if datas then
        local animals = datas:FindFirstChild("Animals")
        if animals then AnimalsData = require(animals) end
    end
end)

-- ============================================
-- HELPER FUNCTIONS
-- ============================================
local function getHRP()
    local c = LocalPlayer.Character
    return c and c:FindFirstChild("HumanoidRootPart")
end

local function getHum()
    local c = LocalPlayer.Character
    return c and c:FindFirstChildOfClass("Humanoid")
end

local function move(pos)
    local char = LocalPlayer.Character
    if char then
        char:PivotTo(CFrame.new(pos))
        local hrp = char:FindFirstChild("HumanoidRootPart")
        if hrp then hrp.AssemblyLinearVelocity = Vector3.new(0,0,0) end
    end
end

-- ============================================
-- RAGDOLL TP LOGIC
-- ============================================
local function executeTpSequence(side)
    isTeleporting = true
    hasRecovered = false
    
    local targetB = (side == "Left") and checkpointB1 or checkpointB2
    local targetFinal = (side == "Left") and finalPos1 or finalPos2
    
    move(checkpointA)
    task.wait(0.12)
    move(targetB)
    task.wait(0.12)
    move(targetFinal)
    
    isTeleporting = false
end

-- ============================================
-- AUTO DUEL LOGIC
-- ============================================
local function stopAutoLeft()
    if autoLeftConn then autoLeftConn:Disconnect(); autoLeftConn = nil end
    autoLeftPhase = 1
    local hum = getHum()
    if hum then hum:Move(Vector3.zero, false) end
end

local function startAutoLeft()
    if autoLeftConn then autoLeftConn:Disconnect() end
    autoLeftPhase = 1

    autoLeftConn = RunService.Heartbeat:Connect(function()
        if not AutoLeftEnabled then return end
        local h, hum = getHRP(), getHum()
        if not h or not hum then return end

        if autoLeftPhase == 1 then
            local d = Vector3.new(POSITION_L1.X - h.Position.X, 0, POSITION_L1.Z - h.Position.Z)
            if d.Magnitude < 1 then autoLeftPhase = 2; return end
            local md = d.Unit
            hum:Move(md, false)
            h.AssemblyLinearVelocity = Vector3.new(md.X * duelConfig.ForwardSpeed, h.AssemblyLinearVelocity.Y, md.Z * duelConfig.ForwardSpeed)

        elseif autoLeftPhase == 2 then
            local d = Vector3.new(POSITION_LEND.X - h.Position.X, 0, POSITION_LEND.Z - h.Position.Z)
            if d.Magnitude < 1 then
                autoLeftPhase = 0
                hum:Move(Vector3.zero, false)
                h.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
                task.delay(0.2, function()
                    if AutoLeftEnabled then autoLeftPhase = 3 end
                end)
                return
            end
            local md = d.Unit
            hum:Move(md, false)
            h.AssemblyLinearVelocity = Vector3.new(md.X * duelConfig.ForwardSpeed, h.AssemblyLinearVelocity.Y, md.Z * duelConfig.ForwardSpeed)

        elseif autoLeftPhase == 0 then
            return

        elseif autoLeftPhase == 3 then
            local d = Vector3.new(POSITION_L1.X - h.Position.X, 0, POSITION_L1.Z - h.Position.Z)
            if d.Magnitude < 1 then autoLeftPhase = 4; return end
            local md = d.Unit
            hum:Move(md, false)
            h.AssemblyLinearVelocity = Vector3.new(md.X * duelConfig.ReturnSpeed, h.AssemblyLinearVelocity.Y, md.Z * duelConfig.ReturnSpeed)

        elseif autoLeftPhase == 4 then
            local d = Vector3.new(POSITION_LFINAL.X - h.Position.X, 0, POSITION_LFINAL.Z - h.Position.Z)
            if d.Magnitude < 1 then
                hum:Move(Vector3.zero, false)
                h.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
                AutoLeftEnabled = false
                stopAutoLeft()
                if _G._updateDuelLeft then _G._updateDuelLeft() end
                return
            end
            local md = d.Unit
            hum:Move(md, false)
            h.AssemblyLinearVelocity = Vector3.new(md.X * duelConfig.ReturnSpeed, h.AssemblyLinearVelocity.Y, md.Z * duelConfig.ReturnSpeed)
        end
    end)
end

local function stopAutoRight()
    if autoRightConn then autoRightConn:Disconnect(); autoRightConn = nil end
    autoRightPhase = 1
    local hum = getHum()
    if hum then hum:Move(Vector3.zero, false) end
end

local function startAutoRight()
    if autoRightConn then autoRightConn:Disconnect() end
    autoRightPhase = 1

    autoRightConn = RunService.Heartbeat:Connect(function()
        if not AutoRightEnabled then return end
        local h, hum = getHRP(), getHum()
        if not h or not hum then return end

        if autoRightPhase == 1 then
            local d = Vector3.new(POSITION_R1.X - h.Position.X, 0, POSITION_R1.Z - h.Position.Z)
            if d.Magnitude < 1 then autoRightPhase = 2; return end
            local md = d.Unit
            hum:Move(md, false)
            h.AssemblyLinearVelocity = Vector3.new(md.X * duelConfig.ForwardSpeed, h.AssemblyLinearVelocity.Y, md.Z * duelConfig.ForwardSpeed)

        elseif autoRightPhase == 2 then
            local d = Vector3.new(POSITION_REND.X - h.Position.X, 0, POSITION_REND.Z - h.Position.Z)
            if d.Magnitude < 1 then
                autoRightPhase = 0
                hum:Move(Vector3.zero, false)
                h.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
                task.delay(0.2, function()
                    if AutoRightEnabled then autoRightPhase = 3 end
                end)
                return
            end
            local md = d.Unit
            hum:Move(md, false)
            h.AssemblyLinearVelocity = Vector3.new(md.X * duelConfig.ForwardSpeed, h.AssemblyLinearVelocity.Y, md.Z * duelConfig.ForwardSpeed)

        elseif autoRightPhase == 0 then
            return

        elseif autoRightPhase == 3 then
            local d = Vector3.new(POSITION_R1.X - h.Position.X, 0, POSITION_R1.Z - h.Position.Z)
            if d.Magnitude < 1 then autoRightPhase = 4; return end
            local md = d.Unit
            hum:Move(md, false)
            h.AssemblyLinearVelocity = Vector3.new(md.X * duelConfig.ReturnSpeed, h.AssemblyLinearVelocity.Y, md.Z * duelConfig.ReturnSpeed)

        elseif autoRightPhase == 4 then
            local d = Vector3.new(POSITION_RFINAL.X - h.Position.X, 0, POSITION_RFINAL.Z - h.Position.Z)
            if d.Magnitude < 1 then
                hum:Move(Vector3.zero, false)
                h.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
                AutoRightEnabled = false
                stopAutoRight()
                if _G._updateDuelRight then _G._updateDuelRight() end
                return
            end
            local md = d.Unit
            hum:Move(md, false)
            h.AssemblyLinearVelocity = Vector3.new(md.X * duelConfig.ReturnSpeed, h.AssemblyLinearVelocity.Y, md.Z * duelConfig.ReturnSpeed)
        end
    end)
end

-- ============================================
-- AUTO STEAL LOGIC
-- ============================================
local function stealHRP()
    local c = LocalPlayer.Character
    if not c then return nil end
    return c:FindFirstChild("HumanoidRootPart") or c:FindFirstChild("UpperTorso")
end

local function isMyBase(plotName)
    local plot = workspace.Plots and workspace.Plots:FindFirstChild(plotName)
    if not plot then return false end
    local sign = plot:FindFirstChild("PlotSign")
    if not sign then return false end
    local yb = sign:FindFirstChild("YourBase")
    return yb and yb:IsA("BillboardGui") and yb.Enabled == true
end

local function scanPlot(plot)
    if not plot or not plot:IsA("Model") then return end
    if isMyBase(plot.Name) then return end
    local podiums = plot:FindFirstChild("AnimalPodiums")
    if not podiums then return end
    for _, pod in ipairs(podiums:GetChildren()) do
        if pod:IsA("Model") and pod:FindFirstChild("Base") then
            local name = "Unknown"
            local spawn = pod.Base:FindFirstChild("Spawn")
            if spawn then
                for _, child in ipairs(spawn:GetChildren()) do
                    if child:IsA("Model") and child.Name ~= "PromptAttachment" then
                        name = child.Name
                        local info = AnimalsData[name]
                        if info and info.DisplayName then name = info.DisplayName end
                        break
                    end
                end
            end
            table.insert(animalCache, {
                name = name, plot = plot.Name, slot = pod.Name,
                worldPosition = pod:GetPivot().Position,
                uid = plot.Name .. "_" .. pod.Name,
            })
        end
    end
end

local function findPrompt(ad)
    if not ad then return nil end
    local cp = promptCache[ad.uid]
    if cp and cp.Parent then return cp end
    local plots = workspace:FindFirstChild("Plots")
    if not plots then return nil end
    local plot = plots:FindFirstChild(ad.plot)
    if not plot then return nil end
    local pods = plot:FindFirstChild("AnimalPodiums")
    if not pods then return nil end
    local pod = pods:FindFirstChild(ad.slot)
    if not pod then return nil end
    local base = pod:FindFirstChild("Base")
    if not base then return nil end
    local sp = base:FindFirstChild("Spawn")
    if not sp then return nil end
    local att = sp:FindFirstChild("PromptAttachment")
    if not att then return nil end
    for _, p in ipairs(att:GetChildren()) do
        if p:IsA("ProximityPrompt") then promptCache[ad.uid] = p; return p end
    end
end

local function buildCallbacks(prompt)
    if stealCache[prompt] then return end
    local data = { holdCallbacks = {}, triggerCallbacks = {}, ready = true }
    local ok1, c1 = pcall(getconnections, prompt.PromptButtonHoldBegan)
    if ok1 and type(c1) == "table" then
        for _, conn in ipairs(c1) do
            if type(conn.Function) == "function" then table.insert(data.holdCallbacks, conn.Function) end
        end
    end
    local ok2, c2 = pcall(getconnections, prompt.Triggered)
    if ok2 and type(c2) == "table" then
        for _, conn in ipairs(c2) do
            if type(conn.Function) == "function" then table.insert(data.triggerCallbacks, conn.Function) end
        end
    end
    if #data.holdCallbacks > 0 or #data.triggerCallbacks > 0 then stealCache[prompt] = data end
end

local function execSteal(prompt)
    local data = stealCache[prompt]
    if not data or not data.ready then return false end
    data.ready = false
    isStealing = true
    task.spawn(function()
        for _, fn in ipairs(data.holdCallbacks) do task.spawn(fn) end
        task.wait(0.2)
        for _, fn in ipairs(data.triggerCallbacks) do task.spawn(fn) end
        task.wait(0.01)
        data.ready = true
        task.wait(0.01)
        isStealing = false
    end)
    return true
end

local function nearestAnimal()
    local hrp = stealHRP()
    if not hrp then return nil end
    local best, bestD = nil, math.huge
    for _, ad in ipairs(animalCache) do
        if not isMyBase(ad.plot) and ad.worldPosition then
            local d = (hrp.Position - ad.worldPosition).Magnitude
            if d < bestD then bestD = d; best = ad end
        end
    end
    return best
end

local function startStealLoop()
    if stealConn then stealConn:Disconnect() end
    stealConn = RunService.Heartbeat:Connect(function()
        if not stealActive or isStealing then return end
        local target = nearestAnimal()
        if not target then return end
        local hrp = stealHRP()
        if not hrp then return end
        if (hrp.Position - target.worldPosition).Magnitude > STEAL_R then return end
        local prompt = promptCache[target.uid]
        if not prompt or not prompt.Parent then prompt = findPrompt(target) end
        if prompt then buildCallbacks(prompt); execSteal(prompt) end
    end)
end

task.spawn(function()
    task.wait(2)
    local plots = workspace:WaitForChild("Plots", 10)
    if not plots then return end
    for _, plot in ipairs(plots:GetChildren()) do
        if plot:IsA("Model") then scanPlot(plot) end
    end
    plots.ChildAdded:Connect(function(plot)
        if plot:IsA("Model") then task.wait(0.5); scanPlot(plot) end
    end)
    task.spawn(function()
        while task.wait(5) do
            animalCache = {}
            for _, plot in ipairs(plots:GetChildren()) do
                if plot:IsA("Model") then scanPlot(plot) end
            end
        end
    end)
end)
startStealLoop()

-- ============================================
-- ANTI RAGDOLL LOGIC
-- ============================================
local function cacheChar()
    local c = LocalPlayer.Character
    if not c then return false end
    local h = c:FindFirstChildOfClass("Humanoid")
    local r = c:FindFirstChild("HumanoidRootPart")
    if not h or not r then return false end
    charCache = { char = c, hum = h, root = r }
    return true
end

local function killConns()
    for _, c in pairs(ragConns) do pcall(function() c:Disconnect() end) end
    ragConns = {}
end

local function isRagdoll()
    if not charCache.hum then return false end
    local s = charCache.hum:GetState()
    if s == Enum.HumanoidStateType.Physics or s == Enum.HumanoidStateType.Ragdoll or s == Enum.HumanoidStateType.FallingDown then
        return true
    end
    local et = LocalPlayer:GetAttribute("RagdollEndTime")
    if et then
        local n = workspace:GetServerTimeNow()
        if (et - n) > 0 then return true end
    end
    return false
end

local function removeCons()
    if not charCache.char then return end
    for _, d in pairs(charCache.char:GetDescendants()) do
        if d:IsA("BallSocketConstraint") or (d:IsA("Attachment") and string.find(d.Name, "RagdollAttachment")) then
            pcall(function() d:Destroy() end)
        end
    end
end

local function forceExit()
    if not charCache.hum or not charCache.root then return end
    pcall(function() LocalPlayer:SetAttribute("RagdollEndTime", workspace:GetServerTimeNow()) end)
    if charCache.hum.Health > 0 then charCache.hum:ChangeState(Enum.HumanoidStateType.Running) end
    charCache.root.Anchored = false
    charCache.root.AssemblyLinearVelocity = Vector3.zero
end

local function setupCam()
    if not charCache.hum then return end
    table.insert(ragConns, RunService.RenderStepped:Connect(function()
        if not antirag then return end
        local c = workspace.CurrentCamera
        if c and charCache.hum and c.CameraSubject ~= charCache.hum then
            c.CameraSubject = charCache.hum
        end
    end))
end

local function antiLoop()
    while antirag and charCache.hum do
        task.wait()
        if isRagdoll() then
            removeCons()
            forceExit()
        end
    end
end

local function onChar(c)
    task.wait(0.5)
    if not antirag then return end
    if cacheChar() then
        setupCam()
        task.spawn(antiLoop)
    end
end

local function enableAntiRagdoll()
    antirag = true
    if cacheChar() then
        setupCam()
        task.spawn(antiLoop)
    end
    table.insert(ragConns, LocalPlayer.CharacterAdded:Connect(onChar))
end

local function disableAntiRagdoll()
    antirag = false
    killConns()
    charCache = {}
end

-- ============================================
-- FLOAT NEAREST LOGIC
-- ============================================
local function startFloat()
    floaton = true
    if floatConn then floatConn:Disconnect() end
    floatConn = RunService.Heartbeat:Connect(function()
        if not floaton then return end
        local c = LocalPlayer.Character
        if not c then return end
        local h = c:FindFirstChild("HumanoidRootPart")
        if not h then return end
        local np = nil
        local nd = math.huge
        for _, p in pairs(Players:GetPlayers()) do
            if p ~= LocalPlayer and p.Character then
                local oh = p.Character:FindFirstChild("HumanoidRootPart")
                if oh then
                    local d = (h.Position - oh.Position).Magnitude
                    if d < nd then nd = d; np = p end
                end
            end
        end
        if np and np.Character then
            local th = np.Character:FindFirstChild("HumanoidRootPart")
            if th then
                local dir = (th.Position - h.Position).Unit
                local hd = th.Position.Y - h.Position.Y
                local hv = dir * floatSpeed
                local vv = 0
                if hd > 2 then vv = vertSpeed
                elseif hd < -2 then vv = -vertSpeed * 0.5 end
                h.AssemblyLinearVelocity = Vector3.new(hv.X, vv, hv.Z)
            end
        else
            h.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
        end
    end)
end

local function stopFloat()
    floaton = false
    if floatConn then floatConn:Disconnect(); floatConn = nil end
    local c = LocalPlayer.Character
    if c then
        local h = c:FindFirstChild("HumanoidRootPart")
        if h then h.AssemblyLinearVelocity = Vector3.new(0, 0, 0) end
    end
end

-- ============================================
-- INFINITE JUMP
-- ============================================
UserInputService.JumpRequest:Connect(function()
    if infjump and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
        LocalPlayer.Character.HumanoidRootPart.AssemblyLinearVelocity = Vector3.new(
            LocalPlayer.Character.HumanoidRootPart.AssemblyLinearVelocity.X,
            52,
            LocalPlayer.Character.HumanoidRootPart.AssemblyLinearVelocity.Z
        )
    end
end)

-- ============================================
-- RAGDOLL TP DETECTION LOOP
-- ============================================
RunService.Heartbeat:Connect(function()
    local char = LocalPlayer.Character
    local hum = char and char:FindFirstChild("Humanoid")
    
    if hum then
        local state = hum:GetState()
        local isRagdollState = (state == Enum.HumanoidStateType.Physics or state == Enum.HumanoidStateType.Ragdoll or state == Enum.HumanoidStateType.FallingDown)
        
        if not isRagdollState then hasRecovered = true end
        
        if not isTeleporting and hasRecovered and isRagdollState then
            if autoTpLeft then executeTpSequence("Left")
            elseif autoTpRight then executeTpSequence("Right") end
        end
    end
end)

-- ============================================
-- GUI SETUP
-- ============================================
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "XENTHUBDuels"
screenGui.ResetOnSpawn = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.Parent = game:GetService("CoreGui")

-- Shadow effect
local shadow = Instance.new("ImageLabel", screenGui)
shadow.Size = UDim2.new(0, 340, 0, 520)
shadow.Position = UDim2.new(0.5, -170, 0.5, -260)
shadow.BackgroundTransparency = 1
shadow.ImageColor3 = Color3.new(0, 0, 0)
shadow.ImageTransparency = 0.5
shadow.ScaleType = Enum.ScaleType.Slice
shadow.SliceCenter = Rect.new(10, 10, 118, 118)

-- Main window
local mainFrame = Instance.new("Frame", screenGui)
mainFrame.Size = UDim2.new(0, 320, 0, 500)
mainFrame.Position = UDim2.new(0.5, -160, 0.5, -250)
mainFrame.BackgroundColor3 = COLORS.Background
mainFrame.BackgroundTransparency = 0.05
mainFrame.BorderSizePixel = 0
mainFrame.Active = true
mainFrame.ClipsDescendants = true

local mainCorner = Instance.new("UICorner", mainFrame)
mainCorner.CornerRadius = UDim.new(0, 16)

-- Animated border stroke
local mainStroke = Instance.new("UIStroke", mainFrame)
mainStroke.Thickness = 2
mainStroke.Transparency = 0.3
mainStroke.Color = COLORS.Blue

-- Animated glow effect
task.spawn(function()
    while screenGui and mainFrame and mainFrame.Parent do
        task.wait(0.05)
        local alpha = 0.2 + (math.abs(math.sin(tick() * 1.5)) * 0.6)
        mainStroke.Transparency = 1 - alpha
        local r = 0
        local g = 80 + math.floor(80 * (math.sin(tick() * 1.5) + 1) / 2)
        local b = 200 + math.floor(55 * (math.sin(tick() * 1.5) + 1) / 2)
        mainStroke.Color = Color3.fromRGB(r, g, b)
    end
end)

-- Top bar (DRAGGABLE)
local topBar = Instance.new("Frame", mainFrame)
topBar.Size = UDim2.new(1, 0, 0, 50)
topBar.BackgroundColor3 = COLORS.TopBar
topBar.BorderSizePixel = 0
topBar.BackgroundTransparency = 0.95

local topCorner = Instance.new("UICorner", topBar)
topCorner.CornerRadius = UDim.new(0, 16)

-- DRAG FUNCTIONALITY
local dragActive = false
local dragStartPos, dragStartMouse

topBar.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragActive = true
        dragStartPos = mainFrame.Position
        dragStartMouse = input.Position
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if dragActive and input.UserInputType == Enum.UserInputType.MouseMovement then
        local delta = input.Position - dragStartMouse
        local newX = dragStartPos.X.Offset + delta.X
        local newY = dragStartPos.Y.Offset + delta.Y
        mainFrame.Position = UDim2.new(dragStartPos.X.Scale, newX, dragStartPos.Y.Scale, newY)
        shadow.Position = UDim2.new(mainFrame.Position.X.Scale, mainFrame.Position.X.Offset - 10, mainFrame.Position.Y.Scale, mainFrame.Position.Y.Offset - 10)
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragActive = false
    end
end)

-- Title
local title = Instance.new("TextLabel", topBar)
title.Size = UDim2.new(1, -80, 1, 0)
title.Position = UDim2.new(0, 15, 0, 0)
title.BackgroundTransparency = 1
title.Text = "XENTHUB DUELS"
title.TextColor3 = COLORS.TextWhite
title.Font = Enum.Font.GothamBlack
title.TextSize = 18
title.TextXAlignment = Enum.TextXAlignment.Left

-- Subtitle (updated vanity URL)
local subtitle = Instance.new("TextLabel", topBar)
subtitle.Size = UDim2.new(1, -80, 0, 14)
subtitle.Position = UDim2.new(0, 15, 0, 28)
subtitle.BackgroundTransparency = 1
subtitle.Text = "discord.gg/xenthub"
subtitle.TextColor3 = COLORS.TextDim
subtitle.Font = Enum.Font.Gotham
subtitle.TextSize = 9
subtitle.TextXAlignment = Enum.TextXAlignment.Left

-- Minimize button
local minimizeBtn = Instance.new("TextButton", topBar)
minimizeBtn.Size = UDim2.new(0, 28, 0, 28)
minimizeBtn.Position = UDim2.new(1, -70, 0.5, -14)
minimizeBtn.BackgroundColor3 = COLORS.BlueDark
minimizeBtn.Text = "−"
minimizeBtn.TextColor3 = COLORS.TextWhite
minimizeBtn.Font = Enum.Font.GothamBold
minimizeBtn.TextSize = 22
minimizeBtn.AutoButtonColor = false
Instance.new("UICorner", minimizeBtn).CornerRadius = UDim.new(0, 6)

-- Close button
local closeBtn = Instance.new("TextButton", topBar)
closeBtn.Size = UDim2.new(0, 28, 0, 28)
closeBtn.Position = UDim2.new(1, -38, 0.5, -14)
closeBtn.BackgroundColor3 = COLORS.BlueDark
closeBtn.Text = "✕"
closeBtn.TextColor3 = COLORS.TextWhite
closeBtn.Font = Enum.Font.GothamBold
closeBtn.TextSize = 18
closeBtn.AutoButtonColor = false
Instance.new("UICorner", closeBtn).CornerRadius = UDim.new(0, 6)

-- Hover effects
minimizeBtn.MouseEnter:Connect(function()
    TweenService:Create(minimizeBtn, TweenInfo.new(0.15), {BackgroundColor3 = COLORS.BlueLight}):Play()
end)
minimizeBtn.MouseLeave:Connect(function()
    TweenService:Create(minimizeBtn, TweenInfo.new(0.15), {BackgroundColor3 = COLORS.BlueDark}):Play()
end)

closeBtn.MouseEnter:Connect(function()
    TweenService:Create(closeBtn, TweenInfo.new(0.15), {BackgroundColor3 = Color3.fromRGB(200, 50, 50)}):Play()
end)
closeBtn.MouseLeave:Connect(function()
    TweenService:Create(closeBtn, TweenInfo.new(0.15), {BackgroundColor3 = COLORS.BlueDark}):Play()
end)

-- Scrolling frame (FIXED SCROLL)
local scrollFrame = Instance.new("ScrollingFrame", mainFrame)
scrollFrame.Size = UDim2.new(1, -10, 1, -60)
scrollFrame.Position = UDim2.new(0, 5, 0, 55)
scrollFrame.BackgroundTransparency = 1
scrollFrame.BorderSizePixel = 0
scrollFrame.ScrollBarThickness = 4
scrollFrame.ScrollBarImageColor3 = COLORS.Blue
scrollFrame.ScrollBarImageTransparency = 0.5
scrollFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
scrollFrame.AutomaticCanvasSize = Enum.AutomaticSize.None

local contentContainer = Instance.new("Frame", scrollFrame)
contentContainer.Size = UDim2.new(1, 0, 0, 0)
contentContainer.AutomaticSize = Enum.AutomaticSize.Y
contentContainer.BackgroundTransparency = 1

local uiList = Instance.new("UIListLayout", contentContainer)
uiList.Padding = UDim.new(0, 8)
uiList.SortOrder = Enum.SortOrder.LayoutOrder

-- Update canvas size when content changes
local function updateCanvasSize()
    task.wait(0.1)
    scrollFrame.CanvasSize = UDim2.new(0, 0, 0, contentContainer.AbsoluteSize.Y + 20)
end

uiList:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(updateCanvasSize)
task.spawn(updateCanvasSize)

-- ============================================
-- SECTION CREATOR
-- ============================================
local function createSection(title, order)
    local section = Instance.new("Frame", contentContainer)
    section.Size = UDim2.new(1, 0, 0, 28)
    section.BackgroundTransparency = 1
    section.LayoutOrder = order
    
    local line = Instance.new("Frame", section)
    line.Size = UDim2.new(1, 0, 0, 1.5)
    line.Position = UDim2.new(0, 0, 1, -1.5)
    line.BackgroundColor3 = COLORS.Blue
    line.BorderSizePixel = 0
    
    local label = Instance.new("TextLabel", section)
    label.Size = UDim2.new(0.8, 0, 1, 0)
    label.BackgroundTransparency = 1
    label.Text = title:upper()
    label.TextColor3 = COLORS.Blue
    label.Font = Enum.Font.GothamBold
    label.TextSize = 11
    label.TextXAlignment = Enum.TextXAlignment.Left
    
    return section
end

-- ============================================
-- TOGGLE ROW CREATOR
-- ============================================
local function createToggleRow(parent, labelText, isBlue, defaultValue, onToggle)
    local row = Instance.new("Frame", parent)
    row.Size = UDim2.new(1, -10, 0, 38)
    row.BackgroundColor3 = COLORS.CardBg
    row.BackgroundTransparency = 0.4
    row.BorderSizePixel = 0
    Instance.new("UICorner", row).CornerRadius = UDim.new(0, 8)
    
    local rowStroke = Instance.new("UIStroke", row)
    rowStroke.Color = COLORS.Blue
    rowStroke.Thickness = 1
    rowStroke.Transparency = 0.7
    
    local label = Instance.new("TextLabel", row)
    label.Size = UDim2.new(1, -80, 1, 0)
    label.Position = UDim2.new(0, 12, 0, 0)
    label.BackgroundTransparency = 1
    label.Text = labelText
    label.TextColor3 = COLORS.TextWhite
    label.Font = Enum.Font.GothamBold
    label.TextSize = 12
    label.TextXAlignment = Enum.TextXAlignment.Left
    
    local switchBg = Instance.new("Frame", row)
    switchBg.Size = UDim2.new(0, 44, 0, 22)
    switchBg.Position = UDim2.new(1, -56, 0.5, -11)
    switchBg.BackgroundColor3 = defaultValue and COLORS.Blue or COLORS.CardBg
    switchBg.BorderSizePixel = 0
    Instance.new("UICorner", switchBg).CornerRadius = UDim.new(1, 0)
    
    local switchCircle = Instance.new("Frame", switchBg)
    switchCircle.Size = UDim2.new(0, 18, 0, 18)
    switchCircle.Position = defaultValue and UDim2.new(1, -20, 0.5, -9) or UDim2.new(0, 3, 0.5, -9)
    switchCircle.BackgroundColor3 = COLORS.TextWhite
    switchCircle.BorderSizePixel = 0
    Instance.new("UICorner", switchCircle).CornerRadius = UDim.new(1, 0)
    
    local isOn = defaultValue
    
    local btn = Instance.new("TextButton", row)
    btn.Size = UDim2.new(1, 0, 1, 0)
    btn.BackgroundTransparency = 1
    btn.Text = ""
    
    btn.MouseButton1Click:Connect(function()
        isOn = not isOn
        TweenService:Create(switchBg, TweenInfo.new(0.2), {BackgroundColor3 = isOn and COLORS.Blue or COLORS.CardBg}):Play()
        TweenService:Create(switchCircle, TweenInfo.new(0.2, Enum.EasingStyle.Back), {Position = isOn and UDim2.new(1, -20, 0.5, -9) or UDim2.new(0, 3, 0.5, -9)}):Play()
        if onToggle then onToggle(isOn) end
    end)
    
    return row
end

-- ============================================
-- BUTTON CREATOR
-- ============================================
local function createButton(parent, labelText, isBlue, onToggle)
    local btn = Instance.new("TextButton", parent)
    btn.Size = UDim2.new(1, -10, 0, 38)
    btn.BackgroundColor3 = isBlue and COLORS.BlueDark or COLORS.Blue
    btn.Text = labelText .. " ● OFF"
    btn.TextColor3 = COLORS.TextWhite
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 12
    btn.AutoButtonColor = false
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 8)
    
    local dot = Instance.new("Frame", btn)
    dot.Size = UDim2.new(0, 8, 0, 8)
    dot.Position = UDim2.new(1, -22, 0.5, -4)
    dot.BackgroundColor3 = COLORS.StatusRed
    Instance.new("UICorner", dot).CornerRadius = UDim.new(1, 0)
    
    local isOn = false
    
    btn.MouseEnter:Connect(function()
        TweenService:Create(btn, TweenInfo.new(0.15), {BackgroundColor3 = isBlue and COLORS.BlueLight or COLORS.BlueLight}):Play()
    end)
    btn.MouseLeave:Connect(function()
        local color = isBlue and COLORS.BlueDark or COLORS.Blue
        if isOn then color = COLORS.BlueLight end
        TweenService:Create(btn, TweenInfo.new(0.15), {BackgroundColor3 = color}):Play()
    end)
    
    btn.MouseButton1Click:Connect(function()
        isOn = not isOn
        if isOn then
            TweenService:Create(btn, TweenInfo.new(0.2), {BackgroundColor3 = COLORS.BlueLight}):Play()
            dot.BackgroundColor3 = COLORS.StatusGreen
            btn.Text = labelText .. " ● ON"
        else
            local color = isBlue and COLORS.BlueDark or COLORS.Blue
            TweenService:Create(btn, TweenInfo.new(0.2), {BackgroundColor3 = color}):Play()
            dot.BackgroundColor3 = COLORS.StatusRed
            btn.Text = labelText .. " ● OFF"
        end
        if onToggle then onToggle(isOn) end
    end)
    
    return btn, dot
end

-- ============================================
-- SLIDER CREATOR (FIXED)
-- ============================================
local function createSlider(parent, labelText, defaultValue, minVal, maxVal, onChanged)
    local container = Instance.new("Frame", parent)
    container.Size = UDim2.new(1, -10, 0, 50)
    container.BackgroundColor3 = COLORS.CardBg
    container.BackgroundTransparency = 0.4
    container.BorderSizePixel = 0
    Instance.new("UICorner", container).CornerRadius = UDim.new(0, 8)
    
    local containerStroke = Instance.new("UIStroke", container)
    containerStroke.Color = COLORS.Blue
    containerStroke.Thickness = 1
    containerStroke.Transparency = 0.7
    
    local label = Instance.new("TextLabel", container)
    label.Size = UDim2.new(0.6, 0, 0, 20)
    label.Position = UDim2.new(0, 12, 0, 4)
    label.BackgroundTransparency = 1
    label.Text = labelText .. defaultValue
    label.TextColor3 = COLORS.TextWhite
    label.Font = Enum.Font.GothamBold
    label.TextSize = 11
    label.TextXAlignment = Enum.TextXAlignment.Left
    
    local valueBox = Instance.new("TextBox", container)
    valueBox.Size = UDim2.new(0, 50, 0, 22)
    valueBox.Position = UDim2.new(1, -62, 0, 3)
    valueBox.BackgroundColor3 = COLORS.CardBg
    valueBox.Text = tostring(defaultValue)
    valueBox.TextColor3 = COLORS.TextWhite
    valueBox.Font = Enum.Font.GothamBold
    valueBox.TextSize = 11
    valueBox.TextXAlignment = Enum.TextXAlignment.Center
    Instance.new("UICorner", valueBox).CornerRadius = UDim.new(0, 5)
    
    local sliderBg = Instance.new("Frame", container)
    sliderBg.Size = UDim2.new(1, -24, 0, 6)
    sliderBg.Position = UDim2.new(0, 12, 0, 34)
    sliderBg.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
    sliderBg.BorderSizePixel = 0
    Instance.new("UICorner", sliderBg).CornerRadius = UDim.new(1, 0)
    
    local sliderFill = Instance.new("Frame", sliderBg)
    sliderFill.Size = UDim2.new((defaultValue - minVal) / (maxVal - minVal), 0, 1, 0)
    sliderFill.BackgroundColor3 = COLORS.Blue
    sliderFill.BorderSizePixel = 0
    Instance.new("UICorner", sliderFill).CornerRadius = UDim.new(1, 0)
    
    local knob = Instance.new("Frame", sliderFill)
    knob.Size = UDim2.new(0, 14, 0, 14)
    knob.Position = UDim2.new(1, -7, 0.5, -7)
    knob.BackgroundColor3 = COLORS.TextWhite
    knob.BorderSizePixel = 0
    Instance.new("UICorner", knob).CornerRadius = UDim.new(1, 0)
    
    local dragging = false
    local sliderBtn = Instance.new("TextButton", sliderBg)
    sliderBtn.Size = UDim2.new(1, 0, 2, 0)
    sliderBtn.Position = UDim2.new(0, 0, -0.5, 0)
    sliderBtn.BackgroundTransparency = 1
    sliderBtn.Text = ""
    
    sliderBtn.MouseButton1Down:Connect(function() dragging = true end)
    UserInputService.InputEnded:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
    end)
    
    local function updateSlider(input)
        if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
            local relativeX = input.Position.X - sliderBg.AbsolutePosition.X
            local pct = math.clamp(relativeX / sliderBg.AbsoluteSize.X, 0, 1)
            local val = math.floor(minVal + pct * (maxVal - minVal))
            sliderFill.Size = UDim2.new(pct, 0, 1, 0)
            label.Text = labelText .. val
            valueBox.Text = tostring(val)
            if onChanged then onChanged(val) end
        end
    end
    
    UserInputService.InputChanged:Connect(updateSlider)
    
    valueBox.FocusLost:Connect(function()
        local n = tonumber(valueBox.Text)
        if n then
            n = math.clamp(n, minVal, maxVal)
            local pct = (n - minVal) / (maxVal - minVal)
            sliderFill.Size = UDim2.new(pct, 0, 1, 0)
            label.Text = labelText .. n
            valueBox.Text = tostring(n)
            if onChanged then onChanged(n) end
        else
            valueBox.Text = tostring(defaultValue)
        end
    end)
    
    return container
end

-- ============================================
-- BUILD THE UI
-- ============================================
local order = 0

-- SECTION 1: RAGDOLL RECOVERY
createSection("RAGDOLL RECOVERY", order)
order = order + 1

local ragCard = Instance.new("Frame", contentContainer)
ragCard.Size = UDim2.new(1, 0, 0, 0)
ragCard.AutomaticSize = Enum.AutomaticSize.Y
ragCard.BackgroundColor3 = COLORS.CardBg
ragCard.BackgroundTransparency = 0.3
ragCard.BorderSizePixel = 0
ragCard.LayoutOrder = order
Instance.new("UICorner", ragCard).CornerRadius = UDim.new(0, 10)
order = order + 1

local ragLayout = Instance.new("UIListLayout", ragCard)
ragLayout.Padding = UDim.new(0, 6)
ragLayout.SortOrder = Enum.SortOrder.LayoutOrder

local leftRow = createToggleRow(ragCard, "AUTO TP LEFT", true, false, function(on)
    autoTpLeft = on
    if on then autoTpRight = false end
end)

local rightRow = createToggleRow(ragCard, "AUTO TP RIGHT", false, false, function(on)
    autoTpRight = on
    if on then autoTpLeft = false end
end)

-- SECTION 2: AUTO DUEL
createSection("AUTO DUEL", order)
order = order + 1

local duelCard = Instance.new("Frame", contentContainer)
duelCard.Size = UDim2.new(1, 0, 0, 0)
duelCard.AutomaticSize = Enum.AutomaticSize.Y
duelCard.BackgroundColor3 = COLORS.CardBg
duelCard.BackgroundTransparency = 0.3
duelCard.BorderSizePixel = 0
duelCard.LayoutOrder = order
Instance.new("UICorner", duelCard).CornerRadius = UDim.new(0, 10)
order = order + 1

local duelLayout = Instance.new("UIListLayout", duelCard)
duelLayout.Padding = UDim.new(0, 6)
duelLayout.SortOrder = Enum.SortOrder.LayoutOrder

local leftDuelBtn, leftDuelDot = createButton(duelCard, "AUTO LEFT", true, function(on)
    AutoLeftEnabled = on
    if on then
        AutoRightEnabled = false
        stopAutoRight()
        startAutoLeft()
        if rightDuelBtn then
            TweenService:Create(rightDuelBtn, TweenInfo.new(0.2), {BackgroundColor3 = COLORS.BlueDark}):Play()
            rightDuelDot.BackgroundColor3 = COLORS.StatusRed
            rightDuelBtn.Text = "AUTO RIGHT ● OFF"
        end
    else
        stopAutoLeft()
    end
end)

local rightDuelBtn, rightDuelDot = createButton(duelCard, "AUTO RIGHT", false, function(on)
    AutoRightEnabled = on
    if on then
        AutoLeftEnabled = false
        stopAutoLeft()
        startAutoRight()
        if leftDuelBtn then
            TweenService:Create(leftDuelBtn, TweenInfo.new(0.2), {BackgroundColor3 = COLORS.BlueDark}):Play()
            leftDuelDot.BackgroundColor3 = COLORS.StatusRed
            leftDuelBtn.Text = "AUTO LEFT ● OFF"
        end
    else
        stopAutoRight()
    end
end)

_G._updateDuelLeft = function()
    if leftDuelBtn then
        if AutoLeftEnabled then
            leftDuelDot.BackgroundColor3 = COLORS.StatusGreen
            leftDuelBtn.Text = "AUTO LEFT ● ON"
        else
            leftDuelDot.BackgroundColor3 = COLORS.StatusRed
            leftDuelBtn.Text = "AUTO LEFT ● OFF"
        end
    end
end

_G._updateDuelRight = function()
    if rightDuelBtn then
        if AutoRightEnabled then
            rightDuelDot.BackgroundColor3 = COLORS.StatusGreen
            rightDuelBtn.Text = "AUTO RIGHT ● ON"
        else
            rightDuelDot.BackgroundColor3 = COLORS.StatusRed
            rightDuelBtn.Text = "AUTO RIGHT ● OFF"
        end
    end
end

local walkSlider = createSlider(duelCard, "WALK SPEED: ", duelConfig.ForwardSpeed, 20, 100, function(v)
    duelConfig.ForwardSpeed = v
end)

local stealSlider = createSlider(duelCard, "STEAL SPEED: ", duelConfig.ReturnSpeed, 10, 80, function(v)
    duelConfig.ReturnSpeed = v
end)

-- SECTION 3: AUTO STEAL
createSection("AUTO STEAL", order)
order = order + 1

local stealCard = Instance.new("Frame", contentContainer)
stealCard.Size = UDim2.new(1, 0, 0, 0)
stealCard.AutomaticSize = Enum.AutomaticSize.Y
stealCard.BackgroundColor3 = COLORS.CardBg
stealCard.BackgroundTransparency = 0.3
stealCard.BorderSizePixel = 0
stealCard.LayoutOrder = order
Instance.new("UICorner", stealCard).CornerRadius = UDim.new(0, 10)
order = order + 1

local stealLayout = Instance.new("UIListLayout", stealCard)
stealLayout.Padding = UDim.new(0, 6)
stealLayout.SortOrder = Enum.SortOrder.LayoutOrder

local stealBtnMain, stealDotMain = createButton(stealCard, "AUTO STEAL", false, function(on)
    stealActive = on
end)

-- Radius slider
local radiusContainer = Instance.new("Frame", stealCard)
radiusContainer.Size = UDim2.new(1, -10, 0, 50)
radiusContainer.BackgroundColor3 = COLORS.CardBg
radiusContainer.BackgroundTransparency = 0.4
radiusContainer.BorderSizePixel = 0
Instance.new("UICorner", radiusContainer).CornerRadius = UDim.new(0, 8)

local radiusStroke = Instance.new("UIStroke", radiusContainer)
radiusStroke.Color = COLORS.Blue
radiusStroke.Thickness = 1
radiusStroke.Transparency = 0.7

local radiusLabel = Instance.new("TextLabel", radiusContainer)
radiusLabel.Size = UDim2.new(0.6, 0, 0, 20)
radiusLabel.Position = UDim2.new(0, 12, 0, 4)
radiusLabel.BackgroundTransparency = 1
radiusLabel.Text = "RADIUS: " .. STEAL_R
radiusLabel.TextColor3 = COLORS.TextWhite
radiusLabel.Font = Enum.Font.GothamBold
radiusLabel.TextSize = 11
radiusLabel.TextXAlignment = Enum.TextXAlignment.Left

local radiusBox = Instance.new("TextBox", radiusContainer)
radiusBox.Size = UDim2.new(0, 50, 0, 22)
radiusBox.Position = UDim2.new(1, -62, 0, 3)
radiusBox.BackgroundColor3 = COLORS.CardBg
radiusBox.Text = tostring(STEAL_R)
radiusBox.TextColor3 = COLORS.TextWhite
radiusBox.Font = Enum.Font.GothamBold
radiusBox.TextSize = 11
radiusBox.TextXAlignment = Enum.TextXAlignment.Center
Instance.new("UICorner", radiusBox).CornerRadius = UDim.new(0, 5)

local radiusSliderBg = Instance.new("Frame", radiusContainer)
radiusSliderBg.Size = UDim2.new(1, -24, 0, 6)
radiusSliderBg.Position = UDim2.new(0, 12, 0, 34)
radiusSliderBg.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
radiusSliderBg.BorderSizePixel = 0
Instance.new("UICorner", radiusSliderBg).CornerRadius = UDim.new(1, 0)

local radiusSliderFill = Instance.new("Frame", radiusSliderBg)
radiusSliderFill.Size = UDim2.new((STEAL_R - 1) / 19, 0, 1, 0)
radiusSliderFill.BackgroundColor3 = COLORS.Blue
radiusSliderFill.BorderSizePixel = 0
Instance.new("UICorner", radiusSliderFill).CornerRadius = UDim.new(1, 0)

local radiusKnob = Instance.new("Frame", radiusSliderFill)
radiusKnob.Size = UDim2.new(0, 14, 0, 14)
radiusKnob.Position = UDim2.new(1, -7, 0.5, -7)
radiusKnob.BackgroundColor3 = COLORS.TextWhite
radiusKnob.BorderSizePixel = 0
Instance.new("UICorner", radiusKnob).CornerRadius = UDim.new(1, 0)

local radiusDragging = false
local radiusSliderBtn = Instance.new("TextButton", radiusSliderBg)
radiusSliderBtn.Size = UDim2.new(1, 0, 2, 0)
radiusSliderBtn.Position = UDim2.new(0, 0, -0.5, 0)
radiusSliderBtn.BackgroundTransparency = 1
radiusSliderBtn.Text = ""

radiusSliderBtn.MouseButton1Down:Connect(function() radiusDragging = true end)
UserInputService.InputEnded:Connect(function(i)
    if i.UserInputType == Enum.UserInputType.MouseButton1 then radiusDragging = false end
end)

UserInputService.InputChanged:Connect(function(i)
    if radiusDragging and i.UserInputType == Enum.UserInputType.MouseMovement then
        local relativeX = i.Position.X - radiusSliderBg.AbsolutePosition.X
        local pct = math.clamp(relativeX / radiusSliderBg.AbsoluteSize.X, 0, 1)
        STEAL_R = math.floor(1 + pct * 19)
        radiusSliderFill.Size = UDim2.new(pct, 0, 1, 0)
        radiusLabel.Text = "RADIUS: " .. STEAL_R
        radiusBox.Text = tostring(STEAL_R)
    end
end)

radiusBox.FocusLost:Connect(function()
    local n = tonumber(radiusBox.Text)
    if n then
        STEAL_R = math.clamp(n, 1, 20)
        local pct = (STEAL_R - 1) / 19
        radiusSliderFill.Size = UDim2.new(pct, 0, 1, 0)
        radiusLabel.Text = "RADIUS: " .. STEAL_R
        radiusBox.Text = tostring(STEAL_R)
    else
        radiusBox.Text = tostring(STEAL_R)
    end
end)

-- SECTION 4: UTILITIES
createSection("UTILITIES", order)
order = order + 1

local utilCard = Instance.new("Frame", contentContainer)
utilCard.Size = UDim2.new(1, 0, 0, 0)
utilCard.AutomaticSize = Enum.AutomaticSize.Y
utilCard.BackgroundColor3 = COLORS.CardBg
utilCard.BackgroundTransparency = 0.3
utilCard.BorderSizePixel = 0
utilCard.LayoutOrder = order
Instance.new("UICorner", utilCard).CornerRadius = UDim.new(0, 10)
order = order + 1

local utilLayout = Instance.new("UIListLayout", utilCard)
utilLayout.Padding = UDim.new(0, 6)
utilLayout.SortOrder = Enum.SortOrder.LayoutOrder

local antiBtnMain, antiDotMain = createButton(utilCard, "ANTI RAGDOLL", true, function(on)
    if on then enableAntiRagdoll() else disableAntiRagdoll() end
    antirag = on
end)

local floatBtnMain, floatDotMain = createButton(utilCard, "FLOAT NEAREST", false, function(on)
    if on then startFloat() else stopFloat() end
    floaton = on
end)

local infBtnMain, infDotMain = createButton(utilCard, "INFINITE JUMP", true, function(on)
    infjump = on
end)

-- Update canvas size after UI is built
task.spawn(function()
    task.wait(0.2)
    scrollFrame.CanvasSize = UDim2.new(0, 0, 0, contentContainer.AbsoluteSize.Y + 30)
end)

-- ============================================
-- WINDOW CONTROLS
-- ============================================
local minimized = false
local normalSize = UDim2.new(0, 320, 0, 500)
local miniSize = UDim2.new(0, 320, 0, 50)

local function setMinimized(state)
    minimized = state
    if minimized then
        TweenService:Create(mainFrame, TweenInfo.new(0.25, Enum.EasingStyle.Quad), {Size = miniSize, Position = UDim2.new(0.5, -160, 0.5, -25)}):Play()
        TweenService:Create(shadow, TweenInfo.new(0.25), {Size = UDim2.new(0, 340, 0, 70), Position = UDim2.new(0.5, -170, 0.5, -35)}):Play()
        scrollFrame.Visible = false
        minimizeBtn.Text = "□"
    else
        TweenService:Create(mainFrame, TweenInfo.new(0.25, Enum.EasingStyle.Quad), {Size = normalSize, Position = UDim2.new(0.5, -160, 0.5, -250)}):Play()
        TweenService:Create(shadow, TweenInfo.new(0.25), {Size = UDim2.new(0, 340, 0, 520), Position = UDim2.new(0.5, -170, 0.5, -260)}):Play()
        scrollFrame.Visible = true
        minimizeBtn.Text = "−"
        task.wait(0.3)
        scrollFrame.CanvasSize = UDim2.new(0, 0, 0, contentContainer.AbsoluteSize.Y + 30)
    end
end

minimizeBtn.MouseButton1Click:Connect(function()
    setMinimized(not minimized)
end)

closeBtn.MouseButton1Click:Connect(function()
    screenGui:Destroy()
end)

-- Update shadow position when dragging
local shadowUpdateConn
local function updateShadowPosition()
    shadow.Position = UDim2.new(mainFrame.Position.X.Scale, mainFrame.Position.X.Offset - 10, mainFrame.Position.Y.Scale, mainFrame.Position.Y.Offset - 10)
end

topBar.InputBegan:Connect(function()
    if shadowUpdateConn then shadowUpdateConn:Disconnect() end
    shadowUpdateConn = RunService.RenderStepped:Connect(updateShadowPosition)
end)

UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        if shadowUpdateConn then shadowUpdateConn:Disconnect(); shadowUpdateConn = nil end
    end
end)

-- ============================================
-- CLEANUP
-- ============================================
screenGui.Destroying:Connect(function()
    if stealConn then stealConn:Disconnect() end
    if floatConn then floatConn:Disconnect() end
    if shadowUpdateConn then shadowUpdateConn:Disconnect() end
    killConns()
end)

LocalPlayer.CharacterAdded:Connect(function(c)
    task.wait(0.5)
    if antirag then enableAntiRagdoll() end
    if floaton then startFloat() end
    autoTpLeft = false
    autoTpRight = false
    isTeleporting = false
    hasRecovered = true
    if stealActive then
        stealActive = false
        if stealBtnMain then
            TweenService:Create(stealBtnMain, TweenInfo.new(0.2), {BackgroundColor3 = COLORS.BlueDark}):Play()
            stealDotMain.BackgroundColor3 = COLORS.StatusRed
            stealBtnMain.Text = "AUTO STEAL ● OFF"
        end
    end
end)

UserInputService.InputBegan:Connect(function(i, g)
    if not g and i.KeyCode == Enum.KeyCode.RightControl then
        screenGui.Enabled = not screenGui.Enabled
    end
end)

pcall(function()
    if setclipboard then
        setclipboard("https://discord.gg/xenthub")
    end
end)

print("XENTHUB DUELS - Complete Duel Hub Loaded")