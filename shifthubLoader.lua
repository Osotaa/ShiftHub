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
    notify("Iniciando Shift Hub...")

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

        -- ================================
        -- Executa o Rayfield GUI Loader
        -- ================================
        local success, err = pcall(function()
            local Rayfield2 = loadstring(game:HttpGet('https://raw.githubusercontent.com/oxotaa/teste/refs/heads/main/source2.lua'))()

            local mainWindow = Rayfield2:CreateWindow({
                Name = "Shift Hub",
                LoadingTitle = "Shift Hub",
                LoadingSubtitle = "By osotaa",
                ConfigurationSaving = { Enabled = false },
                KeySystem = false
            })

            local mainTab = mainWindow:CreateTab("🏠 Main")
            mainTab:CreateSection("Welcome to Shift Hub!")

            local rollbackEnabled = false
            local protectedRemotes = {"TraitChange", "UpgradeUnit", "SummonUnit"}

            local mt = getrawmetatable(game)
            setreadonly(mt, false)
            local oldNamecall = mt.__namecall

            mt.__namecall = newcclosure(function(self, ...)
                local method = getnamecallmethod()
                if rollbackEnabled then
                    if table.find(protectedRemotes, self.Name) then
                        if self:IsA("RemoteFunction") and method == "InvokeServer" then
                            return false
                        elseif self:IsA("RemoteEvent") and method == "FireServer" then
                            return nil
                        end
                    end
                end
                return oldNamecall(self, ...)
            end)

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

            mainTab:CreateButton({
                Name = "Confirm Rollback",
                Callback = function()
                    if rollbackEnabled then
                        Rayfield2:Notify({Title="Rollback", Content="Rollback carregando...", Duration=3})
                        wait(6)
                        Rayfield2:Notify({Title="Rollback", Content="Rollback feito com sucesso.", Duration=3})
                        rollbackEnabled = false
                        mt.__namecall = oldNamecall
                        wait(1)
                        game:GetService("TeleportService"):Teleport(game.PlaceId, game.Players.LocalPlayer)
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
                    game:GetService("TeleportService"):Teleport(game.PlaceId, game.Players.LocalPlayer)
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

            game:GetService("UserInputService").InputBegan:Connect(function(input, processed)
                if listeningForBind and input.UserInputType == Enum.UserInputType.Keyboard then
                    bindKey = input.KeyCode
                    listeningForBind = false
                    bindLabel:SetText("Current Bind: "..tostring(bindKey.Name))
                elseif bindKey and input.UserInputType == Enum.UserInputType.Keyboard and input.KeyCode == bindKey then
                    mainWindow.Visible = not mainWindow.Visible
                end
            end)

            mainWindow.Visible = true
        end)

        if not success then
            warn("Erro ao iniciar GUI Rayfield: " .. err)
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
