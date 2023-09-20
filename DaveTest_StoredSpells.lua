DaveTest_StoredSpells = {}

function DaveTest_StoredSpells:new()
    self = {}

    local AddEventName = "SPELL_ADDED"
    local RemoveEventName = "SPELL_REMOVED"

    local events = DaveTest_Callbacks:new()

    local readSpells = function()
        local defaultStoredRecord = DaveTest_Shared_Singleton.GetDefaultStoredSpell()
        local dbSpells = DaveTest_DbAccessor_Singleton.GetSpells()

        local allResults = {}
        for _, dbSpell in pairs(dbSpells) do
            local singleResult = {}

            for key, _ in pairs(defaultStoredRecord) do
                if (dbSpell[key] ~= nil) then
                    singleResult[key] = dbSpell[key]
                end
            end

            allResults[DaveTest_Shared_Singleton.GetStoredSpellKey(singleResult)] = singleResult
        end

        return allResults
    end

    local saveSpellsToDatabase = function(spells)
        DaveTest_DbAccessor_Singleton.SaveStoredSpells(spells)
    end

    self.hasSpell = function(castRecord) 
        local storedSpells = readSpells()
        return storedSpells[castRecord.key] ~= nil 
    end

    self.addSpell = function(castRecord) 
        local storedSpells = readSpells()
        storedSpells[castRecord.key] = DaveTest_Shared_Singleton.StoredSpellFromCastRecord(castRecord)
        saveSpellsToDatabase(storedSpells)
        events.fire(AddEventName)
    end

    self.removeSpell = function(storedSpell) 
        local key = DaveTest_Shared_Singleton.GetStoredSpellKey(storedSpell)
        local spells = readSpells()
        spells[key] = nil
        saveSpellsToDatabase(spells)
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

