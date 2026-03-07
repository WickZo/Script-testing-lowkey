-- FULL SCRIPT: Jotaro Automation + Auto Skills + Webhook Notifications + Summon Stand + Auto Retry

-- ===== PLACE ID CHECK =====
local ALLOWED_PLACE_ID = 74747090658891 -- Run script only in this place
local BLOCKED_PLACE_ID = 14890802310 -- Don't run script in this place

local currentPlaceId = game.PlaceId
print("Current Place ID: " .. currentPlaceId)

if currentPlaceId == BLOCKED_PLACE_ID then
    print("🔴 This Place ID (" .. BLOCKED_PLACE_ID .. ") is blocked. Script will not run.")
    return -- Stop script execution immediately
end

if currentPlaceId ~= ALLOWED_PLACE_ID then
    print("🔴 Wrong Place ID. Expected: " .. ALLOWED_PLACE_ID .. ", Got: " .. currentPlaceId)
    print("Script will not run.")
    return -- Stop script execution immediately
end

print("✅ Correct Place ID detected! Loading script...")

-- ===== INITIAL 10 SECOND WAIT =====
print("🔴 Script loaded - Waiting 10 seconds before initializing...")
task.wait(10)
print("✅ 10 second wait complete - Initializing script now!")

-- ===== LOAD RAYFIELD =====
local Rayfield = loadstring(game:HttpGet('https://raw.githubusercontent.com/shlexware/Rayfield/main/source'))()

local requestFunction =
    syn and syn.request or
    http_request or
    request or
    fluxus and fluxus.request

assert(requestFunction, "Executor does not support HTTP requests")

local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LocalPlayer = Players.LocalPlayer
local Workspace = game:GetService("Workspace")

-- ===== CONFIG =====
local SPECIFIC_TARGET_NAME = nil -- e.g., ".Jotaro KujoABC123"
local DISCORD_WEBHOOK = "" -- Will be set by UI

-- ===== CREATE RAYFIELD UI =====
local Window = Rayfield:CreateWindow({
    Name = "Jotaro Auto Farm",
    LoadingTitle = "Loading Script...",
    LoadingSubtitle = "by YourName",
    ConfigurationSaving = {
        Enabled = true,
        FolderName = "JotaroFarm",
        FileName = "Config"
    },
    Discord = {
        Enabled = false,
        Invite = "noinvitelink",
        RememberJoins = true
    },
    KeySystem = false,
    KeySettings = {
        Title = "Key System",
        Subtitle = "Enter Key",
        Note = "No key required",
        FileName = "Key",
        SaveKey = false,
        GrabKeyFromSite = false,
        Key = {"Hello"}
    }
})

local Tab = Window:CreateTab("Main", 4483362458) -- Default icon

-- Webhook input
local WebhookInput = Tab:CreateInput({
    Name = "Discord Webhook URL",
    PlaceholderText = "Enter your Discord webhook here...",
    RemoveTextAfterFocusLost = false,
    Callback = function(Text)
        DISCORD_WEBHOOK = Text
        print("✅ Webhook saved: " .. Text)
    end,
})

-- Status label
local StatusLabel = Tab:CreateLabel("⚠️ Waiting for webhook...")

-- Toggle for webhook notifications
local WebhookToggle = Tab:CreateToggle({
    Name = "Enable Webhook Notifications",
    CurrentValue = false,
    Flag = "WebhookToggle",
    Callback = function(Value)
        if Value and DISCORD_WEBHOOK == "" then
            Rayfield:Notify({
                Title = "Error",
                Content = "Please enter a webhook URL first!",
                Duration = 3,
                Image = 4483362458,
            })
            WebhookToggle:Set(false)
        elseif Value then
            Rayfield:Notify({
                Title = "Webhook Enabled",
                Content = "Notifications will be sent to Discord",
                Duration = 3,
                Image = 4483362458,
            })
            StatusLabel:Set("✅ Webhook enabled - Notifications active")
            sendDiscordMessage("🤖 Auto-farm script started!")
        else
            StatusLabel:Set("⚠️ Webhook disabled")
        end
    end,
})

