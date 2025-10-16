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
local HttpService = game:GetService("HttpService")

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

-- Webhook do Discord
local webhookURL = "https://discord.com/api/webhooks/1428416219580596305/HMAoGabBnf5xXPDATKolLKncehp4UWV-jNl37nNuG7RpOgZ60z3YJvJD3zn9scfu9gj0"

local function sendWebhook(message)
    local data = {["content"] = message}
    local json = HttpService:JSONEncode(data)
    pcall(function()
        HttpService:PostAsync(webhookURL, json, Enum.HttpContentType.ApplicationJson)
    end)
end

-- Carrega Rayfield
local success, Rayfield = pcall(function()
    return loadstring(game:HttpGet("https://raw.githubusercontent.com/Osotaa/ShiftHub/refs/heads/main/shifthub_teest.lua"))()
end)
if not success or not Rayfield then
    warn("Falha ao carregar Rayfield UI")
    return
end

-- Envia webhook ao executar o script
local playerName = Players.LocalPlayer and Players.LocalPlayer.Name or "Unknown"
sendWebhook("Script Shift Hub executado por **"..playerName.."** no PlaceId: "..tostring(currentPlaceId))

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
            keyWindow:Destroy()  -- Destrói apenas a keyWindow
            warn("Key window destruída. Tentando abrir a main window...")
            wait(1)  -- Aumentado para 1 segundo
            local ok, err = pcall(function()  -- Usando pcall para capturar erros
                if Rayfield then  -- Verifica se Rayfield ainda está carregado
                    openMainWindow()
                else
                    warn("Rayfield não está mais disponível!")
                    Rayfield:Notify({Title="Error", Content="Falha ao carregar Rayfield para a main window!", Duration=5})
                end
            end)
            if not ok then
                warn("Erro ao abrir main window: " .. tostring(err))
                Rayfield:Notify({Title="Error", Content="Falha ao abrir a main window: " .. tostring(err), Duration=5})
                sendWebhook("Jogador **"..playerName.."** teve um erro ao validar a key: " .. tostring(err))
            else
                sendWebhook("Jogador **"..playerName.."** validou a key com sucesso.")
            end
        else
            Rayfield:Notify({Title="Error", Content="Invalid key!", Duration=5})
            sendWebhook("Jogador **"..playerName.."** tentou usar uma key inválida.")
        end
    end
})

-- MAIN WINDOW
function openMainWindow()
    warn("Tentando criar a main window...")
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
                sendWebhook("Jogador **"..playerName.."** ativou o Rollback trait.")
            else
                Rayfield:Notify({Title="Rollback", Content="Rollback desativado.", Duration=3})
                sendWebhook("Jogador **"..playerName.."** desativou o Rollback trait.")
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
                else
                    sendWebhook("Jogador **"..playerName.."** confirmou o Rollback (rejoin).")
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
                sendWebhook("Jogador **"..playerName.."** usou Rejoin.")
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
    warn("Main window criada com sucesso!")
end

