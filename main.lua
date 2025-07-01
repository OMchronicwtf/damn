--[[
--]]

local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local CoreGui = game:GetService("CoreGui")

local LocalPlayer = Players.LocalPlayer
local Character = LocalPlayer.Character
local Humanoid
local RootPart

local originalWalkSpeed = 16
local originalJumpPower = Humanoid and Humanoid.JumpPower or 0

if Character then
    Humanoid = Character:FindFirstChildOfClass("Humanoid")
    RootPart = Character:FindFirstChild("HumanoidRootPart")
    if Humanoid then
        originalWalkSpeed = Humanoid.WalkSpeed
        originalJumpPower = Humanoid.JumpPower
    else
        print("Admin Menu: Humanoid not found on initial character, will wait for CharacterAdded.")
    end
else
    print("Admin Menu: Character not found initially, will wait for CharacterAdded.")
end

local isFlying = false
local noclipEnabled = false
local espEnabled = false
local speedEnabled = false

local flightBodyVelocity = nil
local flightBodyGyro = nil
local flightRenderSteppedConnection = nil

local originalCollisionStates = {}

local espConnections = {}
local espBillboardGuis = {}
local espRenderSteppedConnection = nil

local screenGui, floatingButton, mainMenu, closeButton
local flightButton, noclipButton, espButton, speedButton
local flightControlFrame, speedControlFrame
local flightSlider, speedSlider
local teleportButton, killPlayerButton, viewScriptsButton, btoolsButton

local MENU_WIDTH = 250
local MENU_HEIGHT = 420
local BUTTON_HEIGHT = 35
local CONTROL_FRAME_HEIGHT = BUTTON_HEIGHT + 30 + 5
local PADDING = 8

local toggleMenu
local getFlightSpeed
local getWalkSpeed
local applySpeed

screenGui = Instance.new("ScreenGui")
screenGui.Name = "AdminMenuGui"
screenGui.ResetOnSpawn = false
screenGui.Parent = CoreGui

floatingButton = Instance.new("TextButton")
floatingButton.Name = "FloatingAdminButton"
floatingButton.Text = "≡"
floatingButton.TextColor3 = Color3.fromRGB(220, 222, 225)
floatingButton.BackgroundColor3 = Color3.fromRGB(44, 47, 51)
floatingButton.BorderSizePixel = 0
floatingButton.Size = UDim2.new(0, 50, 0, 50)
floatingButton.Position = UDim2.new(0, 20, 0.5, -25)
floatingButton.Font = Enum.Font.SourceSansBold
floatingButton.TextSize = 28
floatingButton.AutoButtonColor = true
floatingButton.ZIndex = 10
floatingButton.Parent = screenGui

local floatingButtonCorner = Instance.new("UICorner")
floatingButtonCorner.CornerRadius = UDim.new(0, 12)
floatingButtonCorner.Parent = floatingButton

mainMenu = Instance.new("Frame")
mainMenu.Name = "MainMenuFrame"
mainMenu.ZIndex = 5
mainMenu.BackgroundColor3 = Color3.fromRGB(54, 57, 63)
mainMenu.BorderSizePixel = 0
mainMenu.Size = UDim2.new(0, MENU_WIDTH, 0, MENU_HEIGHT)
mainMenu.Position = UDim2.new(-1, 0, 0.5, -MENU_HEIGHT / 2)
mainMenu.Visible = false
mainMenu.ClipsDescendants = true
mainMenu.Parent = screenGui

local mainMenuCorner = Instance.new("UICorner")
mainMenuCorner.CornerRadius = UDim.new(0, 8)
mainMenuCorner.Parent = mainMenu

closeButton = Instance.new("TextButton")
closeButton.Name = "CloseMenuButton"
closeButton.Text = "✕"
closeButton.TextColor3 = Color3.fromRGB(185, 187, 190)
closeButton.BackgroundTransparency = 1
closeButton.Size = UDim2.new(0, 32, 0, 32)
closeButton.Position = UDim2.new(1, - (32 + PADDING / 2), 0, PADDING / 2)
closeButton.Font = Enum.Font.SourceSansSemibold
closeButton.TextSize = 22
closeButton.Parent = mainMenu
closeButton.MouseEnter:Connect(function() closeButton.TextColor3 = Color3.fromRGB(255,255,255) end)
closeButton.MouseLeave:Connect(function() closeButton.TextColor3 = Color3.fromRGB(185, 187, 190) end)


