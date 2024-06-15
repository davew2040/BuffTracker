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
---@field selfPoint string,
---@field anchorPoint string
---@field unlistedRowCount integer
---@field useDefaultUnlistedMultiplier boolean
---@field customUnlistedMultiplier number
BuffWatcher_AuraContext_Params = {}

---@param params BuffWatcher_AuraContext_Params
---@param configuration BuffWatcher_Configuration
---@param framePool any
function BuffWatcher_AuraContext:new(params, configuration, framePool)
    self = {};

    local maxDistance = 100.0

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

    -- do not add/remove to this directly! use the helpers
    ---@type table<string, table<string, boolean>>
    local guidToStateKeyMap = {}

    ---@type table<integer, string>
    local auraIdToStateKeyMap = {}  

    -- maps state keys to aura instances
    ---@type table<string, BuffWatcher_AuraInstance>
    self.auraInstancesMap = {}

    ---@type BuffWatcher_UnitGuidTable
    local unitToGuidMap = BuffWatcher_UnitGuidTable:new()

    ---@type boolean
    self.useDefaultUnlistedMultiplier = false
    ---@type number
    self.customUnlistedMultiplier = 0.5

    ---@type any
    self.framePool = CreateFramePool("Frame")
    ---@type any
    self.cooldownFramePool = CreateFramePool("Cooldown", nil, "CooldownFrameTemplate")
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

    ---@param frameType BuffWatcher_FrameTypes
    ---@return table<string, boolean>
    local initializeContextUnits = function(frameType)
        if (frameType == BuffWatcher_FrameTypes.Nameplate) then
            return CopyTable(BuffWatcher_Shared_Singleton.nameplateUnits)

        elseif (frameType == BuffWatcher_FrameTypes.Arena) then
            return CopyTable(BuffWatcher_Shared_Singleton.arenaUnits)

        elseif (frameType == BuffWatcher_FrameTypes.Battleground) then
            local bgUnits = CopyTable(BuffWatcher_Shared_Singleton.partyUnits)
            bgUnits['player'] = true
            return bgUnits

        elseif (frameType == BuffWatcher_FrameTypes.Party) then
            local partyUnits = CopyTable(BuffWatcher_Shared_Singleton.partyUnits)
            partyUnits['player'] = true
            return partyUnits

        elseif (frameType == BuffWatcher_FrameTypes.Raid) then
            local raidUnits = CopyTable(BuffWatcher_Shared_Singleton.raidUnits)
            raidUnits['player'] = true
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
        self.useDefaultUnlistedMultiplier = params.useDefaultUnlistedMultiplier
        self.customUnlistedMultiplier = params.customUnlistedMultiplier

        contextUnits = initializeContextUnits(frameType)
        frameManager = BuffWatcher_FrameManagerNew:new(self, configuration)
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

        spellBundle = newSpellBundle

        self.DoFullReset()
    end

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
    self.GetKeysByGuid = function(targetGuid) 
        if (guidToStateKeyMap[targetGuid] == nil) then
            return {}
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

    ---@return boolean
    self.IncludeNpcs = function() 
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
            local isRaid = BuffWatcher_Shared_Singleton.IsPartyUnit(unitName) or
                BuffWatcher_Shared_Singleton.IsRaidUnit(unitName)
                or unitName == 'player'
            return isRaid 
        elseif (frameType == BuffWatcher_FrameTypes.Party) then
            local isGroup = BuffWatcher_Shared_Singleton.IsPartyUnit(unitName) or
                BuffWatcher_Shared_Singleton.IsRaidUnit(unitName)
                or unitName == 'player'
            return isGroup
        elseif (frameType == BuffWatcher_FrameTypes.Arena) then
            return BuffWatcher_Shared_Singleton.IsArenaUnit(unitName)
        elseif (frameType == BuffWatcher_FrameTypes.Nameplate) then
            return BuffWatcher_Shared_Singleton.IsNameplateUnit(unitName)
        elseif (frameType == BuffWatcher_FrameTypes.Battleground) then
            return unitName == 'player' or BuffWatcher_Shared_Singleton.IsPartyUnit(unitName)
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

    ---@param targetUnit string
    ---@return boolean -- false if the filter fails and event should not be processed
    self.FilterEvent = function(targetUnit)
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

    self.ResetAuraState = function()
        for key, _ in pairs(self.auraInstancesMap) do
            self.KillStateKey(key, false)
        end

        guidToStateKeyMap = {}
        auraIdToStateKeyMap = {}
        unitToGuidMap.Reset()
        self.auraInstancesMap = {}
    end

    ---@param auraInfo BuffWatcher_Blizzard_AuraData
    ---@return BuffWatcher_BorderDefinition[]
    self.GetAuraBorders = function(auraInfo)
        ---@type BuffWatcher_BorderDefinition[]
        local borders = {}

        table.insert(borders, {
            width = 1,
            color = BuffWatcher_Color:new(0, 0, 0, 1)
        })

        -- TODO - implement coloring by buff type
        if (showDispelType and auraInfo.dispelName ~= nil) then
            table.insert(borders, {
                width = configuration.GetDispelBorderSize(),
                color = getDispelColor(auraInfo.dispelName)
            })

            table.insert(borders, {
                width = 1,
                color = BuffWatcher_Color:new(0, 0, 0, 1)
            })
        end

        if (auraInfo.isHarmful) then
            table.insert(borders, {
                width = configuration.GetBuffDebuffBorderSize(),
                color = configuration.GetDebuffColor()
            })
        else
            table.insert(borders, {
                width = configuration.GetBuffDebuffBorderSize(),
                color = configuration.GetBuffColor()
            })
        end

        table.insert(borders, {
            width = 1,
            color = BuffWatcher_Color:new(0, 0, 0, 1)
        })

        return borders
    end

    ---@param castInfo BuffWatcher_Blizzard_CastInfo
    ---@return BuffWatcher_BorderDefinition[]
    self.GetCastBorders = function(castInfo)
        ---@type BuffWatcher_BorderDefinition[]
        local borders = {}

        table.insert(borders, {
            width = 1,
            color = BuffWatcher_Color:new(0, 0, 0, 1)
        })

        -- Casts are always considered to be helpful to the caster
        table.insert(borders, {
            width = configuration.GetBuffDebuffBorderSize(),
            color = configuration.GetBuffColor()
        })

        table.insert(borders, {
            width = 1,
            color = BuffWatcher_Color:new(0, 0, 0, 1)
        })

        return borders
    end

    ---@return BuffWatcher_BorderDefinition[]
    self.GetMarkerBorders = function()
        ---@type BuffWatcher_BorderDefinition[]
        local borders = {}

        table.insert(borders, {
            width = 1,
            color = BuffWatcher_Color:new(0, 0, 0, 1)
        })

        local markerColor = configuration.GetBuffColor()
        if (self.includeDebuffs()) then
            markerColor = configuration.GetDebuffColor()
        end

        table.insert(borders, {
            width = configuration.GetBuffDebuffBorderSize(),
            color =  markerColor
        })

        table.insert(borders, {
            width = 1,
            color = BuffWatcher_Color:new(0, 0, 0, 1)
        })

        return borders
    end

    ---comment
    ---@return integer
    local getFrameLevel = function()
        return 100
    end

    ---@param targetGuid string
    ---@param index integer
    ---@return string
    local getMarkerStateKey = function(targetGuid, index) 
        return BuffWatcher_TriggerType.Marker .. ":" .. targetGuid .. ":" .. tostring(index)
    end

    ---@param type SpellTypes
    ---@param spellId integer
    ---@param auraId integer
    ---@return string
    local getBuffDebuffStateKey = function(type, spellId, auraId) 
        return type .. ":" .. spellId .. ":" .. auraId
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
        return BuffWatcher_TriggerType.Cast .. ":" .. spellId .. ":" .. sourceGuid
    end

    ---@param borders BuffWatcher_BorderDefinition[]
    ---@param baseSize integer
    local getSizeWithBorders = function(borders, baseSize)
        for _, border in ipairs(borders) do
            baseSize = baseSize + border.width*2
        end

        return baseSize
    end

    ---@param watcherInfo? BuffWatcher_StoredSpell
    ---@param blizzAuraInfo? BuffWatcher_Blizzard_AuraData
    local getPriority = function(watcherInfo, blizzAuraInfo)
        if watcherInfo ~= nil then 
            return watcherInfo.priority
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
        local newInstance = {
            stateKey = key,
            spellId = 0,
            dispelName = nil,
            showCooldown = false,
            borders = borders,
            duration = 0,
            expirationTime = 0,
            baseSize = baseSize,
            actualSize = baseSize * multiplier,
            priority = priority,
            sourceGuid = targetGuid, 
            targetGuid = targetGuid,
            targetUnit = targetUnit,
            auraInstanceId = 0,
            triggerType = BuffWatcher_TriggerType.Marker,
            icon = icon,
            name = "Marker",
            caster = targetUnit,
            isHarmful = false,
            timerHandle = nil
        }

        self.auraInstancesMap[key] = newInstance
        self.addKeyByGuid(targetGuid, key)

        return true
    end

    ---@param targetUnit string
    ---@param targetGuid string
    local function handleAddMarkers(targetUnit, targetGuid)
        handleSingleMarker(targetUnit, targetGuid, Icons.Up, 25, 1.3)

        local arrowIcon = self.GetGrowthDirection() == BuffWatcher_GrowDirection.Left and Icons.Left or Icons.Right

        handleSingleMarker(targetUnit, targetGuid, arrowIcon, 24, 1.0)
        handleSingleMarker(targetUnit, targetGuid, arrowIcon, 23, 1.0)
    end

    ---@param watcherInfo? BuffWatcher_StoredSpell
    ---@return number
    local getAuraSizeMultiplier = function(watcherInfo)
        if watcherInfo ~= nil then
            return watcherInfo.sizeMultiplier
        else
            return configuration.GetNpcMultiplier()
        end
    end

    ---@param key string
    ---@param auraInfo BuffWatcher_Blizzard_AuraData
    ---@param targetUnit string
    ---@param watcherInfo? BuffWatcher_StoredSpell
    local function addNewStateKey(key, auraInfo, targetUnit, watcherInfo)
        local spellInfo = {GetSpellInfo(auraInfo.spellId)}
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
        local newInstance = {
            spellId = auraInfo.spellId,
            stateKey = key,
            dispelName = auraInfo.dispelName,
            showCooldown = auraInfo.duration ~= 0,
            borders = borders,
            duration = auraInfo.duration,
            expirationTime = auraInfo.expirationTime,
            baseSize = baseSize,
            actualSize = baseSize * sizeMultiplier,
            priority = getPriority(watcherInfo, auraInfo),
            sourceGuid = auraInfo.sourceUnit and UnitGUID(auraInfo.sourceUnit) or nil, 
            targetGuid = targetGuid,
            targetUnit = targetUnit,
            auraInstanceId = auraInfo.auraInstanceID,
            triggerType = triggerType,
            icon = spellInfo[3],
            name = spellInfo[1],
            caster = targetUnit,
            isHarmful = auraInfo.isHarmful,
            timerHandle = nil
        }

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
    ---@param maxRange number
    ---@return boolean
    local isUnitFrameInRange = function(unit, maxRange)
        if (unit == 'player') then
            return true
        end

        return CheckInteractDistance(unit, 4)
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
        if (watcherInfo == nil and self.IncludeNpcs()) then
            -- "isFromPlayerOrPlayerPet" is only reliable if the unit is in the same zone or a nameplate - ignore auras on units in a different zone
            if (self.isNameplate()) then
                return not blizzardAura.isFromPlayerOrPlayerPet
            else 
                return isUnitFrameInRange(targetUnit, maxDistance) and not blizzardAura.isFromPlayerOrPlayerPet
            end
        end

        if (watcherInfo ~= nil) then
            if watcherInfo.hide then
                return false
            end

            if (watcherInfo.ownOnly and blizzardAura.sourceUnit ~= 'player') then
                return false
            end

            if not isUnitFrameInRange(targetUnit, maxDistance) then
                return false
            end
        end

        return true
    end
    

    ---@param unit string
    local refreshUnitAuras = function(unit)
        local hasUpdates = false

        ---@type table<string, BuffWatcher_Blizzard_AuraData>
        local foundStateKeys = {}

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

        return hasUpdates
    end

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

        if (not self.FilterEvent(castInfo.sourceName)) then
            return false
        end

        local spellName, _, spellIcon = GetSpellInfo(castInfo.spellId)

        local key = getCastStateKey(castInfo.spellId, castInfo.sourceGuid)

        if (self.auraInstancesMap[key] == nil) then
            local baseSize = self.GetIconSize()
            local borders = self.GetCastBorders(castInfo)
            local timer = getTimer(watcherInfo.duration, key)

            ---@type BuffWatcher_AuraInstance
            local newCast =
            {
                spellId = castInfo.spellId,
                stateKey = key,
                dispelName = nil,
                showCooldown = true,
                borders = borders,
                duration = watcherInfo.duration,
                expirationTime = GetTime() + watcherInfo.duration,
                baseSize = baseSize,
                actualSize = baseSize * watcherInfo.sizeMultiplier,
                priority = getPriority(watcherInfo, nil),
                sourceGuid = castInfo.sourceGuid, 
                targetGuid = castInfo.sourceGuid,
                targetUnit = nil,
                auraInstanceId = 0,
                triggerType = BuffWatcher_TriggerType.Cast,
                icon = spellIcon,
                name = spellName,
                caster = nil,
                isHarmful = false,
                timerHandle = timer
            }

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

        self.auraInstancesMap[stateKey] = nil
        self.removeKeyFromGuid(auraInstance.targetGuid, stateKey)

        if (notifyFrameManager) then
            frameManager.AuraRemoved(auraInstance.targetGuid, stateKey)
        end

        return true
    end

    ---@param auraId integer
    ---@return boolean
    self.RemoveAuraId = function(auraId)
        if (auraIdToStateKeyMap[auraId] ~= nil) then
            local stateKey = auraIdToStateKeyMap[auraId]
            self.KillStateKey(stateKey, true)

            return true
        end

        return false
    end

    ---@param auraInstance BuffWatcher_AuraInstance
    ---@return BuffWatcher_AuraFrame
    self.GetSingleAuraFrame = function(auraInstance, parentFrame)
        local alpha = 1.0
        if (frameType == BuffWatcher_FrameTypes.Nameplate and not contextIsHostile) then
            alpha = 0.65
        end

        ---@type BuffWatcher_AuraFrame
        local auraFrame = BuffWatcher_AuraFrame:new(
            parentFrame, 
            auraInstance, 
            self.framePool, 
            self.cooldownFramePool, 
            self.texturePool, 
            auraInstance,
            self,
            alpha, 
            self.getName() .. ":" .. auraInstance.stateKey
        )

        return auraFrame
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

    ---@param unitLabel string
    ---@param notifyFrameManager boolean
    ---@return boolean
    self.DoUnitAdd = function(unitLabel, notifyFrameManager)
        if (not self.FilterEvent(unitLabel)) then
            return false
        end

        --- if we've already added, then stop
        if (unitToGuidMap.GetGuidByUnit(unitLabel) ~= nil) then
            return false
        end

        local hasUpdates = false

        local unitGuid = UnitGUID(unitLabel)

        unitToGuidMap.LinkUnitToGuid(unitLabel, unitGuid)

        if (configuration.GetShowTestAnchors()) then
            handleAddMarkers(unitLabel, unitGuid)
            hasUpdates = true
        end

        if refreshUnitAuras(unitLabel) then
            hasUpdates = true
        end

        if (notifyFrameManager) then
            frameManager.NameplateUnitAdded(unitLabel)
        end

        return hasUpdates
    end

    ---@param nameplate string
    self.NameplateRemoved = function(nameplate)
        if (not self.isNameplate()) then
            return
        end

        if (not self.FilterEvent(nameplate)) then
            return
        end
        
        local guid = unitToGuidMap.GetGuidByUnit(nameplate)
        unitToGuidMap.UnlinkUnit(nameplate)

        self.ClearLooseAuras(guid, false)

        frameManager.NameplateUnitRemoved(guid)
    end

    -- Specifically intended to clear auras that aren't persisted between unit add/removes (we keep casts and item uses)
    ---@param guid string
    ---@param notifyFrameManager boolean
    ---@return boolean
    self.ClearLooseAuras = function(guid, notifyFrameManager)
        local stateKeys = guidToStateKeyMap[guid]

        if (stateKeys == nil) then 
            stateKeys = {}
        end

        ---@type table<string, boolean>
        local activeStateKeys = BuffWatcher_Shared_Singleton.TableKeyFilter(stateKeys,
            function(stateKey)
                local auraInstance = self.auraInstancesMap[stateKey]
                return isLooseAura(auraInstance)
            end
        )

        for k,_ in pairs(activeStateKeys) do
            self.KillStateKey(k, notifyFrameManager)
        end

        return true
    end

    self.DoFullClear = function()
        self.ResetAuraState()
        frameManager.Clear()
    end

    self.DoFullReset = function()
        DevTool:AddData("resetting contexts" .. name)

        self.DoFullClear()
        
        if (isLoaded) then
            self.UpdateAllUnits()
        end
    end

    ---@return table<string, boolean>
    local getContextUnits = function()
        return contextUnits
    end

    ---@return BuffWatcher_UnitGuidTable
    local getUnitGuidTable = function()
        local units = getContextUnits()
        local newTable = BuffWatcher_UnitGuidTable:new()

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


    ---@param targetUnit string
    ---@param updateInfo BuffWatcher_Blizzard_UnitAuraUpdateInfo
    ---@return boolean
    self.UnitAura = function(targetUnit, updateInfo)
        local hasUpdates = false

        if (not self.FilterEvent(targetUnit)) then
            return false
        end

        if (refreshUnitAuras(targetUnit)) then
            hasUpdates = true
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


    self.UpdateAllUnits = function()
        DevTool:AddData("fixme UpdateAllUnits " .. name)

        local previousGuids = unitToGuidMap.GetAllGuids()
        local newUnitGuidMap = getUnitGuidTable()
        local newGuids = newUnitGuidMap.GetAllGuids()

        for newGuid, _ in pairs(newGuids) do
            if (previousGuids[newGuid] == nil) then
                local units = newUnitGuidMap.GetUnitsByGuid(newGuid)
                ---@type string?
                local unit = BuffWatcher_Shared.FirstKeyOrDefault(units)
                if (unit ~= nil) then
                    self.DoUnitAdd(unit, false)
                end
            end

            previousGuids[newGuid] = nil
        end

        --- curently not used, as we only call this on a reset
        -- for unusedGuid, _ in pairs(previousGuids) do
        --     self.ClearGuid(unusedGuid)
        -- end

        unitToGuidMap = newUnitGuidMap

        frameManager.DoFullUpdate()

        return true
    end

    ---@return table<string, boolean>
    self.GetPotentialUnits = function()
        return contextUnits
    end

    return self;
end