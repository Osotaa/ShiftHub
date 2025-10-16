-- Você deve rodar este código no seu executor.
-- ATENÇÃO: Altere a linha 2 (API_URL_BASE) para o seu IP/Domínio!
local API_URL_BASE = "http://localhost:3000/verify" -- <<< MUDE ISSO PARA SEU IP/DOMÍNIO PÚBLICO!

local function getHwid()
    local hwid = ""
    local user = getfenv().getuser
    local user_name = user and user().Name or "UnknownUser"
    local system = getfenv().gethwid or getfenv().getip or getfenv().tostring

    if system then
        hwid = tostring(system())
    end

    if hwid == "" or hwid == "Unknown" then
        local computer_name = game:GetService("HttpService"):GenerateGUID(false)
        hwid = user_name .. "_" .. computer_name
    end

    return tostring(hwid):gsub(" ", "_"):sub(1, 64)
end

-- ESTA LINHA O BOT GERA AUTOMATICAMENTE COM A CHAVE DO USUÁRIO
_G.key_to_check = "6RY5BYQJZXVKJA3U" 
local user_hwid = getHwid()
local script_key = _G.key_to_check
local full_url = string.format("%s?key=%s&hwid=%s", API_URL_BASE, script_key, user_hwid)

print("[ShiftHub Loader] Contatando API: " .. full_url)

local success, result = pcall(function()
    return game:HttpGet(full_url, true)
end)

if not success then
    error("[ShiftHub Loader] Erro ao conectar com a API. Verifique o servidor.")
end

local response = result:lower():trim()
print("[ShiftHub Loader] Resposta da API: " .. response)

local VALIDACAO_SUCESSO = false

if response == "hwid_registrado" or response == "hwid_valido" then
    print("[ShiftHub Loader] Acesso concedido.")
    VALIDACAO_SUCESSO = true
elseif response == "script_key_invalida" then
    error("[ShiftHub Loader] Acesso Negado: Chave de Uso inválida. [C:404]")
elseif response == "hwid_diferente" then
    error("[ShiftHub Loader] Acesso Negado: Chave vinculada a outro computador. Reset HWID no Discord. [C:403]")
else
    error("[ShiftHub Loader] Resposta inesperada da API. Tente novamente mais tarde. [C:500]")
end

if VALIDACAO_SUCESSO then
    -- Somente se o servidor Node.js disser OK, o script final é carregado
    loadstring(game:HttpGet("https://raw.githubusercontent.com/Osotaa/ShiftHub/refs/heads/main/shifthub_teest.lua", true))()
else
    warn("[ShiftHub Loader] Script principal não carregado devido a erro de validação.")
end
