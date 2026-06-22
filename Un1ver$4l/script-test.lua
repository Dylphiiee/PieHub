-- PieHub V3 by Dylphiiee
local WindUI = loadstring(game:HttpGet("https://github.com/Footagesus/WindUI/releases/latest/download/main.lua"))()

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")
local UserInputService = game:GetService("UserInputService")
local VirtualUser = game:GetService("VirtualUser")
local Debris = game:GetService("Debris")
local CoreGui = game:GetService("CoreGui")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

local Config = {
    AimbotEnabled = false,
    AimbotActive = false,
    DraggableUI = false,
    FovRadius = 100,
    Smoothing = 1,
    Prediction = false,
    PredAmount = 0.1,
    KillAura = false,
    KillAuraRange = 10,
    AntiAim = false,
    AntiKnockback = false,
    AntiStun = false,
}

WindUI:SetNotificationLower(true)

local Window = WindUI:CreateWindow({
    Title = "PieHub",
    Icon = "cookie",
    Author = "by Dylphiiee",
    Folder = "PieHub",
    Size = UDim2.fromOffset(580, 460),
    ToggleKey = Enum.KeyCode.RightShift,
    Theme = "Dark",
    Resizable = false,
})

WindUI:Notify({
    Title = "PieHub V3",
    Content = "Loaded!",
    Duration = 4,
    Icon = "cookie",
})

Window:Tag({ Title = "Dylphiiee", Icon = "user", Color = Color3.fromHex("#a78bfa"), Radius = 12 })
Window:Tag({ Title = "V3.0.0", Icon = "rocket", Color = Color3.fromHex("#30ff6a"), Radius = 12 })

local function getChar() return LocalPlayer.Character end
local function getHum()
    local c = getChar()
    return c and c:FindFirstChildWhichIsA("Humanoid")
end
local function getHRP()
    local c = getChar()
    return c and c:FindFirstChild("HumanoidRootPart")
end

-- ===================== HIDE UI FROM SCREEN RECORDING =====================
-- Uses the executor's "protectgui" function when available so PieHub's UI does not
-- appear in Roblox's built-in screen recording / screenshot capture. Silently does
-- nothing if the executor doesn't support it (no error, UI just stays normal).
local function hideFromRecording(gui)
    pcall(function()
        if protectgui then
            protectgui(gui)
        elseif syn and syn.protect_gui then
            syn.protect_gui(gui)
        elseif gethui then
            -- Parenting under gethui() keeps the gui out of CoreGui capture on some executors
            gui.Parent = gethui()
        end
    end)
end

-- Moved up so forceJumpStateFix (used by Freecam/Cinematic/Emote systems below) can
-- safely reference these before the Jump Power UI section is created later in the file.
local jumpPowerEnabled = false
local jumpPowerValue = 50

-- Moved up (same reason as jumpPowerEnabled above): the "!re" command handler and other
-- early code reference these, and they must be true locals, not globals, or godmode
-- silently keeps reviving the character after Health is set to 0.
local godmodeConn = nil
local godmodeEnabled = false

-- ===================== JUMP STATE FIXER =====================
local function forceJumpStateFix()
    local hum = getHum()
    if not hum then return end
    pcall(function()
        hum:SetStateEnabled(Enum.HumanoidStateType.Jumping, true)
        hum:SetStateEnabled(Enum.HumanoidStateType.Freefall, true)
        hum:SetStateEnabled(Enum.HumanoidStateType.Landed, true)
        hum:SetStateEnabled(Enum.HumanoidStateType.Running, true)
        hum:SetStateEnabled(Enum.HumanoidStateType.RunningNoPhysics, true)
        hum:SetStateEnabled(Enum.HumanoidStateType.GettingUp, true)
        hum:SetStateEnabled(Enum.HumanoidStateType.PlatformStand, true)
    end)
    if hum.PlatformStand then hum.PlatformStand = false end
    if hum.UseJumpPower and hum.JumpPower <= 0 then hum.JumpPower = jumpPowerEnabled and jumpPowerValue or 50 end
end

-- ===================== AIMBOT BUTTON WITH FIXED DRAG SYSTEM =====================
local AimbotGui = Instance.new("ScreenGui")
AimbotGui.Name = "AimbotButtonUI"
AimbotGui.ResetOnSpawn = false
AimbotGui.Enabled = false

local pcallSuccess, _ = pcall(function() AimbotGui.Parent = CoreGui end)
if not pcallSuccess then AimbotGui.Parent = LocalPlayer:WaitForChild("PlayerGui") end
hideFromRecording(AimbotGui)

local AimbotButton = Instance.new("TextButton", AimbotGui)
AimbotButton.Size = UDim2.new(0, 45, 0, 45)
AimbotButton.Position = UDim2.new(0.5, -22.5, 0.1, 0)
AimbotButton.BackgroundColor3 = Color3.fromRGB(255, 50, 50)
AimbotButton.Text = ""
AimbotButton.AutoButtonColor = false
AimbotButton.BorderSizePixel = 0
AimbotButton.Active = true

local UICorner = Instance.new("UICorner", AimbotButton)
UICorner.CornerRadius = UDim.new(0, 10)

local Icon = Instance.new("ImageLabel", AimbotButton)
Icon.Size = UDim2.new(0.6, 0, 0.6, 0)
Icon.Position = UDim2.new(0.2, 0, 0.2, 0)
Icon.BackgroundTransparency = 1
Icon.Image = "rbxassetid://6031280882"
Icon.ImageColor3 = Color3.fromRGB(255, 255, 255)

local function UpdateAimbotColor()
    if Config.AimbotActive then
        AimbotButton.BackgroundColor3 = Color3.fromRGB(50, 255, 50)
    else
        AimbotButton.BackgroundColor3 = Color3.fromRGB(255, 50, 50)
    end
end

local aimbotDragging = false
local aimbotDragStart = nil
local aimbotStartPos = nil

AimbotButton.MouseButton1Down:Connect(function()
    aimbotDragging = true
    aimbotDragStart = UserInputService:GetMouseLocation()
    aimbotStartPos = AimbotButton.Position
end)

AimbotButton.MouseButton1Up:Connect(function()
    if aimbotDragging then
        local currentPos = UserInputService:GetMouseLocation()
        local delta = (currentPos - aimbotDragStart).Magnitude
        aimbotDragging = false
        
        if delta < 5 then
            Config.AimbotActive = not Config.AimbotActive
            UpdateAimbotColor()
        end
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if aimbotDragging and input.UserInputType == Enum.UserInputType.MouseMovement and Config.DraggableUI then
        local currentPos = UserInputService:GetMouseLocation()
        local delta = currentPos - aimbotDragStart
        AimbotButton.Position = UDim2.new(aimbotStartPos.X.Scale, aimbotStartPos.X.Offset + delta.X, aimbotStartPos.Y.Scale, aimbotStartPos.Y.Offset + delta.Y)
    end
end)

-- ===================== SHIFTLOCK BUTTON WITH FIXED DRAG SYSTEM =====================
local ShiftlockGui = Instance.new("ScreenGui")
ShiftlockGui.Name = "ShiftlockButtonUI"
ShiftlockGui.ResetOnSpawn = false
ShiftlockGui.Enabled = false

local slGuiOk, _ = pcall(function() ShiftlockGui.Parent = CoreGui end)
if not slGuiOk then ShiftlockGui.Parent = LocalPlayer:WaitForChild("PlayerGui") end
hideFromRecording(ShiftlockGui)

local ShiftlockButton = Instance.new("TextButton", ShiftlockGui)
ShiftlockButton.Size = UDim2.new(0, 45, 0, 45)
ShiftlockButton.Position = UDim2.new(0.5, 35, 0.1, 0)
ShiftlockButton.BackgroundColor3 = Color3.fromRGB(255, 50, 50)
ShiftlockButton.Text = ""
ShiftlockButton.AutoButtonColor = false
ShiftlockButton.BorderSizePixel = 0
ShiftlockButton.Active = true

local SLCorner = Instance.new("UICorner", ShiftlockButton)
SLCorner.CornerRadius = UDim.new(0, 10)

local SLIcon = Instance.new("ImageLabel", ShiftlockButton)
SLIcon.Size = UDim2.new(0.6, 0, 0.6, 0)
SLIcon.Position = UDim2.new(0.2, 0, 0.2, 0)
SLIcon.BackgroundTransparency = 1
SLIcon.Image = "rbxassetid://6035341598"
SLIcon.ImageColor3 = Color3.fromRGB(255, 255, 255)

local shiftlockEnabled = false

local function UpdateShiftlockColor()
    if shiftlockEnabled then
        ShiftlockButton.BackgroundColor3 = Color3.fromRGB(50, 255, 50)
    else
        ShiftlockButton.BackgroundColor3 = Color3.fromRGB(255, 50, 50)
    end
end

local slDragging = false
local slDragStart = nil
local slStartPos = nil

ShiftlockButton.MouseButton1Down:Connect(function()
    slDragging = true
    slDragStart = UserInputService:GetMouseLocation()
    slStartPos = ShiftlockButton.Position
end)

ShiftlockButton.MouseButton1Up:Connect(function()
    if slDragging then
        local currentPos = UserInputService:GetMouseLocation()
        local delta = (currentPos - slDragStart).Magnitude
        slDragging = false
        
        if delta < 5 then
            shiftlockEnabled = not shiftlockEnabled
            UpdateShiftlockColor()
            
            local hum = getHum()
            if hum then
                if shiftlockEnabled then
                    hum:SetStateEnabled(Enum.HumanoidStateType.Climbing, false)
                    if UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2) then
                        hum:ChangeState(Enum.HumanoidStateType.Running)
                    end
                else
                    hum:SetStateEnabled(Enum.HumanoidStateType.Climbing, true)
                end
            end
        end
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if slDragging and input.UserInputType == Enum.UserInputType.MouseMovement and Config.DraggableUI then
        local currentPos = UserInputService:GetMouseLocation()
        local delta = currentPos - slDragStart
        ShiftlockButton.Position = UDim2.new(slStartPos.X.Scale, slStartPos.X.Offset + delta.X, slStartPos.Y.Scale, slStartPos.Y.Offset + delta.Y)
    end
end)

-- Maintain shiftlock behavior
RunService.RenderStepped:Connect(function()
    if shiftlockEnabled then
        local hum = getHum()
        if hum then
            hum:SetStateEnabled(Enum.HumanoidStateType.Climbing, false)
        end
    end
end)

-- ===================== FREECAM LOCK BUTTON WITH FIXED DRAG SYSTEM =====================
local FreecamLockGui = Instance.new("ScreenGui")
FreecamLockGui.Name = "FreecamLockButtonUI"
FreecamLockGui.ResetOnSpawn = false
FreecamLockGui.Enabled = false

local flGuiOk, _ = pcall(function() FreecamLockGui.Parent = CoreGui end)
if not flGuiOk then FreecamLockGui.Parent = LocalPlayer:WaitForChild("PlayerGui") end
hideFromRecording(FreecamLockGui)

local FreecamLockButton = Instance.new("TextButton", FreecamLockGui)
FreecamLockButton.Size = UDim2.new(0, 45, 0, 45)
FreecamLockButton.Position = UDim2.new(0.5, 92.5, 0.1, 0)
FreecamLockButton.BackgroundColor3 = Color3.fromRGB(255, 50, 50)
FreecamLockButton.Text = ""
FreecamLockButton.AutoButtonColor = false
FreecamLockButton.BorderSizePixel = 0
FreecamLockButton.Active = true

local FLCorner = Instance.new("UICorner", FreecamLockButton)
FLCorner.CornerRadius = UDim.new(0, 10)

local FLIcon = Instance.new("ImageLabel", FreecamLockButton)
FLIcon.Size = UDim2.new(0.6, 0, 0.6, 0)
FLIcon.Position = UDim2.new(0.2, 0, 0.2, 0)
FLIcon.BackgroundTransparency = 1
FLIcon.Image = "rbxassetid://6034509720"
FLIcon.ImageColor3 = Color3.fromRGB(255, 255, 255)

local freecamCameraLocked = false

local function UpdateFreecamLockColor()
    if freecamCameraLocked then
        FreecamLockButton.BackgroundColor3 = Color3.fromRGB(50, 255, 50)
    else
        FreecamLockButton.BackgroundColor3 = Color3.fromRGB(255, 50, 50)
    end
end

local flDragging = false
local flDragStart = nil
local flStartPos = nil

FreecamLockButton.MouseButton1Down:Connect(function()
    flDragging = true
    flDragStart = UserInputService:GetMouseLocation()
    flStartPos = FreecamLockButton.Position
end)

FreecamLockButton.MouseButton1Up:Connect(function()
    if flDragging then
        local currentPos = UserInputService:GetMouseLocation()
        local delta = (currentPos - flDragStart).Magnitude
        flDragging = false
        
        if delta < 5 then
            freecamCameraLocked = not freecamCameraLocked
            UpdateFreecamLockColor()
        end
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if flDragging and input.UserInputType == Enum.UserInputType.MouseMovement and Config.DraggableUI then
        local currentPos = UserInputService:GetMouseLocation()
        local delta = currentPos - flDragStart
        FreecamLockButton.Position = UDim2.new(flStartPos.X.Scale, flStartPos.X.Offset + delta.X, flStartPos.Y.Scale, flStartPos.Y.Offset + delta.Y)
    end
end)

-- RESPAWN / !re COMMAND WITH RESPAWN LOCATION
local lastDeathCFrame = nil

LocalPlayer.Chatted:Connect(function(msg)
    local lowerMsg = msg:lower()
    if lowerMsg == "!re" or lowerMsg == "/re" or lowerMsg == ";re" then
        local hrp = getHRP()
        if hrp then lastDeathCFrame = hrp.CFrame end

        local hum = getHum()
        if hum then
            local wasGodmode = godmodeEnabled
            -- Fully disable godmode (flag + heartbeat loop) so Health=0 below actually sticks.
            godmodeEnabled = false
            if godmodeConn then godmodeConn:Disconnect() godmodeConn = nil end
            hum.MaxHealth = 100
            hum.Health = 100
            task.wait(0.05)
            hum.Health = 0

            if wasGodmode then
                -- Re-enable godmode properly after respawn (recreates the heartbeat loop,
                -- not just the flag, so it doesn't end up silently broken).
                task.spawn(function()
                    task.wait(3)
                    local h2 = getHum()
                    godmodeEnabled = true
                    if h2 then h2.MaxHealth = math.huge h2.Health = math.huge end
                    if not godmodeConn then
                        godmodeConn = RunService.Heartbeat:Connect(function()
                            local h3 = getHum()
                            if h3 and godmodeEnabled then
                                if h3.Health < h3.MaxHealth then h3.Health = math.huge end
                            end
                        end)
                    end
                end)
            end

            -- Teleport ke lokasi kematian setelah respawn dan auto-activate infjump
            task.spawn(function()
                task.wait(1)
                local newHrp = getHRP()
                if newHrp and lastDeathCFrame then
                    newHrp.CFrame = lastDeathCFrame
                end
                
                -- Auto-activate infjump untuk mengatasin bug loncat setelah !re
                task.wait(0.5)
                infJumpEnabled = true
                startInfiniteJump()
                WindUI:Notify({ Title = "Infinite Jump", Content = "Auto-activated after respawn. Jump once to deactivate.", Duration = 2, Icon = "jump" })
            end)
        end

        -- Jump sometimes stays disabled after the respawn animation settles; force it back on.
        task.spawn(function()
            task.wait(2)
            forceJumpStateFix()
        end)
    end
end)

-- ===================== INFINITE JUMP SYSTEM =====================
local infJumpEnabled = false
local infJumpActive = false
local infJumpConnection = nil
local infJumpManualJump = false

local function startInfiniteJump()
    if infJumpConnection then infJumpConnection:Disconnect() end
    infJumpActive = true
    infJumpManualJump = false
    
    -- Handle Space key input untuk PC dan mobile
    infJumpConnection = UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed then return end
        
        if input.KeyCode == Enum.KeyCode.Space then
            infJumpManualJump = true
            local hum = getHum()
            if hum then
                hum:ChangeState(Enum.HumanoidStateType.Jumping)
            end
        end
    end)
    
    -- Handle TouchTap untuk mobile
    local touchJumpConnection = UserInputService.TouchTap:Connect(function()
        if infJumpActive and not infJumpManualJump then
            infJumpManualJump = true
            local hum = getHum()
            if hum then
                hum:ChangeState(Enum.HumanoidStateType.Jumping)
            end
        end
    end)
    
    -- Auto jump while user hasn't manually jumped
    local jumpLoop = RunService.Heartbeat:Connect(function()
        if not infJumpEnabled or not infJumpActive then
            jumpLoop:Disconnect()
            if touchJumpConnection then touchJumpConnection:Disconnect() end
            return
        end
        
        if infJumpManualJump then
            infJumpEnabled = false
            infJumpActive = false
            jumpLoop:Disconnect()
            if infJumpConnection then infJumpConnection:Disconnect() infJumpConnection = nil end
            if touchJumpConnection then touchJumpConnection:Disconnect() end
            WindUI:Notify({ Title = "Infinite Jump", Content = "Deactivated.", Duration = 1, Icon = "jump" })
            return
        end
        
        local hum = getHum()
        if hum then
            hum:ChangeState(Enum.HumanoidStateType.Jumping)
        end
    end)
end

local function stopInfiniteJump()
    infJumpEnabled = false
    infJumpActive = false
    if infJumpConnection then infJumpConnection:Disconnect() infJumpConnection = nil end
end

-- ANTI FLING SYSTEM
local antiFlingEnabled = false
local antiFlingData = {}
local antiFlingConn = nil
local antiFlingConn = nil
local antiFlingGhostConn = nil

local function restoreAntiFling()
    for part, data in pairs(antiFlingData) do
        if part and part.Parent then
            pcall(function()
                part.CanCollide = data.CanCollide
                part.Massless = data.Massless
            end)
        end
    end
    antiFlingData = {}
end

local function startAntiFling()
    if antiFlingConn then antiFlingConn:Disconnect() antiFlingConn = nil end
    antiFlingConn = RunService.Stepped:Connect(function()
        if not antiFlingEnabled then return end
        for _, player in pairs(Players:GetPlayers()) do
            if player ~= LocalPlayer and player.Character then
                for _, part in pairs(player.Character:GetDescendants()) do
                    if part:IsA("BasePart") then
                        if part.AssemblyLinearVelocity.Magnitude > 100 then
                            part.AssemblyLinearVelocity = Vector3.zero
                            part.AssemblyAngularVelocity = Vector3.zero
                        end
                        part.CanCollide = false
                        part.Massless = true
                    end
                end
            end
        end
    end)
end

local function charFromPart(part)
    local m = part and part.Parent
    if not m then return nil end
    if m:IsA("Accessory") then m = m.Parent end
    if m and m:FindFirstChildWhichIsA("Humanoid") then return m end
end

local function doNaNFling(targetPart)
    local char = getChar()
    local hrp = getHRP()
    local hum = getHum()
    if not char or not hrp or not hum then return end
    if not targetPart or not targetPart.Parent then return end
    local targetChar = charFromPart(targetPart)
    if targetChar then
        for _, p in pairs(targetChar:GetDescendants()) do
            if p:IsA("BasePart") then p.CanCollide = false end
        end
    end
    local origCF = hrp.CFrame
    hrp.CFrame = targetPart.CFrame
    pcall(function()
        sethiddenproperty(hum, "MoveDirectionInternal", Vector3.new(0/0, 0/0, 0/0))
        sethiddenproperty(hum, "NetworkHumanoidState", Enum.HumanoidStateType.Freefall)
    end)
    hrp.Velocity = Vector3.new(0/0, 0/0, 0/0)
    hrp.RotVelocity = Vector3.new(0/0, 0/0, 0/0)
    hrp.AssemblyLinearVelocity = Vector3.new(0/0, 0/0, 0/0)
    hrp.AssemblyAngularVelocity = Vector3.new(0/0, 0/0, 0/0)
    for _, p in pairs(char:GetDescendants()) do
        if p:IsA("BasePart") then
            p.Velocity = Vector3.new(0/0, 0/0, 0/0)
            p.RotVelocity = Vector3.new(0/0, 0/0, 0/0)
            p.AssemblyLinearVelocity = Vector3.new(0/0, 0/0, 0/0)
            p.AssemblyAngularVelocity = Vector3.new(0/0, 0/0, 0/0)
        end
    end
    hum:ChangeState(Enum.HumanoidStateType.Freefall)
    task.wait(0.1)
    pcall(function() hrp.CFrame = origCF end)
end

-- Airwalk System
local airWalkPlatform = Instance.new("Part")
airWalkPlatform.Name = "PieHub_AirWalk"
airWalkPlatform.Anchored = true
airWalkPlatform.Size = Vector3.new(6, 0.1, 6) 
airWalkPlatform.Transparency = 1
airWalkPlatform.CanCollide = false
airWalkPlatform.Parent = workspace

local airWalkHeight = 0

-- Combat System
local function isAlive(player)
    return player and player.Character and player.Character:FindFirstChild("Humanoid") and player.Character.Humanoid.Health > 0 and player.Character:FindFirstChild("HumanoidRootPart")
end

local function getClosestTarget()
    local target = nil
    local shortestDist = Config.FovRadius
    local center = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)

    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and isAlive(p) then
            if p.Team ~= LocalPlayer.Team or p.Team == nil then
                local hrp = p.Character.HumanoidRootPart
                local pos, onScreen = Camera:WorldToViewportPoint(hrp.Position)
                
                if onScreen then
                    local dist = (Vector2.new(pos.X, pos.Y) - center).Magnitude
                    if dist < shortestDist then
                        shortestDist = dist
                        target = hrp
                    end
                end
            end
        end
    end
    return target
end

RunService.RenderStepped:Connect(function()
    local char = LocalPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    local hum = char and char:FindFirstChildWhichIsA("Humanoid")

    if Config.AimbotActive then
        local target = getClosestTarget()
        if target then
            local aimPosition = target.Position
            if Config.Prediction then
                aimPosition = aimPosition + (target.Velocity * Config.PredAmount)
            end
            
            local targetCFrame = CFrame.new(Camera.CFrame.Position, aimPosition)
            if Config.Smoothing > 1 then
                Camera.CFrame = Camera.CFrame:Lerp(targetCFrame, 1 / Config.Smoothing)
            else
                Camera.CFrame = targetCFrame
            end
        end
    end

    if Config.AntiAim and hrp then
        hrp.CFrame = hrp.CFrame * CFrame.Angles(0, math.rad(50), 0)
    end

    if Config.AntiKnockback and char then
        if hum then
            hum:SetStateEnabled(Enum.HumanoidStateType.FallingDown, false)
            hum:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, false)
            hum:SetStateEnabled(Enum.HumanoidStateType.PlatformStand, false)
        end
        for _, v in pairs(char:GetDescendants()) do
            if v:IsA("BodyVelocity") or v:IsA("BodyPosition") or v:IsA("BodyForce") or v:IsA("BodyThrust") then
                v:Destroy()
            end
        end
    elseif hum then
        hum:SetStateEnabled(Enum.HumanoidStateType.FallingDown, true)
        hum:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, true)
    end

    if Config.AntiStun and hum then
        if hum.WalkSpeed < 16 then hum.WalkSpeed = 16 end
        if hum.JumpPower < 50 and hum.UseJumpPower then hum.JumpPower = 50 end
        if hum.PlatformStand then hum.PlatformStand = false end
    end
end)

RunService.Heartbeat:Connect(function()
    if Config.KillAura then
        local myChar = LocalPlayer.Character
        local myHRP = myChar and myChar:FindFirstChild("HumanoidRootPart")
        if not myHRP then return end
        
        local tool = myChar:FindFirstChildOfClass("Tool")
        
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= LocalPlayer and isAlive(p) and (p.Team ~= LocalPlayer.Team or p.Team == nil) then
                local targetHRP = p.Character.HumanoidRootPart
                local dist = (myHRP.Position - targetHRP.Position).Magnitude
                
                if dist <= Config.KillAuraRange then
                    pcall(function() VirtualUser:ClickButton1(Vector2.new(0,0)) end)
                    
                    if tool then
                        tool:Activate()
                        for _, part in pairs(tool:GetDescendants()) do
                            if part:IsA("BasePart") then
                                firetouchinterest(part, targetHRP, 0)
                                firetouchinterest(part, targetHRP, 1)
                            end
                        end
                    end
                end
            end
        end
    end
end)

-- Fling System
local PunchPower = 50
local PunchTime = 30
local punchActive = false
local saitamaActive = false
local kickActive = false
local punchTool = nil
local saitamaTool = nil
local kickTool = nil

local function getRightArm()
    local chr = getChar()
    if not chr then return nil end
    return chr:FindFirstChild("Right Arm") or chr:FindFirstChild("RightLowerArm")
end

local function getLeftLeg()
    local chr = getChar()
    if not chr then return nil end
    local r6 = chr:FindFirstChild("Left Leg")
    if r6 then return r6 end
    local r15 = chr:FindFirstChild("LeftFoot")
        or chr:FindFirstChild("LeftLowerLeg")
        or chr:FindFirstChild("LeftUpperLeg")
    if r15 then return r15 end
    return nil
