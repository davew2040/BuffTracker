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
---@field unlistedRowCount integer
---@field useDefaultUnlistedMultiplier boolean
---@field customUnlistedMultiplier number
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
    ---@type integer
    local unlistedRowCount = 0
    ---@type boolean
    local isLoaded = false

    ---@type table<string, true> 
    local activeGuids = {}
    ---@type table<string, table<string, boolean>>
    local guidToStateKeyMap = {}
    ---@type table<integer, string>
    local auraIdToStateKeyMap = {}  
    ---@type table<string, table<integer, boolean>>
    local stateKeyToAuraIdMap = {}  
    ---@type table<string, string>
    local guidToNameplateMap = {}
    ---@type table<string, string>
    local nameplateToGuidMap = {}

    ---@type boolean
    self.useDefaultUnlistedMultiplier = false
    ---@type number
    self.customUnlistedMultiplier = 0.5

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
        unlistedRowCount = params.unlistedRowCount
        self.useDefaultUnlistedMultiplier = params.useDefaultUnlistedMultiplier
        self.customUnlistedMultiplier = params.customUnlistedMultiplier

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

    ---@param targetGuid string
    ---@param key string
    self.removeKeyFromGuid = function(targetGuid, key)
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
        return auraIdToStateKeyMap[auraId]
    end

    ---@param auraId integer
    ---@param key string
    self.linkAuraIdToStateKey = function(auraId, key)
        auraIdToStateKeyMap[auraId] = key
        if (stateKeyToAuraIdMap[key] == nil) then
            stateKeyToAuraIdMap[key] = {}
        end
        stateKeyToAuraIdMap[key][auraId] = true
    end

    ---@param auraId integer
    ---@param key string
    self.unlinkAuraIdToStateKey = function(auraId, key)
        auraIdToStateKeyMap[auraId] = nil

        if (stateKeyToAuraIdMap[key] ~= nil) then
            stateKeyToAuraIdMap[key][auraId] = nil
        end

        if not BuffWatcher_Shared.TableHasKeys(stateKeyToAuraIdMap[key]) then
            stateKeyToAuraIdMap[key] = nil
        end
    end

    ---@param key string
    ---@return integer[]
    self.getAurasIdsByStateKey = function(key)
        ---@type integer[]
        local auraIds = {}

        if (stateKeyToAuraIdMap[key] ~= nil) then
            for k,v in pairs(stateKeyToAuraIdMap[key]) do
                table.insert(auraIds, k)
            end
        end

        return auraIds
    end


    -- self.removeAuraIdToKeyEntry = function(auraId)
    --     auraIdToStateKeyMap[auraId] = nil
    -- end

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
    self.GetActiveGuidsSet = function()
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
        return unlistedRowCount
    end

    ---@return boolean
    self.GetIsLoaded = function()
        return isLoaded
    end

    ---@return table<string, string>
    local getGroupUnits = function() 
        ---@type table<string, string>
        local result = {}

        if GetNumGroupMembers() == 0 then
            return result
        end

        local playerGuid = UnitGUID('player')

        result['player'] = playerGuid

        for i=1, GetNumGroupMembers() do
            if IsInRaid() then
                local raidUnit = BuffWatcher_Shared_Singleton.raidUnits[i]
                local raidUnitGuid = UnitGUID(raidUnit)
                if (raidUnitGuid ~= nil and raidUnitGuid ~= playerGuid) then
                    result[raidUnit] = raidUnitGuid 
                end
            elseif IsInGroup() then
                local partyUnit = BuffWatcher_Shared_Singleton.partyUnits[i]
                local partyUnitGuid = UnitGUID(partyUnit)
                if (partyUnitGuid ~= nil and partyUnitGuid ~= playerGuid) then
                    result[partyUnit] = partyUnitGuid 
                end
            end
        end

        return result
    end

    ---@return table<string, string>
    local getArenaUnits = function() 
        ---@type table<string, string>
        local result = {}

        for i=1, GetNumArenaOpponents() do
            local arenaUnit = BuffWatcher_Shared_Singleton.arenaUnits[i]
            local arenaUnitGuid = UnitGUID(arenaUnit)
            if (arenaUnitGuid) then
                result[arenaUnitGuid] = arenaUnitGuid 
            end
        end

        return result
    end

    ---@return table<string, string>
    local getNameplateUnits = function() 
        ---@type any[]
        local nameplates = C_NamePlate.GetNamePlates()

        ---@type table<string, string>
        local result = {}

        for i,nameplate in ipairs(nameplates) do
            result[nameplate.namePlateUnitToken] = UnitGUID(nameplate.namePlateUnitToken)
        end

        return result
    end

    ---@return table<string, string>
    self.GetUnits = function()
        if (frameType == BuffWatcher_FrameTypes.Party or frameType == BuffWatcher_FrameTypes.Raid) then
            return getGroupUnits()
        elseif (frameType == BuffWatcher_FrameTypes.Arena) then
            return getArenaUnits()
        elseif (frameType == BuffWatcher_FrameTypes.Nameplate) then
            return getNameplateUnits()
        end

        ---@type table<string, string>
        local result = {}

        return result
    end

    ---@return boolean
    self.IncludeNpcs = function() 
        return true
    end

    ---@return boolean
    local usePartyFrames = function()
        if (BuffWatcher_Shared.PlayerInBattleground()) then
            return false
        elseif (IsInRaid()) then
            return false
        else
            return IsInGroup()
        end
    end

    ---@return boolean
    local useRaidFrames = function()
        if (BuffWatcher_Shared.PlayerInArena()) then
            return false
        end

        return IsInRaid()
    end

    ---@return boolean
    local determineIsLoaded = function()
        if (frameType == BuffWatcher_FrameTypes.Nameplate) then
            return true
        elseif (frameType == BuffWatcher_FrameTypes.Arena) then
            return BuffWatcher_Shared.PlayerInArena()
        elseif (frameType == BuffWatcher_FrameTypes.Party) then
            return usePartyFrames()
        elseif (frameType == BuffWatcher_FrameTypes.Raid) then
            return useRaidFrames()
        elseif (frameType == BuffWatcher_FrameTypes.Battleground) then
            return BuffWatcher_Shared.PlayerInBattleground()
        end

        error("Encountered unrecognized frame type: " .. frameType)
    end

    ---@return boolean -- true if the loaded state has changed
    self.UpdateLoaded = function()
        local previousIsLoaded = isLoaded
        isLoaded = determineIsLoaded()

        return isLoaded ~= previousIsLoaded
    end

    self.ResetAuraState = function()
        activeGuids = {}
        guidToStateKeyMap = {}
        auraIdToStateKeyMap = {}
        stateKeyToAuraIdMap = {}
        guidToNameplateMap = {}
        nameplateToGuidMap = {}
    end

    return self;
end