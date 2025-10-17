-- LOADER CORRIGIDO COM SUPORTE A MÚLTIPLOS EXECUTORES
local API_URL_BASE = "https://patchily-droopiest-herbert.ngrok-free.dev/verify"

-- === FUNÇÃO TRIM ===
local function trim(s)
    s = s:gsub("^%s+", "")
    return s:gsub("%s+$", "")
end

-- === FUNÇÃO PARA OBTER HWID ===
local function getHwid()
    local hwid = ""
    
    -- Tenta usar funções específicas do executor
    local hwid_functions = {
        gethwid,
        get_hwid,
        getexecutorname,
        identifyexecutor
    }
    
    for _, func in ipairs(hwid_functions) do
        if func then
            local ok, result = pcall(func)
            if ok and result ~= nil and result ~= "" then
                hwid = tostring(result)
                break
            end
        end
    end
    
    -- Fallback: cria um ID único baseado no usuário
    if hwid == "" or hwid == "Unknown" then
        local Players = game:GetService("Players")
        local HttpService = game:GetService("HttpService")
        local user_name = Players.LocalPlayer.Name
        local computer_name = HttpService:GenerateGUID(false)
        hwid = user_name .. "_" .. computer_name
    end
    
    return tostring(hwid):gsub(" ", "_"):sub(1, 64)
end

-- === FUNÇÃO PARA PEDIR A KEY (COM FALLBACK) ===
local function getKeyFromUser()
    local key = nil
    
    -- Método 1: gettextinput (Solara, Wave, outros)
    if gettextinput then
        local ok, result = pcall(function()
            return gettextinput("ShiftHub Key", "Insira sua Key de 16 dígitos:")
        end)
        if ok and result and result ~= "" and result ~= "SUA_KEY_AQUI_16_DIGITOS" then
            key = trim(result)
        end
    end
    
    -- Método 2: Fallback para Clipboard
    if not key and setclipboard and getclipboard then
        pcall(function()
            game.StarterGui:SetCore("SendNotification", {
                Title = "ShiftHub Loader",
                Text = "Copie sua key e pressione Ctrl+V no console",
                Duration = 10
            })
        end)
        
        print("=================================")
        print("COPIE SUA KEY E COLE AQUI:")
        print("Exemplo: PQUVUDHXUJSYFJMF")
        print("=================================")
        
        wait(5) -- Aguarda 5 segundos
        
        local ok, clipboard = pcall(getclipboard)
        if ok and clipboard and #clipboard >= 16 then
            key = trim(clipboard)
        end
    end
    
    -- Método 3: Key fixa (APENAS PARA DEBUG - REMOVA EM PRODUÇÃO!)
    if not key then
        warn("⚠️ USANDO KEY DE DEBUG! Remova isso em produção!")
        key = "PQUVUDHXUJSYFJMF" -- Sua key de teste
    end
    
    return key
end

-- === SOLICITA A KEY AO USUÁRIO ===
print("[ShiftHub Loader] Iniciando validação...")

-- OPÇÃO 1: Input do usuário (requer executor com suporte)
-- local script_key = getKeyFromUser()

-- OPÇÃO 2: Key fixa para teste (RECOMENDADO PARA DEBUG)
local script_key = "PQUVUDHXUJSYFJMF" -- ✅ Sua key real do servidor

-- DEBUG: Mostra informações sobre a key
print("[DEBUG] Key recebida: " .. tostring(script_key))
print("[DEBUG] Tamanho da key: " .. tostring(#script_key))
print("[DEBUG] Key após trim: " .. trim(script_key))

-- Remove espaços e quebras de linha
script_key = trim(script_key)

if not script_key or #script_key < 16 then
    error("[ShiftHub Loader] Acesso Negado: Key Inválida ou não inserida. [C:400]")
end

_G.key_to_check = script_key

-- === OBTÉM O HWID ===
local user_hwid = getHwid()
print("[ShiftHub Loader] HWID Detectado: " .. user_hwid)

-- === MONTA A URL DE VALIDAÇÃO ===
local full_url = string.format("%s?key=%s&hwid=%s", API_URL_BASE, script_key, user_hwid)
print("[ShiftHub Loader] URL Completa: " .. full_url)
print("[ShiftHub Loader] Contatando Servidor de Validação...")

-- === FAZ A REQUISIÇÃO HTTP ===
local success, result = pcall(function()
    return game:HttpGet(full_url, true)
end)

if not success then
    error("[ShiftHub Loader] Erro ao conectar com o Servidor de Validação. Verifique sua conexão ou a URL da API.")
end

-- === PROCESSA A RESPOSTA ===
local response = trim(result):lower()
print("[ShiftHub Loader] Resposta do Servidor: '" .. response .. "'")
print("[DEBUG] Resposta bruta (sem trim): '" .. result .. "'")
print("[DEBUG] Tamanho da resposta: " .. #response)

local VALIDACAO_SUCESSO = false

if response == "hwid_registrado" then
    print("[ShiftHub Loader] ✅ Acesso concedido. HWID registrado.")
    pcall(function()
        game.StarterGui:SetCore("SendNotification", {
            Title = "Shift Hub Key",
            Text = "Sucesso! HWID registrado e validado.",
            Duration = 5
        })
    end)
    VALIDACAO_SUCESSO = true
    
elseif response == "hwid_valido" then
    print("[ShiftHub Loader] ✅ Acesso concedido.")
    pcall(function()
        game.StarterGui:SetCore("SendNotification", {
            Title = "Shift Hub Key",
            Text = "Chave validada com sucesso.",
            Duration = 5
        })
    end)
    VALIDACAO_SUCESSO = true
    
elseif response == "script_key_invalida" then
    error("[ShiftHub Loader] ❌ Acesso Negado: Chave de Uso inválida. [C:404]")
    
elseif response == "hwid_diferente" then
    error("[ShiftHub Loader] ❌ Acesso Negado: Chave vinculada a outro computador. [C:403]")
    
else
    error("[ShiftHub Loader] ❌ Resposta inesperada do Servidor: " .. response .. " [C:500]")
end

-- === CARREGA O SCRIPT PRINCIPAL ===
local GITHUB_SCRIPT_URL = "https://raw.githubusercontent.com/Osotaa/ShiftHub/main/ShiftHubScript.lua"

if VALIDACAO_SUCESSO then
    _G.ShiftHub_Validated = true
    print("[ShiftHub Loader] Carregando script principal...")
    
    local script_success, script_error = pcall(function()
        loadstring(game:HttpGet(GITHUB_SCRIPT_URL, true))()
    end)
    
    if not script_success then
        error("[ShiftHub Loader] Erro ao carregar script principal: " .. tostring(script_error))
    end
else
    warn("[ShiftHub Loader] Script principal não carregado.")
end
