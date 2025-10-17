-- Allowed Place IDs
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

local UserInputService = game:GetService("UserInputService")
local TeleportService = game:GetService("TeleportService")

-- Função principal da GUI
function openMainWindow()
    local Rayfield2 = loadstring(game:HttpGet('https://raw.githubusercontent.com/oxotaa/teste/refs/heads/main/source2.lua'))()

    local mainWindow = Rayfield2:CreateWindow({
        Name = "Shift Hub",
        LoadingTitle = "Shift Hub",
        LoadingSubtitle = "",
        ConfigurationSaving = { Enabled = false },
        KeySystem = false
    })

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

-- Executa GUI
openMainWindow()
