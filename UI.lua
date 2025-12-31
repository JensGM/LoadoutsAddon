Loadouts.UI = Loadouts.UI or {}
local AceGUI = LibStub("AceGUI-3.0")

--[[
UI Module for Loadouts Addon


Layout:

mainFrame
--------------------------------------------------------
| loadoutTree                                          |
| |-------------|------------------------------------| |
| | loadoutTree | loadoutTreeView                    | | 
| | Selection   | |--------------------------------| | |
| |             | | combatLoadoutCheckbox          | | |
| |             | |--------------------------------| | |
| |             | | l |---|------------------|---| r | |
| |             | | e | H | modeGroup        | h | i | |
| |             | | f | N | |--------------| | w | g | |
| |             | | t | S | | modelDressup | | L | h | |
| |             | |   | B | |              | | F | t | |
| |             | |   | C | |              | | f |   | |
| |             | |   | S | |              | | f |   | |
| |             | |   | T | |              | | t |   | |
| |             | |   | W | |--------------| | t |   | |
| |             | |   |---| weapons          |---|   | |
| |             | |         |--------------|         | |
| |             | |         | MH    OH   R |         | |
| |             | |         |--------------|         | |
| |-------------|------------------------------------| |
--------------------------------------------------------

-]]

local isIntialized = false
local isOpen = false

local mainFrame = nil
local loadoutTree = nil

local LoadoutTreeView = nil
local LoadoutNameLabel = nil
local equipLoadoutButton = nil
local deleteLoadoutButton = nil
local LoadoutTopBar = nil
local isCombatLoadoutCheckbox = nil
local LoadoutView = nil
local LoadoutCentralColumn = nil

local treeData = nil
local selectedLoadout = nil

local modelGroup = nil
local modelDressup = nil

local leftGroup = nil
local rightGroup = nil
local weaponGroup = nil

local Location = {
    LEFT = "LEFT",
    RIGHT = "RIGHT",
    WEAPON = "WEAPON",
}

local Orientation = {
    VERTICAL = "VERTICAL",
    HORIZONTAL = "HORIZONTAL",
}

local slotOrder = {
    "HEADSLOT",
    "NECKSLOT",
    "SHOULDERSLOT",
    "BACKSLOT",
    "CHESTSLOT",
    "SHIRTSLOT",
    "TABARDSLOT",
    "WRISTSLOT",

    "HANDSSLOT",
    "WAISTSLOT",
    "LEGSSLOT",
    "FEETSLOT",
    "FINGER0SLOT",
    "FINGER1SLOT",
    "TRINKET0SLOT",
    "TRINKET1SLOT",

    "MAINHANDSLOT",
    "SECONDARYHANDSLOT",
    "RANGEDSLOT",
}

local activeForCombatLoadout = {
    ["HEADSLOT"] = false,
    ["NECKSLOT"] = false,
    ["SHOULDERSLOT"] = false,
    ["BACKSLOT"] = false,
    ["CHESTSLOT"] = false,
    ["SHIRTSLOT"] = false,
    ["TABARDSLOT"] = false,
    ["WRISTSLOT"] = false,

    ["HANDSSLOT"] = false,
    ["WAISTSLOT"] = false,
    ["LEGSSLOT"] = false,
    ["FEETSLOT"] = false,
    ["FINGER0SLOT"] = false,
    ["FINGER1SLOT"] = false,
    ["TRINKET0SLOT"] = false,
    ["TRINKET1SLOT"] = false,

    ["MAINHANDSLOT"] = true,
    ["SECONDARYHANDSLOT"] = true,
    ["RANGEDSLOT"] = true,
}

