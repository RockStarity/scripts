local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local RunService = game:GetService("RunService")
local workspace = game:GetService("Workspace")
local UserInputService = game:GetService("UserInputService")
local camera = workspace.CurrentCamera

--> [< Aimbot Variables >] <--
local aimFov = 100
local aiming = false
local predictionStrength = 0.13
local smoothing = 0.05
local aimbotEnabled = false
local wallCheck = true
local teamCheck = false
local aimAtNPC = true
local killCheck = true

local selectedButton = "MouseButton2"
local buttonList = {"MouseButton1", "MouseButton2", "MouseButton3"}
local buttonNames = {
    MouseButton1 = "Left Click",
    MouseButton2 = "Right Click",
    MouseButton3 = "Middle Click"
}

local circleColor = Color3.fromRGB(255, 0, 0)
local targetedCircleColor = Color3.fromRGB(0, 255, 0)
local rainbowFov = false
local hue = 0
local rainbowSpeed = 0.005

--> [< Кэш для оптимизации >] <--
local npcCache = {}
local lastNPCScan = 0
local NPC_SCAN_INTERVAL = 0.5
local playerCache = {}
local lastPlayerScan = 0
local PLAYER_SCAN_INTERVAL = 0.5

--> [< FOV Circle >] <--
local fovCircle = Drawing.new("Circle")
fovCircle.Thickness = 2
fovCircle.NumSides = 64
fovCircle.Radius = aimFov
fovCircle.Filled = false
fovCircle.Transparency = 1
fovCircle.Color = circleColor
fovCircle.Visible = false
fovCircle.ZIndex = 999

local currentTarget = nil
local currentTargetType = nil

getgenv().le = getgenv().le or loadstring(game:HttpGet('https://raw.githubusercontent.com/RockStarity/scripts/refs/heads/main/LimbExtender.lua'))()
local LimbExtender = getgenv().le

local le = LimbExtender({
    LISTEN_FOR_INPUT = false,
    USE_HIGHLIGHT = false,
})

getgenv().uilibray = getgenv().uilibray or loadstring(game:HttpGet('https://sirius.menu/rayfield'))()
local Rayfield = getgenv().uilibray

