-- XENTHUB DUELS - Complete Duel Hub
-- FULLY WORKING: Drag, Sliders, Scroll, Logic

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer

-- ============================================
-- ANIMATED COLORS
-- ============================================
local COLORS = {
    BG = Color3.fromRGB(3, 3, 8),
    CARD = Color3.fromRGB(8, 10, 16),
    BLUE = Color3.fromRGB(0, 100, 255),
    BLUE_LIGHT = Color3.fromRGB(0, 150, 255),
    BLUE_DARK = Color3.fromRGB(0, 60, 200),
    TEXT = Color3.fromRGB(255, 255, 255),
    TEXT_DIM = Color3.fromRGB(140, 145, 160),
    GREEN = Color3.fromRGB(0, 220, 80),
    RED = Color3.fromRGB(255, 50, 50),
}

-- ============================================
-- COORDINATES
-- ============================================
local FINAL_LEFT = Vector3.new(-483.59, -5.04, 104.24)
local FINAL_RIGHT = Vector3.new(-483.51, -5.10, 18.89)
local CHECK_A = Vector3.new(-472.60, -7.00, 57.52)
local CHECK_B1 = Vector3.new(-472.65, -7.00, 95.69)
local CHECK_B2 = Vector3.new(-471.76, -7.00, 26.22)

local L1 = Vector3.new(-476.48, -6.28, 92.73)
local L_END = Vector3.new(-483.12, -4.95, 94.80)
local L_FINAL = Vector3.new(-473.38, -8.40, 22.34)
local R1 = Vector3.new(-476.16, -6.52, 25.62)
local R_END = Vector3.new(-483.04, -5.09, 23.14)
local R_FINAL = Vector3.new(-476.17, -7.91, 97.91)

-- ============================================
-- GLOBAL STATE (so UI can modify)
-- ============================================
_G.XENTHUB = {
    -- Ragdoll TP
    tpLeft = false,
    tpRight = false,
    tpActive = false,
    recovered = true,
    
    -- Auto Duel
    duelLeft = false,
    duelRight = false,
    walkSpeed = 59,
    stealSpeed = 28,
    
    -- Auto Steal
    autoSteal = false,
    stealRadius = 7,
    
    -- Utilities
    antiRag = false,
    floatEnabled = false,
    infJump = false,
}

-- ============================================
-- HELPERS
-- ============================================
local function getHRP()
    local c = LocalPlayer.Character
    return c and c:FindFirstChild("HumanoidRootPart")
end

local function getHum()
    local c = LocalPlayer.Character
    return c and c:FindFirstChildOfClass("Humanoid")
end

local function moveTo(pos)
    local c = LocalPlayer.Character
    if c then
        c:PivotTo(CFrame.new(pos))
        local r = c:FindFirstChild("HumanoidRootPart")
        if r then r.AssemblyLinearVelocity = Vector3.zero end
    end
end

-- ============================================
-- RAGDOLL TP (CONNECTED TO ANTI-RAGDOLL)
-- ============================================
local function doTP(side)
    _G.XENTHUB.tpActive = true
    _G.XENTHUB.recovered = false
    local b = side == "Left" and CHECK_B1 or CHECK_B2
    local f = side == "Left" and FINAL_LEFT or FINAL_RIGHT
    moveTo(CHECK_A)
    task.wait(0.12)
    moveTo(b)
    task.wait(0.12)
    moveTo(f)
    _G.XENTHUB.tpActive = false
end

-- ============================================
-- AUTO DUEL LOGIC
-- ============================================
local leftConn = nil
local rightConn = nil
local leftPhase = 1
local rightPhase = 1

local function stopLeft()
    if leftConn then leftConn:Disconnect(); leftConn = nil end
    leftPhase = 1
    local h = getHum()
    if h then h:Move(Vector3.zero, false) end
end

