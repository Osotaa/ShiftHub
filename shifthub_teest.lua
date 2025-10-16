-- IMPORTANTE: ALTERE 'http://localhost:3000/verify' PARA O IP PÚBLICO DO SEU SERVIDOR!
local API_URL_BASE = "https://patchily-droopiest-herbert.ngrok-free.dev/verify"

local function getHwid()
    local hwid = ""
    local user = getfenv().getuser
    local user_name = user and user().Name or "UnknownUser"
    local system = getfenv().gethwid or getfenv().getip or getfenv().tostring

    if system then
        -- Tenta obter HWID real, senão usa um fallback.
        local ok, result = pcall(system)
        if ok and result ~= nil then
            hwid = tostring(result)
        end
    end

    if hwid == "" or hwid == "Unknown" then
        -- Fallback: Gera um ID baseado no nome do usuário e um GUID
        local HttpService = game:GetService("HttpService")
        local computer_name = HttpService:GenerateGUID(false)
        hwid = user_name .. "_" .. computer_name
    end

    return tostring(hwid):gsub(" ", "_"):sub(1, 64) -- Limita o tamanho do HWID
end

-- A Chave de Uso (Script Key) é definida aqui. O bot Discord preenche esta linha.
_G.key_to_check = "6RY5BYQJZXVKJA3U" 

local user_hwid = getHwid()
local script_key = _G.key_to_check

-- Monta a URL para o seu servidor Node.js
local full_url = string.format("%s?key=%s&hwid=%s", API_URL_BASE, script_key, user_hwid)

print("[ShiftHub Loader] Contatando Servidor de Validação...")

-- Faz a requisição HTTP para o seu server.js
local success, result = pcall(function()
    return game:HttpGet(full_url, true)
end)

if not success then
    error("[ShiftHub Loader] Erro ao conectar com o Servidor de Validação. Verifique a URL.")
end

local response = result:lower():trim()
print("[ShiftHub Loader] Resposta do Servidor: " .. response)

local VALIDACAO_SUCESSO = false

if response == "hwid_registrado" then
    print("[ShiftHub Loader] Acesso concedido. HWID registrado.")
    game.StarterGui:SetCore("SendNotification", {
        Title = "Shift Hub Key",
        Text = "Sucesso! HWID registrado e validado.",
        Duration = 5
    })
    VALIDACAO_SUCESSO = true
elseif response == "hwid_valido" then
    print("[ShiftHub Loader] Acesso concedido.")
    game.StarterGui:SetCore("SendNotification", {
        Title = "Shift Hub Key",
        Text = "Chave validada com sucesso.",
        Duration = 5
    })
    VALIDACAO_SUCESSO = true
elseif response == "script_key_invalida" then
    error("[ShiftHub Loader] Acesso Negado: Chave de Uso inválida. [C:404]")
elseif response == "hwid_diferente" then
    error("[ShiftHub Loader] Acesso Negado: Chave vinculada a outro computador. [C:403]")
else
    error("[ShiftHub Loader] Resposta inesperada do Servidor. Tente novamente mais tarde. [C:500]")
end

-- Se a validação foi um sucesso, carrega o script principal do GitHub.
if VALIDACAO_SUCESSO then
    print("[ShiftHub Loader] Carregando script principal...")
    loadstring(game:HttpGet("https://raw.githubusercontent.com/Osotaa/ShiftHub/refs/heads/main/shifthub_teest.lua", true))()
else
    warn("[ShiftHub Loader] Script principal não carregado.")
end


