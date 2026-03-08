-- FULL SCRIPT: Jotaro Automation + Auto Skills + Webhook Notifications + Summon Stand + Auto Retry

-- ===== PLACE ID CHECK =====
local ALLOWED_PLACE_ID = 74747090658891
local BLOCKED_PLACE_ID = 14890802310

local currentPlaceId = game.PlaceId
print("Current Place ID: " .. currentPlaceId)

if currentPlaceId == BLOCKED_PLACE_ID then
    print("🔴 This Place ID (" .. BLOCKED_PLACE_ID .. ") is blocked. Script will not run.")
    return
end

if currentPlaceId ~= ALLOWED_PLACE_ID then
    print("🔴 Wrong Place ID. Expected: " .. ALLOWED_PLACE_ID .. ", Got: " .. currentPlaceId)
    return
end

print("✅ Correct Place ID detected! Loading script...")

-- ===== INITIAL 10 SECOND WAIT =====
print("🔴 Script loaded - Waiting 10 seconds before initializing...")
task.wait(10)
print("✅ 10 second wait complete - Initializing script now!")

local requestFunction =
    syn and syn.request or
    http_request or
    request or
    fluxus and fluxus.request

assert(requestFunction, "Executor does not support HTTP requests")

local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local HttpService = game:GetService("HttpService")

local LocalPlayer = Players.LocalPlayer

-- ===== CONFIG =====
local SPECIFIC_TARGET_NAME = nil
local DISCORD_WEBHOOK = getgenv().WEBHOOK_URL

-- ===== HELPERS =====
local function sendDiscordMessage(msg)
    if not DISCORD_WEBHOOK then return end

    task.spawn(function()
        pcall(function()
            requestFunction({
                Url = DISCORD_WEBHOOK,
                Method = "POST",
                Headers = {["Content-Type"] = "application/json"},
                Body = HttpService:JSONEncode({
                    content = msg
                })
            })
        end)
    end)
end

sendDiscordMessage("🤖 Auto-farm script started (after 10s delay)!")

-- ===== HELPER: GET LIVE CHARACTER =====
local function getLiveCharacter()
    if Workspace:FindFirstChild("Live") then
        return Workspace.Live:FindFirstChild(LocalPlayer.Name)
    end
end

-- ===== AUTO RETRY =====
task.spawn(function()
    while true do
        task.wait(1)

        local playerGui = LocalPlayer:FindFirstChild("PlayerGui")

        if playerGui and playerGui:FindFirstChild("raidcomplete") then
            print("Raid complete detected, retrying...")
            ReplicatedStorage.requests.character.retryraid:FireServer()
        end
    end
end)

-- ===== AUTO QUICK PLAY =====
local function autoQuickPlay()

    local spawnRemote = ReplicatedStorage.requests.character:WaitForChild("spawn")

    spawnRemote:FireServer()

    LocalPlayer.CharacterAdded:Wait()
    task.wait(0.2)

end

-- ===== NOTIFICATION WATCHER =====
task.spawn(function()

    pcall(function()
        local mainMenu = LocalPlayer.PlayerGui:FindFirstChild("Main Menu")
        if mainMenu then
            mainMenu.Enabled = false
            print("✅ Main Menu disabled")
        end
    end)

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

                    local name = child.Name
                    print("Notification detected:", name)

                    sendDiscordMessage("📢 Notification: "..name)

                end

            end)

        end

    end
end)

-- ===== AUTO SKILL (R) =====
task.spawn(function()

    while true do

        local char = LocalPlayer.Character
        if char and char:FindFirstChild("client_character_controller") then

            local remote = char.client_character_controller:FindFirstChild("Skill")

            if remote then

                remote:FireServer("R", true)
                task.wait(0.1)
                remote:FireServer("R", false)

            end

        end

        task.wait(1)

    end
end)

-- ===== AUTO M1 =====
task.spawn(function()

    while true do

        task.wait(0.1)

        local liveChar = getLiveCharacter()

        if liveChar and liveChar:FindFirstChild("client_character_controller") then

            local controller = liveChar.client_character_controller
            local m1 = controller:FindFirstChild("M1")

            if m1 then
                m1:FireServer(true,false)
            end

        end

    end

end)