end

local function removePunchTool()
    if punchTool and punchTool.Parent then punchTool:Destroy() punchTool = nil end
end

local function removeSaitamaTool()
    if saitamaTool and saitamaTool.Parent then saitamaTool:Destroy() saitamaTool = nil end
end

local function removeKickTool()
    if kickTool and kickTool.Parent then kickTool:Destroy() kickTool = nil end
end

local function createFlingTool(toolName, animId, limbGetFn, isR6AnimId, isR15AnimId, powerMult)
    local chr = getChar()
    local hum = getHum()
    if not chr or not hum then return nil end
    local rigType = hum.RigType
    local limb = limbGetFn()
    if not limb then return nil end

    local tool = Instance.new("Tool", LocalPlayer.Backpack)
    tool.RequiresHandle = false
    tool.Name = toolName
    tool.ToolTip = toolName

    local anim = Instance.new("Animation", tool)
    if animId then
        anim.AnimationId = "rbxassetid://" .. tostring(animId)
    elseif rigType == Enum.HumanoidRigType.R6 then
        anim.AnimationId = "rbxassetid://" .. tostring(isR6AnimId)
    else
        anim.AnimationId = "rbxassetid://" .. tostring(isR15AnimId)
    end

    local track = hum:LoadAnimation(anim)
    local acting = false
    local pm = powerMult or 1

    tool.Activated:Connect(function()
        if acting then return end
        acting = true
        track:Play()
        if not animId then
            if rigType == Enum.HumanoidRigType.R6 then
                task.wait(0.2)
                track:AdjustSpeed(3)
            else
                track.TimePosition = 1.65
                track.Looped = false
                track:AdjustSpeed(1.1)
            end
        else
            track:AdjustSpeed(1.2)
            task.wait(0.15)
        end

        local times = 0
        limb.CanCollide = true

        repeat
            RunService.Heartbeat:Wait()
            limb.CanCollide = true
            times = times + 1
            local root = getHRP()
            local movel = 0.1
            while not (chr and chr.Parent and root and root.Parent) do
                RunService.Heartbeat:Wait()
                root = getHRP()
            end
            for _, touchedPart in pairs(limb:GetTouchingParts()) do
                local touchedChar = touchedPart.Parent
                if touchedChar and touchedChar:FindFirstChildWhichIsA("Humanoid") then
                    local tp = Players:GetPlayerFromCharacter(touchedChar)
                    if tp and tp ~= LocalPlayer then
                        local tHRP = touchedChar:FindFirstChild("HumanoidRootPart")
                        if tHRP then doNaNFling(tHRP) end
                    end
                end
            end
            local vel = root.Velocity
            root.Velocity = vel * (PunchPower * pm) + Vector3.new(0, PunchPower * pm, 0)
            RunService.RenderStepped:Wait()
            if chr and chr.Parent and root and root.Parent then root.Velocity = vel end
            RunService.Stepped:Wait()
            if chr and chr.Parent and root and root.Parent then
                root.Velocity = vel + Vector3.new(0, movel, 0)
                movel = movel * -1
            end
        until times == PunchTime

        acting = false
    end)

    return tool
end

local function createPunchFling()
    removePunchTool()
    local chr = getChar() local hum = getHum()
    if not chr or not hum then return end
    local rigType = hum.RigType
    punchTool = createFlingTool("PiePunch", nil, getRightArm, 28156406, 10717116749, 1)
end

local function createSaitamaFling()
    removeSaitamaTool()
    local chr = getChar() local hum = getHum()
    if not chr or not hum then return end
    saitamaTool = createFlingTool("PieSaitama", 92870860509002, getRightArm, nil, nil, 2)
end

local function createKickFlingFixed()
    removeKickTool()
    local chr = getChar()
    local hum = getHum()
    if not chr or not hum then return end

    local limb = getLeftLeg()
    if not limb then
        WindUI:Notify({ Title = "Error", Content = "Kaki tidak ditemukan!", Duration = 2, Icon = "alert-circle" })
        return
    end

    local tool = Instance.new("Tool", LocalPlayer.Backpack)
    tool.RequiresHandle = false
    tool.Name = "PieKick"
    tool.ToolTip = "Drop Kick Fling"
    kickTool = tool

    local anim = Instance.new("Animation", tool)
    anim.AnimationId = "rbxassetid://133566007754001"

    local track = hum:LoadAnimation(anim)
    local acting = false

    tool.Activated:Connect(function()
        if acting then return end
        acting = true

        track:Play()
        track:AdjustSpeed(1.2)
        task.wait(0.15)

        local legParts = {}
        for _, name in ipairs({"Left Leg","LeftFoot","LeftLowerLeg","LeftUpperLeg"}) do
            local p = chr:FindFirstChild(name)
            if p then
                table.insert(legParts, p)
                p.CanCollide = true
            end
        end

        local times = 0
        local animate = chr:FindFirstChild("Animate")

        repeat
            RunService.Heartbeat:Wait()
            times = times + 1

            for _, p in pairs(legParts) do
                pcall(function() p.CanCollide = true end)
            end

            local root = getHRP()
            if not root then break end

            for _, legPart in pairs(legParts) do
                local ok, touched = pcall(function() return legPart:GetTouchingParts() end)
                if not ok then continue end
                for _, touchedPart in pairs(touched) do
                    local touchedChar = touchedPart.Parent
                    if touchedChar and touchedChar:FindFirstChildWhichIsA("Humanoid") then
                        local tp = Players:GetPlayerFromCharacter(touchedChar)
                        if tp and tp ~= LocalPlayer then
                            local tHRP = touchedChar:FindFirstChild("HumanoidRootPart")
                            if tHRP then doNaNFling(tHRP) end
                        end
                    end
                end
            end

            local vel = root.Velocity
            root.Velocity = vel * (PunchPower * 1.5) + Vector3.new(0, PunchPower * 1.5, 0)

            RunService.RenderStepped:Wait()
            if chr and chr.Parent and root and root.Parent then
                root.Velocity = vel
            end

            RunService.Stepped:Wait()
            if chr and chr.Parent and root and root.Parent then
                local movel = times % 2 == 0 and 0.1 or -0.1
                root.Velocity = vel + Vector3.new(0, movel, 0)
            end
        until times == PunchTime

        pcall(function() track:Stop(0.3) end)
        for _, p in pairs(legParts) do
            pcall(function() p.CanCollide = false end)
        end

        if animate then
            animate.Disabled = true
            task.wait(0.05)
            animate.Disabled = false
        end

        local h = getHum()
        if h then
            local spd = h.WalkSpeed
            h.WalkSpeed = 0
            task.wait(0.05)
            h.WalkSpeed = spd
        end

        acting = false
    end)
end

-- TAB: ABOUT
local TabAbout = Window:Tab({ Title = "About", Icon = "info" })

TabAbout:Image({ Image = "rbxassetid://84187035258606", AspectRatio = "16:9", Radius = 12 })

local SectionInfoAbout = TabAbout:Section({ Title = "About", Icon = "info", Opened = true })
SectionInfoAbout:Paragraph({ Title = "PieHub", Desc = "Version: 2.0.0\nBuild: Stable", Icon = "cookie" })
SectionInfoAbout:Paragraph({ Title = "Creator", Desc = "©Copyright by Dylphiiee 2026", Icon = "user" })

local SectionInfoContact = TabAbout:Section({ Title = "Contact", Icon = "phone", Opened = true })
SectionInfoContact:Button({
    Title = "Discord", Desc = "Join our Discord server", Icon = "message-circle", Color = Color3.fromHex("#5865F2"),
    Callback = function()
        setclipboard("https://discord.gg/8cGVn25HZf")
        WindUI:Notify({ Title = "Discord", Content = "Link Discord disalin!", Duration = 3, Icon = "message-circle" })
    end
})
SectionInfoContact:Button({
    Title = "WhatsApp", Desc = "Join our WhatsApp channel", Icon = "phone", Color = Color3.fromHex("#25D366"),
    Callback = function()
        setclipboard("https://whatsapp.com/channel/0029VbCWGkW30LKTpeSIoW28")
        WindUI:Notify({ Title = "WhatsApp", Content = "Link WhatsApp disalin!", Duration = 3, Icon = "phone" })
    end
})

-- TAB: PLAYER
local TabPlayer = Window:Tab({ Title = "Player", Icon = "user" })

local flyEnabled = false
local flySpeed = 10
local airWalkConn = nil
local noClipConn = nil
local infJumpConn = nil
local invisV1Conn = nil
local invisV2Conn = nil
local invisV1Parts = {}
local invisV2Parts = {}
local flyToggle

local bunnyhopEnabled = false
local bunnyhopIsJumping = false
local RUN_SPEED_THRESHOLD = 16

local function startBunnyhopLoop()
    task.spawn(function()
        while bunnyhopEnabled do
            task.wait(0.1)
            local char = LocalPlayer.Character
            if not char then continue end
            local hum = char:FindFirstChild("Humanoid")
            if not hum then continue end
            local rootPart = char:FindFirstChild("HumanoidRootPart")
            if not rootPart then continue end
            local velocity = rootPart.Velocity
            local speed = (velocity.X^2 + velocity.Z^2)^0.5
            if speed > RUN_SPEED_THRESHOLD and not bunnyhopIsJumping then
                if hum.FloorMaterial ~= Enum.Material.Air then
                    bunnyhopIsJumping = true
                    hum:ChangeState(Enum.HumanoidStateType.Jumping)
                    task.wait(0.2)
                    bunnyhopIsJumping = false
                end
            end
        end
    end)
end

local SectionMovement = TabPlayer:Section({ Title = "Movement", Icon = "footprints", Opened = true })

SectionMovement:Toggle({
    Title = "Air Walk", 
    Desc = "Walk on air", 
    Icon = "footprints", 
    Value = false,
    Callback = function(state)
        local hrp = getHRP()
        if not hrp then return end

        if state then
            airWalkHeight = hrp.Position.Y - 3.2
            airWalkPlatform.CanCollide = true
            
            airWalkConn = RunService.Stepped:Connect(function()
                local currentHRP = getHRP()
                if currentHRP and state then
                    airWalkPlatform.Position = Vector3.new(currentHRP.Position.X, airWalkHeight, currentHRP.Position.Z)
                    airWalkPlatform.CanCollide = true
                else
                    if airWalkConn then airWalkConn:Disconnect() end
                end
            end)
        else
            if airWalkConn then airWalkConn:Disconnect() airWalkConn = nil end
            airWalkPlatform.CanCollide = false
            airWalkPlatform.Position = Vector3.new(0, -1000, 0)
        end
    end
})

SectionMovement:Toggle({
    Title = "Infinite Jump", Desc = "Jump infinitely", Icon = "chevrons-up", Value = false,
    Callback = function(state)
        if state then
            infJumpConn = UserInputService.JumpRequest:Connect(function()
                local hum = getHum()
                if hum then hum:ChangeState(Enum.HumanoidStateType.Jumping) end
            end)
        else
            if infJumpConn then infJumpConn:Disconnect() infJumpConn = nil end
        end
    end
})

SectionMovement:Toggle({
    Title = "No Clip", 
    Desc = "Walk through wall", 
    Icon = "layers", 
    Value = false,
    Callback = function(state)
        _G.noclip = state 
        
        if state then
            noClipConn = RunService.Stepped:Connect(function()
                if _G.noclip then
                    local chr = getChar()
                    if chr then
                        for _, v in pairs(chr:GetDescendants()) do
                            if v:IsA("BasePart") and v.CanCollide then
                                v.CanCollide = false
                            end
                        end
                    end
                else
                    if noClipConn then 
                        noClipConn:Disconnect() 
                        noClipConn = nil 
                    end
                end
            end)
        else
            if noClipConn then 
                noClipConn:Disconnect() 
                noClipConn = nil 
            end
            
            local chr = getChar()
            if chr then
                for _, v in pairs(chr:GetDescendants()) do
                    if v:IsA("BasePart") then
                        v.CanCollide = true
                    end
                end
            end
        end
    end
})


SectionMovement:Divider()

flyToggle = SectionMovement:Toggle({
    Title = "Fly", Desc = "Fly following camera direction", Icon = "plane", Value = false,
    Callback = function(state)
        flyEnabled = state
        local chr = getChar()
        local hum = getHum()
        if not chr or not hum then return end
        if not flyEnabled then
            for _, st in ipairs(Enum.HumanoidStateType:GetEnumItems()) do
                pcall(function() hum:SetStateEnabled(st, true) end)
            end
            hum:ChangeState(Enum.HumanoidStateType.RunningNoPhysics)
            if chr:FindFirstChild("Animate") then chr.Animate.Disabled = false end
            hum.PlatformStand = false
            local cam = workspace.CurrentCamera
            if cam then cam.CameraType = Enum.CameraType.Custom end
        else
            for _, st in ipairs(Enum.HumanoidStateType:GetEnumItems()) do
                pcall(function() hum:SetStateEnabled(st, false) end)
            end
            hum:ChangeState(Enum.HumanoidStateType.Freefall)
            if chr:FindFirstChild("Animate") then chr.Animate.Disabled = true end
            for _, t in ipairs(hum:GetPlayingAnimationTracks()) do t:AdjustSpeed(0) end
            local isR6 = hum.RigType == Enum.HumanoidRigType.R6
            local torso = isR6 and chr:FindFirstChild("Torso") or chr:FindFirstChild("UpperTorso")
            if not torso then return end
            hum.PlatformStand = true
            local bg = Instance.new("BodyGyro", torso)
            bg.P = 9e4 bg.MaxTorque = Vector3.new(9e9,9e9,9e9) bg.CFrame = torso.CFrame
            local bv = Instance.new("BodyVelocity", torso)
            bv.Velocity = Vector3.new(0,0.1,0) bv.MaxForce = Vector3.new(9e9,9e9,9e9)
            task.spawn(function()
                while flyEnabled do
                    RunService.RenderStepped:Wait()
                    local h2 = getHum()
                    if not h2 then break end
                    local camCF = workspace.CurrentCamera.CFrame
                    local lookVec = camCF.LookVector
                    local rightVec = camCF.RightVector
                    local md = h2.MoveDirection
                    local moveDir = Vector3.zero
                    if md.Magnitude > 0 then
                        local flatMD = Vector3.new(md.X,0,md.Z)
                        if flatMD.Magnitude > 0 then flatMD = flatMD.Unit end
                        local camFlat = Vector3.new(lookVec.X,0,lookVec.Z)
                        if camFlat.Magnitude > 0 then camFlat = camFlat.Unit end
                        local camRight = Vector3.new(rightVec.X,0,rightVec.Z)
                        if camRight.Magnitude > 0 then camRight = camRight.Unit end
                        moveDir = moveDir + lookVec * flatMD:Dot(camFlat)
                        moveDir = moveDir + camRight * flatMD:Dot(camRight)
                    end
                    if moveDir.Magnitude > 0 then moveDir = moveDir.Unit end
                    bv.Velocity = moveDir * flySpeed
                    bg.CFrame = camCF
                end
                bg:Destroy() bv:Destroy()
                local h3 = getHum() local c3 = getChar()
                if h3 then
                    h3.PlatformStand = false
                    for _, st in ipairs(Enum.HumanoidStateType:GetEnumItems()) do
                        pcall(function() h3:SetStateEnabled(st, true) end)
                    end
                end
                if c3 and c3:FindFirstChild("Animate") then c3.Animate.Disabled = false end
                local cam = workspace.CurrentCamera
                if cam then cam.CameraType = Enum.CameraType.Custom end
            end)
        end
    end
})

SectionMovement:Slider({
    Title = "Fly Speed", Desc = "Flight Speed | Default: 20", Icon = "wind",
    Step = 1, Value = { Min = 1, Max = 200, Default = 20 }, IsTooltip = true, IsTextbox = true,
    Callback = function(v) flySpeed = v end
})

SectionMovement:Divider()

SectionMovement:Toggle({
    Title = "Bunny Hop", Desc = "Auto jump while running", Icon = "rabbit", Value = false,
    Callback = function(state)
        bunnyhopEnabled = state bunnyhopIsJumping = false
        if state then startBunnyhopLoop() end
    end
})

SectionMovement:Slider({
    Title = "BunnyHop Trigger", Desc = "Minimum Trigger speed for BunnyHop | Default: 16", Icon = "gauge",
    Step = 1, Value = { Min = 1, Max = 100, Default = 16 }, IsTooltip = true, IsTextbox = true,
    Callback = function(v) RUN_SPEED_THRESHOLD = v end
})

SectionMovement:Divider()

-- jumpPowerEnabled / jumpPowerValue moved near top of file (see forceJumpStateFix section)

SectionMovement:Toggle({
    Title = "Jump Power", Desc = "Custom jump height", Icon = "arrow-up", Value = false,
    Callback = function(state)
        jumpPowerEnabled = state
        local hum = getHum()
        if hum then hum.JumpPower = state and jumpPowerValue or 50 end
    end
})

SectionMovement:Slider({
    Title = "Jump Power", Desc = "Set Jump power value | Default: 50", Icon = "arrow-up-circle",
    Step = 1, Value = { Min = 1, Max = 500, Default = 50 }, IsTooltip = true, IsTextbox = true,
    Callback = function(v)
        jumpPowerValue = v
        if jumpPowerEnabled then
            local hum = getHum()
            if hum then hum.JumpPower = v end
        end
    end
})

SectionMovement:Divider()

local walkSpeedEnabled = false
local walkSpeedValue = 16

SectionMovement:Toggle({
    Title = "Walk Speed", Desc = "Custom walk speed", Icon = "gauge", Value = false,
    Callback = function(state)
        walkSpeedEnabled = state
        local hum = getHum()
        if hum then hum.WalkSpeed = state and walkSpeedValue or 16 end
    end
})

SectionMovement:Slider({
    Title = "Walk Speed", Desc = "Set movement speed value | Default: 16", Icon = "gauge",
    Step = 1, Value = { Min = 1, Max = 500, Default = 16 }, IsTooltip = true, IsTextbox = true,
    Callback = function(v)
        walkSpeedValue = v
        if walkSpeedEnabled then
            local hum = getHum()
            if hum then hum.WalkSpeed = v end
        end
    end
})

SectionMovement:Divider()

SectionMovement:Toggle({
    Title = "Shiftlock", Desc = "Enable shiftlock mode (fixed button)", Icon = "square-check-big", Value = false,
    Callback = function(state)
        ShiftlockGui.Enabled = state
        if not state then
            shiftlockEnabled = false
            UpdateShiftlockColor()
            local hum = getHum()
            if hum then hum:SetStateEnabled(Enum.HumanoidStateType.Climbing, true) end
        end
    end
})

local SectionPlayer2 = TabPlayer:Section({ Title = "Player", Icon = "shield", Opened = true })

-- godmodeConn / godmodeEnabled are now declared near the top of the file (see forceJumpStateFix section)

SectionPlayer2:Toggle({
    Title = "Freeze", Desc = "Freeze character in place", Icon = "snowflake", Value = false,
    Callback = function(state)
        local hrp = getHRP()
        if hrp then hrp.Anchored = state end
    end
})

SectionPlayer2:Toggle({
    Title = "Godmode", Desc = "Character cannot die", Icon = "shield", Value = false,
    Callback = function(state)
        godmodeEnabled = state
        local hum = getHum()
        if hum then
            if state then hum.MaxHealth = math.huge hum.Health = math.huge
            else hum.MaxHealth = 100 hum.Health = 100 end
        end
        if state then
            if not godmodeConn then
                godmodeConn = RunService.Heartbeat:Connect(function()
                    local h = getHum()
                    if h and godmodeEnabled then
                        if h.Health < h.MaxHealth then h.Health = math.huge end
                    end
                end)
            end
        else
            if godmodeConn then godmodeConn:Disconnect() godmodeConn = nil end
        end
    end
})

SectionPlayer2:Toggle({
    Title = "No Fall Damage", Desc = "Take no damage when falling", Icon = "shield-check", Value = false,
    Callback = function(state)
        local hum = getHum()
        if hum then hum:SetStateEnabled(Enum.HumanoidStateType.FallingDown, not state) end
    end
})

SectionPlayer2:Toggle({
    Title = "No Gravity", Desc = "Character floats and ignores world gravity", Icon = "orbit", Value = false,
    Callback = function(state)
        if state then
            local hrp = getHRP()
            if hrp then
                local bg = Instance.new("BodyForce", hrp)
                bg.Name = "NoGravityForce"
                bg.Force = Vector3.new(0, workspace.Gravity * hrp:GetMass(), 0)
            end
        else
            local hrp2 = getHRP()
            if hrp2 then
                local f = hrp2:FindFirstChild("NoGravityForce")
                if f then f:Destroy() end
            end
        end
    end
})

SectionPlayer2:Divider()

SectionPlayer2:Toggle({
    Title = "Anti Fling", 
    Desc = "Phase through other players to avoid being flung or pushed", 
    Icon = "shield-off", 
    Value = false,
    Callback = function(state)
        _G.AntiFlingGhostActive = state
        
        if state then
            antiFlingGhostConn = RunService.Stepped:Connect(function()
                if not _G.AntiFlingGhostActive then 
                    if antiFlingGhostConn then antiFlingGhostConn:Disconnect() antiFlingGhostConn = nil end
                    return 
                end
                
                local char = getChar()
                if char then
                    for _, part in pairs(char:GetDescendants()) do
                        if part:IsA("BasePart") then
                            part.CanCollide = false
                            part.Velocity = Vector3.zero
                            part.RotVelocity = Vector3.zero
                        end
                    end
                end
            end)
        else
            if antiFlingGhostConn then 
                antiFlingGhostConn:Disconnect() 
                antiFlingGhostConn = nil 
            end
            
            local char = getChar()
            local hum = getHum()
            
            if char and hum then
                for _, part in pairs(char:GetDescendants()) do
                    if part:IsA("BasePart") then
                        part.CanCollide = false 
                    end
                end
                
                local hrp = char:FindFirstChild("HumanoidRootPart")
                if hrp then hrp.CanCollide = true end
                
                hum:ChangeState(Enum.HumanoidStateType.GettingUp)
                task.wait(0.1)
                hum:ChangeState(Enum.HumanoidStateType.Running)
            end
        end
    end
})



local SectionInvis = TabPlayer:Section({ Title = "Invisible", Icon = "eye-off", Opened = true })

SectionInvis:Toggle({
    Title = "Invisible V1", Desc = "Teleport character underground every frame, appears invisible to others", Icon = "eye-off", Value = false,
    Callback = function(state)
        local chr = getChar() local hum = getHum() local hrp = getHRP()
        if not chr or not hum or not hrp then return end
        if state then
            invisV1Parts = {}
            for _, d in pairs(chr:GetDescendants()) do
                if d:IsA("BasePart") and d.Transparency == 0 then
                    table.insert(invisV1Parts, d) d.Transparency = 0.5
                end
            end
            invisV1Conn = RunService.Heartbeat:Connect(function()
                if not getHRP() then return end
                local origCF = hrp.CFrame local origOffset = hum.CameraOffset
                hrp.CFrame = origCF * CFrame.new(0,-200,0)
                hum.CameraOffset = (origCF * CFrame.new(0,-200,0)):ToObjectSpace(CFrame.new(origCF.Position)).Position
                RunService.RenderStepped:Wait()
                hrp.CFrame = origCF hum.CameraOffset = origOffset
            end)
        else
            if invisV1Conn then invisV1Conn:Disconnect() invisV1Conn = nil end
            for _, p in pairs(invisV1Parts) do pcall(function() p.Transparency = 0 end) end
            invisV1Parts = {}
        end
    end
})

SectionInvis:Toggle({
    Title = "Invisible V2", Desc = "Teleport character to the sky every frame, appears invisible to others", Icon = "eye-off", Value = false,
    Callback = function(state)
        local chr = getChar() local hum = getHum() local hrp = getHRP()
        if not chr or not hum or not hrp then return end
        if state then
            invisV2Parts = {}
            for _, d in pairs(chr:GetDescendants()) do
                if d:IsA("BasePart") and d.Transparency == 0 then
                    table.insert(invisV2Parts, d) d.Transparency = 0.5
                end
            end
            invisV2Conn = RunService.Heartbeat:Connect(function()
                if not getHRP() then return end
                local origCF = hrp.CFrame local origOffset = hum.CameraOffset
                hrp.CFrame = origCF * CFrame.new(0,200,0)
                hum.CameraOffset = (origCF * CFrame.new(0,200,0)):ToObjectSpace(CFrame.new(origCF.Position)).Position
                RunService.RenderStepped:Wait()
                hrp.CFrame = origCF hum.CameraOffset = origOffset
            end)
        else
            if invisV2Conn then invisV2Conn:Disconnect() invisV2Conn = nil end
            for _, p in pairs(invisV2Parts) do pcall(function() p.Transparency = 0 end) end
            invisV2Parts = {}
        end
    end
})

-- TAB: Combat
local TabCombat = Window:Tab({ Title = "Combat", Icon = "swords" })

local SectionAim = TabCombat:Section({ Title = "Aim", Icon = "crosshair", Opened = true })

