---@class BuffWatcher_FramesCollection
---@field rootFrame any
---@field allFrames any[]
---@field cooldownFrame any
---@field parentFrame any
BuffWatcher_FramesCollection = {}

---@return BuffWatcher_FramesCollection
function BuffWatcher_FramesCollection:new()
    ---@type BuffWatcher_FramesCollection
    local result = {
        rootFrame = nil,
        allFrames = {},
        cooldownFrame = nil,
        parentFrame = nil
    }

    return result
end