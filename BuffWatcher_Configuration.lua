BuffWatcher_Configuration = {}

function BuffWatcher_Configuration:new()
    self = {};

    self.GetUnlistedMultiplier = function()
        return 0.5
    end

    self.GetDefaultSize = function()
        return 48
    end

    self.GetBorderSize = function()
        return 3
    end

    self.GetBorderOffset = function()
        return 2
    end

    return self;
end

BuffWatcher_Configuration_Singleton = BuffWatcher_Configuration:new()