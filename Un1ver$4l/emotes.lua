-- QuickEmotes Panel + Speed + ShiftLock
-- Tab: Anim | Emote | VD | R6

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local UserInputService = game:GetService("UserInputService")
local CoreGui = game:GetService("CoreGui")
local LocalPlayer = Players.LocalPlayer
local camera = workspace.CurrentCamera

local QUICK_EMOTE_PER_PAGE = 10

local function getChar() return LocalPlayer.Character end
local function getHum()
    local c = getChar()
    return c and c:FindFirstChildWhichIsA("Humanoid")
end

-- ===================== ANIMATION LIST =====================
local AnimationList = {
    { Title = "Astronaut",  Idle=10921034824, Idle2=10921036806, Walk=10921046031, Run=10921039308, Jump=10921042494, Climb=10921032124, Fall=10921040576, Swim=10921044000, SwimIdle=10921045006 },
    { Title = "Bubbly",     Idle=10921054344, Idle2=10921055107, Walk=10980888364, Run=10921057244, Jump=10921062673, Climb=10921053544, Fall=10921061530, Swim=10921063569, SwimIdle=10922582160 },
    { Title = "Cartoony",   Idle=10921071918, Idle2=10921072875, Walk=10921082452, Run=10921076136, Jump=10921078135, Climb=10921070953, Fall=10921077030, Swim=10921079380, SwimIdle=10921081059 },
    { Title = "Confident",  Idle=1069987858,  Idle2=1069977950,  Walk=1070017263,  Run=1070001516,  Jump=1069984524,  Climb=1069946257,  Fall=1069973677,  Swim=1070009914,  SwimIdle=1070012133  },
    { Title = "Cowboy",     Idle=1014398616,  Idle2=1014390418,  Walk=1014421541,  Run=1014401683,  Jump=1014394726,  Climb=1014380606,  Fall=1014384571,  Swim=1014406523,  SwimIdle=1014411816  },
    { Title = "Elder",      Idle=10921101664, Idle2=10921102574, Walk=10921111375, Run=10921104374, Jump=10921107367, Climb=10921100400, Fall=10921105765, Swim=10921108971, SwimIdle=10921110146 },
    { Title = "Knight",     Idle=10921117521, Idle2=10921118894, Walk=10921127095, Run=10921121197, Jump=10921123517, Climb=10921116196, Fall=10921122579, Swim=10921125160, SwimIdle=10921125935 },
    { Title = "Levitation", Idle=10921132962, Idle2=10921133721, Walk=10921140719, Run=10921135644, Jump=10921137402, Climb=10921132092, Fall=10921136539, Swim=10921138209, SwimIdle=10921139478 },
    { Title = "Mage",       Idle=10921144709, Idle2=10921145797, Walk=10921152678, Run=10921148209, Jump=10921149743, Climb=10921143404, Fall=10921148939, Swim=10921150788, SwimIdle=10921151661 },
    { Title = "Ninja",      Idle=10921155160, Idle2=10921155867, Walk=10921162768, Run=10921157929, Jump=10921160088, Climb=10921154678, Fall=10921159222, Swim=10921161002, SwimIdle=10922757002 },
    { Title = "Oldschool",  Idle=10921230744, Idle2=10921232093, Walk=10921244891, Run=10921240218, Jump=10921242013, Climb=10921229866, Fall=10921241244, Swim=10921243048, SwimIdle=10921244018 },
    { Title = "Patrol",     Idle=1150842221,  Idle2=1149612882,  Walk=1151231493,  Run=1150967949,  Jump=1150944216,  Climb=1148811837,  Fall=1148863382,  Swim=1151204998,  SwimIdle=1151221899  },
    { Title = "Pirate",     Idle=750781874,   Idle2=750782770,   Walk=750785693,   Run=750783738,   Jump=750782230,   Climb=750779899,   Fall=750780242,   Swim=750784579,   SwimIdle=750785176   },
    { Title = "Popstar",    Idle=1212954651,  Idle2=1212900985,  Walk=1212980338,  Run=1212980348,  Jump=1212954642,  Climb=1213044953,  Fall=1212900995,  Swim=1212852603,  SwimIdle=1212998578  },
    { Title = "Princess",   Idle=941013098,   Idle2=941003647,   Walk=941028902,   Run=941015281,   Jump=941008832,   Climb=940996062,   Fall=941000007,   Swim=941018893,   SwimIdle=941025398   },
    { Title = "Robot",      Idle=10921248039, Idle2=10921248831, Walk=10921255446, Run=10921250460, Jump=10921252123, Climb=10921247141, Fall=10921251156, Swim=10921253142, SwimIdle=10921253767 },
    { Title = "Sneaky",     Idle=1132477671,  Idle2=1132473842,  Walk=1132510133,  Run=1132494274,  Jump=1132489853,  Climb=1132461372,  Fall=1132469004,  Swim=1132500520,  SwimIdle=1132506407  },
    { Title = "Superhero",  Idle=10921288909, Idle2=10921290167, Walk=10921298616, Run=10921291831, Jump=10921294559, Climb=10921286911, Fall=10921293373, Swim=10921295495, SwimIdle=10921297391 },
    { Title = "Vampire",    Idle=10921315373, Idle2=10921316709, Walk=10921326949, Run=10921320299, Jump=10921322186, Climb=10921314188, Fall=10921321317, Swim=10921324408, SwimIdle=10921325443 },
    { Title = "Zombie",     Idle=10921344533, Idle2=10921345304, Walk=10921355261, Run=616163682,   Jump=10921351278, Climb=10921343576, Fall=10921350320, Swim=10921352344, SwimIdle=10921353442 },
}