local buttonLocations = {
    ["HEADSLOT"] = Location.LEFT,
    ["NECKSLOT"] = Location.LEFT,
    ["SHOULDERSLOT"] = Location.LEFT,
    ["BACKSLOT"] = Location.LEFT,
    ["CHESTSLOT"] = Location.LEFT,
    ["SHIRTSLOT"] = Location.LEFT,
    ["TABARDSLOT"] = Location.LEFT,
    ["WRISTSLOT"] = Location.LEFT,

    ["HANDSSLOT"] = Location.RIGHT,
    ["WAISTSLOT"] = Location.RIGHT,
    ["LEGSSLOT"] = Location.RIGHT,
    ["FEETSLOT"] = Location.RIGHT,
    ["FINGER0SLOT"] = Location.RIGHT,
    ["FINGER1SLOT"] = Location.RIGHT,
    ["TRINKET0SLOT"] = Location.RIGHT,
    ["TRINKET1SLOT"] = Location.RIGHT,

    ["MAINHANDSLOT"] = Location.WEAPON,
    ["SECONDARYHANDSLOT"] = Location.WEAPON,
    ["RANGEDSLOT"] = Location.WEAPON,
}

local function getItemsForSlotInInventory(slotLoc)
    assert(slotLoc, "slotLoc is required")
    local items = {}

    local function maybeAddItem(itemLink, itemId)
        assert(itemLink, "itemLink is required")
        assert(itemId, "itemId is required")

        local name, _, _, _, _, _, _, _, itemEquipLoc, icon = GetItemInfo(itemLink)
        if not itemEquipLoc then return end

        local itemSlots = Loadouts.Shared.ItemTypeSlots[itemEquipLoc] or {}
        if Loadouts.Lib.contains(itemSlots, slotLoc) then
            table.insert(items, {
                itemId = itemId,
                name = name,
                link = itemLink,
                icon = icon,
            })
        end
    end

    -- 1. Equipped inventory (1–19)
    for invSlot = 1, 19 do
        local itemLink = GetInventoryItemLink("player", invSlot)
        if itemLink then
            local itemId = itemLink and tonumber(itemLink:match("item:(%d+):"))
            assert(itemId, "itemId is nil for inventory slot " .. invSlot)
            maybeAddItem(itemLink, itemId)
        end
    end

    -- 2. Bags
    local NUM_TOTAL_EQUIPPED_BAG_SLOTS = BACKPACK_CONTAINER + NUM_BAG_SLOTS + 1
    for bag = BACKPACK_CONTAINER, NUM_TOTAL_EQUIPPED_BAG_SLOTS do
        for slot = 1, C_Container.GetContainerNumSlots(bag) do
            local itemInfo = C_Container.GetContainerItemInfo(bag, slot)
            if itemInfo then
                local itemLink = itemInfo.hyperlink
                local itemId = itemInfo.itemID
                assert(itemLink, "itemLink is nil for bag " .. bag .. " slot " .. slot)
                assert(itemId, "itemId is nil for bag " .. bag .. " slot " .. slot)
                maybeAddItem(itemLink, itemId)
            end
        end
    end

    return items
end

Loadouts.UI.InventorySlot = {}
Loadouts.UI.InventorySlot.__index = Loadouts.UI.InventorySlot

function Loadouts.UI.InventorySlot:new(slotName)
    assert(slotName, "slotName is required")

    local _, iconPath, _ = GetInventorySlotInfo(slotName)

    local self = setmetatable({}, Loadouts.UI.InventorySlot)
    self.slotName = slotName
    self.slotNameHuman = Loadouts.Shared.HumanSlotNames[slotName]
    self.slotLoc = Loadouts.Shared.SlotLocs[slotName]
    self.iconPath = iconPath
    self.buttonLocation = buttonLocations[slotName]
    self.buttonGroup = nil
    self.button = nil
    self.dropdown = nil

    assert(self.slotName, "slotName not set")
    assert(self.slotNameHuman, "slotNameHuman not set for slot " .. self.slotName)
    assert(self.slotLoc, "slotLoc not set for slot " .. self.slotName)
    assert(self.buttonLocation, "buttonLocation not set for slot " .. self.slotName)
    assert(iconPath, "Failed to get icon path for slot " .. self.slotName)

    return self
end

