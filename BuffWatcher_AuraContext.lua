---@class BuffWatcher_AuraContext
BuffWatcher_AuraContext = {}

---@class BuffWatcher_AuraContext_Params
---@field spellBundle BuffWatcher_SpellBundle
---@field isNameplate boolean
---@field name string
---@field frameType FrameTypes
---@field includeBuffsAndCasts boolean
---@field includeDebuffs boolean
---@field showUnlistedAuras boolean
---@field showDispelType boolean
---@field isHostile boolean

BuffWatcher_AuraContext_Params = {}

---@param params BuffWatcher_AuraContext_Params
function BuffWatcher_AuraContext:new(params)
    self = {};

    ---@type BuffWatcher_SpellBundle
    local spellBundle = nil
    ---@type boolean
    local isNameplateValue = false
    ---@type string
    local name = ""
    ---@type FrameTypes
    local frameType = nil
    ---@type boolean
    local includeBuffsAndCasts = false
    ---@type boolean
    local includeDebuffs = false 
    ---@type boolean
    local isHostile = false
    ---@type boolean
    local showUnlistedAuras = false
    ---@type boolean
    local showDispelType = false

    ---@type table<string, table<string, boolean>>
    local guidToStateKeyMap = {}
    ---@type table<string, string>
    local auraIdToKeyMap = {}
    ---@type table<string, string>
    local guidToNameplateMap = {}
    ---@type table<string, string>
    local nameplateToGuidMap = {}

    ---@param params BuffWatcher_AuraContext_Params
    local initializeFromParameters = function(params)
        DevTool:AddData(params, "fixme params")

        if (params.spellBundle == nil) then
            error("Could not find parameter key 'spellBundle'.")
        else 
            spellBundle = params.spellBundle
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

        if (params.isHostile == nil) then
            error("Could not find parameter key 'isHostile'.")
        else
            isHostile = params.isHostile
        end
    end

    initializeFromParameters(params)

    ---@param targetGuid string
    ---@param key string
    self.addKeyByGuid = function(targetGuid, key)
        if (guidToStateKeyMap[targetGuid] == nil) then
            guidToStateKeyMap[targetGuid] = {}
        end

        guidToStateKeyMap[targetGuid][key] = true 
    end

    self.removeKeyByGuid = function(targetGuid, key)
        if (guidToStateKeyMap[targetGuid] == nil) then
            return
        end

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

    ---@return boolean
    self.showUnlistedAuras = function()
        return showUnlistedAuras
    end

    ---@return FrameTypes
    self.getFrameType = function()
        return frameType
    end

    ---@return boolean
    self.getShowDispelType = function()
        return showDispelType
    end

    ---@return boolean
    self.getIsHostile = function()
        return isHostile
    end

    ---@return BuffWatcher_SpellBundle
    self.GetWeakAuraBundle = function()
        return spellBundle
    end

    return self;
end