local frame = CreateFrame("Frame", "LoadoutsFrame", UIParent)
local equipmentSets = {}

-- Function to print messages
local function Print(msg, color)
    DEFAULT_CHAT_FRAME:AddMessage("|cff" .. color .. "Loadouts:|r " .. msg)
end

-- Helper function to format item links
local function FormatItemLink(itemID)
    local itemLink = select(2, GetItemInfo(itemID)) or "|cffffffff|Hitem:" .. itemID .. "|h[Unknown Item]|h|r"
    return itemLink
end

-- Function to equip an equipment set
local function EquipEquipmentSet(setName)
    local set = equipmentSets[setName]
    if not set then
        Print("Loadout '" .. setName .. "' not recognized.", "ff0000")
        return
    end
    for slot, itemID in pairs(set) do
        EquipItemByName(itemID, slot)
    end
    Print("Switched to " .. setName .. " set.", "00ff00")
end

-- Function to update equipment set by ID
local function UpdateEquipmentSetById(loadout, slot, itemID)
    if equipmentSets[loadout] then
        equipmentSets[loadout][slot] = itemID
        Print(loadout .. " " .. slot .. " set to " .. FormatItemLink(itemID) .. ".", "00ff00")
    else
        Print("Invalid loadout name.", "ff0000")
    end
end

-- Function to clear equipment set slot
local function ClearEquipmentSetSlot(loadout, slot)
    if equipmentSets[loadout] and equipmentSets[loadout][slot] then
        equipmentSets[loadout][slot] = nil
        Print("Cleared " .. slot .. " from loadout '" .. loadout .. "'.", "00ff00")
    else
        Print("Invalid loadout name or slot not set.", "ff0000")
    end
end

-- Function to show equipment sets
local function ShowEquipmentSets()
    Print("Equipment Sets:", "ffff00")
    for loadout, set in pairs(equipmentSets) do
        Print(loadout .. ":", "ffff00")
        for slot, itemID in pairs(set) do
            local itemLink = FormatItemLink(itemID)
            Print("  " .. slot .. ": " .. itemLink, "ffffff")
        end
    end
end

-- Function to create a new equipment set
local function CreateEquipmentSet(setName)
    if equipmentSets[setName] then
        Print("Loadout '" .. setName .. "' already exists.", "ff0000")
        return
    end
    equipmentSets[setName] = {}
    Print("Loadout '" .. setName .. "' created.", "00ff00")
end

-- Function to remove an equipment set
local function RemoveEquipmentSet(setName)
    if not equipmentSets[setName] then
        Print("Loadout '" .. setName .. "' not found.", "ff0000")
        return
    end
    equipmentSets[setName] = nil
    Print("Loadout '" .. setName .. "' removed.", "00ff00")
end

-- Mapping from itemEquipLoc to inventory slot names
local equipLocToSlotName = {
    ["INVTYPE_HEAD"] = "HeadSlot",
    ["INVTYPE_NECK"] = "NeckSlot",
    ["INVTYPE_SHOULDER"] = "ShoulderSlot",
    ["INVTYPE_CHEST"] = "ChestSlot",
    ["INVTYPE_WAIST"] = "WaistSlot",
    ["INVTYPE_LEGS"] = "LegsSlot",
    ["INVTYPE_FEET"] = "FeetSlot",
    ["INVTYPE_WRIST"] = "WristSlot",
    ["INVTYPE_HAND"] = "HandsSlot",
    ["INVTYPE_FINGER"] = "Finger0Slot", -- Note: There are two finger slots
    ["INVTYPE_TRINKET"] = "Trinket0Slot", -- Note: There are two trinket slots
    ["INVTYPE_CLOAK"] = "BackSlot",
    ["INVTYPE_WEAPON"] = "MainHandSlot",
    ["INVTYPE_SHIELD"] = "SecondaryHandSlot",
    ["INVTYPE_2HWEAPON"] = "MainHandSlot",
    ["INVTYPE_WEAPONMAINHAND"] = "MainHandSlot",
    ["INVTYPE_WEAPONOFFHAND"] = "SecondaryHandSlot",
    ["INVTYPE_HOLDABLE"] = "SecondaryHandSlot",
    ["INVTYPE_RANGED"] = "MainHandSlot",
    ["INVTYPE_THROWN"] = "MainHandSlot",
    ["INVTYPE_RANGEDRIGHT"] = "MainHandSlot",
    -- Add other mappings as needed
}

local function DetermineItemSlot(itemName)
    local _, _, _, _, _, _, _, _, itemEquipLoc = GetItemInfo(itemName)
    if not itemEquipLoc or not equipLocToSlotName[itemEquipLoc] then
        Print("Unable to determine slot for '" .. itemName .. "'.", "ff0000")
        return nil
    end

    local slotName = equipLocToSlotName[itemEquipLoc]
    local slotNumberString = GetInventorySlotInfo(slotName)
    local slotNumber = tonumber(slotNumberString)
    return slotNumber -- This will return the slot number
end


-- Slash commands for loadouts
SLASH_LOADOUTS1 = "/loadouts"
SlashCmdList["LOADOUTS"] = function(msg)
    local args = {strsplit(" ", msg)}
    local command, loadoutName = args[1], args[2]

    if command == "set" and loadoutName then
        local itemName = table.concat(args, " ", 3) -- Concatenate the remaining arguments for the item name
        local itemSlot = DetermineItemSlot(itemName)

        if itemSlot then
            -- Assuming UpdateEquipmentSetById can handle the new itemSlot logic
            UpdateEquipmentSetById(loadoutName, itemSlot, itemName) -- Adapt as needed
        end
    elseif command == "equip" and loadoutName then
        EquipEquipmentSet(loadoutName)
    elseif command == "show" then
        ShowEquipmentSets()
    elseif command == "new" and loadoutName then
        CreateEquipmentSet(loadoutName)
    elseif command == "rm" and loadoutName then
        RemoveEquipmentSet(loadoutName)
    elseif command == "clear" and loadoutName then
        -- Implementation for clear command goes here
    else
        Print("Invalid command or parameters. Use /loadouts for a list of commands.", "ffff00")
    end
end

-- Event handling for saving and loading settings
frame:RegisterEvent("PLAYER_LOGOUT")
frame:RegisterEvent("ADDON_LOADED")
frame:SetScript("OnEvent", function(self, event, arg1, ...)
    if event == "ADDON_LOADED" and arg1 == "Loadouts" then
        -- Load saved variables into equipmentSets or initialize if not present
        if Loadouts_SavedSets then
            equipmentSets = Loadouts_SavedSets
            Print("Loadout settings loaded.", "00ff00")
        end
    elseif event == "PLAYER_LOGOUT" then
        -- Save the equipmentSets to saved variables
        Loadouts_SavedSets = equipmentSets
    end
end)

Print("Addon loaded. Use /loadouts for commands.", "00ff00")
