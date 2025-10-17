 1. VERIFICAÇÃO DE VALIDAÇÃO
if not _G.ShiftHub_Validated then
    -- Impede a execução direta, pois a validação não ocorreu no Loader.
    error("Erro: Acesso não autorizado. Execute o Loader para iniciar.")
    return -- Para a execução
end

-- 2. SEÇÃO DE CÓDIGO DO HUB/GUI
-- Coloque todo o código real da sua GUI e das funcionalidades do seu Hub abaixo desta linha.
print("[ShiftHub] Script principal carregado com sucesso. Iniciando GUI...")

-- Script: GUI Personalizada (LocalScript)
-- Coloque este script em StarterPlayerScripts ou um LocalScript dentro de StarterGui

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")  -- Para animações suaves
local TeleportService = game:GetService("TeleportService")
local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

-- Cria o ScreenGui
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "CustomGUI"
ScreenGui.Parent = PlayerGui
ScreenGui.ResetOnSpawn = false  -- Mantém o GUI após spawn

-- Cria o Frame principal (movel, transparente e compacto)
local Frame = Instance.new("Frame")
Frame.Name = "MainFrame"
Frame.Size = UDim2.new(0, 300, 0, 200)  -- Largura: 300px, Altura: 200px
Frame.Position = UDim2.new(0.5, -150, 0.5, -100)  -- Centralizado inicialmente
Frame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)  -- Cor escura e discreta
Frame.BackgroundTransparency = 0.3  -- Transparente
Frame.Draggable = true  -- Faz o frame movel
Frame.Active = true  -- Permite interagir
Frame.Parent = ScreenGui

-- Título do GUI (como uma "aba")
local TitleLabel = Instance.new("TextLabel")
TitleLabel.Name = "Title"
TitleLabel.Size = UDim2.new(1, 0, 0, 30)  -- Ocupa o topo
TitleLabel.Position = UDim2.new(0, 0, 0, 0)
TitleLabel.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
TitleLabel.Text = "Game"  -- Aba "Game"
TitleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
TitleLabel.Font = Enum.Font.Gotham
TitleLabel.TextSize = 18
TitleLabel.Parent = Frame

-- Botão de Fechar
local CloseButton = Instance.new("TextButton")
CloseButton.Name = "CloseButton"
CloseButton.Size = UDim2.new(0, 30, 0, 30)
CloseButton.Position = UDim2.new(1, -30, 0, 0)  -- Canto superior direito
CloseButton.BackgroundColor3 = Color3.fromRGB(200, 50, 50)  -- Vermelho discreto
CloseButton.Text = "X"
CloseButton.TextColor3 = Color3.fromRGB(255, 255, 255)
CloseButton.Font = Enum.Font.SourceSans
CloseButton.TextSize = 20
CloseButton.Parent = Frame

CloseButton.MouseButton1Click:Connect(function()
    ScreenGui.Enabled = false  -- Esconde o GUI
end)

-- Botão de Minimizar
local MinimizeButton = Instance.new("TextButton")
MinimizeButton.Name = "MinimizeButton"
MinimizeButton.Size = UDim2.new(0, 30, 0, 30)
MinimizeButton.Position = UDim2.new(1, -60, 0, 0)  -- Próximo ao botão de fechar
MinimizeButton.BackgroundColor3 = Color3.fromRGB(50, 200, 50)  -- Verde discreto
MinimizeButton.Text = "-"
MinimizeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
MinimizeButton.Font = Enum.Font.SourceSans
MinimizeButton.TextSize = 20
MinimizeButton.Parent = Frame

MinimizeButton.MouseButton1Click:Connect(function()
    Frame.Visible = false  -- Minimiza (esconde)
end)

-- Tecla de bind para minimizar (usando 'M' como exemplo)
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if not gameProcessed and input.KeyCode == Enum.KeyCode.M then  -- Tecla 'M'
        Frame.Visible = not Frame.Visible  -- Alterna visibilidade
    end
end)

-- Conteúdo da aba "Game"
local GameFrame = Instance.new("Frame")
GameFrame.Name = "GameContent"
GameFrame.Size = UDim2.new(1, 0, 1, -30)  -- Ocupa o resto do frame, menos o título
GameFrame.Position = UDim2.new(0, 0, 0, 30)
GameFrame.BackgroundTransparency = 1  -- Transparente para não interferir
GameFrame.Parent = Frame

-- Botão Toggle: Rollback Trait
local ToggleButton = Instance.new("TextButton")
ToggleButton.Name = "ToggleButton"
ToggleButton.Size = UDim2.new(0, 200, 0, 40)
ToggleButton.Position = UDim2.new(0.5, -100, 0.5, -60)  -- Posição dentro do GameFrame
ToggleButton.BackgroundColor3 = Color3.fromRGB(0, 150, 0)  -- Verde
ToggleButton.Text = "Rollback Trait (Desativado)"
ToggleButton.TextColor3 = Color3.fromRGB(255, 255, 255)
ToggleButton.Font = Enum.Font.Gotham
ToggleButton.TextSize = 16
ToggleButton.Parent = GameFrame

local isToggled = false  -- Estado inicial

ToggleButton.MouseButton1Click:Connect(function()
    isToggled = not isToggled
    if isToggled then
        ToggleButton.Text = "Rollback Trait (Ativado)"
        -- Notificação
        showNotification("Rollback Ativado")
    else
        ToggleButton.Text = "Rollback Trait (Desativado)"
    end
end)

-- Botão: Confirm Rollback
local ConfirmButton = Instance.new("TextButton")
ConfirmButton.Name = "ConfirmButton"
ConfirmButton.Size = UDim2.new(0, 200, 0, 40)
ConfirmButton.Position = UDim2.new(0.5, -100, 0.5, 10)  -- Abaixo do toggle
ConfirmButton.BackgroundColor3 = Color3.fromRGB(0, 100, 200)  -- Azul
ConfirmButton.Text = "Confirm Rollback"
ConfirmButton.TextColor3 = Color3.fromRGB(255, 255, 255)
ConfirmButton.Font = Enum.Font.Gotham
ConfirmButton.TextSize = 16
ConfirmButton.Parent = GameFrame

ConfirmButton.MouseButton1Click:Connect(function()
    showNotification("Rollback Confirmed")
    
    -- Contagem regressiva
    local countdownLabel = Instance.new("TextLabel")
    countdownLabel.Size = UDim2.new(0, 200, 0, 50)
    countdownLabel.Position = UDim2.new(0.5, -100, 0.5, 0)
    countdownLabel.BackgroundTransparency = 1
    countdownLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    countdownLabel.Font = Enum.Font.GothamBold
    countdownLabel.TextSize = 24
    countdownLabel.Parent = ScreenGui  -- Exibe na tela
    
    for i = 3, 1, -1 do
        countdownLabel.Text = tostring(i)
        wait(1)  -- Espera 1 segundo
    end
    
    countdownLabel:Destroy()  -- Remove o label
    
    -- Recarrega o jogo
    TeleportService:Teleport(game.PlaceId, LocalPlayer)  -- Teleporta de volta ao mesmo lugar
end)

-- Função para exibir notificação
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
    
    TweenService:Create(notification, TweenInfo.new(0.5, Enum.EasingStyle.Quad), {BackgroundTransparency = 0.8}):Play()  -- Animação de fade
    
    wait(2)  -- Exibe por 2 segundos
    
    notification:Destroy()  -- Remove a notificação
end
