DaveTest_AuraContext = {}

function DaveTest_AuraContext:new(storedSpells, spellFilterFunction, incomingIsNameplate, incomingName)
    self = {};

    local spellBundle = nil
    local initialized = false
    local isNameplateValue = incomingIsNameplate
    local name = incomingName
    local keysByGuid = {}
    local keysByAuraId = {}
    local nameplatesByGuid = {}

    storedSpells.registerSpellAdded(function() 
        initialized = false
    end)

    storedSpells.registerSpellRemoved(function() 
        initialized = false
    end)

    self.resetInitializedState = function()
        initialized = false
    end

    self.GetWeakAuraBundle = function()
        if (not initialized) then
            self.UpdateSpells()
            initialized = true
        end

        return spellBundle
    end

    self.UpdateSpells = function()
        local spells = storedSpells.getSpells()
        spellBundle = spellFilterFunction(spells)
    end


    self.addKeyByGuid = function(targetGuid, key)
        if (keysByGuid[targetGuid] == nil) then
            keysByGuid[targetGuid] = {}
        end
        keysByGuid[targetGuid][key] = true 
    end

    self.removeKeyByGuid = function(targetGuid, key)
        if (keysByGuid[targetGuid] == nil) then
            return
        end

        keysByGuid[targetGuid][key] = nil

        local tableKeyCount = DaveTest_Shared_Singleton.GetTableKeyCount(keysByGuid[targetGuid])
        if (tableKeyCount == 0) then
            keysByGuid[targetGuid] = nil
        end
    end

    self.getKeysByGuid = function(targetGuid) 
        local keys = {}
        if (keysByGuid[targetGuid] == nil) then
            return pairs(keys)
        end
        return pairs(keysByGuid[targetGuid])
    end

    self.getKeysByAuraId = function()
        return keysByAuraId
    end

    self.getNameplatesByGuid = function()
        return nameplatesByGuid
    end

    self.setNameplatesByGuid = function(newValue)
        nameplatesByGuid = newValue
    end

    self.isNameplate = function()
        return isNameplateValue
    end

    self.getName = function()
        return name
    end

    return self;
end