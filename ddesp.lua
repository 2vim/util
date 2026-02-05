-- esp.lua
--// Variables
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local localPlayer = Players.LocalPlayer
local camera = workspace.CurrentCamera
local cache = {}

local bones = {
    {"Head", "UpperTorso"},
    {"UpperTorso", "RightUpperArm"},
    {"RightUpperArm", "RightLowerArm"},
    {"RightLowerArm", "RightHand"},
    {"UpperTorso", "LeftUpperArm"},
    {"LeftUpperArm", "LeftLowerArm"},
    {"LeftLowerArm", "LeftHand"},
    {"UpperTorso", "LowerTorso"},
    {"LowerTorso", "LeftUpperLeg"},
    {"LeftUpperLeg", "LeftLowerLeg"},
    {"LeftLowerLeg", "LeftFoot"},
    {"LowerTorso", "RightUpperLeg"},
    {"RightUpperLeg", "RightLowerLeg"},
    {"RightLowerLeg", "RightFoot"}
}

-- R6 Fallback bones
local bonesR6 = {
    {"Head", "Torso"},
    {"Torso", "Left Arm"},
    {"Torso", "Right Arm"},
    {"Torso", "Left Leg"},
    {"Torso", "Right Leg"}
}

local ESP_SETTINGS = {
    BoxOutlineColor = Color3.fromRGB(0, 0, 0),
    BoxColor = Color3.fromRGB(0, 255, 170),
    EnemyBoxColor = Color3.fromRGB(255, 55, 85),
    
    NameColor = Color3.fromRGB(255, 255, 255),
    NameOutlineColor = Color3.fromRGB(0, 0, 0),
    
    HealthOutlineColor = Color3.fromRGB(0, 0, 0),
    HealthHighColor = Color3.fromRGB(0, 255, 128),
    HealthLowColor = Color3.fromRGB(255, 50, 50),
    HealthBackgroundColor = Color3.fromRGB(40, 40, 40),
    
    CharSize = Vector2.new(4, 6),
    Teamcheck = false,
    WallCheck = false,
    Enabled = false,
    ShowBox = false,
    BoxType = "2D",
    ShowName = false,
    ShowHealth = false,
    ShowDistance = false,
    ShowSkeletons = false,
    ShowTracer = false,
    ShowHeadDot = false,
    
    TracerColor = Color3.fromRGB(0, 255, 170),
    TracerThickness = 1.5,
    TracerPosition = "Bottom",
    TracerGradient = true,
    
    SkeletonsColor = Color3.fromRGB(255, 255, 255),
    SkeletonsThickness = 1.5,
    
    HeadDotColor = Color3.fromRGB(255, 55, 85),
    HeadDotRadius = 3,
    
    -- Distance text
    DistanceColor = Color3.fromRGB(200, 200, 200),
    
    -- Weapon text (testing)
    ShowWeapon = false,
    WeaponColor = Color3.fromRGB(255, 255, 255),
}

local function create(class, properties)
    local drawing = Drawing.new(class)
    for property, value in pairs(properties) do
        drawing[property] = value
    end
    return drawing
end

-- Check if character uses R15 or R6
local function isR15(character)
    return character:FindFirstChild("UpperTorso") ~= nil
end

local function getBones(character)
    if isR15(character) then
        return bones
    else
        return bonesR6
    end
end

