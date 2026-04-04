-- XENT DUELS - Complete Duel Hub
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
    Background = Color3.fromRGB(8, 8, 12),
    CardBg = Color3.fromRGB(15, 15, 22),
    Blue = Color3.fromRGB(0, 120, 255),
    BlueLight = Color3.fromRGB(0, 150, 255),
    BlueDark = Color3.fromRGB(0, 80, 180),
    BlueGlow = Color3.fromRGB(0, 100, 220),
    TopBar = Color3.fromRGB(0, 90, 200),
    TextWhite = Color3.fromRGB(255, 255, 255),
    TextDim = Color3.fromRGB(140, 140, 160),
    StatusGreen = Color3.fromRGB(40, 200, 64),
    StatusRed = Color3.fromRGB(255, 70, 70),
    SliderBlue1 = Color3.fromRGB(0, 150, 255),
    SliderBlue2 = Color3.fromRGB(0, 110, 220),
    SliderBlue3 = Color3.fromRGB(0, 70, 180),
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
-- Ragdoll TP
local autoTpLeft = false
local autoTpRight = false
local isTeleporting = false
local hasRecovered = true

-- Auto Duel
local duelConfig = { ForwardSpeed = 59, ReturnSpeed = 28 }
local AutoLeftEnabled = false
local autoLeftPhase = 1
local autoLeftConn = nil
local AutoRightEnabled = false
local autoRightPhase = 1
local autoRightConn = nil

-- Auto Steal
local stealActive = false
local stealConn = nil
local animalCache = {}
local promptCache = {}
local stealCache = {}
local isStealing = false
local STEAL_R = 7

-- Misc
local antirag = false
local charCache = {}
local ragConns = {}
local floaton = false
local floatConn = nil
local floatSpeed = 56.1
local vertSpeed = 35
local infjump = false

-- Animals Data
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

-- Initialize animal scanning
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
        local isRagdoll = (state == Enum.HumanoidStateType.Physics or state == Enum.HumanoidStateType.Ragdoll or state == Enum.HumanoidStateType.FallingDown)
        
        if not isRagdoll then hasRecovered = true end
        
        if not isTeleporting and hasRecovered and isRagdoll then
            if autoTpLeft then executeTpSequence("Left")
            elseif autoTpRight then executeTpSequence("Right") end
        end
    end
end)

-- ============================================
-- GUI SETUP - UNIFIED PANEL
-- ============================================
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "XENTDuelsHub"
screenGui.ResetOnSpawn = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.Parent = game:GetService("CoreGui")

-- Shadow effect
local shadow = Instance.new("ImageLabel")
shadow.Name = "Shadow"
shadow.Size = UDim2.new(0, 520, 0, 580)
shadow.Position = UDim2.new(0.5, -260, 0.5, -290)
shadow.BackgroundTransparency = 1
shadow.ImageColor3 = Color3.new(0, 0, 0)
shadow.ImageTransparency = 0.6
shadow.ScaleType = Enum.ScaleType.Slice
shadow.SliceCenter = Rect.new(10, 10, 118, 118)
shadow.Parent = screenGui

-- Main window
local mainFrame = Instance.new("Frame")
mainFrame.Size = UDim2.new(0, 500, 0, 560)
mainFrame.Position = UDim2.new(0.5, -250, 0.5, -280)
mainFrame.BackgroundColor3 = COLORS.Background
mainFrame.BackgroundTransparency = 0.05
mainFrame.BorderSizePixel = 0
mainFrame.Active = true
mainFrame.Draggable = true
mainFrame.ClipsDescendants = true
mainFrame.Parent = screenGui

local mainCorner = Instance.new("UICorner", mainFrame)
mainCorner.CornerRadius = UDim.new(0, 20)

-- Animated border stroke
local mainStroke = Instance.new("UIStroke", mainFrame)
mainStroke.Thickness = 2.5
mainStroke.Transparency = 0.3

