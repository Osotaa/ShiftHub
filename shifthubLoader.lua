-- ===============================
-- ShiftHub Loader (Versão aprimorada)
-- ===============================
local API_BASE_URL = "https://patchily-droopiest-herbert.ngrok-free.dev/"
local key = nil

-- Serviços
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local StarterGui = game:GetService("StarterGui")
local TweenService = game:GetService("TweenService")
local TeleportService = game:GetService("TeleportService")
local UserInputService = game:GetService("UserInputService")

-- Identificação do usuário
local robloxId = LocalPlayer.UserId
local hwid = tostring(robloxId) .. "_" .. LocalPlayer.Name:gsub("%s+", ""):lower()

-- Função de notificação
local function notify(message, duration)
	duration = duration or 2
	StarterGui:SetCore("SendNotification", {
		Title = "Shift Hub",
		Text = message,
		Duration = duration
	})
end

-- Função para requisição à API
local function makeApiRequest(endpoint, params)
	local clean_base_url = API_BASE_URL:gsub("/$", "")
	local query_string = ""
	for k, v in pairs(params) do
		query_string = query_string .. string.format("%s=%s&", k, v)
	end
	query_string = query_string:sub(1, #query_string - 1)
	local url = string.format("%s/%s?%s", clean_base_url, endpoint, query_string)

	local success, response = pcall(function()
		return game:HttpGet(url, true)
	end)

	if not success then
		warn("API communication error.")
		return "erro_comunicacao"
	end
	return response
end

local function getAutomaticKey()
	local response = makeApiRequest("get-key-by-roblox", { robloxId = robloxId })
	if response == "no_key_found" then
		warn("Your Roblox ID has no key linked!.")
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

-- ---------------------------
-- Loader principal
-- ---------------------------
local function runLoader()
	notify("Loading game...", 2)
	wait(1)

	local allowedPlaceIds = {
		[17687504411] = "All Star Tower Defense",
		[16146832113] = "Anime Vanguards"
	}

	local currentPlaceId = game.PlaceId
	local gameName = allowedPlaceIds[currentPlaceId]

	if not gameName then
		warn("Script only works in All Star Tower Defense and Anime Vanguards.")
		return
	end

	notify("Game detected: " .. gameName, 2)
	wait(1)
	notify("Starting Shift Hub...")

	local automaticKey = getAutomaticKey()
	if not automaticKey then
		warn("Link your Roblox ID to your key in the Discord bot!")
		return
	end

	local authResponse = verifyAuth(automaticKey, hwid)
	key = automaticKey

	if authResponse == "hwid_valido" or authResponse == "hwid_registrado" then
		_G.ShiftHub_Validated = true
		_G.GameName = gameName

		local success, err = pcall(function()
			local Rayfield = loadstring(game:HttpGet("https://raw.githubusercontent.com/Osotaa/teste/refs/heads/main/source2.lua"))()

			local mainWindow = Rayfield:CreateWindow({
				Name = "Shift Hub",
				LoadingTitle = "Shift Hub",
				LoadingSubtitle = "By osotaa",
				ConfigurationSaving = { Enabled = false },
				KeySystem = false
			})

			local mainTab = mainWindow:CreateTab("🏠 Main")
			mainTab:CreateSection("Welcome to Shift Hub!")

			-- ===============================
			-- Sistema de Rollback
			-- ===============================
			local rollbackEnabled = false
			local rollbackTypes = {}
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
					for _, rollbackType in ipairs(rollbackTypes) do
						local currentList = protectedRemotes[rollbackType]
						if currentList and table.find(currentList, self.Name) then
							if self:IsA("RemoteFunction") and method == "InvokeServer" then
								return false
							elseif self:IsA("RemoteEvent") and method == "FireServer" then
								return nil
							end
						end
					end
				end
				return oldNamecall(self, ...)
			end)

			mainTab:CreateSection("Rollback System")

			-- Dropdown multi-seleção + animação
			local rollbackDropdown = mainTab:CreateDropdown({
				Name = "Select Rollback Type",
				Options = {"Trait", "Summon"},
				MultiSelection = true,
				CurrentOption = {},
				Callback = function(selected)
					rollbackTypes = selected
					local selectionText = type(selected) == "table" and table.concat(selected, ", ") or tostring(selected)
					Rayfield:Notify({
						Title = "Rollback Type",
						Content = "Selected: " .. selectionText,
						Duration = 3
					})
				end
			})

			-- Fade-in suave
			task.wait(0.5)
			local dropdownFrame
			pcall(function()
				for _, gui in pairs(LocalPlayer:WaitForChild("PlayerGui"):GetDescendants()) do
					if gui:IsA("Frame") and gui.Name:lower():find("dropdown") then
						dropdownFrame = gui
					end
				end
			end)

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
						TweenService:Create(obj, TweenInfo.new(0.3, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {
							BackgroundTransparency = 0
						}):Play()
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

			-- Toggle rollback
			mainTab:CreateToggle({
				Name = "Rollback",
				CurrentValue = false,
				Callback = function(value)
					rollbackEnabled = value
					if rollbackEnabled then
						Rayfield:Notify({
							Title = "Rollback",
							Content = "Rollback enabled! Type: " .. (#rollbackTypes > 0 and table.concat(rollbackTypes, ", ") or "nenhum selecionado"),
							Duration = 3
						})
					else
						Rayfield:Notify({
							Title = "Rollback",
							Content = "Rollback disabled!",
							Duration = 3
						})
					end
				end
			})

			-- Botão confirmar rollback
			mainTab:CreateButton({
				Name = "Confirmar Rollback",
				Callback = function()
					if rollbackEnabled and #rollbackTypes > 0 then
						for _, rollbackType in ipairs(rollbackTypes) do
							local remotes = protectedRemotes[rollbackType]
							if remotes then
								Rayfield:Notify({
									Title = "Rollback",
									Content = "Executando rollback ("..rollbackType..")...",
									Duration = 2
								})
								wait(2)
							end
						end
						Rayfield:Notify({
							Title = "Rollback",
							Content = "Rollback completed successfully!",
							Duration = 3
						})
						rollbackEnabled = false
						mt.__namecall = oldNamecall
						wait(1)
						TeleportService:Teleport(game.PlaceId, LocalPlayer)
					else
						Rayfield:Notify({
							Title = "Erro",
							Content = "Select at least one type and enable rollback!",
							Duration = 3
						})
					end
				end
			})

			-- ===============================
			-- Config Tab
			-- ===============================
			local configsTab = mainWindow:CreateTab("⚙️ Config")
			configsTab:CreateSection("Settings")

			configsTab:CreateButton({
				Name = "Rejoin",
				Callback = function()
					TeleportService:Teleport(game.PlaceId, LocalPlayer)
				end
			})

			-- Remove interface de bind de tecla
			-- (Não há mais botão nem label de bind)

			mainWindow.Visible = true
		end)

		if not success then
			warn("Erro ao iniciar GUI Rayfield: " .. err)
		end
	else
		warn("Falha na autenticação: " .. tostring(authResponse))
	end
end

-- Executa loader
runLoader()
