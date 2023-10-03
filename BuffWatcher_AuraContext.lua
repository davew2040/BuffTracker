BuffWatcher_AuraContext = {}

function BuffWatcher_AuraContext:new(params)
--function BuffWatcher_AuraContext:new(storedSpells, spellFilterFunction, isNameplate, name, frameType, includeBuffsAndCasts, includeDebuffs, showUnlistedAuras)
    self = {};

    local storedSpells = nil
    local spellBundle = nil
    local initialized = false
    local isNameplateValue = false
    local name = ""
    local frameType = nil
    local includeBuffsAndCasts = nil
    local includeDebuffs = nil 
    local showUnlistedAuras = nil
    local showDispelType = false
    local spellFilterFunction = function(spells) error("filter function not initialized") end 

    local guidToStateKeyMap = {}
    local auraIdToKeyMap = {}
    local guidToNameplateMap = {}
    local nameplateToGuidMap = {}

    local initializeFromParameters = function(params)
        if (params.storedSpellsRegistry == nil) then
            error("Could not find parameter key 'storedSpellsRegistry'.")
        else
            storedSpells = params.storedSpellsRegistry
        end

        if (params.spellFilterFunction == nil) then
            error("Could not find parameter key 'spellFilterFunction'.")
        else
            spellFilterFunction = params.spellFilterFunction
        end

        if (params.isNameplate == nil) then
            error("Could not find parameter key 'isNameplate'.")
        else
            isNameplateValue = params.isNameplate
        end

        if (params.name == nil) then
            error("Could not find parameter key 'name'.")
        else
            name = params.name
        end

        if (params.frameType == nil) then
            error("Could not find parameter key 'frameType'.")
        else
            frameType = params.frameType
        end

        if (params.includeBuffsAndCasts == nil) then
            error("Could not find parameter key 'includeBuffsAndCasts'.")
        else
            includeBuffsAndCasts = params.includeBuffsAndCasts
        end

        if (params.includeDebuffs == nil) then
            error("Could not find parameter key 'includeDebuffs'.")
        else
            includeDebuffs = params.includeDebuffs
        end

        if (params.showUnlistedAuras == nil) then
            error("Could not find parameter key 'showUnlistedAuras'.")
        else
            showUnlistedAuras = params.showUnlistedAuras
        end

        if (params.showDispelType == nil) then
            error("Could not find parameter key 'showDispelType'.")
        else
            showDispelType = params.showDispelType
        end
    end

    initializeFromParameters(params)

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
        if (guidToStateKeyMap[targetGuid] == nil) then
            guidToStateKeyMap[targetGuid] = {}
        end

        guidToStateKeyMap[targetGuid][key] = true 

        DevTool:AddData({ targetGuid = targetGuid, key = key }, "fixme addKeyByGuid")
    end

    self.removeKeyByGuid = function(targetGuid, key)
        if (guidToStateKeyMap[targetGuid] == nil) then
            return
        end

        DevTool:AddData({ targetGuid = targetGuid, key = key }, "fixme removeKeyByGuid")

        guidToStateKeyMap[targetGuid][key] = nil

        local tableKeyCount = BuffWatcher_Shared_Singleton.GetTableKeyCount(guidToStateKeyMap[targetGuid])
        if (tableKeyCount == 0) then
            guidToStateKeyMap[targetGuid] = nil
        end
    end

    self.getKeysByGuid = function(targetGuid) 
        local keys = {}
        if (guidToStateKeyMap[targetGuid] == nil) then
            return pairs(keys)
        end
        return pairs(guidToStateKeyMap[targetGuid])
    end

    self.getKeyByAuraId = function(auraId)
        return auraIdToKeyMap[auraId]
    end

    self.addAuraIdToKeyEntry = function(auraId, key)
        auraIdToKeyMap[auraId] = key
    end

    self.removeAuraIdToKeyEntry = function(auraId)
        auraIdToKeyMap[auraId] = nil
    end

    self.unlinkAllNameplates = function(nameplate, guid)
        guidToNameplateMap = {}
        nameplateToGuidMap = {}
    end

    self.linkNameplateToGuid = function(nameplate, guid)
        guidToNameplateMap[guid] = nameplate
        nameplateToGuidMap[nameplate] = guid
    end

    self.unlinkNameplateFromGuid = function(nameplate, guid)
        guidToNameplateMap[guid] = nil
        nameplateToGuidMap[nameplate] = nil
    end

    self.getNameplateByGuid = function(guid)
        return guidToNameplateMap[guid]
    end

    self.getGuidByNameplate = function(nameplate)
        return nameplateToGuidMap[nameplate]
    end

    self.isNameplate = function()
        return isNameplateValue
    end

    self.isUnitframe = function()
        return not self.isNameplate()
    end

    self.getName = function()
        return name
    end

    self.includeBuffsAndCasts = function()
        return includeBuffsAndCasts
    end

    self.includeDebuffs = function()
        return includeDebuffs
    end

    self.showUnlistedAuras = function()
        return showUnlistedAuras
    end

    self.getFrameType = function()
        return frameType
    end

    self.getShowDispelType = function()
        return showDispelType
    end

    return self;
end