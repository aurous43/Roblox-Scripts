local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local CoreGui = game:GetService("CoreGui")
local RunService = game:GetService("RunService")

local PLAYERS_FOLDER = workspace:WaitForChild("Players")
local PROJECTILE_FOLDER = workspace:WaitForChild("Projectile")

local highlights = {}
local labels = {}
local attrConnections = {}

local showSurvivorLabels = false
local espEnabled = true

local CHARACTER_COLORS = {
	Sonic = Color3.fromRGB(0, 9, 255),
	Tails = Color3.fromRGB(255, 236, 0),
	Knuckles = Color3.fromRGB(255, 21, 0),
	Amy = Color3.fromRGB(248, 0, 255),
	Cream = Color3.fromRGB(255, 218, 132),
	Eggman = Color3.fromRGB(176, 11, 0),
	MetalSonic = Color3.fromRGB(1, 1, 193),
	Silver = Color3.fromRGB(255, 255, 255),
	Blaze = Color3.fromRGB(184, 131, 255),
}

local function getCharacterColor(model, fallback)
	local c = model:GetAttribute("Character")
	return CHARACTER_COLORS[c] or fallback
end

local function getAttachPart(instance)
	if instance:IsA("BasePart") or instance:IsA("UnionOperation") then
		return instance
	elseif instance:IsA("Model") then
		return instance:FindFirstChildWhichIsA("BasePart", true)
			or instance:FindFirstChildWhichIsA("UnionOperation", true)
	end
end

local function forceTrapVisible(instance)
	attrConnections[instance] = attrConnections[instance] or {}
	if attrConnections[instance].render then return end
	attrConnections[instance].render =
		RunService.RenderStepped:Connect(function()
			if not instance or not instance.Parent then return end
			local function recurse(inst)
				if inst:IsA("BasePart") or inst:IsA("UnionOperation") then
					inst.Transparency = 0
					inst.LocalTransparencyModifier = 0
				end
				for _, c in ipairs(inst:GetChildren()) do
					recurse(c)
				end
			end
			recurse(instance)
		end)
end

local function removeESP(instance)
	if highlights[instance] then
		highlights[instance]:Destroy()
		highlights[instance] = nil
	end
	if labels[instance] then
		labels[instance]:Destroy()
		labels[instance] = nil
	end
	if attrConnections[instance] then
		for _, c in pairs(attrConnections[instance]) do
			c:Disconnect()
		end
		attrConnections[instance] = nil
	end
end

local function createHighlight(instance, color)
	local hl = Instance.new("Highlight")
	hl.FillColor = color
	hl.OutlineColor = color
	hl.FillTransparency = 1
	hl.OutlineTransparency = 0
	hl.Adornee = instance
	hl.Parent = CoreGui
	highlights[instance] = hl
end

local function createLabel(part, text, color)
	if not part then return end
	local billboard = Instance.new("BillboardGui")
	billboard.Size = UDim2.new(0, 60, 0, 15)
	billboard.StudsOffset = Vector3.new(0, 2.8, 0)
	billboard.AlwaysOnTop = true

	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(1, 0, 1, 0)
	label.BackgroundTransparency = 1
	label.Text = text
	label.TextColor3 = color
	label.TextStrokeTransparency = 0
	label.TextScaled = true
	label.Font = Enum.Font.Arcade
	label.Parent = billboard

	billboard.Parent = part
	return billboard, label
end

local function createCharacterLabel(model, fallbackColor)
	if not espEnabled then return end
	local attachPart =
		model:FindFirstChild("Head")
		or model:FindFirstChild("Sphere.001")
		or model:FindFirstChild("HumanoidRootPart")
	if not attachPart then return end

	local function getColor()
		return getCharacterColor(model, fallbackColor)
	end

	local billboard, label = createLabel(attachPart, "", getColor())

	local function update()
		local char = model:GetAttribute("Character")
		if char == "TailsDoll" then
			char = "Tripwire"
		end
		label.Text = string.upper(tostring(char or ""))
		label.TextColor3 = getColor()
		if char == "Sonic" or char == "MetalSonic" then
			label.TextStrokeColor3 = Color3.fromRGB(255, 255, 255)
		else
			label.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
		end
		if highlights[model] then
			highlights[model].FillColor = getColor()
			highlights[model].OutlineColor = getColor()
		end
	end

	update()

	attrConnections[model] = attrConnections[model] or {}
	attrConnections[model].char =
		model:GetAttributeChangedSignal("Character"):Connect(update)

	labels[model] = billboard
end

