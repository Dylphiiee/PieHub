local WindUI = loadstring(game:HttpGet("https://github.com/Footagesus/WindUI/releases/latest/download/main.lua"))()
WindUI:SetNotificationLower(false)

local Window = WindUI:CreateWindow({
    Title = "Shader Controller",
    Icon = "palette",
    Author = "Advanced Visuals",
    Folder = "ShaderController",
    Size = UDim2.fromOffset(620, 480),
    MinSize = Vector2.new(500, 350),
    Resizable = true,
    SideBarWidth = 180,
    HideSearchBar = false,
    Acrylic = false,
    Theme = "Dark",
})

local Config = Window.ConfigManager
local presetConfig = Config:CreateConfig("presets")

local LightingTab = Window:Tab({ Title = "Lighting", Icon = "sun" })

LightingTab:Colorpicker({
    Title = "Ambient",
    Desc = "Warna ambient global",
    Default = game.Lighting.Ambient,
    Flag = "ambientColor",
    Callback = function(color)
        game.Lighting.Ambient = color
    end
})

LightingTab:Colorpicker({
    Title = "Outdoor Ambient",
    Default = game.Lighting.OutdoorAmbient,
    Flag = "outdoorAmbient",
    Callback = function(color)
        game.Lighting.OutdoorAmbient = color
    end
})

LightingTab:Slider({
    Title = "Brightness",
    Desc = "Kecerahan pencahayaan",
    Step = 0.1,
    Value = { Min = 0, Max = 10, Default = game.Lighting.Brightness },
    IsTooltip = true,
    IsTextbox = true,
    Flag = "brightness",
    Callback = function(value)
        game.Lighting.Brightness = value
    end
})

LightingTab:Colorpicker({
    Title = "Fog Color",
    Default = game.Lighting.FogColor,
    Flag = "fogColor",
    Callback = function(color)
        game.Lighting.FogColor = color
    end
})

LightingTab:Slider({
    Title = "Fog Density",
    Step = 0.001,
    Value = { Min = 0, Max = 1, Default = 1 - (game.Lighting.FogEnd / 100000) },
    IsTooltip = true,
    Flag = "fogEnd",
    Callback = function(value)
        game.Lighting.FogEnd = 100000 - (value * 100000)
        game.Lighting.FogStart = 0
    end
})

LightingTab:Slider({
    Title = "Time of Day",
    Step = 0.5,
    Value = { Min = 0, Max = 24, Default = game.Lighting.ClockTime or 12 },
    IsTooltip = true,
    IsTextbox = true,
    Flag = "clockTime",
    Callback = function(value)
        game.Lighting.ClockTime = value
    end
})

local PostTab = Window:Tab({ Title = "PostFX", Icon = "camera" })

PostTab:Slider({
    Title = "Bloom Intensity",
    Step = 0.1,
    Value = { Min = 0, Max = 5, Default = game.Lighting.Bloom.Intensity },
    IsTooltip = true,
    Flag = "bloomIntensity",
    Callback = function(value)
        game.Lighting.Bloom.Intensity = value
    end
})

PostTab:Slider({
    Title = "Bloom Threshold",
    Step = 0.01,
    Value = { Min = 0, Max = 1, Default = game.Lighting.Bloom.Threshold },
    IsTooltip = true,
    Flag = "bloomThreshold",
    Callback = function(value)
        game.Lighting.Bloom.Threshold = value
    end
})

PostTab:Slider({
    Title = "Bloom Size",
    Step = 1,
    Value = { Min = 1, Max = 100, Default = game.Lighting.Bloom.Size },
    IsTooltip = true,
    Flag = "bloomSize",
    Callback = function(value)
        game.Lighting.Bloom.Size = value
    end
})

local blur = game.Lighting:FindFirstChild("Blur")
if not blur then
    blur = Instance.new("BlurEffect")
    blur.Parent = game.Lighting
end

