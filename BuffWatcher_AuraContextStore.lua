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
    RaidDebuffs = "RaidDebuffs"
}

---@param dbAccessor BuffWatcher_DbAccessor
---@param spellRegistry BuffWatcher_StoredSpellsRegistry
---@param defaultContextValues BuffWatcher_DefaultContextValues
function BuffWatcher_AuraContextStore:new(
    dbAccessor, 
    spellRegistry, 
    defaultContextValues
)
    self = {};

    ---@type number
    local DefaultIconSize = 32
    local shared = BuffWatcher_Shared_Singleton

    ---@type table<string, BuffWatcher_AuraContext>
    local contexts = {}
    
    ---@param source BuffWatcher_StoredSpell[]
    ---@param settings any
    local filterByFrameType = function(source, settings)
        local filtered = source

        if (settings.frameType == shared.FrameTypes.Nameplate) then
            filtered = shared.TableValueFilter(filtered, function(spell) 
                return spell.showOnNameplates 
            end)
        elseif (settings.frameType == shared.FrameTypes.Party) then
            filtered = shared.TableValueFilter(filtered, function(spell) return spell.showInParty end)
        elseif (settings.frameType == shared.FrameTypes.Arena) then
            filtered = shared.TableValueFilter(filtered, function(spell) return spell.showInArena end)
        elseif (settings.frameType == shared.FrameTypes.Raid) then
            filtered = shared.TableValueFilter(filtered, function(spell) return spell.showInRaid end)
        end

        return filtered
    end

    local buildSpellBundleBuffs = function(settings, spells)
        if (not settings.includeBuffsAndCasts) then
            return {}
        end

        local filteredSpells = CopyTable(spells)

        filteredSpells = filterByFrameType(filteredSpells, settings)

        filteredSpells = shared.TableValueFilter(filteredSpells, function(spell) return spell.buffType == shared.SpellTypes.Buff end)

        return filteredSpells
    end
    
    local buildSpellBundleDebuffs = function(settings, spells)
        if (not settings.includeDebuffs) then
            return {}
        end
        local filteredSpells = CopyTable(spells)

        filteredSpells = filterByFrameType(filteredSpells, settings)

        filteredSpells = shared.TableValueFilter(filteredSpells, function(spell) return spell.buffType == shared.SpellTypes.Debuff end)

        return filteredSpells
    end

        
    local buildSpellBundleCasts = function(settings, spells)
        if (not settings.includeBuffsAndCasts) then
            return {}
        end

        local filteredSpells = CopyTable(spells)

        filteredSpells = filterByFrameType(filteredSpells, settings)

        filteredSpells = shared.TableValueFilter(filteredSpells, function(spell) return spell.buffType == shared.SpellTypes.Cast end)

        return filteredSpells
    end

    local buildSpellBundle = function(settings, spells)
        local result = {
            buffs = buildSpellBundleBuffs(settings, spells),
            debuffs = buildSpellBundleDebuffs(settings, spells),
            casts = buildSpellBundleCasts(settings, spells),
        }

        return result
    end

    local getSpellsBySpellIdKey = function(spells)
        local result = {}
        for k,v in pairs(spells) do
            result[v.spellId] = v
        end
        return result
    end

    local buildSingleContextFromSettings = function(settings, spells)
        local spellsById = getSpellsBySpellIdKey(spells)

        local spellBundle = buildSpellBundle(settings, spellsById)

        local context = BuffWatcher_AuraContext:new(
            {
                spellBundle = spellBundle, 
                isNameplate = settings.frameType == shared.FrameTypes.Nameplate,
                name = settings.friendlyName, 
                frameType = settings.frameType,
                includeBuffsAndCasts = settings.includeBuffsAndCasts, 
                includeDebuffs = settings.includeDebuffs, 
                showUnlistedAuras = settings.showUnlistedAuras,
                showDispelType = settings.showDispelType,
                isHostile = settings.isHostile
            }
        )

        return context
    end

    local buildContextsFromSettings = function(settings, spells)
        local result = {}

        for k,v in pairs(settings) do
            result[k] = buildSingleContextFromSettings(v, spells)
        end

        return result
    end

    local updateFromSources = function()
        local spells = spellRegistry.GetSpells()
        local userSettings = dbAccessor.GetOptions().groupUserSettings
        local newContextSettings = defaultContextValues.MergeFixedAndUserSettings(userSettings)

        contexts = buildContextsFromSettings(newContextSettings, spells)
    end

    local initialize = function()
        updateFromSources()
    end

    ---@return BuffWatcher_AuraContext[]
    self.GetContexts = function()
        return contexts
    end
    
    initialize()

    return self;
end