local Messages = {
    "happy halloween 🎃",
    "skeleton meme from 2021 💀",
    "spooky ass message 🕸🕷",
    "THE FLYING DUTCHMAN! ⚓",
    "👻 BOO! JOB APPLICATION 📄",
    "trick or treat smell my feet 🦶",
    "santa claus is lowkey a freak 😰",
    "spooky scary coolkids 😈",
    "itsa spooki month 🕺🕺",
    "kitkat razerblade edition 🍬",
    "update: fucking nothing 🎃😨",
    "follow axiogenesis on roblox 🦴👁",
}
local ChosenMessage = Messages[math.random(1, #Messages)]

local Window = Rayfield:CreateWindow({
    Name = "AXIOS",
    Icon = 107904589783906,

    LoadingTitle = "AXIOS",
    LoadingSubtitle = ChosenMessage,

    Theme = "Default",
    DisableRayfieldPrompts = true,

    ConfigurationSaving = {
        Enabled = true,
        FolderName = "LimbExtenderConfigs",
        FileName = "Configuration",
    },
})

local Settings = Window:CreateTab("Limbs", "scale-3d")
local AimbotTab = Window:CreateTab("Aimbot", "crosshair")
local Tab = Window:CreateTab("Sense", "eye")
local Target = Window:CreateTab("Target", "crosshair")
local Themes = Window:CreateTab("Themes", "palette")

local function safeCreate(tab, methodName, opts)
    local method = tab[methodName]
    if type(method) == "function" then
        return method(tab, opts)
    else
        warn("Method " .. tostring(methodName) .. " not found on tab")
    end
end

local function createOption(params)
    local methodName = "Create" .. params.method
    local opts = {
        Name = params.name,
        SectionParent = params.section,
        CurrentValue = params.value,
        Flag = params.flag,
        Options = params.options,
        CurrentOption = params.currentOption,
        MultipleOptions = params.multipleOptions,
        Range = params.range,
        Color = params.color,
        Increment = params.increment,
        Callback = function(Value)
            
            if params.multipleOptions == false and type(Value) == "table" then
                Value = Value[1]
            end
            le:Set(params.flag, Value)
        end,
    }
    return safeCreate(params.tab, methodName, opts)
end

local ModifyLimbs = Settings:CreateToggle({
    Name = "Modify Limbs",
    SectionParent = nil,
    CurrentValue = false,
    Flag = "ModifyLimbs",
    Callback = function(Value)
        le:Toggle(Value)
    end,
})
Settings:CreateDivider()

local toggleSettings = {
    { method = "Toggle", name = "Team Check", flag = "TEAM_CHECK", tab = Settings, value = le:Get("TEAM_CHECK") },
    { method = "Toggle", name = "ForceField Check", flag = "FORCEFIELD_CHECK", tab = Settings, value = le:Get("FORCEFIELD_CHECK") },
    { method = "Toggle", name = "ESP Compatible", flag = "ESP_COMPATIBLE", tab = Settings, value = le:Get("ESP_COMPATIBLE") },
    { method = "Toggle", name = "Limb Collisions", flag = "LIMB_CAN_COLLIDE", tab = Settings, value = le:Get("LIMB_CAN_COLLIDE"), createDivider = true },
    { method = "Slider", name = "Limb Transparency", flag = "LIMB_TRANSPARENCY", tab = Settings, range = {0,1}, increment = 0.1, value = le:Get("LIMB_TRANSPARENCY") },
    { method = "Slider", name = "Limb Size", flag = "LIMB_SIZE", tab = Settings, range = {5,50}, increment = 0.5, value = le:Get("LIMB_SIZE"), createDivider = true },
}

for _, setting in pairs(toggleSettings) do
    createOption(setting)
    if setting.createDivider then
        setting.tab:CreateDivider()
    end
end

Settings:CreateKeybind({
    Name = "Toggle Keybind",
    CurrentKeybind = le:Get("TOGGLE"),
    HoldToInteract = false,
    SectionParent = nil,
    Flag = "ToggleKeybind",
    Callback = function()
        ModifyLimbs:Set(not le._running)
    end,
})

local TargetLimb = Target:CreateDropdown({
    Name = "Target Limb",
    Options = {},
    CurrentOption = { le:Get("TARGET_LIMB") },
    MultipleOptions = false,
    Flag = "TARGET_LIMB",
    Callback = function(Options)
        le:Set("TARGET_LIMB", Options[1])
    end,
})

Themes:CreateDropdown({
    Name = "Current Theme",
    Options = {"Default", "AmberGlow", "Amethyst", "Bloom", "DarkBlue", "Green", "Light", "Ocean", "Serenity"},
    CurrentOption = {"Default"},
    MultipleOptions = false,
    Flag = "CurrentTheme",
    Callback = function(Options)
        Window.ModifyTheme(Options[1])
    end,
})

local Sense = loadstring(game:HttpGet('https://sirius.menu/sense'))()
Sense.teamSettings.enemy.enabled = true
Sense.teamSettings.friendly.enabled = true

-- Function to check if part should be hidden from ESP
local function shouldIgnorePart(part)
    -- Hide parts with _Hidden_ prefix
    if string.sub(part.Name, 1, 7) == "_Hidden_" then
        return true
    end
    
    -- Hide Head parts when ESP Compatible is enabled and they're modified
    if le:Get("ESP_COMPATIBLE") and part.Name == "Head" then
        -- Check if this character has modified limbs
        local character = part.Parent
        if character and character:FindFirstChild("Humanoid") then
            local player = Players:GetPlayerFromCharacter(character)
            if player and player ~= LocalPlayer then
                -- Check if any limb is modified for this player
                for limb, limbData in pairs(le._limbStore or {}) do
                    if limbData.OriginalName == "Head" and limb.Parent == character then
                        return true
                    end
                end
            end
        end
    end
    
    -- Also check if this is a modified limb part
    if le:Get("ESP_COMPATIBLE") then
        for limb, limbData in pairs(le._limbStore or {}) do
            if limb == part and limbData.ESPPart then
                return true -- Hide original limb, ESP part will be shown instead
            end
        end
    end
    
    return false
end

-- Hook into all major ESP functions to ignore hidden parts
local function hookESPFunction(funcName)
    local originalFunc = Sense[funcName] or function() end
    Sense[funcName] = function(part, ...)
        if shouldIgnorePart(part) then
            return
        end
        return originalFunc(part, ...)
    end
end

-- Hook all ESP functions
hookESPFunction("AddBox")
hookESPFunction("AddChams")
hookESPFunction("AddTracer")
hookESPFunction("AddNameTag")
hookESPFunction("AddHealthBar")
hookESPFunction("AddOffScreenArrow")

-- Also hook the main ESP update functions if they exist
hookESPFunction("UpdateESP")
hookESPFunction("DrawESP")
hookESPFunction("RenderESP")

local function setBoth(settingName, value)
    if Sense and Sense.teamSettings then
        Sense.teamSettings.enemy[settingName] = value
        Sense.teamSettings.friendly[settingName] = value
    end
end

local function createControl(def)
    if not def or not def.type then return end

    local function applyPropsToTeams(value)
        if not def.props then return end
        local function wrapColor(c)
            if def.alpha ~= nil then
                return {c, def.alpha}
            end
            return c
        end

        if def.props.friendly then
            local target = Sense.teamSettings.friendly
            for _, propName in ipairs(def.props.friendly) do
                target[propName] = (def.type == "color") and wrapColor(value) or value
            end
        end
        if def.props.enemy then
            local target = Sense.teamSettings.enemy
            for _, propName in ipairs(def.props.enemy) do
                target[propName] = (def.type == "color") and wrapColor(value) or value
            end
        end
    end

    local function controlCallback(v)
        if def.setting then
            setBoth(def.setting, v)
        end
        applyPropsToTeams(v)
        if def.onChange then def.onChange(v) end
    end

    if def.type == "section" then
        Tab:CreateSection(def.name or "")
        return
    elseif def.type == "label" then
        Tab:CreateLabel(def.name or "")
        return
    elseif def.type == "toggle" then
        return Tab:CreateToggle({ Name = def.name, CurrentValue = def.default or false, Flag = def.flag or "", Callback = controlCallback })
    elseif def.type == "color" then
        return Tab:CreateColorPicker({ Name = def.name, Color = def.color or Color3.fromRGB(255,255,255), Flag = def.flag or "", Callback = controlCallback })
    elseif def.type == "dropdown" then
        return Tab:CreateDropdown({ Name = def.name, Options = def.options or {}, CurrentOption = def.current, Flag = def.flag or "", Callback = controlCallback })
    elseif def.type == "slider" then
        return Tab:CreateSlider({ Name = def.name, Range = def.range or {0,100}, CurrentValue = (def.default ~= nil and def.default) or ((def.range and def.range[1]) or 0), Increment = def.increment or 1, Suffix = def.suffix or "", Flag = def.flag or "", Callback = controlCallback })
    end
end

local function colorBoth(name, flag, propertiesList, defaultColor, alpha)
    return { type = "color", name = name, flag = flag, color = defaultColor, alpha = alpha or 1, props = { friendly = propertiesList, enemy = propertiesList } }
end
local function colorFriendly(name, flag, friendlyProps, defaultColor, alpha)
    return { type = "color", name = name, flag = flag, color = defaultColor, alpha = alpha or 1, props = { friendly = friendlyProps } }
end
local function colorEnemy(name, flag, enemyProps, defaultColor, alpha)
    return { type = "color", name = name, flag = flag, color = defaultColor, alpha = alpha or 1, props = { enemy = enemyProps } }
end
local function toggle(name, flag, setting, default)
    return { type = "toggle", name = name, flag = flag, setting = setting, default = default }
end
local function slider(name, flag, range, default, inc, setting)
    return { type = "slider", name = name, flag = flag, range = range, default = default, increment = inc, setting = setting }
end

local ui = {
    { type = "section", name = "Team Settings" },
    { type = "toggle", name = "Hide Team", flag = "HideTeam", default = false, onChange = function(v) Sense.teamSettings.friendly.enabled = not v end },

    colorBoth("Team Color",  "TeamColor", {"boxColor","box3dColor","offScreenArrowColor","tracerColor"}, Color3.fromRGB(0,255,0), 1),
    colorBoth("Enemy Color", "EnemyColor", {"boxColor","box3dColor","offScreenArrowColor","tracerColor"}, Color3.fromRGB(255,0,0), 1),

    { type = "section", name = "Box" },
    toggle("Enabled", "Boxes", "box", false),
    toggle("Outline", "BoxesOutlined", "boxOutline", true),
    toggle("Fill", "BoxesFilled", "boxFill", false),
    colorFriendly("Team Fill Color", "TeamFillColor", {"boxFillColor"}, Color3.fromRGB(0,255,0), 0.5),
    colorEnemy("Enemy Fill Color", "EnemyFillColor", {"boxFillColor"}, Color3.fromRGB(255,0,0), 0.5),
    toggle("3D Boxes", "3DBoxes", "box3d", false),

    { type = "section", name = "Health" },
    toggle("Enabled", "HealthBar", "healthBar", false),
    { type = "color", name = "Health Color", flag = "HealthColor", color = Color3.fromRGB(0,255,0), onChange = function(c) setBoth("healthyColor", c) end },
    { type = "color", name = "Dying Color", flag = "DyingColor", color = Color3.fromRGB(255,0,0), onChange = function(c) setBoth("dyingColor", c) end },
    toggle("Outline", "HBsOutlined", "healthBarOutline", true),

    { type = "section", name = "Tracer" },
    toggle("Enabled", "Tracers", "tracer", false),
    toggle("Outline", "TracersOutlined", "tracerOutline", true),
    { type = "dropdown", name = "Origin", flag = "TracerOrigin", options = {"Bottom","Top","Mouse"}, current = "Bottom", onChange = function(v) setBoth("tracerOrigin", v) end },

    { type = "section", name = "Tag" },
    toggle("Name", "Names", "name", false),
    toggle("Name Outlined", "NamesOutlined", "nameOutline", true),
    toggle("Distance", "Distances", "distance", false),
    toggle("Distance Outlined", "DistancesOutlined", "distanceOutline", true),
    toggle("Health", "Health", "healthText", false),
    toggle("Health Outlined", "HealthsOutlined", "healthOutline", true),

    { type = "section", name = "Chams" },
    toggle("Enabled", "Chams", "chams", false),
    toggle("Visible Only", "ChamsVisOnly", "chamsVisibleOnly", false),
    colorFriendly("Team Fill Color", "TeamFillColorChams", {"chamsFillColor"}, Color3.new(0.2,0.2,0.2), 0.5),
    colorFriendly("Team Outline Color", "TeamOutlineColorChams", {"chamsOutlineColor"}, Color3.new(0,1,0), 0),
    colorEnemy("Enemy Fill Color", "EnemyFillColorChams", {"chamsFillColor"}, Color3.new(0.2,0.2,0.2), 0.5),
    colorEnemy("Enemy Outline Color", "EnemyOutlineColorChams", {"chamsOutlineColor"}, Color3.new(1,0,0), 0),

    { type = "section", name = "Off Screen Arrow" },
    toggle("Enabled", "OSA", "offScreenArrow", false),
    slider("Size", "OSASize", {15,50}, 15, 1, "offScreenArrowSize"),
    slider("Radius", "OSARadius", {150,360}, 150, 1, "offScreenArrowRadius"),
    toggle("Outline", "OSAOutlined", "offScreenArrowOutline", true),

    { type = "section", name = "Weapon" },
    toggle("Enabled", "Weapons", "weapon", false),
    toggle("Outline", "WeaponOutlined", "weaponOutline", true),
}

for _, entry in ipairs(ui) do
    createControl(entry)
end

Sense.Load()
Rayfield:LoadConfiguration()

local limbs = {}
local function addLimbIfNew(name)
    if not name then return end
    if not table.find(limbs, name) then
        table.insert(limbs, name)
        table.sort(limbs)
        TargetLimb:Refresh(limbs)
    end
end

local function characterAdded(Character)
    if not Character then return end
    local function onChildChanged(child)
        if not child or not child:IsA("BasePart") then return end
        addLimbIfNew(child.Name)
    end

    Character.ChildAdded:Connect(onChildChanged)

    for _, child in ipairs(Character:GetChildren()) do
        onChildChanged(child)
    end
end

LocalPlayer.CharacterAdded:Connect(characterAdded)
if LocalPlayer.Character then
    characterAdded(LocalPlayer.Character)
end

--> [< Aimbot Functions >] <--
local function isTargetAlive(target, targetType)
    if not target then return false end
    
    if targetType == "player" then
        if target.Character then
            local humanoid = target.Character:FindFirstChild("Humanoid")
            return humanoid ~= nil and humanoid.Health > 0
        end
    elseif targetType == "npc" then
        if target and target.Parent then
            local humanoid = target:FindFirstChild("Humanoid")
            return humanoid ~= nil and humanoid.Health > 0
        end
    end
    return false
end

local function getValidPlayers()
    local validPlayers = {}
    local currentTime = tick()
    
    if currentTime - lastPlayerScan > PLAYER_SCAN_INTERVAL then
        playerCache = {}
        for _, player in ipairs(Players:GetPlayers()) do
            if player ~= LocalPlayer and player.Character then
                local humanoid = player.Character:FindFirstChild("Humanoid")
                local head = player.Character:FindFirstChild("Head")
                
                if humanoid and head and humanoid.Health > 0 then
                    if not teamCheck or player.Team ~= LocalPlayer.Team then
                        table.insert(playerCache, player)
                    end
                end
            end
        end
        lastPlayerScan = currentTime
    end
    
    return playerCache
end

local function getValidNPCs()
    local currentTime = tick()
    
    if currentTime - lastNPCScan > NPC_SCAN_INTERVAL then
        npcCache = {}
        local cameraPos = camera.CFrame.Position
        local myName = LocalPlayer.Name
        
        for _, obj in pairs(workspace:GetDescendants()) do
            if obj:IsA("Model") then
                local humanoid = obj:FindFirstChild("Humanoid")
                local head = obj:FindFirstChild("Head")
                local hrp = obj:FindFirstChild("HumanoidRootPart")
                
                if humanoid and head and hrp and humanoid.Health > 0 then
                    if obj.Name == myName then
                        continue
                    end
                    
                    local isPlayer = false
                    for _, player in ipairs(Players:GetPlayers()) do
                        if player.Character == obj then
                            isPlayer = true
                            break
                        end
                    end
                    
                    if not isPlayer then
                        local distance = (head.Position - cameraPos).Magnitude
                        if distance < 400 then
                            local size = obj:GetExtentsSize()
                            if size.Magnitude < 20 and size.Magnitude > 2 then
                                table.insert(npcCache, obj)
                            end
                        end
                    end
                end
            end
        end
        lastNPCScan = currentTime
    end
    
    return npcCache
end

local function checkWall(targetChar, targetHead)
    if not targetHead or not wallCheck then return false end
    
    local origin = camera.CFrame.Position
    local direction = (targetHead.Position - origin).unit * 500
    local params = RaycastParams.new()
    params.FilterDescendantsInstances = {LocalPlayer.Character, targetChar}
    params.FilterType = Enum.RaycastFilterType.Blacklist
    
    local raycast = workspace:Raycast(origin, direction, params)
    return raycast ~= nil
end

local function findBestTarget()
    local bestTarget = nil
    local bestType = nil
    local bestDistance = aimFov
    local mousePos = UserInputService:GetMouseLocation()
    local cameraPos = camera.CFrame.Position
    
    for _, player in ipairs(getValidPlayers()) do
        local head = player.Character.Head
        local headPos, onScreen = camera:WorldToViewportPoint(head.Position)
        
        if onScreen and headPos.Z > 0 and headPos.Z < 500 then
            local screenPos = Vector2.new(headPos.X, headPos.Y)
            local cursorDist = (screenPos - mousePos).Magnitude
            
            if cursorDist < bestDistance then
                if not checkWall(player.Character, head) then
                    bestDistance = cursorDist
                    bestTarget = player
                    bestType = "player"
                end
            end
        end
    end
    
    if aimAtNPC then
        for _, npc in ipairs(getValidNPCs()) do
            local head = npc:FindFirstChild("Head")
            local headPos, onScreen = camera:WorldToViewportPoint(head.Position)
            
            if onScreen and headPos.Z > 0 and headPos.Z < 500 then
                local screenPos = Vector2.new(headPos.X, headPos.Y)
                local cursorDist = (screenPos - mousePos).Magnitude
                
                if cursorDist < bestDistance then
                    if not checkWall(npc, head) then
                        bestDistance = cursorDist
                        bestTarget = npc
                        bestType = "npc"
                    end
                end
            end
        end
    end
    
    return bestTarget, bestType
end

local function predictPosition(target, targetType)
    if targetType == "player" then
        if target.Character and target.Character:FindFirstChild("Head") and target.Character:FindFirstChild("HumanoidRootPart") then
            local head = target.Character.Head
            local hrp = target.Character.HumanoidRootPart
            return head.Position + (hrp.Velocity * predictionStrength)
        end
    elseif targetType == "npc" then
        if target:FindFirstChild("Head") and target:FindFirstChild("HumanoidRootPart") then
            local head = target.Head
            local hrp = target.HumanoidRootPart
            return head.Position + (hrp.Velocity * predictionStrength)
        end
    end
    return nil
end

local function aimAtTarget(target, targetType)
    local pos = predictPosition(target, targetType)
    if pos then
        local cameraPos = camera.CFrame.Position
        local distance = (pos - cameraPos).Magnitude
        
        if distance > 5 and distance < 500 then
            local newCF = CFrame.new(cameraPos, pos)
            camera.CFrame = camera.CFrame:Lerp(newCF, smoothing)
            return true
        end
    end
    return false
end

--> [< Aimbot Input Handling >] <--
UserInputService.InputBegan:Connect(function(input, gp)
    if not aimbotEnabled or gp then return end
    if input.UserInputType == Enum.UserInputType[selectedButton] then
        aiming = not aiming
        if not aiming then
            currentTarget = nil
            currentTargetType = nil
        end
    end
end)

--> [< Aimbot Main Loop >] <--
local lastUpdate = 0
local lastKillCheck = 0
local TARGET_UPDATE_INTERVAL = 0.15
local KILL_CHECK_INTERVAL = 0.1

RunService.RenderStepped:Connect(function()
    if aimbotEnabled then
        local mousePos = UserInputService:GetMouseLocation()
        fovCircle.Position = Vector2.new(mousePos.X, mousePos.Y)
        fovCircle.Transparency = 0.7
        fovCircle.Visible = true
        fovCircle.Radius = aimFov
        
        if rainbowFov then
            hue = (hue + rainbowSpeed) % 1
            fovCircle.Color = Color3.fromHSV(hue, 1, 1)
        else
            fovCircle.Color = (aiming and currentTarget) and targetedCircleColor or circleColor
        end
        
        if aiming then
            local now = tick()
            
            if killCheck and currentTarget and now - lastKillCheck > KILL_CHECK_INTERVAL then
                if not isTargetAlive(currentTarget, currentTargetType) then
                    currentTarget = nil
                    currentTargetType = nil
                end
                lastKillCheck = now
            end
            
            if not currentTarget and now - lastUpdate > TARGET_UPDATE_INTERVAL then
                currentTarget, currentTargetType = findBestTarget()
                lastUpdate = now
            end
            
            if currentTarget and currentTargetType then
                aimAtTarget(currentTarget, currentTargetType)
            end
        else
            currentTarget = nil
            currentTargetType = nil
        end
    else
        fovCircle.Visible = false
        aiming = false
        currentTarget = nil
        currentTargetType = nil
    end
end)

--> [< Aimbot UI Elements >] <--
local aimbotToggle = AimbotTab:CreateToggle({
    Name = "Aimbot",
    CurrentValue = false,
    Flag = "Aimbot",
    Callback = function(Value)
        aimbotEnabled = Value
        fovCircle.Visible = Value
        if not Value then
            aiming = false
            currentTarget = nil
            currentTargetType = nil
        end
    end
})

local killCheckToggle = AimbotTab:CreateToggle({
    Name = "Kill Check (Auto Switch)",
    CurrentValue = true,
    Flag = "KillCheck",
    Callback = function(Value)
        killCheck = Value
        Rayfield:Notify({
            Title = "Kill Check",
            Content = Value and "✅ Auto switch target on kill" or "❌ Keep aiming at dead targets",
            Duration = 2
        })
    end
})

local aimAtNPCToggle = AimbotTab:CreateToggle({
    Name = "Aim at NPC",
    CurrentValue = true,
    Flag = "AimAtNPC",
    Callback = function(Value)
        aimAtNPC = Value
        currentTarget = nil
        currentTargetType = nil
        Rayfield:Notify({
            Title = "NPC Aim",
            Content = Value and "✅ Aiming at NPCs" or "❌ NPCs ignored",
            Duration = 1.5
        })
    end
})

local buttonDropdown = AimbotTab:CreateDropdown({
    Name = "Activation Button",
    Options = buttonList,
    CurrentOption = {selectedButton},
    Flag = "ActivationButton",
    Callback = function(Options)
        selectedButton = Options[1]
        Rayfield:Notify({
            Title = "Button Changed",
            Content = "Aim button: " .. buttonNames[selectedButton],
            Duration = 1.5
        })
    end
})

AimbotTab:CreateDivider()

local smoothingSlider = AimbotTab:CreateSlider({
    Name = "Smoothing",
    Range = {0, 100},
    Increment = 1,
    CurrentValue = 5,
    Flag = "Smoothing",
    Callback = function(Value)
        smoothing = 1 - (Value / 100)
    end,
})

local predictionSlider = AimbotTab:CreateSlider({
    Name = "Prediction",
    Range = {0, 0.2},
    Increment = 0.001,
    CurrentValue = 0.13,
    Flag = "PredictionStrength",
    Callback = function(Value)
        predictionStrength = Value
    end,
})

AimbotTab:CreateDivider()

local wallCheckToggle = AimbotTab:CreateToggle({
    Name = "Wall Check",
    CurrentValue = true,
    Flag = "WallCheck",
    Callback = function(Value)
        wallCheck = Value
    end
})

local teamCheckToggle = AimbotTab:CreateToggle({
    Name = "Team Check",
    CurrentValue = false,
    Flag = "TeamCheck",
    Callback = function(Value)
        teamCheck = Value
        currentTarget = nil
        currentTargetType = nil
    end
})

AimbotTab:CreateDivider()

local aimbotFov = AimbotTab:CreateSlider({
    Name = "Aimbot Fov",
    Range = {0, 500},
    Increment = 1,
    CurrentValue = 100,
    Flag = "AimbotFov",
    Callback = function(Value)
        aimFov = Value
    end,
})

local circleColorPicker = AimbotTab:CreateColorPicker({
    Name = "Fov Color",
    Color = circleColor,
    Callback = function(Color)
        circleColor = Color
        if not rainbowFov then
            fovCircle.Color = Color
        end
    end
})

local targetedCircleColorPicker = AimbotTab:CreateColorPicker({
    Name = "Targeted Color",
    Color = targetedCircleColor,
    Callback = function(Color)
        targetedCircleColor = Color
    end
})

local rainbowFovToggle = AimbotTab:CreateToggle({
    Name = "Rainbow Fov",
    CurrentValue = false,
    Flag = "RainbowFov",
    Callback = function(Value)
        rainbowFov = Value
    end
})