local buttonLayout = Instance.new("UIListLayout")
buttonLayout.Parent = mainMenu
buttonLayout.FillDirection = Enum.FillDirection.Vertical
buttonLayout.SortOrder = Enum.SortOrder.LayoutOrder
buttonLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
buttonLayout.VerticalAlignment = Enum.VerticalAlignment.Top
buttonLayout.Padding = UDim.new(0, PADDING / 2)
local topPaddingFrame = Instance.new("Frame")
topPaddingFrame.Name = "TopPadding"
topPaddingFrame.Size = UDim2.new(1,0,0,PADDING*2)
topPaddingFrame.BackgroundTransparency = 1
topPaddingFrame.LayoutOrder = 0
topPaddingFrame.Parent = mainMenu

local function createToggleButtonUi(name, text, order)
    local button = Instance.new("TextButton")
    button.Name = name .. "Button"
    button.Text = text .. ": OFF"
    button.TextColor3 = Color3.fromRGB(220, 222, 225)
    button.BackgroundColor3 = Color3.fromRGB(71, 75, 80)
    button.BorderSizePixel = 0
    button.Size = UDim2.new(0, MENU_WIDTH - (PADDING * 3), 0, BUTTON_HEIGHT)
    button.Font = Enum.Font.SourceSansSemibold
    button.TextSize = 15
    button.AutoButtonColor = false

    local btnCorner = Instance.new("UICorner")
    btnCorner.CornerRadius = UDim.new(0, 6)
    btnCorner.Parent = button
    return button
end

local function createSliderUi(sliderName, minValue, maxValue, defaultValue, parentControlFrame)
    local sliderTrack = Instance.new("Frame")
    sliderTrack.Name = sliderName .. "SliderTrack"
    sliderTrack.BackgroundColor3 = Color3.fromRGB(44, 47, 51)
    sliderTrack.BorderSizePixel = 0
    sliderTrack.Size = UDim2.new(0, MENU_WIDTH - (PADDING * 6), 0, 16)
    sliderTrack.Position = UDim2.new(0.5, 0, 0, BUTTON_HEIGHT + PADDING / 2)
    sliderTrack.AnchorPoint = Vector2.new(0.5, 0)
    sliderTrack.Parent = parentControlFrame
    local trackCorner = Instance.new("UICorner")
    trackCorner.CornerRadius = UDim.new(0,8)
    trackCorner.Parent = sliderTrack

    local thumb = Instance.new("TextButton")
    thumb.Name = "Thumb"
    thumb.BackgroundColor3 = Color3.fromRGB(114, 137, 218)
    thumb.BorderSizePixel = 0
    thumb.Size = UDim2.new(0, 28, 1, 0)
    thumb.Font = Enum.Font.SourceSansSemibold
    thumb.TextSize = 10
    thumb.TextColor3 = Color3.fromRGB(255,255,255)
    thumb.Parent = sliderTrack
    thumb.AutoButtonColor = false
    thumb.ZIndex = 2
    local thumbCorner = Instance.new("UICorner")
    thumbCorner.CornerRadius = UDim.new(0,6)
    thumbCorner.Parent = thumb


    local valueLabel = Instance.new("TextLabel")
    valueLabel.Name = sliderName .. "ValueLabel"
    valueLabel.Size = UDim2.new(0, 40, 1, 0)
    valueLabel.Position = UDim2.new(1, PADDING / 2 + 5, 0, 0)
    valueLabel.Font = Enum.Font.SourceSans
    valueLabel.TextSize = 13
    valueLabel.TextColor3 = Color3.fromRGB(185, 187, 190)
    valueLabel.TextXAlignment = Enum.TextXAlignment.Left
    valueLabel.BackgroundTransparency = 1
    valueLabel.Parent = sliderTrack

    local currentValue = defaultValue
    local isDraggingThumb = false
    local thumbDragInput = nil

    local function updateThumbVisuals()
        local trackWidth = sliderTrack.AbsoluteSize.X
        local thumbWidth = thumb.AbsoluteSize.X
        local formattedValue = string.format("%.1f", currentValue)

        if trackWidth <= 0 or (maxValue - minValue == 0) then
            thumb.Position = UDim2.new(0, 0, 0, 0)
            thumb.Text = formattedValue
            valueLabel.Text = formattedValue
            return
        end

        local percentage = (currentValue - minValue) / (maxValue - minValue)
        percentage = math.clamp(percentage, 0, 1)

        local effectiveTrackWidth = trackWidth - thumbWidth
        if effectiveTrackWidth < 0 then effectiveTrackWidth = 0 end

        thumb.Position = UDim2.new(0, effectiveTrackWidth * percentage, 0, 0)
        thumb.Text = formattedValue
        valueLabel.Text = formattedValue
    end

    updateThumbVisuals()

    local function onThumbInput(input)
        local relativeX = input.Position.X - sliderTrack.AbsolutePosition.X
        local percentage = math.clamp(relativeX / sliderTrack.AbsoluteSize.X, 0, 1)
        currentValue = minValue + (maxValue - minValue) * percentage
        updateThumbVisuals()
    end

    thumb.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            isDraggingThumb = true
            thumbDragInput = input
            onThumbInput(input)

            local inputChangedConnection
            local inputEndedConnection

            inputChangedConnection = UserInputService.InputChanged:Connect(function(changedInput)
                if isDraggingThumb and thumbDragInput and changedInput.UserInputType == thumbDragInput.UserInputType then
                    onThumbInput(changedInput)
                end
            end)

            inputEndedConnection = UserInputService.InputEnded:Connect(function(endedInput)
                if isDraggingThumb and thumbDragInput and endedInput.UserInputType == thumbDragInput.UserInputType then
                    isDraggingThumb = false
                    thumbDragInput = nil
                    if inputChangedConnection then inputChangedConnection:Disconnect() end
                    if inputEndedConnection then inputEndedConnection:Disconnect() end

                    print(sliderName .. " slider final value: " .. string.format("%.1f", currentValue))
                    if sliderName == "Speed" and speedEnabled then applySpeed() end
                    if sliderName == "FlightSpeed" and isFlying then
                        print("Flight speed set to: " .. getFlightSpeed())
                    end
                end
            end)
        end
    end)

    sliderTrack.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            onThumbInput(input)
            print(sliderName .. " slider set by track click: " .. string.format("%.1f", currentValue))
            if sliderName == "Speed" and speedEnabled then applySpeed() end
            if sliderName == "FlightSpeed" and isFlying then print("Flight speed set to: " .. getFlightSpeed()) end
        end
    end)

    return sliderTrack, function() return currentValue end, updateThumbVisuals