SectionAim:Toggle({
    Title = "Toggle Aimbot",
    Desc = "Shows Quick UI to turn Aimbot On/Off",
    Value = false,
    Callback = function(v)
        Config.AimbotEnabled = v
        QuickGui.Enabled = v
        if not v then
            Config.AimbotActive = false
            UpdateAimbotColor()
        end
    end
})

SectionAim:Toggle({
    Title = "Draggable UI",
    Desc = "Enable or disable dragging the Aimbot UI button",
    Value = false,
    Callback = function(v)
        Config.DraggableUI = v
    end
})

SectionAim:Slider({
    Title = "FOV Radius",
    Desc = "Size of the aimbot target area on your screen",
    Step = 1,
    Value = { Min = 10, Max = 500, Default = 100 },
    Callback = function(v)
        Config.FovRadius = v
    end
})

SectionAim:Slider({
    Title = "Smoothing",
    Desc = "How smooth the aimbot moves (1 = Instant, 10 = Very Smooth)",
    Step = 1,
    Value = { Min = 1, Max = 10, Default = 1 },
    Callback = function(v)
        Config.Smoothing = v
    end
})

local SectionPrediction = TabCombat:Section({ Title = "Prediction", Icon = "fast-forward", Opened = true })

SectionPrediction:Toggle({
    Title = "Prediction",
    Desc = "Compensates for lag and target movement",
    Value = false,
    Callback = function(v)
        Config.Prediction = v
    end
})

SectionPrediction:Slider({
    Title = "Prediction Amount",
    Desc = "How far ahead to predict the target's position",
    Step = 0.01,
    Value = { Min = 0.01, Max = 1, Default = 0.1 },
    Callback = function(v)
        Config.PredAmount = v
    end
})

local SectionAttack = TabCombat:Section({ Title = "Attack", Icon = "zap", Opened = true })

SectionAttack:Toggle({
    Title = "Kill Aura",
    Desc = "Automatically attacks players near you",
    Value = false,
    Callback = function(v)
        Config.KillAura = v
    end
})

SectionAttack:Slider({
    Title = "Kill Aura Range",
    Desc = "Maximum distance for Kill Aura to work (Keep it close)",
    Step = 1,
    Value = { Min = 5, Max = 25, Default = 10 },
    Callback = function(v)
        Config.KillAuraRange = v
    end
})

local SectionDefense = TabCombat:Section({ Title = "Defense", Icon = "shield", Opened = true })

SectionDefense:Toggle({
    Title = "Anti Aim",
    Desc = "Makes your character spin and break so enemies can't aim at you",
    Value = false,
    Callback = function(v)
        Config.AntiAim = v
    end
})

SectionDefense:Toggle({
    Title = "Anti Knockback / Ragdoll",
    Desc = "Prevents your character from being knocked back or falling down",
    Value = false,
    Callback = function(v)
        Config.AntiKnockback = v
    end
})

SectionDefense:Toggle({
    Title = "Anti Stun",
    Desc = "Prevents freeze and slow effects on your character",
    Value = false,
    Callback = function(v)
        Config.AntiStun = v
    end
})

-- TAB: TROLL
local TabTroll = Window:Tab({ Title = "Troll", Icon = "skull" })

local targetPlayer = nil
local activeLoops = {}
local activeStates = {}
local currentPlatform = nil

local function getPlayerHRP(player)
    return player.Character and player.Character:FindFirstChild("HumanoidRootPart")
end

local function isAlive(player)
    return player.Character
        and player.Character:FindFirstChild("Humanoid")
        and player.Character.Humanoid.Health > 0
end

local function playEmoteOnSelf(animationId, speed)
    local chr = LocalPlayer.Character
    if not chr then return nil end
    local hum = chr:FindFirstChild("Humanoid")
    if not hum then return nil end
    local anim = Instance.new("Animation")
    anim.AnimationId = "rbxassetid://" .. tostring(animationId)
    local track = hum:LoadAnimation(anim)
    track:Play()
    if speed then track:AdjustSpeed(speed) end
    return track
end

local function stopAllAnimations()
    local chr = LocalPlayer.Character
    if not chr then return end
    local hum = chr:FindFirstChild("Humanoid")
    if hum then
        for _, track in pairs(hum:GetPlayingAnimationTracks()) do
            pcall(function() track:Stop() end)
        end
    end
end

local playerListMap = {}

local function getPlayerDisplayNames()
    local names = {}
    playerListMap = {}
    for _, v in pairs(Players:GetPlayers()) do
        if v ~= LocalPlayer then
            local displayName = v.DisplayName
            if playerListMap[displayName] then
                displayName = displayName .. " (@" .. v.Name .. ")"
            end
            table.insert(names, displayName)
            playerListMap[displayName] = v
        end
    end
    return names
end

local SectionTarget = TabTroll:Section({ Title = "Target", Icon = "target", Opened = true })

local targetDropdown = SectionTarget:Dropdown({
    Title = "Choice Player", Desc = "Select a player as your target",
    Values = getPlayerDisplayNames(), Value = "",
    Callback = function(value)
        targetPlayer = playerListMap[value] or nil
    end
})

SectionTarget:Button({
    Title = "Refresh", Desc = "Update the player list", Icon = "refresh-cw",
    Callback = function()
        targetDropdown:Refresh(getPlayerDisplayNames())
    end
})

local targetDisplay = SectionTarget:Paragraph({
    Title = "Current Target", Desc = "No target selected yet", Icon = "circle-off",
})

task.spawn(function()
    while true do
        task.wait(0.5)
        if targetPlayer and isAlive(targetPlayer) then
            targetDisplay:SetTitle(targetPlayer.DisplayName)
            targetDisplay:SetDesc("@" .. targetPlayer.Name .. " | HP: " .. math.floor(targetPlayer.Character.Humanoid.Health))
        elseif targetPlayer then
            targetDisplay:SetTitle("Target Down")
            targetDisplay:SetDesc(targetPlayer.DisplayName .. " is dead")
        else
            targetDisplay:SetTitle("No Target")
            targetDisplay:SetDesc("Select from dropdown")
        end
    end
end)

TabTroll:Divider()

local SusSection = TabTroll:Section({ Title = "SUS", Icon = "eye", Opened = true })

SusSection:Toggle({
    Title = "DOGGY NORMAL", Desc = "Stand behind the target with doggy animation",
    Icon = "dog", Value = false,
    Callback = function(state)
        if state then
            if not targetPlayer then
                WindUI:Notify({ Title = "Error", Content = "Please select a target first!", Duration = 2, Icon = "alert-circle" }) return
            end
            activeStates["doggy"] = true
            playEmoteOnSelf(80401449796551, 1)
            currentPlatform = Instance.new("Part")
            currentPlatform.Size = Vector3.new(8, 0.5, 8)
            currentPlatform.Transparency = 1
            currentPlatform.Anchored = true
            currentPlatform.CanCollide = true
            currentPlatform.Parent = workspace
            activeLoops["doggy"] = RunService.Heartbeat:Connect(function()
                if activeStates["doggy"] and targetPlayer and isAlive(targetPlayer)
                    and getPlayerHRP(targetPlayer) and getPlayerHRP(LocalPlayer) then
                    currentPlatform.Position = getPlayerHRP(targetPlayer).Position + Vector3.new(0, -3, 0)
                    local targetPos = getPlayerHRP(targetPlayer).Position
                    local frontPos = targetPos + getPlayerHRP(targetPlayer).CFrame.LookVector * 0.6
                    getPlayerHRP(LocalPlayer).CFrame = CFrame.new(frontPos, targetPos) * CFrame.Angles(0, math.pi, 0)
                end
            end)
        else
            activeStates["doggy"] = false
            if activeLoops["doggy"] then activeLoops["doggy"]:Disconnect() activeLoops["doggy"] = nil end
            if currentPlatform then currentPlatform:Destroy() currentPlatform = nil end
            stopAllAnimations()
        end
    end
})

SusSection:Divider()

SusSection:Toggle({
    Title = "DOGGY LICK", Desc = "Stand in front of the target with doggy animation",
    Icon = "dog", Value = false,
    Callback = function(state)
        if state then
            if not targetPlayer then
                WindUI:Notify({ Title = "Error", Content = "Please select a target first!", Duration = 2, Icon = "alert-circle" }) return
            end
            activeStates["doggylick"] = true
            playEmoteOnSelf(80401449796551, 1)
            currentPlatform = Instance.new("Part")
            currentPlatform.Size = Vector3.new(8, 0.5, 8)
            currentPlatform.Transparency = 1
            currentPlatform.Anchored = true
            currentPlatform.CanCollide = true
            currentPlatform.Parent = workspace
            activeLoops["doggylick"] = RunService.Heartbeat:Connect(function()
                if activeStates["doggylick"] and targetPlayer and isAlive(targetPlayer)
                    and getPlayerHRP(targetPlayer) and getPlayerHRP(LocalPlayer) then
                    currentPlatform.Position = getPlayerHRP(targetPlayer).Position + Vector3.new(0, -3, 0)
                    local targetPos = getPlayerHRP(targetPlayer).Position
                    local frontPos = targetPos + getPlayerHRP(targetPlayer).CFrame.LookVector * 2.9
                    getPlayerHRP(LocalPlayer).CFrame = CFrame.new(frontPos, targetPos)
                end
            end)
        else
            activeStates["doggylick"] = false
            if activeLoops["doggylick"] then activeLoops["doggylick"]:Disconnect() activeLoops["doggylick"] = nil end
            if currentPlatform then currentPlatform:Destroy() currentPlatform = nil end
            stopAllAnimations()
        end
    end
})

SusSection:Divider()

SusSection:Toggle({
    Title = "ANNOY POKE", Desc = "Stand behind the target with poking animation",
    Icon = "hand", Value = false,
    Callback = function(state)
        if state then
            if not targetPlayer then
                WindUI:Notify({ Title = "Error", Content = "Please select a target first!", Duration = 2, Icon = "alert-circle" }) return
            end
            activeStates["poke"] = true
            playEmoteOnSelf(132457193718612, 1)
            currentPlatform = Instance.new("Part")
            currentPlatform.Size = Vector3.new(8, 0.5, 8)
            currentPlatform.Transparency = 1
            currentPlatform.Anchored = true
            currentPlatform.CanCollide = true
            currentPlatform.Parent = workspace
            activeLoops["poke"] = RunService.Heartbeat:Connect(function()
                if activeStates["poke"] and targetPlayer and isAlive(targetPlayer)
                    and getPlayerHRP(targetPlayer) and getPlayerHRP(LocalPlayer) then
                    currentPlatform.Position = getPlayerHRP(targetPlayer).Position + Vector3.new(0, -3, 0)
                    local targetPos = getPlayerHRP(targetPlayer).Position
                    local frontPos = targetPos + getPlayerHRP(targetPlayer).CFrame.LookVector * -1.3
                    getPlayerHRP(LocalPlayer).CFrame = CFrame.new(frontPos, targetPos)
                end
            end)
        else
            activeStates["poke"] = false
            if activeLoops["poke"] then activeLoops["poke"]:Disconnect() activeLoops["poke"] = nil end
            if currentPlatform then currentPlatform:Destroy() currentPlatform = nil end
            stopAllAnimations()
        end
    end
})

TabTroll:Divider()

local FlingSection = TabTroll:Section({ Title = "FLING", Icon = "rocket", Opened = true })

local function createFlingToolFixed(toolName, animId, limbGetFn, r6AnimId, r15AnimId, powerMult)
    local chr = getChar()
    local hum = getHum()
    if not chr or not hum then return nil end
    local rigType = hum.RigType
    local limb = limbGetFn()
    if not limb then return nil end

    local tool = Instance.new("Tool", LocalPlayer.Backpack)
    tool.RequiresHandle = false
    tool.Name = toolName
    tool.ToolTip = toolName

    local anim = Instance.new("Animation", tool)
    if animId then
        anim.AnimationId = "rbxassetid://" .. tostring(animId)
    elseif rigType == Enum.HumanoidRigType.R6 then
        anim.AnimationId = "rbxassetid://" .. tostring(r6AnimId)
    else
        anim.AnimationId = "rbxassetid://" .. tostring(r15AnimId)
    end

    local track = hum:LoadAnimation(anim)
    local acting = false
    local pm = powerMult or 1

    tool.Activated:Connect(function()
        if acting then return end
        acting = true

        local animate = chr:FindFirstChild("Animate")

        track:Play()

        if not animId then
            if rigType == Enum.HumanoidRigType.R6 then
                task.wait(0.2)
                track:AdjustSpeed(3)
            else
                track.TimePosition = 1.65
                track.Looped = false
                track:AdjustSpeed(1.1)
            end
        else
            track:AdjustSpeed(1.2)
            task.wait(0.15)
        end

        local times = 0
        limb.CanCollide = true

        repeat
            RunService.Heartbeat:Wait()
            limb.CanCollide = true
            times = times + 1

            local root = getHRP()
            local movel = 0.1

            while not (chr and chr.Parent and root and root.Parent) do
                RunService.Heartbeat:Wait()
                root = getHRP()
            end

            for _, touchedPart in pairs(limb:GetTouchingParts()) do
                local touchedChar = touchedPart.Parent
                if touchedChar and touchedChar:FindFirstChildWhichIsA("Humanoid") then
                    local tp = Players:GetPlayerFromCharacter(touchedChar)
                    if tp and tp ~= LocalPlayer then
                        local tHRP = touchedChar:FindFirstChild("HumanoidRootPart")
                        if tHRP then doNaNFling(tHRP) end
                    end
                end
            end

            local vel = root.Velocity
            root.Velocity = vel * (PunchPower * pm) + Vector3.new(0, PunchPower * pm, 0)

            RunService.RenderStepped:Wait()
            if chr and chr.Parent and root and root.Parent then
                root.Velocity = vel
            end

            RunService.Stepped:Wait()
            if chr and chr.Parent and root and root.Parent then
                root.Velocity = vel + Vector3.new(0, movel, 0)
                movel = movel * -1
            end
        until times == PunchTime

        pcall(function() track:Stop(0.3) end)
        limb.CanCollide = false

        if animate then
            animate.Disabled = true
            task.wait(0.05)
            animate.Disabled = false
        end

        local h = getHum()
        if h then
            local speed = h.WalkSpeed
            h.WalkSpeed = 0
            task.wait(0.05)
            h.WalkSpeed = speed
        end

        acting = false
    end)

    return tool
end

local function createPunchFlingFixed()
    removePunchTool()
    punchTool = createFlingToolFixed("PiePunch", nil, getRightArm, 28156406, 10717116749, 1)
end

local function createSaitamaFlingFixed()
    removeSaitamaTool()
    saitamaTool = createFlingToolFixed("PieSaitama", 92870860509002, getRightArm, nil, nil, 2)
end

local function createKickFlingFixed()
    removeKickTool()
    kickTool = createFlingToolFixed("PieKick", 133566007754001, getLeftLeg, nil, nil, 1.5)
end

FlingSection:Toggle({
    Title = "PUNCH FLING (Tool)", Desc = "Equip punch tool and click a player to fling them",
    Icon = "hand", Value = false,
    Callback = function(state)
        punchActive = state
        if state then
            createPunchFlingFixed()
        else
            removePunchTool()
        end
    end
})

FlingSection:Toggle({
    Title = "SAITAMA FLING (Tool)", Desc = "Equip saitama tool and click a player to fling them",
    Icon = "zap", Value = false,
    Callback = function(state)
        saitamaActive = state
        if state then
            createSaitamaFlingFixed()
        else
            removeSaitamaTool()
        end
    end
})

FlingSection:Toggle({
    Title = "DROP KICK FLING (Tool)", Desc = "Equip dropkick tool and click a player to fling them",
    Icon = "footprints", Value = false,
    Callback = function(state)
        kickActive = state
        if state then
            createKickFlingFixed()
        else
            removeKickTool()
        end
    end
})

FlingSection:Slider({
    Title = "Fling Power", Desc = "Set how strong the fling is | Default: 50", Icon = "zap",
    Step = 5, Value = { Min = 1, Max = 500, Default = 50 }, IsTooltip = true, IsTextbox = true,
    Callback = function(v) PunchPower = v end
})

FlingSection:Slider({
    Title = "Fling Time", Desc = "Set how long the fling lasts | Default: 30", Icon = "timer",
    Step = 5, Value = { Min = 1, Max = 120, Default = 30 }, IsTooltip = true, IsTextbox = true,
    Callback = function(v) PunchTime = v end
})

-- TAB: ANIMATIONS
local TabAnimations = Window:Tab({ Title = "Animations", Icon = "person-standing" })

local AnimationList = {
    { Title = "Astronaut",          Idle = 10921034824,     Idle2 = 10921036806,     Walk = 10921046031,     Run = 10921039308,     Jump = 10921042494,     Climb = 10921032124,     Fall = 10921040576,     Swim = 10921044000,     SwimIdle = 10921045006     },
    { Title = "Bold by e.l.f.",     Idle = 16738333868,     Idle2 = 16738334710,     Walk = 16738340646,     Run = 16738337225,     Jump = 16738336650,     Climb = 16738332169,     Fall = 16738333171,     Swim = 16738339158,     SwimIdle = 16738339817     },
    { Title = "Bubbly",             Idle = 10921054344,     Idle2 = 10921055107,     Walk = 10980888364,     Run = 10921057244,     Jump = 10921062673,     Climb = 10921053544,     Fall = 10921061530,     Swim = 10921063569,     SwimIdle = 10922582160     },
    { Title = "Cartoony",           Idle = 10921071918,     Idle2 = 10921072875,     Walk = 10921082452,     Run = 10921076136,     Jump = 10921078135,     Climb = 10921070953,     Fall = 10921077030,     Swim = 10921079380,     SwimIdle = 10921081059     },
    { Title = "Catwalk Glam",       Idle = 133806214992291, Idle2 = 94970088341563,  Walk = 109168724482748, Run = 81024476153754,  Jump = 116936326516985, Climb = 119377220967554, Fall = 92294537340807,  Swim = 134591743181628, SwimIdle = 98854111361360  },
    { Title = "Confident",          Idle = 1069987858,      Idle2 = 1069977950,      Walk = 1070017263,      Run = 1070001516,      Jump = 1069984524,      Climb = 1069946257,      Fall = 1069973677,      Swim = 1070009914,      SwimIdle = 1070012133      },
    { Title = "Cowboy",             Idle = 1014398616,      Idle2 = 1014390418,      Walk = 1014421541,      Run = 1014401683,      Jump = 1014394726,      Climb = 1014380606,      Fall = 1014384571,      Swim = 1014406523,      SwimIdle = 1014411816      },
    { Title = "Elder",              Idle = 10921101664,     Idle2 = 10921102574,     Walk = 10921111375,     Run = 10921104374,     Jump = 10921107367,     Climb = 10921100400,     Fall = 10921105765,     Swim = 10921108971,     SwimIdle = 10921110146     },
    { Title = "Knight",             Idle = 10921117521,     Idle2 = 10921118894,     Walk = 10921127095,     Run = 10921121197,     Jump = 10921123517,     Climb = 10921116196,     Fall = 10921122579,     Swim = 10921125160,     SwimIdle = 10921125935     },
    { Title = "Levitation",         Idle = 10921132962,     Idle2 = 10921133721,     Walk = 10921140719,     Run = 10921135644,     Jump = 10921137402,     Climb = 10921132092,     Fall = 10921136539,     Swim = 10921138209,     SwimIdle = 10921139478     },
    { Title = "Mage",               Idle = 10921144709,     Idle2 = 10921145797,     Walk = 10921152678,     Run = 10921148209,     Jump = 10921149743,     Climb = 10921143404,     Fall = 10921148939,     Swim = 10921150788,     SwimIdle = 10921151661     },
    { Title = "NFL",                Idle = 92080889861410,  Idle2 = 74451233229259,  Walk = 110358958299415, Run = 117333533048078, Jump = 119846112151352, Climb = 134630013742019, Fall = 129773241321032, Swim = 132697394189921, SwimIdle = 79090109939093  },
    { Title = "Ninja",              Idle = 10921155160,     Idle2 = 10921155867,     Walk = 10921162768,     Run = 10921157929,     Jump = 10921160088,     Climb = 10921154678,     Fall = 10921159222,     Swim = 10921161002,     SwimIdle = 10922757002     },
    { Title = "No Boundaries",      Idle = 18747067405,     Idle2 = 18747063918,     Walk = 18747074203,     Run = 18747070484,     Jump = 18747069148,     Climb = 18747060903,     Fall = 18747062535,     Swim = 18747073181,     SwimIdle = 18747071682     },
    { Title = "Oldschool",          Idle = 10921230744,     Idle2 = 10921232093,     Walk = 10921244891,     Run = 10921240218,     Jump = 10921242013,     Climb = 10921229866,     Fall = 10921241244,     Swim = 10921243048,     SwimIdle = 10921244018     },
    { Title = "Patrol",             Idle = 1150842221,      Idle2 = 1149612882,      Walk = 1151231493,      Run = 1150967949,      Jump = 1150944216,      Climb = 1148811837,      Fall = 1148863382,      Swim = 1151204998,      SwimIdle = 1151221899      },
    { Title = "Pirate",             Idle = 750781874,       Idle2 = 750782770,       Walk = 750785693,       Run = 750783738,       Jump = 750782230,       Climb = 750779899,       Fall = 750780242,       Swim = 750784579,       SwimIdle = 750785176       },
    { Title = "Popstar",            Idle = 1212954651,      Idle2 = 1212900985,      Walk = 1212980338,      Run = 1212980348,      Jump = 1212954642,      Climb = 1213044953,      Fall = 1212900995,      Swim = 1212852603,      SwimIdle = 1212998578      },
    { Title = "Princess",           Idle = 941013098,       Idle2 = 941003647,       Walk = 941028902,       Run = 941015281,       Jump = 941008832,       Climb = 940996062,       Fall = 941000007,       Swim = 941018893,       SwimIdle = 941025398       },
    { Title = "Robot",              Idle = 10921248039,     Idle2 = 10921248831,     Walk = 10921255446,     Run = 10921250460,     Jump = 10921252123,     Climb = 10921247141,     Fall = 10921251156,     Swim = 10921253142,     SwimIdle = 10921253767     },
    { Title = "Rthro",              Idle = 10921259953,     Idle2 = 10921258489,     Walk = 10921269718,     Run = 10921261968,     Jump = 10921263860,     Climb = 10921257536,     Fall = 10921262864,     Swim = 10921264784,     SwimIdle = 10921265698     },
    { Title = "Sneaky",             Idle = 1132477671,      Idle2 = 1132473842,      Walk = 1132510133,      Run = 1132494274,      Jump = 1132489853,      Climb = 1132461372,      Fall = 1132469004,      Swim = 1132500520,      SwimIdle = 1132506407      },
    { Title = "Stylish",            Idle = 10921272275,     Idle2 = 10921273958,     Walk = 10921283326,     Run = 10921276116,     Jump = 10921279832,     Climb = 10921271391,     Fall = 10921278648,     Swim = 10921281000,     SwimIdle = 10921281964     },
    { Title = "Stylized Female",    Idle = 4708192150,      Idle2 = 4708191566,      Walk = 4708193840,      Run = 4708192705,      Jump = 4708188025,      Climb = 4708184253,      Fall = 4708186162,      Swim = 4708189360,      SwimIdle = 4708190607      },
    { Title = "Superhero",          Idle = 10921288909,     Idle2 = 10921290167,     Walk = 10921298616,     Run = 10921291831,     Jump = 10921294559,     Climb = 10921286911,     Fall = 10921293373,     Swim = 10921295495,     SwimIdle = 10921297391     },
    { Title = "Toy",                Idle = 10921301576,     Idle2 = 10921302207,     Walk = 10921312010,     Run = 10921306285,     Jump = 10921308158,     Climb = 10921300839,     Fall = 10921307241,     Swim = 10921309319,     SwimIdle = 10921310341     },
    { Title = "Vampire",            Idle = 10921315373,     Idle2 = 10921316709,     Walk = 10921326949,     Run = 10921320299,     Jump = 10921322186,     Climb = 10921314188,     Fall = 10921321317,     Swim = 10921324408,     SwimIdle = 10921325443     },
    { Title = "Werewolf",           Idle = 10921330408,     Idle2 = 10921333667,     Walk = 10921342074,     Run = 10921336997,     Jump = 1083218792,      Climb = 10921329322,     Fall = 10921337907,     Swim = 10921340419,     SwimIdle = 10921341319     },
    { Title = "Wicked Popular",     Idle = 118832222982049, Idle2 = 76049494037641,  Walk = 92072849924640,  Run = 72301599441680,  Jump = 104325245285198, Climb = 131326830509784, Fall = 121152442762481, Swim = 99384245425157,  SwimIdle = 113199415118199 },
    { Title = "Zombie",             Idle = 10921344533,     Idle2 = 10921345304,     Walk = 10921355261,     Run = 616163682,       Jump = 10921351278,     Climb = 10921343576,     Fall = 10921350320,     Swim = 10921352344,     SwimIdle = 10921353442     },
    { Title = "adidas Sports",      Idle = 18537376492,     Idle2 = 18537371272,     Walk = 18537392113,     Run = 18537384940,     Jump = 18537380791,     Climb = 18537363391,     Fall = 18537367238,     Swim = 18537389531,     SwimIdle = 18537387180     },
}

