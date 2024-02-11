local frame = CreateFrame("Frame", "LoadoutsFrame", UIParent)
local equipmentSets = {}

local logger = Loadouts.Logger:new()
local t = {}
t.slot = logger:token("slot", Loadouts.lightBlue)
t.loadout = logger:token("loadout", Loadouts.teal)
t.cmd = logger:token("cmd", Loadouts.teal)
t.args = logger:token("args", Loadouts.lightBlue)

local function log(log_level)
    return logger:log(log_level)
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
        log("error")
            :print("Loadout ")
            :print(setName):as(t.loadout)
            :print(" not recognized.")
            :flush()
        return
    end
    for slot, itemId in pairs(set) do
        EquipItemByName(itemId, slot)
    end
    log("debug")
        :print("Switched to ")
        :print(setName):as(t.loadout)
        :print(" set.")
        :flush()
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
            log("error")
                :print("Unable to determine slot for ")
                :print(itemName)
                :flush()
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
        local itemLink = formatItemLink(itemName)
        logger:log("info")
            :print(loadout):as(t.loadout)
            :print(" ", itemSlot)
            :print(" set to ")
            :print(itemLink)
            :flush()
    else
        logger:log("error")
            :print("Invalid loadout name: ")
            :print(loadout):as(t.slot)
            :flush()
    end
end

-- Function to clear equipment set slot
local function clearEquipmentSetSlot(loadout, slot)
    if equipmentSets[loadout] and equipmentSets[loadout][slot] then
        equipmentSets[loadout][slot] = nil
        log("info")
            :print("Cleared "):print(slot)
            :print(" from "):print(loadout):as(t.slot)
            :flush()
    else
        log("error"):print("Invalid loadout name or slot not set."):flush()
    end
end

-- Function to show equipment sets
local function showEquipmentSets()
    local l = log("always")
        :println("Equipment Sets:")
        :indent()
    for loadout, set in pairs(equipmentSets) do
        l:print(loadout):as(t.loadout):println(":"):indent()
        for slot, itemId in pairs(set) do
            l:print(slot):as(t.slot)
                :print(": ")
                :print(formatItemLink(itemId))
                :newline()
        end
        l:popIndent()
    end
    l:flush()
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

local function printColors()
    local l = log("info")
        :println("Available colors:")
        :indent()
    for colorName, colorCode in pairs(Loadouts.colorScheme) do
        l = l:print(colorName, ": ")
            :println(colorCode)
            :rgb(colorCode)
    end
    l:flush()
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
        ["_colors"] = {printColors, nil},
    }

    local args = {strsplit(" ", msg)}
    local command = args[1]

    if not command or commands[command] == nil then
        local l = log("info")
            :println("Available commands:")
            :indent()
        for cmd, fns in pairs(commands) do
            local _, help = unpack(fns)
            if help then
                l = l:print("/loadouts ")
                    :print(cmd):as(t.cmd)
                    :print(" ")
                    :println(help)
                    :as(t.args)
            end
        end
        l:flush()
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
            log("info"):print("Loadout settings loaded."):flush()
        end
    elseif event == "PLAYER_LOGOUT" then
        Loadouts_SavedSets = equipmentSets
    end
end)

log("info"):print("Loadouts loaded, use /loadouts for commands."):flush()
