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
    
    ---@type BuffWatcher_SavedDbOptions
    local dbConfig = nil

    local initialize = function()
        dbConfig = dbAccessor.GetOptions()

        dbAccessor.GetEvents().registerCallback(BuffWatcher_DbAccessor.Events.OptionsUpdated, 
            function() 
                dbConfig = dbAccessor.GetOptions()
                DevTool:AddData(CopyTable(dbConfig), "Received updated db options")
            end
        )
    end

    ---@return number
    self.GetUnlistedMultiplier = function()
        return dbConfig.unlistedMultiplier
    end

    ---@return number
    self.GetDefaultSize = function()
        return dbConfig.iconSize
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


    initialize()

    return self;
end