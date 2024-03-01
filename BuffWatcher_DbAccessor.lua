---@class BuffWatcher_DbAccessor
BuffWatcher_DbAccessor = {}

BuffWatcher_DbAccessor.Events = {
    OptionsUpdated = "OptionsUpdated"
}

function BuffWatcher_DbAccessor:new()
    self = {};

    local callbacks = BuffWatcher_Callbacks:new()

    ---@type BuffWatcher_SavedDbRootSettings
    local db = nil

    ---@param contextStore BuffWatcher_DefaultContextValues
    ---@return BuffWatcher_SavedDbRootSettings
    local GetDefaultDb = function(contextStore)
        local groupUserSettings = contextStore.GetDefaultContextUserSettings()

        ---@type BuffWatcher_SavedDbRootSettings
        local defaults = {
            global = {
                options = {
                    addTestAnchors = false,
                    unitFrameIconSize = 64,
                    nameplateIconSize = 58,
                    unlistedMultiplier = 0.5,
                    groupUserSettings = groupUserSettings
                },
                savedSpells = {}
            }
        }

        return defaults
    end

    ---@param newStoredSpells table<string, BuffWatcher_StoredSpell>
    self.SaveStoredSpells = function(newStoredSpells)
        DevTool:AddData(CopyTable(newStoredSpells), "fixme newStoredSpells SaveStoredSpells")
        db.global.savedSpells = newStoredSpells
    end

    ---@param newGroupSettings table<string, BuffWatcher_AuraGroupUserSettings>
    self.SaveGroupSettings = function(newGroupSettings)
        db.global.options.groupUserSettings = newGroupSettings
    end

    ---@return table<string, BuffWatcher_StoredSpell>
    self.GetSpells = function()
        local result = {}
        ---@type table<string, BuffWatcher_StoredSpell>
        local copy = BuffWatcher_Shared:CopyTable(db.global.savedSpells)

        return copy
    end

    ---@return BuffWatcher_SavedDbOptions
    self.GetOptions = function()
        local copy = CopyTable(db.global.options)
        DevTool:AddData(copy, "fixme get db options")
        return copy
    end

    ---@param newOptions BuffWatcher_SavedDbOptions
    self.SetOptions = function(newOptions)
        local copied = CopyTable(newOptions)
        ---@cast copied BuffWatcher_SavedDbOptions

        db.global.options = copied
        callbacks.fire(BuffWatcher_DbAccessor.Events.OptionsUpdated, db.global.options)
    end

    ---@return BuffWatcher_Callbacks
    self.GetEvents = function()
        return callbacks
    end

    self.OnInitialize = function(contextDefaults)
        local defaults = GetDefaultDb(contextDefaults)
        db = LibStub("AceDB-3.0"):New("BuffWatcherDB", defaults)
    end

    ---@param fn fun(options: BuffWatcher_SavedDbOptions): nil
    self.RegisterOptionsChanged = function(fn)
        callbacks.registerCallback(BuffWatcher_DbAccessor.Events.OptionsUpdated, fn)
    end

    return self;
end

BuffWatcher_DbAccessor_Singleton = BuffWatcher_DbAccessor:new()