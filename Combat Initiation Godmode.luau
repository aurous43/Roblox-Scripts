-- Fixed version of TheGuyWhoUh's godmode script

local Humanoid = workspace:WaitForChild(game:GetService("Players").LocalPlayer.Name):WaitForChild("Humanoid")

local mt = getrawmetatable(game)
setreadonly(mt, false)

local old = mt.__namecall
mt.__namecall = newcclosure(function(self, ...)
    local m = getnamecallmethod()
    local args = {...}

    if m == "FireServer" then
        local remoteName = tostring(self)
        if remoteName == "DamageEvent" then
            for _, v in ipairs(args) do
                if v == Humanoid then
                    return nil
                end
            end
        elseif remoteName == "PlayerDamage" then
            return nil
        end
    end

    return old(self, ...)
end)

local oldFireServer
oldFireServer = hookfunction(Instance.new("RemoteEvent").FireServer, function(self, ...)
    local args = {...}
    local remoteName = tostring(self)

    if remoteName == "DamageEvent" then
        for _, v in ipairs(args) do
            if v == Humanoid then
                return nil
            end
        end
    elseif remoteName == "PlayerDamage" then
        return nil
    end

    return oldFireServer(self, ...)
end)
