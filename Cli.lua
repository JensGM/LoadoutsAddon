-- imports
local unpack = unpack or table.unpack
local formatItemLink = Loadouts.Lib.formatItemLink
local itemName = Loadouts.Lib.itemName
local log = Loadouts.Lib.log
local t = Loadouts.Tokens

local function LogErr(result)
    if result.isError then
        result.error:flush()
    end
    return result
end

local function updateEquipmentSetById(loadout, ...)
    local itemArgs = {...}
    local itemString = table.concat(itemArgs, " ")

    local function parseItem(itemString)
        local pattern = "^([^\|:]*):?(.*)$"
        local fst, snd = itemString:match(pattern)
        local itemSlot, itemName

        if snd ~= "" then
            itemSlot = tonumber(fst)
            itemName = snd
        else
            itemName = itemString
        end

        -- if item string is an item link, extract the item ID
        if itemName:find("|") then
            local itemId = {strsplit(":", itemName)}
            itemId = tonumber(itemId[2])
            return itemSlot, itemId
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

        local _, _, _, _, _, _, _, _, itemEquipLoc = GetItemInfo(itemName)
        if not itemEquipLoc or not equipLocToSlotName[itemEquipLoc] then
            log("error")
                :print("Unable to determine slot for ")
                :print(itemName)
                :print(" ")
                :print(itemEquipLoc)
                :flush()
            return nil
        end

        local slotName = equipLocToSlotName[itemEquipLoc]
        local slotNumberString = GetInventorySlotInfo(slotName)

        return slotNumberString
    end

    local itemSlotString, itemName = parseItem(itemString)

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

    if Loadouts_SavedSets[loadout] then
        Loadouts_SavedSets[loadout][itemSlot] = itemName
        local itemLink = formatItemLink(itemName)
        log("info")
            :print(loadout):as(t.loadout)
            :print("["):print(itemSlot):as(t.slot):print("]")
            :print(" set to ")
            :print(itemLink)
            :flush()
    else
        log("error")
            :print("Invalid loadout name: ")
            :print(loadout):as(t.loadout)
            :flush()
    end
end

-- Function to show equipment sets
local function showEquipmentSets()
    local l = log("always")
        :println("Equipment Sets:")
        :indent()
    for loadout, set in pairs(Loadouts_SavedSets) do
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

-- CLI functions

local function strip(s)
    return s:gsub("^%s+", ""):gsub("%s+$", "")
end

local function validateSetName(setName)
    setName = strip(setName)
    if setName == nil or setName == "" then
        return Monad.Result.err(log("error")
            :print("Loadout name not specified.")
        )
    end
    return Monad.Result.ok(setName)
end

local createEquipmentSet = Monad.F(LogErr)
  .. Monad.K(validateSetName)
  .. Monad.K(Loadouts.Lib.createEquipmentSet)

local removeEquipmentSet = Monad.F(LogErr)
  .. Monad.K(validateSetName)
  .. Monad.K(Loadouts.Lib.removeEquipmentSet)

local equipEquipmentSet = Monad.F(LogErr)
  .. Monad.K(validateSetName)
  .. Monad.K(Loadouts.Lib.equipEquipmentSet)

local function renameEquipmentSet(oldName, newName)
    oldName = strip(oldName)
    newName = strip(newName)

    if not oldName or oldName == "" then
        log("error")
            :print("Old loadout name not specified.")
            :flush()
        return
    end

    if not newName or newName == "" then
        log("error")
            :print("New loadout name not specified.")
            :flush()
        return
    end

    local result = Loadouts.Lib.renameEquipmentSet(oldName, newName)
    if result.isError then
        result.error:flush()
    end
    return result
end 

local function clearEquipmentSetSlot(loadout, slotId)
    loadout = strip(loadout)
    slotId = strip(slotId)
    slotId = tonumber(slotId)

    if not loadout or loadout == "" then
        log("error")
            :print("Loadout name not specified.")
            :flush()
        return
    end

    if not slotId then
        log("error")
            :print("Invalid slot ID: ")
            :print(slotId)
            :flush()
        return
    end

    local result = Loadouts.Lib.clearEquipmentSetSlot(loadout, slotId)
    if result.isError then
        result.error:flush()
    end
    return result
end

local updateCharacterMacros = Loadouts.Lib.updateCharacterMacros

local printColors = Loadouts.Lib.printColors
local deleteAll = Loadouts.Lib.deleteAllEquipmentSets

local function tutorial(...)
    log("always")
        :println("Welcome to Loadouts!")
        :println("To get started, try creating a new loadout with")
        :indent():println("/loadouts new <loadoutName>"):as(t.cmd):popIndent()
        :println("Then, add items to the loadout with")
        :indent():println("/loadouts set <loadoutName> <slotId:>?<itemName>"):as(t.cmd):popIndent()
        :println("Finally, use the loadout in a macro:")
        :indent()
        :println("#showtooltip"):as(t.code)
        :println("-@<loadoutName>"):as(t.code)
        :println("-@"):as(t.code)
        :println("/cast [stance:1/2] Spell Reflection"):as(t.code)
        :println("")
        :println("Loadouts will add and manage lines between")
        :print("the ")
        :print("-@<loadoutName>"):as(t.code)
        :print(" and ")
        :print("-@"):as(t.code)
        :println(" lines.")
        :popIndent()
        :println("For more information, use /loadouts")
        :flush()
end

-- CLI Setup

SLASH_LOADOUTS1 = "/loadouts"
SLASH_LOADOUTS2 = "/loadout"
SLASH_LOADOUTS3 = "/ld"
SlashCmdList["LOADOUTS"] = function(msg)
    local commands = {
        ["open"] = {
            fn = function()
                local fn = Loadouts.UI and Loadouts.UI.ToggleUI
                if fn then
                    fn()
                else
                    log("error")
                        :println("Loadouts UI not found.")
                        :flush()
                end
            end,
        },
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
        ["rename"] = {fn = renameEquipmentSet, help = "oldName newName"},
        ["clear"] = {
            fn = clearEquipmentSetSlot,
            postExec = {updateCharacterMacros},
            help = "loadoutName slotId"
        },
        ["refreshMacros"] = {fn = updateCharacterMacros, help = ""},
        ["tutorial"] = {fn = tutorial, help = ""},
        ["_colors"] = {fn = printColors},
        ["_deleteAll"] = {fn = deleteAll},
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

log("info"):print("Loadouts loaded, use /loadouts for commands."):flush()
