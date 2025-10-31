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

local function onCharacterAdded(character)
	task.wait(1)
	if hitboxEnabled then resizeOtherPlayers() end
end

Players.PlayerAdded:Connect(function(player)
	player.CharacterAdded:Connect(onCharacterAdded)
end)

localPlayer.CharacterAdded:Connect(onCharacterAdded)

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
--// IMMORTALITY SECTION
--------------------------------------------------

local InvEvent = workspace.game.WorkspaceStuff.SetInvincibilityScript:FindFirstChild("SetInvincibility")

if not InvEvent then
	warn("SetInvincibility event not found!")
end

--// Variables
local ImmortalLoop = nil
local Hooked = false
local OldNamecall
local mt = getrawmetatable(game)
local temporaryDisableEnabled = false
local canTemporarilyDisable = true
local immortalityEnabled = false

--// Functions
local function HookRemoveBlock()
	if Hooked then return end
	Hooked = true

	setreadonly(mt, false)
	OldNamecall = mt.__namecall

	mt.__namecall = function(self, ...)
		local method = getnamecallmethod()
		local args = { ... }

		if method == "FireServer" and self == InvEvent then
			if args[2] == "Remove" then
				return -- Block "Remove" calls
			end
		end

		return OldNamecall(self, ...)
	end

	setreadonly(mt, true)
end

local function UnhookRemoveBlock()
	if not Hooked then return end
	Hooked = false

	setreadonly(mt, false)
	mt.__namecall = OldNamecall
	setreadonly(mt, true)
end

local function StartImmortality()
	if ImmortalLoop then return end
	HookRemoveBlock()

	immortalityEnabled = true
	ImmortalLoop = task.spawn(function()
		while immortalityEnabled do
			task.wait(2)
			local Character = localPlayer.Character or localPlayer.CharacterAdded:Wait()
			if Character and InvEvent then
				InvEvent:FireServer(Character, "Add")
			end
		end
	end)
end

local function StopImmortality()
	if ImmortalLoop then
		task.cancel(ImmortalLoop)
		ImmortalLoop = nil
	end
	immortalityEnabled = false
	UnhookRemoveBlock()
end

--------------------------------------------------
--// UI
--------------------------------------------------

local ImmortalGroupbox = Tab:CreateGroupbox({
	Name = "Immortality",
	Column = 2,
}, "ImmortalGB")

-- Main immortality toggle
ImmortalGroupbox:CreateToggle({
	Name = "Immortality",
	Icon = NebulaIcons:GetIcon("shield", "Material"),
	CurrentValue = false,
	Style = 2,
	Callback = function(Value)
		if Value then
			StartImmortality()
			print("🟢 Immortality enabled — blocking Remove calls.")
		else
			StopImmortality()
			print("🔴 Immortality disabled — Remove calls unblocked.")
		end
	end,
}, "ImmortalToggle")

-- Secondary toggle: Temporary disable with E key
ImmortalGroupbox:CreateToggle({
	Name = "Temporary Disable (E)",
	Icon = NebulaIcons:GetIcon("keyboard", "Material"),
	CurrentValue = false,
	Style = 2,
	Callback = function(Value)
		temporaryDisableEnabled = Value
	end,
}, "ImmortalTempDisableToggle")

--------------------------------------------------
--// Input Logic
--------------------------------------------------

UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed or not temporaryDisableEnabled then return end
	if input.KeyCode == Enum.KeyCode.E and canTemporarilyDisable and immortalityEnabled then
		canTemporarilyDisable = false

		local Character = localPlayer.Character or localPlayer.CharacterAdded:Wait()
		if not Character or not InvEvent then return end

		print("🟡 Temporarily disabling immortality (2s)...")

		-- 1. Fire Remove
		InvEvent:FireServer(Character, "Remove")

		-- 2. Pause immortality loop
		StopImmortality()

		-- 3. Wait 2 seconds, then resume and reapply Add immediately
		task.delay(2, function()
			print("🟢 Re-enabling immortality.")
			InvEvent:FireServer(Character, "Add") -- immediately reapply
			StartImmortality()
			canTemporarilyDisable = true
		end)
	end
end)

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
--// SETTINGS SECTION
--------------------------------------------------

local TabSection = Window:CreateTabSection("Settings")

local Tab = TabSection:CreateTab({
    Name = "Settings",
    Icon = NebulaIcons:GetIcon('settings', 'Material'),
    Columns = 2,
}, "SettingsTab")

Tab:BuildThemeGroupbox(1)

Tab:BuildConfigGroupbox(2)

local SettingsGroupbox = Tab:CreateGroupbox({
    Name = "Misc.",
    Column = 2,
}, "SettingsGB")

local Button = SettingsGroupbox:CreateButton({
    Name = "Rejoin",
    Icon = NebulaIcons:GetIcon('repeat', 'Material'),
    Callback = function()
        game:GetService("TeleportService"):TeleportToPlaceInstance(game.PlaceId, game.JobId, localPlayer)
    end,
}, "RejoinButton")

local Button = SettingsGroupbox:CreateButton({
    Name = "Destroy UI",
    Icon = NebulaIcons:GetIcon('delete', 'Material'),
    Callback = function()
        Starlight:Destroy()
    end,
}, "DestroyButton")
