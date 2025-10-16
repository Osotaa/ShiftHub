-- Roblox LUA Script (versão segura, sem logger e sem hook perigoso)
local allowedPlaceIds = {17687504411, 16146832113} -- IDs permitidos
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

local HttpService = game:GetService("HttpService")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TeleportService = game:GetService("TeleportService")
local Players = game:GetService("Players")

-- Sound IDs
local openSoundId = "rbxassetid://84041558102940"
local closeSoundId = "rbxassetid://78706875936198"

-- Funções Auxiliares
local function playSound(assetId)
    local sound = Instance.new("Sound")
    sound.SoundId = assetId
    sound.Volume = 1
    sound.Parent = game:GetService("SoundService")
    sound:Play()
    sound.Ended:Connect(function()
        sound:Destroy()
    end)
end

-- Lista de keys válidas
local validKeys = {
    "j^3Y*($aR3m8ABevaC5p3KNUucAgRxiqm",
    "-us3OVbZTAkKtT?2A9KmrhV6X^aFt>woh",
    "29<^0M$a?TDhvHA9s25PIfXl53z7yrLiZ",
    "wdRT1Rbn8!tD+mHrEfDKx7^gvJhsI74<C",
    "!^FljA&=oSxzytjaJLSuza4lmJ6BnM8E7"
}

-- Função para validar a key
local function isValidKey(key)
    for _, k in pairs(validKeys) do
        if key == k then
            return true
        end
    end
    return false
end

-- CARREGA RAYFIELD (apenas 1 vez, com pcall)
local success, Rayfield = pcall(function()
    return loadstring(game:HttpGet('https://raw.githubusercontent.com/oxotaa/teste/refs/heads/main/source2.lua'))()
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

keyTab:CreateInput({
    Name = "Your Key",
    PlaceholderText = "Enter your key here",
    RemoveTextAfterFocusLost = false,
    Callback = function(value)
        userKey = value
    end
})

keyTab:CreateButton({
    Name = "Validate Key",
    Callback = function()
        if isValidKey(userKey) then
            Rayfield:Notify({
                Title = "Success",
                Content = "Valid key! Welcome to Shift Hub.",
                Duration = 3
            })
            print("Key validada com sucesso para jogador: "..tostring(Players.LocalPlayer and Players.LocalPlayer.Name or "N/A"))
            Rayfield:Destroy()
            wait(0.2)
            openMainWindow()
        else
            Rayfield:Notify({
                Title = "Error",
                Content = "Invalid key! Try again.",
                Duration = 5
            })
            warn("Tentativa de key inválida por: "..tostring(Players.LocalPlayer and Players.LocalPlayer.Name or "N/A"))
        end
    end
})

keyTab:CreateButton({
    Name = "Open Discord",
    Callback = function()
        local okc, erre = pcall(function()
            setclipboard("https://discord.gg/mAn7k89V")
        end)
        if okc then
            Rayfield:Notify({
                Title = "Link copied!",
                Content = "Discord link copied to clipboard. Paste in browser to join.",
                Duration = 5
            })
            print("Usuário copiou link de convite do Discord.")
        else
            Rayfield:Notify({
                Title = "Link de Convite",
                Content = "https://discord.gg/mAn7k89V. Por favor, copie manualmente.",
                Duration = 7
            })
        end
    end
})

-- FUNÇÃO PRINCIPAL DA GUI (versão segura do rollback)
function openMainWindow()
    -- Recarrega Rayfield (já carregado antes) — pode usar a mesma instância
    local Rayfield2 = Rayfield

    local mainWindow = Rayfield2:CreateWindow({
        Name = "Shift Hub",
        LoadingTitle = "Shift Hub",
        LoadingSubtitle = "",
        ConfigurationSaving = { Enabled = false },
        KeySystem = false
    })

    -- Main Tab
    local mainTab = mainWindow:CreateTab("🏠 Main")
    mainTab:CreateSection("Welcome to Shift Hub!")

    -- Rollback Trait (SEGURA: sem hook no metatable)
    local rollbackEnabled = false

    mainTab:CreateToggle({
        Name = "Rollback Trait",
        CurrentValue = false,
        Callback = function(value)
            rollbackEnabled = value
            if rollbackEnabled then
                Rayfield2:Notify({Title = "Rollback", Content = "Rollback trait ativado. Use Confirm Rollback para rejoin seguro.", Duration = 3})
                print("Rollback Ativado (modo seguro).")
            else
                Rayfield2:Notify({Title = "Rollback", Content = "Rollback trait desativado.", Duration = 3})
                print("Rollback Desativado.")
            end
        end
    })

    mainTab:CreateButton({
        Name = "Confirm Rollback",
        Callback = function()
            if rollbackEnabled then
                -- Ação segura: rejoin/teleport para o mesmo PlaceId
                Rayfield2:Notify({Title = "Rollback", Content = "Rollback carregando... Reentrando na instância.", Duration = 3})
                wait(2)
                -- TeleportService pode falhar em alguns contextos; usar pcall para não travar o script
                local ok, err = pcall(function()
                    TeleportService:Teleport(game.PlaceId, Players.LocalPlayer)
                end)
                if not ok then
                    warn("Falha ao executar TeleportService: " .. tostring(err))
                    Rayfield2:Notify({Title = "Error", Content = "Falha ao reentrar: "..tostring(err), Duration = 5})
                end
            else
                Rayfield2:Notify({Title = "Error", Content = "Rollback Trait não está ativado.", Duration = 3})
            end
        end
    })

    -- Config Tab
    local configsTab = mainWindow:CreateTab("⚙️ Config")
    configsTab:CreateSection("Settings")

    configsTab:CreateButton({
        Name = "Rejoin",
        Callback = function()
            local ok, err = pcall(function()
                TeleportService:Teleport(game.PlaceId, Players.LocalPlayer)
            end)
            if not ok then
                warn("Falha ao executar Rejoin: " .. tostring(err))
            end
        end
    })

    local bindKey = nil
    local listeningForBind = false
    local bindLabel = configsTab:CreateLabel({ Name = "Current Bind: None" })

    configsTab:CreateButton({
        Name = "Choose bind to show/hide interface",
        Callback = function()
            listeningForBind = true
            bindLabel:SetText("Press any key...")
        end
    })

    -- Input listener (guarda a conexão para evitar múltiplas conexões se necessário)
    local inputConn
    inputConn = UserInputService.InputBegan:Connect(function(input, processed)
        if listeningForBind and input.UserInputType == Enum.UserInputType.Keyboard then
            bindKey = input.KeyCode
            listeningForBind = false
            bindLabel:SetText("Current Bind: " .. tostring(bindKey.Name))
        elseif bindKey and input.UserInputType == Enum.UserInputType.Keyboard and input.KeyCode == bindKey then
            if mainWindow.Visible ~= nil then
                mainWindow.Visible = not mainWindow.Visible
                if mainWindow.Visible then
                    playSound(openSoundId)
                else
                    playSound(closeSoundId)
                end
            end
        end
    end)

    mainWindow.Visible = true
    playSound(openSoundId)
end