local function startLeft()
    if leftConn then leftConn:Disconnect() end
    leftPhase = 1
    leftConn = RunService.Heartbeat:Connect(function()
        if not _G.XENTHUB.duelLeft then return end
        local r, h = getHRP(), getHum()
        if not r or not h then return end
        
        if leftPhase == 1 then
            local d = Vector3.new(L1.X - r.Position.X, 0, L1.Z - r.Position.Z)
            if d.Magnitude < 1 then leftPhase = 2 return end
            local dir = d.Unit
            h:Move(dir, false)
            r.AssemblyLinearVelocity = Vector3.new(dir.X * _G.XENTHUB.walkSpeed, r.AssemblyLinearVelocity.Y, dir.Z * _G.XENTHUB.walkSpeed)
        elseif leftPhase == 2 then
            local d = Vector3.new(L_END.X - r.Position.X, 0, L_END.Z - r.Position.Z)
            if d.Magnitude < 1 then
                leftPhase = 0
                h:Move(Vector3.zero, false)
                r.AssemblyLinearVelocity = Vector3.zero
                task.delay(0.2, function() if _G.XENTHUB.duelLeft then leftPhase = 3 end end)
                return
            end
            local dir = d.Unit
            h:Move(dir, false)
            r.AssemblyLinearVelocity = Vector3.new(dir.X * _G.XENTHUB.walkSpeed, r.AssemblyLinearVelocity.Y, dir.Z * _G.XENTHUB.walkSpeed)
        elseif leftPhase == 3 then
            local d = Vector3.new(L1.X - r.Position.X, 0, L1.Z - r.Position.Z)
            if d.Magnitude < 1 then leftPhase = 4 return end
            local dir = d.Unit
            h:Move(dir, false)
            r.AssemblyLinearVelocity = Vector3.new(dir.X * _G.XENTHUB.stealSpeed, r.AssemblyLinearVelocity.Y, dir.Z * _G.XENTHUB.stealSpeed)
        elseif leftPhase == 4 then
            local d = Vector3.new(L_FINAL.X - r.Position.X, 0, L_FINAL.Z - r.Position.Z)
            if d.Magnitude < 1 then
                h:Move(Vector3.zero, false)
                r.AssemblyLinearVelocity = Vector3.zero
                _G.XENTHUB.duelLeft = false
                stopLeft()
                return
            end
            local dir = d.Unit
            h:Move(dir, false)
            r.AssemblyLinearVelocity = Vector3.new(dir.X * _G.XENTHUB.stealSpeed, r.AssemblyLinearVelocity.Y, dir.Z * _G.XENTHUB.stealSpeed)
        end
    end)
end

local function stopRight()
    if rightConn then rightConn:Disconnect(); rightConn = nil end
    rightPhase = 1
    local h = getHum()
    if h then h:Move(Vector3.zero, false) end
end

local function startRight()
    if rightConn then rightConn:Disconnect() end
    rightPhase = 1
    rightConn = RunService.Heartbeat:Connect(function()
        if not _G.XENTHUB.duelRight then return end
        local r, h = getHRP(), getHum()
        if not r or not h then return end
        
        if rightPhase == 1 then
            local d = Vector3.new(R1.X - r.Position.X, 0, R1.Z - r.Position.Z)
            if d.Magnitude < 1 then rightPhase = 2 return end
            local dir = d.Unit
            h:Move(dir, false)
            r.AssemblyLinearVelocity = Vector3.new(dir.X * _G.XENTHUB.walkSpeed, r.AssemblyLinearVelocity.Y, dir.Z * _G.XENTHUB.walkSpeed)
        elseif rightPhase == 2 then
            local d = Vector3.new(R_END.X - r.Position.X, 0, R_END.Z - r.Position.Z)
            if d.Magnitude < 1 then
                rightPhase = 0
                h:Move(Vector3.zero, false)
                r.AssemblyLinearVelocity = Vector3.zero
                task.delay(0.2, function() if _G.XENTHUB.duelRight then rightPhase = 3 end end)
                return
            end
            local dir = d.Unit
            h:Move(dir, false)
            r.AssemblyLinearVelocity = Vector3.new(dir.X * _G.XENTHUB.walkSpeed, r.AssemblyLinearVelocity.Y, dir.Z * _G.XENTHUB.walkSpeed)
        elseif rightPhase == 3 then
            local d = Vector3.new(R1.X - r.Position.X, 0, R1.Z - r.Position.Z)
            if d.Magnitude < 1 then rightPhase = 4 return end
            local dir = d.Unit
            h:Move(dir, false)
            r.AssemblyLinearVelocity = Vector3.new(dir.X * _G.XENTHUB.stealSpeed, r.AssemblyLinearVelocity.Y, dir.Z * _G.XENTHUB.stealSpeed)
        elseif rightPhase == 4 then
            local d = Vector3.new(R_FINAL.X - r.Position.X, 0, R_FINAL.Z - r.Position.Z)
            if d.Magnitude < 1 then
                h:Move(Vector3.zero, false)
                r.AssemblyLinearVelocity = Vector3.zero
                _G.XENTHUB.duelRight = false
                stopRight()
                return
            end
            local dir = d.Unit
            h:Move(dir, false)
            r.AssemblyLinearVelocity = Vector3.new(dir.X * _G.XENTHUB.stealSpeed, r.AssemblyLinearVelocity.Y, dir.Z * _G.XENTHUB.stealSpeed)
        end
    end)
