local LGF = LibStub("LibGetFrame-1.0")

---@class BuffWatcher_WatcherService
BuffWatcher_WatcherService = {}

---@param configuration BuffWatcher_Configuration
---@param contextStore BuffWatcher_AuraContextStore
function BuffWatcher_WatcherService:new(configuration, contextStore)
    self = {};

    DevTool:AddData("added new BuffWatcher_WatcherService")

    local GroupSpacingWidth = 10

    local storedSpellsRegistry = nil

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

    ---@param auraInfo BuffWatcher_Blizzard_AuraData
    ---@return string
    local getOutlineType = function(auraInfo)
        if (auraInfo.isHelpful) then
            return BuffWatcher_OutlineType.Buff
        else
            return BuffWatcher_OutlineType.Debuff
        end 
    end

    ---@param borders BuffWatcher_BorderDefinition[]
    ---@param baseSize integer
    local getSizeWithBorders = function(borders, baseSize)
        for _, border in ipairs(borders) do
            baseSize = baseSize + border.width*2
        end

        return baseSize
    end

    ---@param context BuffWatcher_AuraContext
    ---@param auraInfo BuffWatcher_Blizzard_AuraData
    ---@param watcherInfo BuffWatcher_StoredSpell
    ---@param targetUnit string
    ---@param targetGuid string
    ---@param sourceGuid string
    ---@return boolean
    local function handleBuffOrDebuffAddOrUpdateStoredSpell(context, auraInfo, watcherInfo, targetUnit, targetGuid, sourceGuid)
        local auraId = auraInfo.auraInstanceID
        local spellInfo = {GetSpellInfo(auraInfo.spellId)}
        local auraInstances = context.auraInstancesMap;

        if (watcherInfo.hide) then
            return false
        end

        if (watcherInfo.ownOnly and sourceGuid ~= UnitGUID('player')) then
            return false
        end

        local key = getBuffDebuffStateKey(watcherInfo.buffType, watcherInfo.spellId, targetGuid, sourceGuid, auraId, context.getName())

        if (auraInstances[key] == nil) then
            context.linkAuraIdToStateKey(auraId, key)
            context.addKeyByGuid(targetGuid, key)

            local baseSize = configuration.GetDefaultSize()
            local borders = context.GetAuraBorders(auraInfo)
            local sizeWithBorders = getSizeWithBorders(borders, baseSize)

            local triggerType = BuffWatcher_TriggerType.Buff
            if (auraInfo.isHarmful) then
                triggerType = BuffWatcher_TriggerType.Debuff
            end

            ---@type BuffWatcher_AuraInstance
            local newInstance = {
                spellId = watcherInfo.spellId,
                showCooldown = auraInfo.duration ~= 0,
                borders = borders,
                frames = BuffWatcher_FramesCollection:new(),
                baseSize = baseSize,
                actualSize = sizeWithBorders,
                priority = watcherInfo.priority,
                sourceGuid = sourceGuid, 
                targetGuid = targetGuid,
                auraInstanceId = auraInfo.auraInstanceID,
                triggerType = triggerType,
                icon = spellInfo[3],
                name = spellInfo[1],
                caster = targetUnit,
                isHarmful = auraInfo.isHarmful
            }

            local frames = context.GetAuraFrames(auraInfo, newInstance, borders)
            newInstance.frames = frames

            DevTool:AddData(borders, "fixme borders")
            DevTool:AddData(newInstance, "fixme newInstance")

            auraInstances[key] = newInstance
        else
            --fixme - update
            -- auraInstances[key].duration = auraInfo.duration
            -- auraInstances[key].expirationTime = auraInfo.expirationTime
            -- auraInstances[key].changed = true
        end

        return true
    end

    ---@param auraInfo BuffWatcher_Blizzard_AuraData
    ---@return boolean -- true if passes filter, false if fails
    local catchAllFilter = function(auraInfo)
        if (auraInfo.duration == 0) then 
            return false
        end

        return true
    end

    ---@param context BuffWatcher_AuraContext
    ---@param auraInfo BuffWatcher_Blizzard_AuraData
    ---@param targetUnit string
    ---@param normalizedUnit string
    ---@param targetGuid string
    ---@param sourceGuid string
    ---@return boolean
    local function handleBuffOrDebuffNpc(context, auraInfo, targetUnit, normalizedUnit, targetGuid, sourceGuid)
        local auraId = auraInfo.auraInstanceID
        local spellInfo = {GetSpellInfo(auraInfo.spellId)}
            
        local key = getBuffDebuffStateKey(BuffWatcher_Shared_Singleton.SpellTypes.Buff, auraInfo.spellId, targetGuid, sourceGuid, auraId, context.getName())
            
        local autoHide = true
        if (auraInfo.duration == 0) then
            autoHide = false
        end

        local triggerType = BuffWatcher_TriggerType.Buff
        if (auraInfo.isHarmful) then
            triggerType = BuffWatcher_TriggerType.Debuff
        end

        if (allstates[key] == nil) then
            ---@type BuffWatcher_WeakAura_StateEntry
            local newState = {
                show = true,
                changed = true,
                progressType = auraInfo.duration == 0 and "static" or "timed",
                duration = auraInfo.duration,
                expirationTime = auraInfo.duration + GetTime(),
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
                targetGuid = targetGuid,
                triggerType = triggerType,
                outlineType = getOutlineType(auraInfo)
            }
            allstates[key] = newState
            context.linkAuraIdToStateKey(auraId, key)
            context.addKeyByGuid(targetGuid, key)
    
        else
            allstates[key].duration = auraInfo.duration
            allstates[key].expirationTime = auraInfo.expirationTime
            allstates[key].changed = true
        end

        return true
    end

    ---@param context BuffWatcher_AuraContext
    ---@param auraInfo BuffWatcher_Blizzard_AuraData
    ---@param targetUnit string
    ---@param targetGuid string
    ---@param sourceGuid string
    ---@return boolean
    local function handleBuffOrDebuffCatchAll(allstates, context, auraInfo, targetUnit, targetGuid, sourceGuid)
        local auraId = auraInfo.auraInstanceID
        local spellInfo = {GetSpellInfo(auraInfo.spellId)}

        if (context.showUnlistedAuras() == BuffWatcher_ShowUnlistedType.OwnOnly and sourceGuid ~= UnitGUID("player")) then
            return false
        end
            
        if (not catchAllFilter(auraInfo)) then
            return false
        end

        local key = getBuffDebuffStateKey(BuffWatcher_Shared_Singleton.SpellTypes.Buff, auraInfo.spellId, targetGuid, sourceGuid, auraId, context.getName())

        local autoHide = true
        if (auraInfo.duration == 0) then
            autoHide = false
        end

        if (allstates[key] == nil) then
            ---@type BuffWatcher_WeakAura_StateEntry
            local newState = {
                show = true,
                changed = true,
                progressType = auraInfo.duration == 0 and "static" or "timed",
                duration = auraInfo.duration,
                expirationTime = auraInfo.duration + GetTime(),
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
                targetGuid = targetGuid,
                triggerType = BuffWatcher_TriggerType.CatchAll,
                outlineType = getOutlineType(auraInfo)
            }
            allstates[key] = newState
            context.linkAuraIdToStateKey(auraId, key)
            context.addKeyByGuid(targetGuid, key)
        else
            allstates[key].duration = auraInfo.duration
            allstates[key].expirationTime = auraInfo.expirationTime
            allstates[key].changed = true
        end

        return true
    end

    ---@param context BuffWatcher_AuraContext
    ---@param sourceGuid string
    ---@return boolean
    local useNpcAura = function(context, sourceGuid)
        return context.IncludeNpcs() and context.getFrameType() == BuffWatcher_FrameTypes.Nameplate 
            and sourceGuid ~= nil and BuffWatcher_Shared.GuidIsNpc(sourceGuid)
    end

    ---@param context BuffWatcher_AuraContext
    ---@param addedAura BuffWatcher_Blizzard_AuraData
    ---@param targetUnit string
    ---@param targetGuid string
    ---@param sourceGuid string
    ---@return boolean
    local handleBuffAddOrUpdate = function(context, addedAura, targetUnit, targetGuid, sourceGuid)
        local weakAuraBundle = context.GetWeakAuraBundle()

        if (weakAuraBundle.buffs[addedAura.spellId] ~= nil) then
            local watcherInfo = weakAuraBundle.buffs[addedAura.spellId]
            return handleBuffOrDebuffAddOrUpdateStoredSpell(context, addedAura, watcherInfo, targetUnit, targetGuid, sourceGuid)
        --FIXME re-enable
        -- elseif (useNpcAura(context, sourceGuid)) then
        --     return handleBuffOrDebuffNpc(context, addedAura, targetUnit, targetGuid, sourceGuid)
        -- elseif (context.showUnlistedAuras() ~= BuffWatcher_ShowUnlistedType.None) then
        --     return handleBuffOrDebuffCatchAll(context, addedAura, targetUnit, targetGuid, sourceGuid)
        end

        return false
    end

    ---@param context BuffWatcher_AuraContext
    ---@param addedAura BuffWatcher_Blizzard_AuraData
    ---@param targetUnit string
    ---@param targetGuid string
    ---@param sourceGuid string
    ---@return boolean
    local handleDebuffAddOrUpdate = function(context, addedAura, targetUnit, targetGuid, sourceGuid)
        local weakAuraBundle = context.GetWeakAuraBundle()

        if (weakAuraBundle.debuffs[addedAura.spellId] ~= nil) then
            local watcherInfo = weakAuraBundle.debuffs[addedAura.spellId]

            return handleBuffOrDebuffAddOrUpdateStoredSpell(context, addedAura, watcherInfo, targetUnit, targetGuid, sourceGuid)
        --FIXME - re-enable
        -- elseif (useNpcAura(context, sourceGuid)) then
        --     return handleBuffOrDebuffNpc(context, addedAura, targetUnit, targetGuid, sourceGuid)
        -- elseif (context.showUnlistedAuras() ~= BuffWatcher_ShowUnlistedType.None) then
        --     return handleBuffOrDebuffCatchAll(context, addedAura, targetUnit, targetGuid, sourceGuid)
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

    ---@param allstates table<string, BuffWatcher_WeakAura_StateEntry>
    ---@param context BuffWatcher_AuraContext
    ---@param guid string
    ---@return boolean
    local removeAurasByGuid = function(allstates, context, guid)
        ---@type table<string, boolean>
        local stateKeysByGuid = CopyTable(context.getKeysByGuid(guid))

        for key,_ in pairs(stateKeysByGuid) do
            if (allstates[key] ~= nil) then
                allstates[key].changed = true
                allstates[key].show = false
            end

            context.removeKeyFromGuid(guid, key)

            local auraIds = context.getAurasIdsByStateKey(key)
            for _, auraId in ipairs(auraIds) do
                context.unlinkAuraIdToStateKey(auraId, key)
            end
        end

        return true
    end

    ---@param context BuffWatcher_AuraContext
    ---@param auraData BuffWatcher_Blizzard_AuraData
    ---@param targetUnit string
    ---@param targetGuid string
    local handleBuffOrDebuffAddOrUpdate = function(context, auraData, targetUnit, targetGuid)
        local hasUpdates = false

        ---@type string
        local sourceGuid = nil

        if (auraData.sourceUnit ~= nil) then
            sourceGuid = UnitGUID(auraData.sourceUnit)
        end

        --fixme - filter npc minor units

        DevTool:AddData("handleBuffOrDebuffAddOrUpdate")

        if (auraData.isHelpful and context.includeBuffsAndCasts()) then
            local result = handleBuffAddOrUpdate(context, auraData, targetUnit, targetGuid, sourceGuid)
            if (result) then
                hasUpdates = true
            end
        elseif (auraData.isHarmful and context.includeDebuffs()) then
            local result = handleDebuffAddOrUpdate(context, auraData, targetUnit, targetGuid, sourceGuid)
            if (result) then
                hasUpdates = true
            end
        end

        return hasUpdates
    end

    ---@param context BuffWatcher_AuraContext
    ---@param targetUnit string
    ---@param eventData BuffWatcher_Blizzard_UnitAuraUpdateInfo
    ---@return boolean
    local handleBuffsAndDebuffsChanged = function(context, targetUnit, eventData)
        if (not context.FilterEvent(targetUnit)) then
            DevTool:AddData("fixme filtered handleBuffsAndDebuffsChanged")
            return false
        end

        local hasUpdates = false
        local targetGuid = UnitGUID(targetUnit)

        DevTool:AddData("fixme handleBuffsAndDebuffsChangeds")

        if (eventData.addedAuras ~= nil) then
            for i,addedAura in ipairs(eventData.addedAuras) do 
                if (handleBuffOrDebuffAddOrUpdate(context, addedAura, targetUnit, targetGuid)) then
                    hasUpdates = true
                end
            end
        end

        -- if (eventData.updatedAuraInstanceIDs ~= nil) then
        --     for i,updatedAuraId in ipairs(eventData.updatedAuraInstanceIDs) do
        --         local updateInfo = C_UnitAuras.GetAuraDataByAuraInstanceID(targetUnit, updatedAuraId)
        --         ---@cast updateInfo BuffWatcher_Blizzard_AuraData

        --         if (updateInfo ~= nil) then
        --             if (handleBuffOrDebuffAddOrUpdate(allstates, context, updateInfo, targetUnit, targetGuid)) then
        --                 hasUpdates = true
        --             end
        --         end
        --     end
        -- end

        -- if (eventData.removedAuraInstanceIDs ~= nil) then
        --     for i,removedAuraId in ipairs(eventData.removedAuraInstanceIDs) do
        --         local key = context.getKeyByAuraId(removedAuraId) 

        --         if (key ~= nil) then
        --             context.unlinkAuraIdToStateKey(removedAuraId, key)

        --             if (allstates[key] ~= nil) then
        --                 allstates[key].show = false
        --                 allstates[key].changed = true
        --                 context.removeKeyFromGuid(allstates[key].targetGuid, key)
        --                 hasUpdates = true
        --             end
        --         end
        --     end
        -- end

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
            for i=1, GetNumGroupMembers() do
                local unit = BuffWatcher_Shared_Singleton.raidUnitsByIndex[i]
                local unitGuid = UnitGUID(unit)
                if (unitGuid == sourceGuid) then
                    return unit
                end
            end
        elseif (IsInGroup()) then
            for i=1, GetNumGroupMembers() do
                local unit = BuffWatcher_Shared_Singleton.partyUnitsByIndex[i]
                local unitGuid = UnitGUID(unit)
                if (unitGuid == sourceGuid) then
                    return unit
                end
            end
        end

        if (BuffWatcher_Shared.PlayerInArena()) then
            for i=1, 20 do
                local unit = BuffWatcher_Shared_Singleton.arenaUnitsByIndex[i]
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

        if (not context.FilterEvent(sourceUnit)) then
            return false
        end

        local weakAuraBundle = context.GetWeakAuraBundle()

        local spellName, _, spellIcon = GetSpellInfo(spellId)

        if (weakAuraBundle.casts[spellId] ~= nil) then
            local watcherInfo = weakAuraBundle.casts[spellId]
            local key = getCastStateKey(watcherInfo.buffType, spellId, sourceGuid, context.getName())

            if (watcherInfo.hide) then
                return false
            end
    
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
                    targetGuid = sourceGuid,
                    auraInstanceID = 0,
                    triggerType = BuffWatcher_TriggerType.Cast,
                    outlineType = BuffWatcher_OutlineType.Buff
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

        ---@param allstates table<string, BuffWatcher_WeakAura_StateEntry>
    ---@param context BuffWatcher_AuraContext
    ---@param unitGuid string
    ---@param unitLabel string
    ---@return true
    local forceAurasByGuid = function(allstates, context, unitGuid, unitLabel) 
        local activeGuids = context.GetActiveGuidsSet()

        AuraUtil.ForEachAura(unit, "HELPFUL", nil, 
            function(auraInfo) 
                ---@cast auraInfo BuffWatcher_Blizzard_AuraData
                if (handleBuffOrDebuffAddOrUpdate(allstates, context, auraInfo, unitLabel, unitGuid)) then
                    hasUpdates = true
                end
            end,
            true
        )
        AuraUtil.ForEachAura(unit, "HARMFUL", nil, 
            function(auraInfo) 
                ---@cast auraInfo BuffWatcher_Blizzard_AuraData
                if (handleBuffOrDebuffAddOrUpdate(allstates, context, auraInfo, unitLabel, unitGuid)) then
                    hasUpdates = true
                end
            end,
            true
        )
    end


    ---@param context BuffWatcher_AuraContext
    ---@param unitGuid string
    ---@param unitLabel string
    ---@return boolean
    local forceAurasByGuid = function(context, unitGuid, unitLabel) 
        local hasUpdates = false

        DevTool:AddData({
            unitGuid = unitGuid,
            unitLabel = unitLabel
        }, "fixme forceAurasByGuid")

        AuraUtil.ForEachAura(unitLabel, "HELPFUL", nil, 
            function(auraInfo) 
                ---@cast auraInfo BuffWatcher_Blizzard_AuraData
                if (handleBuffOrDebuffAddOrUpdate(context, auraInfo, unitLabel, unitGuid)) then
                    hasUpdates = true
                end
            end,
            true
        )

        --FIXME - re-enable
        -- AuraUtil.ForEachAura(unitLabel, "HARMFUL", nil, 
        --     function(auraInfo) 
        --         ---@cast auraInfo BuffWatcher_Blizzard_AuraData
        --         if (handleBuffOrDebuffAddOrUpdate(context, auraInfo, unitLabel, unitGuid)) then
        --             hasUpdates = true
        --         end
        --     end,
        --     true
        -- )

        return hasUpdates
    end

    ---@param context BuffWatcher_AuraContext
    ---@param guid string
    local redrawUnitAuras = function(context, guid)
        local x = 0
        for key, _ in pairs(context.getKeysByGuid(guid)) do
            DevTool:AddData(key, "fixme redrawUnitAuras")
            local auraInstance = context.auraInstancesMap[key]
            DevTool:AddData(auraInstance, "fixme redrawUnitAuras auraInstance")

            auraInstance.frames.rootFrame:SetPoint("TOPLEFT", auraInstance.frames.parentFrame, "TOPLEFT", x, 0)
            x = x + auraInstance.actualSize + 4
        end
    end

    ---@param context BuffWatcher_AuraContext
    local doAuraPartialUpdate = function(context) 
        local hasUpdates = false

        --BuffWatcher_Tests.GroupCompareTests_RaidSwitch()

        DevTool:AddData(context.unitToGuidLinkage, "fixme old unitToGuidLinkage")
        local newUnits = context.BuildUnitsToGuids()
        DevTool:AddData(newUnits, "fixme new unitToGuidLinkage")

        local comparison = BuffWatcher_Shared.CompareUnitToGuidMaps(context.unitToGuidLinkage, newUnits)
        DevTool:AddData(comparison, "fixme comparison")

        context.unitToGuidLinkage = newUnits

        for i, addedUnit in ipairs(comparison.addedUnits) do
            local guid = context.unitToGuidLinkage.unitToGuid[addedUnit]
            forceAurasByGuid(context, guid, addedUnit)
            redrawUnitAuras(context, guid)
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

        if (doAuraPartialUpdate(allstates, context, ...)) then
            hasUpdates = true
        end

        return hasUpdates
    end

    ---@param context BuffWatcher_AuraContext
    local clearAllAuras = function(context)
        --- 
        local auras = context.auraInstancesMap;

        for key,aura in pairs(auras) do
            for _,frame in ipairs(aura.frames.allFrames) do
                frame:Hide()
                context.framePool:Release(frame)
            end
        end

        context.ResetAuraState()
    end

    ---@param context BuffWatcher_AuraContext
    local doFullUpdate = function(context)
        --clearAllAuras(context)

        --doAuraPartialUpdate(context)

        return true
    end

    ---@param allstates table<string, BuffWatcher_WeakAura_StateEntry>
    ---@param context BuffWatcher_AuraContext
    ---@param guid string 
    local clearGuidAuras = function(allstates, context, guid)
    end

    self.IsRegistered = function()
        return storedSpellsRegistry ~= nil
    end


    ---@param allstates table<string, BuffWatcher_WeakAura_StateEntry>
    ---@param context BuffWatcher_AuraContext
    ---@param unitGuid string
    ---@param unitName string
    local refreshUnitAuras = function(allstates, context, unitGuid, unitName)
        removeAurasByGuid(allstates, context, unitGuid)

        forceAurasByGuid(context, unitGuid, unitName)

        return true
    end

    ---comment
    ---@param targetUnit string
    self.HandleEvent_NameplateAdded = function(targetUnit)
        for key, context in pairs(contextStore.GetContexts()) do
            if (context.GetIsLoaded()) then
                context.DoUnitUpdate(targetUnit)
            end
        end
    end

    ---comment
    ---@param targetUnit string
    self.HandleEvent_NameplateRemoved = function(targetUnit)
        for key, context in pairs(contextStore.GetContexts()) do
            if (context.GetIsLoaded()) then
                context.ClearUnit(targetUnit)
            end
        end
    end

    ---comment
    ---@param targetUnit string
    ---@param updateInfo BuffWatcher_Blizzard_UnitAuraUpdateInfo
    self.HandleEvent_UnitAura = function(targetUnit, updateInfo)
        for _, context in pairs(contextStore.GetContexts()) do
            if (context.GetIsLoaded()) then
                context.UnitAura(targetUnit, updateInfo)
            end
        end

        -- if (event == "STATUS" 
        --         or event == "PLAYER_ENTERING_WORLD"
        --         or event == "GROUP_ROSTER_UPDATE"
        --         or event == "PARTY_CONVERTED_TO_RAID") then
        --     if refreshLoaded(allstates, context) then
        --         return true
        --     end
        -- end

        -- if (not context.GetIsLoaded()) then
        --     return false
        -- end

        -- if (event == "COMBAT_LOG_EVENT_UNFILTERED") then
        --     if (eventSubtype == "SPELL_CAST_SUCCESS") then
        --         local result = handleCasts(allstates, context, ...)
        --         if (result == true) then
        --             hasUpdates = true
        --         end
        --     elseif (eventSubtype == "UNIT_DIED") then
        --         local unitGuid = select(9, ...)
        --         removeAurasByGuid(allstates, context, unitGuid)
        --     end
        -- elseif (event == "UNIT_AURA") then
        --     return handleBuffsAndDebuffs(allstates, context, ...)
        -- elseif (event == "NAME_PLATE_UNIT_ADDED") then
        --     if (context.getFrameType() ~= BuffWatcher_FrameTypes.Nameplate) then 
        --         return false
        --     end

        --     local nameplate = select(1, ...)
        --     local unitGuid = UnitGUID(nameplate)

        --     hasUpdates = refreshUnitAuras(allstates, context, unitGuid, nameplate)

        --     context.linkNameplateToGuid(nameplate, unitGuid)
        -- elseif (event == "NAME_PLATE_UNIT_REMOVED") then
        --     if (context.getFrameType() ~= BuffWatcher_FrameTypes.Nameplate) then 
        --         return false
        --     end

        --     local nameplate = select(1, ...)
        --     local guid = context.getGuidByNameplate(nameplate)

        --     if (guid ~= nil) then
        --         hasUpdates = removeAurasByGuid(allstates, context, guid)
        --         context.unlinkNameplateFromGuid(nameplate, guid)
        --     end
        -- elseif (event == "GROUP_ROSTER_UPDATE") then
        --     if (handleGroupUpdate(allstates, context, ...)) then
        --         hasUpdates = true
        --         DevTool:AddData(hasUpdates, "fixme hasUpdates from group")
        --         DevTool:AddData(CopyTable(allstates), "fixme allstates")
        --     end
        -- end
    
        -- return hasUpdates
    end

    ---@param context BuffWatcher_AuraContext
    ---@param regionData any
    ---@return number
    local getAuraSize = function(context, regionData)
        if (not regionData.region.state.triggerType) then
            return regionData.data.width
        end

        ---@type BuffWatcher_TriggerType
        local type = regionData.region.state.triggerType
        local size = context.GetIconSize()

        if (context.getFrameType() == BuffWatcher_FrameTypes.Nameplate) then
            size = size * 0.5
        end

        if (type == BuffWatcher_TriggerType.CatchAll) then
            local multiplier = configuration.GetUnlistedMultiplier()

            if (not context.useDefaultUnlistedMultiplier) then
                multiplier = context.customUnlistedMultiplier
            end

            return size * multiplier
        else
            return size
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

    self.RefreshLoaded = function()
        for key, context in pairs(contextStore.GetContexts()) do

            local loadedChanged = context.UpdateLoaded()

            if (loadedChanged) then
                if (context.GetIsLoaded()) then
                    DevTool:AddData("loading context " .. context.getName())
                    doFullUpdate(context)
                    context.DoFullUpdate()
                else
                    DevTool:AddData("unloading context " .. context.getName())
                    clearAllAuras(context)
                end
            end
        end
    end

    initialize()

    return self
end