-- ===================== VD EMOTE LIST =====================
local VDEmoteList = {
    { Title="24 Hour Cinderella", Id=137195203725366 },
    { Title="Applause",           Id=96328361165090  },
    { Title="Arm Swing",          Id=80552139463944  },
    { Title="Backflip",           Id=74705617908505  },
    { Title="Broken Doll",        Id=131796630104825 },
    { Title="California Girl",    Id=123552803041504 },
    { Title="Christmas Spirit",   Id=137859761110514 },
    { Title="Floating Rest",      Id=114593021219597 },
    { Title="Friday Night",       Id=83229063951016  },
    { Title="Ghoul",              Id=130415594909401 },
    { Title="Griddy",             Id=75586690784894  },
    { Title="Kwik Flip",          Id=73896868179198  },
    { Title="Kyoufuu",            Id=137322894494527 },
    { Title="Manrobics",          Id=134677515695156 },
    { Title="Oneplays",           Id=140625405103474 },
    { Title="Pop Off",            Id=130933486827090 },
    { Title="Quick Combo",        Id=105592621576604 },
    { Title="Rambunctious",       Id=81054496834622  },
    { Title="Rampage",            Id=79155929355612  },
    { Title="Schadenfreude",      Id=138303785534052 },
    { Title="Source",             Id=122615684039119 },
    { Title="Static",             Id=95096724457263  },
    { Title="The Dab",            Id=93350677984372  },
    { Title="Thriller",           Id=99835792883875  },
    { Title="Tor Monitor",        Id=81792358514569  },
    { Title="Vulnerable",         Id=121773684313913 },
    { Title="War Cry",            Id=82600868380136  },
    { Title="Wave",                Id=99670106766588  },
}

-- ===================== R6 EMOTE LIST =====================
local R6EmoteList = {
    { Title="Head Throw",     Id=35154961  },
    { Title="Floating Head",  Id=121572214 },
    { Title="Crouch",         Id=182724289 },
    { Title="Floor Crawl",    Id=282574440 },
    { Title="Dino Walk",      Id=204328711 },
    { Title="Jumping Jacks",  Id=429681631 },
    { Title="Loop Head",      Id=35154961  },
    { Title="Hero Jump",      Id=184574340 },
    { Title="Faint",          Id=181526230 },
    { Title="Floor Faint",    Id=181525546 },
    { Title="Super Faint",    Id=181525546 },
    { Title="Levitate",       Id=313762630 },
    { Title="Dab",            Id=183412246 },
    { Title="Spinner",        Id=188632011 },
    { Title="Float Sit",      Id=179224234 },
    { Title="Moving Dance",   Id=429703734 },
    { Title="Weird Move",     Id=215384594 },
    { Title="Clone Illusion", Id=215384594 },
    { Title="Glitch Levitate",Id=313762630 },
    { Title="Spin Dance",     Id=429730430 },
    { Title="Moon Dance",     Id=45834924  },
    { Title="Full Punch",     Id=204062532 },
    { Title="Spin Dance 2",   Id=186934910 },
    { Title="Bow Down",       Id=204292303 },
    { Title="Sword Slam",     Id=204295235 },
    { Title="Loop Slam",      Id=204295235 },
    { Title="Mega Insane",    Id=184574340 },
    { Title="Super Punch",    Id=126753849 },
    { Title="Full Swing",     Id=218504594 },
    { Title="Arm Turbine",    Id=259438880 },
    { Title="Barrel Roll",    Id=136801964 },
    { Title="Scared",         Id=180612465 },
    { Title="Insane",         Id=33796059  },
    { Title="Arm Detach",     Id=33169583  },
    { Title="Sword Slice",    Id=35978879  },
    { Title="Insane Arms",    Id=27432691  },
}