end

-- ============================================
-- AUTO STEAL LOGIC
-- ============================================
local animals = {}
local prompts = {}
local stealing = false
local stealLoop = nil

local function isMyPlot(name)
    local p = workspace.Plots and workspace.Plots:FindFirstChild(name)
    if not p then return false end
    local s = p:FindFirstChild("PlotSign")
    if not s then return false end
    local yb = s:FindFirstChild("YourBase")
    return yb and yb:IsA("BillboardGui") and yb.Enabled == true
end

local function scanAnimals()
    animals = {}
    local plots = workspace:FindFirstChild("Plots")
    if not plots then return end
    for _, p in ipairs(plots:GetChildren()) do
        if p:IsA("Model") and not isMyPlot(p.Name) then
            local pods = p:FindFirstChild("AnimalPodiums")
            if pods then
                for _, pod in ipairs(pods:GetChildren()) do
                    if pod:IsA("Model") and pod:FindFirstChild("Base") then
                        local spawn = pod.Base:FindFirstChild("Spawn")
                        if spawn then
                            table.insert(animals, {
                                pos = pod:GetPivot().Position,
                                uid = p.Name .. "_" .. pod.Name,
                                plot = p.Name,
                                slot = pod.Name
                            })
                        end
                    end
                end
            end
        end
    end
end

local function getPrompt(ad)
    if prompts[ad.uid] and prompts[ad.uid].Parent then return prompts[ad.uid] end
    local plots = workspace:FindFirstChild("Plots")
    if not plots then return nil end
    local p = plots:FindFirstChild(ad.plot)
    if not p then return nil end
    local pods = p:FindFirstChild("AnimalPodiums")
    if not pods then return nil end
    local pod = pods:FindFirstChild(ad.slot)
    if not pod then return nil end
    local base = pod:FindFirstChild("Base")
    if not base then return nil end
    local spawn = base:FindFirstChild("Spawn")
    if not spawn then return nil end
    local att = spawn:FindFirstChild("PromptAttachment")
    if not att then return nil end
    for _, pr in ipairs(att:GetChildren()) do
        if pr:IsA("ProximityPrompt") then
            prompts[ad.uid] = pr
            return pr
        end
    end
    return nil
end

local function doSteal(prompt)
    if stealing then return end
    stealing = true
    pcall(function()
        if fireproximityprompt then
            fireproximityprompt(prompt)
        else
            prompt:InputHoldBegin()
            task.wait(0.2)
            prompt:InputHoldEnd()
        end
    end)
    task.wait(0.1)
    stealing = false
end

local function startStealLoop()
    if stealLoop then stealLoop:Disconnect() end
    stealLoop = RunService.Heartbeat:Connect(function()
        if not _G.XENTHUB.autoSteal or stealing then return end
        local hrp = getHRP()
        if not hrp then return end
        local nearest = nil
        local nearestDist = _G.XENTHUB.stealRadius + 1
        for _, a in ipairs(animals) do
            local d = (hrp.Position - a.pos).Magnitude
            if d < nearestDist then
                nearestDist = d
                nearest = a
            end
        end
        if nearest and nearestDist <= _G.XENTHUB.stealRadius then
            local p = getPrompt(nearest)
            if p then doSteal(p) end
        end
    end)
end

-- ============================================
-- ANTI RAGDOLL (CONNECTED TO TP)
-- ============================================
local antiConn = nil

local function isRagdolled()
    local h = getHum()
    if not h then return false end
    local s = h:GetState()
    return s == Enum.HumanoidStateType.Physics or s == Enum.HumanoidStateType.Ragdoll or s == Enum.HumanoidStateType.FallingDown
end

local function fixRagdoll()
    local h = getHum()
    local r = getHRP()
    if h and r then
        if h.Health > 0 then h:ChangeState(Enum.HumanoidStateType.Running) end
        r.AssemblyLinearVelocity = Vector3.zero
        r.AssemblyAngularVelocity = Vector3.zero
        r.Anchored = false
        workspace.CurrentCamera.CameraSubject = h
    end
end

