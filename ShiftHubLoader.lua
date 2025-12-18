local API_BASE_URL = "http://51.75.118.169:20016"
local API_SECRET = (function()
    local encoded = "WG90YTMyMQ=="
    local b = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/'
    encoded = string.gsub(encoded, '[^'..b..'=]', '')
    return (encoded:gsub('.', function(x)
        if (x == '=') then return '' end
        local r,f='',(b:find(x)-1)
        for i=6,1,-1 do r=r..(f%2^i-f%2^(i-1)>0 and '1' or '0') end
        return r;
    end):gsub('%d%d%d?%d?%d?%d?%d?%d?', function(x)
        if (#x ~= 8) then return '' end
        local c=0
        for i=1,8 do c=c+(x:sub(i,i)=='1' and 2^(8-i) or 0) end
        return string.char(c)
    end))
end)()
local key = nil

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local TeleportService = game:GetService("TeleportService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local robloxId = (LocalPlayer and LocalPlayer.UserId) or 0
local hwid = tostring(robloxId) .. "_" .. ((LocalPlayer and LocalPlayer.Name) or "unknown"):gsub("%s+", ""):lower()

-- ===== SISTEMA DE LOGS DISCORD (PROTEGIDO) =====
local WEBHOOK_PROXY = "https://shifthub-webhook-proxy.artur418098.workers.dev"
local WEBHOOK_SECRET = "241433ShiftHub"

local lastLogTimes = {}
local LOG_COOLDOWN = 2

-- ===== PERFORMANCE MONITOR =====
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
        highMemory = 300,
        lowFPS = 20,
        highPing = 500,
        maxErrorsPerMinute = 5
    }
}

-- ===== FUNÇÃO AUXILIAR PARA BUSCAR MAIOR DISPLAYORDER =====
local function getHighestDisplayOrder()
    local highest = 0
    pcall(function()
        local playerGui = LocalPlayer:WaitForChild("PlayerGui", 5)
        if playerGui then
            for _, gui in pairs(playerGui:GetChildren()) do
                if gui:IsA("ScreenGui") and gui.DisplayOrder > highest then
                    highest = gui.DisplayOrder
                end
            end
        end
    end)
    return highest + 1000 -- ✅ Muito maior agora!
end

-- ===== MODAL DE CHANGELOG (APÓS UPDATE) =====
local function createChangelogModal(changelog)
    pcall(function()
        local playerGui = LocalPlayer:WaitForChild("PlayerGui", 5)
        if not playerGui then return end

        local sg = Instance.new("ScreenGui")
        sg.Name = "ShiftHub_ChangelogModal"
        sg.ResetOnSpawn = false
        sg.DisplayOrder = getHighestDisplayOrder()
        sg.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

        -- Background com imagem
        local overlay = Instance.new("ImageLabel")
        overlay.Size = UDim2.new(1, 0, 1, 0)
        overlay.BackgroundTransparency = 1
        overlay.Image = "rbxassetid://18939690993" -- Sua imagem
        overlay.ScaleType = Enum.ScaleType.Crop
        overlay.ImageTransparency = 0.3
        overlay.Parent = sg

        -- Blur effect
        local blur = Instance.new("Frame")
        blur.Size = UDim2.new(1, 0, 1, 0)
        blur.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
        blur.BackgroundTransparency = 0.4
        blur.BorderSizePixel = 0
        blur.Parent = overlay

        -- Modal principal
        local modal = Instance.new("Frame")
        modal.Size = UDim2.new(0, 900, 0, 400)
        modal.AnchorPoint = Vector2.new(0.5, 0.5)
        modal.Position = UDim2.new(0.5, 0, 0.5, 0)
        modal.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
        modal.BackgroundTransparency = 0.1
        modal.BorderSizePixel = 0
        modal.Parent = sg

        local modalCorner = Instance.new("UICorner")
        modalCorner.CornerRadius = UDim.new(0, 20)
        modalCorner.Parent = modal

        local stroke = Instance.new("UIStroke")
        stroke.Color = Color3.fromRGB(255, 255, 255)
        stroke.Thickness = 1
        stroke.Transparency = 0.9
        stroke.Parent = modal

        -- Ícone de tendência (como na imagem)
        local icon = Instance.new("ImageLabel")
        icon.Size = UDim2.new(0, 40, 0, 40)
        icon.Position = UDim2.new(0.5, -20, 0, 30)
        icon.BackgroundTransparency = 1
        icon.Image = "rbxassetid://10723434711" -- Ícone de gráfico/tendência
        icon.ImageColor3 = Color3.fromRGB(255, 255, 255)
        icon.Parent = modal

        -- Título
        local title = Instance.new("TextLabel")
        title.Size = UDim2.new(1, 0, 0, 50)
        title.Position = UDim2.new(0, 0, 0, 80)
        title.BackgroundTransparency = 1
        title.Font = Enum.Font.GothamBold
        title.Text = "Change Logs"
        title.TextSize = 32
        title.TextColor3 = Color3.fromRGB(255, 255, 255)
        title.Parent = modal

        -- Subtítulo
        local subtitle = Instance.new("TextLabel")
        subtitle.Size = UDim2.new(1, 0, 0, 30)
        subtitle.Position = UDim2.new(0, 0, 0, 130)
        subtitle.BackgroundTransparency = 1
        subtitle.Font = Enum.Font.Gotham
        subtitle.Text = "Stay updated with the latest features and improvements"
        subtitle.TextSize = 14
        subtitle.TextColor3 = Color3.fromRGB(150, 150, 150)
        subtitle.Parent = modal

        -- Área de changelog com scroll
        local changelogFrame = Instance.new("ScrollingFrame")
        changelogFrame.Size = UDim2.new(1, -80, 0, 180)
        changelogFrame.Position = UDim2.new(0, 40, 0, 180)
        changelogFrame.BackgroundTransparency = 1
        changelogFrame.BorderSizePixel = 0
        changelogFrame.ScrollBarThickness = 4
        changelogFrame.ScrollBarImageColor3 = Color3.fromRGB(255, 255, 255)
        changelogFrame.ScrollBarImageTransparency = 0.7
        changelogFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
        changelogFrame.Parent = modal

        -- Lista de mudanças
        local listLayout = Instance.new("UIListLayout")
        listLayout.Padding = UDim.new(0, 10)
        listLayout.SortOrder = Enum.SortOrder.LayoutOrder
        listLayout.Parent = changelogFrame

        -- Parse changelog e criar items
        local yOffset = 0
        for line in string.gmatch(changelog, "[^\r\n]+") do
            if line:match("%S") and not line:match("%[%d") then -- Ignora linhas vazias e headers
                local item = Instance.new("Frame")
                item.Size = UDim2.new(1, -20, 0, 35)
                item.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
                item.BorderSizePixel = 0
                item.Parent = changelogFrame

                local itemCorner = Instance.new("UICorner")
                itemCorner.CornerRadius = UDim.new(0, 8)
                itemCorner.Parent = item

                local itemText = Instance.new("TextLabel")
                itemText.Size = UDim2.new(1, -20, 1, 0)
                itemText.Position = UDim2.new(0, 10, 0, 0)
                itemText.BackgroundTransparency = 1
                itemText.Font = Enum.Font.Gotham
                itemText.Text = line
                itemText.TextSize = 14
                itemText.TextColor3 = Color3.fromRGB(220, 220, 220)
                itemText.TextXAlignment = Enum.TextXAlignment.Left
                itemText.Parent = item

                yOffset = yOffset + 45
            end
        end

        changelogFrame.CanvasSize = UDim2.new(0, 0, 0, yOffset)

        -- Botão Close
        local closeBtn = Instance.new("TextButton")
        closeBtn.Size = UDim2.new(0, 120, 0, 45)
        closeBtn.AnchorPoint = Vector2.new(0.5, 0)
        closeBtn.Position = UDim2.new(0.5, 0, 1, -65)
        closeBtn.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        closeBtn.BorderSizePixel = 0
        closeBtn.Font = Enum.Font.GothamBold
        closeBtn.Text = "Close"
        closeBtn.TextSize = 16
        closeBtn.TextColor3 = Color3.fromRGB(0, 0, 0)
        closeBtn.AutoButtonColor = false
        closeBtn.Parent = modal

        local closeCorner = Instance.new("UICorner")
        closeCorner.CornerRadius = UDim.new(0, 10)
        closeCorner.Parent = closeBtn

        sg.Parent = playerGui

        -- Animação de entrada
        modal.Size = UDim2.new(0, 850, 0, 350)
        modal.BackgroundTransparency = 1
        
        task.spawn(function()
            TweenService:Create(modal, TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
                Size = UDim2.new(0, 900, 0, 400),
                BackgroundTransparency = 0.1
            }):Play()
        end)

        -- Hover no botão
        closeBtn.MouseEnter:Connect(function()
            TweenService:Create(closeBtn, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(230, 230, 230)}):Play()
        end)
        closeBtn.MouseLeave:Connect(function()
            TweenService:Create(closeBtn, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(255, 255, 255)}):Play()
        end)

        closeBtn.MouseButton1Click:Connect(function()
            TweenService:Create(modal, TweenInfo.new(0.3), {BackgroundTransparency = 1}):Play()
            TweenService:Create(overlay, TweenInfo.new(0.3), {ImageTransparency = 1}):Play()
            task.wait(0.35)
            sg:Destroy()
        end)
    end)