local FullEmoteList = {}

local function loadVexroEmotes()
    pcall(function()
        local response = game:HttpGet("https://raw.githubusercontent.com/zyrovell/Vexro/main/emotes.json")
        local data = HttpService:JSONDecode(response)
        if type(data) == "table" then
            for _, v in ipairs(data.data) do
                if type(v) == "table" then
                    local name = v.name or v.Name
                    local id = tonumber(v.id or v.Id)
                    if name and id then table.insert(FullEmoteList, { Title = tostring(name), Id = id }) end
                end
            end
        end
    end)
    if #FullEmoteList == 0 then
        for _, v in ipairs({
            { Title = "Floss Dance", Id = 5917459365 }, { Title = "Fancy Feet", Id = 3333432454 },
            { Title = "Wave", Id = 3576686446 }, { Title = "Dance", Id = 3576720708 },
        }) do table.insert(FullEmoteList, v) end
    end
end

local function loadAFEMEmotes()
    pcall(function()
        local response = game:HttpGet("https://raw.githubusercontent.com/Joystickplays/AFEM/main/emotes.json")
        local data = HttpService:JSONDecode(response)
        if type(data) == "table" then
            for _, v in ipairs(data) do
                if type(v) == "table" then
                    local name = v.name or v.Name
                    local id = tonumber(v.id or v.Id)
                    if name and id then table.insert(FullEmoteList, { Title = tostring(name), Id = id }) end
                end
            end
        end
    end)
end

local function load7yd7Emotes()
    pcall(function()
        local response = game:HttpGet("https://raw.githubusercontent.com/7yd7/sniper-Emote/test/EmoteSniper.json")
        local data = HttpService:JSONDecode(response)
        if type(data) == "table" then
            for _, v in ipairs(data.data) do
                if type(v) == "table" then
                    local name = v.name or v.Name
                    local id = tonumber(v.id or v.Id)
                    if name and id then table.insert(FullEmoteList, { Title = tostring(name), Id = id }) end
                end
            end
        end
    end)
end

loadVexroEmotes()
loadAFEMEmotes()
load7yd7Emotes()

for _, v in ipairs({
    { Title = "Kicau Mania", Id = 94366793932506 },
    { Title = "Ketlin", Id = 138980457623979 },
    { Title = "Drop Kick", Id = 133566007754001 },
}) do table.insert(FullEmoteList, v) end

local _seen = {} local _deduped = {}
for _, v in ipairs(FullEmoteList) do
    if not _seen[v.Title] then _seen[v.Title] = true table.insert(_deduped, v) end
end
FullEmoteList = _deduped
table.sort(FullEmoteList, function(a,b) return a.Title:lower() < b.Title:lower() end)

local URL_ANIM = "http://www.roblox.com/asset/?id="
local selectedAnimation = nil
local selectedCustomEmote = nil
local customEmoteNameValue = ""
local customEmoteAnimIdValue = ""
local defaultAnimIds = {}
local currentEmoteTrack = nil
local emoteLoopEnabled = true
local emoteWalkEnabled = false
local customEmoteLoopEnabled = true
local customEmoteWalkEnabled = false
local walkEmoteConn = nil
local customWalkEmoteConn = nil
local _animObjCache = {}

local function getAnimator()
    local chr = getChar()
    if not chr then return nil end
    local hum = chr:FindFirstChildWhichIsA("Humanoid")
    if not hum then return nil end
    local animator = hum:FindFirstChildOfClass("Animator")
    if not animator then animator = Instance.new("Animator") animator.Parent = hum end
    return animator
end

local function stopAllTracks()
    local animator = getAnimator()
    if not animator then return end
    for _, track in ipairs(animator:GetPlayingAnimationTracks()) do
        pcall(function() track:Stop(0.1) end)
    end
    currentEmoteTrack = nil
end

local function getAnimData(title)
    for _, v in ipairs(AnimationList) do
        if v.Title == title then return v end
    end
end

local function saveDefaultAnims()
    local chr = getChar()
    if not chr then return end
    local Animate = chr:FindFirstChild("Animate")
    if not Animate or next(defaultAnimIds) ~= nil then return end
    pcall(function()
        if Animate:FindFirstChild("idle") then
            defaultAnimIds.Idle = Animate.idle.Animation1.AnimationId
            defaultAnimIds.Idle2 = Animate.idle.Animation2.AnimationId
        end
        for _, name in ipairs({"walk","run","jump","climb","fall"}) do
            if Animate:FindFirstChild(name) then
                local a = Animate[name]:FindFirstChildOfClass("Animation")
                if a then defaultAnimIds[name:sub(1,1):upper()..name:sub(2)] = a.AnimationId end
            end
        end
        if Animate:FindFirstChild("swim") then
            local a = Animate.swim:FindFirstChildOfClass("Animation")
            if a then defaultAnimIds.Swim = a.AnimationId end
        end
        if Animate:FindFirstChild("swimidle") then
            local a = Animate.swimidle:FindFirstChildOfClass("Animation")
            if a then defaultAnimIds.SwimIdle = a.AnimationId end
        end
    end)
end

local function applyAnimation(data)
    local chr = getChar()
    if not chr then return end
    local Animate = chr:FindFirstChild("Animate")
    if not Animate then return end
    saveDefaultAnims()
    stopAllTracks()
    pcall(function()
        if Animate:FindFirstChild("idle") then
            Animate.idle.Animation1.AnimationId = URL_ANIM .. data.Idle
            Animate.idle.Animation2.AnimationId = URL_ANIM .. data.Idle2
        end
        for _, pair in ipairs({{"walk","Walk"},{"run","Run"},{"jump","Jump"},{"climb","Climb"},{"fall","Fall"}}) do
            if Animate:FindFirstChild(pair[1]) then
                local a = Animate[pair[1]]:FindFirstChildOfClass("Animation")
                if a then a.AnimationId = URL_ANIM .. data[pair[2]] end
            end
        end
        if data.Swim and Animate:FindFirstChild("swim") then
            local a = Animate.swim:FindFirstChildOfClass("Animation")
            if a then a.AnimationId = URL_ANIM .. data.Swim end
        end
        if data.SwimIdle and Animate:FindFirstChild("swimidle") then
            local a = Animate.swimidle:FindFirstChildOfClass("Animation")
            if a then a.AnimationId = URL_ANIM .. data.SwimIdle end
        end
    end)
    Animate.Disabled = true task.wait(0.05) Animate.Disabled = false
end

local function resetAnimation()
    local chr = getChar()
    if not chr then return end
    local Animate = chr:FindFirstChild("Animate")
    if not Animate then return end
    stopAllTracks()
    if next(defaultAnimIds) ~= nil then
        pcall(function()
            if Animate:FindFirstChild("idle") then
                if defaultAnimIds.Idle then Animate.idle.Animation1.AnimationId = defaultAnimIds.Idle end
                if defaultAnimIds.Idle2 then Animate.idle.Animation2.AnimationId = defaultAnimIds.Idle2 end
            end
            for _, pair in ipairs({{"walk","Walk"},{"run","Run"},{"jump","Jump"},{"climb","Climb"},{"fall","Fall"}}) do
                if Animate:FindFirstChild(pair[1]) then
                    local a = Animate[pair[1]]:FindFirstChildOfClass("Animation")
                    if a and defaultAnimIds[pair[2]] then a.AnimationId = defaultAnimIds[pair[2]] end
                end
            end
            if Animate:FindFirstChild("swim") then
                local a = Animate.swim:FindFirstChildOfClass("Animation")
                if a and defaultAnimIds.Swim then a.AnimationId = defaultAnimIds.Swim end
            end
            if Animate:FindFirstChild("swimidle") then
                local a = Animate.swimidle:FindFirstChildOfClass("Animation")
                if a and defaultAnimIds.SwimIdle then a.AnimationId = defaultAnimIds.SwimIdle end
            end
        end)
    end
    Animate.Disabled = true task.wait(0.05) Animate.Disabled = false
    defaultAnimIds = {}
end

local function loadEmoteObj(id)
    local animObj = _animObjCache[id]
    if not animObj then
        local ok, objects = pcall(function() return game:GetObjects("rbxassetid://" .. tostring(id)) end)
        if ok and objects and #objects > 0 then
            local item = objects[1]
            animObj = item:IsA("Animation") and item or item:FindFirstChildWhichIsA("Animation", true)
        end
        if not animObj then
            animObj = Instance.new("Animation")
            animObj.AnimationId = "rbxassetid://" .. tostring(id)
        end
        _animObjCache[id] = animObj
    end
    return animObj
end

local emotePlayGeneration = 0

local function playEmote(data, loopState, walkState)
    emotePlayGeneration = emotePlayGeneration + 1
    local myGeneration = emotePlayGeneration

    if walkEmoteConn then walkEmoteConn:Disconnect() walkEmoteConn = nil end
    if currentEmoteTrack then
        pcall(function() currentEmoteTrack:Stop(0.1) end)
        currentEmoteTrack = nil
    end
    local animator = getAnimator()
    if not animator then return end
    for _, oldTrack in ipairs(animator:GetPlayingAnimationTracks()) do
        pcall(function() oldTrack:Stop(0.1) end)
    end
    task.spawn(function()
        local animObj = loadEmoteObj(data.Id)
        local ok2, track = pcall(function() return animator:LoadAnimation(animObj) end)
        if myGeneration ~= emotePlayGeneration then
            if ok2 and track then pcall(function() track:Stop(0) track:Destroy() end) end
            return
        end
        if not ok2 or not track then
            WindUI:Notify({ Title = "Error", Content = "Gagal load emote!", Duration = 2, Icon = "alert-circle" }) return
        end
        track.Priority = Enum.AnimationPriority.Action4
        track.Looped = loopState
        track:Play(0.15)
        if myGeneration ~= emotePlayGeneration then
            pcall(function() track:Stop(0) end)
            return
        end
        currentEmoteTrack = track

        if walkState then
            local conn
            conn = RunService.Heartbeat:Connect(function()
                if myGeneration ~= emotePlayGeneration then conn:Disconnect() return end
                local hum = getHum()
                if not hum then
                    pcall(function() track:Stop(0.1) end)
                    conn:Disconnect() currentEmoteTrack = nil return
                end
                if not track.IsPlaying and loopState then
                    track:Play(0.1)
                end
            end)
            walkEmoteConn = conn
        else
            local conn
            conn = RunService.Heartbeat:Connect(function()
                if myGeneration ~= emotePlayGeneration then conn:Disconnect() return end
                local hum = getHum()
                if not hum then
                    pcall(function() track:Stop(0.1) end)
                    conn:Disconnect() currentEmoteTrack = nil return
                end
                if hum.MoveDirection.Magnitude > 0 then
                    pcall(function() track:Stop(0.2) end)
                    currentEmoteTrack = nil conn:Disconnect()
                end
            end)
            track.Stopped:Connect(function()
                if myGeneration == emotePlayGeneration then currentEmoteTrack = nil end
                pcall(function() conn:Disconnect() end)
            end)
        end
    end)
end

local function stopEmote()
    emotePlayGeneration = emotePlayGeneration + 1
    if walkEmoteConn then walkEmoteConn:Disconnect() walkEmoteConn = nil end
    if customWalkEmoteConn then customWalkEmoteConn:Disconnect() customWalkEmoteConn = nil end
    if currentEmoteTrack then
        pcall(function() currentEmoteTrack:Stop(0.2) end)
        currentEmoteTrack = nil
    end
    local animator = getAnimator()
    if animator then
        for _, oldTrack in ipairs(animator:GetPlayingAnimationTracks()) do
            if oldTrack.Priority == Enum.AnimationPriority.Action4 then
                pcall(function() oldTrack:Stop(0.2) end)
            end
        end
    end
end

local EMOTE_PER_PAGE = 30
local emotePage = 1
local emoteSearchResults = FullEmoteList
local selectedEmote = nil

local function getFilteredEmotes(query)
    if not query or query == "" then return FullEmoteList end
    local result = {} local q = query:lower()
    for _, v in ipairs(FullEmoteList) do
        if v.Title:lower():find(q, 1, true) then table.insert(result, v) end
    end
    return result
end

local function filterEmoteListBy(list, query)
    if not query or query == "" then return list end
    local result = {} local q = query:lower()
    for _, v in ipairs(list) do
        if v.Title:lower():find(q, 1, true) then table.insert(result, v) end
    end
    return result
end

