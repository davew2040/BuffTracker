BuffWatcher_WeakAuraExporter = {}

function BuffWatcher_WeakAuraExporter:new()
    self = {};

    local buffWatcherGroupPrefix = "BuffWatcher Group - "
    local buffWatcherSinglePrefix = "BuffWatcher Spell - "

    local storedSpellsRegistry = nil
    local contexts = {}

    local getSize = function(spellDefinition)
        DevTool:AddData(spellDefinition, "fixme spellDefinition")
        return spellDefinition.sizeMultiplier * BuffWatcher_Configuration_Singleton.GetDefaultSize()
    end

    local deleteAurasInGroupGroup = function(groupName)
        if (WeakAurasSaved.displays[groupName] ~= nil) then
            local toDelete = {}

            for k,v in pairs(WeakAurasSaved.displays) do
                if (1 == string.find(k, buffWatcherSinglePrefix) and v.parent == groupName) then
                    toDelete[k] = true
                end
            end

            for k, _ in pairs(toDelete) do
                WeakAuras.Delete(WeakAurasSaved.displays[k])
            end
        end
    end

    local deleteExistingGroup = function(existingGroupName)
        DevTool:AddData(existingGroupName, "deleting existing group " .. existingGroupName)

        if (WeakAurasSaved.displays[existingGroupName] ~= nil) then
            deleteAurasInGroupGroup(existingGroupName)

            WeakAuras.Delete(WeakAurasSaved.displays[existingGroupName])
        end
    end

    local addWeakAura = function(aura, groupName)
        WeakAuras.Add(aura)
        table.insert(WeakAurasSaved.displays[groupName].controlledChildren, aura.id)
    end

    local addBuffsAndCasts = function(context, bundle, groupName)
        for key, buff in pairs(bundle.buffs) do
            local size = getSize(buff)
            local buffName = buffWatcherSinglePrefix .. context.getName() .. ' - Buff - ' .. buff.spellId

            local newBuff = BuffWatcher_WeakAuraGenerator_Singleton.GenerateBuffDebuff(buff.spellId, true, buffName, groupName, 
                size, context.getFrameType(), context.getShowDispelType(), buff.sizeMultiplier)

            addWeakAura(newBuff, groupName)

            DevTool:AddData(newBuff, "fixme new buff")
        end

        for key, cast in pairs(bundle.casts) do
            local size = getSize(cast)
            local castName = buffWatcherSinglePrefix .. context.getName() .. ' - Cast - ' .. cast.spellId

            local _, _, icon = GetSpellInfo(cast.spellId)

            local newBuff = BuffWatcher_WeakAuraGenerator_Singleton.GenerateCast(castName, cast.spellId, groupName, size, icon, context.getName())

            addWeakAura(newBuff, groupName)

            DevTool:AddData(newBuff, "fixme new cast")
        end
    end

    local addDebuffs = function(context, bundle, groupName)
        for key, debuff in pairs(bundle.debuffs) do
            local size = getSize(debuff)
            local debuffName = buffWatcherSinglePrefix .. context.getName() .. ' - Debuff - ' .. debuff.spellId

            local newDebuff = BuffWatcher_WeakAuraGenerator_Singleton.GenerateBuffDebuff(debuff.spellId, false, debuffName, groupName, 
                size, context.getFrameType(), context.getShowDispelType(), debuff.sizeMultiplier)

            addWeakAura(newDebuff, groupName)

            DevTool:AddData(newDebuff, "fixme new debuff")
        end
    end

    local addCatchAlls = function(context, bundle, groupName)
        if (context.showUnlistedAuras()) then
            local size = BuffWatcher_Configuration_Singleton.GetDefaultSize() * BuffWatcher_Configuration_Singleton.GetUnlistedMultiplier()

            if (context.includeBuffsAndCasts()) then
                local auraName = buffWatcherSinglePrefix .. context.getName() .. ' - CATCH ALL BUFFS'
    
                local buffIds = BuffWatcher_Shared_Singleton.CopyKeys(bundle.buffs)
                local castIds = BuffWatcher_Shared_Singleton.CopyKeys(bundle.casts)
                local merged = BuffWatcher_Shared_Singleton.SimpleTableMerge(buffIds, castIds)

                DevTool:AddData(merged, "merged catch-all buff id's")
                local catchAllBuffs = BuffWatcher_WeakAuraGenerator_Singleton.GenerateCatchAllBuffDebuff(merged, true, auraName, groupName, 
                    size, context.getFrameType(), context.getShowDispelType(), BuffWatcher_Configuration_Singleton.GetUnlistedMultiplier())
    
                addWeakAura(catchAllBuffs, groupName)
    
                DevTool:AddData(catchAllBuffs, "fixme new catch all")
            elseif (context.includeDebuffs()) then
                local auraName = buffWatcherSinglePrefix .. context.getName() .. ' - CATCH ALL DEBUFFS'
    
                local debuffIds = BuffWatcher_Shared_Singleton.CopyKeys(bundle.debuffs)

                DevTool:AddData(debuffIds, "merged catch-all debuff id's")

                local catchAllDebuffs = BuffWatcher_WeakAuraGenerator_Singleton.GenerateCatchAllBuffDebuff(debuffIds, false, auraName, groupName, 
                    size, context.getFrameType(), context.getShowDispelType(), BuffWatcher_Configuration_Singleton.GetUnlistedMultiplier())
    
                addWeakAura(catchAllDebuffs, groupName)

                DevTool:AddData(catchAllDebuffs, "fixme new catch all debuffs")
            end
        end
    end

    local exportContext = function(context, spellRegistry)
        local groupName = buffWatcherGroupPrefix .. context.getName()
        local tempGroupName =  groupName .. ' - old'

        DevTool:AddData(groupName, "fixme groupName")

        -- if (WeakAurasSaved.displays[tempGroupName] ~= nil) then
        --     WeakAuras.Delete(WeakAurasSaved.displays[tempGroupName])
        -- end

        deleteAurasInGroupGroup(groupName)

        if (WeakAurasSaved.displays[groupName] == nil) then
            WeakAuras.Add(BuffWatcher_WeakAuraGenerator_Singleton.GenerateDynamicGroup(groupName, context.getFrameType()))
        end

        local bundle = context.GetWeakAuraBundle()

        DevTool:AddData(bundle, "fixme bundle")

        addBuffsAndCasts(context, bundle, groupName)
        addDebuffs(context, bundle, groupName)
        addCatchAlls(context, bundle, groupName)
    end

    self.Export = function(spellRegistry, contextMap)
        DevTool:AddData(contextMap, "exporting all contexts")

        for k,context in pairs(contextMap) do 
            DevTool:AddData(context, "fixme exporting context")
            exportContext(context)
        end
    end

    return self
end

BuffWatcher_WeakAuraExporter_Singleton = BuffWatcher_WeakAuraExporter:new()