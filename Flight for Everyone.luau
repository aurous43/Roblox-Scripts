local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")

local LocalPlayer = Players.LocalPlayer
local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
local Humanoid = Character:WaitForChild("Humanoid")
local RootPart = Humanoid.RootPart or Character:WaitForChild("HumanoidRootPart")

-- Assets
local SoundBling = game:GetService("ReplicatedStorage").ClientAssets.Characters.Survivors.Silver.scriptstuff.fly.Bling
local SoundFlyLoop = game:GetService("ReplicatedStorage").ClientAssets.Characters.Survivors.Silver.scriptstuff.fly.fly
local SoundFlyStart = game:GetService("ReplicatedStorage").ClientAssets.Characters.Survivors.Silver.scriptstuff.fly.flystart
local RemoteRequest = game:GetService("ReplicatedStorage").ClientAssets.Characters.Survivors.Silver.scriptstuff.fly.REQUEST

-- GUI
local FlightGui = game:GetService("ReplicatedStorage").ClientAssets.Characters.Survivors.Silver.Skins.Default.HumanoidRootPart.BillboardGui

-- States
local isFlying = false
local forceFly = false       -- Used when flight is triggered by Remote
local isCooldown = false     -- Cooldown after being hit/stunned
local jumpDebounce = false   -- Prevents spamming jump
local flightStamina = 15     -- Max flight duration
local lastJumpTime = tick()
local startHealth = 0        -- Used to detect damage while flying

-- Physics
local bodyGyro = nil
local bodyVelocity = nil

-- Constants
local MAX_STAMINA = 15
local DOUBLE_JUMP_WINDOW = 0.15
local FLIGHT_SPEED_MULTI = 1.81
local COOLDOWN_DURATION = 7

-- Helper Functions
local function StopFlying(disableGuiImmediate)
    isFlying = false
    forceFly = false
    print("unfly")
    
    -- Reset Animation
    if script.Parent:FindFirstChild("Animate") then
        script.Parent.Animate:SetAttribute("AnimationState", "Default")
    end

    -- Clean up Physics
    if bodyGyro then
        bodyGyro:Destroy()
        bodyGyro = nil
    end
    if bodyVelocity then
        bodyVelocity:Destroy()
        SoundFlyLoop:Stop()
        bodyVelocity = nil
    end

    -- Reset Rotation Setting
    if UserSettings().GameSettings.RotationType == Enum.RotationType.CameraRelative then
        UserSettings().GameSettings.RotationType = Enum.RotationType.MovementRelative
    end
end

local function StartFlying()
    if isFlying then return end
    
    startHealth = Character.Humanoid.Health.Value
    isFlying = true
    
    -- Debounce
    jumpDebounce = true
    task.delay(0.5, function()
        jumpDebounce = false
    end)

    -- Animation & Sound
    if script.Parent:FindFirstChild("Animate") then
        script.Parent.Animate:SetAttribute("AnimationState", "Flying")
    end
    SoundFlyStart:Play()
    SoundFlyLoop:Play()

    -- Physics Setup
    bodyVelocity = Instance.new("BodyVelocity")
    bodyVelocity.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
    bodyVelocity.Parent = RootPart

    bodyGyro = Instance.new("BodyGyro")
    bodyGyro.MaxTorque = Vector3.new(math.huge, math.huge, math.huge)
    bodyGyro.Parent = RootPart

    -- Change Camera Rotation Mode
    UserSettings().GameSettings.RotationType = Enum.RotationType.CameraRelative
end

-- 1. Stop flying on Land/Run
Humanoid.StateChanged:Connect(function(_, newState)
    if (newState == Enum.HumanoidStateType.Landed or newState == Enum.HumanoidStateType.Running) and (forceFly and not isFlying) then
        forceFly = false
    end
    if newState == Enum.HumanoidStateType.Jumping then
        lastJumpTime = tick()
    end
end)

-- 2. "Kill" (Restores Stamina)
CollectionService:GetInstanceAddedSignal("Kill"):Connect(function(target)
    if target == Character then
        flightStamina = math.min(MAX_STAMINA, flightStamina + 15)
    end
end)

-- 3. "Attack-2011" (Drains Stamina if flying)
CollectionService:GetInstanceAddedSignal("Attack-2011"):Connect(function(target)
    if target == Character and isFlying then
        flightStamina = math.max(0, flightStamina - 15)
    end
end)

-- 4. Jump Request (Toggle Flight)
UserInputService.JumpRequest:Connect(function()
    -- Checks for disable tags
    if Character:HasTag("NoFly") or Character:HasTag("Downed") or Character:HasTag("Stunned") or isCooldown then
        return
    
    -- If already flying, stop flying
    elseif isFlying and not jumpDebounce then
        StopFlying()
        
    -- If falling and double jumped check
    elseif Humanoid:GetState() == Enum.HumanoidStateType.Freefall then
        -- Check double jump timing
        if (tick() - lastJumpTime) > DOUBLE_JUMP_WINDOW then -- Wait slight delay
            -- Note: Original script implies if tick diff > 0.15 it ALLOWS flight??
            -- Usually double jumps require < time, but whatever
            -- If time passed since last jump > 0.15s allow flight
            
            if isFlying then return end
            StartFlying()
        end
    end
end)