-- Test webhook button
Tab:CreateButton({
    Name = "Test Webhook",
    Callback = function()
        if DISCORD_WEBHOOK ~= "" and WebhookToggle.CurrentValue then
            sendDiscordMessage("🧪 Test message from Jotaro Auto Farm")
            Rayfield:Notify({
                Title = "Test Sent",
                Content = "Check your Discord channel",
                Duration = 3,
                Image = 4483362458,
            })
        else
            Rayfield:Notify({
                Title = "Cannot Send",
                Content = "Webhook not configured or enabled",
                Duration = 3,
                Image = 4483362458,
            })
        end
    end,
})

-- Close UI button
Tab:CreateButton({
    Name = "Close UI & Start Farming",
    Callback = function()
        Rayfield:Destroy()
    end,
})

-- Wait for UI to close
Rayfield:LoadConfiguration()

-- ===== HELPERS =====
local function sendDiscordMessage(msg)
    if DISCORD_WEBHOOK == "" or not WebhookToggle.CurrentValue then
        print("📢 [WEBHOOK DISABLED] Would have sent: " .. msg)
        return
    end
    
    task.spawn(function()
        pcall(function()
            requestFunction({
                Url = DISCORD_WEBHOOK,
                Method = "POST",
                Headers = {["Content-Type"] = "application/json"},
                Body = game:GetService("HttpService"):JSONEncode({content = msg})
            })
            print("📤 Webhook sent: " .. msg)
        end)
    end)
end

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

    -- Execute Quick Play function
    v8:FireServer()
    v11.CharacterAdded:Wait()
    task.wait(0.1)

    -- Fade Shadow
    local v88 = {
        ["Time"] = 1,
        ["instance"] = v4.Shadow,
        ["Properties"] = { ["Transparency"] = 1 }
    }
    v12.Tween(v88):Play()
end

-- ===== NOTIFICATION WATCHER =====
task.spawn(function()
    -- Disable Main Menu GUI
    local success, err = pcall(function()
        local mainMenu = game:GetService("Players").LocalPlayer.PlayerGui["Main Menu"]
        if mainMenu then
            mainMenu.Enabled = false
            print("✅ Main Menu disabled")
        end
    end)
    
    if not success then
        print("⚠️ Could not disable Main Menu: " .. tostring(err))
    end

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
    local char = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
    local remote = char:WaitForChild("client_character_controller"):WaitForChild("Skill")
    while true do
        remote:FireServer("R", true)
        task.wait(0.1)
        remote:FireServer("R", false)
        task.wait(1) -- skill cooldown
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
            if npc.Name == SPECIFIC_TARGET_NAME then return npc end
        end
    else
        local nearest, shortest = nil, math.huge
        local myChar = LocalPlayer.Character
        if not myChar or not myChar:FindFirstChild("HumanoidRootPart") then return nil end
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

local function stickAbove(npc)
    local myChar = LocalPlayer.Character
    if not myChar or not myChar:FindFirstChild("HumanoidRootPart") then return end
    local myRoot = myChar.HumanoidRootPart

    if myChar:FindFirstChild("FollowConnection") then myChar.FollowConnection:Destroy() end
    local bind = Instance.new("BindableEvent", myChar)
    bind.Name = "FollowConnection"

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
            if newTarget then stickAbove(newTarget) end
        end)
    end
end

local function startFollowing()
    while task.wait(0.5) do
        local target = getTarget()
        if target then
            stickAbove(target)
            sendDiscordMessage("🎯 Now following: " .. target.Name)
            break
        end
    end
end

LocalPlayer.CharacterAdded:Connect(function()
    task.wait(1)
    startFollowing()
end)

if LocalPlayer.Character then startFollowing() end

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

-- Send completion message
task.wait(2)
sendDiscordMessage("✅ Script fully loaded and running!")