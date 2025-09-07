setfpscap(32555555555555555)
local Config = {
    Box = {
        Enabled = true,
        Color = Color3.fromRGB(255, 255, 255),
        Filled = {
            Enabled = true,
            Gradient = {
                Enabled = true,
                Color = {
                    Start = Color3.fromRGB(255, 255, 255),
                    End = Color3.fromRGB(0, 255, 0)
                },
                Rotation = {
                    Amount = 1,
                    Moving = {
                    	Enabled = true,
                        Speed = 300
                    },
                },
            }
        }
    },
    Text = {
        Font = "Arcade",
        Name = {
            Enabled = false,
            Type = "DisplayName",
            Color = Color3.fromRGB(255, 255, 255)
        },
        Distance = {
            Enabled = false,
            Color = Color3.fromRGB(255, 255, 255)
        },
        Weapon = {
            Enabled = false,
            Color = Color3.fromRGB(255, 255, 255)
        }
    },
    Bars = {
    	Resize = false,
        Width = 2.5,
        Lerp = 0.05,
        Moving = {
            Enabled = true,
            Speed = 1
        },
        Health = {
            Enabled = true,
            Color1 = Color3.fromRGB(0, 255, 0),
            Color2 = Color3.fromRGB(255, 255, 0),
            Color3 = Color3.fromRGB(255, 0, 0)
        },
        Armor = {
            Enabled = false,
            Color1 = Color3.fromRGB(0, 0, 255),
            Color2 = Color3.fromRGB(135, 206, 235),
            Color3 = Color3.fromRGB(1, 0, 0)
        }
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
local increase = Vector3.new(2, 2, 2)
local vertices = { { -0.5, -0.5, -0.5 }, { -0.5, 0.5, -0.5 }, { 0.5, -0.5, -0.5 }, { 0.5, 0.5, -0.5 },{ -0.5, -0.5, 0.5 }, { -0.5, 0.5, 0.5 }, { 0.5, -0.5, 0.5 }, { 0.5, 0.5, 0.5 } };

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
    d.Font = Config.Text.Font
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
            Gradient = armorGradient
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
            Gradient = healthGradient
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
                filled.BackgroundTransparency = 0.3
                filled.BackgroundColor3 = Color3.fromRGB(255,255,255)
                filled.Visible = true
                filled.ZIndex = -9e9

                if Config.Box.Filled.Gradient.Enabled then
                    local gradient = filled:FindFirstChild("Gradient") or Instance.new("UIGradient")
                    gradient.Name = "Gradient"
                    gradient.Color = ColorSequence.new({
                        ColorSequenceKeypoint.new(0, Config.Box.Filled.Gradient.Color.Start),
                        ColorSequenceKeypoint.new(1, Config.Box.Filled.Gradient.Color.End)
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

        if Config.Bars.Health.Enabled and humanoid then
            local targetHealth = math.clamp(humanoid.Health / humanoid.MaxHealth, 0, 1)
            local lastHealth = playerCache.Bars.Health.LastHealth or targetHealth
            local lerpedHealth = lastHealth + (targetHealth - lastHealth) * Config.Bars.Lerp
            playerCache.Bars.Health.LastHealth = lerpedHealth
            local x = base_x - (bar_width + 4)
            local outline = playerCache.Bars.Health.Outline
            local fill = playerCache.Bars.Health.Frame

            if outline and fill then
                outline.Visible = true
                outline.Position = UDim2.new(0, x - 1, 0, y - 1)
                outline.Size = UDim2.new(0, bar_width + 2, 0, bar_height + 1.1)
                outline.BackgroundTransparency = 0.2

                fill.Visible = true
                fill.Position = UDim2.new(0, 1, 0, (1 - lerpedHealth) * bar_height + 1)
                fill.Size = UDim2.new(0, bar_width, 0, lerpedHealth * bar_height)
            end
        else
            if playerCache.Bars.Health.Outline then playerCache.Bars.Health.Outline.Visible = false end
            if playerCache.Bars.Health.Frame then playerCache.Bars.Health.Frame.Visible = false end
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
            if Config.Text.Name.Type == "DisplayName" then
                nameLabel.Text = player.DisplayName
            else
                nameLabel.Text = player.Name
            end
        else
            nameLabel.Visible = false
        end

        if Config.Text.Weapon.Enabled then
            weaponLabel.Visible = true
            weaponLabel.Position = UDim2.new(0, baseX - (weaponLabel.AbsoluteSize.X / 2), 0, baseY + scale.Y + 15)
            local Weapon = character:FindFirstChildOfClass("Weapon")
            weaponLabel.Text = Weapon and Weapon.Name or "none"
        else
            weaponLabel.Visible = false
        end

        if Config.Text.Distance.Enabled then
            distanceLabel.Visible = true
            distanceLabel.Position = UDim2.new(0, baseX - (distanceLabel.AbsoluteSize.X / 2), 0, baseY + scale.Y + 5)
            distanceLabel.Text = string.format("[%.0fm]", distance * 0.28)
        else
            distanceLabel.Visible = false
        end

        if Config.Bars.Armor.Enabled and character then
            local bodyEffects = character:FindFirstChild("BodyEffects")
            local values = bodyEffects and bodyEffects:FindFirstChild("Armor")
            local targetArmor = values and math.clamp(values.Value / 130, 0, 1) or 0
            local lastArmor = playerCache.Bars.Armor.LastArmor or targetArmor
            local lerpedArmor = lastArmor + (targetArmor - lastArmor) * Config.Bars.Lerp
            playerCache.Bars.Armor.LastArmor = lerpedArmor
            local x = base_x - (bar_width * 2 + 6 + 2)

            local outline = playerCache.Bars.Armor.Outline
            local fill = playerCache.Bars.Armor.Frame
            if outline and fill then
                outline.Visible = true
                outline.Position = UDim2.new(0, x - 1, 0, y - 1)
                outline.Size = UDim2.new(0, bar_width + 2, 0, bar_height + 1.1)
                outline.BackgroundTransparency = 0.2

                fill.Visible = true
                fill.Position = UDim2.new(0, 1, 0, (1 - lerpedArmor) * bar_height + 1)
                fill.Size = UDim2.new(0, bar_width, 0, lerpedArmor * bar_height)
            end
        else
            if playerCache.Bars.Armor.Outline then playerCache.Bars.Armor.Outline.Visible = false end
            if playerCache.Bars.Armor.Frame then playerCache.Bars.Armor.Frame.Visible = false end
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