local strokeTween
local blueToPurple = true

local function updateStrokeColor()
    local targetColor = blueToPurple and COLORS.Blue or COLORS.BlueDark
    strokeTween = TweenService:Create(mainStroke, TweenInfo.new(2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {Color = targetColor})
    strokeTween:Play()
    blueToPurple = not blueToPurple
end

updateStrokeColor()
strokeTween.Completed:Connect(updateStrokeColor)

-- Animated pulse effect on stroke
task.spawn(function()
    while true do
        task.wait(0.05)
        local alpha = 0.2 + (math.abs(math.sin(tick() * 1.5)) * 0.4)
        mainStroke.Transparency = 1 - alpha
    end
end)

-- Top bar
local topBar = Instance.new("Frame", mainFrame)
topBar.Size = UDim2.new(1, 0, 0, 50)
topBar.BackgroundColor3 = COLORS.TopBar
topBar.BorderSizePixel = 0

local topCorner = Instance.new("UICorner", topBar)
topCorner.CornerRadius = UDim.new(0, 20)

-- Title
local title = Instance.new("TextLabel", topBar)
title.Size = UDim2.new(1, -100, 1, 0)
title.Position = UDim2.new(0, 20, 0, 0)
title.BackgroundTransparency = 1
title.Text = "XENT DUELS"
title.TextColor3 = COLORS.TextWhite
title.Font = Enum.Font.GothamBlack
title.TextSize = 24
title.TextXAlignment = Enum.TextXAlignment.Left

-- Subtitle
local subtitle = Instance.new("TextLabel", topBar)
subtitle.Size = UDim2.new(1, -100, 0, 16)
subtitle.Position = UDim2.new(0, 20, 0, 30)
subtitle.BackgroundTransparency = 1
subtitle.Text = "discord.gg/xent"
subtitle.TextColor3 = COLORS.TextDim
subtitle.Font = Enum.Font.Gotham
subtitle.TextSize = 11
subtitle.TextXAlignment = Enum.TextXAlignment.Left

-- Minimize button
local minimizeBtn = Instance.new("TextButton", topBar)
minimizeBtn.Size = UDim2.new(0, 35, 0, 35)
minimizeBtn.Position = UDim2.new(1, -85, 0.5, -17)
minimizeBtn.BackgroundColor3 = COLORS.BlueDark
minimizeBtn.Text = "−"
minimizeBtn.TextColor3 = COLORS.TextWhite
minimizeBtn.Font = Enum.Font.GothamBold
minimizeBtn.TextSize = 28
minimizeBtn.AutoButtonColor = false
Instance.new("UICorner", minimizeBtn).CornerRadius = UDim.new(0, 8)

-- Close button
local closeBtn = Instance.new("TextButton", topBar)
closeBtn.Size = UDim2.new(0, 35, 0, 35)
closeBtn.Position = UDim2.new(1, -45, 0.5, -17)
closeBtn.BackgroundColor3 = COLORS.BlueDark
closeBtn.Text = "✕"
closeBtn.TextColor3 = COLORS.TextWhite
closeBtn.Font = Enum.Font.GothamBold
closeBtn.TextSize = 22
closeBtn.AutoButtonColor = false
Instance.new("UICorner", closeBtn).CornerRadius = UDim.new(0, 8)

-- Hover effects
minimizeBtn.MouseEnter:Connect(function()
    TweenService:Create(minimizeBtn, TweenInfo.new(0.2), {BackgroundColor3 = COLORS.BlueLight}):Play()
end)
minimizeBtn.MouseLeave:Connect(function()
    TweenService:Create(minimizeBtn, TweenInfo.new(0.2), {BackgroundColor3 = COLORS.BlueDark}):Play()
end)

closeBtn.MouseEnter:Connect(function()
    TweenService:Create(closeBtn, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(200, 50, 50)}):Play()
end)
closeBtn.MouseLeave:Connect(function()
    TweenService:Create(closeBtn, TweenInfo.new(0.2), {BackgroundColor3 = COLORS.BlueDark}):Play()
end)

