---@class BuffWatcher_Blizzard_AuraData
---@field name string
---@field spellId integer
---@field dispelName? string
---@field auraInstanceID integer
---@field isHelpful boolean
---@field isHarmful boolean
---@field sourceUnit string
---@field duration number
---@field expirationTime number
---@field isFromPlayerOrPlayerPet boolean

---@class BuffWatcher_Blizzard_UnitAura
---@field name string
---@field icon string,
---@field count number
---@field duration number
---@field expirationTime number,
---@field source string
---@field spellId number

---@class BuffWatcher_Blizzard_SpellInfo
---@field name string
---@field iconID number,
---@field spellID number


---@class BuffWatcher_Blizzard_UnitAuraUpdateInfo
---@field addedAuras BuffWatcher_Blizzard_AuraData[]
---@field updatedAuraInstanceIDs integer[]
---@field removedAuraInstanceIDs integer[]
---@field isFullUpdate boolean

---@class BuffWatcher_Blizzard_CastInfo
---@field spellId integer
---@field sourceName string
---@field sourceGuid string

---@class BuffWatcher_Blizzard_Frame

---@class BuffWatcher_Blizzard_CombatLogEntry
---@field timestamp number
---@field subevent string
---@field hideCaster boolean
---@field sourceGUID string
---@field sourceName string
---@field destGUID string
---@field spellID number