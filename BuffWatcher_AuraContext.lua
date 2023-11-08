---@class BuffWatcher_AuraContext
BuffWatcher_AuraContext = {}

---@class BuffWatcher_AuraContext_Params
---@field spellBundle BuffWatcher_SpellBundle
---@field name string
---@field key string
---@field frameType BuffWatcher_FrameTypes
---@field includeBuffsAndCasts boolean
---@field includeDebuffs boolean
---@field showUnlistedAuras BuffWatcher_ShowUnlistedType
---@field showDispelType boolean
---@field isHostile boolean
---@field growDirection BuffWatcher_GrowDirection
---@field useDefaultIconSize boolean
---@field customIconSize integer
---@field icon integer
---@field xOffset integer,
---@field yOffset integer,
---@field selfPoint string,
---@field anchorPoint string

BuffWatcher_AuraContext_Params = {}

---@param params BuffWatcher_AuraContext_Params
---@param configuration BuffWatcher_Configuration
function BuffWatcher_AuraContext:new(params, configuration)
    self = {};

    ---@type BuffWatcher_SpellBundle
    local spellBundle = nil
    ---@type string
    local name = ""
    ---@type string
    local key = ""
    ---@type BuffWatcher_FrameTypes
    local frameType = nil
    ---@type boolean
    local includeBuffsAndCasts = false
    ---@type boolean
    local includeDebuffs = false 
    ---@type boolean
    local isHostile = false
    ---@type BuffWatcher_ShowUnlistedType
    local showUnlistedAuras = BuffWatcher_ShowUnlistedType.Any
    ---@type boolean
    local showDispelType = false
    ---@type BuffWatcher_GrowDirection
    local growDirection = BuffWatcher_GrowDirection.Left
    ---@type boolean
    local useDefaultIconSize = false
    ---@type integer
    local customIconSize = 0
    ---@type integer
    local icon = 0
    ---@type integer
    local xOffset = 0
    ---@type integer
    local yOffset = 0
    ---@type string
    local selfPoint = ""
    ---@type string
    local anchorPoint = ""

    ---@type table<string, true> 
    local activeGuids = {}
    ---@type table<string, table<string, boolean>>
    local guidToStateKeyMap = {}
    ---@type table<string, string>
    local auraIdToKeyMap = {}
    ---@type table<string, string>
    local guidToNameplateMap = {}
    ---@type table<string, string>
    local nameplateToGuidMap = {}

    ---@type table<string, boolean>
    self.seenGuids = {}

    ---@param params BuffWatcher_AuraContext_Params
    local initializeFromParameters = function(params)
        spellBundle = params.spellBundle
        name = params.name
        key = params.key
        frameType = params.frameType
        includeBuffsAndCasts = params.includeBuffsAndCasts
        includeDebuffs = params.includeDebuffs
        showUnlistedAuras = params.showUnlistedAuras
        showDispelType = params.showDispelType
        isHostile = params.isHostile
        growDirection = params.growDirection
        useDefaultIconSize = params.useDefaultIconSize
        customIconSize = params.customIconSize
        icon = params.icon
        xOffset = params.xOffset
        yOffset = params.yOffset
        selfPoint = params.selfPoint
        anchorPoint = params.anchorPoint

        DevTool:AddData(params, "fixme params")
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

    ---@param targetGuid string
    ---@return table<string, boolean>
    self.getKeysByGuid = function(targetGuid) 
        ---@type table<string, boolean>
        local keys = {}
        
        if (guidToStateKeyMap[targetGuid] == nil) then
            return keys
        end

        return guidToStateKeyMap[targetGuid]
    end

    ---@param auraId string
    ---@return string
    self.getKeyByAuraId = function(auraId)
        return auraIdToKeyMap[auraId]
    end

    ---@param auraId string
    ---@param key string
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
        return frameType == BuffWatcher_FrameTypes.Nameplate
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

    ---@return BuffWatcher_ShowUnlistedType
    self.showUnlistedAuras = function()
        return showUnlistedAuras
    end

    ---@return BuffWatcher_FrameTypes
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

    ---@return BuffWatcher_GrowDirection
    self.GetGrowthDirection = function()
        return growDirection
    end

    ---@return table<string, boolean>
    self.GetActiveGuids = function()
        return activeGuids
    end

    ---@param newActiveGuids table<string, boolean>
    self.SetActiveGuids = function(newActiveGuids)
        activeGuids = newActiveGuids
    end
    
    ---@return boolean
    self.GetUseDefaultIconSize = function()
        return useDefaultIconSize
    end
    
    ---@return integer
    self.GetCustomIconSize = function()
        return customIconSize
    end

    ---@return integer
    self.GetIconSize = function()
        if (useDefaultIconSize) then 
            return configuration.GetDefaultSize()
        else 
            return customIconSize
        end
    end

    ---@return string
    self.GetKey = function()
        return key
    end

    ---@return integer
    self.GetIcon = function()
        return icon
    end

    ---@return integer
    self.GetXOffset = function()
        return xOffset
    end

    ---@return integer
    self.GetYOffset = function()
        return yOffset
    end

    ---@return string
    self.GetSelfPoint = function()
        return selfPoint
    end

    ---@return string
    self.GetAnchorPoint = function()
        return anchorPoint
    end

    ---@return integer
    self.GetUnlistedRows = function()
        return 2
    end

    return self;
end