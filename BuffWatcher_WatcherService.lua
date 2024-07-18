local LGF = LibStub("LibGetFrame-1.0")

---@class BuffWatcher_WatcherService
BuffWatcher_WatcherService = {}

---@param configuration BuffWatcher_Configuration
---@param contextStore BuffWatcher_AuraContextStore
---@param pool BuffWatcher_MiscellaneousObjectPool
function BuffWatcher_WatcherService:new(configuration, contextStore, pool)
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

    local handleConfigChanged = function()
        for key, context in pairs(contextStore.GetContexts()) do
            context.DoFullReset()
        end
    end

    local initialize = function()
        configuration.registerConfigChanged(handleConfigChanged)
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

            local baseSize = configuration.GetDefaultUnitFrameSize()
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
                size = configuration.GetDefaultUnitFrameSize(),
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
                size = configuration.GetDefaultUnitFrameSize(),
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

    self.IsRegistered = function()
        return storedSpellsRegistry ~= nil
    end

    ---comment
    ---@param targetUnit string
    self.HandleEvent_NameplateAdded = function(targetUnit)
        for key, context in pairs(contextStore.GetContexts()) do
            if (context.IsLoaded() and context.isNameplate()) then
                context.DoUnitAdd(targetUnit, true)
            end
        end
    end

    ---comment
    ---@param targetUnit string
    self.HandleEvent_NameplateRemoved = function(targetUnit)
        for key, context in pairs(contextStore.GetContexts()) do
            if (context.isNameplate() and context.IsLoaded()) then
                context.NameplateRemoved(targetUnit)
            end
        end
    end

    ---@type table<integer, any>
    local tempAuraIds = {}

    ---comment
    ---@param targetUnit string
    ---@param updateInfo BuffWatcher_Blizzard_UnitAuraUpdateInfo
    self.HandleEvent_UnitAura = function(targetUnit, updateInfo)
        for _, context in pairs(contextStore.GetContexts()) do
            if (context.IsLoaded()) then
                context.UnitAura(targetUnit, updateInfo)
            end
        end
    end

    ---@param eventData BuffWatcher_Blizzard_CombatLogEntry
    self.HandleEvent_Cast = function(eventData)
        ---@type BuffWatcher_Blizzard_CastInfo
        local castInfo = pool.GetObject()
        
        castInfo.spellId = eventData.spellID
        castInfo.sourceGuid = eventData.sourceGUID
        castInfo.sourceName = eventData.sourceName

        for _, context in pairs(contextStore.GetContexts()) do
            if (context.IsLoaded()) then
                context.HandleCast(castInfo)
            end
        end

        pool.ReleaseObject(castInfo)
    end

    ---@param eventData BuffWatcher_Blizzard_CombatLogEntry
    self.HandleEvent_UnitDied = function(eventData)
        local deadGuid = eventData[8]

        for _, context in pairs(contextStore.GetContexts()) do
            if (context.IsLoaded()) then
                context.HandleUnitDied(deadGuid)
            end
        end
    end

    self.RefreshLoaded = function()
        for key, context in pairs(contextStore.GetContexts()) do
            local loadedChanged = context.UpdateLoadedState()

            if (loadedChanged) then
                DevTool:AddData({key = key}, "fixme loadedChanged")

                context.DoFullReset()

                if (context.IsLoaded()) then
                    DevTool:AddData("loading context " .. context.getName())
                else
                    DevTool:AddData("unloading context " .. context.getName())
                end
            -- else -- remove if we determine this isn't needed
            --     if (context.IsLoaded()) then
            --         context.DoFullReset()
            --     end
            end
        end
    end

    self.ArenaOpponentUpdate = function()
        DevTool:AddData("fixme ArenaOpponentUpdate")
        for key, context in pairs(contextStore.GetContexts()) do
            if (context.IsLoaded() and (context.getFrameType() == BuffWatcher_Shared_Singleton.FrameTypes.Arena or context.getFrameType() == BuffWatcher_Shared_Singleton.FrameTypes.Party)) then
                context.DoFullReset()
            end
        end
    end

    self.PlayerEnteringWorld = function()
        DevTool:AddData('fixme PlayerEnteringWorld')
        self.RefreshLoaded()

        for key, context in pairs(contextStore.GetContexts()) do
            if (context.IsLoaded()) then
                context.DoFullReset()
            end
        end
    end

    self.FramesChanged = function()
        for key, context in pairs(contextStore.GetContexts()) do
            if (context.IsLoaded()) then
                context.FramesChanged()
            end
        end
    end

    initialize()

    return self
end