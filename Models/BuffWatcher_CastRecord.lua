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
function BuffWatcher_CastRecord.GetKey(record)
    return record.type .. ":" .. record.spellId
end