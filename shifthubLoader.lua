-- ESTE É O SCRIPT LOADER FINAL E CORRIGIDO
local API_URL_BASE = "https://patchily-droopiest-herbert.ngrok-free.dev/verify"

-- === FUNÇÃO TRIM ===
local function trim(s)
    s = s:gsub("^%s+", "")
    return s:gsub("%s+$", "")
end

local function getHwid()
    local hwid = ""
    local user = getfenv().getuser
    local user_name = user and user().Name or "UnknownUser"
    local system = getfenv().gethwid or getfenv().getip or getfenv().tostring

    if system then
        local ok, result = pcall(system)
        if ok and result ~= nil then
            hwid = tostring(result)
        end
    end

    if hwid == "" or hwid == "Unknown" then
        local HttpService = game:GetService("HttpService")
        local computer_name = HttpService:GenerateGUID(false)
        hwid = user_name .. "_" .. computer_name
    end

    return tostring(hwid):gsub(" ", "_"):sub(1, 64)
end

-- === MODIFICAÇÃO 2: PEDIR A CHAVE AO USUÁRIO (CORREÇÃO DE GETTEXTBOX) ===

-- Utilize a função gettextinput() que é o padrão da maioria dos executores.
local script_key = gettextinput("ShiftHub Key", "Insira sua Key de Acesso de 16 dígitos aqui:")

if not script_key or #script_key < 16 then
    error("[ShiftHub Loader] Acesso Negado: Key Inválida ou não inserida. [C:400]")
end

_G.key_to_check = script_key

local user_hwid = getHwid()

local full_url = string.format("%s?key=%s&hwid=%s", API_URL_BASE, script_key, user_hwid)

print("[ShiftHub Loader] URL Enviada para Validação: " .. full_url)
print("[ShiftHub Loader] Contatando Servidor de Validação...")

local success, result = pcall(function()
    return game:HttpGet(full_url, true)
end)

if not success then
    error("[ShiftHub Loader] Erro ao conectar com o Servidor de Validação. Verifique a URL.")
end

local response = trim(result):lower()
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

local GITHUB_SCRIPT_URL = "https://raw.githubusercontent.com/Osotaa/ShiftHub/main/ShiftHubScript.lua" -- Verifique se este link está correto!

if VALIDACAO_SUCESSO then
    _G.ShiftHub_Validated = true

    print("[ShiftHub Loader] Carregando script principal de: " .. GITHUB_SCRIPT_URL)
    loadstring(game:HttpGet(GITHUB_SCRIPT_URL, true))()
else
    warn("[ShiftHub Loader] Script principal não carregado.")
end