local function startAnti()
    if antiConn then antiConn:Disconnect() end
    antiConn = RunService.Heartbeat:Connect(function()
        if _G.XENTHUB.antiRag and isRagdolled() then fixRagdoll() end
    end)
end

-- RAGDOLL TP DETECTION (CONNECTED)
RunService.Heartbeat:Connect(function()
    local h = getHum()
    if h then
        local rag = isRagdolled()
        if not rag then _G.XENTHUB.recovered = true end
        if not _G.XENTHUB.tpActive and _G.XENTHUB.recovered and rag then
            if _G.XENTHUB.tpLeft then doTP("Left")
            elseif _G.XENTHUB.tpRight then doTP("Right") end
        end
    end
end)

-- ============================================
-- FLOAT LOGIC
-- ============================================
local floatLoop = nil

local function startFloatLoop()
    if floatLoop then floatLoop:Disconnect() end
    floatLoop = RunService.Heartbeat:Connect(function()
        if not _G.XENTHUB.floatEnabled then return end
        local r = getHRP()
        if not r then return end
        local target = nil
        local targetDist = math.huge
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= LocalPlayer and p.Character then
                local tr = p.Character:FindFirstChild("HumanoidRootPart")
                if tr then
                    local d = (r.Position - tr.Position).Magnitude
                    if d < targetDist then
                        targetDist = d
                        target = tr
                    end
                end
            end
        end
        if target then
            local dir = (target.Position - r.Position).Unit
            local yDiff = target.Position.Y - r.Position.Y
            local yVel = yDiff > 2 and 35 or (yDiff < -2 and -18 or 0)
            r.AssemblyLinearVelocity = Vector3.new(dir.X * 56, yVel, dir.Z * 56)
        else
            r.AssemblyLinearVelocity = Vector3.new(0, r.AssemblyLinearVelocity.Y, 0)
        end
    end)
end

-- ============================================
-- INFINITE JUMP
-- ============================================
UserInputService.JumpRequest:Connect(function()
    if _G.XENTHUB.infJump and LocalPlayer.Character then
        local r = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        if r then r.AssemblyLinearVelocity = Vector3.new(r.AssemblyLinearVelocity.X, 52, r.AssemblyLinearVelocity.Z) end
    end
end)

-- ============================================
-- INITIALIZE BACKGROUND TASKS
-- ============================================
task.spawn(function()
    while task.wait(3) do
        pcall(scanAnimals)
    end
end)
task.wait(1)
pcall(scanAnimals)
startStealLoop()
startAnti()

-- ============================================
-- GUI - FULLY WORKING
-- ============================================
local isMobile = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled
local guiSize = isMobile and UDim2.new(0, 290, 0, 440) or UDim2.new(0, 320, 0, 480)

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "XENTHUB"
screenGui.ResetOnSpawn = false
screenGui.Parent = game:GetService("CoreGui")

local mainFrame = Instance.new("Frame", screenGui)
mainFrame.Size = guiSize
mainFrame.Position = UDim2.new(0.5, -guiSize.X.Offset/2, 0.5, -guiSize.Y.Offset/2)
mainFrame.BackgroundColor3 = COLORS.BG
mainFrame.BackgroundTransparency = 0.05
mainFrame.BorderSizePixel = 0
mainFrame.ClipsDescendants = true
Instance.new("UICorner", mainFrame).CornerRadius = UDim.new(0, 16)

-- Animated border
local border = Instance.new("UIStroke", mainFrame)
border.Thickness = 2.5
border.Color = COLORS.BLUE
border.Transparency = 0.3

task.spawn(function()
    while screenGui and mainFrame do
        task.wait(0.05)
        local t = tick() * 1.5
        local r = 0
        local g = 80 + math.sin(t) * 50
        local b = 180 + math.cos(t) * 75
        border.Color = Color3.fromRGB(r, g, b)
        border.Transparency = 0.2 + math.sin(t) * 0.2
    end
end)

-- DRAG FUNCTIONALITY (ONLY TOP BAR)
local dragActive = false
local dragStart, dragPos

-- TOP BAR (draggable area)
local topBar = Instance.new("Frame", mainFrame)
topBar.Size = UDim2.new(1, 0, 0, isMobile and 50 or 55)
topBar.BackgroundColor3 = COLORS.BLUE_DARK
topBar.BorderSizePixel = 0
Instance.new("UICorner", topBar).CornerRadius = UDim.new(0, 16)

