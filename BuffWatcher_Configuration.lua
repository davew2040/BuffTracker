BuffWatcher_Configuration = {}

function BuffWatcher_Configuration:new()
    self = {};

    self.GetUnlistedMultiplier = function()
        return 1
    end

    return self;
end

BuffWatcher_Configuration_Singleton = BuffWatcher_Configuration:new()