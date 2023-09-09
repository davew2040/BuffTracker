DaveTest_Callbacks = {}

function DaveTest_Callbacks:new()
    local self = {};

    local registrations = {}

    local addCallback = function(eventName, fn) 
        if (registrations[eventName] == nil) then
            registrations[eventName] = {}
        end

        registrations[fn] = fn
    end

    self.fire = function(eventName, ...)
        if (registrations[eventName] ~= nil) then
            for k, v in pairs(registrations) do
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