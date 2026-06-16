-- PieHub V2 Troll Script by Dylphiiee
-- With Transparent Collision Objects & Auto Cleanup

local WindUI = loadstring(game:HttpGet("https://github.com/Footagesus/WindUI/releases/latest/download/main.lua"))()

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Debris = game:GetService("Debris")
local LocalPlayer = Players.LocalPlayer

local function getChar() return LocalPlayer.Character end
local function getHum()
    local c = getChar()
    return c and c:FindFirstChildWhichIsA("Humanoid")
end
local function getHRP()
    local c = getChar()
    return c and c:FindFirstChild("HumanoidRootPart")
end

local function isAlive(player)
    return player and player.Character 
        and player.Character:FindFirstChild("Humanoid") 
        and player.Character.Humanoid.Health > 0
        and player.Character:FindFirstChild("HumanoidRootPart")
end

local function getPlayerHRP(player)
    return player.Character and player.Character:FindFirstChild("HumanoidRootPart")
end

local targetPlayer = nil
local PunchPower = 50
local PunchTime = 30
local collisionFlingPower = 150

local punchActive = false
local saitamaActive = false
local kickActive = false
local punchTool = nil
local saitamaTool = nil
local kickTool = nil

local collisionObjects = {}
local cleanupConnection = nil

local function createCollisionObject(size, position, velocity, lifespan)
    local part = Instance.new("Part")
    part.Size = size or Vector3.new(3, 3, 3)
    part.Position = position or Vector3.new(0, 10, 0)
    part.Anchored = false
    part.CanCollide = true
    part.BrickColor = BrickColor.new("Bright red")
    part.Material = Enum.Material.Neon
    part.Transparency = 1
    part.Parent = workspace
    
    if velocity then
        part.Velocity = velocity
    end
    
    if lifespan then
        Debris:AddItem(part, lifespan)
    end
    
    table.insert(collisionObjects, part)
    
    part.Touched:Connect(function(hit)
        local hitParent = hit.Parent
        if not hitParent then return end
        
        local humanoid = hitParent:FindFirstChildWhichIsA("Humanoid")
        if not humanoid then return end
        
        local player = Players:GetPlayerFromCharacter(hitParent)
        if not player or player == LocalPlayer then return end
        
        if targetPlayer and player == targetPlayer then
            local hrp = hitParent:FindFirstChild("HumanoidRootPart")
            if hrp then
                local direction = (hrp.Position - part.Position).Unit
                local power = collisionFlingPower
                
                hrp.Velocity = direction * power + Vector3.new(0, power * 0.5, 0)
                hrp.AssemblyLinearVelocity = direction * power + Vector3.new(0, power * 0.5, 0)
                hrp.AssemblyAngularVelocity = Vector3.new(
                    math.random(-10, 10),
                    math.random(-10, 10),
                    math.random(-10, 10)
                )
                
                WindUI:Notify({
                    Title = "💥 HIT!", 
                    Content = "Fling " .. player.DisplayName,
                    Duration = 1,
                    Icon = "zap"
                })
            end
        end
    end)
    
    return part
end

local function cleanupCollisionObjects()
    local count = 0
    for i = #collisionObjects, 1, -1 do
        local obj = collisionObjects[i]
        if obj and obj.Parent then
            pcall(function() obj:Destroy() end)
            count = count + 1
        end
        collisionObjects[i] = nil
    end
    collisionObjects = {}
    
    if count > 0 then
        WindUI:Notify({
            Title = "🧹 Cleanup",
            Content = "Removed " .. count .. " collision objects",
            Duration = 1.5,
            Icon = "broom"
        })
    end
end

task.spawn(function()
    while true do
        task.wait(10)
        cleanupCollisionObjects()
    end
end)

local noCollisionActive = false
local noCollisionConnection = nil
local noCollisionObjects = {}

