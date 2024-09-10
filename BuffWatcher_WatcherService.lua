local LGF = LibStub("LibGetFrame-1.0")

---@class BuffWatcher_WatcherService
BuffWatcher_WatcherService = {}

---@param configuration BuffWatcher_Configuration
---@param contextStore BuffWatcher_AuraContextStore
---@param pool BuffWatcher_MiscellaneousObjectPool
function BuffWatcher_WatcherService:new(configuration, contextStore, pool)
    self = {};

    DevTool:AddData("added new BuffWatcher_WatcherService")

    local refreshTime = 0.1

    local storedSpellsRegistry = nil

    local refreshTimer = C_Timer.NewTicker(refreshTime, function()
        self.RefreshTimerTick()
    end) -- This ticker will run 10 times (10 seconds in total).
    

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

    ---@param auraInfo BuffWatcher_Blizzard_AuraData
    ---@return boolean -- true if passes filter, false if fails
    local catchAllFilter = function(auraInfo)
        if (auraInfo.duration == 0) then 
            return false
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
        --DevTool:AddData("fixme HandleEvent_NameplateAdded " .. targetUnit .. " " .. UnitName(targetUnit))

        for key, context in pairs(contextStore.GetContexts()) do
            if (context.IsLoaded() and context.isNameplate()) then
                context.DoUnitAdd(targetUnit, true)
            end
        end
    end

    ---comment
    ---@param targetUnit string
    self.HandleEvent_NameplateRemoved = function(targetUnit)
        --DevTool:AddData("fixme HandleEvent_NameplateRemoved " .. targetUnit)

        for key, context in pairs(contextStore.GetContexts()) do
            if (context.isNameplate() and context.IsLoaded()) then
                context.NameplateRemoved(targetUnit)
            end
        end
    end

    ---comment
    self.HandleEvent_GroupRosterUpdate = function()
        for _, context in pairs(contextStore.GetContexts()) do
            if (context.IsLoaded()) then
                context.GroupRosterUpdate()
            end
        end
    end

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

    self.RefreshTimerTick = function()
        for key, context in pairs(contextStore.GetContexts()) do
            if (context.IsLoaded()) then
                context.HandleTimerTick()
            end
        end
    end

    self.ArenaOpponentUpdate = function()
        DevTool:AddData("fixme ArenaOpponentUpdate")
        for key, context in pairs(contextStore.GetContexts()) do
            if (context.IsLoaded() and (context.getFrameType() == BuffWatcher_Shared_Singleton.FrameTypes.Arena or context.getFrameType() == BuffWatcher_Shared_Singleton.FrameTypes.Party)) then
                context.GroupRosterUpdate()
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