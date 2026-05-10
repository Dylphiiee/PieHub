-- PieHub V2 by Dylphiiee
local WindUI = loadstring(game:HttpGet("https://github.com/Footagesus/WindUI/releases/latest/download/main.lua"))()

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")
local UserInputService = game:GetService("UserInputService")
local Debris = game:GetService("Debris")
local LocalPlayer = Players.LocalPlayer

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
    Title = "PieHub V2",
    Content = "Loaded! Press RightShift to toggle.",
    Duration = 4,
    Icon = "cookie",
})

Window:Tag({ Title = "Dylphiiee", Icon = "user", Color = Color3.fromHex("#a78bfa"), Radius = 12 })
Window:Tag({ Title = "V2.0.0", Icon = "rocket", Color = Color3.fromHex("#30ff6a"), Radius = 12 })

local function getChar() return LocalPlayer.Character end
local function getHum()
    local c = getChar()
    return c and c:FindFirstChildWhichIsA("Humanoid")
end
local function getHRP()
    local c = getChar()
    return c and c:FindFirstChild("HumanoidRootPart")
end

-- RESPAWN / !re COMMAND
local lastDeathCFrame = nil

LocalPlayer.Chatted:Connect(function(msg)
    local lowerMsg = msg:lower()
    if lowerMsg == "!re" or lowerMsg == "/re" or lowerMsg == ";re" then
        local hrp = getHRP()
        if hrp then lastDeathCFrame = hrp.CFrame end

        local hum = getHum()
        if hum then
            hum.MaxHealth = 100
            hum.Health = 100
            task.wait(0.05)
            hum.Health = 0
        end
    end
end)

-- ANTI FLING SYSTEM
local antiFlingEnabled = false
local antiFlingData = {}
local antiFlingConn = nil

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

-- FLING TOOL SYSTEM
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
    return chr:FindFirstChild("Left Leg") or chr:FindFirstChild("LeftLowerLeg")
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

local function createKickFling()
    removeKickTool()
    local chr = getChar() local hum = getHum()
    if not chr or not hum then return end
    kickTool = createFlingTool("PieKick", 133566007754001, getLeftLeg, nil, nil, 1.5)
end

-- TAB: ABOUT
local TabAbout = Window:Tab({ Title = "About", Icon = "info" })

TabAbout:Image({ Image = "rbxassetid://5107182114", AspectRatio = "16:9", Radius = 12 })

local SectionInfoAbout = TabAbout:Section({ Title = "About", Icon = "info", Opened = true })
SectionInfoAbout:Paragraph({ Title = "PieHub", Desc = "Version: 2.0.0\nBuild: Stable", Icon = "cookie" })
SectionInfoAbout:Paragraph({ Title = "Creator", Desc = "Dibuat oleh Dylphiiee\nTerimakasih sudah menggunakan PieHub V2!", Icon = "user" })

local SectionInfoContact = TabAbout:Section({ Title = "Contact", Icon = "phone", Opened = true })
SectionInfoContact:Button({
    Title = "Discord", Desc = "Join server Discord kami", Icon = "message-circle", Color = Color3.fromHex("#5865F2"),
    Callback = function()
        setclipboard("https://discord.gg/yourinvite")
        WindUI:Notify({ Title = "Discord", Content = "Link Discord disalin!", Duration = 3, Icon = "message-circle" })
    end
})
SectionInfoContact:Button({
    Title = "WhatsApp", Desc = "Hubungi via WhatsApp", Icon = "phone", Color = Color3.fromHex("#25D366"),
    Callback = function()
        setclipboard("https://wa.me/yourwalink")
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
    Title = "Air Walk", Desc = "Berjalan di udara", Icon = "footprints", Value = false,
    Callback = function(state)
        if state then
            airWalkConn = RunService.Stepped:Connect(function()
                local hum = getHum()
                if hum then hum:SetStateEnabled(Enum.HumanoidStateType.Freefall, false) end
            end)
        else
            if airWalkConn then airWalkConn:Disconnect() airWalkConn = nil end
            local hum = getHum()
            if hum then hum:SetStateEnabled(Enum.HumanoidStateType.Freefall, true) end
        end
    end
})

SectionMovement:Toggle({
    Title = "Infinite Jump", Desc = "Lompat tanpa batas", Icon = "chevrons-up", Value = false,
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
    Title = "No Clip", Desc = "Tembus dinding", Icon = "layers", Value = false,
    Callback = function(state)
        if state then
            noClipConn = RunService.Stepped:Connect(function()
                local chr = getChar()
                if chr then
                    for _, p in pairs(chr:GetDescendants()) do
                        if p:IsA("BasePart") then p.CanCollide = false end
                    end
                end
            end)
        else
            if noClipConn then noClipConn:Disconnect() noClipConn = nil end
            local chr = getChar()
            if chr then
                for _, p in pairs(chr:GetDescendants()) do
                    if p:IsA("BasePart") then p.CanCollide = true end
                end
            end
        end
    end
})

SectionMovement:Divider()

flyToggle = SectionMovement:Toggle({
    Title = "Fly", Desc = "Terbang mengikuti arah kamera", Icon = "plane", Value = false,
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
            hum:ChangeState(Enum.HumanoidStateType.Swimming)
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
    Title = "Fly Speed", Desc = "Kecepatan terbang | Default: 10", Icon = "wind",
    Step = 1, Value = { Min = 1, Max = 200, Default = 10 }, IsTooltip = true, IsTextbox = true,
    Callback = function(v) flySpeed = v end
})

SectionMovement:Divider()

SectionMovement:Toggle({
    Title = "Bunny Hop", Desc = "Auto lompat saat berlari", Icon = "rabbit", Value = false,
    Callback = function(state)
        bunnyhopEnabled = state bunnyhopIsJumping = false
        if state then startBunnyhopLoop() end
    end
})

