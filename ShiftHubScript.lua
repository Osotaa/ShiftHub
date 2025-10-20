-- ===============================
-- ShiftHub Script Principal
-- ===============================
if not _G.ShiftHub_Validated then
    error("Erro: Acesso não autorizado. Execute o Loader primeiro.")
    return
end

-- Serviços
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local TeleportService = game:GetService("TeleportService")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")
local StarterGui = game:GetService("StarterGui")

local gameName = _G.GameName

-- Função de notificação
local function notify(message, duration)
    duration = duration or 2
    StarterGui:SetCore("SendNotification", {
        Title = "Shift Hub",
        Text = message,
        Duration = duration
    })
end

-- ----------------------------
-- GUI principal
-- ----------------------------
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "CustomGUI"
ScreenGui.Parent = PlayerGui
ScreenGui.ResetOnSpawn = false

local Frame = Instance.new("Frame")
Frame.Name = "MainFrame"
Frame.Size = UDim2.new(0, 300, 0, 200)
Frame.Position = UDim2.new(0.5, -150, 0.5, -100)
Frame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
Frame.BackgroundTransparency = 0.3
Frame.Draggable = true
Frame.Active = true
Frame.Parent = ScreenGui

local TitleLabel = Instance.new("TextLabel")
TitleLabel.Name = "Title"
TitleLabel.Size = UDim2.new(1, 0, 0, 30)
TitleLabel.Position = UDim2.new(0, 0, 0, 0)
TitleLabel.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
TitleLabel.Text = gameName
TitleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
TitleLabel.Font = Enum.Font.Gotham
TitleLabel.TextSize = 18
TitleLabel.Parent = Frame

-- Botões fechar/minimizar
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

-- Toggle Rollback
local GameFrame = Instance.new("Frame")
GameFrame.Name = "GameContent"
GameFrame.Size = UDim2.new(1, 0, 1, -30)
GameFrame.Position = UDim2.new(0, 0, 0, 30)
GameFrame.BackgroundTransparency = 1
GameFrame.Parent = Frame

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

local function showNotification(msg)
    notify(msg, 2)
end

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
    end
end)

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
    showNotification("Rollback Confirmado")
    wait(1)
    rollbackEnabled = false
    mt.__namecall = oldNamecall
    TeleportService:Teleport(game.PlaceId, LocalPlayer)
end)