-- Scrolling frame for content
local scrollFrame = Instance.new("ScrollingFrame", mainFrame)
scrollFrame.Size = UDim2.new(1, -20, 1, -70)
scrollFrame.Position = UDim2.new(0, 10, 0, 55)
scrollFrame.BackgroundTransparency = 1
scrollFrame.BorderSizePixel = 0
scrollFrame.ScrollBarThickness = 4
scrollFrame.ScrollBarImageColor3 = COLORS.Blue
scrollFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
scrollFrame.CanvasSize = UDim2.new(0, 0, 0, 0)

-- Content container
local contentContainer = Instance.new("Frame", scrollFrame)
contentContainer.Size = UDim2.new(1, 0, 0, 0)
contentContainer.AutomaticSize = Enum.AutomaticSize.Y
contentContainer.BackgroundTransparency = 1

local uiList = Instance.new("UIListLayout", contentContainer)
uiList.Padding = UDim.new(0, 10)
uiList.SortOrder = Enum.SortOrder.LayoutOrder

-- ============================================
-- SECTION CREATOR
-- ============================================
local function createSection(title, order)
    local section = Instance.new("Frame", contentContainer)
    section.Size = UDim2.new(1, 0, 0, 35)
    section.BackgroundTransparency = 1
    section.LayoutOrder = order
    
    local line = Instance.new("Frame", section)
    line.Size = UDim2.new(1, 0, 0, 2)
    line.Position = UDim2.new(0, 0, 1, -2)
    line.BackgroundColor3 = COLORS.Blue
    line.BorderSizePixel = 0
    
    local label = Instance.new("TextLabel", section)
    label.Size = UDim2.new(0.8, 0, 1, 0)
    label.BackgroundTransparency = 1
    label.Text = title:upper()
    label.TextColor3 = COLORS.Blue
    label.Font = Enum.Font.GothamBold
    label.TextSize = 14
    label.TextXAlignment = Enum.TextXAlignment.Left
    
    return section
end

-- ============================================
-- CARD CREATOR
-- ============================================
local function createCard(order)
    local card = Instance.new("Frame", contentContainer)
    card.Size = UDim2.new(1, 0, 0, 0)
    card.AutomaticSize = Enum.AutomaticSize.Y
    card.BackgroundColor3 = COLORS.CardBg
    card.BackgroundTransparency = 0.3
    card.BorderSizePixel = 0
    card.LayoutOrder = order
    Instance.new("UICorner", card).CornerRadius = UDim.new(0, 12)
    
    local cardStroke = Instance.new("UIStroke", card)
    cardStroke.Color = COLORS.Blue
    cardStroke.Thickness = 1
    cardStroke.Transparency = 0.7
    
    return card
end

-- ============================================
-- BUTTON CREATOR
-- ============================================
local function createButton(parent, yPos, text, isBlue, callback)
    local btn = Instance.new("TextButton", parent)
    btn.Size = UDim2.new(1, -20, 0, 42)
    btn.Position = UDim2.new(0, 10, 0, yPos)
    btn.BackgroundColor3 = isBlue and COLORS.BlueDark or COLORS.Blue
    btn.Text = text
    btn.TextColor3 = COLORS.TextWhite
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 15
    btn.AutoButtonColor = false
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 8)
    
    local dot = Instance.new("Frame", btn)
    dot.Size = UDim2.new(0, 10, 0, 10)
    dot.Position = UDim2.new(1, -25, 0.5, -5)
    dot.BackgroundColor3 = COLORS.StatusRed
    Instance.new("UICorner", dot).CornerRadius = UDim.new(1, 0)
    
    btn.MouseEnter:Connect(function()
        TweenService:Create(btn, TweenInfo.new(0.2), {BackgroundColor3 = isBlue and COLORS.BlueLight or COLORS.BlueLight}):Play()
    end)
    btn.MouseLeave:Connect(function()
        local color = isBlue and COLORS.BlueDark or COLORS.Blue
        TweenService:Create(btn, TweenInfo.new(0.2), {BackgroundColor3 = color}):Play()
    end)
    
    return btn, dot