SectionMovement:Slider({
    Title = "Run Speed Threshold", Desc = "Kecepatan minimum bunny hop | Default: 16", Icon = "gauge",
    Step = 1, Value = { Min = 1, Max = 100, Default = 16 }, IsTooltip = true, IsTextbox = true,
    Callback = function(v) RUN_SPEED_THRESHOLD = v end
})

SectionMovement:Divider()

local jumpPowerEnabled = false
local jumpPowerValue = 50

SectionMovement:Toggle({
    Title = "Jump Power", Desc = "Aktifkan custom jump power", Icon = "arrow-up", Value = false,
    Callback = function(state)
        jumpPowerEnabled = state
        local hum = getHum()
        if hum then hum.JumpPower = state and jumpPowerValue or 50 end
    end
})

SectionMovement:Slider({
    Title = "Jump Power", Desc = "Nilai jump power | Default: 50", Icon = "arrow-up-circle",
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
    Title = "Walk Speed", Desc = "Aktifkan custom walk speed", Icon = "gauge", Value = false,
    Callback = function(state)
        walkSpeedEnabled = state
        local hum = getHum()
        if hum then hum.WalkSpeed = state and walkSpeedValue or 16 end
    end
})

SectionMovement:Slider({
    Title = "Walk Speed", Desc = "Kecepatan berjalan | Default: 16", Icon = "gauge",
    Step = 1, Value = { Min = 1, Max = 500, Default = 16 }, IsTooltip = true, IsTextbox = true,
    Callback = function(v)
        walkSpeedValue = v
        if walkSpeedEnabled then
            local hum = getHum()
            if hum then hum.WalkSpeed = v end
        end
    end
})

local SectionPlayer2 = TabPlayer:Section({ Title = "Player", Icon = "shield", Opened = true })

local godmodeConn = nil
local godmodeEnabled = false

SectionPlayer2:Toggle({
    Title = "Freeze", Desc = "Bekukan karakter di tempat", Icon = "snowflake", Value = false,
    Callback = function(state)
        local hrp = getHRP()
        if hrp then hrp.Anchored = state end
    end
})

SectionPlayer2:Toggle({
    Title = "Godmode", Desc = "Karakter tidak bisa mati", Icon = "shield", Value = false,
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
    Title = "No Fall Damage", Desc = "Tidak ada damage jatuh", Icon = "shield-check", Value = false,
    Callback = function(state)
        local hum = getHum()
        if hum then hum:SetStateEnabled(Enum.HumanoidStateType.FallingDown, not state) end
    end
})

SectionPlayer2:Toggle({
    Title = "No Gravity", Desc = "Karakter mengambang", Icon = "orbit", Value = false,
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
    Title = "Anti Fling", Desc = "Cegah di-fling oleh pemain lain", Icon = "shield-off", Value = false,
    Callback = function(state)
        antiFlingEnabled = state
        if state then
            startAntiFling()
            WindUI:Notify({ Title = "Anti Fling", Content = "Anti Fling aktif!", Duration = 2, Icon = "shield-off" })
        else
            if antiFlingConn then antiFlingConn:Disconnect() antiFlingConn = nil end
            restoreAntiFling()
            WindUI:Notify({ Title = "Anti Fling", Content = "Anti Fling nonaktif.", Duration = 2, Icon = "shield" })
        end
    end
})

local SectionInvis = TabPlayer:Section({ Title = "Invisible", Icon = "eye-off", Opened = true })

SectionInvis:Toggle({
    Title = "Invisible V1", Desc = "Teleport bawah tanah setiap frame", Icon = "eye-off", Value = false,
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
                hrp.CFrame = origCF * CFrame.new(0,-200000,0)
                hum.CameraOffset = (origCF * CFrame.new(0,-200000,0)):ToObjectSpace(CFrame.new(origCF.Position)).Position
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
    Title = "Invisible V2", Desc = "Teleport ke langit setiap frame", Icon = "eye-off", Value = false,
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
                hrp.CFrame = origCF * CFrame.new(0,200000,0)
                hum.CameraOffset = (origCF * CFrame.new(0,200000,0)):ToObjectSpace(CFrame.new(origCF.Position)).Position
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
    Title = "Choice Player", Desc = "Pilih pemain yang akan jadi target",
    Values = getPlayerDisplayNames(), Value = "",
    Callback = function(value)
        targetPlayer = playerListMap[value] or nil
    end
})

SectionTarget:Button({
    Title = "Refresh", Desc = "Refresh daftar player", Icon = "refresh-cw",
    Callback = function()
        targetDropdown:Refresh(getPlayerDisplayNames())
        WindUI:Notify({ Title = "Refresh", Content = "Daftar player diperbarui.", Duration = 2, Icon = "refresh-cw" })
    end
})

local targetDisplay = SectionTarget:Paragraph({
    Title = "Current Target", Desc = "Belum ada target", Icon = "circle-off",
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
    Title = "DOGGY NORMAL", Desc = "Membelakangi target di DEPAN dengan animasi doggy",
    Icon = "dog", Value = false,
    Callback = function(state)
        if state then
            if not targetPlayer then
                WindUI:Notify({ Title = "Error", Content = "Pilih target dulu!", Duration = 2, Icon = "alert-circle" }) return
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
    Title = "DOGGY LICK", Desc = "Menghadap target di DEPAN dengan animasi doggy",
    Icon = "dog", Value = false,
    Callback = function(state)
        if state then
            if not targetPlayer then
                WindUI:Notify({ Title = "Error", Content = "Pilih target dulu!", Duration = 2, Icon = "alert-circle" }) return
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
                    local frontPos = targetPos + getPlayerHRP(targetPlayer).CFrame.LookVector * 2.7
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
    Title = "ANNOY POKE", Desc = "Mengikuti target di BELAKANG dengan animasi shake hip",
    Icon = "hand", Value = false,
    Callback = function(state)
        if state then
            if not targetPlayer then
                WindUI:Notify({ Title = "Error", Content = "Pilih target dulu!", Duration = 2, Icon = "alert-circle" }) return
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
                    local behindPos = targetPos - getPlayerHRP(targetPlayer).CFrame.LookVector * 1.3
                    getPlayerHRP(LocalPlayer).CFrame = CFrame.new(behindPos, targetPos)
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

FlingSection:Paragraph({
    Title = "Cara Pakai Fling",
    Desc = "Aktifkan toggle lalu equip tool dari Backpack, klik/sentuh player untuk fling.",
    Icon = "info",
})

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
    Title = "PUNCH FLING (Tool)", Desc = "Tool punch - equip lalu klik player untuk fling",
    Icon = "hand", Value = false,
    Callback = function(state)
        punchActive = state
        if state then
            createPunchFlingFixed()
            WindUI:Notify({ Title = "Punch Fling", Content = "Tool 'PiePunch' di Backpack! Equip lalu klik.", Duration = 4, Icon = "hand" })
        else
            removePunchTool()
            WindUI:Notify({ Title = "Punch Fling", Content = "Dinonaktifkan.", Duration = 2, Icon = "x" })
        end
    end
})

