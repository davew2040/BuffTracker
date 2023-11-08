local LGF = LibStub("LibGetFrame-1.0")

---@class BuffWatcher_WeakAuraInterface
BuffWatcher_WeakAuraInterface = {}

---@param configuration BuffWatcher_Configuration
---@param contextStore BuffWatcher_AuraContextStore
function BuffWatcher_WeakAuraInterface:new(configuration, contextStore)
    self = {};

    local GroupSpacingWidth = 10

    local storedSpellsRegistry = nil
    local initialized = false

    ---@type table<integer, string>
    local partySufFrameMap = {}
    ---@type table<integer, string>
    local raidSufFrameMap = {}

    local activeGuids 
    local resetNameplatesMap = function(context)
        context.unlinkAllNameplates()
        for i=1, 40 do
            local u = "nameplate"..i
            if UnitExists(u) then
                local guid = UnitGUID(u)
                context.linkNameplateToGuid(u, guid)
            end
        end
    end

    local initialize = function()
        for i=1, 20 do
            partySufFrameMap[i] = BuffWatcher_Shared_Singleton.SufPartyFramePrefix .. tostring(i)
        end

        for i=1, 40 do
            raidSufFrameMap[i] = BuffWatcher_Shared_Singleton.SufRaidFramePrefix .. tostring(i)
        end
    end

    self.RegisterSpells = function(incomingStoredSpellsRegistry)
        storedSpellsRegistry = incomingStoredSpellsRegistry

        local contexts = contextStore.GetContexts()

        for k, context in pairs(contexts) do
            resetNameplatesMap(context)
        end
    end

    ---@param type SpellTypes
    ---@param spellId integer
    ---@param targetGuid string
    ---@param sourceGuid string
    ---@param auraId integer
    ---@param contextName string
    ---@return string
    local getBuffDebuffStateKey = function(type, spellId, targetGuid, sourceGuid, auraId, contextName) 
        return type .. ":" .. spellId .. ":" .. targetGuid ..":" .. tostring(sourceGuid) .. ":" .. auraId .. ":" .. contextName
    end

    ---@param type SpellTypes
    ---@param spellId integer
    ---@param sourceGuid string
    ---@param contextName string
    ---@return string
    local getCastStateKey = function(type, spellId, sourceGuid, contextName) 
        return type .. ":" .. spellId .. ":" .. sourceGuid .. ":" .. contextName
    end

    ---@param allstates table<string, any>
    ---@param context BuffWatcher_AuraContext
    ---@param auraInfo BuffWatcher_Blizzard_AuraData
    ---@param watcherInfo BuffWatcher_StoredSpell
    ---@param targetUnit string
    ---@param normalizedUnit string
    ---@param targetGuid string
    ---@param sourceGuid string
    ---@return boolean
    local function handleBuffOrDebuffAddOrUpdateStoredSpell(allstates, context, auraInfo, watcherInfo, targetUnit, normalizedUnit, targetGuid, sourceGuid)
        local auraId = auraInfo.auraInstanceID
        local spellInfo = {GetSpellInfo(auraInfo.spellId)}

        DevTool:AddData(allstates, "fixme adding buff 3")

        if (watcherInfo.hide) then
            return false
        end

        if (watcherInfo.ownOnly and sourceGuid ~= UnitGUID('player')) then
            return false
        end

        local key = getBuffDebuffStateKey(watcherInfo.buffType, watcherInfo.spellId, targetGuid, sourceGuid, auraId, context.getName())

        if (allstates[key] == nil) then
            DevTool:AddData(allstates, "fixme adding buff 4")

            context.addAuraIdToKeyEntry(auraId, key)
            context.addKeyByGuid(targetGuid, key)

            local autoHide = true
            if (auraInfo.duration == 0) then
                autoHide = false
            end

            allstates[key] = {
                show = true,
                changed = true,
                progressType = auraInfo.duration == 0 and "static" or "timed",
                duration = auraInfo.duration,
                name = auraInfo.name,
                icon = spellInfo[3],
                caster = auraInfo.sourceUnit,
                autoHide = autoHide,
                showGlow = true,
                sizeMultiplier = watcherInfo.sizeMultiplier,
                unit = targetUnit,
                size = configuration.GetDefaultSize(),
                index = BuffWatcher_Shared_Singleton.GetAuraIndexByPriority(watcherInfo.priority),
                targetGuid = targetGuid,
                auraInstanceID = auraInfo.auraInstanceID
            }
        else
            allstates[key].duration = auraInfo.duration
            allstates[key].expirationTime = auraInfo.expirationTime
            allstates[key].changed = true
        end

        DevTool:AddData(CopyTable(allstates), "fixme after stored add")
        return true
    end

    ---@param allstates table<string, any>
    ---@param context BuffWatcher_AuraContext
    ---@param auraInfo BuffWatcher_Blizzard_AuraData
    ---@param targetUnit string
    ---@param normalizedUnit string
    ---@param targetGuid string
    ---@param sourceGuid string
    ---@return boolean
    local function handleBuffOrDebuffCatchAll(allstates, context, auraInfo,  targetUnit, normalizedUnit, targetGuid, sourceGuid)
        local auraId = auraInfo.auraInstanceID
        local spellInfo = {GetSpellInfo(auraInfo.spellId)}

        if (context.showUnlistedAuras() == BuffWatcher_ShowUnlistedType.OwnOnly and sourceGuid ~= UnitGUID("player")) then
            return false
        end
            
        local key = getBuffDebuffStateKey(BuffWatcher_Shared_Singleton.SpellTypes.Buff, auraInfo.spellId, targetGuid, sourceGuid, auraId, context.getName())
            
        context.addAuraIdToKeyEntry(auraId, key)
        context.addKeyByGuid(targetGuid, key)


        DevTool:AddData(allstates, "fixme adding buff 4")

        context.addAuraIdToKeyEntry(auraId, key)
        context.addKeyByGuid(targetGuid, key)

        local autoHide = true
        if (auraInfo.duration == 0) then
            autoHide = false
        end

        if (allstates[key] == nil) then
            allstates[key] = {
                show = true,
                changed = true,
                progressType = auraInfo.duration == 0 and "static" or "timed",
                duration = auraInfo.duration,
                name = auraInfo.name,
                icon = spellInfo[3],
                caster = auraInfo.sourceUnit,
                autoHide = autoHide,
                showGlow = false,
                sizeMultiplier = configuration.GetUnlistedMultiplier(),
                index = 10,
                unit = targetUnit,
                size = configuration.GetDefaultSize(),
                showDispelOutline = true,
                targetGuid = targetGuid
            }

            DevTool:AddData(CopyTable(allstates), "fixme after catch all add")
        else
            allstates[key].duration = auraInfo.duration
            allstates[key].expirationTime = auraInfo.expirationTime
            allstates[key].changed = true
        end

        return true
    end