end

-- ===== MODAL DE UPDATE SIMPLIFICADO (SEM CHANGELOG) =====
local function createUpdateModal(currentVer, newVer, updateCallback, cancelCallback)
    pcall(function()
        local playerGui = LocalPlayer:WaitForChild("PlayerGui", 5)
        if not playerGui then return end

        local oldModal = playerGui:FindFirstChild("ShiftHub_UpdateModal")
        if oldModal then oldModal:Destroy() end

        local sg = Instance.new("ScreenGui")
        sg.Name = "ShiftHub_UpdateModal"
        sg.ResetOnSpawn = false
        sg.DisplayOrder = getHighestDisplayOrder()
        sg.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

        local overlay = Instance.new("Frame")
        overlay.Size = UDim2.new(1, 0, 1, 0)
        overlay.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
        overlay.BackgroundTransparency = 1
        overlay.BorderSizePixel = 0
        overlay.Parent = sg

        local modal = Instance.new("Frame")
        modal.Size = UDim2.new(0, 450, 0, 250)
        modal.AnchorPoint = Vector2.new(0.5, 0.5)
        modal.Position = UDim2.new(0.5, 0, 0.5, 0)
        modal.BackgroundColor3 = Color3.fromRGB(30, 32, 38)
        modal.BorderSizePixel = 0
        modal.BackgroundTransparency = 1
        modal.Parent = sg

        local modalCorner = Instance.new("UICorner")
        modalCorner.CornerRadius = UDim.new(0, 16)
        modalCorner.Parent = modal

        local stroke = Instance.new("UIStroke")
        stroke.Color = Color3.fromRGB(88, 101, 242)
        stroke.Thickness = 2
        stroke.Transparency = 1
        stroke.Parent = modal

        local header = Instance.new("Frame")
        header.Size = UDim2.new(1, 0, 0, 80)
        header.BackgroundColor3 = Color3.fromRGB(88, 101, 242)
        header.BorderSizePixel = 0
        header.Parent = modal

        local headerCorner = Instance.new("UICorner")
        headerCorner.CornerRadius = UDim.new(0, 16)
        headerCorner.Parent = header

        local headerFix = Instance.new("Frame")
        headerFix.Size = UDim2.new(1, 0, 0, 16)
        headerFix.Position = UDim2.new(0, 0, 1, -16)
        headerFix.BackgroundColor3 = Color3.fromRGB(88, 101, 242)
        headerFix.BorderSizePixel = 0
        headerFix.Parent = header

        local gradient = Instance.new("UIGradient")
        gradient.Color = ColorSequence.new{
            ColorSequenceKeypoint.new(0, Color3.fromRGB(88, 101, 242)),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(108, 121, 255))
        }
        gradient.Rotation = 45
        gradient.Parent = header

        local icon = Instance.new("TextLabel")
        icon.Size = UDim2.new(0, 50, 0, 50)
        icon.Position = UDim2.new(0, 20, 0, 15)
        icon.BackgroundTransparency = 1
        icon.Font = Enum.Font.SourceSansBold
        icon.Text = "🎉"
        icon.TextSize = 40
        icon.TextTransparency = 1
        icon.Parent = header

        local title = Instance.new("TextLabel")
        title.Size = UDim2.new(1, -90, 1, 0)
        title.Position = UDim2.new(0, 75, 0, 0)
        title.BackgroundTransparency = 1
        title.Font = Enum.Font.GothamBold
        title.Text = "New Version Available!"
        title.TextSize = 24
        title.TextColor3 = Color3.fromRGB(255, 255, 255)
        title.TextXAlignment = Enum.TextXAlignment.Left
        title.TextTransparency = 1
        title.Parent = header

        local content = Instance.new("Frame")
        content.Size = UDim2.new(1, -50, 1, -170)
        content.Position = UDim2.new(0, 25, 0, 90)
        content.BackgroundTransparency = 1
        content.Parent = modal

        local versionBox = Instance.new("Frame")
        versionBox.Size = UDim2.new(1, 0, 0, 70)
        versionBox.Position = UDim2.new(0, 0, 0, 5)
        versionBox.BackgroundColor3 = Color3.fromRGB(40, 42, 50)
        versionBox.BorderSizePixel = 0
        versionBox.BackgroundTransparency = 1
        versionBox.Parent = content

        local versionCorner = Instance.new("UICorner")
        versionCorner.CornerRadius = UDim.new(0, 10)
        versionCorner.Parent = versionBox

        local currentLabel = Instance.new("TextLabel")
        currentLabel.Size = UDim2.new(1, -20, 0, 28)
        currentLabel.Position = UDim2.new(0, 10, 0, 8)
        currentLabel.BackgroundTransparency = 1
        currentLabel.Font = Enum.Font.Gotham
        currentLabel.Text = "📦 Current: v" .. currentVer
        currentLabel.TextSize = 15
        currentLabel.TextColor3 = Color3.fromRGB(180, 180, 190)
        currentLabel.TextXAlignment = Enum.TextXAlignment.Left
        currentLabel.TextTransparency = 1
        currentLabel.Parent = versionBox

        local newLabel = Instance.new("TextLabel")
        newLabel.Size = UDim2.new(1, -20, 0, 28)
        newLabel.Position = UDim2.new(0, 10, 0, 36)
        newLabel.BackgroundTransparency = 1
        newLabel.Font = Enum.Font.GothamBold
        newLabel.Text = "✨ New: v" .. newVer
        newLabel.TextSize = 16
        newLabel.TextColor3 = Color3.fromRGB(88, 200, 255)
        newLabel.TextXAlignment = Enum.TextXAlignment.Left
        newLabel.TextTransparency = 1
        newLabel.Parent = versionBox

        local buttonsFrame = Instance.new("Frame")
        buttonsFrame.Size = UDim2.new(1, -50, 0, 50)
        buttonsFrame.Position = UDim2.new(0, 25, 1, -70)
        buttonsFrame.BackgroundTransparency = 1
        buttonsFrame.Parent = modal

        local laterBtn = Instance.new("TextButton")
        laterBtn.Size = UDim2.new(0.47, 0, 1, 0)
        laterBtn.Position = UDim2.new(0, 0, 0, 0)
        laterBtn.BackgroundColor3 = Color3.fromRGB(50, 52, 60)
        laterBtn.BorderSizePixel = 0
        laterBtn.Font = Enum.Font.GothamBold
        laterBtn.Text = "Later"
        laterBtn.TextSize = 16
        laterBtn.TextColor3 = Color3.fromRGB(200, 200, 210)
        laterBtn.AutoButtonColor = false
        laterBtn.BackgroundTransparency = 1
        laterBtn.TextTransparency = 1
        laterBtn.Parent = buttonsFrame

        local laterCorner = Instance.new("UICorner")
        laterCorner.CornerRadius = UDim.new(0, 10)
        laterCorner.Parent = laterBtn

        local laterStroke = Instance.new("UIStroke")
        laterStroke.Color = Color3.fromRGB(70, 72, 80)
        laterStroke.Thickness = 2
        laterStroke.Transparency = 1
        laterStroke.Parent = laterBtn

        local updateBtn = Instance.new("TextButton")
        updateBtn.Size = UDim2.new(0.47, 0, 1, 0)
        updateBtn.Position = UDim2.new(0.53, 0, 0, 0)
        updateBtn.BackgroundColor3 = Color3.fromRGB(88, 101, 242)
        updateBtn.BorderSizePixel = 0
        updateBtn.Font = Enum.Font.GothamBold
        updateBtn.Text = "Update Now"
        updateBtn.TextSize = 16
        updateBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
        updateBtn.AutoButtonColor = false
        updateBtn.BackgroundTransparency = 1
        updateBtn.TextTransparency = 1
        updateBtn.Parent = buttonsFrame

        local updateCorner = Instance.new("UICorner")
        updateCorner.CornerRadius = UDim.new(0, 10)
        updateCorner.Parent = updateBtn

        local btnGradient = Instance.new("UIGradient")
        btnGradient.Color = ColorSequence.new{
            ColorSequenceKeypoint.new(0, Color3.fromRGB(88, 101, 242)),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(108, 121, 255))
        }
        btnGradient.Rotation = 45
        btnGradient.Parent = updateBtn

        sg.Parent = playerGui

        task.spawn(function()
            TweenService:Create(overlay, TweenInfo.new(0.3), {BackgroundTransparency = 0.6}):Play()
            
            modal.Size = UDim2.new(0, 420, 0, 220)
            TweenService:Create(modal, TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
                BackgroundTransparency = 0,
                Size = UDim2.new(0, 450, 0, 250)
            }):Play()
            
            TweenService:Create(stroke, TweenInfo.new(0.5), {Transparency = 0}):Play()
            
            task.wait(0.2)
            
            TweenService:Create(icon, TweenInfo.new(0.3), {TextTransparency = 0}):Play()
            TweenService:Create(title, TweenInfo.new(0.3), {TextTransparency = 0}):Play()
            
            task.wait(0.1)
            
            TweenService:Create(versionBox, TweenInfo.new(0.3), {BackgroundTransparency = 0}):Play()
            TweenService:Create(currentLabel, TweenInfo.new(0.3), {TextTransparency = 0}):Play()
            TweenService:Create(newLabel, TweenInfo.new(0.3), {TextTransparency = 0}):Play()
            
            task.wait(0.1)
            
            TweenService:Create(laterBtn, TweenInfo.new(0.3), {
                BackgroundTransparency = 0,
                TextTransparency = 0
            }):Play()
            TweenService:Create(laterStroke, TweenInfo.new(0.3), {Transparency = 0}):Play()
            
            TweenService:Create(updateBtn, TweenInfo.new(0.3), {
                BackgroundTransparency = 0,
                TextTransparency = 0
            }):Play()
            
            task.spawn(function()
                while icon.Parent do
                    TweenService:Create(icon, TweenInfo.new(0.8, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {
                        TextSize = 44
                    }):Play()
                    task.wait(0.8)
                    TweenService:Create(icon, TweenInfo.new(0.8, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {
                        TextSize = 40
                    }):Play()
                    task.wait(0.8)
                end
            end)
        end)

        laterBtn.MouseEnter:Connect(function()
            TweenService:Create(laterBtn, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(60, 62, 70)}):Play()
        end)
        laterBtn.MouseLeave:Connect(function()
            TweenService:Create(laterBtn, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(50, 52, 60)}):Play()
        end)

        updateBtn.MouseEnter:Connect(function()
            TweenService:Create(updateBtn, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(98, 111, 252)}):Play()
        end)
        updateBtn.MouseLeave:Connect(function()
            TweenService:Create(updateBtn, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(88, 101, 242)}):Play()
        end)

        laterBtn.MouseButton1Click:Connect(function()
            TweenService:Create(overlay, TweenInfo.new(0.3), {BackgroundTransparency = 1}):Play()
            TweenService:Create(modal, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.In), {
                BackgroundTransparency = 1,
                Size = UDim2.new(0, 420, 0, 220)
            }):Play()
            
            task.wait(0.45)
            sg:Destroy()
            
            if cancelCallback then
                cancelCallback()
            end
        end)

        updateBtn.MouseButton1Click:Connect(function()
            laterBtn.Active = false
            updateBtn.Active = false
            laterBtn.TextTransparency = 0.5
            
            updateBtn.Text = "Updating"
            
            task.spawn(function()
                local dots = 0
                while updateBtn.Parent do
                    dots = (dots % 3) + 1
                    updateBtn.Text = "Updating" .. string.rep(".", dots)
                    task.wait(0.5)
                end
            end)
            
            if updateCallback then
                updateCallback(sg, modal, overlay)
            end
        end)
    end)
