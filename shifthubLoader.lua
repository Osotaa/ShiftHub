-- SHIFTHUB AUTO LOADER V2 (com GUI Rayfield integrada)
print("Iniciando Shift Hub by Osotaa")

-- === CONFIGURAÇÕES ===
local API_URL_BASE = "https://patchily-droopiest-herbert.ngrok-free.dev"
local API_SECRET = "Xota321"
local DISCORD_ID = nil

-- === FUNÇÕES AUXILIARES ===
local function trim(s)
    if not s then return "" end
    return s:gsub("^%s+", ""):gsub("%s+$", "")
end

local function getHwid()
    local hwid = ""
    local hwid_functions = {gethwid, get_hwid}
    for _, func in ipairs(hwid_functions) do
        if func then
            local ok, result = pcall(func)
            if ok and result and result ~= "" then
                hwid = tostring(result)
                break
            end
        end
    end
    if hwid == "" or hwid == "Unknown" then
        local Players = game:GetService("Players")
        local HttpService = game:GetService("HttpService")
        local user_name = Players.LocalPlayer.Name
        local computer_name = HttpService:GenerateGUID(false)
        hwid = user_name .. "_" .. computer_name
    end
    return tostring(hwid):gsub(" ", "_"):sub(1, 64)
end

local function getKeyByRobloxId()
    local Players = game:GetService("Players")
    local userId = tostring(Players.LocalPlayer.UserId)
    local url = string.format("%s/get-key-by-roblox?robloxId=%s&secret=%s", API_URL_BASE, userId, API_SECRET)
    local ok, result = pcall(function() return game:HttpGet(url, true) end)
    if ok and result and result ~= "no_key_found" and #trim(result) == 16 then
        return trim(result)
    end
    return nil
end

local function verifyKey(script_key, hwid)
    local url = string.format("%s/verify?key=%s&hwid=%s&secret=%s", API_URL_BASE, script_key, hwid, API_SECRET)
    local ok, res = pcall(function() return game:HttpGet(url, true) end)
    if not ok then return nil, "connection_error" end
    local response = (res or ""):gsub("'", ""):gsub('"', ""):lower()
    return response, nil
end

local function notify(title, text, duration)
    pcall(function()
        game.StarterGui:SetCore("SendNotification", {Title = title, Text = text, Duration = duration or 5})
    end)
end

-- === AUTENTICAÇÃO ===
local script_key = getKeyByRobloxId() or _G.ShiftHub_CachedKey
if not script_key or #script_key ~= 16 then
    notify("ShiftHub", "❌ Nenhuma key encontrada", 10)
    error("[ShiftHub] Obtenha sua key no Discord.")
end

local user_hwid = getHwid()
local response, err = verifyKey(script_key, user_hwid)
if not response then
    notify("ShiftHub", "❌ Erro de conexão", 10)
    error("[ShiftHub] Falha na conexão ("..tostring(err)..")")
end

if response ~= "hwid_valido" and response ~= "hwid_registrado" then
    notify("ShiftHub", "❌ Erro: "..tostring(response), 10)
    error("[ShiftHub] Falha na autenticação: "..tostring(response))
end

_G.ShiftHub_Validated = true
notify("ShiftHub", "✅ Autenticado com sucesso!", 3)

-----------------------------------------------------
-- === SCRIPT PRINCIPAL (Rayfield GUI Integrado) ===
-----------------------------------------------------
if not _G.ShiftHub_Validated then
    error("Erro: Acesso não autorizado. Execute o Loader para iniciar.")
    return
end

-- IDs permitidos
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
    warn("Script only works in All Star Tower Defense And Anime Vanguards!")
    return
end

local UserInputService = game:GetService("UserInputService")
local TeleportService = game:GetService("TeleportService")

function openMainWindow()
    local Rayfield2 = loadstring(game:HttpGet('https://raw.githubusercontent.com/oxotaa/teste/refs/heads/main/source2.lua'))()

    local mainWindow = Rayfield2:CreateWindow({
        Name = "Shift Hub",
        LoadingTitle = "Shift Hub",
        LoadingSubtitle = "",
        ConfigurationSaving = {Enabled = false},
        KeySystem = false
    })

    local mainTab = mainWindow:CreateTab("🏠 Main")
    mainTab:CreateSection("Welcome to Shift Hub!")

    local rollbackEnabled = false

    -- Hook rollback seguro
    local mt = getrawmetatable(game)
    setreadonly(mt, false)
    local oldNamecall = mt.__namecall
    mt.__namecall = newcclosure(function(self, ...)
        local method = getnamecallmethod()
        if rollbackEnabled and (self:IsA("RemoteEvent") or self:IsA("RemoteFunction")) then
            if self:IsA("RemoteFunction") and method == "InvokeServer" then
                return false
            else
                return nil
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
                Rayfield2:Notify({Title = "Rollback", Content = "Ativado!", Duration = 3})
            else
                Rayfield2:Notify({Title = "Rollback", Content = "Desativado!", Duration = 3})
            end
        end
    })

    mainTab:CreateButton({
        Name = "Confirm Rollback",
        Callback = function()
            if rollbackEnabled then
                Rayfield2:Notify({Title = "Rollback", Content = "Carregando...", Duration = 3})
                wait(6)
                Rayfield2:Notify({Title = "Rollback", Content = "Feito com sucesso.", Duration = 3})
                wait(3)
                TeleportService:Teleport(game.PlaceId, game.Players.LocalPlayer)
            else
                Rayfield2:Notify({Title = "Erro", Content = "Rollback não está ativado.", Duration = 3})
            end
        end
    })

    local configsTab = mainWindow:CreateTab("⚙️ Config")
    configsTab:CreateSection("Settings")

    configsTab:CreateButton({
        Name = "Rejoin",
        Callback = function()
            TeleportService:Teleport(game.PlaceId, game.Players.LocalPlayer)
        end
    })

    local bindKey = nil
    local listeningForBind = false
    local bindLabel = configsTab:CreateLabel({Name = "Current Bind: None"})

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
            bindLabel:SetText("Current Bind: " .. tostring(bindKey.Name))
        elseif bindKey and input.UserInputType == Enum.UserInputType.Keyboard and input.KeyCode == bindKey then
            mainWindow.Visible = not mainWindow.Visible
        end
    end)

    mainWindow.Visible = true
end

openMainWindow()
