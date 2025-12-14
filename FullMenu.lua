local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local SoundService = game:GetService("SoundService")
local Camera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer

-- チート有効/無効フラグ
local espEnabled = false
local aimbotEnabled = false
local noclipEnabled = false
local headshotSoundEnabled = false -- ヘッドショット音ON/OFFフラグ

-- チーン音の用意
local chime = Instance.new("Sound")
chime.Name = "HeadshotSound"
chime.SoundId = "rbxassetid://7128958209" -- チーン音
chime.Volume = 1
chime.Parent = SoundService

-- GUI作成
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "CheatGui"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui") -- ここを修正

-- アイコンボタン
local IconButton = Instance.new("ImageButton")
IconButton.Name = "ToggleButton"
IconButton.Size = UDim2.new(0, 40, 0, 40)
IconButton.Position = UDim2.new(0, 10, 0, 10)
IconButton.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
IconButton.BorderSizePixel = 0
IconButton.Image = "rbxassetid://7038847777" -- ギアアイコン
IconButton.Parent = ScreenGui

-- チートメニューフレーム（初期非表示）
local CheatFrame = Instance.new("Frame")
CheatFrame.Size = UDim2.new(0, 180, 0, 170)
CheatFrame.Position = UDim2.new(0, 10, 0, 60)
CheatFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
CheatFrame.BorderSizePixel = 0
CheatFrame.Visible = false
CheatFrame.Parent = ScreenGui

-- タイトル
local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, 0, 0, 25)
title.BackgroundTransparency = 1
title.TextColor3 = Color3.new(1,1,1)
title.Text = "チートメニュー"
title.Font = Enum.Font.SourceSansBold
title.TextSize = 20
title.Parent = CheatFrame

-- チェックボックス作成関数
local function createCheckbox(parent, text, position, callback)
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, -10, 0, 30)
    frame.Position = position
    frame.BackgroundTransparency = 1
    frame.Parent = parent

    local box = Instance.new("TextButton")
    box.Size = UDim2.new(0, 25, 0, 25)
    box.Position = UDim2.new(0, 5, 0, 2)
    box.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    box.BorderColor3 = Color3.new(1,1,1)
    box.Text = ""
    box.Parent = frame

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, -40, 1, 0)
    label.Position = UDim2.new(0, 35, 0, 0)
    label.BackgroundTransparency = 1
    label.TextColor3 = Color3.new(1,1,1)
    label.Text = text
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Font = Enum.Font.SourceSans
    label.TextSize = 18
    label.Parent = frame

    local checked = false
    local function updateVisual()
        if checked then
            box.BackgroundColor3 = Color3.fromRGB(0, 170, 0)
        else
            box.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
        end
    end

    box.MouseButton1Click:Connect(function()
        checked = not checked
        updateVisual()
        callback(checked)
    end)

    updateVisual()
    return frame
end

-- ESPとエイムボットとNoClipとヘッドショット音のチェックボックス
createCheckbox(CheatFrame, "ESP (敵体力バー＋枠)", UDim2.new(0, 5, 0, 35), function(state)
    espEnabled = state
end)

createCheckbox(CheatFrame, "エイムボット", UDim2.new(0, 5, 0, 70), function(state)
    aimbotEnabled = state
end)

createCheckbox(CheatFrame, "NoClip (透明パーツの当たり判定解除)", UDim2.new(0, 5, 0, 105), function(state)
    noclipEnabled = state
end)

createCheckbox(CheatFrame, "ヘッドショット音ON/OFF", UDim2.new(0, 5, 0, 140), function(state)
    headshotSoundEnabled = state
end)

-- アイコンをドラッグ可能にする処理
local dragging = false
local dragInput
local dragStart
local startPos

local function updatePosition(input)
    local delta = input.Position - dragStart
    local newPos = UDim2.new(
        0,
        math.clamp(startPos.X.Offset + delta.X, 0, Camera.ViewportSize.X - IconButton.AbsoluteSize.X),
        0,
        math.clamp(startPos.Y.Offset + delta.Y, 0, Camera.ViewportSize.Y - IconButton.AbsoluteSize.Y)
    )
    IconButton.Position = newPos
    CheatFrame.Position = UDim2.new(0, newPos.X.Offset, 0, newPos.Y.Offset + IconButton.AbsoluteSize.Y + 10)
end

IconButton.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragStart = input.Position
        startPos = IconButton.Position

        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                dragging = false
            end
        end)
    end
end)

IconButton.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
        dragInput = input
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if dragging and input == dragInput then
        updatePosition(input)
    end
end)

-- アイコンをクリックしたらチートメニューをトグル表示
IconButton.MouseButton1Click:Connect(function()
    CheatFrame.Visible = not CheatFrame.Visible
end)