end

-- ============================================
-- TOGGLE ROW CREATOR
-- ============================================
local function createToggleRow(parent, yPos, labelText, isBlue, defaultValue, onToggle)
    local row = Instance.new("Frame", parent)
    row.Size = UDim2.new(1, -20, 0, 42)
    row.Position = UDim2.new(0, 10, 0, yPos)
    row.BackgroundColor3 = COLORS.CardBg
    row.BackgroundTransparency = 0.5
    row.BorderSizePixel = 0
    Instance.new("UICorner", row).CornerRadius = UDim.new(0, 8)
    
    local rowStroke = Instance.new("UIStroke", row)
    rowStroke.Color = COLORS.Blue
    rowStroke.Thickness = 1
    rowStroke.Transparency = 0.6
    
    local label = Instance.new("TextLabel", row)
    label.Size = UDim2.new(1, -80, 1, 0)
    label.Position = UDim2.new(0, 15, 0, 0)
    label.BackgroundTransparency = 1
    label.Text = labelText
    label.TextColor3 = COLORS.TextWhite
    label.Font = Enum.Font.GothamBold
    label.TextSize = 14
    label.TextXAlignment = Enum.TextXAlignment.Left
    
    local switchBg = Instance.new("Frame", row)
    switchBg.Size = UDim2.new(0, 50, 0, 24)
    switchBg.Position = UDim2.new(1, -65, 0.5, -12)
    switchBg.BackgroundColor3 = defaultValue and COLORS.Blue or COLORS.CardBg
    switchBg.BorderSizePixel = 0
    Instance.new("UICorner", switchBg).CornerRadius = UDim.new(1, 0)
    
    local switchCircle = Instance.new("Frame", switchBg)
    switchCircle.Size = UDim2.new(0, 20, 0, 20)
    switchCircle.Position = defaultValue and UDim2.new(1, -23, 0.5, -10) or UDim2.new(0, 3, 0.5, -10)
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
        TweenService:Create(switchCircle, TweenInfo.new(0.2), {Position = isOn and UDim2.new(1, -23, 0.5, -10) or UDim2.new(0, 3, 0.5, -10)}):Play()
        if onToggle then onToggle(isOn) end
    end)
    
    return row
end