local function createEsp(player)
    local esp = {
        -- Tracer with gradient style
        tracer = create("Line", {
            Thickness = ESP_SETTINGS.TracerThickness,
            Color = ESP_SETTINGS.TracerColor,
            Transparency = 1
        }),
        -- Box outline (thicker for that CS2 look)
        boxOutline = create("Square", {
            Color = ESP_SETTINGS.BoxOutlineColor,
            Thickness = 1,
            Filled = false,
            Transparency = 1
        }),
        -- Main box
        box = create("Square", {
            Color = ESP_SETTINGS.BoxColor,
            Thickness = 1,
            Filled = false,
            Transparency = 1
        }),
        -- Name with clean font
        name = create("Text", {
            Color = ESP_SETTINGS.NameColor,
            Outline = false,
            Center = true,
            Size = 13,
            Font = Drawing.Fonts.Plex
        }),
        -- Health bar background
        healthBackground = create("Line", {
            Thickness = 5,
            Color = ESP_SETTINGS.HealthBackgroundColor,
            Transparency = 1
        }),
        -- Health outline
        healthOutline = create("Line", {
            Thickness = 5,
            Color = ESP_SETTINGS.HealthOutlineColor,
            Transparency = 1
        }),
        -- Health bar
        health = create("Line", {
            Thickness = 2,
            Transparency = 1
        }),
        -- Health text
        healthText = create("Text", {
            Color = Color3.new(1, 1, 1),
            Size = 10,
            Outline = false,
            Center = true,
            Font = Drawing.Fonts.Plex
        }),
        -- Distance text
        distance = create("Text", {
            Color = ESP_SETTINGS.NameColor,
            Size = 13,
            Outline = false,
            Center = true,
            Font = Drawing.Fonts.Plex
        }),
        weapon = create("Text", {
            Color = ESP_SETTINGS.WeaponColor,
            Size = 13,
            Outline = true,
            Center = true,
            Font = Drawing.Fonts.Plex
        }),
        -- Head dot (CS2 signature)
        headDot = create("Circle", {
            Color = ESP_SETTINGS.HeadDotColor,
            Thickness = 1,
            Filled = true,
            Transparency = 1,
            NumSides = 12
        }),
        headDotOutline = create("Circle", {
            Color = Color3.new(0, 0, 0),
            Thickness = 2,
            Filled = false,
            Transparency = 1,
            NumSides = 12
        }),
        boxLines = {},
        skeletonLines = {},
    }

    cache[player] = esp
end

local function isPlayerBehindWall(player)
    local character = player.Character
    if not character then
        return false
    end

    local rootPart = character:FindFirstChild("HumanoidRootPart")
    if not rootPart then
        return false
    end

    local ray = Ray.new(camera.CFrame.Position, (rootPart.Position - camera.CFrame.Position).Unit * (rootPart.Position - camera.CFrame.Position).Magnitude)
    local hit, position = workspace:FindPartOnRayWithIgnoreList(ray, {localPlayer.Character, character})
    
    return hit and hit:IsA("Part")
end

local function removeEsp(player)
    local esp = cache[player]
    if not esp then return end

    for key, drawing in pairs(esp) do
        if type(drawing) == "table" then
            -- Handle arrays like boxLines and skeletonLines
            if key == "boxLines" then
                for _, line in ipairs(drawing) do
                    if line and line.Remove then
                        line:Remove()
                    end
                end
            elseif key == "skeletonLines" then
                for _, lineData in ipairs(drawing) do
                    if lineData and lineData[1] and lineData[1].Remove then
                        lineData[1]:Remove()
                    end
                end
            end
        elseif drawing and drawing.Remove then
            drawing:Remove()
        end
    end

    cache[player] = nil
end

-- Helper function to hide all ESP elements
local function hideAllEsp(esp)
    esp.name.Visible = false
    esp.box.Visible = false
    esp.boxOutline.Visible = false
    esp.health.Visible = false
    esp.healthOutline.Visible = false
    esp.healthBackground.Visible = false
    esp.healthText.Visible = false
    esp.distance.Visible = false
    esp.tracer.Visible = false
    esp.headDot.Visible = false
    esp.headDotOutline.Visible = false
    esp.weapon.Visible = false
    
    for _, line in ipairs(esp.boxLines) do
        line.Visible = false
    end
    
    for _, lineData in ipairs(esp.skeletonLines) do
        if lineData[1] then
            lineData[1].Visible = false
        end
    end
end

local function getPlayerTeam(player)
    local playerStates = player:FindFirstChild("PlayerStates")
    if playerStates then
        local teamValue = playerStates:FindFirstChild("Team")
        if teamValue and teamValue:IsA("StringValue") then
            return teamValue.Value
        end
    end
    return nil
end