end

local function createPlaceholderButtonUi(name, text, order)
    local button = Instance.new("TextButton")
    button.Name = name .. "Button"
    button.Text = text
    button.TextColor3 = Color3.fromRGB(200, 202, 205)
    button.BackgroundColor3 = Color3.fromRGB(71, 75, 80)
    button.BorderSizePixel = 0
    button.Size = UDim2.new(0, MENU_WIDTH - (PADDING * 3), 0, BUTTON_HEIGHT)
    button.Font = Enum.Font.SourceSansSemibold
    button.TextSize = 15
    button.AutoButtonColor = true

    local btnCorner = Instance.new("UICorner")
    btnCorner.CornerRadius = UDim.new(0, 6)
    btnCorner.Parent = button
    return button
end

-- Flight Button and Slider
flightControlFrame = Instance.new("Frame")
flightControlFrame.Name = "FlightControlFrame"
flightControlFrame.BackgroundTransparency = 1
flightControlFrame.Size = UDim2.new(1, 0, 0, CONTROL_FRAME_HEIGHT)
flightControlFrame.LayoutOrder = 1
flightControlFrame.Parent = mainMenu
flightButton = createToggleButtonUi("Flight", "Flight", 1)
flightButton.Parent = flightControlFrame
flightButton.Position = UDim2.new(0.5, 0, 0, PADDING/2)
flightButton.AnchorPoint = Vector2.new(0.5, 0)
local flightSliderInstance, getFlightSpeed_orig, updateFlightVis = createSliderUi("FlightSpeed", 1, 150, 50, flightControlFrame)
getFlightSpeed = getFlightSpeed_orig
flightSlider = flightSliderInstance

-- Noclip Button
noclipButton = createToggleButtonUi("Noclip", "Noclip", 2)
noclipButton.LayoutOrder = 2
noclipButton.Parent = mainMenu