end

-- ===== TELA DE LOADING COM ENGRENAGEM GIRANDO =====
local function createLoadingOverlay()
    local success, loadingSg = pcall(function()
        local playerGui = LocalPlayer:WaitForChild("PlayerGui", 5)
        if not playerGui then return nil end

        local sg = Instance.new("ScreenGui")
        sg.Name = "ShiftHub_LoadingOverlay"
        sg.ResetOnSpawn = false
        sg.DisplayOrder = getHighestDisplayOrder()
        sg.IgnoreGuiInset = true

        -- Background com imagem
        local overlay = Instance.new("ImageLabel")
        overlay.Size = UDim2.new(1, 0, 1, 0)
        overlay.BackgroundTransparency = 1
        overlay.Image = "rbxassetid://18939690993"
        overlay.ScaleType = Enum.ScaleType.Crop
        overlay.ImageTransparency = 0
        overlay.Parent = sg

        -- Blur/Darkening
        local darkening = Instance.new("Frame")
        darkening.Size = UDim2.new(1, 0, 1, 0)
        darkening.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
        darkening.BackgroundTransparency = 0.5
        darkening.BorderSizePixel = 0
        darkening.Parent = overlay

        -- Engrenagem girando
        local gear = Instance.new("ImageLabel")
        gear.Size = UDim2.new(0, 100, 0, 100)
        gear.AnchorPoint = Vector2.new(0.5, 0.5)
        gear.Position = UDim2.new(0.5, 0, 0.5, -60)
        gear.BackgroundTransparency = 1
        gear.Image = "rbxassetid://6031094678" -- Engrenagem
        gear.ImageColor3 = Color3.fromRGB(255, 255, 255)
        gear.Parent = darkening

        local text = Instance.new("TextLabel")
        text.Size = UDim2.new(0, 400, 0, 40)
        text.AnchorPoint = Vector2.new(0.5, 0.5)
        text.Position = UDim2.new(0.5, 0, 0.5, 30)
        text.BackgroundTransparency = 1
        text.Font = Enum.Font.GothamBold
        text.Text = "Updating Shift Hub"
        text.TextSize = 24
        text.TextColor3 = Color3.fromRGB(255, 255, 255)
        text.Parent = darkening

        local subtext = Instance.new("TextLabel")
        subtext.Size = UDim2.new(0, 400, 0, 30)
        subtext.AnchorPoint = Vector2.new(0.5, 0.5)
        subtext.Position = UDim2.new(0.5, 0, 0.5, 65)
        subtext.BackgroundTransparency = 1
        subtext.Font = Enum.Font.Gotham
        subtext.Text = "Please wait..."
        subtext.TextSize = 14
        subtext.TextColor3 = Color3.fromRGB(200, 200, 200)
        subtext.Parent = darkening

        sg.Parent = playerGui

        -- Rotação da engrenagem
        task.spawn(function()
            while gear.Parent do
                for i = 0, 360, 2 do
                    if not gear.Parent then break end
                    gear.Rotation = i
                    task.wait(0.01)
                end
            end
        end)

        -- Animação do texto
        task.spawn(function()
            local dots = 0
            while text.Parent do
                dots = (dots % 3) + 1
                text.Text = "Updating Shift Hub" .. string.rep(".", dots)
                task.wait(0.5)
            end
        end)

        -- Auto-destruir após 7 segundos
        task.spawn(function()
            task.wait(7)
            if sg and sg.Parent then
                TweenService:Create(overlay, TweenInfo.new(0.5), {ImageTransparency = 1}):Play()
                TweenService:Create(darkening, TweenInfo.new(0.5), {BackgroundTransparency = 1}):Play()
                task.wait(0.6)
                sg:Destroy()
            end
        end)

        return sg
    end)
    
    return success and loadingSg or nil
