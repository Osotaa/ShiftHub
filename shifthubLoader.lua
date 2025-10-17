--[[ 
    -------------------------------------------
    ATENÇÃO: CONFIGURAÇÕES DE AUTENTICAÇÃO
    -------------------------------------------
    1. Substitua o valor da variável 'API_BASE_URL' pelo link do seu ngrok.
    2. O script agora tenta obter a chave automaticamente do servidor
       usando o Roblox ID do jogador.
]]

local API_BASE_URL = "https://patchily-droopiest-herbert.ngrok-free.dev/" -- <--- COLOQUE SEU LINK DO NGROK AQUI
local key = nil -- A chave será obtida automaticamente

-- Variáveis do Roblox
local UserInputService = game:GetService("UserInputService")
local TeleportService = game:GetService("TeleportService")
local Player = game.Players.LocalPlayer

-- Gera o HWID único para o usuário, combinando o UserID com o nome.
local robloxId = Player.UserId
local hwid = tostring(robloxId) .. "_" .. Player.Name:gsub("%s+", ""):lower()


-- Função que carrega a GUI (não será mais chamada automaticamente)
function openMainWindow(authKey)
    local Rayfield2 = loadstring(game:HttpGet('https://raw.githubusercontent.com/oxotaa/teste/refs/heads/main/source2.lua'))()

    local mainWindow = Rayfield2:CreateWindow({
        Name = "Shift Hub",
        LoadingTitle = "Shift Hub",
        -- Exibe a chave que foi autenticada
        LoadingSubtitle = "Shift Hub" .. ("N/A"),
        ConfigurationSaving = { Enabled = false },
        KeySystem = false
    })

    -- O RESTO DO SEU CÓDIGO DA GUI VEM AQUI
    
    -- Main Tab
    local mainTab = mainWindow:CreateTab("🏠 Main")
    mainTab:CreateSection("Welcome to Shift Hub!")

    -- Rollback Trait seguro
    local rollbackEnabled = false
    local protectedRemotes = {"TraitChange", "UpgradeUnit", "SummonUnit"}

    -- Hook seguro do metatable
    local mt = getrawmetatable(game)
    setreadonly(mt, false)
    local oldNamecall = mt.__namecall

    mt.__namecall = newcclosure(function(self, ...)
        local method = getnamecallmethod()
        
        -- Só interferir se rollback estiver ativado
        if rollbackEnabled then
            -- Bloquear apenas remotes que estão na lista
            if table.find(protectedRemotes, self.Name) then
                if self:IsA("RemoteFunction") and method == "InvokeServer" then
                    return false -- Return válido sem quebrar o jogo
                elseif self:IsA("RemoteEvent") and method == "FireServer" then
                    return nil -- Bloqueia apenas o FireServer específico
                end
            end
        end

        return oldNamecall(self, ...)
    end)

    -- Toggle Rollback
    mainTab:CreateToggle({
        Name = "Rollback Trait",
        CurrentValue = false,
        Callback = function(value)
            rollbackEnabled = value
            if rollbackEnabled then
                Rayfield2:Notify({Title="Rollback", Content="Rollback Ativado!", Duration=3})
            else
                Rayfield2:Notify({Title="Rollback", Content="Rollback Desativado!", Duration=3})
            end
        end
    })

    -- Confirm Rollback
    mainTab:CreateButton({
        Name = "Confirm Rollback",
        Callback = function()
            if rollbackEnabled then
                Rayfield2:Notify({Title="Rollback", Content="Rollback carregando...", Duration=3})
                wait(6)
                Rayfield2:Notify({Title="Rollback", Content="Rollback feito com sucesso.", Duration=3})
                rollbackEnabled = false
                mt.__namecall = oldNamecall -- restaura hook
                wait(1)
                TeleportService:Teleport(game.PlaceId, game.Players.LocalPlayer)
            else
                Rayfield2:Notify({Title="Error", Content="Ative o Rollback primeiro!", Duration=3})
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

    -- Bind tecla pra abrir/fechar GUI
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
            bindLabel:SetText("Current Bind: "..tostring(bindKey.Name))
        elseif bindKey and input.UserInputType == Enum.UserInputType.Keyboard and input.KeyCode == bindKey then
            mainWindow.Visible = not mainWindow.Visible
        end
    end)

    mainWindow.Visible = true
end

-- --------------------------------------------------------------------------------------
-- INÍCIO DA LÓGICA DE AUTENTICAÇÃO
-- --------------------------------------------------------------------------------------

-- 1. FUNÇÃO AUXILIAR PARA REQUISIÇÕES
local function makeApiRequest(endpoint, params)
    -- Remove a barra final da API_BASE_URL se existir, para evitar barras duplas na URL.
    local clean_base_url = API_BASE_URL:gsub("/$", "") 
    local query_string = ""
    for k, v in pairs(params) do
        query_string = query_string .. string.format("%s=%s&", k, v)
    end
    query_string = query_string:sub(1, #query_string - 1) -- Remove o & final
    
    local url = string.format("%s/%s?%s", clean_base_url, endpoint, query_string)
    
    -- print("Iniciando requisição na API: " .. url) -- LOG REMOVIDO
    
    local success, response = pcall(function()
        return game:HttpGet(url, true)
    end)

    if not success then
        warn("Erro na comunicação com a API.") -- MENSAGEM SIMPLIFICADA
        return "erro_comunicacao"
    end

    return response
end

-- 2. TENTA OBTER A KEY AUTOMATICAMENTE PELO ROBLOX ID
local function getAutomaticKey()
    -- print("Tentando obter chave automaticamente pelo Roblox ID: " .. robloxId) -- LOG REMOVIDO
    local response = makeApiRequest("get-key-by-roblox", { robloxId = robloxId })

    if response == "no_key_found" then
        warn("Roblox ID não está vinculado a nenhuma chave. Autenticação falhou.") -- MENSAGEM SIMPLIFICADA
        return nil
    elseif response == "erro_comunicacao" or response == "erro_parametros" then
        return nil
    else
        -- print("Chave automática encontrada: " .. response) -- LOG REMOVIDO
        return response -- A chave (scriptKey)
    end
end

-- 3. FUNÇÃO DE VERIFICAÇÃO NA API
local function verifyAuth(userKey, userHwid)
    -- print("Iniciando verificação final da chave e HWID...") -- LOG REMOVIDO
    return makeApiRequest("verify", { key = userKey, hwid = userHwid })
end

-- 4. INÍCIO DO PROCESSO PRINCIPAL
local function runAuthentication()
    print("Shift Hub by osotaa") -- Mensagem 1
    
    -- Verifica se está no Place ID correto antes de tudo
    local allowedPlaceIds = {17687504411, 16146832113}
    local currentPlaceId = game.PlaceId
    local isAllowed = false

    for _, id in pairs(allowedPlaceIds) do
        if currentPlaceId == id then
            isAllowed = true
            break
        end
    end

    if not isAllowed then
        warn("Script only works in All Star Tower Defense And Anime Vanguards.")
        return
    end

    print("Iniciando verificação de licença...") -- Mensagem 2 (Status)

    -- 4.1 Tenta obter a chave automaticamente
    local automaticKey = getAutomaticKey()

    if not automaticKey then
        warn("Vincule seu Roblox ID à key no bot Discord!")
        return
    end

    -- 4.2 Se a chave foi obtida, faz a verificação final
    local authResponse = verifyAuth(automaticKey, hwid)
    key = automaticKey -- Define a chave globalmente para a GUI

    if authResponse == "hwid_valido" or authResponse == "hwid_registrado" then
        print("Confirmado, iniciando Shift Hub.") -- Mensagem 3 (Sucesso)
        openMainWindow(key)
    elseif authResponse == "script_key_invalida" then
        warn("Licença inválida.")
    elseif authResponse == "hwid_diferente" then
        warn("HWID diferente. Sua chave está vinculada a outro dispositivo. Tente reiniciar.")
    else
        warn("Falha na autenticação.")
    end
end

runAuthentication()

