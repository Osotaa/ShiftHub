-- =============================
-- Overlay Executor Final 3.9 (Client-only, otimizado, protege TraitIcon e OwnedAmount travado)
-- =============================
local Players = game:GetService("Players")
local player = Players.LocalPlayer
if not player then return end
local playerGui = player:WaitForChild("PlayerGui")

local UnitIDsToHide = {"a5ecef1b-73fa-435b-a9fb-400809a4af53"}

-- =============================
-- Helpers
-- =============================
local function safe(fn) pcall(fn) end

local function hideAndLock(obj)
    if not obj or not obj:IsA("GuiObject") then return end
    safe(function()
        obj.Visible = false
        obj.ZIndex = 0
    end)
    safe(function()
        obj:GetPropertyChangedSignal("Visible"):Connect(function()
            if obj.Visible then
                obj.Visible = false
                obj.ZIndex = 0
            end
        end)
    end)
end

local function hideGuiObject(obj)
    if obj and obj:IsA("GuiObject") then hideAndLock(obj) end
end

-- =============================
-- Travar OwnedAmount
-- =============================
local function fixOwnedAmount()
    local invHover = playerGui:FindFirstChild("InventoryHover")
    if not invHover then return end

    local function applyLock(ownedAmount)
        if not ownedAmount then return end
        safe(function() ownedAmount.Text = "Você possui: 15x" end)

        -- monitorar Text
        safe(function()
            ownedAmount:GetPropertyChangedSignal("Text"):Connect(function()
                if ownedAmount.Text ~= "Você possui: 15x" then
                    ownedAmount.Text = "Você possui: 15x"
                end
            end)
        end)

        -- monitorar qualquer IntValue interno que possa atualizar o texto
        safe(function()
            for _, val in ipairs(ownedAmount:GetDescendants()) do
                if val:IsA("IntValue") then
                    val.Value = 15
                    val:GetPropertyChangedSignal("Value"):Connect(function()
                        val.Value = 15
                    end)
                end
            end
        end)
    end

    -- Aplica lock em OwnedAmount existente
    for _, icon in ipairs(invHover:GetChildren()) do
        local ownedAmount = icon:FindFirstChild("Glow") 
            and icon.Glow:FindFirstChild("ItemInfo") 
            and icon.Glow.ItemInfo:FindFirstChild("Main") 
            and icon.Glow.ItemInfo.Main:FindFirstChild("OwnedAmount")
        applyLock(ownedAmount)
    end

    -- Listener para novos Icon adicionados
    safe(function()
        invHover.ChildAdded:Connect(function(icon)
            local ownedAmount = icon:FindFirstChild("Glow") 
                and icon.Glow:FindFirstChild("ItemInfo") 
                and icon.Glow.ItemInfo:FindFirstChild("Main") 
                and icon.Glow.ItemInfo.Main:FindFirstChild("OwnedAmount")
            applyLock(ownedAmount)
        end)
    end)
end

-- =============================
-- Atualiza quantidade de Traits (display)
-- =============================
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
        safe(function() traitsAmount.Text = "15/1" end)
        safe(function()
            traitsAmount:GetPropertyChangedSignal("Text"):Connect(function()
                if traitsAmount.Text ~= "15/1" then
                    traitsAmount.Text = "15/1"
                end
            end)
        end)
    end
end

-- =============================
-- Esconde TraitIcon e UnitTrait
-- =============================
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
            if d:IsA("GuiObject") and d.Name == "TraitIcon" then
                hideAndLock(d)
            end
        end
        container.DescendantAdded:Connect(function(desc)
            if desc:IsA("GuiObject") and desc.Name == "TraitIcon" then
                hideAndLock(desc)
            end
        end)
    end

    processDescendants(main)
end

-- =============================
-- Esconde UnitTrait do InventoryHover
-- =============================
local function hideUnitTraitHover()
    local invHover = playerGui:FindFirstChild("InventoryHover")
    if not invHover then return end
    for _, obj in ipairs(invHover:GetDescendants()) do
        if obj.Name == "UnitTrait" and obj:IsA("GuiObject") then
            hideAndLock(obj)
        end
    end
    invHover.DescendantAdded:Connect(function(desc)
        if desc.Name == "UnitTrait" and desc:IsA("GuiObject") then
            hideAndLock(desc)
        end
    end)
end

-- =============================
-- Esconde TraitIcon de Units específicas
-- =============================
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
                if d:IsA("GuiObject") and d.Name == "TraitIcon" then
                    hideAndLock(d)
                end
            end
            unit.DescendantAdded:Connect(function(desc)
                if desc:IsA("GuiObject") and desc.Name == "TraitIcon" then
                    hideAndLock(desc)
                end
            end)
        end
    end

    for _, unit in ipairs(unitsFolder:GetChildren()) do
        processUnit(unit)
    end

    unitsFolder.ChildAdded:Connect(processUnit)
end

-- =============================
-- Esconde ViewFrame.UnitTrait de forma definitiva
-- =============================
local function hideViewFrameTrait()
    local viewFramesFolder = playerGui:FindFirstChild("ViewFrames")
    if not viewFramesFolder then return end

    local function lockUnitTrait(obj)
        if obj:IsA("GuiObject") and obj.Name == "UnitTrait" then
            hideAndLock(obj)
        end
    end

    local function processViewFrame(viewFrame)
        if not viewFrame then return end
        local holder = viewFrame:FindFirstChild("Holder") and viewFrame.Holder:FindFirstChild("Main")
        if not holder then return end

        -- tranca descendentes atuais
        for _, d in ipairs(holder:GetDescendants()) do
            lockUnitTrait(d)
        end

        -- listeners para novos descendentes
        holder.DescendantAdded:Connect(lockUnitTrait)
        holder.ChildAdded:Connect(lockUnitTrait)

        -- loop leve de backup
        task.spawn(function()
            while task.wait(0.25) do
                for _, d in ipairs(holder:GetDescendants()) do
                    lockUnitTrait(d)
                end
            end
        end)
    end

    -- processa ViewFrames existentes
    for _, vf in ipairs(viewFramesFolder:GetChildren()) do
        if vf.Name == "ViewFrame" then
            processViewFrame(vf)
        end
    end

    -- listener para novos ViewFrames (quando abrir tela de visualização)
    viewFramesFolder.ChildAdded:Connect(function(child)
        if child.Name == "ViewFrame" then
            task.wait(0.1)
            processViewFrame(child)
        end
    end)
end

-- =============================
-- Execução otimizada
-- =============================
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
