-- 1. VERIFICAÇÃO DE VALIDAÇÃO
if not _G.ShiftHub_Validated then
    error("Erro: Acesso não autorizado. Execute o Loader para iniciar.")
    return
end

-- 2. SEÇÃO DE CÓDIGO DO HUB/GUI
print("[ShiftHub] Script principal carregado com sucesso. Iniciando GUI...")

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local TeleportService = game:GetService("TeleportService")
local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

-- Limite de jogos permitidos
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

-- Cria o ScreenGui
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "ShiftHubGUI"
ScreenGui.Parent = PlayerGui
ScreenGui.ResetOnSpawn = false

-- Cria o Frame principal
local Frame = Instance.new("Frame")
Frame.Name = "MainFrame"
Frame.Size = UDim2.new(0, 300, 0, 200)
Frame.Position = UDim2.new(0.5, -150, 0.5, -100)
Frame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
Frame.BackgroundTransparency = 0.3
Frame.Draggable = true
Frame.Active = true
Frame.Parent = ScreenGui

-- Título do GUI
local TitleLabel = Instance.new("TextLabel")
TitleLabel.Name = "Title"
TitleLabel.Size = UDim2.new(1, 0, 0, 30)
TitleLabel.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
TitleLabel.Text = "Shift Hub"
TitleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
TitleLabel.Font = Enum.Font.Gotham
TitleLabel.TextSize = 18
TitleLabel.Parent = Frame

-- Botão Fechar
local CloseButton = Instance.new("TextButton")
CloseButton.Name = "CloseButton"
CloseButton.Size = UDim2.new(0, 30, 0, 30)
CloseButton.Position = UDim2.new(1, -30, 0, 0)
CloseButton.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
CloseButton.Text = "X"
CloseButton.TextColor3 = Color3.fromRGB(255, 255, 255)
CloseButton.Font = Enum.Font.SourceSans
CloseButton.TextSize = 20
CloseButton.Parent = Frame

CloseButton.MouseButton1Click:Connect(function()
    ScreenGui.Enabled = false
end)

-- Botão Minimizar
local MinimizeButton = Instance.new("TextButton")
MinimizeButton.Name = "MinimizeButton"
MinimizeButton.Size = UDim2.new(0, 30, 0, 30)
MinimizeButton.Position = UDim2.new(1, -60, 0, 0)
MinimizeButton.BackgroundColor3 = Color3.fromRGB(50, 200, 50)
MinimizeButton.Text = "-"
MinimizeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
MinimizeButton.Font = Enum.Font.SourceSans
MinimizeButton.TextSize = 20
MinimizeButton.Parent = Frame

MinimizeButton.MouseButton1Click:Connect(function()
    Frame.Visible = false
end)

-- Tecla M para mostrar/ocultar GUI
UserInputService.InputBegan:Connect(function(input, processed)
    if not processed and input.KeyCode == Enum.KeyCode.M then
        Frame.Visible = not Frame.Visible
    end
end)

-- Conteúdo da aba "Game"
local GameFrame = Instance.new("Frame")
GameFrame.Name = "GameContent"
GameFrame.Size = UDim2.new(1, 0, 1, -30)
GameFrame.Position = UDim2.new(0, 0, 0, 30)
GameFrame.BackgroundTransparency = 1
GameFrame.Parent = Frame

-- Função de notificação
local function showNotification(message)
    local notification = Instance.new("TextLabel")
    notification.Size = UDim2.new(0, 300, 0, 50)
    notification.Position = UDim2.new(0.5, -150, 0.5, -25)
    notification.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    notification.BackgroundTransparency = 0.5
    notification.Text = message
    notification.TextColor3 = Color3.fromRGB(255, 255, 255)
    notification.Font = Enum.Font.Gotham
    notification.TextSize = 20
    notification.Parent = ScreenGui

    TweenService:Create(notification, TweenInfo.new(0.5, Enum.EasingStyle.Quad), {BackgroundTransparency = 0.8}):Play()
    wait(2)
    notification:Destroy()
end

-- Proteção de metatable com pcall
local rollbackEnabled = false
local protectedRemotes = {"TraitChange", "UpgradeUnit", "SummonUnit"}

pcall(function()
    local mt = getrawmetatable(game)
    setreadonly(mt, false)
    local oldNamecall = mt.__namecall

    mt.__namecall = newcclosure(function(self, ...)
        local method = getnamecallmethod()
        if rollbackEnabled and self and (self:IsA("RemoteEvent") or self:IsA("RemoteFunction")) then
            if table.find(protectedRemotes, self.Name) then
                print("[Rollback] Bloqueado:", self.Name)
                if self:IsA("RemoteFunction") and method == "InvokeServer" then
                    return false
                else
                    return nil
                end
            end
        end
        return oldNamecall(self, ...)
    end)

    -- Botão: Toggle Rollback
    local ToggleButton = Instance.new("TextButton")
    ToggleButton.Name = "ToggleButton"
    ToggleButton.Size = UDim2.new(0, 200, 0, 40)
    ToggleButton.Position = UDim2.new(0.5, -100, 0.5, -60)
    ToggleButton.BackgroundColor3 = Color3.fromRGB(0, 150, 0)
    ToggleButton.Text = "Rollback Trait (Desativado)"
    ToggleButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    ToggleButton.Font = Enum.Font.Gotham
    ToggleButton.TextSize = 16
    ToggleButton.Parent = GameFrame

    ToggleButton.MouseButton1Click:Connect(function()
        rollbackEnabled = not rollbackEnabled
        if rollbackEnabled then
            ToggleButton.Text = "Rollback Trait (Ativado)"
            showNotification("Rollback Ativado")
        else
            ToggleButton.Text = "Rollback Trait (Desativado)"
            showNotification("Rollback Desativado")
        end
    end)

    -- Botão: Confirm Rollback
    local ConfirmButton = Instance.new("TextButton")
    ConfirmButton.Name = "ConfirmButton"
    ConfirmButton.Size = UDim2.new(0, 200, 0, 40)
    ConfirmButton.Position = UDim2.new(0.5, -100, 0.5, 10)
    ConfirmButton.BackgroundColor3 = Color3.fromRGB(0, 100, 200)
    ConfirmButton.Text = "Confirm Rollback"
    ConfirmButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    ConfirmButton.Font = Enum.Font.Gotham
    ConfirmButton.TextSize = 16
    ConfirmButton.Parent = GameFrame

    ConfirmButton.MouseButton1Click:Connect(function()
        if rollbackEnabled then
            showNotification("Rollback Confirmado")
            rollbackEnabled = false
            mt.__namecall = oldNamecall -- restaura o hook antes de teleportar

            local countdownLabel = Instance.new("TextLabel")
            countdownLabel.Size = UDim2.new(0, 200, 0, 50)
            countdownLabel.Position = UDim2.new(0.5, -100, 0.5, 0)
            countdownLabel.BackgroundTransparency = 1
            countdownLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
            countdownLabel.Font = Enum.Font.GothamBold
            countdownLabel.TextSize = 24
            countdownLabel.Parent = ScreenGui

            for i = 3, 1, -1 do
                countdownLabel.Text = tostring(i)
                wait(1)
            end

            countdownLabel:Destroy()
            TeleportService:Teleport(game.PlaceId, LocalPlayer)
        else
            showNotification("Ative o Rollback primeiro!")
        end
    end)
end)
