-- ===============================
-- ShiftHub Loader
-- ===============================
local API_BASE_URL = "https://patchily-droopiest-herbert.ngrok-free.dev/"
local key = nil

-- Serviços
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local StarterGui = game:GetService("StarterGui")

-- Identificação do usuário
local robloxId = LocalPlayer.UserId
local hwid = tostring(robloxId) .. "_" .. LocalPlayer.Name:gsub("%s+", ""):lower()

-- Função de notificação
local function notify(message, duration)
    duration = duration or 2
    StarterGui:SetCore("SendNotification", {
        Title = "Shift Hub",
        Text = message,
        Duration = duration
    })
end

-- Função para requisição à API
local function makeApiRequest(endpoint, params)
    local clean_base_url = API_BASE_URL:gsub("/$", "")
    local query_string = ""
    for k, v in pairs(params) do
        query_string = query_string .. string.format("%s=%s&", k, v)
    end
    query_string = query_string:sub(1, #query_string - 1)
    local url = string.format("%s/%s?%s", clean_base_url, endpoint, query_string)

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

-- ---------------------------
-- Loader principal
-- ---------------------------
local function runLoader()
    notify("Codificando jogo...", 2)
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

    notify("Jogo reconhecido: " .. gameName, 2)
    wait(1)
    notify("Iniciando Shift Hub")

    local automaticKey = getAutomaticKey()
    if not automaticKey then
        warn("Vincule seu Roblox ID à key no bot Discord!")
        return
    end

    local authResponse = verifyAuth(automaticKey, hwid)
    key = automaticKey

    if authResponse == "hwid_valido" or authResponse == "hwid_registrado" then
        -- Define global para o script principal
        _G.ShiftHub_Validated = true
        _G.GameName = gameName

        -- Executa o script principal
        local success, err = pcall(function()
    loadstring(game:HttpGet("https://raw.githubusercontent.com/oxotaa/teste/refs/heads/main/source2.lua"))()
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