FlingSection:Toggle({
    Title = "SAITAMA FLING (Tool)", Desc = "Tool saitama punch - equip lalu klik player untuk fling",
    Icon = "zap", Value = false,
    Callback = function(state)
        saitamaActive = state
        if state then
            createSaitamaFlingFixed()
            WindUI:Notify({ Title = "Saitama Fling", Content = "Tool 'PieSaitama' di Backpack! Equip lalu klik.", Duration = 4, Icon = "zap" })
        else
            removeSaitamaTool()
            WindUI:Notify({ Title = "Saitama Fling", Content = "Dinonaktifkan.", Duration = 2, Icon = "x" })
        end
    end
})

FlingSection:Toggle({
    Title = "DROP KICK FLING (Tool)", Desc = "Tool dropkick - equip lalu klik player untuk fling",
    Icon = "footprints", Value = false,
    Callback = function(state)
        kickActive = state
        if state then
            createKickFlingFixed()
            WindUI:Notify({ Title = "Drop Kick Fling", Content = "Tool 'PieKick' di Backpack! Equip lalu klik.", Duration = 4, Icon = "footprints" })
        else
            removeKickTool()
            WindUI:Notify({ Title = "Drop Kick Fling", Content = "Dinonaktifkan.", Duration = 2, Icon = "x" })
        end
    end
})

FlingSection:Slider({
    Title = "Fling Power", Desc = "Kekuatan fling | Default: 50", Icon = "zap",
    Step = 5, Value = { Min = 1, Max = 500, Default = 50 }, IsTooltip = true, IsTextbox = true,
    Callback = function(v) PunchPower = v end
})