local function getEmotePage(list, pg)
    local names = {}
    local s = (pg-1)*EMOTE_PER_PAGE+1
    local e2 = math.min(pg*EMOTE_PER_PAGE, #list)
    for i = s, e2 do table.insert(names, list[i].Title) end
    return names
end

local function getTotalEmotePages(list)
    return math.max(1, math.ceil(#list / EMOTE_PER_PAGE))
end

local function getEmoteData(title)
    for _, v in ipairs(FullEmoteList) do
        if v.Title == title then return v end
    end
    return nil
end

local customEmotes = {}
local customEmotesFile = "WindUI/PieHub/customEmotes.json"

pcall(function()
    if makefolder and not isfolder("WindUI") then makefolder("WindUI") end
    if makefolder and not isfolder("WindUI/PieHub") then makefolder("WindUI/PieHub") end
end)

local function saveCustomEmotes()
    pcall(function()
        if writefile then writefile(customEmotesFile, HttpService:JSONEncode(customEmotes)) end
    end)
end

local function loadCustomEmotes()
    pcall(function()
        if readfile and isfile and isfile(customEmotesFile) then
            local data = HttpService:JSONDecode(readfile(customEmotesFile))
            if type(data) == "table" then customEmotes = data end
        end
    end)
end

loadCustomEmotes()

local animNameList = {}
for _, v in ipairs(AnimationList) do table.insert(animNameList, v.Title) end
table.sort(animNameList, function(a,b) return a:lower() < b:lower() end)

-- ===================== CUSTOM ANIMATIONS SECTION =====================
local customAnimPacks = {}
local customAnimPacksFile = "WindUI/PieHub/customAnimPacks.json"
local customAnimPackNameValue = ""
local selectedCustomAnimPack = ""
local customAnimIdle = "Default"
local customAnimIdle2 = "Default"
local customAnimWalk = "Default"
local customAnimRun = "Default"
local customAnimJump = "Default"
local customAnimClimb = "Default"
local customAnimFall = "Default"
local customAnimSwim = "Default"
local customAnimSwimIdle = "Default"
local customAnimPackDropdown
local customAnimGuiAnimDropdown

pcall(function()
    if makefolder and not isfolder("WindUI") then makefolder("WindUI") end
    if makefolder and not isfolder("WindUI/PieHub") then makefolder("WindUI/PieHub") end
end)

local function saveCustomAnimPacks()
    pcall(function()
        if writefile then writefile(customAnimPacksFile, HttpService:JSONEncode(customAnimPacks)) end
    end)
end

local function loadCustomAnimPacks()
    pcall(function()
        if readfile and isfile and isfile(customAnimPacksFile) then
            local data = HttpService:JSONDecode(readfile(customAnimPacksFile))
            if type(data) == "table" then customAnimPacks = data end
        end
    end)
end

loadCustomAnimPacks()

local function getCustomAnimPackNames()
    local names = {}
    for name in pairs(customAnimPacks) do table.insert(names, name) end
    table.sort(names, function(a, b) return a:lower() < b:lower() end)
    return names
end

local function getAnimIdDropdownValues()
    local vals = { "Default" }
    for _, v in ipairs(AnimationList) do table.insert(vals, v.Title) end
    return vals
end

local function applyCustomAnimPack(packName)
    local pack = customAnimPacks[packName]
    if not pack then return end
    local chr = getChar()
    if not chr then return end
    local Animate = chr:FindFirstChild("Animate")
    if not Animate then return end
    saveDefaultAnims()
    stopAllTracks()
    pcall(function()
        local function resolveId(fieldName)
            local val = pack[fieldName]
            if not val or val == "Default" then
                return defaultAnimIds[fieldName] or nil
            end
            local animData = getAnimData(val)
            if animData then
                return animData[fieldName]
            end
            return nil
        end
        if Animate:FindFirstChild("idle") then
            local id1 = resolveId("Idle")
            local id2 = resolveId("Idle2")
            if id1 then Animate.idle.Animation1.AnimationId = URL_ANIM .. id1 end
            if id2 then Animate.idle.Animation2.AnimationId = URL_ANIM .. id2 end
        end
        for _, pair in ipairs({ { "walk", "Walk" }, { "run", "Run" }, { "jump", "Jump" }, { "climb", "Climb" }, { "fall", "Fall" } }) do
            if Animate:FindFirstChild(pair[1]) then
                local a = Animate[pair[1]]:FindFirstChildOfClass("Animation")
                local id = resolveId(pair[2])
                if a and id then a.AnimationId = URL_ANIM .. id end
            end
        end
        if Animate:FindFirstChild("swim") then
            local a = Animate.swim:FindFirstChildOfClass("Animation")
            local id = resolveId("Swim")
            if a and id then a.AnimationId = URL_ANIM .. id end
        end
        if Animate:FindFirstChild("swimidle") then
            local a = Animate.swimidle:FindFirstChildOfClass("Animation")
            local id = resolveId("SwimIdle")
            if a and id then a.AnimationId = URL_ANIM .. id end
        end
    end)
    Animate.Disabled = true task.wait(0.05) Animate.Disabled = false
end

local function refreshCustomAnimGui()
    customAnimPackDropdown:Refresh(getCustomAnimPackNames())
    local allNames = {}
    for _, v in ipairs(animNameList) do table.insert(allNames, v) end
    for k in pairs(customAnimPacks) do table.insert(allNames, "[Custom] " .. k) end
    table.sort(allNames, function(a, b) return a:lower() < b:lower() end)
    customAnimGuiAnimDropdown:Refresh(allNames)
    qeAnimResults = qeGetAnimList()
    qeRefreshList()
end

-- TAB ANIMATIONS: Section Animations
local SectionAnim = TabAnimations:Section({ Title = "Animations", Icon = "person-standing", Opened = true })

customAnimGuiAnimDropdown = SectionAnim:Dropdown({
    Title = "Animation List", Desc = "Choose an animation pack to apply",
    Values = animNameList, Value = "", SearchBarEnabled = true,
    Callback = function(v) selectedAnimation = v end
})

local HStackAnimBtn = SectionAnim:HStack({ AutoSpace = true })
HStackAnimBtn:Button({
    Title = "Apply", Icon = "check",
    Callback = function()
        if not selectedAnimation or selectedAnimation == "" then
            WindUI:Notify({ Title = "Error", Content = "Please select an animation first!", Duration = 2, Icon = "alert-circle" }) return
        end
        local customKey = selectedAnimation:match("^%[Custom%] (.+)$")
        if customKey then
            applyCustomAnimPack(customKey)
            WindUI:Notify({ Title = "Animations", Content = "Custom pack '" .. customKey .. "' has been applied!", Duration = 2, Icon = "check" })
            return
        end
        local data = getAnimData(selectedAnimation)
        if not data then
            WindUI:Notify({ Title = "Error", Content = "The selected animation could not be found!", Duration = 2, Icon = "alert-circle" }) return
        end
        applyAnimation(data)
        WindUI:Notify({ Title = "Animations", Content = "Animation '" .. selectedAnimation .. "' has been applied!", Duration = 2, Icon = "check" })
    end
})
HStackAnimBtn:Button({
    Title = "Reset", Icon = "refresh-cw",
    Callback = function()
        resetAnimation() selectedAnimation = nil
        WindUI:Notify({ Title = "Animations", Content = "Animation has been reset to default", Duration = 2, Icon = "refresh-cw" })
    end
})

-- TAB ANIMATIONS: Section Custom Animations
local SectionCustomAnim = TabAnimations:Section({ Title = "Custom Animations", Icon = "sliders", Opened = true })

SectionCustomAnim:Input({
    Title = "Pack Name",
    Desc = "Enter a name for your custom animation pack",
    Placeholder = "My Pack",
    Value = "",
    Callback = function(v)
        customAnimPackNameValue = v
    end
})

customAnimPackDropdown = SectionCustomAnim:Dropdown({
    Title = "Custom Pack List",
    Desc = "Select a saved custom animation pack",
    Values = getCustomAnimPackNames(),
    Value = "",
    Callback = function(v)
        selectedCustomAnimPack = v
    end
})

SectionCustomAnim:Dropdown({
    Title = "Idle",
    Desc = "Animation for Idle | Default = use your own character animation",
    Values = getAnimIdDropdownValues(),
    Value = "Default",
    Callback = function(v)
        customAnimIdle = v
    end
})

SectionCustomAnim:Dropdown({
    Title = "Idle2",
    Desc = "Animation for Idle2 | Default = use your own character animation",
    Values = getAnimIdDropdownValues(),
    Value = "Default",
    Callback = function(v)
        customAnimIdle2 = v
    end
})

SectionCustomAnim:Dropdown({
    Title = "Walk",
    Desc = "Animation for Walk | Default = use your own character animation",
    Values = getAnimIdDropdownValues(),
    Value = "Default",
    Callback = function(v)
        customAnimWalk = v
    end
})

SectionCustomAnim:Dropdown({
    Title = "Run",
    Desc = "Animation for Run | Default = use your own character animation",
    Values = getAnimIdDropdownValues(),
    Value = "Default",
    Callback = function(v)
        customAnimRun = v
    end
})

SectionCustomAnim:Dropdown({
    Title = "Jump",
    Desc = "Animation for Jump | Default = use your own character animation",
    Values = getAnimIdDropdownValues(),
    Value = "Default",
    Callback = function(v)
        customAnimJump = v
    end
})

SectionCustomAnim:Dropdown({
    Title = "Climb",
    Desc = "Animation for Climb | Default = use your own character animation",
    Values = getAnimIdDropdownValues(),
    Value = "Default",
    Callback = function(v)
        customAnimClimb = v
    end
})

SectionCustomAnim:Dropdown({
    Title = "Fall",
    Desc = "Animation for Fall | Default = use your own character animation",
    Values = getAnimIdDropdownValues(),
    Value = "Default",
    Callback = function(v)
        customAnimFall = v
    end
})

SectionCustomAnim:Dropdown({
    Title = "Swim",
    Desc = "Animation for Swim | Default = use your own character animation",
    Values = getAnimIdDropdownValues(),
    Value = "Default",
    Callback = function(v)
        customAnimSwim = v
    end
})

SectionCustomAnim:Dropdown({
    Title = "Swim Idle",
    Desc = "Animation for Swim Idle | Default = use your own character animation",
    Values = getAnimIdDropdownValues(),
    Value = "Default",
    Callback = function(v)
        customAnimSwimIdle = v
    end
})

local HStackCustomAnimSave = SectionCustomAnim:HStack({ AutoSpace = true })
HStackCustomAnimSave:Button({
    Title = "Save",
    Icon = "save",
    Callback = function()
        if customAnimPackNameValue == "" then
            WindUI:Notify({ Title = "Error", Content = "Please enter a pack name!", Duration = 2, Icon = "alert-circle" }) return
        end
        customAnimPacks[customAnimPackNameValue] = {
            Idle     = customAnimIdle,
            Idle2    = customAnimIdle2,
            Walk     = customAnimWalk,
            Run      = customAnimRun,
            Jump     = customAnimJump,
            Climb    = customAnimClimb,
            Fall     = customAnimFall,
            Swim     = customAnimSwim,
            SwimIdle = customAnimSwimIdle,
        }
        saveCustomAnimPacks()
        refreshCustomAnimGui()
        WindUI:Notify({ Title = "Custom Animations", Content = "Pack '" .. customAnimPackNameValue .. "' saved!", Duration = 2, Icon = "save" })
    end
})
HStackCustomAnimSave:Button({
    Title = "Refresh",
    Icon = "refresh-cw",
    Callback = function()
        refreshCustomAnimGui()
        WindUI:Notify({ Title = "Custom Animations", Content = "Pack list refreshed.", Duration = 2, Icon = "refresh-cw" })
    end
})
HStackCustomAnimSave:Button({
    Title = "Delete",
    Icon = "trash",
    Callback = function()
        if selectedCustomAnimPack == "" or not customAnimPacks[selectedCustomAnimPack] then
            WindUI:Notify({ Title = "Error", Content = "Please select a pack first!", Duration = 2, Icon = "alert-circle" }) return
        end
        customAnimPacks[selectedCustomAnimPack] = nil
        selectedCustomAnimPack = ""
        saveCustomAnimPacks()
        refreshCustomAnimGui()
        WindUI:Notify({ Title = "Custom Animations", Content = "Pack deleted.", Duration = 2, Icon = "trash" })
    end
})

SectionCustomAnim:Divider()

local HStackCustomAnimApply = SectionCustomAnim:HStack({ AutoSpace = true })
HStackCustomAnimApply:Button({
    Title = "Apply",
    Icon = "check",
    Callback = function()
        if selectedCustomAnimPack == "" or not customAnimPacks[selectedCustomAnimPack] then
            WindUI:Notify({ Title = "Error", Content = "Please select a custom pack first!", Duration = 2, Icon = "alert-circle" }) return
        end
        applyCustomAnimPack(selectedCustomAnimPack)
        WindUI:Notify({ Title = "Custom Animations", Content = "Pack '" .. selectedCustomAnimPack .. "' applied!", Duration = 2, Icon = "check" })
    end
})
HStackCustomAnimApply:Button({
    Title = "Stop",
    Icon = "refresh-cw",
    Callback = function()
        resetAnimation()
        WindUI:Notify({ Title = "Custom Animations", Content = "Animation reset to default.", Duration = 2, Icon = "refresh-cw" })
    end
})

-- ===================== R6 EMOTE DATA (shared by Emote dropdown + QuickEmotes R6 tab) =====================
local R6EmoteList = {
    { Title = "Head Throw",      Id = 35154961   },
    { Title = "Floating Head",   Id = 121572214  },
    { Title = "Crouch",          Id = 182724289  },
    { Title = "Floor Crawl",     Id = 282574440  },
    { Title = "Dino Walk",       Id = 204328711  },
    { Title = "Jumping Jacks",   Id = 429681631  },
    { Title = "Loop Head",       Id = 35154961   },
    { Title = "Hero Jump",       Id = 184574340  },
    { Title = "Faint",           Id = 181526230  },
    { Title = "Floor Faint",     Id = 181525546  },
    { Title = "Super Faint",     Id = 181525546  },
    { Title = "Levitate",        Id = 313762630  },
    { Title = "Dab",             Id = 183412246  },
    { Title = "Spinner",         Id = 188632011  },
    { Title = "Float Sit",       Id = 179224234  },
    { Title = "Moving Dance",    Id = 429703734  },
    { Title = "Weird Move",      Id = 215384594  },
    { Title = "Clone Illusion",  Id = 215384594  },
    { Title = "Glitch Levitate", Id = 313762630  },
    { Title = "Spin Dance",      Id = 429730430  },
    { Title = "Moon Dance",      Id = 45834924   },
    { Title = "Full Punch",      Id = 204062532  },
    { Title = "Spin Dance 2",    Id = 186934910  },
    { Title = "Bow Down",        Id = 204292303  },
    { Title = "Sword Slam",      Id = 204295235  },
    { Title = "Loop Slam",       Id = 204295235  },
    { Title = "Mega Insane",     Id = 184574340  },
    { Title = "Super Punch",     Id = 126753849  },
    { Title = "Full Swing",      Id = 218504594  },
    { Title = "Arm Turbine",     Id = 259438880  },
    { Title = "Barrel Roll",     Id = 136801964  },
    { Title = "Scared",          Id = 180612465  },
    { Title = "Insane",          Id = 33796059   },
    { Title = "Arm Detach",      Id = 33169583   },
    { Title = "Sword Slice",     Id = 35978879   },
    { Title = "Insane Arms",     Id = 27432691   },
}
table.sort(R6EmoteList, function(a,b) return a.Title:lower() < b.Title:lower() end)

local function getR6EmoteData(title)
    for _, v in ipairs(R6EmoteList) do
        if v.Title == title then return v end
    end
    return nil
end

local SectionEmote = TabAnimations:Section({ Title = "Emote", Icon = "drama", Opened = true })

local emoteSearchValue = ""
SectionEmote:Input({
    Title = "Search", Desc = "Search for an emote by name", Placeholder = "Dance", Value = "",
    Callback = function(v) emoteSearchValue = v end
})

local selectedEmoteRig = "R15"

local function getActiveEmoteList()
    if selectedEmoteRig == "R6" then return R6EmoteList end
    return FullEmoteList
end

local function getActiveEmoteData(title)
    if selectedEmoteRig == "R6" then return getR6EmoteData(title) end
    return getEmoteData(title)
end

SectionEmote:Dropdown({
    Title = "Rig Type", Desc = "Choose which emote list to use (R15 or R6)",
    Values = { "R15", "R6" }, Value = "R15",
    Callback = function(v)
        selectedEmoteRig = v
        emoteSearchValue = "" emoteSearchResults = getActiveEmoteList() emotePage = 1 refreshEmoteDropdown()
    end
})

SectionEmote:Divider()

local emoteDropdown
local emotePageParagraph

local function refreshEmoteDropdown()
    local totalPages = getTotalEmotePages(emoteSearchResults)
    emotePage = math.clamp(emotePage, 1, totalPages)
    emoteDropdown:Refresh(getEmotePage(emoteSearchResults, emotePage))
    emotePageParagraph:SetTitle("Emote Pages")
    emotePageParagraph:SetDesc("page " .. emotePage .. " / " .. totalPages .. " | Hasil: " .. #emoteSearchResults .. " emote")
    selectedEmote = nil
end

local HStackEmoteSearch = SectionEmote:HStack({ AutoSpace = true })
HStackEmoteSearch:Button({
    Title = "Search", Icon = "search",
    Callback = function()
        emoteSearchResults = filterEmoteListBy(getActiveEmoteList(), emoteSearchValue)
        emotePage = 1 refreshEmoteDropdown()
        if #emoteSearchResults == 0 then
            WindUI:Notify({ Title = "Emote", Content = "No emotes found matching" .. emoteSearchValue .. "'", Duration = 2, Icon = "alert-circle" })
        else
            WindUI:Notify({ Title = "Emote", Content = "Found" .. #emoteSearchResults .. " emote", Duration = 2, Icon = "search" })
        end
    end
})
HStackEmoteSearch:Button({
    Title = "Reset", Icon = "refresh-cw",
    Callback = function()
        emoteSearchValue = "" emoteSearchResults = getActiveEmoteList() emotePage = 1 refreshEmoteDropdown()
        WindUI:Notify({ Title = "Emote", Content = "Showing all available emotes", Duration = 2, Icon = "refresh-cw" })
    end
})

SectionEmote:Divider()

emotePageParagraph = SectionEmote:Paragraph({
    Title = "Emote Page",
    Desc = "page of 1 / " .. getTotalEmotePages(FullEmoteList) .. " | Total: " .. #FullEmoteList .. " emote",
    Icon = "list",
})

emoteDropdown = SectionEmote:Dropdown({
    Title = "Emote List", Desc = "Pick an emote to play on your character",
    Values = getEmotePage(FullEmoteList, 1), Value = "",
    Callback = function(v) selectedEmote = v end
})

local HStackEmoteNav = SectionEmote:HStack({ AutoSpace = true })
HStackEmoteNav:Button({
    Title = "< Previous",
    Callback = function()
        if emotePage <= 1 then
            WindUI:Notify({ Title = "Emote", Content = "You are already on the first page!", Duration = 2, Icon = "alert-circle" }) return
        end
        emotePage = emotePage - 1 refreshEmoteDropdown()
        WindUI:Notify({ Title = "Emote", Content = "Switched to page " .. emotePage, Duration = 1, Icon = "chevron-left" })
    end
})
HStackEmoteNav:Button({
    Title = "Next >",
    Callback = function()
        if emotePage >= getTotalEmotePages(emoteSearchResults) then
            WindUI:Notify({ Title = "Emote", Content = "You are already on the last page!", Duration = 2, Icon = "alert-circle" }) return
        end
        emotePage = emotePage + 1 refreshEmoteDropdown()
        WindUI:Notify({ Title = "Emote", Content = "Switched to page " .. emotePage, Duration = 1, Icon = "chevron-right" })
    end
})

SectionEmote:Divider()

local HStackEmotePlay = SectionEmote:HStack({ AutoSpace = true })
HStackEmotePlay:Button({
    Title = "Apply", Icon = "play",
    Callback = function()
        if not selectedEmote or selectedEmote == "" then
            WindUI:Notify({ Title = "Error", Content = "Please select an emote first!", Duration = 2, Icon = "alert-circle" }) return
        end
        local data = getActiveEmoteData(selectedEmote)
        if not data then
            WindUI:Notify({ Title = "Error", Content = "The selected emote could not be found!", Duration = 2, Icon = "alert-circle" }) return
        end
        playEmote(data, emoteLoopEnabled, emoteWalkEnabled)
        WindUI:Notify({ Title = "Emote", Content = "Now playing: '" .. selectedEmote .. "'", Duration = 2, Icon = "play" })
    end
})
HStackEmotePlay:Button({
    Title = "Stop", Icon = "square",
    Callback = function()
        stopEmote()
        WindUI:Notify({ Title = "Emote", Content = "Emote has been stopped", Duration = 2, Icon = "square" })
    end
})

SectionEmote:Toggle({
    Title = "Loop", Desc = "Keep playing the emote on repeat", Icon = "repeat", Value = true,
    Callback = function(state)
        emoteLoopEnabled = state
        if currentEmoteTrack then currentEmoteTrack.Looped = state end
    end
})

SectionEmote:Toggle({
    Title = "Walking Animation", Desc = "Continue emote while walking around", Icon = "footprints", Value = false,
    Callback = function(state) emoteWalkEnabled = state end
})

local SectionMoreAnim = TabAnimations:Section({ Title = "Custom Emote", Icon = "smile-plus", Opened = true })

SectionMoreAnim:Input({
    Title = "Emote Name", Desc = "Give your custom emote a name", Placeholder = "My Emote", Value = "",
    Callback = function(v) customEmoteNameValue = v end
})
SectionMoreAnim:Input({
    Title = "Animation ID", Desc = "Animation ID emote Roblox", Placeholder = "507770818", Value = "",
    Callback = function(v) customEmoteAnimIdValue = v end
})

local customEmoteDropdown

local function buildCustomEmoteNames()
    local names = {}
    for name in pairs(customEmotes) do table.insert(names, name) end
    table.sort(names, function(a,b) return a:lower() < b:lower() end)
    return names
end

customEmoteDropdown = SectionMoreAnim:Dropdown({
    Title = "Custom Emote List", Desc = "Pick an custom emote to play on your character",
    Values = buildCustomEmoteNames(), Value = "",
    Callback = function(v) selectedCustomEmote = v end
})

local HStackCustomBtn = SectionMoreAnim:HStack({ AutoSpace = true })
HStackCustomBtn:Button({
    Title = "Save", Icon = "save",
    Callback = function()
        if customEmoteNameValue == "" then
            WindUI:Notify({ Title = "Error", Content = "Please enter a name for the emote!", Duration = 2, Icon = "alert-circle" }) return
        end
        local id = tonumber(customEmoteAnimIdValue)
        if not id then
            WindUI:Notify({ Title = "Error", Content = "Animation ID must be a valid number!", Duration = 2, Icon = "alert-circle" }) return
        end
        customEmotes[customEmoteNameValue] = id
        saveCustomEmotes() customEmoteDropdown:Refresh(buildCustomEmoteNames())
        WindUI:Notify({ Title = "Custom Emote", Content = "Emote '" .. customEmoteNameValue .. "' has been saved!", Duration = 2, Icon = "save" })
    end
})
HStackCustomBtn:Button({
    Title = "Refresh", Icon = "refresh-cw",
    Callback = function()
        customEmoteDropdown:Refresh(buildCustomEmoteNames())
        WindUI:Notify({ Title = "Custom Emote", Content = "Custom emote list has been refreshed.", Duration = 2, Icon = "refresh-cw" })
    end
})
HStackCustomBtn:Button({
    Title = "Delete", Icon = "trash",
    Callback = function()
        if not selectedCustomEmote or not customEmotes[selectedCustomEmote] then
            WindUI:Notify({ Title = "Error", Content = "Please select a custom emote first!", Duration = 2, Icon = "alert-circle" }) return
        end
        customEmotes[selectedCustomEmote] = nil selectedCustomEmote = nil
        saveCustomEmotes() customEmoteDropdown:Refresh(buildCustomEmoteNames())
        WindUI:Notify({ Title = "Custom Emote", Content = "Custom emote has been deleted.", Duration = 2, Icon = "trash" })
    end
})

SectionMoreAnim:Divider()

local HStackCustomPlay = SectionMoreAnim:HStack({ AutoSpace = true })
HStackCustomPlay:Button({
    Title = "Apply", Icon = "play",
    Callback = function()
        if not selectedCustomEmote or not customEmotes[selectedCustomEmote] then
            WindUI:Notify({ Title = "Error", Content = "Please select a custom emote first!", Duration = 2, Icon = "alert-circle" }) return
        end
        playEmote({ Title = selectedCustomEmote, Id = customEmotes[selectedCustomEmote] }, customEmoteLoopEnabled, customEmoteWalkEnabled)
        WindUI:Notify({ Title = "Custom Emote", Content = "Now playing: '" .. selectedCustomEmote .. "'", Duration = 2, Icon = "play" })
    end
})
HStackCustomPlay:Button({
    Title = "Stop", Icon = "square",
    Callback = function()
        stopEmote()
        WindUI:Notify({ Title = "Custom Emote", Content = "Custom emote has been stopped.", Duration = 2, Icon = "square" })
    end
})

SectionMoreAnim:Toggle({
    Title = "Loop", Desc = "Keep playing the custom emote on repeat", Icon = "repeat", Value = true,
    Callback = function(state)
        customEmoteLoopEnabled = state
        if currentEmoteTrack then currentEmoteTrack.Looped = state end
    end
})

SectionMoreAnim:Toggle({
    Title = "Walking Animation", Desc = "Continue custom emote while walking around", Icon = "footprints", Value = false,
    Callback = function(state) customEmoteWalkEnabled = state end
})

-- TAB: TELEPORT
local TabTeleport = Window:Tab({ Title = "Teleport", Icon = "map-pin" })

local selectedPlayer = nil
local selectedPlace  = nil
local savedPlaces    = {}
local savedPlacesOrder = {}
local savedPlacesCount = 0
local playerList     = {}

local function getPlayerNames()
    local names = {} playerList = {}
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer then
            table.insert(names, p.DisplayName)
            playerList[p.DisplayName] = p.Name
        end
    end
    return names
end

local SectionTpPlayer = TabTeleport:Section({ Title = "Player", Icon = "users", Opened = true })

local playerDropdown = SectionTpPlayer:Dropdown({
    Title = "Choice Player", Desc = "Select a player as your target",
    Values = getPlayerNames(), Value = "", SearchBarEnabled = true,
    Callback = function(v) selectedPlayer = v end
})

local HStackTpPlayer = SectionTpPlayer:HStack({ AutoSpace = true })
HStackTpPlayer:Button({
    Title = "Refresh", Icon = "refresh-cw",
    Callback = function()
        playerDropdown:Refresh(getPlayerNames())
    end
})
HStackTpPlayer:Button({
    Title = "Teleport", Icon = "map-pin",
    Callback = function()
        if not selectedPlayer then
            WindUI:Notify({ Title = "Error", Content = "Please select a target first!", Duration = 2, Icon = "alert-circle" }) return
        end
        local username = playerList[selectedPlayer]
        local target = Players:FindFirstChild(username)
        if target and target.Character and target.Character:FindFirstChild("HumanoidRootPart") then
            local hrp = getHRP()
            if hrp then
                hrp.CFrame = target.Character.HumanoidRootPart.CFrame + Vector3.new(3, 0, 0)
                WindUI:Notify({ Title = "Teleport", Content = "Teleport to " .. selectedPlayer, Duration = 2, Icon = "map-pin" })
            end
        else
            WindUI:Notify({ Title = "Error", Content = "Target could not be found!", Duration = 2, Icon = "alert-circle" })
        end
    end
})

local SectionTpPlace = TabTeleport:Section({ Title = "Place", Icon = "map", Opened = true })

local placeNameInputValue = ""

local placeDropdown = SectionTpPlace:Dropdown({
    Title = "Choice Place", Desc = "Select a saved location to teleport",
    Values = {}, Value = "",
    Callback = function(v) selectedPlace = v end
})

SectionTpPlace:Input({
    Title = "Place Name", Desc = "Name this location (leave empty for auto-name)",
    Placeholder = "Place Name...", Value = "",
    Callback = function(v) placeNameInputValue = v end
})

local function getOrderedPlaceKeys()
    local keys = {}
    for _, k in ipairs(savedPlacesOrder) do
        if savedPlaces[k] then table.insert(keys, k) end
    end
    return keys
end

local HStackTpPlace = SectionTpPlace:HStack({ AutoSpace = true })
HStackTpPlace:Button({
    Title = "Save", Icon = "save",
    Callback = function()
        local hrp = getHRP()
        if not hrp then
            WindUI:Notify({ Title = "Error", Content = "Your character could not be found!", Duration = 2, Icon = "alert-circle" }) return
        end
        savedPlacesCount = savedPlacesCount + 1
        local name = (placeNameInputValue ~= "" and placeNameInputValue) or ("Place " .. savedPlacesCount)
        if savedPlaces[name] then name = name .. " (" .. savedPlacesCount .. ")" end
        savedPlaces[name] = hrp.CFrame
        table.insert(savedPlacesOrder, name)
        placeDropdown:Refresh(getOrderedPlaceKeys())
        WindUI:Notify({ Title = "Save", Content = "Saved place: " .. name, Duration = 2, Icon = "save" })
    end
})
HStackTpPlace:Button({
    Title = "Refresh", Icon = "refresh-cw",
    Callback = function()
        placeDropdown:Refresh(getOrderedPlaceKeys())
    end
})
HStackTpPlace:Button({
    Title = "Delete", Icon = "trash",
    Callback = function()
        if selectedPlace and savedPlaces[selectedPlace] then
            savedPlaces[selectedPlace] = nil
            for i, k in ipairs(savedPlacesOrder) do
                if k == selectedPlace then table.remove(savedPlacesOrder, i) break end
            end
            placeDropdown:Refresh(getOrderedPlaceKeys()) selectedPlace = nil
            WindUI:Notify({ Title = "Delete", Content = "Saved place has been deleted.", Duration = 2, Icon = "trash" })
        else
            WindUI:Notify({ Title = "Error", Content = "Please select a place first!", Duration = 2, Icon = "alert-circle" })
        end
    end
})

SectionTpPlace:Divider()

SectionTpPlace:Button({
    Title = "Teleport to Place", Desc = "Teleport to the selected saved location", Icon = "map-pin",
    Callback = function()
        if not selectedPlace or not savedPlaces[selectedPlace] then
            WindUI:Notify({ Title = "Error", Content = "Pilih tempat dulu!", Duration = 2, Icon = "alert-circle" }) return
        end
        local hrp = getHRP()
        if hrp then
            hrp.CFrame = savedPlaces[selectedPlace]
            WindUI:Notify({ Title = "Teleport", Content = "Teleport to " .. selectedPlace, Duration = 2, Icon = "map-pin" })
        else
            WindUI:Notify({ Title = "Error", Content = "Your character could not be found!", Duration = 2, Icon = "alert-circle" })
        end
    end
})

-- TAB: VISUALS
local TabVisuals = Window:Tab({ Title = "Visuals", Icon = "eye" })

local espSettings = { Enabled = false, Box = false, Name = false, Health = false, Distance = false, Tracer = false, Highlight = false }
local espObjects = {}
local camera = workspace.CurrentCamera

local function newDrawing(type_, props)
    local d = Drawing.new(type_)
    for k, v in pairs(props) do d[k] = v end
    return d
end

local function removeESPFor(name)
    if not espObjects[name] then return end
    local t = espObjects[name]
    for _, d in pairs(t.drawings or {}) do pcall(function() d:Remove() end) end
    if t.highlight then pcall(function() t.highlight:Destroy() end) end
    espObjects[name] = nil
end

local function clearAllESP()
    for name in pairs(espObjects) do removeESPFor(name) end
end

local function createESPFor(p)
    if p == LocalPlayer then return end
    removeESPFor(p.Name)
    local drawings = {} local box = {}
    for i = 1, 4 do
        box[i] = newDrawing("Line", { Color = Color3.fromRGB(255,50,50), Thickness = 1.5, Visible = false, ZIndex = 2 })
        table.insert(drawings, box[i])
    end
    local nameText   = newDrawing("Text", { Color = Color3.fromRGB(255,255,255), Size = 13, Center = true, Outline = true, OutlineColor = Color3.fromRGB(0,0,0), Visible = false, ZIndex = 3 })
    local distText   = newDrawing("Text", { Color = Color3.fromRGB(200,200,200), Size = 12, Center = true, Outline = true, OutlineColor = Color3.fromRGB(0,0,0), Visible = false, ZIndex = 3 })
    local healthBg   = newDrawing("Line", { Color = Color3.fromRGB(0,0,0), Thickness = 4, Visible = false, ZIndex = 3 })
    local healthBar  = newDrawing("Line", { Color = Color3.fromRGB(0,255,0), Thickness = 3, Visible = false, ZIndex = 4 })
    local healthText = newDrawing("Text", { Color = Color3.fromRGB(255,255,255), Size = 11, Center = true, Outline = true, OutlineColor = Color3.fromRGB(0,0,0), Visible = false, ZIndex = 5 })
    local tracer     = newDrawing("Line", { Color = Color3.fromRGB(255,50,50), Thickness = 1, Visible = false, ZIndex = 1 })
    for _, d in ipairs({nameText,distText,healthBg,healthBar,healthText,tracer}) do table.insert(drawings, d) end
    espObjects[p.Name] = {
        drawings = drawings, box = box,
        nameText = nameText, distText = distText,
        healthBg = healthBg, healthBar = healthBar, healthText = healthText,
        tracer = tracer, highlight = nil, player = p,
    }
end

local function updateESPHighlight(p, enable)
    local e = espObjects[p.Name]
    if not e then return end
    if enable then
        if not e.highlight then
            local chr = p.Character
            if chr then
                local hl = Instance.new("Highlight", chr)
                hl.FillColor = Color3.fromRGB(255,50,50)
                hl.OutlineColor = Color3.fromRGB(255,255,255)
                hl.FillTransparency = 0.6 hl.OutlineTransparency = 0 e.highlight = hl
            end
        end
    else
        if e.highlight then pcall(function() e.highlight:Destroy() end) e.highlight = nil end
    end
end

RunService.RenderStepped:Connect(function()
    if not espSettings.Enabled then
        for _, e in pairs(espObjects) do for _, d in pairs(e.drawings or {}) do d.Visible = false end end
        return
    end
    local vpSize = camera.ViewportSize
    for _, p in ipairs(Players:GetPlayers()) do
        if p == LocalPlayer then continue end
        local e = espObjects[p.Name]
        if not e then continue end
        local chr = p.Character
        local hrp = chr and chr:FindFirstChild("HumanoidRootPart")
        local hum = chr and chr:FindFirstChildWhichIsA("Humanoid")
        if not hrp or not hum then for _, d in pairs(e.drawings) do d.Visible = false end continue end
        local headScreen, headVis = camera:WorldToViewportPoint(hrp.Position + Vector3.new(0,3,0))
        local feetScreen, feetVis = camera:WorldToViewportPoint(hrp.Position - Vector3.new(0,3,0))
        if not headVis or not feetVis then for _, d in pairs(e.drawings) do d.Visible = false end continue end
        local h = math.abs(headScreen.Y - feetScreen.Y)
        local w = h * 0.5
        local cx = (headScreen.X + feetScreen.X) / 2
        local top = math.min(headScreen.Y, feetScreen.Y)
        local bot = math.max(headScreen.Y, feetScreen.Y)
        local left = cx - w/2 local right = cx + w/2
        e.box[1].From=Vector2.new(left,top)  e.box[1].To=Vector2.new(right,top) e.box[1].Visible=espSettings.Box
        e.box[2].From=Vector2.new(left,bot)  e.box[2].To=Vector2.new(right,bot) e.box[2].Visible=espSettings.Box
        e.box[3].From=Vector2.new(left,top)  e.box[3].To=Vector2.new(left,bot)  e.box[3].Visible=espSettings.Box
        e.box[4].From=Vector2.new(right,top) e.box[4].To=Vector2.new(right,bot) e.box[4].Visible=espSettings.Box
        e.nameText.Position=Vector2.new(cx,top-15) e.nameText.Text=p.DisplayName e.nameText.Visible=espSettings.Name
        local myHRP = getHRP()
        local dist = myHRP and math.floor((hrp.Position-myHRP.Position).Magnitude) or 0
        e.distText.Position=Vector2.new(cx,bot+3) e.distText.Text=dist.."m" e.distText.Visible=espSettings.Distance
        local hpRatio = math.clamp(hum.Health/math.max(hum.MaxHealth,1),0,1)
        local barX = left-6
        local barFillBot = bot-((bot-top)*hpRatio)
        e.healthBg.From=Vector2.new(barX,top) e.healthBg.To=Vector2.new(barX,bot) e.healthBg.Visible=espSettings.Health
        e.healthBar.Color=Color3.fromRGB(math.floor(255*(1-hpRatio)),math.floor(255*hpRatio),0)
        e.healthBar.From=Vector2.new(barX,barFillBot) e.healthBar.To=Vector2.new(barX,bot) e.healthBar.Visible=espSettings.Health
        e.healthText.Position=Vector2.new(barX-8,(top+bot)/2-5) e.healthText.Text=math.floor(hpRatio*100).."%"  e.healthText.Visible=espSettings.Health
        e.tracer.From=Vector2.new(vpSize.X/2,vpSize.Y) e.tracer.To=Vector2.new(cx,bot) e.tracer.Visible=espSettings.Tracer
        updateESPHighlight(p,espSettings.Highlight)
    end
end)

Players.PlayerAdded:Connect(function(p)
    if espSettings.Enabled then createESPFor(p) end
    p.CharacterAdded:Connect(function()
        if espSettings.Enabled then task.wait(1) updateESPHighlight(p,espSettings.Highlight) end
    end)
end)
Players.PlayerRemoving:Connect(function(p) removeESPFor(p.Name) end)

local function refreshAllESP()
    clearAllESP()
    if espSettings.Enabled then
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= LocalPlayer then createESPFor(p) updateESPHighlight(p,espSettings.Highlight) end
        end
    end
end

local SectionESP = TabVisuals:Section({ Title = "ESP", Icon = "scan", Opened = true })
SectionESP:Toggle({ Title = "ESP",           Desc = "Turn all ESP features on or off",       Icon = "scan",        Value = false, Callback = function(v) espSettings.Enabled=v refreshAllESP() end })
SectionESP:Toggle({ Title = "ESP Box",       Desc = "Draw a box outline around each player",           Icon = "square",      Value = false, Callback = function(v) espSettings.Box=v end })
SectionESP:Toggle({ Title = "ESP Name",      Desc = "Show each player's display name",             Icon = "user",        Value = false, Callback = function(v) espSettings.Name=v end })
SectionESP:Toggle({ Title = "ESP Health",    Desc = "Show a health bar for each player",       Icon = "heart",       Value = false, Callback = function(v) espSettings.Health=v end })
SectionESP:Toggle({ Title = "ESP Distance",  Desc = "Show how far away each player is",         Icon = "ruler",       Value = false, Callback = function(v) espSettings.Distance=v end })
SectionESP:Toggle({ Title = "ESP Tracer",    Desc = "Draw a line from screen bottom to each player",  Icon = "navigation",  Value = false, Callback = function(v) espSettings.Tracer=v end })
SectionESP:Toggle({ Title = "ESP Highlight", Desc = "Add a glowing highlight around each player",         Icon = "highlighter", Value = false, Callback = function(v)
    espSettings.Highlight=v
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer then updateESPHighlight(p,v) end
    end
end })

-- ===================== FREECAM V4 (Fixed) =====================
-- Fixes from V3: joystick was unresponsive (extra invisible touch-zone caused input
-- conflicts), forward/back was mapped to world up/down instead of camera direction,
-- and the Lock button wasn't reliably clickable. V4 removes the invisible zone,
-- maps the joystick the same way the Fly system does (movement follows full camera
-- direction, including pitch, so looking up + pushing forward also lifts you up),
-- and gives the Lock button its own clear hit area with no overlapping frames.
local freecamEnabled = false
local freecamLocked = false
local freecamSpeed = 20
local freecamJoystickVec = Vector3.zero -- X = strafe, Y = forward/back (screen-space joystick axes)

local FreecamGui = Instance.new("ScreenGui")
FreecamGui.Name = "FreecamUI"
FreecamGui.ResetOnSpawn = false
FreecamGui.Enabled = false
FreecamGui.IgnoreGuiInset = true

local fcGuiOk, _ = pcall(function() FreecamGui.Parent = CoreGui end)
if not fcGuiOk then FreecamGui.Parent = LocalPlayer:WaitForChild("PlayerGui") end
hideFromRecording(FreecamGui)

local FCJoystickOuter = Instance.new("Frame", FreecamGui)
FCJoystickOuter.Name = "JoystickOuter"
FCJoystickOuter.Size = UDim2.new(0, 120, 0, 120)
FCJoystickOuter.Position = UDim2.new(0, 25, 1, -155)
FCJoystickOuter.BackgroundColor3 = Color3.fromRGB(30, 30, 38)
FCJoystickOuter.BackgroundTransparency = 0.3
FCJoystickOuter.BorderSizePixel = 0
FCJoystickOuter.ZIndex = 60
FCJoystickOuter.Active = true
local FCJoystickOuterCorner = Instance.new("UICorner", FCJoystickOuter)
FCJoystickOuterCorner.CornerRadius = UDim.new(1, 0)

local FCJoystickKnob = Instance.new("Frame", FCJoystickOuter)
FCJoystickKnob.Name = "JoystickKnob"
FCJoystickKnob.Size = UDim2.new(0, 48, 0, 48)
FCJoystickKnob.Position = UDim2.new(0.5, -24, 0.5, -24)
FCJoystickKnob.BackgroundColor3 = Color3.fromRGB(80, 60, 200)
FCJoystickKnob.BorderSizePixel = 0
FCJoystickKnob.ZIndex = 61
local FCJoystickKnobCorner = Instance.new("UICorner", FCJoystickKnob)
FCJoystickKnobCorner.CornerRadius = UDim.new(1, 0)

local fcJoystickActive = false
local fcJoystickInputObj = nil
local fcJoystickCenter = Vector2.zero
local fcJoystickRadius = 60

local function fcUpdateJoystick(inputPos)
    local delta = Vector2.new(inputPos.X, inputPos.Y) - fcJoystickCenter
    local dist = math.min(delta.Magnitude, fcJoystickRadius)
    local clamped = (delta.Magnitude > 0) and (delta.Unit * dist) or Vector2.zero
    FCJoystickKnob.Position = UDim2.new(0.5, clamped.X - 24, 0.5, clamped.Y - 24)
    -- Screen-up (negative Y) should mean "forward", so flip the sign here.
    freecamJoystickVec = Vector3.new(clamped.X / fcJoystickRadius, 0, -clamped.Y / fcJoystickRadius)
end

local function fcResetJoystick()
    fcJoystickActive = false
    fcJoystickInputObj = nil
    FCJoystickKnob.Position = UDim2.new(0.5, -24, 0.5, -24)
    freecamJoystickVec = Vector3.zero
end

local function fcBeginJoystick(input)
    fcJoystickActive = true
    fcJoystickInputObj = input
    local absPos = FCJoystickOuter.AbsolutePosition
    local absSize = FCJoystickOuter.AbsoluteSize
    fcJoystickCenter = Vector2.new(absPos.X + absSize.X / 2, absPos.Y + absSize.Y / 2)
    fcUpdateJoystick(input.Position)
end

FCJoystickOuter.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        fcBeginJoystick(input)
    end
end)

-- Listen globally for movement/release so the knob keeps tracking even if the
-- finger/mouse drifts outside the small outer ring - this is what makes the
-- joystick feel responsive instead of "sticky".
UserInputService.InputChanged:Connect(function(input)
    if fcJoystickActive and input == fcJoystickInputObj then
        fcUpdateJoystick(input.Position)
    end
end)
UserInputService.InputEnded:Connect(function(input)
    if fcJoystickActive and input == fcJoystickInputObj then
        fcResetJoystick()
    end
end)

-- Lock Camera button: own dedicated hit area, far enough from the joystick that
-- there is no overlap, so clicks/taps always register.
local FCLockBtn = Instance.new("TextButton", FreecamGui)
FCLockBtn.Name = "LockCameraBtn"
FCLockBtn.Size = UDim2.new(0, 70, 0, 70)
FCLockBtn.Position = UDim2.new(1, -90, 1, -155)
FCLockBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 38)
FCLockBtn.BackgroundTransparency = 0.3
FCLockBtn.Text = "LOCK"
FCLockBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
FCLockBtn.Font = Enum.Font.GothamBold
FCLockBtn.TextSize = 14
FCLockBtn.AutoButtonColor = false
FCLockBtn.BorderSizePixel = 0
FCLockBtn.ZIndex = 60
FCLockBtn.Active = true
local FCLockBtnCorner = Instance.new("UICorner", FCLockBtn)
FCLockBtnCorner.CornerRadius = UDim.new(1, 0)

local function fcSetLocked(state)
    freecamLocked = state
    if state then
        FCLockBtn.BackgroundColor3 = Color3.fromRGB(120, 60, 220)
        FCLockBtn.Text = "LOCKED"
        FCJoystickOuter.Visible = false
        fcResetJoystick()
        local cam = workspace.CurrentCamera
        if cam then cam.CameraType = Enum.CameraType.Custom end
        local hrp = getHRP()
        if hrp then
            local av = hrp:FindFirstChild("FreecamAnchor")
            if av then av:Destroy() end
        end
        local hum = getHum()
        if hum then
            hum.PlatformStand = false
            forceJumpStateFix()
        end
    else
        FCLockBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 38)
        FCLockBtn.Text = "LOCK"
        FCJoystickOuter.Visible = true
        local cam = workspace.CurrentCamera
        if cam then cam.CameraType = Enum.CameraType.Scriptable end
    end
end

local function fcToggleLock()
    if not freecamEnabled then return end
    fcSetLocked(not freecamLocked)
end

FCLockBtn.MouseButton1Click:Connect(fcToggleLock)
FCLockBtn.TouchTap:Connect(fcToggleLock)

local function startFreecamV4()
    local cam = workspace.CurrentCamera
    if not cam then return end
    cam.CameraType = freecamLocked and Enum.CameraType.Custom or Enum.CameraType.Scriptable
    
    local camYaw, camPitch = 0, 0
    local cf = cam.CFrame
    camYaw = math.atan2(-cf.LookVector.X, -cf.LookVector.Z)
    camPitch = math.asin(cf.LookVector.Y)
    
    local swipeData = { touching = false, swipeX = 0, swipeY = 0, lastPos = Vector2.zero }
    
    local touchStartConn = UserInputService.TouchStarted:Connect(function(touch, gp)
        if not freecamEnabled or freecamLocked or gp then return end
        swipeData.touching = true
        swipeData.lastPos = touch.Position
        swipeData.swipeX = 0
        swipeData.swipeY = 0
    end)
    
    local touchMovedConn = UserInputService.TouchMoved:Connect(function(touch, gp)
        if not freecamEnabled or freecamLocked or not swipeData.touching or gp then return end
        local delta = touch.Position - swipeData.lastPos
        swipeData.swipeX = delta.X
        swipeData.swipeY = delta.Y
        swipeData.lastPos = touch.Position
    end)
    
    local touchEndConn = UserInputService.TouchEnded:Connect(function(touch, gp)
        swipeData.touching = false
        swipeData.swipeX = 0
        swipeData.swipeY = 0
    end)

    task.spawn(function()
        while freecamEnabled do
            RunService.RenderStepped:Wait()
            local dt = 0.016

            if freecamLocked then
                -- Locked: character is controllable with normal Roblox input, camera stays Custom.
                local hum = getHum()
                local hrp = getHRP()
                if hum and hrp then
                    hum.PlatformStand = false
                    local av = hrp:FindFirstChild("FreecamAnchor")
                    if av then av:Destroy() end
                end
            else
                local camCF = cam.CFrame
                local moveVec = Vector3.zero

                -- Keyboard (PC) support, same camera-relative behavior as the joystick
                if UserInputService:IsKeyDown(Enum.KeyCode.W) then moveVec = moveVec + camCF.LookVector end
                if UserInputService:IsKeyDown(Enum.KeyCode.S) then moveVec = moveVec - camCF.LookVector end
                if UserInputService:IsKeyDown(Enum.KeyCode.A) then moveVec = moveVec - camCF.RightVector end
                if UserInputService:IsKeyDown(Enum.KeyCode.D) then moveVec = moveVec + camCF.RightVector end

                -- Joystick: follows full camera direction (like Fly) so pushing "forward"
                -- while looking up also moves you up - no separate vertical axis needed.
                if freecamJoystickVec.Magnitude > 0.05 then
                    moveVec = moveVec + camCF.LookVector * freecamJoystickVec.Z
                    moveVec = moveVec + camCF.RightVector * freecamJoystickVec.X
                end

                if moveVec.Magnitude > 0 then
                    cam.CFrame = cam.CFrame + moveVec.Unit * freecamSpeed * dt
                end
                
                -- Swipe untuk rotate kamera (Mobile & PC)
                if swipeData.swipeX ~= 0 or swipeData.swipeY ~= 0 then
                    camYaw = camYaw - swipeData.swipeX * 0.008
                    camPitch = math.clamp(camPitch - swipeData.swipeY * 0.008, -math.pi/2 + 0.05, math.pi/2 - 0.05)
                    cam.CFrame = CFrame.new(cam.CFrame.Position) * CFrame.Angles(0, camYaw, 0) * CFrame.Angles(camPitch, 0, 0)
                end

                local hum = getHum()
                local hrp = getHRP()
                if hum and hrp then
                    hum.PlatformStand = true
                    if not hrp:FindFirstChild("FreecamAnchor") then
                        local av = Instance.new("BodyVelocity", hrp)
                        av.Name = "FreecamAnchor"
                        av.MaxForce = Vector3.new(9e9, 9e9, 9e9)
                        av.Velocity = Vector3.zero
                    end
                end
            end
        end

        touchStartConn:Disconnect()
        touchMovedConn:Disconnect()
        touchEndConn:Disconnect()
        cam.CameraType = Enum.CameraType.Custom
        local hum2 = getHum()
        local hrp2 = getHRP()
        if hrp2 then
            local av2 = hrp2:FindFirstChild("FreecamAnchor")
            if av2 then av2:Destroy() end
        end
        if hum2 then
            hum2.PlatformStand = false
            forceJumpStateFix()
        end
        
        if mouseConnection then mouseConnection:Disconnect() end
    end)
    
    -- Mouse camera rotation handler untuk freecam
    if mouseConnection then mouseConnection:Disconnect() end
    mouseConnection = UserInputService.InputChanged:Connect(function(input)
        if not freecamEnabled or freecamCameraLocked then return end
        
        if input.UserInputType == Enum.UserInputType.MouseMovement then
            local currentMousePos = UserInputService:GetMouseLocation()
            local delta = currentMousePos - lastMousePos
            lastMousePos = currentMousePos
            
            local sensitivity = 0.005
            local yaw = -delta.X * sensitivity
            local pitch = -delta.Y * sensitivity
            
            local currentCFrame = cam.CFrame
            local rotated = currentCFrame * CFrame.Angles(pitch, yaw, 0)
            cam.CFrame = CFrame.new(rotated.Position, rotated.Position + rotated.LookVector)
        end
    end)
end

local SectionVisualMore = TabVisuals:Section({ Title = "World", Icon = "globe", Opened = true })

local freecamToggle = SectionVisualMore:Toggle({
    Title = "Freecam", Desc = "Joystick-flight camera (follows camera direction) with a lock button to switch back to normal character control", Icon = "video", Value = false,
    Callback = function(state)
        freecamEnabled = state
        FreecamLockGui.Enabled = state
        freecamCameraLocked = false
        UpdateFreecamLockColor()
        if state then
            freecamLocked = false
            fcSetLocked(false)
            FreecamGui.Enabled = true
            startFreecamV4()
        else
            FreecamGui.Enabled = false
            fcResetJoystick()
            local cam = workspace.CurrentCamera
            if cam then cam.CameraType = Enum.CameraType.Custom end
            local hrp = getHRP()
            if hrp then
                local av = hrp:FindFirstChild("FreecamAnchor")
                if av then av:Destroy() end
            end
            local hum = getHum()
            if hum then
                hum.PlatformStand = false
                forceJumpStateFix()
            end
        end
    end
})

SectionVisualMore:Slider({
    Title = "Freecam Speed", Desc = "Camera flight speed | Default: 20", Icon = "wind",
    Step = 1, Value = { Min = 1, Max = 200, Default = 20 }, IsTooltip = true, IsTextbox = true,
    Callback = function(v) freecamSpeed = v end
})

-- ===================== PERSISTENT SHIFTLOCK =====================
local shiftlockEnabled = false
local shiftlockDragEnabled = false
local shiftlockPosFile = "WindUI/PieHub/shiftlockPos.json"
local shiftlockDefaultPos = UDim2.new(0, 12, 0.5, -30)

pcall(function()
    if makefolder and not isfolder("WindUI") then makefolder("WindUI") end
    if makefolder and not isfolder("WindUI/PieHub") then makefolder("WindUI/PieHub") end
end)

local function saveShiftlockPos(pos)
    pcall(function()
        if writefile then
            writefile(shiftlockPosFile, HttpService:JSONEncode({
                XS = pos.X.Scale, XO = pos.X.Offset, YS = pos.Y.Scale, YO = pos.Y.Offset
            }))
        end
    end)
end

local function loadShiftlockPos()
    local ok, result = pcall(function()
        if readfile and isfile and isfile(shiftlockPosFile) then
            local data = HttpService:JSONDecode(readfile(shiftlockPosFile))
            if type(data) == "table" then
                return UDim2.new(data.XS or 0, data.XO or 12, data.YS or 0.5, data.YO or -30)
            end
        end
        return nil
    end)
    if ok and result then return result end
    return shiftlockDefaultPos
end

local ShiftlockGui = Instance.new("ScreenGui")
ShiftlockGui.Name = "ShiftlockUI"
ShiftlockGui.ResetOnSpawn = false
ShiftlockGui.Enabled = false

local slGuiOk, _ = pcall(function() ShiftlockGui.Parent = CoreGui end)
if not slGuiOk then ShiftlockGui.Parent = LocalPlayer:WaitForChild("PlayerGui") end
hideFromRecording(ShiftlockGui)

local ShiftlockBtn = Instance.new("TextButton", ShiftlockGui)
ShiftlockBtn.Name = "ShiftlockBtn"
ShiftlockBtn.Size = UDim2.new(0, 56, 0, 56)
ShiftlockBtn.Position = loadShiftlockPos()
ShiftlockBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 38)
ShiftlockBtn.BackgroundTransparency = 0.2
ShiftlockBtn.Text = "SL"
ShiftlockBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
ShiftlockBtn.Font = Enum.Font.GothamBold
ShiftlockBtn.TextSize = 16
ShiftlockBtn.AutoButtonColor = false
ShiftlockBtn.BorderSizePixel = 0
ShiftlockBtn.ZIndex = 60
local ShiftlockBtnCorner = Instance.new("UICorner", ShiftlockBtn)
ShiftlockBtnCorner.CornerRadius = UDim.new(1, 0)

local function applyShiftlock(state)
    local hum = getHum()
    pcall(function()
        if hum then
            hum.AutoRotate = not state
        end
        UserInputService.MouseBehavior = state and Enum.MouseBehavior.LockCenter or Enum.MouseBehavior.Default
        UserInputService.MouseIconEnabled = not state
    end)
    if state then
        ShiftlockBtn.BackgroundColor3 = Color3.fromRGB(120, 60, 220)
    else
        ShiftlockBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 38)
    end
end

-- Rotate the character to face the camera direction every frame while Shiftlock is on,
-- same behavior as the reference Speed/ShiftLock script.
RunService.RenderStepped:Connect(function()
    if not shiftlockEnabled then return end
    local hrp = getHRP()
    local hum = getHum()
    if not hrp or not hum then return end
    local camCF = workspace.CurrentCamera.CFrame
    local lookVector = camCF.LookVector
    local flatLook = Vector3.new(lookVector.X, 0, lookVector.Z)
    if flatLook.Magnitude > 0.001 then
        hrp.CFrame = CFrame.new(hrp.Position, hrp.Position + flatLook)
    end
end)

ShiftlockBtn.MouseButton1Click:Connect(function()
    if shiftlockDragEnabled then return end
    shiftlockEnabled = not shiftlockEnabled
    applyShiftlock(shiftlockEnabled)
end)
ShiftlockBtn.TouchTap:Connect(function()
    if shiftlockDragEnabled then return end
    shiftlockEnabled = not shiftlockEnabled
    applyShiftlock(shiftlockEnabled)
end)

-- LeftShift keybind toggle, same as the reference script (only when the Shiftlock UI is enabled).
UserInputService.InputBegan:Connect(function(input, processed)
    if processed then return end
    if input.KeyCode == Enum.KeyCode.LeftShift and ShiftlockGui.Enabled then
        shiftlockEnabled = not shiftlockEnabled
        applyShiftlock(shiftlockEnabled)
    end
end)

-- Drag-to-reposition (only active while "Move Shiftlock Button" toggle is on); position is remembered.
local slDragging, slDragInput, slDragStart, slStartPos = false, nil, nil, nil
ShiftlockBtn.InputBegan:Connect(function(input)
    if not shiftlockDragEnabled then return end
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        slDragging = true
        slDragStart = input.Position
        slStartPos = ShiftlockBtn.Position
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                slDragging = false
                saveShiftlockPos(ShiftlockBtn.Position)
            end
        end)
    end
end)
ShiftlockBtn.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
        slDragInput = input
    end