-- ============================================
-- SLIDER CREATOR
-- ============================================
local function createSlider(parent, yPos, labelText, defaultValue, minVal, maxVal, onChanged)
    local container = Instance.new("Frame", parent)
    container.Size = UDim2.new(1, -20, 0, 60)
    container.Position = UDim2.new(0, 10, 0, yPos)
    container.BackgroundColor3 = COLORS.CardBg
    container.BackgroundTransparency = 0.5
    container.BorderSizePixel = 0
    Instance.new("UICorner", container).CornerRadius = UDim.new(0, 8)
    
    local containerStroke = Instance.new("UIStroke", container)
    containerStroke.Color = COLORS.Blue
    containerStroke.Thickness = 1
    containerStroke.Transparency = 0.6
    
    local label = Instance.new("TextLabel", container)
    label.Size = UDim2.new(0.6, 0, 0, 25)
    label.Position = UDim2.new(0, 15, 0, 5)
    label.BackgroundTransparency = 1
    label.Text = labelText .. defaultValue
    label.TextColor3 = COLORS.TextWhite
    label.Font = Enum.Font.GothamBold
    label.TextSize = 13
    label.TextXAlignment = Enum.TextXAlignment.Left
    
    local valueBox = Instance.new("TextBox", container)
    valueBox.Size = UDim2.new(0, 60, 0, 25)
    valueBox.Position = UDim2.new(1, -75, 0, 5)
    valueBox.BackgroundColor3 = COLORS.CardBg
    valueBox.Text = tostring(defaultValue)
    valueBox.TextColor3 = COLORS.TextWhite
    valueBox.Font = Enum.Font.GothamBold
    valueBox.TextSize = 13
    valueBox.TextXAlignment = Enum.TextXAlignment.Center
    Instance.new("UICorner", valueBox).CornerRadius = UDim.new(0, 6)
    
    local sliderBg = Instance.new("Frame", container)
    sliderBg.Size = UDim2.new(1, -30, 0, 8)
    sliderBg.Position = UDim2.new(0, 15, 0, 40)
    sliderBg.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
    sliderBg.BorderSizePixel = 0
    Instance.new("UICorner", sliderBg).CornerRadius = UDim.new(1, 0)
    
    local sliderFill = Instance.new("Frame", sliderBg)
    sliderFill.Size = UDim2.new((defaultValue - minVal) / (maxVal - minVal), 0, 1, 0)
    sliderFill.BackgroundColor3 = COLORS.Blue
    sliderFill.BorderSizePixel = 0
    Instance.new("UICorner", sliderFill).CornerRadius = UDim.new(1, 0)
    
    local knob = Instance.new("Frame", sliderFill)
    knob.Size = UDim2.new(0, 16, 0, 16)
    knob.Position = UDim2.new(1, -8, 0.5, -8)
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
    UserInputService.InputChanged:Connect(function(i)
        if dragging and i.UserInputType == Enum.UserInputType.MouseMovement then
            local pct = math.clamp((i.Position.X - sliderBg.AbsolutePosition.X) / sliderBg.AbsoluteSize.X, 0, 1)
            local val = math.floor(minVal + pct * (maxVal - minVal))
            sliderFill.Size = UDim2.new(pct, 0, 1, 0)
            label.Text = labelText .. val
            valueBox.Text = tostring(val)
            if onChanged then onChanged(val) end
        end
    end)
    
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

local ragCard = createCard(order)
order = order + 1

local ragY = 10
local leftRow = createToggleRow(ragCard, ragY, "AUTO TP LEFT", true, false, function(on)
    autoTpLeft = on
    if on then autoTpRight = false
        if rightRow then
            TweenService:Create(rightRow, TweenInfo.new(0.2), {BackgroundColor3 = COLORS.CardBg}):Play()
        end
    end
end)
ragY = ragY + 52

local rightRow = createToggleRow(ragCard, ragY, "AUTO TP RIGHT", false, false, function(on)
    autoTpRight = on
    if on then autoTpLeft = false
        if leftRow then
            TweenService:Create(leftRow, TweenInfo.new(0.2), {BackgroundColor3 = COLORS.CardBg}):Play()
        end
    end
end)
ragY = ragY + 52

-- SECTION 2: AUTO DUEL
createSection("AUTO DUEL", order)
order = order + 1

local duelCard = createCard(order)
order = order + 1

local duelY = 10
local leftDuelBtn, leftDuelDot = createButton(duelCard, duelY, "AUTO LEFT ● OFF", true, function(btn, dot)
    AutoLeftEnabled = not AutoLeftEnabled
    if AutoLeftEnabled then
        AutoRightEnabled = false
        stopAutoRight()
        startAutoLeft()
        if rightDuelBtn then
            TweenService:Create(rightDuelBtn, TweenInfo.new(0.2), {BackgroundColor3 = COLORS.BlueDark}):Play()
            rightDuelDot.BackgroundColor3 = COLORS.StatusRed
            rightDuelBtn.Text = "AUTO RIGHT ● OFF"
        end
        TweenService:Create(btn, TweenInfo.new(0.2), {BackgroundColor3 = COLORS.BlueLight}):Play()
        dot.BackgroundColor3 = COLORS.StatusGreen
        btn.Text = "AUTO LEFT ● ON"
    else
        stopAutoLeft()
        TweenService:Create(btn, TweenInfo.new(0.2), {BackgroundColor3 = COLORS.BlueDark}):Play()
        dot.BackgroundColor3 = COLORS.StatusRed
        btn.Text = "AUTO LEFT ● OFF"
    end
end)
duelY = duelY + 52