-- ===== JOTARO TARGETING =====
local function getAllJotaroNPCs()

    if not Workspace:FindFirstChild("Live") then return {} end

    local jotaroNPCs = {}

    for _, npc in ipairs(Workspace.Live:GetChildren()) do
        if npc.Name:match("^%.Jotaro Kujo") then
            table.insert(jotaroNPCs, npc)
        end
    end

    return jotaroNPCs

end

local function getTarget()

    local jotaroNPCs = getAllJotaroNPCs()

    if SPECIFIC_TARGET_NAME then
        for _, npc in ipairs(jotaroNPCs) do
            if npc.Name == SPECIFIC_TARGET_NAME then
                return npc
            end
        end
    else

        local nearest
        local shortest = math.huge

        local myChar = LocalPlayer.Character
        if not myChar or not myChar:FindFirstChild("HumanoidRootPart") then return end

        local myPos = myChar.HumanoidRootPart.Position

        for _, npc in ipairs(jotaroNPCs) do

            if npc:FindFirstChild("HumanoidRootPart") then

                local dist = (npc.HumanoidRootPart.Position - myPos).Magnitude

                if dist < shortest then
                    shortest = dist
                    nearest = npc
                end

            end

        end

        return nearest
    end

end

-- ===== FOLLOW TARGET =====
local function stickAbove(npc)

    local myChar = LocalPlayer.Character
    if not myChar or not myChar:FindFirstChild("HumanoidRootPart") then return end

    local myRoot = myChar.HumanoidRootPart

    if myChar:FindFirstChild("FollowConnection") then
        myChar.FollowConnection:Destroy()
    end

    local bind = Instance.new("BindableEvent")
    bind.Name = "FollowConnection"
    bind.Parent = myChar

    local conn

    conn = RunService.Heartbeat:Connect(function()

        if not npc or not npc.Parent or not npc:FindFirstChild("HumanoidRootPart") then
            conn:Disconnect()
            bind:Destroy()
            return
        end

        local targetRoot = npc.HumanoidRootPart

        local newPos = targetRoot.Position + Vector3.new(0,10,0)

        myRoot.CFrame = CFrame.new(newPos, targetRoot.Position)

    end)

    local humanoid = npc:FindFirstChildOfClass("Humanoid")

    if humanoid then
        humanoid.Died:Connect(function()

            conn:Disconnect()
            bind:Destroy()

            sendDiscordMessage("💀 Jotaro NPC defeated - finding next target...")

            task.wait(1)

            local newTarget = getTarget()

            if newTarget then
                stickAbove(newTarget)
            end

        end)
    end

end

local function startFollowing()

    while task.wait(0.5) do

        local target = getTarget()

        if target then

            stickAbove(target)

            sendDiscordMessage("🎯 Now following: "..target.Name)

            break

        end

    end

end

LocalPlayer.CharacterAdded:Connect(function()

    task.wait(1)
    startFollowing()

end)

if LocalPlayer.Character then
    startFollowing()
end

-- ===== AUTO SUMMON STAND (WHEN LOCKED ONTO JOTARO) =====
task.spawn(function()

    while true do
        
        task.wait(0.5)  -- Check every half second
        
        local target = getTarget()  -- Get current Jotaro target
        local liveChar = getLiveCharacter()
        
        -- Only summon stand if:
        -- 1. We have a target (locked onto Jotaro)
        -- 2. We have a character
        if target and liveChar and LocalPlayer.Character then
            
            local controller = LocalPlayer.Character:FindFirstChild("client_character_controller")
            
            if controller and controller:FindFirstChild("SummonStand") then
                controller.SummonStand:FireServer()
                sendDiscordMessage("⭐ Stand summon fired (locked onto: "..target.Name..")")
                
                -- Optional: Add a small delay to prevent spam
                task.wait(1)
            end
            
        end
        
    end

end)

-- ===== INITIAL EXECUTION =====
autoQuickPlay()

task.wait(2)

sendDiscordMessage("✅ Script fully loaded and running!")
