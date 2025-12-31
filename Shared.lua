Loadouts = Loadouts or {}
Loadouts.Shared = Loadouts.Shared or {}


--[[
https://wowpedia.fandom.com/wiki/InventorySlotId
InvSlotName GlobalString (enUS) 	InvSlotId 	Constant 
AMMOSLOT WoW Icon update 	Ammo 	0 	INVSLOT_AMMO
HEADSLOT 	Head 	1 	INVSLOT_HEAD
NECKSLOT 	Neck 	2 	INVSLOT_NECK
SHOULDERSLOT 	Shoulders 	3 	INVSLOT_SHOULDER
SHIRTSLOT 	Shirt 	4 	INVSLOT_BODY
CHESTSLOT 	Chest 	5 	INVSLOT_CHEST
WAISTSLOT 	Waist 	6 	INVSLOT_WAIST
LEGSSLOT 	Legs 	7 	INVSLOT_LEGS
FEETSLOT 	Feet 	8 	INVSLOT_FEET
WRISTSLOT 	Wrist 	9 	INVSLOT_WRIST
HANDSSLOT 	Hands 	10 	INVSLOT_HAND
FINGER0SLOT 	Finger 	11 	INVSLOT_FINGER1
FINGER1SLOT 	Finger 	12 	INVSLOT_FINGER2
TRINKET0SLOT 	Trinket 	13 	INVSLOT_TRINKET1
TRINKET1SLOT 	Trinket 	14 	INVSLOT_TRINKET2
BACKSLOT 	Back 	15 	INVSLOT_BACK
MAINHANDSLOT 	Main Hand 	16 	INVSLOT_MAINHAND
SECOndaryhandslot 	Off Hand 	17 	INVSLOT_OFFHAND
RANGEDSLOT WoW Icon update 	Ranged 	18 	INVSLOT_RANGED
TABARDSLOT 	Tabard 	19 	INVSLOT_TABARD 
--]]

--[[
https://wowpedia.fandom.com/wiki/Enum.InventoryType
Enum.InventoryType Value 	Field 	ItemEquipLoc
GlobalString (enUS) 	InvSlotId
0 	IndexNonEquipType 	INVTYPE_NON_EQUIP 	Non-equippable 	
1 	IndexHeadType 	INVTYPE_HEAD 	Head 	1
2 	IndexNeckType 	INVTYPE_NECK 	Neck 	2
3 	IndexShoulderType 	INVTYPE_SHOULDER 	Shoulder 	3
4 	IndexBodyType 	INVTYPE_BODY 	Shirt 	4
5 	IndexChestType 	INVTYPE_CHEST 	Chest 	5
6 	IndexWaistType 	INVTYPE_WAIST 	Waist 	6
7 	IndexLegsType 	INVTYPE_LEGS 	Legs 	7
8 	IndexFeetType 	INVTYPE_FEET 	Feet 	8
9 	IndexWristType 	INVTYPE_WRIST 	Wrist 	9
10 	IndexHandType 	INVTYPE_HAND 	Hands 	10
11 	IndexFingerType 	INVTYPE_FINGER 	Finger 	11, 12
12 	IndexTrinketType 	INVTYPE_TRINKET 	Trinket 	13, 14
13 	IndexWeaponType 	INVTYPE_WEAPON 	One-Hand 	16, 17: Dual wield
14 	IndexShieldType 	INVTYPE_SHIELD 	Off Hand 	17
15 	IndexRangedType 	INVTYPE_RANGED 	Ranged 	16
16 	IndexCloakType 	INVTYPE_CLOAK 	Back 	15
17 	Index2HweaponType 	INVTYPE_2HWEAPON 	Two-Hand 	16
18 	IndexBagType 	INVTYPE_BAG 	Bag 	
19 	IndexTabardType 	INVTYPE_TABARD 	Tabard 	19
20 	IndexRobeType 	INVTYPE_ROBE 	Chest 	5
21 	IndexWeaponmainhandType 	INVTYPE_WEAPONMAINHAND 	Main Hand 	16
22 	IndexWeaponoffhandType 	INVTYPE_WEAPONOFFHAND 	Off Hand 	16
23 	IndexHoldableType 	INVTYPE_HOLDABLE 	Held In Off-hand 	17
24 	IndexAmmoType 	INVTYPE_AMMO 	Ammo 	
25 	IndexThrownType 	INVTYPE_THROWN 	Thrown 	16
26 	IndexRangedrightType 	INVTYPE_RANGEDRIGHT 	Ranged 	16
27 	IndexQuiverType 	INVTYPE_QUIVER 	Quiver 	
28 	IndexRelicType 	INVTYPE_RELIC 	Relic 	
29 	IndexProfessionToolType 	INVTYPE_PROFESSION_TOOL 	Profession Tool 	20, 23
30 	IndexProfessionGearType 	INVTYPE_PROFESSION_GEAR 	Profession Equipment 	21, 22, 24, 25
31 	IndexEquipablespellOffensiveType 	INVTYPE_EQUIPABLESPELL_OFFENSIVE 	Equipable Spell - Offensive 	
32 	IndexEquipablespellUtilityType 	INVTYPE_EQUIPABLESPELL_UTILITY 	Equipable Spell - Utility 	
33 	IndexEquipablespellDefensiveType 	INVTYPE_EQUIPABLESPELL_DEFENSIVE 	Equipable Spell - Defensive 	
34 	IndexEquipablespellWeaponType 	INVTYPE_EQUIPABLESPELL_WEAPON 	Equipable Spell - Weapon 	
--]]

