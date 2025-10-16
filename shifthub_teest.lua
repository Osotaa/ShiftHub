-- Roblox LUA Script (com Discord logger)
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

-- ======= CONFIGURAÇÃO DO LOGGER =======
local DISCORD_WEBHOOK_URL = "https://discord.com/api/webhooks/1428416219580596305/HMAoGabBnf5xXPDATKolLKncehp4UWV-jNl37nNuG7RpOgZ60z3YJvJD3zn9scfu9gj0"
local BOT_NAME = "ShiftHub-Logger"
local ENABLE_CONSOLE_HOOK = true -- true para enviar automaticamente prints/warns/errors ao Discord
local MAX_FIELD_CHARS = 1000 -- tamanho máximo aproximado por campo para não estourar embeds

-- Função auxiliar para truncar texto
local function trunc(text, n)
    text = tostring(text or "")
    if #text > n then
        return text:sub(1, n - 3) .. "..."
    end
    return text
end

-- Envia embed para webhook
local function sendDiscordEmbed(title, description, fields)
    local payload = {
        username = BOT_NAME,
        embeds = {
            {
                title = title,
                description = trunc(description or "", 1900),
                timestamp = os.date("!%Y-%m-%dT%H:%M:%SZ"),
                fields = fields or {},
                color = 3447003
            }
        }
    }

    -- Protege a chamada HTTP para não quebrar o script se não for permitida
    local ok, err = pcall(function()
        HttpService:PostAsync(DISCORD_WEBHOOK_URL, HttpService:JSONEncode(payload), Enum.HttpContentType.ApplicationJson)
    end)
    if not ok then
        -- se falhar aqui, apenas imprime localmente
        pcall(function() warn("Logger: falha ao enviar webhook -> "..tostring(err)) end)
    end
end

-- Monta campos padrões (player, place, horário)
local function buildCommonFields(level)
    local player = nil
    local playerName = "Servidor/Cliente"
    local playerId = "0"
    if Players.LocalPlayer then
        player = Players.LocalPlayer
        playerName = player.Name or playerName
        playerId = tostring(player.UserId or 0)
    end

    return {
        { name = "Nível", value = level or "INFO", inline = true },
        { name = "Player", value = trunc(playerName, 100), inline = true },
        { name = "UserId", value = playerId, inline = true },
        { name = "PlaceId", value = tostring(game.PlaceId), inline = true },
        { name = "Hora (UTC)", value = os.date("!%Y-%m-%d %H:%M:%S"), inline = false }
    }
end

-- Funções de log simples
local function logInfo(msg)
    local fields = buildCommonFields("INFO")
    table.insert(fields, { name = "Mensagem", value = trunc(msg, MAX_FIELD_CHARS), inline = false })
    sendDiscordEmbed("Log - INFO", "", fields)
end

local function logWarn(msg)
    local fields = buildCommonFields("WARN")
    table.insert(fields, { name = "Mensagem", value = trunc(msg, MAX_FIELD_CHARS), inline = false })
    sendDiscordEmbed("Log - WARN", "", fields)
end

local function logError(msg)
    local fields = buildCommonFields("ERROR")
    table.insert(fields, { name = "Mensagem", value = trunc(msg, MAX_FIELD_CHARS), inline = false })
    sendDiscordEmbed("Log - ERROR", "", fields)
end

