setfpscap(32555555555555555)
local Config = {
    Box = {
        Enabled = false,
        Color = Color3.fromRGB(255, 255, 255),
        Filled = {
            Enabled = false,
            Gradient = {
                Enabled = true,
                Color1 = Color3.fromRGB(255, 255, 255),
                Color2 = Color3.fromRGB(255, 255, 255),
                Color3 = Color3.fromRGB(255, 255, 255),
                Rotation = {
                    Amount = 1,
                    Moving = {
                    	Enabled = false,
                        Speed = 300
                    }
                }
            }
        }
    },
    Text = {
        Font = "Minecraftia",
        Name = {
            Enabled = false,
            Color = Color3.fromRGB(255, 255, 255),
            Type = "DisplayName",
            Casing = "lowercase"
        },
        Weapon = {
            Enabled = false,
            Color = Color3.fromRGB(255, 255, 255),
            Casing = "lowercase"
        },
        Distance = {
            Enabled = false,
            Color = Color3.fromRGB(255, 255, 255),
            Casing = "lowercase"
        }
    },
    Bars = {
        Resize = false,
        Width = 2.5,
        Lerp = 0.05,
        Type = "Gradient",
        Health = {
            Enabled = false,
            Color1 = Color3.fromRGB(0, 255, 0),
            Color2 = Color3.fromRGB(255, 255, 0),
            Color3 = Color3.fromRGB(255, 0, 0)
        },
        Armor = {
            Enabled = false,
            Color1 = Color3.fromRGB(0, 0, 255),
            Color2 = Color3.fromRGB(135, 206, 235),
            Color3 = Color3.fromRGB(1, 0, 0),
            Armored = false
        }
    },
    Material = {
        Enabled = false,
        Color = Color3.fromRGB(255, 255, 255),
        Material = Enum.Material.ForceField
    },
    Highlight = {
        Enabled = false,
        BehindWalls = false,
        Color = Color3.fromRGB(255, 255, 255),
        Outline = Color3.fromRGB(0, 0, 0)
    },
    Chams = {
        Enabled = false,
        BehindWalls = false,
        Color = Color3.fromRGB(255, 255, 255)
    }
}

if not LPH_OBFUSCATED then
    LPH_JIT_MAX = function(...)
        return (...)
    end

    LPH_NO_VIRTUALIZE = function(...)
        return (...)
    end
end

local Overlay = {}
local draw = nil

local Overlay
Config = Config
Drawing = Drawing

local gui_inset = game:GetService("GuiService"):GetGuiInset()
local rotation_angle, okazaki_tickling_ushio = -45, tick()

local utility, connections, cache = {}, {}, {}
utility.funcs = utility.funcs or {}
local originalStates = {}
local increase = Vector3.new(2, 2, 2)
local vertices = { { -0.5, -0.5, -0.5 }, { -0.5, 0.5, -0.5 }, { 0.5, -0.5, -0.5 }, { 0.5, 0.5, -0.5 },{ -0.5, -0.5, 0.5 }, { -0.5, 0.5, 0.5 }, { 0.5, -0.5, 0.5 }, { 0.5, 0.5, 0.5 } };

local fonts = {
    { ttf = "Proggy.ttf", json = "Proggy.json", url = "https://raw.githubusercontent.com/OxygenClub/Random-LUAS/main/Proggy.txt", name = "Proggy" },
    { ttf = "Minecraftia.ttf", json = "Minecraftia.json", url = "https://raw.githubusercontent.com/OxygenClub/Random-LUAS/main/Minecraftia.txt", name = "Minecraftia" },
    { ttf = "SmallestPixel7.ttf", json = "SmallestPixel7.json", url = "https://raw.githubusercontent.com/OxygenClub/Random-LUAS/main/Smallest%20Pixel.txt", name = "SmallestPixel7" },
    { ttf = "Verdana.ttf", json = "Verdana.json", url = "https://raw.githubusercontent.com/OxygenClub/Random-LUAS/main/Verdana.txt", name = "Verdana" },
    { ttf = "VerdanaBold.ttf", json = "VerdanaBold.json", url = "https://raw.githubusercontent.com/OxygenClub/Random-LUAS/main/Verdana%20Bold.txt", name = "VerdanaBold" },
    { ttf = "Tahoma.ttf", json = "Tahoma.json", url = "https://raw.githubusercontent.com/OxygenClub/Random-LUAS/main/Tahoma.txt", name = "Tahoma" },
    { ttf = "TahomaBold.ttf", json = "TahomaBold.json", url = "https://raw.githubusercontent.com/OxygenClub/Random-LUAS/main/Tahoma%20Bold.txt", name = "TahomaBold" }
}