local function updateEsp()
    for player, esp in pairs(cache) do
        local character = player.Character
        local playerTeam = getPlayerTeam(player)
        local localTeam = getPlayerTeam(localPlayer)
        local isTeammate = ESP_SETTINGS.Teamcheck and playerTeam and localTeam and playerTeam == localTeam
        
        if character and not isTeammate then
            local rootPart = character:FindFirstChild("HumanoidRootPart")
            local head = character:FindFirstChild("Head")
            local humanoid = character:FindFirstChildOfClass("Humanoid")
            local isBehindWall = ESP_SETTINGS.WallCheck and isPlayerBehindWall(player)
            local shouldShow = not isBehindWall and ESP_SETTINGS.Enabled
            
            if rootPart and head and humanoid and shouldShow then
                local position, onScreen = camera:WorldToViewportPoint(rootPart.Position)
                
                if onScreen then
                    local hrp2D = camera:WorldToViewportPoint(rootPart.Position)
                    local headPos = camera:WorldToViewportPoint(head.Position + Vector3.new(0, 0.5, 0))
                    local footPos = camera:WorldToViewportPoint(rootPart.Position - Vector3.new(0, 3, 0))
                    
                    local boxHeight = math.abs(headPos.Y - footPos.Y)
                    local boxWidth = boxHeight * 0.55 -- CS2 ratio
                    
                    local boxSize = Vector2.new(math.floor(boxWidth), math.floor(boxHeight))
                    local boxPosition = Vector2.new(
                        math.floor(hrp2D.X - boxWidth / 2),
                        math.floor(headPos.Y)
                    )
                    if ESP_SETTINGS.ShowName then
                        esp.name.Visible = true
                        esp.name.Text = player.DisplayName
                        esp.name.Position = Vector2.new(boxPosition.X + boxSize.X / 2, boxPosition.Y - 15)
                        esp.name.Color = ESP_SETTINGS.NameColor
                    else
                        esp.name.Visible = false
                    end

                    if ESP_SETTINGS.ShowBox then
                        if ESP_SETTINGS.BoxType == "2D" then
                            -- Clean 2D box
                            esp.boxOutline.Size = boxSize
                            esp.boxOutline.Position = boxPosition
                            esp.box.Size = boxSize
                            esp.box.Position = boxPosition
                            esp.box.Color = ESP_SETTINGS.BoxColor
                            esp.box.Visible = true
                            esp.boxOutline.Visible = true
                            
                            for _, line in ipairs(esp.boxLines) do
                                line:Remove()
                            end
                            esp.boxLines = {}
                            
                        elseif ESP_SETTINGS.BoxType == "Corner Box Esp" then
                            -- CS2 Style Corner Box
                            local cornerLength = boxSize.X / 4
                            local cornerHeight = boxSize.Y / 5
                            
                            -- Create corner lines if not exists
                            if #esp.boxLines == 0 then
                                -- 8 corner lines (outer) + 8 outline
                                for i = 1, 16 do
                                    local boxLine = create("Line", {
                                        Thickness = i <= 8 and 2 or 4,
                                        Color = i <= 8 and ESP_SETTINGS.BoxColor or ESP_SETTINGS.BoxOutlineColor,
                                        Transparency = 1
                                    })
                                    esp.boxLines[#esp.boxLines + 1] = boxLine
                                end
                            end

                            local lines = esp.boxLines
                            local x, y, w, h = boxPosition.X, boxPosition.Y, boxSize.X, boxSize.Y

                            -- Outline (drawn first, thicker)
                            -- Top left
                            lines[9].From = Vector2.new(x - 1, y - 1)
                            lines[9].To = Vector2.new(x + cornerLength, y - 1)
                            lines[10].From = Vector2.new(x - 1, y - 1)
                            lines[10].To = Vector2.new(x - 1, y + cornerHeight)
                            
                            -- Top right
                            lines[11].From = Vector2.new(x + w - cornerLength, y - 1)
                            lines[11].To = Vector2.new(x + w + 1, y - 1)
                            lines[12].From = Vector2.new(x + w + 1, y - 1)
                            lines[12].To = Vector2.new(x + w + 1, y + cornerHeight)
                            
                            -- Bottom left
                            lines[13].From = Vector2.new(x - 1, y + h - cornerHeight)
                            lines[13].To = Vector2.new(x - 1, y + h + 1)
                            lines[14].From = Vector2.new(x - 1, y + h + 1)
                            lines[14].To = Vector2.new(x + cornerLength, y + h + 1)
                            
                            -- Bottom right
                            lines[15].From = Vector2.new(x + w + 1, y + h - cornerHeight)
                            lines[15].To = Vector2.new(x + w + 1, y + h + 1)
                            lines[16].From = Vector2.new(x + w - cornerLength, y + h + 1)
                            lines[16].To = Vector2.new(x + w + 1, y + h + 1)

                            -- Main corners (colored)
                            -- Top left
                            lines[1].From = Vector2.new(x, y)
                            lines[1].To = Vector2.new(x + cornerLength, y)
                            lines[2].From = Vector2.new(x, y)
                            lines[2].To = Vector2.new(x, y + cornerHeight)
                            
                            -- Top right
                            lines[3].From = Vector2.new(x + w - cornerLength, y)
                            lines[3].To = Vector2.new(x + w, y)
                            lines[4].From = Vector2.new(x + w, y)
                            lines[4].To = Vector2.new(x + w, y + cornerHeight)
                            
                            -- Bottom left
                            lines[5].From = Vector2.new(x, y + h - cornerHeight)
                            lines[5].To = Vector2.new(x, y + h)
                            lines[6].From = Vector2.new(x, y + h)
                            lines[6].To = Vector2.new(x + cornerLength, y + h)
                            
                            -- Bottom right
                            lines[7].From = Vector2.new(x + w, y + h - cornerHeight)
                            lines[7].To = Vector2.new(x + w, y + h)
                            lines[8].From = Vector2.new(x + w - cornerLength, y + h)
                            lines[8].To = Vector2.new(x + w, y + h)

                            -- Update colors and show
                            for i = 1, 8 do
                                lines[i].Color = ESP_SETTINGS.BoxColor
                                lines[i].Thickness = 2
                                lines[i].Visible = true
                            end
                            for i = 9, 16 do
                                lines[i].Color = ESP_SETTINGS.BoxOutlineColor
                                lines[i].Thickness = 4
                                lines[i].Visible = true
                            end
                            
                            esp.box.Visible = false
                            esp.boxOutline.Visible = false
                        end
                    else
                        esp.box.Visible = false
                        esp.boxOutline.Visible = false
                        for _, line in ipairs(esp.boxLines) do
                            line:Remove()
                        end
                        esp.boxLines = {}
                    end

                    if ESP_SETTINGS.ShowHealth then
                        local hp = humanoid.Health
                        local maxHp = humanoid.MaxHealth
                        local healthPercent = math.clamp(hp / maxHp, 0, 1)
                        local barHeight = boxSize.Y * healthPercent
                        
                        -- Background bar
                        esp.healthBackground.From = Vector2.new(boxPosition.X - 5, boxPosition.Y + boxSize.Y)
                        esp.healthBackground.To = Vector2.new(boxPosition.X - 5, boxPosition.Y)
                        esp.healthBackground.Visible = true
                        
                        -- Health bar
                        esp.health.From = Vector2.new(boxPosition.X - 5, boxPosition.Y + boxSize.Y)
                        esp.health.To = Vector2.new(boxPosition.X - 5, boxPosition.Y + boxSize.Y - barHeight)
                        esp.health.Color = ESP_SETTINGS.HealthLowColor:Lerp(ESP_SETTINGS.HealthHighColor, healthPercent)
                        esp.health.Visible = true
                        
                        -- Health outline
                        esp.healthOutline.From = Vector2.new(boxPosition.X - 5, boxPosition.Y + boxSize.Y + 1)
                        esp.healthOutline.To = Vector2.new(boxPosition.X - 5, boxPosition.Y - 1)
                        esp.healthOutline.Visible = true
                        
                        -- Show HP number if damaged
                        if healthPercent < 1 then
                            esp.healthText.Text = tostring(math.floor(hp))
                            esp.healthText.Position = Vector2.new(boxPosition.X - 5, boxPosition.Y + boxSize.Y - barHeight - 12)
                            esp.healthText.Visible = true
                        else
                            esp.healthText.Visible = false
                        end
                    else
                        esp.healthBackground.Visible = false
                        esp.health.Visible = false
                        esp.healthOutline.Visible = false
                        esp.healthText.Visible = false
                    end

                    if ESP_SETTINGS.ShowDistance then
                        local dist = (camera.CFrame.Position - rootPart.Position).Magnitude
                        esp.distance.Text = string.format("[%dm]", math.floor(dist))
                        esp.distance.Position = Vector2.new(boxPosition.X + boxSize.X / 2, boxPosition.Y + boxSize.Y + 2)
                        esp.distance.Color = ESP_SETTINGS.NameColor
                        esp.distance.Visible = true
                    else
                        esp.distance.Visible = false
                    end

                    if ESP_SETTINGS.ShowHeadDot then
                        local headScreenPos = camera:WorldToViewportPoint(head.Position)
                        esp.headDot.Position = Vector2.new(headScreenPos.X, headScreenPos.Y)
                        esp.headDot.Radius = ESP_SETTINGS.HeadDotRadius
                        esp.headDot.Color = ESP_SETTINGS.HeadDotColor
                        esp.headDot.Visible = true
                        
                        esp.headDotOutline.Position = Vector2.new(headScreenPos.X, headScreenPos.Y)
                        esp.headDotOutline.Radius = ESP_SETTINGS.HeadDotRadius + 1
                        esp.headDotOutline.Visible = true
                    else
                        esp.headDot.Visible = false
                        esp.headDotOutline.Visible = false
                    end

                    if ESP_SETTINGS.ShowSkeletons then
                        local currentBones = getBones(character)
                        
                        -- Create skeleton lines if needed
                        if #esp.skeletonLines == 0 then
                            for i, bonePair in ipairs(currentBones) do
                                local line = create("Line", {
                                    Thickness = ESP_SETTINGS.SkeletonsThickness,
                                    Color = ESP_SETTINGS.SkeletonsColor,
                                    Transparency = 1
                                })
                                esp.skeletonLines[i] = {line, bonePair[1], bonePair[2]}
                            end
                        end
                        
                        -- Update skeleton positions
                        for _, lineData in ipairs(esp.skeletonLines) do
                            local line = lineData[1]
                            local bone1Name = lineData[2]
                            local bone2Name = lineData[3]
                            
                            local bone1 = character:FindFirstChild(bone1Name)
                            local bone2 = character:FindFirstChild(bone2Name)
                            
                            if bone1 and bone2 then
                                local pos1, vis1 = camera:WorldToViewportPoint(bone1.Position)
                                local pos2, vis2 = camera:WorldToViewportPoint(bone2.Position)
                                
                                if vis1 and vis2 then
                                    line.From = Vector2.new(pos1.X, pos1.Y)
                                    line.To = Vector2.new(pos2.X, pos2.Y)
                                    line.Color = ESP_SETTINGS.SkeletonsColor
                                    line.Thickness = ESP_SETTINGS.SkeletonsThickness
                                    line.Visible = true
                                else
                                    line.Visible = false
                                end
                            else
                                line.Visible = false
                            end
                        end
                    else
                        -- Hide skeleton lines
                        for _, lineData in ipairs(esp.skeletonLines) do
                            if lineData[1] then
                                lineData[1].Visible = false
                            end
                        end
                    end

                    if ESP_SETTINGS.ShowWeapon then
                        local gunFolder = character:FindFirstChild("Gun")
                        if gunFolder then
                            local gunName = gunFolder:FindFirstChild("GunName")
                            if gunName and gunName:IsA("StringValue") and gunName.Value ~= "" then
                                local weaponYOffset = ESP_SETTINGS.ShowDistance and 15 or 2
                                esp.weapon.Text = gunName.Value
                                esp.weapon.Position = Vector2.new(boxPosition.X + boxSize.X / 2, boxPosition.Y + boxSize.Y + weaponYOffset)
                                esp.weapon.Color = ESP_SETTINGS.WeaponColor
                                esp.weapon.Visible = true
                            else
                                esp.weapon.Visible = false
                            end
                        else
                            esp.weapon.Visible = false
                        end
                    else
                        esp.weapon.Visible = false
                    end

                    if ESP_SETTINGS.ShowTracer then
                        local tracerY
                        if ESP_SETTINGS.TracerPosition == "Top" then
                            tracerY = 0
                        elseif ESP_SETTINGS.TracerPosition == "Middle" then
                            tracerY = camera.ViewportSize.Y / 2
                        else
                            tracerY = camera.ViewportSize.Y
                        end
                        
                        esp.tracer.From = Vector2.new(camera.ViewportSize.X / 2, tracerY)
                        esp.tracer.To = Vector2.new(boxPosition.X + boxSize.X / 2, boxPosition.Y + boxSize.Y)
                        esp.tracer.Color = ESP_SETTINGS.TracerColor
                        esp.tracer.Thickness = ESP_SETTINGS.TracerThickness
                        esp.tracer.Transparency = 1
                        esp.tracer.Visible = true
                    else
                        esp.tracer.Visible = false
                    end
                else
                    hideAllEsp(esp)
                end
            else
                hideAllEsp(esp)
            end
        else
            hideAllEsp(esp)
        end
    end
end

for _, player in ipairs(Players:GetPlayers()) do
    if player ~= localPlayer then
        createEsp(player)
    end
end

Players.PlayerAdded:Connect(function(player)
    if player ~= localPlayer then
        createEsp(player)
    end
end)

Players.PlayerRemoving:Connect(function(player)
    removeEsp(player)
end)

RunService.RenderStepped:Connect(updateEsp)
return ESP_SETTINGS
