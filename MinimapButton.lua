local DBIcon = LibStub:GetLibrary("LibDBIcon-1.0", true)

if not DBIcon then
    Loadouts.Lib.log("always")
        :print("Loadouts: DBIcon not found; minimap button disabled.")
        :flush()
    return
end

LoadoutsDB = LoadoutsDB or {
    minimap = { hide = false },
}

local addonName = "Loadouts"
local ldb = LibStub("LibDataBroker-1.1"):NewDataObject(addonName,  {
    type = "launcher",
    icon = 626008, -- ClassIcon Warrior
    OnClick = function(_, button)
        if button == "LeftButton" then
            Loadouts.UI.OpenUI()
        end
    end,
    OnTooltipShow = function(tt)
        tt:AddLine("Loadouts")
        tt:AddLine("Left-click: Open UI", 1, 1, 1)
    end,
})

DBIcon:Register(addonName, ldb, LoadoutsDB.minimap)