end)
UserInputService.InputChanged:Connect(function(input)
    if input == slDragInput and slDragging and shiftlockDragEnabled then
        local delta = input.Position - slDragStart
        ShiftlockBtn.Position = UDim2.new(slStartPos.X.Scale, slStartPos.X.Offset + delta.X, slStartPos.Y.Scale, slStartPos.Y.Offset + delta.Y)
    end
end)

SectionVisualMore:Toggle({
    Title = "Shiftlock Button", Desc = "Show an on-screen Shiftlock toggle button", Icon = "crosshair", Value = false,
    Callback = function(state)
        ShiftlockGui.Enabled = state
        if not state and shiftlockEnabled then
            shiftlockEnabled = false
            applyShiftlock(false)
        end
    end
})

SectionVisualMore:Toggle({
    Title = "Move Shiftlock Button", Desc = "Enable dragging to reposition the Shiftlock button (position is saved)", Icon = "move", Value = false,
    Callback = function(state) shiftlockDragEnabled = state end
})

SectionVisualMore:Toggle({
    Title = "Fullbright", Desc = "Make the entire map fully bright", Icon = "sun", Value = false,
    Callback = function(state)
        local L = game:GetService("Lighting")
        if state then
            L.Brightness=2 L.ClockTime=14 L.FogEnd=100000 L.GlobalShadows=false L.Ambient=Color3.fromRGB(255,255,255)
        else
            L.Brightness=1 L.ClockTime=14 L.FogEnd=100000 L.GlobalShadows=true L.Ambient=Color3.fromRGB(127,127,127)
        end
    end
})

SectionVisualMore:Toggle({
    Title = "No Fog", Desc = "Remove all fog from the map", Icon = "cloud-off", Value = false,
    Callback = function(state)
        local L = game:GetService("Lighting")
        if state then L.FogEnd=100000 L.FogStart=100000
        else L.FogEnd=100000 L.FogStart=0 end
    end
})

SectionVisualMore:Toggle({
    Title = "No Skybox", Desc = "Hide the skybox background", Icon = "image-off", Value = false,
    Callback = function(state)
        local sky = game:GetService("Lighting"):FindFirstChildOfClass("Sky")
        if sky then sky.Enabled = not state end
    end
})

SectionVisualMore:Toggle({
    Title = "Xray", Desc = "Make walls and objects semi-transparent", Icon = "scan-line", Value = false,
    Callback = function(state)
        for _, obj in pairs(workspace:GetDescendants()) do
            if obj:IsA("BasePart") and not obj:IsDescendantOf(getChar() or Instance.new("Model")) then
                obj.LocalTransparencyModifier = state and 0.7 or 0
            end
        end
    end
})

local crosshairLines = {}
local function createCrosshair()
    local vpSize = workspace.CurrentCamera.ViewportSize
    local cx = vpSize.X/2 local cy = vpSize.Y/2
    local size=10 local gap=4 local thickness=2 local color=Color3.fromRGB(255,255,255)
    crosshairLines[1]=Drawing.new("Line") crosshairLines[1].From=Vector2.new(cx,cy-gap-size) crosshairLines[1].To=Vector2.new(cx,cy-gap) crosshairLines[1].Color=color crosshairLines[1].Thickness=thickness crosshairLines[1].Visible=true
    crosshairLines[2]=Drawing.new("Line") crosshairLines[2].From=Vector2.new(cx,cy+gap) crosshairLines[2].To=Vector2.new(cx,cy+gap+size) crosshairLines[2].Color=color crosshairLines[2].Thickness=thickness crosshairLines[2].Visible=true
    crosshairLines[3]=Drawing.new("Line") crosshairLines[3].From=Vector2.new(cx-gap-size,cy) crosshairLines[3].To=Vector2.new(cx-gap,cy) crosshairLines[3].Color=color crosshairLines[3].Thickness=thickness crosshairLines[3].Visible=true
    crosshairLines[4]=Drawing.new("Line") crosshairLines[4].From=Vector2.new(cx+gap,cy) crosshairLines[4].To=Vector2.new(cx+gap+size,cy) crosshairLines[4].Color=color crosshairLines[4].Thickness=thickness crosshairLines[4].Visible=true
    crosshairLines[5]=Drawing.new("Line") crosshairLines[5].From=Vector2.new(cx-1,cy) crosshairLines[5].To=Vector2.new(cx+1,cy) crosshairLines[5].Color=Color3.fromRGB(255,50,50) crosshairLines[5].Thickness=2 crosshairLines[5].Visible=true
end
local function removeCrosshair()
    for _, l in pairs(crosshairLines) do pcall(function() l:Remove() end) end crosshairLines = {}
end

SectionVisualMore:Toggle({
    Title = "Crosshair", Desc = "Show a crosshair at screen center", Icon = "crosshair", Value = false,
    Callback = function(state)
        if state then createCrosshair() else removeCrosshair() end
    end
})

