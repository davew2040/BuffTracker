BuffWatcher_Callbacks = {}

function BuffWatcher_Callbacks:new()
    self = {};

    local registrations = {}

    local addCallback = function(eventName, fn) 
        if (registrations[eventName] == nil) then
            registrations[eventName] = {}
        end

        registrations[eventName][fn] = fn
    end

    self.fire = function(eventName, ...)
        print("firing event name" .. eventName)
        if (registrations[eventName] ~= nil) then
            for k, v in pairs(registrations[eventName]) do
                print("firing event name" .. eventName)
                v(...)
            end
        end
    end

    self.registerCallback = function(eventName, fn) 
        addCallback(eventName, fn)
    end

    self.unregisterCallback = function(eventName, fn) 
        if (registrations[eventName] ~= nil) then
            registrations[eventName][fn] = nil;
        end
    end

    return self;
end