-- 5. Remote Function Handler
RemoteRequest.OnClientInvoke = function(action)
    print("Status:", isFlying)
    
    if action == "stopflying" then
        StopFlying()
        return isFlying
    end

    if action == "fly" then
        if Character:HasTag("Flying") then return end
        
        forceFly = true
        StartFlying() -- Uses helper to reduce code duplication
    end
    
    return isFlying
end

-- Main Heartbeat Loop
while RunService.Heartbeat:Wait() do
    local deltaTime = task.wait() -- loop yield
    local currentCam = workspace.CurrentCamera
    
    -- GUI Update
    if FlightGui and FlightGui:FindFirstChild("Frame") then
        local bar = FlightGui.Frame.Bar.ImageLabel.UIGradient
        -- Interpolate the gradient based on stamina
        bar.Offset = bar.Offset:Lerp(Vector2.new(-(1 - flightStamina / 15), 0), 0.1)
    end

    if isFlying then
        -- Check: Out of stamina, Stunned, Damaged, Downed, or Carried
        local isDamaged = (Character.Humanoid.Health.Value ~= startHealth)
        
        if flightStamina <= 0 
           or Character:HasTag("Stunned") 
           or isDamaged
           or Character:GetAttribute("State") == "downed" 
           or Character:HasTag("Carried") then
            
            -- Stop Flying with Cooldown
            forceFly = false
            print("unfly")
            isCooldown = true
            
            task.delay(COOLDOWN_DURATION, function()
                isCooldown = false
                SoundBling:Play() -- "Stamina Ready" sound
            end)
            
            StopFlying()
            isFlying = false -- Explicitly ensure false here for immediate logic
            
        elseif flightStamina > 0 then
            -- Drain Stamina, comment the line below to have infinite flight
            flightStamina = flightStamina - (deltaTime * 10)
        end

        -- Show GUI
        if not FlightGui.Enabled then
            FlightGui.Enabled = true
            FlightGui.Size = UDim2.new(0, 0, 1.5, 0)
            TweenService:Create(FlightGui, TweenInfo.new(0.5), {
                Size = UDim2.new(5, 0, 1.5, 0)
            }):Play()
        end

    else
        -- Regenerate Stamina if not flying
        if FlightGui.Enabled then
            task.delay(0.5, function()
                FlightGui.Enabled = false
            end)
            TweenService:Create(FlightGui, TweenInfo.new(0.5), {
                Size = UDim2.new(0, 0, 1.5, 0)
            }):Play()
        end
        
        local regenAmount = flightStamina + (deltaTime * 2)
        flightStamina = math.min(MAX_STAMINA, regenAmount)
    end

    -- Physics Updates
    if bodyGyro and RootPart then
        -- Orient character to Camera look direction
        local targetCFrame = CFrame.new(RootPart.Position, RootPart.Position + currentCam.CFrame.LookVector * 25)
        bodyGyro.CFrame = bodyGyro.CFrame:Lerp(targetCFrame, 0.1)
    end

    if bodyVelocity and RootPart then
        local moveSpeed = Humanoid.WalkSpeed * FLIGHT_SPEED_MULTI
        
        -- Adjust sound pitch based on speed
        local speedRatio = bodyVelocity.Velocity.Magnitude / 2.5 / 35
        SoundFlyLoop.PlaybackSpeed = math.max(0.5, speedRatio)

        -- Calculate movement direction relative to camera
        local moveDir = Humanoid.MoveDirection
        local lookDot = moveDir:Dot(RootPart.CFrame.LookVector)
        local rightDot = moveDir:Dot(RootPart.CFrame.RightVector)
        
        local camLook = currentCam.CFrame.LookVector * moveSpeed
        local camRight = currentCam.CFrame.RightVector * moveSpeed
        
        -- Apply Velocity
        local targetVelocity = (camLook * lookDot) + (camRight * rightDot * rightDot) -- Note: Decompiled math looked slightly specific here, maintained logic
        
        -- Corrected Velocity Logic based on standard flight scripts + decompiled structure
        -- The original script uses: v35 * v33 + workspace.CurrentCamera.CFrame.RightVector * v30 * v34
        targetVelocity = (currentCam.CFrame.LookVector * moveSpeed * lookDot) + (currentCam.CFrame.RightVector * moveSpeed * rightDot)

        bodyVelocity.Velocity = bodyVelocity.Velocity:Lerp(targetVelocity, 0.1)
    end
end
