---@class BuffWatcher_Configuration
BuffWatcher_Configuration = {}

BuffWatcher_Configuration.Events = {
    ConfigChanged = "ConfigChanged"
}

---@param dbAccessor BuffWatcher_DbAccessor
function BuffWatcher_Configuration:new(dbAccessor)
    self = {};

    local buffColor = BuffWatcher_Color:new(0.0, 0.6, 0.153, 1.0)
    local debuffColor = BuffWatcher_Color:new(0.5, 0.0, 0.0, 1.0)
    local magicColor = BuffWatcher_Color:new(0, 0.77, 1.0, 1.0)
    local curseColor = BuffWatcher_Color:newByHex6('17FF00')
    local diseaseColor = BuffWatcher_Color:newByHex6('926100')
    local poisonColor = BuffWatcher_Color:newByHex6('006017')

    local callbacks = BuffWatcher_Callbacks:new()

    ---@type BuffWatcher_SavedDbOptions
    local dbConfig = nil

    local initialize = function()
        dbConfig = dbAccessor.GetOptions()

        dbAccessor.GetEvents().registerCallback(BuffWatcher_DbAccessor.Events.OptionsUpdated, 
            function() 
                dbConfig = dbAccessor.GetOptions()
                DevTool:AddData(CopyTable(dbConfig), "Received updated db options")
                callbacks.fire(BuffWatcher_Configuration.Events.ConfigChanged, dbConfig)
            end
        )
    end

    ---@return number
    self.GetUnlistedMultiplier = function()
        return dbConfig.unlistedMultiplier
    end

    ---@return number
    self.GetNpcMultiplier = function()
        return 1
    end

    ---@return number
    self.GetDefaultUnitFrameSize = function()
        return dbConfig.unitFrameIconSize
    end

    ---@return number
    self.GetDefaultNameplateSize = function()
        return dbConfig.nameplateIconSize
    end

    ---@return boolean
    self.GetShowTestAnchors = function()
        return dbConfig.addTestAnchors
    end

    ---@return number
    self.GetBorderSize = function()
        return 3
    end

    ---@return number
    self.GetBorderOffset = function()
        return 2
    end

    ---@return number
    self.GetMaxUntrackedIcons = function()
        return 8
    end

    self.GetBuffDebuffBorderSize = function()
        return 3
    end

    self.GetDispelBorderSize = function()
        return 3
    end

    ---@return BuffWatcher_Color
    self.GetBuffColor = function()
        return buffColor
    end

    ---@return BuffWatcher_Color
    self.GetDebuffColor = function()
        return debuffColor
    end

    ---@return BuffWatcher_Color
    self.GetMagicColor = function()
        return magicColor
    end

    ---@return BuffWatcher_Color
    self.GetCurseColor = function()
        return curseColor
    end

    ---@return BuffWatcher_Color
    self.GetDiseaseColor = function()
        return diseaseColor
    end

    ---@return BuffWatcher_Color
    self.GetPoisonColor = function()
        return poisonColor
    end

    ---@param fn fun(): nil
    self.registerConfigChanged = function(fn)
        callbacks.registerCallback(BuffWatcher_Configuration.Events.ConfigChanged, fn)
    end

    initialize()

    return self;
end