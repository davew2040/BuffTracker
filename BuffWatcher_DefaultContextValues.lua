---@class BuffWatcher_DefaultContextValues
BuffWatcher_DefaultContextValues = {}

function BuffWatcher_DefaultContextValues:new()
    self = {};

    local DefaultIconSize = 32
    local DefaultRaidIconSize = 12

    -- only used to show the expected structure of the object
    local BaseContextSettings = {
        friendlyName = "friendly name",
        includeBuffsAndCasts = false,
        includeDebuffs = false,
        isHostile = false,
        frameType = BuffWatcher_Shared_Singleton.FrameTypes.Arena
    }

    local BaseUserSettings = {
        showUnlistedAuras = false,
        showDispelType = false,
        useDefaultIconSize = false,
        customIconSize = 1234,
    }

    local buildUserSettingsInstance = function(showUnlistedAuras, showDispelType, useDefaultIconSize, customIconSize)
        local newUserSettings = {
            showUnlistedAuras = showUnlistedAuras,
            showDispelType = showDispelType,
            useDefaultIconSize = useDefaultIconSize,
            customIconSize = customIconSize
        }

        BuffWatcher_Shared_Singleton.ValidateObjectCopy(BaseUserSettings, newUserSettings)

        return newUserSettings
    end

    local buildFixedSettingsInstance = function(friendlyName, frameType, includeBuffsAndCasts, includeDebuffs, isHostile)
        local settingsObject = {
            friendlyName = friendlyName,
            includeBuffsAndCasts = includeBuffsAndCasts,
            includeDebuffs = includeDebuffs,
            isHostile = isHostile,
            frameType = frameType
        }

        BuffWatcher_Shared_Singleton.ValidateObjectCopy(BaseContextSettings, settingsObject)

        return settingsObject
    end

    local keys = BuffWatcher_AuraContextStore.ContextKeys

    local DefaultUserSettings = {
        [keys.EnemyNameplateBuffs] = buildUserSettingsInstance(
            true,
            true, 
            true,
            DefaultIconSize
        ),
        [keys.EnemyNameplateDebuffs] = buildUserSettingsInstance(
            false,
            false, 
            true,
            DefaultIconSize
        ),
        [keys.FriendlyNameplateBuffs] = buildUserSettingsInstance(
            false,
            false, 
            true,
            DefaultIconSize
        ),
        [keys.FriendlyNameplateDebuffs] = buildUserSettingsInstance(
            false,
            true, 
            true,
            DefaultIconSize
        ),
        [keys.PartyBuffs] = buildUserSettingsInstance(
            true,
            false, 
            true,
            DefaultIconSize
        ),
        [keys.PartyDebuffs] = buildUserSettingsInstance(
            true,
            true, 
            true,
            DefaultIconSize
        ),
        [keys.ArenaEnemyBuffs] = buildUserSettingsInstance(
            true,
            true, 
            true,
            DefaultIconSize
        ),
        [keys.ArenaEnemyDebuffs] = buildUserSettingsInstance(
            true,
            false, 
            true,
            DefaultIconSize
        ),
        [keys.RaidBuffs] = buildUserSettingsInstance(
            false,
            true, 
            true,
            DefaultIconSize
        ),
        [keys.RaidDebuffs] = buildUserSettingsInstance(
            false,
            false, 
            true,
            DefaultRaidIconSize
        )
    }

    local DefaultFixedContextSettings = {
        [keys.EnemyNameplateBuffs] = buildFixedSettingsInstance(
            "Enemy Nameplate Buffs",
            BuffWatcher_Shared_Singleton.FrameTypes.Nameplate,
            false,
            false,
            true
        ),
        [keys.EnemyNameplateDebuffs] = buildFixedSettingsInstance(
            "Enemy Nameplate Debuffs",
            BuffWatcher_Shared_Singleton.FrameTypes.Nameplate,
            false,
            true,
            true
        ),
        [keys.FriendlyNameplateBuffs] = buildFixedSettingsInstance(
            "Friendly Nameplate Buffs",
            BuffWatcher_Shared_Singleton.FrameTypes.Nameplate,
            false,
            false,
            false
        ),
        [keys.FriendlyNameplateDebuffs] = buildFixedSettingsInstance(
            "Friendly Nameplate Debuffs",
            BuffWatcher_Shared_Singleton.FrameTypes.Nameplate,
            false,
            true,
            false
        ),
        [keys.FriendlyNameplateBuffs] = buildFixedSettingsInstance(
            "Friendly Nameplate Buffs",
            BuffWatcher_Shared_Singleton.FrameTypes.Nameplate,
            true,
            false,
            false
        ),
        [keys.FriendlyNameplateDebuffs] = buildFixedSettingsInstance(
            "Friendly Nameplate Debuffs",
            BuffWatcher_Shared_Singleton.FrameTypes.Nameplate,
            false,
            true,
            false
        ),
        [keys.PartyBuffs] = buildFixedSettingsInstance(
            "Party Buffs",
            BuffWatcher_Shared_Singleton.FrameTypes.Party,
            true,
            false,
            false
        ),
        [keys.PartyDebuffs] = buildFixedSettingsInstance(
            "Party Debuffs",
            BuffWatcher_Shared_Singleton.FrameTypes.Party,
            false,
            true,
            false
        ),
        [keys.ArenaEnemyBuffs] = buildFixedSettingsInstance(
            "Arena Buffs",
            BuffWatcher_Shared_Singleton.FrameTypes.Arena,
            true,
            false,
            false
        ),
        [keys.ArenaEnemyDebuffs] = buildFixedSettingsInstance(
            "Arena Debuffs",
            BuffWatcher_Shared_Singleton.FrameTypes.Arena,
            false,
            true,
            false
        ),
        [keys.RaidBuffs] = buildFixedSettingsInstance(
            "Raid Buffs",
            BuffWatcher_Shared_Singleton.FrameTypes.Raid,
            true,
            false,
            false
        ),
        [keys.RaidDebuffs] = buildFixedSettingsInstance(
            "Raid Debuffs",
            BuffWatcher_Shared_Singleton.FrameTypes.Raid,
            false,
            true,
            false
        )
    }

    self.GetDefaultUserSettings = function()
        return CopyTable(DefaultUserSettings)
    end

    self.GetFixedDefaults = function()
        DevTool:AddData(DefaultFixedContextSettings, "inner defaults")
        return CopyTable(DefaultFixedContextSettings)
    end

    self.MergeFixedAndUserSettings = function(userSettings)
        local merged = {}

        for k,v in pairs(DefaultFixedContextSettings) do
            local fixedValues = CopyTable(v)
            local userValues = CopyTable(userSettings[k])
            merged[k] = BuffWatcher_Shared_Singleton.SimpleTableMerge(fixedValues, userValues)
        end

        return merged
    end

    return self;
end