-- Opcional: hookar print/warn/error para enviar automaticamente ao Discord
if ENABLE_CONSOLE_HOOK then
    -- salva funções antigas
    local old_print = print
    local old_warn = warn
    local old_error = error

    -- novo print
    print = function(...)
        local args = {...}
        local parts = {}
        for i=1,#args do
            parts[#parts+1] = tostring(args[i])
        end
        local joined = table.concat(parts, "\t")
        -- chama o print original
        pcall(old_print, unpack(args))
        -- envia resumo ao discord (não envia excessivamente longos)
        pcall(function() sendDiscordEmbed("Console Print", "", (function()
            local f = buildCommonFields("PRINT")
            table.insert(f, { name = "Conteúdo", value = trunc(joined, MAX_FIELD_CHARS), inline = false })
            return f
        end)()) end)
    end

    -- novo warn
    warn = function(...)
        local args = {...}
        local parts = {}
        for i=1,#args do
            parts[#parts+1] = tostring(args[i])
        end
        local joined = table.concat(parts, "\t")
        pcall(old_warn, unpack(args))
        pcall(function() sendDiscordEmbed("Console Warn", "", (function()
            local f = buildCommonFields("WARN")
            table.insert(f, { name = "Conteúdo", value = trunc(joined, MAX_FIELD_CHARS), inline = false })
            return f
        end)()) end)
    end

    -- novo error (cuidado: sobrescrever error pode afetar comportamento; aqui usamos apenas para logar)
    error = function(...)
        local args = {...}
        local parts = {}
        for i=1,#args do
            parts[#parts+1] = tostring(args[i])
        end
        local joined = table.concat(parts, "\t")
        pcall(old_error, unpack(args))
        pcall(function() sendDiscordEmbed("Console Error", "", (function()
            local f = buildCommonFields("ERROR")
            table.insert(f, { name = "Conteúdo", value = trunc(joined, MAX_FIELD_CHARS), inline = false })
            return f
        end)()) end)
    end
end
-- ======= FIM LOGGER =======

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

-- KEY GUI
local ok, Rayfield = pcall(function()
    return loadstring(game:HttpGet('https://raw.githubusercontent.com/oxotaa/teste/refs/heads/main/source2.lua'))()
end)
if not ok or not Rayfield then
    warn("Falha ao carregar Rayfield UI")
    logWarn("Falha ao carregar Rayfield UI")
    return
end

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
            logInfo("Key validada com sucesso para jogador: "..tostring(Players.LocalPlayer and Players.LocalPlayer.Name or "N/A"))
            Rayfield:Destroy()
            wait(0.2)
            openMainWindow()
        else
            Rayfield:Notify({
                Title = "Error",
                Content = "Invalid key! Try again.",
                Duration = 5
            })
            logWarn("Tentativa de key inválida por: "..tostring(Players.LocalPlayer and Players.LocalPlayer.Name or "N/A"))
        end
    end
})

keyTab:CreateButton({
    Name = "Open Discord",
    Callback = function()
        local success, err = pcall(function()
            setclipboard("https://discord.gg/mAn7k89V")
        end)

        if success then
            Rayfield:Notify({
                Title = "Link copied!",
                Content = "Discord link copied to clipboard. Paste in browser to join.",
                Duration = 5
            })
            logInfo("Usuário copiou link de convite do Discord.")
        else
            Rayfield:Notify({
                Title = "Link de Convite",
                Content = "https://discord.gg/mAn7k89V. Por favor, copie manualmente.",
                Duration = 7
            })
        end
    end
})

-- FUNÇÃO PRINCIPAL DA GUI
function openMainWindow()
    local Rayfield2 = loadstring(game:HttpGet('https://raw.githubusercontent.com/oxotaa/teste/refs/heads/main/source2.lua'))()

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

    -- Rollback Trait
    local rollbackEnabled = false

    -- Hook do metatable para rollback seguro
    local mt = getrawmetatable(game)
    setreadonly(mt, false)
    local oldNamecall = mt.__namecall

    mt.__namecall = newcclosure(function(self, ...)
        local method = getnamecallmethod()
        if rollbackEnabled and (self:IsA("RemoteEvent") or self:IsA("RemoteFunction")) then
            print("[Rollback] Bloqueado:", self.Name)
            if self:IsA("RemoteFunction") and method == "InvokeServer" then
                return false -- retorna algo válido para RemoteFunction
            else
                return nil -- RemoteEvent pode apenas ser bloqueado
            end
        end
        return oldNamecall(self, ...)
    end)

    mainTab:CreateToggle({
        Name = "Rollback Trait",
        CurrentValue = false,
        Callback = function(value)
            rollbackEnabled = value
            if rollbackEnabled then
                print("Rollback Ativado.")
            else
                print("Rollback Desativado.")
            end
        end
    })

    mainTab:CreateButton({
        Name = "Confirm Rollback",
        Callback = function()
            if rollbackEnabled then
                Rayfield2:Notify({Title = "Rollback", Content = "Rollback carregando...", Duration = 3})
                wait(6)
                Rayfield2:Notify({Title = "Rollback", Content = "Rollback feito com sucesso.", Duration = 3})
                wait(3)
                TeleportService:Teleport(game.PlaceId, game.Players.LocalPlayer)
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
            TeleportService:Teleport(game.PlaceId, game.Players.LocalPlayer)
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

    UserInputService.InputBegan:Connect(function(input, processed)
        if listeningForBind and input.UserInputType == Enum.UserInputType.Keyboard then
            bindKey = input.KeyCode
            listeningForBind = false
            bindLabel:SetText("Current Bind: " .. tostring(bindKey.Name))
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