function Loadouts.UI.InventorySlot:setItem(itemLink, updateLoadout)
    assert(selectedLoadout, "No loadout selected")
    assert(self.button, "Button not created for slot " .. self.slotName)
    assert(itemLink, "itemLink is required")
    local _, _, _, _, _, _, _, _, _, icon = GetItemInfo(itemLink)
    assert(icon, "icon is nil for itemLink " .. tostring(itemLink))
    if updateLoadout then
        Loadouts.Lib.updateEquipmentSetById(
            selectedLoadout,
            self.slotLoc,
            itemLink
        )
        Loadouts.Lib.updateCharacterMacros()
    end
    self.button.itemLink = itemLink
    self.button.icon:SetTexture(icon)
end

function Loadouts.UI.InventorySlot:clearItem()
    assert(self.button, "Button not created for slot " .. self.slotName)
    self.button.itemLink = nil
    self.button.icon:SetTexture(self.iconPath)
end

function Loadouts.UI.InventorySlot:_InitializeDropdown()
    local items = getItemsForSlotInInventory(self.slotLoc)

    do
        local info = UIDropDownMenu_CreateInfo()
        info.notCheckable = true
        info.text = "None"
        info.icon = nil
        info.checked = (self.button.itemId == nil)

        info.func = function()
            self:clearItem()
        end

        UIDropDownMenu_AddButton(info, 1)
    end
    
    for i = 1, #items do
        local item = items[i]
        local info = UIDropDownMenu_CreateInfo()
        info.notCheckable = false
        info.text = item.name
        info.icon = item.icon
        info.checked = (self.button.itemLink == item.link)

        info.func = function()
            assert(item.link, "item.link is nil for itemId " .. tostring(item.itemId))
            self:setItem(item.link, true)
        end

        UIDropDownMenu_AddButton(info, 1)

        local enableDropdownTooltip = false
        if enableDropdownTooltip then
            C_Timer.After(0, function()
                local menuBtn = _G["DropDownList1Button"..i + 1]
                if menuBtn then
                    menuBtn:SetScript("OnEnter", function(self)
                        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
                        GameTooltip:SetHyperlink(item.link)
                        GameTooltip:Show()
                    end)
                    menuBtn:SetScript("OnLeave", GameTooltip_Hide)
                end
            end)
        end
    end
end

function Loadouts.UI.InventorySlot:createButton()
    assert(not self.button, "Button already created for slot " .. self.slotName)
    assert(not self.buttonGroup, "Button group not created for slot " .. self.slotName)
    
    -- AceGUI button group
    self.buttonGroup = AceGUI:Create("SimpleGroup")
    self.buttonGroup:SetLayout("Flow")
    self.buttonGroup:SetWidth(44)
    self.buttonGroup:SetHeight(44)
    self.buttonGroup:SetAutoAdjustHeight(false)

    -- Item button
    self.button = CreateFrame("Button", nil, self.buttonGroup.frame, "ItemButtonTemplate")
    self.button:SetSize(40, 40)
    self.button:SetPoint("CENTER", self.buttonGroup.frame, "CENTER", 0, 0)
    self.button.itemLink = nil
    self.button.icon:SetTexture(self.iconPath)

    local isCombatLoadout = true
    if isCombatLoadout and not activeForCombatLoadout[self.slotName] then
        self.button:SetAlpha(0.15)
        self.button:Disable()
    end

    -- Item tooltip
    local humanReadableSlot = self.slotNameHuman or self.slotName
    self.button:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        if self.itemLink then
            GameTooltip:SetHyperlink(self.itemLink)
        else
            GameTooltip:SetText("Select an item for " .. humanReadableSlot)
        end
        GameTooltip:Show()
    end)
    self.button:SetScript("OnLeave", function(self)
        GameTooltip:Hide()
    end)

    -- Dropdown
    self.dropdown = CreateFrame("Frame", nil, self.button, "UIDropDownMenuTemplate")
    self.button:SetScript("OnClick", function()
        UIDropDownMenu_Initialize(self.dropdown, function()
            self:_InitializeDropdown()
        end, "MENU")
        ToggleDropDownMenu(1, nil, self.dropdown, self.button, 0, 0)
    end)

    assert(self.buttonGroup, "Button group not created for slot " .. self.slotName)
    assert(self.button, "Button not created for slot " .. self.slotName)
    assert(self.dropdown, "Dropdown not created for slot " .. self.slotName)
