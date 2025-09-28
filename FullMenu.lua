local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local SoundService = game:GetService("SoundService")
local Camera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer

-- =========================================================
-- チート有効/無効フラグ
-- =========================================================
local espEnabled = false
local aimbotEnabled = false
local noclipEnabled = false
local headshotSoundEnabled = false 

local speedControlEnabled = false -- ★ NEW: 速度制御フラグ
local jumpControlEnabled = false  -- (ジャンプ力調整は不要だが、UIロジックの汎用性のため残す)

-- チーン音の用意
local chime = Instance.new("Sound")
chime.Name = "HeadshotSound"
chime.SoundId = "rbxassetid://7128958209" -- チーン音
chime.Volume = 1
chime.Parent = SoundService

-- =========================================================
-- GUI作成のセットアップ
-- =========================================================
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "CheatGui"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")

-- アイコンボタン
local IconButton = Instance.new("ImageButton")
IconButton.Name = "ToggleButton"
IconButton.Size = UDim2.new(0, 40, 0, 40)
IconButton.Position = UDim2.new(0, 10, 0, 10)
IconButton.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
IconButton.BorderSizePixel = 0
IconButton.Image = "rbxassetid://7038847777" -- ギアアイコン
IconButton.Parent = ScreenGui

-- チートメニューフレーム
local CheatFrame = Instance.new("Frame")
CheatFrame.Size = UDim2.new(0, 180, 0, 245) -- ★ 速度調整パネル用にサイズを広げた (245)
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

-- =========================================================
-- ★ NEW: 設定パネル作成関数 (入力ボックスとボタン)
-- =========================================================
local function createPanel(parent, titleText, initialPosition, actionCallback)
    local panelFrame = Instance.new("Frame")
    -- メインメニューの右隣に配置するため、X軸をメニューの幅分オフセットする
    panelFrame.Position = UDim2.new(0, initialPosition.X.Offset + parent.Size.X.Offset + 10, 0, initialPosition.Y.Offset)
    panelFrame.Size = UDim2.new(0, 150, 0, 80)
    panelFrame.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
    panelFrame.BorderSizePixel = 0
    panelFrame.Visible = false -- 初期は非表示
    panelFrame.Parent = ScreenGui -- CheatFrameの親であるScreenGuiに直接配置

    local titleLabel = Instance.new("TextLabel")
    titleLabel.Size = UDim2.new(1, 0, 0, 20)
    titleLabel.BackgroundTransparency = 1
    titleLabel.TextColor3 = Color3.new(1, 1, 1)
    titleLabel.Text = titleText
    titleLabel.Font = Enum.Font.SourceSansBold
    titleLabel.TextSize = 16
    titleLabel.Parent = panelFrame

    local inputTextBox = Instance.new("TextBox")
    inputTextBox.Size = UDim2.new(0.8, 0, 0, 20)
    inputTextBox.Position = UDim2.new(0.1, 0, 0, 20)
    inputTextBox.PlaceholderText = "速度を入力"
    inputTextBox.Text = "16" -- デフォルト値を設定
    inputTextBox.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
    inputTextBox.TextColor3 = Color3.new(1, 1, 1)
    inputTextBox.Parent = panelFrame

    local applyButton = Instance.new("TextButton")
    applyButton.Size = UDim2.new(0.8, 0, 0, 30)
    applyButton.Position = UDim2.new(0.1, 0, 0, 45)
    applyButton.BackgroundColor3 = Color3.fromRGB(0, 170, 0)
    applyButton.TextColor3 = Color3.new(1, 1, 1)
    applyButton.Text = "適用"
    applyButton.Font = Enum.Font.SourceSansBold
    applyButton.TextSize = 16
    applyButton.Parent = panelFrame

    applyButton.MouseButton1Click:Connect(function()
        actionCallback(inputTextBox.Text) -- ボタンが押されたらコールバックを実行
    end)
    
    return panelFrame, inputTextBox
end

-- =========================================================
-- チェックボックス作成関数 (パネル連携ロジックを追加)
-- =========================================================
local function createCheckbox(parent, text, position, callback, panelFrame)
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
        callback(checked) -- ★ メインロジックを実行

        -- ★ パネルの表示/非表示をチェックボックスと連動させる
        if panelFrame then
            panelFrame.Visible = checked
        end
    end)

    updateVisual()
    return frame
end

-- =========================================================
-- ★ 速度設定ロジック (ラグ解消のために pcall を使用)
-- =========================================================
local function setWalkSpeed(textValue)
    local speed = tonumber(textValue)
    if speed and speed >= 16 and speed <= 200 then
        local humanoid = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid")
        if humanoid then
            -- pcallを使って、安全にWalkSpeedを変更
            local success, err = pcall(function()
                humanoid.WalkSpeed = speed
            end)

            if success then
                print("✅ 速度を " .. speed .. " に設定しました。")
            else
                print("❌ 速度設定中にエラーが発生しました: " .. err)
            end
        end
    else
        print("⚠️ 無効な速度値。16-200を入力してください。")
    end
end