-- ESP Button
espButton = createToggleButtonUi("ESP", "ESP", 3)
espButton.LayoutOrder = 3
espButton.Parent = mainMenu

-- Speed Button and Slider
speedControlFrame = Instance.new("Frame")
speedControlFrame.Name = "SpeedControlFrame"
speedControlFrame.BackgroundTransparency = 1
speedControlFrame.Size = UDim2.new(1, 0, 0, CONTROL_FRAME_HEIGHT)
speedControlFrame.LayoutOrder = 4
speedControlFrame.Parent = mainMenu
speedButton = createToggleButtonUi("Speed", "Speed", 4)
speedButton.Parent = speedControlFrame
speedButton.Position = UDim2.new(0.5, 0, 0, PADDING/2)
speedButton.AnchorPoint = Vector2.new(0.5, 0)
local speedSliderInstance, getWalkSpeed_orig, updateSpeedVis = createSliderUi("Speed", 16, 250, originalWalkSpeed, speedControlFrame)
getWalkSpeed = getWalkSpeed_orig
speedSlider = speedSliderInstance

-- Placeholder Buttons
teleportButton = createPlaceholderButtonUi("TeleportToPlayer", "Teleport to Player", 5)
teleportButton.LayoutOrder = 5; teleportButton.Parent = mainMenu
killPlayerButton = createPlaceholderButtonUi("KillPlayer", "Kill Player", 6)
killPlayerButton.LayoutOrder = 6; killPlayerButton.Parent = mainMenu
viewScriptsButton = createPlaceholderButtonUi("ViewServerScripts", "View Server Scripts", 7)
viewScriptsButton.LayoutOrder = 7; viewScriptsButton.Parent = mainMenu
btoolsButton = createPlaceholderButtonUi("Btools", "Btools", 8)
btoolsButton.LayoutOrder = 8; btoolsButton.Parent = mainMenu

local function getPlayerCharacter(player)
    return player and player.Character
end

local function toggleFlight(enable)
    Character = getPlayerCharacter(LocalPlayer)
    if not Character or not Character:FindFirstChild("HumanoidRootPart") then return end
    RootPart = Character.HumanoidRootPart
    Humanoid = Character:FindFirstChildOfClass("Humanoid")
    if not Humanoid then return end

    isFlying = enable
    if enable then
        if not flightBodyVelocity then
            flightBodyVelocity = Instance.new("BodyVelocity", RootPart)
            flightBodyVelocity.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
            flightBodyVelocity.P = 10000
        end
        if not flightBodyGyro then
            flightBodyGyro = Instance.new("BodyGyro", RootPart)
            flightBodyGyro.MaxTorque = Vector3.new(math.huge, math.huge, math.huge)
            flightBodyGyro.P = 10000
        end
        flightBodyVelocity.Velocity = Vector3.new(0,0.1,0)
        flightBodyGyro.CFrame = RootPart.CFrame
        Humanoid.PlatformStand = true

        if not flightRenderSteppedConnection or not flightRenderSteppedConnection.Connected then
            flightRenderSteppedConnection = RunService.RenderStepped:Connect(function()
                if isFlying and flightBodyVelocity and flightBodyGyro and RootPart and Workspace.CurrentCamera then
                    local camera = Workspace.CurrentCamera
                    local speed = getFlightSpeed()
                    local direction = camera.CFrame.LookVector
                    flightBodyVelocity.Velocity = direction * speed
                    flightBodyGyro.CFrame = camera.CFrame
                else
                    if isFlying then toggleFlight(false) end
                end
            end)
        end
    else
        if flightRenderSteppedConnection and flightRenderSteppedConnection.Connected then
            flightRenderSteppedConnection:Disconnect()
            flightRenderSteppedConnection = nil
        end
        if flightBodyVelocity then flightBodyVelocity:Destroy(); flightBodyVelocity = nil; end
        if flightBodyGyro then flightBodyGyro:Destroy(); flightBodyGyro = nil; end
        if Humanoid then Humanoid.PlatformStand = false; end
    end
    print("Flight " .. (enable and "Enabled" or "Disabled"))
end

