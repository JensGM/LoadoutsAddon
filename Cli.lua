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

local function updateEquipmentSetById(loadout, ...)
    local result = Loadouts.Lib.updateEquipmentSetById(loadout, ...)
    result = LogErr(result)
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

local function setLogLevel(loglevel)
    loglevel = strip(loglevel)
    if not Loadouts.logLevels[loglevel] then
        log("error")
            :print("Invalid log level: ")
            :print(loglevel)
            :flush()
        return
    end
    Loadouts.Lib.setLogLevel(loglevel)
    log("info")
        :print("Log level set to ")
        :print(loglevel)
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
                local fn = Loadouts.UI and Loadouts.UI.OpenUI
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
        ["loglevel"] = {fn = setLogLevel, help = "loglevel"},
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