-- --- ESP 実装 ---
local enemyLines = {}
local healthBars = {}

local function isEnemy(player)
    if not LocalPlayer.Team or not player.Team then
        return true
    end
    return player.Team ~= LocalPlayer.Team
end

local function createHealthBar(player)
    if not player.Character or not player.Character:FindFirstChild("HumanoidRootPart") then return end
    if healthBars[player] then return end

    local hrp = player.Character.HumanoidRootPart

    local barGui = Instance.new("BillboardGui")
    barGui.Name = "VerticalHealthBar"
    barGui.Adornee = hrp
    barGui.Size = UDim2.new(0, 4, 0, 30)
    barGui.StudsOffset = Vector3.new(1.5, 0, 0)
    barGui.AlwaysOnTop = true

    local healthBar = Instance.new("Frame")
    healthBar.Name = "HealthBar"
    healthBar.Size = UDim2.new(1, 0, 1, 0)
    healthBar.Position = UDim2.new(0, 0, 1, 0)
    healthBar.AnchorPoint = Vector2.new(0, 1)
    healthBar.BackgroundColor3 = Color3.new(0, 1, 0)
    healthBar.BorderSizePixel = 0
    healthBar.Parent = barGui

    local bgBar = Instance.new("Frame")
    bgBar.Name = "Background"
    bgBar.Size = UDim2.new(1, 0, 1, 0)
    bgBar.Position = UDim2.new(0, 0, 0, 0)
    bgBar.BackgroundColor3 = Color3.new(0.1, 0.1, 0.1)
    bgBar.BorderSizePixel = 0
    bgBar.ZIndex = 0
    bgBar.Parent = barGui

    barGui.Parent = player.Character

    local updateConnection
    updateConnection = RunService.RenderStepped:Connect(function()
        if player.Character and player.Character:FindFirstChild("Humanoid") and healthBar.Parent then
            local humanoid = player.Character.Humanoid
            local healthRatio = math.clamp(humanoid.Health / humanoid.MaxHealth, 0, 1)
            healthBar.Size = UDim2.new(1, 0, healthRatio, 0)

            if healthRatio > 0.5 then
                healthBar.BackgroundColor3 = Color3.new(0, 1, 0)
            elseif healthRatio > 0.25 then
                healthBar.BackgroundColor3 = Color3.new(1, 0.5, 0)
            else
                healthBar.BackgroundColor3 = Color3.new(1, 0, 0)
            end

            if humanoid.Health <= 0 then
                updateConnection:Disconnect()
                barGui:Destroy()
                healthBars[player] = nil
            end
        else
            updateConnection:Disconnect()
            if barGui.Parent then
                barGui:Destroy()
            end
            healthBars[player] = nil
        end
    end)

    healthBars[player] = barGui
end

local function createEnemyLines(player, screenPos)
    if not enemyLines[player] then
        enemyLines[player] = {}
        for i = 1, 4 do
            local line = Drawing.new("Line")
            line.Color = Color3.new(1, 1, 1)
            line.Thickness = 2
            line.Visible = false
            table.insert(enemyLines[player], line)
        end
    end

    local size = 20
    local topLeft = Vector2.new(screenPos.X - size, screenPos.Y - size)
    local topRight = Vector2.new(screenPos.X + size, screenPos.Y - size)
    local bottomLeft = Vector2.new(screenPos.X - size, screenPos.Y + size)
    local bottomRight = Vector2.new(screenPos.X + size, screenPos.Y + size)

    local lines = enemyLines[player]
    lines[1].From = topLeft
    lines[1].To = topRight

    lines[2].From = topRight
    lines[2].To = bottomRight

    lines[3].From = bottomRight
    lines[3].To = bottomLeft

    lines[4].From = bottomLeft
    lines[4].To = topLeft

    for i = 1, 4 do
        lines[i].Visible = true
    end
end

local function hideEnemyLines(player)
    if enemyLines[player] then
        for _, line in pairs(enemyLines[player]) do
            line.Visible = false
        end
    end
end

-- ESP更新ループ
RunService.RenderStepped:Connect(function()
    if not espEnabled then
        for player, _ in pairs(enemyLines) do
            hideEnemyLines(player)
        end
        for player, bar in pairs(healthBars) do
            if bar then
                bar:Destroy()
                healthBars[player] = nil
            end
        end
        return
    end

    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and isEnemy(player) then
            if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
                local hrp = player.Character.HumanoidRootPart
                local screenPos, onScreen = Camera:WorldToViewportPoint(hrp.Position)
                if onScreen then
                    createEnemyLines(player, screenPos)
                    if not healthBars[player] then
                        createHealthBar(player)
                    end
                else
                    hideEnemyLines(player)
                    if healthBars[player] then
                        healthBars[player]:Destroy()
                        healthBars[player] = nil
                    end
                end
            else
                hideEnemyLines(player)
                if healthBars[player] then
                    healthBars[player]:Destroy()
                    healthBars[player] = nil
                end
            end
        else
            hideEnemyLines(player)
            if healthBars[player] then
                healthBars[player]:Destroy()
                healthBars[player] = nil
            end
        end
    end
end)

