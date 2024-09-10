
---@class BuffWatcher_Blizzard_Wrapper
BuffWatcher_Blizzard_Wrapper = {}

function BuffWatcher_Blizzard_Wrapper:new()
    self = {};

    return self;
end

---comment
---@param spellId number
---@return BuffWatcher_Blizzard_SpellInfo
BuffWatcher_Blizzard_Wrapper.GetSpellInfo = function(spellId)
   return C_Spell.GetSpellInfo(spellId)
end