function applyPlayerESP(model)
	if not espEnabled then return end
	if not model:IsA("Model") then return end
	if model == LocalPlayer.Character then return end
	removeESP(model)

	local team = model:GetAttribute("Team")

	if team == "EXE" then
		local color = getCharacterColor(model, Color3.fromRGB(255, 0, 0))
		createHighlight(model, color)

		local attachPart = model:FindFirstChild("Head") or model:FindFirstChildWhichIsA("BasePart", true)
		if attachPart then
			local billboard, label = createLabel(attachPart, "", color)

			local function updateText()
				local stun = model:GetAttribute("StunDur")
				local char = model:GetAttribute("Character")
				local c = getCharacterColor(model, Color3.fromRGB(255, 0, 0))
				if char == "TailsDoll" then
					char = "Tripwire"
				end
				label.TextColor3 = c
				if char == "Sonic" or char == "MetalSonic" then
					label.TextStrokeColor3 = Color3.fromRGB(255, 255, 255)
				else
					label.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
				end
				if highlights[model] then
					highlights[model].FillColor = c
					highlights[model].OutlineColor = c
				end
				if type(stun) == "number" and stun >= 0.1 then
					label.Text = string.upper(string.format("%.1f", stun))
				elseif char then
					label.Text = string.upper(tostring(char))
				else
					label.Text = ""
				end
			end

			updateText()

			attrConnections[model] = attrConnections[model] or {}
			attrConnections[model].stun =
				model:GetAttributeChangedSignal("StunDur"):Connect(updateText)
			attrConnections[model].char =
				model:GetAttributeChangedSignal("Character"):Connect(updateText)

			labels[model] = billboard
		end

	elseif team == "Survivor" then
		local color = getCharacterColor(model, Color3.fromRGB(0, 0, 255))
		createHighlight(model, color)
		if showSurvivorLabels then
			createCharacterLabel(model, Color3.fromRGB(0, 0, 255))
		end
	end
end

local function applyTrapESP(instance)
	if not espEnabled then return end
	if not instance then return end
	removeESP(instance)
	forceTrapVisible(instance)

	attrConnections[instance] = {}
	attrConnections[instance].desc =
		instance.DescendantAdded:Connect(function(d)
			if d:IsA("BasePart") or d:IsA("UnionOperation") then
				d.Transparency = 0
				d.LocalTransparencyModifier = 0
			end
		end)

	attrConnections[instance].attr =
		instance.AttributeChanged:Connect(function(attr)
			if attr == "Explode" or attr == "Owner" then
				applyTrapESP(instance)
			end
		end)

task.spawn(function()
	if not instance or not instance.Parent then return end

	local start = os.clock()
	while instance.Parent and os.clock() - start < 1 do
		local owner = instance:GetAttribute("Owner")
		local explode = instance:GetAttribute("Explode")

		if owner == LocalPlayer.Name then return end
		if explode == nil then break end

		RunService.Heartbeat:Wait()
	end

	if not instance or not instance.Parent then return end
	if instance:GetAttribute("Owner") == LocalPlayer.Name then return end
	if instance:GetAttribute("Explode") ~= nil then return end

	createHighlight(instance, Color3.fromRGB(255, 255, 0))

	local attachPart = getAttachPart(instance)
	if attachPart then
		labels[instance] =
			select(1, createLabel(attachPart, "TRAP", Color3.fromRGB(255, 255, 0)))
	end
end)

end -- ✅ CLOSES applyTrapESP

LocalPlayer.Chatted:Connect(function(msg)
	msg = msg:lower()

	if msg == "/e hide" then
		espEnabled = not espEnabled
		if not espEnabled then
			for inst in pairs(highlights) do
				removeESP(inst)
			end
			for inst in pairs(labels) do
				removeESP(inst)
			end
		else
			for _, model in ipairs(PLAYERS_FOLDER:GetChildren()) do
				applyPlayerESP(model)
			end
			local traps = PROJECTILE_FOLDER:FindFirstChild("Traps")
			if traps then
				for _, t in ipairs(traps:GetChildren()) do
					applyTrapESP(t)
				end
			end
		end

	elseif msg == "/e clutter" then
		showSurvivorLabels = not showSurvivorLabels
		if espEnabled then
			for _, model in ipairs(PLAYERS_FOLDER:GetChildren()) do
				applyPlayerESP(model)
			end
		end
	end
end)

for _, model in ipairs(PLAYERS_FOLDER:GetChildren()) do
	applyPlayerESP(model)
end

PLAYERS_FOLDER.ChildAdded:Connect(function(model)
	task.defer(function()
		applyPlayerESP(model)
	end)
end)

PLAYERS_FOLDER.ChildRemoved:Connect(removeESP)

local function setupTraps(folder)
	for _, obj in ipairs(folder:GetChildren()) do
		applyTrapESP(obj)
	end
	folder.ChildAdded:Connect(function(obj)
		task.defer(function()
			applyTrapESP(obj)
		end)
	end)
	folder.ChildRemoved:Connect(removeESP)
end

local trapsFolder = PROJECTILE_FOLDER:FindFirstChild("Traps")
if trapsFolder then
	setupTraps(trapsFolder)
else
	PROJECTILE_FOLDER.ChildAdded:Connect(function(child)
		if child.Name == "Traps" then
			setupTraps(child)
		end
	end)
end