for _, font in fonts do
    if not isfile(font.ttf) then
        writefile(font.ttf, base64_decode(game:HttpGet(font.url)))
    end

    if not isfile(font.json) then
        local fontConfig = {
            name = font.name,
            faces = {
                {
                    name = "Regular",
                    weight = 200,
                    style = "normal",
                    assetId = getcustomasset(font.ttf)
                }
            }
        }
        writefile(font.json, game:GetService("HttpService"):JSONEncode(fontConfig))
    end
end

local DrawingFontsEnum = {
    [0] = Font.new(getcustomasset("Verdana.json"), Enum.FontWeight.Regular),
    [1] = Font.new(getcustomasset("SmallestPixel7.json"), Enum.FontWeight.Regular),
    [2] = Font.new(getcustomasset("Proggy.json"), Enum.FontWeight.Regular),
    [3] = Font.new(getcustomasset("Minecraftia.json"), Enum.FontWeight.Regular),
    [4] = Font.new(getcustomasset("VerdanaBold.json"), Enum.FontWeight.Regular),
    [5] = Font.new(getcustomasset("Tahoma.json"), Enum.FontWeight.Regular),
    [6] = Font.new(getcustomasset("TahomaBold.json"), Enum.FontWeight.Regular)
}

function GetFontFromIndex(fontIndex)
    return DrawingFontsEnum[fontIndex]
end

local Fonts = {
    ["Verdana"] = 0,
    ["Smallest Pixel-7"] = 1,
    ["Proggy"] = 2,
    ["Minecraftia"] = 3,
    ["Verdana Bold"] = 4,
    ["Tahoma"] = 5,
    ["Tahoma Bold"] = 6
}

utility.funcs.custom_bounds = function(model)
    local min_bound, max_bound = Vector3.new(math.huge, math.huge, math.huge), Vector3.new(-math.huge, -math.huge, -math.huge)
        
    for _, part in ipairs(model:GetChildren()) do
        if part:IsA("BasePart") then
            local cframe, size = part.CFrame, part.Size
            for _, v in ipairs(vertices) do
                local world_space = cframe:PointToWorldSpace(Vector3.new(v[1] * size.X, (v[2] + 0.2) * (size.Y + 0.2), v[3] * size.Z))
                min_bound = Vector3.new(math.min(min_bound.X, world_space.X), math.min(min_bound.Y, world_space.Y), math.min(min_bound.Z, world_space.Z))
                max_bound = Vector3.new(math.max(max_bound.X, world_space.X), math.max(max_bound.Y, world_space.Y), math.max(max_bound.Z, world_space.Z))
            end
        end
    end
        
    if min_bound == Vector3.new(math.huge, math.huge, math.huge) then return end
    local center = (min_bound + max_bound) / 2
    return CFrame.new(center), max_bound - min_bound + increase, center
end  

utility.funcs.get_case = function(text, casetype)
    casetype = casetype or "lowercase"
    
    if casetype == "UPPERCASE" then
        return text:upper()
    elseif casetype == "lowercase" then
        return text:lower()
    else
        return text
    end
end

utility.funcs.make_text = function(p)
    local d = Instance.new("TextLabel")
    d.Parent = p
    d.Size = UDim2.new(0, 4, 0, 4)
    d.BackgroundTransparency = 1
    d.TextColor3 = Color3.fromRGB(255, 255, 255)
    d.TextStrokeTransparency = 0
    d.TextScaled = false
    d.TextSize = 10
    d.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    d.FontFace = GetFontFromIndex(Fonts[Config.Text.Font])
    d.Text = ""
    return d
end

