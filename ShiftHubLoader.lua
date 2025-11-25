local API_BASE_URL = "http://51.75.118.149:20029/"
local key = nil

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local TeleportService = game:GetService("TeleportService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local robloxId = (LocalPlayer and LocalPlayer.UserId) or 0
local hwid = tostring(robloxId) .. "_" .. ((LocalPlayer and LocalPlayer.Name) or "unknown"):gsub("%s+", ""):lower()

-- ===== SISTEMA DE LOGS DISCORD (COM PROTEÇÃO) =====
local DISCORD_WEBHOOKS = {
    INFO = "https://discord.com/api/webhooks/1442997875637489845/Y2uoehEebrP6vJaMnFQqbg0Z6ax5VW6GVbfPlygGRRJ2n4tfWj9ylzFT-bQkOpye5cOo",
    WARNING = "https://discord.com/api/webhooks/1442998043170308147/UfK5_W3AVzsH25vvKPCcL_VMns3Yfh3tMoiddS_YPPiNpQh4M210gx5C1L3HWeoYC9iA", 
    ERROR = "https://discord.com/api/webhooks/1442998301908664380/LBiVVL37uVTsauiV6BfmS2v6WvzkltvvEqJVSev0zIFFbOtciSGLTHp6xGuCO2II0CeM",
    SUCCESS = "https://discord.com/api/webhooks/1442998591873613975/JMDiaBzPOsO1xbI0iKUegZuNPSUBYlOm4jOg7fnu6slVRzYSrgurHafi9sJAH_yz1gwD",
    PERFORMANCE = "https://discord.com/api/webhooks/1443010364215398551/rD8_i5J6jfH947sCSirhjQxRQ09x6222792mB1D2ezR0f_GR8Wm4jbKtTG7__H2as_nC"
}

-- Cache para evitar spam
local lastLogTimes = {}
local LOG_COOLDOWN = 2 -- segundos

-- ===== SISTEMA DE MONITORAMENTO DE PERFORMANCE =====
local PerformanceMonitor = {
    metrics = {
        startTime = os.time(),
        errorCount = 0,
        actionCount = 0,
        memoryUsage = {},
        fpsHistory = {},
        apiResponseTimes = {},
        lastGCCount = 0
    },
    thresholds = {
        highMemory = 300, -- MB
        lowFPS = 20,
        highPing = 500, -- ms
        maxErrorsPerMinute = 5
    }
}

-- ===== DETECÇÃO AUTOMÁTICA DE ERROS =====
local function setupErrorMonitoring()
    local originalTraceback = debug.traceback
    
    -- Monitor global de erros
    local function globalErrorHandler(err)
        local traceback = originalTraceback(err, 2)
        PerformanceMonitor.metrics.errorCount += 1
        
        -- Log automático do erro
        pcall(function()
            local systemInfo = collectSystemInfo()
            
            local extraFields = {
                {
                    name = "❌ Erro",
                    value = "```" .. tostring(err) .. "```",
                    inline = false
                },
                {
                    name = "📋 Stack Trace",
                    value = "```" .. traceback .. "```",
                    inline = false
                },
                {
                    name = "📊 Contador de Erros",
                    value = "`" .. PerformanceMonitor.metrics.errorCount .. " erros nesta sessão`",
                    inline = true
                }
            }
            
            sendDiscordLog("PERFORMANCE", "💥 Erro Detectado Automaticamente", 
                "**Sistema detectou um erro automaticamente**\n⚠️ Não requer ação do usuário", extraFields)
        end)
        
        return traceback
    end

    -- Substitui a função de erro global
    debug.traceback = globalErrorHandler
    
    -- Monitor de memory leaks
    task.spawn(function()
        local lastMemory = game:GetService("Stats"):GetMemoryUsageMbForTag(Enum.DeveloperMemoryType.Script)
        while task.wait(30) do
            local currentMemory = game:GetService("Stats"):GetMemoryUsageMbForTag(Enum.DeveloperMemoryType.Script)
            table.insert(PerformanceMonitor.metrics.memoryUsage, currentMemory)
            
            -- Detecta memory leak
            if #PerformanceMonitor.metrics.memoryUsage > 10 then
                local memoryIncrease = currentMemory - PerformanceMonitor.metrics.memoryUsage[1]
                if memoryIncrease > 50 then -- 50MB increase in 5 minutes
                    pcall(function()
                        sendDiscordLog("PERFORMANCE", "🚨 Possível Memory Leak Detectado", 
                            string.format("**Aumento de memória detectado:** +%.1fMB em 5 minutos\n🔄 Recomendado verificar vazamentos", memoryIncrease))
                    end)
                end
                
                -- Mantém apenas últimas 10 medições
                if #PerformanceMonitor.metrics.memoryUsage > 10 then
                    table.remove(PerformanceMonitor.metrics.memoryUsage, 1)
                end
            end
            
            lastMemory = currentMemory
        end
    end)
    
    -- Monitor de performance geral
    task.spawn(function()
        while task.wait(60) do -- Report a cada 1 minuto
            local systemInfo = collectSystemInfo()
            local currentFPS = systemInfo.fps
            local currentPing = systemInfo.ping
            local currentMemory = game:GetService("Stats"):GetMemoryUsageMbForTag(Enum.DeveloperMemoryType.Script)
            
            table.insert(PerformanceMonitor.metrics.fpsHistory, currentFPS)
            if #PerformanceMonitor.metrics.fpsHistory > 10 then
                table.remove(PerformanceMonitor.metrics.fpsHistory, 1)
            end
            
            -- Verifica thresholds
            local warnings = {}
            if currentMemory > PerformanceMonitor.thresholds.highMemory then
                table.insert(warnings, string.format("Alta memória: %.1fMB", currentMemory))
            end
            if currentFPS < PerformanceMonitor.thresholds.lowFPS then
                table.insert(warnings, string.format("FPS baixo: %d", currentFPS))
            end
            if currentPing > PerformanceMonitor.thresholds.highPing then
                table.insert(warnings, string.format("Ping alto: %dms", currentPing))
            end
            
            if #warnings > 0 then
                pcall(function()
                    local extraFields = {
                        {
                            name = "📊 Métricas Atuais",
                            value = string.format("FPS: `%d`\nPing: `%dms`\nMemória: `%.1fMB`", 
                                currentFPS, currentPing, currentMemory),
                            inline = true
                        },
                        {
                            name = "⚠️ Alertas",
                            value = "`" .. table.concat(warnings, "\n") .. "`",
                            inline = true
                        },
                        {
                            name = "📈 Estatísticas da Sessão",
                            value = string.format("Erros: `%d`\nAções: `%d`\nTempo: `%dm`", 
                                PerformanceMonitor.metrics.errorCount, 
                                PerformanceMonitor.metrics.actionCount,
                                math.floor((os.time() - PerformanceMonitor.metrics.startTime) / 60)),
                            inline = true
                        }
                    }
                    
                    sendDiscordLog("PERFORMANCE", "📈 Relatório de Performance", 
                        "**Monitoramento automático do sistema**\n🔍 Métricas coletadas a cada 1 minuto", extraFields)
                end)
            end
        end
    end)
end

-- ===== DETECÇÃO DE ADMIN =====
local function setupAdminDetection()
    local function checkForAdmins()
        local admins = {}
        local adminKeywords = {
            "admin", "mod", "staff", "owner", "developer", "moderator",
            "game", "owner", "builder", "tester", "roblox", "official"
        }
        
        for _, player in pairs(game:GetService("Players"):GetPlayers()) do
            local playerName = player.Name:lower()
            local displayName = player.DisplayName:lower()
            
            for _, keyword in pairs(adminKeywords) do
                if playerName:find(keyword) or displayName:find(keyword) then
                    table.insert(admins, {
                        name = player.Name,
                        displayName = player.DisplayName,
                        userId = player.UserId,
                        reason = "Nome contém: " .. keyword
                    })
                    break
                end
            end
            
            -- Verifica se tem badges de staff (opcional)
            pcall(function()
                if player:GetRankInGroup(1200769) > 100 then -- Grupo Roblox
                    table.insert(admins, {
                        name = player.Name,
                        displayName = player.DisplayName,
                        userId = player.UserId,
                        reason = "Staff do Roblox detectado"
                    })
                end
            end)
        end
        
        return admins
    end
    
    -- Verifica admins periodicamente
    task.spawn(function()
        while task.wait(120) do -- A cada 2 minutos
            local admins = checkForAdmins()
            if #admins > 0 then
                pcall(function()
                    local adminList = ""
                    for i, admin in ipairs(admins) do
                        adminList = adminList .. string.format("**%s** (%s) - %s\n", 
                            admin.name, admin.displayName, admin.reason)
                        if i >= 5 then break end -- Limita a 5 admins no log
                    end
                    
                    local extraFields = {
                        {
                            name = "👮 Admins Detectados",
                            value = adminList,
                            inline = false
                        },
                        {
                            name = "📊 Total de Players",
                            value = "`" .. #game:GetService("Players"):GetPlayers() .. " players no servidor`",
                            inline = true
                        }
                    }
                    
                    sendDiscordLog("WARNING", "👀 Staff Detectado no Servidor", 
                        "**Sistema detectou possíveis staff members**\n🔒 Script continua funcionando normalmente", extraFields)
                end)
            end
        end
    end)
end

-- ===== STATUS DA API =====
local function setupAPIMonitoring()
    local function checkAPIStatus()
        local startTime = os.clock()
        local success, response = pcall(function()
            return game:HttpGet(API_BASE_URL .. "status", true)
        end)
        local responseTime = math.floor((os.clock() - startTime) * 1000) -- ms
        
        table.insert(PerformanceMonitor.metrics.apiResponseTimes, responseTime)
        if #PerformanceMonitor.metrics.apiResponseTimes > 5 then
            table.remove(PerformanceMonitor.metrics.apiResponseTimes, 1)
        end
        
        if not success then
            pcall(function()
                sendDiscordLog("PERFORMANCE", "🔴 API Offline", 
                    string.format("**Falha na conexão com a API**\n⏱️ Última tentativa: %dms\n❌ Erro: %s", 
                        responseTime, tostring(response)))
            end)
            return false
        end
        
        -- Se response time estiver muito alto
        if responseTime > 1000 then
            pcall(function()
                sendDiscordLog("PERFORMANCE", "🐌 API Lenta", 
                    string.format("**API respondendo lentamente**\n⏱️ Response time: %dms\n⚠️ Pode afetar performance", responseTime))
            end)
        end
        
        return true
    end
    
    -- Verifica status da API periodicamente
    task.spawn(function()
        task.wait(30) -- Espera inicial
        while task.wait(60) do -- A cada 1 minuto
            checkAPIStatus()
        end
    end)
    
    return {
        checkStatus = checkAPIStatus,
        getAvgResponseTime = function()
            if #PerformanceMonitor.metrics.apiResponseTimes == 0 then return 0 end
            local sum = 0
            for _, time in pairs(PerformanceMonitor.metrics.apiResponseTimes) do
                sum += time
            end
            return math.floor(sum / #PerformanceMonitor.metrics.apiResponseTimes)
        end
    }
end

-- ===== IDENTIFICAÇÃO DE EXECUTOR SIMPLIFICADA =====
local function identifyExecutor()
    local success, result = pcall(function()
        -- Detecta o executor baseado em funções disponíveis
        if getexecutorname then
            return getexecutorname()
        elseif syn and syn.request then
            return "Synapse X"
        elseif KRNL_LOADED then
            return "KRNL"
        elseif fluxus then
            return "Fluxus"
        elseif identifyexecutor then
            return identifyexecutor()
        elseif get_hui_animation then
            return "ScriptWare"
        else
            return "Executor Desconhecido"
        end
    end)
    
    return success and result or "Executor Não Identificado"
end

-- ===== FUNÇÃO DE COLETA DE INFORMAÇÕES SEGURA =====
local function collectSystemInfo()
    local success, result = pcall(function()
        local player = game.Players.LocalPlayer
        local executor = identifyExecutor()
        
        return {
            -- Usuário
            username = player.Name,
            displayName = player.DisplayName,
            userId = player.UserId,
            accountAge = player.AccountAge,
            membership = player.MembershipType.Name,
            
            -- Jogo
            gameName = game:GetService("MarketplaceService"):GetProductInfo(game.PlaceId).Name,
            placeId = game.PlaceId,
            jobId = game.JobId,
            
            -- Executor
            executor = executor,
            timestamp = os.date("%d/%m/%Y %H:%M:%S"),
            hwid = hwid,
            
            -- Performance
            fps = math.floor(1/wait()),
            ping = game:GetService("Stats").Network.ServerStatsItem["Data Ping"]:GetValue(),
            platform = game:GetService("UserInputService"):GetPlatform().Name,
            
            -- Informações adicionais
            serverPlayers = #game.Players:GetPlayers(),
            serverMaxPlayers = game.Players.MaxPlayers,
        }
    end)
    
    return success and result or {
        username = "Erro",
        displayName = "Erro",
        userId = 0,
        accountAge = 0,
        membership = "Erro",
        gameName = "Erro",
        placeId = 0,
        jobId = "Erro",
        executor = "Erro",
        timestamp = os.date("%d/%m/%Y %H:%M:%S"),
        hwid = hwid,
        fps = 0,
        ping = 0,
        platform = "Erro",
        serverPlayers = 0,
        serverMaxPlayers = 0
    }
end

-- ===== SISTEMA DE LOGS SEGURO =====
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
        SUCCESS = 65280,     -- Verde
        PERFORMANCE = 10181046 -- Roxo
    }
    
    local embed = {
        title = title,
        description = description,
        color = colors[webhookType] or 3447003,
        fields = {
            {
                name = "👤 Usuário",
                value = string.format("`%s`\nID: `%d`", systemInfo.username, systemInfo.userId),
                inline = true
            },
            {
                name = "🔧 Executor",
                value = "`" .. systemInfo.executor .. "`",
                inline = true
            },
            {
                name = "🎮 Jogo",
                value = string.format("`%s`\nPlace: `%d`", systemInfo.gameName, systemInfo.placeId),
                inline = true
            },
            {
                name = "📊 Account Info",
                value = string.format("Age: `%d dias`\nMembership: `%s`", systemInfo.accountAge, systemInfo.membership),
                inline = true
            },
            {
                name = "🕒 Horário",
                value = "`" .. systemInfo.timestamp .. "`",
                inline = true
            },
            {
                name = "🔑 HWID",
                value = "`" .. systemInfo.hwid .. "`",
                inline = true
            }
        },
        footer = {
            text = "Shift Hub Logger"
        },
        timestamp = os.date("!%Y-%m-%dT%H:%M:%SZ")
    }
    
    -- Adiciona campos extras se fornecidos
    if extraFields then
        for _, field in ipairs(extraFields) do
            table.insert(embed.fields, field)
        end
    end
    
    -- Envia para Discord de forma segura
    local success, result = pcall(function()
        local headers = {
            ["Content-Type"] = "application/json"
        }
        
        local data = {
            embeds = {embed}
        }
        
        local jsonData = game:GetService("HttpService"):JSONEncode(data)
        
        -- Tenta diferentes métodos de request
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
            -- Fallback seguro
            return {Success = true}
        end
    end)
    
    return success
end

-- ===== FUNÇÕES DE LOG SIMPLIFICADAS =====
local function logScriptStart()
    local success = pcall(function()
        sendDiscordLog("SUCCESS", "🚀 Script Iniciado", "Shift Hub foi executado com sucesso!")
    end)
    if not success then
        warn("[ShiftHub] Erro ao enviar log de início")
    end
end

local function logAuthSuccess()
    local success = pcall(function()
        sendDiscordLog("SUCCESS", "🔐 Autenticação Bem-Sucedida", "Usuário autenticado com sucesso no Shift Hub")
    end)
    if not success then
        warn("[ShiftHub] Erro ao enviar log de autenticação")
    end
end

local function logUserAction(action, details)
    PerformanceMonitor.metrics.actionCount += 1
    
    local success = pcall(function()
        local extraFields = {
            {
                name = "🎯 Ação",
                value = "`" .. action .. "`",
                inline = true
            },
            {
                name = "📝 Detalhes", 
                value = "`" .. (details or "Nenhum") .. "`",
                inline = true
            }
        }
        
        sendDiscordLog("INFO", "📋 Ação do Usuário", "Nova ação registrada no sistema", extraFields)
    end)
    if not success then
        warn("[ShiftHub] Erro ao enviar log de ação")
    end
end

-- FUNÇÃO NOVA PARA KEY NÃO VINCULADA
local function logNoKeyLinked()
    local success = pcall(function()
        local systemInfo = collectSystemInfo()
        
        local extraFields = {
            {
                name = "🚫 Status da Key",
                value = "`NÃO VINCULADA`",
                inline = true
            },
            {
                name = "🔍 Roblox ID",
                value = "`" .. tostring(robloxId) .. "`",
                inline = true
            },
            {
                name = "⚠️ Ação Necessária",
                value = "`Vincular key no site`",
                inline = true
            }
        }
        
        sendDiscordLog("ERROR", "🔑 Key Não Vinculada", 
            "**Usuário tentou executar sem key vinculada!**\n❌ Acesso negado pelo sistema", extraFields)
    end)
    if not success then
        warn("[ShiftHub] Erro ao enviar log de key não vinculada")
    end
end

local function logInvalidHWID()
    local success = pcall(function()
        sendDiscordLog("ERROR", "🚫 Tentativa de Acesso Bloqueada", "Tentativa de acesso com HWID inválido ou não autorizado")
    end)
    if not success then
        warn("[ShiftHub] Erro ao enviar log de HWID inválido")
    end
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
    -- INICIALIZA SISTEMAS DE MONITORAMENTO
    pcall(setupErrorMonitoring)
    pcall(setupAdminDetection)
    pcall(setupAPIMonitoring)
    
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
        -- LOG: Key não vinculada
        pcall(logNoKeyLinked)
        safeNotify(nil, "Authentication failed!", 5)
        return
    end

    local authResponse = verifyAuth(automaticKey, hwid)
    key = automaticKey

    if authResponse == "hwid_valido" or authResponse == "hwid_registrado" then
        _G.ShiftHub_Validated = true
        _G.GameName = gameName
        
        -- LOG: Script iniciado com sucesso (PROTEGIDO)
        pcall(logScriptStart)
        
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
            
            -- LOG: Autenticação bem-sucedida (PROTEGIDO)
            pcall(logAuthSuccess)
            
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
                    pcall(logUserAction, "Rollback Type Selected", "Type: " .. Value)
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
                    pcall(logUserAction, "Rollback Method Selected", "Method: " .. cleaned)
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
                        pcall(logUserAction, "Rollback Enabled", "Type: " .. (type or "None"))
                        safeNotify(nil, "Rollback Enabled! Type: " .. (type or "None"), 2)
                    else
                        pcall(logUserAction, "Rollback Disabled", "Type: " .. (type or "None"))
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
                        pcall(logUserAction, "Rollback Confirmed", "Executing rollback - Type: " .. type)
                        safeNotify(nil, "Initiating rollback...", 2)
                        task.wait(2)
                        safeNotify(nil, "Rollback completed successfully!", 3)
                        rollbackSystem.setEnabled(false)
                        task.wait(1)
                        TeleportService:Teleport(game.PlaceId, LocalPlayer)
                    else
                        pcall(logUserAction, "Rollback Failed", "No type selected or disabled")
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
                    pcall(logUserAction, "Rejoin Server", "Manual rejoin triggered")
                    safeNotify(nil, "Rejoining server...", 2)
                    task.wait(1)
                    TeleportService:Teleport(game.PlaceId, LocalPlayer)
                end,
                Tooltip = 'Rejoin the current server'
            })

            RightGroupbox:AddButton({
                Text = 'Server Hop',
                Func = function()
                    pcall(logUserAction, "Server Hop", "Manual server hop triggered")
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
                    pcall(logUserAction, "Infinite Range Toggle", "Status: " .. tostring(Value))
                    safeNotify(nil, Value and "Infinite Range ON!" or "Infinite Range OFF!", 1)
                end
            })
            
            CombatBox:AddToggle('NoCooldown', {
                Text = 'No Cooldown (Patched)',
                Default = false,
                Tooltip = 'Remove ability cooldowns',
                Callback = function(Value)
                    pcall(logUserAction, "No Cooldown Toggle", "Status: " .. tostring(Value))
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
                    pcall(logUserAction, "Damage Multiplier Changed", "New value: " .. tostring(Value))
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
                    pcall(logUserAction, "Speed Hack Toggle", "Status: " .. tostring(Value))
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
                    pcall(logUserAction, "Walk Speed Changed", "New speed: " .. tostring(Value))
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
                pcall(logUserAction, "Script Unloaded", "Manual unload triggered")
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
            warn("[ShiftHub] Failed to load Linoria: " .. tostring(err))
            safeNotify(nil, "Error loading UI: " .. tostring(err), 5)
        end
    else
        pcall(logInvalidHWID)
        safeNotify(nil, "HWID verification failed!", 5)
    end
end

-- ===== EXECUTA LOADER =====
runLoader()
