local workspace = game:GetService("Workspace")
local players = game:GetService("Players")
local player = players.LocalPlayer

local function getHRP(person)
    if not person then person = player end
    local character = person.Character
    if not character then return nil end
    return character:FindFirstChild("HumanoidRootPart"), character.Name
end

local function getGlove()
    local character = player.Character
    if not character then return nil end
    return character:FindFirstChildWhichIsA("Tool")
end

local function magnitude(v1, v2)
    local diff = v1 - v2
    return math.sqrt(diff.X * diff.X + diff.Y * diff.Y + diff.Z * diff.Z)
end

local function getClosestPlayerHRP()
    local closestHRP
    local lowestDist = math.huge
    local playerName = "None"

    local myhrp = getHRP()
    for _, v in pairs(players:GetPlayers()) do
        if not v then continue end
        local theirhrp, name = getHRP(v)

        if not myhrp or not theirhrp then continue end
        if myhrp.Address == theirhrp.Address then continue end

        local dist = magnitude(myhrp.Position, theirhrp.Position)
        if dist < lowestDist then 
            lowestDist = dist
            closestHRP = theirhrp
            playerName = name
        end
    end
    return closestHRP, playerName, lowestDist
end

-- Settings
local ExtraReach = true
local MaxReachDistance = 25 -- Default max reach distance

-- UI
local vSize = workspace.CurrentCamera.ViewportSize
local statusText = Drawing.new("Text")
statusText.Position = Vector2.new(10, vSize.Y - 60)
statusText.Size = 14
statusText.Color = Color3.fromRGB(128, 255, 128)
statusText.Visible = true
statusText.Outline = true

local toggleButton = Drawing.new("Text")
toggleButton.Position = Vector2.new(10, vSize.Y - 40)
toggleButton.Size = 14
toggleButton.Color = Color3.fromRGB(128, 255, 128)
toggleButton.Visible = true
toggleButton.Text = "[ON]"
toggleButton.Outline = true

-- Slider UI
local sliderText = Drawing.new("Text")
sliderText.Position = Vector2.new(10, vSize.Y - 20)
sliderText.Size = 14
sliderText.Color = Color3.fromRGB(200, 200, 200)
sliderText.Visible = true
sliderText.Text = "Range: 25"
sliderText.Outline = true

local sliderBg = Drawing.new("Square")
sliderBg.Position = Vector2.new(80, vSize.Y - 18)
sliderBg.Size = Vector2.new(100, 10)
sliderBg.Color = Color3.fromRGB(50, 50, 50)
sliderBg.Filled = true
sliderBg.Visible = true

local sliderFill = Drawing.new("Square")
sliderFill.Position = Vector2.new(80, vSize.Y - 18)
sliderFill.Size = Vector2.new(44.4, 10) -- ~middle position for 25
sliderFill.Color = Color3.fromRGB(128, 255, 128)
sliderFill.Filled = true
sliderFill.Visible = true

local function mousewithindrawing(pos, size)
    local mouse = player:GetMouse()
    return mouse.X >= pos.X 
       and mouse.X <= pos.X + size.X
       and mouse.Y >= pos.Y 
       and mouse.Y <= pos.Y + size.Y
end

local function MAIN()
    while true do task.wait()
        local target, name, dist = getClosestPlayerHRP()
        
        statusText.Text = name .. " | " .. (dist and math.floor(dist) or "---")
        
        if ExtraReach then
            local glove = getGlove()
            if glove and target and dist and dist <= MaxReachDistance then
                for _, v in pairs(glove:GetChildren()) do
                    if v.Position then
                        v.Position = target.Position
                    end
                end
            end
        end
    end
end

local draggingSlider = false
local function UI_UPDATE()
    while true do task.wait()
        toggleButton.Color = ExtraReach and Color3.fromRGB(128, 255, 128) or Color3.fromRGB(255, 128, 128)
        toggleButton.Text = ExtraReach and "[ON]" or "[OFF]"
        
        -- Toggle button
        if mousewithindrawing(toggleButton.Position, Vector2.new(50, 14)) and ismouse1pressed() then
            ExtraReach = not ExtraReach
            repeat wait() until not ismouse1pressed()
        end
        
        -- Slider interaction
        local mouse = player:GetMouse()
        if mousewithindrawing(sliderBg.Position, sliderBg.Size) then
            if ismouse1pressed() then
                draggingSlider = true
            end
        end
        
        if not ismouse1pressed() then
            draggingSlider = false
        end
        
        if draggingSlider then
            local relativeX = mouse.X - sliderBg.Position.X
            relativeX = math.clamp(relativeX, 0, sliderBg.Size.X)
            
            -- Map slider position to range 5-50 studs in increments of 5
            -- Values: 5, 10, 15, 20, 25, 30, 35, 40, 45, 50 (10 total values)
            local rawValue = 5 + (relativeX / sliderBg.Size.X) * 45
            MaxReachDistance = math.floor(rawValue / 5) * 5 -- Round to nearest 5
            
            -- Update slider fill to snap to increments
            local snappedX = ((MaxReachDistance - 5) / 45) * sliderBg.Size.X
            sliderFill.Size = Vector2.new(snappedX, 10)
            sliderText.Text = "Range: " .. MaxReachDistance
        end
    end
end

spawn(MAIN)
spawn(UI_UPDATE)
