Loadouts.UI = Loadouts.UI or {}
local AceGUI = LibStub("AceGUI-3.0")

local isOpen = false

local function getContext()
    return {
        ["equipmentSets"] = Loadouts.Lib.getEquipmentSets(),
    }
end

local function tableLength(t)
    local count = 0
    for _, _ in pairs(t) do
        count = count + 1
    end
    return count
end

local mainHandItems = {
    19019, -- Thunderfury
    17182, -- Sulfuras
}

-- local variable to track the selected main-hand item
local selectedMainHandItem = nil

local function CreateMainHandButton(parent, onItemSelected)
    local btn = CreateFrame("Button", "LoadoutMainHandButton", parent, "ItemButtonTemplate")
    btn:SetSize(40, 40)

    -- safe reference to icon texture
    btn.icon = btn.IconTexture or btn.icon
    btn.icon:SetTexture(134400) -- default "?" icon
    btn.itemID = selectedMainHandItem -- initialize to the selected item

    -- Dropdown frame
    local dropdown = CreateFrame("Frame", nil, btn, "UIDropDownMenuTemplate")

    local function InitializeDropdown()
        local info = UIDropDownMenu_CreateInfo()
        info.notCheckable = false -- show circles

        for i, itemID in ipairs(onItemSelected.items) do
            local name, _, _, _, _, _, _, _, _, icon = GetItemInfo(itemID)
            if name then
                info.text = name
                info.icon = icon
                info.checked = (selectedMainHandItem == itemID) -- circle filled if selected

                info.func = function()
                    selectedMainHandItem = itemID
                    btn.itemID = itemID
                    btn.icon:SetTexture(icon)
                    onItemSelected.select(itemID)
                end

                UIDropDownMenu_AddButton(info, 1)

                -- Hook tooltip for dropdown item (delayed to ensure button exists)
                C_Timer.After(0, function()
                    local menuBtn = _G["DropDownList1Button"..i]
                    if menuBtn then
                        menuBtn:SetScript("OnEnter", function(self)
                            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
                            GameTooltip:SetItemByID(itemID)
                            GameTooltip:Show()
                        end)
                        menuBtn:SetScript("OnLeave", GameTooltip_Hide)
                    end
                end)
            end
        end
    end

    -- Show dropdown on click
    btn:SetScript("OnClick", function()
        UIDropDownMenu_Initialize(dropdown, InitializeDropdown, "MENU")
        ToggleDropDownMenu(1, nil, dropdown, btn, 0, 0)
    end)

    -- Tooltip for the main-hand button itself
    btn:SetScript("OnEnter", function(self)
        if self.itemID then
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:SetItemByID(self.itemID)
            GameTooltip:Show()
        else
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:SetText("Main Hand")
            GameTooltip:Show()
        end
    end)
    btn:SetScript("OnLeave", GameTooltip_Hide)

    return btn
end

local function createItemDropdown(parent, items, onSelect)
    local questionMarkIcon = 134400
  
    local btn = CreateFrame("Button", nil, parent, "ItemButtonTemplate")
    btn:SetSize(40, 40)
    btn.icon = btn.IconTexture or btn.icon
    btn.icon:SetTexture(questionMarkIcon)
    btn.itemID = nil

    local dropdown = CreateFrame("Frame", nil, btn, "UIDropDownMenuTemplate")

    local function InitializeDropdown()
        local info = UIDropDownMenu_CreateInfo()
        info.notCheckable = false

        for i, itemID in ipairs(items) do
            local name, _, _, _, _, _, _, _, _, icon = GetItemInfo(itemID)
            if name then
                info.text = name
                info.icon = icon
                info.checked = (btn.itemID == itemID)

                info.func = function()
                    btn.itemID = itemID
                    btn.icon:SetTexture(icon)
                    onSelect(itemID)
                end

                UIDropDownMenu_AddButton(info, 1)

                C_Timer.After(0, function()
                    local menuBtn = _G["DropDownList1Button"..i]
                    if menuBtn then
                        menuBtn:SetScript("OnEnter", function(self)
                            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
                            GameTooltip:SetItemByID(itemID)
                            GameTooltip:Show()
                        end)
                        menuBtn:SetScript("OnLeave", GameTooltip_Hide)
                    end
                end)
            end
        end
    end

    btn:SetScript("OnClick", function()
        UIDropDownMenu_Initialize(dropdown, InitializeDropdown, "MENU")
        ToggleDropDownMenu(1, nil, dropdown, btn, 0, 0)
    end)

    btn:SetScript("OnEnter", function(self)
        if self.itemID then
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:SetItemByID(self.itemID)
            GameTooltip:Show()
        else
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:SetText("Select Item")
            GameTooltip:Show()
        end
    end)
    btn:SetScript("OnLeave", GameTooltip_Hide)

    return btn
