-- PieHub by Dylphiiee
local WindUI = loadstring(game:HttpGet("https://github.com/Footagesus/WindUI/releases/latest/download/main.lua"))()

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer

WindUI:SetNotificationLower(true)

-- Window
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
Window:Tag({ Title = "V1.0.0", Icon = "rocket", Color = Color3.fromHex("#30ff6a"), Radius = 12 })

-- Helpers
local function getChar() return LocalPlayer.Character end
local function getHum()
    local c = getChar()
    return c and c:FindFirstChildWhichIsA("Humanoid")
end
local function getHRP()
    local c = getChar()
    return c and c:FindFirstChild("HumanoidRootPart")
end

-- Tab: Player
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
local bunnyhopStrength = 1
local bunnyhopConn = nil

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
            if chr:FindFirstChild("Animate") then chr.Animate.Disabled = false end
            hum.PlatformStand = false
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
    Callback = function(v) flySpeed = v end
})

SectionMovement:Divider()

SectionMovement:Toggle({
    Title = "Bunny Hop",
    Desc = "Auto lompat saat mendarat",
    Icon = "rabbit",
    Value = false,
    Callback = function(state)
        bunnyhopEnabled = state
        if state then
            bunnyhopConn = RunService.Heartbeat:Connect(function()
                local hum = getHum()
                if not hum then return end
                if hum:GetState() == Enum.HumanoidStateType.Landed or hum:GetState() == Enum.HumanoidStateType.Running then
                    if UserInputService:IsKeyDown(Enum.KeyCode.Space) then
                        local hrp = getHRP()
                        if hrp then
                            hum:ChangeState(Enum.HumanoidStateType.Jumping)
                            hrp.Velocity = Vector3.new(hrp.Velocity.X, bunnyhopStrength * 50, hrp.Velocity.Z)
                        end
                    end
                end
            end)
        else
            if bunnyhopConn then bunnyhopConn:Disconnect() bunnyhopConn = nil end
        end
    end
})

SectionMovement:Slider({
    Title = "Bunny Hop Strength",
    Desc = "Kekuatan lompatan bunny hop | Default: 1",
    Icon = "chevrons-up",
    Step = 0.1,
    Value = { Min = 0.5, Max = 5, Default = 1 },
    IsTooltip = true,
    IsTextbox = true,
    Callback = function(v) bunnyhopStrength = v end
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

local SectionPlayer2 = TabPlayer:Section({ Title = "Player", Icon = "shield", Opened = true })

local godmodeConn = nil
local godmodeEnabled = false

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
        godmodeEnabled = state
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
    Title = "No Fall Damage",
    Desc = "Tidak ada damage jatuh",
    Icon = "shield-check",
    Value = false,
    Callback = function(state)
        local hum = getHum()
        if hum then hum:SetStateEnabled(Enum.HumanoidStateType.FallingDown, not state) end
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
                hrp.CFrame = origCF * CFrame.new(0, -200000, 0)
                hum.CameraOffset = (origCF * CFrame.new(0, -200000, 0)):ToObjectSpace(CFrame.new(origCF.Position)).Position
                RunService.RenderStepped:Wait()
                hrp.CFrame = origCF
                hum.CameraOffset = origOffset
            end)
        else
            if invisV1Conn then invisV1Conn:Disconnect() invisV1Conn = nil end
            for _, p in pairs(invisV1Parts) do pcall(function() p.Transparency = 0 end) end
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
                hrp.CFrame = origCF * CFrame.new(0, 200000, 0)
                hum.CameraOffset = (origCF * CFrame.new(0, 200000, 0)):ToObjectSpace(CFrame.new(origCF.Position)).Position
                RunService.RenderStepped:Wait()
                hrp.CFrame = origCF
                hum.CameraOffset = origOffset
            end)
        else
            if invisV2Conn then invisV2Conn:Disconnect() invisV2Conn = nil end
            for _, p in pairs(invisV2Parts) do pcall(function() p.Transparency = 0 end) end
            invisV2Parts = {}
        end
    end
})

