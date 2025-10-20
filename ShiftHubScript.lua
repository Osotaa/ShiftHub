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
local Rayfield = loadstring(game:HttpGet("https://raw.githubusercontent.com/Osotaa/teste/refs/heads/main/source2.lua"))()

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

-- ===============================
-- Rollback System (com seletor + animação)
-- ===============================

local rollbackEnabled = false
local rollbackType = "Trait" -- padrão inicial
local protectedRemotes = {
    Trait = {"TraitChange", "UpgradeUnit"},
    Summon = {"SummonUnit"}
}

-- Hook de rollback
local mt = getrawmetatable(game)
setreadonly(mt, false)
local oldNamecall = mt.__namecall
mt.__namecall = newcclosure(function(self, ...)
    local method = getnamecallmethod()
    if rollbackEnabled then
        local list = protectedRemotes[rollbackType]
        if list and table.find(list, self.Name) then
            if self:IsA("RemoteFunction") and method == "InvokeServer" then
                return false
            elseif self:IsA("RemoteEvent") and method == "FireServer" then
                return nil
            end
        end
    end
    return oldNamecall(self, ...)
end)

mainTab:CreateSection("Rollback System")

-- Dropdown com animação de fade-in
local rollbackDropdown = mainTab:CreateDropdown({
    Name = "Tipo de Rollback",
    Options = {"Trait", "Summon"},
    CurrentOption = "Trait",
    Callback = function(option)
        rollbackType = option
        Rayfield:Notify({
            Title = "Rollback Type",
            Content = "Tipo de rollback definido para: " .. option,
            Duration = 3
        })
    end
})

-- Pequeno delay para garantir que o dropdown foi criado
task.wait(0.5)

-- Procura o frame do dropdown (parte visual)
local dropdownFrame
pcall(function()
    -- tenta localizar o elemento no PlayerGui
    for _, gui in pairs(LocalPlayer:WaitForChild("PlayerGui"):GetDescendants()) do
        if gui:IsA("Frame") and gui.Name:lower():find("dropdown") then
            dropdownFrame = gui
        end
    end
end)

-- Adiciona efeito de fade-in quando abrir o modal/dropdown
if dropdownFrame then
    dropdownFrame.DescendantAdded:Connect(function(obj)
        if obj:IsA("Frame") and obj.Name:lower():find("options") then
            obj.BackgroundTransparency = 1
            for _, child in pairs(obj:GetDescendants()) do
                if child:IsA("TextLabel") or child:IsA("TextButton") or child:IsA("Frame") then
                    child.BackgroundTransparency = 1
                    if child.TextTransparency ~= nil then
                        child.TextTransparency = 1
                    end
                end
            end

            -- anima fade-in do fundo
            TweenService:Create(obj, TweenInfo.new(0.3, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {
                BackgroundTransparency = 0
            }):Play()

            -- anima os filhos (texto e botões)
            task.wait(0.05)
            for _, child in pairs(obj:GetDescendants()) do
                if child:IsA("TextLabel") or child:IsA("TextButton") then
                    TweenService:Create(child, TweenInfo.new(0.3), {TextTransparency = 0}):Play()
                elseif child:IsA("Frame") then
                    TweenService:Create(child, TweenInfo.new(0.3), {BackgroundTransparency = 0}):Play()
                end
            end
        end
    end)
end

-- Toggle para ativar/desativar rollback
mainTab:CreateToggle({
    Name = "Rollback",
    CurrentValue = false,
    Callback = function(value)
        rollbackEnabled = value
        if rollbackEnabled then
            Rayfield:Notify({
                Title = "Rollback",
                Content = "Rollback (" .. rollbackType .. ") ativado!",
                Duration = 3
            })
        else
            Rayfield:Notify({
                Title = "Rollback",
                Content = "Rollback desativado!",
                Duration = 3
            })
        end
    end
})

-- Botão para confirmar rollback
mainTab:CreateButton({
    Name = "Confirm Rollback",
    Callback = function()
        if rollbackEnabled then
            Rayfield:Notify({
                Title="Rollback",
                Content="Rollback (" .. rollbackType .. ") carregando...",
                Duration=3
            })
            wait(6)
            Rayfield:Notify({
                Title="Rollback",
                Content="Rollback (" .. rollbackType .. ") feito com sucesso.",
                Duration=3
            })
            rollbackEnabled = false
            mt.__namecall = oldNamecall -- restaura hook
            wait(1)
            TeleportService:Teleport(game.PlaceId, LocalPlayer)
        else
            Rayfield:Notify({
                Title="Erro",
                Content="Ative o rollback primeiro!",
                Duration=3
            })
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