-- ===================== ANIM HELPERS =====================
local URL_ANIM = "http://www.roblox.com/asset/?id="
local defaultAnimIds = {}
local currentEmoteTrack = nil
local emoteLoopEnabled = true
local walkEmoteConn = nil
local _animObjCache = {}
local emotePlayGeneration = 0

local animNameList = {}
for _, v in ipairs(AnimationList) do table.insert(animNameList, v.Title) end
table.sort(animNameList, function(a,b) return a:lower()<b:lower() end)

local function getAnimData(title)
    for _, v in ipairs(AnimationList) do
        if v.Title == title then return v end
    end
end

local function getAnimator()
    local chr = getChar() if not chr then return nil end
    local hum = chr:FindFirstChildWhichIsA("Humanoid") if not hum then return nil end
    local anim = hum:FindFirstChildOfClass("Animator")
    if not anim then anim = Instance.new("Animator") anim.Parent = hum end
    return anim
end

local function stopAllTracks()
    local anim = getAnimator() if not anim then return end
    for _, t in ipairs(anim:GetPlayingAnimationTracks()) do pcall(function() t:Stop(0.1) end) end
    currentEmoteTrack = nil
end

local function saveDefaultAnims()
    local chr = getChar() if not chr then return end
    local Animate = chr:FindFirstChild("Animate")
    if not Animate or next(defaultAnimIds) ~= nil then return end
    pcall(function()
        if Animate:FindFirstChild("idle") then
            defaultAnimIds.Idle  = Animate.idle.Animation1.AnimationId
            defaultAnimIds.Idle2 = Animate.idle.Animation2.AnimationId
        end
        for _, name in ipairs({"walk","run","jump","climb","fall"}) do
            if Animate:FindFirstChild(name) then
                local a = Animate[name]:FindFirstChildOfClass("Animation")
                if a then defaultAnimIds[name:sub(1,1):upper()..name:sub(2)] = a.AnimationId end
            end
        end
        for _, pair in ipairs({{"swim","Swim"},{"swimidle","SwimIdle"}}) do
            if Animate:FindFirstChild(pair[1]) then
                local a = Animate[pair[1]]:FindFirstChildOfClass("Animation")
                if a then defaultAnimIds[pair[2]] = a.AnimationId end
            end
        end
    end)
end

local function applyAnimation(data)
    local chr = getChar() if not chr then return end
    local Animate = chr:FindFirstChild("Animate") if not Animate then return end
    saveDefaultAnims() stopAllTracks()
    pcall(function()
        if Animate:FindFirstChild("idle") then
            Animate.idle.Animation1.AnimationId = URL_ANIM..data.Idle
            Animate.idle.Animation2.AnimationId = URL_ANIM..data.Idle2
        end
        for _, p in ipairs({{"walk","Walk"},{"run","Run"},{"jump","Jump"},{"climb","Climb"},{"fall","Fall"}}) do
            if Animate:FindFirstChild(p[1]) then
                local a = Animate[p[1]]:FindFirstChildOfClass("Animation")
                if a then a.AnimationId = URL_ANIM..data[p[2]] end
            end
        end
        if data.Swim and Animate:FindFirstChild("swim") then
            local a = Animate.swim:FindFirstChildOfClass("Animation")
            if a then a.AnimationId = URL_ANIM..data.Swim end
        end
        if data.SwimIdle and Animate:FindFirstChild("swimidle") then
            local a = Animate.swimidle:FindFirstChildOfClass("Animation")
            if a then a.AnimationId = URL_ANIM..data.SwimIdle end
        end
    end)
    Animate.Disabled = true task.wait(0.05) Animate.Disabled = false
end

local function resetAnimation()
    local chr = getChar() if not chr then return end
    local Animate = chr:FindFirstChild("Animate") if not Animate then return end
    stopAllTracks()
    if next(defaultAnimIds) ~= nil then
        pcall(function()
            if Animate:FindFirstChild("idle") then
                if defaultAnimIds.Idle  then Animate.idle.Animation1.AnimationId = defaultAnimIds.Idle  end
                if defaultAnimIds.Idle2 then Animate.idle.Animation2.AnimationId = defaultAnimIds.Idle2 end
            end
            for _, p in ipairs({{"walk","Walk"},{"run","Run"},{"jump","Jump"},{"climb","Climb"},{"fall","Fall"}}) do
                if Animate:FindFirstChild(p[1]) then
                    local a = Animate[p[1]]:FindFirstChildOfClass("Animation")
                    if a and defaultAnimIds[p[2]] then a.AnimationId = defaultAnimIds[p[2]] end
                end
            end
            for _, pair in ipairs({{"swim","Swim"},{"swimidle","SwimIdle"}}) do
                if Animate:FindFirstChild(pair[1]) then
                    local a = Animate[pair[1]]:FindFirstChildOfClass("Animation")
                    if a and defaultAnimIds[pair[2]] then a.AnimationId = defaultAnimIds[pair[2]] end
                end
            end
        end)
    end
    Animate.Disabled = true task.wait(0.05) Animate.Disabled = false
    defaultAnimIds = {}