-- Make top bar draggable
topBar.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragActive = true
        dragStart = input.Position
        dragPos = mainFrame.Position
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if dragActive and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        local delta = input.Position - dragStart
        mainFrame.Position = UDim2.new(dragPos.X.Scale, dragPos.X.Offset + delta.X, dragPos.Y.Scale, dragPos.Y.Offset + delta.Y)
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragActive = false
    end
end)

-- Title
local title = Instance.new("TextLabel", topBar)
title.Size = UDim2.new(1, -100, 1, 0)
title.Position = UDim2.new(0, 15, 0, 0)
title.BackgroundTransparency = 1
title.Text = "XENTHUB DUELS"
title.TextColor3 = COLORS.TEXT
title.Font = Enum.Font.GothamBlack
title.TextSize = isMobile and 18 or 20
title.TextXAlignment = Enum.TextXAlignment.Left

-- Subtitle
local sub = Instance.new("TextLabel", topBar)
sub.Size = UDim2.new(1, -100, 0, 16)
sub.Position = UDim2.new(0, 15, 0, isMobile and 30 or 34)
sub.BackgroundTransparency = 1
sub.Text = "discord.gg/xenthub"
sub.TextColor3 = COLORS.TEXT_DIM
sub.Font = Enum.Font.Gotham
sub.TextSize = 10
sub.TextXAlignment = Enum.TextXAlignment.Left

-- Minimize button
local miniBtn = Instance.new("TextButton", topBar)
miniBtn.Size = UDim2.new(0, isMobile and 32 or 35, 0, isMobile and 32 or 35)
miniBtn.Position = UDim2.new(1, isMobile and -75 or -80, 0.5, isMobile and -16 or -17)
miniBtn.BackgroundColor3 = COLORS.BLUE
miniBtn.Text = "−"
miniBtn.TextColor3 = COLORS.TEXT
miniBtn.Font = Enum.Font.GothamBold
miniBtn.TextSize = isMobile and 22 or 24
miniBtn.AutoButtonColor = false
Instance.new("UICorner", miniBtn).CornerRadius = UDim.new(0, 8)

-- Close button
local closeBtn = Instance.new("TextButton", topBar)
closeBtn.Size = UDim2.new(0, isMobile and 32 or 35, 0, isMobile and 32 or 35)
closeBtn.Position = UDim2.new(1, isMobile and -38 or -42, 0.5, isMobile and -16 or -17)
closeBtn.BackgroundColor3 = COLORS.RED
closeBtn.Text = "✕"
closeBtn.TextColor3 = COLORS.TEXT
closeBtn.Font = Enum.Font.GothamBold
closeBtn.TextSize = isMobile and 18 or 20
closeBtn.AutoButtonColor = false
Instance.new("UICorner", closeBtn).CornerRadius = UDim.new(0, 8)

-- Hover effects
miniBtn.MouseEnter:Connect(function() TweenService:Create(miniBtn, TweenInfo.new(0.15), {BackgroundColor3 = COLORS.BLUE_LIGHT}):Play() end)
miniBtn.MouseLeave:Connect(function() TweenService:Create(miniBtn, TweenInfo.new(0.15), {BackgroundColor3 = COLORS.BLUE}):Play() end)
closeBtn.MouseEnter:Connect(function() TweenService:Create(closeBtn, TweenInfo.new(0.15), {BackgroundColor3 = Color3.fromRGB(220, 40, 40)}):Play() end)
closeBtn.MouseLeave:Connect(function() TweenService:Create(closeBtn, TweenInfo.new(0.15), {BackgroundColor3 = COLORS.RED}):Play() end)

-- SCROLLING FRAME (FIXED)
local scroll = Instance.new("ScrollingFrame", mainFrame)
scroll.Size = UDim2.new(1, -12, 1, -(topBar.Size.Y.Offset + 8))
scroll.Position = UDim2.new(0, 6, 0, topBar.Size.Y.Offset + 4)
scroll.BackgroundTransparency = 1
scroll.BorderSizePixel = 0
scroll.ScrollBarThickness = 4
scroll.ScrollBarImageColor3 = COLORS.BLUE
scroll.ScrollBarImageTransparency = 0.5

local container = Instance.new("Frame", scroll)
container.Size = UDim2.new(1, 0, 0, 0)
container.AutomaticSize = Enum.AutomaticSize.Y
container.BackgroundTransparency = 1

local layout = Instance.new("UIListLayout", container)
layout.Padding = UDim.new(0, 8)
layout.SortOrder = Enum.SortOrder.LayoutOrder