local function toggleNoclip(enable)
    Character = getPlayerCharacter(LocalPlayer)
    if not Character or not Character:FindFirstChild("HumanoidRootPart") then
        print("Noclip: Character or HumanoidRootPart not found.")
        return
    end
    Humanoid = Character:FindFirstChildOfClass("Humanoid")
    if not Humanoid then
        print("Noclip: Humanoid not found.")
        return
    end

    noclipEnabled = enable

    for _, part in ipairs(Character:GetDescendants()) do
        if part:IsA("BasePart") then
            if enable then
                originalCollisionStates[part] = part.CanCollide
                part.CanCollide = false
            else
                if originalCollisionStates[part] ~= nil then
                    part.CanCollide = originalCollisionStates[part]
                end
            end
        end
    end
    if Humanoid then
        local state = not enable
        Humanoid:SetStateEnabled(Enum.HumanoidStateType.GettingUp, state)
        Humanoid:SetStateEnabled(Enum.HumanoidStateType.FallingDown, state)
        Humanoid:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, state)
        Humanoid:SetStateEnabled(Enum.HumanoidStateType.Seated, state)
        Humanoid:ChangeState(enable and Enum.HumanoidStateType.Physics or Enum.HumanoidStateType.Running)
    end
    print("Noclip " .. (enable and "Enabled" or "Disabled"))
end

local function updateEspTarget(player)
    local playerChar = getPlayerCharacter(player)
    local head = playerChar and playerChar:FindFirstChild("Head")

    if not head or player == LocalPlayer then
        if espBillboardGuis[player] then
            espBillboardGuis[player]:Destroy()
            espBillboardGuis[player] = nil
        end
        return
    end

    if not espBillboardGuis[player] or not espBillboardGuis[player].Parent then
        if espBillboardGuis[player] then espBillboardGuis[player]:Destroy() end

        local billboardGui = Instance.new("BillboardGui")
        billboardGui.Name = "PlayerESP_" .. player.UserId
        billboardGui.Adornee = head
        billboardGui.Size = UDim2.new(0, 120, 0, 22)
        billboardGui.StudsOffset = Vector3.new(0, 2.8, 0)
        billboardGui.AlwaysOnTop = true
        billboardGui.LightInfluence = 0
        billboardGui.ResetOnSpawn = false

        local textLabel = Instance.new("TextLabel")
        textLabel.Name = "NameLabel"
        textLabel.Text = player.DisplayName .. " (" .. player.Name .. ")"
        textLabel.TextColor3 = player.TeamColor.Color or Color3.fromRGB(230,230,230)
        textLabel.BackgroundColor3 = Color3.fromRGB(20,20,20)
        textLabel.BackgroundTransparency = 0.3
        textLabel.Size = UDim2.new(1,0,1,0)
        textLabel.Font = Enum.Font.SourceSansSemibold
        textLabel.TextSize = 13
        textLabel.Parent = billboardGui

        espBillboardGuis[player] = billboardGui
        billboardGui.Parent = CoreGui
    else
        espBillboardGuis[player].Adornee = head
        espBillboardGuis[player].Enabled = true
    end
end

local function toggleEsp(enable)
    espEnabled = enable
    if enable then
        local function setupPlayerEsp(player)
            if player ~= LocalPlayer then
                local charAddedKey = "CharAdded_" .. player.UserId
                if espConnections[charAddedKey] then espConnections[charAddedKey]:Disconnect() end

                espConnections[charAddedKey] = player.CharacterAdded:Connect(function(char)
                    updateEspTarget(player)
                end)
                if player.Character then updateEspTarget(player) end
            end
        end

        for _, p in ipairs(Players:GetPlayers()) do setupPlayerEsp(p) end
        if espConnections["PlayerAdded"] then espConnections["PlayerAdded"]:Disconnect() end
        espConnections["PlayerAdded"] = Players.PlayerAdded:Connect(setupPlayerEsp)

        if espConnections["PlayerRemoving"] then espConnections["PlayerRemoving"]:Disconnect() end
        espConnections["PlayerRemoving"] = Players.PlayerRemoving:Connect(function(removedPlayer)
            if espBillboardGuis[removedPlayer] then
                espBillboardGuis[removedPlayer]:Destroy()
                espBillboardGuis[removedPlayer] = nil
            end
            local charAddedKey = "CharAdded_" .. removedPlayer.UserId
            if espConnections[charAddedKey] then
                espConnections[charAddedKey]:Disconnect()
                espConnections[charAddedKey] = nil
            end
        end)

        if not espRenderSteppedConnection or not espRenderSteppedConnection.Connected then
            espRenderSteppedConnection = RunService.RenderStepped:Connect(function()
                if espEnabled then
                    for _, p_loop in ipairs(Players:GetPlayers()) do
                        if p_loop ~= LocalPlayer then updateEspTarget(p_loop) end
                    end
                end
            end)
        end
    else
        if espRenderSteppedConnection and espRenderSteppedConnection.Connected then
            espRenderSteppedConnection:Disconnect()
            espRenderSteppedConnection = nil
        end
        for _, gui in pairs(espBillboardGuis) do if gui then gui:Destroy() end end
        espBillboardGuis = {}
        for key, conn in pairs(espConnections) do if conn then conn:Disconnect() end end
        espConnections = {}
    end
    print("ESP " .. (enable and "Enabled" or "Disabled"))
