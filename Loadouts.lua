local frame = CreateFrame("Frame", "LoadoutsFrame", UIParent)
local equipmentSets = {}

-- Function to print messages
local function printMessage(msg, color)
    DEFAULT_CHAT_FRAME:AddMessage("|cff" .. color .. "Loadouts:|r " .. msg)
end

-- Helper function to format item links
local function formatItemLink(itemId)
    local itemLink = select(2, GetItemInfo(itemId)) or "|cffffffff|Hitem:" .. itemId .. "|h[Unknown Item]|h|r"
    return itemLink
end

-- Function to equip an equipment set
local function equipEquipmentSet(setName)
    local set = equipmentSets[setName]
    if not set then
        printMessage("Loadout '" .. setName .. "' not recognized.", "ff0000")
        return
    end
    for slot, itemId in pairs(set) do
        EquipItemByName(itemId, slot)
    end
    printMessage("Switched to " .. setName .. " set.", "00ff00")
end

-- Function to update equipment set by ID
local function updateEquipmentSetById(loadout, ...)
    local itemArgs = {...}

    local function parseItem(itemArgs)
        local itemString = table.concat(itemArgs, " ")
        local pattern = "^([^:]*):?(.*)$"
        local fst, snd = itemString:match(pattern)
        local itemSlot, itemName

        if snd ~= "" then
            itemSlot = fst
            itemName = snd
        else
            itemName = itemString
        end

        local itemNameTrimmed = itemName:gsub("^%[?(.-)%]?$", "%1")
        return itemSlot, itemNameTrimmed
    end

    local function determineItemSlot(itemName)
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
            ["INVTYPE_FINGER"] = "Finger0Slot",
            ["INVTYPE_TRINKET"] = "Trinket0Slot",
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
        }

        local itemSlot, itemName = parseItem(itemArgs)
        local _, _, _, _, _, _, _, _, itemEquipLoc = GetItemInfo(itemName)
        if not itemEquipLoc or not equipLocToSlotName[itemEquipLoc] then
            printMessage("Unable to determine slot for '" .. itemName .. "'.", "ff0000")
            return nil
        end

        local slotName = equipLocToSlotName[itemEquipLoc]
        local slotNumberString = GetInventorySlotInfo(slotName)
        local slotNumber = tonumber(slotNumberString)
        return slotNumber
    end

    local itemSlot, itemName = parseItem(itemArgs)
    if not itemSlot then
        itemSlot = determineItemSlot(itemName)
    end

    if equipmentSets[loadout] then
        equipmentSets[loadout][itemSlot] = itemName
        printMessage(loadout .. " " .. itemSlot .. " set to " .. formatItemLink(itemName) .. ".", "00ff00")
    else
        printMessage("Invalid loadout name.", "ff0000")
    end
end

-- Function to clear equipment set slot
local function clearEquipmentSetSlot(loadout, slot)
    if equipmentSets[loadout] and equipmentSets[loadout][slot] then
        equipmentSets[loadout][slot] = nil
        printMessage("Cleared " .. slot .. " from loadout '" .. loadout .. "'.", "00ff00")
    else
        printMessage("Invalid loadout name or slot not set.", "ff0000")
    end
end

-- Function to show equipment sets
local function showEquipmentSets()
    printMessage("Equipment Sets:", "ffff00")
    for loadout, set in pairs(equipmentSets) do
        printMessage(loadout .. ":", "ffff00")
        for slot, itemId in pairs(set) do
            local itemLink = formatItemLink(itemId)
            printMessage("  " .. slot .. ": " .. itemLink, "ffffff")
        end
    end
end

-- Function to create a new equipment set
local function createEquipmentSet(setName)
    if equipmentSets[setName] then
        printMessage("Loadout '" .. setName .. "' already exists.", "ff0000")
        return
    end
    equipmentSets[setName] = {}
    printMessage("Loadout '" .. setName .. "' created.", "00ff00")
end

-- Function to remove an equipment set
local function removeEquipmentSet(setName)
    if not equipmentSets[setName] then
        printMessage("Loadout '" .. setName .. "' not found.", "ff0000")
        return
    end
    equipmentSets[setName] = nil
    printMessage("Loadout '" .. setName .. "' removed.", "00ff00")
end

-- Slash commands for loadouts
SLASH_LOADOUTS1 = "/loadouts"
SlashCmdList["LOADOUTS"] = function(msg)
    local commands = {
        ["set"] = {updateEquipmentSetById, "loadoutName (slotId:)?[item name]"},
        ["equip"] = {equipEquipmentSet, "loadoutName"},
        ["show"] = {showEquipmentSets, ""},
        ["new"] = {createEquipmentSet, "loadoutName"},
        ["rm"] = {removeEquipmentSet, "loadoutName"},
        ["clear"] = {clearEquipmentSetSlot, "loadoutName slotId"},
    }

    local args = {strsplit(" ", msg)}
    local command = args[1]

    if not command or commands[command] == nil then
        printMessage("Available commands:", "ffff00")
        for cmd, fns in pairs(commands) do
            local _, help = unpack(fns)
            printMessage("  /loadouts " .. cmd .. " " .. help, "ffffff")
        end
        return
    end

    local fn, _ = unpack(commands[command])
    table.remove(args, 1)
    fn(unpack(args))
end

-- Event handling for saving and loading settings
frame:RegisterEvent("PLAYER_LOGOUT")
frame:RegisterEvent("ADDON_LOADED")
frame:SetScript("OnEvent", function(self, event, arg1, ...)
    if event == "ADDON_LOADED" and arg1 == "Loadouts" then
        if Loadouts_SavedSets then
            equipmentSets = Loadouts_SavedSets
            printMessage("Loadout settings loaded.", "00ff00")
        end
    elseif event == "PLAYER_LOGOUT" then
        Loadouts_SavedSets = equipmentSets
    end
end)

printMessage("Addon loaded. Use /loadouts for commands.", "00ff00")