end

local function createCharacterModel()
    local modelGroup = AceGUI:Create("SimpleGroup")
    modelGroup:SetLayout("Fill")
    
    local model = CreateFrame("DressUpModel", nil, modelGroup.frame)
    model:SetAllPoints()
    model:SetUnit("player")
    model:SetFacing(0.5)
    model:SetCamera(0)
    model:SetPosition(0, 0, 0)
    model:SetCamDistanceScale(1.3)

    model:EnableMouse(true)

    local lastX
    model:SetScript("OnMouseDown", function(self, button)
        if button ~= "LeftButton" then return end
        lastX = GetCursorPosition()
    end)
    model:SetScript("OnMouseUp", function(self)
        lastX = nil
    end)

    model:SetScript("OnUpdate", function(self)
        if not lastX then return end

        local x = GetCursorPosition()
        local delta = (x - lastX) * 0.01
        lastX = x

        self:SetFacing(self:GetFacing() + delta)
    end)

    local function cleanup()
        if model then
            model:ClearModel()
            model:Hide()
            model:SetParent(nil)
            model:UnregisterAllEvents()
            model:SetScript("OnUpdate", nil)
            model:SetScript("OnMouseDown", nil)
            model:SetScript("OnMouseUp", nil)
            model = nil
        end
    end
    
    return modelGroup, cleanup
end

-- Inspired by the CreateMainHandButton function above
local function createItemSlotGroup(orientation, slotDefs, selectedSet)
    local container = AceGUI:Create("SimpleGroup")
    if orientation == "vertical" then
        container:SetLayout("List")
        container:SetWidth(44)
        container:SetHeight(300)
    else
        container:SetLayout("Flow")
        container:SetFullWidth(true)
        container:SetHeight(44)
    end

    local itemButtons = {}
    for _, slotDef in ipairs(slotDefs) do
        local slotName = slotDef.slotName
        local items = slotDef.items

        local function onSelect(itemID)
            -- selectedSet[slotName] = itemID
            Loadouts.Lib.log("always")
                :print("Selected item ID ")
                :print(tostring(itemID))
                :print(" for slot ")
                :print(slotName)
                :as(t.slot)
                :flush()
        end

        local itemButton = createItemDropdown(container.frame, items, onSelect)
        itemButton:SetPoint("TOP", container.frame, "TOP", 0, 0)

        if selectedSet[slotName] then
            local _, _, _, _, _, _, _, _, _, icon = GetItemInfo(selectedSet[slotName])
            if icon then
                itemButton.icon:SetTexture(icon)
                itemButton.itemID = selectedSet[slotName]
            end
        end

        table.insert(itemButtons, itemButton)
        Loadouts.Lib.log("always")
            :print("Created item button for slot ")
            :print(slotName)
            :flush()
        -- container:AddChild(itemButton)
    end
    local function cleanup()
        for _, btn in ipairs(itemButtons) do
            btn:SetParent(nil)
        end
        container:ReleaseChildren()
    end
    return container, cleanup
end