local rightDuelBtn, rightDuelDot = createButton(duelCard, duelY, "AUTO RIGHT ● OFF", false, function(btn, dot)
    AutoRightEnabled = not AutoRightEnabled
    if AutoRightEnabled then
        AutoLeftEnabled = false
        stopAutoLeft()
        startAutoRight()
        if leftDuelBtn then
            TweenService:Create(leftDuelBtn, TweenInfo.new(0.2), {BackgroundColor3 = COLORS.BlueDark}):Play()
            leftDuelDot.BackgroundColor3 = COLORS.StatusRed
            leftDuelBtn.Text = "AUTO LEFT ● OFF"
        end
        TweenService:Create(btn, TweenInfo.new(0.2), {BackgroundColor3 = COLORS.BlueLight}):Play()
        dot.BackgroundColor3 = COLORS.StatusGreen
        btn.Text = "AUTO RIGHT ● ON"
    else
        stopAutoRight()
        TweenService:Create(btn, TweenInfo.new(0.2), {BackgroundColor3 = COLORS.BlueDark}):Play()
        dot.BackgroundColor3 = COLORS.StatusRed
        btn.Text = "AUTO RIGHT ● OFF"
    end
end)
duelY = duelY + 52

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

-- Duel Speed Sliders
createSlider(duelCard, duelY, "WALK SPEED: ", duelConfig.ForwardSpeed, 20, 100, function(v)
    duelConfig.ForwardSpeed = v
end)
duelY = duelY + 70

createSlider(duelCard, duelY, "STEAL SPEED: ", duelConfig.ReturnSpeed, 10, 80, function(v)
    duelConfig.ReturnSpeed = v
end)
duelY = duelY + 70

-- SECTION 3: AUTO STEAL
createSection("AUTO STEAL", order)
order = order + 1

local stealCard = createCard(order)
order = order + 1

local stealY = 10
local stealBtn, stealDot = createButton(stealCard, stealY, "AUTO STEAL ● OFF", false, function(btn, dot)
    stealActive = not stealActive
    if stealActive then
        TweenService:Create(btn, TweenInfo.new(0.2), {BackgroundColor3 = COLORS.BlueLight}):Play()
        dot.BackgroundColor3 = COLORS.StatusGreen
        btn.Text = "AUTO STEAL ● ON"
    else
        TweenService:Create(btn, TweenInfo.new(0.2), {BackgroundColor3 = COLORS.BlueDark}):Play()
        dot.BackgroundColor3 = COLORS.StatusRed
        btn.Text = "AUTO STEAL ● OFF"
    end
end)
stealY = stealY + 52

-- Steal Radius Slider
local radiusContainer = Instance.new("Frame", stealCard)
radiusContainer.Size = UDim2.new(1, -20, 0, 60)
radiusContainer.Position = UDim2.new(0, 10, 0, stealY)
radiusContainer.BackgroundColor3 = COLORS.CardBg
radiusContainer.BackgroundTransparency = 0.5
radiusContainer.BorderSizePixel = 0
Instance.new("UICorner", radiusContainer).CornerRadius = UDim.new(0, 8)

local radiusStroke = Instance.new("UIStroke", radiusContainer)
radiusStroke.Color = COLORS.Blue
radiusStroke.Thickness = 1
radiusStroke.Transparency = 0.6

local radiusLabel = Instance.new("TextLabel", radiusContainer)
radiusLabel.Size = UDim2.new(0.6, 0, 0, 25)
radiusLabel.Position = UDim2.new(0, 15, 0, 5)
radiusLabel.BackgroundTransparency = 1
radiusLabel.Text = "STEAL RADIUS: " .. STEAL_R
radiusLabel.TextColor3 = COLORS.TextWhite
radiusLabel.Font = Enum.Font.GothamBold
radiusLabel.TextSize = 13
radiusLabel.TextXAlignment = Enum.TextXAlignment.Left

