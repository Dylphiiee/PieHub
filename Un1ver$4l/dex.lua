-- ============================================================
-- Piehub Explorer v1.0.0
-- Made by Dylphiiee
-- ============================================================

local WindUI = loadstring(game:HttpGet("https://github.com/Footagesus/WindUI/releases/latest/download/main.lua"))()

WindUI:SetNotificationLower(true)

-- ============================================================
-- SERVICES
-- ============================================================
local Players           = game:GetService("Players")
local RunService        = game:GetService("RunService")
local UserInputService  = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Lighting          = game:GetService("Lighting")
local SoundService      = game:GetService("SoundService")
local LocalPlayer       = Players.LocalPlayer
local PlayerGui         = LocalPlayer:WaitForChild("PlayerGui")
local Camera            = workspace.CurrentCamera

-- ============================================================
-- WINDOW
-- ============================================================
local Window = WindUI:CreateWindow({
    Title      = "Piehub Explorer",
    Icon       = "cookie",
    Author     = "by Dylphiiee",
    Folder     = "PieHub",
    Size       = UDim2.fromOffset(580, 460),
    ToggleKey  = Enum.KeyCode.RightControl,
    Theme      = "Dark",
    Resizable  = false,
})

Window:EditOpenButton({
    Title           = "",
    Icon            = "cookie",
    CornerRadius    = UDim.new(1, 0),
    StrokeThickness = 1,
    OnlyMobile      = false,
    Enabled         = true,
    Draggable       = true,
})

