-- PieHub by Dylphiiee
local WindUI = loadstring(game:HttpGet("https://github.com/Footagesus/WindUI/releases/latest/download/main.lua"))()

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")
local LocalPlayer = Players.LocalPlayer
local Mouse = LocalPlayer:GetMouse()

WindUI:SetNotificationLower(true)

-- ============================================================
-- WINDOW SETUP
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

Window:Tag({ Title = "Dylphiiee", Icon = "user", Color = Color3.fromHex("#a78bfa"), Radius = 12 })
Window:Tag({ Title = "V1.0.0 (Ultimate)", Icon = "rocket", Color = Color3.fromHex("#30ff6a"), Radius = 12 })

-- ============================================================
-- HELPERS & VARIABLES
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

-- Connection Variables (For Respawn Handling)
local airWalkConn, noClipConn, infJumpConn, invisV1Conn, invisV2Conn = nil, nil, nil, nil, nil
local bhopConn, clickTpConn, antiFlingConn, spinbotConn = nil, nil, nil, nil
local flyEnabled, flySpeed = false, 10
local walkSpeedEnabled, walkSpeedValue = false, 16
local jumpPowerEnabled, jumpPowerValue = false, 50
local godmodeEnabled = false

-- ============================================================
-- TAB: PLAYER
-- ============================================================
local TabPlayer = Window:Tab({ Title = "Player", Icon = "user" })

-- SECTION: MOVEMENT
local SectionMovement = TabPlayer:Section({ Title = "Movement", Icon = "footprints", Opened = true })

SectionMovement:Toggle({
    Title = "Bunny Hop (Bhop)",
    Desc = "Lompat otomatis saat menahan Spasi",
    Icon = "rabbit",
    Value = false,
    Callback = function(state)
        if state then
            local UIS = game:GetService("UserInputService")
            bhopConn = RunService.RenderStepped:Connect(function()
                local hum = getHum()
                if hum and UIS:IsKeyDown(Enum.KeyCode.Space) then hum.Jump = true end
            end)
        else
            if bhopConn then bhopConn:Disconnect() bhopConn = nil end
        end
    end
})

SectionMovement:Toggle({
    Title = "Ctrl + Click TP",
    Desc = "Tahan CTRL Kiri + Klik Mouse untuk Teleport",
    Icon = "mouse-pointer",
    Value = false,
    Callback = function(state)
        if state then
            local UIS = game:GetService("UserInputService")
            clickTpConn = Mouse.Button1Down:Connect(function()
                if UIS:IsKeyDown(Enum.KeyCode.LeftControl) then
                    local hrp = getHRP()
                    if hrp and Mouse.Hit then hrp.CFrame = CFrame.new(Mouse.Hit.Position + Vector3.new(0, 3, 0)) end
                end
            end)
        else
            if clickTpConn then clickTpConn:Disconnect() clickTpConn = nil end
        end
    end
})

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

local flyToggle = SectionMovement:Toggle({
    Title = "Fly",
    Desc = "Terbang (WASD + Camera)",
    Icon = "plane",
    Value = false,
    Callback = function(state)
        flyEnabled = state
        local chr = getChar()
        local hum = getHum()
        if not chr or not hum then return end
        if not flyEnabled then
            for _, st in ipairs(Enum.HumanoidStateType:GetEnumItems()) do pcall(function() hum:SetStateEnabled(st, true) end) end
            hum:ChangeState(Enum.HumanoidStateType.RunningNoPhysics)
            chr.Animate.Disabled = false
            hum.PlatformStand = false
        else
            for _, st in ipairs(Enum.HumanoidStateType:GetEnumItems()) do pcall(function() hum:SetStateEnabled(st, false) end) end
            hum:ChangeState(Enum.HumanoidStateType.Swimming)
            chr.Animate.Disabled = true
            local torso = hum.RigType == Enum.HumanoidRigType.R6 and chr:FindFirstChild("Torso") or chr:FindFirstChild("UpperTorso")
            if not torso then return end
            hum.PlatformStand = true
            local bg = Instance.new("BodyGyro", torso)
            bg.P = 9e4; bg.MaxTorque = Vector3.new(9e9, 9e9, 9e9); bg.CFrame = torso.CFrame
            local bv = Instance.new("BodyVelocity", torso)
            bv.Velocity = Vector3.zero; bv.MaxForce = Vector3.new(9e9, 9e9, 9e9)
            task.spawn(function()
                while flyEnabled do
                    RunService.RenderStepped:Wait()
                    local h2 = getHum()
                    if not h2 then break end
                    local camCF = workspace.CurrentCamera.CFrame
                    local md = h2.MoveDirection
                    local moveDir = Vector3.zero
                    if md.Magnitude > 0 then
                        moveDir = (camCF.LookVector * (md:Dot(camCF.LookVector))) + (camCF.RightVector * (md:Dot(camCF.RightVector)))
                    end
                    bv.Velocity = moveDir * flySpeed
                    bg.CFrame = camCF
                end
                bg:Destroy(); bv:Destroy()
            end)
        end
    end
})