-- Tab: Animations
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

-- Emote list lengkap dari Vexro + bawaan
local FullEmoteList = {
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
    { Title = "Wave",             Id = 3576686446  },
    { Title = "Dance",            Id = 3576720708  },
    { Title = "Laugh",            Id = 3576777185  },
    { Title = "Cheer",            Id = 3576738018  },
}

table.sort(FullEmoteList, function(a, b) return a.Title:lower() < b.Title:lower() end)

-- Emote pagination system
local EMOTE_PER_PAGE = 30
local emotePage = 1
local emoteSearchQuery = ""
local emoteSearchResults = FullEmoteList
local selectedEmote = nil
local currentEmoteTrack = nil

local function getFilteredEmotes(query)
    if not query or query == "" then return FullEmoteList end
    local result = {}
    local q = query:lower()
    for _, v in ipairs(FullEmoteList) do
        if v.Title:lower():find(q, 1, true) then
            table.insert(result, v)
        end
    end
    return result
end

local function getEmotePage(list, page)
    local names = {}
    local startIdx = (page - 1) * EMOTE_PER_PAGE + 1
    local endIdx = math.min(page * EMOTE_PER_PAGE, #list)
    for i = startIdx, endIdx do
        table.insert(names, list[i].Title)
    end
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
table.sort(animNameList, function(a, b) return a:lower() < b:lower() end)

local URL_ANIM = "http://www.roblox.com/asset/?id="
local selectedAnimation = nil
local selectedCustomEmote = nil
local customEmoteNameValue = ""
local customEmoteIdValue = ""
local defaultAnimIds = {}

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

-- Info halaman emote
local emotePageParagraph = SectionEmote:Paragraph({
    Title = "Halaman Emote",
    Desc = "Hal. 1 / " .. getTotalEmotePages(FullEmoteList) .. " | Total: " .. #FullEmoteList .. " emote",
    Icon = "list",
})

-- Dropdown emote (30 per halaman)
local emoteDropdown = SectionEmote:Dropdown({
    Title = "Daftar Emote",
    Desc = "Pilih emote untuk dimainkan",
    Values = getEmotePage(FullEmoteList, 1),
    Value = "",
    Callback = function(v) selectedEmote = v end
})

-- Search emote
local emoteSearchValue = ""
SectionEmote:Input({
    Title = "Cari Emote",
    Desc = "Ketik nama emote lalu tekan Search",
    Placeholder = "Contoh: Dance",
    Value = "",
    Callback = function(v) emoteSearchValue = v end
})

local function refreshEmoteDropdown()
    local totalPages = getTotalEmotePages(emoteSearchResults)
    emotePage = math.clamp(emotePage, 1, totalPages)
    emoteDropdown:Refresh(getEmotePage(emoteSearchResults, emotePage))
    emotePageParagraph:SetTitle("Halaman Emote")
    emotePageParagraph:SetDesc(
        "Hal. " .. emotePage .. " / " .. totalPages ..
        " | Hasil: " .. #emoteSearchResults .. " emote"
    )
    selectedEmote = nil
end

SectionEmote:Button({
    Title = "Search",
    Desc = "Cari emote berdasarkan nama",
    Icon = "search",
    Callback = function()
        emoteSearchResults = getFilteredEmotes(emoteSearchValue)
        emotePage = 1
        refreshEmoteDropdown()
        if #emoteSearchResults == 0 then
            WindUI:Notify({ Title = "Emote", Content = "Tidak ada emote dengan nama '" .. emoteSearchValue .. "'", Duration = 2, Icon = "alert-circle" })
        else
            WindUI:Notify({ Title = "Emote", Content = "Ditemukan " .. #emoteSearchResults .. " emote", Duration = 2, Icon = "search" })
        end
    end
})

local HStackEmoteNav = SectionEmote:HStack({ AutoSpace = true })

HStackEmoteNav:Button({
    Title = "◀ Previous",
    Callback = function()
        if emotePage <= 1 then
            WindUI:Notify({ Title = "Emote", Content = "Sudah di halaman pertama!", Duration = 2, Icon = "alert-circle" })
            return
        end
        emotePage = emotePage - 1
        refreshEmoteDropdown()
        WindUI:Notify({ Title = "Emote", Content = "Halaman " .. emotePage, Duration = 1, Icon = "chevron-left" })
    end
})

HStackEmoteNav:Button({
    Title = "Next ▶",
    Callback = function()
        local totalPages = getTotalEmotePages(emoteSearchResults)
        if emotePage >= totalPages then
            WindUI:Notify({ Title = "Emote", Content = "Sudah di halaman terakhir!", Duration = 2, Icon = "alert-circle" })
            return
        end
        emotePage = emotePage + 1
        refreshEmoteDropdown()
        WindUI:Notify({ Title = "Emote", Content = "Halaman " .. emotePage, Duration = 1, Icon = "chevron-right" })
    end
})

SectionEmote:Button({
    Title = "Reset Search",
    Desc = "Tampilkan semua emote",
    Icon = "refresh-cw",
    Callback = function()
        emoteSearchValue = ""
        emoteSearchResults = FullEmoteList
        emotePage = 1
        refreshEmoteDropdown()
        WindUI:Notify({ Title = "Emote", Content = "Menampilkan semua emote.", Duration = 2, Icon = "refresh-cw" })
    end
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

local function buildCustomEmoteNames()
    local names = {}
    for name in pairs(customEmotes) do table.insert(names, name) end
    table.sort(names, function(a, b) return a:lower() < b:lower() end)
    return names
end

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
        WindUI:Notify({ Title = "Custom Emote", Content = "Emote '" .. customEmoteNameValue .. "' disimpan!", Duration = 2, Icon = "save" })
    end
})

SectionMoreAnim:Button({
    Title = "Refresh",
    Desc = "Refresh daftar emote custom",
    Icon = "refresh-cw",
    Callback = function()
        customEmoteDropdown:Refresh(buildCustomEmoteNames())
        WindUI:Notify({ Title = "Custom Emote", Content = "Daftar diperbarui.", Duration = 2, Icon = "refresh-cw" })
    end
})

customEmoteDropdown = SectionMoreAnim:Dropdown({
    Title = "Daftar Custom Emote",
    Desc = "Emote custom tersimpan",
    Values = buildCustomEmoteNames(),
    Value = "",
    Callback = function(v) selectedCustomEmote = v end
})

SectionMoreAnim:Button({
    Title = "Apply Custom",
    Desc = "Mainkan emote custom yang dipilih",
    Icon = "play",
    Callback = function()
        if not selectedCustomEmote or not customEmotes[selectedCustomEmote] then
            WindUI:Notify({ Title = "Error", Content = "Pilih emote custom dulu!", Duration = 2, Icon = "alert-circle" })
            return
        end
        playEmote({ Title = selectedCustomEmote, Id = customEmotes[selectedCustomEmote] })
        WindUI:Notify({ Title = "Custom Emote", Content = "Memainkan '" .. selectedCustomEmote .. "'", Duration = 2, Icon = "play" })
    end
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
        WindUI:Notify({ Title = "Custom Emote", Content = "Emote dihapus.", Duration = 2, Icon = "trash" })
    end
})

-- Tab: Teleport
local TabTeleport = Window:Tab({ Title = "Teleport", Icon = "map-pin" })

local selectedPlayer = nil
local selectedPlace  = nil
local savedPlaces    = {}
local savedPlacesOrder = {}
local savedPlacesCount = 0
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

local placeNameInputValue = ""

local placeDropdown = SectionTpPlace:Dropdown({
    Title = "Pilih Place",
    Desc = "Pilih tempat yang sudah disimpan",
    Values = {},
    Value = "",
    Callback = function(v) selectedPlace = v end
})

SectionTpPlace:Input({
    Title = "Nama Tempat",
    Desc = "Nama tempat (kosong = auto)",
    Placeholder = "Nama tempat...",
    Value = "",
    Callback = function(v) placeNameInputValue = v end
})

local function getOrderedPlaceKeys()
    local keys = {}
    for _, k in ipairs(savedPlacesOrder) do
        if savedPlaces[k] then table.insert(keys, k) end
    end
    return keys
end

SectionTpPlace:Button({
    Title = "Save Place",
    Desc = "Simpan posisi saat ini",
    Icon = "save",
    Callback = function()
        local hrp = getHRP()
        if not hrp then
            WindUI:Notify({ Title = "Error", Content = "Karakter tidak ditemukan!", Duration = 2, Icon = "alert-circle" })
            return
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

SectionTpPlace:Button({
    Title = "Delete Place",
    Desc = "Hapus tempat yang dipilih",
    Icon = "trash",
    Callback = function()
        if selectedPlace and savedPlaces[selectedPlace] then
            savedPlaces[selectedPlace] = nil
            for i, k in ipairs(savedPlacesOrder) do
                if k == selectedPlace then table.remove(savedPlacesOrder, i) break end
            end
            placeDropdown:Refresh(getOrderedPlaceKeys())
            selectedPlace = nil
            WindUI:Notify({ Title = "Delete", Content = "Tempat dihapus.", Duration = 2, Icon = "trash" })
        else
            WindUI:Notify({ Title = "Error", Content = "Pilih tempat dulu!", Duration = 2, Icon = "alert-circle" })
        end
    end
})

SectionTpPlace:Button({
    Title = "Refresh",
    Desc = "Refresh daftar tempat",
    Icon = "refresh-cw",
    Callback = function()
        placeDropdown:Refresh(getOrderedPlaceKeys())
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
        else
            WindUI:Notify({ Title = "Error", Content = "Karakter tidak ditemukan!", Duration = 2, Icon = "alert-circle" })
        end
    end
})

-- Tab: Visuals
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
        box[i] = newDrawing("Line", { Color = Color3.fromRGB(255, 50, 50), Thickness = 1.5, Visible = false, ZIndex = 2 })
        table.insert(drawings, box[i])
    end
    local nameText = newDrawing("Text", { Color = Color3.fromRGB(255, 255, 255), Size = 13, Center = true, Outline = true, OutlineColor = Color3.fromRGB(0, 0, 0), Visible = false, ZIndex = 3 })
    table.insert(drawings, nameText)
    local distText = newDrawing("Text", { Color = Color3.fromRGB(200, 200, 200), Size = 12, Center = true, Outline = true, OutlineColor = Color3.fromRGB(0, 0, 0), Visible = false, ZIndex = 3 })
    table.insert(drawings, distText)
    local healthBg = newDrawing("Line", { Color = Color3.fromRGB(0, 0, 0), Thickness = 4, Visible = false, ZIndex = 3 })
    table.insert(drawings, healthBg)
    local healthBar = newDrawing("Line", { Color = Color3.fromRGB(0, 255, 0), Thickness = 3, Visible = false, ZIndex = 4 })
    table.insert(drawings, healthBar)
    local healthText = newDrawing("Text", { Color = Color3.fromRGB(255, 255, 255), Size = 11, Center = true, Outline = true, OutlineColor = Color3.fromRGB(0, 0, 0), Visible = false, ZIndex = 5 })
    table.insert(drawings, healthText)
    local tracer = newDrawing("Line", { Color = Color3.fromRGB(255, 50, 50), Thickness = 1, Visible = false, ZIndex = 1 })
    table.insert(drawings, tracer)
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
        local showBox = espSettings.Box
        e.box[1].From = Vector2.new(left, top)  e.box[1].To = Vector2.new(right, top) e.box[1].Visible = showBox
        e.box[2].From = Vector2.new(left, bot)  e.box[2].To = Vector2.new(right, bot) e.box[2].Visible = showBox
        e.box[3].From = Vector2.new(left, top)  e.box[3].To = Vector2.new(left, bot)  e.box[3].Visible = showBox
        e.box[4].From = Vector2.new(right, top) e.box[4].To = Vector2.new(right, bot) e.box[4].Visible = showBox
        e.nameText.Position = Vector2.new(cx, top - 15)
        e.nameText.Text = p.DisplayName
        e.nameText.Visible = espSettings.Name
        local myHRP = getHRP()
        local dist = myHRP and math.floor((hrp.Position - myHRP.Position).Magnitude) or 0
        e.distText.Position = Vector2.new(cx, bot + 3)
        e.distText.Text = dist .. "m"
        e.distText.Visible = espSettings.Distance
        local hpRatio = math.clamp(hum.Health / math.max(hum.MaxHealth, 1), 0, 1)
        local barX = left - 6
        local barTop = top
        local barBot = bot
        local barFillBot = bot - ((bot - top) * hpRatio)
        e.healthBg.From = Vector2.new(barX, barTop) e.healthBg.To = Vector2.new(barX, barBot) e.healthBg.Visible = espSettings.Health
        e.healthBar.Color = Color3.fromRGB(math.floor(255*(1-hpRatio)), math.floor(255*hpRatio), 0)
        e.healthBar.From = Vector2.new(barX, barFillBot) e.healthBar.To = Vector2.new(barX, barBot) e.healthBar.Visible = espSettings.Health
        e.healthText.Position = Vector2.new(barX - 8, (barTop + barBot) / 2 - 5)
        e.healthText.Text = math.floor(hpRatio * 100) .. "%"
        e.healthText.Visible = espSettings.Health
        e.tracer.From = Vector2.new(vpSize.X / 2, vpSize.Y) e.tracer.To = Vector2.new(cx, bot) e.tracer.Visible = espSettings.Tracer
        updateESPHighlight(p, espSettings.Highlight)
    end
end)

Players.PlayerAdded:Connect(function(p)
    if espSettings.Enabled then createESPFor(p) end
    p.CharacterAdded:Connect(function()
        if espSettings.Enabled then task.wait(1) updateESPHighlight(p, espSettings.Highlight) end
    end)
end)

Players.PlayerRemoving:Connect(function(p) removeESPFor(p.Name) end)

local function refreshAllESP()
    clearAllESP()
    if espSettings.Enabled then
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= LocalPlayer then createESPFor(p) updateESPHighlight(p, espSettings.Highlight) end
        end
    end
end

local SectionESP = TabVisuals:Section({ Title = "ESP", Icon = "scan", Opened = true })

SectionESP:Toggle({ Title = "ESP", Desc = "Enable / Disable semua ESP", Icon = "scan", Value = false, Callback = function(v) espSettings.Enabled = v refreshAllESP() end })
SectionESP:Toggle({ Title = "ESP Box", Desc = "Kotak di sekitar player", Icon = "square", Value = false, Callback = function(v) espSettings.Box = v end })
SectionESP:Toggle({ Title = "ESP Name", Desc = "Tampilkan nama player", Icon = "user", Value = false, Callback = function(v) espSettings.Name = v end })
SectionESP:Toggle({ Title = "ESP Health", Desc = "Tampilkan health bar player", Icon = "heart", Value = false, Callback = function(v) espSettings.Health = v end })
SectionESP:Toggle({ Title = "ESP Distance", Desc = "Tampilkan jarak ke player", Icon = "ruler", Value = false, Callback = function(v) espSettings.Distance = v end })
SectionESP:Toggle({ Title = "ESP Tracer", Desc = "Garis dari bawah layar ke player", Icon = "navigation", Value = false, Callback = function(v) espSettings.Tracer = v end })
SectionESP:Toggle({ Title = "ESP Highlight", Desc = "Highlight karakter player", Icon = "highlighter", Value = false, Callback = function(v)
    espSettings.Highlight = v
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer then updateESPHighlight(p, v) end
    end
end })

local SectionVisualMore = TabVisuals:Section({ Title = "World", Icon = "globe", Opened = true })

local freecamEnabled = false
local freecamSpeed = 20

SectionVisualMore:Toggle({
    Title = "Freecam", Desc = "Kamera bebas terbang", Icon = "video", Value = false,
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
                    if moveVec.Magnitude > 0 then cam.CFrame = cam.CFrame + moveVec.Unit * freecamSpeed * 0.016 end
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
        local lighting = game:GetService("Lighting")
        if state then
            lighting.Brightness = 2 lighting.ClockTime = 14 lighting.FogEnd = 100000
            lighting.GlobalShadows = false lighting.Ambient = Color3.fromRGB(255, 255, 255)
        else
            lighting.Brightness = 1 lighting.ClockTime = 14 lighting.FogEnd = 100000
            lighting.GlobalShadows = true lighting.Ambient = Color3.fromRGB(127, 127, 127)
        end
    end
})

SectionVisualMore:Toggle({
    Title = "No Fog", Desc = "Hilangkan fog", Icon = "cloud-off", Value = false,
    Callback = function(state)
        local lighting = game:GetService("Lighting")
        if state then lighting.FogEnd = 100000 lighting.FogStart = 100000
        else lighting.FogEnd = 100000 lighting.FogStart = 0 end
    end
})

SectionVisualMore:Toggle({
    Title = "No Skybox", Desc = "Hilangkan skybox", Icon = "image-off", Value = false,
    Callback = function(state)
        local lighting = game:GetService("Lighting")
        local sky = lighting:FindFirstChildOfClass("Sky")
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

local crosshairEnabled = false
local crosshairLines = {}

local function createCrosshair()
    local vpSize = workspace.CurrentCamera.ViewportSize
    local cx = vpSize.X / 2
    local cy = vpSize.Y / 2
    local size = 10
    local gap = 4
    local thickness = 2
    local color = Color3.fromRGB(255, 255, 255)
    crosshairLines[1] = Drawing.new("Line") crosshairLines[1].From = Vector2.new(cx, cy - gap - size) crosshairLines[1].To = Vector2.new(cx, cy - gap) crosshairLines[1].Color = color crosshairLines[1].Thickness = thickness crosshairLines[1].Visible = true
    crosshairLines[2] = Drawing.new("Line") crosshairLines[2].From = Vector2.new(cx, cy + gap) crosshairLines[2].To = Vector2.new(cx, cy + gap + size) crosshairLines[2].Color = color crosshairLines[2].Thickness = thickness crosshairLines[2].Visible = true
    crosshairLines[3] = Drawing.new("Line") crosshairLines[3].From = Vector2.new(cx - gap - size, cy) crosshairLines[3].To = Vector2.new(cx - gap, cy) crosshairLines[3].Color = color crosshairLines[3].Thickness = thickness crosshairLines[3].Visible = true
    crosshairLines[4] = Drawing.new("Line") crosshairLines[4].From = Vector2.new(cx + gap, cy) crosshairLines[4].To = Vector2.new(cx + gap + size, cy) crosshairLines[4].Color = color crosshairLines[4].Thickness = thickness crosshairLines[4].Visible = true
    crosshairLines[5] = Drawing.new("Line") crosshairLines[5].From = Vector2.new(cx - 1, cy) crosshairLines[5].To = Vector2.new(cx + 1, cy) crosshairLines[5].Color = Color3.fromRGB(255, 50, 50) crosshairLines[5].Thickness = 2 crosshairLines[5].Visible = true
end

local function removeCrosshair()
    for _, l in pairs(crosshairLines) do pcall(function() l:Remove() end) end
    crosshairLines = {}
end

SectionVisualMore:Toggle({
    Title = "Crosshair", Desc = "Tampilkan crosshair di tengah layar", Icon = "crosshair", Value = false,
    Callback = function(state)
        crosshairEnabled = state
        if state then createCrosshair() else removeCrosshair() end
    end
})

-- Tab: Server
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
            local VirtualUser = game:GetService("VirtualUser")
            antiAfkConn = Players.LocalPlayer.Idled:Connect(function()
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
    Title = "Rejoin", Desc = "Masuk ulang ke game ini", Icon = "log-in",
    Callback = function() TeleportService:Teleport(game.PlaceId, LocalPlayer) end
})

SectionServerActions:Button({
    Title = "Server Hop", Desc = "Pindah ke server lain", Icon = "shuffle",
    Callback = function()
        local placeId = game.PlaceId
        local servers = {}
        local success, result = pcall(function()
            local url = "https://games.roblox.com/v1/games/" .. placeId .. "/servers/Public?sortOrder=Asc&limit=100"
            local res = HttpService:JSONDecode(game:HttpGet(url))
            for _, s in pairs(res.data) do
                if s.playing < s.maxPlayers then table.insert(servers, s.id) end
            end
        end)
        if success and #servers > 0 then
            TeleportService:TeleportToPlaceInstance(placeId, servers[math.random(1, #servers)], LocalPlayer)
        else
            WindUI:Notify({ Title = "Server Hop", Content = "Tidak ada server lain ditemukan.", Duration = 3, Icon = "alert-circle" })
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
                found = true
                break
            end
        end
        if not found then
            WindUI:Notify({ Title = "Server Friend", Content = "Tidak ada teman online di game ini.", Duration = 3, Icon = "alert-circle" })
        end
    end
})

-- Tab: DevTools
local TabDevTools = Window:Tab({ Title = "DevTools", Icon = "code" })

local savedCoords = {}
local savedCoordsOrder = {}
local savedCoordsCount = 0
local selectedCoord = nil
local coordNameValue = ""

local function buildCoordCode()
    if #savedCoordsOrder == 0 then return "-- Belum ada koordinat tersimpan" end
    local lines = {}
    table.insert(lines, "-- Koordinat tersimpan:")
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
    Title = "Koordinat Tersimpan",
    Code = "-- Belum ada koordinat tersimpan",
    OnCopy = function()
        WindUI:Notify({ Title = "DevTools", Content = "Kode disalin!", Duration = 2, Icon = "copy" })
    end
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
    coordDropdown:Refresh(keys)
    coordCodeBlock:SetCode(buildCoordCode())
end

SectionCoords:Button({
    Title = "Save Koordinat", Desc = "Simpan posisi karakter saat ini", Icon = "save",
    Callback = function()
        local hrp = getHRP()
        if not hrp then
            WindUI:Notify({ Title = "Error", Content = "Karakter tidak ditemukan!", Duration = 2, Icon = "alert-circle" })
            return
        end
        savedCoordsCount = savedCoordsCount + 1
        local name = (coordNameValue ~= "" and coordNameValue) or ("checkpoint" .. savedCoordsCount)
        if savedCoords[name] then name = name .. " (" .. savedCoordsCount .. ")" end
        savedCoords[name] = hrp.CFrame
        table.insert(savedCoordsOrder, name)
        refreshCoordDropdown()
        WindUI:Notify({ Title = "DevTools", Content = "Koordinat '" .. name .. "' disimpan!", Duration = 2, Icon = "save" })
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
            WindUI:Notify({ Title = "Error", Content = "Pilih koordinat dulu!", Duration = 2, Icon = "alert-circle" })
            return
        end
        savedCoords[selectedCoord] = nil
        for i, k in ipairs(savedCoordsOrder) do
            if k == selectedCoord then table.remove(savedCoordsOrder, i) break end
        end
        selectedCoord = nil
        refreshCoordDropdown()
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

-- Tab: Config
local TabConfig = Window:Tab({ Title = "Config", Icon = "settings" })

local ConfigManager = Window.ConfigManager
local configInputValue = ""
local selectedConfig = nil

local SectionConfigSave = TabConfig:Section({ Title = "Save & Load", Icon = "save", Opened = true })

SectionConfigSave:Input({
    Title = "Nama Config", Desc = "Masukkan nama config baru",
    Placeholder = "Contoh: myConfig", Value = "",
    Callback = function(v) configInputValue = v end
})

local function getConfigNames()
    local all = ConfigManager:AllConfigs()
    local names = {}
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
        cfg:Save()
        configDropdown:Refresh(getConfigNames())
        WindUI:Notify({ Title = "Config", Content = "Config '" .. name .. "' disimpan!", Duration = 2, Icon = "save" })
    end
})

SectionConfigSave:Button({
    Title = "Apply Config", Desc = "Terapkan config yang dipilih", Icon = "check",
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
            WindUI:Notify({ Title = "Error", Content = "Pilih config dulu!", Duration = 2, Icon = "alert-circle" })
            return
        end
        ConfigManager:DeleteConfig(selectedConfig)
        selectedConfig = nil
        configDropdown:Refresh(getConfigNames())
        WindUI:Notify({ Title = "Config", Content = "Config dihapus.", Duration = 2, Icon = "trash" })
    end
})

-- Tab: Info
local TabInfo = Window:Tab({ Title = "Info", Icon = "info" })

TabInfo:Image({ Image = "rbxassetid://5107182114", AspectRatio = "16:9", Radius = 12 })

local SectionInfoAbout = TabInfo:Section({ Title = "About", Icon = "info", Opened = true })
SectionInfoAbout:Paragraph({ Title = "PieHub", Desc = "Version: 1.0.0\nBuild: Stable", Icon = "cookie" })
SectionInfoAbout:Paragraph({ Title = "Creator", Desc = "Dibuat oleh Dylphiiee\nTerimakasih sudah menggunakan PieHub!", Icon = "user" })

local SectionInfoContact = TabInfo:Section({ Title = "Contact", Icon = "phone", Opened = true })

SectionInfoContact:Button({
    Title = "Discord", Desc = "Join server Discord kami", Icon = "message-circle", Color = Color3.fromHex("#5865F2"),
    Callback = function()
        setclipboard("https://discord.gg/yourinvite")
        WindUI:Notify({ Title = "Discord", Content = "Link Discord disalin ke clipboard!", Duration = 3, Icon = "message-circle" })
    end
})

SectionInfoContact:Button({
    Title = "WhatsApp", Desc = "Hubungi via WhatsApp", Icon = "phone", Color = Color3.fromHex("#25D366"),
    Callback = function()
        setclipboard("https://wa.me/yourwalink")
        WindUI:Notify({ Title = "WhatsApp", Content = "Link WhatsApp disalin ke clipboard!", Duration = 3, Icon = "phone" })
    end
})

-- Respawn Handler
LocalPlayer.CharacterAdded:Connect(function(char)
    task.wait(0.7)
    flyEnabled = false
    pcall(function() flyToggle:Set(false) end)
    local hum = char:WaitForChild("Humanoid", 10)
    if hum then
        hum.PlatformStand = false
        for _, st in ipairs(Enum.HumanoidStateType:GetEnumItems()) do
            pcall(function() hum:SetStateEnabled(st, true) end)
        end
        if jumpPowerEnabled then hum.JumpPower = jumpPowerValue end
        if walkSpeedEnabled then hum.WalkSpeed = walkSpeedValue end
        if godmodeEnabled then hum.MaxHealth = math.huge hum.Health = math.huge end
    end
    local animate = char:FindFirstChild("Animate")
    if animate then animate.Disabled = false end
    if bunnyhopEnabled then
        if bunnyhopConn then bunnyhopConn:Disconnect() bunnyhopConn = nil end
        bunnyhopConn = RunService.Heartbeat:Connect(function()
            local h = char:FindFirstChildWhichIsA("Humanoid")
            if not h then return end
            if h:GetState() == Enum.HumanoidStateType.Landed or h:GetState() == Enum.HumanoidStateType.Running then
                if UserInputService:IsKeyDown(Enum.KeyCode.Space) then
                    local root = char:FindFirstChild("HumanoidRootPart")
                    if root then
                        h:ChangeState(Enum.HumanoidStateType.Jumping)
                        root.Velocity = Vector3.new(root.Velocity.X, bunnyhopStrength * 50, root.Velocity.Z)
                    end
                end
            end
        end)
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
end)
