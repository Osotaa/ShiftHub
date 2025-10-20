-- ===============================
-- ShiftHub Script Principal (Rayfield)
-- ===============================
if not _G.ShiftHub_Validated then
    error("Erro: Acesso não autorizado. Execute o Loader primeiro.")
    return
end

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local TeleportService = game:GetService("TeleportService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

local gameName = _G.GameName

-- ===============================
-- Carrega Rayfield
-- ===============================
local Rayfield = loadstring(game:HttpGet("https://raw.githubusercontent.com/oxotaa/teste/refs/heads/main/source2.lua"))()

-- ===============================
-- Cria a janela principal
-- ===============================
local mainWindow = Rayfield:CreateWindow({
    Name = "Shift Hub",
    LoadingTitle = "Shift Hub",
    LoadingSubtitle = "By osotaa",
    ConfigurationSaving = { Enabled = false },
    KeySystem = false
})

-- ===============================
-- Aba Main
-- ===============================
local mainTab = mainWindow:CreateTab("🏠 Main")
mainTab:CreateSection("Bem-vindo ao Shift Hub!")

local rollbackEnabled = false
local protectedRemotes = {"TraitChange", "UpgradeUnit", "SummonUnit"}

-- Hook de rollback
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

-- Toggle Rollback
mainTab:CreateToggle({
    Name = "Rollback Trait",
    CurrentValue = false,
    Callback = function(value)
        rollbackEnabled = value
        if rollbackEnabled then
            Rayfield:Notify({Title="Rollback", Content="Rollback Ativado!", Duration=3})
        else
            Rayfield:Notify({Title="Rollback", Content="Rollback Desativado!", Duration=3})
        end
    end
})

-- Confirm Rollback
mainTab:CreateButton({
    Name = "Confirm Rollback",
    Callback = function()
        if rollbackEnabled then
            Rayfield:Notify({Title="Rollback", Content="Rollback carregando...", Duration=3})
            wait(6)
            Rayfield:Notify({Title="Rollback", Content="Rollback feito com sucesso.", Duration=3})
            rollbackEnabled = false
            mt.__namecall = oldNamecall -- restaura hook
            wait(1)
            TeleportService:Teleport(game.PlaceId, LocalPlayer)
        else
            Rayfield:Notify({Title="Error", Content="Ative o Rollback primeiro!", Duration=3})
        end
    end
})

-- ===============================
-- Aba Config
-- ===============================
local configTab = mainWindow:CreateTab("⚙️ Config")
configTab:CreateSection("Configurações")

-- Rejoin
configTab:CreateButton({
    Name = "Rejoin",
    Callback = function()
        TeleportService:Teleport(game.PlaceId, LocalPlayer)
    end
})

-- Bind configurável
local bindKey = nil
local listeningForBind = false
local bindLabel = configTab:CreateLabel({ Name = "Current Bind: None" })

configTab:CreateButton({
    Name = "Escolher bind para abrir/fechar GUI",
    Callback = function()
        listeningForBind = true
        bindLabel:SetText("Pressione qualquer tecla...")
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

-- Janela visível por padrão
mainWindow.Visible = true

Rayfield:Notify({Title="Shift Hub", Content="Shift Hub iniciado em "..gameName, Duration=3})