SectionMovement:Slider({ Title = "Fly Speed", Step = 1, Value = { Min = 1, Max = 200, Default = 10 }, Callback = function(v) flySpeed = v end })

SectionMovement:Divider()

SectionMovement:Toggle({
    Title = "Custom Walk Speed", Icon = "gauge", Value = false,
    Callback = function(state) walkSpeedEnabled = state; local hum = getHum(); if hum then hum.WalkSpeed = state and walkSpeedValue or 16 end end
})
SectionMovement:Slider({ Title = "Speed Value", Step = 1, Value = { Min = 1, Max = 500, Default = 16 }, Callback = function(v) walkSpeedValue = v; if walkSpeedEnabled then local h = getHum(); if h then h.WalkSpeed = v end end end })

SectionMovement:Toggle({
    Title = "Custom Jump Power", Icon = "arrow-up", Value = false,
    Callback = function(state) jumpPowerEnabled = state; local hum = getHum(); if hum then hum.UseJumpPower = true; hum.JumpPower = state and jumpPowerValue or 50 end end
})
SectionMovement:Slider({ Title = "Jump Value", Step = 1, Value = { Min = 1, Max = 500, Default = 50 }, Callback = function(v) jumpPowerValue = v; if jumpPowerEnabled then local h = getHum(); if h then h.UseJumpPower = true; h.JumpPower = v end end end end })

-- SECTION: STATUS
local SectionStatus = TabPlayer:Section({ Title = "Status", Icon = "shield", Opened = true })

SectionStatus:Toggle({
    Title = "Godmode (Client)", Desc = "Karakter tidak bisa mati (Client Side)", Icon = "shield", Value = false,
    Callback = function(state)
        godmodeEnabled = state
        local hum = getHum()
        if hum then hum.MaxHealth = state and math.huge or 100; hum.Health = state and math.huge or 100 end
    end
})

SectionStatus:Toggle({
    Title = "Anti-Fling", Desc = "Cegah terpental jauh", Icon = "anchor", Value = false,
    Callback = function(state)
        if state then
            antiFlingConn = RunService.Stepped:Connect(function()
                local hrp = getHRP()
                if hrp and (hrp.Velocity.Magnitude > 250 or hrp.RotVelocity.Magnitude > 250) then
                    hrp.Velocity = Vector3.zero; hrp.RotVelocity = Vector3.zero
                end
            end)
        else if antiFlingConn then antiFlingConn:Disconnect() antiFlingConn = nil end end
    end
})

SectionStatus:Toggle({
    Title = "Spinbot", Desc = "Putar karakter dengan cepat", Icon = "refresh-cw", Value = false,
    Callback = function(state)
        if state then
            spinbotConn = RunService.RenderStepped:Connect(function()
                local hrp = getHRP()
                if hrp then hrp.CFrame = hrp.CFrame * CFrame.Angles(0, math.rad(20), 0) end
            end)
        else if spinbotConn then spinbotConn:Disconnect() spinbotConn = nil end end
    end
})