end

-- ===== MODAL DE ERRO COM RETRY =====
local function createErrorModal(errorMessage, retryCallback, continueCallback)
    pcall(function()
        local playerGui = LocalPlayer:WaitForChild("PlayerGui", 5)
        if not playerGui then return end

        local sg = Instance.new("ScreenGui")
        sg.Name = "ShiftHub_ErrorModal"
        sg.ResetOnSpawn = false
        sg.DisplayOrder = getHighestDisplayOrder()
        sg.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

        local overlay = Instance.new("Frame")
        overlay.Size = UDim2.new(1, 0, 1, 0)
        overlay.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
        overlay.BackgroundTransparency = 1
        overlay.BorderSizePixel = 0
        overlay.Parent = sg

        local modal = Instance.new("Frame")
        modal.Size = UDim2.new(0, 420, 0, 280)
        modal.AnchorPoint = Vector2.new(0.5, 0.5)
        modal.Position = UDim2.new(0.5, 0, 0.5, 0)
        modal.BackgroundColor3 = Color3.fromRGB(30, 32, 38)
        modal.BorderSizePixel = 0
        modal.BackgroundTransparency = 1
        modal.Parent = sg

        local modalCorner = Instance.new("UICorner")
        modalCorner.CornerRadius = UDim.new(0, 16)
        modalCorner.Parent = modal

        local stroke = Instance.new("UIStroke")
        stroke.Color = Color3.fromRGB(231, 76, 60)
        stroke.Thickness = 2
        stroke.Transparency = 1
        stroke.Parent = modal

        local header = Instance.new("Frame")
        header.Size = UDim2.new(1, 0, 0, 80)
        header.BackgroundColor3 = Color3.fromRGB(231, 76, 60)
        header.BorderSizePixel = 0
        header.Parent = modal

        local headerCorner = Instance.new("UICorner")
        headerCorner.CornerRadius = UDim.new(0, 16)
        headerCorner.Parent = header

        local headerFix = Instance.new("Frame")
        headerFix.Size = UDim2.new(1, 0, 0, 16)
        headerFix.Position = UDim2.new(0, 0, 1, -16)
        headerFix.BackgroundColor3 = Color3.fromRGB(231, 76, 60)
        headerFix.BorderSizePixel = 0
        headerFix.Parent = header

        local icon = Instance.new("TextLabel")
        icon.Size = UDim2.new(0, 50, 0, 50)
        icon.Position = UDim2.new(0, 20, 0, 15)
        icon.BackgroundTransparency = 1
        icon.Font = Enum.Font.SourceSansBold
        icon.Text = "❌"
        icon.TextSize = 40
        icon.TextTransparency = 1
        icon.Parent = header

        local title = Instance.new("TextLabel")
        title.Size = UDim2.new(1, -90, 1, 0)
        title.Position = UDim2.new(0, 75, 0, 0)
        title.BackgroundTransparency = 1
        title.Font = Enum.Font.GothamBold
        title.Text = "Update Failed"
        title.TextSize = 24
        title.TextColor3 = Color3.fromRGB(255, 255, 255)
        title.TextXAlignment = Enum.TextXAlignment.Left
        title.TextTransparency = 1
        title.Parent = header

        local message = Instance.new("TextLabel")
        message.Size = UDim2.new(1, -50, 0, 100)
        message.Position = UDim2.new(0, 25, 0, 95)
        message.BackgroundTransparency = 1
        message.Font = Enum.Font.Gotham
        message.Text = errorMessage
        message.TextSize = 13
        message.TextColor3 = Color3.fromRGB(200, 200, 210)
        message.TextXAlignment = Enum.TextXAlignment.Center
        message.TextYAlignment = Enum.TextYAlignment.Top
        message.TextWrapped = true
        message.TextTransparency = 1
        message.Parent = modal

        local buttonsFrame = Instance.new("Frame")
        buttonsFrame.Size = UDim2.new(1, -50, 0, 50)
        buttonsFrame.Position = UDim2.new(0, 25, 1, -70)
        buttonsFrame.BackgroundTransparency = 1
        buttonsFrame.Parent = modal

        local continueBtn = Instance.new("TextButton")
        continueBtn.Size = UDim2.new(0.47, 0, 1, 0)
        continueBtn.Position = UDim2.new(0, 0, 0, 0)
        continueBtn.BackgroundColor3 = Color3.fromRGB(50, 52, 60)
        continueBtn.BorderSizePixel = 0
        continueBtn.Font = Enum.Font.GothamBold
        continueBtn.Text = "Continue Anyway"
        continueBtn.TextSize = 14
        continueBtn.TextColor3 = Color3.fromRGB(200, 200, 210)
        continueBtn.AutoButtonColor = false
        continueBtn.BackgroundTransparency = 1
        continueBtn.TextTransparency = 1
        continueBtn.Parent = buttonsFrame

        local continueCorner = Instance.new("UICorner")
        continueCorner.CornerRadius = UDim.new(0, 10)
        continueCorner.Parent = continueBtn

        local retryBtn = Instance.new("TextButton")
        retryBtn.Size = UDim2.new(0.47, 0, 1, 0)
        retryBtn.Position = UDim2.new(0.53, 0, 0, 0)
        retryBtn.BackgroundColor3 = Color3.fromRGB(231, 76, 60)
        retryBtn.BorderSizePixel = 0
        retryBtn.Font = Enum.Font.GothamBold
        retryBtn.Text = "Retry Update"
        retryBtn.TextSize = 14
        retryBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
        retryBtn.AutoButtonColor = false
        retryBtn.BackgroundTransparency = 1
        retryBtn.TextTransparency = 1
        retryBtn.Parent = buttonsFrame

        local retryCorner = Instance.new("UICorner")
        retryCorner.CornerRadius = UDim.new(0, 10)
        retryCorner.Parent = retryBtn

        sg.Parent = playerGui

        task.spawn(function()
            TweenService:Create(overlay, TweenInfo.new(0.3), {BackgroundTransparency = 0.6}):Play()
            modal.Size = UDim2.new(0, 390, 0, 250)
            TweenService:Create(modal, TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
                BackgroundTransparency = 0,
                Size = UDim2.new(0, 420, 0, 280)
            }):Play()
            TweenService:Create(stroke, TweenInfo.new(0.5), {Transparency = 0}):Play()
            
            task.wait(0.2)
            TweenService:Create(icon, TweenInfo.new(0.3), {TextTransparency = 0}):Play()
            TweenService:Create(title, TweenInfo.new(0.3), {TextTransparency = 0}):Play()
            TweenService:Create(message, TweenInfo.new(0.3), {TextTransparency = 0}):Play()
            
            task.wait(0.1)
            TweenService:Create(continueBtn, TweenInfo.new(0.3), {
                BackgroundTransparency = 0,
                TextTransparency = 0
            }):Play()
            TweenService:Create(retryBtn, TweenInfo.new(0.3), {
                BackgroundTransparency = 0,
                TextTransparency = 0
            }):Play()
        end)

        continueBtn.MouseEnter:Connect(function()
            TweenService:Create(continueBtn, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(60, 62, 70)}):Play()
        end)
        continueBtn.MouseLeave:Connect(function()
            TweenService:Create(continueBtn, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(50, 52, 60)}):Play()
        end)

        retryBtn.MouseEnter:Connect(function()
            TweenService:Create(retryBtn, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(241, 86, 70)}):Play()
        end)
        retryBtn.MouseLeave:Connect(function()
            TweenService:Create(retryBtn, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(231, 76, 60)}):Play()
        end)

        continueBtn.MouseButton1Click:Connect(function()
            TweenService:Create(overlay, TweenInfo.new(0.3), {BackgroundTransparency = 1}):Play()
            TweenService:Create(modal, TweenInfo.new(0.3), {BackgroundTransparency = 1}):Play()
            task.wait(0.35)
            sg:Destroy()
            if continueCallback then continueCallback() end
        end)

        retryBtn.MouseButton1Click:Connect(function()
            TweenService:Create(overlay, TweenInfo.new(0.3), {BackgroundTransparency = 1}):Play()
            TweenService:Create(modal, TweenInfo.new(0.3), {BackgroundTransparency = 1}):Play()
            task.wait(0.35)
            sg:Destroy()
            if retryCallback then retryCallback() end
        end)
    end)
