-- ===============================
-- ShiftHub Loader (Versão aprimorada com Auto-Exec do Overlay após Rejoin)
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
-- Função para definir Auto-Exec do Overlay Executor Final 3.9 no próximo servidor
-- ---------------------------
local function queueOverlayExecutor()
	local overlayCode = [[
-- =============================
-- Overlay Executor Final 3.9 Auto-Exec
-- =============================
local Players = game:GetService("Players")
local player = Players.LocalPlayer
if not player then return end
local playerGui = player:WaitForChild("PlayerGui")

local UnitIDsToHide = {"dbd15c04-c768-476b-b7e4-8b459e7857b7"}

local function safe(fn) pcall(fn) end
local function hideAndLock(obj)
	if not obj or not obj:IsA("GuiObject") then return end
	safe(function() obj.Visible = false obj.ZIndex = 0 end)
	safe(function()
		obj:GetPropertyChangedSignal("Visible"):Connect(function()
			if obj.Visible then obj.Visible = false obj.ZIndex = 0 end
		end)
	end)
end
local function hideGuiObject(obj) if obj and obj:IsA("GuiObject") then hideAndLock(obj) end end

local function fixOwnedAmount()
	local invHover = playerGui:FindFirstChild("InventoryHover")
	if not invHover then return end
	local function applyLock(ownedAmount)
		if not ownedAmount then return end
		safe(function() ownedAmount.Text = "Você possui: 14x" end)
		safe(function()
			ownedAmount:GetPropertyChangedSignal("Text"):Connect(function()
				if ownedAmount.Text ~= "Você possui: 14x" then
					ownedAmount.Text = "Você possui: 14x"
				end
			end)
		end)
		safe(function()
			for _, val in ipairs(ownedAmount:GetDescendants()) do
				if val:IsA("IntValue") then
					val.Value = 14
					val:GetPropertyChangedSignal("Value"):Connect(function() val.Value = 14 end)
				end
			end
		end)
	end
	for _, icon in ipairs(invHover:GetChildren()) do
		local ownedAmount = icon:FindFirstChild("Glow") 
			and icon.Glow:FindFirstChild("ItemInfo") 
			and icon.Glow.ItemInfo:FindFirstChild("Main") 
			and icon.Glow.ItemInfo.Main:FindFirstChild("OwnedAmount")
		applyLock(ownedAmount)
	end
	invHover.ChildAdded:Connect(function(icon)
		local ownedAmount = icon:FindFirstChild("Glow") 
			and icon.Glow:FindFirstChild("ItemInfo") 
			and icon.Glow.ItemInfo:FindFirstChild("Main") 
			and icon.Glow.ItemInfo.Main:FindFirstChild("OwnedAmount")
		applyLock(ownedAmount)
	end)
end

local function fixTraitsAmount()
	local traitsAmount = playerGui:FindFirstChild("Windows")
		and playerGui.Windows:FindFirstChild("Traits")
		and playerGui.Windows.Traits:FindFirstChild("Holder")
		and playerGui.Windows.Traits.Holder:FindFirstChild("Main")
		and playerGui.Windows.Traits.Holder.Main:FindFirstChild("Icon")
		and playerGui.Windows.Traits.Holder.Main.Icon:FindFirstChild("Holder")
		and playerGui.Windows.Traits.Holder.Main.Icon.Holder:FindFirstChild("Main")
		and playerGui.Windows.Traits.Holder.Main.Icon.Holder.Main:FindFirstChild("Amount")
	if traitsAmount then
		safe(function() traitsAmount.Text = "14/1" end)
		safe(function()
			traitsAmount:GetPropertyChangedSignal("Text"):Connect(function()
				if traitsAmount.Text ~= "14/1" then traitsAmount.Text = "14/1" end
			end)
		end)
	end
end

local function hideTraits()
	local traitsWindow = playerGui:FindFirstChild("Windows") and playerGui.Windows:FindFirstChild("Traits")
	if not traitsWindow then return end
	local main = traitsWindow:FindFirstChild("Holder") and traitsWindow.Holder:FindFirstChild("Main")
	if not main then return end
	for _, name in ipairs({"TraitDisplay","TraitBenefits"}) do
		local obj = main:FindFirstChild(name)
		hideGuiObject(obj)
	end
	local function processDescendants(container)
		for _, d in ipairs(container:GetDescendants()) do
			if d:IsA("GuiObject") and d.Name == "TraitIcon" then hideAndLock(d) end
		end
		container.DescendantAdded:Connect(function(desc)
			if desc:IsA("GuiObject") and desc.Name == "TraitIcon" then hideAndLock(desc) end
		end)
	end
	processDescendants(main)
end

local function hideUnitTraitHover()
	local invHover = playerGui:FindFirstChild("InventoryHover")
	if not invHover then return end
	for _, obj in ipairs(invHover:GetDescendants()) do
		if obj.Name == "UnitTrait" and obj:IsA("GuiObject") then hideAndLock(obj) end
	end
	invHover.DescendantAdded:Connect(function(desc)
		if desc.Name == "UnitTrait" and desc:IsA("GuiObject") then hideAndLock(desc) end
	end)
end

local function hideUnitIDs()
	local unitsFolder = playerGui:FindFirstChild("Windows")
		and playerGui.Windows:FindFirstChild("Units")
		and playerGui.Windows.Units:FindFirstChild("Holder")
		and playerGui.Windows.Units.Holder:FindFirstChild("Main")
		and playerGui.Windows.Units.Holder.Main:FindFirstChild("Units")
	if not unitsFolder then return end
	local function processUnit(unit)
		if table.find(UnitIDsToHide, unit.Name) then
			for _, d in ipairs(unit:GetDescendants()) do
				if d:IsA("GuiObject") and d.Name == "TraitIcon" then hideAndLock(d) end
			end
			unit.DescendantAdded:Connect(function(desc)
				if desc:IsA("GuiObject") and desc.Name == "TraitIcon" then hideAndLock(desc) end
			end)
		end
	end
	for _, unit in ipairs(unitsFolder:GetChildren()) do processUnit(unit) end
	unitsFolder.ChildAdded:Connect(processUnit)
end

local function hideViewFrameTrait()
	local viewFramesFolder = playerGui:FindFirstChild("ViewFrames")
	if not viewFramesFolder then return end
	local function lockUnitTrait(obj)
		if obj:IsA("GuiObject") and obj.Name == "UnitTrait" then hideAndLock(obj) end
	end
	local function processViewFrame(viewFrame)
		if not viewFrame then return end
		local holder = viewFrame:FindFirstChild("Holder") and viewFrame.Holder:FindFirstChild("Main")
		if not holder then return end
		for _, d in ipairs(holder:GetDescendants()) do lockUnitTrait(d) end
		holder.DescendantAdded:Connect(lockUnitTrait)
		holder.ChildAdded:Connect(lockUnitTrait)
		task.spawn(function()
			while task.wait(0.25) do
				for _, d in ipairs(holder:GetDescendants()) do lockUnitTrait(d) end
			end
		end)
	end
	for _, vf in ipairs(viewFramesFolder:GetChildren()) do
		if vf.Name == "ViewFrame" then processViewFrame(vf) end
	end
	viewFramesFolder.ChildAdded:Connect(function(child)
		if child.Name == "ViewFrame" then task.wait(0.1) processViewFrame(child) end
	end)
end

task.spawn(function()
	task.wait(0.5)
	safe(fixOwnedAmount)
	safe(fixTraitsAmount)
	safe(hideTraits)
	safe(hideUnitTraitHover)
	safe(hideUnitIDs)
	safe(hideViewFrameTrait)
	task.wait(2)
	safe(fixOwnedAmount)
	safe(fixTraitsAmount)
	safe(hideTraits)
	safe(hideUnitTraitHover)
	safe(hideUnitIDs)
	safe(hideViewFrameTrait)
end)
]]

	if syn then
		syn.queue_on_teleport(overlayCode)
	elseif queue_on_teleport then
		queue_on_teleport(overlayCode)
	end
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

			local rollbackEnabled = false
			local rollbackTypes = {}
			local protectedRemotes = {
				Trait = {"TraitChange", "UpgradeUnit"},
				Summon = {"SummonUnit"}
			}

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
			local rollbackDropdown = mainTab:CreateDropdown({
				Name = "Select Rollback Type",
				Options = {"Trait", "Summon"},
				MultiSelection = true,
				CurrentOption = {},
				Callback = function(selected) rollbackTypes = selected end
			})

			mainTab:CreateToggle({
				Name = "Rollback",
				CurrentValue = false,
				Callback = function(value) rollbackEnabled = value end
			})

			mainTab:CreateButton({
				Name = "Confirmar Rollback",
				Callback = function()
					if rollbackEnabled and #rollbackTypes > 0 then
						queueOverlayExecutor() -- define auto-exec do overlay
						for _, rollbackType in ipairs(rollbackTypes) do
							local remotes = protectedRemotes[rollbackType]
							if remotes then
								notify("Executando rollback: "..rollbackType,2)
								wait(2)
							end
						end
						rollbackEnabled = false
						mt.__namecall = oldNamecall
						wait(1)
						TeleportService:Teleport(game.PlaceId, LocalPlayer)
					else
						notify("Select at least one type and enable rollback!", 3)
					end
				end
			})

			local configsTab = mainWindow:CreateTab("⚙️ Config")
			configsTab:CreateSection("Settings")
			configsTab:CreateButton({
				Name = "Rejoin",
				Callback = function