-- =========================================================
-- UI要素の配置と機能の紐づけ
-- =========================================================
local yOffset = 35 -- 最初のチェックボックスのY座標オフセット

-- ★ NEW: 速度設定パネルの作成と紐づけ
local speedPanel, speedInput = createPanel(
    CheatFrame,
    "移動速度",
    UDim2.new(0, 5, 0, yOffset),
    setWalkSpeed -- 適用ボタンが押されたら setWalkSpeed を実行
)
createCheckbox(CheatFrame, "移動速度調整", UDim2.new(0, 5, 0, yOffset), function(state)
    speedControlEnabled = state
    speedPanel.Visible = state -- パネルをON/OFF
end, speedPanel)
yOffset = yOffset + 35

-- 既存のエイムボット、NoClipなどのチェックボックス（元のコードのyOffsetを調整）
-- 元のコードのチェックボックスのY座標を調整して、速度調整パネルの下に配置する

createCheckbox(CheatFrame, "ESP (敵体力バー＋枠)", UDim2.new(0, 5, 0, yOffset), function(state)
    espEnabled = state
end)
yOffset = yOffset + 35

createCheckbox(CheatFrame, "エイムボット", UDim2.new(0, 5, 0, yOffset), function(state)
    aimbotEnabled = state
end)
yOffset = yOffset + 35

createCheckbox(CheatFrame, "NoClip (透明パーツの当たり判定解除)", UDim2.new(0, 5, 0, yOffset), function(state)
    toggleNoClip(state) -- ★ ここを修正
end)
yOffset = yOffset + 35

createCheckbox(CheatFrame, "ヘッドショット音ON/OFF", UDim2.new(0, 5, 0, yOffset), function(state)
    headshotSoundEnabled = state
end)
yOffset = yOffset + 35

-- =========================================================
-- アイコンのドラッグ処理（元のコードから変更なし）
-- =========================================================
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
    -- メニューフレームもアイコンに追従させる
    CheatFrame.Position = UDim2.new(0, newPos.X.Offset, 0, newPos.Y.Offset + IconButton.AbsoluteSize.Y + 10)
    
    -- ★ NEW: 速度パネルもアイコンに追従させる（パネルのX座標はメニューフレームに依存）
    local speedPanelPosition = UDim2.new(0, CheatFrame.Position.X.Offset + CheatFrame.Size.X.Offset + 10, 0, CheatFrame.Position.Y.Offset + 0)
    speedPanel.Position = speedPanelPosition
    
    -- (他のカスタムパネルがある場合もここに追加して追従させます)
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
    
    -- ★ NEW: メニューが閉じるときにパネルを非表示にする
    if not CheatFrame.Visible then
        speedPanel.Visible = false 
        -- (他のパネルも同様に非表示にする)
    end
end)

-- =========================================================
-- --- ESP 実装 --- (元のコードから変更なし)
-- =========================================================
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

-- =========================================================
-- --- エイムボット実装 --- (元のコードから変更なし)
-- =========================================================
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

-- =========================================================
-- --- NoClip 実装 --- (ラグ解消のための修正)
-- =========================================================
local defaultCanCollide = {} -- 既存の値を保存するためのテーブル

local function setCharacterCanCollide(state, parts)
    local character = LocalPlayer.Character
    if not character then return end

    for _, part in pairs(parts or character:GetChildren()) do
        if part:IsA("BasePart") then
            if state == false then
                -- ONにする際は即時変更
                defaultCanCollide[part] = part.CanCollide -- 元の値を保存
                part.CanCollide = false
            elseif state == true then
                -- OFFにする際は元の値に戻す
                part.CanCollide = defaultCanCollide[part] ~= nil and defaultCanCollide[part] or true
                defaultCanCollide[part] = nil -- 保存した値をクリア
            end
        end
    end
end

local function toggleNoClip(enabled)
    noclipEnabled = enabled
    if noclipEnabled then
        -- ONは即座に実行
        setCharacterCanCollide(false)
    else
        -- OFFはラグを避けるため、パーツを分けて処理する
        local character = LocalPlayer.Character
        if character then
            local children = character:GetChildren()
            local chunkSize = math.ceil(#children / 10) -- 10分割して処理
            
            for i = 1, 10 do
                -- わずかな遅延（0.01秒）を設けて処理
                task.delay((i - 1) * 0.01, function()
                    local startIdx = (i - 1) * chunkSize + 1
                    local endIdx = math.min(i * chunkSize, #children)
                    local chunkParts = {}
                    for j = startIdx, endIdx do
                        table.insert(chunkParts, children[j])
                    end
                    setCharacterCanCollide(true, chunkParts)
                end)
            end
        end
    end
end

-- NoClipチェックボックスのロジックは、UI要素の配置セクションで組み込まれています。
-- ここでは、RenderSteppedでの継続的な処理のみを行います。
RunService.RenderStepped:Connect(function()
    if noclipEnabled then
        setCharacterCanCollide(false)
    end
end)

-- =========================================================
-- --- ヘッドショット音 --- (元のコードから変更なし)
-- =========================================================
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
