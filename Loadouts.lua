-- Loadouts

local frame = CreateFrame("Frame", "LoadoutsFrame", UIParent)
local weaponSets = {}

-- Function to print messages
local function Print(msg, color)
    DEFAULT_CHAT_FRAME:AddMessage("|cff" .. color .. "Loadouts:|r " .. msg)
end

-- Helper function to format item links
local function FormatItemLink(itemID)
    local itemLink = select(2, GetItemInfo(itemID)) or "|cffffffff|Hitem:" .. itemID .. "|h[Unknown Item]|h|r"
    return itemLink
end

-- Function to equip a weapon set
local function EquipWeaponSet(setName)
    local set = weaponSets[setName]
    if not set then
        Print("Loadout '" .. setName .. "' not recognized.", "ff0000")
        return
    end
    if set.mainHand ~= 0 then
        EquipItemByName(set.mainHand, 16) -- Main hand slot
    end
    if set.offHand ~= 0 then
        EquipItemByName(set.offHand, 17) -- Off-hand slot
    end
    Print("Switched to " .. setName .. " set.", "00ff00")
end

-- Function to update weapon set by ID
local function UpdateWeaponSetById(loadout, slot, itemID)
    if weaponSets[loadout] and (slot == "mainHand" or slot == "offHand") then
        weaponSets[loadout][slot] = itemID
        Print(loadout .. "." .. slot .. " set to " .. FormatItemLink(itemID) .. ".", "00ff00")
    else
        Print("Invalid loadout or slot name.", "ff0000")
    end
end

-- Function to update weapon set by name
local function UpdateWeaponSetByName(loadout, slot, itemName)
    local itemID = GetItemInfo(itemName)
    if itemID then
        UpdateWeaponSetById(loadout, slot, itemID)
    else
        Print("Item '" .. itemName .. "' not found.", "ff0000")
    end
end

-- Function to show weapon sets
local function ShowWeaponSets()
    Print("Weapon Sets:", "ffff00")
    for loadout, set in pairs(weaponSets) do
        Print(loadout .. ":", "ffff00")

        -- Update the code to use the helper function
        local mainHandLink = FormatItemLink(set.mainHand)
        local offHandLink = FormatItemLink(set.offHand)

        -- Print item links with YAML-like layout
        Print("  mainHand: " .. mainHandLink, "ffffff")
        Print("  offHand: " .. offHandLink, "ffffff")
    end
end

-- Function to create a new weapon set
local function CreateWeaponSet(setName)
    if weaponSets[setName] then
        Print("Loadout '" .. setName .. "' already exists.", "ff0000")
        return
    end
    weaponSets[setName] = {
        mainHand = 0,
        offHand = 0
    }
    Print("Loadout '" .. setName .. "' created.", "00ff00")
end

-- Function to remove a weapon set
local function RemoveWeaponSet(setName)
    if not weaponSets[setName] then
        Print("Loadout '" .. setName .. "' not found.", "ff0000")
        return
    end
    weaponSets[setName] = nil
    Print("Loadout '" .. setName .. "' removed.", "00ff00")
end

-- Slash command for loadouts
SLASH_LOADOUTS1 = "/loadouts"
SlashCmdList["LOADOUTS"] = function(msg)
    local args = { strsplit(" ", msg) }
    local command = args[1]
    if command == "set" then
        if args[2] and args[3] and args[4] then
            local loadout, slot = strsplit(".", args[2])
            local itemName = table.concat(args, " ", 3)
            -- Check if the loadout and slot names are valid
            if weaponSets[loadout] and (slot == "mainHand" or slot == "offHand") then
                UpdateWeaponSetByName(loadout, slot, itemName)
            else
                Print("Invalid loadout or slot name.", "ff0000")
            end
        else
            Print("Usage: /loadouts set [loadout].[mainHand|offHand] [item name]", "ff0000")
        end
    elseif command == "equip" then
        if args[2] then
            EquipWeaponSet(args[2])
        else
            Print("Please specify a loadout name.", "ff0000")
        end
    elseif command == "show" then
        ShowWeaponSets()
    elseif command == "new" then
        if args[2] then
            CreateWeaponSet(args[2])
        else
            Print("Please specify a loadout name.", "ff0000")
        end
    elseif command == "rm" then
        if args[2] then
            RemoveWeaponSet(args[2])
        else
            Print("Please specify a loadout name.", "ff0000")
        end
    else
        Print("Commands:\n- /loadouts set [loadout].[mainHand|offHand] [item name]\n- /loadouts equip [loadout]\n- /loadouts show\n- /loadouts new [loadout]\n- /loadouts rm [loadout]", "ffff00")
    end
end

-- Event handling for saving and loading settings
frame:RegisterEvent("PLAYER_LOGOUT")
frame:RegisterEvent("ADDON_LOADED")
frame:SetScript("OnEvent", function(self, event, arg1, ...)
    if event == "ADDON_LOADED" and arg1 == "Loadouts" then
        -- Load saved variables into weaponSets or initialize if not present
        if Loadouts_SavedSets then
            weaponSets = Loadouts_SavedSets
            Print("Loadout settings loaded.", "00ff00")
        end
    elseif event == "PLAYER_LOGOUT" then
        -- Save the weaponSets to saved variables
        Loadouts_SavedSets = weaponSets
    end
end)

Print("Addon loaded. Use /loadouts for commands.", "00ff00")
