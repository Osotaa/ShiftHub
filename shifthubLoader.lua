-- ===============================
-- ShiftHub Loader (com notificações Rayfield)
-- ===============================

local API_BASE_URL = "https://patchily-droopiest-herbert.ngrok-free.dev/"
local key = nil

-- Serviços
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

-- Identificação do usuário
local robloxId = LocalPlayer.UserId
local hwid = tostring(robloxId) .. "_" .. LocalPlayer.Name:gsub("%s+", ""):lower()

-- ===============================
-- Carrega Rayfield (para notificações)
-- ===============================
local Rayfield = loadstring(game:HttpGet("https://raw.githubusercontent.com/Osotaa/teste/refs/heads/main/source2.lua"))()

-- Função de notificação
local function notify(message, title)
    Rayfield:Notify({
        Title = title or "Shift Hub",
        Content = message,
        Duration = 3
    })
end

-- ===============================
-- Funções de API
-- ===============================
local function makeApiRequest(endpoint, params)
    local base = API_BASE_URL:gsub("/$", "")
    local query = ""
    for k, v in pairs(params) do
        query = query .. string.format("%s=%s&", k, v)
    end
    query = query:sub(1, #query - 1)
    local url = string.format("%s/%s?%s", base, endpoint, query)

    local success, response = pcall(function()
        return game:HttpGet(url, true)
    end)

    if not success then
        warn("Erro na comunicação com a API.")
        return "erro_comunicacao"
    end
    return response
end

local function getAutomaticKey()
    local response = makeApiRequest("get-key-by-roblox", { robloxId = robloxId })
    if response == "no_key_found" then
        warn("Roblox ID não está vinculado a nenhuma chave.")
        return nil
    elseif response == "erro_comunicacao" or response == "erro_parametros" then
        return nil
    else
        return response
    end
end

local function verifyAuth(userKey, userHwid)
    return makeApiRequest("verify", { key = userKey, hwid = userHwid })
end

-- ===============================
-- Loader principal
-- ===============================
local function runLoader()
    notify("Codificando jogo...", "Shift Hub")
    wait(1)

    local allowedPlaceIds = {
        [17687504411] = "All Star Tower Defense",
        [16146832113] = "Anime Vanguards"
    }

    local currentPlaceId = game.PlaceId
    local gameName = allowedPlaceIds[currentPlaceId]

    if not gameName then
        warn("Script só funciona em All Star Tower Defense e Anime Vanguards.")
        return
    end

    notify("Jogo reconhecido: " .. gameName, "Shift Hub")
    wait(1)
    notify("Iniciando Shift Hub", "Shift Hub")

    local automaticKey = getAutomaticKey()
    if not automaticKey then
        warn("Vincule seu Roblox ID à key no bot Discord!")
        return
    end

    local authResponse = verifyAuth(automaticKey, hwid)
    key = automaticKey

    if authResponse == "hwid_valido" or authResponse == "hwid_registrado" then
        -- Define globals para o script principal
        _G.ShiftHub_Validated = true
        _G.GameName = gameName

        -- Executa o ShiftHubScript
        local success, err = pcall(function()
            loadstring(game:HttpGet("https://raw.githubusercontent.com/Osotaa/ShiftHub/refs/heads/main/ShiftHubScript.lua"))()
        end)

        if not success then
            warn("Erro ao executar ShiftHubScript: " .. err)
        end
    elseif authResponse == "script_key_invalida" then
        warn("Licença inválida.")
    elseif authResponse == "hwid_diferente" then
        warn("HWID diferente. Sua chave está vinculada a outro dispositivo.")
    else
        warn("Falha na autenticação.")
    end
end

-- Executa loader
runLoader()