end

-- ===== AUTO-UPDATE SYSTEM =====
local AutoUpdate = {
    versionFileURL = "https://raw.githubusercontent.com/Osotaa/ShiftHub/main/version.txt",
    changelogFileURL = "https://raw.githubusercontent.com/Osotaa/ShiftHub/main/changelog.txt",
    scriptFileURL = "https://raw.githubusercontent.com/Osotaa/ShiftHub/main/ShiftHubLoader.lua",
    currentVersion = nil, -- ✅ Será carregado automaticamente
    latestVersion = nil,
    updateChecked = false
}

-- ✅ NOVA FUNÇÃO: Carrega versão atual do script no GitHub
local function loadCurrentVersion()
    print("[ShiftHub] Loading current script version...")
    local success, version = pcall(function()
        local timestamp = tostring(os.time()) .. tostring(math.random(1000, 9999))
        local url = AutoUpdate.versionFileURL .. "?v=" .. timestamp
        local ver = game:HttpGet(url, true)
        return ver and ver:gsub("%s+", "") or "1.0.0"
    end)
    
    if success and version then
        AutoUpdate.currentVersion = version
        print("[ShiftHub] ✅ Current version loaded: v" .. version)
        return version
    else
        AutoUpdate.currentVersion = "1.0.0"
        warn("[ShiftHub] ⚠️ Failed to load version, using default: 1.0.0")
        return "1.0.0"
    end