end

function applySpeed()
    Character = getPlayerCharacter(LocalPlayer)
    if not Character then return end
    Humanoid = Character:FindFirstChildOfClass("Humanoid")
    if not Humanoid then return end

    if speedEnabled then
        Humanoid.WalkSpeed = getWalkSpeed()
    else
        Humanoid.WalkSpeed = originalWalkSpeed
    end
end

local function toggleSpeed(enable)
    speedEnabled = enable
    applySpeed()
    print("Speed Override " .. (enable and "Enabled with value: " .. getWalkSpeed() or "Disabled, speed reset to: " .. originalWalkSpeed))
end

flightButton.MouseButton1Click:Connect(function()
    toggleFlight(not isFlying)
    flightButton.Text = "Flight: " .. (isFlying and "ON" or "OFF")
    flightButton.BackgroundColor3 = isFlying and Color3.fromRGB(0, 150, 0) or Color3.fromRGB(80, 80, 80)
end)

noclipButton.MouseButton1Click:Connect(function()
    toggleNoclip(not noclipEnabled)
    noclipButton.Text = "Noclip: " .. (noclipEnabled and "ON" or "OFF")
    noclipButton.BackgroundColor3 = noclipEnabled and Color3.fromRGB(0, 150, 0) or Color3.fromRGB(80, 80, 80)
end)

espButton.MouseButton1Click:Connect(function()
    toggleEsp(not espEnabled)
    espButton.Text = "ESP: " .. (espEnabled and "ON" or "OFF")
    espButton.BackgroundColor3 = espEnabled and Color3.fromRGB(0, 150, 0) or Color3.fromRGB(80, 80, 80)
end)

speedButton.MouseButton1Click:Connect(function()
    toggleSpeed(not speedEnabled)
    speedButton.Text = "Speed: " .. (speedEnabled and "ON" or "OFF")
    speedButton.BackgroundColor3 = speedEnabled and Color3.fromRGB(0, 150, 0) or Color3.fromRGB(80, 80, 80)
end)

teleportButton.MouseButton1Click:Connect(function() print("Teleport to Player button clicked (placeholder).") end)
killPlayerButton.MouseButton1Click:Connect(function() print("Kill Player button clicked (placeholder).") end)
viewScriptsButton.MouseButton1Click:Connect(function() print("View Server Scripts button clicked (placeholder).") end)
btoolsButton.MouseButton1Click:Connect(function() print("Btools button clicked (placeholder).") end)

local isFloatingButtonDragging = false
local floatingButtonDragStartPos = Vector2.new()
    noclipButton.BackgroundColor3 = noclipEnabled and Color3.fromRGB(0, 150, 0) or Color3.fromRGB(80, 80, 80)
end)

local isFloatingButtonDragging = false
local floatingButtonDragStartPos = Vector2.new()
local floatingButtonOriginalUIPos = Vector2.new()

