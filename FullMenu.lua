local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local SoundService = game:GetService("SoundService")
local Camera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer

-- ★ 修正: 確実にゲームとGUIがロードされるのを待つ
repeat wait() until game:IsLoaded() and LocalPlayer

-- =========================================================
-- チート有効/無効フラグとデフォルト値
-- =========================================================
local espEnabled = false
local aimbotEnabled = false
local noclipEnabled = false
local headshotSoundEnabled = false 

local speedControlEnabled = false
local currentWalkSpeed = 16 -- 現在の速度を保持

-- NoClip用の当たり判定保存テーブル
local defaultCanCollide = {} 

-- チーン音の用意
local chime = Instance.new("Sound")
chime.Name = "HeadshotSound"
chime.SoundId = "rbxassetid://7128958209"
chime.Volume = 1
chime.Parent = SoundService

-- =========================================================
-- GUI作成のセットアップ
-- (GUI作成部分は変更なし)
-- =========================================================
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "CheatGui"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")

local IconButton = Instance.new("ImageButton")
IconButton.Name = "ToggleButton"
IconButton.Size = UDim2.new(0, 40, 0, 40)
IconButton.Position = UDim2.new(0.01, 0, 0.05, 0) 
IconButton.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
IconButton.BorderSizePixel = 0
IconButton.Image = "rbxassetid://7038847777" 
IconButton.Parent = ScreenGui

local CheatFrame = Instance.new("Frame")
CheatFrame.Size = UDim2.new(0, 180, 0, 245) 
CheatFrame.Position = UDim2.new(0, IconButton.Position.X.Offset, 0, IconButton.Position.Y.Offset + IconButton.Size.Y.Offset + 10) 
CheatFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
CheatFrame.BorderSizePixel = 0
CheatFrame.Visible = false
CheatFrame.Parent = ScreenGui

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, 0, 0, 25)
title.BackgroundTransparency = 1
title.TextColor3 = Color3.new(1,1,1)
title.Text = "チートメニュー"
title.Font = Enum.Font.SourceSansBold
title.TextSize = 20
title.Parent = CheatFrame

-- =========================================================
-- 設定パネル作成関数
-- (変更なし)
-- =========================================================
local function createPanel(parent, titleText, initialPosition, actionCallback)
    local panelFrame = Instance.new("Frame")
    panelFrame.Position = UDim2.new(0, initialPosition.X.Offset + parent.Size.X.Offset + 10, 0, initialPosition.Y.Offset)
    panelFrame.Size = UDim2.new(0, 150, 0, 80)
    panelFrame.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
    panelFrame.BorderSizePixel = 0
    panelFrame.Visible = false
    panelFrame.Parent = ScreenGui

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
    inputTextBox.Text = tostring(currentWalkSpeed)
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
        actionCallback(inputTextBox.Text) 
    end)
    
    return panelFrame, inputTextBox
end

-- =========================================================
-- チェックボックス作成関数
-- (変更なし)
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
        callback(checked) 

        if panelFrame then
            panelFrame.Visible = checked
        end
    end)

    updateVisual()
    return frame
end

-- =========================================================
-- ★ 速度設定ロジック (リスポーン対応)
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
        currentWalkSpeed = speed -- 入力された速度を保持
        if speedControlEnabled then 
            local character = LocalPlayer.Character
            local humanoid = character and character:FindFirstChild("Humanoid")
            setCharacterSpeed(humanoid, speed)
            print("✅ 速度を " .. speed .. " に設定しました。")
        end
    end
end

local function toggleSpeedControl(enabled, speedInputBox)
    speedControlEnabled = enabled
    local character = LocalPlayer.Character
    local humanoid = character and character:FindFirstChild("Humanoid")
    if not humanoid then return end

    if enabled then
        -- ONにするときは、UIに入力されている速度を適用
        setWalkSpeed(speedInputBox.Text)
    else
        -- OFFにするときは、デフォルトの速度16に戻す
        currentWalkSpeed = 16 -- 保持する速度もデフォルトに戻す
        setCharacterSpeed(humanoid, 16)
        print("✅ 速度をデフォルトの 16 に戻しました。")
    end
end

-- =========================================================
-- --- NoClip 実装 --- (リスポーン対応と永続化)
-- =========================================================
local function setCharacterCanCollide(state, parts)
    local character = LocalPlayer.Character
    if not character then return end

    for _, part in pairs(parts or character:GetChildren()) do
        if part:IsA("BasePart") then
            if state == false then
                -- ONにする際は即時変更
                defaultCanCollide[part] = part.CanCollide 
                part.CanCollide = false
            elseif state == true then
                -- OFFにする際は元の値に戻す
                part.CanCollide = defaultCanCollide[part] ~= nil and defaultCanCollide[part] or true
                defaultCanCollide[part] = nil 
            end
        end
    end