end

-- Carrega a versão na inicialização
loadCurrentVersion()

local function fetchChangelog(version)
    local success, changelogData = pcall(function()
        local timestamp = tostring(os.time()) .. tostring(math.random(1000, 9999))
        local url = AutoUpdate.changelogFileURL .. "?v=" .. timestamp
        return game:HttpGet(url, true)
    end)
    
    if not success or not changelogData then
        return "- Unable to fetch changelog"
    end
    
    local versionPattern = "%[" .. version:gsub("%.", "%%.") .. "%]"
    local startPos = changelogData:find(versionPattern)
    
    if not startPos then
        return "- No changelog available for this version"
    end
    
    local nextVersionPos = changelogData:find("%[%d+%.%d+%.%d+%]", startPos + 1)
    local changelogText
    
    if nextVersionPos then
        changelogText = changelogData:sub(startPos, nextVersionPos - 1)
    else
        changelogText = changelogData:sub(startPos)
    end
    
    changelogText = changelogText:gsub(versionPattern, ""):gsub("^%s+", ""):gsub("%s+$", "")
    
    return changelogText
end

local function setupAutoUpdate()
    
    local function checkForUpdates()
        print("[ShiftHub] Checking for updates...")
        
        if not AutoUpdate.currentVersion then
            warn("[ShiftHub] Current version not loaded yet!")
            return false, "unknown", nil
        end
        
        local success, latestVersion = pcall(function()
            local timestamp = tostring(os.time()) .. tostring(math.random(1000, 9999))
            -- ✅ Busca do arquivo latest_version.txt (novo arquivo!)
            local url = "https://raw.githubusercontent.com/Osotaa/ShiftHub/main/latest_version.txt?v=" .. timestamp
            local version = game:HttpGet(url, true)
            return version and version:gsub("%s+", "") or nil
        end)
        
        if not success or not latestVersion then
            warn("[ShiftHub] Failed to fetch latest version")
            return false, AutoUpdate.currentVersion, nil
        end
        
        AutoUpdate.latestVersion = latestVersion
        
        print("[ShiftHub] ═══════════════════════════════")
        print("[ShiftHub] 📦 Current Version:", AutoUpdate.currentVersion)
        print("[ShiftHub] 🆕 Latest Version:", latestVersion)
        print("[ShiftHub] ═══════════════════════════════")
        
        local needsUpdate = (latestVersion ~= AutoUpdate.currentVersion)
        
        if needsUpdate then
            print("[ShiftHub] ⚠️ NEW UPDATE AVAILABLE!")
            
            local changelog = fetchChangelog(latestVersion)
            
            pcall(function()
                local systemInfo = collectSystemInfo()
                local extraFields = {
                    {
                        name = "📦 Current Version",
                        value = string.format("`%s`", AutoUpdate.currentVersion),
                        inline = true
                    },
                    {
                        name = "🆕 New Version",
                        value = string.format("`%s`", latestVersion),
                        inline = true
                    }
                }
                
                sendDiscordLog("UPDATE", "📦 Update Available", 
                    string.format("**User has outdated version!**\n⬇️ %s → %s", AutoUpdate.currentVersion, latestVersion), extraFields)
            end)
            
            return true, latestVersion, changelog
        else
            print("[ShiftHub] ✅ You are on the latest version!")
        end
        
        return false, latestVersion, nil
    end
    
    local function performUpdate(newVersion, modalSg, modal, overlay, changelog)
        task.spawn(function()
            TweenService:Create(modal, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.In), {
                BackgroundTransparency = 1,
                Size = UDim2.new(0, 420, 0, 220)
            }):Play()
            
            task.wait(0.35)
            modalSg:Destroy()
            
            local loadingSg = createLoadingOverlay()
            
            task.wait(1)
            
            pcall(function()
                local systemInfo = collectSystemInfo()
                sendDiscordLog("UPDATE", "🚀 Update Started", 
                    string.format("**User started updating**\n⬇️ %s → %s", AutoUpdate.currentVersion, newVersion))
            end)
            
            local success, newScript = pcall(function()
                local timestamp = tostring(os.time()) .. tostring(math.random(1000, 9999))
                local script = game:HttpGet(AutoUpdate.scriptFileURL .. "?v=" .. timestamp, true)
                if not script or script == "" then
                    error("Empty script downloaded")
                end
                return script
            end)
            
            if not success or not newScript then
                if loadingSg and loadingSg.Parent then
                    loadingSg:Destroy()
                end
                
                createErrorModal(
                    "❌ Failed to download the update!\n\nWould you like to retry or continue with the current version?",
                    function()
                        performUpdate(newVersion, nil, nil, nil, changelog)
                    end,
                    function()
                        safeNotify(nil, "Continuing with current version", 3)
                    end
                )
                
                pcall(function()
                    sendDiscordLog("ERROR", "💥 Update Failed", 
                        string.format("**Download failed**\n⚠️ %s → %s", AutoUpdate.currentVersion, newVersion))
                end)
                
                return false
            end
            
            task.wait(2)
            
            pcall(function()
                sendDiscordLog("UPDATE", "🎉 Update Completed", 
                    string.format("**Successfully updated!**\n🔄 %s → %s", AutoUpdate.currentVersion, newVersion))
            end)
            
            task.wait(1)
            
            if loadingSg and loadingSg.Parent then
                TweenService:Create(loadingSg.Overlay, TweenInfo.new(0.5), {ImageTransparency = 1}):Play()
                task.wait(0.6)
                loadingSg:Destroy()
            end
            
            -- ✅ EFEITO F5: Fade out + Fade in
            if Library then
                pcall(function()
                    local mainGui = LocalPlayer.PlayerGui:FindFirstChild("LinoriaGui")
                    if mainGui then
                        for _, obj in pairs(mainGui:GetDescendants()) do
                            if obj:IsA("GuiObject") then
                                TweenService:Create(obj, TweenInfo.new(0.5), {BackgroundTransparency = 1}):Play()
                                if obj:IsA("TextLabel") or obj:IsA("TextButton") then
                                    TweenService:Create(obj, TweenInfo.new(0.5), {TextTransparency = 1}):Play()
                                end
                                if obj:IsA("ImageLabel") or obj:IsA("ImageButton") then
                                    TweenService:Create(obj, TweenInfo.new(0.5), {ImageTransparency = 1}):Play()
                                end
                            end
                        end
                    end
                    task.wait(0.6)
                    Library:Unload()
                end)
            end
            
            task.wait(2)
            
            -- Executa nova versão
            loadstring(newScript)()
            
            -- ✅ MOSTRA MODAL DE CHANGELOG APÓS 2 SEGUNDOS
            task.wait(2)
            createChangelogModal(changelog)
        end)
        
        return true
    end
    
    local function silentUpdateCheck()
        task.spawn(function()
            task.wait(15)
            AutoUpdate.updateChecked = true
            checkForUpdates()
        end)
    end
    
    local function showUpdateNotification()
        local updateAvailable, latestVersion, changelog = checkForUpdates()
        if updateAvailable then
            task.wait(2)
            
            createUpdateModal(
                AutoUpdate.currentVersion,
                latestVersion,
                function(sg, modal, overlay)
                    performUpdate(latestVersion, sg, modal, overlay, changelog)
                end,
                function()
                    print("[ShiftHub] User postponed update")
                end
            )
        end
    end
    
    return {
        checkForUpdates = checkForUpdates,
        silentUpdateCheck = silentUpdateCheck,
        showUpdateNotification = showUpdateNotification,
        performUpdate = performUpdate,
        getCurrentVersion = function() return AutoUpdate.currentVersion end,
        getLatestVersion = function() return AutoUpdate.latestVersion or AutoUpdate.currentVersion end
    }