-- Update canvas size when content changes
local function updateCanvas()
    task.wait(0.05)
    scroll.CanvasSize = UDim2.new(0, 0, 0, container.AbsoluteSize.Y + 15)
end

layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(updateCanvas)
task.spawn(updateCanvas)

-- ============================================
-- UI COMPONENTS
-- ============================================
local function makeSection(title)
    local s = Instance.new("Frame", container)
    s.Size = UDim2.new(1, 0, 0, 28)
    s.BackgroundTransparency = 1
    
    local line = Instance.new("Frame", s)
    line.Size = UDim2.new(1, 0, 0, 2)
    line.Position = UDim2.new(0, 0, 1, -2)
    line.BackgroundColor3 = COLORS.BLUE
    line.BorderSizePixel = 0
    
    local l = Instance.new("TextLabel", s)
    l.Size = UDim2.new(1, -10, 1, 0)
    l.BackgroundTransparency = 1
    l.Text = title:upper()
    l.TextColor3 = COLORS.BLUE
    l.Font = Enum.Font.GothamBold
    l.TextSize = 12
    l.TextXAlignment = Enum.TextXAlignment.Left
end

local function makeButton(parent, text, isBlue, callback)
    local btn = Instance.new("TextButton", parent)
    btn.Size = UDim2.new(1, -10, 0, isMobile and 42 or 44)
    btn.BackgroundColor3 = isBlue and COLORS.BLUE_DARK or COLORS.BLUE
    btn.Text = text .. " ● OFF"
    btn.TextColor3 = COLORS.TEXT
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = isMobile and 13 or 14
    btn.AutoButtonColor = false
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 10)
    
    local dot = Instance.new("Frame", btn)
    dot.Size = UDim2.new(0, 10, 0, 10)
    dot.Position = UDim2.new(1, -22, 0.5, -5)
    dot.BackgroundColor3 = COLORS.RED
    Instance.new("UICorner", dot).CornerRadius = UDim.new(1, 0)
    
    local active = false
    
    btn.MouseEnter:Connect(function()
        TweenService:Create(btn, TweenInfo.new(0.15), {BackgroundColor3 = COLORS.BLUE_LIGHT}):Play()
    end)
    btn.MouseLeave:Connect(function()
        local c = isBlue and COLORS.BLUE_DARK or COLORS.BLUE
        if active then c = COLORS.BLUE_LIGHT end
        TweenService:Create(btn, TweenInfo.new(0.15), {BackgroundColor3 = c}):Play()
    end)
    
    btn.MouseButton1Click:Connect(function()
        active = not active
        if active then
            TweenService:Create(btn, TweenInfo.new(0.2), {BackgroundColor3 = COLORS.BLUE_LIGHT}):Play()
            dot.BackgroundColor3 = COLORS.GREEN
            btn.Text = text .. " ● ON"
        else
            local c = isBlue and COLORS.BLUE_DARK or COLORS.BLUE
            TweenService:Create(btn, TweenInfo.new(0.2), {BackgroundColor3 = c}):Play()
            dot.BackgroundColor3 = COLORS.RED
            btn.Text = text .. " ● OFF"
        end
        callback(active)
    end)
    
    return btn
end