utility.funcs.render =
    LPH_NO_VIRTUALIZE(
    function(player)
        if not player then
            return
        end

        cache[player] = cache[player] or {}
        cache[player].Box = {}
        cache[player].Bars = {}
        cache[player].Text = {}
        cache[player].Box.Full = {
            Square = Drawing.new("Square"),
            Inline = Drawing.new("Square"),
            Outline = Drawing.new("Square"),
            Filled = Instance.new("Frame", Instance.new("ScreenGui", game.CoreGui))
        }

        local Distance = Instance.new("ScreenGui")
        Distance.Parent = game.CoreGui
        
        local Name = Instance.new("ScreenGui")
        Name.Parent = game.CoreGui
        
        local Weapon = Instance.new("ScreenGui")
        Weapon.Parent = game.CoreGui
        
        cache[player].Text.Distance = utility.funcs.make_text(Distance)
        cache[player].Text.Weapon = utility.funcs.make_text(Weapon)
        cache[player].Text.Name = utility.funcs.make_text(Name)

        local armorGui = Instance.new("ScreenGui")
        armorGui.Name = player.Name .. "_ArmorBar"
        armorGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
        armorGui.Parent = game.CoreGui
        local armorOutline = Instance.new("Frame")
        armorOutline.BackgroundColor3 = Color3.new(0, 0, 0)
        armorOutline.BorderSizePixel = 0
        armorOutline.Name = "Outline"
        armorOutline.Parent = armorGui
        
        local armorFill = Instance.new("Frame")
        armorFill.BackgroundTransparency = 0
        armorFill.BorderSizePixel = 0
        armorFill.Name = "Fill"
        armorFill.Parent = armorOutline
        local armorGradient = Instance.new("UIGradient", armorFill)
        armorGradient.Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Config.Bars.Armor.Color1),
            ColorSequenceKeypoint.new(0.5, Config.Bars.Armor.Color2),
            ColorSequenceKeypoint.new(1, Config.Bars.Armor.Color3)
        })
        armorGradient.Rotation = 90

        cache[player].Bars.Armor = {
            Gui = armorGui,
            Outline = armorOutline,
            Frame = armorFill,
            Gradient = armorGradient,
            Tick = tick(),
            Rotation = 90
        }

        local healthGui = Instance.new("ScreenGui")
        healthGui.Name = player.Name .. "_HealthBar"
        healthGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
        healthGui.Parent = game.CoreGui
        local healthOutline = Instance.new("Frame")
        healthOutline.BackgroundColor3 = Color3.new(0, 0, 0)
        healthOutline.BorderSizePixel = 0
        healthOutline.Name = "Outline"
        healthOutline.Parent = healthGui

        local healthFill = Instance.new("Frame")
        healthFill.BackgroundTransparency = 0
        healthFill.BorderSizePixel = 0
        healthFill.Name = "Fill"
        healthFill.Parent = healthOutline
        
        local healthGradient = Instance.new("UIGradient", healthFill)
        healthGradient.Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Config.Bars.Health.Color1),
            ColorSequenceKeypoint.new(0.5, Config.Bars.Health.Color2),
            ColorSequenceKeypoint.new(1, Config.Bars.Health.Color3)
        })
        healthGradient.Rotation = 90

        cache[player].Bars.Health = {
            Gui = healthGui,
            Outline = healthOutline,
            Frame = healthFill,
            Gradient = healthGradient,
            Tick = tick(),
            Rotation = 90
        }
    end
)

utility.funcs.clear_esp =
    LPH_NO_VIRTUALIZE(
    function(player)
        if not cache[player] then
            return
        end

        if cache[player].Box and cache[player].Box.Full then
            cache[player].Box.Full.Square.Visible = false
            cache[player].Box.Full.Outline.Visible = false
            cache[player].Box.Full.Inline.Visible = false
            if cache[player].Box.Full.Filled then
                cache[player].Box.Full.Filled.Visible = false
            end
        end

        if cache[player].Text then
            if cache[player].Text.Distance then
                cache[player].Text.Distance.Visible = false
            end
            if cache[player].Text.Weapon then
                cache[player].Text.Weapon.Visible = false
            end
            if cache[player].Text.Name then
                cache[player].Text.Name.Visible = false
            end
        end

        if cache[player].Bars then
            if cache[player].Bars.Health and cache[player].Bars.Health.Frame then
                cache[player].Bars.Health.Frame.Visible = false
                cache[player].Bars.Health.Outline.Visible = false
            end

            if cache[player].Bars.Armor and cache[player].Bars.Armor.Frame then
                cache[player].Bars.Armor.Frame.Visible = false
                cache[player].Bars.Armor.Outline.Visible = false
            end
        end
    end
)