PostTab:Slider({
    Title = "Blur Amount",
    Step = 1,
    Value = { Min = 0, Max = 100, Default = blur.Size },
    IsTooltip = true,
    Flag = "blurSize",
    Callback = function(value)
        blur.Size = value
        blur.Enabled = (value > 0)
    end
})

PostTab:Slider({
    Title = "SunRays Intensity",
    Step = 0.01,
    Value = { Min = 0, Max = 1, Default = game.Lighting.SunRays.Intensity },
    IsTooltip = true,
    Flag = "sunraysIntensity",
    Callback = function(value)
        game.Lighting.SunRays.Intensity = value
    end
})

PostTab:Colorpicker({
    Title = "Color Correction Tint",
    Default = game.Lighting.ColorCorrection.TintColor,
    Flag = "ccTint",
    Callback = function(color)
        game.Lighting.ColorCorrection.TintColor = color
        game.Lighting.ColorCorrection.Enabled = true
    end
})

PostTab:Slider({
    Title = "CC Brightness",
    Step = 0.01,
    Value = { Min = -1, Max = 1, Default = game.Lighting.ColorCorrection.Brightness or 0 },
    IsTooltip = true,
    Flag = "ccBrightness",
    Callback = function(value)
        game.Lighting.ColorCorrection.Brightness = value
        game.Lighting.ColorCorrection.Enabled = true
    end
})

PostTab:Slider({
    Title = "CC Saturation",
    Step = 0.01,
    Value = { Min = -1, Max = 1, Default = game.Lighting.ColorCorrection.Saturation or 0 },
    IsTooltip = true,
    Flag = "ccSaturation",
    Callback = function(value)
        game.Lighting.ColorCorrection.Saturation = value
        game.Lighting.ColorCorrection.Enabled = true
    end
})

PostTab:Slider({
    Title = "SunRays Spread",
    Step = 0.01,
    Value = { Min = 0, Max = 1, Default = game.Lighting.SunRays.Spread },
    Flag = "sunraysSpread",
    Callback = function(value)
        game.Lighting.SunRays.Spread = value
    end
})

PostTab:Slider({
    Title = "Sun Glare",
    Desc = "Intensitas pantulan menyilaukan",
    Step = 0.01,
    Value = { Min = 0, Max = 1, Default = game.Lighting.SunRays.Intensity },
    IsTooltip = true,
    Flag = "sunGlare",
    Callback = function(value)
        game.Lighting.SunRays.Intensity = value
        game.Lighting.Bloom.Intensity = value * 2
    end
})

PostTab:Slider({
    Title = "Reflection Strength",
    Desc = "Kekuatan pantulan pada objek",
    Step = 0.01,
    Value = { Min = 0, Max = 1, Default = game.Lighting.EnvironmentSpecularScale },
    Flag = "reflectionStrength",
    Callback = function(value)
        game.Lighting.EnvironmentSpecularScale = value
    end
})

local MaterialTab = Window:Tab({ Title = "Materials", Icon = "droplet" })

MaterialTab:Slider({
    Title = "Env Specular Scale",
    Step = 0.01,
    Value = { Min = 0, Max = 1, Default = game.Lighting.EnvironmentSpecularScale },
    Flag = "specularScale",
    Callback = function(value)
        game.Lighting.EnvironmentSpecularScale = value
    end
})

MaterialTab:Slider({
    Title = "Env Diffuse Scale",
    Step = 0.01,
    Value = { Min = 0, Max = 1, Default = game.Lighting.EnvironmentDiffuseScale },
    Flag = "diffuseScale",
    Callback = function(value)
        game.Lighting.EnvironmentDiffuseScale = value
    end
})

MaterialTab:Slider({
    Title = "Exposure Compensation",
    Step = 0.1,
    Value = { Min = -5, Max = 5, Default = game.Lighting.ExposureCompensation },
    Flag = "exposure",
    Callback = function(value)
        game.Lighting.ExposureCompensation = value
    end
})

