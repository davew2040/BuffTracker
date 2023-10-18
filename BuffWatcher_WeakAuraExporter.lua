---@class BuffWatcher_WeakAuraExporter
BuffWatcher_WeakAuraExporter = {}

---@param configuration BuffWatcher_Configuration
---@param weakAuraGenerator BuffWatcher_WeakAuraGenerator
---@return table
function BuffWatcher_WeakAuraExporter:new(configuration, weakAuraGenerator)
    self = {};

    local buffWatcherGroupPrefix = "BuffWatcher Group - "
    local BuffWatcherSinglePrefix = "BuffWatcher Spell - "

    local storedSpellsRegistry = nil
    local contexts = {}

    local Icons = {
        Up = 450907,
        Left = 450906,
        Right = 450908
    }

    ---@class WeakAuraExporterContext
    ---@field addedAuras table<integer, ExporterContextEntry>
    local WeakAuraExporterContext = {}

    ---@return WeakAuraExporterContext
    function WeakAuraExporterContext:new()
        ---@type WeakAuraExporterContext
        self = {
            addedAuras = {}
        }

        return self
    end

    ---@class ExporterContextEntry
    ---@field name string
    ---@field priority integer
    ---@field weakAuraContent any
    local ExporterContextEntry = {}

    ---@param name string
    ---@param priority integer
    ---@param auraContent any
    ---@return ExporterContextEntry
    function ExporterContextEntry:new(name, priority, auraContent)
        ---@type ExporterContextEntry
        self = {
            name = name,
            priority = priority,
            weakAuraContent = auraContent
        }

        return self
    end

    ---@param spellDefinition BuffWatcher_StoredSpell
    ---@return number
    local getSize = function(spellDefinition)
        return spellDefinition.sizeMultiplier * configuration.GetDefaultSize()
    end

    ---@param weakAurasRoot any
    ---@param groupName string
    local deleteAurasInGroup = function(weakAurasRoot, groupName)
        if (weakAurasRoot[groupName] ~= nil) then
            local group = weakAurasRoot[groupName]
            local toDelete = {}

            for k,v in pairs(weakAurasRoot) do
                if (1 == string.find(k, BuffWatcherSinglePrefix) and v.parent == groupName) then
                    toDelete[k] = v
                end
            end

            for k, _ in pairs(toDelete) do
                weakAurasRoot[k] = nil

                for i,v in ipairs(group["controlledChildren"]) do
                    if (v == k) then
                        table.remove(group["controlledChildren"], i)
                        break
                    end
                end
            end
        end
    end

    ---@param newAura any
    ---@param auraName string
    ---@param groupName string
    ---@param weakAurasRoot any
    local addWeakAura = function(newAura, auraName, groupName, weakAurasRoot)
        weakAurasRoot[auraName] = newAura
    end

    ---@param context BuffWatcher_AuraContext
    ---@param type string
    ---@param identifier string
    ---@return string
    local function getAuraName(context, type, identifier)
        local result = BuffWatcherSinglePrefix .. context.getName() .. ' - ' .. type .. ' - ' .. identifier
        return result
    end

    ---@param context BuffWatcher_AuraContext
    ---@param buffId integer
    ---@return string
    local function getBuffName(context, buffId)
        ---@type string
        local spellName = GetSpellInfo(buffId)

        local idText = spellName .. " - " .. tostring(buffId)
        local result = getAuraName(context, 'Buff', idText)

        return result
    end

    ---@param context BuffWatcher_AuraContext
    ---@param castId integer
    ---@return string
    local function getCastName(context, castId)
        ---@type string
        local spellName = GetSpellInfo(castId)

        local idText = spellName .. " - " .. tostring(castId)
        local result = getAuraName(context, 'Cast', idText)

        return result
    end

    ---@param context BuffWatcher_AuraContext
    ---@param debuffId integer
    ---@return string
    local function getDebuffName(context, debuffId)
        ---@type string
        local spellName = GetSpellInfo(debuffId)

        local idText = spellName .. " - " .. tostring(debuffId)
        local result = getAuraName(context, 'Debuff', idText)

        return result
    end

    ---@param context BuffWatcher_AuraContext
    ---@param number number
    ---@return string
    local function getTestAnchorName(context, number)
        return getAuraName(context, 'Test Anchor', tostring(number))
    end

    ---@param anchorName string
    ---@param icon number
    ---@param context BuffWatcher_AuraContext
    ---@param size number
    ---@param exporterContext WeakAuraExporterContext
    ---@return nil
    local addSingleTestAnchor = function(anchorName, icon, context, size, parentGroup, exporterContext)
        local anchor = weakAuraGenerator.GenerateAnchor(anchorName, icon, context.getIsHostile(), parentGroup, size, context.getFrameType())

        table.insert(exporterContext.addedAuras, ExporterContextEntry:new(anchorName, 12, anchor))
    end

    ---@param context BuffWatcher_AuraContext
    ---@param groupName string
    ---@param exporterContext WeakAuraExporterContext
    local addAllTestAnchors = function(context, groupName, exporterContext)
        addSingleTestAnchor(getTestAnchorName(context, 1), Icons.Up, context, configuration.GetDefaultSize(), groupName, exporterContext)
        addSingleTestAnchor(getTestAnchorName(context, 2), Icons.Left, context, configuration.GetDefaultSize(), groupName, exporterContext)
        addSingleTestAnchor(getTestAnchorName(context, 3), Icons.Right, context, configuration.GetDefaultSize(), groupName, exporterContext)
    end

    ---@param context BuffWatcher_AuraContext
    ---@param bundle BuffWatcher_SpellBundle
    ---@param groupName string
    ---@param exporterContext WeakAuraExporterContext
    local addBuffsAndCasts = function(context, bundle, groupName, exporterContext)
        for key, buff in pairs(bundle.buffs) do
            if (not buff.hide) then
                local size = getSize(buff)
                local buffName = getBuffName(context, buff.spellId)

                local newBuff = weakAuraGenerator.GenerateBuffDebuff(buff.spellId, true, buffName, context.getIsHostile(), groupName, 
                    size, context.getFrameType(), context.getShowDispelType(), buff.sizeMultiplier, buff.ownOnly)

                table.insert(exporterContext.addedAuras, ExporterContextEntry:new(buffName, buff.priority, newBuff))
            end
        end

        for key, cast in pairs(bundle.casts) do
            if (not cast.hide) then
                local size = getSize(cast)
                local castName = getCastName(context, cast.spellId)

                local _, _, icon = GetSpellInfo(cast.spellId)

                local newCast = weakAuraGenerator.GenerateCast(castName, cast.spellId, groupName, size, icon, context.getName(), cast.ownOnly)

                table.insert(exporterContext.addedAuras, ExporterContextEntry:new(castName, cast.priority, newCast))
            end
        end
    end

    ---@param context BuffWatcher_AuraContext
    ---@param bundle BuffWatcher_SpellBundle
    ---@param groupName string
    ---@param exporterContext WeakAuraExporterContext
    local addDebuffs = function(context, bundle, groupName, exporterContext)
        for key, debuff in pairs(bundle.debuffs) do
            if (not debuff.hide) then
                local size = getSize(debuff)
                local debuffName = getDebuffName(context, debuff.spellId)

                local newDebuff = weakAuraGenerator.GenerateBuffDebuff(debuff.spellId, false, debuffName, context.getIsHostile(), groupName, 
                    size, context.getFrameType(), context.getShowDispelType(), debuff.sizeMultiplier, debuff.ownOnly)
                    
                table.insert(exporterContext.addedAuras, ExporterContextEntry:new(debuffName, debuff.priority, newDebuff))
            end
        end
    end

    ---@param context BuffWatcher_AuraContext
    ---@param bundle BuffWatcher_SpellBundle
    ---@param groupName string
    ---@param exporterContext WeakAuraExporterContext
    local addCatchAlls = function(context, bundle, groupName, exporterContext)
        if (context.showUnlistedAuras()) then
            local size = configuration.GetDefaultSize() * configuration.GetUnlistedMultiplier()

            if (context.includeBuffsAndCasts()) then
                local auraName = getAuraName(context, 'CATCH ALL', 'BUFFS') 
    
                local buffIds = BuffWatcher_Shared_Singleton.CopyKeys(bundle.buffs)
                local castIds = BuffWatcher_Shared_Singleton.CopyKeys(bundle.casts)
                local merged = BuffWatcher_Shared_Singleton.SimpleTableMerge(buffIds, castIds)

                local catchAllBuffs = weakAuraGenerator.GenerateCatchAllBuffDebuff(merged, true, auraName, context.getIsHostile(), groupName, 
                    size, context.getFrameType(), context.getShowDispelType(), configuration.GetUnlistedMultiplier())
    
                table.insert(exporterContext.addedAuras, ExporterContextEntry:new(auraName, 1, catchAllBuffs))
            elseif (context.includeDebuffs()) then
                local auraName = getAuraName(context, 'CATCH ALL', 'DEBUFFS') 
    
                local debuffIds = BuffWatcher_Shared_Singleton.CopyKeys(bundle.debuffs)

                local catchAllDebuffs = weakAuraGenerator.GenerateCatchAllBuffDebuff(debuffIds, false, auraName, context.getIsHostile(), groupName, 
                    size, context.getFrameType(), context.getShowDispelType(), configuration.GetUnlistedMultiplier())
    
                table.insert(exporterContext.addedAuras, ExporterContextEntry:new(auraName, 1, catchAllDebuffs))
            end
        end
    end

    ---@param exporterContext WeakAuraExporterContext
    ---@param groupName string
    ---@param weakAurasRoot any
    local exportAllAuras = function(exporterContext, groupName, weakAurasRoot)
        local sorted = exporterContext.addedAuras

        table.sort(sorted, 
            ---@param a ExporterContextEntry
            ---@param b ExporterContextEntry
            ---@return boolean
            function (a, b)
                return a.priority > b.priority
            end)

        ---@type table<integer, any>
        local newChildren = {}

        for k,v in pairs(weakAurasRoot[groupName]["controlledChildren"]) do
            table.insert(newChildren, v)
        end

        for i,v in ipairs(exporterContext.addedAuras) do
            addWeakAura(v.weakAuraContent, v.name, groupName, weakAurasRoot)
            table.insert(newChildren, v.name)
        end

        weakAurasRoot[groupName]["controlledChildren"] = newChildren
    end

    ---@param context BuffWatcher_AuraContext
    ---@param spellRegistry BuffWatcher_StoredSpellsRegistry
    ---@param weakAurasRoot any
    local exportContext = function(context, spellRegistry, weakAurasRoot)
        local groupName = buffWatcherGroupPrefix .. context.getName()

        -- if (WeakAurasSaved.displays[tempGroupName] ~= nil) then
        --     WeakAuras.Delete(WeakAurasSaved.displays[tempGroupName])
        -- end

        deleteAurasInGroup(weakAurasRoot, groupName)

        if (weakAurasRoot[groupName] == nil) then
            local dynamicGroup = weakAuraGenerator.GenerateDynamicGroup(groupName, context.getFrameType())
            weakAurasRoot[groupName] = dynamicGroup
        end

        local bundle = context.GetWeakAuraBundle()
        local exporterContext = WeakAuraExporterContext:new()

        if (configuration.GetShowTestAnchors()) then
            addAllTestAnchors(context, groupName, exporterContext)
        end

        addBuffsAndCasts(context, bundle, groupName, exporterContext)
        addDebuffs(context, bundle, groupName, exporterContext)
        addCatchAlls(context, bundle, groupName, exporterContext)

        exportAllAuras(exporterContext, groupName, weakAurasRoot)
    end

    ---@param spellRegistry BuffWatcher_StoredSpellsRegistry
    ---@param contextMap table<string, BuffWatcher_AuraContext>
    self.Export = function(spellRegistry, contextMap)
        local weakAuraRoot = WeakAurasSaved.displays

        DevTool:AddData(CopyTable(contextMap), "fixme exporting contexts")

        for k,context in pairs(contextMap) do 
            exportContext(context, spellRegistry, weakAuraRoot)
        end
    end

    return self
end