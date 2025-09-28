local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local SoundService = game:GetService("SoundService")
local Camera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer

-- ★ NEW: 確実にキャラクターがロードされるのを待つ
repeat wait() until LocalPlayer.Character

-- =========================================================
-- チート有効/無効フラグ
-- =========================================================
local espEnabled = false
local aimbotEnabled = false
local noclipEnabled = false
local headshotSoundEnabled = false 

local speedControlEnabled = false -- ★ 速度制御フラグ
local currentWalkSpeed = 16       -- ★ NEW: 現在の速度値を保持 (デフォルト16)
local jumpControlEnabled = false  

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
    inputTextBox.Text = tostring(currentWalkSpeed) -- ★ 修正: 保存された速度を表示
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
-- ★ 修正された速度設定ロジック
-- =========================================================

local function setCharacterSpeed(humanoid, speed)
    if humanoid and humanoid:IsA("Humanoid") then
        pcall(function()
            humanoid.WalkSpeed = speed
        end)
    end
end

local function setWalkSpeed(textValue)
    local speed = tonumber(textValue)
    if speed and speed >= 16 and speed <= 200 then
        currentWalkSpeed = speed -- ★ NEW: 速度を保存
        if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
            setCharacterSpeed(LocalPlayer.Character.Humanoid, speed)
            print("✅ 速度を " .. speed .. " に設定しました。")
        end
    else
        print("⚠️ 無効な速度値。16-200を入力してください。")
    end
end

-- ★ NEW: 速度制御ON/OFFの関数
local function toggleSpeedControl(enabled)
    speedControlEnabled = enabled
    local humanoid = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid")

    if not enabled then
        -- OFFにした場合はデフォルトに戻す
        currentWalkSpeed = 16 -- 保持する速度もデフォルトに戻す
        setCharacterSpeed(humanoid, 16)
        print("✅ 速度をデフォルトの 16 に戻しました。")
    end
    -- ONにした場合の設定は、RenderSteppedで行います
end


-- =========================================================
-- UI要素の配置と機能の紐づけ
-- =========================================================
local yOffset = 35 

local speedPanel, speedInput = createPanel(
    CheatFrame,
    "移動速度",
    UDim2.new(0, 5, 0, yOffset),
    setWalkSpeed 
)
createCheckbox(CheatFrame, "移動速度調整", UDim2.new(0, 5, 0, yOffset), function(state)
    toggleSpeedControl(state) -- ★ 修正: 新しい toggleSpeedControl を呼び出す
    speedPanel.Visible = state 
end, speedPanel)
yOffset = yOffset + 35

-- 既存のエイムボット、NoClipなどのチェックボックス（変更なし）
createCheckbox(CheatFrame, "ESP (敵体力バー＋枠)", UDim2.new(0, 5, 0, yOffset), function(state)
    espEnabled = state
end)
yOffset = yOffset + 35

createCheckbox(CheatFrame, "エイムボット", UDim2.new(0, 5, 0, yOffset), function(state)
    aimbotEnabled = state
end)
yOffset = yOffset + 35

createCheckbox(CheatFrame, "NoClip (透明パーツの当たり判定解除)", UDim2.new(0, 5, 0, yOffset), function(state)
    noclipEnabled = state
end)
yOffset = yOffset + 35

createCheckbox(CheatFrame, "ヘッドショット音ON/OFF", UDim2.new(0, 5, 0, yOffset), function(state)
    headshotSoundEnabled = state
end)
yOffset = yOffset + 35

-- =========================================================
-- アイコンのドラッグ処理（変更なし）
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
    end
end)

-- =========================================================
-- ★ NEW: キャラクターリスポーン時の再設定ロジック
-- =========================================================
local function setupCharacter(character)
    if character then
        local humanoid = character:FindFirstChildOfClass("Humanoid")
        if humanoid and speedControlEnabled then
            -- 速度制御がONの場合、設定された速度を強制適用
            setCharacterSpeed(humanoid, currentWalkSpeed)
        end
    end
end

-- プレイヤーのCharacterAddedイベントに接続（リスポーン対応のコア部分）
LocalPlayer.CharacterAdded:Connect(setupCharacter)


-- =========================================================
-- ★ 修正された RenderStepped (永続化ループ)
-- =========================================================
RunService.RenderStepped:Connect(function()
    local character = LocalPlayer.Character
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")

    -- 1. ★ 速度の永続化: 制御ONの時、毎フレーム速度を上書き
    if speedControlEnabled and humanoid then
        humanoid.WalkSpeed = currentWalkSpeed
    end

    -- 2. NoClipの永続化 (元のロジックを維持)
    if noclipEnabled then
        local function setCharacterCanCollide(state)
            local character = LocalPlayer.Character
            if not character then return end
        
            for _, part in pairs(character:GetChildren()) do
                if part:IsA("BasePart") then
                    part.CanCollide = state
                end
            end
        end
        setCharacterCanCollide(false)
    end
    
    -- 3. ESP/Aimbotロジックは元のコードのまま、このループ内に残す (変更なし)
    -- ... (ESP更新ループのロジックをここに貼り付ける)
    -- ... (Aimbotの毎フレーム視点更新ロジックをここに貼り付ける)
    -- ★ 実際にコードを貼り付ける際は、上記の省略されたESP/Aimbotのロジックを、ご提示いただいた元のコードからRenderStepped内に戻してください。
end)

-- ★ NEW: 初回実行時に速度を適用
if LocalPlayer.Character then
    setupCharacter(LocalPlayer.Character)
end

-- =========================================================
-- 以下、元のコードのESP/Aimbot/Headshot音のロジックを全て維持...
-- =========================================================

-- ... (元のコードの isEnemy, createHealthBar, createEnemyLines, hideEnemyLines の関数) ...
-- ... (元のコードの isVisible, isInCircle, getClosestEnemyPart の関数) ...
-- ... (元のコードの playHeadshotSound, onBulletHit の関数) ...