MaterialTab:Slider({
    Title = "Shadow Softness",
    Step = 0.01,
    Value = { Min = 0, Max = 1, Default = game.Lighting.ShadowSoftness or 0.3 },
    Flag = "shadowSoftness",
    Callback = function(value)
        game.Lighting.ShadowSoftness = value
    end
})

MaterialTab:Slider({
    Title = "Global Wind",
    Step = 0.1,
    Value = { Min = 0, Max = 2, Default = game.Lighting.GlobalWind or 0 },
    Flag = "globalWind",
    Callback = function(value)
        game.Lighting.GlobalWind = value
    end
})

local SkyTab = Window:Tab({ Title = "Skybox", Icon = "cloud" })

local skyboxPresets = {
    { Title = "Default (No Sky)", Value = "Default" },
    { Title = "Realistic Sky", Value = "Realistic" },
    { Title = "Nebula", Value = "Nebula" },
    { Title = "Space", Value = "Space" },
    { Title = "Sunset", Value = "Sunset" },
    { Title = "Custom", Value = "Custom" },
}

local function applySkyboxPreset(presetName)
    local sky = game.Lighting:FindFirstChildOfClass("Sky") or Instance.new("Sky")
    sky.Parent = game.Lighting
    sky.Name = "Sky"
    if presetName == "Default" then
        sky:Destroy()
        return
    elseif presetName == "Realistic" then
        sky.SkyboxBk = "rbxassetid://2920442330"
        sky.SkyboxDn = "rbxassetid://2920442418"
        sky.SkyboxFt = "rbxassetid://2920442621"
        sky.SkyboxLf = "rbxassetid://2920442730"
        sky.SkyboxRt = "rbxassetid://2920442821"
        sky.SkyboxUp = "rbxassetid://2920442943"
    elseif presetName == "Nebula" then
        sky.SkyboxBk = "rbxassetid://159454299"
        sky.SkyboxDn = "rbxassetid://159454306"
        sky.SkyboxFt = "rbxassetid://159454311"
        sky.SkyboxLf = "rbxassetid://159454313"
        sky.SkyboxRt = "rbxassetid://159454321"
        sky.SkyboxUp = "rbxassetid://159454325"
    elseif presetName == "Space" then
        sky.SkyboxBk = "rbxassetid://600830446"
        sky.SkyboxDn = "rbxassetid://600831651"
        sky.SkyboxFt = "rbxassetid://600832324"
        sky.SkyboxLf = "rbxassetid://600832803"
        sky.SkyboxRt = "rbxassetid://600833166"
        sky.SkyboxUp = "rbxassetid://600833677"
    elseif presetName == "Sunset" then
        sky.SkyboxBk = "rbxassetid://1083472392"
        sky.SkyboxDn = "rbxassetid://1083472499"
        sky.SkyboxFt = "rbxassetid://1083472620"
        sky.SkyboxLf = "rbxassetid://1083472757"
        sky.SkyboxRt = "rbxassetid://1083472860"
        sky.SkyboxUp = "rbxassetid://1083472990"
    end
end

SkyTab:Dropdown({
    Title = "Skybox Preset",
    Values = skyboxPresets,
    Value = "Default",
    Flag = "skyboxPreset",
    Callback = function(option)
        applySkyboxPreset(option)
    end
})

SkyTab:Divider()

local sides = {"Bk", "Dn", "Ft", "Lf", "Rt", "Up"}
local sideLabels = {
    Bk = "Belakang", Dn = "Bawah", Ft = "Depan",
    Lf = "Kiri", Rt = "Kanan", Up = "Atas"
}

for _, side in ipairs(sides) do
    SkyTab:Input({
        Title = "Skybox " .. sideLabels[side],
        Value = "",
        Placeholder = "rbxassetid://...",
        Type = "Input",
        Flag = "skybox" .. side,
        Callback = function(url)
            local sky = game.Lighting:FindFirstChildOfClass("Sky") or Instance.new("Sky")
            sky.Parent = game.Lighting
            if sky and url ~= "" then
                sky["Skybox" .. side] = url
            end
        end
    })
end

SkyTab:Divider()

