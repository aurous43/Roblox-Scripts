-- Fixed version of TheGuyWhoUh's godmode script

local Humanoid = workspace:WaitForChild(game:GetService("Players").LocalPlayer.Name):WaitForChild("Humanoid")

local mt = getrawmetatable(game)
setreadonly(mt, false)

local old = mt.__namecall
mt.__namecall = newcclosure(function(self, ...)
    local m = getnamecallmethod()
    local args = {...}

    if m == "FireServer" and tostring(self) == "DamageEvent" then
        for _, v in ipairs(args) do
            if v == Humanoid then
                return nil
            end
        end
    end

    return old(self, ...)
end)

local oldFireServer
oldFireServer = hookfunction(Instance.new("RemoteEvent").FireServer, function(self, ...)
    local args = {...}

    if tostring(self) == "DamageEvent" then
        for _, v in ipairs(args) do
            if v == Humanoid then
                return nil
            end
        end
    end

    return oldFireServer(self, ...)
end)
