--------------------------------------------------
--// CORE INITIALIZATION
--------------------------------------------------

--// Libraries
local Starlight = loadstring(game:HttpGet("https://raw.nebulasoftworks.xyz/starlight"))()
local NebulaIcons = loadstring(game:HttpGet("https://raw.nebulasoftworks.xyz/nebula-icon-library-loader"))()

--// Services
local Players = game:GetService("Players")
local StarterGui = game:GetService("StarterGui")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

--// Locals
local localPlayer = Players.LocalPlayer
local hitboxEnabled = false
local hitboxSizeMultiplier = 10
local hitboxTransparency = 0.9
local noJumpCooldownEnabled = false
local originalHitboxData = {}

--------------------------------------------------
--// UI SETUP
--------------------------------------------------

local Window = Starlight:CreateWindow({
	Name = "The Dihsaster",
	Subtitle = "made by @ntwau",
	Icon = 97475025083291,
	LoadingEnabled = "true",

	LoadingSettings = {
		Title = "The Dihsaster",
		Subtitle = "PLAY MY GAME",
		Logo = 84884444944085,
	},

	FileSettings = {
		ConfigFolder = "TDih"
	},
})

Window:CreateHomeTab({
	SupportedExecutors = {"Volcano", "Delta", "Codex"},
	UnsupportedExecutors = {},
	DiscordInvite = "z4HXmCF77j",
	Backdrop = 0,
	IconStyle = 2,
	Changelog = {
		{
			Title = "Release",
			Date = "10/20/25",
			Description = "blablabla release",
		}
	}
})

local TabSection = Window:CreateTabSection("The Disaster")

local Tab = TabSection:CreateTab({
	Name = "Main",
	Icon = NebulaIcons:GetIcon("house", "Material"),
	Columns = 2,
}, "MainTab")

--------------------------------------------------
--// HITBOX SECTION
--------------------------------------------------

local HitboxGroupbox = Tab:CreateGroupbox({
	Name = "Hitbox",
	Column = 1,
}, "HitboxGB")

HitboxGroupbox:CreateParagraph({
	Name = "Warning",
	Icon = NebulaIcons:GetIcon("triangle-alert", "Lucide"),
	Content = "This only works with the following abilities: Arm Cannon, Zapper, Homing Attack, Boost, Push, Grapple, Spindash, and Charge",
}, "HitboxWarning")

--// Resize and reset logic
local function resizeOtherPlayers()
	if not hitboxEnabled then return end

	for _, player in ipairs(Players:GetPlayers()) do
		if player ~= localPlayer then
			local character = player.Character
			if character then
				local torsoFolder = character:FindFirstChild("torso")
				if torsoFolder then
					local collisionMesh = torsoFolder:FindFirstChild("collision")

					if collisionMesh and collisionMesh:IsA("MeshPart") then
						if not originalHitboxData[collisionMesh] then
							originalHitboxData[collisionMesh] = {
								Size = collisionMesh.Size,
								Transparency = collisionMesh.Transparency,
								CanCollide = collisionMesh.CanCollide
							}
						end

						collisionMesh.Size = Vector3.new(2, 2, 1) * hitboxSizeMultiplier
						collisionMesh.CanCollide = false
						collisionMesh.Transparency = hitboxTransparency
					end
				end
			end
		end
	end
end

local function resetHitboxes()
	for mesh, data in pairs(originalHitboxData) do
		if mesh and mesh.Parent then
			mesh.Size = data.Size
			mesh.Transparency = data.Transparency
			mesh.CanCollide = data.CanCollide
		end
	end
	table.clear(originalHitboxData)
end

task.spawn(function()
	while task.wait(3) do
		if hitboxEnabled then
			resizeOtherPlayers()
		end
	end
end)

Players.PlayerAdded:Connect(function(player)
	player.CharacterAdded:Connect(function()
		task.wait(1)
		if hitboxEnabled then resizeOtherPlayers() end
	end)
end)

localPlayer.CharacterAdded:Connect(function()
	task.wait(1)
	if hitboxEnabled then resizeOtherPlayers() end
end)

HitboxGroupbox:CreateToggle({
	Name = "Enable Hitbox Changer",
	Tooltip = "Toggles hitbox resizing for other players.",
	Style = 1,
	CurrentValue = false,
	Icon = NebulaIcons:GetIcon("box", "Lucide"),
	Callback = function(Value)
		hitboxEnabled = Value
		if hitboxEnabled then
			resizeOtherPlayers()
		else
			resetHitboxes()
		end
	end,
}, "HitboxToggle")