SkyTab:Slider({
    Title = "Sun Size",
    Desc = "Ukuran bola matahari di langit",
    Step = 1,
    Value = { Min = 1, Max = 50, Default = game.Lighting:FindFirstChildOfClass("Sky") and game.Lighting.Sky.SunAngularSize or 21 },
    IsTooltip = true,
    Flag = "sunAngularSize",
    Callback = function(value)
        local sky = game.Lighting:FindFirstChildOfClass("Sky")
        if sky then
            sky.SunAngularSize = value
        else
            sky = Instance.new("Sky")
            sky.Parent = game.Lighting
            sky.SunAngularSize = value
        end
    end
})

local GFXTab = Window:Tab({ Title = "Global FX", Icon = "sparkles", Desc = "Kontrol grafik global tanpa ubah map" })

local materialList = {
    "Default (Reset)",
    "Plastic",
    "SmoothPlastic",
    "Neon",
    "Metal",
    "Glass",
    "Wood",
    "WoodPlanks",
    "Marble",
    "Granite",
    "Brick",
    "Pebble",
    "Cobblestone",
    "Concrete",
    "CorrodedMetal",
    "DiamondPlate",
    "Foil",
    "Grass",
    "Ice",
    "LeafyGrass",
    "Sand",
    "Snow",
    "Water",
}

local originalMaterials = {}

local function saveOriginalMaterials()
    originalMaterials = {}
    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("BasePart") and not obj:IsA("Terrain") then
            originalMaterials[obj] = obj.Material
        end
    end
end

saveOriginalMaterials()

local function applyGlobalMaterial(materialName)
    if materialName == "Default (Reset)" then
        for obj, mat in pairs(originalMaterials) do
            if obj and obj:IsA("BasePart") then
                pcall(function() obj.Material = mat end)
            end
        end
    else
        if next(originalMaterials) == nil then
            saveOriginalMaterials()
        end
        for _, obj in ipairs(workspace:GetDescendants()) do
            if obj:IsA("BasePart") and not obj:IsA("Terrain") then
                pcall(function()
                    if not originalMaterials[obj] then
                        originalMaterials[obj] = obj.Material
                    end
                    obj.Material = Enum.Material[materialName]
                end)
            end
        end
    end
end

GFXTab:Dropdown({
    Title = "Global Material",
    Desc = "Paksa semua objek pakai material ini",
    Values = materialList,
    Value = "Default (Reset)",
    Flag = "globalMaterial",
    Callback = function(selected)
        applyGlobalMaterial(selected)
    end
})

GFXTab:Button({
    Title = "Simpan Material Asli Ulang",
    Desc = "Rekam ulang material asli",
    Callback = function()
        saveOriginalMaterials()
        WindUI:Notify({ Title = "Material", Content = "Material asli tersimpan ulang.", Duration = 1.5 })
    end
})

GFXTab:Divider()

local dof = game.Lighting:FindFirstChild("DepthOfField") or Instance.new("DepthOfFieldEffect")
dof.Parent = game.Lighting
dof.Enabled = false

GFXTab:Toggle({
    Title = "Depth of Field",
    Desc = "Aktifkan blur jarak",
    Value = false,
    Flag = "dofEnabled",
    Callback = function(state)
        dof.Enabled = state
    end
})

GFXTab:Slider({
    Title = "Focus Distance",
    Step = 1,
    Value = { Min = 0, Max = 1000, Default = 50 },
    IsTooltip = true,
    Flag = "dofFocus",
    Callback = function(val)
        dof.FocusDistance = val
    end
})

GFXTab:Slider({
    Title = "Near Blur",
    Step = 0.1,
    Value = { Min = 0, Max = 10, Default = 0 },
    IsTooltip = true,
    Flag = "dofNear",
    Callback = function(val)
        dof.NearIntensity = val
    end
})

GFXTab:Slider({
    Title = "Far Blur",
    Step = 0.1,
    Value = { Min = 0, Max = 10, Default = 0 },
    IsTooltip = true,
    Flag = "dofFar",
    Callback = function(val)
        dof.FarIntensity = val
    end
})

