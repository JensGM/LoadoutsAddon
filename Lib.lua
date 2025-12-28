Loadouts.Lib = Loadouts.Lib or {}

-- Logging

local logger = Loadouts.Logger:new()
Loadouts.Tokens = {}
local t = Loadouts.Tokens
t.slot = logger:token("slot", Loadouts.lightBlue)
t.loadout = logger:token("loadout", Loadouts.teal)
t.macro = logger:token("macro", Loadouts.blue)
t.code = logger:token("code", Loadouts.teal)
t.cmd = logger:token("cmd", Loadouts.teal)
t.args = logger:token("args", Loadouts.lightBlue)

function Loadouts.Lib.log(log_level)
    return logger:log(log_level)
end

local log = Loadouts.Lib.log

-- Helpers

function Loadouts.Lib.formatItemLink(itemId)
    local itemLink = select(2, GetItemInfo(itemId)) or "|cffffffff|Hitem:" .. itemId .. "|h[Unknown Item]|h|r"
    return itemLink
end

function Loadouts.Lib.itemName(itemId)
    return select(1, GetItemInfo(itemId))
end

-- Macros

Loadouts.Lib.macro_pattern = "-@([^\n]+)\n[^@]*-@"

function Loadouts.Lib.findMacrosContainingSets()
    local characterMacroStart = 1
    local characterMacroEnd = 256
    local macros = {}
    for i = characterMacroStart, characterMacroEnd do
        local name, _, body = GetMacroInfo(i)
        local setName = body and body:match(Loadouts.Lib.macro_pattern)
        if setName then
            if not macros[setName] then
                macros[setName] = {}
            end
            macros[setName][name] = {
                name = name,
                index = i,
                setName = setName,
                body = body,
            }
        end
    end
    return macros
end

function Loadouts.Lib.equipslotCommands(setName)
    local set = Loadouts.Lib.getEquipmentSet(setName)
    if set.isError then
        log("error")
            :print("Cannot generate loadout commands for ")
            :print(setName):as(t.loadout)
            :print(". Error: " )
            :flush()
        err:flush()
        log("error")
            :print("Using empty set instead.")
            :flush()
        set = {}
    end
    set = set.value

    local equipCmds = {"-@" .. setName}
    for slot, itemId in pairs(set or {}) do
        local itemName = Loadouts.Lib.itemName(itemId)
        local cmd = "/equipslot " .. slot .. " " .. itemName
        table.insert(equipCmds, cmd)
    end
    table.insert(equipCmds, "-@")

    return table.concat(equipCmds, "\n")
end

function Loadouts.Lib.updateMacro(macro)
    local setName = macro.setName
    local equipCmds = Loadouts.Lib.equipslotCommands(setName)
    local newBody = macro.body:gsub(Loadouts.Lib.macro_pattern, equipCmds)
    if newBody ~= macro.body then
        EditMacro(macro.index, macro.name, nil, newBody, 1, 1)
        log("info")
            :indent()
            :print("+ "):print(macro.name):as(t.macro)
            :flush()
    end
end

function Loadouts.Lib.updateCharacterMacros()
    local macros = Loadouts.Lib.findMacrosContainingSets()
    for _, macroSet in pairs(macros) do
        for _, macro in pairs(macroSet) do
            Loadouts.Lib.updateMacro(macro)
        end
    end
end

-- Equipment Sets

-- string -> Result<void, string>
function Loadouts.Lib.createEquipmentSet(setName)
    if Loadouts_SavedSets[setName] then
        return Monad.Result.err(log("error")
            :print("Loadout ")
            :print(setName):as(t.loadout)
            :print(" already exists.")
        )
    end
    Loadouts_SavedSets[setName] = {}
    log("info")
        :print("Loadout ")
        :print(setName):as(t.loadout)
        :print(" created.")
        :flush()
    return Monad.Result.ok()
end

-- string -> Result<void, string>
function Loadouts.Lib.removeEquipmentSet(setName)
    local set = Loadouts.Lib.getEquipmentSet(setName)
    if set.isError then return set end
    set = set.value
    
    Loadouts_SavedSets[setName] = nil
    log("info")
        :print("Loadout ")
        :print(setName):as(t.loadout)
        :print(" removed.")
        :flush()
    return Monad.Result.ok()
end

-- string -> Result<EquipmentSet, string>
function Loadouts.Lib.getEquipmentSet(setName)
    local set = Loadouts_SavedSets[setName]
    if not set then
        return Monad.Result.err(log("error")
            :print("Loadout ")
            :print(setName):as(t.loadout)
            :print(" not recognized.")
        )
    end
    return Monad.Result.ok(set)
end

-- string -> Result<void, string>
function Loadouts.Lib.equipEquipmentSet(setName)
    local set = Loadouts.Lib.getEquipmentSet(setName)
    if set.isError then return set end
    set = set.value
    
    for slot, itemId in pairs(set) do
        EquipItemByName(itemId, slot)
    end
    log("debug")
        :print("Switched to ")
        :print(setName):as(t.loadout)
        :print(" set.")
        :flush()
    return Monad.Result.ok()
end

-- (string, string) -> Result<string, string>
function Loadouts.Lib.renameEquipmentSet(oldName, newName)
    local set = Loadouts.Lib.getEquipmentSet(oldName)
    if set.isError then return set end
    set = set.value
    
    Loadouts_SavedSets[newName] = set
    Loadouts_SavedSets[oldName] = nil

    local macros = Loadouts.Lib.findMacrosContainingSets()[oldName]
    for _, macro in pairs(macros or {}) do
        macro.body = macro.body:gsub("-@" .. oldName, "-@" .. newName)
        EditMacro(macro.index, macro.name, nil, macro.body, 1, 1)
        log("info")
            :indent()
            :print("+ "):print(macro.name):as(t.macro)
            :flush()
    end

    log("info")
        :print("Loadout ")
        :print(oldName):as(t.loadout)
        :print(" renamed to ")
        :print(newName):as(t.loadout)
        :flush()
    return Monad.Result.ok(newName)
end

-- (string, string|number) -> Result<void, string>
function Loadouts.Lib.clearEquipmentSetSlot(setName, slot)
    local set = Loadouts.Lib.getEquipmentSet(setName)
    if set then return set end
    set = set.value

    local slotNumber = tonumber(slot) or slot
    set[slotNumber] = nil

    log("info")
        :print("Cleared "):print(slotNumber)
        :print(" from "):print(setName):as(t.loadout)
        :flush()
    return Monad.Result.ok()
end

-- Utilities

function Loadouts.Lib.printColors()
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

function Loadouts.Lib.deleteAllEquipmentSets()
    Loadouts_SavedSets = {}
    log("info")
        :println("All loadouts deleted.")
        :flush()
end