end

local function loadEmoteObj(id)
    local obj = _animObjCache[id]
    if not obj then
        local ok, objects = pcall(function() return game:GetObjects("rbxassetid://"..tostring(id)) end)
        if ok and objects and #objects > 0 then
            local item = objects[1]
            obj = item:IsA("Animation") and item or item:FindFirstChildWhichIsA("Animation", true)
        end
        if not obj then
            obj = Instance.new("Animation")
            obj.AnimationId = "rbxassetid://"..tostring(id)
        end
        _animObjCache[id] = obj
    end
    return obj
end

local function playEmote(data, loopState)
    emotePlayGeneration = emotePlayGeneration + 1
    local myGen = emotePlayGeneration
    if walkEmoteConn then walkEmoteConn:Disconnect() walkEmoteConn = nil end
    if currentEmoteTrack then pcall(function() currentEmoteTrack:Stop(0.1) end) currentEmoteTrack = nil end
    local animator = getAnimator() if not animator then return end
    for _, t in ipairs(animator:GetPlayingAnimationTracks()) do pcall(function() t:Stop(0.1) end) end
    task.spawn(function()
        local animObj = loadEmoteObj(data.Id)
        local ok2, track = pcall(function() return animator:LoadAnimation(animObj) end)
        if myGen ~= emotePlayGeneration then
            if ok2 and track then pcall(function() track:Stop(0) track:Destroy() end) end
            return
        end
        if not ok2 or not track then return end
        track.Priority = Enum.AnimationPriority.Action4
        track.Looped = loopState
        track:Play(0.15)
        if myGen ~= emotePlayGeneration then pcall(function() track:Stop(0) end) return end
        currentEmoteTrack = track
        local conn
        conn = RunService.Heartbeat:Connect(function()
            if myGen ~= emotePlayGeneration then conn:Disconnect() return end
            if not getHum() then pcall(function() track:Stop(0.1) end) conn:Disconnect() currentEmoteTrack = nil end
        end)
        track.Stopped:Connect(function()
            if myGen == emotePlayGeneration then currentEmoteTrack = nil end
            pcall(function() conn:Disconnect() end)
        end)
    end)
end

local function stopEmote()
    emotePlayGeneration = emotePlayGeneration + 1
    if walkEmoteConn then walkEmoteConn:Disconnect() walkEmoteConn = nil end
    if currentEmoteTrack then pcall(function() currentEmoteTrack:Stop(0.2) end) currentEmoteTrack = nil end
    local animator = getAnimator()
    if animator then
        for _, t in ipairs(animator:GetPlayingAnimationTracks()) do
            if t.Priority == Enum.AnimationPriority.Action4 then pcall(function() t:Stop(0.2) end) end
        end
    end
end

-- ===================== ONLINE EMOTE LIST =====================
local FullEmoteList = {}

pcall(function()
    local res = game:HttpGet("https://raw.githubusercontent.com/zyrovell/Vexro/main/emotes.json")
    local data = HttpService:JSONDecode(res)
    if type(data) == "table" then
        for _, v in ipairs(data.data) do
            local name = v.name or v.Name
            local id = tonumber(v.id or v.Id)
            if name and id then table.insert(FullEmoteList, {Title=tostring(name), Id=id}) end
        end
    end
end)

pcall(function()
    local res = game:HttpGet("https://raw.githubusercontent.com/Joystickplays/AFEM/main/emotes.json")
    local data = HttpService:JSONDecode(res)
    if type(data) == "table" then
        for _, v in ipairs(data) do
            local name = v.name or v.Name
            local id = tonumber(v.id or v.Id)
            if name and id then table.insert(FullEmoteList, {Title=tostring(name), Id=id}) end
        end
    end
end)

do
    local seen = {} local deduped = {}
    for _, v in ipairs(FullEmoteList) do
        if not seen[v.Title] then seen[v.Title]=true table.insert(deduped,v) end
    end
    FullEmoteList = deduped
    table.sort(FullEmoteList, function(a,b) return a.Title:lower()<b.Title:lower() end)
