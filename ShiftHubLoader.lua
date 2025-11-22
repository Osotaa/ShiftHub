local API_BASE_URL = "http://51.75.118.149:20029/"
local key = nil

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local TeleportService = game:GetService("TeleportService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local robloxId = (LocalPlayer and LocalPlayer.UserId) or 0
local hwid = tostring(robloxId) .. "_" .. ((LocalPlayer and LocalPlayer.Name) or "unknown"):gsub("%s+", ""):lower()

-- ===== FUNÇÕES AUXILIARES =====
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

-- ===== API FUNCTIONS =====
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
        warn("[ShiftHub] Your Roblox ID has no key linked!")
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

-- ===== FUNÇÃO PARA CARREGAR LINORIA COM FALLBACKS =====
local function loadLinoria()
    local sources = {
        {
            name = "mstudio45",
            library = "https://raw.githubusercontent.com/mstudio45/LinoriaLib/main/Library.lua",
            theme = "https://raw.githubusercontent.com/mstudio45/LinoriaLib/main/addons/ThemeManager.lua",
            save = "https://raw.githubusercontent.com/mstudio45/LinoriaLib/main/addons/SaveManager.lua"
        },
        {
            name = "violin-suzutsuki",
            library = "https://raw.githubusercontent.com/violin-suzutsuki/LinoriaLib/main/Library.lua",
            theme = "https://raw.githubusercontent.com/violin-suzutsuki/LinoriaLib/main/addons/ThemeManager.lua",
            save = "https://raw.githubusercontent.com/violin-suzutsuki/LinoriaLib/main/addons/SaveManager.lua"
        },
        {
            name = "ActualMasterOogway",
            library = "https://raw.githubusercontent.com/ActualMasterOogway/Linoria-Library/main/Library.lua",
            theme = "https://raw.githubusercontent.com/ActualMasterOogway/Linoria-Library/main/addons/ThemeManager.lua",
            save = "https://raw.githubusercontent.com/ActualMasterOogway/Linoria-Library/main/addons/SaveManager.lua"
        }
    }
    
    for _, source in ipairs(sources) do
        local success, result = pcall(function()
            local libCode = game:HttpGet(source.library, true)
            if not libCode or libCode == "" then
                error("Empty library code")
            end
            
            local Library = loadstring(libCode)()
            if not Library then
                error("Library loadstring failed")
            end
            
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
        else
            warn("[ShiftHub] Failed to load from " .. source.name .. ": " .. tostring(result))
        end
    end
    
    return nil
end

-- ===== SISTEMA DE ROLLBACK OTIMIZADO =====
local function setupRollbackSystem()
    local rollbackEnabled = false
    local rollbackType = nil
    
    local protectedRemotes = {
        Trait = {"TraitChange", "UpgradeUnit"},
        Summon = {"SummonUnit"}
    }

    -- Sistema mais seguro que não interfere com a UI
    local function safeHookRemote(remote, remoteType)
        if remote:IsA("RemoteFunction") then
            local oldInvoke = remote.InvokeServer
            local newInvoke = function(self, ...)
                if rollbackEnabled and rollbackType == remoteType then
                    return nil
                end
                return oldInvoke(self, ...)
            end
            remote.InvokeServer = newInvoke
        elseif remote:IsA("RemoteEvent") then
            local oldFire = remote.FireServer
            local newFire = function(self, ...)
                if rollbackEnabled and rollbackType == remoteType then
                    return nil
                end
                return oldFire(self, ...)
            end
            remote.FireServer = newFire
        end
    end

    -- Encontrar e proteger os remotes específicos
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

    -- Executar após um delay para não travar a UI
    task.spawn(function()
        task.wait(3) -- Esperar a UI carregar primeiro
        findAndProtectRemotes()
    end)

    return {
        setEnabled = function(enabled)
            rollbackEnabled = enabled
        end,
        setType = function(type)
            rollbackType = type
        end,
        getStatus = function()
            return rollbackEnabled, rollbackType
        end
    }
end

-- ===== LOADER PRINCIPAL =====
local function runLoader()
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
        warn("[ShiftHub] Script only works in allowed games.")
        safeNotify(nil, "Game not supported!", 3)
        return
    end

    safeNotify(nil, "Game detected: " .. gameName, 3)
    task.wait(1.5)
    safeNotify(nil, "Validating HWID...", 3)
    task.wait(1.5)

    local automaticKey = getAutomaticKey()
    if not automaticKey then
        warn("[ShiftHub] Link your Roblox ID to your key!")
        safeNotify(nil, "Authentication failed!", 5)
        return
    end

    local authResponse = verifyAuth(automaticKey, hwid)
    key = automaticKey

    if authResponse == "hwid_valido" or authResponse == "hwid_registrado" then
        _G.ShiftHub_Validated = true
        _G.GameName = gameName
        
        safeNotify(nil, "Verifying User ID...", 2)
        task.wait(1.5)
        safeNotify(nil, 'Hello: ' .. LocalPlayer.Name, 2)
        task.wait(1.5)
        safeNotify(nil, "Starting Shift Hub...", 2)
        task.wait(1.5)

        local success, err = pcall(function()
            local Library, ThemeManager, SaveManager = loadLinoria()
            
            if not Library then
                error("Failed to load Linoria from all sources. Your firewall may be blocking GitHub.")
            end
            
            -- Inicializar sistema de rollback
            local rollbackSystem = setupRollbackSystem()
            
            -- Criar janela com título personalizado
            local Window = Library:CreateWindow({
                Title = 'Shift Hub | ' .. gameName .. ' | ' .. LocalPlayer.Name,
                Center = true,
                AutoShow = true,
                TabPadding = 8,
                MenuFadeTime = 0.2
            })

            -- Criar abas
            local Tabs = {
                Main = Window:AddTab('Main'),
                ['UI Settings'] = Window:AddTab('UI Settings'),
            }

            -- Criar elementos UI
            local LeftGroupbox = Tabs.Main:AddLeftGroupbox('Rollback System')
            local RightGroupbox = Tabs.Main:AddRightGroupbox('Extras')

            -- Dropdown de Tipo
            LeftGroupbox:AddDropdown('RollbackType', {
                Values = {'Trait', 'Summon(Patched)'},
                Default = 1,
                Multi = false,
                Text = 'Rollback Type',
                Tooltip = 'Select the type of rollback',
                Callback = function(Value)
                    rollbackSystem.setType(Value)
                    safeNotify(nil, "Type selected: " .. Value, 1)
                end
            })

            -- Dropdown de Método
            LeftGroupbox:AddDropdown('RollbackMethod', {
                Values = {'ServerSide - Recommended', 'ClientSide'},
                Default = 1,
                Multi = false,
                Text = 'Rollback Method',
                Tooltip = 'Select the rollback method',
                Callback = function(Value)
                    local cleaned = cleanMethodName(Value)
                    safeNotify(nil, "Method selected: " .. cleaned, 1)
                end
            })

            LeftGroupbox:AddDivider()

            -- Toggle de Rollback
            LeftGroupbox:AddToggle('RollbackToggle', {
                Text = 'Enable Rollback',
                Default = false,
                Tooltip = 'Enable or disable rollback protection',
                Callback = function(Value)
                    rollbackSystem.setEnabled(Value)
                    local enabled, type = rollbackSystem.getStatus()
                    if enabled then
                        safeNotify(nil, "Rollback Enabled! Type: " .. (type or "None"), 2)
                    else
                        safeNotify(nil, "Rollback disabled!", 1)
                    end
                end
            })

            LeftGroupbox:AddDivider()

            -- Botão de Confirmar Rollback
            LeftGroupbox:AddButton({
                Text = 'Confirm Rollback',
                Func = function()
                    local enabled, type = rollbackSystem.getStatus()
                    if enabled and type then
                        safeNotify(nil, "Initiating rollback...", 2)
                        task.wait(2)
                        safeNotify(nil, "Rollback completed successfully!", 3)
                        rollbackSystem.setEnabled(false)
                        task.wait(1)
                        TeleportService:Teleport(game.PlaceId, LocalPlayer)
                    else
                        safeNotify(nil, "Select a type and enable rollback first!", 2)
                    end
                end,
                Tooltip = 'Execute the rollback and rejoin'
            })

            -- Groupbox de Extras
            RightGroupbox:AddLabel('Server Actions')
            RightGroupbox:AddDivider()

            RightGroupbox:AddButton({
                Text = 'Rejoin Server',
                Func = function()
                    safeNotify(nil, "Rejoining server...", 2)
                    task.wait(1)
                    TeleportService:Teleport(game.PlaceId, LocalPlayer)
                end,
                Tooltip = 'Rejoin the current server'
            })

            RightGroupbox:AddButton({
                Text = 'Server Hop',
                Func = function()
                    safeNotify(nil, "Server hopping...", 2)
                    -- Código de server hop aqui
                end,
                Tooltip = 'Join a different server'
            })

            -- ADICIONAR MAIS FUNCIONALIDADES NA ABA MAIN
            
            -- Groupbox de Summon & Units
-- Groupbox de Summon & Units SOMENTE PARA ANIME CRUSADERS
-- ADICIONAR MAIS FUNCIONALIDADES NA ABA MAIN

            
            -- Groupbox de Combat
            local CombatBox = Tabs.Main:AddRightGroupbox('Units Enhancements')
            
            CombatBox:AddToggle('InfiniteRange', {
                Text = 'Infinite Range (Patched)',
                Default = false,
                Tooltip = 'Units attack from anywhere on map',
                Callback = function(Value)
                    safeNotify(nil, Value and "Infinite Range ON!" or "Infinite Range OFF!", 1)
                end
            })
            
            CombatBox:AddToggle('NoCooldown', {
                Text = 'No Cooldown (Patched)',
                Default = false,
                Tooltip = 'Remove ability cooldowns',
                Callback = function(Value)
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
                    safeNotify(nil, "Damage: " .. Value .. "x", 1)
                end
            })
            
            -- Nova aba de Misc
            local MiscTab = Window:AddTab('Misc')
            
            local MiscLeft = MiscTab:AddLeftGroupbox('Player Modifications')
            
            MiscLeft:AddToggle('SpeedHack', {
                Text = 'Speed Hack',
                Default = false,
                Tooltip = 'Increase player walk speed',
                Callback = function(Value)
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
                    safeNotify(nil, "WalkSpeed: " .. Value, 1)
                end
            })
            
            -- UI Settings
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

            -- Configurar o keybind corretamente
            UserInputService.InputBegan:Connect(function(input, gpe)
    if gpe then return end
    if input.KeyCode == Options.MenuKeybind.Value then
        Library:ToggleUI()
    end
end)


            MenuGroup:AddButton('Unload Script', function() 
                Library:Unload() 
                safeNotify(nil, "Script unloaded!", 2)
            end)

            MenuGroup:AddDivider()

            local InfoGroup = Tabs['UI Settings']:AddRightGroupbox('Information')
            InfoGroup:AddLabel('Script: Shift Hub 🫦')
            InfoGroup:AddLabel('Version: 1.0.0')
            InfoGroup:AddLabel('Game: ' .. gameName)
            InfoGroup:AddDivider()
            InfoGroup:AddLabel('User: ' .. LocalPlayer.Name)
            InfoGroup:AddDivider()
            InfoGroup:AddButton('Copy Discord', function()
                if setclipboard then
                    setclipboard('https://discord.gg/pKcRvJqGyv')
                    Library:Notify('Discord link copied!', 2)
                end
            end)
            InfoGroup:AddButton('Join Discord Server', function()
                Library:Notify('Opening Discord invite...', 2)
            end)

            if SaveManager then
                SaveManager:LoadAutoloadConfig()
            end

            Library:SetWatermarkVisibility(false)
            safeNotify(nil, "Welcome to Shift Hub!", 3)
        end)

        if not success then
            warn("[ShiftHub] Failed to load Linoria: " .. tostring(err))
            safeNotify(nil, "Error loading UI: " .. tostring(err), 5)
        end
    else
        safeNotify(nil, "HWID verification failed!", 5)
    end
end

-- ===== EXECUTA LOADER =====
runLoader()