---@param allstates table<string, any>
    ---@param context BuffWatcher_AuraContext
    ---@param addedAura BuffWatcher_Blizzard_AuraData
    ---@param targetUnit string
    ---@param normalizedUnit string
    ---@param targetGuid string
    ---@param sourceGuid string
    ---@return boolean
    local handleBuffAddOrUpdate = function(allstates, context, addedAura, targetUnit, normalizedUnit, targetGuid, sourceGuid)
        local weakAuraBundle = context.GetWeakAuraBundle()

        if (weakAuraBundle.buffs[addedAura.spellId] ~= nil) then
            local watcherInfo = weakAuraBundle.buffs[addedAura.spellId]
            return handleBuffOrDebuffAddOrUpdateStoredSpell(allstates, context, addedAura, watcherInfo, targetUnit, normalizedUnit, targetGuid, sourceGuid)
        elseif (context.showUnlistedAuras() ~= BuffWatcher_ShowUnlistedType.None) then
            return handleBuffOrDebuffCatchAll(allstates, context, addedAura, targetUnit, normalizedUnit, targetGuid, sourceGuid)
        end

        return false
    end

    ---@param allstates table<string, any>
    ---@param context BuffWatcher_AuraContext
    ---@param addedAura BuffWatcher_Blizzard_AuraData
    ---@param targetUnit string
    ---@param normalizedUnit string
    ---@param targetGuid string
    ---@param sourceGuid string
    ---@return boolean
    local handleDebuffAddOrUpdate = function(allstates, context, addedAura, targetUnit, normalizedUnit, targetGuid, sourceGuid)
        local weakAuraBundle = context.GetWeakAuraBundle()

        if (weakAuraBundle.debuffs[addedAura.spellId] ~= nil) then
            local watcherInfo = weakAuraBundle.debuffs[addedAura.spellId]

            return handleBuffOrDebuffAddOrUpdateStoredSpell(allstates, context, addedAura, watcherInfo, targetUnit, normalizedUnit, targetGuid, sourceGuid)
        elseif (context.showUnlistedAuras() ~= BuffWatcher_ShowUnlistedType.None) then
            return handleBuffOrDebuffCatchAll(allstates, context, addedAura, targetUnit, normalizedUnit, targetGuid, sourceGuid)
        end

        return false
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

    
    ---@param allstates any
    ---@param context BuffWatcher_AuraContext
    ---@param guid string
    local removeAurasByGuid = function(allstates, context, guid)

        local stateKeysByGuid = context.getKeysByGuid(guid)
        
        ---@type table<string, boolean>
        local auraInstanceIds = {}

        for key,_ in pairs(stateKeysByGuid) do
            allstates[key].changed = true
            allstates[key].show = false

            if (allstates[key].auraInstanceID ~= nil) then
                auraInstanceIds[allstates[key].auraInstanceID] = true
            end
        end

        local keysCopy = CopyTable(stateKeysByGuid)

        for key,_ in keysCopy do
            context.removeKeyByGuid(guid, key)
        end

        for auraInstanceId, _ in auraInstanceIds do
            context.removeAuraIdToKeyEntry(auraInstanceId)
        end
    end

    ---@param allstates any
    ---@param context BuffWatcher_AuraContext
    ---@param auraData BuffWatcher_Blizzard_AuraData
    ---@param targetUnit string
    ---@param targetGuid string
    local handleBuffOrDebuffAddOrUpdate = function(allstates, context, auraData, targetUnit, targetGuid)
        local hasUpdates = false
        ---@type string
        local sourceGuid = nil
        if (auraData.sourceUnit ~= nil) then
            sourceGuid = UnitGUID(auraData.sourceUnit)
        end

        if (auraData.isHelpful and context.includeBuffsAndCasts()) then
            local result = handleBuffAddOrUpdate(allstates, context, auraData, targetUnit, targetUnit, targetGuid, sourceGuid)
            if (result) then
                hasUpdates = true
            end
        elseif (auraData.isHarmful and context.includeDebuffs()) then
            local result = handleDebuffAddOrUpdate(allstates, context, auraData, targetUnit, targetUnit, targetGuid, sourceGuid)
            if (result) then
                hasUpdates = true
            end
        end

        return hasUpdates
    end

    ---@param allstates any
    ---@param context BuffWatcher_AuraContext
    ---@param ... any
    local handleBuffsAndDebuffs = function(
        allstates,
        context,
        ...)
        local hasUpdates = false

        local targetUnit = select(1, ...)
        local normalizedUnit = BuffWatcher_Shared_Singleton.NormalizeUnit(targetUnit)
        local auraData = select(2, ...)

        if (targetUnit == 'target' or targetUnit == 'softenemy') then
            return false 
        end

        if (normalizedUnit == nil) then
            DevTool:AddData("ignoring unit " .. normalizedUnit)
            return false
        end

        if (not filterByInstanceType(normalizedUnit, context.getFrameType())) then
            return false
        end

        if (not filterByUnit(targetUnit, context.getFrameType())) then
            return false
        end

        if (filterByHostility(targetUnit, context.getFrameType(), context.getIsHostile())) then
            return false
        end

        local targetGuid = UnitGUID(targetUnit)
        local weakAuraBundle = context.GetWeakAuraBundle()

        if (auraData.addedAuras ~= nil) then
            for i,addedAura in ipairs(auraData.addedAuras) do 
                if (handleBuffOrDebuffAddOrUpdate(allstates, context, addedAura, targetUnit, targetGuid)) then
                    hasUpdates = true
                end
            end
        end

        if (auraData.updatedAuraInstanceIDs ~= nil) then
            for i,updatedAuraId in ipairs(auraData.updatedAuraInstanceIDs) do
                local updateInfo = C_UnitAuras.GetAuraDataByAuraInstanceID(targetUnit, updatedAuraId)
                ---@cast updateInfo BuffWatcher_Blizzard_AuraData

                if (updateInfo ~= nil) then
                    if (handleBuffOrDebuffAddOrUpdate(allstates, context, updateInfo, targetUnit, targetGuid)) then
                        hasUpdates = true
                    end
                end
            end
        end

        if (auraData.removedAuraInstanceIDs ~= nil) then
            for i,removedAuraId in ipairs(auraData.removedAuraInstanceIDs) do
                local key = context.getKeyByAuraId(removedAuraId) 

                if (key ~= nil) then
                    if (allstates[key] ~= nil) then
                        allstates[key].show = false
                        allstates[key].changed = true
                        context.removeKeyByGuid(allstates[key].targetGuid, key)
                        hasUpdates = true
                    end

                    context.removeAuraIdToKeyEntry(removedAuraId)
                end
            end
        end

        return hasUpdates
    end

    ---@param context BuffWatcher_AuraContext
    ---@param sourceGuid string
    ---@return string
    local getUnitForGuid = function(context, sourceGuid)
        if (sourceGuid == UnitGUID("player")) then
            return "player"
        end

        if (IsInRaid()) then
            for i=1, GetNumRaidMembers() do
                local unit = BuffWatcher_Shared_Singleton.raidUnits[i]
                local unitGuid = UnitGUID(unit)
                if (unitGuid == sourceGuid) then
                    return unit
                end
            end
        end

        if (IsInGroup()) then
            for i=1, GetNumGroupMembers() do
                local unit = BuffWatcher_Shared_Singleton.partyUnits[i]
                local unitGuid = UnitGUID(unit)
                if (unitGuid == sourceGuid) then
                    return unit
                end
            end
        end

        if (BuffWatcher_Shared.PlayerInArena()) then
            for i=1, 20 do
                local unit = BuffWatcher_Shared_Singleton.arenaUnits[i]
                local unitGuid = UnitGUID(unit)
                if (unitGuid == nil) then
                    return nil
                elseif (unitGuid == sourceGuid) then
                    return unit
                end
            end
        end

        for i=1, 40 do
            local unit = 'nameplate' .. i
            local unitGuid = UnitGUID(unit)
            if (unitGuid == sourceGuid) then
                return unit
            end
        end

        return nil
    end

    ---@param allstates table<string, BuffWatcher_WeakAura_StateEntry>
    ---@param context BuffWatcher_AuraContext
    ---@param ... any
    local handleCasts = function(allstates, context, ...)
        local hasUpdates = false

        local spellId = select(12, ...)
        local sourceName = select(5, ...)
        local sourceGuid = select(4, ...)
        local sourceUnit = getUnitForGuid(context, sourceGuid)

        if (sourceUnit == nil) then
            return false
        end

        if (not filterByInstanceType(sourceUnit, context.getFrameType())) then
            return false
        end

        if (not filterByUnit(sourceUnit, context.getFrameType())) then
            return false
        end

        if (filterByHostility(sourceUnit, context.getFrameType(), context.getIsHostile())) then
            return false
        end

        local weakAuraBundle = context.GetWeakAuraBundle()

        local spellName, _, spellIcon = GetSpellInfo(spellId)

        if (weakAuraBundle.casts[spellId] ~= nil) then
            local watcherInfo = weakAuraBundle.casts[spellId]
            local key = getCastStateKey(watcherInfo.buffType, spellId, sourceGuid, context.getName())

            if (allstates[key] == nil) then
                context.addKeyByGuid(sourceGuid, key)

                ---@type BuffWatcher_WeakAura_StateEntry
                local newState =
                {
                    show = true,
                    changed = true,
                    progressType = "timed",
                    duration = watcherInfo.duration,
                    expirationTime = GetTime() + watcherInfo.duration,
                    name = spellName,
                    icon = spellIcon,
                    caster = sourceName,
                    autoHide = true,
                    showGlow = true,
                    sizeMultiplier = watcherInfo.sizeMultiplier,
                    unit = sourceUnit,
                    size = configuration.GetDefaultSize(),
                    index = BuffWatcher_Shared_Singleton.GetAuraIndexByPriority(watcherInfo.priority),
                    targetGuid = sourceGuid
                }
                allstates[key] = newState
            else
                allstates[key].duration = watcherInfo.duration
                allstates[key].expirationTime = GetTime() + watcherInfo.duration
                allstates[key].changed = true
            end

            hasUpdates = true
        end

        return hasUpdates
    end

    ---@param allstates any
    ---@param context BuffWatcher_AuraContext
    ---@param ... any
    local handleGroupUpdate = function(allstates, context, ...)
        local hasUpdates = false

        DevTool:AddData("fixme handleGroupUpdate")

        if (context.getFrameType() ~= BuffWatcher_FrameTypes.Party 
                and context.getFrameType() ~= BuffWatcher_FrameTypes.Raid) then
            return false
        end

        local groupUnits = BuffWatcher_Shared.GetGroupUnits()

        DevTool:AddData(groupUnits, "fixme finding group members")

        ---@type table<string, boolean>
        local currentGuids = {}

        for unit, unitGuid in pairs(groupUnits) do
            currentGuids[unitGuid]= true

            DevTool:AddData("fixme processing unit " .. unit)
            if (context.seenGuids[unitGuid] == nil) then
                AuraUtil.ForEachAura(unit, "HELPFUL", nil, 
                    function(auraInfo) 
                        ---@cast auraInfo BuffWatcher_Blizzard_AuraData
                        if (handleBuffOrDebuffAddOrUpdate(allstates, context, auraInfo, unit, unitGuid)) then
                            hasUpdates = true
                        end
                    end,
                    true
                )
                AuraUtil.ForEachAura(unit, "HARMFUL", nil, 
                    function(auraInfo) 
                        ---@cast auraInfo BuffWatcher_Blizzard_AuraData
                        if (handleBuffOrDebuffAddOrUpdate(allstates, context, auraInfo, unit, unitGuid)) then
                            hasUpdates = true
                        end
                    end,
                    true
                )

                context.seenGuids[unitGuid] = true
            end
        end
        
        DevTool:AddData(context.seenGuids, "fixme seenGuids")
        DevTool:AddData(currentGuids, "fixme currentGuids")

        for seenGuid, _ in pairs(context.seenGuids) do
            if (currentGuids[seenGuid] == nil) then
                DevTool:AddData(seenGuid, "fixme removing guid")
                removeAurasByGuid(allstates, context, seenGuid)
            end
        end

        DevTool:AddData(hasUpdates, "fixme after auras loop")

        return hasUpdates
    end

    self.IsRegistered = function()
        return storedSpellsRegistry ~= nil
    end

    self.DelegateTsu = function(allstates, event, contextName, ...)
        local context = contextStore.GetContexts()[contextName]

        if (context == nil) then
            return false
        end

        local hasUpdates = false
        local eventSubtype = select(2, ...)

        if (event == "COMBAT_LOG_EVENT_UNFILTERED" and eventSubtype == "SPELL_CAST_SUCCESS") then
            local result = handleCasts(allstates, context, ...) 
            if (result == true) then
                hasUpdates = true
            end
        elseif (event == "UNIT_AURA") then
            return handleBuffsAndDebuffs(allstates, context, ...)
        elseif (event == "NAME_PLATE_UNIT_ADDED") then
            local nameplate = select(1, ...)
            local unitGuid = UnitGUID(nameplate)

            for stateKey,_ in pairs(context.getKeysByGuid(unitGuid)) do
                if (allstates[stateKey] ~= nil) then
                    allstates[stateKey].unit = nameplate
                    allstates[stateKey].show = true
                    allstates[stateKey].changed = true
                    hasUpdates = true
                end
            end

            context.linkNameplateToGuid(nameplate, unitGuid)
        elseif (event == "NAME_PLATE_UNIT_REMOVED") then
            local nameplate = select(1, ...)

            local guid = context.getGuidByNameplate(nameplate)

            if (guid ~= nil) then
                for stateKey, _ in pairs(context.getKeysByGuid(guid)) do
                    if (allstates[stateKey] ~= nil) then
                        allstates[stateKey].unit = nil
                        allstates[stateKey].show = false
                        allstates[stateKey].changed = true
                        hasUpdates = true
                    end
                end
    
                context.unlinkNameplateFromGuid(nameplate, guid)
            end
        elseif (event == "GROUP_ROSTER_UPDATE") then
            if (handleGroupUpdate(allstates, context, ...)) then
                hasUpdates = true
                DevTool:AddData(hasUpdates, "fixme hasUpdates from group")
                DevTool:AddData(CopyTable(allstates), "fixme allstates")
            end
        end
    
        return hasUpdates
    end

    ---@param context BuffWatcher_AuraContext
    ---@param regionData any
    ---@return number
    local getAuraSize = function(context, regionData)
        if (not regionData.data.config.triggerType) then
            return regionData.data.width
        end

        ---@type BuffWatcher_TriggerType
        local type = regionData.data.config.triggerType
        local defaultSize = context.GetIconSize()

        if (type == BuffWatcher_TriggerType.CatchAll) then
            return defaultSize * configuration.GetUnlistedMultiplier()
        else
            return defaultSize
        end
    end

    ---@param framesToRegions table<any, any[]>
    ---@param context BuffWatcher_AuraContext
    ---@param newPositions any
    ---@param isNameplate boolean
    local displayFrames = function(framesToRegions, context, newPositions, isNameplate)
        local growthDirection = context.GetGrowthDirection()

        for frame, frameRegions in pairs(framesToRegions) do
            local x,y = 0, 0
            newPositions[frame] = {}

            for _, regionData in ipairs(frameRegions) do
                ---@type BuffWatcher_TriggerType
                local triggerType = regionData.data.config.triggerType

                if (triggerType ~= BuffWatcher_TriggerType.CatchAll) then
                    local size = getAuraSize(context, regionData)

                    regionData.region:SetRegionWidth(size)
                    regionData.region:SetRegionHeight(size)

                    newPositions[frame][regionData] = { x, 0 }

                    if (growthDirection == BuffWatcher_GrowDirection.Right) then
                        x = x + size
                    else 
                        x = x - size
                    end
                end
            end

            if (not isNameplate) then
                if (growthDirection == BuffWatcher_GrowDirection.Right) then
                    x = x + GroupSpacingWidth
                    if (x < 32) then
                        x = 32
                    end
                else 
                    x = x - GroupSpacingWidth
                    if (x > -32) then
                        x = -32
                    end
                end
            end

            local totalRows = context.GetUnlistedRows()
            local currentRow = 1
            y = 0

            if (growthDirection == BuffWatcher_GrowDirection.Right) then
                if (x < 32) then
                    x = 32
                end
            else 
                if (x > -32) then
                    x = -32
                end
            end

            for _, regionData in ipairs(frameRegions) do
                ---@type BuffWatcher_TriggerType
                local triggerType = regionData.data.config.triggerType

                if (triggerType == BuffWatcher_TriggerType.CatchAll) then
                    local size = getAuraSize(context, regionData)

                    regionData.region:SetRegionWidth(size)
                    regionData.region:SetRegionHeight(size)

                    newPositions[frame][regionData] = { x, y }

                    currentRow = currentRow + 1
                    if (currentRow > totalRows) then
                        currentRow = 1
                        y = 0
                        if (growthDirection == BuffWatcher_GrowDirection.Right) then
                            x = x + size
                        else 
                            x = x - size
                        end
                    else
                        y = y + size
                    end
                end
            end
        end
    end
    
    ---@param context BuffWatcher_AuraContext
    ---@param newPositions any
    ---@param activeRegions any
    local doCustomGrowUnitFrames = function(context, newPositions, activeRegions)
        ---@type table<any, any>
        local framesToRegions = {}
        local bundle = context.GetWeakAuraBundle()

        for i = 1, #activeRegions do
            local activeRegion = activeRegions[i]

            if (activeRegion.region and activeRegion.region.state and activeRegion.region.state.unit) then
                local state = activeRegion.region.state

                local frame = LGF.GetUnitFrame(state.unit)

                if (frame ~= nil) then
                    framesToRegions[frame] = framesToRegions[frame] or {}
                    table.insert(framesToRegions[frame], activeRegion)
                end
            end
        end

        displayFrames(framesToRegions, context, newPositions, false)
    end

    ---@param context BuffWatcher_AuraContext
    ---@param newPositions any
    ---@param activeRegions any
    local doCustomGrowNameplates = function(context, newPositions, activeRegions)
        ---@type table<any, any>
        local framesToRegion = {}

        for i = 1, #activeRegions do
            local activeRegion = activeRegions[i]

            if (activeRegion.region and activeRegion.region.state) then
                local state = activeRegion.region.state

                if (state.unit ~= nil) then
                    local frame = C_NamePlate.GetNamePlateForUnit(state.unit)

                    if (frame == nil) then
                        DevTool:AddData({frame = frame, unit = state.unit}, "fixme nil nameplate")
                    else 
                        framesToRegion[frame] = framesToRegion[frame] or {}
                        table.insert(framesToRegion[frame], activeRegion)
                    end
                end
            end
        end

        displayFrames(framesToRegion, context, newPositions, true)
    end

    ---@param contextName string
    ---@param newPositions any
    ---@param activeRegions any
    self.DelegateCustomGrow = function(contextName, newPositions, activeRegions)
        local context = contextStore.GetContexts()[contextName]

        -- DevTool:AddData(CopyTable(activeRegions, true), "performing custom grow")

        if (context == nil) then
            error("Couldn't find context " .. contextName)
        end

        if (context.isUnitframe()) then
            doCustomGrowUnitFrames(context, newPositions, activeRegions)
        else -- nameplate
            doCustomGrowNameplates(context, newPositions, activeRegions)
        end
    end

    local findPlayerUnitAsGroup = function()
        if (IsInGroup() and GetNumGroupMembers() == 1) then
            return 'party1'
        elseif (IsInRaid() and GetNumGroupMembers() == 1) then
            return 'raid1'
        end

        for i = 1, GetNumGroupMembers() do
            local partyUnit = 'party' .. i
            if UnitIsPlayer(partyUnit) then
                return partyUnit
            end
        end

        return 'player'
    end

    ---@param unitGuid string
    ---@return any ---SUF frame
    local getSufFrame = function(unitGuid)
        for i=1, GetNumGroupMembers() do
            local frameName = partySufFrameMap[i]
            local frame =_G[frameName]

            if (frame ~= nil and frame.unitGUID == unitGuid) then
                return frame
            end
        end

        for i=1, GetNumGroupMembers() do
            local frameName = raidSufFrameMap[i]
            local frame =_G[frameName]

            if (frame ~= nil and frame.unitGUID == unitGuid) then
                return frame
            end
        end

        return nil
    end

    ---@param unitName string
    ---@param unitGuid string
    self.GetUnitFrame = function(unitName, unitGuid)
        local sufFrame = getSufFrame(unitGuid)
        if (sufFrame ~= nil) then
            return sufFrame
        end

        if (unitName == 'player') then
            unitName = findPlayerUnitAsGroup()
        end

        return _G[unitName]
    end

    initialize()

    return self
end