-- TAB: SERVER
local TabServer = Window:Tab({ Title = "Server", Icon = "server" })
local antiAfkConn = nil

local SectionServerTools = TabServer:Section({ Title = "Tools", Icon = "wrench", Opened = true })

local autoRejoin = false
SectionServerTools:Toggle({
    Title = "Auto Rejoin", Desc = "Automatically rejoin the game when disconnected", Icon = "refresh-cw", Value = false,
    Callback = function(state)
        autoRejoin = state
        if state then
            task.spawn(function()
                while autoRejoin do
                    task.wait(5)
                    if not LocalPlayer or not LocalPlayer.Parent then
                        TeleportService:Teleport(game.PlaceId, LocalPlayer)
                    end
                end
            end)
        end
    end
})

SectionServerTools:Toggle({
    Title = "Anti AFK", Desc = "Prevent being kicked for being idle too long", Icon = "activity", Value = false,
    Callback = function(state)
        if state then
            local VU = game:GetService("VirtualUser")
            antiAfkConn = Players.LocalPlayer.Idled:Connect(function()
                VU:Button2Down(Vector2.new(0,0), workspace.CurrentCamera.CFrame)
                task.wait(1)
                VU:Button2Up(Vector2.new(0,0), workspace.CurrentCamera.CFrame)
            end)
        else
            if antiAfkConn then antiAfkConn:Disconnect() antiAfkConn = nil end
        end
    end
})

local SectionServerActions = TabServer:Section({ Title = "Actions", Icon = "zap", Opened = true })

SectionServerActions:Button({
    Title = "Rejoin", Desc = "Leave and rejoin the current game", Icon = "log-in",
    Callback = function() TeleportService:Teleport(game.PlaceId, LocalPlayer) end
})