SectionStatus:Toggle({ Title = "No Gravity", Icon = "orbit", Value = false, Callback = function(state)
    local hrp = getHRP()
    if state and hrp then
        local bf = Instance.new("BodyForce", hrp); bf.Name = "NoGrav"; bf.Force = Vector3.new(0, workspace.Gravity * hrp:GetMass(), 0)
    else local h2 = getHRP(); if h2 and h2:FindFirstChild("NoGrav") then h2.NoGrav:Destroy() end end
end})

-- SECTION: INVISIBLE
local SectionInvis = TabPlayer:Section({ Title = "Invisible", Icon = "eye-off", Opened = false })
SectionInvis:Toggle({ Title = "Invisible V1 (Void)", Value = false, Callback = function(state)
    local hrp = getHRP(); local hum = getHum()
    if state and hrp and hum then
        invisV1Conn = RunService.Heartbeat:Connect(function()
            local cf = hrp.CFrame; hrp.CFrame = cf * CFrame.new(0, -200000, 0)
            hum.CameraOffset = (cf * CFrame.new(0, -200000, 0)):ToObjectSpace(CFrame.new(cf.Position)).Position
            RunService.RenderStepped:Wait(); hrp.CFrame = cf; hum.CameraOffset = Vector3.zero
        end)
    else if invisV1Conn then invisV1Conn:Disconnect() invisV1Conn = nil; if hum then hum.CameraOffset = Vector3.zero end end end
end})

-- ============================================================
-- TAB: ANIMATIONS (DYNAMIC)
-- ============================================================
local TabAnimations = Window:Tab({ Title = "Animations", Icon = "person-standing" })
local EmoteList = {}

local function fetchEmotes()
    local success, res = pcall(function() return game:HttpGet("https://raw.githubusercontent.com/zyrovell/Vexro/main/emotes.json") end)
    if success then
        local data = HttpService:JSONDecode(res)
        for _, v in ipairs(data) do table.insert(EmoteList, { Title = v.name, Id = v.id }) end
        table.sort(EmoteList, function(a,b) return a.Title:lower() < b.Title:lower() end)
    end
end
fetchEmotes()

local SectionAnim = TabAnimations:Section({ Title = "Emotes", Icon = "drama", Opened = true })
local selectedEmote = nil
local emoteDrop = SectionAnim:Dropdown({ Title = "Pilih Emote", Values = {}, SearchBarEnabled = true, Callback = function(v) selectedEmote = v end })
local function updateEmoteDrop() local n = {}; for _,v in ipairs(EmoteList) do table.insert(n, v.Title) end; emoteDrop:Refresh(n) end
updateEmoteDrop()

local currentTrack = nil
SectionAnim:Button({ Title = "Play", Callback = function()
    if not selectedEmote then return end
    local id = 0; for _,v in ipairs(EmoteList) do if v.Title == selectedEmote then id = v.Id break end end
    local hum = getHum(); if not hum then return end
    if currentTrack then currentTrack:Stop() end
    local anim = Instance.new("Animation"); anim.AnimationId = "rbxassetid://"..id
    currentTrack = hum:LoadAnimation(anim); currentTrack:Play()
end})
SectionAnim:Button({ Title = "Stop", Callback = function() if currentTrack then currentTrack:Stop() end end })

-- ============================================================
-- TAB: VISUALS (MODERN ESP & CROSSHAIR)
-- ============================================================
local TabVisuals = Window:Tab({ Title = "Visuals", Icon = "eye" })
local espSettings = { Enabled = false, Box = false, Name = false, HealthText = false, Distance = false, Tracer = false, Highlight = false, TeamCheck = false, UseTeamColor = true }
local crosshairSettings = { Enabled = false, Color = Color3.new(0,1,0), Size = 10, Gap = 5, Thickness = 2 }

local function newDrawing(type_, props) local d = Drawing.new(type_); for k, v in pairs(props) do d[k] = v end; return d end
local espObjects = {}
local crosshairLines = {
    T = newDrawing("Line", {Thickness=2, Visible=false, ZIndex=10}), B = newDrawing("Line", {Thickness=2, Visible=false, ZIndex=10}),
    L = newDrawing("Line", {Thickness=2, Visible=false, ZIndex=10}), R = newDrawing("Line", {Thickness=2, Visible=false, ZIndex=10})
}