local radiusBox = Instance.new("TextBox", radiusContainer)
radiusBox.Size = UDim2.new(0, 60, 0, 25)
radiusBox.Position = UDim2.new(1, -75, 0, 5)
radiusBox.BackgroundColor3 = COLORS.CardBg
radiusBox.Text = tostring(STEAL_R)
radiusBox.TextColor3 = COLORS.TextWhite
radiusBox.Font = Enum.Font.GothamBold
radiusBox.TextSize = 13
radiusBox.TextXAlignment = Enum.TextXAlignment.Center
Instance.new("UICorner", radiusBox).CornerRadius = UDim.new(0, 6)

local radiusSliderBg = Instance.new("Frame", radiusContainer)
radiusSliderBg.Size = UDim2.new(1, -30, 0, 8)
radiusSliderBg.Position = UDim2.new(0, 15, 0, 40)
radiusSliderBg.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
radiusSliderBg.BorderSizePixel = 0
Instance.new("UICorner", radiusSliderBg).CornerRadius = UDim.new(1, 0)

local radiusSliderFill = Instance.new("Frame", radiusSliderBg)
radiusSliderFill.Size = UDim2.new(STEAL_R / 20, 0, 1, 0)
radiusSliderFill.BackgroundColor3 = COLORS.Blue
radiusSliderFill.BorderSizePixel = 0
Instance.new("UICorner", radiusSliderFill).CornerRadius = UDim.new(1, 0)

local radiusKnob = Instance.new("Frame", radiusSliderFill)
radiusKnob.Size = UDim2.new(0, 16, 0, 16)
radiusKnob.Position = UDim2.new(1, -8, 0.5, -8)
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
        local pct = math.clamp((i.Position.X - radiusSliderBg.AbsolutePosition.X) / radiusSliderBg.AbsoluteSize.X, 0, 1)
        STEAL_R = math.floor(1 + pct * 19)
        radiusSliderFill.Size = UDim2.new(pct, 0, 1, 0)
        radiusLabel.Text = "STEAL RADIUS: " .. STEAL_R
        radiusBox.Text = tostring(STEAL_R)
    end
end)

radiusBox.FocusLost:Connect(function()
    local n = tonumber(radiusBox.Text)
    if n then
        STEAL_R = math.clamp(n, 1, 20)
        local pct = (STEAL_R - 1) / 19
        radiusSliderFill.Size = UDim2.new(pct, 0, 1, 0)
        radiusLabel.Text = "STEAL RADIUS: " .. STEAL_R
        radiusBox.Text = tostring(STEAL_R)
    else
        radiusBox.Text = tostring(STEAL_R)
    end
end)

stealY = stealY + 70

-- SECTION 4: UTILITIES
createSection("UTILITIES", order)
order = order + 1

local utilCard = createCard(order)
order = order + 1

local utilY = 10
local antiBtn, antiDot = createButton(utilCard, utilY, "ANTI RAGDOLL ● OFF", true, function(btn, dot)
    if antirag then
        disableAntiRagdoll()
        TweenService:Create(btn, TweenInfo.new(0.2), {BackgroundColor3 = COLORS.BlueDark}):Play()
        dot.BackgroundColor3 = COLORS.StatusRed
        btn.Text = "ANTI RAGDOLL ● OFF"
    else
        enableAntiRagdoll()
        TweenService:Create(btn, TweenInfo.new(0.2), {BackgroundColor3 = COLORS.BlueLight}):Play()
        dot.BackgroundColor3 = COLORS.StatusGreen
        btn.Text = "ANTI RAGDOLL ● ON"
    end
    antirag = not antirag
end)
utilY = utilY + 52