Loadouts.Shared.SlotLocNames = {
    [0] = "AMMOSLOT",
    [1] = "HEADSLOT",
    [2] = "NECKSLOT",
    [3] = "SHOULDERSLOT",
    [4] = "SHIRTSLOT",
    [5] = "CHESTSLOT",
    [6] = "WAISTSLOT",
    [7] = "LEGSSLOT",
    [8] = "FEETSLOT",
    [9] = "WRISTSLOT",
    [10] = "HANDSSLOT",
    [11] = "FINGER0SLOT",
    [12] = "FINGER1SLOT",
    [13] = "TRINKET0SLOT",
    [14] = "TRINKET1SLOT",
    [15] = "BACKSLOT",
    [16] = "MAINHANDSLOT",
    [17] = "SECONDARYHANDSLOT",
    [18] = "RANGEDSLOT",
    [19] = "TABARDSLOT",
}

Loadouts.Shared.SlotLocs = {
    ["AMMOSLOT"] = 0,
    ["HEADSLOT"] = 1,
    ["NECKSLOT"] = 2,
    ["SHOULDERSLOT"] = 3,
    ["SHIRTSLOT"] = 4,
    ["CHESTSLOT"] = 5,
    ["WAISTSLOT"] = 6,
    ["LEGSSLOT"] = 7,
    ["FEETSLOT"] = 8,
    ["WRISTSLOT"] = 9,
    ["HANDSSLOT"] = 10,
    ["FINGER0SLOT"] = 11,
    ["FINGER1SLOT"] = 12,
    ["TRINKET0SLOT"] = 13,
    ["TRINKET1SLOT"] = 14,
    ["BACKSLOT"] = 15,
    ["MAINHANDSLOT"] = 16,
    ["SECONDARYHANDSLOT"] = 17,
    ["RANGEDSLOT"] = 18,
    ["TABARDSLOT"] = 19,
}

