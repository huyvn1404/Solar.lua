
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local UIS = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local SERVER = RunService:IsServer()

if SERVER then
    local Remote = RS:FindFirstChild("SolarCombatEvent")

    if not Remote then
        Remote = Instance.new("RemoteEvent")
        Remote.Name = "SolarCombatEvent"
        Remote.Parent = RS
    end

    local RANGE = 30
    local DAMAGE = 10
    local COOLDOWN = 0.5
    local LastAttack = {}

    local function getTarget(target)
        if typeof(target) ~= "Instance" then return end

        local folder = workspace:FindFirstChild("Targets")
        if not folder or not target:IsDescendantOf(folder) then return end
        if not target:IsA("Model") then return end

        local hum = target:FindFirstChildOfClass("Humanoid")
        local root = target:FindFirstChild("HumanoidRootPart")

        if not hum or not root or hum.Health <= 0 then return end
        return hum, root
    end

    Remote.OnServerEvent:Connect(function(player, action, target)
        if action ~= "Attack" then return end

        local now = os.clock()
        if LastAttack[player] and now - LastAttack[player] < COOLDOWN then
            return
        end

        local char = player.Character
        local root = char and char:FindFirstChild("HumanoidRootPart")
        if not root then return end

        local hum, targetRoot = getTarget(target)
        if not hum then return end

        if (root.Position - targetRoot.Position).Magnitude > RANGE then
            return
        end

        LastAttack[player] = now
        hum:TakeDamage(DAMAGE)
    end)

    Players.PlayerRemoving:Connect(function(player)
        LastAttack[player] = nil
    end)

    return
end

local Player = Players.LocalPlayer
local Camera = workspace.CurrentCamera
local Remote = RS:WaitForChild("SolarCombatEvent")

local Settings = {
    Speed = 32,
    JumpPower = 100,
    FlySpeed = 45
}

local State = {
    Fly = false,
    Lock = false,
    Speed = false,
    HighJump = false,
    InfiniteJump = false
}

local Character
local Humanoid
local Root
local DefaultSpeed = 16
local DefaultJump = 50
local JumpUntil = 0
local Buttons = {}

local function updateCharacter()
    Character = Player.Character
    if not Character then return end

    Humanoid = Character:WaitForChild("Humanoid")
    Root = Character:WaitForChild("HumanoidRootPart")

    DefaultSpeed = Humanoid.WalkSpeed
    DefaultJump = Humanoid.JumpPower
end

updateCharacter()

local function resetState()
    for key in pairs(State) do
        State[key] = false
    end

    if Humanoid then
        Humanoid.WalkSpeed = DefaultSpeed
        Humanoid.UseJumpPower = true
        Humanoid.JumpPower = DefaultJump
        Humanoid.PlatformStand = false
    end

    if Humanoid then
        Camera.CameraSubject = Humanoid
    end

    for key, button in pairs(Buttons) do
        button.Text = key .. " : OFF"
        button.BackgroundColor3 = Color3.fromRGB(55, 39, 78)
    end
end

Player.CharacterAdded:Connect(function()
    task.wait(0.5)
    updateCharacter()
    resetState()
end)

local function getNearestTarget(maxRange)
    local folder = workspace:FindFirstChild("Targets")
    if not folder or not Root then return end

    local nearest
    local shortest = maxRange

    for _, model in ipairs(folder:GetChildren()) do
        if model:IsA("Model") then
            local hum = model:FindFirstChildOfClass("Humanoid")
            local root = model:FindFirstChild("HumanoidRootPart")

            if hum and root and hum.Health > 0 then
                local distance = (Root.Position - root.Position).Magnitude

                if distance < shortest then
                    shortest = distance
                    nearest = model
                end
            end
        end
    end

    return nearest
end

local Gui = Instance.new("ScreenGui")
Gui.Name = "SOLAR_V2"
Gui.ResetOnSpawn = false
Gui.Parent = Player:WaitForChild("PlayerGui")

local Main = Instance.new("Frame")
Main.Size = UDim2.fromOffset(260, 360)
Main.Position = UDim2.new(0.5, -130, 0.5, -180)
Main.BackgroundColor3 = Color3.fromRGB(24, 20, 38)
Main.Parent = Gui

local function addCorner(object, radius)
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, radius)
    corner.Parent = object
end

addCorner(Main, 12)

local Stroke = Instance.new("UIStroke")
Stroke.Color = Color3.fromRGB(155, 90, 255)
Stroke.Thickness = 1.5
Stroke.Parent = Main

local Header = Instance.new("Frame")
Header.Size = UDim2.new(1, 0, 0, 42)
Header.BackgroundColor3 = Color3.fromRGB(48, 30, 75)
Header.Parent = Main
addCorner(Header, 12)

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, -55, 1, 0)
Title.Position = UDim2.fromOffset(12, 0)
Title.BackgroundTransparency = 1
Title.Text = "☾  SOLAR V2 LITE"
Title.TextColor3 = Color3.new(1, 1, 1)
Title.TextSize = 15
Title.Font = Enum.Font.GothamBold
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.Parent = Header

