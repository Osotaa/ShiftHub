-- Roblox LUA Script
local allowedPlaceIds = {17687504411, 16146832113}
local currentPlaceId = game.PlaceId

local isAllowed = false
for _, id in pairs(allowedPlaceIds) do
    if currentPlaceId == id then
        isAllowed = true
        break
    end
end

if not isAllowed then
    warn("Script only works in All Star Tower Defense and Anime Vanguards!")
    return
end

local Players = game:GetService("Players")
local TeleportService = game:GetService("TeleportService")
local UserInputService = game:GetService("UserInputService")

local openSoundId = "rbxassetid://84041558102940"
local closeSoundId = "rbxassetid://78706875936198"

local function playSound(id)
    local s = Instance.new("Sound")
    s.SoundId = id
    s.Volume = 1
    s.Parent = game:GetService("SoundService")
    s:Play()
    s.Ended:Connect(function() s:Destroy() end)
end

-- Carrega Rayfield
local success, Rayfield = pcall(function()
    return loadstring(game:HttpGet("https://raw.githubusercontent.com/oxotaa/teste/refs/heads/main/source2.lua"))()
end)
if not success or not Rayfield then
    warn("Falha ao carregar Rayfield UI")
    return
end

-- KEY WINDOW
local keyWindow = Rayfield:CreateWindow({
    Name = "Shift Hub - Key",
    LoadingTitle = "Loading Shift Hub...",
    LoadingSubtitle = "Checking Key...",
    ConfigurationSaving = { Enabled = false },
    KeySystem = false
})

local keyTab = keyWindow:CreateTab("🔑 Key")
local userKey = ""
local validKeys = {
    "j^3Y*($aR3m8ABevaC5p3KNUucAgRxiqm",
    "-us3OVbZTAkKtT?2A9KmrhV6X^aFt>woh",
    "29<^0M$a?TDhvHA9s25PIfXl53z7yrLiZ",
    "wdRT1Rbn8!tD+mHrEfDKx7^gvJhsI74<C",
    "!^FljA&=oSxzytjaJLSuza4lmJ6BnM8E7"
}

local function isValidKey(key)
    for _, k in pairs(validKeys) do
        if key == k then return true end
    end
    return false
end

keyTab:CreateInput({
    Name = "Your Key",
    PlaceholderText = "Enter your key here",
    RemoveTextAfterFocusLost = false,
    Callback = function(value) userKey = value end
})

keyTab:CreateButton({
    Name = "Validate Key",
    Callback = function()
        if isValidKey(userKey) then
            Rayfield:Notify({Title="Success", Content="Valid key!", Duration=3})
            Rayfield:Destroy()
            wait(0.2)
            openMainWindow()
        else
            Rayfield:Notify({Title="Error", Content="Invalid key!", Duration=5})
        end
    end
})

-- MAIN WINDOW
function openMainWindow()
    local mainWindow = Rayfield:CreateWindow({
        Name = "Shift Hub",
        LoadingTitle = "Shift Hub",
        LoadingSubtitle = "",
        ConfigurationSaving = { Enabled = false },
        KeySystem = false
    })

    local mainTab = mainWindow:CreateTab("🏠 Main")
    mainTab:CreateSection("Welcome to Shift Hub!")

    local rollbackEnabled = false

    mainTab:CreateToggle({
        Name = "Rollback Trait",
        CurrentValue = false,
        Callback = function(value)
            rollbackEnabled = value
            if rollbackEnabled then
                Rayfield:Notify({Title="Rollback", Content="Rollback ativado.", Duration=3})
            else
                Rayfield:Notify({Title="Rollback", Content="Rollback desativado.", Duration=3})
            end
        end
    })

    mainTab:CreateButton({
        Name = "Confirm Rollback",
        Callback = function()
            if rollbackEnabled then
                Rayfield:Notify({Title="Rollback", Content="Reentrando na instância...", Duration=3})
                wait(2)
                local ok, err = pcall(function()
                    TeleportService:Teleport(game.PlaceId, Players.LocalPlayer)
                end)
                if not ok then
                    Rayfield:Notify({Title="Error", Content="Falha ao reentrar: "..tostring(err), Duration=5})
                end
            else
                Rayfield:Notify({Title="Error", Content="Rollback não ativado.", Duration=3})
            end
        end
    })

    local configsTab = mainWindow:CreateTab("⚙️ Config")
    configsTab:CreateSection("Settings")

    configsTab:CreateButton({
        Name = "Rejoin",
        Callback = function()
            pcall(function()
                TeleportService:Teleport(game.PlaceId, Players.LocalPlayer)
            end)
        end
    })

    local bindKey = nil
    local listening = false
    local bindLabel = configsTab:CreateLabel({Name="Current Bind: None"})

    configsTab:CreateButton({
        Name = "Choose bind to show/hide interface",
        Callback = function()
            listening = true
            bindLabel:SetText("Press any key...")
        end
    })

    UserInputService.InputBegan:Connect(function(input, processed)
        if listening and input.UserInputType == Enum.UserInputType.Keyboard then
            bindKey = input.KeyCode
            listening = false
            bindLabel:SetText("Current Bind: "..tostring(bindKey.Name))
        elseif bindKey and input.UserInputType == Enum.UserInputType.Keyboard and input.KeyCode == bindKey then
            mainWindow.Visible = not mainWindow.Visible
            if mainWindow.Visible then
                playSound(openSoundId)
            else
                playSound(closeSoundId)
            end
        end
    end)

    mainWindow.Visible = true
    playSound(openSoundId)
end