utility.funcs.update = 
    LPH_NO_VIRTUALIZE(
    function(player)
        if not player or not cache[player] then return end

        local character = player.Character
        local client_character = game.Players.LocalPlayer.Character
        local Camera = workspace.CurrentCamera

        if not character or not client_character then return end

        local rootPart = character:FindFirstChild("HumanoidRootPart")
        local humanoid = character:FindFirstChildWhichIsA("Humanoid")
        if not rootPart or not humanoid then
            utility.funcs.clear_esp(player)
            return
        end

        local cframe, size3d, center = utility.funcs.custom_bounds(character)
        if not cframe then
            utility.funcs.clear_esp(player)
            return
        end

        local screen_pos, on_screen = Camera:WorldToViewportPoint(center)
        if not on_screen then
            utility.funcs.clear_esp(player)
            return
        end

        local distance = (Camera.CFrame.Position - center).Magnitude
        local height = math.tan(math.rad(Camera.FieldOfView / 2)) * 2 * distance
        local scale = Vector2.new((Camera.ViewportSize.Y / height) * size3d.X,(Camera.ViewportSize.Y / height) * size3d.Y)
        local position = Vector2.new(screen_pos.X - scale.X / 2, screen_pos.Y - scale.Y / 2)

        local playerCache = cache[player]
        local fullBox = playerCache.Box.Full
        local square, outline, inline, filled = fullBox.Square, fullBox.Outline, fullBox.Inline, fullBox.Filled

        if Config.Box.Enabled then
            square.Visible = true
            square.Position = position
            square.Size = scale
            square.Color = Config.Box.Color
            square.Thickness = 2
            square.Filled = false
            square.ZIndex = 9e9

            outline.Visible = true
            outline.Position = position - Vector2.new(1, 1)
            outline.Size = scale + Vector2.new(2, 2)
            outline.Color = Color3.new(0, 0, 0)
            outline.Thickness = 1
            outline.Filled = false

            inline.Visible = true
            inline.Position = position + Vector2.new(1, 1)
            inline.Size = scale - Vector2.new(2, 2)
            inline.Color = Color3.new(0, 0, 0)
            inline.Thickness = 1
            inline.Filled = false

    if Config.Box.Filled.Enabled and filled then
        filled.Position = UDim2.new(0, position.X, 0, position.Y - gui_inset.Y)
        filled.Size = UDim2.new(0, scale.X, 0, scale.Y)
        filled.BackgroundTransparency = Config.Box.Filled.Transparency or 0.5
        filled.BackgroundColor3 = Config.Box.Filled.Color or Config.Box.Filled.Gradient.Color1 or Color3.fromRGB(255,255,255)
        filled.Visible = true
        filled.ZIndex = 1

        if Config.Box.Filled.Gradient.Enabled then
                    local gradient = filled:FindFirstChild("Gradient") or Instance.new("UIGradient")
                    gradient.Name = "Gradient"
                    gradient.Color = ColorSequence.new({
                        ColorSequenceKeypoint.new(0, Config.Box.Filled.Gradient.Color1),
                        ColorSequenceKeypoint.new(0.5, Config.Box.Filled.Gradient.Color2),
                        ColorSequenceKeypoint.new(1, Config.Box.Filled.Gradient.Color3)
                    })
                    rotation_angle = rotation_angle + (tick() - okazaki_tickling_ushio) * Config.Box.Filled.Gradient.Rotation.Moving.Speed * math.cos(math.pi / 4 * tick() - math.pi / 2)
                    if Config.Box.Filled.Gradient.Rotation.Moving.Enabled then
                        gradient.Rotation = rotation_angle
                    else
                        gradient.Rotation = Config.Box.Filled.Gradient.Rotation.Amount
                    end
                    okazaki_tickling_ushio = tick()
                    if not gradient.Parent then
                        gradient.Parent = filled
                    end
                end
            elseif filled then
                filled.Visible = false
            end
        else
            square.Visible = false
            outline.Visible = false
            inline.Visible = false
            if filled then filled.Visible = false end
        end
        
        local bar_height = scale.Y
        local bar_width = Config.Bars.Width
        local base_x = position.X
        local y = position.Y - gui_inset.Y
        
        local healthBarVisible = false
        local armorBarVisible = false
        
        if Config.Bars.Health.Enabled and humanoid then
            local targetHealth = math.clamp(humanoid.Health / humanoid.MaxHealth, 0, 1)
            local lastHealth = playerCache.Bars.Health.LastHealth or targetHealth
            local lerpedHealth = lastHealth + (targetHealth - lastHealth) * Config.Bars.Lerp
            playerCache.Bars.Health.LastHealth = lerpedHealth
            
            local x = base_x - (bar_width + 4)
            local outline = playerCache.Bars.Health.Outline
            local fill = playerCache.Bars.Health.Frame
        
            if outline and fill then
                healthBarVisible = true
                outline.Visible = true
                
                if Config.Bars.Resize then
                    local currentBarHeight = math.max(bar_height * lerpedHealth, 2)
                    outline.Position = UDim2.new(0, x - 1, 0, y + bar_height - currentBarHeight - 1)
                    outline.Size = UDim2.new(0, bar_width + 2, 0, currentBarHeight + 2)
                    
                    fill.Visible = true
                    fill.Position = UDim2.new(0, 1, 0, 1)
                    fill.Size = UDim2.new(0, bar_width, 0, currentBarHeight)
                else
                    outline.Position = UDim2.new(0, x - 1, 0, y - 1)
                    outline.Size = UDim2.new(0, bar_width + 2, 0, bar_height + 2)
                    
                    fill.Visible = true
                    fill.Position = UDim2.new(0, 1, 0, (1 - lerpedHealth) * bar_height + 1)
                    fill.Size = UDim2.new(0, bar_width, 0, lerpedHealth * bar_height)
                end
                
                outline.BackgroundTransparency = 0.2
                
                if playerCache.Bars.Health.Gradient then
                    if Config.Bars.Type == "Gradient" then
                        playerCache.Bars.Health.Gradient.Color = ColorSequence.new({
                            ColorSequenceKeypoint.new(0, Config.Bars.Health.Color1),
                            ColorSequenceKeypoint.new(0.5, Config.Bars.Health.Color2),
                            ColorSequenceKeypoint.new(1, Config.Bars.Health.Color3)
                        })
                    elseif Config.Bars.Type == "Solid Color" then
                        playerCache.Bars.Health.Gradient.Color = ColorSequence.new(Config.Bars.Health.Color1)
                    end
                end
            end
        else
            if playerCache.Bars.Health.Outline then playerCache.Bars.Health.Outline.Visible = false end
            if playerCache.Bars.Health.Frame then playerCache.Bars.Health.Frame.Visible = false end
        end
        
        if Config.Bars.Armor.Enabled and character then
            local bodyEffects = character:FindFirstChild("BodyEffects")
            local values = bodyEffects and bodyEffects:FindFirstChild("Armor")
            local armorValue = values and values.Value or 0
            local targetArmor = math.clamp(armorValue / 130, 0, 1)
            
            local shouldShowArmor = true
            if Config.Bars.Armor.Armored then
                shouldShowArmor = armorValue > 0
            end
            
            if shouldShowArmor then
                local lastArmor = playerCache.Bars.Armor.LastArmor or targetArmor
                local lerpedArmor = lastArmor + (targetArmor - lastArmor) * Config.Bars.Lerp
                playerCache.Bars.Armor.LastArmor = lerpedArmor
                
                local x
                if healthBarVisible then
                    x = base_x - (bar_width * 2 + 6 + 2)
                else
                    x = base_x - (bar_width + 4)
                end
                
                local outline = playerCache.Bars.Armor.Outline
                local fill = playerCache.Bars.Armor.Frame
                
                if outline and fill then
                    armorBarVisible = true
                    outline.Visible = true
                    
                    if Config.Bars.Resize then
                        local currentBarHeight = math.max(bar_height * lerpedArmor, 2)
                        outline.Position = UDim2.new(0, x - 1, 0, y + bar_height - currentBarHeight - 1)
                        outline.Size = UDim2.new(0, bar_width + 2, 0, currentBarHeight + 2)
                        
                        fill.Visible = true
                        fill.Position = UDim2.new(0, 1, 0, 1)
                        fill.Size = UDim2.new(0, bar_width, 0, currentBarHeight)
                    else
                        outline.Position = UDim2.new(0, x - 1, 0, y - 1)
                        outline.Size = UDim2.new(0, bar_width + 2, 0, bar_height + 2)
                        
                        fill.Visible = true
                        fill.Position = UDim2.new(0, 1, 0, (1 - lerpedArmor) * bar_height + 1)
                        fill.Size = UDim2.new(0, bar_width, 0, lerpedArmor * bar_height)
                    end
                    
                    outline.BackgroundTransparency = 0.2
                    
                    if playerCache.Bars.Armor.Gradient then
                        if Config.Bars.Type == "Gradient" then
                            playerCache.Bars.Armor.Gradient.Color = ColorSequence.new({
                                ColorSequenceKeypoint.new(0, Config.Bars.Armor.Color1),
                                ColorSequenceKeypoint.new(0.5, Config.Bars.Armor.Color2),
                                ColorSequenceKeypoint.new(1, Config.Bars.Armor.Color3)
                            })
                        elseif Config.Bars.Type == "Solid Color" then
                            playerCache.Bars.Armor.Gradient.Color = ColorSequence.new(Config.Bars.Armor.Color1)
                        end
                    end
                end
            else
                if playerCache.Bars.Armor.Outline then playerCache.Bars.Armor.Outline.Visible = false end
                if playerCache.Bars.Armor.Frame then playerCache.Bars.Armor.Frame.Visible = false end
            end
        else
            if playerCache.Bars.Armor.Outline then playerCache.Bars.Armor.Outline.Visible = false end
            if playerCache.Bars.Armor.Frame then playerCache.Bars.Armor.Frame.Visible = false end
        end
        
        local nameLabel = playerCache.Text.Name
        local weaponLabel = playerCache.Text.Weapon
        local distanceLabel = playerCache.Text.Distance
        local textOffset = 15
        local baseX = position.X + (scale.X / 2)
        local baseY = position.Y - gui_inset.Y
        
        if Config.Text.Name.Enabled then
            nameLabel.Visible = true
            nameLabel.Position = UDim2.new(0, baseX - (nameLabel.AbsoluteSize.X / 2), 0, baseY - textOffset + 6)
            nameLabel.TextColor3 = Config.Text.Name.Color
            nameLabel.FontFace = GetFontFromIndex(Fonts[Config.Text.Font])
            if Config.Text.Name.Type == "DisplayName" then
                nameLabel.Text = utility.funcs.get_case(player.DisplayName, Config.Text.Name.Casing)
            else
                nameLabel.Text = utility.funcs.get_case(player.Name, Config.Text.Name.Casing)
            end
        else
            nameLabel.Visible = false
        end
        
        local bottomTextOffset = 5
        local distanceYOffset = baseY + scale.Y + bottomTextOffset
        
        if Config.Text.Weapon.Enabled then
            weaponLabel.Visible = true
            weaponLabel.Position = UDim2.new(0, baseX - (weaponLabel.AbsoluteSize.X / 2), 0, distanceYOffset)
            weaponLabel.TextColor3 = Config.Text.Weapon.Color
            weaponLabel.FontFace = GetFontFromIndex(Fonts[Config.Text.Font])
            local Weapon = player.Character:FindFirstChildOfClass("Tool")
            weaponLabel.Text = utility.funcs.get_case((Weapon and Weapon.Name) or "None", Config.Text.Weapon.Casing)
            
            distanceYOffset = distanceYOffset + 12
        else
            weaponLabel.Visible = false
        end
        
        if Config.Text.Distance.Enabled then
            distanceLabel.Visible = true
            distanceLabel.Position = UDim2.new(0, baseX - (distanceLabel.AbsoluteSize.X / 2), 0, distanceYOffset)
            distanceLabel.TextColor3 = Config.Text.Distance.Color
            distanceLabel.FontFace = GetFontFromIndex(Fonts[Config.Text.Font])
            distanceLabel.Text = utility.funcs.get_case(string.format("[%.0fM]", distance * 0.28), Config.Text.Distance.Casing)
        else
            distanceLabel.Visible = false
        end
    end
)