end

local function filterList(query, list)
    if not query or query == "" then return list end
    local r = {} local q = query:lower()
    for _, v in ipairs(list) do
        local title = type(v)=="string" and v or v.Title
        if title:lower():find(q,1,true) then table.insert(r,v) end
    end
    return r
end

-- ===================== SHIFT LOCK + SPEED =====================
local isSpeedOn = false
local isShiftLockOn = false
local NORMAL_SPEED = 16
local BOOST_SPEED = 30
local trails = {}

local function createTrail(part)
    if not part then return end
    local a1=Instance.new("Attachment") a1.Position=Vector3.new(0,-0.6,0) a1.Parent=part
    local a2=Instance.new("Attachment") a2.Position=Vector3.new(0,-0.6,0) a2.Parent=part
    local t=Instance.new("Trail")
    t.Attachment0=a1 t.Attachment1=a2 t.FaceCamera=true t.LightEmission=1
    t.Lifetime=0.35 t.Transparency=NumberSequence.new(0)
    t.WidthScale=NumberSequence.new(1.2) t.MinLength=0.1 t.Parent=part
    return t
end

local function findHands()
    local chr=getChar() if not chr then return end
    if chr:FindFirstChild("LeftHand") then
        return chr:FindFirstChild("LeftHand"), chr:FindFirstChild("RightHand")
    else
        return chr:FindFirstChild("Left Arm"), chr:FindFirstChild("Right Arm")
    end
end

local function enableTrails()
    for _,t in pairs(trails) do if t then t:Destroy() end end trails={}
    local l,r=findHands()
    if l then trails.left=createTrail(l) end
    if r then trails.right=createTrail(r) end
end

local function disableTrails()
    for _,t in pairs(trails) do if t then t:Destroy() end end trails={}
end

local speedBtn, shiftBtn

local function setSpeed(state)
    isSpeedOn = state
    local hum = getHum() if not hum then return end
    if isSpeedOn then
        hum.WalkSpeed = BOOST_SPEED enableTrails()
        speedBtn.Text = "Speed ON"
        speedBtn.BackgroundColor3 = Color3.fromRGB(0,200,80)
    else
        hum.WalkSpeed = NORMAL_SPEED disableTrails()
        speedBtn.Text = "Speed OFF"
        speedBtn.BackgroundColor3 = Color3.fromRGB(60,60,60)
    end
end

local function setShiftLock(state)
    isShiftLockOn = state
    local hum = getHum() if not hum then return end
    if isShiftLockOn then
        UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter
        UserInputService.MouseIconEnabled = false
        hum.AutoRotate = false
        shiftBtn.Text = "ShiftLock ON"
        shiftBtn.BackgroundColor3 = Color3.fromRGB(0,140,220)
    else
        UserInputService.MouseBehavior = Enum.MouseBehavior.Default
        UserInputService.MouseIconEnabled = true
        hum.AutoRotate = true
        shiftBtn.Text = "ShiftLock OFF"
        shiftBtn.BackgroundColor3 = Color3.fromRGB(60,60,60)
    end
end

RunService.RenderStepped:Connect(function()
    if isShiftLockOn then
        local hum=getHum()
        if hum and hum.RootPart then
            local root=hum.RootPart
            local look=camera.CFrame.LookVector
            root.CFrame=CFrame.new(root.Position, root.Position+Vector3.new(look.X,0,look.Z))
        end
    end
end)

UserInputService.InputBegan:Connect(function(input, processed)
    if processed then return end
    if input.KeyCode == Enum.KeyCode.LeftShift then setShiftLock(not isShiftLockOn) end
end)

LocalPlayer.CharacterAdded:Connect(function()
    task.wait(0.5)
    if isSpeedOn then setSpeed(true) end
    if isShiftLockOn then setShiftLock(true) end
end)

-- ===================== GUI =====================
local MainGui = Instance.new("ScreenGui")
MainGui.Name = "QuickEmotesUI"
MainGui.ResetOnSpawn = false
MainGui.IgnoreGuiInset = true

local ok2 = pcall(function() MainGui.Parent = CoreGui end)
if not ok2 then MainGui.Parent = LocalPlayer:WaitForChild("PlayerGui") end