local floatBtn, floatDot = createButton(utilCard, utilY, "FLOAT NEAREST ● OFF", false, function(btn, dot)
    if floaton then
        stopFloat()
        TweenService:Create(btn, TweenInfo.new(0.2), {BackgroundColor3 = COLORS.BlueDark}):Play()
        dot.BackgroundColor3 = COLORS.StatusRed
        btn.Text = "FLOAT NEAREST ● OFF"
    else
        startFloat()
        TweenService:Create(btn, TweenInfo.new(0.2), {BackgroundColor3 = COLORS.BlueLight}):Play()
        dot.BackgroundColor3 = COLORS.StatusGreen
        btn.Text = "FLOAT NEAREST ● ON"
    end
    floaton = not floaton
end)
utilY = utilY + 52

local infBtn, infDot = createButton(utilCard, utilY, "INFINITE JUMP ● OFF", true, function(btn, dot)
    infjump = not infjump
    if infjump then
        TweenService:Create(btn, TweenInfo.new(0.2), {BackgroundColor3 = COLORS.BlueLight}):Play()
        dot.BackgroundColor3 = COLORS.StatusGreen
        btn.Text = "INFINITE JUMP ● ON"
    else
        TweenService:Create(btn, TweenInfo.new(0.2), {BackgroundColor3 = COLORS.BlueDark}):Play()
        dot.BackgroundColor3 = COLORS.StatusRed
        btn.Text = "INFINITE JUMP ● OFF"
    end
end)
utilY = utilY + 52

-- ============================================
-- WINDOW CONTROLS
-- ============================================
local isMinimized = false
local originalSize = UDim2.new(0, 500, 0, 560)
local minimizedSize = UDim2.new(0, 500, 0, 50)

local function setMinimized(state)
    isMinimized = state
    if isMinimized then
        TweenService:Create(mainFrame, TweenInfo.new(0.3, Enum.EasingStyle.Quad), {Size = minimizedSize, Position = UDim2.new(0.5, -250, 0.5, -25)}):Play()
        scrollFrame.Visible = false
        minimizeBtn.Text = "□"
    else
        TweenService:Create(mainFrame, TweenInfo.new(0.3, Enum.EasingStyle.Quad), {Size = originalSize, Position = UDim2.new(0.5, -250, 0.5, -280)}):Play()
        scrollFrame.Visible = true
        minimizeBtn.Text = "−"
    end
end

minimizeBtn.MouseButton1Click:Connect(function()
    setMinimized(not isMinimized)
end)

closeBtn.MouseButton1Click:Connect(function()
    screenGui:Destroy()
end)

-- ============================================
-- CLEANUP
-- ============================================
screenGui.Destroying:Connect(function()
    if strokeTween then strokeTween:Cancel() end
    if stealConn then stealConn:Disconnect() end
    if floatConn then floatConn:Disconnect() end
    killConns()
end)

-- Character respawn handling
LocalPlayer.CharacterAdded:Connect(function(c)
    task.wait(0.5)
    if antirag then enableAntiRagdoll() end
    if floaton then startFloat() end
    autoTpLeft = false
    autoTpRight = false
    isTeleporting = false
    hasRecovered = true
    stealActive = false
    if stealBtn then
        TweenService:Create(stealBtn, TweenInfo.new(0.2), {BackgroundColor3 = COLORS.BlueDark}):Play()
        stealDot.BackgroundColor3 = COLORS.StatusRed
        stealBtn.Text = "AUTO STEAL ● OFF"
    end
end)

-- Keyboard shortcut to toggle GUI (Right Control)
UserInputService.InputBegan:Connect(function(i, g)
    if not g and i.KeyCode == Enum.KeyCode.RightControl then
        screenGui.Enabled = not screenGui.Enabled
    end
end)

-- Auto copy Discord invite
pcall(function()
    if setclipboard then
        setclipboard("https://discord.gg/xent")
    end
end)

print("XENT DUELS - Complete Duel Hub Loaded")