end

-- Create empty buttons for all inventory slots
local inventoryButtons = {}
for _, slotName in ipairs(slotOrder) do
    inventoryButtons[slotName] = Loadouts.UI.InventorySlot:new(slotName)
end
assert(Loadouts.Lib.tableLength(inventoryButtons) == 19, "Incorrect number of inventory buttons created: " .. tostring(Loadouts.Lib.tableLength(inventoryButtons)))

local function refreshInventorySlots()
    if not selectedLoadout then
        for _, slotName in ipairs(slotOrder) do
            local slot = inventoryButtons[slotName]
            slot:clearItem()
        end
        return
    end

    local set = Loadouts.Lib.getEquipmentSet(selectedLoadout)
    assert(set and not set.isError, "Failed to get equipment set for loadout " .. tostring(selectedLoadout))
    set = set.value

    for _, slotName in ipairs(slotOrder) do
        local slot = inventoryButtons[slotName]
        local itemIdOrLink = set[slot.slotLoc]
        if itemIdOrLink then
            local itemLink = Loadouts.Lib.formatItemLink(itemIdOrLink)
            assert(itemLink, "itemLink is nil for itemId " .. tostring(itemId))
            slot:setItem(itemLink)
        else
            slot:clearItem()
        end
    end
end

local function refreshTreeData()
    treeData = {}
    table.insert(treeData, {
        value = "Create New Loadout",
        text = "Create New Loadout",
    })
    local equipmentSets = Loadouts.Lib.getEquipmentSets()
    for loadoutName, _ in pairs(equipmentSets) do
        table.insert(treeData, {
            value = loadoutName,
            text = loadoutName,
        })
    end
end

local function dressupEquipmentSet(loadoutName)
    assert(modelDressup, "Model dressup not created")
  
    local set = {}
    if selectLoadout then
        set = Loadouts.Lib.getEquipmentSet(loadoutName)
        assert(set and not set.isError, "Failed to get equipment set for loadout " .. tostring(loadoutName))
        set = set.value
    end

    modelDressup:Undress()

    -- Equip current items first
    for slotId, _ in pairs(Loadouts.Shared.SlotLocNames) do
        local itemLink = GetInventoryItemLink("player", slotId)
        if itemLink then
            modelDressup:TryOn(itemLink)
        end
    end
    
    -- Equip loadout items
    for slot, itemId in pairs(set or {}) do
        local itemLink = Loadouts.Lib.formatItemLink(itemId)

        -- Off-hand items need special handling
        local handSlotName = nil
        if Loadouts.Shared.SlotLocNames[slot] == "SECONDARYHANDSLOT" then
            handSlotName = "SECONDARYHANDSLOT"
        end

        if itemLink then
            modelDressup:TryOn(itemLink, handSlotName)
        end
    end
end

local function refreshUI()
    assert(loadoutTree, "Loadout tree not created")

    refreshTreeData()

    loadoutTree:SetTree(treeData)
    loadoutTree:SetSelected(selectedLoadout)

    LoadoutNameLabel:SetText(selectedLoadout, "")

    refreshInventorySlots()

    dressupEquipmentSet(selectedLoadout)
end

local function onLoadoutSelected(widget, event, selected)
    if selected == "Create New Loadout" then
        local new_name = "New Loadout"
        local new_name_attempt = 1
        existing = Loadouts.Lib.getEquipmentSet(new_name)
        while not existing.isError do
            new_name = new_name .. " " .. tostring(new_name_attempt)
            existing = Loadouts.Lib.getEquipmentSet(new_name)
            new_name_attempt = new_name_attempt + 1
        end
        local result = Loadouts.Lib.createEquipmentSet(new_name)
        if result.isError then
            result.error:flush()
            return
        end
        selectedLoadout = new_name
    else
        selectedLoadout = selected
    end
    refreshUI()
