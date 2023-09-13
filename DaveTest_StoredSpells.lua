DaveTest_StoredSpells = {}

function DaveTest_StoredSpells:new()
    self = {}

    local AddEventName = "SPELL_ADDED"
    local events = DaveTest_Callbacks:new()

    local storedSpellFromCastRecord = function(spellRecord)
        return {
            spellId = spellRecord.spellId,
            buffType = spellRecord.type,
            version = 1,
            showInParty = true,
            showInArena = true,
            showInRaid = true,
            showOnNameplates = true
        }
    end

    self.hasSpell = function(castRecord) 
        local storedSpells = DaveTest_DbAccessor_Singleton.GetSpells()
        return storedSpells[castRecord.key] ~= nil 
    end

    self.addSpell = function(castRecord) 
        DevTool:AddData(DaveTest_DbAccessor_Singleton, "fixme DaveTest_DbAccessor_Singleton")
        local storedSpells = DaveTest_DbAccessor_Singleton.GetSpells()
        storedSpells[castRecord.key] = storedSpellFromCastRecord(castRecord)
        DaveTest_DbAccessor_Singleton.SaveStoredSpells(storedSpells)
        events.fire(AddEventName)
    end

    self.removeSpell = function(storedSpell) 
        local key = DaveTest_Shared_Singleton.GetStoredSpellKey(storedSpell)
        local spells = DaveTest_DbAccessor_Singleton.GetSpells()
        spells[key] = nil
        DaveTest_DbAccessor_Singleton.SaveStoredSpells(spells)
    end

    self.getSpells = function()
        local spells = DaveTest_DbAccessor_Singleton.GetSpells()
        DevTool:AddData(spells, "fixme getSpells() spells")
        return spells
    end

    self.registerSpellAdded = function(callback)
        events.registerCallback(AddEventName, callback)
    end

    return self
end

