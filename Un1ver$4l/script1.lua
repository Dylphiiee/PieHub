-- PieHub by Dylphiiee
local WindUI = loadstring(game:HttpGet("https://github.com/Footagesus/WindUI/releases/latest/download/main.lua"))()

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")
local LocalPlayer = Players.LocalPlayer

WindUI:SetNotificationLower(true)

-- ============================================================
-- WINDOW
-- ============================================================
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
    Title = "PieHub",
    Content = "Loaded! Press RightShift to toggle.",
    Duration = 4,
    Icon = "cookie",
})

Window:Tag({
    Title = "Dylphiiee",
    Icon = "user",
    Color = Color3.fromHex("#a78bfa"),
    Radius = 12
})

Window:Tag({
    Title = "V1.0.0",
    Icon = "rocket",
    Color = Color3.fromHex("#30ff6a"),
    Radius = 12
})

-- ============================================================
-- HELPERS
-- ============================================================
local function getChar() return LocalPlayer.Character end
local function getHum()
    local c = getChar()
    return c and c:FindFirstChildWhichIsA("Humanoid")
end
local function getHRP()
    local c = getChar()
    return c and c:FindFirstChild("HumanoidRootPart")
end

-- ============================================================
-- TAB: PLAYER
-- ============================================================
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

-- SECTION: MOVEMENT
local SectionMovement = TabPlayer:Section({ Title = "Movement", Icon = "footprints", Opened = true })

SectionMovement:Toggle({
    Title = "Air Walk",
    Desc = "Berjalan di udara",
    Icon = "footprints",
    Value = false,
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
    Title = "Infinite Jump",
    Desc = "Lompat tanpa batas",
    Icon = "chevrons-up",
    Value = false,
    Callback = function(state)
        if state then
            infJumpConn = game:GetService("UserInputService").JumpRequest:Connect(function()
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
    Desc = "Tembus dinding",
    Icon = "layers",
    Value = false,
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
    Title = "Fly",
    Desc = "Terbang mengikuti arah kamera",
    Icon = "plane",
    Value = false,
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
            chr.Animate.Disabled = false
            hum.PlatformStand = false
        else
            for _, st in ipairs(Enum.HumanoidStateType:GetEnumItems()) do
                pcall(function() hum:SetStateEnabled(st, false) end)
            end
            hum:ChangeState(Enum.HumanoidStateType.Swimming)
            chr.Animate.Disabled = true
            for _, t in ipairs(hum:GetPlayingAnimationTracks()) do t:AdjustSpeed(0) end

            local isR6 = hum.RigType == Enum.HumanoidRigType.R6
            local torso = isR6 and chr:FindFirstChild("Torso") or chr:FindFirstChild("UpperTorso")
            if not torso then return end

            hum.PlatformStand = true

            local bg = Instance.new("BodyGyro", torso)
            bg.P = 9e4
            bg.MaxTorque = Vector3.new(9e9, 9e9, 9e9)
            bg.CFrame = torso.CFrame

            local bv = Instance.new("BodyVelocity", torso)
            bv.Velocity = Vector3.new(0, 0.1, 0)
            bv.MaxForce = Vector3.new(9e9, 9e9, 9e9)

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
                        local flatMD = Vector3.new(md.X, 0, md.Z)
                        if flatMD.Magnitude > 0 then flatMD = flatMD.Unit end
                        local camFlat = Vector3.new(lookVec.X, 0, lookVec.Z)
                        if camFlat.Magnitude > 0 then camFlat = camFlat.Unit end
                        local camRight = Vector3.new(rightVec.X, 0, rightVec.Z)
                        if camRight.Magnitude > 0 then camRight = camRight.Unit end
                        moveDir = moveDir + lookVec * flatMD:Dot(camFlat)
                        moveDir = moveDir + camRight * flatMD:Dot(camRight)
                    end

                    if moveDir.Magnitude > 0 then moveDir = moveDir.Unit end
                    bv.Velocity = moveDir * flySpeed
                    bg.CFrame = camCF
                end
                bg:Destroy()
                bv:Destroy()
                local h3 = getHum()
                local c3 = getChar()
                if h3 then
                    h3.PlatformStand = false
                    for _, st in ipairs(Enum.HumanoidStateType:GetEnumItems()) do
                        pcall(function() h3:SetStateEnabled(st, true) end)
                    end
                end
                if c3 and c3:FindFirstChild("Animate") then
                    c3.Animate.Disabled = false
                end
            end)
        end
    end
})

SectionMovement:Slider({
    Title = "Fly Speed",
    Desc = "Kecepatan terbang | Default: 10",
    Icon = "wind",
    Step = 1,
    Value = { Min = 1, Max = 200, Default = 10 },
    IsTooltip = true,
    IsTextbox = true,
    Callback = function(v)
        flySpeed = v
    end
})

SectionMovement:Divider()

local jumpPowerEnabled = false
local jumpPowerValue = 50

SectionMovement:Toggle({
    Title = "Jump Power",
    Desc = "Aktifkan custom jump power",
    Icon = "arrow-up",
    Value = false,
    Callback = function(state)
        jumpPowerEnabled = state
        local hum = getHum()
        if hum then hum.JumpPower = state and jumpPowerValue or 50 end
    end
})

SectionMovement:Slider({
    Title = "Jump Power",
    Desc = "Nilai jump power | Default: 50",
    Icon = "arrow-up-circle",
    Step = 1,
    Value = { Min = 1, Max = 500, Default = 50 },
    IsTooltip = true,
    IsTextbox = true,
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
    Title = "Walk Speed",
    Desc = "Aktifkan custom walk speed",
    Icon = "gauge",
    Value = false,
    Callback = function(state)
        walkSpeedEnabled = state
        local hum = getHum()
        if hum then hum.WalkSpeed = state and walkSpeedValue or 16 end
    end
})

SectionMovement:Slider({
    Title = "Walk Speed",
    Desc = "Kecepatan berjalan | Default: 16",
    Icon = "gauge",
    Step = 1,
    Value = { Min = 1, Max = 500, Default = 16 },
    IsTooltip = true,
    IsTextbox = true,
    Callback = function(v)
        walkSpeedValue = v
        if walkSpeedEnabled then
            local hum = getHum()
            if hum then hum.WalkSpeed = v end
        end
    end
})


-- SECTION: PLAYER
local SectionPlayer2 = TabPlayer:Section({ Title = "Player", Icon = "shield", Opened = true })

SectionPlayer2:Toggle({
    Title = "Freeze",
    Desc = "Bekukan karakter di tempat",
    Icon = "snowflake",
    Value = false,
    Callback = function(state)
        local hrp = getHRP()
        if hrp then hrp.Anchored = state end
    end
})

SectionPlayer2:Toggle({
    Title = "Godmode",
    Desc = "Karakter tidak bisa mati",
    Icon = "shield",
    Value = false,
    Callback = function(state)
        local hum = getHum()
        if hum then
            if state then
                hum.MaxHealth = math.huge
                hum.Health = math.huge
            else
                hum.MaxHealth = 100
                hum.Health = 100
            end
        end
    end
})

SectionPlayer2:Toggle({
    Title = "No Fall Damage",
    Desc = "Tidak ada damage jatuh",
    Icon = "shield-check",
    Value = false,
    Callback = function(state)
        local hum = getHum()
        if hum then
            hum:SetStateEnabled(Enum.HumanoidStateType.FallingDown, not state)
        end
    end
})

