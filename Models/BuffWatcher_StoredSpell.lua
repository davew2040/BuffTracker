---@class BuffWatcher_StoredSpell
---@field spellId number
---@field buffType SpellTypes
---@field version number
---@field hide boolean
---@field showInParty boolean
---@field showInArena boolean
---@field showInRaid boolean
---@field showOnNameplates boolean
---@field showInBattlegrounds boolean
---@field showDispelTypeOutline boolean
---@field duration number
---@field showGlow boolean
---@field sizeMultiplier number
---@field priority number
---@field ownOnly boolean
---@field isMinorAura boolean
BuffWatcher_StoredSpell = {}

---@return BuffWatcher_StoredSpell
function BuffWatcher_StoredSpell:new()
    ---@type BuffWatcher_StoredSpell
    self = {
        spellId = 0,
        buffType = BuffWatcher_Shared_Singleton.SpellTypes.Any,
        version = 1,
        hide = false,
        showInParty = false,
        showInArena = false,
        showInRaid = false,
        showOnNameplates = false,
        showInBattlegrounds = false,
        showDispelTypeOutline = false,
        duration = 0,
        showGlow = false,
        sizeMultiplier = 1,
        priority = 0,
        ownOnly = false,
        isMinorAura = false
    }

    return self
end

---@param storedSpell BuffWatcher_StoredSpell
---@return string
function BuffWatcher_StoredSpell.GetStoredSpellKey(storedSpell)
    return storedSpell.buffType .. ":" .. storedSpell.spellId
end