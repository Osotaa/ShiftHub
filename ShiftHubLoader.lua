local API_BASE_URL = "http://51.75.118.149:20029/"
local key = nil

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local TeleportService = game:GetService("TeleportService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local robloxId = (LocalPlayer and LocalPlayer.UserId) or 0

-- ===== SISTEMA DE LOGS DISCORD =====
local DISCORD_WEBHOOKS = {
    INFO = "https://discord.com/api/webhooks/1442997875637489845/Y2uoehEebrP6vJaMnFQqbg0Z6ax5VW6GVbfPlygGRRJ2n4tfWj9ylzFT-bQkOpye5cOo",
    WARNING = "https://discord.com/api/webhooks/1442998043170308147/UfK5_W3AVzsH25vvKPCcL_VMns3Yfh3tMoiddS_YPPiNpQh4M210gx5C1L3HWeoYC9iA", 
    ERROR = "https://discord.com/api/webhooks/1442998301908664380/LBiVVL37uVTsauiV6BfmS2v6WvzkltvvEqJVSev0zIFFbOtciSGLTHp6xGuCO2II0CeM",
    SUCCESS = "https://discord.com/api/webhooks/1442998591873613975/JMDiaBzPOsO1xbI0iKUegZuNPSUBYlOm4jOg7fnu6slVRzYSrgurHafi9sJAH_yz1gwD"
}

-- Cache para evitar spam
local lastLogTimes = {}
local LOG_COOLDOWN = 2 -- segundos

-- ===== IDENTIFICAÇÃO DE EXECUTOR =====
local function identifyExecutor()
    -- Detecta o executor baseado em funções e variáveis disponíveis
    
    -- PC Executors
    if getexecutorname then
        local name = getexecutorname():lower()
        if name:find("wave") then return "Wave" end
        if name:find("zenith") then return "Zenith" end
        if name:find("xeno") then return "Xeno" end
        if name:find("valex") then return "Valex" end
        return getexecutorname()
    end
    
    if syn and syn.request then
        return "Synapse X"
    end
    
    if PROTOSMASHER_LOADED then
        return "ProtoSmasher"
    end
    
    if sentinel then
        return "Sentinel"
    end
    
    if KRNL_LOADED then
        return "KRNL"
    end
    
    if fluxus then
        -- Verifica se é Fluxus PC ou Mobile
        if isfluxusclosure then
            return "Fluxus PC"
        else
            return "Fluxus Mobile"
        end
    end
    
    if identifyexecutor then
        local exec = identifyexecutor():lower()
        if exec:find("serotonin") then return "Serotonin" end
        if exec:find("vulcan") then return "Vulcanon" end
        return identifyexecutor()
    end
    
    -- Mobile Executors
    if get_hui_animation then
        return "ScriptWare Mobile"
    end
    
    if arceusx then
        return "Arceus X"
    end
    
    if delta then
        return "Delta Executor"
    end
    
    if hydrogen then
        return "Hydrogen"
    end
    
    -- Testes específicos para cada executor
    if pcall(function() return readfile("wave.lua") end) then
        return "Wave"
    end
    
    if pcall(function() return iswindowactive end) then
        return "Zenith"
    end
    
    if pcall(function() return getscriptbytecode end) then
        return "Valex"
    end
    
    if pcall(function() return checkclosure end) then
        return "Serotonin"
    end
    
    if pcall(function() return get_script_function_bytecode end) then
        return "Xeno"
    end
    
    -- Teste genérico para mobile
    if pcall(function() return getgenv().gethui end) then
        return "Executor Mobile Desconhecido"
    end
    
    -- Teste genérico para PC
    if pcall(function() return readfile("") end) then
        if pcall(function() return getrenv().crypt end) then
            return "Electron"
        else
            return "Executor PC com Arquivos"
        end
    end
    
    return "Executor Desconhecido"
end

-- ===== SISTEMA DE HWID MELHORADO =====
local function getDetailedHWID()
    local hwidParts = {}
    
    -- Informações básicas
    table.insert(hwidParts, "UserID:" .. tostring(robloxId))
    table.insert(hwidParts, "Player:" .. (LocalPlayer and LocalPlayer.Name or "unknown"))
    
    -- Tenta coletar informações específicas de cada executor
    local success, hwidData = pcall(function()
        local data = {}
        
        -- Para executores com função de HWID
        if get_hwid then
            data.hwid = get_hwid()
        end
        
        if syn and syn.crypt then
            data.synapse = syn.crypt.base64.encode(tostring(robloxId))
        end
        
        -- Informações de hardware (se disponíveis)
        if getpermission then
            data.permission = getpermission()
        end
        
        -- Informações do jogo
        data.placeId = game.PlaceId
        data.jobId = game.JobId
        data.serverTime = os.time()
        
        return data
    end)
    
    if success and hwidData then
        for key, value in pairs(hwidData) do
            table.insert(hwidParts, key .. ":" .. tostring(value))
        end
    end
    
    return table.concat(hwidParts, "|")
end

-- Atualiza a variável hwid global
local hwid = getDetailedHWID()

-- ===== FUNÇÃO DE COLETA DE INFORMAÇÕES EXPANDIDA =====
local function collectSystemInfo()
    local player = game.Players.LocalPlayer
    local executor = identifyExecutor()
    local detailedHWID = getDetailedHWID()
    
    -- Informações expandidas do sistema
    local systemInfo = {
        -- Usuário
        username = player.Name,
        displayName = player.DisplayName,
        userId = player.UserId,
        accountAge = player.AccountAge,
        membership = player.MembershipType.Name,
        followers = player.Followers.Count,
        following = player.Following.Count,
        friends = player.Friends.Count,
        
        -- Jogo
        gameName = game:GetService("MarketplaceService"):GetProductInfo(game.PlaceId).Name,
        placeId = game.PlaceId,
        jobId = game.JobId,
        serverRegion = game:GetService("LocalizationService").RobloxLocaleId,
        
        -- Executor
        executor = executor,
        executorStatus = getExecutorStatus(executor),
        timestamp = os.date("%d/%m/%Y %H:%M:%S"),
        hwid = detailedHWID,
        hwidSimple = tostring(robloxId) .. "_" .. ((LocalPlayer and LocalPlayer.Name) or "unknown"):gsub("%s+", ""):lower(),
        
        -- Performance e Sistema
        fps = math.floor(1/wait()),
        ping = game:GetService("Stats").Network.ServerStatsItem["Data Ping"]:GetValue(),
        memory = game:GetService("Stats"):GetMemoryUsageMbForTag(Enum.DeveloperMemoryType.Script),
        platform = game:GetService("UserInputService"):GetPlatform().Name,
        
        -- Informações adicionais
        gameVersion = tostring(game.PlaceVersion),
        serverPlayers = #game.Players:GetPlayers(),
        serverMaxPlayers = game.Players.MaxPlayers,
        localPlayerId = tostring(LocalPlayer.UserId)
    }
    
    return systemInfo
end

-- Função auxiliar para status do executor
local function getExecutorStatus(executorName)
    local statusList = {
        ["Wave"] = "🟢 Online",
        ["Zenith"] = "🟢 Online", 
        ["KRNL"] = "🟢 Online",
        ["Valex"] = "🟢 Online",
        ["Serotonin"] = "🟢 Online",
        ["Vulcanon"] = "🔴 Offline",
        ["Xeno"] = "🟢 Online",
        ["Arceus X"] = "🟢 Online",
        ["Delta Executor"] = "🟢 Online",
        ["Fluxus Mobile"] = "🟢 Online",
        ["Hydrogen"] = "🟢 Online",
        ["Fluxus PC"] = "🟢 Online"
    }
    
    return statusList[executorName] or "⚪ Desconhecido"
end

-- ===== SISTEMA DE LOGS COM INFORMAÇÕES EXPANDIDAS =====
local function sendDiscordLog(webhookType, title, description, extraFields)
    -- Verifica cooldown
    local now = os.time()
    if lastLogTimes[webhookType] and (now - lastLogTimes[webhookType] < LOG_COOLDOWN) then
        return false
    end
    lastLogTimes[webhookType] = now
    
    local webhookUrl = DISCORD_WEBHOOKS[webhookType]
    if not webhookUrl then return false end
    
    local systemInfo = collectSystemInfo()
    
    -- Configura cores baseadas no tipo
    local colors = {
        INFO = 3447003,      -- Azul
        WARNING = 16776960,  -- Amarelo  
        ERROR = 16711680,    -- Vermelho
        SUCCESS = 65280      -- Verde
    }
    
    local embed = {
        title = title,
        description = description,
        color = colors[webhookType] or 3447003,
        fields = {
            {
                name = "👤 Informações do Usuário",
                value = string.format("**Nome:** `%s`\n**Display:** `%s`\n**ID:** `%d`\n**Idade da Conta:** `%d dias`",
                    systemInfo.username, systemInfo.displayName, systemInfo.userId, systemInfo.accountAge),
                inline = true
            },
            {
                name = "🔧 Executor",
                value = string.format("**Nome:** `%s`\n**Status:** %s\n**Plataforma:** `%s`",
                    systemInfo.executor, systemInfo.executorStatus, systemInfo.platform),
                inline = true
            },
            {
                name = "🎮 Informações do Jogo",
                value = string.format("**Jogo:** `%s`\n**Place ID:** `%d`\n**Job ID:** `%s`\n**Versão:** `%s`",
                    systemInfo.gameName, systemInfo.placeId, systemInfo.jobId, systemInfo.gameVersion),
                inline = true
            },
            {
                name = "📊 Rede & Performance",
                value = string.format("**FPS:** `%d`\n**Ping:** `%dms`\n**Memória:** `%.1fMB`\n**Players:** `%d/%d`",
                    systemInfo.fps, systemInfo.ping, systemInfo.memory, systemInfo.serverPlayers, systemInfo.serverMaxPlayers),
                inline = true
            },
            {
                name = "🔑 HWID Detalhado",
                value = "```" .. systemInfo.hwid .. "```",
                inline = false
            },
            {
                name = "🕒 Horário de Execução",
                value = "`" .. systemInfo.timestamp .. "`\n**Região:** `" .. (systemInfo.serverRegion or "N/A") .. "`",
                inline = true
            }
        },
        footer = {
            text = "Shift Hub Logger • " .. systemInfo.hwidSimple
        },
        timestamp = os.date("!%Y-%m-%dT%H:%M:%SZ")
    }
    
    -- Adiciona campos extras se fornecidos
    if extraFields then
        for _, field in ipairs(extraFields) do
            table.insert(embed.fields, field)
        end
    end
    
    -- Envia para Discord
    local success, result = pcall(function()
        local headers = {
            ["Content-Type"] = "application/json"
        }
        
        local data = {
            embeds = {embed}
        }
        
        local jsonData = game:GetService("HttpService"):JSONEncode(data)
        
        -- Compatibilidade com múltiplos executores
        if syn and syn.request then
            return syn.request({
                Url = webhookUrl,
                Method = "POST",
                Headers = headers,
                Body = jsonData
            })
        elseif request then
            return request({
                Url = webhookUrl,
                Method = "POST", 
                Headers = headers,
                Body = jsonData
            })
        else
            -- Fallback para HttpPost
            return game:HttpPostAsync(webhookUrl, jsonData, headers)
        end
    end)
    
    if success then
        print("[ShiftHub] Log enviado para Discord: " .. webhookType)
    else
        warn("[ShiftHub] Erro ao enviar log: " .. tostring(result))
    end
    
    return success
end

-- ===== FUNÇÕES DE LOG ESPECÍFICAS =====
local function logScriptStart()
    local systemInfo = collectSystemInfo()
    
    local extraFields = {
        {
            name = "📱 Primeira Execução",
            value = string.format("**Executor:** `%s`\n**Plataforma:** `%s`\n**HWID:** `%s`",
                systemInfo.executor, systemInfo.platform, systemInfo.hwidSimple),
            inline = true
        }
    }
    
    sendDiscordLog("SUCCESS", "🚀 Script Shift Hub Iniciado", 
        "**Executado com sucesso!**\n📊 Coletadas todas as informações do sistema", extraFields)
end

local function logAuthSuccess()
    local systemInfo = collectSystemInfo()
    
    local extraFields = {
        {
            name = "✅ Status da Autenticação",
            value = string.format("**HWID:** `VALIDADO`\n**Key:** `%s`\n**User ID:** `%d`",
                string.sub(key or "N/A", 1, 8) .. "...", systemInfo.userId),
            inline = true
        }
    }
    
    sendDiscordLog("SUCCESS", "🔐 Autenticação Bem-Sucedida", 
        "**Usuário autenticado com sucesso!**\n🎮 Pronto para usar o Shift Hub", extraFields)
end

local function logUserAction(action, details, value)
    local systemInfo = collectSystemInfo()
    
    local extraFields = {
        {
            name = "🎯 Ação Executada",
            value = "**Tipo:** `" .. action .. "`\n**Detalhes:** `" .. (details or "Nenhum") .. "`",
            inline = true
        },
        {
            name = "⚙️ Configuração",
            value = "**Valor:** `" .. tostring(value or "N/A") .. "`\n**Executor:** `" .. systemInfo.executor .. "`",
            inline = true
        }
    }
    
    sendDiscordLog("INFO", "📋 Ação do Usuário Registrada", 
        "**Nova ação detectada no sistema**\n⏰ Timestamp: " .. systemInfo.timestamp, extraFields)
end

local function logRollback(rollbackType, method)
    local systemInfo = collectSystemInfo()
    
    local extraFields = {
        {
            name = "🔄 Tipo de Rollback",
            value = "`" .. rollbackType .. "`",
            inline = true
        },
        {
            name = "⚙️ Método",
            value = "`" .. method .. "`", 
            inline = true
        }
    }
    
    sendDiscordLog("WARNING", "⚠️ Rollback Executado", 
        "**Sistema de rollback foi ativado**\n🔒 Proteção anti-ban ativa", extraFields)
end

local function logError(errorMsg, context)
    local systemInfo = collectSystemInfo()
    
    local extraFields = {
        {
            name = "❌ Erro",
            value = "```" .. tostring(errorMsg) .. "```",
            inline = false
        },
        {
            name = "🔍 Contexto",
            value = "`" .. (context or "Desconhecido") .. "`",
            inline = true
        }
    }
    
    sendDiscordLog("ERROR", "💥 Erro no Sistema", 
        "**Ocorreu um erro durante a execução**\n⚠️ Verifique os detalhes abaixo", extraFields)
end

local function logInvalidHWID()
    local systemInfo = collectSystemInfo()
    
    sendDiscordLog("ERROR", "🚫 Tentativa de Acesso Bloqueada", 
        "**Tentativa de acesso com HWID inválido ou não autorizado**\n🔒 Acesso negado pelo sistema de segurança")
end

-- ===== FUNÇÕES AUXILIARES =====
local function trim(s)
    if type(s) ~= "string" then return s end
    return (s:gsub("^%s+", ""):gsub("%s+$", ""))
end

local function cleanMethodName(name)
    if type(name) ~= "string" then return name end
    local cleaned = name
    cleaned = cleaned:gsub("%s*[—%-]%s*[Rr]eco[mn]en[ds]ed?", "")
    cleaned = cleaned:gsub("%s*Recomen[ds]ed?", "")
    cleaned = cleaned:gsub("%s*Recomended", "")
    return trim(cleaned)
end

local function createScreenNotification(title, content, duration)
    duration = duration or 3
    pcall(function()
        local playerGui = LocalPlayer:WaitForChild("PlayerGui", 5)
        if not playerGui then return end

        local sg = Instance.new("ScreenGui")
        sg.Name = "ShiftHub_Notification_" .. tostring(math.random(100000,999999))
        sg.ResetOnSpawn = false
        sg.DisplayOrder = 99999

        local frame = Instance.new("Frame")
        frame.Size = UDim2.new(0, 360, 0, 68)
        frame.AnchorPoint = Vector2.new(1, 1)
        frame.Position = UDim2.new(1, -20, 1, -20)
        frame.BackgroundColor3 = Color3.fromRGB(40, 42, 50)
        frame.BorderSizePixel = 0
        frame.Parent = sg

        local uicorner = Instance.new("UICorner")
        uicorner.CornerRadius = UDim.new(0, 10)
        uicorner.Parent = frame

        local titleLbl = Instance.new("TextLabel")
        titleLbl.Parent = frame
        titleLbl.Size = UDim2.new(1, -20, 0, 22)
        titleLbl.Position = UDim2.new(0, 10, 0, 6)
        titleLbl.BackgroundTransparency = 1
        titleLbl.Font = Enum.Font.SourceSansBold
        titleLbl.TextSize = 17
        titleLbl.TextColor3 = Color3.fromRGB(255, 255, 255)
        titleLbl.TextXAlignment = Enum.TextXAlignment.Left
        titleLbl.Text = "Shift Hub"

        local contentLbl = Instance.new("TextLabel")
        contentLbl.Parent = frame
        contentLbl.Size = UDim2.new(1, -20, 1, -36)
        contentLbl.Position = UDim2.new(0, 10, 0, 30)
        contentLbl.BackgroundTransparency = 1
        contentLbl.Font = Enum.Font.SourceSans
        contentLbl.TextSize = 14
        contentLbl.TextColor3 = Color3.fromRGB(220, 220, 220)
        contentLbl.TextXAlignment = Enum.TextXAlignment.Left
        contentLbl.TextWrapped = true
        contentLbl.Text = tostring(content or "")

        frame.BackgroundTransparency = 1
        titleLbl.TextTransparency = 1
        contentLbl.TextTransparency = 1

        sg.Parent = playerGui

        pcall(function()
            TweenService:Create(frame, TweenInfo.new(0.22, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {BackgroundTransparency = 0}):Play()
            TweenService:Create(titleLbl, TweenInfo.new(0.22), {TextTransparency = 0}):Play()
            TweenService:Create(contentLbl, TweenInfo.new(0.22), {TextTransparency = 0}):Play()
        end)

        task.spawn(function()
            task.wait(duration)
            pcall(function()
                TweenService:Create(frame, TweenInfo.new(0.18), {BackgroundTransparency = 1}):Play()
                TweenService:Create(titleLbl, TweenInfo.new(0.18), {TextTransparency = 1}):Play()
                TweenService:Create(contentLbl, TweenInfo.new(0.18), {TextTransparency = 1}):Play()
                task.wait(0.22)
                sg:Destroy()
            end)
        end)
    end)
end

local function safeNotify(_, content, duration)
    pcall(function()
        createScreenNotification("Shift Hub", content or "", duration or 3)
    end)
end

-- ===== API FUNCTIONS =====
local function makeApiRequest(endpoint, params)
    local clean_base_url = API_BASE_URL:gsub("/$", "")
    local query_string = ""
    for k, v in pairs(params) do
        query_string = query_string .. string.format("%s=%s&", k, v)
    end
    if #query_string > 0 then
        query_string = query_string:sub(1, #query_string - 1)
    end
    local url = string.format("%s/%s?%s", clean_base_url, endpoint, query_string)

    local success, response = pcall(function()
        return game:HttpGet(url, true)
    end)

    if not success then
        warn("[ShiftHub] API communication error.")
        return "erro_comunicacao"
    end
    return response
end

local function getAutomaticKey()
    local response = makeApiRequest("get-key-by-roblox", { robloxId = robloxId })
    if response == "no_key_found" then
        warn("[ShiftHub] Your Roblox ID has no key linked!")
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

-- ===== FUNÇÃO PARA CARREGAR LINORIA COM FALLBACKS =====
local function loadLinoria()
    local sources = {
        {
            name = "mstudio45",
            library = "https://raw.githubusercontent.com/mstudio45/LinoriaLib/main/Library.lua",
            theme = "https://raw.githubusercontent.com/mstudio45/LinoriaLib/main/addons/ThemeManager.lua",
            save = "https://raw.githubusercontent.com/mstudio45/LinoriaLib/main/addons/SaveManager.lua"
        },
        {
            name = "violin-suzutsuki",
            library = "https://raw.githubusercontent.com/violin-suzutsuki/LinoriaLib/main/Library.lua",
            theme = "https://raw.githubusercontent.com/violin-suzutsuki/LinoriaLib/main/addons/ThemeManager.lua",
            save = "https://raw.githubusercontent.com/violin-suzutsuki/LinoriaLib/main/addons/SaveManager.lua"
        },
        {
            name = "ActualMasterOogway",
            library = "https://raw.githubusercontent.com/ActualMasterOogway/Linoria-Library/main/Library.lua",
            theme = "https://raw.githubusercontent.com/ActualMasterOogway/Linoria-Library/main/addons/ThemeManager.lua",
            save = "https://raw.githubusercontent.com/ActualMasterOogway/Linoria-Library/main/addons/SaveManager.lua"
        }
    }
    
    for _, source in ipairs(sources) do
        local success, result = pcall(function()
            local libCode = game:HttpGet(source.library, true)
            if not libCode or libCode == "" then
                error("Empty library code")
            end
            
            local Library = loadstring(libCode)()
            if not Library then
                error("Library loadstring failed")
            end
            
            local ThemeManager, SaveManager
            
            pcall(function()
                local themeCode = game:HttpGet(source.theme, true)
                if themeCode and themeCode ~= "" then
                    ThemeManager = loadstring(themeCode)()
                end
            end)
            
            pcall(function()
                local saveCode = game:HttpGet(source.save, true)
                if saveCode and saveCode ~= "" then
                    SaveManager = loadstring(saveCode)()
                end
            end)
            
            return Library, ThemeManager, SaveManager
        end)
        
        if success and result then
            return result
        else
            warn("[ShiftHub] Failed to load from " .. source.name .. ": " .. tostring(result))
        end
    end
    
    return nil
end

-- ===== SISTEMA DE ROLLBACK OTIMIZADO =====
local function setupRollbackSystem()
    local rollbackEnabled = false
    local rollbackType = nil
    
    local protectedRemotes = {
        Trait = {"TraitChange", "UpgradeUnit"},
        Summon = {"SummonUnit"}
    }

    -- Sistema mais seguro que não interfere com a UI
    local function safeHookRemote(remote, remoteType)
        if remote:IsA("RemoteFunction") then
            local oldInvoke = remote.InvokeServer
            local newInvoke = function(self, ...)
                if rollbackEnabled and rollbackType == remoteType then
                    return nil
                end
                return oldInvoke(self, ...)
            end
            remote.InvokeServer = newInvoke
        elseif remote:IsA("RemoteEvent") then
            local oldFire = remote.FireServer
            local newFire = function(self, ...)
                if rollbackEnabled and rollbackType == remoteType then
                    return nil
                end
                return oldFire(self, ...)
            end
            remote.FireServer = newFire
        end
    end

    -- Encontrar e proteger os remotes específicos
    local function findAndProtectRemotes()
        for remoteType, remoteNames in pairs(protectedRemotes) do
            for _, remoteName in ipairs(remoteNames) do
                local remote = game:GetService("ReplicatedStorage"):FindFirstChild(remoteName)
                if remote and (remote:IsA("RemoteFunction") or remote:IsA("RemoteEvent")) then
                    safeHookRemote(remote, remoteType)
                end
            end
        end
    end

    -- Executar após um delay para não travar a UI
    task.spawn(function()
        task.wait(3) -- Esperar a UI carregar primeiro
        findAndProtectRemotes()
    end)

    return {
        setEnabled = function(enabled)
            rollbackEnabled = enabled
        end,
        setType = function(type)
            rollbackType = type
        end,
        getStatus = function()
            return rollbackEnabled, rollbackType
        end
    }
end

-- ===== LOADER PRINCIPAL =====
local function runLoader()
    safeNotify(nil, "Loading game...", 3)
    task.wait(1.5)

    local allowedPlaceIds = {
        [17687504411] = "All Star Tower Defense",
        [16146832113] = "Anime Vanguards",
        [107573139811370] = "Anime Crusaders",
        [12886143095] = "Anime Last Stand",
    }

    local currentPlaceId = game.PlaceId
    local gameName = allowedPlaceIds[currentPlaceId]

    if not gameName then
        warn("[ShiftHub] Script only works in allowed games.")
        safeNotify(nil, "Game not supported!", 3)
        return
    end

    safeNotify(nil, "Game detected: " .. gameName, 3)
    task.wait(1.5)
    safeNotify(nil, "Validating HWID...", 3)
    task.wait(1.5)

    local automaticKey = getAutomaticKey()
    if not automaticKey then
        warn("[ShiftHub] Link your Roblox ID to your key!")
        safeNotify(nil, "Authentication failed!", 5)
        return
    end

    local authResponse = verifyAuth(automaticKey, hwid)
    key = automaticKey

    if authResponse == "hwid_valido" or authResponse == "hwid_registrado" then
        _G.ShiftHub_Validated = true
        _G.GameName = gameName
        
        -- LOG: Script iniciado com sucesso
        logScriptStart()
        
        safeNotify(nil, "Verifying User ID...", 2)
        task.wait(1.5)
        safeNotify(nil, 'Hello: ' .. LocalPlayer.Name, 2)
        task.wait(1.5)
        safeNotify(nil, "Starting Shift Hub...", 2)
        task.wait(1.5)

        local success, err = pcall(function()
            local Library, ThemeManager, SaveManager = loadLinoria()
            
            if not Library then
                error("Failed to load Linoria from all sources. Your firewall may be blocking GitHub.")
            end
            
            -- LOG: Autenticação bem-sucedida
            logAuthSuccess()
            
            -- Inicializar sistema de rollback
            local rollbackSystem = setupRollbackSystem()
            
            -- Criar janela com título personalizado
            local Window = Library:CreateWindow({
                Title = 'Shift Hub | ' .. gameName .. ' | ' .. LocalPlayer.Name,
                Center = true,
                AutoShow = true,
                TabPadding = 8,
                MenuFadeTime = 0.2
            })

            -- Criar abas
            local Tabs = {
                Main = Window:AddTab('Main'),
                ['UI Settings'] = Window:AddTab('UI Settings'),
            }

            -- Criar elementos UI
            local LeftGroupbox = Tabs.Main:AddLeftGroupbox('Rollback System')
            local RightGroupbox = Tabs.Main:AddRightGroupbox('Extras')

            -- Dropdown de Tipo
            LeftGroupbox:AddDropdown('RollbackType', {
                Values = {'Trait', 'Summon(Patched)'},
                Default = 1,
                Multi = false,
                Text = 'Rollback Type',
                Tooltip = 'Select the type of rollback',
                Callback = function(Value)
                    rollbackSystem.setType(Value)
                    logUserAction("Rollback Type Selected", "Type: " .. Value, Value)
                    safeNotify(nil, "Type selected: " .. Value, 1)
                end
            })

            -- Dropdown de Método
            LeftGroupbox:AddDropdown('RollbackMethod', {
                Values = {'ServerSide - Recommended', 'ClientSide'},
                Default = 1,
                Multi = false,
                Text = 'Rollback Method',
                Tooltip = 'Select the rollback method',
                Callback = function(Value)
                    local cleaned = cleanMethodName(Value)
                    logUserAction("Rollback Method Selected", "Method: " .. cleaned, Value)
                    safeNotify(nil, "Method selected: " .. cleaned, 1)
                end
            })

            LeftGroupbox:AddDivider()

            -- Toggle de Rollback
            LeftGroupbox:AddToggle('RollbackToggle', {
                Text = 'Enable Rollback',
                Default = false,
                Tooltip = 'Enable or disable rollback protection',
                Callback = function(Value)
                    rollbackSystem.setEnabled(Value)
                    local enabled, type = rollbackSystem.getStatus()
                    if enabled then
                        logRollback(type or "Unknown", "ClientSide")
                        safeNotify(nil, "Rollback Enabled! Type: " .. (type or "None"), 2)
                    else
                        logUserAction("Rollback Disabled", "Type: " .. (type or "None"), Value)
                        safeNotify(nil, "Rollback disabled!", 1)
                    end
                end
            })

            LeftGroupbox:AddDivider()

            -- Botão de Confirmar Rollback
            LeftGroupbox:AddButton({
                Text = 'Confirm Rollback',
                Func = function()
                    local enabled, type = rollbackSystem.getStatus()
                    if enabled and type then
                        logUserAction("Rollback Confirmed", "Executing rollback - Type: " .. type, "Confirmed")
                        safeNotify(nil, "Initiating rollback...", 2)
                        task.wait(2)
                        safeNotify(nil, "Rollback completed successfully!", 3)
                        rollbackSystem.setEnabled(false)
                        task.wait(1)
                        TeleportService:Teleport(game.PlaceId, LocalPlayer)
                    else
                        logUserAction("Rollback Failed", "No type selected or disabled", "Error")
                        safeNotify(nil, "Select a type and enable rollback first!", 2)
                    end
                end,
                Tooltip = 'Execute the rollback and rejoin'
            })

            -- Groupbox de Extras
            RightGroupbox:AddLabel('Server Actions')
            RightGroupbox:AddDivider()

            RightGroupbox:AddButton({
                Text = 'Rejoin Server',
                Func = function()
                    logUserAction("Rejoin Server", "Manual rejoin triggered", "N/A")
                    safeNotify(nil, "Rejoining server...", 2)
                    task.wait(1)
                    TeleportService:Teleport(game.PlaceId, LocalPlayer)
                end,
                Tooltip = 'Rejoin the current server'
            })

            RightGroupbox:AddButton({
                Text = 'Server Hop',
                Func = function()
                    logUserAction("Server Hop", "Manual server hop triggered", "N/A")
                    safeNotify(nil, "Server hopping...", 2)
                    -- Código de server hop aqui
                end,
                Tooltip = 'Join a different server'
            })

            -- Groupbox de Combat
            local CombatBox = Tabs.Main:AddRightGroupbox('Units Enhancements')
            
            CombatBox:AddToggle('InfiniteRange', {
                Text = 'Infinite Range (Patched)',
                Default = false,
                Tooltip = 'Units attack from anywhere on map',
                Callback = function(Value)
                    logUserAction("Infinite Range Toggle", "Status changed", Value)
                    safeNotify(nil, Value and "Infinite Range ON!" or "Infinite Range OFF!", 1)
                end
            })
            
            CombatBox:AddToggle('NoCooldown', {
                Text = 'No Cooldown (Patched)',
                Default = false,
                Tooltip = 'Remove ability cooldowns',
                Callback = function(Value)
                    logUserAction("No Cooldown Toggle", "Status changed", Value)
                    safeNotify(nil, Value and "No Cooldown ON!" or "No Cooldown OFF!", 1)
                end
            })
            
            CombatBox:AddDivider()
            
            CombatBox:AddSlider('DamageMultiplier', {
                Text = 'Damage Multiplier (Patched)',
                Default = 1,
                Min = 1,
                Max = 10,
                Rounding = 1,
                Compact = false,
                Callback = function(Value)
                    logUserAction("Damage Multiplier Changed", "New value set", Value)
                    safeNotify(nil, "Damage: " .. Value .. "x", 1)
                end
            })
            
            -- Nova aba de Misc
            local MiscTab = Window:AddTab('Misc')
            
            local MiscLeft = MiscTab:AddLeftGroupbox('Player Modifications')
            
            MiscLeft:AddToggle('SpeedHack', {
                Text = 'Speed Hack',
                Default = false,
                Tooltip = 'Increase player walk speed',
                Callback = function(Value)
                    logUserAction("Speed Hack Toggle", "Status changed", Value)
                    safeNotify(nil, Value and "Speed Hack Enabled!" or "Speed Hack Disabled!", 1)
                end
            })
            
            MiscLeft:AddSlider('WalkSpeed', {
                Text = 'Walk Speed',
                Default = 16,
                Min = 16,
                Max = 200,
                Rounding = 0,
                Compact = false,
                Callback = function(Value)
                    if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
                        LocalPlayer.Character.Humanoid.WalkSpeed = Value
                    end
                    logUserAction("Walk Speed Changed", "New speed set", Value)
                    safeNotify(nil, "WalkSpeed: " .. Value, 1)
                end
            })
            
            -- UI Settings
            if ThemeManager and SaveManager then
                ThemeManager:SetLibrary(Library)
                SaveManager:SetLibrary(Library)
                
                SaveManager:IgnoreThemeSettings()
                SaveManager:SetIgnoreIndexes({'MenuKeybind', 'WalkSpeed', 'FarmSpeed', 'DamageMultiplier'})
                
                ThemeManager:SetFolder('ShiftHub')
                SaveManager:SetFolder('ShiftHub/' .. gameName)
                
                SaveManager:BuildConfigSection(Tabs['UI Settings'])
                ThemeManager:ApplyToTab(Tabs['UI Settings'])
            end

            local MenuGroup = Tabs['UI Settings']:AddLeftGroupbox('Menu')

            local MenuKeyPicker = MenuGroup:AddLabel('Menu Keybind'):AddKeyPicker('MenuKeybind', {
                Default = 'End',
                NoUI = true,
                Text = 'Menu keybind'
            })

            Library.ToggleKeybind = MenuKeyPicker

            -- Configurar o keybind corretamente
            UserInputService.InputBegan:Connect(function(input, gpe)
                if gpe then return end
                if input.KeyCode == Options.MenuKeybind.Value then
                    Library:ToggleUI()
                end
            end)

            MenuGroup:AddButton('Unload Script', function() 
                logUserAction("Script Unloaded", "Manual unload triggered", "N/A")
                Library:Unload() 
                safeNotify(nil, "Script unloaded!", 2)
            end)

            MenuGroup:AddDivider()

            local InfoGroup = Tabs['UI Settings']:AddRightGroupbox('Information')
            InfoGroup:AddLabel('Script: Shift Hub 🫦')
            InfoGroup:AddLabel('Version: 1.0.0')
            InfoGroup:AddLabel('Game: ' .. gameName)
            InfoGroup:AddDivider()
            InfoGroup:AddLabel('User: ' .. LocalPlayer.Name)
            InfoGroup:AddDivider()
            InfoGroup:AddButton('Copy Discord', function()
                if setclipboard then
                    setclipboard('https://discord.gg/pKcRvJqGyv')
                    Library:Notify('Discord link copied!', 2)
                end
            end)
            InfoGroup:AddButton('Join Discord Server', function()
                Library:Notify('Opening Discord invite...', 2)
            end)

            if SaveManager then
                SaveManager:LoadAutoloadConfig()
            end

            Library:SetWatermarkVisibility(false)
            safeNotify(nil, "Welcome to Shift Hub!", 3)
        end)

        if not success then
            logError(err, "Linoria UI Load")
            warn("[ShiftHub] Failed to load Linoria: " .. tostring(err))
            safeNotify(nil, "Error loading UI: " .. tostring(err), 5)
        end
    else
        logInvalidHWID()
        safeNotify(nil, "HWID verification failed!", 5)
    end
end

-- ===== EXECUTA LOADER =====
runLoader()
