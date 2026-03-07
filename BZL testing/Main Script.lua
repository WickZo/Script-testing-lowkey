-- ===== PLACE ID CHECK =====
local ALLOWED_PLACE_ID = 74747090658891 -- Run script only in this place
local BLOCKED_PLACE_ID = 14890802310 -- Don't run script in this place

local currentPlaceId = game.PlaceId
print("Current Place ID: " .. currentPlaceId)

if currentPlaceId == BLOCKED_PLACE_ID then
    print("🔴 This Place ID (" .. BLOCKED_PLACE_ID .. ") is blocked. Script will not run.")
    return
end

if currentPlaceId ~= ALLOWED_PLACE_ID then
    print("🔴 Wrong Place ID. Expected: " .. ALLOWED_PLACE_ID .. ", Got: " .. currentPlaceId)
    print("Script will not run.")
    return
end

print("✅ Correct Place ID detected! Loading script...")

-- ===== INITIAL 10 SECOND WAIT =====
print("🔴 Script loaded - Waiting 5 seconds before initializing...")
task.wait(5)
print("✅ 5 second wait complete - Initializing script now!")

-- ===== REQUEST FUNCTION =====
local requestFunction =
    syn and syn.request or
    http_request or
    request or
    fluxus and fluxus.request

assert(requestFunction, "Executor does not support HTTP requests")

-- ===== SERVICES =====
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LocalPlayer = Players.LocalPlayer
local Workspace = game:GetService("Workspace")

-- ===== LOAD CONFIG =====
local CONFIG = loadfile("webhook_config.lua")()  -- Make sure this file is in same folder
local DISCORD_WEBHOOK = CONFIG.webhook

-- ===== HELPERS =====
local function sendDiscordMessage(msg)
    task.spawn(function()
        pcall(function()
            requestFunction({
                Url = DISCORD_WEBHOOK,
                Method = "POST",
                Headers = {["Content-Type"] = "application/json"},
                Body = game:GetService("HttpService"):JSONEncode({content = msg})
            })
        end)
    end)
end

-- Send startup message
sendDiscordMessage("🤖 Auto-farm script started (after 10s delay)!")

-- ===== AUTO RETRY =====
task.spawn(function()
    while true do
        task.wait(1)
        local playerGui = Players:FindFirstChild("Solenoid13") and Players.Solenoid13:FindFirstChild("PlayerGui")
        if playerGui and playerGui:FindFirstChild("raidcomplete") then
            print("Raid complete detected, retrying...")
            ReplicatedStorage.requests.character.retryraid:FireServer()
        end
    end
end)

-- ===== AUTO QUICK PLAY =====
local function autoQuickPlay()
    local v4 = script.Parent
    local v8 = ReplicatedStorage.requests.character:WaitForChild("spawn")
    local v11 = LocalPlayer
    local v12 = require(ReplicatedStorage.client_utils)

    v8:FireServer()
    v11.CharacterAdded:Wait()
    task.wait(0.1)

    local v88 = {
        ["Time"] = 1,
        ["instance"] = v4.Shadow,
        ["Properties"] = { ["Transparency"] = 1 }
    }
    v12.Tween(v88):Play()
end

-- ===== NOTIFICATION WATCHER =====
task.spawn(function()
    local connectedHolder = nil
    while true do
        task.wait(2)
        local playerGui = LocalPlayer:FindFirstChild("PlayerGui")
        if not playerGui then continue end
        local notifications = playerGui:FindFirstChild("Notifications")
        if not notifications then continue end
        local holder = notifications:FindFirstChild("holder")
        if not holder then continue end

        if holder ~= connectedHolder then
            connectedHolder = holder
            print("Connected to Notifications holder")
            holder.ChildAdded:Connect(function(child)
                if child:IsA("Frame") then
                    sendDiscordMessage("📢 Notification: "..child.Name)
                end
            end)
        end
    end
end)

-- ===== AUTO SKILL (R) =====
task.spawn(function()
    local char = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
    local remote = char:WaitForChild("client_character_controller"):WaitForChild("Skill")
    while true do
        remote:FireServer("R", true)
        task.wait(0.1)
        remote:FireServer("R", false)
        task.wait(1)
    end
end)

-- ===== AUTO M1 =====
task.spawn(function()
    while true do
        task.wait(0.1)
        local charInWorkspace = Workspace.Live:FindFirstChild(LocalPlayer.Name)
        if charInWorkspace and charInWorkspace:FindFirstChild("client_character_controller") and charInWorkspace.client_character_controller:FindFirstChild("M1") then
            local remote = charInWorkspace.client_character_controller.M1
            remote:FireServer(true,false)
        end
    end
end)

-- ===== FOLLOW JOTARO =====
-- (Your existing follow logic here, unchanged)
-- ...

-- ===== AUTO SUMMON STAND =====
task.spawn(function()
    while true do
        task.wait(0.5)
        local liveChar = Workspace.Live:FindFirstChild("Solenoid13")
        if liveChar and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("client_character_controller") then
            if not liveChar:FindFirstChild("Stand_Weapon") then
                LocalPlayer.Character.client_character_controller.SummonStand:FireServer()
                sendDiscordMessage("⭐ Stand summoned")
            end
        end
    end
end)

-- ===== INITIAL EXECUTION =====
autoQuickPlay()
task.wait(2)
sendDiscordMessage("✅ Script fully loaded and running!")