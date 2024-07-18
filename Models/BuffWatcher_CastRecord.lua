---@class BuffWatcher_CastRecord
---@field type SpellTypes
---@field spellId integer
---@field spellName string
---@field loweredName string
---@field sourceName string
---@field loweredCaster string
---@field duration integer
---@field key string
BuffWatcher_CastRecord = {}

local keyMaker = {}

---@param type SpellTypes
---@param spellId integer
---@param spellName string
---@param sourceName string
---@return BuffWatcher_CastRecord
function BuffWatcher_CastRecord:new(type, spellId, spellName, sourceName)
    ---@type BuffWatcher_CastRecord
    self = {
        type = type,
        spellName = spellName,
        spellId = spellId,
        loweredName = string.lower(spellName),
        sourceName = sourceName, 
        loweredCaster = string.lower(sourceName), 
        duration = 0,
        key = ""
    }

    self.key = BuffWatcher_CastRecord.GetKey(self)

    return self
end

---@param record BuffWatcher_CastRecord
---@return string
BuffWatcher_CastRecord.GetKey = function(record)
    keyMaker[1] = record.type
    keyMaker[2] = record.spellId
    return table.concat(keyMaker, ":")
end

---@param spellType SpellTypes
---@param spellId number
---@return string
BuffWatcher_CastRecord.GetKeyFromParams = function(spellType, spellId)
    keyMaker[1] = spellType
    keyMaker[2] = spellId
    return table.concat(keyMaker, ":")
end