local function makeDraggable(button)
    button.Active = true
    button.Draggable = false

    local currentDragInputObject = nil

    button.InputBegan:Connect(function(inputObject)
        if inputObject.UserInputType == Enum.UserInputType.MouseButton1 or inputObject.UserInputType == Enum.UserInputType.Touch then
            isFloatingButtonDragging = true
            floatingButtonDragStartPos = inputObject.Position
            floatingButtonOriginalUIPos = button.AbsolutePosition
            currentDragInputObject = inputObject

            local inputChangedConnection
            local inputEndedConnection

            inputChangedConnection = UserInputService.InputChanged:Connect(function(changedInputObject)
                if not isFloatingButtonDragging or changedInputObject.UserInputType ~= currentDragInputObject.UserInputType then
                    return
                end

                if isFloatingButtonDragging then
                    local guiParent = button.Parent
                    if not guiParent then return end

                    local screen = guiParent.AbsoluteSize
                    local delta = changedInputObject.Position - floatingButtonDragStartPos
                    local newAbsolutePos = floatingButtonOriginalUIPos + delta
                    local buttonSize = button.AbsoluteSize

                    newAbsolutePos = Vector2.new(
                        math.clamp(newAbsolutePos.X, 0, screen.X - buttonSize.X),
                        math.clamp(newAbsolutePos.Y, 0, screen.Y - buttonSize.Y)
                    )
                    button.Position = UDim2.fromOffset(newAbsolutePos.X, newAbsolutePos.Y)
                end
            end)

            inputEndedConnection = UserInputService.InputEnded:Connect(function(endedInputObject)
                if endedInputObject.UserInputType == currentDragInputObject.UserInputType then
                    isFloatingButtonDragging = false
                    currentDragInputObject = nil
                    if inputChangedConnection then inputChangedConnection:Disconnect() end
                    if inputEndedConnection then inputEndedConnection:Disconnect() end
                end
            end)
        end
    end)
end

makeDraggable(floatingButton)

local menuOpen = false
local menuTween = nil
local menuTweenCompletedConnection = nil

function toggleMenu()
    if not mainMenu then
        print("AdminMenu Error: toggleMenu called but mainMenu is nil. Cannot open/close menu.")
        return
    end

    if menuTween and menuTween.PlaybackState == Enum.PlaybackState.Playing then
        menuTween:Cancel()
    end
    if menuTweenCompletedConnection then
        menuTweenCompletedConnection:Disconnect()
        menuTweenCompletedConnection = nil
    end

    menuOpen = not menuOpen
    local goalPosition

    if menuOpen then
        mainMenu.Visible = true
        mainMenu.ZIndex = 20
        task.wait()
        if not screenGui or not mainMenu then return end

        local targetPositionXScale = 0
        local targetPositionXOffset = PADDING
        local menuYPosition = screenGui.AbsoluteSize.Y > 0 and -mainMenu.AbsoluteSize.Y / 2 or 0
        goalPosition = UDim2.new(targetPositionXScale, targetPositionXOffset, 0.5, menuYPosition)
    else
        if not screenGui or not mainMenu or mainMenu.AbsoluteSize.X == 0 or screenGui.AbsoluteSize.X == 0 then
            mainMenu.Visible = false
            mainMenu.ZIndex = 5
            return
        end
        local targetPositionXScale = - (mainMenu.AbsoluteSize.X / screenGui.AbsoluteSize.X) - 0.05
        local targetPositionXOffset = 0
        local menuYPosition = screenGui.AbsoluteSize.Y > 0 and -mainMenu.AbsoluteSize.Y / 2 or 0
        goalPosition = UDim2.new(targetPositionXScale, targetPositionXOffset, 0.5, menuYPosition)
    end

    local tweenInfo = TweenInfo.new(0.25, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
    menuTween = TweenService:Create(mainMenu, tweenInfo, {Position = goalPosition})
    menuTween:Play()

    menuTweenCompletedConnection = menuTween.Completed:Connect(function(state)
        if menuTweenCompletedConnection then
            menuTweenCompletedConnection:Disconnect()
            menuTweenCompletedConnection = nil
        end
        if state == Enum.TweenStatus.Completed then
            if not menuOpen then
                mainMenu.Visible = false
                mainMenu.ZIndex = 5
            end
        end
    end)
end

floatingButton.MouseButton1Click:Connect(toggleMenu)
closeButton.MouseButton1Click:Connect(toggleMenu)

print("Admin Menu Script Loaded (Structure V2)")
LocalPlayer.CharacterAdded:Connect(function(newChar)
    Character = newChar
    Humanoid = newChar:WaitForChild("Humanoid")
    RootPart = newChar:WaitForChild("HumanoidRootPart")
    originalWalkSpeed = Humanoid.WalkSpeed
    originalJumpPower = Humanoid.JumpPower

    if isFlying then toggleFlight(false); toggleFlight(true); end
    if noclipEnabled then toggleNoclip(false); toggleNoclip(true); end
    if speedEnabled then applySpeed() end
end)
