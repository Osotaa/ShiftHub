--[[ 
    -------------------------------------------
    ATENÇÃO: CONFIGURAÇÕES DE AUTENTICAÇÃO
    -------------------------------------------
    1. Substitua o valor da variável 'API_BASE_URL' pelo link do seu ngrok.
    2. A variável 'key' deve ser preenchida pelo método de input do seu executor.
]]

local API_BASE_URL = "SEU_LINK_NGROK_AQUI" -- <--- COLOQUE SEU LINK DO NGROK AQUI (Ex: https://patchily-droopiest-herbert.ngrok-free.dev)
local key = nil -- A chave será solicitada pelo prompt abaixo

-- Variáveis do Roblox
local UserInputService = game:GetService("UserInputService")
local TeleportService = game:GetService("TeleportService")
local Player = game.Players.LocalPlayer

-- Gera um HWID único para o usuário, combinando o UserID com o nome.
local robloxId = Player.UserId
local hwid = tostring(robloxId) .. "_" .. Player.Name:gsub("%s+", ""):lower()


-- Função que carrega a GUI (não será mais chamada automaticamente)
function openMainWindow()
    local Rayfield2 = loadstring(game:HttpGet('https://raw.githubusercontent.com/oxotaa/teste/refs/heads/main/source2.lua'))()

    local mainWindow = Rayfield2:CreateWindow({
        Name = "Shift Hub",
        LoadingTitle = "Shift Hub",
        LoadingSubtitle = "Autenticação OK!",
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

-- 1. SOLICITA A CHAVE AO USUÁRIO
-- Nota: 'PromptKey' é uma função comum em exploiters para input de chave. Se não funcionar,
-- você deve usar a função de input fornecida pelo seu executor (Ex: loadstring(game:HttpGet('...')))
key = game:GetService("StarterGui"):GetCore("PromptKey", "Shift Hub - Digite sua Chave")
if not key or key == "" then
    warn("Autenticação cancelada. Chave não fornecida.")
    return
end

-- 2. FUNÇÃO DE VERIFICAÇÃO NA API
local function verifyAuth(userKey, userHwid)
    print("Iniciando verificação na API...")
    local url = string.format("%s/verify?key=%s&hwid=%s", API_BASE_URL, userKey, userHwid)
    
    -- Faz a requisição GET na API (síncrono, aguarda a resposta)
    local success, response = pcall(function()
        return game:HttpGet(url, true)
    end)

    if not success then
        warn("Erro na comunicação com a API: " .. tostring(response))
        return "erro_comunicacao"
    end

    return response
end

-- 3. EXECUTA A VERIFICAÇÃO E DECIDE SE CARREGA A GUI
local authResponse = verifyAuth(key, hwid)

if authResponse == "hwid_valido" or authResponse == "hwid_registrado" then
    print("Autenticação bem-sucedida! Carregando GUI...")
    openMainWindow()
elseif authResponse == "script_key_invalida" then
    warn("A chave fornecida é inválida.")
elseif authResponse == "hwid_diferente" then
    warn("HWID diferente. Sua chave está vinculada a outro dispositivo.")
else
    warn("Falha na autenticação. Resposta da API: " .. authResponse)
end

-- O script termina aqui se a autenticação falhar
