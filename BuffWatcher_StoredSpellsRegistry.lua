BuffWatcher_StoredSpellsRegistry = {}

function BuffWatcher_StoredSpellsRegistry:new()
    self = {}

    local AddEventName = "SPELL_ADDED"
    local RemoveEventName = "SPELL_REMOVED"

    local events = BuffWatcher_Callbacks:new()

    local readSpells = function()
        local defaultStoredRecord = BuffWatcher_Shared_Singleton.GetDefaultStoredSpell()
        local dbSpells = BuffWatcher_DbAccessor_Singleton.GetSpells()

        local allResults = {}
        for _, dbSpell in pairs(dbSpells) do
            local singleResult = {}

            for key, _ in pairs(defaultStoredRecord) do
                if (dbSpell[key] ~= nil) then
                    singleResult[key] = dbSpell[key]
                end
            end

            allResults[BuffWatcher_Shared_Singleton.GetStoredSpellKey(singleResult)] = singleResult
        end

        return allResults
    end

    self.saveSpellsToDatabase = function(spells)
        BuffWatcher_DbAccessor_Singleton.SaveStoredSpells(spells)
    end

    self.hasSpell = function(castRecord) 
        local storedSpells = readSpells()
        return storedSpells[castRecord.key] ~= nil 
    end

    self.addSpell = function(castRecord) 
        local storedSpells = readSpells()
        storedSpells[castRecord.key] = BuffWatcher_Shared_Singleton.StoredSpellFromCastRecord(castRecord)
        self.saveSpellsToDatabase(storedSpells)
        events.fire(AddEventName)
    end

    self.removeSpell = function(storedSpell) 
        local key = BuffWatcher_Shared_Singleton.GetStoredSpellKey(storedSpell)
        local spells = readSpells()
        spells[key] = nil
        self.saveSpellsToDatabase(spells)
        events.fire(RemoveEventName)
    end

    self.getSpells = function()
        local spells = readSpells()
        return spells
    end

    self.registerSpellAdded = function(callback)
        events.registerCallback(AddEventName, callback)
    end

    self.registerSpellRemoved = function(callback)
        events.registerCallback(RemoveEventName, callback)
    end

    return self
end