local function makeToggle(parent, text, callback)
    local row = Instance.new("Frame", parent)
    row.Size = UDim2.new(1, -10, 0, isMobile and 42 or 44)
    row.BackgroundColor3 = COLORS.CARD
    row.BackgroundTransparency = 0.4
    Instance.new("UICorner", row).CornerRadius = UDim.new(0, 10)
    
    local stroke = Instance.new("UIStroke", row)
    stroke.Color = COLORS.BLUE
    stroke.Thickness = 1
    stroke.Transparency = 0.6
    
    local label = Instance.new("TextLabel", row)
    label.Size = UDim2.new(1, -80, 1, 0)
    label.Position = UDim2.new(0, 15, 0, 0)
    label.BackgroundTransparency = 1
    label.Text = text
    label.TextColor3 = COLORS.TEXT
    label.Font = Enum.Font.GothamBold
    label.TextSize = isMobile and 13 or 14
    label.TextXAlignment = Enum.TextXAlignment.Left
    
    local bg = Instance.new("Frame", row)
    bg.Size = UDim2.new(0, 48, 0, 24)
    bg.Position = UDim2.new(1, -60, 0.5, -12)
    bg.BackgroundColor3 = COLORS.CARD
    bg.BorderSizePixel = 0
    Instance.new("UICorner", bg).CornerRadius = UDim.new(1, 0)
    
    local circle = Instance.new("Frame", bg)
    circle.Size = UDim2.new(0, 20, 0, 20)
    circle.Position = UDim2.new(0, 3, 0.5, -10)
    circle.BackgroundColor3 = COLORS.TEXT
    circle.BorderSizePixel = 0
    Instance.new("UICorner", circle).CornerRadius = UDim.new(1, 0)
    
    local active = false
    
    local btn = Instance.new("TextButton", row)
    btn.Size = UDim2.new(1, 0, 1, 0)
    btn.BackgroundTransparency = 1
    btn.Text = ""
    
    btn.MouseButton1Click:Connect(function()
        active = not active
        TweenService:Create(bg, TweenInfo.new(0.2), {BackgroundColor3 = active and COLORS.BLUE or COLORS.CARD}):Play()
        TweenService:Create(circle, TweenInfo.new(0.2, Enum.EasingStyle.Back), {Position = active and UDim2.new(1, -23, 0.5, -10) or UDim2.new(0, 3, 0.5, -10)}):Play()
        callback(active)
    end)
    
    return row
end

local function makeSlider(parent, labelText, minVal, maxVal, defaultValue, callback)
    local container = Instance.new("Frame", parent)
    container.Size = UDim2.new(1, -10, 0, isMobile and 60 or 65)
    container.BackgroundColor3 = COLORS.CARD
    container.BackgroundTransparency = 0.4
    Instance.new("UICorner", container).CornerRadius = UDim.new(0, 10)
    
    local stroke = Instance.new("UIStroke", container)
    stroke.Color = COLORS.BLUE
    stroke.Thickness = 1
    stroke.Transparency = 0.6
    
    local label = Instance.new("TextLabel", container)
    label.Size = UDim2.new(0.6, 0, 0, 24)
    label.Position = UDim2.new(0, 15, 0, 5)
    label.BackgroundTransparency = 1
    label.Text = labelText .. defaultValue
    label.TextColor3 = COLORS.TEXT
    label.Font = Enum.Font.GothamBold
    label.TextSize = isMobile and 12 or 13
    label.TextXAlignment = Enum.TextXAlignment.Left
    
    local box = Instance.new("TextBox", container)
    box.Size = UDim2.new(0, 60, 0, 26)
    box.Position = UDim2.new(1, -75, 0, 4)
    box.BackgroundColor3 = COLORS.CARD
    box.Text = tostring(defaultValue)
    box.TextColor3 = COLORS.TEXT
    box.Font = Enum.Font.GothamBold
    box.TextSize = 13
    box.TextXAlignment = Enum.TextXAlignment.Center
    Instance.new("UICorner", box).CornerRadius = UDim.new(0, 6)
    
    local sliderBg = Instance.new("Frame", container)
    sliderBg.Size = UDim2.new(1, -30, 0, 8)
    sliderBg.Position = UDim2.new(0, 15, 0, 42)
    sliderBg.BackgroundColor3 = Color3.fromRGB(18, 20, 26)
    sliderBg.BorderSizePixel = 0
    Instance.new("UICorner", sliderBg).CornerRadius = UDim.new(1, 0)
    
    local fill = Instance.new("Frame", sliderBg)
    fill.Size = UDim2.new((defaultValue - minVal) / (maxVal - minVal), 0, 1, 0)
    fill.BackgroundColor3 = COLORS.BLUE
    fill.BorderSizePixel = 0
    Instance.new("UICorner", fill).CornerRadius = UDim.new(1, 0)
    
    local knob = Instance.new("Frame", fill)
    knob.Size = UDim2.new(0, 16, 0, 16)
    knob.Position = UDim2.new(1, -8, 0.5, -8)
    knob.BackgroundColor3 = COLORS.TEXT
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
            local rel = input.Position.X - sliderBg.AbsolutePosition.X
            local pct = math.clamp(rel / sliderBg.AbsoluteSize.X, 0, 1)
            local val = math.floor(minVal + pct * (maxVal - minVal))
            fill.Size = UDim2.new(pct, 0, 1, 0)
            label.Text = labelText .. val
            box.Text = tostring(val)
            callback(val)
        end
    end
    
    UserInputService.InputChanged:Connect(updateSlider)
    
    box.FocusLost:Connect(function()
        local n = tonumber(box.Text)
        if n then
            n = math.clamp(n, minVal, maxVal)
            local pct = (n - minVal) / (maxVal - minVal)
            fill.Size = UDim2.new(pct, 0, 1, 0)
            label.Text = labelText .. n
            box.Text = tostring(n)
            callback(n)
        else
            box.Text = tostring(defaultValue)
        end
    end)
    
    return container