for _, player in ipairs(game:GetService("Players"):GetPlayers()) do
    if player ~= game.Players.LocalPlayer then
        utility.funcs.render(player)
    end
end

game:GetService("Players").PlayerAdded:Connect(
    function(player)
        if player ~= game.Players.LocalPlayer then
            utility.funcs.render(player)
        end
    end
)

game:GetService("Players").PlayerRemoving:Connect(
    function(player)
        if player ~= game.Players.LocalPlayer then
            utility.funcs.clear_esp(player)
        end
    end
)

task.spawn(function()
    while true do
        task.wait(1)
        
        for _, player in ipairs(game:GetService("Players"):GetPlayers()) do
            if player ~= game.Players.LocalPlayer and player.Character then
                for _, obj in ipairs(player.Character:GetDescendants()) do
                    if obj:IsA("BasePart") and obj.Name ~= "HumanoidRootPart" and obj.Name ~= "CUFF" then
                        if Config.Material.Enabled then
                            obj.Material = Config.Material.Material
                            obj.Color = Config.Material.Color
                            if obj:IsA("MeshPart") then
                                obj.TextureID = ""
                            end
                        else
                            if not originalStates[obj] then
                                originalStates[obj] = {Material = obj.Material, Color = obj.Color, TextureID = obj:IsA("MeshPart") and obj.TextureID or nil}
                            end
                            obj.Material = originalStates[obj].Material
                            obj.Color = originalStates[obj].Color
                            if obj:IsA("MeshPart") then
                                obj.TextureID = originalStates[obj].TextureID or ""
                            end
                        end
                    elseif obj:IsA("SpecialMesh") then
                        if Config.Material.Enabled then
                            obj.TextureId = ""
                        else
                            obj.TextureId = ""
                        end
                    elseif obj:IsA("Decal") and obj.Name == "face" then
                        if Config.Material.Enabled then
                            obj:Destroy()
                        end
                    end
                end
            
                for _, className in ipairs({"Pants", "Shirt", "ShirtGraphic"}) do
                    local clothing = player.Character:FindFirstChildOfClass(className)
                    if clothing then
                        if Config.Material.Enabled then
                            clothing:Destroy()
                        end
                    end
                end
                
                if Config.Chams.Enabled then
                    for _, part in ipairs(player.Character:GetChildren()) do
                        if part:IsA("BasePart") and part.Transparency ~= 1 and part.Name ~= "HumanoidRootPart" then
                            local chamsBox = part:FindFirstChild("Chams")
                            if not chamsBox then
                                chamsBox = Instance.new("BoxHandleAdornment")
                                chamsBox.Name = "Chams"
                                chamsBox.ZIndex = 4
                                chamsBox.Adornee = part
                                chamsBox.Size = part.Size + Vector3.new(0.02, 0.02, 0.02)
                                chamsBox.Parent = part
                            end
                            chamsBox.AlwaysOnTop = Config.Chams.BehindWalls
                            chamsBox.Color3 = Config.Chams.Color
                            chamsBox.Transparency = 0.5
                            
                            local glowBox = part:FindFirstChild("Glow")
                            if not glowBox then
                                glowBox = Instance.new("BoxHandleAdornment")
                                glowBox.Name = "Glow"
                                glowBox.AlwaysOnTop = false
                                glowBox.ZIndex = 3
                                glowBox.Adornee = part
                                glowBox.Transparency = 0.5
                                glowBox.Size = part.Size + Vector3.new(0.13, 0.13, 0.13)
                                glowBox.Parent = part
                            end
                            glowBox.Color3 = Config.Chams.Color
                        end
                    end
                else
                    for _, v in ipairs(player.Character:GetChildren()) do
                        if v:IsA("BasePart") and v.Transparency ~= 1 then
                            if v:FindFirstChild("Glow") then
                                v.Glow:Destroy()
                            end
                            if v:FindFirstChild("Chams") then
                                v.Chams:Destroy()
                            end
                        end
                    end
                end
            
                local highlight = player.Character:FindFirstChildOfClass("Highlight")
                if Config.Highlight.Enabled then
                    if not highlight then
                        highlight = Instance.new("Highlight")
                        highlight.Parent = player.Character
                    end
                    highlight.FillColor = Config.Highlight.Color
                    highlight.OutlineColor = Config.Highlight.Outline
                    highlight.FillTransparency = 0.5
                    highlight.OutlineTransparency = 0.5
                    if Config.Highlight.BehindWalls then
                        highlight.DepthMode = "AlwaysOnTop"
                    else
                        highlight.DepthMode = "Occluded"
                    end
                    highlight.Enabled = true
                elseif highlight then
                    if highlight.FillColor == Config.Highlight.Color then
                        highlight.Enabled = false
                    end
                end
            end
        end
    end
end)

connections.main = connections.main or {}

connections.main.RenderStepped =
    game:GetService("RunService").Heartbeat:Connect(
    function()
        for v, _ in pairs(cache) do
            if v then
                utility.funcs.update(v)
            end
        end
    end
)

return Config