-- Speed button (top right)
speedBtn = Instance.new("TextButton", MainGui)
speedBtn.Size = UDim2.new(0,80,0,28)
speedBtn.Position = UDim2.new(1,-90,0.45,-15)
speedBtn.BackgroundColor3 = Color3.fromRGB(60,60,60)
speedBtn.TextColor3 = Color3.new(1,1,1)
speedBtn.Font = Enum.Font.GothamBold speedBtn.TextSize = 12
speedBtn.Text = "Speed OFF" speedBtn.BorderSizePixel = 0 speedBtn.ZIndex = 10
Instance.new("UICorner",speedBtn).CornerRadius = UDim.new(0,8)
speedBtn.MouseButton1Click:Connect(function() setSpeed(not isSpeedOn) end)

-- ShiftLock button (top right, above speed)
shiftBtn = Instance.new("TextButton", MainGui)
shiftBtn.Size = UDim2.new(0,80,0,28)
shiftBtn.Position = UDim2.new(1,-90,0.45,-48)
shiftBtn.BackgroundColor3 = Color3.fromRGB(60,60,60)
shiftBtn.TextColor3 = Color3.new(1,1,1)
shiftBtn.Font = Enum.Font.GothamBold shiftBtn.TextSize = 12
shiftBtn.Text = "ShiftLock OFF" shiftBtn.BorderSizePixel = 0 shiftBtn.ZIndex = 10
Instance.new("UICorner",shiftBtn).CornerRadius = UDim.new(0,8)
shiftBtn.MouseButton1Click:Connect(function() setShiftLock(not isShiftLockOn) end)

-- Toggle Button (FIXED bottom left, no drag)
local ToggleBtn = Instance.new("TextButton", MainGui)
ToggleBtn.Size = UDim2.new(0,38,0,38)
ToggleBtn.Position = UDim2.new(0,12,1,-60)
ToggleBtn.AnchorPoint = Vector2.new(0,0)
ToggleBtn.BackgroundColor3 = Color3.fromRGB(45,45,55)
ToggleBtn.Text = "" ToggleBtn.AutoButtonColor = false
ToggleBtn.BorderSizePixel = 0 ToggleBtn.ZIndex = 50
Instance.new("UICorner",ToggleBtn).CornerRadius = UDim.new(1,0)

local TIcon = Instance.new("ImageLabel", ToggleBtn)
TIcon.Size = UDim2.new(0.6,0,0.6,0) TIcon.Position = UDim2.new(0.2,0,0.2,0)
TIcon.BackgroundTransparency = 1 TIcon.Image = "rbxassetid://6034509993"
TIcon.ImageColor3 = Color3.fromRGB(255,255,255) TIcon.ZIndex = 51

-- Panel
local Panel = Instance.new("Frame", MainGui)
Panel.Name = "Panel"
Panel.Size = UDim2.new(0,160,0,160)
Panel.Position = UDim2.new(0,12,1,-228)
Panel.BackgroundColor3 = Color3.fromRGB(30,30,38)
Panel.BorderSizePixel = 0 Panel.Visible = false Panel.ZIndex = 50
Instance.new("UICorner",Panel).CornerRadius = UDim.new(0,12)
local Stroke = Instance.new("UIStroke",Panel)
Stroke.Color = Color3.fromRGB(70,70,85) Stroke.Thickness = 1

-- Search
local SearchBox = Instance.new("TextBox", Panel)
SearchBox.Size = UDim2.new(1,-10,0,20) SearchBox.Position = UDim2.new(0,5,0,5)
SearchBox.BackgroundColor3 = Color3.fromRGB(45,45,55)
SearchBox.TextColor3 = Color3.fromRGB(255,255,255)
SearchBox.PlaceholderText = "Search..." SearchBox.PlaceholderColor3 = Color3.fromRGB(150,150,160)
SearchBox.Text = "" SearchBox.ClearTextOnFocus = false
SearchBox.Font = Enum.Font.Gotham SearchBox.TextSize = 12
SearchBox.BorderSizePixel = 0 SearchBox.ZIndex = 51
Instance.new("UICorner",SearchBox).CornerRadius = UDim.new(0,8)

-- 4 Tab Buttons
local TabBar = Instance.new("Frame", Panel)
TabBar.Size = UDim2.new(1,-10,0,18) TabBar.Position = UDim2.new(0,5,0,29)
TabBar.BackgroundTransparency = 1 TabBar.ZIndex = 51

local TABS = {"Anim","Emote","VD","R6"}
local TAB_ON  = Color3.fromRGB(80,60,200)
local TAB_OFF = Color3.fromRGB(45,45,55)
local tabBtns = {}

