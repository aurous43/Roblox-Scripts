local Players = game:GetService("Players")
local CollectionService = game:GetService("CollectionService")
local RunService = game:GetService("RunService")
local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
-- kill tag loop interval
local REFILL_INTERVAL = 0.1

task.spawn(function()
    while character.Parent do
        -- check if flying
        local animate = character:FindFirstChild("Animate")
        local isFlying = animate and animate:GetAttribute("AnimationState") == "Flying"
        if isFlying then
        -- loop kill tag to refill bar
            if CollectionService:HasTag(character, "Kill") then
                CollectionService:RemoveTag(character, "Kill")
                task.wait()
            end
            CollectionService:AddTag(character, "Kill")
        end
        task.wait(REFILL_INTERVAL)
    end
end)
