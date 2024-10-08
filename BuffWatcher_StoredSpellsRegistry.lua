---@class BuffWatcher_StoredSpellsRegistry
BuffWatcher_StoredSpellsRegistry = {}

function BuffWatcher_StoredSpellsRegistry:new()
    self = {}

    local AddEventName = "SPELL_ADDED"
    local RemoveEventName = "SPELL_REMOVED"
    local SpellsChangedEventName = "SPELLS_CHANGED"

    local events = BuffWatcher_Callbacks:new()

    ---@return table<string, BuffWatcher_StoredSpell>
    local readSpells = function()
        local defaultStoredRecord = BuffWatcher_Shared.GetDefaultStoredSpell()
        local dbSpells = BuffWatcher_DbAccessor_Singleton.GetSpells()

        ---@type table<string, BuffWatcher_StoredSpell>
        local allResults = {}

        for _, dbSpell in pairs(dbSpells) do
            ---@type BuffWatcher_StoredSpell
            local singleResult = {}

            for key, _ in pairs(defaultStoredRecord) do
                if (dbSpell[key] ~= nil) then
                    singleResult[key] = dbSpell[key]
                end
            end

            if (BuffWatcher_Blizzard_Wrapper.GetSpellInfo(dbSpell.spellId) ~= nil) then
                allResults[BuffWatcher_StoredSpell.GetStoredSpellKey(singleResult)] = singleResult
            end
        end

        return allResults
    end

    ---@param key string
    ---@param newSpell BuffWatcher_StoredSpell
    ---@param currentSpells table<string, BuffWatcher_StoredSpell>
    ---@param defaultSpell BuffWatcher_StoredSpell
    local validateNewEntry = function(key, newSpell, currentSpells, defaultSpell)
        if (currentSpells[key] ~= nil) then 
            return false
        end

        if (newSpell.buffType == defaultSpell.buffType) then
            return false
        end

        if (newSpell.spellId == defaultSpell.spellId) then
            return false
        end

        return true
    end

    ---@param spells table<string, BuffWatcher_StoredSpell>
    self.saveSpellsToDatabase = function(spells)
        BuffWatcher_DbAccessor_Singleton.SaveStoredSpells(spells)
        events.fire(SpellsChangedEventName)
    end

    ---@param imports any[]
    self.importSpells = function(imports)
        local baseline = BuffWatcher_Shared.GetDefaultStoredSpell();
        local dbSpells = BuffWatcher_DbAccessor_Singleton.GetSpells()

        DevTool:AddData(dbSpells, "fixme dbSpells")

        for i,importedSpell in ipairs(imports) do
            local newEntry = BuffWatcher_Shared.GetDefaultStoredSpell()
            BuffWatcher_Shared.PatchTable(newEntry, importedSpell)

            local key = BuffWatcher_StoredSpell.GetStoredSpellKey(newEntry)
            if (validateNewEntry(key, newEntry, dbSpells, baseline)) then 
                DevTool:AddData(newEntry, "fixme adding new spell")

                dbSpells[key] = newEntry
            end
        end

        BuffWatcher_DbAccessor_Singleton.SaveStoredSpells(dbSpells)
    end

    ---@param castRecord BuffWatcher_CastRecord
    ---@return boolean
    self.hasSpell = function(castRecord) 
        local storedSpells = readSpells()
        return storedSpells[castRecord.key] ~= nil 
    end

    ---comment
    ---@param castRecord BuffWatcher_CastRecord
    self.addSpell = function(castRecord) 
        local storedSpells = readSpells()
        storedSpells[castRecord.key] = BuffWatcher_Shared_Singleton.StoredSpellFromCastRecord(castRecord)
        self.saveSpellsToDatabase(storedSpells)
        events.fire(AddEventName)
        events.fire(SpellsChangedEventName)
    end

    self.removeSpell = function(storedSpell) 
        local key = BuffWatcher_StoredSpell.GetStoredSpellKey(storedSpell)
        local spells = readSpells()
        spells[key] = nil
        self.saveSpellsToDatabase(spells)
        events.fire(RemoveEventName)
        events.fire(SpellsChangedEventName)
    end

    self.GetSpells = function()
        local spells = readSpells()
        return spells
    end

    self.registerSpellAdded = function(callback)
        events.registerCallback(AddEventName, callback)
    end

    self.registerSpellRemoved = function(callback)
        events.registerCallback(RemoveEventName, callback)
    end

    self.registerSpellsChanged = function(callback)
        events.registerCallback(SpellsChangedEventName, callback)
    end

    return self
end