RunService.RenderStepped:Connect(function()
    -- ESP Logic
    if espSettings.Enabled then
        for _, p in ipairs(Players:GetPlayers()) do
            if p == LocalPlayer then continue end
            local char = p.Character; local hrp = char and char:FindFirstChild("HumanoidRootPart"); local hum = char and char:FindFirstChildOfClass("Humanoid")
            local e = espObjects[p.Name] or (function()
                local obj = {
                    Box = newDrawing("Square", {Thickness=1, Filled=false, ZIndex=2}),
                    Outline = newDrawing("Square", {Thickness=3, Color=Color3.new(0,0,0), Filled=false, ZIndex=1}),
                    Name = newDrawing("Text", {Size=13, Center=true, Outline=true, ZIndex=3}),
                    Health = newDrawing("Text", {Size=12, Center=true, Outline=true, ZIndex=3}),
                    Dist = newDrawing("Text", {Size=11, Center=true, Outline=true, ZIndex=3}),
                    Tracer = newDrawing("Line", {Thickness=1.5, ZIndex=1})
                }
                espObjects[p.Name] = obj; return obj
            end)()

            if hrp and hum and hum.Health > 0 then
                local headPos, headVis = workspace.CurrentCamera:WorldToViewportPoint(hrp.Position + Vector3.new(0, 2.5, 0))
                local feetPos, feetVis = workspace.CurrentCamera:WorldToViewportPoint(hrp.Position - Vector3.new(0, 3, 0))
                
                if headVis and feetVis and not (espSettings.TeamCheck and p.Team == LocalPlayer.Team) then
                    local h = math.abs(headPos.Y - feetPos.Y); local w = h * 0.5; local cx = headPos.X; local t = headPos.Y; local l = cx - w/2
                    local color = espSettings.UseTeamColor and p.TeamColor.Color or (p.Team == LocalPlayer.Team and Color3.new(0,1,0) or Color3.new(1,0,0))
                    
                    e.Box.Visible = espSettings.Box; e.Box.Position = Vector2.new(l, t); e.Box.Size = Vector2.new(w, h); e.Box.Color = color
                    e.Outline.Visible = espSettings.Box; e.Outline.Position = Vector2.new(l, t); e.Outline.Size = Vector2.new(w, h)
                    
                    e.Name.Visible = espSettings.Name; e.Name.Position = Vector2.new(cx, t - 16); e.Name.Text = p.DisplayName; e.Name.Color = color
                    
                    local hpPct = math.clamp(hum.Health/hum.MaxHealth, 0, 1)
                    e.Health.Visible = espSettings.HealthText; e.Health.Text = math.floor(hpPct*100).."%"; e.Health.Position = Vector2.new(l - 20, t + (h*(1-hpPct))); e.Health.Color = Color3.fromHSV(hpPct*0.3, 1, 1)
                    
                    e.Dist.Visible = espSettings.Distance; e.Dist.Position = Vector2.new(cx, t + h + 2); e.Dist.Text = math.floor((hrp.Position - getHRP().Position).Magnitude).."m"
                    
                    e.Tracer.Visible = espSettings.Tracer; e.Tracer.From = Vector2.new(workspace.CurrentCamera.ViewportSize.X/2, workspace.CurrentCamera.ViewportSize.Y); e.Tracer.To = Vector2.new(cx, t + h); e.Tracer.Color = color
                else for _,v in pairs(e) do if type(v)=="table" and v.Remove then else v.Visible = false end end end
            else for _,v in pairs(e) do if type(v)=="table" and v.Remove then else v.Visible = false end end end
        end
    else for _,e in pairs(espObjects) do for _,v in pairs(e) do v.Visible = false end end end

    -- Crosshair Logic
    if crosshairSettings.Enabled then
        local center = workspace.CurrentCamera.ViewportSize / 2
        local s, g = crosshairSettings.Size, crosshairSettings.Gap
        crosshairLines.T.From = center - Vector2.new(0, g); crosshairLines.T.To = center - Vector2.new(0, g+s)
        crosshairLines.B.From = center + Vector2.new(0, g); crosshairLines.B.To = center + Vector2.new(0, g+s)
        crosshairLines.L.From = center - Vector2.new(g, 0); crosshairLines.L.To = center - Vector2.new(g+s, 0)
        crosshairLines.R.From = center + Vector2.new(g, 0); crosshairLines.R.To = center + Vector2.new(g+s, 0)
        for _,l in pairs(crosshairLines) do l.Visible = true; l.Color = crosshairSettings.Color; l.Thickness = crosshairSettings.Thickness end
    else for _,l in pairs(crosshairLines) do l.Visible = false end end
end)

