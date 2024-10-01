---@class BuffWatcher_DefaultContextValues
BuffWatcher_DefaultContextValues = {}

function BuffWatcher_DefaultContextValues:new()
    self = {};

    local DefaultIconSize = 32
    local DefaultRaidIconSize = 12
    local DefaultMinorAuraPriorty = 3

    ---@class BuffWatcher_ContextSettingsValues
    ---@field key string
    ---@field friendlyName string
    ---@field frameType FrameTypes
    ---@field isBuffs boolean
    ---@field isHostile boolean
    ---@field showUnlisted BuffWatcher_ShowUnlistedType
    ---@field showDispelType boolean
    ---@field useDefaultIconSize boolean
    ---@field customIconSize integer
    ---@field icon integer
    ---@field xOffset integer
    ---@field yOffset integer
    ---@field selfPoint string
    ---@field anchorPoint string
    ---@field unlistedRowCount integer
    ---@field minorAuraMultiplier number
    ---@field minorAuraPriority integer
    ---@field useDefaultUnlistedMultiplier boolean
    ---@field customUnlistedMultiplier number
    
    -- only used to show the expected structure of the object
    ---@type BuffWatcher_AuraGroupFixedSettings
    local BaseFixedSettings = {
        friendlyName = "friendly name",
        includeBuffsAndCasts = false,
        includeDebuffs = false,
        isHostile = false,
        frameType = BuffWatcher_Shared_Singleton.FrameTypes.Arena,
        icon = 0
    }

    ---@type BuffWatcher_AuraGroupUserSettings
    local BaseUserSettings = {
        showUnlistedAuras = BuffWatcher_ShowUnlistedType.None,
        showDispelType = false,
        useDefaultIconSize = false,
        customIconSize = 1234,
        growDirection = BuffWatcher_GrowDirection.Left,
        unlistedRowCount = 0,
        useDefaultUnlistedMultiplier = true,
        customUnlistedMultiplier = 0.5,
        xOffset = 0,
        yOffset = 0,
        minorAuraMultiplier = 0.8,
        minorAuraPriority = 3,
        selfPoint = BuffWatcher_AnchorPoints.TOPLEFT,
        anchorPoint = BuffWatcher_AnchorPoints.TOPLEFT
    }

    ---@param showUnlistedAuras BuffWatcher_ShowUnlistedType
    ---@param showDispelType boolean
    ---@param useDefaultIconSize boolean
    ---@param customIconSize integer
    ---@param growDirection BuffWatcher_GrowDirection
    ---@param unlistedRowCount integer
    ---@param useDefaultUnlistedMultiplier boolean,
    ---@param customUnlistedMultiplier number,
    ---@param xOffset integer,
    ---@param yOffset integer
    ---@param minorAuraMultiplier number
    ---@param minorAuraPriority integer
    ---@param anchorPoint BuffWatcher_AnchorPoints,
    ---@param selfPoint BuffWatcher_AnchorPoints
    ---@return BuffWatcher_AuraGroupUserSettings
    local buildUserSettingsInstance = function(
        showUnlistedAuras, 
        showDispelType, 
        useDefaultIconSize, 
        customIconSize, 
        growDirection, 
        unlistedRowCount,
        useDefaultUnlistedMultiplier,
        customUnlistedMultiplier,
        xOffset,
        yOffset,
        minorAuraMultiplier,
        minorAuraPriority,
        anchorPoint,
        selfPoint
    )
        ---@type BuffWatcher_AuraGroupUserSettings
        local newUserSettings = {
            showUnlistedAuras = showUnlistedAuras,
            showDispelType = showDispelType,
            useDefaultIconSize = useDefaultIconSize,
            customIconSize = customIconSize,
            growDirection = growDirection,
            unlistedRowCount = unlistedRowCount,
            useDefaultUnlistedMultiplier = useDefaultUnlistedMultiplier,
            customUnlistedMultiplier = customUnlistedMultiplier,
            xOffset = xOffset,
            yOffset = yOffset,
            minorAuraMultiplier = minorAuraMultiplier,
            minorAuraPriority = minorAuraPriority,
            selfPoint = selfPoint,
            anchorPoint = anchorPoint
        }

        BuffWatcher_Shared_Singleton.ValidateObjectCopy(BaseUserSettings, newUserSettings)

        return newUserSettings
    end

    ---@param friendlyName string
    ---@param frameType FrameTypes
    ---@param includeBuffsAndCasts boolean
    ---@param includeDebuffs boolean
    ---@param isHostile boolean
    ---@param icon integer
    local buildFixedSettingsInstance = function(friendlyName, frameType, includeBuffsAndCasts, includeDebuffs, isHostile, icon)
        ---@type BuffWatcher_AuraGroupFixedSettings
        local settingsObject = {
            friendlyName = friendlyName,
            includeBuffsAndCasts = includeBuffsAndCasts,
            includeDebuffs = includeDebuffs,
            isHostile = isHostile,
            frameType = frameType,
            icon = icon
        }

        BuffWatcher_Shared_Singleton.ValidateObjectCopy(BaseFixedSettings, settingsObject)

        return settingsObject
    end

    local keys = BuffWatcher_AuraContextStore.ContextKeys

    ---@type table<string, BuffWatcher_AuraGroupUserSettings>
    local DefaultUserSettings = {}
    ---@type table<string, BuffWatcher_AuraGroupFixedSettings>
    local DefaultFixedContextSettings = {}

    ---@param params BuffWatcher_ContextSettingsValues
    local addDefaultSettingsEntry = function(params)
        local newEntry = buildFixedSettingsInstance(
            params.friendlyName, 
            params.frameType, 
            params.isBuffs, 
            not params.isBuffs, 
            params.isHostile, 
            params.icon
        );
        DefaultFixedContextSettings[params.key] = newEntry

        ---@type BuffWatcher_GrowDirection
        local direction = (params.isBuffs and BuffWatcher_GrowDirection.Left) or BuffWatcher_GrowDirection.Right

        DefaultUserSettings[params.key] = buildUserSettingsInstance(
            params.showUnlisted, 
            params.showDispelType, 
            params.useDefaultIconSize, 
            params.customIconSize, 
            direction, 
            params.unlistedRowCount, 
            params.useDefaultUnlistedMultiplier,
            params.customUnlistedMultiplier,
            params.xOffset,
            params.yOffset,
            params.minorAuraMultiplier,
            params.minorAuraPriority,
            params.anchorPoint,
            params.selfPoint
        )
    end

    local addDefaultSettings = function()
        addDefaultSettingsEntry({
            key = keys.EnemyNameplateBuffs,
            friendlyName = "Enemy Nameplate Buffs",
            frameType = BuffWatcher_Shared_Singleton.FrameTypes.Nameplate,
            isBuffs = true,
            isHostile = true,
            showUnlisted = BuffWatcher_ShowUnlistedType.None, 
            showDispelType = true,
            useDefaultIconSize = true,
            customIconSize = 32,
            icon = 2178499,
            xOffset = 60,
            yOffset = 10,
            minorAuraMultiplier = 0.8,
            minorAuraPriority = DefaultMinorAuraPriorty,
            selfPoint = BuffWatcher_AnchorPoints.BOTTOMRIGHT,
            anchorPoint = BuffWatcher_AnchorPoints.TOPLEFT,
            unlistedRowCount = 2,
            useDefaultUnlistedMultiplier = true,
            customUnlistedMultiplier = 0.5
        })

        addDefaultSettingsEntry({
            key = keys.EnemyNameplateDebuffs,
            friendlyName = "Enemy Nameplate Debuffs",
            frameType = BuffWatcher_Shared_Singleton.FrameTypes.Nameplate,
            isBuffs = false,
            isHostile = true,
            showUnlisted = BuffWatcher_ShowUnlistedType.OwnOnly, 
            showDispelType = false,
            useDefaultIconSize = true,
            customIconSize = 32,
            icon = 2178492,
            xOffset = -80,
            yOffset = 10,
            minorAuraMultiplier = 0.8,
            minorAuraPriority = DefaultMinorAuraPriorty,
            selfPoint = BuffWatcher_AnchorPoints.BOTTOMLEFT,
            anchorPoint = BuffWatcher_AnchorPoints.TOPRIGHT,
            unlistedRowCount = 2,
            useDefaultUnlistedMultiplier = true,
            customUnlistedMultiplier = 0.5
        })

        addDefaultSettingsEntry({
            key = keys.FriendlyNameplateBuffs,
            friendlyName = "Friendly Nameplate Buffs",
            frameType = BuffWatcher_Shared_Singleton.FrameTypes.Nameplate,
            isBuffs = true,
            isHostile = false,
            showUnlisted = BuffWatcher_ShowUnlistedType.OwnOnly, 
            showDispelType = false,
            useDefaultIconSize = true,
            customIconSize = 32,
            icon = 2178493,
            xOffset = 60,
            yOffset = 15,
            minorAuraMultiplier = 0.8,
            minorAuraPriority = DefaultMinorAuraPriorty,
            selfPoint = BuffWatcher_AnchorPoints.BOTTOMRIGHT,
            anchorPoint = BuffWatcher_AnchorPoints.TOPLEFT,
            unlistedRowCount = 2,
            useDefaultUnlistedMultiplier = true,
            customUnlistedMultiplier = 0.5
        })

        addDefaultSettingsEntry({
            key = keys.FriendlyNameplateDebuffs,
            friendlyName = "Friendly Nameplate Debuffs",
            frameType = BuffWatcher_Shared_Singleton.FrameTypes.Nameplate,
            isBuffs = false,
            isHostile = false,
            showUnlisted = BuffWatcher_ShowUnlistedType.None, 
            showDispelType = false,
            useDefaultIconSize = true,
            customIconSize = 32,
            icon = 2178494,
            xOffset = -80,
            yOffset = 15,
            minorAuraMultiplier = 0.8,
            minorAuraPriority = DefaultMinorAuraPriorty,
            selfPoint = BuffWatcher_AnchorPoints.BOTTOMLEFT,
            anchorPoint = BuffWatcher_AnchorPoints.TOPRIGHT,
            unlistedRowCount = 2,
            useDefaultUnlistedMultiplier = true,
            customUnlistedMultiplier = 0.5
        })

        addDefaultSettingsEntry({
            key = keys.PartyBuffs,
            friendlyName = "Party Buffs",
            frameType = BuffWatcher_Shared_Singleton.FrameTypes.Party,
            isBuffs = true,
            isHostile = false,
            showUnlisted = BuffWatcher_ShowUnlistedType.Any, 
            showDispelType = false,
            useDefaultIconSize = true,
            customIconSize = 32,
            icon = 2178495,
            xOffset = -10,
            yOffset = 15,
            minorAuraMultiplier = 0.8,
            minorAuraPriority = DefaultMinorAuraPriorty,
            selfPoint = BuffWatcher_AnchorPoints.BOTTOMRIGHT,
            anchorPoint = BuffWatcher_AnchorPoints.BOTTOMRIGHT,
            unlistedRowCount = 2,
            useDefaultUnlistedMultiplier = true,
            customUnlistedMultiplier = 0.5
        })

        addDefaultSettingsEntry({
            key = keys.PartyDebuffs,
            friendlyName = "Party Debuffs",
            frameType = BuffWatcher_Shared_Singleton.FrameTypes.Party,
            isBuffs = false,
            isHostile = false,
            showUnlisted = BuffWatcher_ShowUnlistedType.Any, 
            showDispelType = true,
            useDefaultIconSize = true,
            customIconSize = 32,
            icon = 2178496,
            xOffset = -10,
            yOffset = -10,
            minorAuraMultiplier = 0.8,
            minorAuraPriority = DefaultMinorAuraPriorty,
            selfPoint = BuffWatcher_AnchorPoints.TOPRIGHT,
            anchorPoint = BuffWatcher_AnchorPoints.TOPRIGHT,
            unlistedRowCount = 1,
            useDefaultUnlistedMultiplier = true,
            customUnlistedMultiplier = 0.5
        })

        addDefaultSettingsEntry({
            key = keys.ArenaEnemyBuffs,
            friendlyName = "Arena Enemy Buffs",
            frameType = BuffWatcher_Shared_Singleton.FrameTypes.Arena,
            isBuffs = true,
            isHostile = true,
            showUnlisted = BuffWatcher_ShowUnlistedType.Any, 
            showDispelType = true,
            useDefaultIconSize = true,
            customIconSize = 32,
            icon = 2178497,
            xOffset = -10,
            yOffset = 15,
            minorAuraMultiplier = 0.8,
            minorAuraPriority = DefaultMinorAuraPriorty,
            selfPoint = BuffWatcher_AnchorPoints.BOTTOMRIGHT,
            anchorPoint = BuffWatcher_AnchorPoints.BOTTOMRIGHT,
            unlistedRowCount = 2,
            useDefaultUnlistedMultiplier = true,
            customUnlistedMultiplier = 0.5
        })

        addDefaultSettingsEntry({
            key = keys.ArenaEnemyDebuffs,
            friendlyName = "Arena Enemy Debuffs",
            frameType = BuffWatcher_Shared_Singleton.FrameTypes.Arena,
            isBuffs = false,
            isHostile = true,
            showUnlisted = BuffWatcher_ShowUnlistedType.Any, 
            showDispelType = false,
            useDefaultIconSize = true,
            customIconSize = 32,
            icon = 2178498,
            xOffset = -10,
            yOffset = -10,
            minorAuraMultiplier = 0.8,
            minorAuraPriority = DefaultMinorAuraPriorty,
            selfPoint = BuffWatcher_AnchorPoints.TOPRIGHT,
            anchorPoint = BuffWatcher_AnchorPoints.TOPRIGHT,
            unlistedRowCount = 2,
            useDefaultUnlistedMultiplier = true,
            customUnlistedMultiplier = 0.5
        })

        addDefaultSettingsEntry({
            key = keys.RaidBuffs,
            friendlyName = "Raid Buffs",
            frameType = BuffWatcher_Shared_Singleton.FrameTypes.Raid,
            isBuffs = true,
            isHostile = false,
            showUnlisted = BuffWatcher_ShowUnlistedType.None, 
            showDispelType = false,
            useDefaultIconSize = false,
            customIconSize = DefaultRaidIconSize,
            icon = 3717310,
            xOffset = -5,
            yOffset = 5,
            minorAuraMultiplier = 0.9,
            minorAuraPriority = DefaultMinorAuraPriorty,
            selfPoint = BuffWatcher_AnchorPoints.BOTTOMRIGHT,
            anchorPoint = BuffWatcher_AnchorPoints.BOTTOMRIGHT,
            unlistedRowCount = 2,
            useDefaultUnlistedMultiplier = true,
            customUnlistedMultiplier = 0.5
        })

        addDefaultSettingsEntry({
            key = keys.RaidDebuffs,
            friendlyName = "Raid Debuffs",
            frameType = BuffWatcher_Shared_Singleton.FrameTypes.Raid,
            isBuffs = false,
            isHostile = false,
            showUnlisted = BuffWatcher_ShowUnlistedType.None, 
            showDispelType = true,
            useDefaultIconSize = false,
            customIconSize = DefaultRaidIconSize,
            icon = 3717303,
            xOffset = -5,
            yOffset = -5,
            minorAuraMultiplier = 0.9,
            minorAuraPriority = DefaultMinorAuraPriorty,
            selfPoint = BuffWatcher_AnchorPoints.TOPRIGHT,
            anchorPoint = BuffWatcher_AnchorPoints.TOPRIGHT,
            unlistedRowCount = 2,
            useDefaultUnlistedMultiplier = true,
            customUnlistedMultiplier = 0.5
        })

        addDefaultSettingsEntry({
            key = keys.BattlegroundBuffs,
            friendlyName = "Battleground Buffs",
            frameType = BuffWatcher_Shared_Singleton.FrameTypes.Battleground,
            isBuffs = true,
            isHostile = false,
            showUnlisted = BuffWatcher_ShowUnlistedType.None, 
            showDispelType = false,
            useDefaultIconSize = false,
            customIconSize = DefaultRaidIconSize,
            icon = 3717310,
            xOffset = -5,
            yOffset = 5,
            minorAuraMultiplier = 0.9,
            minorAuraPriority = DefaultMinorAuraPriorty,
            selfPoint = BuffWatcher_AnchorPoints.BOTTOMRIGHT,
            anchorPoint = BuffWatcher_AnchorPoints.BOTTOMRIGHT,
            unlistedRowCount = 2,
            useDefaultUnlistedMultiplier = true,
            customUnlistedMultiplier = 0.5
        })

        addDefaultSettingsEntry({
            key = keys.BattlegroundDebuffs,
            friendlyName = "Battleground Debuffs",
            frameType = BuffWatcher_Shared_Singleton.FrameTypes.Battleground,
            isBuffs = false,
            isHostile = false,
            showUnlisted = BuffWatcher_ShowUnlistedType.None, 
            showDispelType = true,
            useDefaultIconSize = false,
            customIconSize = DefaultRaidIconSize,
            icon = 3717303,
            xOffset = -5,
            yOffset = -5,
            minorAuraMultiplier = 0.9,
            minorAuraPriority = DefaultMinorAuraPriorty,
            selfPoint = BuffWatcher_AnchorPoints.TOPRIGHT,
            anchorPoint = BuffWatcher_AnchorPoints.TOPRIGHT,
            unlistedRowCount = 2,
            useDefaultUnlistedMultiplier = true,
            customUnlistedMultiplier = 0.5
        })
    end

    -- we want to just initialize immediately
    addDefaultSettings()

    ---@return table<
    self.GetDefaultContextUserSettings = function()
        return CopyTable(DefaultUserSettings)
    end

    self.GetFixedDefaults = function()
        DevTool:AddData(DefaultFixedContextSettings, "inner defaults")
        return CopyTable(DefaultFixedContextSettings)
    end

    ---@param fixedValues BuffWatcher_AuraGroupFixedSettings
    ---@param userValues BuffWatcher_AuraGroupUserSettings
    ---@return BuffWatcher_AuraGroupMergedSettings
    local buildMergedSettingsEntry = function(fixedValues, userValues)
        ---@type BuffWatcher_AuraGroupMergedSettings
        local merged = {
            friendlyName = fixedValues.friendlyName,
            includeBuffsAndCasts = fixedValues.includeBuffsAndCasts,
            includeDebuffs = fixedValues.includeDebuffs,
            isHostile = fixedValues.isHostile,
            frameType = fixedValues.frameType,
            showUnlistedAuras = userValues.showUnlistedAuras,
            showDispelType = userValues.showDispelType,
            useDefaultIconSize = userValues.useDefaultIconSize,
            customIconSize = userValues.customIconSize,
            growDirection = userValues.growDirection,
            icon = fixedValues.icon,
            xOffset = userValues.xOffset,
            yOffset = userValues.yOffset,
            minorAuraMultiplier = userValues.minorAuraMultiplier,
            minorAuraPriority = userValues.minorAuraPriority,
            selfPoint = userValues.selfPoint,
            anchorPoint = userValues.anchorPoint,
            unlistedRowCount = userValues.unlistedRowCount,
            useDefaultUnlistedMultiplier = userValues.useDefaultUnlistedMultiplier,
            customUnlistedMultiplier = userValues.customUnlistedMultiplier
        }

        return merged
    end

    ---@param dbUserSettings table<string, BuffWatcher_AuraGroupUserSettings>
    ---@return table<string, BuffWatcher_AuraGroupMergedSettings>
    self.MergeFixedAndUserSettings = function(dbUserSettings)
        ---@type table<string, BuffWatcher_AuraGroupMergedSettings>
        local merged = {}

        for contextKey,fixedSettings in pairs(DefaultFixedContextSettings) do
            local defaultUserSettings = DefaultUserSettings[contextKey]
            local dbUserValues = dbUserSettings[contextKey]

            ---@type BuffWatcher_AuraGroupUserSettings
            local correctedUserValues = BuffWatcher_Shared.FillMissingValues(dbUserValues, defaultUserSettings)

            ---@type BuffWatcher_AuraGroupMergedSettings
            local mergedEntry = buildMergedSettingsEntry(fixedSettings, correctedUserValues)
            merged[contextKey] = mergedEntry

            DevTool:AddData(
                { dbValues = CopyTable(dbUserValues), finalValues = CopyTable(mergedEntry)}, 
                "fixme final context values after merge")
        end

        return merged
    end

    return self;
end