GFXTab:Divider()

local vignetteGui = Instance.new("ScreenGui")
vignetteGui.Name = "VignetteOverlay"
vignetteGui.IgnoreGuiInset = true
vignetteGui.ResetOnSpawn = false
vignetteGui.Parent = game.Players.LocalPlayer:WaitForChild("PlayerGui")

local vignetteFrame = Instance.new("Frame")
vignetteFrame.Size = UDim2.fromScale(1, 1)
vignetteFrame.BackgroundTransparency = 1
vignetteFrame.BorderSizePixel = 0
vignetteFrame.Parent = vignetteGui

local vignetteImage = Instance.new("ImageLabel")
vignetteImage.Size = UDim2.fromScale(1, 1)
vignetteImage.BackgroundTransparency = 1
vignetteImage.Image = "rbxassetid://284402758"
vignetteImage.ImageColor3 = Color3.fromRGB(0, 0, 0)
vignetteImage.ScaleType = Enum.ScaleType.Slice
vignetteImage.SliceCenter = Rect.new(100, 100, 100, 100)
vignetteImage.Parent = vignetteFrame

local vignetteEnabled = false
local vignetteTransparency = 0.7

local function updateVignette()
    vignetteFrame.Visible = vignetteEnabled
    vignetteImage.ImageTransparency = vignetteTransparency
end

GFXTab:Toggle({
    Title = "Vignette",
    Desc = "Efek sudut gelap",
    Value = false,
    Callback = function(state)
        vignetteEnabled = state
        updateVignette()
    end
})

GFXTab:Slider({
    Title = "Vignette Strength",
    Step = 0.01,
    Value = { Min = 0, Max = 1, Default = 0.7 },
    IsTooltip = true,
    Callback = function(val)
        vignetteTransparency = 1 - val
        updateVignette()
    end
})

GFXTab:Divider()

GFXTab:Slider({
    Title = "Exposure Compensation",
    Step = 0.1,
    Value = { Min = -5, Max = 5, Default = game.Lighting.ExposureCompensation },
    IsTooltip = true,
    Flag = "exposure",
    Callback = function(value)
        game.Lighting.ExposureCompensation = value
    end
})

GFXTab:Slider({
    Title = "Contrast (Gamma)",
    Desc = "Semakin rendah semakin kontras",
    Step = 0.01,
    Value = { Min = 0.5, Max = 3, Default = 1 },
    IsTooltip = true,
    Callback = function(value)
        pcall(function()
            game.Lighting.ColorCorrection.Contrast = value
            game.Lighting.ColorCorrection.Enabled = true
        end)
    end
})

GFXTab:Slider({
    Title = "Sun Azimuth",
    Step = 1,
    Value = { Min = 0, Max = 360, Default = 150 },
    IsTooltip = true,
    Callback = function(val)
        game.Lighting.ClockTime = val / 15
    end
})

GFXTab:Slider({
    Title = "Sun Altitude",
    Step = 1,
    Value = { Min = 0, Max = 90, Default = 30 },
    IsTooltip = true,
    Callback = function(val)
        local altitude = math.clamp(val, 0, 90)
        local hour = 6 + (altitude / 90) * 12
        game.Lighting.ClockTime = hour
    end
})

local PresetTab = Window:Tab({ Title = "Presets", Icon = "save" })

PresetTab:Button({
    Title = "Simpan Preset Saat Ini",
    Icon = "hard-drive",
    Callback = function()
        presetConfig:Save()
        WindUI:Notify({ Title = "Preset", Content = "Pengaturan berhasil disimpan sebagai preset.", Duration = 2, Icon = "check-circle" })
    end
})

PresetTab:Button({
    Title = "Muat Preset Tersimpan",
    Icon = "download",
    Callback = function()
        presetConfig:Load()
        WindUI:Notify({ Title = "Preset", Content = "Preset berhasil dimuat.", Duration = 2, Icon = "check-circle" })
    end
})