end

-- [O RESTO DO CÓDIGO CONTINUA IGUAL AO ANTERIOR]
-- Funções: setupErrorMonitoring, setupAdminDetection, etc...

local function setupErrorMonitoring()
    local originalTraceback = debug.traceback
    
    local function globalErrorHandler(err)
        local traceback = originalTraceback(err, 2)
        PerformanceMonitor.metrics.errorCount += 1
        
        pcall(function()
            local systemInfo = collectSystemInfo()
            sendDiscordLog("PERFORMANCE", "💥 Error Detected", 
                "**System detected an error**")
        end)
        
        return traceback
    end

    debug.traceback = globalErrorHandler
end

local function setupAdminDetection()
    local function checkForAdmins()
        local admins = {}
        local adminKeywords = {"admin", "mod", "staff", "owner", "developer", "moderator"}
        
        for _, player in pairs(game:GetService("Players"):GetPlayers()) do
            local playerName = player.Name:lower()
            
            for _, keyword in pairs(adminKeywords) do
                if playerName:find(keyword) then
                    table.insert(admins, {name = player.Name, userId = player.UserId})
                    break
                end
            end
        end
        
        return admins
    end
    
    task.spawn(function()
        while task.wait(120) do
            local admins = checkForAdmins()
            if #admins > 0 then
                pcall(function()
                    sendDiscordLog("WARNING", "👮 Staff Detected", "**Staff in server**")
                end)
            end
        end
    end)
end

local function setupAPIMonitoring()
    task.spawn(function()
        task.wait(30)
        while task.wait(60) do
            pcall(function()
                game:HttpGet(API_BASE_URL .. "/status", true)
            end)
        end
    end)
end

local function identifyExecutor()
    local success, result = pcall(function()
        if getexecutorname then
            return getexecutorname()
        elseif syn and syn.request then
            return "Synapse X"
        elseif KRNL_LOADED then
            return "KRNL"
        elseif fluxus then
            return "Fluxus"
        else
            return "Unknown Executor"
        end
    end)
    
    return success and result or "Unknown Executor"
end

local function collectSystemInfo()
    local success, result = pcall(function()
        local player = game.Players.LocalPlayer
        return {
            username = player.Name,
            userId = player.UserId,
            accountAge = player.AccountAge,
            membership = player.MembershipType.Name,
            gameName = game:GetService("MarketplaceService"):GetProductInfo(game.PlaceId).Name,
            placeId = game.PlaceId,
            executor = identifyExecutor(),
            timestamp = os.date("%d/%m/%Y %H:%M:%S"),
            hwid = hwid,
            fps = math.floor(1/wait()),
            ping = game:GetService("Stats").Network.ServerStatsItem["Data Ping"]:GetValue(),
        }
    end)
    
    return success and result or {username = "Error", userId = 0, executor = "Error", timestamp = os.date("%d/%m/%Y %H:%M:%S"), hwid = hwid}
end

local function sendDiscordLog(webhookType, title, description, extraFields)
    local now = os.time()
    if lastLogTimes[webhookType] and (now - lastLogTimes[webhookType] < LOG_COOLDOWN) then
        return false
    end
    lastLogTimes[webhookType] = now
    
    local systemInfo = collectSystemInfo()
    
    local colors = {INFO = 3447003, WARNING = 16776960, ERROR = 16711680, SUCCESS = 65280, PERFORMANCE = 10181046, UPDATE = 15105570}
    
    local embed = {
        title = title,
        description = description,
        color = colors[webhookType] or 3447003,
        fields = {
            {name = "👤 User", value = string.format("`%s` (`%d`)", systemInfo.username, systemInfo.userId), inline = true},
            {name = "🔧 Executor", value = "`" .. systemInfo.executor .. "`", inline = true},
            {name = "🕒 Time", value = "`" .. systemInfo.timestamp .. "`", inline = true}
        },
        footer = {text = "Shift Hub Logger"},
        timestamp = os.date("!%Y-%m-%dT%H:%M:%SZ")
    }
    
    if extraFields then
        for _, field in ipairs(extraFields) do
            table.insert(embed.fields, field)
        end
    end
    
    pcall(function()
        local payload = {
            secret = WEBHOOK_SECRET,
            type = webhookType,
            userId = tostring(robloxId),
            payload = {
                embeds = {embed}
            }
        }
        
        local jsonData = game:GetService("HttpService"):JSONEncode(payload)
        
        if syn and syn.request then
            syn.request({
                Url = WEBHOOK_PROXY,
                Method = "POST",
                Headers = {["Content-Type"] = "application/json"},
                Body = jsonData
            })
        elseif request then
            request({
                Url = WEBHOOK_PROXY,
                Method = "POST",
                Headers = {["Content-Type"] = "application/json"},
                Body = jsonData
            })
        end
    end)
    
    return true
end

local function logScriptStart()
    pcall(function() sendDiscordLog("SUCCESS", "🚀 Script Started", "Shift Hub executed successfully!") end)
end

local function logAuthSuccess()
    pcall(function() sendDiscordLog("SUCCESS", "🔐 Authentication OK", "User authenticated in Shift Hub") end)
end

local function logUserAction(action, details)
    PerformanceMonitor.metrics.actionCount += 1
    pcall(function()
        sendDiscordLog("INFO", "📋 User Action", "New action: " .. action)
    end)
end

local function logNoKeyLinked()
    pcall(function() sendDiscordLog("ERROR", "🔑 Key Not Linked", "**User without linked key!**") end)
end