for i, name in ipairs(TABS) do
    local w = 1/#TABS
    local btn = Instance.new("TextButton", TabBar)
    btn.Size = UDim2.new(w,-3,1,0)
    btn.Position = UDim2.new((i-1)*w, i==1 and 0 or 2, 0, 0)
    btn.BackgroundColor3 = i==1 and TAB_ON or TAB_OFF
    btn.Text = name btn.TextColor3 = Color3.fromRGB(255,255,255)
    btn.Font = Enum.Font.GothamBold btn.TextSize = 10
    btn.AutoButtonColor = false btn.BorderSizePixel = 0 btn.ZIndex = 52
    Instance.new("UICorner",btn).CornerRadius = UDim.new(0,6)
    tabBtns[i] = btn
end

-- List
local ListFrame = Instance.new("ScrollingFrame", Panel)
ListFrame.Size = UDim2.new(1,-10,0,56) ListFrame.Position = UDim2.new(0,5,0,51)
ListFrame.BackgroundColor3 = Color3.fromRGB(24,24,30)
ListFrame.BorderSizePixel = 0 ListFrame.ScrollBarThickness = 4
ListFrame.CanvasSize = UDim2.new(0,0,0,0)
ListFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y ListFrame.ZIndex = 51
Instance.new("UICorner",ListFrame).CornerRadius = UDim.new(0,8)
local ListLayout = Instance.new("UIListLayout", ListFrame)
ListLayout.Padding = UDim.new(0,4) ListLayout.SortOrder = Enum.SortOrder.LayoutOrder

-- Page controls
local PageFrame = Instance.new("Frame", Panel)
PageFrame.Size = UDim2.new(1,-10,0,18) PageFrame.Position = UDim2.new(0,5,1,-50)
PageFrame.BackgroundTransparency = 1 PageFrame.ZIndex = 51

local PrevBtn = Instance.new("TextButton", PageFrame)
PrevBtn.Size = UDim2.new(0.32,0,1,0) PrevBtn.BackgroundColor3 = Color3.fromRGB(45,45,55)
PrevBtn.Text = "< Prev" PrevBtn.TextColor3 = Color3.fromRGB(255,255,255)
PrevBtn.Font = Enum.Font.Gotham PrevBtn.TextSize = 11
PrevBtn.AutoButtonColor = false PrevBtn.BorderSizePixel = 0 PrevBtn.ZIndex = 51
Instance.new("UICorner",PrevBtn).CornerRadius = UDim.new(0,8)

local PageLabel = Instance.new("TextLabel", PageFrame)
PageLabel.Size = UDim2.new(0.36,0,1,0) PageLabel.Position = UDim2.new(0.32,0,0,0)
PageLabel.BackgroundTransparency = 1 PageLabel.Text = "1 / 1"
PageLabel.TextColor3 = Color3.fromRGB(200,200,210) PageLabel.Font = Enum.Font.Gotham
PageLabel.TextSize = 11 PageLabel.ZIndex = 51

local NextBtn = Instance.new("TextButton", PageFrame)
NextBtn.Size = UDim2.new(0.32,0,1,0) NextBtn.Position = UDim2.new(0.68,0,0,0)
NextBtn.BackgroundColor3 = Color3.fromRGB(45,45,55)
NextBtn.Text = "Next >" NextBtn.TextColor3 = Color3.fromRGB(255,255,255)
NextBtn.Font = Enum.Font.Gotham NextBtn.TextSize = 11
NextBtn.AutoButtonColor = false NextBtn.BorderSizePixel = 0 NextBtn.ZIndex = 51
Instance.new("UICorner",NextBtn).CornerRadius = UDim.new(0,8)

-- Stop buttons
local StopAnimBtn = Instance.new("TextButton", Panel)
StopAnimBtn.Size = UDim2.new(0.5,-7,0,20) StopAnimBtn.Position = UDim2.new(0,5,1,-24)
StopAnimBtn.BackgroundColor3 = Color3.fromRGB(180,40,40)
StopAnimBtn.Text = "Stop Anim" StopAnimBtn.TextColor3 = Color3.fromRGB(255,255,255)
StopAnimBtn.Font = Enum.Font.GothamBold StopAnimBtn.TextSize = 11
StopAnimBtn.AutoButtonColor = false StopAnimBtn.BorderSizePixel = 0 StopAnimBtn.ZIndex = 51
Instance.new("UICorner",StopAnimBtn).CornerRadius = UDim.new(0,8)

local StopEmoteBtn = Instance.new("TextButton", Panel)
StopEmoteBtn.Size = UDim2.new(0.5,-7,0,20) StopEmoteBtn.Position = UDim2.new(0.5,2,1,-24)
StopEmoteBtn.BackgroundColor3 = Color3.fromRGB(180,40,40)
StopEmoteBtn.Text = "Stop Emote" StopEmoteBtn.TextColor3 = Color3.fromRGB(255,255,255)
StopEmoteBtn.Font = Enum.Font.GothamBold StopEmoteBtn.TextSize = 11
StopEmoteBtn.AutoButtonColor = false StopEmoteBtn.BorderSizePixel = 0 StopEmoteBtn.ZIndex = 51
Instance.new("UICorner",StopEmoteBtn).CornerRadius = UDim.new(0,8)