end

local function createMainFrame()
    assert(not mainFrame, "Main frame already created")

    mainFrame = AceGUI:Create("Frame")
    mainFrame:Hide()
    mainFrame:SetTitle("Loadouts")
    mainFrame:SetStatusText("Manage your equipment loadouts")
    mainFrame:SetLayout("Flow")
    local treeWidth = 265
    local modelWidth = 200
    local buttonWidth = 44 * 2
    mainFrame:SetWidth(treeWidth + modelWidth + buttonWidth)
    mainFrame:EnableResize(false)
    mainFrame:SetCallback("OnClose", function()
        isOpen = false
    end)
end

local function createLoadoutNameLabel()
    assert(not LoadoutNameLabel, "Loadout name label already created")

    LoadoutNameLabel = AceGUI:Create("EditBox")
    LoadoutNameLabel:SetText("")
    LoadoutNameLabel:SetWidth(100)
    LoadoutNameLabel:SetCallback("OnEnterPressed", function(widget, event, text)
        if not selectedLoadout then
            return
        end
        local newName = text:gsub("^%s*(.-)%s*$", "%1") -- trim whitespace
        if newName == "" or newName == selectedLoadout then
            widget:SetText(selectedLoadout)
            return
        end
        local result = Loadouts.Lib.renameEquipmentSet(selectedLoadout, newName)
        if result.isError then
            result.error:flush()
            widget:SetText(selectedLoadout)
            return
        end
        selectedLoadout = newName
        refreshUI()
    end)

    return LoadoutNameLabel
end

local function createLoadoutTopBar()
    assert(LoadoutTreeView, "Loadout tree view not created")
    assert(not LoadoutTopBar, "Loadout top bar already created")

    LoadoutTopBar = AceGUI:Create("SimpleGroup")
    LoadoutTopBar:SetLayout("Flow")
    LoadoutTopBar:SetFullWidth(true)

    LoadoutNameLabel = createLoadoutNameLabel()

    equipLoadoutButton = AceGUI:Create("Button")
    equipLoadoutButton:SetText("Equip")
    equipLoadoutButton:SetWidth(100)
    equipLoadoutButton:SetCallback("OnClick", function()
        if not selectedLoadout then
            return
        end
        local result = Loadouts.Lib.equipEquipmentSet(selectedLoadout)
        if result.isError then
            result.error:flush()
            return
        end
    end)

    deleteLoadoutButton = AceGUI:Create("Button")
    deleteLoadoutButton:SetText("Delete")
    deleteLoadoutButton:SetWidth(75)
    deleteLoadoutButton:SetCallback("OnClick", function()
        if not selectedLoadout then
            return
        end
        local result = Loadouts.Lib.removeEquipmentSet(selectedLoadout)
        if result.isError then
            result.error:flush()
            return
        end
        selectedLoadout = Loadouts.Lib.getFirstLoadoutName() or nil
        refreshUI()
    end)

    LoadoutTopBar:AddChild(LoadoutNameLabel)
    LoadoutTopBar:AddChild(equipLoadoutButton)
    LoadoutTopBar:AddChild(deleteLoadoutButton)

    LoadoutTreeView:AddChild(LoadoutTopBar)
end

local function createCombatLoadoutCheckbox()
    assert(LoadoutTreeView, "Loadout tree view not created")
    assert(not isCombatLoadoutCheckbox, "Combat loadout checkbox already created")

    isCombatLoadoutCheckbox = AceGUI:Create("CheckBox")
    isCombatLoadoutCheckbox:SetLabel("Combat Loadout")
    isCombatLoadoutCheckbox:SetValue(true)
    isCombatLoadoutCheckbox:SetDisabled(true)

    LoadoutTreeView:AddChild(isCombatLoadoutCheckbox)