Loadouts.Shared.HumanSlotNames = {
    ["AMMOSLOT"] = "Ammo",
    ["HEADSLOT"] = "Head",
    ["NECKSLOT"] = "Neck",
    ["SHOULDERSLOT"] = "Shoulders",
    ["SHIRTSLOT"] = "Shirt",
    ["CHESTSLOT"] = "Chest",
    ["WAISTSLOT"] = "Waist",
    ["LEGSSLOT"] = "Legs",
    ["FEETSLOT"] = "Feet",
    ["WRISTSLOT"] = "Wrist",
    ["HANDSSLOT"] = "Hands",
    ["FINGER0SLOT"] = "Finger 1",
    ["FINGER1SLOT"] = "Finger 2",
    ["TRINKET0SLOT"] = "Trinket 1",
    ["TRINKET1SLOT"] = "Trinket 2",
    ["BACKSLOT"] = "Back",
    ["MAINHANDSLOT"] = "Main Hand",
    ["SECONDARYHANDSLOT"] = "Off Hand",
    ["RANGEDSLOT"] = "Ranged",
    ["TABARDSLOT"] = "Tabard",
}

Loadouts.Shared.InventorySlotNames = {
    ["AMMOSLOT"] = "INVSLOT_AMMO",
    ["HEADSLOT"] = "INVSLOT_HEAD",
    ["NECKSLOT"] = "INVSLOT_NECK",
    ["SHOULDERSLOT"] = "INVSLOT_SHOULDER",
    ["SHIRTSLOT"] = "INVSLOT_BODY",
    ["CHESTSLOT"] = "INVSLOT_CHEST",
    ["WAISTSLOT"] = "INVSLOT_WAIST",
    ["LEGSSLOT"] = "INVSLOT_LEGS",
    ["FEETSLOT"] = "INVSLOT_FEET",
    ["WRISTSLOT"] = "INVSLOT_WRIST",
    ["HANDSSLOT"] = "INVSLOT_HAND",
    ["FINGER0SLOT"] = "INVSLOT_FINGER1",
    ["FINGER1SLOT"] = "INVSLOT_FINGER2",
    ["TRINKET0SLOT"] = "INVSLOT_TRINKET1",
    ["TRINKET1SLOT"] = "INVSLOT_TRINKET2",
    ["BACKSLOT"] = "INVSLOT_BACK",
    ["MAINHANDSLOT"] = "INVSLOT_MAINHAND",
    ["SECONDARYHANDSLOT"] = "INVSLOT_OFFHAND",
    ["RANGEDSLOT"] = "INVSLOT_RANGED",
    ["TABARDSLOT"] = "INVSLOT_TABARD",
}

Loadouts.Shared.ItemTypeSlots = {
    ["INVTYPE_NON_EQUIP"] = {},
    ["INVTYPE_HEAD"] = {1},
    ["INVTYPE_NECK"] = {2},
    ["INVTYPE_SHOULDER"] = {3},
    ["INVTYPE_BODY"] = {4},
    ["INVTYPE_CHEST"] = {5},
    ["INVTYPE_WAIST"] = {6},
    ["INVTYPE_LEGS"] = {7},
    ["INVTYPE_FEET"] = {8},
    ["INVTYPE_WRIST"] = {9},
    ["INVTYPE_HAND"] = {10},
    ["INVTYPE_FINGER"] = {11, 12},
    ["INVTYPE_TRINKET"] = {13, 14},
    ["INVTYPE_WEAPON"] = {16, 17},
    ["INVTYPE_SHIELD"] = {17},
    ["INVTYPE_RANGED"] = {18},
    ["INVTYPE_CLOAK"] = {15},
    ["INVTYPE_2HWEAPON"] = {16},
    ["INVTYPE_BAG"] = {},
    ["INVTYPE_TABARD"] = {19},
    ["INVTYPE_ROBE"] = {5},
    ["INVTYPE_WEAPONMAINHAND"] = {16},
    ["INVTYPE_WEAPONOFFHAND"] = {17},
    ["INVTYPE_HOLDABLE"] = {},
    ["INVTYPE_AMMO"] = {},
    ["INVTYPE_THROWN"] = {18},
    ["INVTYPE_RANGEDRIGHT"] = {18},
    ["INVTYPE_QUIVER"] = {},
    ["INVTYPE_RELIC"] = {18},
}