local function toggleNoCollisionFling()
    if not targetPlayer or not isAlive(targetPlayer) then
        WindUI:Notify({ Title = "Error", Content = "Select target first!", Duration = 2, Icon = "alert-circle" })
        return
    end
    
    noCollisionActive = not noCollisionActive
    
    if noCollisionActive then
        WindUI:Notify({
            Title = "🔄 No Collision Fling ACTIVE",
            Content = "Flinging " .. targetPlayer.DisplayName,
            Duration = 2,
            Icon = "zap"
        })
        
        noCollisionConnection = RunService.Heartbeat:Connect(function()
            if not noCollisionActive or not targetPlayer or not isAlive(targetPlayer) then
                noCollisionActive = false
                if noCollisionConnection then 
                    noCollisionConnection:Disconnect() 
                    noCollisionConnection = nil 
                end
                return
            end
            
            local targetHRP = getPlayerHRP(targetPlayer)
            if not targetHRP then return end
            
            for i = 1, 5 do
                local angle = math.random() * math.pi * 2
                local radius = math.random(2, 6)
                local pos = targetHRP.Position + Vector3.new(
                    math.cos(angle) * radius,
                    math.random(-2, 4),
                    math.sin(angle) * radius
                )
                
                local part = createCollisionObject(
                    Vector3.new(2, 2, 2),
                    pos,
                    Vector3.new(
                        math.random(-30, 30),
                        math.random(-10, 30),
                        math.random(-30, 30)
                    ),
                    3
                )
                table.insert(noCollisionObjects, part)
            end
            
            if #noCollisionObjects > 30 then
                for i = 1, 10 do
                    local old = table.remove(noCollisionObjects, 1)
                    if old and old.Parent then
                        pcall(function() old:Destroy() end)
                    end
                end
            end
        end)
    else
        if noCollisionConnection then 
            noCollisionConnection:Disconnect() 
            noCollisionConnection = nil 
        end
        for _, obj in pairs(noCollisionObjects) do
            pcall(function() obj:Destroy() end)
        end
        noCollisionObjects = {}
        WindUI:Notify({
            Title = "⏹️ No Collision Fling OFF",
            Content = "Stopped flinging",
            Duration = 2,
            Icon = "square"
        })
    end
end

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

local function doNaNFling(targetPart)
    local char = getChar()
    local hrp = getHRP()
    local hum = getHum()
    if not char or not hrp or not hum then return end
    if not targetPart or not targetPart.Parent then return end
    
    local function charFromPart(part)
        local m = part and part.Parent
        if not m then return nil end
        if m:IsA("Accessory") then m = m.Parent end
        if m and m:FindFirstChildWhichIsA("Humanoid") then return m end
    end
    
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

local function createFlingTool(toolName, animId, limbGetFn, r6AnimId, r15AnimId, powerMult)
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

local function createPunchFling()
    removePunchTool()
    punchTool = createFlingTool("PiePunch", nil, getRightArm, 28156406, 10717116749, 1)
end

local function createKickFling()
    removeKickTool()
    kickTool = createFlingTool("PieKick", 133566007754001, getLeftLeg, nil, nil, 1.5)
end

WindUI:SetNotificationLower(true)

local Window = WindUI:CreateWindow({
    Title = "PieHub Troll",
    Icon = "skull",
    Author = "by Dylphiiee",
    Folder = "PieHub_Troll",
    Size = UDim2.fromOffset(500, 550),
    ToggleKey = Enum.KeyCode.RightShift,
    Theme = "Dark",
    Resizable = false,
})

WindUI:Notify({
    Title = "PieHub Troll",
    Content = "Loaded! Transparent Collision Ready!",
    Duration = 3,
    Icon = "skull"
})

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

local TabMain = Window:Tab({ Title = "Troll", Icon: "skull" })

local SectionTarget = TabMain:Section({ Title = "🎯 Target", Icon = "target", Opened = true })