end

local function createModelDressup()
    assert(modelGroup, "Model group not created")
    assert(not modelDressup, "Model dressup already created")

    modelDressup = CreateFrame("DressUpModel", nil, modelGroup.frame)
    modelDressup:SetAllPoints(modelGroup.frame)
    modelDressup:SetUnit("player")
    modelDressup:SetFacing(0.5)
    modelDressup:SetCamera(0)
    modelDressup:SetPosition(0, 0, 0)
    modelDressup:SetCamDistanceScale(1.0)

    modelDressup:EnableMouse(true)

    local lastX
    modelDressup:SetScript("OnMouseDown", function(self, button)
        if button ~= "LeftButton" then return end
        lastX = GetCursorPosition()
    end)
    modelDressup:SetScript("OnMouseUp", function(self)
        lastX = nil
    end)

    modelDressup:SetScript("OnUpdate", function(self)
        if not lastX then return end

        local x = GetCursorPosition()
        local delta = (x - lastX) * 0.01
        lastX = x

        self:SetFacing(self:GetFacing() + delta)
    end)

    assert(modelDressup, "Model dressup not created")
end

local function createModelView()
    assert(LoadoutCentralColumn, "Loadout central column not created")
    assert(not modelGroup, "Model group already created")

    modelGroup = AceGUI:Create("SimpleGroup")
    modelGroup:SetWidth(200)
    local height = 44 * 7 -- Height for 7 inventory slots, weapons will be below
    modelGroup:SetHeight(height)
    modelGroup:SetAutoAdjustHeight(false)

    createModelDressup()
end

local function createEquipmentSlots()
    assert(not leftGroup, "Left equipment slot group already created")
    assert(not rightGroup, "Right equipment slot group already created")
    assert(not weaponGroup, "Weapon equipment slot group already created")

    leftGroup = AceGUI:Create("SimpleGroup")
    leftGroup:SetLayout("List")
    leftGroup:SetWidth(44)
    leftGroup:SetAutoAdjustHeight(true)

    rightGroup = AceGUI:Create("SimpleGroup")
    rightGroup:SetLayout("List")
    rightGroup:SetWidth(44)
    rightGroup:SetAutoAdjustHeight(true)

    weaponGroup = AceGUI:Create("SimpleGroup")
    weaponGroup:SetLayout("Flow")
    weaponGroup:SetWidth(200)
    weaponGroup:SetAutoAdjustHeight(true)
    local pad = AceGUI:Create("SimpleGroup")
    local padWidth = (200 - 3 * 44) / 2
    pad:SetWidth(padWidth)
    pad:SetAutoAdjustHeight(false)
    weaponGroup:AddChild(pad)

    buttonGroups = {
        [Location.LEFT] = leftGroup,
        [Location.RIGHT] = rightGroup,
        [Location.WEAPON] = weaponGroup,
    }

    for _, slotName in ipairs(slotOrder) do
        local slot = inventoryButtons[slotName]
        slot:createButton()
        buttonGroups[slot.buttonLocation]:AddChild(slot.buttonGroup)
    end

    return leftGroup, rightGroup, weaponGroup
end

local function createLoadoutView()
    assert(LoadoutTreeView, "Loadout tree view not created")
    assert(not LoadoutView, "Loadout view already created")
    assert(not LoadoutCentralColumn, "Loadout central column already created")

    LoadoutView = AceGUI:Create("SimpleGroup")
    LoadoutView:SetLayout("Flow")
    LoadoutView:SetFullWidth(true)
    LoadoutView:SetFullHeight(true)

    LoadoutCentralColumn = AceGUI:Create("SimpleGroup")
    LoadoutCentralColumn:SetLayout("List")
    LoadoutCentralColumn:SetWidth(200)
    LoadoutCentralColumn:SetFullHeight(true)

    createModelView()
    left, right, weapon = createEquipmentSlots()

    LoadoutView:AddChild(left)

    LoadoutCentralColumn:AddChild(modelGroup)
    LoadoutCentralColumn:AddChild(weapon)
    LoadoutView:AddChild(LoadoutCentralColumn)

    LoadoutView:AddChild(right)

    LoadoutTreeView:AddChild(LoadoutView)