SectionServerActions:Button({
    Title = "Server Hop", Desc = "Join a different server of this game", Icon = "shuffle",
    Callback = function()
        local placeId = game.PlaceId local servers = {}
        local success = pcall(function()
            local url = "https://games.roblox.com/v1/games/"..placeId.."/servers/Public?sortOrder=Asc&limit=100"
            local res = HttpService:JSONDecode(game:HttpGet(url))
            for _, s in pairs(res.data) do
                if s.playing < s.maxPlayers then table.insert(servers, s.id) end
            end
        end)
        if success and #servers > 0 then
            TeleportService:TeleportToPlaceInstance(placeId, servers[math.random(1,#servers)], LocalPlayer)
        else
            WindUI:Notify({ Title = "Server Hop", Content = "No other servers are available right now.", Duration = 3, Icon = "alert-circle" })
        end
    end
})

SectionServerActions:Button({
    Title = "Server Friend", Desc = "Join a server where your friends are playing", Icon = "users",
    Callback = function()
        local found = false
        for _, friend in ipairs(LocalPlayer:GetFriendsOnline()) do
            if friend.IsOnline and friend.PlaceId == game.PlaceId then
                pcall(function() TeleportService:TeleportToPlaceInstance(game.PlaceId, friend.GameId, LocalPlayer) end)
                found = true break
            end
        end
        if not found then
            WindUI:Notify({ Title = "Server Friend", Content = "No friends are currently online in this game.", Duration = 3, Icon = "alert-circle" })
        end
    end
})

-- TAB: DEVTOOLS
local TabDevTools = Window:Tab({ Title = "DevTools", Icon = "code" })

local savedCoords = {} local savedCoordsOrder = {} local savedCoordsCount = 0
local selectedCoord = nil local coordNameValue = ""

local function buildCoordCode()
    if #savedCoordsOrder == 0 then return "-- Empty Saved Coordinates" end
    local lines = { "-- Saved Coordinates:" }
    for i, name in ipairs(savedCoordsOrder) do
        local cf = savedCoords[name]
        if cf then
            local p = cf.Position
            table.insert(lines, string.format("%d. %s | X: %.2f, Y: %.2f, Z: %.2f", i, name, p.X, p.Y, p.Z))
        end
    end
    table.insert(lines, "") table.insert(lines, "-- Lua table:") table.insert(lines, "local savedPlaces = {")
    for _, name in ipairs(savedCoordsOrder) do
        local cf = savedCoords[name]
        if cf then
            local p = cf.Position
            table.insert(lines, string.format('    ["%s"] = CFrame.new(%.2f, %.2f, %.2f),', name, p.X, p.Y, p.Z))
        end
    end
    table.insert(lines, "}")
    return table.concat(lines, "\n")
end

local SectionCoords = TabDevTools:Section({ Title = "Coordinates", Icon = "map-pin", Opened = true })

local coordCodeBlock = SectionCoords:Code({
    Title = "Saved Coordinates", Code = "Empty Saved Coordinates",
    OnCopy = function() WindUI:Notify({ Title = "DevTools", Content = "Code has been copied to clipboard!", Duration = 2, Icon = "copy" }) end
})

local coordDropdown = SectionCoords:Dropdown({
    Title = "Coordinates List", Desc = "Choose a saved coordinate to view or use",
    Values = {}, Value = "", SearchBarEnabled = true,
    Callback = function(v) selectedCoord = v end
})

SectionCoords:Input({
    Title = "Coordinates Name", Desc = "Name this coordinate for easy reference",
    Placeholder = "checkpoint1", Value = "",
    Callback = function(v) coordNameValue = v end
})

local function refreshCoordDropdown()
    local keys = {}
    for _, k in ipairs(savedCoordsOrder) do
        if savedCoords[k] then table.insert(keys, k) end
    end
    coordDropdown:Refresh(keys) coordCodeBlock:SetCode(buildCoordCode())
end

SectionCoords:Button({
    Title = "Save", Desc = "Save your current position as a coordinate", Icon = "save",
    Callback = function()
        local hrp = getHRP()
        if not hrp then
            WindUI:Notify({ Title = "Error", Content = "Your character could not be found!", Duration = 2, Icon = "alert-circle" }) return
        end
        savedCoordsCount = savedCoordsCount + 1
        local name = (coordNameValue ~= "" and coordNameValue) or ("checkpoint"..savedCoordsCount)
        if savedCoords[name] then name = name.." ("..savedCoordsCount..")" end
        savedCoords[name] = hrp.CFrame
        table.insert(savedCoordsOrder, name)
        refreshCoordDropdown()
        WindUI:Notify({ Title = "DevTools", Content = "Coordinate '"..name.."' has been saved!", Duration = 2, Icon = "save" })
    end
})

SectionCoords:Button({
    Title = "Refresh", Desc = "Update the saved coordinates list", Icon = "refresh-cw",
    Callback = function()
        refreshCoordDropdown()
        WindUI:Notify({ Title = "DevTools", Content = "Coordinates list has been refreshed.", Duration = 2, Icon = "refresh-cw" })
    end
})

SectionCoords:Button({
    Title = "Delete", Desc = "Remove the selected coordinate", Icon = "trash",
    Callback = function()
        if not selectedCoord or not savedCoords[selectedCoord] then
            WindUI:Notify({ Title = "Error", Content = "Please select a coordinate first!", Duration = 2, Icon = "alert-circle" }) return
        end
        savedCoords[selectedCoord] = nil
        for i, k in ipairs(savedCoordsOrder) do
            if k == selectedCoord then table.remove(savedCoordsOrder, i) break end
        end
        selectedCoord = nil refreshCoordDropdown()
        WindUI:Notify({ Title = "DevTools", Content = "Coordinate has been deleted.", Duration = 2, Icon = "trash" })
    end
})

local SectionDevMore = TabDevTools:Section({ Title = "Tools", Icon = "terminal", Opened = true })

SectionDevMore:Button({
    Title = "Piehub Explorer", Desc = "Open the Piehub Explorer tool", Icon = "terminal",
    Callback = function()
        pcall(function()
            loadstring(game:HttpGet("https://raw.githubusercontent.com/Dylphiiee/PieHub/refs/heads/main/Un1ver%244l/explorer.lua"))()
        end)
        WindUI:Notify({ Title = "DevTools", Content = "Piehub Explorer has been opened!", Duration = 2, Icon = "terminal" })
    end
})

-- TAB: CONFIG
local TabConfig = Window:Tab({ Title = "Config", Icon = "settings" })

local ConfigManager = Window.ConfigManager
local configInputValue = "" local selectedConfig = nil

local SectionConfigSave = TabConfig:Section({ Title = "Save & Load", Icon = "save", Opened = true })

SectionConfigSave:Input({
    Title = "Config Name", Desc = "Enter a name for your new config",
    Placeholder = "myConfig", Value = "",
    Callback = function(v) configInputValue = v end
})

local function getConfigNames()
    local all = ConfigManager:AllConfigs() local names = {}
    for _, v in ipairs(all) do table.insert(names, v) end
    return names
end

local configDropdown = SectionConfigSave:Dropdown({
    Title = "Config List", Desc = "Choose a saved config",
    Values = getConfigNames(), Value = "", SearchBarEnabled = true,
    Callback = function(v) selectedConfig = v end
})

SectionConfigSave:Button({
    Title = "Save", Desc = "Save all current settings to a config", Icon = "save",
    Callback = function()
        local name = configInputValue ~= "" and configInputValue or "default"
        local cfg = ConfigManager:GetConfig(name) or ConfigManager:CreateConfig(name)
        cfg:Save() configDropdown:Refresh(getConfigNames())
        WindUI:Notify({ Title = "Config", Content = "Config '"..name.."' has been saved!", Duration = 2, Icon = "save" })
    end
})

SectionConfigSave:Button({
    Title = "Refresh", Desc = "Update the saved configs list", Icon = "refresh-cw",
    Callback = function()
        configDropdown:Refresh(getConfigNames())
        WindUI:Notify({ Title = "Config", Content = "Config list has been refreshed.", Duration = 2, Icon = "refresh-cw" })
    end
})

SectionConfigSave:Button({
    Title = "Delete", Desc = "Remove the selected config permanently", Icon = "trash",
    Callback = function()
        if not selectedConfig then
            WindUI:Notify({ Title = "Error", Content = "Please select a config first!", Duration = 2, Icon = "alert-circle" }) return
        end
        ConfigManager:DeleteConfig(selectedConfig) selectedConfig = nil
        configDropdown:Refresh(getConfigNames())
        WindUI:Notify({ Title = "Config", Content = "Config has been deleted.", Duration = 2, Icon = "trash" })
    end
})

SectionConfigSave:Divider()

SectionConfigSave:Button({
    Title = "Apply", Desc = "Load and apply the selected config", Icon = "check",
    Callback = function()
        if not selectedConfig then
            WindUI:Notify({ Title = "Error", Content = "Please select a config first!", Duration = 2, Icon = "alert-circle" }) return
        end
        local cfg = ConfigManager:GetConfig(selectedConfig)
        if cfg then
            cfg:Load()
            WindUI:Notify({ Title = "Config", Content = "Config '"..selectedConfig.."' has been applied!", Duration = 2, Icon = "check" })
        else
            WindUI:Notify({ Title = "Error", Content = "The selected config could not be found!", Duration = 2, Icon = "alert-circle" })
        end
    end
})

-- RESPAWN HANDLER
LocalPlayer.CharacterAdded:Connect(function(char)
    local hum = char:WaitForChild("Humanoid", 10)
    local hrp = char:WaitForChild("HumanoidRootPart", 10)
    local animate = char:FindFirstChild("Animate")

    local spawnWait = 0
    repeat
        task.wait(0.1)
        spawnWait = spawnWait + 0.1
    until (hrp and hrp.Position.Y > -100) or spawnWait > 5

    task.wait(0.5)

    if lastDeathCFrame then
        local cf = lastDeathCFrame
        lastDeathCFrame = nil
        task.wait(0.3)
        local hrp2 = char:FindFirstChild("HumanoidRootPart")
        if hrp2 then hrp2.CFrame = cf end

        -- Wait until the character has fully spawned (2-3 seconds) before touching jump
        task.wait(2)
        local hum2 = char:FindFirstChildWhichIsA("Humanoid")
        local hrp3 = char:FindFirstChild("HumanoidRootPart")
        local extraSpawnWait = 0
        while hum2 and hrp3 and extraSpawnWait < 1 do
            if hum2.FloorMaterial ~= Enum.Material.Air then break end
            task.wait(0.1)
            extraSpawnWait = extraSpawnWait + 0.1
            hum2 = char:FindFirstChildWhichIsA("Humanoid")
            hrp3 = char:FindFirstChild("HumanoidRootPart")
        end

        hum2 = char:FindFirstChildWhichIsA("Humanoid")
        if hum2 then
            -- Briefly enable infinite jump and perform a single bunnyhop-style jump
            local _tempInfJump = true
            local _tempJumped = false
            local _tempConn
            _tempConn = UserInputService.JumpRequest:Connect(function()
                if _tempInfJump and not _tempJumped then
                    local h = char:FindFirstChildWhichIsA("Humanoid")
                    if h then
                        _tempJumped = true
                        h:ChangeState(Enum.HumanoidStateType.Jumping)
                    end
                end
            end)
            pcall(function() hum2:SetStateEnabled(Enum.HumanoidStateType.Jumping, true) end)
            hum2:ChangeState(Enum.HumanoidStateType.Jumping)
            _tempJumped = true

            -- Wait for the bunnyhop-style jump to land before turning infinite jump back off
            local landWait = 0
            local h4 = char:FindFirstChildWhichIsA("Humanoid")
            while h4 and landWait < 2 do
                if h4.FloorMaterial ~= Enum.Material.Air and landWait > 0.15 then break end
                task.wait(0.1)
                landWait = landWait + 0.1
                h4 = char:FindFirstChildWhichIsA("Humanoid")
            end

            _tempInfJump = false
            if _tempConn then _tempConn:Disconnect() _tempConn = nil end
        end
    end

    task.wait(0.3)

    flyEnabled = false
    pcall(function() flyToggle:Set(false) end)

    freecamEnabled = false
    pcall(function() FreecamGui.Enabled = false end)
    pcall(function() freecamToggle:Set(false) end)
    local cam = workspace.CurrentCamera
    if cam then cam.CameraType = Enum.CameraType.Custom end

    task.spawn(function()
        task.wait(0.5)
        if shiftlockEnabled then applyShiftlock(true) end
    end)

    if hum then
        hum.PlatformStand = false

        for _, st in ipairs(Enum.HumanoidStateType:GetEnumItems()) do
            pcall(function() hum:SetStateEnabled(st, true) end)
        end

        pcall(function()
            hum:SetStateEnabled(Enum.HumanoidStateType.Jumping, true)
            hum:SetStateEnabled(Enum.HumanoidStateType.Freefall, true)
            hum:SetStateEnabled(Enum.HumanoidStateType.Landed, true)
            hum:SetStateEnabled(Enum.HumanoidStateType.Running, true)
            hum:SetStateEnabled(Enum.HumanoidStateType.RunningNoPhysics, true)
            hum:SetStateEnabled(Enum.HumanoidStateType.GettingUp, true)
        end)

        task.wait(0.1)
        pcall(function() hum:ChangeState(Enum.HumanoidStateType.RunningNoPhysics) end)

        if jumpPowerEnabled then hum.JumpPower = jumpPowerValue end
        if walkSpeedEnabled then hum.WalkSpeed = walkSpeedValue end
        if godmodeEnabled then
            hum.MaxHealth = math.huge
            hum.Health = math.huge
        end
    end

    if animate then
        animate.Disabled = true
        task.wait(0.05)
        animate.Disabled = false
    end

    if bunnyhopEnabled then
        bunnyhopIsJumping = false
        startBunnyhopLoop()
    end

    if godmodeEnabled then
        if godmodeConn then godmodeConn:Disconnect() godmodeConn = nil end
        godmodeConn = RunService.Heartbeat:Connect(function()
            local h = char:FindFirstChildWhichIsA("Humanoid")
            if h and godmodeEnabled then
                if h.Health < math.huge then h.Health = math.huge end
            end
        end)
    end

    if antiFlingEnabled then
        antiFlingData = {}
        startAntiFling()
    end

    task.wait(0.5)
    if punchActive then createPunchFlingFixed() end
    if saitamaActive then createSaitamaFlingFixed() end
    if kickActive then createKickFlingFixed() end
end)

-- forceJumpStateFix is now defined near the top of the file (see getHRP/getHum section)

local _origApplyAnimation = applyAnimation
applyAnimation = function(data)
    _origApplyAnimation(data)
    task.spawn(function() task.wait(0.1) forceJumpStateFix() end)
end

local _origResetAnimation = resetAnimation
resetAnimation = function()
    _origResetAnimation()
    task.spawn(function() task.wait(0.1) forceJumpStateFix() end)
end

local _origPlayEmote = playEmote
playEmote = function(data, loopState, walkState)
    _origPlayEmote(data, loopState, walkState)
    task.spawn(function() task.wait(0.1) forceJumpStateFix() end)
end

local _origStopEmote = stopEmote
stopEmote = function()
    _origStopEmote()
    task.spawn(function() task.wait(0.1) forceJumpStateFix() end)
end

-- (Redundant duplicate "!re" handler removed - the jump-state fix is now part of the
-- consolidated handler near the top of the file, right after the RESPAWN / !re COMMAND section.)

-- ===================== QUICKEMOTES PANEL =====================
local QUICK_EMOTE_PER_PAGE = 10

local QuickEmotesGui = Instance.new("ScreenGui")
QuickEmotesGui.Name = "QuickEmotesUI"
QuickEmotesGui.ResetOnSpawn = false
QuickEmotesGui.Enabled = true

local qePcallSuccess, _ = pcall(function() QuickEmotesGui.Parent = CoreGui end)
if not qePcallSuccess then QuickEmotesGui.Parent = LocalPlayer:WaitForChild("PlayerGui") end
hideFromRecording(QuickEmotesGui)

local QuickEmotesToggleBtn = Instance.new("TextButton", QuickEmotesGui)
QuickEmotesToggleBtn.Name = "QuickEmotesToggle"
QuickEmotesToggleBtn.Size = UDim2.new(0, 38, 0, 38)
QuickEmotesToggleBtn.Position = UDim2.new(0, 12, 1, -60)
QuickEmotesToggleBtn.BackgroundColor3 = Color3.fromRGB(45, 45, 55)
QuickEmotesToggleBtn.Text = ""
QuickEmotesToggleBtn.AutoButtonColor = false
QuickEmotesToggleBtn.BorderSizePixel = 0
QuickEmotesToggleBtn.Active = true
QuickEmotesToggleBtn.ZIndex = 50

local QECorner = Instance.new("UICorner", QuickEmotesToggleBtn)
QECorner.CornerRadius = UDim.new(1, 0)

local QEIcon = Instance.new("ImageLabel", QuickEmotesToggleBtn)
QEIcon.Size = UDim2.new(0.6, 0, 0.6, 0)
QEIcon.Position = UDim2.new(0.2, 0, 0.2, 0)
QEIcon.BackgroundTransparency = 1
QEIcon.Image = "rbxassetid://6034509993"
QEIcon.ImageColor3 = Color3.fromRGB(255, 255, 255)
QEIcon.ZIndex = 51

-- QuickEmotes toggle position is fixed (bottom-left); drag state no longer needed.

local QuickEmotesPanel = Instance.new("Frame", QuickEmotesGui)
QuickEmotesPanel.Name = "QuickEmotesPanel"
QuickEmotesPanel.Size = UDim2.new(0, 180, 0, 260)
QuickEmotesPanel.Position = UDim2.new(0, 12, 1, -330)
QuickEmotesPanel.BackgroundColor3 = Color3.fromRGB(30, 30, 38)
QuickEmotesPanel.BorderSizePixel = 0
QuickEmotesPanel.Visible = false
QuickEmotesPanel.ZIndex = 50

local QEPanelCorner = Instance.new("UICorner", QuickEmotesPanel)
QEPanelCorner.CornerRadius = UDim.new(0, 12)

local QEPanelStroke = Instance.new("UIStroke", QuickEmotesPanel)
QEPanelStroke.Color = Color3.fromRGB(70, 70, 85)
QEPanelStroke.Thickness = 1

local QESearchBox = Instance.new("TextBox", QuickEmotesPanel)
QESearchBox.Size = UDim2.new(1, -12, 0, 24)
QESearchBox.Position = UDim2.new(0, 6, 0, 6)
QESearchBox.BackgroundColor3 = Color3.fromRGB(45, 45, 55)
QESearchBox.TextColor3 = Color3.fromRGB(255, 255, 255)
QESearchBox.PlaceholderText = "Search..."
QESearchBox.PlaceholderColor3 = Color3.fromRGB(150, 150, 160)
QESearchBox.Text = ""
QESearchBox.ClearTextOnFocus = false
QESearchBox.Font = Enum.Font.Gotham
QESearchBox.TextSize = 12
QESearchBox.BorderSizePixel = 0
QESearchBox.ZIndex = 51

local QESearchCorner = Instance.new("UICorner", QESearchBox)
QESearchCorner.CornerRadius = UDim.new(0, 8)

local QEMenuFrame = Instance.new("Frame", QuickEmotesPanel)
QEMenuFrame.Size = UDim2.new(1, -12, 0, 24)
QEMenuFrame.Position = UDim2.new(0, 6, 0, 34)
QEMenuFrame.BackgroundTransparency = 1
QEMenuFrame.ZIndex = 51

local QEAnimMenuBtn = Instance.new("TextButton", QEMenuFrame)
QEAnimMenuBtn.Size = UDim2.new(0.3333, -3, 1, 0)
QEAnimMenuBtn.Position = UDim2.new(0, 0, 0, 0)
QEAnimMenuBtn.BackgroundColor3 = Color3.fromRGB(80, 60, 200)
QEAnimMenuBtn.Text = "Animation"
QEAnimMenuBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
QEAnimMenuBtn.Font = Enum.Font.GothamBold
QEAnimMenuBtn.TextSize = 10
QEAnimMenuBtn.AutoButtonColor = false
QEAnimMenuBtn.BorderSizePixel = 0
QEAnimMenuBtn.ZIndex = 51
local QEAnimMenuCorner = Instance.new("UICorner", QEAnimMenuBtn)
QEAnimMenuCorner.CornerRadius = UDim.new(0, 8)

local QEEmoteMenuBtn = Instance.new("TextButton", QEMenuFrame)
QEEmoteMenuBtn.Size = UDim2.new(0.3333, -3, 1, 0)
QEEmoteMenuBtn.Position = UDim2.new(0.3333, 3, 0, 0)
QEEmoteMenuBtn.BackgroundColor3 = Color3.fromRGB(45, 45, 55)
QEEmoteMenuBtn.Text = "Emotes"
QEEmoteMenuBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
QEEmoteMenuBtn.Font = Enum.Font.GothamBold
QEEmoteMenuBtn.TextSize = 10
QEEmoteMenuBtn.AutoButtonColor = false
QEEmoteMenuBtn.BorderSizePixel = 0
QEEmoteMenuBtn.ZIndex = 51
local QEEmoteMenuCorner = Instance.new("UICorner", QEEmoteMenuBtn)
QEEmoteMenuCorner.CornerRadius = UDim.new(0, 8)

local QER6MenuBtn = Instance.new("TextButton", QEMenuFrame)
QER6MenuBtn.Size = UDim2.new(0.3333, -3, 1, 0)
QER6MenuBtn.Position = UDim2.new(0.6666, 3, 0, 0)
QER6MenuBtn.BackgroundColor3 = Color3.fromRGB(45, 45, 55)
QER6MenuBtn.Text = "R6"
QER6MenuBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
QER6MenuBtn.Font = Enum.Font.GothamBold
QER6MenuBtn.TextSize = 10
QER6MenuBtn.AutoButtonColor = false
QER6MenuBtn.BorderSizePixel = 0
QER6MenuBtn.ZIndex = 51
local QER6MenuCorner = Instance.new("UICorner", QER6MenuBtn)
QER6MenuCorner.CornerRadius = UDim.new(0, 8)

local QEListFrame = Instance.new("ScrollingFrame", QuickEmotesPanel)
QEListFrame.Size = UDim2.new(1, -12, 0, 138)
QEListFrame.Position = UDim2.new(0, 6, 0, 62)
QEListFrame.BackgroundColor3 = Color3.fromRGB(24, 24, 30)
QEListFrame.BorderSizePixel = 0
QEListFrame.ScrollBarThickness = 4
QEListFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
QEListFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
QEListFrame.ZIndex = 51

local QEListCorner = Instance.new("UICorner", QEListFrame)
QEListCorner.CornerRadius = UDim.new(0, 8)

local QEListLayout = Instance.new("UIListLayout", QEListFrame)
QEListLayout.Padding = UDim.new(0, 4)
QEListLayout.SortOrder = Enum.SortOrder.LayoutOrder

local QEPageFrame = Instance.new("Frame", QuickEmotesPanel)
QEPageFrame.Size = UDim2.new(1, -12, 0, 22)
QEPageFrame.Position = UDim2.new(0, 6, 0, 204)
QEPageFrame.BackgroundTransparency = 1
QEPageFrame.ZIndex = 51

local QEPrevBtn = Instance.new("TextButton", QEPageFrame)
QEPrevBtn.Size = UDim2.new(0.32, 0, 1, 0)
QEPrevBtn.Position = UDim2.new(0, 0, 0, 0)
QEPrevBtn.BackgroundColor3 = Color3.fromRGB(45, 45, 55)
QEPrevBtn.Text = "< Prev"
QEPrevBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
QEPrevBtn.Font = Enum.Font.Gotham
QEPrevBtn.TextSize = 11
QEPrevBtn.AutoButtonColor = false
QEPrevBtn.BorderSizePixel = 0
QEPrevBtn.ZIndex = 51
local QEPrevCorner = Instance.new("UICorner", QEPrevBtn)
QEPrevCorner.CornerRadius = UDim.new(0, 8)

local QEPageLabel = Instance.new("TextLabel", QEPageFrame)
QEPageLabel.Size = UDim2.new(0.36, 0, 1, 0)
QEPageLabel.Position = UDim2.new(0.32, 0, 0, 0)
QEPageLabel.BackgroundTransparency = 1
QEPageLabel.Text = "1 / 1"
QEPageLabel.TextColor3 = Color3.fromRGB(200, 200, 210)
QEPageLabel.Font = Enum.Font.Gotham
QEPageLabel.TextSize = 11
QEPageLabel.ZIndex = 51

local QENextBtn = Instance.new("TextButton", QEPageFrame)
QENextBtn.Size = UDim2.new(0.32, 0, 1, 0)
QENextBtn.Position = UDim2.new(0.68, 0, 0, 0)
QENextBtn.BackgroundColor3 = Color3.fromRGB(45, 45, 55)
QENextBtn.Text = "Next >"
QENextBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
QENextBtn.Font = Enum.Font.Gotham
QENextBtn.TextSize = 11
QENextBtn.AutoButtonColor = false
QENextBtn.BorderSizePixel = 0
QENextBtn.ZIndex = 51
local QENextCorner = Instance.new("UICorner", QENextBtn)
QENextCorner.CornerRadius = UDim.new(0, 8)

local QEStopAnimBtn = Instance.new("TextButton", QuickEmotesPanel)
QEStopAnimBtn.Size = UDim2.new(0.5, -9, 0, 26)
QEStopAnimBtn.Position = UDim2.new(0, 6, 1, -32)
QEStopAnimBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
QEStopAnimBtn.Text = "Stop Anim"
QEStopAnimBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
QEStopAnimBtn.Font = Enum.Font.GothamBold
QEStopAnimBtn.TextSize = 11
QEStopAnimBtn.AutoButtonColor = false
QEStopAnimBtn.BorderSizePixel = 0
QEStopAnimBtn.ZIndex = 51
local QEStopAnimCorner = Instance.new("UICorner", QEStopAnimBtn)
QEStopAnimCorner.CornerRadius = UDim.new(0, 8)

local QEStopEmoteBtn = Instance.new("TextButton", QuickEmotesPanel)
QEStopEmoteBtn.Size = UDim2.new(0.5, -9, 0, 26)
QEStopEmoteBtn.Position = UDim2.new(0.5, 3, 1, -32)
QEStopEmoteBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
QEStopEmoteBtn.Text = "Stop Emote"
QEStopEmoteBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
QEStopEmoteBtn.Font = Enum.Font.GothamBold
QEStopEmoteBtn.TextSize = 11
QEStopEmoteBtn.AutoButtonColor = false
QEStopEmoteBtn.BorderSizePixel = 0
QEStopEmoteBtn.ZIndex = 51
local QEStopEmoteCorner = Instance.new("UICorner", QEStopEmoteBtn)
QEStopEmoteCorner.CornerRadius = UDim.new(0, 8)

local qeCurrentMode = "Animation"
local qeCurrentPage = 1
local qeSearchQuery = ""
local qeEmoteResults = FullEmoteList
local qeR6Results = R6EmoteList

local function qeGetAnimList()
    local list = {}
    for _, v in ipairs(animNameList) do table.insert(list, v) end
    for k in pairs(customAnimPacks) do table.insert(list, "[Custom] " .. k) end
    table.sort(list, function(a, b) return a:lower() < b:lower() end)
    return list
end

local qeAnimResults = qeGetAnimList()

local function qeGetTotalPages(list)
    return math.max(1, math.ceil(#list / QUICK_EMOTE_PER_PAGE))
end

local function qeGetPageItems(list, pg)
    local items = {}
    local s = (pg - 1) * QUICK_EMOTE_PER_PAGE + 1
    local e2 = math.min(pg * QUICK_EMOTE_PER_PAGE, #list)
    for i = s, e2 do table.insert(items, list[i]) end
    return items
end

local function qeClearList()
    for _, child in ipairs(QEListFrame:GetChildren()) do
        if child:IsA("TextButton") then child:Destroy() end
    end
end

local function qeRefreshList()
    qeClearList()
    local list, totalPages, pageItems

    if qeCurrentMode == "Animation" then
        list = qeAnimResults
        totalPages = qeGetTotalPages(list)
        qeCurrentPage = math.clamp(qeCurrentPage, 1, totalPages)
        pageItems = qeGetPageItems(list, qeCurrentPage)

        for i, title in ipairs(pageItems) do
            local btn = Instance.new("TextButton")
            btn.Size = UDim2.new(1, 0, 0, 24)
            btn.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
            btn.Text = title
            btn.TextColor3 = Color3.fromRGB(255, 255, 255)
            btn.Font = Enum.Font.Gotham
            btn.TextSize = 11
            btn.AutoButtonColor = false
            btn.BorderSizePixel = 0
            btn.ZIndex = 52
            btn.LayoutOrder = i
            local c = Instance.new("UICorner", btn)
            c.CornerRadius = UDim.new(0, 6)
            btn.Parent = QEListFrame
            btn.MouseButton1Click:Connect(function()
                local customKey = title:match("^%[Custom%] (.+)$")
                if customKey then
                    applyCustomAnimPack(customKey)
                    WindUI:Notify({ Title = "QuickEmotes", Content = "Custom pack '" .. customKey .. "' has been applied!", Duration = 2, Icon = "check" })
                else
                    local data = getAnimData(title)
                    if data then
                        applyAnimation(data)
                        WindUI:Notify({ Title = "QuickEmotes", Content = "Animation '" .. title .. "' has been applied!", Duration = 2, Icon = "check" })
                    end
                end
            end)
        end
    elseif qeCurrentMode == "Emotes" then
        list = qeEmoteResults
        totalPages = qeGetTotalPages(list)
        qeCurrentPage = math.clamp(qeCurrentPage, 1, totalPages)
        pageItems = qeGetPageItems(list, qeCurrentPage)

        for i, emoteData in ipairs(pageItems) do
            local btn = Instance.new("TextButton")
            btn.Size = UDim2.new(1, 0, 0, 24)
            btn.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
            btn.Text = emoteData.Title
            btn.TextColor3 = Color3.fromRGB(255, 255, 255)
            btn.Font = Enum.Font.Gotham
            btn.TextSize = 11
            btn.AutoButtonColor = false
            btn.BorderSizePixel = 0
            btn.ZIndex = 52
            btn.LayoutOrder = i
            local c = Instance.new("UICorner", btn)
            c.CornerRadius = UDim.new(0, 6)
            btn.Parent = QEListFrame
            btn.MouseButton1Click:Connect(function()
                playEmote(emoteData, emoteLoopEnabled, emoteWalkEnabled)
                WindUI:Notify({ Title = "QuickEmotes", Content = "Now playing: '" .. emoteData.Title .. "'", Duration = 2, Icon = "play" })
            end)
        end
    else
        list = qeR6Results
        totalPages = qeGetTotalPages(list)
        qeCurrentPage = math.clamp(qeCurrentPage, 1, totalPages)
        pageItems = qeGetPageItems(list, qeCurrentPage)

        for i, emoteData in ipairs(pageItems) do
            local btn = Instance.new("TextButton")
            btn.Size = UDim2.new(1, 0, 0, 24)
            btn.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
            btn.Text = emoteData.Title
            btn.TextColor3 = Color3.fromRGB(255, 255, 255)
            btn.Font = Enum.Font.Gotham
            btn.TextSize = 11
            btn.AutoButtonColor = false
            btn.BorderSizePixel = 0
            btn.ZIndex = 52
            btn.LayoutOrder = i
            local c = Instance.new("UICorner", btn)
            c.CornerRadius = UDim.new(0, 6)
            btn.Parent = QEListFrame
            btn.MouseButton1Click:Connect(function()
                playEmote(emoteData, emoteLoopEnabled, emoteWalkEnabled)
                WindUI:Notify({ Title = "QuickEmotes", Content = "Now playing: '" .. emoteData.Title .. "'", Duration = 2, Icon = "play" })
            end)
        end
    end

    QEPageLabel.Text = qeCurrentPage .. " / " .. totalPages
end

local function qeSetMode(mode)
    qeCurrentMode = mode
    qeCurrentPage = 1
    if mode == "Animation" then
        QEAnimMenuBtn.BackgroundColor3 = Color3.fromRGB(80, 60, 200)
        QEEmoteMenuBtn.BackgroundColor3 = Color3.fromRGB(45, 45, 55)
        QER6MenuBtn.BackgroundColor3 = Color3.fromRGB(45, 45, 55)
    elseif mode == "Emotes" then
        QEAnimMenuBtn.BackgroundColor3 = Color3.fromRGB(45, 45, 55)
        QEEmoteMenuBtn.BackgroundColor3 = Color3.fromRGB(80, 60, 200)
        QER6MenuBtn.BackgroundColor3 = Color3.fromRGB(45, 45, 55)
    else
        QEAnimMenuBtn.BackgroundColor3 = Color3.fromRGB(45, 45, 55)
        QEEmoteMenuBtn.BackgroundColor3 = Color3.fromRGB(45, 45, 55)
        QER6MenuBtn.BackgroundColor3 = Color3.fromRGB(80, 60, 200)
    end
    qeRefreshList()
end

QEAnimMenuBtn.MouseButton1Click:Connect(function() qeSetMode("Animation") end)
QEEmoteMenuBtn.MouseButton1Click:Connect(function() qeSetMode("Emotes") end)
QER6MenuBtn.MouseButton1Click:Connect(function() qeSetMode("R6") end)

QEPrevBtn.MouseButton1Click:Connect(function()
    if qeCurrentPage <= 1 then return end
    qeCurrentPage = qeCurrentPage - 1
    qeRefreshList()
end)

QENextBtn.MouseButton1Click:Connect(function()
    local list
    if qeCurrentMode == "Animation" then list = qeAnimResults
    elseif qeCurrentMode == "Emotes" then list = qeEmoteResults
    else list = qeR6Results end
    if qeCurrentPage >= qeGetTotalPages(list) then return end
    qeCurrentPage = qeCurrentPage + 1
    qeRefreshList()
end)

QEStopAnimBtn.MouseButton1Click:Connect(function()
    resetAnimation()
    WindUI:Notify({ Title = "QuickEmotes", Content = "Animation stopped.", Duration = 2, Icon = "square" })
end)

QEStopEmoteBtn.MouseButton1Click:Connect(function()
    stopEmote()
    WindUI:Notify({ Title = "QuickEmotes", Content = "Emote stopped.", Duration = 2, Icon = "square" })
end)

QESearchBox:GetPropertyChangedSignal("Text"):Connect(function()
    qeSearchQuery = QESearchBox.Text
    if qeCurrentMode == "Animation" then
        if qeSearchQuery == "" then
            qeAnimResults = qeGetAnimList()
        else
            local q = qeSearchQuery:lower()
            local result = {}
            for _, title in ipairs(qeGetAnimList()) do
                if title:lower():find(q, 1, true) then table.insert(result, title) end
            end
            qeAnimResults = result
        end
    elseif qeCurrentMode == "Emotes" then
        qeEmoteResults = getFilteredEmotes(qeSearchQuery)
    else
        qeR6Results = filterEmoteListBy(R6EmoteList, qeSearchQuery)
    end
    qeCurrentPage = 1
    qeRefreshList()
end)

-- QuickEmotes toggle is now fixed at bottom-left and cannot be dragged/moved.
QuickEmotesToggleBtn.Position = UDim2.new(0, 12, 1, -60)
QuickEmotesPanel.Position = UDim2.new(0, 12, 1, -330)

QuickEmotesToggleBtn.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        QuickEmotesPanel.Visible = not QuickEmotesPanel.Visible
        if QuickEmotesPanel.Visible then qeRefreshList() end
    end
end)

qeRefreshList()

-- ===================== MOOD ANIMATIONS PANEL =====================
-- Integrated from the standalone "Fe Mood Animations" script. Toggle button sits
-- immediately to the right of the QuickEmotes toggle, bottom-left of the screen.
local moodSaveFile = "WindUI/PieHub/moodAnimations.json"
local moodCurTrack = nil
local moodCurId = nil
local moodLooped = false
local moodCfg = { weight = 1, speed = 1, priority = Enum.AnimationPriority.Action4 }

local defaultMoods = {
    {id=14618207727, name="Default Mood"},
    {id=11163856931, name="The Winning Smile"},
    {id=11822637523, name="Classic M"},
    {id=14532855772, name="Skeptic"},
    {id=11236428476, name="Chill"},
    {id=11308848181, name="Err..."},
    {id=13692973305, name="Friendly Smile"},
    {id=12936976200, name="Big Grin"},
}

local moods = {}

local function moodSaveData()
    local data = {}
    for _, m in ipairs(moods) do table.insert(data, { id = m.id, name = m.name }) end
    pcall(function() writefile(moodSaveFile, HttpService:JSONEncode(data)) end)
end

local function moodLoadData()
    local ok, content = pcall(function() return readfile(moodSaveFile) end)
    if ok and content then
        local dok, decoded = pcall(function() return HttpService:JSONDecode(content) end)
        if dok and type(decoded) == "table" then
            for _, entry in ipairs(decoded) do
                if type(entry) == "table" and type(entry.id) == "number" then
                    table.insert(moods, { id = entry.id, name = entry.name })
                end
            end
            return true
        end
    end
    return false
end

if not moodLoadData() then
    for _, m in ipairs(defaultMoods) do table.insert(moods, { id = m.id, name = m.name }) end
    moodSaveData()
end

local function getMoodAnimId(id)
    local animObj = loadEmoteObj(id)
    return animObj.AnimationId ~= "" and animObj.AnimationId or ("rbxassetid://" .. tostring(id))
end

local function applyToMoodTrack(t)
    t.Priority = moodCfg.priority
    t.Looped = moodLooped
    t:AdjustWeight(moodCfg.weight)
    t:AdjustSpeed(moodCfg.speed)
end

local function playMood(moodId)
    local animator = getAnimator()
    if not animator then return end
    if moodCurTrack then
        pcall(function() moodCurTrack:Destroy() end)
        moodCurTrack = nil
    end
    moodCurId = moodId
    local a = Instance.new("Animation")
    a.AnimationId = getMoodAnimId(moodId)
    local ok, t = pcall(function() return animator:LoadAnimation(a) end)
    if not ok or not t then return end
    applyToMoodTrack(t)
    moodCurTrack = t
    t:Play()
    if not moodLooped then
        t.Stopped:Connect(function()
            if moodCurTrack == t and moodCurId == moodId then t:Play() end
        end)
    end
end

local function stopMood()
    if moodCurTrack then
        pcall(function() moodCurTrack:Destroy() end)
        moodCurTrack = nil
    end
    moodCurId = nil
end

local MoodGui = Instance.new("ScreenGui")
MoodGui.Name = "MoodAnimationsUI"
MoodGui.ResetOnSpawn = false
MoodGui.Enabled = true
local moodGuiOk, _ = pcall(function() MoodGui.Parent = CoreGui end)
if not moodGuiOk then MoodGui.Parent = LocalPlayer:WaitForChild("PlayerGui") end
hideFromRecording(MoodGui)

local MoodToggleBtn = Instance.new("TextButton", MoodGui)
MoodToggleBtn.Name = "MoodToggle"
MoodToggleBtn.Size = UDim2.new(0, 38, 0, 38)
MoodToggleBtn.Position = UDim2.new(0, 58, 1, -60)
MoodToggleBtn.BackgroundColor3 = Color3.fromRGB(45, 45, 55)
MoodToggleBtn.Text = ""
MoodToggleBtn.AutoButtonColor = false
MoodToggleBtn.BorderSizePixel = 0
MoodToggleBtn.Active = true
MoodToggleBtn.ZIndex = 50
local MoodToggleCorner = Instance.new("UICorner", MoodToggleBtn)
MoodToggleCorner.CornerRadius = UDim.new(1, 0)

local MoodIcon = Instance.new("ImageLabel", MoodToggleBtn)
MoodIcon.Size = UDim2.new(0.6, 0, 0.6, 0)
MoodIcon.Position = UDim2.new(0.2, 0, 0.2, 0)
MoodIcon.BackgroundTransparency = 1
MoodIcon.Image = "rbxassetid://6034509720"
MoodIcon.ImageColor3 = Color3.fromRGB(255, 255, 255)
MoodIcon.ZIndex = 51

local MoodPanel = Instance.new("Frame", MoodGui)
MoodPanel.Name = "MoodPanel"
MoodPanel.Size = UDim2.new(0, 200, 0, 260)
MoodPanel.Position = UDim2.new(0, 58, 1, -330)
MoodPanel.BackgroundColor3 = Color3.fromRGB(30, 30, 38)
MoodPanel.BorderSizePixel = 0
MoodPanel.Visible = false
MoodPanel.ZIndex = 50
local MoodPanelCorner = Instance.new("UICorner", MoodPanel)
MoodPanelCorner.CornerRadius = UDim.new(0, 12)
local MoodPanelStroke = Instance.new("UIStroke", MoodPanel)
MoodPanelStroke.Color = Color3.fromRGB(70, 70, 85)
MoodPanelStroke.Thickness = 1

local MoodSearchBox = Instance.new("TextBox", MoodPanel)
MoodSearchBox.Size = UDim2.new(1, -12, 0, 24)
MoodSearchBox.Position = UDim2.new(0, 6, 0, 6)
MoodSearchBox.BackgroundColor3 = Color3.fromRGB(45, 45, 55)
MoodSearchBox.TextColor3 = Color3.fromRGB(255, 255, 255)
MoodSearchBox.PlaceholderText = "Search moods..."
MoodSearchBox.PlaceholderColor3 = Color3.fromRGB(150, 150, 160)
MoodSearchBox.Text = ""
MoodSearchBox.ClearTextOnFocus = false
MoodSearchBox.Font = Enum.Font.Gotham
MoodSearchBox.TextSize = 12
MoodSearchBox.BorderSizePixel = 0
MoodSearchBox.ZIndex = 51
local MoodSearchCorner = Instance.new("UICorner", MoodSearchBox)
MoodSearchCorner.CornerRadius = UDim.new(0, 8)

local MoodAddBtn = Instance.new("TextButton", MoodPanel)
MoodAddBtn.Size = UDim2.new(1, -12, 0, 24)
MoodAddBtn.Position = UDim2.new(0, 6, 0, 34)
MoodAddBtn.BackgroundColor3 = Color3.fromRGB(80, 60, 200)
MoodAddBtn.Text = "+ Add Mood by ID"
MoodAddBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
MoodAddBtn.Font = Enum.Font.GothamBold
MoodAddBtn.TextSize = 11
MoodAddBtn.AutoButtonColor = false
MoodAddBtn.BorderSizePixel = 0
MoodAddBtn.ZIndex = 51
local MoodAddCorner = Instance.new("UICorner", MoodAddBtn)
MoodAddCorner.CornerRadius = UDim.new(0, 8)

local MoodListFrame = Instance.new("ScrollingFrame", MoodPanel)
MoodListFrame.Size = UDim2.new(1, -12, 0, 138)
MoodListFrame.Position = UDim2.new(0, 6, 0, 62)
MoodListFrame.BackgroundColor3 = Color3.fromRGB(24, 24, 30)
MoodListFrame.BorderSizePixel = 0
MoodListFrame.ScrollBarThickness = 4
MoodListFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
MoodListFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
MoodListFrame.ZIndex = 51
local MoodListCorner = Instance.new("UICorner", MoodListFrame)
MoodListCorner.CornerRadius = UDim.new(0, 8)
local MoodListLayout = Instance.new("UIListLayout", MoodListFrame)
MoodListLayout.Padding = UDim.new(0, 4)
MoodListLayout.SortOrder = Enum.SortOrder.LayoutOrder

local MoodStopBtn = Instance.new("TextButton", MoodPanel)
MoodStopBtn.Size = UDim2.new(0.5, -9, 0, 26)
MoodStopBtn.Position = UDim2.new(0, 6, 1, -32)
MoodStopBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
MoodStopBtn.Text = "Stop Mood"
MoodStopBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
MoodStopBtn.Font = Enum.Font.GothamBold
MoodStopBtn.TextSize = 11
MoodStopBtn.AutoButtonColor = false
MoodStopBtn.BorderSizePixel = 0
MoodStopBtn.ZIndex = 51
local MoodStopCorner = Instance.new("UICorner", MoodStopBtn)
MoodStopCorner.CornerRadius = UDim.new(0, 8)

local MoodLoopBtn = Instance.new("TextButton", MoodPanel)
MoodLoopBtn.Size = UDim2.new(0.5, -9, 0, 26)
MoodLoopBtn.Position = UDim2.new(0.5, 3, 1, -32)
MoodLoopBtn.BackgroundColor3 = Color3.fromRGB(45, 45, 55)
MoodLoopBtn.Text = "Loop: OFF"
MoodLoopBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
MoodLoopBtn.Font = Enum.Font.GothamBold
MoodLoopBtn.TextSize = 11
MoodLoopBtn.AutoButtonColor = false
MoodLoopBtn.BorderSizePixel = 0
MoodLoopBtn.ZIndex = 51
local MoodLoopCorner = Instance.new("UICorner", MoodLoopBtn)
MoodLoopCorner.CornerRadius = UDim.new(0, 8)

MoodLoopBtn.MouseButton1Click:Connect(function()
    moodLooped = not moodLooped
    MoodLoopBtn.Text = moodLooped and "Loop: ON" or "Loop: OFF"
    MoodLoopBtn.BackgroundColor3 = moodLooped and Color3.fromRGB(80, 60, 200) or Color3.fromRGB(45, 45, 55)
    if moodCurTrack then moodCurTrack.Looped = moodLooped end
end)

MoodStopBtn.MouseButton1Click:Connect(function()
    stopMood()
    WindUI:Notify({ Title = "Mood", Content = "Mood animation stopped.", Duration = 2, Icon = "square" })
end)

local moodSearchQuery = ""

local function moodFilteredList()
    if moodSearchQuery == "" then return moods end
    local result = {}
    local q = moodSearchQuery:lower()
    for _, m in ipairs(moods) do
        if (m.name or ""):lower():find(q, 1, true) then table.insert(result, m) end
    end
    return result
end

local function moodClearList()
    for _, child in ipairs(MoodListFrame:GetChildren()) do
        if child:IsA("TextButton") then child:Destroy() end
    end
end

local function moodRefreshList()
    moodClearList()
    local list = moodFilteredList()
    for i, m in ipairs(list) do
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(1, 0, 0, 24)
        btn.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
        btn.Text = m.name or tostring(m.id)
        btn.TextColor3 = Color3.fromRGB(255, 255, 255)
        btn.Font = Enum.Font.Gotham
        btn.TextSize = 11
        btn.AutoButtonColor = false
        btn.BorderSizePixel = 0
        btn.ZIndex = 52
        btn.LayoutOrder = i
        local c = Instance.new("UICorner", btn)
        c.CornerRadius = UDim.new(0, 6)
        btn.Parent = MoodListFrame
        btn.MouseButton1Click:Connect(function()
            playMood(m.id)
            WindUI:Notify({ Title = "Mood", Content = "Now playing: '" .. (m.name or tostring(m.id)) .. "'", Duration = 2, Icon = "play" })
        end)
    end
end

MoodSearchBox:GetPropertyChangedSignal("Text"):Connect(function()
    moodSearchQuery = MoodSearchBox.Text
    moodRefreshList()
end)

MoodAddBtn.MouseButton1Click:Connect(function()
    local id = tonumber(MoodSearchBox.Text)
    if not id then
        WindUI:Notify({ Title = "Mood", Content = "Type a numeric Asset ID in the search box first, then press '+ Add Mood by ID'.", Duration = 3, Icon = "alert-circle" })
        return
    end
    for _, m in ipairs(moods) do
        if m.id == id then
            WindUI:Notify({ Title = "Mood", Content = "That mood is already in your list.", Duration = 2, Icon = "alert-circle" })
            return
        end
    end
    table.insert(moods, { id = id, name = tostring(id) })
    moodSaveData()
    MoodSearchBox.Text = ""
    moodSearchQuery = ""
    moodRefreshList()
    WindUI:Notify({ Title = "Mood", Content = "Mood " .. id .. " added!", Duration = 2, Icon = "check" })
end)

MoodToggleBtn.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        MoodPanel.Visible = not MoodPanel.Visible
        if MoodPanel.Visible then moodRefreshList() end
    end
end)

moodRefreshList()

task.defer(function()
    TabAbout:Select()
end)
