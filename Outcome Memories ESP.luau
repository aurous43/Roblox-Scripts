--// Outcome Memories ESP (LocalScript)
-- Highlights Survivors (blue) and Executioner (red) with dynamic stun display
-- Only rounds up if StunDur >= 1 and decimal >= 0.5

-- // Services
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local PLAYERS_FOLDER = workspace:WaitForChild("Players")

-- // State
local enabled = true
local highlights = {}
local labels = {}
local connections = {}

-- // Remove ESP from a model
local function removeESP(model)
	if highlights[model] then
		highlights[model]:Destroy()
		highlights[model] = nil
	end

	local entry = labels[model]
	if entry then
		if entry.conn then entry.conn:Disconnect() end
		if entry.gui then entry.gui:Destroy() end
		labels[model] = nil
	end
end

-- // Create highlight
local function createHighlight(model, color)
	local hl = Instance.new("Highlight")
	hl.FillColor = color
	hl.OutlineColor = color
	hl.FillTransparency = 0.5
	hl.OutlineTransparency = 0
	hl.Adornee = model
	hl.Parent = model
	highlights[model] = hl
end

-- // Create EXE label
local function createEXELabel(model)
	local head = model:FindFirstChild("Head")
	if not head then return end

	local billboard = Instance.new("BillboardGui")
	billboard.Size = UDim2.new(0, 60, 0, 15)
	billboard.StudsOffset = Vector3.new(0, 2.8, 0)
	billboard.AlwaysOnTop = true
	billboard.Name = "EXE_Label"

	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(1, 0, 1, 0)
	label.BackgroundTransparency = 1
	label.Text = "EXE"
	label.TextColor3 = Color3.fromRGB(255, 0, 0)
	label.TextStrokeTransparency = 0
	label.TextScaled = true
	label.Font = Enum.Font.GothamBold
	label.Parent = billboard
	billboard.Parent = head

	local function updateText()
		local stun = model:GetAttribute("StunDur")
		if type(stun) == "number" and stun >= 0.1 then
			if stun >= 1 then
				local intPart = math.floor(stun)
				local decPart = stun - intPart
				if decPart >= 0.5 then
					label.Text = tostring(intPart + 1)
				else
					label.Text = tostring(intPart)
				end
			else
				label.Text = string.format("%.1f", stun)
			end
		else
			label.Text = "EXE"
		end
	end

	updateText()
	local conn = model:GetAttributeChangedSignal("StunDur"):Connect(updateText)
	labels[model] = { gui = billboard, conn = conn }
end

-- // Apply ESP to a model
local function applyESP(model)
	if not model:IsA("Model") then return end
	if model == LocalPlayer.Character then return end

	removeESP(model)
	local team = model:GetAttribute("Team")

	if team == "EXE" then
		createHighlight(model, Color3.fromRGB(255, 0, 0))
		createEXELabel(model)
	elseif team == "Survivor" then
		createHighlight(model, Color3.fromRGB(19, 56, 190)) -- #1338BE
	end
end

-- // Enable ESP
local function enableESP()
	if not enabled then return end

	for _, model in ipairs(PLAYERS_FOLDER:GetChildren()) do
		applyESP(model)
	end

	table.insert(connections, PLAYERS_FOLDER.ChildAdded:Connect(function(model)
		task.defer(function() applyESP(model) end)
	end))

	table.insert(connections, PLAYERS_FOLDER.ChildRemoved:Connect(removeESP))

	for _, model in ipairs(PLAYERS_FOLDER:GetChildren()) do
		table.insert(connections, model:GetAttributeChangedSignal("Team"):Connect(function()
			applyESP(model)
		end))
	end
end

-- // Initialize
enableESP()
