---@class BuffWatcher_SpellBundle
---@field buffs table<number, BuffWatcher_StoredSpell>
---@field debuffs table<number, BuffWatcher_StoredSpell>
---@field casts table<number, BuffWatcher_StoredSpell>
BuffWatcher_SpellBundle = {}

function BuffWatcher_SpellBundle:new()
    ---@type BuffWatcher_SpellBundle
    self = {
        buffs = {},
        debuffs = {},
        casts = {}
    }

    return self;
end