FlingSection:Slider({
    Title = "Fling Time", Desc = "Durasi fling dalam frames | Default: 30", Icon = "timer",
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
            for _, v in ipairs(data) do
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
        local response = game:HttpGet("https://raw.githubusercontent.com/Joystickplays/AFEM/refs/heads/main/emotes.json")
        local data = HttpService:JSONDecode(response)
        if type(data) == "table" then
            for _, v in ipairs(data) do
                if type(v) == "table" and not v["_comment"] then
                    local name = v.name
                    local id = tonumber(v.id)
                    if name and id then table.insert(FullEmoteList, { Title = tostring(name), Id = id }) end
                end
            end
        end
    end)
end

loadVexroEmotes()
loadAFEMEmotes()

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

local function playEmote(data, loopState, walkState)
    if currentEmoteTrack then
        pcall(function() currentEmoteTrack:Stop(0.1) end)
        currentEmoteTrack = nil
    end
    if walkEmoteConn then walkEmoteConn:Disconnect() walkEmoteConn = nil end
    local animator = getAnimator()
    if not animator then return end
    task.spawn(function()
        local animObj = loadEmoteObj(data.Id)
        local ok2, track = pcall(function() return animator:LoadAnimation(animObj) end)
        if not ok2 or not track then
            WindUI:Notify({ Title = "Error", Content = "Gagal load emote!", Duration = 2, Icon = "alert-circle" }) return
        end
        track.Priority = Enum.AnimationPriority.Action4
        track.Looped = loopState
        track:Play(0.15)
        currentEmoteTrack = track

        if walkState then
            local conn
            conn = RunService.Heartbeat:Connect(function()
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
                currentEmoteTrack = nil
                pcall(function() conn:Disconnect() end)
            end)
        end
    end)
end

local function stopEmote()
    if walkEmoteConn then walkEmoteConn:Disconnect() walkEmoteConn = nil end
    if customWalkEmoteConn then customWalkEmoteConn:Disconnect() customWalkEmoteConn = nil end
    if currentEmoteTrack then
        pcall(function() currentEmoteTrack:Stop(0.2) end)
        currentEmoteTrack = nil
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

local SectionAnim = TabAnimations:Section({ Title = "Animations", Icon = "person-standing", Opened = true })

SectionAnim:Dropdown({
    Title = "Daftar Animasi", Desc = "Pilih animation pack karakter",
    Values = animNameList, Value = "", SearchBarEnabled = true,
    Callback = function(v) selectedAnimation = v end
})

local HStackAnimBtn = SectionAnim:HStack({ AutoSpace = true })
HStackAnimBtn:Button({
    Title = "Apply", Icon = "check",
    Callback = function()
        if not selectedAnimation or selectedAnimation == "" then
            WindUI:Notify({ Title = "Error", Content = "Pilih animasi dulu!", Duration = 2, Icon = "alert-circle" }) return
        end
        local data = getAnimData(selectedAnimation)
        if not data then
            WindUI:Notify({ Title = "Error", Content = "Animasi tidak ditemukan!", Duration = 2, Icon = "alert-circle" }) return
        end
        applyAnimation(data)
        WindUI:Notify({ Title = "Animations", Content = "Animasi '" .. selectedAnimation .. "' diterapkan!", Duration = 2, Icon = "check" })
    end
})
HStackAnimBtn:Button({
    Title = "Reset", Icon = "refresh-cw",
    Callback = function()
        resetAnimation() selectedAnimation = nil
        WindUI:Notify({ Title = "Animations", Content = "Animasi dikembalikan ke default.", Duration = 2, Icon = "refresh-cw" })
    end
})

local SectionEmote = TabAnimations:Section({ Title = "Emote", Icon = "drama", Opened = true })

local emoteSearchValue = ""
SectionEmote:Input({
    Title = "Search", Desc = "Ketik nama emote", Placeholder = "Contoh: Dance", Value = "",
    Callback = function(v) emoteSearchValue = v end
})

local emoteDropdown
local emotePageParagraph

local function refreshEmoteDropdown()
    local totalPages = getTotalEmotePages(emoteSearchResults)
    emotePage = math.clamp(emotePage, 1, totalPages)
    emoteDropdown:Refresh(getEmotePage(emoteSearchResults, emotePage))
    emotePageParagraph:SetTitle("Halaman Emote")
    emotePageParagraph:SetDesc("Hal. " .. emotePage .. " / " .. totalPages .. " | Hasil: " .. #emoteSearchResults .. " emote")
    selectedEmote = nil
end

local HStackEmoteSearch = SectionEmote:HStack({ AutoSpace = true })
HStackEmoteSearch:Button({
    Title = "Search", Icon = "search",
    Callback = function()
        emoteSearchResults = getFilteredEmotes(emoteSearchValue)
        emotePage = 1 refreshEmoteDropdown()
        if #emoteSearchResults == 0 then
            WindUI:Notify({ Title = "Emote", Content = "Tidak ada emote '" .. emoteSearchValue .. "'", Duration = 2, Icon = "alert-circle" })
        else
            WindUI:Notify({ Title = "Emote", Content = "Ditemukan " .. #emoteSearchResults .. " emote", Duration = 2, Icon = "search" })
        end
    end
})
HStackEmoteSearch:Button({
    Title = "Reset Search", Icon = "refresh-cw",
    Callback = function()
        emoteSearchValue = "" emoteSearchResults = FullEmoteList emotePage = 1 refreshEmoteDropdown()
        WindUI:Notify({ Title = "Emote", Content = "Menampilkan semua emote.", Duration = 2, Icon = "refresh-cw" })
    end
})

SectionEmote:Divider()

emotePageParagraph = SectionEmote:Paragraph({
    Title = "Halaman Emote",
    Desc = "Hal. 1 / " .. getTotalEmotePages(FullEmoteList) .. " | Total: " .. #FullEmoteList .. " emote",
    Icon = "list",
})

emoteDropdown = SectionEmote:Dropdown({
    Title = "Daftar Emote", Desc = "Pilih emote untuk dimainkan",
    Values = getEmotePage(FullEmoteList, 1), Value = "",
    Callback = function(v) selectedEmote = v end
})

local HStackEmoteNav = SectionEmote:HStack({ AutoSpace = true })
HStackEmoteNav:Button({
    Title = "< Previous",
    Callback = function()
        if emotePage <= 1 then
            WindUI:Notify({ Title = "Emote", Content = "Sudah di halaman pertama!", Duration = 2, Icon = "alert-circle" }) return
        end
        emotePage = emotePage - 1 refreshEmoteDropdown()
        WindUI:Notify({ Title = "Emote", Content = "Halaman " .. emotePage, Duration = 1, Icon = "chevron-left" })
    end
})
HStackEmoteNav:Button({
    Title = "Next >",
    Callback = function()
        if emotePage >= getTotalEmotePages(emoteSearchResults) then
            WindUI:Notify({ Title = "Emote", Content = "Sudah di halaman terakhir!", Duration = 2, Icon = "alert-circle" }) return
        end
        emotePage = emotePage + 1 refreshEmoteDropdown()
        WindUI:Notify({ Title = "Emote", Content = "Halaman " .. emotePage, Duration = 1, Icon = "chevron-right" })
    end
})

SectionEmote:Divider()

local HStackEmotePlay = SectionEmote:HStack({ AutoSpace = true })
HStackEmotePlay:Button({
    Title = "Apply", Icon = "play",
    Callback = function()
        if not selectedEmote or selectedEmote == "" then
            WindUI:Notify({ Title = "Error", Content = "Pilih emote dulu!", Duration = 2, Icon = "alert-circle" }) return
        end
        local data = getEmoteData(selectedEmote)
        if not data then
            WindUI:Notify({ Title = "Error", Content = "Emote tidak ditemukan!", Duration = 2, Icon = "alert-circle" }) return
        end
        playEmote(data, emoteLoopEnabled, emoteWalkEnabled)
        WindUI:Notify({ Title = "Emote", Content = "Memainkan '" .. selectedEmote .. "'", Duration = 2, Icon = "play" })
    end
})
HStackEmotePlay:Button({
    Title = "Stop", Icon = "square",
    Callback = function()
        stopEmote()
        WindUI:Notify({ Title = "Emote", Content = "Emote dihentikan.", Duration = 2, Icon = "square" })
    end
})

SectionEmote:Toggle({
    Title = "Loop", Desc = "Ulangi emote terus menerus", Icon = "repeat", Value = true,
    Callback = function(state)
        emoteLoopEnabled = state
        if currentEmoteTrack then currentEmoteTrack.Looped = state end
    end
})

SectionEmote:Toggle({
    Title = "Walking Animation", Desc = "Emote tetap berjalan saat bergerak", Icon = "footprints", Value = false,
    Callback = function(state) emoteWalkEnabled = state end
})

local SectionMoreAnim = TabAnimations:Section({ Title = "Custom Emote", Icon = "plus-circle", Opened = true })

SectionMoreAnim:Input({
    Title = "Nama Emote", Desc = "Nama untuk emote custom", Placeholder = "Contoh: My Emote", Value = "",
    Callback = function(v) customEmoteNameValue = v end
})
SectionMoreAnim:Input({
    Title = "Animation ID", Desc = "Animation ID emote Roblox", Placeholder = "Contoh: 507770818", Value = "",
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
    Title = "Daftar Custom Emote", Desc = "Emote custom tersimpan",
    Values = buildCustomEmoteNames(), Value = "",
    Callback = function(v) selectedCustomEmote = v end
})

local HStackCustomBtn = SectionMoreAnim:HStack({ AutoSpace = true })
HStackCustomBtn:Button({
    Title = "Save", Icon = "save",
    Callback = function()
        if customEmoteNameValue == "" then
            WindUI:Notify({ Title = "Error", Content = "Masukkan nama emote dulu!", Duration = 2, Icon = "alert-circle" }) return
        end
        local id = tonumber(customEmoteAnimIdValue)
        if not id then
            WindUI:Notify({ Title = "Error", Content = "Animation ID harus angka!", Duration = 2, Icon = "alert-circle" }) return
        end
        customEmotes[customEmoteNameValue] = id
        saveCustomEmotes() customEmoteDropdown:Refresh(buildCustomEmoteNames())
        WindUI:Notify({ Title = "Custom Emote", Content = "Emote '" .. customEmoteNameValue .. "' disimpan!", Duration = 2, Icon = "save" })
    end
})
HStackCustomBtn:Button({
    Title = "Refresh", Icon = "refresh-cw",
    Callback = function()
        customEmoteDropdown:Refresh(buildCustomEmoteNames())
        WindUI:Notify({ Title = "Custom Emote", Content = "Daftar diperbarui.", Duration = 2, Icon = "refresh-cw" })
    end
})
HStackCustomBtn:Button({
    Title = "Delete", Icon = "trash",
    Callback = function()
        if not selectedCustomEmote or not customEmotes[selectedCustomEmote] then
            WindUI:Notify({ Title = "Error", Content = "Pilih emote custom dulu!", Duration = 2, Icon = "alert-circle" }) return
        end
        customEmotes[selectedCustomEmote] = nil selectedCustomEmote = nil
        saveCustomEmotes() customEmoteDropdown:Refresh(buildCustomEmoteNames())
        WindUI:Notify({ Title = "Custom Emote", Content = "Emote dihapus.", Duration = 2, Icon = "trash" })
    end
})

SectionMoreAnim:Divider()

local HStackCustomPlay = SectionMoreAnim:HStack({ AutoSpace = true })
HStackCustomPlay:Button({
    Title = "Apply", Icon = "play",
    Callback = function()
        if not selectedCustomEmote or not customEmotes[selectedCustomEmote] then
            WindUI:Notify({ Title = "Error", Content = "Pilih emote custom dulu!", Duration = 2, Icon = "alert-circle" }) return
        end
        playEmote({ Title = selectedCustomEmote, Id = customEmotes[selectedCustomEmote] }, customEmoteLoopEnabled, customEmoteWalkEnabled)
        WindUI:Notify({ Title = "Custom Emote", Content = "Memainkan '" .. selectedCustomEmote .. "'", Duration = 2, Icon = "play" })
    end
})
HStackCustomPlay:Button({
    Title = "Stop", Icon = "square",
    Callback = function()
        stopEmote()
        WindUI:Notify({ Title = "Custom Emote", Content = "Emote dihentikan.", Duration = 2, Icon = "square" })
    end
})

SectionMoreAnim:Toggle({
    Title = "Loop", Desc = "Ulangi custom emote terus menerus", Icon = "repeat", Value = true,
    Callback = function(state)
        customEmoteLoopEnabled = state
        if currentEmoteTrack then currentEmoteTrack.Looped = state end
    end
})

SectionMoreAnim:Toggle({
    Title = "Walking Animation", Desc = "Custom emote tetap berjalan saat bergerak", Icon = "footprints", Value = false,
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
    Title = "Choice Player", Desc = "Pilih player untuk teleport",
    Values = getPlayerNames(), Value = "", SearchBarEnabled = true,
    Callback = function(v) selectedPlayer = v end
})

local HStackTpPlayer = SectionTpPlayer:HStack({ AutoSpace = true })
HStackTpPlayer:Button({
    Title = "Refresh", Icon = "refresh-cw",
    Callback = function()
        playerDropdown:Refresh(getPlayerNames())
        WindUI:Notify({ Title = "Teleport", Content = "Daftar player diperbarui.", Duration = 2, Icon = "refresh-cw" })
    end
})
HStackTpPlayer:Button({
    Title = "Teleport", Icon = "map-pin",
    Callback = function()
        if not selectedPlayer then
            WindUI:Notify({ Title = "Error", Content = "Pilih player dulu!", Duration = 2, Icon = "alert-circle" }) return
        end
        local username = playerList[selectedPlayer]
        local target = Players:FindFirstChild(username)
        if target and target.Character and target.Character:FindFirstChild("HumanoidRootPart") then
            local hrp = getHRP()
            if hrp then
                hrp.CFrame = target.Character.HumanoidRootPart.CFrame + Vector3.new(3, 0, 0)
                WindUI:Notify({ Title = "Teleport", Content = "Teleport ke " .. selectedPlayer, Duration = 2, Icon = "map-pin" })
            end
        else
            WindUI:Notify({ Title = "Error", Content = "Player tidak ditemukan!", Duration = 2, Icon = "alert-circle" })
        end
    end
})

local SectionTpPlace = TabTeleport:Section({ Title = "Place", Icon = "map", Opened = true })

local placeNameInputValue = ""

local placeDropdown = SectionTpPlace:Dropdown({
    Title = "Pilih Place", Desc = "Pilih tempat yang sudah disimpan",
    Values = {}, Value = "",
    Callback = function(v) selectedPlace = v end
})

SectionTpPlace:Input({
    Title = "Nama Tempat", Desc = "Nama tempat (kosong = auto)",
    Placeholder = "Nama tempat...", Value = "",
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
            WindUI:Notify({ Title = "Error", Content = "Karakter tidak ditemukan!", Duration = 2, Icon = "alert-circle" }) return
        end
        savedPlacesCount = savedPlacesCount + 1
        local name = (placeNameInputValue ~= "" and placeNameInputValue) or ("Place " .. savedPlacesCount)
        if savedPlaces[name] then name = name .. " (" .. savedPlacesCount .. ")" end
        savedPlaces[name] = hrp.CFrame
        table.insert(savedPlacesOrder, name)
        placeDropdown:Refresh(getOrderedPlaceKeys())
        WindUI:Notify({ Title = "Save", Content = "Tempat disimpan: " .. name, Duration = 2, Icon = "save" })
    end
})
HStackTpPlace:Button({
    Title = "Refresh", Icon = "refresh-cw",
    Callback = function()
        placeDropdown:Refresh(getOrderedPlaceKeys())
        WindUI:Notify({ Title = "Teleport", Content = "Daftar tempat diperbarui.", Duration = 2, Icon = "refresh-cw" })
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
            WindUI:Notify({ Title = "Delete", Content = "Tempat dihapus.", Duration = 2, Icon = "trash" })
        else
            WindUI:Notify({ Title = "Error", Content = "Pilih tempat dulu!", Duration = 2, Icon = "alert-circle" })
        end
    end
})

SectionTpPlace:Divider()

SectionTpPlace:Button({
    Title = "Teleport ke Place", Desc = "Teleport ke tempat yang dipilih", Icon = "map-pin",
    Callback = function()
        if not selectedPlace or not savedPlaces[selectedPlace] then
            WindUI:Notify({ Title = "Error", Content = "Pilih tempat dulu!", Duration = 2, Icon = "alert-circle" }) return
        end
        local hrp = getHRP()
        if hrp then
            hrp.CFrame = savedPlaces[selectedPlace]
            WindUI:Notify({ Title = "Teleport", Content = "Teleport ke " .. selectedPlace, Duration = 2, Icon = "map-pin" })
        else
            WindUI:Notify({ Title = "Error", Content = "Karakter tidak ditemukan!", Duration = 2, Icon = "alert-circle" })
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
SectionESP:Toggle({ Title = "ESP",           Desc = "Enable / Disable semua ESP",       Icon = "scan",        Value = false, Callback = function(v) espSettings.Enabled=v refreshAllESP() end })
SectionESP:Toggle({ Title = "ESP Box",       Desc = "Kotak di sekitar player",           Icon = "square",      Value = false, Callback = function(v) espSettings.Box=v end })
SectionESP:Toggle({ Title = "ESP Name",      Desc = "Tampilkan nama player",             Icon = "user",        Value = false, Callback = function(v) espSettings.Name=v end })
SectionESP:Toggle({ Title = "ESP Health",    Desc = "Tampilkan health bar player",       Icon = "heart",       Value = false, Callback = function(v) espSettings.Health=v end })
SectionESP:Toggle({ Title = "ESP Distance",  Desc = "Tampilkan jarak ke player",         Icon = "ruler",       Value = false, Callback = function(v) espSettings.Distance=v end })
SectionESP:Toggle({ Title = "ESP Tracer",    Desc = "Garis dari bawah layar ke player",  Icon = "navigation",  Value = false, Callback = function(v) espSettings.Tracer=v end })
SectionESP:Toggle({ Title = "ESP Highlight", Desc = "Highlight karakter player",         Icon = "highlighter", Value = false, Callback = function(v)
    espSettings.Highlight=v
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer then updateESPHighlight(p,v) end
    end
end })

local SectionVisualMore = TabVisuals:Section({ Title = "World", Icon = "globe", Opened = true })

local freecamEnabled = false

SectionVisualMore:Toggle({
    Title = "Freecam", Desc = "Kamera bebas terbang", Icon = "video", Value = false,
    Callback = function(state)
        freecamEnabled = state
        local cam = workspace.CurrentCamera
        if state then
            cam.CameraType = Enum.CameraType.Scriptable
            task.spawn(function()
                while freecamEnabled do
                    RunService.RenderStepped:Wait()
                    local moveVec = Vector3.zero
                    if UserInputService:IsKeyDown(Enum.KeyCode.W) then moveVec = moveVec + cam.CFrame.LookVector end
                    if UserInputService:IsKeyDown(Enum.KeyCode.S) then moveVec = moveVec - cam.CFrame.LookVector end
                    if UserInputService:IsKeyDown(Enum.KeyCode.A) then moveVec = moveVec - cam.CFrame.RightVector end
                    if UserInputService:IsKeyDown(Enum.KeyCode.D) then moveVec = moveVec + cam.CFrame.RightVector end
                    if UserInputService:IsKeyDown(Enum.KeyCode.E) then moveVec = moveVec + Vector3.new(0,1,0) end
                    if UserInputService:IsKeyDown(Enum.KeyCode.Q) then moveVec = moveVec - Vector3.new(0,1,0) end
                    if moveVec.Magnitude > 0 then cam.CFrame = cam.CFrame + moveVec.Unit * 20 * 0.016 end
                end
                cam.CameraType = Enum.CameraType.Custom
            end)
        else
            cam.CameraType = Enum.CameraType.Custom
        end
    end
})

SectionVisualMore:Toggle({
    Title = "Fullbright", Desc = "Terangi semua area", Icon = "sun", Value = false,
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
    Title = "No Fog", Desc = "Hilangkan fog", Icon = "cloud-off", Value = false,
    Callback = function(state)
        local L = game:GetService("Lighting")
        if state then L.FogEnd=100000 L.FogStart=100000
        else L.FogEnd=100000 L.FogStart=0 end
    end
})

SectionVisualMore:Toggle({
    Title = "No Skybox", Desc = "Hilangkan skybox", Icon = "image-off", Value = false,
    Callback = function(state)
        local sky = game:GetService("Lighting"):FindFirstChildOfClass("Sky")
        if sky then sky.Enabled = not state end
    end
})

SectionVisualMore:Toggle({
    Title = "Xray", Desc = "Lihat melalui objek", Icon = "scan-line", Value = false,
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
    Title = "Crosshair", Desc = "Tampilkan crosshair di tengah layar", Icon = "crosshair", Value = false,
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
    Title = "Auto Rejoin", Desc = "Auto masuk ulang saat disconnect", Icon = "refresh-cw", Value = false,
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
    Title = "Anti AFK", Desc = "Mencegah kick karena AFK", Icon = "activity", Value = false,
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
    Title = "Rejoin", Desc = "Masuk ulang ke game ini", Icon = "log-in",
    Callback = function() TeleportService:Teleport(game.PlaceId, LocalPlayer) end
})

SectionServerActions:Button({
    Title = "Server Hop", Desc = "Pindah ke server lain", Icon = "shuffle",
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
            WindUI:Notify({ Title = "Server Hop", Content = "Tidak ada server lain.", Duration = 3, Icon = "alert-circle" })
        end
    end
})

SectionServerActions:Button({
    Title = "Server Friend", Desc = "Pindah ke server yang ada teman", Icon = "users",
    Callback = function()
        local found = false
        for _, friend in ipairs(LocalPlayer:GetFriendsOnline()) do
            if friend.IsOnline and friend.PlaceId == game.PlaceId then
                pcall(function() TeleportService:TeleportToPlaceInstance(game.PlaceId, friend.GameId, LocalPlayer) end)
                found = true break
            end
        end
        if not found then
            WindUI:Notify({ Title = "Server Friend", Content = "Tidak ada teman online di game ini.", Duration = 3, Icon = "alert-circle" })
        end
    end
})

-- TAB: DEVTOOLS
local TabDevTools = Window:Tab({ Title = "DevTools", Icon = "code" })

local savedCoords = {} local savedCoordsOrder = {} local savedCoordsCount = 0
local selectedCoord = nil local coordNameValue = ""

local function buildCoordCode()
    if #savedCoordsOrder == 0 then return "-- Belum ada koordinat tersimpan" end
    local lines = { "-- Koordinat tersimpan:" }
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

local SectionCoords = TabDevTools:Section({ Title = "Koordinat", Icon = "map-pin", Opened = true })

local coordCodeBlock = SectionCoords:Code({
    Title = "Koordinat Tersimpan", Code = "-- Belum ada koordinat tersimpan",
    OnCopy = function() WindUI:Notify({ Title = "DevTools", Content = "Kode disalin!", Duration = 2, Icon = "copy" }) end
})

local coordDropdown = SectionCoords:Dropdown({
    Title = "Daftar Koordinat", Desc = "Pilih koordinat tersimpan",
    Values = {}, Value = "", SearchBarEnabled = true,
    Callback = function(v) selectedCoord = v end
})

SectionCoords:Input({
    Title = "Nama Koordinat", Desc = "Nama untuk koordinat yang akan disimpan",
    Placeholder = "Contoh: checkpoint1", Value = "",
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
    Title = "Save Koordinat", Desc = "Simpan posisi karakter saat ini", Icon = "save",
    Callback = function()
        local hrp = getHRP()
        if not hrp then
            WindUI:Notify({ Title = "Error", Content = "Karakter tidak ditemukan!", Duration = 2, Icon = "alert-circle" }) return
        end
        savedCoordsCount = savedCoordsCount + 1
        local name = (coordNameValue ~= "" and coordNameValue) or ("checkpoint"..savedCoordsCount)
        if savedCoords[name] then name = name.." ("..savedCoordsCount..")" end
        savedCoords[name] = hrp.CFrame
        table.insert(savedCoordsOrder, name)
        refreshCoordDropdown()
        WindUI:Notify({ Title = "DevTools", Content = "Koordinat '"..name.."' disimpan!", Duration = 2, Icon = "save" })
    end
})

SectionCoords:Button({
    Title = "Refresh", Desc = "Refresh daftar koordinat", Icon = "refresh-cw",
    Callback = function()
        refreshCoordDropdown()
        WindUI:Notify({ Title = "DevTools", Content = "Daftar diperbarui.", Duration = 2, Icon = "refresh-cw" })
    end
})

SectionCoords:Button({
    Title = "Delete Koordinat", Desc = "Hapus koordinat yang dipilih", Icon = "trash",
    Callback = function()
        if not selectedCoord or not savedCoords[selectedCoord] then
            WindUI:Notify({ Title = "Error", Content = "Pilih koordinat dulu!", Duration = 2, Icon = "alert-circle" }) return
        end
        savedCoords[selectedCoord] = nil
        for i, k in ipairs(savedCoordsOrder) do
            if k == selectedCoord then table.remove(savedCoordsOrder, i) break end
        end
        selectedCoord = nil refreshCoordDropdown()
        WindUI:Notify({ Title = "DevTools", Content = "Koordinat dihapus.", Duration = 2, Icon = "trash" })
    end
})

local SectionDevMore = TabDevTools:Section({ Title = "Tools", Icon = "terminal", Opened = true })

SectionDevMore:Button({
    Title = "Piehub Explorer", Desc = "Buka Piehub Explorer (Dex++)", Icon = "terminal",
    Callback = function()
        pcall(function()
            loadstring(game:HttpGet("https://raw.githubusercontent.com/Dylphiiee/PieHub/refs/heads/main/Un1ver%244l/dex.lua"))()
        end)
        WindUI:Notify({ Title = "DevTools", Content = "Piehub Explorer dibuka!", Duration = 2, Icon = "terminal" })
    end
})

-- TAB: CONFIG
local TabConfig = Window:Tab({ Title = "Config", Icon = "settings" })

local ConfigManager = Window.ConfigManager
local configInputValue = "" local selectedConfig = nil

local SectionConfigSave = TabConfig:Section({ Title = "Save & Load", Icon = "save", Opened = true })

SectionConfigSave:Input({
    Title = "Nama Config", Desc = "Masukkan nama config baru",
    Placeholder = "Contoh: myConfig", Value = "",
    Callback = function(v) configInputValue = v end
})

local function getConfigNames()
    local all = ConfigManager:AllConfigs() local names = {}
    for _, v in ipairs(all) do table.insert(names, v) end
    return names
end

local configDropdown = SectionConfigSave:Dropdown({
    Title = "Daftar Config", Desc = "Pilih config yang tersimpan",
    Values = getConfigNames(), Value = "", SearchBarEnabled = true,
    Callback = function(v) selectedConfig = v end
})

SectionConfigSave:Button({
    Title = "Save Config", Desc = "Simpan semua settingan saat ini", Icon = "save",
    Callback = function()
        local name = configInputValue ~= "" and configInputValue or "default"
        local cfg = ConfigManager:GetConfig(name) or ConfigManager:CreateConfig(name)
        cfg:Save() configDropdown:Refresh(getConfigNames())
        WindUI:Notify({ Title = "Config", Content = "Config '"..name.."' disimpan!", Duration = 2, Icon = "save" })
    end
})

SectionConfigSave:Button({
    Title = "Apply Config", Desc = "Terapkan config yang dipilih", Icon = "check",
    Callback = function()
        if not selectedConfig then
            WindUI:Notify({ Title = "Error", Content = "Pilih config dulu!", Duration = 2, Icon = "alert-circle" }) return
        end
        local cfg = ConfigManager:GetConfig(selectedConfig)
        if cfg then
            cfg:Load()
            WindUI:Notify({ Title = "Config", Content = "Config '"..selectedConfig.."' diterapkan!", Duration = 2, Icon = "check" })
        else
            WindUI:Notify({ Title = "Error", Content = "Config tidak ditemukan!", Duration = 2, Icon = "alert-circle" })
        end
    end
})

SectionConfigSave:Button({
    Title = "Refresh", Desc = "Refresh daftar config", Icon = "refresh-cw",
    Callback = function()
        configDropdown:Refresh(getConfigNames())
        WindUI:Notify({ Title = "Config", Content = "Daftar config diperbarui.", Duration = 2, Icon = "refresh-cw" })
    end
})

SectionConfigSave:Button({
    Title = "Delete Config", Desc = "Hapus config yang dipilih", Icon = "trash",
    Callback = function()
        if not selectedConfig then
            WindUI:Notify({ Title = "Error", Content = "Pilih config dulu!", Duration = 2, Icon = "alert-circle" }) return
        end
        ConfigManager:DeleteConfig(selectedConfig) selectedConfig = nil
        configDropdown:Refresh(getConfigNames())
        WindUI:Notify({ Title = "Config", Content = "Config dihapus.", Duration = 2, Icon = "trash" })
    end
})

-- RESPAWN HANDLER
LocalPlayer.CharacterAdded:Connect(function(char)
    -- Tunggu karakter benar-benar loaded
    local hum = char:WaitForChild("Humanoid", 10)
    local hrp = char:WaitForChild("HumanoidRootPart", 10)
    local animate = char:FindFirstChild("Animate")

    -- Tunggu sampai karakter benar-benar spawn di dunia
    local spawnWait = 0
    repeat
        task.wait(0.1)
        spawnWait = spawnWait + 0.1
    until (hrp and hrp.Position.Y > -100) or spawnWait > 5

    task.wait(0.5)

    -- Teleport ke tempat terakhir mati jika ada (dari !re)
    if lastDeathCFrame then
        local cf = lastDeathCFrame
        lastDeathCFrame = nil
        task.wait(0.3)
        local hrp2 = char:FindFirstChild("HumanoidRootPart")
        if hrp2 then hrp2.CFrame = cf end
    end

    task.wait(0.3)

    -- Fix fly
    flyEnabled = false
    pcall(function() flyToggle:Set(false) end)

    -- Fix freecam
    freecamEnabled = false
    local cam = workspace.CurrentCamera
    if cam then cam.CameraType = Enum.CameraType.Custom end

    -- Fix humanoid states - ini yang paling penting
    if hum then
        hum.PlatformStand = false

        -- Enable semua states termasuk jumping
        for _, st in ipairs(Enum.HumanoidStateType:GetEnumItems()) do
            pcall(function() hum:SetStateEnabled(st, true) end)
        end

        -- Pastikan jump state aktif secara eksplisit
        pcall(function()
            hum:SetStateEnabled(Enum.HumanoidStateType.Jumping, true)
            hum:SetStateEnabled(Enum.HumanoidStateType.Freefall, true)
            hum:SetStateEnabled(Enum.HumanoidStateType.Landed, true)
            hum:SetStateEnabled(Enum.HumanoidStateType.Running, true)
            hum:SetStateEnabled(Enum.HumanoidStateType.RunningNoPhysics, true)
            hum:SetStateEnabled(Enum.HumanoidStateType.GettingUp, true)
        end)

        -- Set state ke running agar karakter siap bergerak
        task.wait(0.1)
        pcall(function() hum:ChangeState(Enum.HumanoidStateType.RunningNoPhysics) end)

        if jumpPowerEnabled then hum.JumpPower = jumpPowerValue end
        if walkSpeedEnabled then hum.WalkSpeed = walkSpeedValue end
        if godmodeEnabled then
            hum.MaxHealth = math.huge
            hum.Health = math.huge
        end
    end

    -- Fix animate
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

    -- Reapply theme
    if currentAppliedTheme and currentAppliedTheme ~= "" then
        pcall(function() WindUI:SetTheme(currentAppliedTheme) end)
    end

    -- Recreate fling tools
    task.wait(0.5)
    if punchActive then createPunchFlingFixed() end
    if saitamaActive then createSaitamaFlingFixed() end
    if kickActive then createKickFlingFixed() end
end)

task.defer(function()
    TabAbout:Select()
end)