local function createItemSlots(selectedSet)
    left, left_cleanup = createItemSlotGroup("vertical", {
        {slotName = "Head", items = {}},
        {slotName = "Shoulder", items = {}},
        {slotName = "Back", items = {}},
        {slotName = "Chest", items = {}},
        {slotName = "Wrist", items = {}},
        {slotName = "Hands", items = {}},
    }, selectedSet)

    right, right_cleanup = createItemSlotGroup("vertical", {
        {slotName = "Waist", items = {}},
        {slotName = "Legs", items = {}},
        {slotName = "Feet", items = {}},
        {slotName = "Finger0", items = {}},
        {slotName = "Finger1", items = {}},
        {slotName = "Trinket0", items = {}},
        {slotName = "Trinket1", items = {}},
    }, selectedSet)

    weapons, weapons_cleanup = createItemSlotGroup("horizontal", {
        {slotName = "MainHand", items = mainHandItems},
        {slotName = "OffHand", items = {}},
        {slotName = "Ranged", items = {}},
    }, selectedSet)

    local function cleanup()
        left_cleanup()
        weapons_cleanup()
        right_cleanup()
    end

    return left, weapons, right, cleanup
end

local function createLoadoutView(context, selectedSetName)
    local mainContainer = AceGUI:Create("SimpleGroup")
    mainContainer:SetLayout("Flow")
    mainContainer:SetFullWidth(true)
    mainContainer:SetFullHeight(true)

    local modelGroup, cleanupModel = createCharacterModel(mainContainer)
    
    local selectedSet = context.equipmentSets[selectedSetName]
    
    left, weapons, right, cleanupItems = createItemSlots(selectedSet)
    mainContainer:AddChild(left)
    mainContainer:AddChild(modelGroup)
    mainContainer:AddChild(right)
    mainContainer:AddChild(weapons)

    local function cleanup()
        cleanupModel()
        cleanupItems()
        mainContainer:ReleaseChildren()
    end
    
    return mainContainer, cleanup
end

local function createLoadoutTree(context)
    local tree = AceGUI:Create("TreeGroup")
    tree:SetLayout("Fill")
    tree:SetFullWidth(true)
    tree:SetFullHeight(true)

    local treeData = {}
    for setName, _ in pairs(context.equipmentSets) do
        table.insert(treeData, {
            value = setName,
            text = setName,
        })
    end
    tree:SetTree(treeData)

    local loadoutView = nil
    local cleanup = nil

    tree:SetCallback("OnGroupSelected", function(container, event, group)
        if cleanup then
            cleanup()
            cleanup = nil
        end
        container:ReleaseChildren()

        container:SetLayout("Flow")
        container:SetFullWidth(true)
        container:SetFullHeight(true)

        loadoutView, cleanup = createLoadoutView(context, group)
        container:AddChild(loadoutView)
        loadoutView:SetFullWidth(true)
        loadoutView:SetFullHeight(true)

        -- local slotBar = AceGUI:Create("SimpleGroup")
        -- slotBar:SetLayout("Flow")
        -- slotBar:SetFullWidth(true)
        -- slotBar:SetHeight(44)
        -- container:AddChild(slotBar)

        -- buttonFrame = CreateMainHandButton(
        --     slotBar.frame,
        --     {
        --         items = mainHandItems,
        --         select = function(itemID)
        --             model:ClearModel()
        --             model:SetUnit("player")
        --             Loadouts.Lib.log("always"):print("Trying on main-hand item ID " .. tostring(itemID)):flush()
        --             model:TryOn("item:" .. tostring(itemID))
        --         end
        --     }
        -- )
        -- buttonFrame:SetPoint("LEFT", slotBar.frame, "LEFT", 0, 0)
        -- buttonFrame.icon:SetDesaturated(true)
        -- buttonFrame:Disable()
    end)

    tree:SetSelected(context.equipmentSets and next(context.equipmentSets) or nil)

    tree:SetCallback("OnRelease", function()
        Loadouts.Lib.log("always")
            :print("Releasing loadout tree and cleaning up resources.")
            :flush()
        if cleanup then
            cleanup()
        end
    end)

    return tree
end

function Loadouts.UI.OpenUI()
    if isOpen then
        return
    end
    isOpen = true

    context = getContext()

    local f = AceGUI:Create("Frame")
    f:SetTitle("Loadouts")
    f:SetStatusText("Loadout count: " .. tostring(tableLength(context.equipmentSets)))
    f:SetLayout("Flow")

    local loadoutTree = createLoadoutTree(context)
    f:AddChild(loadoutTree)

    f:SetCallback("OnClose", function(widget)
        AceGUI:Release(widget)
        isOpen = false
    end)
end
