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
local keybindPressed = false

-- UI
local vSize = workspace.CurrentCamera.ViewportSize
local statusText = Drawing.new("Text")
statusText.Position = Vector2.new(10, vSize.Y - 40)
statusText.Size = 14
statusText.Color = Color3.fromRGB(128, 255, 128)
statusText.Visible = true
statusText.Outline = true

local toggleButton = Drawing.new("Text")
toggleButton.Position = Vector2.new(10, vSize.Y - 20)
toggleButton.Size = 14
toggleButton.Color = Color3.fromRGB(128, 255, 128)
toggleButton.Visible = true
toggleButton.Text = "[ON] ]"
toggleButton.Outline = true

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
        
        -- Keybind check with GetAsyncKeyState (] key = 0xDD)
        if GetAsyncKeyState then
            local keyState = GetAsyncKeyState(0xDD)
            if keyState == 1 or keyState == -32767 then
                if not keybindPressed then
                    keybindPressed = true
                    ExtraReach = not ExtraReach
                end
            else
                keybindPressed = false
            end
        end
        
        if ExtraReach then
            local glove = getGlove()
            if glove and target then
                for _, v in pairs(glove:GetChildren()) do
                    if v.Position then
                        v.Position = target.Position
                    end
                end
            end
        end
    end
end

local function UI_UPDATE()
    while true do task.wait()
        toggleButton.Color = ExtraReach and Color3.fromRGB(128, 255, 128) or Color3.fromRGB(255, 128, 128)
        toggleButton.Text = ExtraReach and "[ON] ]" or "[OFF] ]"
        
        if mousewithindrawing(toggleButton.Position, Vector2.new(60, 14)) and ismouse1pressed() then
            ExtraReach = not ExtraReach
            repeat wait() until not ismouse1pressed()
        end
    end
end

spawn(MAIN)
spawn(UI_UPDATE)