local Minimize = Instance.new("TextButton")
Minimize.Size = UDim2.fromOffset(35, 30)
Minimize.Position = UDim2.new(1, -42, 0, 6)
Minimize.Text = "—"
Minimize.TextSize = 18
Minimize.TextColor3 = Color3.new(1, 1, 1)
Minimize.BackgroundColor3 = Color3.fromRGB(105, 65, 155)
Minimize.Parent = Header
addCorner(Minimize, 8)

local Content = Instance.new("ScrollingFrame")
Content.Position = UDim2.fromOffset(10, 50)
Content.Size = UDim2.new(1, -20, 1, -60)
Content.BackgroundTransparency = 1
Content.BorderSizePixel = 0
Content.ScrollBarThickness = 3
Content.CanvasSize = UDim2.new(0, 0, 0, 0)
Content.Parent = Main

local Layout = Instance.new("UIListLayout")
Layout.Padding = UDim.new(0, 7)
Layout.SortOrder = Enum.SortOrder.LayoutOrder
Layout.Parent = Content

Layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
    Content.CanvasSize = UDim2.new(0, 0, 0, Layout.AbsoluteContentSize.Y + 10)
end)

local function makeButton(name, callback)
    local button = Instance.new("TextButton")
    button.Size = UDim2.new(1, -5, 0, 38)
    button.BackgroundColor3 = Color3.fromRGB(55, 39, 78)
    button.TextColor3 = Color3.new(1, 1, 1)
    button.TextSize = 13
    button.Font = Enum.Font.GothamMedium
    button.Text = name
    button.Parent = Content
    addCorner(button, 8)
    button.Activated:Connect(callback)
    return button
end

local function updateButton(button, name, enabled)
    button.Text = name .. " : " .. (enabled and "ON" or "OFF")
    button.BackgroundColor3 = enabled
        and Color3.fromRGB(105, 65, 155)
        or Color3.fromRGB(55, 39, 78)
end

local function toggle(name, callback)
    local button
    button = makeButton(name .. " : OFF", function()
        State[name] = not State[name]
        updateButton(button, name, State[name])
        callback(State[name])
    end)
    Buttons[name] = button
end

toggle("Fly", function() end)

toggle("Lock", function(enabled)
    if not enabled and Humanoid then
        Camera.CameraSubject = Humanoid
    end
end)

toggle("HighJump", function(enabled)
    if Humanoid then
        Humanoid.UseJumpPower = true
        Humanoid.JumpPower = enabled and Settings.JumpPower or DefaultJump
    end
end)

toggle("Speed", function(enabled)
    if Humanoid then
        Humanoid.WalkSpeed = enabled and Settings.Speed or DefaultSpeed
    end
end)

toggle("InfiniteJump", function() end)

makeButton("ATTACK NEAREST TARGET", function()
    local target = getNearestTarget(30)
    if target then
        Remote:FireServer("Attack", target)
    end
end)

makeButton("RESET SETTINGS", resetState)

local Restore = Instance.new("TextButton")
Restore.Size = UDim2.fromOffset(48, 48)
Restore.Position = UDim2.new(0, 15, 0.5, -24)
Restore.BackgroundColor3 = Color3.fromRGB(105, 65, 155)
Restore.Text = "☾"
Restore.TextSize = 27
Restore.TextColor3 = Color3.new(1, 1, 1)
Restore.Visible = false
Restore.Parent = Gui
addCorner(Restore, 24)

Minimize.Activated:Connect(function()
    Main.Visible = false
    Restore.Visible = true
end)

Restore.Activated:Connect(function()
    Main.Visible = true
    Restore.Visible = false
end)

local dragging = false
local dragStart
local startPosition

Header.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragStart = input.Position
        startPosition = Main.Position
    end
end)

UIS.InputChanged:Connect(function(input)
    if dragging and (
        input.UserInputType == Enum.UserInputType.MouseMovement
        or input.UserInputType == Enum.UserInputType.Touch
    ) then
        local delta = input.Position - dragStart
        Main.Position = UDim2.new(
            startPosition.X.Scale,
            startPosition.X.Offset + delta.X,
            startPosition.Y.Scale,
            startPosition.Y.Offset + delta.Y
        )
    end
end)

UIS.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
        dragging = false
    end
end)

UIS.JumpRequest:Connect(function()
    if State.InfiniteJump and Humanoid then
        Humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
    end

    if State.Fly then
        JumpUntil = os.clock() + 0.25
    end
end)

RunService.RenderStepped:Connect(function(dt)
    if not Character or not Humanoid or not Root then return end

    if State.Lock then
        local target = getNearestTarget(500)
        local targetHum = target and target:FindFirstChildOfClass("Humanoid")
        Camera.CameraSubject = targetHum or Humanoid
    end

    if State.Fly then
        local move = Humanoid.MoveDirection
        local vertical = 0

        if UIS:IsKeyDown(Enum.KeyCode.Space) then
            vertical = 1
        elseif UIS:IsKeyDown(Enum.KeyCode.LeftControl) then
            vertical = -1
        elseif os.clock() < JumpUntil then
            vertical = 1
        end

        local direction = move + Vector3.new(0, vertical, 0)

        if direction.Magnitude > 0 then
            Root.CFrame = Root.CFrame + direction.Unit * Settings.FlySpeed * dt
        end
    end
end)

print("SOLAR V2 LITE LOADED")