SectionPlayer2:Toggle({
    Title = "No Gravity",
    Desc = "Karakter mengambang",
    Icon = "orbit",
    Value = false,
    Callback = function(state)
        local hrp = getHRP()
        if state then
            if hrp then
                local bg = Instance.new("BodyForce", hrp)
                bg.Name = "NoGravityForce"
                bg.Force = Vector3.new(0, workspace.Gravity * (hrp:GetMass()), 0)
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

-- SECTION: INVISIBLE
local SectionInvis = TabPlayer:Section({ Title = "Invisible", Icon = "eye-off", Opened = true })

SectionInvis:Toggle({
    Title = "Invisible V1",
    Desc = "Teleport bawah tanah setiap frame",
    Icon = "eye-off",
    Value = false,
    Callback = function(state)
        local chr = getChar()
        local hum = getHum()
        local hrp = getHRP()
        if not chr or not hum or not hrp then return end

        if state then
            invisV1Parts = {}
            for _, d in pairs(chr:GetDescendants()) do
                if d:IsA("BasePart") and d.Transparency == 0 then
                    table.insert(invisV1Parts, d)
                    d.Transparency = 0.5
                end
            end
            invisV1Conn = RunService.Heartbeat:Connect(function()
                if not getHRP() then return end
                local origCF = hrp.CFrame
                local origOffset = hum.CameraOffset
                hrp.CFrame = origCF * CFrame.new(0, -2000, 0)
                hum.CameraOffset = (origCF * CFrame.new(0, -2000, 0)):ToObjectSpace(CFrame.new(origCF.Position)).Position
                RunService.RenderStepped:Wait()
                hrp.CFrame = origCF
                hum.CameraOffset = origOffset
            end)
        else
            if invisV1Conn then invisV1Conn:Disconnect() invisV1Conn = nil end
            for _, p in pairs(invisV1Parts) do
                pcall(function() p.Transparency = 0 end)
            end
            invisV1Parts = {}
        end
    end
})

SectionInvis:Toggle({
    Title = "Invisible V2",
    Desc = "Teleport ke langit setiap frame",
    Icon = "eye-off",
    Value = false,
    Callback = function(state)
        local chr = getChar()
        local hum = getHum()
        local hrp = getHRP()
        if not chr or not hum or not hrp then return end

        if state then
            invisV2Parts = {}
            for _, d in pairs(chr:GetDescendants()) do
                if d:IsA("BasePart") and d.Transparency == 0 then
                    table.insert(invisV2Parts, d)
                    d.Transparency = 0.5
                end
            end
            invisV2Conn = RunService.Heartbeat:Connect(function()
                if not getHRP() then return end
                local origCF = hrp.CFrame
                local origOffset = hum.CameraOffset
                hrp.CFrame = origCF * CFrame.new(0, 2000, 0)
                hum.CameraOffset = (origCF * CFrame.new(0, 2000, 0)):ToObjectSpace(CFrame.new(origCF.Position)).Position
                RunService.RenderStepped:Wait()
                hrp.CFrame = origCF
                hum.CameraOffset = origOffset
            end)
        else
            if invisV2Conn then invisV2Conn:Disconnect() invisV2Conn = nil end
            for _, p in pairs(invisV2Parts) do
                pcall(function() p.Transparency = 0 end)
            end
            invisV2Parts = {}
        end
    end
})

-- ============================================================
-- TAB: SIZE
-- ============================================================
local TabSize = Window:Tab({ Title = "Size", Icon = "maximize" })

local currentScale = 1
local selectedScale = 1

local function scaleCharacter(newScale)
    local char = getChar()
    if not char then return false end

    local root = char:FindFirstChild("HumanoidRootPart")
    local hum = char:FindFirstChildWhichIsA("Humanoid")
    if not root or not hum then return false end

    newScale = math.clamp(newScale, 0.1, 30)
    local delta = newScale / currentScale
    if math.abs(delta - 1) < 0.001 then return true end

    local footParts = {"LeftFoot", "RightFoot", "LeftLeg", "RightLeg"}
    local lowestYBefore = math.huge
    for _, name in ipairs(footParts) do
        local foot = char:FindFirstChild(name)
        if foot and foot:IsA("BasePart") then
            local bottom = foot.Position.Y - (foot.Size.Y / 2)
            if bottom < lowestYBefore then lowestYBefore = bottom end
        end
    end
    if lowestYBefore == math.huge then
        for _, part in ipairs(char:GetDescendants()) do
            if part:IsA("BasePart") then
                local bottom = part.Position.Y - (part.Size.Y / 2)
                if bottom < lowestYBefore then lowestYBefore = bottom end
            end
        end
    end

    local partsData = {}
    for _, part in ipairs(char:GetDescendants()) do
        if part:IsA("BasePart") and part ~= root then
            local isHandle = part.Name == "Handle"
            local parentIsAcc = part.Parent:IsA("Accessory") or part.Parent:IsA("Tool")
            if not (isHandle and parentIsAcc) then
                local mesh = part:FindFirstChildWhichIsA("SpecialMesh")
                    or part:FindFirstChildWhichIsA("BlockMesh")
                    or part:FindFirstChildWhichIsA("CylinderMesh")
                table.insert(partsData, {
                    part = part,
                    size = part.Size,
                    relativeCF = root.CFrame:inverse() * part.CFrame,
                    mesh = mesh,
                    meshScale = mesh and Vector3.new(mesh.Scale.X, mesh.Scale.Y, mesh.Scale.Z) or nil
                })
            end
        end
    end

    local handleData = {}
    for _, child in ipairs(char:GetChildren()) do
        if child:IsA("Accessory") or child:IsA("Tool") then
            local handle = child:FindFirstChild("Handle")
            if handle then
                local mesh = handle:FindFirstChildWhichIsA("SpecialMesh")
                    or handle:FindFirstChildWhichIsA("BlockMesh")
                table.insert(handleData, {
                    part = handle,
                    size = handle.Size,
                    relativeCF = root.CFrame:inverse() * handle.CFrame,
                    mesh = mesh,
                    meshScale = mesh and Vector3.new(mesh.Scale.X, mesh.Scale.Y, mesh.Scale.Z) or nil
                })
            end
        end
    end

    local motorData = {}
    for _, motor in ipairs(char:GetDescendants()) do
        if motor:IsA("Motor6D") then
            table.insert(motorData, { motor = motor, c0 = motor.C0, c1 = motor.C1 })
        end
    end

    local anchoredState = {}
    for _, part in ipairs(char:GetDescendants()) do
        if part:IsA("BasePart") then
            anchoredState[part] = part.Anchored
            part.Anchored = true
        end
    end

    root.Size = root.Size * delta

    for _, data in ipairs(partsData) do
        local part = data.part
        part.Size = data.size * delta
        local scaledPos = data.relativeCF.Position * delta
        local rot = data.relativeCF - data.relativeCF.Position
        part.CFrame = root.CFrame * (CFrame.new(scaledPos) * rot)
        if data.mesh and data.meshScale then
            data.mesh.Scale = data.meshScale * delta
        end
    end

    for _, data in ipairs(handleData) do
        local part = data.part
        part.Size = data.size * delta
        local scaledPos = data.relativeCF.Position * delta
        local rot = data.relativeCF - data.relativeCF.Position
        part.CFrame = root.CFrame * (CFrame.new(scaledPos) * rot)
        if data.mesh and data.meshScale then
            data.mesh.Scale = data.meshScale * delta
        end
    end

    for _, data in ipairs(motorData) do
        local m = data.motor
        local c0rot = data.c0 - data.c0.Position
        local c1rot = data.c1 - data.c1.Position
        m.C0 = CFrame.new(data.c0.Position * delta) * c0rot
        m.C1 = CFrame.new(data.c1.Position * delta) * c1rot
    end

    for _, part in ipairs(char:GetDescendants()) do
        if part:IsA("BasePart") then
            part.Anchored = anchoredState[part] or false
        end
    end

    task.wait(0.05)

    local lowestYAfter = math.huge
    for _, name in ipairs(footParts) do
        local foot = char:FindFirstChild(name)
        if foot and foot:IsA("BasePart") then
            local bottom = foot.Position.Y - (foot.Size.Y / 2)
            if bottom < lowestYAfter then lowestYAfter = bottom end
        end
    end
    if lowestYAfter == math.huge then
        for _, part in ipairs(char:GetDescendants()) do
            if part:IsA("BasePart") then
                local bottom = part.Position.Y - (part.Size.Y / 2)
                if bottom < lowestYAfter then lowestYAfter = bottom end
            end
        end
    end

    local diff = lowestYBefore - lowestYAfter
    root.CFrame = root.CFrame + Vector3.new(0, diff, 0)

    currentScale = newScale
    return true
end

local SectionEnlarge = TabSize:Section({ Title = "Enlarge Size", Icon = "maximize-2", Opened = true })

local enlargeSlider = SectionEnlarge:Slider({
    Title = "Perbesar Karakter",
    Desc = "Ukuran 1x - 30x | Default: 1",
    Icon = "maximize-2",
    Step = 0.1,
    Value = { Min = 1, Max = 30, Default = 1 },
    IsTooltip = true,
    IsTextbox = true,
    Callback = function(v)
        selectedScale = v
    end
})

SectionEnlarge:Button({
    Title = "Apply Perbesar",
    Desc = "Terapkan ukuran besar",
    Icon = "check",
    Callback = function()
        local success = scaleCharacter(selectedScale)
        if success then
            WindUI:Notify({ Title = "Size", Content = "Ukuran menjadi " .. selectedScale .. "x", Duration = 2, Icon = "check" })
        else
            WindUI:Notify({ Title = "Error", Content = "Karakter tidak ditemukan!", Duration = 2, Icon = "alert-circle" })
        end
    end
})

local SectionReduce = TabSize:Section({ Title = "Reduce Size", Icon = "minimize-2", Opened = true })

local reduceSlider = SectionReduce:Slider({
    Title = "Perkecil Karakter",
    Desc = "Ukuran 0.1x - 1x | Default: 1",
    Icon = "minimize-2",
    Step = 0.01,
    Value = { Min = 0.1, Max = 1, Default = 1 },
    IsTooltip = true,
    IsTextbox = true,
    Callback = function(v)
        selectedScale = v
    end
})

SectionReduce:Button({
    Title = "Apply Perkecil",
    Desc = "Terapkan ukuran kecil",
    Icon = "check",
    Callback = function()
        local success = scaleCharacter(selectedScale)
        if success then
            WindUI:Notify({ Title = "Size", Content = "Ukuran menjadi " .. selectedScale .. "x", Duration = 2, Icon = "check" })
        else
            WindUI:Notify({ Title = "Error", Content = "Karakter tidak ditemukan!", Duration = 2, Icon = "alert-circle" })
        end
    end
})

local SectionReset = TabSize:Section({ Title = "Reset", Icon = "refresh-cw", Opened = true })

SectionReset:Button({
    Title = "Reset ke Normal",
    Desc = "Kembalikan ukuran ke 1x",
    Icon = "refresh-cw",
    Callback = function()
        local success = scaleCharacter(1)
        if success then
            enlargeSlider:Set(1)
            reduceSlider:Set(1)
            selectedScale = 1
            currentScale = 1
            WindUI:Notify({ Title = "Reset", Content = "Ukuran karakter kembali normal", Duration = 2, Icon = "refresh-cw" })
        end
    end
})

LocalPlayer.CharacterAdded:Connect(function()
    task.wait(0.8)
    currentScale = 1
    selectedScale = 1
    pcall(function() enlargeSlider:Set(1) end)
    pcall(function() reduceSlider:Set(1) end)
end)

-- ============================================================
-- TAB: ANIMATIONS
-- ============================================================
local TabAnimations = Window:Tab({ Title = "Animations", Icon = "person-standing" })

local AnimationList = {
    { Title = "Stylish",   Idle = 616136790,  Idle2 = 616138447,  Walk = 616146177,  Run = 616140816,  Jump = 616139451,  Climb = 616133594,  Fall = 616134815  },
    { Title = "Zombie",    Idle = 616158929,  Idle2 = 616160636,  Walk = 616168032,  Run = 616163682,  Jump = 616161997,  Climb = 616156119,  Fall = 616157476  },
    { Title = "Robot",     Idle = 616088211,  Idle2 = 616089559,  Walk = 616095330,  Run = 616091570,  Jump = 616090535,  Climb = 616086039,  Fall = 616087089  },
    { Title = "Toy",       Idle = 782841498,  Idle2 = 782845736,  Walk = 782843345,  Run = 782842708,  Jump = 782847020,  Climb = 782843869,  Fall = 782846423  },
    { Title = "Cartoony",  Idle = 742637544,  Idle2 = 742638445,  Walk = 742640026,  Run = 742638842,  Jump = 742637942,  Climb = 742636889,  Fall = 742637151  },
    { Title = "Superhero", Idle = 616111295,  Idle2 = 616113536,  Walk = 616122287,  Run = 616117076,  Jump = 616115533,  Climb = 616104706,  Fall = 616108001  },
    { Title = "Ninja",     Idle = 656117400,  Idle2 = 656118341,  Walk = 656121766,  Run = 656118852,  Jump = 656117878,  Climb = 656114359,  Fall = 656115606  },
    { Title = "Knight",    Idle = 657595757,  Idle2 = 657568135,  Walk = 657552124,  Run = 657564596,  Jump = 658409194,  Climb = 658360781,  Fall = 657600338  },
    { Title = "Vampire",   Idle = 1083445855, Idle2 = 1083450166, Walk = 1083473930, Run = 1083462077, Jump = 1083455352, Climb = 1083439238, Fall = 1083443587 },
    { Title = "Mage",      Idle = 707742142,  Idle2 = 707855907,  Walk = 707897309,  Run = 707861613,  Jump = 707853694,  Climb = 707826056,  Fall = 707829716  },
    { Title = "Rthro",     Idle = 2510196951, Idle2 = 2510197257, Walk = 2510202577, Run = 2510198475, Jump = 2510197830, Climb = 2510192778, Fall = 2510195892 },
    { Title = "Cowboy",    Idle = 1014390418, Idle2 = 1014398616, Walk = 1014421541, Run = 1014401683, Jump = 1014394726, Climb = 1014380606, Fall = 1014384571 },
    { Title = "Princess",  Idle = 941003647,  Idle2 = 941013098,  Walk = 941028902,  Run = 941015281,  Jump = 941008832,  Climb = 940996062,  Fall = 941000007  },
    { Title = "Astronaut", Idle = 891621366,  Idle2 = 891633237,  Walk = 891667138,  Run = 891636393,  Jump = 891627522,  Climb = 891609353,  Fall = 891617961  },
    { Title = "Pirate",    Idle = 750781874,  Idle2 = 750782770,  Walk = 750785693,  Run = 750783738,  Jump = 750782230,  Climb = 750779899,  Fall = 750780242  },
    { Title = "Elder",     Idle = 845397899,  Idle2 = 845400520,  Walk = 845403856,  Run = 845386501,  Jump = 845398858,  Climb = 845392038,  Fall = 845396048  },
}

local EmoteList = {
    { Title = "Floss Dance",      Id = 5917459365  },
    { Title = "Fancy Feet",       Id = 3333432454  },
    { Title = "Fashion",          Id = 3333331310  },
    { Title = "Shuffle",          Id = 4349242221  },
    { Title = "Hype Dance",       Id = 3695333486  },
    { Title = "Bodybuilder",      Id = 3333387824  },
    { Title = "Celebrate",        Id = 3338097973  },
    { Title = "Happy",            Id = 4841405708  },
    { Title = "Sad",              Id = 4841407203  },
    { Title = "Sleep",            Id = 4686925579  },
    { Title = "Shy",              Id = 3337978742  },
    { Title = "Shrug",            Id = 3334392772  },
    { Title = "Tilt",             Id = 3334538554  },
    { Title = "Salute",           Id = 3333474484  },
    { Title = "Zombie",           Id = 4210116953  },
    { Title = "Robot",            Id = 3338025566  },
    { Title = "Break Dance",      Id = 5915648917  },
    { Title = "Dolphin Dance",    Id = 5918726674  },
    { Title = "Samba",            Id = 6869766175  },
    { Title = "Cha-Cha",          Id = 6862001787  },
    { Title = "Air Guitar",       Id = 3695300085  },
    { Title = "Jumping Cheer",    Id = 5895324424  },
    { Title = "Rock On",          Id = 5915714366  },
    { Title = "Top Rock",         Id = 3361276673  },
    { Title = "Side to Side",     Id = 3333136415  },
    { Title = "Twirl",            Id = 3334968680  },
    { Title = "Point",            Id = 3344585679  },
    { Title = "Haha",             Id = 3337966527  },
    { Title = "Hello",            Id = 3344650532  },
    { Title = "Line Dance",       Id = 4049037604  },
    { Title = "Godlike",          Id = 3337994105  },
    { Title = "Sneaky",           Id = 3334424322  },
    { Title = "Fishing",          Id = 3334832150  },
    { Title = "Stadium",          Id = 3338055167  },
    { Title = "Greatest",         Id = 3338042785  },
    { Title = "Louder",           Id = 3338083565  },
    { Title = "Idol",             Id = 4101966434  },
    { Title = "Curtsy",           Id = 4555816777  },
    { Title = "Agree",            Id = 4841397952  },
    { Title = "Disagree",         Id = 4841401869  },
    { Title = "Power Blast",      Id = 4841403964  },
    { Title = "Hero Landing",     Id = 5104344710  },
    { Title = "Tantrum",          Id = 5104341999  },
    { Title = "Applaud",          Id = 5915693819  },
    { Title = "High Wave",        Id = 5915690960  },
    { Title = "Cower",            Id = 4940563117  },
    { Title = "Bored",            Id = 5230599789  },
    { Title = "Beckon",           Id = 5230598276  },
    { Title = "Confused",         Id = 4940561610  },
    { Title = "Jumping Wave",     Id = 4940564896  },
    { Title = "Bunny Hop",        Id = 4641985101  },
    { Title = "Dorky Dance",      Id = 4212455378  },
    { Title = "Mean Girls Dance", Id = 15963314052 },
    { Title = "SpongeBob Dance",  Id = 18443245017 },
    { Title = "Shrek Roar",       Id = 18524313628 },
    { Title = "TMNT Dance",       Id = 18665811005 },
    { Title = "Festive Dance",    Id = 15679621440 },
    { Title = "Victory Dance",    Id = 15505456446 },
    { Title = "Rock n Roll",      Id = 15505458452 },
    { Title = "Flex Walk",        Id = 15505459811 },
}

local customEmotes = {}
local customEmotesFile = "WindUI/PieHub/customEmotes.json"

pcall(function()
    if makefolder and not isfolder("WindUI") then makefolder("WindUI") end
    if makefolder and not isfolder("WindUI/PieHub") then makefolder("WindUI/PieHub") end
end)

local function saveCustomEmotes()
    pcall(function()
        if writefile then
            writefile(customEmotesFile, HttpService:JSONEncode(customEmotes))
        end
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

local function buildEmoteNameList()
    local names = {}
    for _, v in ipairs(EmoteList) do table.insert(names, v.Title) end
    for name in pairs(customEmotes) do table.insert(names, name .. " (custom)") end
    table.sort(names, function(a, b) return a:lower() < b:lower() end)
    return names
end

local function buildCustomEmoteNames()
    local names = {}
    for name in pairs(customEmotes) do table.insert(names, name) end
    table.sort(names, function(a, b) return a:lower() < b:lower() end)
    return names
end

local animNameList = {}
for _, v in ipairs(AnimationList) do table.insert(animNameList, v.Title) end
table.sort(animNameList, function(a, b) return a:lower() < b:lower() end)

local URL_ANIM = "http://www.roblox.com/asset/?id="
local selectedAnimation   = nil
local selectedEmote       = nil
local selectedCustomEmote = nil
local currentEmoteTrack   = nil
local customEmoteNameValue = ""
local customEmoteIdValue   = ""
local defaultAnimIds = {}

local function getAnimData(title)
    for _, v in ipairs(AnimationList) do
        if v.Title == title then return v end
    end
end

local function getEmoteData(title)
    for _, v in ipairs(EmoteList) do
        if v.Title == title then return v end
    end
    local plainName = title:gsub(" %(custom%)$", "")
    if customEmotes[plainName] then
        return { Title = plainName, Id = customEmotes[plainName] }
    end
end

local function saveDefaultAnims()
    local chr = getChar()
    if not chr then return end
    local Animate = chr:FindFirstChild("Animate")
    if not Animate or next(defaultAnimIds) ~= nil then return end
    if Animate:FindFirstChild("idle") then
        defaultAnimIds.Idle  = Animate.idle.Animation1.AnimationId
        defaultAnimIds.Idle2 = Animate.idle.Animation2.AnimationId
    end
    if Animate:FindFirstChild("walk") then
        local a = Animate.walk:FindFirstChildOfClass("Animation")
        if a then defaultAnimIds.Walk = a.AnimationId end
    end
    if Animate:FindFirstChild("run") then
        local a = Animate.run:FindFirstChildOfClass("Animation")
        if a then defaultAnimIds.Run = a.AnimationId end
    end
    if Animate:FindFirstChild("jump") then
        local a = Animate.jump:FindFirstChildOfClass("Animation")
        if a then defaultAnimIds.Jump = a.AnimationId end
    end
    if Animate:FindFirstChild("climb") then
        local a = Animate.climb:FindFirstChildOfClass("Animation")
        if a then defaultAnimIds.Climb = a.AnimationId end
    end
    if Animate:FindFirstChild("fall") then
        local a = Animate.fall:FindFirstChildOfClass("Animation")
        if a then defaultAnimIds.Fall = a.AnimationId end
    end
end

local function applyAnimation(data)
    local chr = getChar()
    if not chr then return end
    local Animate = chr:FindFirstChild("Animate")
    if not Animate then return end
    saveDefaultAnims()
    if Animate:FindFirstChild("idle") then
        Animate.idle.Animation1.AnimationId = URL_ANIM .. data.Idle
        Animate.idle.Animation2.AnimationId = URL_ANIM .. data.Idle2
    end
    if Animate:FindFirstChild("walk") then
        Animate.walk:FindFirstChildOfClass("Animation").AnimationId = URL_ANIM .. data.Walk
    end
    if Animate:FindFirstChild("run") then
        Animate.run:FindFirstChildOfClass("Animation").AnimationId = URL_ANIM .. data.Run
    end
    if Animate:FindFirstChild("jump") then
        Animate.jump:FindFirstChildOfClass("Animation").AnimationId = URL_ANIM .. data.Jump
    end
    if Animate:FindFirstChild("climb") then
        Animate.climb:FindFirstChildOfClass("Animation").AnimationId = URL_ANIM .. data.Climb
    end
    if Animate:FindFirstChild("fall") then
        Animate.fall:FindFirstChildOfClass("Animation").AnimationId = URL_ANIM .. data.Fall
    end
    Animate.Disabled = true
    local hum = getHum()
    if hum then
        for _, t in ipairs(hum:GetPlayingAnimationTracks()) do t:Stop() end
        local s = hum.WalkSpeed
        hum.WalkSpeed = 0
        task.wait()
        hum.WalkSpeed = s
    end
    Animate.Disabled = false
end

local function resetAnimation()
    local chr = getChar()
    if not chr then return end
    local Animate = chr:FindFirstChild("Animate")
    if not Animate then return end
    if next(defaultAnimIds) ~= nil then
        if Animate:FindFirstChild("idle") then
            if defaultAnimIds.Idle  then Animate.idle.Animation1.AnimationId = defaultAnimIds.Idle  end
            if defaultAnimIds.Idle2 then Animate.idle.Animation2.AnimationId = defaultAnimIds.Idle2 end
        end
        if Animate:FindFirstChild("walk") then
            local a = Animate.walk:FindFirstChildOfClass("Animation")
            if a and defaultAnimIds.Walk then a.AnimationId = defaultAnimIds.Walk end
        end
        if Animate:FindFirstChild("run") then
            local a = Animate.run:FindFirstChildOfClass("Animation")
            if a and defaultAnimIds.Run then a.AnimationId = defaultAnimIds.Run end
        end
        if Animate:FindFirstChild("jump") then
            local a = Animate.jump:FindFirstChildOfClass("Animation")
            if a and defaultAnimIds.Jump then a.AnimationId = defaultAnimIds.Jump end
        end
        if Animate:FindFirstChild("climb") then
            local a = Animate.climb:FindFirstChildOfClass("Animation")
            if a and defaultAnimIds.Climb then a.AnimationId = defaultAnimIds.Climb end
        end
        if Animate:FindFirstChild("fall") then
            local a = Animate.fall:FindFirstChildOfClass("Animation")
            if a and defaultAnimIds.Fall then a.AnimationId = defaultAnimIds.Fall end
        end
    end
    Animate.Disabled = true
    task.wait(0.1)
    Animate.Disabled = false
    local hum = getHum()
    if hum then
        for _, t in ipairs(hum:GetPlayingAnimationTracks()) do t:Stop() end
        local s = hum.WalkSpeed
        hum.WalkSpeed = 0
        task.wait()
        hum.WalkSpeed = s
    end
    defaultAnimIds = {}
end

local function playEmote(data)
    if currentEmoteTrack then
        pcall(function() currentEmoteTrack:Stop() end)
        currentEmoteTrack = nil
    end
    local chr = getChar()
    local hum = getHum()
    if not chr or not hum then return end
    local Animate = chr:FindFirstChild("Animate")
    if Animate then Animate.Disabled = true end
    local anim = Instance.new("Animation")
    anim.AnimationId = "rbxassetid://" .. data.Id
    local track = hum:LoadAnimation(anim)
    track.Priority = Enum.AnimationPriority.Action
    track:Play(0)
    currentEmoteTrack = track
    track.Stopped:Connect(function()
        if Animate then Animate.Disabled = false end
    end)
end

local function stopEmote()
    if currentEmoteTrack then
        pcall(function() currentEmoteTrack:Stop() end)
        currentEmoteTrack = nil
    end
    local chr = getChar()
    if chr then
        local Animate = chr:FindFirstChild("Animate")
        if Animate then
            Animate.Disabled = true
            task.wait(0.05)
            Animate.Disabled = false
        end
        local hum = getHum()
        if hum then
            local s = hum.WalkSpeed
            hum.WalkSpeed = 0
            task.wait()
            hum.WalkSpeed = s
        end
    end
end

local SectionAnim = TabAnimations:Section({ Title = "Animations", Icon = "person-standing", Opened = true })

SectionAnim:Dropdown({
    Title = "Pilih Animasi",
    Desc = "Pilih animasi karakter",
    Values = animNameList,
    Value = "",
    SearchBarEnabled = true,
    Callback = function(v) selectedAnimation = v end
})

SectionAnim:Button({
    Title = "Apply",
    Desc = "Terapkan animasi yang dipilih",
    Icon = "check",
    Callback = function()
        if not selectedAnimation then
            WindUI:Notify({ Title = "Error", Content = "Pilih animasi dulu!", Duration = 2, Icon = "alert-circle" })
            return
        end
        local data = getAnimData(selectedAnimation)
        if not data then
            WindUI:Notify({ Title = "Error", Content = "Animasi tidak ditemukan!", Duration = 2, Icon = "alert-circle" })
            return
        end
        applyAnimation(data)
        WindUI:Notify({ Title = "Animations", Content = "Animasi '" .. selectedAnimation .. "' diterapkan!", Duration = 2, Icon = "check" })
    end
})

SectionAnim:Button({
    Title = "Reset",
    Desc = "Kembalikan animasi ke default",
    Icon = "refresh-cw",
    Callback = function()
        resetAnimation()
        selectedAnimation = nil
        WindUI:Notify({ Title = "Animations", Content = "Animasi dikembalikan ke default.", Duration = 2, Icon = "refresh-cw" })
    end
})

local SectionEmote = TabAnimations:Section({ Title = "Emote", Icon = "drama", Opened = true })

local emoteDropdown = SectionEmote:Dropdown({
    Title = "Daftar Emote",
    Desc = "Pilih emote untuk dimainkan",
    Values = buildEmoteNameList(),
    Value = "",
    SearchBarEnabled = true,
    Callback = function(v) selectedEmote = v end
})

SectionEmote:Button({
    Title = "Apply",
    Desc = "Mainkan emote yang dipilih",
    Icon = "play",
    Callback = function()
        if not selectedEmote then
            WindUI:Notify({ Title = "Error", Content = "Pilih emote dulu!", Duration = 2, Icon = "alert-circle" })
            return
        end
        local data = getEmoteData(selectedEmote)
        if not data then
            WindUI:Notify({ Title = "Error", Content = "Emote tidak ditemukan!", Duration = 2, Icon = "alert-circle" })
            return
        end
        playEmote(data)
        WindUI:Notify({ Title = "Emote", Content = "Memainkan '" .. selectedEmote .. "'", Duration = 2, Icon = "play" })
    end
})

SectionEmote:Button({
    Title = "Refresh",
    Desc = "Refresh daftar emote",
    Icon = "refresh-cw",
    Callback = function()
        emoteDropdown:Refresh(buildEmoteNameList())
        WindUI:Notify({ Title = "Emote", Content = "Daftar emote diperbarui.", Duration = 2, Icon = "refresh-cw" })
    end
})

SectionEmote:Button({
    Title = "Stop",
    Desc = "Hentikan emote yang sedang berjalan",
    Icon = "square",
    Callback = function()
        stopEmote()
        WindUI:Notify({ Title = "Emote", Content = "Emote dihentikan.", Duration = 2, Icon = "square" })
    end
})

local SectionMoreAnim = TabAnimations:Section({ Title = "Custom Emote", Icon = "plus-circle", Opened = true })

SectionMoreAnim:Input({
    Title = "Nama",
    Desc = "Nama untuk emote custom",
    Placeholder = "Contoh: My Emote",
    Value = "",
    Callback = function(v) customEmoteNameValue = v end
})

SectionMoreAnim:Input({
    Title = "Asset ID",
    Desc = "Asset ID emote Roblox",
    Placeholder = "Contoh: 507770818",
    Value = "",
    Callback = function(v) customEmoteIdValue = v end
})

local customEmoteDropdown

SectionMoreAnim:Button({
    Title = "Save",
    Desc = "Simpan emote custom ke file",
    Icon = "save",
    Callback = function()
        if customEmoteNameValue == "" then
            WindUI:Notify({ Title = "Error", Content = "Masukkan nama emote dulu!", Duration = 2, Icon = "alert-circle" })
            return
        end
        local id = tonumber(customEmoteIdValue)
        if not id then
            WindUI:Notify({ Title = "Error", Content = "Asset ID harus berupa angka!", Duration = 2, Icon = "alert-circle" })
            return
        end
        customEmotes[customEmoteNameValue] = id
        saveCustomEmotes()
        customEmoteDropdown:Refresh(buildCustomEmoteNames())
        emoteDropdown:Refresh(buildEmoteNameList())
        WindUI:Notify({ Title = "Custom Emote", Content = "Emote '" .. customEmoteNameValue .. "' disimpan!", Duration = 2, Icon = "save" })
    end
})

SectionMoreAnim:Button({
    Title = "Refresh",
    Desc = "Refresh daftar emote custom",
    Icon = "refresh-cw",
    Callback = function()
        customEmoteDropdown:Refresh(buildCustomEmoteNames())
        emoteDropdown:Refresh(buildEmoteNameList())
        WindUI:Notify({ Title = "Custom Emote", Content = "Daftar diperbarui.", Duration = 2, Icon = "refresh-cw" })
    end
})

customEmoteDropdown = SectionMoreAnim:Dropdown({
    Title = "Daftar Custom Emote",
    Desc = "Emote custom tersimpan",
    Values = buildCustomEmoteNames(),
    Value = "",
    SearchBarEnabled = true,
    Callback = function(v) selectedCustomEmote = v end
})

SectionMoreAnim:Button({
    Title = "Delete",
    Desc = "Hapus emote custom yang dipilih",
    Icon = "trash",
    Callback = function()
        if not selectedCustomEmote or not customEmotes[selectedCustomEmote] then
            WindUI:Notify({ Title = "Error", Content = "Pilih emote custom dulu!", Duration = 2, Icon = "alert-circle" })
            return
        end
        customEmotes[selectedCustomEmote] = nil
        selectedCustomEmote = nil
        saveCustomEmotes()
        customEmoteDropdown:Refresh(buildCustomEmoteNames())
        emoteDropdown:Refresh(buildEmoteNameList())
        WindUI:Notify({ Title = "Custom Emote", Content = "Emote dihapus.", Duration = 2, Icon = "trash" })
    end
})

-- ============================================================
-- TAB: AVATARS
-- ============================================================
local TabAvatars = Window:Tab({ Title = "Avatars", Icon = "shirt" })

local lastAvatarUsername = nil
local selectedMethod = "Auto (Semua Metode)"
local isRespawning = false
local originalDescription = nil
local originalDescriptionSaved = false

local methodOptions = {
    "Auto (Semua Metode)",
    "Metode 1 - RemoteEvent Keyword",
    "Metode 2 - Brute Force Remote",
    "Metode 3 - Body Part Swap",
    "Metode 4 - ApplyDescriptionClientServer",
    "Metode 5 - StarterCharacter",
    "Metode 6 - BindableEvent",
    "Metode 7 - Respawn Command",
    "Metode 8 - Visual Only",
}

local HttpService = game:GetService("HttpService")
local itemTypeCache = {}

local function detectItemTypeRealtime(assetId)
    if itemTypeCache[assetId] then
        return itemTypeCache[assetId]
    end
    
    assetId = tonumber(assetId) or 0
    if assetId <= 0 then
        return { type = "Unknown", name = "", slot = "HatAccessory" }
    end
    
    local result = {
        type = "Unknown",
        name = "",
        slot = "HatAccessory",
        bodyPart = nil,
        isBundle = false,
    }
    
    local success, data = pcall(function()
        local url = "https://economy.roblox.com/v2/assets/" .. assetId .. "/details"
        local response = syn and syn.request or (http and http.request)
        
        if response then
            local res = response({
                Url = url,
                Method = "GET",
                Headers = { ["Content-Type"] = "application/json" }
            })
            if res and res.Body then
                return HttpService:JSONDecode(res.Body)
            end
        end
        return nil
    end)
    
    if success and data and data.AssetTypeId then
        result.name = data.Name or ""
        
        local assetTypeId = data.AssetTypeId
        
        if assetTypeId == 8 then
            result.type = "Accessory"
            local lowerName = (result.name or ""):lower()
            if lowerName:find("face") then
                result.slot = "FaceAccessory"
            elseif lowerName:find("hair") then
                result.slot = "HairAccessory"
            elseif lowerName:find("back") or lowerName:find("sayap") then
                result.slot = "BackAccessory"
            elseif lowerName:find("waist") or lowerName:find("pinggang") then
                result.slot = "WaistAccessory"
            elseif lowerName:find("neck") then
                result.slot = "NeckAccessory"
            elseif lowerName:find("shoulder") then
                result.slot = "ShouldersAccessory"
            else
                result.slot = "HatAccessory"
            end
        elseif assetTypeId == 11 then
            result.type = "Shirt"
        elseif assetTypeId == 12 then
            result.type = "Pants"
        elseif assetTypeId == 2 then
            result.type = "TShirt"
        elseif assetTypeId == 17 then
            result.type = "DynamicHead"
        elseif assetTypeId == 18 then
            result.type = "BodyPart"
            local lowerName = (result.name or ""):lower()
            if lowerName:find("head") then
                result.bodyPart = "Head"
            elseif lowerName:find("torso") then
                result.bodyPart = "Torso"
            elseif lowerName:find("arm") then
                if lowerName:find("left") then
                    result.bodyPart = "LeftArm"
                else
                    result.bodyPart = "RightArm"
                end
            elseif lowerName:find("leg") then
                if lowerName:find("left") then
                    result.bodyPart = "LeftLeg"
                else
                    result.bodyPart = "RightLeg"
                end
            end
        elseif assetTypeId == 41 or assetTypeId == 61 then
            result.type = "Bundle"
            result.isBundle = true
        end
        
        itemTypeCache[assetId] = result
        return result
    end
    
    if not result or result.type == "Unknown" then
        pcall(function()
            local ins = game:GetService("InsertService")
            local model = ins:LoadAsset(assetId)
            if model then
                local hasAccessory = false
                local hasShirt = false
                local hasPants = false
                local hasShirtGraphic = false
                local hasBodyPart = false
                
                for _, child in ipairs(model:GetChildren()) do
                    if child:IsA("Accessory") or child:IsA("Hat") then
                        hasAccessory = true
                    elseif child:IsA("Shirt") then
                        hasShirt = true
                    elseif child:IsA("Pants") then
                        hasPants = true
                    elseif child:IsA("ShirtGraphic") then
                        hasShirtGraphic = true
                    elseif child:IsA("Part") or child:IsA("MeshPart") then
                        hasBodyPart = true
                    end
                end
                
                if hasAccessory then
                    result.type = "Accessory"
                elseif hasShirt then
                    result.type = "Shirt"
                elseif hasPants then
                    result.type = "Pants"
                elseif hasShirtGraphic then
                    result.type = "TShirt"
                elseif hasBodyPart then
                    result.type = "BodyPartReplacement"
                elseif #model:GetChildren() > 1 then
                    result.type = "Bundle"
                    result.isBundle = true
                end
                
                model:Destroy()
            end
        end)
        itemTypeCache[assetId] = result
    end
    
    return result
end

local function saveOriginalAvatar()
    if originalDescriptionSaved then return true end
    
    local char = LocalPlayer.Character
    if not char then return false end
    
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hum then return false end
    
    local success = pcall(function()
        originalDescription = hum:GetAppliedDescription()
    end)
    
    if success and originalDescription then
        originalDescriptionSaved = true
        return true
    end
    return false
end

local function restoreOriginalAvatar()
    if originalDescription and originalDescriptionSaved then
        apply_avatar_fe(originalDescription, true)
        WindUI:Notify({ Title = "Restore", Content = "Avatar asli dikembalikan!", Duration = 2, Icon = "rotate-ccw" })
        return true
    else
        resetAvatar()
        return false
    end
end

local function selectiveCleanup(char, targetDesc)
    local removedCount = 0
    
    for _, c in ipairs(char:GetChildren()) do
        if c:IsA("Accessory") or c:IsA("Hat") then
            local handle = c:FindFirstChild("Handle")
            local assetId = nil
            if handle then
                local mesh = handle:FindFirstChildOfClass("SpecialMesh")
                if mesh and mesh.MeshId then
                    assetId = tonumber(tostring(mesh.MeshId):match("(%d+)"))
                end
            end
            
            if assetId and targetDesc then
                local found = false
                local slots = {"HatAccessory", "HairAccessory", "FaceAccessory", "BackAccessory", "WaistAccessory", "NeckAccessory", "ShouldersAccessory"}
                for _, slot in ipairs(slots) do
                    local val = tostring(targetDesc[slot] or "")
                    if val:find(tostring(assetId)) then
                        found = true
                        break
                    end
                end
                if not found then
                    c:Destroy()
                    removedCount = removedCount + 1
                end
            else
                c:Destroy()
                removedCount = removedCount + 1
            end
        elseif c:IsA("Shirt") or c:IsA("Pants") or c:IsA("ShirtGraphic") then
            c:Destroy()
            removedCount = removedCount + 1
        end
    end
    
    return removedCount
end

local function applyVisualFallback(char, hum, desc)
    selectiveCleanup(char, desc)
    
    pcall(function()
        hum:ApplyDescription(desc)
    end)
    
    task.wait(0.1)
    
    if desc.Shirt and tonumber(tostring(desc.Shirt)) then
        local shirt = char:FindFirstChildOfClass("Shirt")
        if not shirt then
            shirt = Instance.new("Shirt")
            shirt.Parent = char
        end
        pcall(function()
            shirt.ShirtTemplate = "rbxassetid://" .. tostring(desc.Shirt)
        end)
    end
    
    if desc.Pants and tonumber(tostring(desc.Pants)) then
        local pants = char:FindFirstChildOfClass("Pants")
        if not pants then
            pants = Instance.new("Pants")
            pants.Parent = char
        end
        pcall(function()
            pants.PantsTemplate = "rbxassetid://" .. tostring(desc.Pants)
        end)
    end
    
    WindUI:Notify({ Title = "Visual Only", Content = "Avatar hanya terlihat di sisi kamu.", Duration = 3, Icon = "eye" })
end

local function verifyApplied(hum, targetDesc)
    task.wait(0.8)
    local ok = false
    pcall(function()
        local current = hum:GetAppliedDescription()
        if not current then return end
        local slots = {"HatAccessory", "HairAccessory", "Shirt", "Pants"}
        local match = 0
        for _, slot in ipairs(slots) do
            if tostring(current[slot]) == tostring(targetDesc[slot]) then
                match = match + 1
            end
        end
        ok = match >= 2
    end)
    return ok
end

local function apply_avatar_fe(desc, skipBackup)
    task.spawn(function()
        if not skipBackup then
            saveOriginalAvatar()
        end
        
        local char = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
        local hum = char:WaitForChild("Humanoid", 10)
        if not hum then
            WindUI:Notify({ Title = "Error", Content = "Humanoid tidak ditemukan!", Duration = 2, Icon = "alert-circle" })
            return
        end

        local remoteKeywords = {"avatar", "appearance", "outfit", "description", "character", "skin", "look"}
        local function matchesKeyword(name)
            local lower = name:lower()
            for _, kw in ipairs(remoteKeywords) do
                if lower:find(kw) then return true end
            end
            return false
        end

        local useMethod = selectedMethod

        if useMethod == "Auto (Semua Metode)" or useMethod == "Metode 1 - RemoteEvent Keyword" then
            local m1ok = false
            for _, v in ipairs(game:GetDescendants()) do
                if (v:IsA("RemoteEvent") or v:IsA("RemoteFunction")) and matchesKeyword(v.Name) then
                    pcall(function()
                        if v:IsA("RemoteEvent") then v:FireServer(desc)
                        else v:InvokeServer(desc) end
                    end)
                    if verifyApplied(hum, desc) then
                        WindUI:Notify({ Title = "Metode 1 ✓", Content = "RemoteEvent: " .. v.Name, Duration = 3, Icon = "radio" })
                        m1ok = true
                        break
                    end
                end
            end
            if m1ok then return end
            if useMethod == "Metode 1 - RemoteEvent Keyword" then
                applyVisualFallback(char, hum, desc)
                return
            end
        end

        if useMethod == "Auto (Semua Metode)" or useMethod == "Metode 2 - Brute Force Remote" then
            local m2ok = false
            for _, v in ipairs(game:GetDescendants()) do
                if v:IsA("RemoteEvent") or v:IsA("RemoteFunction") then
                    pcall(function()
                        if v:IsA("RemoteEvent") then v:FireServer(desc)
                        else v:InvokeServer(desc) end
                    end)
                    if verifyApplied(hum, desc) then
                        WindUI:Notify({ Title = "Metode 2 ✓", Content = "Brute force: " .. v.Name, Duration = 3, Icon = "zap" })
                        m2ok = true
                        break
                    end
                end
            end
            if m2ok then return end
            if useMethod == "Metode 2 - Brute Force Remote" then
                applyVisualFallback(char, hum, desc)
                return
            end
        end

        if useMethod == "Auto (Semua Metode)" or useMethod == "Metode 3 - Body Part Swap" then
            local m3ok = false
            pcall(function()
                local ins = game:GetService("InsertService")
                local ok, model = pcall(function()
                    return ins:LoadCharacterAppearanceAsync(LocalPlayer.UserId)
                end)
                if ok and model then
                    for _, part in ipairs(model:GetChildren()) do
                        if part:IsA("Accessory") or part:IsA("Hat") then
                            local clone = part:Clone()
                            pcall(function() clone.Parent = char end)
                        elseif part:IsA("Shirt") then
                            local existing = char:FindFirstChildOfClass("Shirt")
                            if existing then existing:Destroy() end
                            local clone = part:Clone()
                            pcall(function() clone.Parent = char end)
                        elseif part:IsA("Pants") then
                            local existing = char:FindFirstChildOfClass("Pants")
                            if existing then existing:Destroy() end
                            local clone = part:Clone()
                            pcall(function() clone.Parent = char end)
                        elseif part:IsA("BodyColors") then
                            local existing = char:FindFirstChildOfClass("BodyColors")
                            if existing then existing:Destroy() end
                            local clone = part:Clone()
                            pcall(function() clone.Parent = char end)
                        end
                    end
                    model:Destroy()
                    m3ok = true
                end
            end)
            if m3ok and verifyApplied(hum, desc) then
                WindUI:Notify({ Title = "Metode 3 ✓", Content = "Body part swap berhasil!", Duration = 3, Icon = "copy" })
                return
            end
            if useMethod == "Metode 3 - Body Part Swap" then
                applyVisualFallback(char, hum, desc)
                return
            end
        end

        if useMethod == "Auto (Semua Metode)" or useMethod == "Metode 4 - ApplyDescriptionClientServer" then
            pcall(function()
                if not hum.ApplyDescriptionClientServer then error() end
                hum:ApplyDescriptionClientServer(desc)
            end)
            if verifyApplied(hum, desc) then
                WindUI:Notify({ Title = "Metode 4 ✓", Content = "ApplyDescriptionClientServer berhasil!", Duration = 3, Icon = "shield-check" })
                return
            end
            if useMethod == "Metode 4 - ApplyDescriptionClientServer" then
                applyVisualFallback(char, hum, desc)
                return
            end
        end

        if useMethod == "Auto (Semua Metode)" or useMethod == "Metode 5 - StarterCharacter" then
            pcall(function()
                local StarterPlayer = game:GetService("StarterPlayer")
                local StarterChar = StarterPlayer:FindFirstChild("StarterCharacter")
                if StarterChar then
                    local starterHum = StarterChar:FindFirstChildOfClass("Humanoid")
                    if starterHum then starterHum:ApplyDescription(desc) end
                end
            end)
            if verifyApplied(hum, desc) then
                WindUI:Notify({ Title = "Metode 5 ✓", Content = "StarterCharacter berhasil!", Duration = 3, Icon = "user-check" })
                return
            end
            if useMethod == "Metode 5 - StarterCharacter" then
                applyVisualFallback(char, hum, desc)
                return
            end
        end

        if useMethod == "Auto (Semua Metode)" or useMethod == "Metode 6 - BindableEvent" then
            local m6ok = false
            for _, v in ipairs(game:GetDescendants()) do
                if v:IsA("BindableEvent") or v:IsA("BindableFunction") then
                    pcall(function()
                        if v:IsA("BindableEvent") then v:Fire(desc)
                        else v:Invoke(desc) end
                    end)
                    if verifyApplied(hum, desc) then
                        WindUI:Notify({ Title = "Metode 6 ✓", Content = "BindableEvent: " .. v.Name, Duration = 3, Icon = "link" })
                        m6ok = true
                        break
                    end
                end
            end
            if m6ok then return end
            if useMethod == "Metode 6 - BindableEvent" then
                applyVisualFallback(char, hum, desc)
                return
            end
        end

        if useMethod == "Auto (Semua Metode)" or useMethod == "Metode 7 - Respawn Command" then
            if isRespawning then
                return
            end
            
            isRespawning = true
            local pendingDesc = desc
            local m7done = false
            local timeout = 10
            
            local connection
            connection = LocalPlayer.CharacterAdded:Connect(function(newChar)
                if m7done then return end
                m7done = true
                connection:Disconnect()
                isRespawning = false
                local newHum = newChar:WaitForChild("Humanoid", 10)
                if not newHum then return end
                task.wait(0.8)
                selectiveCleanup(newChar, pendingDesc)
                pcall(function() newHum:ApplyDescription(pendingDesc) end)
                if pendingDesc.Shirt and tonumber(tostring(pendingDesc.Shirt)) then
                    local shirt = newChar:FindFirstChildOfClass("Shirt")
                    if not shirt then
                        shirt = Instance.new("Shirt")
                        shirt.Parent = newChar
                    end
                    pcall(function() shirt.ShirtTemplate = "rbxassetid://" .. tostring(pendingDesc.Shirt) end)
                end
                if pendingDesc.Pants and tonumber(tostring(pendingDesc.Pants)) then
                    local pants = newChar:FindFirstChildOfClass("Pants")
                    if not pants then
                        pants = Instance.new("Pants")
                        pants.Parent = newChar
                    end
                    pcall(function() pants.PantsTemplate = "rbxassetid://" .. tostring(pendingDesc.Pants) end)
                end
                WindUI:Notify({ Title = "Metode 7 ✓", Content = "Avatar diapply setelah respawn!", Duration = 3, Icon = "refresh-cw" })
            end)

            local fired = false
            local respawnCommands = {"!re", "!respawn", "!reset", "/re", "/respawn", "/reset"}
            
            for _, cmd in ipairs(respawnCommands) do
                if fired then break end
                pcall(function()
                    local chatService = game:GetService("TextChatService")
                    local channel = chatService.TextChannels:FindFirstChild("RBXGeneral")
                    if channel then
                        channel:SendAsync(cmd)
                        fired = true
                    end
                end)
                if not fired then
                    pcall(function()
                        game:GetService("Chat"):Chat(LocalPlayer.Character, cmd)
                        fired = true
                    end)
                end
            end

            if not fired then
                connection:Disconnect()
                isRespawning = false
                WindUI:Notify({ Title = "Metode 7 Gagal", Content = "Tidak bisa kirim command respawn!", Duration = 3, Icon = "alert-circle" })
                return
            end
            
            task.delay(timeout, function()
                if not m7done then
                    connection:Disconnect()
                    isRespawning = false
                    WindUI:Notify({ Title = "Metode 7 Timeout", Content = "Respawn tidak terjadi dalam " .. timeout .. " detik", Duration = 3, Icon = "alert-circle" })
                end
            end)
            
            return
        end

        applyVisualFallback(char, hum, desc)
    end)
end

local function applyItemWithDetection(assetId)
    task.spawn(function()
        saveOriginalAvatar()
        
        local itemInfo = detectItemTypeRealtime(assetId)
        
        if itemInfo.type == "Unknown" then
            WindUI:Notify({ Title = "Error", Content = "Tidak bisa detect tipe item!", Duration = 2, Icon = "alert-circle" })
            return
        end
        
        local char = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
        local hum = char:WaitForChild("Humanoid", 10)
        
        if not hum then
            WindUI:Notify({ Title = "Error", Content = "Humanoid tidak ditemukan!", Duration = 2 })
            return
        end
        
        local ok, desc = pcall(function() return hum:GetAppliedDescription() end)
        if not ok or not desc then
            desc = Instance.new("HumanoidDescription")
        end
        
        if itemInfo.type == "Accessory" then
            local slot = itemInfo.slot or "HatAccessory"
            local current = tostring(desc[slot] or "")
            if current == "0" or current == "" then
                desc[slot] = assetId
            else
                desc[slot] = current .. "," .. tostring(assetId)
            end
            apply_avatar_fe(desc)
            
        elseif itemInfo.type == "Shirt" then
            desc.Shirt = assetId
            apply_avatar_fe(desc)
            
        elseif itemInfo.type == "Pants" then
            desc.Pants = assetId
            apply_avatar_fe(desc)
            
        elseif itemInfo.type == "TShirt" then
            desc.GraphicTShirt = assetId
            apply_avatar_fe(desc)
            
        elseif itemInfo.type == "DynamicHead" then
            desc.DynamicHead = assetId
            apply_avatar_fe(desc)
            
        elseif itemInfo.type == "BodyPart" or itemInfo.type == "BodyPartReplacement" then
            pcall(function()
                local ins = game:GetService("InsertService")
                local model = ins:LoadAsset(assetId)
                if model then
                    for _, child in ipairs(model:GetChildren()) do
                        if child:IsA("Part") or child:IsA("MeshPart") then
                            local partName = itemInfo.bodyPart or child.Name
                            local originalPart = char:FindFirstChild(partName)
                            if originalPart then
                                child.CFrame = originalPart.CFrame
                                child.Parent = char
                                child.Name = partName
                                originalPart:Destroy()
                            else
                                child.Parent = char
                            end
                        end
                    end
                    model:Destroy()
                end
            end)
            WindUI:Notify({ Title = "Body Part", Content = "Part tubuh diganti!", Duration = 2 })
            
        elseif itemInfo.type == "Bundle" then
            local currentHat = tostring(desc.HatAccessory or "")
            if currentHat == "0" or currentHat == "" then
                desc.HatAccessory = assetId
            else
                desc.HatAccessory = currentHat .. "," .. tostring(assetId)
            end
            apply_avatar_fe(desc)
        else
            local currentHat = tostring(desc.HatAccessory or "")
            if currentHat == "0" or currentHat == "" then
                desc.HatAccessory = assetId
            else
                desc.HatAccessory = currentHat .. "," .. tostring(assetId)
            end
            apply_avatar_fe(desc)
        end
        
        WindUI:Notify({ Title = "Applied", Content = itemInfo.name or ("ID: "..assetId), Duration = 3, Icon = "check-circle" })
    end)
end

local function apply_avatar_method(username)
    task.spawn(function()
        saveOriginalAvatar()
        
        local char = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
        local hum = char:WaitForChild("Humanoid", 10)
        if not hum then
            WindUI:Notify({ Title = "Error", Content = "Humanoid tidak ditemukan!", Duration = 2, Icon = "alert-circle" })
            return
        end

        local desc = nil

        local ok, userId = pcall(Players.GetUserIdFromNameAsync, Players, username)
        if ok and userId then
            local ok2, d = pcall(Players.GetHumanoidDescriptionFromUserId, Players, userId)
            if ok2 and d then desc = d end
        end

        if not desc then
            for _, p in ipairs(Players:GetPlayers()) do
                if p.Name:lower() == username:lower() and p.Character then
                    local targetHum = p.Character:FindFirstChildOfClass("Humanoid")
                    if targetHum then
                        pcall(function() desc = targetHum:GetAppliedDescription() end)
                    end
                    break
                end
            end
        end

        if not desc then
            WindUI:Notify({ Title = "Error", Content = "Gagal ambil avatar dari " .. username, Duration = 2, Icon = "user-x" })
            return
        end

        apply_avatar_fe(desc)
    end)
end

local function apply_avatar_from_userid_method(userId)
    task.spawn(function()
        saveOriginalAvatar()
        local ok, desc = pcall(Players.GetHumanoidDescriptionFromUserId, Players, userId)
        if not ok or not desc then
            WindUI:Notify({ Title = "Error", Content = "Gagal ambil avatar! ID tidak valid.", Duration = 3, Icon = "alert-circle" })
            return
        end
        apply_avatar_fe(desc)
    end)
end

local function resetAvatar()
    lastAvatarUsername = nil
    originalDescriptionSaved = false
    originalDescription = nil
    apply_avatar_from_userid_method(LocalPlayer.UserId)
end

LocalPlayer.CharacterAdded:Connect(function(char)
    if lastAvatarUsername and not isRespawning then
        char:WaitForChild("Humanoid", 10)
        task.wait(0.65)
        apply_avatar_method(lastAvatarUsername)
    end
end)

local PresetItems = {
    { Title = "[Bundle] Korblox Deathspeaker", IsBundle = true, Id = nil,
        Items = {
            { Name = "Korblox Deathspeaker Lengan Kiri", Id = 139607570 },
            { Name = "Korblox Deathspeaker Tangan Kanan", Id = 139607625 },
            { Name = "Kaki Kiri Korblox Deathspeaker", Id = 139607673 },
            { Name = "Kaki Kanan Korblox Deathspeaker", Id = 139607718 },
            { Name = "Torso Pembicara Kematian Korblox", Id = 139607770 },
            { Name = "Korblox Deathspeaker Hood", Id = 139610147 },
        }
    },
    { Title = "Kepala Tanpa Kepala", IsBundle = false, Id = 15093053680 },
    { Title = "8-Bit HP Bar", IsBundle = false, Id = 10159610478 },
    { Title = "Mahkota Royal 8-Bit", IsBundle = false, Id = 10159600649 },
    { Title = "8-Bit Extra Life", IsBundle = false, Id = 10159606132 },
    { Title = "8-Bit Roblox Coin", IsBundle = false, Id = 10159622004 },
    { Title = "Ghosdeeri", IsBundle = false, Id = 183468963 },
    { Title = "Poisoned Horns of the Toxic Wasteland", IsBundle = false, Id = 1744060292 },
    { Title = "Fiery Horns of the Netherworld", IsBundle = false, Id = 215718515 },
    { Title = "Winter Fairy", IsBundle = false, Id = 141742418 },
    { Title = "St. Patrick's Day Fairy", IsBundle = false, Id = 226189871 },
    { Title = "Fall Fairy", IsBundle = false, Id = 128217885 },
    { Title = "Spring Fairy", IsBundle = false, Id = 150381051 },
    { Title = "Crescendo The Soul Stealer", IsBundle = false, Id = 94794774 },
    { Title = "Azure Dragon's Magic Slayer", IsBundle = false, Id = 268586231 },
}

local customItems = {}
local customItemsFile = "WindUI/PieHub/customItems.json"

local function saveCustomItems()
    pcall(function()
        if writefile then writefile(customItemsFile, HttpService:JSONEncode(customItems)) end
    end)
end

local function loadCustomItems()
    pcall(function()
        if readfile and isfile and isfile(customItemsFile) then
            local data = HttpService:JSONDecode(readfile(customItemsFile))
            if type(data) == "table" then customItems = data end
        end
    end)
end

loadCustomItems()

local function buildPresetItemNames()
    local names = {}
    for _, v in ipairs(PresetItems) do table.insert(names, v.Title) end
    for name in pairs(customItems) do table.insert(names, name .. " (custom)") end
    table.sort(names, function(a, b) return a:lower() < b:lower() end)
    return names
end

local function buildCustomItemNames()
    local names = {}
    for name in pairs(customItems) do table.insert(names, name) end
    table.sort(names, function(a, b) return a:lower() < b:lower() end)
    return names
end

local function getPresetItemData(title)
    for _, v in ipairs(PresetItems) do
        if v.Title == title then return v end
    end
    local plainName = title:gsub(" %(custom%)$", "")
    if customItems[plainName] then
        return { Title = plainName, IsBundle = false, Id = customItems[plainName] }
    end
end

local SectionMethod = TabAvatars:Section({ Title = "Metode FE", Icon = "settings", Opened = true })

SectionMethod:Dropdown({
    Title = "Pilih Metode",
    Desc = "Pilih metode yang digunakan saat apply avatar",
    Values = methodOptions,
    Value = "Auto (Semua Metode)",
    SearchBarEnabled = false,
    Callback = function(v) selectedMethod = v end
})

local SectionAvatarUsername = TabAvatars:Section({ Title = "Username", Icon = "user", Opened = true })
local avatarUsernameValue = ""

SectionAvatarUsername:Input({
    Title = "Username",
    Desc = "Masukkan username Roblox",
    Placeholder = "Contoh: Roblox",
    Value = "",
    Callback = function(v) avatarUsernameValue = v end
})

SectionAvatarUsername:Button({
    Title = "Apply",
    Desc = "Terapkan avatar dari username",
    Icon = "check",
    Callback = function()
        if avatarUsernameValue == "" then
            WindUI:Notify({ Title = "Error", Content = "Masukkan username dulu!", Duration = 2, Icon = "alert-circle" })
            return
        end
        lastAvatarUsername = avatarUsernameValue
        apply_avatar_method(avatarUsernameValue)
    end
})

SectionAvatarUsername:Button({
    Title = "Reset",
    Desc = "Kembalikan avatar ke default",
    Icon = "refresh-cw",
    Callback = function() resetAvatar() end
})

SectionAvatarUsername:Button({
    Title = "Restore Original",
    Desc = "Kembalikan ke avatar sebelum apply",
    Icon = "rotate-ccw",
    Callback = function() restoreOriginalAvatar() end
})

local SectionAvatarUserId = TabAvatars:Section({ Title = "User ID", Icon = "hash", Opened = true })
local avatarUserIdValue = ""

SectionAvatarUserId:Input({
    Title = "User ID",
    Desc = "Masukkan User ID Roblox",
    Placeholder = "Contoh: 1",
    Value = "",
    Callback = function(v) avatarUserIdValue = v end
})

SectionAvatarUserId:Button({
    Title = "Apply",
    Desc = "Terapkan avatar dari User ID",
    Icon = "check",
    Callback = function()
        local id = tonumber(avatarUserIdValue)
        if not id then
            WindUI:Notify({ Title = "Error", Content = "User ID harus berupa angka!", Duration = 2, Icon = "alert-circle" })
            return
        end
        apply_avatar_from_userid_method(id)
    end
})

SectionAvatarUserId:Button({
    Title = "Reset",
    Desc = "Kembalikan avatar ke default",
    Icon = "refresh-cw",
    Callback = function() resetAvatar() end
})

SectionAvatarUserId:Button({
    Title = "Restore Original",
    Desc = "Kembalikan ke avatar sebelum apply",
    Icon = "rotate-ccw",
    Callback = function() restoreOriginalAvatar() end
})

local SectionAvatarPlayer = TabAvatars:Section({ Title = "Player In Map", Icon = "users", Opened = true })
local selectedAvatarPlayer = nil
local avatarPlayerList = {}

local function getAvatarPlayerNames()
    local names = {}
    avatarPlayerList = {}
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer then
            table.insert(names, p.DisplayName)
            avatarPlayerList[p.DisplayName] = p.UserId
        end
    end
    return names
end

local avatarPlayerDropdown = SectionAvatarPlayer:Dropdown({
    Title = "Pilih Player",
    Desc = "Pilih player untuk ambil avatarnya",
    Values = getAvatarPlayerNames(),
    Value = "",
    SearchBarEnabled = true,
    Callback = function(v) selectedAvatarPlayer = v end
})

SectionAvatarPlayer:Button({
    Title = "Refresh",
    Desc = "Refresh daftar player",
    Icon = "refresh-cw",
    Callback = function()
        avatarPlayerDropdown:Refresh(getAvatarPlayerNames())
        WindUI:Notify({ Title = "Avatars", Content = "Daftar player diperbarui.", Duration = 2, Icon = "refresh-cw" })
    end
})

SectionAvatarPlayer:Button({
    Title = "Apply",
    Desc = "Terapkan avatar player yang dipilih",
    Icon = "check",
    Callback = function()
        if not selectedAvatarPlayer then
            WindUI:Notify({ Title = "Error", Content = "Pilih player dulu!", Duration = 2, Icon = "alert-circle" })
            return
        end
        local userId = avatarPlayerList[selectedAvatarPlayer]
        if not userId then
            WindUI:Notify({ Title = "Error", Content = "Player tidak ditemukan!", Duration = 2, Icon = "user-x" })
            return
        end
        apply_avatar_from_userid_method(userId)
    end
})

SectionAvatarPlayer:Button({
    Title = "Reset",
    Desc = "Kembalikan avatar ke default",
    Icon = "refresh-cw",
    Callback = function() resetAvatar() end
})

SectionAvatarPlayer:Button({
    Title = "Restore Original",
    Desc = "Kembalikan ke avatar sebelum apply",
    Icon = "rotate-ccw",
    Callback = function() restoreOriginalAvatar() end
})

local SectionAvatarItem = TabAvatars:Section({ Title = "Item / Asset ID", Icon = "package", Opened = true })
local itemNameValue = ""
local itemAssetIdValue = ""
local selectedItem = nil
local selectedCustomItem = nil
local itemDropdown
local customItemDropdown

SectionAvatarItem:Input({
    Title = "Nama",
    Desc = "Nama item untuk disimpan",
    Placeholder = "Contoh: My Hat",
    Value = "",
    Callback = function(v) itemNameValue = v end
})

SectionAvatarItem:Input({
    Title = "Asset ID",
    Desc = "Asset ID item Roblox (angka di URL catalog)",
    Placeholder = "Contoh: 139610147",
    Value = "",
    Callback = function(v) itemAssetIdValue = v end
})

SectionAvatarItem:Button({
    Title = "Save Custom Item",
    Desc = "Simpan item custom",
    Icon = "save",
    Callback = function()
        if itemNameValue == "" then
            WindUI:Notify({ Title = "Error", Content = "Masukkan nama item dulu!", Duration = 2, Icon = "alert-circle" })
            return
        end
        local id = tonumber(itemAssetIdValue)
        if not id then
            WindUI:Notify({ Title = "Error", Content = "Asset ID harus berupa angka!", Duration = 2, Icon = "alert-circle" })
            return
        end
        customItems[itemNameValue] = id
        saveCustomItems()
        itemDropdown:Refresh(buildPresetItemNames())
        customItemDropdown:Refresh(buildCustomItemNames())
        WindUI:Notify({ Title = "Avatars", Content = "Item '" .. itemNameValue .. "' disimpan!", Duration = 2, Icon = "save" })
    end
})

SectionAvatarItem:Button({
    Title = "Apply Asset ID Langsung",
    Desc = "Pasang item dari Asset ID yang diinput (auto detect type)",
    Icon = "download",
    Callback = function()
        local id = tonumber(itemAssetIdValue)
        if not id then
            WindUI:Notify({ Title = "Error", Content = "Asset ID harus berupa angka!", Duration = 2, Icon = "alert-circle" })
            return
        end
        applyItemWithDetection(id)
    end
})

SectionAvatarItem:Divider()

itemDropdown = SectionAvatarItem:Dropdown({
    Title = "Pilih Item / Bundle",
    Desc = "Daftar item & bundle tersedia",
    Values = buildPresetItemNames(),
    Value = "",
    SearchBarEnabled = true,
    Callback = function(v) selectedItem = v end
})

SectionAvatarItem:Button({
    Title = "Apply",
    Desc = "Pasang item / bundle yang dipilih",
    Icon = "check",
    Callback = function()
        if not selectedItem then
            WindUI:Notify({ Title = "Error", Content = "Pilih item dulu!", Duration = 2, Icon = "alert-circle" })
            return
        end
        local data = getPresetItemData(selectedItem)
        if not data then
            WindUI:Notify({ Title = "Error", Content = "Item tidak ditemukan!", Duration = 2, Icon = "alert-circle" })
            return
        end
        if data.IsBundle and data.Items then
            for _, item in ipairs(data.Items) do
                applyItemWithDetection(item.Id)
                task.wait(0.2)
            end
        else
            applyItemWithDetection(data.Id)
        end
    end
})

SectionAvatarItem:Button({
    Title = "Refresh List",
    Desc = "Refresh daftar item",
    Icon = "refresh-cw",
    Callback = function()
        itemDropdown:Refresh(buildPresetItemNames())
        WindUI:Notify({ Title = "Avatars", Content = "Daftar item diperbarui.", Duration = 2, Icon = "refresh-cw" })
    end
})

SectionAvatarItem:Button({
    Title = "Reset Avatar",
    Desc = "Kembalikan avatar ke default",
    Icon = "refresh-cw",
    Callback = function() resetAvatar() end
})

SectionAvatarItem:Button({
    Title = "Restore Original",
    Desc = "Kembalikan ke avatar sebelum apply",
    Icon = "rotate-ccw",
    Callback = function() restoreOriginalAvatar() end
})

SectionAvatarItem:Divider()

customItemDropdown = SectionAvatarItem:Dropdown({
    Title = "Item Custom Tersimpan",
    Desc = "Daftar item custom kamu",
    Values = buildCustomItemNames(),
    Value = "",
    SearchBarEnabled = true,
    Callback = function(v) selectedCustomItem = v end
})

SectionAvatarItem:Button({
    Title = "Delete Custom",
    Desc = "Hapus item custom yang dipilih",
    Icon = "trash",
    Callback = function()
        if not selectedCustomItem or not customItems[selectedCustomItem] then
            WindUI:Notify({ Title = "Error", Content = "Pilih item custom dulu!", Duration = 2, Icon = "alert-circle" })
            return
        end
        customItems[selectedCustomItem] = nil
        selectedCustomItem = nil
        saveCustomItems()
        itemDropdown:Refresh(buildPresetItemNames())
        customItemDropdown:Refresh(buildCustomItemNames())
        WindUI:Notify({ Title = "Avatars", Content = "Item dihapus.", Duration = 2, Icon = "trash-2" })
    end
})

SectionAvatarItem:Button({
    Title = "Apply Custom",
    Desc = "Pasang item custom yang dipilih",
    Icon = "check",
    Callback = function()
        if not selectedCustomItem or not customItems[selectedCustomItem] then
            WindUI:Notify({ Title = "Error", Content = "Pilih item custom dulu!", Duration = 2, Icon = "alert-circle" })
            return
        end
        applyItemWithDetection(customItems[selectedCustomItem])
    end
})

-- ============================================================
-- TAB: TELEPORT
-- ============================================================
local TabTeleport = Window:Tab({ Title = "Teleport", Icon = "map-pin" })

local selectedPlayer = nil
local selectedPlace  = nil
local savedPlaces    = {}
local playerList     = {}

local function getPlayerNames()
    local names = {}
    playerList = {}
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
    Title = "Pilih Player",
    Desc = "Pilih player untuk teleport",
    Values = getPlayerNames(),
    Value = "",
    SearchBarEnabled = true,
    Callback = function(v) selectedPlayer = v end
})

SectionTpPlayer:Button({
    Title = "Refresh",
    Desc = "Refresh daftar player",
    Icon = "refresh-cw",
    Callback = function()
        playerDropdown:Refresh(getPlayerNames())
        WindUI:Notify({ Title = "Teleport", Content = "Daftar player diperbarui.", Duration = 2, Icon = "refresh-cw" })
    end
})

SectionTpPlayer:Button({
    Title = "Teleport ke Player",
    Desc = "Teleport ke player yang dipilih",
    Icon = "map-pin",
    Callback = function()
        if not selectedPlayer then
            WindUI:Notify({ Title = "Error", Content = "Pilih player dulu!", Duration = 2, Icon = "alert-circle" })
            return
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

local placeDropdown = SectionTpPlace:Dropdown({
    Title = "Pilih Place",
    Desc = "Pilih tempat yang sudah disimpan",
    Values = {},
    Value = "",
    Callback = function(v) selectedPlace = v end
})

SectionTpPlace:Input({
    Title = "Nama Tempat",
    Desc = "Masukkan nama tempat",
    Placeholder = "Nama tempat...",
    Value = "",
    Callback = function(v) end
})

SectionTpPlace:Button({
    Title = "Save Place",
    Desc = "Simpan posisi saat ini",
    Icon = "save",
    Callback = function()
        local hrp = getHRP()
        if not hrp then return end
        local name = "Place " .. (#savedPlaces + 1)
        savedPlaces[name] = hrp.CFrame
        local keys = {}
        for k in pairs(savedPlaces) do table.insert(keys, k) end
        placeDropdown:Refresh(keys)
        WindUI:Notify({ Title = "Save", Content = "Tempat disimpan: " .. name, Duration = 2, Icon = "save" })
    end
})

SectionTpPlace:Button({
    Title = "Delete Place",
    Desc = "Hapus tempat yang dipilih",
    Icon = "trash",
    Callback = function()
        if selectedPlace and savedPlaces[selectedPlace] then
            savedPlaces[selectedPlace] = nil
            local keys = {}
            for k in pairs(savedPlaces) do table.insert(keys, k) end
            placeDropdown:Refresh(keys)
            selectedPlace = nil
            WindUI:Notify({ Title = "Delete", Content = "Tempat dihapus.", Duration = 2, Icon = "trash" })
        end
    end
})

SectionTpPlace:Button({
    Title = "Refresh",
    Desc = "Refresh daftar tempat",
    Icon = "refresh-cw",
    Callback = function()
        local keys = {}
        for k in pairs(savedPlaces) do table.insert(keys, k) end
        placeDropdown:Refresh(keys)
        WindUI:Notify({ Title = "Teleport", Content = "Daftar tempat diperbarui.", Duration = 2, Icon = "refresh-cw" })
    end
})

SectionTpPlace:Button({
    Title = "Teleport ke Place",
    Desc = "Teleport ke tempat yang dipilih",
    Icon = "map-pin",
    Callback = function()
        if not selectedPlace or not savedPlaces[selectedPlace] then
            WindUI:Notify({ Title = "Error", Content = "Pilih tempat dulu!", Duration = 2, Icon = "alert-circle" })
            return
        end
        local hrp = getHRP()
        if hrp then
            hrp.CFrame = savedPlaces[selectedPlace]
            WindUI:Notify({ Title = "Teleport", Content = "Teleport ke " .. selectedPlace, Duration = 2, Icon = "map-pin" })
        end
    end
})

-- ============================================================
-- TAB: VISUALS
-- ============================================================
local TabVisuals = Window:Tab({ Title = "Visuals", Icon = "eye" })

local espSettings = {
    Enabled   = false,
    Box       = false,
    Name      = false,
    Health    = false,
    Distance  = false,
    Tracer    = false,
    Highlight = false,
}

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
    local drawings = {}
    local box = {}
    for i = 1, 4 do
        box[i] = newDrawing("Line", {
            Color = Color3.fromRGB(255, 50, 50),
            Thickness = 1.5,
            Visible = false,
            ZIndex = 2,
        })
        table.insert(drawings, box[i])
    end
    local nameText = newDrawing("Text", {
        Color = Color3.fromRGB(255, 255, 255),
        Size = 10, Center = true, Outline = true,
        OutlineColor = Color3.fromRGB(0, 0, 0),
        Visible = false, ZIndex = 3,
    })
    table.insert(drawings, nameText)
    local distText = newDrawing("Text", {
        Color = Color3.fromRGB(200, 200, 200),
        Size = 10, Center = true, Outline = true,
        OutlineColor = Color3.fromRGB(0, 0, 0),
        Visible = false, ZIndex = 3,
    })
    table.insert(drawings, distText)
    local healthText = newDrawing("Text", {
        Color = Color3.fromRGB(100, 255, 100),
        Size = 10, Center = true, Outline = true,
        OutlineColor = Color3.fromRGB(0, 0, 0),
        Visible = false, ZIndex = 3,
    })
    table.insert(drawings, healthText)
    local tracer = newDrawing("Line", {
        Color = Color3.fromRGB(255, 50, 50),
        Thickness = 1, Visible = false, ZIndex = 1,
    })
    table.insert(drawings, tracer)
    espObjects[p.Name] = {
        drawings = drawings, box = box,
        nameText = nameText, distText = distText,
        healthText = healthText, healthBg = healthText, healthBar = healthText,
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
                hl.FillColor = Color3.fromRGB(255, 50, 50)
                hl.OutlineColor = Color3.fromRGB(255, 255, 255)
                hl.FillTransparency = 0.6
                hl.OutlineTransparency = 0
                e.highlight = hl
            end
        end
    else
        if e.highlight then
            pcall(function() e.highlight:Destroy() end)
            e.highlight = nil
        end
    end
end

RunService.RenderStepped:Connect(function()
    if not espSettings.Enabled then
        for _, e in pairs(espObjects) do
            for _, d in pairs(e.drawings or {}) do d.Visible = false end
        end
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
        if not hrp or not hum then
            for _, d in pairs(e.drawings) do d.Visible = false end
            continue
        end
        local headPos = hrp.Position + Vector3.new(0, 3, 0)
        local feetPos = hrp.Position - Vector3.new(0, 3, 0)
        local headScreen, headVis = camera:WorldToViewportPoint(headPos)
        local feetScreen, feetVis = camera:WorldToViewportPoint(feetPos)
        if not headVis or not feetVis then
            for _, d in pairs(e.drawings) do d.Visible = false end
            continue
        end
        local h = math.abs(headScreen.Y - feetScreen.Y)
        local w = h * 0.5
        local cx = (headScreen.X + feetScreen.X) / 2
        local top = math.min(headScreen.Y, feetScreen.Y)
        local bot = math.max(headScreen.Y, feetScreen.Y)
        local left = cx - w / 2
        local right = cx + w / 2
        local mid = (top + bot) / 2
        local showBox = espSettings.Box
        e.box[1].From = Vector2.new(left, top)  e.box[1].To = Vector2.new(right, top) e.box[1].Visible = showBox
        e.box[2].From = Vector2.new(left, bot)  e.box[2].To = Vector2.new(right, bot) e.box[2].Visible = showBox
        e.box[3].From = Vector2.new(left, top)  e.box[3].To = Vector2.new(left, bot)  e.box[3].Visible = showBox
        e.box[4].From = Vector2.new(right, top) e.box[4].To = Vector2.new(right, bot) e.box[4].Visible = showBox
        e.nameText.Position = Vector2.new(cx, top - 13)
        e.nameText.Text = p.DisplayName
        e.nameText.Visible = espSettings.Name
        local myHRP = getHRP()
        local dist = myHRP and math.floor((hrp.Position - myHRP.Position).Magnitude) or 0
        e.distText.Position = Vector2.new(cx, bot + 2)
        e.distText.Text = dist .. "m"
        e.distText.Visible = espSettings.Distance
        local hp = math.clamp(hum.Health / hum.MaxHealth, 0, 1)
        e.healthText.Position = Vector2.new(cx, mid - 5)
        e.healthText.Text = math.floor(hum.Health) .. " HP"
        e.healthText.Color = Color3.fromRGB(math.floor(255*(1-hp)), math.floor(255*hp), 0)
        e.healthText.Visible = espSettings.Health
        e.healthBg.Visible = false
        e.healthBar.Visible = false
        e.tracer.From = Vector2.new(vpSize.X / 2, vpSize.Y)
        e.tracer.To   = Vector2.new(cx, bot)
        e.tracer.Visible = espSettings.Tracer
        updateESPHighlight(p, espSettings.Highlight)
    end
end)

Players.PlayerAdded:Connect(function(p)
    if espSettings.Enabled then createESPFor(p) end
    p.CharacterAdded:Connect(function()
        if espSettings.Enabled then
            task.wait(1)
            updateESPHighlight(p, espSettings.Highlight)
        end
    end)
end)

Players.PlayerRemoving:Connect(function(p)
    removeESPFor(p.Name)
end)

local function refreshAllESP()
    clearAllESP()
    if espSettings.Enabled then
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= LocalPlayer then
                createESPFor(p)
                updateESPHighlight(p, espSettings.Highlight)
            end
        end
    end
end

local SectionESP = TabVisuals:Section({ Title = "ESP", Icon = "scan", Opened = true })

SectionESP:Toggle({ Title = "ESP", Desc = "Enable / Disable semua ESP", Icon = "scan", Value = false,
    Callback = function(v) espSettings.Enabled = v refreshAllESP() end })
SectionESP:Toggle({ Title = "ESP Box", Desc = "Kotak di sekitar player", Icon = "square", Value = false,
    Callback = function(v) espSettings.Box = v end })
SectionESP:Toggle({ Title = "ESP Name", Desc = "Tampilkan nama player", Icon = "user", Value = false,
    Callback = function(v) espSettings.Name = v end })
SectionESP:Toggle({ Title = "ESP Health", Desc = "Tampilkan HP player", Icon = "heart", Value = false,
    Callback = function(v) espSettings.Health = v end })
SectionESP:Toggle({ Title = "ESP Distance", Desc = "Tampilkan jarak ke player", Icon = "ruler", Value = false,
    Callback = function(v) espSettings.Distance = v end })
SectionESP:Toggle({ Title = "ESP Tracer", Desc = "Garis dari bawah layar ke player", Icon = "navigation", Value = false,
    Callback = function(v) espSettings.Tracer = v end })
SectionESP:Toggle({ Title = "ESP Highlight", Desc = "Highlight karakter player", Icon = "highlighter", Value = false,
    Callback = function(v)
        espSettings.Highlight = v
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= LocalPlayer then updateESPHighlight(p, v) end
        end
    end })

local SectionVisualMore = TabVisuals:Section({ Title = "World", Icon = "globe", Opened = true })

local freecamEnabled = false
local freecamSpeed = 20

SectionVisualMore:Toggle({
    Title = "Freecam",
    Desc = "Kamera bebas terbang",
    Icon = "video",
    Value = false,
    Callback = function(state)
        freecamEnabled = state
        local cam = workspace.CurrentCamera
        if state then
            cam.CameraType = Enum.CameraType.Scriptable
            task.spawn(function()
                local UIS = game:GetService("UserInputService")
                while freecamEnabled do
                    RunService.RenderStepped:Wait()
                    local moveVec = Vector3.zero
                    if UIS:IsKeyDown(Enum.KeyCode.W) then moveVec = moveVec + cam.CFrame.LookVector end
                    if UIS:IsKeyDown(Enum.KeyCode.S) then moveVec = moveVec - cam.CFrame.LookVector end
                    if UIS:IsKeyDown(Enum.KeyCode.A) then moveVec = moveVec - cam.CFrame.RightVector end
                    if UIS:IsKeyDown(Enum.KeyCode.D) then moveVec = moveVec + cam.CFrame.RightVector end
                    if UIS:IsKeyDown(Enum.KeyCode.E) then moveVec = moveVec + Vector3.new(0,1,0) end
                    if UIS:IsKeyDown(Enum.KeyCode.Q) then moveVec = moveVec - Vector3.new(0,1,0) end
                    if moveVec.Magnitude > 0 then
                        cam.CFrame = cam.CFrame + moveVec.Unit * freecamSpeed * 0.016
                    end
                end
                cam.CameraType = Enum.CameraType.Custom
            end)
        else
            cam.CameraType = Enum.CameraType.Custom
        end
    end
})

SectionVisualMore:Toggle({
    Title = "Fullbright",
    Desc = "Terangi semua area",
    Icon = "sun",
    Value = false,
    Callback = function(state)
        local lighting = game:GetService("Lighting")
        if state then
            lighting.Brightness = 2
            lighting.ClockTime = 14
            lighting.FogEnd = 100000
            lighting.GlobalShadows = false
            lighting.Ambient = Color3.fromRGB(255, 255, 255)
        else
            lighting.Brightness = 1
            lighting.ClockTime = 14
            lighting.FogEnd = 100000
            lighting.GlobalShadows = true
            lighting.Ambient = Color3.fromRGB(127, 127, 127)
        end
    end
})

SectionVisualMore:Toggle({
    Title = "No Fog",
    Desc = "Hilangkan fog",
    Icon = "cloud-off",
    Value = false,
    Callback = function(state)
        local lighting = game:GetService("Lighting")
        if state then
            lighting.FogEnd = 100000
            lighting.FogStart = 100000
        else
            lighting.FogEnd = 100000
            lighting.FogStart = 0
        end
    end
})

SectionVisualMore:Toggle({
    Title = "No Skybox",
    Desc = "Hilangkan skybox",
    Icon = "image-off",
    Value = false,
    Callback = function(state)
        local lighting = game:GetService("Lighting")
        local sky = lighting:FindFirstChildOfClass("Sky")
        if sky then sky.Enabled = not state end
    end
})

SectionVisualMore:Toggle({
    Title = "Xray",
    Desc = "Lihat melalui objek",
    Icon = "scan-line",
    Value = false,
    Callback = function(state)
        for _, obj in pairs(workspace:GetDescendants()) do
            if obj:IsA("BasePart") and not obj:IsDescendantOf(getChar() or Instance.new("Model")) then
                obj.LocalTransparencyModifier = state and 0.7 or 0
            end
        end
    end
})

-- ============================================================
-- TAB: SERVER
-- ============================================================
local TabServer = Window:Tab({ Title = "Server", Icon = "server" })

local antiAfkConn = nil

local SectionServerTools = TabServer:Section({ Title = "Tools", Icon = "wrench", Opened = true })

local autoRejoin = false
SectionServerTools:Toggle({
    Title = "Auto Rejoin",
    Desc = "Auto masuk ulang saat disconnect",
    Icon = "refresh-cw",
    Value = false,
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
    Title = "Anti AFK",
    Desc = "Mencegah kick karena AFK",
    Icon = "activity",
    Value = false,
    Callback = function(state)
        if state then
            local VirtualUser = game:GetService("VirtualUser")
            antiAfkConn = game:GetService("Players").LocalPlayer.Idled:Connect(function()
                VirtualUser:Button2Down(Vector2.new(0,0), workspace.CurrentCamera.CFrame)
                task.wait(1)
                VirtualUser:Button2Up(Vector2.new(0,0), workspace.CurrentCamera.CFrame)
            end)
        else
            if antiAfkConn then antiAfkConn:Disconnect() antiAfkConn = nil end
        end
    end
})

local SectionServerActions = TabServer:Section({ Title = "Actions", Icon = "zap", Opened = true })

SectionServerActions:Button({
    Title = "Rejoin",
    Desc = "Masuk ulang ke game ini",
    Icon = "log-in",
    Callback = function()
        TeleportService:Teleport(game.PlaceId, LocalPlayer)
    end
})

SectionServerActions:Button({
    Title = "Server Hop",
    Desc = "Pindah ke server lain",
    Icon = "shuffle",
    Callback = function()
        local placeId = game.PlaceId
        local servers = {}
        local success, result = pcall(function()
            local url = "https://games.roblox.com/v1/games/" .. placeId .. "/servers/Public?sortOrder=Asc&limit=100"
            local res = HttpService:JSONDecode(game:HttpGet(url))
            for _, s in pairs(res.data) do
                if s.playing < s.maxPlayers then
                    table.insert(servers, s.id)
                end
            end
        end)
        if success and #servers > 0 then
            local jobId = servers[math.random(1, #servers)]
            TeleportService:TeleportToPlaceInstance(placeId, jobId, LocalPlayer)
        else
            WindUI:Notify({ Title = "Server Hop", Content = "Tidak ada server lain ditemukan.", Duration = 3, Icon = "alert-circle" })
        end
    end
})

SectionServerActions:Button({
    Title = "Server Friend",
    Desc = "Pindah ke server yang ada teman",
    Icon = "users",
    Callback = function()
        local found = false
        for _, friend in ipairs(LocalPlayer:GetFriendsOnline()) do
            if friend.IsOnline and friend.PlaceId == game.PlaceId then
                pcall(function()
                    TeleportService:TeleportToPlaceInstance(game.PlaceId, friend.GameId, LocalPlayer)
                end)
                found = true
                break
            end
        end
        if not found then
            WindUI:Notify({ Title = "Server Friend", Content = "Tidak ada teman online di game ini.", Duration = 3, Icon = "alert-circle" })
        end
    end
})

-- ============================================================
-- TAB: DEVTOOLS
-- ============================================================
local TabDevTools = Window:Tab({ Title = "DevTools", Icon = "code" })

local savedCoords  = {}
local selectedCoord = nil
local coordNameValue = ""

local function buildCoordCode()
    if next(savedCoords) == nil then
        return "-- Belum ada koordinat tersimpan"
    end
    local lines = {}
    table.insert(lines, "-- Koordinat tersimpan:")
    local i = 1
    for name, cf in pairs(savedCoords) do
        local p = cf.Position
        table.insert(lines, string.format("%d. %s | X: %.2f, Y: %.2f, Z: %.2f", i, name, p.X, p.Y, p.Z))
        i = i + 1
    end
    table.insert(lines, "")
    table.insert(lines, "-- Lua table:")
    table.insert(lines, "local savedPlaces = {")
    for name, cf in pairs(savedCoords) do
        local p = cf.Position
        table.insert(lines, string.format('    ["%s"] = CFrame.new(%.2f, %.2f, %.2f),', name, p.X, p.Y, p.Z))
    end
    table.insert(lines, "}")
    return table.concat(lines, "\n")
end

local SectionCoords = TabDevTools:Section({ Title = "Koordinat", Icon = "map-pin", Opened = true })

local coordCodeBlock = SectionCoords:Code({
    Title = "Koordinat Tersimpan",
    Code = "-- Belum ada koordinat tersimpan",
    OnCopy = function()
        WindUI:Notify({ Title = "DevTools", Content = "Kode disalin!", Duration = 2, Icon = "copy" })
    end
})

local coordDropdown = SectionCoords:Dropdown({
    Title = "Daftar Koordinat",
    Desc = "Pilih koordinat tersimpan",
    Values = {},
    Value = "",
    SearchBarEnabled = true,
    Callback = function(v) selectedCoord = v end
})

SectionCoords:Input({
    Title = "Nama Koordinat",
    Desc = "Nama untuk koordinat yang akan disimpan",
    Placeholder = "Contoh: checkpoint1",
    Value = "",
    Callback = function(v) coordNameValue = v end
})

local function refreshCoordDropdown()
    local keys = {}
    for k in pairs(savedCoords) do table.insert(keys, k) end
    table.sort(keys)
    coordDropdown:Refresh(keys)
    coordCodeBlock:SetCode(buildCoordCode())
end

SectionCoords:Button({
    Title = "Save Koordinat",
    Desc = "Simpan posisi karakter saat ini",
    Icon = "save",
    Callback = function()
        local hrp = getHRP()
        if not hrp then
            WindUI:Notify({ Title = "Error", Content = "Karakter tidak ditemukan!", Duration = 2, Icon = "alert-circle" })
            return
        end
        local count = 0
        for _ in pairs(savedCoords) do count = count + 1 end
        local name = (coordNameValue ~= "" and coordNameValue) or ("checkpoint" .. (count + 1))
        savedCoords[name] = hrp.CFrame
        refreshCoordDropdown()
        WindUI:Notify({ Title = "DevTools", Content = "Koordinat '" .. name .. "' disimpan!", Duration = 2, Icon = "save" })
    end
})

SectionCoords:Button({
    Title = "Refresh",
    Desc = "Refresh daftar koordinat",
    Icon = "refresh-cw",
    Callback = function()
        refreshCoordDropdown()
        WindUI:Notify({ Title = "DevTools", Content = "Daftar diperbarui.", Duration = 2, Icon = "refresh-cw" })
    end
})

SectionCoords:Button({
    Title = "Delete Koordinat",
    Desc = "Hapus koordinat yang dipilih",
    Icon = "trash",
    Callback = function()
        if not selectedCoord or not savedCoords[selectedCoord] then
            WindUI:Notify({ Title = "Error", Content = "Pilih koordinat dulu!", Duration = 2, Icon = "alert-circle" })
            return
        end
        savedCoords[selectedCoord] = nil
        selectedCoord = nil
        refreshCoordDropdown()
        WindUI:Notify({ Title = "DevTools", Content = "Koordinat dihapus.", Duration = 2, Icon = "trash" })
    end
})

local SectionDevMore = TabDevTools:Section({ Title = "Tools", Icon = "terminal", Opened = true })

SectionDevMore:Button({
    Title = "Piehub Explorer",
    Desc = "Buka Piehub Explorer",
    Icon = "terminal",
    Callback = function()
        pcall(function()
            loadstring(game:HttpGet("https://raw.githubusercontent.com/Dylphiiee/PieHub/refs/heads/main/Un1ver%244l/dex.lua"))()
        end)
        WindUI:Notify({ Title = "DevTools", Content = "Piehub Explorer dibuka!", Duration = 2, Icon = "terminal" })
    end
})

-- ============================================================
-- TAB: CONFIG
-- ============================================================
local TabConfig = Window:Tab({ Title = "Config", Icon = "settings" })

local ConfigManager  = Window.ConfigManager
local configInputValue = ""
local selectedConfig = nil

local SectionConfigSave = TabConfig:Section({ Title = "Save & Load", Icon = "save", Opened = true })

SectionConfigSave:Input({
    Title = "Nama Config",
    Desc = "Masukkan nama config baru",
    Placeholder = "Contoh: myConfig",
    Value = "",
    Callback = function(v) configInputValue = v end
})

local function getConfigNames()
    local all = ConfigManager:AllConfigs()
    local names = {}
    for _, v in ipairs(all) do table.insert(names, v) end
    return names
end

local configDropdown = SectionConfigSave:Dropdown({
    Title = "Daftar Config",
    Desc = "Pilih config yang tersimpan",
    Values = getConfigNames(),
    Value = "",
    SearchBarEnabled = true,
    Callback = function(v) selectedConfig = v end
})

SectionConfigSave:Button({
    Title = "Save Config",
    Desc = "Simpan semua settingan saat ini",
    Icon = "save",
    Callback = function()
        local name = configInputValue ~= "" and configInputValue or "default"
        local cfg = ConfigManager:GetConfig(name) or ConfigManager:CreateConfig(name)
        cfg:Save()
        configDropdown:Refresh(getConfigNames())
        WindUI:Notify({ Title = "Config", Content = "Config '" .. name .. "' disimpan!", Duration = 2, Icon = "save" })
    end
})

SectionConfigSave:Button({
    Title = "Apply Config",
    Desc = "Terapkan config yang dipilih",
    Icon = "check",
    Callback = function()
        if not selectedConfig then
            WindUI:Notify({ Title = "Error", Content = "Pilih config dulu!", Duration = 2, Icon = "alert-circle" })
            return
        end
        local cfg = ConfigManager:GetConfig(selectedConfig)
        if cfg then
            cfg:Load()
            WindUI:Notify({ Title = "Config", Content = "Config '" .. selectedConfig .. "' diterapkan!", Duration = 2, Icon = "check" })
        else
            WindUI:Notify({ Title = "Error", Content = "Config tidak ditemukan!", Duration = 2, Icon = "alert-circle" })
        end
    end
})

SectionConfigSave:Button({
    Title = "Refresh",
    Desc = "Refresh daftar config",
    Icon = "refresh-cw",
    Callback = function()
        configDropdown:Refresh(getConfigNames())
        WindUI:Notify({ Title = "Config", Content = "Daftar config diperbarui.", Duration = 2, Icon = "refresh-cw" })
    end
})

SectionConfigSave:Button({
    Title = "Delete Config",
    Desc = "Hapus config yang dipilih",
    Icon = "trash",
    Callback = function()
        if not selectedConfig then
            WindUI:Notify({ Title = "Error", Content = "Pilih config dulu!", Duration = 2, Icon = "alert-circle" })
            return
        end
        ConfigManager:DeleteConfig(selectedConfig)
        selectedConfig = nil
        configDropdown:Refresh(getConfigNames())
        WindUI:Notify({ Title = "Config", Content = "Config dihapus.", Duration = 2, Icon = "trash" })
    end
})

-- ============================================================
-- TAB: INFO
-- ============================================================
local TabInfo = Window:Tab({ Title = "Info", Icon = "info" })

TabInfo:Image({
    Image = "rbxassetid://5107182114",
    AspectRatio = "16:9",
    Radius = 12
})

local SectionInfoAbout = TabInfo:Section({ Title = "About", Icon = "info", Opened = true })

SectionInfoAbout:Paragraph({
    Title = "PieHub",
    Desc = "Version: 1.0.0\nBuild: Stable",
    Icon = "cookie",
})

SectionInfoAbout:Paragraph({
    Title = "Creator",
    Desc = "Dibuat oleh Dylphiiee\nTerimakasih sudah menggunakan PieHub!",
    Icon = "user",
})

local SectionInfoContact = TabInfo:Section({ Title = "Contact", Icon = "phone", Opened = true })

SectionInfoContact:Button({
    Title = "Discord",
    Desc = "Join server Discord kami",
    Icon = "message-circle",
    Color = Color3.fromHex("#5865F2"),
    Callback = function()
        setclipboard("https://discord.gg/yourinvite")
        WindUI:Notify({ Title = "Discord", Content = "Link Discord disalin ke clipboard!", Duration = 3, Icon = "message-circle" })
    end
})

SectionInfoContact:Button({
    Title = "WhatsApp",
    Desc = "Hubungi via WhatsApp",
    Icon = "phone",
    Color = Color3.fromHex("#25D366"),
    Callback = function()
        setclipboard("https://wa.me/yourwalink")
        WindUI:Notify({ Title = "WhatsApp", Content = "Link WhatsApp disalin ke clipboard!", Duration = 3, Icon = "phone" })
    end
})

-- ============================================================
-- RESPAWN HANDLER
-- ============================================================
LocalPlayer.CharacterAdded:Connect(function(char)
    task.wait(0.7)
    flyEnabled = false
    pcall(function() flyToggle:Set(false) end)
    local hum = char:FindFirstChildWhichIsA("Humanoid")
    if hum then hum.PlatformStand = false end
    if char:FindFirstChild("Animate") then char.Animate.Disabled = false end
end)
