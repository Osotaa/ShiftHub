-- NOVO shifthub_teest.lua (COM VALIDAÇÃO REMOVIDA)

local userKey = _G.key_to_check or "KeyNotFound" -- Pega a chave curta do loader

-- *** VALIDAÇÃO DE CHAVE REMOVIDA ***
-- O LOADER JÁ GARANTIU QUE ESTA KEY É VÁLIDA VIA SEU SERVIDOR (server.js).

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
    -- ********** Use a versão corrigida do Rayfield que funcionou para você **********
    return loadstring(game:HttpGet("https://raw.githubusercontent.com/Osotaa/teste/refs/heads/main/source2.lua"))()
end)
if not success or not Rayfield then
    warn("Falha ao carregar Rayfield UI")
    return
end

-- Envia webhook ao executar o script (agora sabemos que a chave é válida)
local playerName = Players.LocalPlayer and Players.LocalPlayer.Name or "Unknown"
-- AQUI USAMOS A CHAVE CURTA, QUE FOI VALIDADA PELO SERVIDOR!
sendWebhook("Script Shift Hub executado com **SUCESSO** por **"..playerName.."** (Key: "..userKey..") no PlaceId: "..tostring(currentPlaceId))

-- Função para notificações seguras
local function safeNotify(options)
    local ok, err = pcall(function()
        Rayfield:Notify(options)
    end)
    if not ok then
        warn("Erro ao chamar Rayfield:Notify: " .. tostring(err))
        game.StarterGui:SetCore("SendNotification", {
            Title = "Erro",
            Text = "Falha na notificação: " .. tostring(err),
            Duration = 5
        })
    end
end

-- ***************************************************************
-- ** JANELA PRINCIPAL (NÃO HÁ MAIS LÓGICA DE KEY/GUI AQUI) **
-- ***************************************************************

-- MAIN WINDOW
function openMainWindow()
    warn("Tentando criar a main window...")
    local mainWindow = Rayfield:CreateWindow({
        Name = "Shift Hub",
        LoadingTitle = "Shift Hub",
        LoadingSubtitle = "Bem-vindo, " .. playerName,
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
            safeNotify({Title="Rollback", Content="Rollback ativado.", Duration=3})
            sendWebhook("Jogador **"..playerName.."** ativou o Rollback trait.")
        end
    })

    mainTab:CreateButton({
        Name = "Confirm Rollback",
        Callback = function()
            if rollbackEnabled then
                safeNotify({Title="Rollback", Content="Reentrando na instância...", Duration=3})
                wait(2)
                local ok, err = pcall(function()
                    TeleportService:Teleport(game.PlaceId, Players.LocalPlayer)
                end)
                if not ok then
                    safeNotify({Title="Error", Content="Falha ao reentrar: "..tostring(err), Duration=5})
                else
                    sendWebhook("Jogador **"..playerName.."** confirmou o Rollback (rejoin).")
                end
            else
                safeNotify({Title="Error", Content="Rollback não ativado.", Duration=3})
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

-- 3. CHAMA A JANELA PRINCIPAL
openMainWindow()
