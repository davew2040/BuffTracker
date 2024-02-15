---@class BuffWatcher_BlizzardFrameWrapper
BuffWatcher_BlizzardFrameWrapper = {}

---@param frame any
function BuffWatcher_BlizzardFrameWrapper:new(frame)
    self = {};

    self.GetFrame = function()
        return frame
    end

    if frame == nil then
        error("Attempted to supply nil frame to wrapper.")
    end

    return self;
end