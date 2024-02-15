---@class BuffWatcher_BlizzardFrameWrapper
BuffWatcher_BlizzardFrameWrapper = {}

---@param frame any
function BuffWatcher_BlizzardFrameWrapper:new(frame)
    self = {};

    self.GetFrame = function()
        return frame
    end

    return self;
end