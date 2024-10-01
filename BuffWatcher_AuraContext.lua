local LGF = LibStub("LibGetFrame-1.0")

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
---@field minorAuraMultiplier number,
---@field minorAuraPriority integer,
---@field selfPoint string,
---@field anchorPoint string
---@field unlistedRowCount integer
---@field useDefaultUnlistedMultiplier boolean
---@field customUnlistedMultiplier number
BuffWatcher_AuraContext_Params = {}

---@param params BuffWatcher_AuraContext_Params
---@param configuration BuffWatcher_Configuration
---@param objectPool BuffWatcher_MiscellaneousObjectPool
function BuffWatcher_AuraContext:new(params, configuration, objectPool)
    self = {};

    ---@type BuffWatcher_SpellBundle
    local spellBundle = nil
    ---@type string
    local name = ""
    ---@type string
    local contextKey = ""
    ---@type BuffWatcher_FrameTypes
    local frameType = nil
    ---@type boolean
    local includeBuffsAndCasts = false
    ---@type boolean
    local includeDebuffs = false 
    ---@type boolean
    local contextIsHostile = false
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
    ---@type table<string, boolean> 
    local contextUnits = {}
    ---@type number
    local minorAuraMultiplier = 1.0
    ---@type integer
    local minorAuraPriority = 1
    
    local threePartKeyBuilder = {}

    -- do not add/remove to this directly! use the helpers
    ---@type table<string, table<string, boolean>>
    local guidToStateKeyMap = {}

    ---@type table<integer, string>
    local auraIdToStateKeyMap = nil

    -- maps state keys to aura instances
    ---@type table<string, BuffWatcher_AuraInstance>
    self.auraInstancesMap = {}

    ---@type BuffWatcher_UnitGuidTable
    local unitToGuidMap = nil

    ---@type boolean
    self.useDefaultUnlistedMultiplier = false
    ---@type number
    self.customUnlistedMultiplier = 0.5

    ---@type table<string, boolean>
    local visibleUnits = nil

    ---@type number
    local lastUpdateTime = 0

    local minimumUpdateTimeSeconds = 0.05

    ---@type any
    self.framePool = CreateFramePool("Frame")
    ---@type any
    self.cooldownFramePool = CreateFramePool("Cooldown", nil, "CooldownFrameTemplate")
    ---@type BuffWatcher_AuraFramePool
    self.auraFramePool = BuffWatcher_AuraFramePool:new(self.framePool, self.cooldownFramePool)
    ---@type any
    self.texturePool = CreateTexturePool(UIParent)

    local Icons = {
        Up = 450907,
        Left = 450906,
        Right = 450908
    }

    local dispelColors = {
        ["Magic"] = configuration.GetMagicColor(),
        ["Curse"] = configuration.GetCurseColor(),
        ["Poison"] = configuration.GetPoisonColor(),
        ["Disease"] = configuration.GetDiseaseColor()
    }

    ---@type table<BuffWatcher_TriggerType, boolean>
    local LooseTriggers = {
        [BuffWatcher_TriggerType.Buff] = true,
        [BuffWatcher_TriggerType.Debuff] = true,
        [BuffWatcher_TriggerType.CatchAll] = true,
        [BuffWatcher_TriggerType.Marker] = true
    }

    ---@type table<BuffWatcher_TriggerType, boolean>
    local BuffDebuffTriggers = {
        [BuffWatcher_TriggerType.Buff] = true,
        [BuffWatcher_TriggerType.Debuff] = true,
        [BuffWatcher_TriggerType.CatchAll] = true
    }

    ---@type BuffWatcher_FrameManagerNew
    local frameManager

    local getPartyAndRaidUnits = function()
        local party = CopyTable(BuffWatcher_Shared_Singleton.partyUnits)
        local raid = CopyTable(BuffWatcher_Shared_Singleton.raidUnits)

        local merged = BuffWatcher_Shared_Singleton.SimpleTableMerge(party, raid)
        
        return merged
    end

    ---@param frameType BuffWatcher_FrameTypes
    ---@return table<string, boolean>
    local initializeContextUnits = function(frameType)
        if (frameType == BuffWatcher_FrameTypes.Nameplate) then
            return CopyTable(BuffWatcher_Shared_Singleton.nameplateUnits)

        elseif (frameType == BuffWatcher_FrameTypes.Arena) then
            return CopyTable(BuffWatcher_Shared_Singleton.arenaUnits)

        elseif (frameType == BuffWatcher_FrameTypes.Battleground) then
            local bgUnits = getPartyAndRaidUnits()
            bgUnits['player'] = true

            DevTool:AddData(CopyTable(bgUnits), "fixme bgUnits")

            return bgUnits

        elseif (frameType == BuffWatcher_FrameTypes.Party) then
            local partyUnits = CopyTable(BuffWatcher_Shared_Singleton.partyUnits)
            partyUnits['player'] = true
            return partyUnits

        elseif (frameType == BuffWatcher_FrameTypes.Raid) then
            local raidUnits = getPartyAndRaidUnits()
            raidUnits['player'] = true

            
            DevTool:AddData(CopyTable(raidUnits), "fixme raidUnits")
            return raidUnits

        end

        error("Could not identify context units from frame type")
    end

    ---@param params BuffWatcher_AuraContext_Params
    local initializeFromParameters = function(params)
        DevTool:AddData(params, "fixme loading context from params")

        spellBundle = params.spellBundle
        name = params.name
        contextKey = params.key
        frameType = params.frameType
        includeBuffsAndCasts = params.includeBuffsAndCasts
        includeDebuffs = params.includeDebuffs
        showUnlistedAuras = params.showUnlistedAuras
        showDispelType = params.showDispelType
        contextIsHostile = params.isHostile
        growDirection = params.growDirection
        useDefaultIconSize = params.useDefaultIconSize
        customIconSize = params.customIconSize
        icon = params.icon
        xOffset = params.xOffset
        yOffset = params.yOffset
        selfPoint = params.selfPoint
        anchorPoint = params.anchorPoint
        unlistedRowCount = params.unlistedRowCount
        minorAuraMultiplier = params.minorAuraMultiplier
        minorAuraPriority = params.minorAuraPriority
        self.useDefaultUnlistedMultiplier = params.useDefaultUnlistedMultiplier
        self.customUnlistedMultiplier = params.customUnlistedMultiplier

        contextUnits = initializeContextUnits(frameType)
        frameManager = BuffWatcher_FrameManagerNew:new(self, configuration, objectPool)
    end

    initializeFromParameters(params)

    ---@param settings BuffWatcher_AuraGroupMergedSettings
    ---@param newSpellBundle BuffWatcher_SpellBundle
    self.UpdateFromDbSettings = function(settings, newSpellBundle)
        --TODO - update rest of settings
        xOffset = settings.xOffset
        yOffset = settings.yOffset
        useDefaultIconSize = settings.useDefaultIconSize
        showDispelType = settings.showDispelType
        customIconSize = settings.customIconSize
        selfPoint = settings.selfPoint
        anchorPoint = settings.anchorPoint
        growDirection = settings.growDirection
        minorAuraMultiplier = settings.minorAuraMultiplier
        minorAuraPriority = settings.minorAuraPriority

        spellBundle = newSpellBundle

        self.DoFullReset()
    end

    ---@param targetGuid string
    ---@param key string
    self.addKeyByGuid = function(targetGuid, key)
        if (guidToStateKeyMap[targetGuid] == nil) then
            guidToStateKeyMap[targetGuid] = objectPool.GetObject()
        end

        guidToStateKeyMap[targetGuid][key] = true 
    end

    ---@param targetGuid string
    ---@param key string
    self.RemoveKeyFromGuid = function(targetGuid, key)
        if (guidToStateKeyMap[targetGuid] == nil) then
            return
        end

        guidToStateKeyMap[targetGuid][key] = nil

        local tableKeyCount = BuffWatcher_Shared_Singleton.GetTableKeyCount(guidToStateKeyMap[targetGuid])

        if (tableKeyCount == 0) then
            objectPool.ReleaseObject(guidToStateKeyMap[targetGuid])
            guidToStateKeyMap[targetGuid] = nil
        end
    end

    ---@param targetGuid string
    ---@return table<string, boolean>
    self.GetKeysByGuid = function(targetGuid) 
        if (guidToStateKeyMap[targetGuid] == nil) then
            return BuffWatcher_Shared.EmptyTable
        end

        return guidToStateKeyMap[targetGuid]
    end

    ---@param auraId string
    ---@return string
    self.getKeyByAuraId = function(auraId)
        return auraIdToStateKeyMap[auraId]
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
        return contextIsHostile
    end

    ---@return BuffWatcher_SpellBundle
    self.GetWeakAuraBundle = function()
        return spellBundle
    end

    ---@return BuffWatcher_GrowDirection
    self.GetGrowthDirection = function()
        return growDirection
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
            if (self.isNameplate()) then
                local nameplateSize = configuration.GetDefaultNameplateSize()
                return nameplateSize
            else
                local unitFrameSize = configuration.GetDefaultUnitFrameSize()
                return unitFrameSize
            end
        else 
            return customIconSize
        end
    end

    ---@return string
    self.GetKey = function()
        return contextKey
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
    self.GetSelfAnchorPoint = function()
        return selfPoint
    end

    ---@return string
    self.GetTargetAnchorPoint = function()
        return anchorPoint
    end

    ---@return integer
    self.GetUnlistedRows = function()
        return unlistedRowCount
    end

    ---@return boolean
    self.IsLoaded = function()
        return isLoaded
    end

    ---@param stateKey string
    ---@return BuffWatcher_AuraInstance
    self.GetAuraInstanceByKey = function(stateKey)
        return self.auraInstancesMap[stateKey]
    end

    ---@param auraInstance BuffWatcher_AuraInstance
    local isTimedAura = function(auraInstance)
        return auraInstance.triggerType == BuffWatcher_TriggerType.Cast
    end

    -- Indicates that an aura is one that gets added and removed based on its existence in a unit frame
    ---@param auraInstance BuffWatcher_AuraInstance
    local isBuffDebuff = function(auraInstance)
        return BuffDebuffTriggers[auraInstance.triggerType] ~= nil
    end

    -- Indicates that an aura is one that gets added and removed based on its existence in a unit frame
    ---@param auraInstance BuffWatcher_AuraInstance
    local isLooseAura = function(auraInstance)
        return LooseTriggers[auraInstance.triggerType] ~= nil
    end

    local isCompStomp = function()
        local inBrawl = C_PvP.IsInBrawl()

        if not inBrawl then
            return false
        end
    
        local brawlInfo = C_PvP.GetAvailableBrawlInfo()

        return brawlInfo and brawlInfo.name == "Brawl: Comp Stomp"
    end

    ---@return boolean
    self.IncludeNpcs = function() 
        -- if in comp stomp, then there will be a crazy amount of aura spam that's technically from NPC's
        if (isCompStomp()) then
            return false
        end

        return true
    end

    ---@return boolean
    local usePartyFrames = function()
        if (BuffWatcher_Shared.PlayerInBattleground()) then
            return false
        elseif BuffWatcher_Shared.PlayerInArena() then
            return true
        elseif (IsInRaid()) then
            return false
        else
            return IsInGroup()
        end
    end

    ---@return boolean
    local useRaidFrames = function()
        if (BuffWatcher_Shared.PlayerInArena() or BuffWatcher_Shared.PlayerInBattleground()) then
            return false
        end

        local result = UnitInRaid("player")
        local isInRaid = result ~= nil

        return isInRaid
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
    self.UpdateLoadedState = function()
        local previousIsLoaded = isLoaded
        isLoaded = determineIsLoaded()

        return isLoaded ~= previousIsLoaded
    end


    ---@param unitName string
    ---@param frameType BuffWatcher_FrameTypes
    ---@return boolean
    local filterByInstanceType = function(unitName, frameType)
        if (frameType == BuffWatcher_FrameTypes.Raid) then
            local isArena = IsActiveBattlefieldArena()
            if (isArena) then
                return true
            end
            return IsInRaid()
        elseif (frameType == BuffWatcher_FrameTypes.Party) then
            if (BuffWatcher_Shared:PlayerInBattleground()) then
                return not IsInRaid()
            end

            local isGroup = not IsInRaid() and IsInGroup()
            return isGroup
        elseif (frameType == BuffWatcher_FrameTypes.Arena) then
            local isArena = IsActiveBattlefieldArena()
            return isArena
        end

        return true
    end

    ---@param unitName string
    ---@param frameType BuffWatcher_FrameTypes
    ---@return boolean
    local filterByUnit = function(unitName, frameType)
        if (frameType == BuffWatcher_FrameTypes.Raid) then
            local isRaid = BuffWatcher_Shared_Singleton.IsPartyOrRaidUnit(unitName)
                or unitName == 'player'
            return isRaid 

        elseif (frameType == BuffWatcher_FrameTypes.Party) then
            local isGroup = BuffWatcher_Shared_Singleton.IsPartyOrRaidUnit(unitName)
                or unitName == 'player'
            return isGroup

        elseif (frameType == BuffWatcher_FrameTypes.Arena) then
            return BuffWatcher_Shared_Singleton.IsArenaUnit(unitName)

        elseif (frameType == BuffWatcher_FrameTypes.Nameplate) then
            return BuffWatcher_Shared_Singleton.IsNameplateUnit(unitName)

        elseif (frameType == BuffWatcher_FrameTypes.Battleground) then
            return BuffWatcher_Shared_Singleton.IsPartyOrRaidUnit(unitName)
                or unitName == 'player'

        end

        return false
    end

    ---@param unitName string
    ---@param frameType BuffWatcher_FrameTypes
    ---@return boolean
    local filterByHostility = function(unitName, frameType)
        if (frameType == BuffWatcher_FrameTypes.Nameplate and BuffWatcher_Shared_Singleton.IsNameplateUnit(unitName)) then
            local unitIsHostile = not BuffWatcher_Shared.UnitIsFriendly(unitName)
            return unitIsHostile == contextIsHostile
        end

        return true
    end

    ---comment
    ---@param unit string
    ---@return boolean
    local unitIsPlayerDuplicate = function(unit)
        return (BuffWatcher_Shared_Singleton.IsPartyOrRaidUnit(unit) and UnitGUID(unit) == UnitGUID('player'))
    end

    ---@param targetUnit string
    ---@return boolean -- false if the filter fails and event should not be processed
    self.UnitPassesFilter = function(targetUnit)
        if (targetUnit == 'target' or targetUnit == 'softenemy') then
            return false
        end

        if (not filterByUnit(targetUnit, frameType)) then
            if (targetUnit ~= nil and not self.isNameplate()) then
                --replace when done debugging
                --DevTool:AddData({ targetUnit = targetUnit, context = self.getName(), frameType == frameType }, "fixme filterbyunit " .. targetUnit)
            end
            
            return false
        end

        if (not filterByHostility(targetUnit, frameType)) then
            return false
        end

        if (BuffWatcher_Shared.UnitIsMinor(targetUnit)) then
            return false
        end

        if UnitGUID(targetUnit) == nil then
            DevTool:AddData("Identified nil guid for unit " .. targetUnit)
            return false
        end

        if unitIsPlayerDuplicate(targetUnit) then
            return false
        end

        return true
    end

        ---@param targetUnit string
    ---@return boolean -- false if the filter fails and event should not be processed
    self.FilterCastEvent = function(targetUnit)
        if (targetUnit == 'target' or targetUnit == 'softenemy') then
            return false
        end

        if (not filterByUnit(targetUnit, frameType)) then
            return false
        end

        if (not filterByHostility(targetUnit, frameType)) then
            return false
        end

        if (BuffWatcher_Shared.UnitIsMinor(targetUnit)) then
            return false
        end

        return true
    end

    ---@param dispelName string
    ---@return BuffWatcher_Color
    local getDispelColor = function(dispelName)
        if (dispelName ~= nil and dispelColors[dispelName] ~= nil) then
            return dispelColors[dispelName]
        else
            DevTool:AddData("fixme before Unrecognized dispel color")
            DevTool:AddData(dispelName, "Unrecognized dispel color")
            return configuration.GetMagicColor()
        end
    end

    self.ReleaseGuidToStateKeyMap = function()
        for key, _ in pairs(guidToStateKeyMap) do
            objectPool.ReleaseObject(guidToStateKeyMap[key])
        end

        guidToStateKeyMap = {}
    end

    self.ResetAuraState = function()
        for key, _ in pairs(self.auraInstancesMap) do
            self.KillStateKey(key, false)
        end

        self.auraInstancesMap = objectPool.GetObject()

        self.ReleaseGuidToStateKeyMap()

        if (auraIdToStateKeyMap ~= nil) then
            objectPool.ReleaseObject(auraIdToStateKeyMap)
        end

        auraIdToStateKeyMap = objectPool.GetObject()

        if (unitToGuidMap ~= nil) then
            unitToGuidMap.Release()
        end

        unitToGuidMap = BuffWatcher_UnitGuidTable:new(objectPool)

        if visibleUnits ~= nil then
            objectPool.ReleaseObject(visibleUnits)
        end

        visibleUnits = objectPool.GetObject()
    end

    ---@param auraInfo BuffWatcher_Blizzard_AuraData
    ---@return BuffWatcher_BordersDefinition
    self.GetAuraBorders = function(auraInfo)
        local dispelWidth = 0
        ---@type BuffWatcher_Color
        local dispelColor = nil

        if (showDispelType and auraInfo.dispelName ~= nil) then
            dispelWidth = configuration.GetDispelBorderSize()
            dispelColor = getDispelColor(auraInfo.dispelName)
        else
            dispelColor = BuffWatcher_Color:new(0, 0, 0, 1)
        end

        local hostilityWidth = configuration.GetBuffDebuffBorderSize()
        local hostilityColor = nil

        if (auraInfo.isHarmful) then
            hostilityColor = configuration.GetDebuffColor()
        else
            hostilityColor = configuration.GetBuffColor()
        end

        ---@type BuffWatcher_BordersDefinition
        local borders =  objectPool.GetObject()
        
        borders.innerWidth = 1
        borders.outerWidth = 1
        borders.dispelColor = dispelColor
        borders.dispelWidth = dispelWidth
        borders.hostilityColor = hostilityColor
        borders.hostilityWidth = hostilityWidth
        borders.showDispel = true

        return borders
    end

    ---@param castInfo BuffWatcher_Blizzard_CastInfo
    ---@return BuffWatcher_BordersDefinition
    self.GetCastBorders = function(castInfo)
        ---@type BuffWatcher_BordersDefinition
        local borders =  objectPool.GetObject()
        
        borders.innerWidth = 1
        borders.outerWidth = 1
        borders.dispelColor = BuffWatcher_Color:new(0, 0, 0, 1)
        borders.dispelWidth = 0
        borders.hostilityColor = configuration.GetBuffColor()
        borders.hostilityWidth = configuration.GetBuffDebuffBorderSize()
        borders.showDispel = false

        return borders
    end

    ---@return BuffWatcher_BordersDefinition[]
    self.GetMarkerBorders = function()
        local markerColor = configuration.GetBuffColor()

        if (self.includeDebuffs()) then
            markerColor = configuration.GetDebuffColor()
        end

        ---@type BuffWatcher_BordersDefinition
        local borders =  objectPool.GetObject()
        
        borders.innerWidth = 1
        borders.outerWidth = 1
        borders.dispelColor = BuffWatcher_Color:new(0, 0, 0, 1)
        borders.dispelWidth = 0
        borders.hostilityColor = markerColor
        borders.hostilityWidth = configuration.GetBuffDebuffBorderSize()
        borders.showDispel = false

        return borders
    end

    ---comment
    ---@return integer
    local getFrameLevel = function()
        return 100
    end

    ---Builds a three-part string key
    ---@param one any
    ---@param two any
    ---@param three any
    local getThreePartKey = function(one, two, three)
        threePartKeyBuilder[1] = one
        threePartKeyBuilder[2] = two
        threePartKeyBuilder[3] = three

        local key =  table.concat(threePartKeyBuilder, ":")

        return key
    end

    ---@param targetGuid string
    ---@param index integer
    ---@return string
    local getMarkerStateKey = function(targetGuid, index) 
        return getThreePartKey(BuffWatcher_TriggerType.Marker, targetGuid, index)
    end

    ---@param type SpellTypes
    ---@param spellId integer
    ---@param auraId integer
    ---@return string
    local getBuffDebuffStateKey = function(type, spellId, auraId) 
        return getThreePartKey(type, spellId, auraId)
    end

    ---@param auraInfo BuffWatcher_Blizzard_AuraData
    ---@return string
    local getBuffDebuffStateKeyFromAura = function(auraInfo) 
        local auraId = auraInfo.auraInstanceID

        local key = getBuffDebuffStateKey(
            auraInfo.isHelpful and BuffWatcher_Shared_Singleton.SpellTypes.Buff or BuffWatcher_Shared_Singleton.SpellTypes.Debuff, 
            auraInfo.spellId,
            auraId
        )

        return key
    end

    ---@param spellId integer
    ---@param sourceGuid string
    ---@return string
    local getCastStateKey = function(spellId, sourceGuid) 
        return getThreePartKey(BuffWatcher_TriggerType.Cast, spellId, sourceGuid)
    end

    ---@param watcherInfo? BuffWatcher_StoredSpell
    ---@param blizzAuraInfo? BuffWatcher_Blizzard_AuraData
    local getPriority = function(watcherInfo, blizzAuraInfo)
        if watcherInfo ~= nil then 
            if watcherInfo.isMinorAura then
                return minorAuraPriority
            else 
                return watcherInfo.priority
            end
        elseif blizzAuraInfo ~= nil and blizzAuraInfo.dispelName ~= nil then -- if dispellable, prioritize it over other auras
            return 2
        else
            return 1
        end
    end

    ---@param sourceGuid string
    ---@return boolean
    local useNpcAura = function(sourceGuid)
        return self.IncludeNpcs() and sourceGuid ~= nil and BuffWatcher_Shared.GuidIsNpc(sourceGuid)
    end

    ---@param targetUnit string
    ---@param targetGuid string
    ---@param icon integer
    ---@param priority integer
    ---@param multiplier number
    ---@return boolean
    local function handleSingleMarker(targetUnit, targetGuid, icon, priority, multiplier)
        local key = getMarkerStateKey(targetGuid, priority)

        if (self.auraInstancesMap[key] ~= nil) then
            error("Attempting a double add of marker key " .. key)
        end

        local baseSize = self.GetIconSize()
        local borders = self.GetMarkerBorders()

        ---@type BuffWatcher_AuraInstance
        local newInstance = objectPool.GetObject()
        
        newInstance.stateKey = key
        newInstance.spellId = 0
        newInstance.dispelName = nil
        newInstance.showCooldown = false
        newInstance.borders = borders
        newInstance.duration = 0
        newInstance.expirationTime = 0
        newInstance.baseSize = baseSize
        newInstance.actualSize = baseSize * multiplier
        newInstance.priority = priority
        newInstance.sourceGuid = targetGuid
        newInstance.targetGuid = targetGuid
        newInstance.targetUnit = targetUnit
        newInstance.auraInstanceId = 0
        newInstance.triggerType = BuffWatcher_TriggerType.Marker
        newInstance.icon = icon
        newInstance.name = "Marker"
        newInstance.caster = targetUnit
        newInstance.isHarmful = false
        newInstance.timerHandle = nil

        self.auraInstancesMap[key] = newInstance
        self.addKeyByGuid(targetGuid, key)

        return true
    end

    ---@param targetUnit string
    ---@param targetGuid string
    local function handleAddMarkers(targetUnit, targetGuid)
        handleSingleMarker(targetUnit, targetGuid, Icons.Up, 25, 1.0)

        local arrowIcon = self.GetGrowthDirection() == BuffWatcher_GrowDirection.Left and Icons.Left or Icons.Right

        handleSingleMarker(targetUnit, targetGuid, arrowIcon, 24, minorAuraMultiplier)
        handleSingleMarker(targetUnit, targetGuid, arrowIcon, 23, minorAuraMultiplier)
    end

    ---@param watcherInfo? BuffWatcher_StoredSpell
    ---@return number
    local getAuraSizeMultiplier = function(watcherInfo)
        if watcherInfo ~= nil then
            if watcherInfo.isMinorAura then
                return minorAuraMultiplier
            else 
                return watcherInfo.sizeMultiplier
            end
        else
            return configuration.GetNpcMultiplier()
        end
    end

    ---@param key string
    ---@param auraInfo BuffWatcher_Blizzard_AuraData
    ---@param targetUnit string
    ---@param watcherInfo? BuffWatcher_StoredSpell
    local function addNewStateKey(key, auraInfo, targetUnit, watcherInfo)
        local spell = BuffWatcher_Blizzard_Wrapper.GetSpellInfo(auraInfo.spellId)

        local sizeMultiplier = getAuraSizeMultiplier(watcherInfo)

        local targetGuid = UnitGUID(targetUnit)

        if (self.auraInstancesMap[key] ~= nil) then
            DevTool:AddData({key = key, auraInstancesMap = CopyTable(self.auraInstancesMap) }, 
                "fixme - tried to add state key that already exists")
            return
        end

        local baseSize = self.GetIconSize()
        local borders = self.GetAuraBorders(auraInfo)

        --TODO - decide if we want to do push borders outward?
        --local sizeWithBorders = getSizeWithBorders(borders, baseSize)

        local triggerType = BuffWatcher_TriggerType.Buff
        if (auraInfo.isHarmful) then
            triggerType = BuffWatcher_TriggerType.Debuff
        end

        ---@type BuffWatcher_AuraInstance
        local newInstance = objectPool.GetObject()

        newInstance.spellId = auraInfo.spellId
        newInstance.stateKey = key
        newInstance.dispelName = auraInfo.dispelName
        newInstance.showCooldown = auraInfo.duration ~= 0
        newInstance.borders = borders
        newInstance.duration = auraInfo.duration
        newInstance.expirationTime = auraInfo.expirationTime
        newInstance.baseSize = baseSize
        newInstance.actualSize = baseSize * sizeMultiplier
        newInstance.priority = getPriority(watcherInfo, auraInfo)
        newInstance.sourceGuid = auraInfo.sourceUnit and UnitGUID(auraInfo.sourceUnit) or nil
        newInstance.targetGuid = targetGuid
        newInstance.targetUnit = targetUnit
        newInstance.auraInstanceId = auraInfo.auraInstanceID
        newInstance.triggerType = triggerType
        newInstance.icon = spell.iconID
        newInstance.name = spell.name
        newInstance.caster = targetUnit
        newInstance.isHarmful = auraInfo.isHarmful
        newInstance.timerHandle = nil
        
        self.auraInstancesMap[key] = newInstance
        auraIdToStateKeyMap[auraInfo.auraInstanceID] = key 
        self.addKeyByGuid(targetGuid, key)
    end

    ---@param auraInfo BuffWatcher_Blizzard_AuraData
    ---@param targetUnit string
    ---@param notifyFrameManager boolean
    ---@return boolean
    local function handleBuffDebuffUpdate(auraInfo, targetUnit,notifyFrameManager)
        local key = getBuffDebuffStateKeyFromAura(auraInfo)

        local existingInstance = self.auraInstancesMap[key]

        if (existingInstance ~= nil) then
            local targetGuid = UnitGUID(targetUnit)

            existingInstance.duration = auraInfo.duration
            existingInstance.expirationTime = auraInfo.expirationTime

            if notifyFrameManager then
                frameManager.AuraUpdated(targetGuid, key)
            end

            return true
        end

        return false
    end

    ---@param blizzardAura BuffWatcher_Blizzard_AuraData
    ---@return BuffWatcher_StoredSpell?
    local getWatcherInfo = function(blizzardAura)
        if (blizzardAura.isHelpful) then
            return spellBundle.buffs[blizzardAura.spellId]
        elseif (blizzardAura.isHarmful) then
            return spellBundle.debuffs[blizzardAura.spellId]
        else
            return nil
        end
    end

    ---Returns true if the units are comparable and the distance is less than a specified amount
    ---@param unit string
    ---@return boolean
    local isUnitFrameInRange = function(unit)
        if (unit == 'player') then
            return true
        end

        local isVisible = UnitIsVisible(unit)

        return isVisible == true
    end

    ---@param blizzardAura BuffWatcher_Blizzard_AuraData
    ---@param targetUnit string
    ---@return boolean
    local shouldHandleAura = function(blizzardAura, targetUnit)
        if (not includeBuffsAndCasts and blizzardAura.isHelpful) then
            return false
        end

        if (not includeDebuffs and blizzardAura.isHarmful) then
            return false
        end

        ---@type BuffWatcher_StoredSpell?
        local watcherInfo = getWatcherInfo(blizzardAura)

        -- if we haven't explicitly opted to see (or hide) this aura, then only show if it's an NPC aura
        if (watcherInfo == nil) then
            if (self.IncludeNpcs()) then
                -- "isFromPlayerOrPlayerPet" is only reliable if the unit is in the same zone or a nameplate - ignore auras on units in a different zone
                if (self.isNameplate()) then
                    return not blizzardAura.isFromPlayerOrPlayerPet
                else 
                    local isNotFromPlayerOrPet = not blizzardAura.isFromPlayerOrPlayerPet
                    local shouldInclude = isNotFromPlayerOrPet 
                    
                    return shouldInclude
                end
            else
                return false
            end
        end

        if (watcherInfo ~= nil) then
            if watcherInfo.hide then
                return false
            end

            if (watcherInfo.ownOnly and blizzardAura.sourceUnit ~= 'player') then
                return false
            end

            if not self.isNameplate() and not isUnitFrameInRange(targetUnit) then
                return false
            end
        end

        return true
    end

    ---@param unit string
    ---@param blizzardAura BuffWatcher_Blizzard_AuraData
    local handleAuraAdd = function(unit, blizzardAura)
        local guid = unitToGuidMap.GetGuidByUnit(unit)

        if (guid == nil) then
            DevTool:AddData(unit, "fixme tried to add aura to unregistered unit ".. unit)
            return false 
        end

        if shouldHandleAura(blizzardAura, unit) then
            local key = getBuffDebuffStateKeyFromAura(blizzardAura)
            local watcherInfo = getWatcherInfo(blizzardAura)
            addNewStateKey(key, blizzardAura, unit, watcherInfo)

            frameManager.AuraAdded(guid, key)
        end

        return false
    end


    ---@param unit string
    ---@param removedId number
    local handleAuraRemove = function(unit, removedId)
        self.RemoveAuraId(removedId)
    end

    ---@param unit string
    local refreshUnitAuras = function(unit)
        local hasUpdates = false

        ---@type table<string, BuffWatcher_Blizzard_AuraData>
        local foundStateKeys = objectPool.GetObject()

        AuraUtil.ForEachAura(unit, "HELPFUL", nil, 
            function(auraInfo) 
                if (auraInfo ~= nil) then
                    if shouldHandleAura(auraInfo, unit) then
                        local key = getBuffDebuffStateKeyFromAura(auraInfo)
                        foundStateKeys[key] = auraInfo
                    end
                else
                    DevTool:AddData("error - helpful aura not found")
                end
            end,
            true
        )

        AuraUtil.ForEachAura(unit, "HARMFUL", nil, 
            function(auraInfo) 
                if (auraInfo ~= nil) then
                    if shouldHandleAura(auraInfo, unit) then
                        local key = getBuffDebuffStateKeyFromAura(auraInfo)
                        foundStateKeys[key] = auraInfo
                    end
                else
                    DevTool:AddData("error - harmful aura not found")
                end
            end,
            true
        )

        local guid = UnitGUID(unit)

        local existingKeys = self.GetKeysByGuid(guid)

        for foundAuraKey, auraInfo in pairs(foundStateKeys) do
            -- if we found a new key that doesn't exist, then add
            if existingKeys[foundAuraKey] == nil then
                local watcherInfo = getWatcherInfo(auraInfo)
                addNewStateKey(foundAuraKey, auraInfo, unit, watcherInfo)
                hasUpdates = true
            end
        end

        for existingKey, _ in pairs(existingKeys) do
            -- if an existing key no longer exists, then remove it
            local existingKeyInfo = self.GetAuraInstanceByKey(existingKey)

            if isBuffDebuff(existingKeyInfo) and foundStateKeys[existingKey] == nil then
                self.KillStateKey(existingKey, false)
                hasUpdates = true
            end
        end

        objectPool.ReleaseObject(foundStateKeys)

        return hasUpdates
    end

    -- local refreshAllPendingUnitAuras = function()
    --     local hasUpdates = false

    --     for unit, _ in pairs(unitToGuidMap.GetUnitsToGuid()) do
    --         if unitsWithPendingUpdates[unit] ~= nil then
    --             if refreshUnitAuras(unit) then
    --                 frameManager.GuidRefreshed(unitToGuidMap.GetGuidByUnit(unit))
    --             end
    --         end
    --     end

    --     objectPool.ReleaseObject(unitsWithPendingUpdates)

    --     unitsWithPendingUpdates = objectPool.GetObject()

    --     lastUpdateTime = GetTime()
    -- end

    ---@param blizzardAura BuffWatcher_Blizzard_AuraData
    ---@param targetUnit string
    ---@param notifyFrameManager boolean
    ---@return boolean
    self.HandleAuraUpdate = function(blizzardAura, targetUnit, notifyFrameManager)
        return handleBuffDebuffUpdate(blizzardAura, targetUnit, notifyFrameManager)
    end

    ---@param stateKey string
    local handleTimer = function(stateKey)
        self.KillStateKey(stateKey, true)
    end

    ---@param stateKey string
    ---@return BuffWatcher_TimerWrapper
    local getTimer = function(duration, stateKey)
        local timer = C_Timer.NewTimer(duration, 
            function()
                handleTimer(stateKey)
            end
        )
        return BuffWatcher_TimerWrapper:new(timer)
    end

    ---@param deadGuid string
    self.HandleUnitDied = function(deadGuid)
        -- if it's a nameplate, then the name plate removal handler should deal with it
        if (not self.isNameplate()) then
            self.RefreshGuid(deadGuid)
        end
    end


    ---@param castInfo BuffWatcher_Blizzard_CastInfo
    ---@return boolean
    self.HandleCast = function(castInfo)
        local hasUpdates = false

        if (not includeBuffsAndCasts) then
            return false
        end

        local watcherInfo = spellBundle.casts[castInfo.spellId]

        if (watcherInfo == nil or watcherInfo.hide) then
            return false
        end

        if (not self.UnitPassesFilter(castInfo.sourceName)) then
            return false
        end

        local spell = BuffWatcher_Blizzard_Wrapper.GetSpellInfo(castInfo.spellId)

        local key = getCastStateKey(castInfo.spellId, castInfo.sourceGuid)

        if (self.auraInstancesMap[key] == nil) then
            local baseSize = self.GetIconSize()
            local borders = self.GetCastBorders(castInfo)
            local timer = getTimer(watcherInfo.duration, key)

            ---@type BuffWatcher_AuraInstance
            local newCast = objectPool.GetObject()
            
            newCast.spellId = castInfo.spellId
            newCast.stateKey = key
            newCast.dispelName = nil
            newCast.showCooldown = true
            newCast.borders = borders
            newCast.duration = watcherInfo.duration
            newCast.expirationTime = GetTime() + watcherInfo.duration
            newCast.baseSize = baseSize
            newCast.actualSize = baseSize * watcherInfo.sizeMultiplier
            newCast.priority = getPriority(watcherInfo, nil)
            newCast.sourceGuid = castInfo.sourceGuid
            newCast.targetGuid = castInfo.sourceGuid
            newCast.targetUnit = nil
            newCast.auraInstanceId = 0
            newCast.triggerType = BuffWatcher_TriggerType.Cast
            newCast.icon = spell.iconID
            newCast.name = spell.name
            newCast.caster = nil
            newCast.isHarmful = false
            newCast.timerHandle = timer

            self.auraInstancesMap[key] = newCast
            self.addKeyByGuid(castInfo.sourceGuid, key)
            frameManager.AuraAdded(castInfo.sourceGuid, key)
        else
            local castInstance = self.auraInstancesMap[key]

            castInstance.duration = watcherInfo.duration
            castInstance.expirationTime = GetTime() + watcherInfo.duration

            castInstance.timerHandle.GetTimer():Cancel()
            local newTimer = getTimer(watcherInfo.duration, key)
            castInstance.timerHandle = newTimer

            frameManager.AuraUpdated(castInfo.sourceGuid, key)
        end

        hasUpdates = true

        return hasUpdates
    end

    ---@param stateKey string
    ---@param notifyFrameManager boolean
    ---@return boolean
    self.KillStateKey = function(stateKey, notifyFrameManager)
        local auraInstance = self.auraInstancesMap[stateKey]

        if (auraInstance.triggerType == BuffWatcher_TriggerType.Buff 
                or auraInstance.triggerType == BuffWatcher_TriggerType.Debuff
                or auraInstance.triggerType == BuffWatcher_TriggerType.CatchAll) then

            if (auraIdToStateKeyMap[auraInstance.auraInstanceId] ~= nil) then
                auraIdToStateKeyMap[auraInstance.auraInstanceId] = nil
            end

        elseif (auraInstance.triggerType == BuffWatcher_TriggerType.Cast) then
            local blizzardTimer = auraInstance.timerHandle.GetTimer()

            if (not blizzardTimer:IsCancelled()) then
                blizzardTimer:Cancel()
            end
        end

        self.RemoveKeyFromGuid(auraInstance.targetGuid, stateKey)

        if (notifyFrameManager) then
            frameManager.AuraRemoved(auraInstance.targetGuid, stateKey)
        end

        self.ReleaseAuraInstance(stateKey)

        return true
    end

    ---@param stateKey string
    self.ReleaseAuraInstance = function(stateKey)
        local auraInstance = self.auraInstancesMap[stateKey]

        self.auraInstancesMap[stateKey] = nil

        objectPool.ReleaseObject(auraInstance.borders)
        objectPool.ReleaseObject(auraInstance)
    end

    ---@param auraId integer
    ---@return boolean
    self.RemoveAuraId = function(auraId)
        local stateKey = auraIdToStateKeyMap[auraId]

        if (stateKey == nil) then
            return false
        end
    
        self.KillStateKey(stateKey, true)

        return true
    end

    ---@param auraInstance BuffWatcher_AuraInstance
    ---@return BuffWatcher_AuraFrame
    self.GetSingleAuraFrame = function(auraInstance, parentFrame)
        local alpha = 1.0
        if (frameType == BuffWatcher_FrameTypes.Nameplate and not contextIsHostile) then
            alpha = 0.65
        end

        ---@type BuffWatcher_AuraFrame
        local auraFrame = self.auraFramePool.GetAuraFrame()
        auraFrame.SetAura(auraInstance, self, parentFrame, alpha)

        return auraFrame
    end

    ---@param auraFrame BuffWatcher_AuraFrame
    self.ReleaseAuraFrame = function(auraFrame)
        self.auraFramePool.ReleaseAuraFrame(auraFrame)
    end

    ---@param guid string 
    self.RefreshGuid = function(guid)
        local units = unitToGuidMap.GetUnitsByGuid(guid)

        local hasUpdate = false

        for unit in pairs(units) do
            if (refreshUnitAuras(unit)) then
                hasUpdate = true
            end
        end

        if hasUpdate then
            frameManager.GuidRefreshed(guid)
        end
    end

    local removeUnit = function(unit)
        local guid = unitToGuidMap.GetGuidByUnit(unit)

        if guid == nil then
            DevTool:AddData("fixme tried to remove unit without corresponding guid " .. unit)
            return
        end

        self.ClearLooseAuras(guid, false)

        unitToGuidMap.UnlinkUnit(unit)

        frameManager.NameplateUnitRemoved(guid)
    end

    ---@comment This is really pulling double duty, but as a handler for nameplate adding and
    ---    also for when a unit frame is initally added
    ---@param unitLabel string
    ---@param notifyFrameManager boolean
    ---@return boolean
    self.DoUnitAdd = function(unitLabel, notifyFrameManager)
        if (not self.UnitPassesFilter(unitLabel)) then
            return false
        end

        local unitGuid = UnitGUID(unitLabel)
        local existingGuid = unitToGuidMap.GetGuidByUnit(unitLabel)

        if (existingGuid ~= nil) then
            if unitGuid ~= existingGuid then
                -- if unit already present isn't linked to the correct guid, then assume it's
                --   removed and proceed as though it's new
                removeUnit(unitLabel)
            else 
                -- already added, so exit
                if refreshUnitAuras(unitLabel) then
                    return true
                end
            end
        end

        local hasUpdates = false

        unitToGuidMap.LinkUnitToGuid(unitLabel, unitGuid)

        if configuration.GetShowTestAnchors() then
            handleAddMarkers(unitLabel, unitGuid)
            hasUpdates = true
        end

        -- if it's a unit frame, then defer to visibility check
        if (self.isNameplate()) then
            if refreshUnitAuras(unitLabel) then
                hasUpdates = true
            end
        else
            local inRange = isUnitFrameInRange(unitLabel)

            if inRange then
                if refreshUnitAuras(unitLabel) then
                    hasUpdates = true
                end
            end

            visibleUnits[unitLabel] = inRange
        end

        if (notifyFrameManager and self.isNameplate()) then
            frameManager.NameplateUnitAdded(unitLabel)
        end

        return hasUpdates
    end

    ---@param nameplate string
    self.NameplateRemoved = function(nameplate)
        if (not self.isNameplate()) then
            return
        end

        if (not self.UnitPassesFilter(nameplate)) then
            return
        end
        
        removeUnit(nameplate)
    end

    ---@return BuffWatcher_UnitGuidTable
    local buildTemporaryUnitMap = function()
        local newUnitMap = BuffWatcher_UnitGuidTable:new(objectPool)

        for unit, _ in pairs(contextUnits) do
            if (UnitExists(unit) and self.UnitPassesFilter(unit)) then
                newUnitMap.LinkUnitToGuid(unit, UnitGUID(unit))
            end    
        end

        return newUnitMap
    end

    ---@return boolean
    local haveUnitsChanged = function()
        local newUnitMap = buildTemporaryUnitMap()

        local areEqual = BuffWatcher_Shared.CompareValues(unitToGuidMap.GetUnitsToGuid(), newUnitMap.GetUnitsToGuid())

        if (not areEqual) then
            DevTool:AddData({ existing = CopyTable(unitToGuidMap.GetUnitsToGuid()), newUnits = CopyTable(newUnitMap.GetUnitsToGuid()), result = areEqual}, "fixme haveUnitsChanged failed result = " .. tostring(areEqual))
        end

        newUnitMap.Release()

        return not areEqual
    end


    self.GroupRosterUpdate = function()
        if (not self.isNameplate()) then
            if (haveUnitsChanged()) then
                self.DoFullReset()
            end
        end
    end

    ---@param stateKey string
    ---@return boolean
    local clearLooseAurasHelper = function(stateKey)
        local auraInstance = self.auraInstancesMap[stateKey]
        return isLooseAura(auraInstance)
    end

    -- Specifically intended to clear auras that aren't persisted between unit add/removes (we keep casts and item uses)
    ---@param guid string
    ---@param notifyFrameManager boolean
    ---@return boolean
    self.ClearLooseAuras = function(guid, notifyFrameManager)
        local stateKeys = guidToStateKeyMap[guid]
        local clearedAny = false

        if (stateKeys == nil) then 
            return false
        end

        ---@type table<string, boolean>
        local activeStateKeys = objectPool.GetObject()
        
        BuffWatcher_Shared.InsertKeysWhere(
            activeStateKeys,
            stateKeys,
            clearLooseAurasHelper
        )

        for k,_ in pairs(activeStateKeys) do
            clearedAny = true
            self.KillStateKey(k, notifyFrameManager)
        end

        objectPool.ReleaseObject(activeStateKeys)

        return clearedAny
    end

    self.DoFullClear = function()
        self.ResetAuraState()
        frameManager.Clear()
    end

    self.DoFullReset = function()
        DevTool:AddData("resetting contexts " .. name)

        self.DoFullClear()
        
        if (isLoaded) then
            self.AddAllUnits()
        end
    end

    local refreshVisibility = function()
        for unit, lastVisibility in pairs(visibleUnits) do
            local newVisibility = isUnitFrameInRange(unit)

            if (newVisibility ~= lastVisibility) then
                visibleUnits[unit] = newVisibility

                if (newVisibility == true) then
                    refreshUnitAuras(unit)
                else
                    local guid = unitToGuidMap.GetGuidByUnit(unit)
                    self.ClearLooseAuras(guid, true)
                end

                frameManager.GuidRefreshed(UnitGUID(unit))
            end
        end
    end

    
    self.HandleTimerTick = function()
        if (not self.isNameplate()) then
            refreshVisibility()
        end
    end

    ---@return table<string, boolean>
    local getContextUnits = function()
        return contextUnits
    end

    ---@return BuffWatcher_UnitGuidTable
    local getUnitGuidTable = function()
        local units = getContextUnits()
        local newTable = BuffWatcher_UnitGuidTable:new(objectPool)

        for unitName, _ in pairs(units) do
            if (UnitExists(unitName)) then
                local unitGuid = UnitGUID(unitName)

                newTable.LinkUnitToGuid(unitName, unitGuid)
            end
        end

        return newTable
    end

    ---@comment Should re-arrange all frames 
    ---@return boolean
    self.FramesChanged = function()
        if (self.isNameplate()) then
            return false
        end
    
        frameManager.FramesChanged()

        return true
    end

    local unitVisibleStatus = function(unit) 
        if (self.isNameplate()) then
            return true
        end
        
        if visibleUnits[unit] == nil then
            DevTool:AddData("visibleUnits[unit] is nil for unit " .. unit)
        end

        return visibleUnits[unit] == true
    end

    ---@param targetUnit string
    ---@param updateInfo BuffWatcher_Blizzard_UnitAuraUpdateInfo
    ---@return boolean
    self.UnitAura = function(targetUnit, updateInfo)
        local hasUpdates = false

        if (not self.UnitPassesFilter(targetUnit)) then
            return false
        end

        if (not unitVisibleStatus(targetUnit)) then
            return false
        end

        if (updateInfo.removedAuraInstanceIDs ~= nil) then
            for _, removedId in ipairs(updateInfo.removedAuraInstanceIDs) do
                handleAuraRemove(targetUnit, removedId)
            end    
        end

        if (updateInfo.addedAuras ~= nil) then
            for _, aura in ipairs(updateInfo.addedAuras) do
                handleAuraAdd(targetUnit, aura)
            end    
        end

        if (updateInfo.updatedAuraInstanceIDs ~= nil) then
            for _, auraId in ipairs(updateInfo.updatedAuraInstanceIDs) do
                ---@type BuffWatcher_Blizzard_AuraData
                local auraInfo = C_UnitAuras.GetAuraDataByAuraInstanceID(targetUnit, auraId)

                if (auraInfo ~= nil) then
                    local result = self.HandleAuraUpdate(auraInfo, targetUnit, true)

                    if (result == true) then
                        hasUpdates = true
                    end
                end
            end
        end

        if hasUpdates then
            frameManager.GuidRefreshed(UnitGUID(targetUnit))
        end

        return hasUpdates
    end


    self.AddAllUnits = function()
        -- nameplates should receive a full set of update notifications anyway
        if self.isNameplate() then
            return false
        end

        for unit, _ in pairs(self.GetPotentialUnits()) do
            if (UnitExists(unit)) then
                self.DoUnitAdd(unit, false)
            end
        end

        DevTool:AddData({ visibleUnits = CopyTable(visibleUnits), context = self.getName() }, "fixme resetting visibleUnits")

        frameManager.DoFullUpdate()

        return true
    end

    ---@return table<string, boolean>
    self.GetPotentialUnits = function()
        return contextUnits
    end

    self.DoFullClear()

    return self;
end