HitboxGroupbox:CreateSlider({
	Name = "Hitbox Size",
	Tooltip = "Adjusts the scale of other players' hitboxes.",
	Icon = NebulaIcons:GetIcon("scaling", "Lucide"),
	Range = {1, 50},
	Increment = 1,
	CurrentValue = hitboxSizeMultiplier,
	Suffix = "x",
	Callback = function(Value)
		hitboxSizeMultiplier = Value
		if hitboxEnabled then resizeOtherPlayers() end
	end,
}, "HitboxSlider")

HitboxGroupbox:CreateSlider({
	Name = "Hitbox Transparency",
	Tooltip = "Controls visibility of resized hitboxes.",
	Icon = NebulaIcons:GetIcon("blend", "Lucide"),
	Range = {0, 1},
	Increment = 0.1,
	CurrentValue = hitboxTransparency,
	Callback = function(Value)
		hitboxTransparency = Value
		if hitboxEnabled then resizeOtherPlayers() end
	end,
}, "HitboxTransSlider")

--------------------------------------------------
--// NO JUMP COOLDOWN SECTION
--------------------------------------------------

local JumpGroupbox = Tab:CreateGroupbox({
	Name = "No Jump Cooldown",
	Column = 2,
}, "NoJumpCDGB")

task.spawn(function()
	while task.wait(0.1) do
		pcall(function()
			StarterGui:SetCore("JumpButtonEnabled", true)
			StarterGui:SetCore("JumpButtonVisible", true)
		end)
	end
end)

local function setupCharacter(char)
	local humanoid = char:WaitForChild("Humanoid")
	RunService.RenderStepped:Connect(function()
		if humanoid then
			if noJumpCooldownEnabled then
				humanoid:SetStateEnabled(Enum.HumanoidStateType.Jumping, true)
			end
			humanoid.AutoJumpEnabled = false
		end
	end)
end

if localPlayer.Character then
	setupCharacter(localPlayer.Character)
end
localPlayer.CharacterAdded:Connect(setupCharacter)

JumpGroupbox:CreateToggle({
	Name = "No Jump Cooldown",
	Tooltip = "Removes jump delay so you can jump repeatedly without cooldown.",
	Icon = NebulaIcons:GetIcon("circle-chevron-up", "Lucide"),
	CurrentValue = false,
	Style = 2,
	Callback = function(Value)
		noJumpCooldownEnabled = Value
	end,
}, "NoJumpCD")

--------------------------------------------------
--// IMMORTALITY SECT
--------------------------------------------------

local ImmortalGroupbox = Tab:CreateGroupbox({
	Name = "Character Select",
	Column = 2,
}, "ImmortalGB")

--------------------------------------------------
--// PERMA IMMORTALITY LOOP SCRIPT
--------------------------------------------------

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local InvEvent = workspace.game.WorkspaceStuff.SetInvincibilityScript:FindFirstChild("SetInvincibility")

if not InvEvent then
    warn("⚠️ SetInvincibility event not found!")
    return
end

--------------------------------------------------
--// VARIABLES
--------------------------------------------------

local immortalityLoop
local metatableHookEnabled = false
local originalNamecall

--------------------------------------------------
--// FUNCTIONS
--------------------------------------------------

local function enableImmortality()
    -- Enable metatable hook to block Remove calls
    if not metatableHookEnabled then
        local mt = getrawmetatable(game)
        setreadonly(mt, false)
        originalNamecall = mt.__namecall
        
        mt.__namecall = function(self, ...)
            local method = getnamecallmethod()
            local args = { ... }
            
            if method == "FireServer" and self == InvEvent then
                local action = args[2]
                if action == "Remove" then
                    return -- 🚫 Block any Remove attempts
                end
            end
            
            return originalNamecall(self, ...)
        end
        
        setreadonly(mt, true)
        metatableHookEnabled = true
    end
    
    -- Start immortality loop
    immortalityLoop = task.spawn(function()
        while task.wait(2) do -- 🔁 Fires every 2 seconds (adjust as needed)
            local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
            if Character and InvEvent then
                InvEvent:FireServer(Character, "Add")
            end
        end
    end)
    
    print("🟢 Immortality loop active — blocking Remove calls.")
end