WindUI:Notify({
    Title   = "PieHub v1.0.0",
    Content = "Event Recorder siap! RightCtrl untuk toggle.",
    Duration = 4,
    Icon    = "activity",
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
-- STATE
-- ============================================================
local Recording      = false
local Connections    = {}
local EventLog       = {}
local EventCount     = 0
local MaxLogs        = 300
local SessionStart   = 0

local TrackedLabels  = {}
local TrackedSounds  = {}
local TrackedRemotes = {}
local PrevLabelTexts = {}

local Filter = {
    GUI_TEXT     = true,
    GUI_VISIBLE  = true,
    PLAYER       = true,
    INPUT        = true,
    CHAT         = true,
    REMOTE       = true,
    SOUND        = true,
    WORKSPACE    = true,
    LIGHTING     = true,
    LEADERSTATS  = true,
    PROXIMITY    = true,
    SYSTEM       = true,
}

-- ============================================================
-- HELPERS
-- ============================================================
local function ts()
    return os.date("%H:%M:%S")
end

local function elapsed()
    if SessionStart == 0 then return "00:00" end
    local s = math.floor(tick() - SessionStart)
    return string.format("%02d:%02d", math.floor(s/60), s%60)
end

local liveLogElement = nil

local function log(cat, msg, notify, notifyTime)
    if not Recording then return end
    if Filter[cat] == false then return end
    EventCount += 1
    local entry = string.format("[%s | %s] [%-12s] %s", ts(), elapsed(), cat, msg)
    table.insert(EventLog, entry)
    if #EventLog > MaxLogs then table.remove(EventLog, 1) end
    if liveLogElement then
        pcall(function()
            liveLogElement:SetCode(table.concat(EventLog, "\n"))
        end)
    end
    if notify then
        WindUI:Notify({ Title = cat, Content = msg, Duration = notifyTime or 2, Icon = "bell" })
    end
end

local function clearConns()
    for _, c in pairs(Connections) do
        pcall(function()
            if typeof(c) == "RBXScriptConnection" then c:Disconnect() end
        end)
    end
    Connections      = {}
    TrackedLabels    = {}
    TrackedSounds    = {}
    TrackedRemotes   = {}
    PrevLabelTexts   = {}
end

local function conn(signal, fn)
    local ok, c = pcall(function() return signal:Connect(fn) end)
    if ok and c then table.insert(Connections, c) end
end

-- ============================================================
-- TAB: RECORDER
-- ============================================================
local TabRec = Window:Tab({ Title = "Recorder", Icon = "activity" })

TabRec:Paragraph({
    Title = "Universal Event Recorder",
    Desc  = "Rekam semua event yang terjadi di game secara realtime. Aktifkan toggle untuk mulai.",
})

TabRec:Divider()

liveLogElement = TabRec:Code({
    Title = "Live Event Feed",
    Code  = "-- Aktifkan [Start Recording] untuk mulai merekam...",
})

TabRec:Divider()

local function startAllHooks()

    -- [1] GUI TEXT
    local function hookLabel(lbl)
        if TrackedLabels[lbl] then return end
        TrackedLabels[lbl] = true
        PrevLabelTexts[lbl] = lbl.Text or ""
        conn(lbl:GetPropertyChangedSignal("Text"), function()
            local new = lbl.Text or ""
            local old = PrevLabelTexts[lbl] or ""
            if new == old or new == "" then return end
            PrevLabelTexts[lbl] = new
            local ctx = lbl.Parent and (" [" .. lbl.Parent.Name .. "." .. lbl.Name .. "]") or ""
            log("GUI_TEXT", string.format("Text berubah%s: \"%s\"", ctx, new))
        end)
    end
    for _, obj in ipairs(PlayerGui:GetDescendants()) do
        if obj:IsA("TextLabel") or obj:IsA("TextBox") then hookLabel(obj) end
    end
    conn(PlayerGui.DescendantAdded, function(obj)
        task.wait(0.05)
        if obj:IsA("TextLabel") or obj:IsA("TextBox") then hookLabel(obj) end
    end)

    -- [2] GUI VISIBLE
    local TrackedFrames = {}
    local function hookFrame(f)
        if TrackedFrames[f] then return end
        TrackedFrames[f] = true
        conn(f:GetPropertyChangedSignal("Visible"), function()
            local state = f.Visible and "MUNCUL" or "HILANG"
            local path = f.Parent and (f.Parent.Name .. "/" .. f.Name) or f.Name
            log("GUI_VISIBLE", string.format("GUI [%s] -> %s", path, state))
        end)
    end
    for _, obj in ipairs(PlayerGui:GetDescendants()) do
        if obj:IsA("Frame") or obj:IsA("ScreenGui") or obj:IsA("ImageLabel") then hookFrame(obj) end
    end
    conn(PlayerGui.DescendantAdded, function(obj)
        task.wait(0.05)
        if obj:IsA("Frame") or obj:IsA("ScreenGui") or obj:IsA("ImageLabel") then hookFrame(obj) end
    end)

    -- [3] PLAYER EVENTS
    local function hookPlayer(plr)
        local function hookChar(char)
            local hum = char:FindFirstChildOfClass("Humanoid")
            if hum then
                conn(hum.Died, function()
                    local tag = plr == LocalPlayer and "KAMU" or plr.Name
                    log("PLAYER", tag .. " mati!", plr == LocalPlayer, 3)
                end)
                local prevHP = hum.Health
                conn(hum:GetPropertyChangedSignal("Health"), function()
                    local hp = hum.Health
                    local diff = hp - prevHP
                    if math.abs(diff) >= 10 then
                        local arrow = diff > 0 and "+" or "-"
                        local tag = plr == LocalPlayer and "KAMU" or plr.Name
                        log("PLAYER", string.format("%s HP %s%.0f (%.0f->%.0f)", tag, arrow, math.abs(diff), prevHP, hp))
                    end
                    prevHP = hp
                end)
            end
            log("PLAYER", plr.Name .. " spawn")
        end
        if plr.Character then hookChar(plr.Character) end
        conn(plr.CharacterAdded, hookChar)
    end
    conn(Players.PlayerAdded, function(plr)
        log("PLAYER", "+ " .. plr.Name .. " bergabung", true, 2)
        hookPlayer(plr)
    end)
    conn(Players.PlayerRemoving, function(plr)
        log("PLAYER", "- " .. plr.Name .. " keluar")
    end)
    for _, plr in ipairs(Players:GetPlayers()) do hookPlayer(plr) end

    -- [4] INPUT
    conn(UserInputService.InputBegan, function(input, gpe)
        if gpe then return end
        local t = input.UserInputType
        if t == Enum.UserInputType.MouseButton1 then
            log("INPUT", "Klik Kiri")
        elseif t == Enum.UserInputType.MouseButton2 then
            log("INPUT", "Klik Kanan")
        elseif t == Enum.UserInputType.Keyboard then
            local key = tostring(input.KeyCode):gsub("Enum.KeyCode.", "")
            local important = {"E","F","Q","R","G","Z","X","C","V","Space","Return","LeftShift","Tab","Escape","T","H","M"}
            for _, k in ipairs(important) do
                if key == k then log("INPUT", "Key: [" .. key .. "]") break end
            end
        end
    end)

    -- [5] CHAT
    pcall(function()
        local TCS = game:GetService("TextChatService")
        for _, ch in ipairs(TCS:GetDescendants()) do
            if ch:IsA("TextChannel") then
                conn(ch.MessageReceived, function(msg)
                    local sender = msg.TextSource and msg.TextSource.Name or "Server"
                    log("CHAT", sender .. ": " .. (msg.Text or ""))
                end)
            end
        end
    end)

    -- [6] REMOTE EVENTS
    local function hookRemote(remote)
        if TrackedRemotes[remote] then return end
        TrackedRemotes[remote] = true
        conn(remote.OnClientEvent, function(...)
            local args = {...}
            local argStr = ""
            for i, v in ipairs(args) do
                argStr = argStr .. tostring(v)
                if i < #args then argStr = argStr .. ", " end
            end
            log("REMOTE", string.format("[%s] <- Server: (%s)", remote.Name, argStr))
        end)
    end
    for _, obj in ipairs(ReplicatedStorage:GetDescendants()) do
        if obj:IsA("RemoteEvent") then hookRemote(obj) end
    end
    conn(ReplicatedStorage.DescendantAdded, function(obj)
        if obj:IsA("RemoteEvent") then hookRemote(obj) end
    end)

    -- [7] SOUND
    local function hookSound(sound)
        if TrackedSounds[sound] then return end
        TrackedSounds[sound] = true
        conn(sound.Played, function()
            log("SOUND", string.format("Play: \"%s\" ID:%s", sound.Name,
                tostring(sound.SoundId):gsub("rbxassetid://", "")))
        end)
        conn(sound.Stopped, function()
            log("SOUND", string.format("Stop: \"%s\"", sound.Name))
        end)
    end
    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("Sound") then hookSound(obj) end
    end
    for _, obj in ipairs(SoundService:GetDescendants()) do
        if obj:IsA("Sound") then hookSound(obj) end
    end
    conn(workspace.DescendantAdded, function(obj)
        if obj:IsA("Sound") then hookSound(obj) end
    end)

    -- [8] WORKSPACE MODEL
    conn(workspace.DescendantAdded, function(obj)
        if obj:IsA("Model") then
            log("WORKSPACE", "+ Model: \"" .. obj.Name .. "\"")
        end
    end)
    conn(workspace.DescendantRemoving, function(obj)
        if obj:IsA("Model") then
            log("WORKSPACE", "- Model dihapus: \"" .. obj.Name .. "\"")
        end
    end)

    -- [9] LIGHTING
    local prevTime = Lighting.ClockTime
    local prevFog  = Lighting.FogEnd
    conn(RunService.Heartbeat, (function()
        local lc = 0
        return function()
            if tick()-lc < 2 then return end lc = tick()
            local ct = Lighting.ClockTime
            if math.abs(ct-prevTime) >= 0.5 then
                local label = ct<6 and "Malam" or ct<12 and "Pagi" or ct<17 and "Siang" or "Sore"
                log("LIGHTING", string.format("Waktu: %.1f (%s)", ct, label))
                prevTime = ct
            end
            local fe = Lighting.FogEnd
            if math.abs(fe-prevFog) >= 100 then
                log("LIGHTING", string.format("Fog: %.0f -> %.0f", prevFog, fe))
                prevFog = fe
            end
        end
    end)())

    -- [10] LEADERSTATS
    local function hookLeaderstats(plr)
        local function scanStats(ls)
            for _, stat in ipairs(ls:GetChildren()) do
                if stat:IsA("IntValue") or stat:IsA("NumberValue") or stat:IsA("StringValue") then
                    local prevVal = stat.Value
                    conn(stat.Changed, function(newVal)
                        local tag = plr == LocalPlayer and "KAMU" or plr.Name
                        log("LEADERSTATS", string.format("%s | %s: %s -> %s", tag, stat.Name, tostring(prevVal), tostring(newVal)), plr==LocalPlayer, 2)
                        prevVal = newVal
                    end)
                end
            end
        end
        local ls = plr:FindFirstChild("leaderstats")
        if ls then scanStats(ls) else
            conn(plr.ChildAdded, function(child)
                if child.Name == "leaderstats" then task.wait(0.1) scanStats(child) end
            end)
        end
    end
    for _, plr in ipairs(Players:GetPlayers()) do hookLeaderstats(plr) end
    conn(Players.PlayerAdded, function(plr) task.wait(1) hookLeaderstats(plr) end)

    -- [11] PROXIMITY PROMPT
    local function hookProximity(pp)
        conn(pp.Triggered, function(plr)
            local who = plr and plr.Name or "?"
            local action = pp.ActionText ~= "" and pp.ActionText or pp.Name
            log("PROXIMITY", string.format("[%s] oleh %s", action, who), plr==LocalPlayer, 2)
        end)
    end
    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("ProximityPrompt") then hookProximity(obj) end
    end
    conn(workspace.DescendantAdded, function(obj)
        if obj:IsA("ProximityPrompt") then hookProximity(obj) end
    end)

    -- [12] SNAPSHOT
    conn(RunService.Heartbeat, (function()
        local ls = 0
        return function()
            if tick()-ls < 15 then return end ls = tick()
            log("SYSTEM", string.format("Snapshot | Players:%d Events:%d Durasi:%s",
                #Players:GetPlayers(), EventCount, elapsed()))
        end
    end)())

    log("SYSTEM", string.format("Recording dimulai | Game: %s [%d]", game.Name, game.PlaceId))
end

TabRec:Toggle({
    Title    = "Start Recording",
    Desc     = "Mulai / hentikan perekaman event",
    Icon     = "circle",
    Value    = false,
    Callback = function(enabled)
        Recording = enabled
        if enabled then
            clearConns()
            EventLog     = {}
            EventCount   = 0
            SessionStart = tick()
            startAllHooks()
            WindUI:Notify({ Title = "Recording ON", Content = "Merekam event di: " .. game.Name, Duration = 3, Icon = "activity" })
        else
            clearConns()
            if liveLogElement then
                liveLogElement:SetCode(table.concat(EventLog, "\n"))
            end
            WindUI:Notify({ Title = "Recording OFF", Content = EventCount .. " events terekam.", Duration = 3, Icon = "activity" })
        end
    end
})

TabRec:Button({
    Title    = "Clear Log",
    Desc     = "Bersihkan semua log",
    Icon     = "trash",
    Callback = function()
        EventLog   = {}
        EventCount = 0
        if liveLogElement then liveLogElement:SetCode("-- Log dibersihkan.") end
        WindUI:Notify({ Title = "Cleared", Content = "Log dikosongkan.", Duration = 2, Icon = "trash" })
    end
})

TabRec:Button({
    Title    = "Export ke Output (F9)",
    Desc     = "Print semua log ke Roblox Output",
    Icon     = "terminal",
    Callback = function()
        if #EventLog == 0 then
            WindUI:Notify({ Title = "Export", Content = "Log kosong!", Duration = 2, Icon = "alert-circle" })
            return
        end
        print("========== PieHub v1.0.0 | by Dylphiiee ==========")
        print("Game: " .. game.Name .. " | PlaceId: " .. game.PlaceId)
        print("Events: " .. EventCount .. " | Durasi: " .. elapsed())
        print("===================================================")
        for _, v in ipairs(EventLog) do print(v) end
        print("==================== END ==========================")
        WindUI:Notify({ Title = "Exported!", Content = "Cek F9 Output.", Duration = 3, Icon = "terminal" })
    end
})

TabRec:Slider({
    Title    = "Max Log Entries",
    Desc     = "Batas maksimal log | Default: 300",
    Icon     = "list",
    Step     = 50,
    Value    = { Min = 100, Max = 1000, Default = 300 },
    IsTooltip = true,
    IsTextbox = true,
    Callback = function(v) MaxLogs = v end
})

-- ============================================================
-- TAB: FILTER
-- ============================================================
local TabFilter = Window:Tab({ Title = "Filter", Icon = "filter" })

TabFilter:Paragraph({
    Title = "Filter Kategori",
    Desc  = "Pilih kategori event yang ingin direkam.",
})

TabFilter:Divider()

local filterList = {
    { key = "GUI_TEXT",    label = "GUI Text Changes",     desc = "Perubahan teks di layar game" },
    { key = "GUI_VISIBLE", label = "GUI Show/Hide",        desc = "Frame atau GUI muncul/hilang" },
    { key = "PLAYER",      label = "Player Events",        desc = "Join, leave, spawn, mati, HP" },
    { key = "INPUT",       label = "Keyboard & Mouse",     desc = "Input dari pemain" },
    { key = "CHAT",        label = "Chat Messages",        desc = "Pesan chat semua player" },
    { key = "REMOTE",      label = "RemoteEvent",          desc = "Event dari server ke client" },
    { key = "SOUND",       label = "Sound Events",         desc = "Suara play/stop" },
    { key = "WORKSPACE",   label = "Workspace Changes",    desc = "Model/Part muncul/hilang" },
    { key = "LIGHTING",    label = "Lighting/Environment", desc = "Perubahan waktu, fog" },
    { key = "LEADERSTATS", label = "Leaderboard/Stats",    desc = "Skor, coins, level pemain" },
    { key = "PROXIMITY",   label = "ProximityPrompt",      desc = "Interaksi objek di map" },
    { key = "SYSTEM",      label = "System Snapshot",      desc = "Info periodik sistem" },
}

for _, f in ipairs(filterList) do
    TabFilter:Toggle({
        Title    = f.label,
        Desc     = f.desc,
        Value    = Filter[f.key],
        Callback = (function(k) return function(v) Filter[k] = v end end)(f.key)
    })
end

-- ============================================================
-- TAB: ANALYZER
-- ============================================================
local TabAna = Window:Tab({ Title = "Analyzer", Icon = "search" })

TabAna:Paragraph({
    Title = "Event Analyzer",
    Desc  = "Scan semua object di game sekali jalan. Pilih kategori lalu tekan Mulai Scan.",
})

TabAna:Divider()

local ScanFilter = {
    REMOTE      = true,
    SOUND       = true,
    ANIMATION   = true,
    PROXIMITY   = true,
    VALUES      = true,
    LEADERSTATS = true,
    GUI_LABELS  = true,
    SCRIPTS     = true,
}

local anaResultEl  = nil
local anaStatusEl  = nil
local ScanRunning  = false

TabAna:Toggle({ Title = "RemoteEvents",        Desc = "Scan semua RemoteEvent",       Value = true,  Callback = function(v) ScanFilter.REMOTE      = v end })
TabAna:Toggle({ Title = "Sounds",              Desc = "Scan semua suara di game",     Value = true,  Callback = function(v) ScanFilter.SOUND       = v end })
TabAna:Toggle({ Title = "Animations",          Desc = "Scan semua animasi",           Value = true,  Callback = function(v) ScanFilter.ANIMATION   = v end })
TabAna:Toggle({ Title = "ProximityPrompts",    Desc = "Scan interaksi objek",         Value = true,  Callback = function(v) ScanFilter.PROXIMITY   = v end })
TabAna:Toggle({ Title = "Values",              Desc = "Scan IntValue/StringValue dll",Value = true,  Callback = function(v) ScanFilter.VALUES      = v end })
TabAna:Toggle({ Title = "Leaderstats",         Desc = "Scan stats pemain",            Value = true,  Callback = function(v) ScanFilter.LEADERSTATS = v end })
TabAna:Toggle({ Title = "GUI Labels Penting",  Desc = "Scan label timer/score/round", Value = true,  Callback = function(v) ScanFilter.GUI_LABELS  = v end })
TabAna:Toggle({ Title = "Scripts Aktif",       Desc = "Scan script di Workspace/RS",  Value = true,  Callback = function(v) ScanFilter.SCRIPTS     = v end })

TabAna:Divider()

anaStatusEl = TabAna:Code({ Title = "Status Scan", Code = "-- Pilih kategori lalu tekan Mulai Scan." })
anaResultEl = TabAna:Code({ Title = "Hasil Scan",  Code = "-- Hasil akan muncul di sini..." })

local function runScan()
    if ScanRunning then return end
    ScanRunning = true

    local lines      = {}
    local totalFound = 0

    local function addLine(txt)
        lines[#lines+1] = txt
        pcall(function() anaResultEl:SetCode(table.concat(lines, "\n")) end)
        task.wait()
    end

    local function addSection(title)
        addLine("")
        addLine("-- ==================== " .. title .. " ====================")
    end

    local function addItem(label, detail)
        totalFound += 1
        addLine(string.format("  %-35s %s", label, detail or ""))
    end

    local function setStatus(msg)
        pcall(function() anaStatusEl:SetCode(msg) end)
        task.wait()
    end

    addLine("-- PieHub v1.0.0 | Hasil Scan | " .. os.date("%H:%M:%S"))
    addLine("-- Game: " .. game.Name .. " | PlaceId: " .. tostring(game.PlaceId))

    -- REMOTE EVENTS
    if ScanFilter.REMOTE then
        setStatus("Scanning RemoteEvents...")
        addSection("REMOTE EVENTS")
        local found = {}
        pcall(function()
            for _, obj in ipairs(ReplicatedStorage:GetDescendants()) do
                if obj:IsA("RemoteEvent") or obj:IsA("RemoteFunction") then
                    table.insert(found, { name = obj.Name, class = obj.ClassName })
                end
            end
        end)
        if #found == 0 then addLine("  (tidak ditemukan)")
        else for _, r in ipairs(found) do addItem(r.name, "[" .. r.class .. "]") end end
    end

    -- SOUNDS
    if ScanFilter.SOUND then
        setStatus("Scanning Sounds...")
        addSection("SOUNDS")
        local found = {}
        local function collectSounds(parent)
            for _, obj in ipairs(parent:GetDescendants()) do
                if obj:IsA("Sound") then
                    table.insert(found, {
                        name = obj.Name,
                        id   = tostring(obj.SoundId):gsub("rbxassetid://",""),
                        vol  = obj.Volume,
                        loop = obj.Looped,
                    })
                end
            end
        end
        pcall(function() collectSounds(workspace) end)
        pcall(function() collectSounds(SoundService) end)
        if #found == 0 then addLine("  (tidak ditemukan)")
        else
            for _, s in ipairs(found) do
                local flags = (s.loop and "[LOOP] " or "")
                addItem(s.name, string.format("ID:%s Vol:%.1f %s", s.id, s.vol, flags))
            end
        end
    end

    -- ANIMATIONS
    if ScanFilter.ANIMATION then
        setStatus("Scanning Animations...")
        addSection("ANIMATIONS")
        local found = {}
        local function collectAnims(parent)
            for _, obj in ipairs(parent:GetDescendants()) do
                if obj:IsA("Animation") then
                    table.insert(found, {
                        name = obj.Name,
                        id   = tostring(obj.AnimationId):gsub("rbxassetid://",""),
                    })
                end
            end
        end
        pcall(function() collectAnims(workspace) end)
        pcall(function() collectAnims(ReplicatedStorage) end)
        if #found == 0 then addLine("  (tidak ditemukan)")
        else for _, a in ipairs(found) do addItem(a.name, "ID:" .. a.id) end end
    end

    -- PROXIMITY
    if ScanFilter.PROXIMITY then
        setStatus("Scanning ProximityPrompts...")
        addSection("PROXIMITY PROMPTS")
        local found = {}
        for _, obj in ipairs(workspace:GetDescendants()) do
            if obj:IsA("ProximityPrompt") then
                table.insert(found, {
                    action = obj.ActionText ~= "" and obj.ActionText or "(no label)",
                    key    = tostring(obj.KeyboardKeyCode):gsub("Enum.KeyCode.",""),
                    parent = obj.Parent and obj.Parent.Name or "?",
                })
            end
        end
        if #found == 0 then addLine("  (tidak ditemukan)")
        else
            for _, p in ipairs(found) do
                addItem(p.action, string.format("Key:[%s] Parent:%s", p.key, p.parent))
            end
        end
    end

    -- VALUES
    if ScanFilter.VALUES then
        setStatus("Scanning Values...")
        addSection("VALUES")
        local found = {}
        local vTypes = { IntValue=true, NumberValue=true, StringValue=true, BoolValue=true }
        local function collectVals(parent)
            for _, obj in ipairs(parent:GetDescendants()) do
                if vTypes[obj.ClassName] then
                    table.insert(found, { name = obj.Name, class = obj.ClassName, value = tostring(obj.Value) })
                end
            end
        end
        pcall(function() collectVals(ReplicatedStorage) end)
        pcall(function() collectVals(workspace) end)
        if #found == 0 then addLine("  (tidak ditemukan)")
        else for _, v in ipairs(found) do addItem(v.name, "[" .. v.class .. "] = " .. v.value) end end
    end

    -- LEADERSTATS
    if ScanFilter.LEADERSTATS then
        setStatus("Scanning Leaderstats...")
        addSection("LEADERSTATS")
        local count = 0
        for _, plr in ipairs(Players:GetPlayers()) do
            local ls = plr:FindFirstChild("leaderstats")
            if ls then
                addLine("  -- " .. plr.Name)
                for _, stat in ipairs(ls:GetChildren()) do
                    addItem(stat.Name, "[" .. stat.ClassName .. "] = " .. tostring(stat.Value))
                    count += 1
                end
            end
        end
        if count == 0 then addLine("  (tidak ditemukan)") end
    end

    -- GUI LABELS
    if ScanFilter.GUI_LABELS then
        setStatus("Scanning GUI Labels...")
        addSection("GUI LABELS PENTING")
        local keywords = {"timer","score","round","health","hp","level","wave","kill","win","lose","time","coin","point"}
        local found = {}
        for _, obj in ipairs(PlayerGui:GetDescendants()) do
            if obj:IsA("TextLabel") and obj.Text ~= "" then
                local n = obj.Name:lower()
                local t = obj.Text:lower()
                for _, kw in ipairs(keywords) do
                    if string.find(n, kw) or string.find(t, kw) then
                        table.insert(found, { name = obj.Name, text = obj.Text })
                        break
                    end
                end
            end
        end
        if #found == 0 then addLine("  (tidak ditemukan)")
        else for _, g in ipairs(found) do addItem(g.name, "\"" .. g.text .. "\"") end end
    end

    -- SCRIPTS
    if ScanFilter.SCRIPTS then
        setStatus("Scanning Scripts...")
        addSection("SCRIPTS AKTIF")
        local found = {}
        local function collectScripts(parent)
            for _, obj in ipairs(parent:GetDescendants()) do
                if obj:IsA("Script") or obj:IsA("LocalScript") or obj:IsA("ModuleScript") then
                    table.insert(found, { name = obj.Name, class = obj.ClassName })
                end
            end
        end
        pcall(function() collectScripts(workspace) end)
        pcall(function() collectScripts(ReplicatedStorage) end)
        if #found == 0 then addLine("  (tidak ditemukan)")
        else for _, s in ipairs(found) do addItem(s.name, "[" .. s.class .. "]") end end
    end

    addLine("")
    addLine("-- ===================================================")
    addLine("-- Total item ditemukan: " .. totalFound)
    addLine("-- Scan selesai: " .. os.date("%H:%M:%S"))
    addLine("-- ===================================================")

    setStatus("-- Scan selesai! " .. totalFound .. " item ditemukan.")
    WindUI:Notify({ Title = "Scan Selesai", Content = totalFound .. " item ditemukan.", Duration = 4, Icon = "search" })
    ScanRunning = false
end

TabAna:Button({
    Title    = "Mulai Scan",
    Desc     = "Scan semua kategori yang dipilih",
    Icon     = "play",
    Callback = function()
        if ScanRunning then
            WindUI:Notify({ Title = "Scanning", Content = "Tunggu scan sebelumnya selesai.", Duration = 2, Icon = "loader" })
            return
        end
        WindUI:Notify({ Title = "Scan Dimulai", Content = "Scan berjalan...", Duration = 2, Icon = "search" })
        task.spawn(runScan)
    end
})

TabAna:Button({
    Title    = "Export ke Output (F9)",
    Desc     = "Print hasil scan ke Roblox Output",
    Icon     = "terminal",
    Callback = function()
        if ScanRunning then return end
        WindUI:Notify({ Title = "Export", Content = "Cek F9 Output.", Duration = 2, Icon = "terminal" })
        task.spawn(function()
            runScan()
            task.wait(0.5)
            local ok, code = pcall(function()
                return anaResultEl and anaResultEl.Code or ""
            end)
            print(ok and code or "-- Tidak ada hasil scan.")
        end)
    end
})

-- ============================================================
-- TAB: INFO
-- ============================================================
local TabInfo = Window:Tab({ Title = "Info", Icon = "info" })

TabInfo:Paragraph({
    Title = "Piehub Explorer",
    Desc  = "Version: 1.0.0 | Made by Dylphiiee\nUniversal game event recorder & analyzer.",
    Icon  = "activity",
})

TabInfo:Divider()

local function buildGameInfo()
    local plrList = Players:GetPlayers()
    local names = {}
    for _, p in ipairs(plrList) do table.insert(names, p.Name) end
    return string.format(
        "Game: %s\nPlaceId: %s\nPlayers: %d/%d\nFOV: %.0f\nTime: %.1f",
        game.Name, tostring(game.PlaceId),
        #plrList, Players.MaxPlayers,
        Camera.FieldOfView,
        Lighting.ClockTime
    )
end

local gameInfoPara = TabInfo:Paragraph({
    Title = "Game Info",
    Desc  = buildGameInfo(),
    Icon  = "globe",
})

TabInfo:Button({
    Title    = "Refresh Info",
    Desc     = "Perbarui info game",
    Icon     = "refresh-cw",
    Callback = function()
        pcall(function()
            gameInfoPara:SetDesc(buildGameInfo())
        end)
        WindUI:Notify({ Title = "Refreshed", Content = "Info diperbarui.", Duration = 2, Icon = "refresh-cw" })
    end
})

TabInfo:Divider()

TabInfo:Paragraph({
    Title = "Cara Pakai",
    Desc  = "1. Buka tab Recorder, aktifkan Start Recording.\n2. Mainkan game, semua event akan terekam.\n3. Buka tab Filter untuk memilih kategori.\n4. Buka tab Analyzer untuk scan object game.\n5. Gunakan Export untuk lihat di F9 Output.",
    Icon  = "help-circle",
})
