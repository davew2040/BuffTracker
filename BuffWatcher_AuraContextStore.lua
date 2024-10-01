---@class BuffWatcher_AuraContextStore
BuffWatcher_AuraContextStore = {}

BuffWatcher_AuraContextStore.ContextKeys = {
    EnemyNameplateBuffs = "EnemyNameplateBuffs",
    EnemyNameplateDebuffs = "EnemyNameplateDebuffs",
    FriendlyNameplateBuffs = "FriendlyNameplateBuffs",
    FriendlyNameplateDebuffs = "FriendlyNameplateDebuffs",
    PartyBuffs = "PartyBuffs",
    PartyDebuffs = "PartyDebuffs",
    ArenaEnemyBuffs = "ArenaEnemyBuffs",
    ArenaEnemyDebuffs = "ArenaEnemyDebuffs",
    RaidBuffs = "RaidBuffs",
    RaidDebuffs = "RaidDebuffs",
    BattlegroundBuffs = "BattlegroundBuffs",
    BattlegroundDebuffs = "BattlegroundDebuffs"
}

---@param dbAccessor BuffWatcher_DbAccessor
---@param configuration BuffWatcher_Configuration
---@param spellRegistry BuffWatcher_StoredSpellsRegistry
---@param defaultContextValues BuffWatcher_DefaultContextValues
---@param objectPool BuffWatcher_MiscellaneousObjectPool
function BuffWatcher_AuraContextStore:new(
    dbAccessor, 
    configuration,
    spellRegistry, 
    defaultContextValues, 
    objectPool
)
    self = {};

    ---@type number
    local DefaultIconSize = 32
    local shared = BuffWatcher_Shared_Singleton

    ---@type table<string, BuffWatcher_AuraContext>
    local contexts = {}
    
    ---@param source BuffWatcher_StoredSpell[]
    ---@param settings BuffWatcher_AuraGroupMergedSettings
    local filterByFrameType = function(source, settings)
        local filtered = source

        if (settings.frameType == shared.FrameTypes.Nameplate) then
            filtered = shared.TableValueFilter(filtered, function(spell) 
                return spell.showOnNameplates 
            end)
        elseif (settings.frameType == shared.FrameTypes.Party) then
            filtered = shared.TableValueFilter(filtered, 
                ---@param spell BuffWatcher_StoredSpell
                function(spell) return spell.showInParty end)
        elseif (settings.frameType == shared.FrameTypes.Arena) then
            filtered = shared.TableValueFilter(filtered, 
                ---@param spell BuffWatcher_StoredSpell
                function(spell) return spell.showInArena end
            )
        elseif (settings.frameType == shared.FrameTypes.Raid) then
            filtered = shared.TableValueFilter(filtered, 
            ---@param spell BuffWatcher_StoredSpell 
            function(spell) return spell.showInRaid end)
        elseif (settings.frameType == shared.FrameTypes.Battleground) then
            filtered = shared.TableValueFilter(filtered, 
            ---@param spell BuffWatcher_StoredSpell
            function(spell) return spell.showInBattlegrounds end)
        end

        return filtered
    end

    ---@param settings BuffWatcher_AuraGroupMergedSettings
    ---@param spellsById table<integer, BuffWatcher_StoredSpell>
    ---@return table<integer, BuffWatcher_StoredSpell>
    local buildSpellBundleBuffs = function(settings, spellsById)
        if (not settings.includeBuffsAndCasts) then
            return {}
        end

        local filteredSpells = CopyTable(spellsById)

        filteredSpells = filterByFrameType(filteredSpells, settings)

        filteredSpells = shared.TableValueFilter(filteredSpells, function(spell) return spell.buffType == shared.SpellTypes.Buff end)

        return filteredSpells
    end
    
    ---@param settings BuffWatcher_AuraGroupMergedSettings
    ---@param spellsById table<integer, BuffWatcher_StoredSpell>
    ---@return table<integer, BuffWatcher_StoredSpell>
    local buildSpellBundleDebuffs = function(settings, spellsById)
        if (not settings.includeDebuffs) then
            return {}
        end
        local filteredSpells = CopyTable(spellsById)

        filteredSpells = filterByFrameType(filteredSpells, settings)

        filteredSpells = shared.TableValueFilter(filteredSpells, function(spell) return spell.buffType == shared.SpellTypes.Debuff end)

        return filteredSpells
    end

    ---@param settings BuffWatcher_AuraGroupMergedSettings
    ---@param spellsById table<integer, BuffWatcher_StoredSpell>
    ---@return table<integer, BuffWatcher_StoredSpell>
    local buildSpellBundleCasts = function(settings, spellsById)
        if (not settings.includeBuffsAndCasts) then
            return {}
        end

        local filteredSpells = CopyTable(spellsById)

        filteredSpells = filterByFrameType(filteredSpells, settings)

        filteredSpells = shared.TableValueFilter(filteredSpells, function(spell) return spell.buffType == shared.SpellTypes.Cast end)

        return filteredSpells
    end

    ---@param spells table<string, BuffWatcher_StoredSpell>
    ---@return table<integer, BuffWatcher_StoredSpell>
    local getSpellsBySpellIdKey = function(spells)
        ---@type  table<integer, BuffWatcher_StoredSpell>
        local result = {}

        for k,v in pairs(spells) do
            result[v.spellId] = v
        end

        return result
    end

    ---@param settings BuffWatcher_AuraGroupMergedSettings
    ---@param spells table<string, BuffWatcher_StoredSpell>
    ---@return BuffWatcher_SpellBundle
    local buildSpellBundle = function(settings, spells)

        local spellsById = getSpellsBySpellIdKey(spells)

        ---@type BuffWatcher_SpellBundle
        local result = {
            buffs = buildSpellBundleBuffs(settings, spellsById),
            debuffs = buildSpellBundleDebuffs(settings, spellsById),
            casts = buildSpellBundleCasts(settings, spellsById),
        }

        return result
    end

    ---@param key string
    ---@param settings BuffWatcher_AuraGroupMergedSettings
    ---@param spells table<string, BuffWatcher_StoredSpell>
    ---@return BuffWatcher_AuraContext
    local buildSingleContextFromSettings = function(key, settings, spells)
        local spellBundle = buildSpellBundle(settings, spells)

        ---@type BuffWatcher_AuraContext_Params
        local params = {
            spellBundle = spellBundle, 
            isNameplate = settings.frameType == shared.FrameTypes.Nameplate,
            name = settings.friendlyName, 
            key = key,
            frameType = settings.frameType,
            includeBuffsAndCasts = settings.includeBuffsAndCasts, 
            includeDebuffs = settings.includeDebuffs, 
            showUnlistedAuras = settings.showUnlistedAuras,
            showDispelType = settings.showDispelType,
            isHostile = settings.isHostile,
            growDirection = settings.growDirection,
            customIconSize = settings.customIconSize,
            useDefaultIconSize = settings.useDefaultIconSize,
            icon = settings.icon,
            xOffset = settings.xOffset,
            yOffset = settings.yOffset,
            minorAuraMultiplier = settings.minorAuraMultiplier,
            minorAuraPriority = settings.minorAuraPriority,
            selfPoint = settings.selfPoint,
            anchorPoint = settings.anchorPoint,
            unlistedRowCount = settings.unlistedRowCount,
            useDefaultUnlistedMultiplier = settings.useDefaultUnlistedMultiplier,
            customUnlistedMultiplier = settings.customUnlistedMultiplier
        }

        local context = BuffWatcher_AuraContext:new(params, configuration, objectPool)

        return context
    end

    ---@param settings table<string, BuffWatcher_AuraGroupMergedSettings>
    ---@param spells table<string, BuffWatcher_StoredSpell>
    ---@return table<string, BuffWatcher_AuraContext>
    local buildAllContextsFromSettings = function(settings, spells)
        ---@type table<string, BuffWatcher_AuraContext>
        local result = {}

        for key, mergedSettings in pairs(settings) do
            result[key] = buildSingleContextFromSettings(key, mergedSettings, spells)
        end

        return result
    end

    local updateFromSources = function()
        local spells = spellRegistry.GetSpells()
        local userSettings = dbAccessor.GetOptions().groupUserSettings
        local newContextSettings = defaultContextValues.MergeFixedAndUserSettings(userSettings)

        contexts = buildAllContextsFromSettings(newContextSettings, spells)
    end

    local updateContexts = function()
        local spells = spellRegistry.GetSpells()
        local userSettings = dbAccessor.GetOptions().groupUserSettings
        local allContextSettings = defaultContextValues.MergeFixedAndUserSettings(userSettings)

        for key, settings in pairs(allContextSettings) do
            local newSpellBundle = buildSpellBundle(settings, spells) 
            contexts[key].UpdateFromDbSettings(settings, newSpellBundle)
        end
    end

    ---@param newOptions BuffWatcher_SavedDbOptions
    local handleConfigChanged = function(newOptions)
        updateContexts()
    end

    local handleSpellsChanged = function()
        updateContexts()
    end

    local initialize = function()
        updateFromSources()

        dbAccessor.RegisterOptionsChanged(handleConfigChanged)
        spellRegistry.registerSpellsChanged(handleSpellsChanged)
    end

    ---@return table<string, BuffWatcher_AuraContext>
    self.GetContexts = function()
        return contexts
    end
    
    initialize()

    return self;
end