-- ===================== TAB LOGIC =====================
local qeMode = "Anim"
local qePage  = 1
local qeSearchQuery = ""

local qeAnimResults  = { unpack(animNameList) }
local qeEmoteResults = FullEmoteList
local qeVDResults    = VDEmoteList
local qeR6Results    = R6EmoteList

local function getCurrentList()
    if qeMode=="Anim"  then return qeAnimResults  end
    if qeMode=="Emote" then return qeEmoteResults end
    if qeMode=="VD"    then return qeVDResults    end
    if qeMode=="R6"    then return qeR6Results    end
    return {}
end

local function totalPages(list) return math.max(1, math.ceil(#list/QUICK_EMOTE_PER_PAGE)) end

local function pageItems(list, pg)
    local items={}
    local s=(pg-1)*QUICK_EMOTE_PER_PAGE+1
    local e=math.min(pg*QUICK_EMOTE_PER_PAGE,#list)
    for i=s,e do table.insert(items,list[i]) end
    return items
end

local function clearList()
    for _, c in ipairs(ListFrame:GetChildren()) do
        if c:IsA("TextButton") then c:Destroy() end
    end
end

local function refreshList()
    clearList()
    local list = getCurrentList()
    local tp = totalPages(list)
    qePage = math.clamp(qePage, 1, tp)
    PageLabel.Text = qePage.." / "..tp
    local items = pageItems(list, qePage)
    for i, item in ipairs(items) do
        local isStr = type(item)=="string"
        local title = isStr and item or item.Title
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(1,-8,0,24)
        btn.BackgroundColor3 = Color3.fromRGB(40,40,50)
        btn.Text = title btn.TextColor3 = Color3.fromRGB(255,255,255)
        btn.Font = Enum.Font.Gotham btn.TextSize = 11
        btn.AutoButtonColor = false btn.BorderSizePixel = 0
        btn.ZIndex = 52 btn.LayoutOrder = i
        btn.TextXAlignment = Enum.TextXAlignment.Left
        local pad = Instance.new("UIPadding",btn)
        pad.PaddingLeft = UDim.new(0,6)
        Instance.new("UICorner",btn).CornerRadius = UDim.new(0,6)
        btn.Parent = ListFrame
        btn.MouseButton1Click:Connect(function()
            if qeMode=="Anim" then
                local data = getAnimData(title)
                if data then applyAnimation(data) end
            else
                playEmote(item, emoteLoopEnabled)
            end
        end)
    end
end

local function applySearch()
    local q = qeSearchQuery
    if qeMode=="Anim" then
        qeAnimResults = q=="" and {unpack(animNameList)} or filterList(q, animNameList)
    elseif qeMode=="Emote" then
        qeEmoteResults = filterList(q, FullEmoteList)
    elseif qeMode=="VD" then
        qeVDResults = filterList(q, VDEmoteList)
    elseif qeMode=="R6" then
        qeR6Results = filterList(q, R6EmoteList)
    end
end

local function setMode(mode)
    qeMode = mode qePage = 1
    for i, name in ipairs(TABS) do
        tabBtns[i].BackgroundColor3 = name==mode and TAB_ON or TAB_OFF
    end
    applySearch()
    refreshList()
end

for i, name in ipairs(TABS) do
    tabBtns[i].MouseButton1Click:Connect(function() setMode(name) end)
end

PrevBtn.MouseButton1Click:Connect(function()
    if qePage<=1 then return end qePage=qePage-1 refreshList()
end)
NextBtn.MouseButton1Click:Connect(function()
    local list=getCurrentList() if qePage>=totalPages(list) then return end qePage=qePage+1 refreshList()
end)

StopAnimBtn.MouseButton1Click:Connect(function() resetAnimation() end)
StopEmoteBtn.MouseButton1Click:Connect(function() stopEmote() end)

SearchBox:GetPropertyChangedSignal("Text"):Connect(function()
    qeSearchQuery = SearchBox.Text
    qePage = 1 applySearch() refreshList()
end)

-- Toggle Panel (fixed button, tap only)
ToggleBtn.MouseButton1Click:Connect(function()
    Panel.Visible = not Panel.Visible
    if Panel.Visible then refreshList() end
end)

refreshList()
