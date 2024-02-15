---@class BuffWatcher_TimerWrapper
BuffWatcher_TimerWrapper = {}

---@param timer any
function BuffWatcher_TimerWrapper:new(timer)
    self = {};

    self.GetTimer = function()
        return timer
    end

    if timer == nil then
        error("Attempted to supply nil frame to wrapper.")
    end

    return self;
end