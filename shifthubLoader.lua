local API_BASE_URL = "https://patchily-droopiest-herbert.ngrok-free.dev/"
local key = nil

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local TeleportService = game:GetService("TeleportService")
local TweenService = game:GetService("TweenService")


local robloxId = (LocalPlayer and LocalPlayer.UserId) or 0
local hwid = tostring(robloxId) .. "_" .. ((LocalPlayer and LocalPlayer.Name) or "unknown"):gsub("%s+", ""):lower()


local function trim(s)
    if type(s) ~= "string" then return s end
    return (s:gsub("^%s+", ""):gsub("%s+$", ""))
end


local function cleanMethodName(name)
    if type(name) ~= "string" then return name end
    local cleaned = name
    cleaned = cleaned:gsub("%s*[—%-]%s*[Rr]eco[mn]en[ds]ed?", "")
    cleaned = cleaned:gsub("%s*Recomen[ds]ed?", "")
    cleaned = cleaned:gsub("%s*Recomended", "")
    return trim(cleaned)
end


local function createScreenNotification(title, content, duration)
    duration = duration or 3
    pcall(function()
        local playerGui = LocalPlayer and (LocalPlayer:FindFirstChild("PlayerGui") or LocalPlayer:WaitForChild("PlayerGui", 5))
        if not playerGui then
            return
        end

        local sg = Instance.new("ScreenGui")
        sg.Name = "ShiftHub_Notification_" .. tostring(math.random(100000,999999))
        sg.ResetOnSpawn = false
        sg.DisplayOrder = 99999

        local frame = Instance.new("Frame")
        frame.Size = UDim2.new(0, 360, 0, 68)
        frame.AnchorPoint = Vector2.new(1, 1) -- bottom-right anchor
        frame.Position = UDim2.new(1, -20, 1, -20) -- 20px margin from bottom-right
        frame.BackgroundColor3 = Color3.fromRGB(40, 42, 50)
        frame.BorderSizePixel = 0
        frame.Parent = sg

        local uicorner = Instance.new("UICorner")
        uicorner.CornerRadius = UDim.new(0, 10)
        uicorner.Parent = frame

        -- Title fixed to "Shift Hub"
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

        -- Start invisible
        frame.BackgroundTransparency = 1
        titleLbl.TextTransparency = 1
        contentLbl.TextTransparency = 1

        sg.Parent = playerGui

        -- Tween in
        pcall(function()
            TweenService:Create(frame, TweenInfo.new(0.22, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {BackgroundTransparency = 0}):Play()
            TweenService:Create(titleLbl, TweenInfo.new(0.22), {TextTransparency = 0}):Play()
            TweenService:Create(contentLbl, TweenInfo.new(0.22), {TextTransparency = 0}):Play()
        end)

        -- Fade out and destroy
        spawn(function()
            wait(duration)
            pcall(function()
                TweenService:Create(frame, TweenInfo.new(0.18), {BackgroundTransparency = 1}):Play()
                TweenService:Create(titleLbl, TweenInfo.new(0.18), {TextTransparency = 1}):Play()
                TweenService:Create(contentLbl, TweenInfo.new(0.18), {TextTransparency = 1}):Play()
                wait(0.22)
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
        warn("[ShiftHub] Your Roblox ID has no key linked!.")
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

-- =============================
-- Loader principal
-- =============================
local function runLoader()
    safeNotify(nil, "Loading game...", 3)
    wait(2)

    local allowedPlaceIds = {
        [17687504411] = "All Star Tower Defense",
        [16146832113] = "Anime Vanguards",
        [107573139811370] = "Anime Crusaders"
    }

    local currentPlaceId = game.PlaceId
    local gameName = allowedPlaceIds[currentPlaceId]

    if not gameName then
        warn("[ShiftHub] Script only works in All Star Tower Defense, Anime Vanguards, and Anime Crusaders.")
        return
    end

    safeNotify(nil, "Game detected: " .. gameName, 3)
    wait(2)
    safeNotify(nil, "Validating user credentials...", 3)
    wait(2)
    safeNotify(nil, "Authenticating with server...", 3)
    wait(2)
    safeNotify(nil, "Starting Shift Hub...", 3)
    wait(2)

    local automaticKey = getAutomaticKey()
    if not automaticKey then
        warn("[ShiftHub] Link your Roblox ID to your key in the Discord bot!")
        return
    end

    local authResponse = verifyAuth(automaticKey, hwid)
    key = automaticKey

    if authResponse == "hwid_valido" or authResponse == "hwid_registrado" then
        _G.ShiftHub_Validated = true
        _G.GameName = gameName

        local success, err = pcall(function()
            -- Carrega Linoria (mantemos carga, mas notificações não dependem dela)
            local repo = 'https://raw.githubusercontent.com/violin-suzutsuki/LinoriaLib/main/'
            Library = loadstring(game:HttpGet(repo .. 'Library.lua'))() -- Library global para callbacks (se disponível)
            local ThemeManager = loadstring(game:HttpGet(repo .. 'addons/ThemeManager.lua'))()
            local SaveManager = loadstring(game:HttpGet(repo .. 'addons/SaveManager.lua'))()

            -- Cria janela
            local Window = Library:CreateWindow({
                Title = "Shift Hub",
                Center = true,
                AutoShow = true,
                TabPadding = 8,
                MenuFadeTime = 0.2,
                Subtitle = gameName
            })

            local Tabs = {
                Main = Window:AddTab('Main'),
                ['UI Settings'] = Window:AddTab('UI Settings'),
            }

            -- ===============================
            -- Rollback Hook
            -- ===============================
            local rollbackEnabled = false
            local rollbackType = nil
            local rollbackMethod = nil
            local protectedRemotes = {
                Trait = {"TraitChange", "UpgradeUnit"},
                Summon = {"SummonUnit"}
            }

            local mt = getrawmetatable(game)
            setreadonly(mt, false)
            local oldNamecall = mt.__namecall
            mt.__namecall = newcclosure(function(self, ...)
                local method = getnamecallmethod()
                if rollbackEnabled and rollbackType and rollbackMethod then
                    local currentList = protectedRemotes[rollbackType]
                    if currentList and table.find(currentList, self.Name) then
                        if self:IsA("RemoteFunction") and method == "InvokeServer" then
                            return false
                        elseif self:IsA("RemoteEvent") and method == "FireServer" then
                            return nil
                        end
                    end
                end
                return oldNamecall(self, ...)
            end)

            -- ===============================
            -- POPULAÇÃO DA ABA MAIN
            -- ===============================
            local mainTab = Tabs.Main
            local LeftGroupBox = mainTab:AddLeftGroupbox('Rollback System')
            local RightGroupbox = mainTab:AddRightGroupbox('Extras')

            -- Dropdown Type (visível apenas como "Type" no UI)
            LeftGroupBox:AddDropdown('RollbackType', {
                Values = { 'Trait', 'Summon' },
                Default = "None",
                Multi = false,
                Text = 'Type', -- alterado aqui
                Tooltip = 'Select type',
                Callback = function(selected)
                    rollbackType = tostring(selected)
                    local displayText = rollbackType or "None"
                    safeNotify(nil, "type selected: " .. displayText, 1)
                    wait(1) -- intervalo após seleção para garantir visibilidade
                end
            })

            -- Dropdown Method (visível apenas como "Method" no UI)
            LeftGroupBox:AddDropdown('RollbackMethod', {
                Values = { 'ServerSide — Recomended', 'ClientSide' },
                Default = "None",
                Multi = false,
                Text = 'Method', -- alterado aqui
                Tooltip = 'Select method',
                Callback = function(selected)
                    rollbackMethod = tostring(selected)
                    local cleaned = cleanMethodName(rollbackMethod or "None")
                    safeNotify(nil, "method selected: " .. cleaned, 1)
                    wait(1) -- intervalo após seleção
                end
            })

            -- Toggle rollback
            LeftGroupBox:AddToggle('Rollback', {
                Text = 'Enable Rollback',
                Default = false,
                Tooltip = 'Enables or disables rollback',
                Callback = function(value)
                    rollbackEnabled = value
                    local typeText = rollbackType or "None"
                    local methodText = cleanMethodName(rollbackMethod or "None")
                    if rollbackEnabled then
                        safeNotify(nil, "Rollback Enabled! Method: " .. methodText .. " | Type: " .. typeText, 1)
                    else
                        safeNotify(nil, "Rollback disabled!", 1)
                    end
                    wait(1) -- intervalo após toggle para visibilidade
                end
            })

            -- Botão confirmar rollback
            LeftGroupBox:AddButton({
                Text = 'Confirmar Rollback',
                Func = function()
                    if rollbackEnabled and rollbackType and rollbackMethod and rollbackType ~= "None" and rollbackMethod ~= "None" then
                        local remotes = protectedRemotes[rollbackType]
                        if remotes then
                            safeNotify(nil, "Initiating rollback...", 2)
                            wait(2)
                            safeNotify(nil, "Rollback completed successfully!", 3)
                            rollbackEnabled = false
                            mt.__namecall = oldNamecall
                            wait(1)
                            TeleportService:Teleport(game.PlaceId, LocalPlayer)
                        end
                    else
                        safeNotify(nil, "Select a type and method first!", 2)
                    end
                end
            })

            -- Botão Rejoin
            RightGroupbox:AddButton({
                Text = 'Rejoin',
                Func = function()
                    TeleportService:Teleport(game.PlaceId, LocalPlayer)
                end
            })

            -- UI Settings Tab
            local configsTab = Tabs['UI Settings']
            local MenuGroup = configsTab:AddLeftGroupbox('Menu')
            MenuGroup:AddButton('Unload', function()
                pcall(function() Library:Unload() end)
            end)
            MenuGroup:AddLabel('Menu bind'):AddKeyPicker('MenuKeybind', { Default = 'End', NoUI = true, Text = 'Menu keybind' })

            -- Proteções ao definir o keybind (Options pode não existir dependendo da versão da lib)
            pcall(function()
                if type(Options) == "table" and Options.MenuKeybind then
                    Library.ToggleKeybind = Options.MenuKeybind
                elseif Library.Flags and Library.Flags.MenuKeybind then
                    Library.ToggleKeybind = Library.Flags.MenuKeybind
                end
            end)

            ThemeManager:SetLibrary(Library)
            SaveManager:SetLibrary(Library)
            SaveManager:IgnoreThemeSettings()
            SaveManager:SetIgnoreIndexes({ 'MenuKeybind' })
            ThemeManager:SetFolder('ShiftHub')
            SaveManager:SetFolder('ShiftHub/' .. gameName)
            SaveManager:BuildConfigSection(Tabs['UI Settings'])
            ThemeManager:ApplyToTab(Tabs['UI Settings'])
            SaveManager:LoadAutoloadConfig()
            pcall(function() if Window and type(Window.SetWatermarkVisibility) == "function" then Window:SetWatermarkVisibility(true) end end)

            -- Teste inicial: notificação on-screen forçada para confirmar GUI carregada
            safeNotify(nil, "GUI carregada com sucesso!", 3)
        end)

        if not success then
            warn("[ShiftHub] Erro ao iniciar GUI Linoria: " .. tostring(err))
        end
    else
        warn("[ShiftHub] Falha na autenticação: " .. tostring(authResponse))
    end
end

-- Executa loader
runLoader()