local SectionESP = TabVisuals:Section({ Title = "ESP Settings", Icon = "scan", Opened = true })
SectionESP:Toggle({ Title = "Enable ESP", Callback = function(v) espSettings.Enabled = v end })
SectionESP:Toggle({ Title = "Box", Callback = function(v) espSettings.Box = v end })
SectionESP:Toggle({ Title = "Name", Callback = function(v) espSettings.Name = v end })
SectionESP:Toggle({ Title = "Health (%)", Callback = function(v) espSettings.HealthText = v end })
SectionESP:Toggle({ Title = "Tracer", Callback = function(v) espSettings.Tracer = v end })
SectionESP:Toggle({ Title = "Team Check", Callback = function(v) espSettings.TeamCheck = v end })

local SectionCH = TabVisuals:Section({ Title = "Crosshair", Icon = "target", Opened = false })
SectionCH:Toggle({ Title = "Enable", Callback = function(v) crosshairSettings.Enabled = v end })
SectionCH:Colorpicker({ Title = "Color", Default = Color3.new(0,1,0), Callback = function(v) crosshairSettings.Color = v end })
SectionCH:Slider({ Title = "Gap", Step = 1, Value = { Min = 0, Max = 20, Default = 5 }, Callback = function(v) crosshairSettings.Gap = v end })

-- ============================================================
-- TAB: SERVER, CONFIG, ETC
-- ============================================================
local TabServer = Window:Tab({ Title = "Server", Icon = "server" })
TabServer:Section({ Title = "Actions" }):Button({ Title = "Rejoin", Callback = function() TeleportService:Teleport(game.PlaceId, LocalPlayer) end })
TabServer:Section({ Title = "Actions" }):Button({ Title = "Server Hop", Callback = function() 
    local servers = HttpService:JSONDecode(game:HttpGet("https://games.roblox.com/v1/games/"..game.PlaceId.."/servers/Public?sortOrder=Asc&limit=100")).data
    for _, s in pairs(servers) do if s.playing < s.maxPlayers and s.id ~= game.JobId then TeleportService:TeleportToPlaceInstance(game.PlaceId, s.id, LocalPlayer) break end end
end })

-- ============================================================
-- FINAL RESPAWN HANDLER (FIXED)
-- ============================================================
LocalPlayer.CharacterAdded:Connect(function(char)
    -- Clean connections to prevent instant death/glitch
    if airWalkConn then airWalkConn:Disconnect(); airWalkConn = nil end
    if invisV1Conn then invisV1Conn:Disconnect(); invisV1Conn = nil end
    if bhopConn then bhopConn:Disconnect(); bhopConn = nil end
    if spinbotConn then spinbotConn:Disconnect(); spinbotConn = nil end
    
    flyEnabled = false; pcall(function() flyToggle:Set(false) end)

    local hum = char:WaitForChild("Humanoid", 10)
    if not hum then return end
    task.wait(0.5)

    -- Force physics reset (Fixed jump bug)
    for _, st in ipairs(Enum.HumanoidStateType:GetEnumItems()) do pcall(function() hum:SetStateEnabled(st, true) end) end
    hum.PlatformStand = false
    
    -- Re-apply settings
    if walkSpeedEnabled then hum.WalkSpeed = walkSpeedValue end
    if jumpPowerEnabled then hum.UseJumpPower = true; hum.JumpPower = jumpPowerValue end
    if godmodeEnabled then hum.MaxHealth = math.huge; hum.Health = math.huge end
    
    char.Animate.Disabled = false
end)