end

-- ============================================
-- BUILD UI
-- ============================================
makeSection("RAGDOLL RECOVERY")

makeToggle(container, "AUTO TP LEFT", function(on)
    _G.XENTHUB.tpLeft = on
    if on then _G.XENTHUB.tpRight = false end
end)

makeToggle(container, "AUTO TP RIGHT", function(on)
    _G.XENTHUB.tpRight = on
    if on then _G.XENTHUB.tpLeft = false end
end)

makeSection("AUTO DUEL")

makeButton(container, "AUTO LEFT", true, function(on)
    _G.XENTHUB.duelLeft = on
    if on then
        _G.XENTHUB.duelRight = false
        stopRight()
        startLeft()
    else
        stopLeft()
    end
end)

makeButton(container, "AUTO RIGHT", false, function(on)
    _G.XENTHUB.duelRight = on
    if on then
        _G.XENTHUB.duelLeft = false
        stopLeft()
        startRight()
    else
        stopRight()
    end
end)

makeSlider(container, "WALK SPEED: ", 20, 100, _G.XENTHUB.walkSpeed, function(v)
    _G.XENTHUB.walkSpeed = v
end)

makeSlider(container, "STEAL SPEED: ", 10, 80, _G.XENTHUB.stealSpeed, function(v)
    _G.XENTHUB.stealSpeed = v
end)

makeSection("AUTO STEAL")

makeButton(container, "AUTO STEAL", false, function(on)
    _G.XENTHUB.autoSteal = on
end)

makeSlider(container, "STEAL RADIUS: ", 1, 20, _G.XENTHUB.stealRadius, function(v)
    _G.XENTHUB.stealRadius = v
end)

makeSection("UTILITIES")

makeButton(container, "ANTI RAGDOLL", true, function(on)
    _G.XENTHUB.antiRag = on
end)

makeButton(container, "FLOAT NEAREST", false, function(on)
    _G.XENTHUB.floatEnabled = on
    if on then startFloatLoop() end
end)

makeButton(container, "INFINITE JUMP", true, function(on)
    _G.XENTHUB.infJump = on
end)

-- ============================================
-- WINDOW CONTROLS
-- ============================================
local minimized = false
local fullSize = guiSize
local miniSize = UDim2.new(0, guiSize.X.Offset, 0, 50)

miniBtn.MouseButton1Click:Connect(function()
    minimized = not minimized
    if minimized then
        TweenService:Create(mainFrame, TweenInfo.new(0.25), {Size = miniSize, Position = UDim2.new(0.5, -miniSize.X.Offset/2, 0.5, -25)}):Play()
        scroll.Visible = false
        miniBtn.Text = "□"
    else
        TweenService:Create(mainFrame, TweenInfo.new(0.25), {Size = fullSize, Position = UDim2.new(0.5, -fullSize.X.Offset/2, 0.5, -fullSize.Y.Offset/2)}):Play()
        scroll.Visible = true
        miniBtn.Text = "−"
        task.wait(0.3)
        updateCanvas()
    end
end)

closeBtn.MouseButton1Click:Connect(function()
    screenGui:Destroy()
end)

-- Initial canvas update
task.wait(0.3)
updateCanvas()

-- ============================================
-- CLEANUP
-- ============================================
screenGui.Destroying:Connect(function()
    if leftConn then leftConn:Disconnect() end
    if rightConn then rightConn:Disconnect() end
    if stealLoop then stealLoop:Disconnect() end
    if antiConn then antiConn:Disconnect() end
    if floatLoop then floatLoop:Disconnect() end
end)

-- Character respawn handler
LocalPlayer.CharacterAdded:Connect(function()
    if _G.XENTHUB.antiRag then end
    if _G.XENTHUB.floatEnabled then startFloatLoop() end
    _G.XENTHUB.tpLeft = false
    _G.XENTHUB.tpRight = false
    _G.XENTHUB.autoSteal = false
end)

-- Copy discord invite
pcall(function()
    if setclipboard then setclipboard("https://discord.gg/xenthub") end
end)

print("XENTHUB DUELS FULLY LOADED - Everything works!")