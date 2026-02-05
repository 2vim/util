-- itemesp.lua
--// Variables
local RunService = game:GetService("RunService")
local camera = workspace.CurrentCamera
local cache = {}

local ITEM_ESP_SETTINGS = {
    Enabled = false,
    
    -- Box settings
    ShowBox = false,
    BoxColor = Color3.fromRGB(255, 255, 102550),
    BoxOutlineColor = Color3.fromRGB(0, 0, 0),
    
    -- Name settings
    ShowName = false,
    NameColor = Color3.fromRGB(255, 255, 255),
    
    -- Distance settings
    ShowDistance = false,
    DistanceColor = Color3.fromRGB(255, 255, 255),
}

local function create(class, properties)
    local drawing = Drawing.new(class)
    for property, value in pairs(properties) do
        drawing[property] = value
    end
    return drawing
end

local function createItemEsp(item, label)
    if cache[item] then return end
    
    local esp = {
        label = label or nil,
        boxOutline = create("Square", {
            Color = ITEM_ESP_SETTINGS.BoxOutlineColor,
            Thickness = 3,
            Filled = false,
            Transparency = 1
        }),
        box = create("Square", {
            Color = ITEM_ESP_SETTINGS.BoxColor,
            Thickness = 1,
            Filled = false,
            Transparency = 1
        }),
        name = create("Text", {
            Color = ITEM_ESP_SETTINGS.NameColor,
            Outline = true,
            Center = true,
            Size = 13,
            Font = Drawing.Fonts.Plex
        }),
        distance = create("Text", {
            Color = ITEM_ESP_SETTINGS.DistanceColor,
            Outline = true,
            Center = true,
            Size = 13,
            Font = Drawing.Fonts.Plex
        }),
    }

    cache[item] = esp
end

local function removeItemEsp(item)
    local esp = cache[item]
    if not esp then return end

    for _, drawing in pairs(esp) do
        if drawing and drawing.Remove then
            drawing:Remove()
        end
    end

    cache[item] = nil
end

local function hideAllItemEsp(esp)
    esp.name.Visible = false
    esp.box.Visible = false
    esp.boxOutline.Visible = false
    esp.distance.Visible = false
end

local function getItemPosition(item)
    if item:IsA("BasePart") then
        return item.Position
    elseif item:IsA("Model") then
        local primary = item.PrimaryPart or item:FindFirstChildWhichIsA("BasePart")
        if primary then
            return primary.Position
        end
    end
    return nil
end

local function getItemSize(item)
    if item:IsA("BasePart") then
        return item.Size
    elseif item:IsA("Model") then
        local primary = item.PrimaryPart or item:FindFirstChildWhichIsA("BasePart")
        if primary then
            return primary.Size
        end
    end
    return Vector3.new(2, 2, 2) -- Default size
end

local function updateItemEsp()
    for item, esp in pairs(cache) do
        if not item or not item.Parent then
            removeItemEsp(item)
            continue
        end
        
        local position = getItemPosition(item)
        
        if position and ITEM_ESP_SETTINGS.Enabled then
            local screenPos, onScreen = camera:WorldToViewportPoint(position)
            
            if onScreen then
                local itemSize = getItemSize(item)
                local distance = (camera.CFrame.Position - position).Magnitude
                
                -- Calculate screen size based on distance
                local scaleFactor = math.clamp(500 / distance, 0.1, 1)
                local boxWidth = math.clamp(itemSize.X * scaleFactor * 20, 5, 40)
                local boxHeight = math.clamp(itemSize.Y * scaleFactor * 20, 5, 40)
                
                local boxSize = Vector2.new(math.floor(boxWidth), math.floor(boxHeight))
                local boxPosition = Vector2.new(
                    math.floor(screenPos.X - boxWidth / 2),
                    math.floor(screenPos.Y - boxHeight / 2)
                )
                
                if ITEM_ESP_SETTINGS.ShowName then
                    esp.name.Visible = true
                    local displayText = item.Name
                    if esp.label then
                        displayText = displayText .. " [" .. esp.label .. "]"
                    end
                    esp.name.Text = displayText
                    esp.name.Position = Vector2.new(boxPosition.X + boxSize.X / 2, boxPosition.Y - 15)
                    esp.name.Color = ITEM_ESP_SETTINGS.NameColor
                else
                    esp.name.Visible = false
                end
                
                if ITEM_ESP_SETTINGS.ShowBox then
                    esp.boxOutline.Size = boxSize
                    esp.boxOutline.Position = boxPosition
                    esp.box.Size = boxSize
                    esp.box.Position = boxPosition
                    esp.box.Color = ITEM_ESP_SETTINGS.BoxColor
                    esp.box.Visible = true
                    esp.boxOutline.Visible = true
                else
                    esp.box.Visible = false
                    esp.boxOutline.Visible = false
                end
                
                if ITEM_ESP_SETTINGS.ShowDistance then
                    esp.distance.Text = string.format("[%dm]", math.floor(distance))
                    esp.distance.Position = Vector2.new(boxPosition.X + boxSize.X / 2, boxPosition.Y + boxSize.Y + 2)
                    esp.distance.Color = ITEM_ESP_SETTINGS.DistanceColor
                    esp.distance.Visible = true
                else
                    esp.distance.Visible = false
                end
            else
                hideAllItemEsp(esp)
            end
        else
            hideAllItemEsp(esp)
        end
    end
end

local function addItems(items, label)
    for _, item in ipairs(items) do
        if typeof(item) == "table" then
            -- Format: {item, "LABEL"}
            local obj = item[1]
            local itemLabel = item[2]
            if obj and (obj:IsA("BasePart") or obj:IsA("Model")) then
                createItemEsp(obj, itemLabel)
            end
        elseif item:IsA("BasePart") or item:IsA("Model") then
            createItemEsp(item, label)
        end
    end
end

-- Function to clear all tracked items
local function clearAll()
    for item, _ in pairs(cache) do
        removeItemEsp(item)
    end
end

RunService.RenderStepped:Connect(updateItemEsp)

-- Return settings and helper functions
return {
    Settings = ITEM_ESP_SETTINGS,
    AddItems = addItems,
    AddItem = createItemEsp,
    RemoveItem = removeItemEsp,
    ClearAll = clearAll,
}
