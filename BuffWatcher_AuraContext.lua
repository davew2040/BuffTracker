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

    ---@type table<string, table<string, boolean>>
    local guidToStateKeyMap = {}
    ---@type table<integer, string>
    local auraIdToStateKeyMap = {}  
    ---@type table<string, table<integer, boolean>>
    local stateKeyToAuraIdMap = {}  

    ---@type boolean
    self.useDefaultUnlistedMultiplier = false
    ---@type number
    self.customUnlistedMultiplier = 0.5
    ---@type table<string, BuffWatcher_AuraInstance>
    self.auraInstancesMap = {}
    ---@type any
    self.framePool = CreateFramePool("Frame")
    ---@type any
    self.cooldownFramePool = CreateFramePool("Cooldown", nil, "CooldownFrameTemplate")
    ---@type any
    self.texturePool = CreateTexturePool(UIParent)
    ---@type BuffWatcher_UnitToGuidLinkage
    self.unitToGuidLinkage = {
        unitToGuid = {},
        guidToUnit = {}
    }

    local Icons = {
        Up = 450907,
        Left = 450906,
        Right = 450908
    }

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
        guidToUnitMap = {}
        unitToGuidMap = {}
    end

    self.linkNameplateToGuid = function(nameplate, guid)
        guidToUnitMap[guid] = nameplate
        unitToGuidMap[nameplate] = guid
    end

    self.unlinkNameplateFromGuid = function(nameplate, guid)
        guidToUnitMap[guid] = nil
        unitToGuidMap[nameplate] = nil
    end

    self.getNameplateByGuid = function(guid)
        return guidToUnitMap[guid]
    end

    self.getGuidByNameplate = function(nameplate)
        return unitToGuidMap[nameplate]
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
                local raidUnit = BuffWatcher_Shared_Singleton.raidUnitsByIndex[i]
                local raidUnitGuid = UnitGUID(raidUnit)
                if (raidUnitGuid ~= nil and raidUnitGuid ~= playerGuid) then
                    result[raidUnit] = raidUnitGuid 
                end
            elseif IsInGroup() then
                local partyUnit = BuffWatcher_Shared_Singleton.partyUnitsByIndex[i]
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
            local arenaUnit = BuffWatcher_Shared_Singleton.arenaUnitsByIndex[i]
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

    ---@return BuffWatcher_UnitToGuidLinkage
    self.BuildUnitsToGuids = function()
        ---@type table<string, string>
        local unitsToGuid = {}

        if (frameType == BuffWatcher_FrameTypes.Party or frameType == BuffWatcher_FrameTypes.Raid) then
            unitsToGuid = getGroupUnits()
        elseif (frameType == BuffWatcher_FrameTypes.Arena) then
            unitsToGuid = getArenaUnits()
        elseif (frameType == BuffWatcher_FrameTypes.Nameplate) then
            unitsToGuid = getNameplateUnits()
        end

        ---@type BuffWatcher_UnitToGuidLinkage 
        local linkage = {
            unitToGuid = unitsToGuid,
            guidToUnit = BuffWatcher_Shared.InvertStringMap(unitsToGuid)
        }

        return linkage
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
            return BuffWatcher_Shared_Singleton.IsPartyUnit(unitName)
        end

        return false
    end

    ---@param unitName string
    ---@param frameType BuffWatcher_FrameTypes
    ---@param contextIsHostile boolean
    ---@return boolean
    local filterByHostility = function(unitName, frameType, contextIsHostile)
        if (frameType == BuffWatcher_FrameTypes.Nameplate and BuffWatcher_Shared_Singleton.IsNameplateUnit(unitName)) then
            local unitIsHostile = not UnitIsFriend('player', unitName)
            return unitIsHostile ~= contextIsHostile
        end

        return false
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

        if (filterByHostility(targetUnit, frameType, isHostile)) then
            return false
        end

        if (BuffWatcher_Shared.UnitIsMinor(targetUnit)) then
            return false
        end

        return true
    end

    self.ResetAuraState = function()
        guidToStateKeyMap = {}
        auraIdToStateKeyMap = {}
        stateKeyToAuraIdMap = {}

        self.auraInstancesMap = {}
    end

    ---@param auraInfo BuffWatcher_AuraInstance
    ---@return BuffWatcher_BorderDefinition[]
    self.GetAuraBorders = function(auraInfo)
        ---@type BuffWatcher_BorderDefinition[]
        local borders = {}

        -- TODO - implement coloring by buff type
        if (showDispelType) then
            table.insert(borders, {
                width = 2,
                color = BuffWatcher_Color:new(0, 0, 1, 1)
            })
        end

        table.insert(borders, {
            width = 1,
            color = BuffWatcher_Color:new(0, 0, 0, 1)
        })

        if (auraInfo.isHarmful) then
            table.insert(borders, {
                width = 2,
                color = configuration.GetDebuffColor()
            })
        else
            table.insert(borders, {
                width = 2,
                color = configuration.GetBuffColor()
            })
        end

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

        table.insert(borders, {
            width = 2,
            color =  BuffWatcher_Color:new(0.7, 0.7, 0.7, 1)
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

    ---@param borders BuffWatcher_BorderDefinition[]
    ---@param baseSize integer
    local getSizeWithBorders = function(borders, baseSize)
        for _, border in ipairs(borders) do
            baseSize = baseSize + border.width*2
        end

        return baseSize
    end

    ---@param watcherInfo BuffWatcher_StoredSpell
    local getPriority = function(watcherInfo)
        if watcherInfo ~= nil then 
            return watcherInfo.priority
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
    ---@return boolean
    local function handleAddMarkers(targetUnit, targetGuid)
        local key = getMarkerStateKey(targetGuid, 1)

        if (self.auraInstancesMap[key] ~= nil) then
            error("Attempting a double add of marker key " .. key)
        end

        local baseSize = configuration.GetDefaultSize()
        local borders = self.GetMarkerBorders()
        local sizeWithBorders = getSizeWithBorders(borders, baseSize)

        ---@type BuffWatcher_AuraInstance
        local newInstance = {
            spellId = 0,
            showCooldown = false,
            borders = borders,
            duration = 0,
            expirationTime = 0,
            frames = {},
            baseSize = baseSize,
            actualSize = sizeWithBorders,
            priority = 25,
            sourceGuid = targetGuid, 
            targetGuid = targetGuid,
            targetUnit = targetUnit,
            auraInstanceId = 0,
            triggerType = BuffWatcher_TriggerType.Marker,
            icon = Icons.Up,
            name = "Marker Up",
            caster = targetUnit,
            isHarmful = false
        }

        local frames = self.GetAuraFramesAlternate(newInstance)
        newInstance.frames = frames

        self.addKeyByGuid(targetGuid, key)

        return true
    end

    ---@param auraInfo BuffWatcher_Blizzard_AuraData
    ---@param targetUnit string
    ---@param watcherInfo BuffWatcher_StoredSpell
    ---@return boolean
    local function handleBuffOrDebuffAddOrUpdateStoredSpellByContext(auraInfo, targetUnit, watcherInfo)
        local auraId = auraInfo.auraInstanceID
        local spellInfo = {GetSpellInfo(auraInfo.spellId)}

        if (watcherInfo ~= nil and watcherInfo.hide) then
            return false
        end

        if (watcherInfo ~= nil and watcherInfo.ownOnly and sourceGuid ~= UnitGUID('player')) then
            return false
        end

        local key = getBuffDebuffStateKey(
            auraInfo.isHelpful and BuffWatcher_Shared_Singleton.SpellTypes.Buff or BuffWatcher_Shared_Singleton.SpellTypes.Debuff, 
            auraInfo.spellId, 
            auraId
        )

        if (self.auraInstancesMap[key] == nil) then
            local baseSize = configuration.GetDefaultSize()
            local borders = self.GetAuraBorders(auraInfo)
            local sizeWithBorders = getSizeWithBorders(borders, baseSize)
            local targetGuid = UnitGUID(targetUnit)


            local triggerType = BuffWatcher_TriggerType.Buff
            if (auraInfo.isHarmful) then
                triggerType = BuffWatcher_TriggerType.Debuff
            end

            ---@type BuffWatcher_AuraInstance
            local newInstance = {
                spellId = auraInfo.spellId,
                showCooldown = auraInfo.duration ~= 0,
                borders = borders,
                duration = auraInfo.duration,
                expirationTime = auraInfo.expirationTime,
                frames = {},
                baseSize = baseSize,
                actualSize = sizeWithBorders,
                priority = getPriority(watcherInfo),
                sourceGuid = auraInfo.sourceUnit and UnitGUID(auraInfo.sourceUnit) or nil, 
                targetGuid = targetGuid,
                targetUnit = targetUnit,
                auraInstanceId = auraInfo.auraInstanceID,
                triggerType = triggerType,
                icon = spellInfo[3],
                name = spellInfo[1],
                caster = targetUnit,
                isHarmful = auraInfo.isHarmful
            }

            local frames = self.GetAuraFramesAlternate(newInstance)
            newInstance.frames = frames


            self.auraInstancesMap[key] = newInstance
            auraIdToStateKeyMap[auraInfo.auraInstanceID] = key 
            self.addKeyByGuid(targetGuid, key)
        else
            local existingInstance = self.auraInstancesMap[key]

            existingInstance.duration = auraInfo.duration
            existingInstance.expirationTime = auraInfo.expirationTime

            for _, auraFrame in pairs(existingInstance.frames) do
                auraFrame.UpdateCooldown()
            end
        end

        return true
    end
    
    ---@param blizzardAura BuffWatcher_Blizzard_AuraData
    ---@param targetUnit string
    ---@return boolean
    self.HandleAuraAddOrUpdate = function(blizzardAura, targetUnit)
        --- TODO - filter by unit
        if (self.isNameplate() and not BuffWatcher_Shared_Singleton.IsNameplateUnit(targetUnit)) then
            return false
        end

        if (isHostile and BuffWatcher_Shared.UnitIsFriendly(targetUnit)) then
            return false
        end

        if (not isHostile and not BuffWatcher_Shared.UnitIsFriendly(targetUnit)) then
            return false
        end

        if (not includeBuffsAndCasts and blizzardAura.isHelpful) then
            return false
        end

        if (not includeDebuffs and blizzardAura.isHarmful) then
            return false
        end

        if (blizzardAura.isHelpful) then -- and spellBundle.buffs[aura.spellId] ~= nil) then
            local watcherInfo = spellBundle.buffs[blizzardAura.spellId]
            return handleBuffOrDebuffAddOrUpdateStoredSpellByContext(blizzardAura, targetUnit, watcherInfo)
        elseif (blizzardAura.isHarmful) then -- and spellBundle.debuffs[aura.spellId] ~= nil) then
            local watcherInfo = spellBundle.debuffs[blizzardAura.spellId]
            return handleBuffOrDebuffAddOrUpdateStoredSpellByContext(blizzardAura, targetUnit, watcherInfo)
        -- elseif (useNpcAura(UnitGUID(blizzardAura.sourceUnit))) then
        --     return handleBuffOrDebuffAddOrUpdateStoredSpellByContext(blizzardAura, targetUnit, nil)
        end

        --FIXME re-enable
        -- elseif (useNpcAura(context, sourceGuid)) then
        --     return handleBuffOrDebuffNpc(context, addedAura, targetUnit, targetGuid, sourceGuid)
        -- elseif (context.showUnlistedAuras() ~= BuffWatcher_ShowUnlistedType.None) then
        --     return handleBuffOrDebuffCatchAll(context, addedAura, targetUnit, targetGuid, sourceGuid)
        --end

        return false
    end

    ---@param targetUnit string
    ---@param updateInfo BuffWatcher_Blizzard_UnitAuraUpdateInfo
    self.UnitAura = function(targetUnit, updateInfo)
        local hasUpdates = false

        if (updateInfo.addedAuras ~= nil) then
            for _, addedAura in ipairs(updateInfo.addedAuras) do
                local result = self.HandleAuraAddOrUpdate(addedAura, targetUnit)
                if (result == true) then
                    hasUpdates = true
                end
            end
        end

        if (updateInfo.updatedAuraInstanceIDs ~= nil) then
            for _, auraId in ipairs(updateInfo.updatedAuraInstanceIDs) do
                ---@type BuffWatcher_Blizzard_AuraData
                local auraInfo = C_UnitAuras.GetAuraDataByAuraInstanceID(targetUnit, auraId)
                if (auraInfo ~= nil) then
                    local result = self.HandleAuraAddOrUpdate(auraInfo, targetUnit)
                    if (result == true) then
                        hasUpdates = true
                    end
                end
            end
        end

        if (updateInfo.removedAuraInstanceIDs ~= nil)  then
            for _, auraId in ipairs(updateInfo.removedAuraInstanceIDs) do
                local result = self.RemoveAura(auraId)
                if (result == true) then
                    hasUpdates = true
                end
            end
        end

        if hasUpdates then
            self.RedrawAurasByGuid(UnitGUID(targetUnit))
        end
    end

    ---@param stateKey string
    ---@return boolean
    self.RemoveStateKey = function(stateKey)
        local auraInstance = self.auraInstancesMap[stateKey]

        if (auraInstance.triggerType == BuffWatcher_TriggerType.Buff 
                or auraInstance.triggerType == BuffWatcher_TriggerType.Debuff
                or auraInstance.triggerType == BuffWatcher_TriggerType.CatchAll) then
            if (auraIdToStateKeyMap[auraInstance.auraInstanceId] ~= nil) then
                auraIdToStateKeyMap[auraInstance.auraInstanceId] = nil
            end
        end

        self.auraInstancesMap[stateKey] = nil
        self.removeKeyFromGuid(auraInstance.targetGuid, stateKey)

        for _, auraFrame in pairs(auraInstance.frames) do
            auraFrame.Dispose()
        end

        return true
    end

    ---@param auraId integer
    ---@return boolean
    self.RemoveAura = function(auraId)
        if (auraIdToStateKeyMap[auraId] ~= nil) then
            local stateKey = auraIdToStateKeyMap[auraId]
            self.RemoveStateKey(stateKey)

            return true
        end

        return false
    end

    ---@param guid string
    ---@return nil
    self.RedrawAurasByGuid = function(guid) 
        local auraKeysByGuid = self.getKeysByGuid(guid)
        
        ---@type table<any, BuffWatcher_AuraFrame[]>
        local byWoWframe = {}

        for auraKey, _ in pairs(auraKeysByGuid) do
            local auraInstance = self.auraInstancesMap[auraKey]

            for wowFrame, auraFrame in pairs(auraInstance.frames) do
                if byWoWframe[wowFrame] == nil then
                    byWoWframe[wowFrame] = {}
                end
                table.insert(byWoWframe[wowFrame], auraFrame)
            end
        end

        for _, auraFrames in pairs(byWoWframe) do

            local x = 0
            for _, auraFrame in ipairs(auraFrames) do
                auraFrame.SetOffsets(x, 0)

                if (growDirection == BuffWatcher_GrowDirection.Left) then
                    x = x - auraFrame.GetWidth()
                else 
                    x = x + auraFrame.GetWidth()
                end
            end
        end
    end

    ---@param auraInfo BuffWatcher_Blizzard_AuraData
    ---@param auraInstance BuffWatcher_AuraInstance
    ---@param borders BuffWatcher_BorderDefinition[]
    ---@return BuffWatcher_FramesCollection
    self.GetAuraFrames = function(auraInfo, auraInstance, borders)
        ---@type BuffWatcher_FramesCollection
        local framesCollection = BuffWatcher_FramesCollection:new()

        local unit = self.unitToGuidLinkage.guidToUnit[auraInstance.targetGuid]

        local parentFrame = LGF.GetUnitFrame(unit, { 
            ignorePlayerFrame = true, 
            ignoreTargetFrame = true, 
            ignoreTargettargetFrame = true,
        })

        self.BuildFrames(parentFrame, framesCollection, borders, 1, auraInfo, auraInstance, auraInstance.actualSize, 0)
        framesCollection.parentFrame = parentFrame

        return framesCollection
    end

    ---@param targetUnit string
    ---@return any[]
    local getTargetFrames = function(targetUnit)
        local result = {}

        if (self.isNameplate()) then
            table.insert(result, C_NamePlate.GetNamePlateForUnit(targetUnit))
        else
            local frame = LGF.GetUnitFrame(targetUnit, { 
                ignorePlayerFrame = true, 
                ignoreTargetFrame = true, 
                ignoreTargettargetFrame = true,
            })
            table.insert(result, frame)
        end

        return result
    end

    ---@param auraInstance BuffWatcher_AuraInstance
    ---@return table<any, BuffWatcher_AuraFrame>
    self.GetAuraFramesAlternate = function(auraInstance)
        local targetFrames = getTargetFrames(auraInstance.targetUnit)

        ---@type table<any, BuffWatcher_AuraFrame>
        local result = {}

        for _, targetFrame in ipairs(targetFrames) do
            ---@type BuffWatcher_AuraFrame
            local auraFrame = BuffWatcher_AuraFrame:new(
                targetFrame, 
                auraInstance, 
                self.framePool, 
                self.cooldownFramePool, 
                self.texturePool, 
                auraInstance,
                self
            )

            result[targetFrame] = auraFrame
        end

        return result
    end

    ---@param unit string
    ---@return boolean
    self.DoUnitUpdate = function(unit)
        --- TODO - enable other frame types when done debugging
        if (frameType ~= BuffWatcher_FrameTypes.Nameplate) then
            return false
        end

        --handleAddMarkers(unit, UnitGUID(unit))

        local hasUpdates = false

        AuraUtil.ForEachAura(unit, "HELPFUL", nil, 
            function(auraInfo) 
                ---@cast auraInfo BuffWatcher_Blizzard_AuraData
                if (self.HandleAuraAddOrUpdate(auraInfo, unit)) then
                    hasUpdates = true
                end
            end,
            true
        )

        AuraUtil.ForEachAura(unit, "HARMFUL", nil, 
            function(auraInfo) 
                ---@cast auraInfo BuffWatcher_Blizzard_AuraData
                if (self.HandleAuraAddOrUpdate(auraInfo, unit)) then
                    hasUpdates = true
                end
            end,
            true
        )

        if (hasUpdates) then
            self.RedrawAurasByGuid(UnitGUID(unit))
        end

        return hasUpdates
    end

    ---@param unit string
    ---@return boolean
    self.ClearUnit = function(unit)
        --- TODO - enable other frame types when done debugging
        if (frameType ~= BuffWatcher_FrameTypes.Nameplate) then
            return false
        end

        local stateKeys = guidToStateKeyMap[UnitGUID(unit)]

        if (stateKeys == nil) then
            return false
        end

        DevTool:AddData(CopyTable(stateKeys), "Found stateKeys attached to unit " .. unit)


        ---@type string[]
        local stateKeysToDelete = {}

        for k,_ in pairs(stateKeys) do
            table.insert(stateKeysToDelete, k)
        end

        for _, stateKey in ipairs(stateKeysToDelete) do
            self.RemoveStateKey(stateKey)
        end

        return true
    end

    ---@return boolean
    self.DoFullUpdate = function()
        return true 
        -- --- TODO - enable other frame types when done debugging
        -- if (frameType ~= BuffWatcher_FrameTypes.Nameplate) then
        --     return false
        -- end

        -- DevTool:AddData("fixme DoFullUpdate")

        -- local hasUpdates = false

        -- AuraUtil.ForEachAura(unit, "HELPFUL", nil, 
        --     function(auraInfo) 
        --         ---@cast auraInfo BuffWatcher_Blizzard_AuraData
        --         if (handleAuraAddOrUpdate(auraInfo, unit)) then
        --             hasUpdates = true
        --         end
        --     end,
        --     true
        -- )
        -- AuraUtil.ForEachAura(unit, "HARMFUL", nil, 
        --     function(auraInfo) 
        --         ---@cast auraInfo BuffWatcher_Blizzard_AuraData
        --         if (handleAuraAddOrUpdate(auraInfo, unit)) then
        --             hasUpdates = true
        --         end
        --     end,
        --     true
        -- )

        -- return hasUpdates
    end

    return self;
end