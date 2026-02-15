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
    if not myhrp then return nil, "None", math.huge end
    
    for _, v in pairs(players:GetPlayers()) do
        if not v then continue end
        local theirhrp, name = getHRP(v)

        if not theirhrp then continue end
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
local MaxReachDistance = 40

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

local sliderText = Drawing.new("Text")
sliderText.Position = Vector2.new(10, vSize.Y - 20)
sliderText.Size = 14
sliderText.Color = Color3.fromRGB(200, 200, 200)
sliderText.Visible = true
sliderText.Text = "Range: 40"
sliderText.Outline = true

local sliderBg = Drawing.new("Square")
sliderBg.Position = Vector2.new(80, vSize.Y - 18)
sliderBg.Size = Vector2.new(100, 10)
sliderBg.Color = Color3.fromRGB(50, 50, 50)
sliderBg.Filled = true
sliderBg.Visible = true

local sliderFill = Drawing.new("Square")
sliderFill.Position = Vector2.new(80, vSize.Y - 18)
sliderFill.Size = Vector2.new(46.7, 10)
sliderFill.Color = Color3.fromRGB(128, 255, 128)
sliderFill.Filled = true
sliderFill.Visible = true

local function mousewithindrawing(pos, size)
    local mouse = player:GetMouse()
    if not mouse then return false end
    return mouse.X >= pos.X 
       and mouse.X <= pos.X + size.X
       and mouse.Y >= pos.Y 
       and mouse.Y <= pos.Y + size.Y
end

local function MAIN()
    while true do 
        task.wait(0.05) -- Reduced frequency to prevent crashing
        
        pcall(function() -- Wrap in pcall to catch errors
            local target, name, dist = getClosestPlayerHRP()
            
            statusText.Text = name .. " | " .. (dist and dist ~= math.huge and math.floor(dist) or "---")
            
            if ExtraReach and target and dist and dist <= MaxReachDistance then
                local glove = getGlove()
                if glove then
                    for _, v in pairs(glove:GetChildren()) do
                        if v:IsA("BasePart") and v.Position then
                            v.Position = target.Position
                        end
                    end
                end
            end
        end)
    end
end

local draggingSlider = false
local lastUpdate = tick()
local function UI_UPDATE()
    while true do 
        task.wait(0.05) -- Reduced frequency
        
        pcall(function() -- Wrap in pcall to catch errors
            local currentTime = tick()
            
            -- Only update colors if enough time has passed
            if currentTime - lastUpdate >= 0.1 then
                toggleButton.Color = ExtraReach and Color3.fromRGB(128, 255, 128) or Color3.fromRGB(255, 128, 128)
                toggleButton.Text = ExtraReach and "[ON]" or "[OFF]"
                lastUpdate = currentTime
            end
            
            -- Toggle button
            if mousewithindrawing(toggleButton.Position, Vector2.new(50, 14)) and ismouse1pressed() then
                ExtraReach = not ExtraReach
                repeat task.wait() until not ismouse1pressed()
            end
            
            -- Slider interaction
            local mouse = player:GetMouse()
            if not mouse then return end
            
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
                
                local rawValue = 5 + (relativeX / sliderBg.Size.X) * 75
                MaxReachDistance = math.floor(rawValue / 5) * 5
                
                local snappedX = ((MaxReachDistance - 5) / 75) * sliderBg.Size.X
                sliderFill.Size = Vector2.new(snappedX, 10)
                sliderText.Text = "Range: " .. MaxReachDistance
            end
        end)
    end
end

spawn(MAIN)
spawn(UI_UPDATE)
