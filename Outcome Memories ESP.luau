local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local CoreGui = game:GetService("CoreGui")

local PLAYERS_FOLDER = workspace:WaitForChild("Players")
local PROJECTILE_FOLDER = workspace:WaitForChild("Projectile")

local highlights = {}
local labels = {}
local attrConnections = {}

local function getAttachPart(instance)
	if instance:IsA("BasePart") or instance:IsA("UnionOperation") then
		return instance
	elseif instance:IsA("Model") then
		return instance:FindFirstChildWhichIsA("BasePart", true)
			or instance:FindFirstChildWhichIsA("UnionOperation", true)
	end
end

local function forceTrapVisible(instance)
	for _, desc in ipairs(instance:GetDescendants()) do
		if desc:IsA("BasePart") or desc:IsA("UnionOperation") then
			desc.Transparency = 0
		end
	end
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
		for _, conn in pairs(attrConnections[instance]) do
			conn:Disconnect()
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

local function createEXELabel(model)
	local attachPart =
		model:FindFirstChild("Head")
		or model:FindFirstChildWhichIsA("BasePart", true)

	if not attachPart then return end

	local billboard, label = createLabel(
		attachPart,
		"EXE",
		Color3.fromRGB(255, 0, 0)
	)

	local function updateText()
		local stun = model:GetAttribute("StunDur")
		if type(stun) == "number" and stun >= 0.1 then
			if stun >= 1 then
				local i = math.floor(stun)
				label.Text = tostring((stun - i) >= 0.5 and i + 1 or i)
			else
				label.Text = string.format("%.1f", stun)
			end
		else
			label.Text = "EXE"
		end
	end

	updateText()

	attrConnections[model] = attrConnections[model] or {}
	attrConnections[model].stun =
		model:GetAttributeChangedSignal("StunDur"):Connect(updateText)

	labels[model] = billboard
end

local function applyPlayerESP(model)
	if not model:IsA("Model") then return end
	if model == LocalPlayer.Character then return end

	removeESP(model)

	local team = model:GetAttribute("Team")
	if team == "EXE" then
		createHighlight(model, Color3.fromRGB(255, 0, 0))
		createEXELabel(model)
	elseif team == "Survivor" then
		createHighlight(model, Color3.fromRGB(0, 0, 255))
	end
end

local function applyTrapESP(instance)
	if not instance then return end

	removeESP(instance)

	forceTrapVisible(instance)

	attrConnections[instance] = {}

	attrConnections[instance].desc =
		instance.DescendantAdded:Connect(function(desc)
			if desc:IsA("BasePart") or desc:IsA("UnionOperation") then
				desc.Transparency = 0
			end
		end)

	attrConnections[instance].attr =
		instance.AttributeChanged:Connect(function(attr)
			if attr == "Explode" or attr == "Owner" then
				applyTrapESP(instance)
			end
		end)

	task.defer(function()
		if not instance or not instance.Parent then return end
		if instance:GetAttribute("Explode") ~= nil then return end
		if instance:GetAttribute("Owner") == LocalPlayer.Name then return end

		local attachPart = getAttachPart(instance)
		if not attachPart then return end

		createHighlight(instance, Color3.fromRGB(255, 255, 0))
		labels[instance] =
			(select(1, createLabel(attachPart, "TRAP", Color3.fromRGB(255, 255, 0))))
	end)
end

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