-- --- エイムボット実装 ---
local Drawing = Drawing -- Drawing API が使える前提

-- 円の設定
local circleRadius = 100 -- 円を少し大きく
local centerX, centerY = Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2

-- 円を描画
local circleDrawing = Drawing.new("Circle")
circleDrawing.Radius = circleRadius
circleDrawing.Color = Color3.fromRGB(255, 255, 255) -- 白に修正
circleDrawing.Thickness = 2
circleDrawing.Filled = false
circleDrawing.Position = Vector2.new(centerX, centerY)
circleDrawing.Visible = false
circleDrawing.Transparency = 1

-- 敵判定関数
local function isEnemy(player)
    if not LocalPlayer.Team or not player.Team then
        return true
    end
    return player.Team ~= LocalPlayer.Team
end

-- 可視判定（壁越しは無視）
local function isVisible(part)
    local origin = Camera.CFrame.Position
    local direction = (part.Position - origin).Unit * (part.Position - origin).Magnitude

    local rayParams = RaycastParams.new()
    rayParams.FilterType = Enum.RaycastFilterType.Blacklist
    rayParams.FilterDescendantsInstances = {LocalPlayer.Character}
    rayParams.IgnoreWater = true

    local result = workspace:Raycast(origin, direction, rayParams)

    return result and (result.Instance == part or part:IsDescendantOf(result.Instance))
end

-- ○内にいるか判定
local function isInCircle(part)
    local screenPos, onScreen = Camera:WorldToViewportPoint(part.Position)
    if not onScreen then return false end
    local distance = math.sqrt((screenPos.X - centerX)^2 + (screenPos.Y - centerY)^2)
    return distance <= circleRadius
end

-- 最も近い敵パーツを取得（○内かつ壁越し無視）
local function getClosestEnemyPart()
    local closestPart = nil
    local shortestDistance = math.huge

    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and isEnemy(player) then
            local char = player.Character
            if char and char:FindFirstChild("Humanoid") and char.Humanoid.Health > 0 then
                local partsToCheck = {
                    char:FindFirstChild("Head"),
                    char:FindFirstChild("HumanoidRootPart"),
                    char:FindFirstChild("Torso") or char:FindFirstChild("UpperTorso"),
                }
                for _, part in pairs(partsToCheck) do
                    if part and isVisible(part) and isInCircle(part) then
                        local distance = (Camera.CFrame.Position - part.Position).Magnitude
                        if distance < shortestDistance then
                            shortestDistance = distance
                            closestPart = part
                        end
                    end
                end
            end
        end
    end

    return closestPart
end

-- 毎フレーム視点更新
RunService.RenderStepped:Connect(function()
    -- 画面サイズが変わった場合に円の位置を更新
    centerX, centerY = Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2
    circleDrawing.Position = Vector2.new(centerX, centerY)
    circleDrawing.Visible = aimbotEnabled -- チェック状態に応じて表示

    if aimbotEnabled then
        local target = getClosestEnemyPart()
        if target then
            local cameraPos = Camera.CFrame.Position
            local lookVector = (target.Position - cameraPos).Unit
            Camera.CFrame = CFrame.new(cameraPos, cameraPos + lookVector)
        end
    end
end)

-- --- NoClip 実装 ---
local function setCharacterCanCollide(state)
    local character = LocalPlayer.Character
    if not character then return end

    for _, part in pairs(character:GetChildren()) do
        if part:IsA("BasePart") then
            part.CanCollide = state
        end
    end
end

local function toggleNoClip(enabled)
    noclipEnabled = enabled
    if noclipEnabled then
        setCharacterCanCollide(false)
    else
        setCharacterCanCollide(true)
    end
end

createCheckbox(CheatFrame, "NoClip (透明パーツの当たり判定解除)", UDim2.new(0, 5, 0, 105), function(state)
    toggleNoClip(state)
end)

RunService.RenderStepped:Connect(function()
    if noclipEnabled then
        setCharacterCanCollide(false)
    end
end)

-- --- ヘッドショット音 ---
local function playHeadshotSound()
    if headshotSoundEnabled then
        chime:Play()
    end
end

local function onBulletHit(hitPart)
    if hitPart and hitPart.Name == "Head" then
        local character = hitPart:FindFirstAncestorOfClass("Model")
        if character and Players:GetPlayerFromCharacter(character) ~= LocalPlayer then
            playHeadshotSound()
        end
    end
end