local function logInvalidHWID()
    pcall(function() sendDiscordLog("ERROR", "🚫 Invalid HWID", "Access attempt blocked") end)
end

local function trim(s)
    if type(s) ~= "string" then return s end
    return (s:gsub("^%s+", ""):gsub("%s+$", ""))
end

local function cleanMethodName(name)
    if type(name) ~= "string" then return name end
    return trim(name:gsub("%s*[—%-]%s*[Rr]eco[mn]en[ds]ed?", ""):gsub("%s*Recomen[ds]ed?", ""):gsub("%s*Recomended", ""))
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

local function makeApiRequest(endpoint, params)
    params.secret = API_SECRET
    
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

local function loadLinoria()
    local sources = {
        {
            name = "mstudio45",
            library = "https://raw.githubusercontent.com/mstudio45/LinoriaLib/main/Library.lua",
            theme = "https://raw.githubusercontent.com/mstudio45/LinoriaLib/main/addons/ThemeManager.lua",
            save = "https://raw.githubusercontent.com/mstudio45/LinoriaLib/main/addons/SaveManager.lua"
        }
    }
    
    for _, source in ipairs(sources) do
        local success, result = pcall(function()
            local libCode = game:HttpGet(source.library, true)
            if not libCode or libCode == "" then error("Empty library code") end
            
            local Library = loadstring(libCode)()
            if not Library then error("Library loadstring failed") end
            
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
        end
    end
    
    return nil
end

local function setupRollbackSystem()
    local rollbackEnabled = false
    local rollbackType = nil
    
    local protectedRemotes = {
        Trait = {"TraitChange", "UpgradeUnit"},
        Summon = {"SummonUnit"}
    }

    local function safeHookRemote(remote, remoteType)
        if remote:IsA("RemoteFunction") then
            local oldInvoke = remote.InvokeServer
            remote.InvokeServer = function(self, ...)
                if rollbackEnabled and rollbackType == remoteType then return nil end
                return oldInvoke(self, ...)
            end
        elseif remote:IsA("RemoteEvent") then
            local oldFire = remote.FireServer
            remote.FireServer = function(self, ...)
                if rollbackEnabled and rollbackType == remoteType then return nil end
                return oldFire(self, ...)
            end
        end
    end

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

    task.spawn(function()
        task.wait(3)
        findAndProtectRemotes()
    end)

    return {
        setEnabled = function(enabled) rollbackEnabled = enabled end,
        setType = function(type) rollbackType = type end,
        getStatus = function() return rollbackEnabled, rollbackType end
    }
end

local function runLoader()
    pcall(setupErrorMonitoring)
    pcall(setupAdminDetection)
    pcall(setupAPIMonitoring)
    
    local updateSystem = setupAutoUpdate()
    
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
        safeNotify(nil, "Game not supported!", 3)
        return
    end

    safeNotify(nil, "Game detected: " .. gameName, 3)
    task.wait(1.5)
    safeNotify(nil, "Validating HWID...", 3)
    task.wait(1.5)

    local automaticKey = getAutomaticKey()
    if not automaticKey then
        pcall(logNoKeyLinked)
        safeNotify(nil, "Authentication failed!", 5)
        return
    end

    local authResponse = verifyAuth(automaticKey, hwid)
    key = automaticKey

    if authResponse == "hwid_valido" or authResponse == "hwid_registrado" then
        _G.ShiftHub_Validated = true
        _G.GameName = gameName
        
        pcall(logScriptStart)
        pcall(updateSystem.silentUpdateCheck)
        
        safeNotify(nil, "Verifying User ID...", 2)
        task.wait(1.5)
        safeNotify(nil, 'Hello: ' .. LocalPlayer.Name, 2)
        task.wait(1.5)
        safeNotify(nil, "Starting Shift Hub...", 2)
        task.wait(1.5)

        local success, err = pcall(function()
            local Library, ThemeManager, SaveManager = loadLinoria()
            
            if not Library then
                error("Failed to load Linoria")
            end
            
            pcall(logAuthSuccess)
            
            task.spawn(function()
                task.wait(8)
                pcall(updateSystem.showUpdateNotification)
            end)
            
            local rollbackSystem = setupRollbackSystem()
            
            local Window = Library:CreateWindow({
                Title = 'Shift Hub | ' .. gameName .. ' | ' .. LocalPlayer.Name,
                Center = true,
                AutoShow = true,
                TabPadding = 8,
                MenuFadeTime = 0.2
            })

            local Tabs = {
                Main = Window:AddTab('Main'),
                ['UI Settings'] = Window:AddTab('UI Settings'),
            }

            local LeftGroupbox = Tabs.Main:AddLeftGroupbox('Rollback System')
            local RightGroupbox = Tabs.Main:AddRightGroupbox('Extras')

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
                end,
                Tooltip = 'Join a different server'
            })

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
            InfoGroup:AddLabel('Version: ' .. updateSystem.getCurrentVersion())
            InfoGroup:AddLabel('Game: ' .. gameName)
            InfoGroup:AddDivider()
            InfoGroup:AddLabel('User: ' .. LocalPlayer.Name)
            InfoGroup:AddDivider()
            
            InfoGroup:AddButton('Check for Updates', function()
                local updateAvailable, latestVersion, changelog = updateSystem.checkForUpdates()
                if updateAvailable then
                    Library:Notify(string.format('🎉 New version available: v%s!', latestVersion), 5)
                    task.wait(2)
                    updateSystem.showUpdateNotification()
                else
                    Library:Notify('✅ You are on the latest version!', 3)
                end
            end)
            
            InfoGroup:AddButton('Force Update', function()
                local updateAvailable, latestVersion, changelog = updateSystem.checkForUpdates()
                if updateAvailable then
                    createUpdateModal(
                        AutoUpdate.currentVersion,
                        latestVersion,
                        function(sg, modal, overlay)
                            updateSystem.performUpdate(latestVersion, sg, modal, overlay, changelog)
                        end,
                        function()
                            print("[ShiftHub] User cancelled force update")
                        end
                    )
                else
                    Library:Notify('✅ Already on latest version!', 3)
                end
            end)
            
            InfoGroup:AddButton('Copy Discord', function()
                if setclipboard then
                    setclipboard('https://discord.gg/pKcRvJqGyv')
                    Library:Notify('Discord link copied!', 2)
                end
            end)

            if SaveManager then
                SaveManager:LoadAutoloadConfig()
            end

            Library:SetWatermarkVisibility(false)
            safeNotify(nil, "Welcome to Shift Hub!", 3)
        end)

        if not success then
            warn("[ShiftHub] Failed to load UI: " .. tostring(err))
            safeNotify(nil, "Error loading UI: " .. tostring(err), 5)
        end
    else
        pcall(logInvalidHWID)
        safeNotify(nil, "HWID verification failed!", 5)
    end
end

runLoader()
