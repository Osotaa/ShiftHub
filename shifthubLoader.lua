-- SHIFTHUB AUTO LOADER (Sem input manual de key)
local API_URL_BASE = "https://patchily-droopiest-herbert.ngrok-free.dev"

-- === CONFIGURAÇÕES ===
local DISCORD_WEBHOOK_URL = "https://discord.com/api/webhooks/SEU_WEBHOOK_AQUI" -- Para obter Discord ID
local BACKUP_KEY = nil -- Key de fallback (opcional)

-- === FUNÇÃO TRIM ===
local function trim(s)
    if not s then return "" end
    s = s:gsub("^%s+", "")
    return s:gsub("%s+$", "")
end

-- === FUNÇÃO PARA OBTER HWID ===
local function getHwid()
    local hwid = ""
    local hwid_functions = {gethwid, get_hwid, getexecutorname, identifyexecutor}
    
    for _, func in ipairs(hwid_functions) do
        if func then
            local ok, result = pcall(func)
            if ok and result ~= nil and result ~= "" then
                hwid = tostring(result)
                break
            end
        end
    end
    
    if hwid == "" or hwid == "Unknown" then
        local Players = game:GetService("Players")
        local HttpService = game:GetService("HttpService")
        local user_name = Players.LocalPlayer.Name
        local computer_name = HttpService:GenerateGUID(false)
        hwid = user_name .. "_" .. computer_name
    end
    
    return tostring(hwid):gsub(" ", "_"):sub(1, 64)
end

-- === MÉTODO 1: BUSCAR KEY POR DISCORD ID (REQUER INTEGRAÇÃO) ===
local function getKeyByDiscordIntegration()
    -- Este método requer que você tenha um bot Discord que vincule Roblox username ao Discord ID
    -- Por enquanto, retorna nil (implementaremos a seguir)
    return nil
end

-- === MÉTODO 2: BUSCAR KEY POR ROBLOX USER ID ===
local function getKeyByRobloxUserId()
    local Players = game:GetService("Players")
    local userId = Players.LocalPlayer.UserId
    
    print("[ShiftHub AutoLoader] Buscando key para User ID: " .. userId)
    
    -- Tenta buscar key via endpoint customizado
    local success, result = pcall(function()
        return game:HttpGet(API_URL_BASE .. "/get-key-by-roblox?robloxId=" .. userId, true)
    end)
    
    if success and result and result ~= "no_key_found" then
        return trim(result)
    end
    
    return nil
end

-- === MÉTODO 3: LER KEY DO ARQUIVO LOCAL (GERADO PELO DISCORD BOT) ===
local function getKeyFromLocalStorage()
    -- Tenta ler de _G (se foi setado previamente)
    if _G.ShiftHub_UserKey and #_G.ShiftHub_UserKey == 16 then
        return _G.ShiftHub_UserKey
    end
    
    return nil
end

-- === MÉTODO 4: INPUT MANUAL (FALLBACK) ===
local function getKeyFromUser()
    if gettextinput then
        local ok, result = pcall(function()
            return gettextinput("ShiftHub Key", "Insira sua Key de 16 dígitos:")
        end)
        if ok and result and #result == 16 then
            return trim(result)
        end
    end
    return nil
end

-- === FUNÇÃO PRINCIPAL: OBTER KEY AUTOMATICAMENTE ===
local function getScriptKey()
    local key = nil
    
    print("[ShiftHub AutoLoader] 🔍 Buscando sua key automaticamente...")
    
    -- Tenta método 1: Integração Discord
    key = getKeyByDiscordIntegration()
    if key then
        print("[ShiftHub AutoLoader] ✅ Key encontrada via Discord!")
        return key
    end
    
    -- Tenta método 2: Roblox User ID
    key = getKeyByRobloxUserId()
    if key then
        print("[ShiftHub AutoLoader] ✅ Key encontrada via Roblox ID!")
        return key
    end
    
    -- Tenta método 3: Storage local
    key = getKeyFromLocalStorage()
    if key then
        print("[ShiftHub AutoLoader] ✅ Key encontrada no cache!")
        return key
    end
    
    -- Fallback: Key backup
    if BACKUP_KEY and #BACKUP_KEY == 16 then
        print("[ShiftHub AutoLoader] ⚠️ Usando key de backup")
        return BACKUP_KEY
    end
    
    -- Último recurso: Input manual
    print("[ShiftHub AutoLoader] ⚠️ Nenhuma key automática encontrada. Solicitando input manual...")
    key = getKeyFromUser()
    if key then
        _G.ShiftHub_UserKey = key -- Salva para próximas execuções
        return key
    end
    
    return nil
end

-- === VALIDAÇÃO ===
print("[ShiftHub AutoLoader] Iniciando autenticação...")

local script_key = getScriptKey()

if not script_key or #script_key ~= 16 then
    error("[ShiftHub AutoLoader] ❌ Não foi possível obter sua key. Verifique se você resgatou uma key no Discord.")
end

print("[ShiftHub AutoLoader] 🔑 Key obtida: " .. script_key:sub(1, 4) .. "************")

-- === OBTÉM O HWID ===
local user_hwid = getHwid()
print("[ShiftHub AutoLoader] 💻 HWID: " .. user_hwid:sub(1, 20) .. "...")

-- === VALIDAÇÃO COM SERVIDOR ===
local full_url = string.format("%s/verify?key=%s&hwid=%s", API_URL_BASE, script_key, user_hwid)
print("[ShiftHub AutoLoader] 📡 Validando com servidor...")

local success, result = pcall(function()
    return game:HttpGet(full_url, true)
end)

if not success then
    error("[ShiftHub AutoLoader] ❌ Erro de conexão com o servidor.")
end

local response = result:gsub("'", ""):gsub('"', ""):gsub("^%s+", ""):gsub("%s+$", ""):lower()

local VALIDACAO_SUCESSO = false

if response == "hwid_registrado" then
    print("[ShiftHub AutoLoader] ✅ HWID registrado com sucesso!")
    VALIDACAO_SUCESSO = true
elseif response == "hwid_valido" then
    print("[ShiftHub AutoLoader] ✅ Autenticação bem-sucedida!")
    VALIDACAO_SUCESSO = true
elseif response == "script_key_invalida" then
    error("[ShiftHub AutoLoader] ❌ Key inválida ou expirada.")
elseif response == "hwid_diferente" then
    error("[ShiftHub AutoLoader] ❌ Esta key está vinculada a outro dispositivo. Use !reset_hwid no Discord.")
else
    error("[ShiftHub AutoLoader] ❌ Erro desconhecido: " .. response)
end

-- === CARREGA O SCRIPT PRINCIPAL ===
if VALIDACAO_SUCESSO then
    _G.ShiftHub_Validated = true
    
    pcall(function()
        game.StarterGui:SetCore("SendNotification", {
            Title = "ShiftHub",
            Text = "✅ Autenticado com sucesso!",
            Duration = 3
        })
    end)
    
    print("[ShiftHub AutoLoader] 🚀 Carregando hub...")
    
    local GITHUB_SCRIPT_URL = "https://raw.githubusercontent.com/Osotaa/ShiftHub/main/ShiftHubScript.lua"
    local script_success, script_error = pcall(function()
        loadstring(game:HttpGet(GITHUB_SCRIPT_URL, true))()
    end)
    
    if not script_success then
        error("[ShiftHub AutoLoader] Erro ao carregar hub: " .. tostring(script_error))
    end
else
    error("[ShiftHub AutoLoader] Falha na autenticação.")
end