local targetDropdown = SectionTarget:Dropdown({
    Title = "Choose Player",
    Desc = "Select a player as your target",
    Values = getPlayerDisplayNames(),
    Value = "",
    SearchBarEnabled = true,
    Callback = function(value)
        targetPlayer = playerListMap[value] or nil
    end
})

SectionTarget:Button({
    Title = "Refresh",
    Desc = "Update the player list",
    Icon = "refresh-cw",
    Callback = function()
        targetDropdown:Refresh(getPlayerDisplayNames())
    end
})

local targetDisplay = SectionTarget:Paragraph({
    Title = "Current Target",
    Desc = "No target selected yet",
    Icon = "circle-off",
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

local FlingSection = TabMain:Section({ Title = "👊 FLING", Icon = "hand", Opened = true })

FlingSection:Toggle({
    Title = "PUNCH FLING",
    Desc = "Equip punch tool, click player to fling them",
    Icon = "hand",
    Value = false,
    Callback = function(state)
        punchActive = state
        if state then
            createPunchFling()
            WindUI:Notify({
                Title = "Punch Fling",
                Content = "Tool equipped! Click players to fling!",
                Duration = 2,
                Icon = "hand"
            })
        else
            removePunchTool()
        end
    end
})

FlingSection:Toggle({
    Title = "DROP KICK FLING",
    Desc = "Equip dropkick tool, click player to fling them",
    Icon = "footprints",
    Value = false,
    Callback = function(state)
        kickActive = state
        if state then
            createKickFling()
            WindUI:Notify({
                Title = "Drop Kick Fling",
                Content = "Tool equipped! Click players to fling!",
                Duration = 2,
                Icon = "footprints"
            })
        else
            removeKickTool()
        end
    end
})

FlingSection:Divider()

FlingSection:Toggle({
    Title = "🔄 NO COLLISION FLING",
    Desc = "Spawn invisible collision objects around target (toggle)",
    Icon = "zap",
    Value = false,
    Callback = function(state)
        toggleNoCollisionFling()
    end
})

FlingSection:Divider()

FlingSection:Slider({
    Title = "Tool Fling Power",
    Desc = "How strong the tool fling is | Default: 50",
    Icon = "zap",
    Step = 5,
    Value = { Min = 1, Max = 500, Default = 50 },
    IsTooltip = true,
    IsTextbox = true,
    Callback = function(v) 
        PunchPower = v 
    end
})

FlingSection:Slider({
    Title = "Tool Fling Time",
    Desc = "How long the fling lasts | Default: 30",
    Icon = "timer",
    Step = 5,
    Value = { Min = 1, Max = 120, Default = 30 },
    IsTooltip = true,
    IsTextbox = true,
    Callback = function(v) 
        PunchTime = v 
    end
})

FlingSection:Slider({
    Title = "No Collision Fling Power",
    Desc = "How strong the no collision fling is | Default: 150",
    Icon = "zap",
    Step = 10,
    Value = { Min = 50, Max = 500, Default = 150 },
    IsTooltip = true,
    IsTextbox = true,
    Callback = function(v) 
        collisionFlingPower = v 
    end
})

FlingSection:Divider()

FlingSection:Button({
    Title = "🧹 Cleanup Objects",
    Desc = "Remove all invisible collision objects",
    Icon = "broom",
    Callback = function()
        cleanupCollisionObjects()
        for _, obj in pairs(noCollisionObjects) do
            pcall(function() obj:Destroy() end)
        end
        noCollisionObjects = {}
    end
})

LocalPlayer.CharacterAdded:Connect(function(char)
    task.wait(0.5)
    
    if punchActive then 
        task.wait(0.3)
        createPunchFling() 
    end
    if kickActive then 
        task.wait(0.3)
        createKickFling() 
    end
    
    if noCollisionActive then
        noCollisionActive = false
        if noCollisionConnection then 
            noCollisionConnection:Disconnect() 
            noCollisionConnection = nil 
        end
        task.wait(0.5)
        toggleNoCollisionFling()
    end
end)

task.defer(function()
    TabMain:Select()
end)