PresetTab:Divider()

PresetTab:Toggle({
    Title = "Auto-Load Preset",
    Desc = "Otomatis memuat preset saat game dimulai",
    Value = false,
    Callback = function(state)
        presetConfig:SetAutoLoad(state)
    end
})

PresetTab:Divider()

PresetTab:Button({
    Title = "Realistic",
    Icon = "sunrise",
    Callback = function()
        game.Lighting.Ambient = Color3.fromRGB(105, 105, 105)
        game.Lighting.OutdoorAmbient = Color3.fromRGB(127, 140, 153)
        game.Lighting.Brightness = 3
        game.Lighting.ClockTime = 14
        game.Lighting.Bloom.Intensity = 0.3
        game.Lighting.Bloom.Threshold = 0.8
        game.Lighting.ColorCorrection.TintColor = Color3.fromRGB(255, 255, 255)
        game.Lighting.ColorCorrection.Brightness = 0.02
        game.Lighting.ColorCorrection.Saturation = -0.1
        game.Lighting.EnvironmentSpecularScale = 0.5
        game.Lighting.EnvironmentDiffuseScale = 0.7
        WindUI:Notify({ Title = "Preset", Content = "Realistic preset applied.", Duration = 1.5 })
    end
})

PresetTab:Button({
    Title = "Vibrant",
    Icon = "palette",
    Callback = function()
        game.Lighting.Ambient = Color3.fromRGB(50, 50, 50)
        game.Lighting.Brightness = 5
        game.Lighting.Bloom.Intensity = 1
        game.Lighting.Bloom.Threshold = 0.5
        game.Lighting.ColorCorrection.Saturation = 0.4
        game.Lighting.ColorCorrection.Brightness = 0.05
        WindUI:Notify({ Title = "Preset", Content = "Vibrant preset applied.", Duration = 1.5 })
    end
})

PresetTab:Button({
    Title = "Dark & Moody",
    Icon = "moon",
    Callback = function()
        game.Lighting.Ambient = Color3.fromRGB(20, 20, 20)
        game.Lighting.Brightness = 1
        game.Lighting.FogEnd = 100
        game.Lighting.Bloom.Intensity = 0.1
        game.Lighting.ColorCorrection.TintColor = Color3.fromRGB(180, 180, 255)
        game.Lighting.ColorCorrection.Saturation = -0.5
        game.Lighting.EnvironmentSpecularScale = 0.1
        WindUI:Notify({ Title = "Preset", Content = "Dark & Moody applied.", Duration = 1.5 })
    end
})

Window:CreateTopbarButton("Reset", "rotate-ccw", function()
    game.Lighting.Ambient = Color3.fromRGB(70, 70, 70)
    game.Lighting.OutdoorAmbient = Color3.fromRGB(127, 140, 153)
    game.Lighting.Brightness = 2
    game.Lighting.FogEnd = 100000
    game.Lighting.FogColor = Color3.fromRGB(192, 192, 192)
    game.Lighting.ClockTime = 14
    game.Lighting.Bloom.Intensity = 0
    game.Lighting.Bloom.Threshold = 0.9
    game.Lighting.Bloom.Size = 56
    game.Lighting.ColorCorrection.TintColor = Color3.fromRGB(255, 255, 255)
    game.Lighting.ColorCorrection.Brightness = 0
    game.Lighting.ColorCorrection.Saturation = 0
    game.Lighting.EnvironmentSpecularScale = 0.5
    game.Lighting.EnvironmentDiffuseScale = 0.7
    game.Lighting.ExposureCompensation = 0
    game.Lighting.ShadowSoftness = 0.3
    game.Lighting.GlobalWind = 0
    blur.Size = 0
    blur.Enabled = false
    presetConfig:Delete()
    WindUI:Notify({ Title = "Reset", Content = "Semua shader dikembalikan ke default.", Duration = 2 })
end, 1)

if presetConfig:Get("autoLoad") == true then
    presetConfig:Load()
end
