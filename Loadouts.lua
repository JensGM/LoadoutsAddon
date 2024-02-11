local frame = CreateFrame("Frame", "LoadoutsFrame", UIParent)
local equipmentSets = {}

local logger = Loadouts.Logger:new()
local t = {}
t.slot = logger:token("slot", Loadouts.lightBlue)
t.loadout = logger:token("loadout", Loadouts.teal)
t.macro = logger:token("macro", Loadouts.blue)
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

local function itemName(itemId)
    return select(1, GetItemInfo(itemId))
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
            itemSlot = tonumber(fst)
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

        return slotNumberString
    end

    local itemSlotString, itemName = parseItem(itemArgs)
    if not itemSlotString then
        itemSlotString = determineItemSlot(itemName)
    end
    local itemSlot = tonumber(itemSlotString)

    if not itemSlot then
        log("error")
            :print("Invalid slot: ")
            :print(itemSlotString)
            :flush()
        return
    end

    if equipmentSets[loadout] then
        equipmentSets[loadout][itemSlot] = itemName
        local itemLink = formatItemLink(itemName)
        logger:log("info")
            :print(loadout):as(t.loadout)
            :print("["):print(itemSlot):as(t.slot):print("]")
            :print(" set to ")
            :print(itemLink)
            :flush()
    else
        logger:log("error")
            :print("Invalid loadout name: ")
            :print(loadout):as(t.loadout)
            :flush()
    end
end

-- Function to clear equipment set slot
local function clearEquipmentSetSlot(loadout, slot)
    if not loadout then
        log("error"):print("Loadout not specified."):flush()
        return
    end
    if not equipmentSets[loadout] then
        log("error")
            :print("Loadout ")
            :print(loadout):as(t.loadout)
            :print(" not found.")
            :flush()
        return
    end

    if not slot then
        log("error")
            :print("Slot not specified.")
            :flush()
        return
    end

    local slotNumber = tonumber(slot) or slot

    equipmentSets[loadout][slotNumber] = nil
    log("info")
        :print("Cleared "):print(slotNumber)
        :print(" from "):print(loadout):as(t.slot)
        :flush()
end

-- Function to show equipment sets
local function showEquipmentSets()
    local l = log("always")
        :println("Equipment Sets:")
        :indent()
    for loadout, set in pairs(equipmentSets) do
        l:print(loadout):as(t.loadout):println(":"):indent()
        for slot, itemId in pairs(set) do
            local as_str = "" .. slot;
            if not tonumber(slot) then
                log("error")
                    :print("Invalid slot: ")
                    :print(slot)
                    :flush()
                set[slot] = nil
            end
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
        log("error")
            :print("Loadout ")
            :print(setName):as(t.loadout)
            :print(" already exists.")
            :flush()
        return
    end
    equipmentSets[setName] = {}
    log("info")
        :print("Loadout ")
        :print(setName):as(t.loadout)
        :print(" created.")
        :flush()
end

-- Function to remove an equipment set
local function removeEquipmentSet(setName)
    if not equipmentSets[setName] then
        log("error")
            :print("Loadout ")
            :print(setName):as(t.loadout)
            :print(" not found.")
            :flush()
        return
    end
    equipmentSets[setName] = nil
    log("info")
        :print("Loadout ")
        :print(setName):as(t.loadout)
        :print(" removed.")
        :flush()
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

local function deleteAll()
    equipmentSets = {}
    log("info")
        :println("All loadouts deleted.")
        :flush()
end

-- Function to update all macros with equipment set commands
local function updateCharacterMacros(...)
    local pattern = "-@([^\n]+)\n[^@]*-@"
    local characterMacroStart = 1
    local characterMacroEnd = 256
    for i = characterMacroStart, characterMacroEnd do
        local name, _, body = GetMacroInfo(i)
        local setName = body and body:match(pattern)
        if setName then
            local set = equipmentSets[setName] or {}

            local equipCmds = {"-@" .. setName}
            for slot, itemId in pairs(set) do
                local itemName = itemName(itemId)
                local cmd = "/equipslot " .. slot .. " " .. itemName
                table.insert(equipCmds, cmd)
            end
            table.insert(equipCmds, "-@")
            local newBody = body:gsub(pattern, table.concat(equipCmds, "\n"))
            if newBody ~= body then
                EditMacro(i, name, nil, newBody, 1, 1)
                log("info")
                    :indent()
                    :print("+ "):print(name):as(t.macro)
                    :flush()
            end
        end
    end
end

-- Slash commands for loadouts
SLASH_LOADOUTS1 = "/loadouts"
SlashCmdList["LOADOUTS"] = function(msg)
    local commands = {
        ["set"] = {
            fn = updateEquipmentSetById,
            postExec = {updateCharacterMacros},
            help = "loadoutName (slotId:)?[item name]"
        },
        ["equip"] = {fn = equipEquipmentSet, help = "loadoutName"},
        ["show"] = {fn = showEquipmentSets, help = ""},
        ["new"] = {fn = createEquipmentSet, help = "loadoutName"},
        ["rm"] = {
            fn = removeEquipmentSet,
            postExec = {updateCharacterMacros},
            help = "loadoutName"
        },
        ["clear"] = {
            fn = clearEquipmentSetSlot,
            postExec = {updateCharacterMacros},
            help = "loadoutName slotId"},
        ["_colors"] = {fn = printColors},
        ["_deleteAll"] = {fn = deleteAll},
        ["_updateMacros"] = {fn = updateCharacterMacros},
    }

    local args = {strsplit(" ", msg)}
    local command = args[1]

    if not command or commands[command] == nil then
        local l = log("info")
            :println("Available commands:")
            :indent()
        for cmd, fns in pairs(commands) do
            if fns.help then
                l = l:print("/loadouts ")
                    :print(cmd):as(t.cmd)
                    :print(" ")
                    :println(fns.help)
                    :as(t.args)
            end
        end
        l:flush()
        return
    end

    local cmd = commands[command]
    table.remove(args, 1)

    if #args == 0 then
        cmd.fn()
    else
        cmd.fn(unpack(args))
    end

    for _, postExec in ipairs(cmd.postExec or {}) do
        postExec(unpack(args))
    end
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