end

local function toggleNoClip(enabled)
    if enabled then
        -- ON: 即座に全てのパーツの当たり判定を解除
        setCharacterCanCollide(false)
    else
        -- OFF: ラグを避けるため、パーツを分けて処理する
        local character = LocalPlayer.Character
        if character then
            local children = character:GetChildren()
            local chunkSize = math.ceil(#children / 10) 
            
            for i = 1, 10 do
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

-- =========================================================
-- UI要素の配置と機能の紐づけ
-- (変更なし)
-- =========================================================
local yOffset = 35 

local speedPanel, speedInput = createPanel(
    CheatFrame,
    "移動速度",
    UDim2.new(0, 5, 0, yOffset),
    setWalkSpeed 
)
createCheckbox(CheatFrame, "移動速度調整", UDim2.new(0, 5, 0, yOffset), function(state)
    toggleSpeedControl(state, speedInput) 
end, speedPanel)
yOffset = yOffset + 35

createCheckbox(CheatFrame, "ESP (敵体力バー＋枠)", UDim2.new(0, 5, 0, yOffset), function(state)
    espEnabled = state
    -- ★ NEW: ESP有効時の処理関数を呼び出す（ここでは省略）
end)
yOffset = yOffset + 35

createCheckbox(CheatFrame, "エイムボット", UDim2.new(0, 5, 0, yOffset), function(state)
    aimbotEnabled = state
    -- ★ NEW: Aimbot有効時の処理関数を呼び出す（ここでは省略）
end)
yOffset = yOffset + 35

createCheckbox(CheatFrame, "NoClip (透明パーツの当たり判定解除)", UDim2.new(0, 5, 0, yOffset), function(state)
    noclipEnabled = state
    toggleNoClip(state) 
end)
yOffset = yOffset + 35

createCheckbox(CheatFrame, "ヘッドショット音ON/OFF", UDim2.new(0, 5, 0, yOffset), function(state)
    headshotSoundEnabled = state
end)
yOffset = yOffset + 35

-- =========================================================
-- アイコンのドラッグ処理
-- (変更なし)
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
    CheatFrame.Position = UDim2.new(0, newPos.X.Offset, 0, newPos.Y.Offset + IconButton.AbsoluteSize.Y + 10)
    
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

IconButton.MouseButton1Click:Connect(function()
    CheatFrame.Visible = not CheatFrame.Visible
    
    if not CheatFrame.Visible then
        speedPanel.Visible = false 
    end
end)


-- =========================================================
-- ★ NEW: 永続的な動作を保証するロジック
-- =========================================================

-- 新しいキャラクターがロードされるたびに実行される関数
local function setupCharacter(character)
    if character then
        -- 1. NoClipの再適用
        if noclipEnabled then
            toggleNoClip(true)
        end

        -- 2. 速度の再適用
        if speedControlEnabled then
            local humanoid = character:FindFirstChildOfClass("Humanoid")
            if humanoid then
                setCharacterSpeed(humanoid, currentWalkSpeed)
            end
        end

        -- 3. ESP/Aimbot用のセットアップ（省略）
        -- (ESPやAimbotの処理は通常、この関数内で新しいキャラクターや敵プレイヤーを監視するように設定します)
    end
end

-- プレイヤーのCharacterAddedイベントに接続（リスポーン対応のコア部分）
LocalPlayer.CharacterAdded:Connect(setupCharacter)

-- 最初のキャラクターにも適用
if LocalPlayer.Character then
    setupCharacter(LocalPlayer.Character)
end

-- RenderSteppedで継続的にNoClipと速度を適用し、ゲーム側の上書きを防ぐ
RunService.RenderStepped:Connect(function()
    local character = LocalPlayer.Character
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")

    -- NoClipを継続的に適用
    if noclipEnabled and character then
        setCharacterCanCollide(false)
    end

    -- 速度制御がONの時、保存された速度を毎フレーム適用
    if speedControlEnabled and humanoid then
        humanoid.WalkSpeed = currentWalkSpeed
    end
    
    -- ★ エイムボットとESPの永続的な処理（このコードには実装されていませんが、ここに記述されます）
    -- if aimbotEnabled then runAimbotLogic() end
    -- if espEnabled then runESPLogic() end
end)