end

local function createLoadoutTreeView()
    assert(loadoutTree, "Loadout tree not created")
    assert(not LoadoutTreeView, "Loadout tree view already created")

    LoadoutTreeView = AceGUI:Create("SimpleGroup")
    LoadoutTreeView:SetLayout("List")
    LoadoutTreeView:SetFullWidth(true)
    LoadoutTreeView:SetFullHeight(true)
    
    createLoadoutTopBar()
    createCombatLoadoutCheckbox()
    createLoadoutView()

    loadoutTree:AddChild(LoadoutTreeView)
end

local function createLoadoutTree()
    assert(mainFrame, "Main frame not created")
    assert(not loadoutTree, "Loadout tree already created")

    loadoutTree = AceGUI:Create("TreeGroup")
    loadoutTree:SetLayout("Fill")
    loadoutTree:SetFullWidth(true)
    loadoutTree:SetFullHeight(true)

    refreshTreeData()
    loadoutTree:SetTree(treeData)
    loadoutTree:SetCallback("OnGroupSelected", onLoadoutSelected)

    createLoadoutTreeView()

    if not selectedLoadout then
        selectedLoadout = Loadouts.Lib.getFirstLoadoutName() or nil
    end
    loadoutTree:SetSelected(selectedLoadout)

    mainFrame:AddChild(loadoutTree)
end

local function initializeUI()
    if isIntialized then
        return
    end

    createMainFrame()
    createLoadoutTree(mainFrame)
    isIntialized = true

    -- validate ui tree
    assert(mainFrame, "Main frame not created")

    assert(loadoutTree, "Loadout tree not created")
    assert(loadoutTree.parent == mainFrame, "Loadout tree not child of main frame")

    assert(LoadoutTreeView, "Loadout tree view not created")
    assert(LoadoutTreeView.parent == loadoutTree, "Loadout tree view not child of loadout tree")

    assert(LoadoutView, "Loadout view not created")
    assert(LoadoutView.parent == LoadoutTreeView, "Loadout view not child of loadout tree view")

    assert(LoadoutCentralColumn, "Loadout central column not created")
    assert(LoadoutCentralColumn.parent == LoadoutView, "Loadout central column not child of loadout view")

    assert(modelGroup, "Model group not created")
    assert(modelGroup.parent == LoadoutCentralColumn, "Model group not child of loadout central column")

    assert(modelDressup, "Model dressup not created")
    assert(modelDressup:GetParent() == modelGroup.frame, "Model dressup not child of model group frame")

    assert(leftGroup, "Left equipment slot group not created")
    assert(leftGroup.parent == LoadoutView, "Left equipment slot group not child of loadout view")

    assert(rightGroup, "Right equipment slot group not created")
    assert(rightGroup.parent == LoadoutView, "Right equipment slot group not child of loadout view")

    assert(weaponGroup, "Weapon equipment slot group not created")
    assert(weaponGroup.parent == LoadoutCentralColumn, "Weapon equipment slot group not child of loadout central column")
    
    assert(isCombatLoadoutCheckbox, "Combat loadout checkbox not created")
    assert(isCombatLoadoutCheckbox.parent == LoadoutTreeView, "Combat loadout checkbox not child of loadout tree view")
end

function Loadouts.UI.show()
    mainFrame:Show()
    isOpen = true
end

function Loadouts.UI.OpenUI()
    if isOpen then
        return
    end

    if not isIntialized then
        initializeUI()
    end

    -- Refresh UI on next tick to allow model to fully initialize
    C_Timer.After(0, function()
        refreshUI()
    end)
    
    Loadouts.UI.show()
end