local function disableImmortality()
    -- Stop immortality loop
    if immortalityLoop then
        task.cancel(immortalityLoop)
        immortalityLoop = nil
    end
    
    -- Restore original metatable
    if metatableHookEnabled then
        local mt = getrawmetatable(game)
        setreadonly(mt, false)
        mt.__namecall = originalNamecall
        setreadonly(mt, true)
        metatableHookEnabled = false
    end
    
    print("🔴 Immortality loop disabled.")
end

local Toggle = ImmortalGroupbox:CreateToggle({
    Name = "Immortality",
    CurrentValue = false,
    Style = 2,
    Callback = function(Value)
        if Value then
            enableImmortality()
        else
            disableImmortality()
        end
    end,
}, "ImmortalToggle")

--------------------------------------------------
--// CHARACTER SELECT SECTION
--------------------------------------------------

local CharacterGroupbox = Tab:CreateGroupbox({
	Name = "Character Select",
	Column = 1,
}, "CharacterGB")

local Label = CharacterGroupbox:CreateLabel({
	Name = "Survivors",
}, "CharacterLabel")

local selectedCharacter = nil

Label:AddDropdown({
	Options = {"tails", "knuckles", "eggman", "amy", "cream", "sally", "shadow", "rouge", "metalsonic", "silver", "blaze"},
	CurrentOption = "tails",
	Placeholder = "None Selected",
	Callback = function(Option)
		if typeof(Option) == "table" then
			selectedCharacter = Option[1]
		else
			selectedCharacter = Option
		end
		print("Selected character:", selectedCharacter)
	end,
}, "CharacterDropdown")

CharacterGroupbox:CreateButton({
	Name = "Select",
	Icon = NebulaIcons:GetIcon("check", "Material"),
	Callback = function()
		if selectedCharacter then
			local args = { selectedCharacter }
			ReplicatedStorage.remotes.morphs:FireServer(unpack(args))
			print("Morphed into:", selectedCharacter)
		else
			warn("No character selected!")
		end
	end,
}, "CharacterSelectButton")

--------------------------------------------------
--// VISUAL SECTION
--------------------------------------------------

local VisualTab = TabSection:CreateTab({
	Name = "Visual",
	Icon = NebulaIcons:GetIcon("visibility", "Material"),
	Columns = 2,
}, "VisualTab")

local VisualGroupbox = VisualTab:CreateGroupbox({
	Name = "Atmosphere",
	Column = 1,
}, "VisualGB")

VisualGroupbox:CreateToggle({
	Name = "Disable Blur",
	Tooltip = "Toggles the Lighting blur effect.",
	Icon = NebulaIcons:GetIcon("glasses", "Lucide"),
	Style = 2,
	CurrentValue = false,
	Callback = function(Value)
		local blur = Lighting:FindFirstChildOfClass("BlurEffect")
		if blur then
			blur.Enabled = not Value
		end
	end,
}, "BlurToggle")

local DefaultFogEnd = Lighting.FogEnd
local DefaultAtmosphere = Lighting:FindFirstChildOfClass("Atmosphere")
local SavedAtmosphereClone = DefaultAtmosphere and DefaultAtmosphere:Clone() or nil

VisualGroupbox:CreateToggle({
	Name = "No Fog",
	Icon = NebulaIcons:GetIcon("cloud-off", "Lucide"),
	Style = 2,
	CurrentValue = false,
	Callback = function(Value)
		if Value then
			for _, v in pairs(Lighting:GetDescendants()) do
				if v:IsA("Atmosphere") then
					v:Destroy()
				end
			end
		else
			if SavedAtmosphereClone and not Lighting:FindFirstChildOfClass("Atmosphere") then
				SavedAtmosphereClone:Clone().Parent = Lighting
			end
		end
	end,
}, "NoAtmosphereToggle")

--------------------------------------------------
--// CLEANUP ON DESTROY
--------------------------------------------------

Starlight:OnDestroy(function()
	if hitboxEnabled then
		resetHitboxes()
	end

	if Lighting then
		if Lighting.FogEnd ~= DefaultFogEnd then
			Lighting.FogEnd = DefaultFogEnd
		end

		if DefaultAtmosphere and not Lighting:FindFirstChildOfClass("Atmosphere") then
			DefaultAtmosphere:Clone().Parent = Lighting
		end
	end

	noJumpCooldownEnabled = false

	local blur = Lighting:FindFirstChildOfClass("BlurEffect")
	if blur then
		blur.Enabled = true
	end
end)
