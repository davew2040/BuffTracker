---@class BuffWatcher_FramesCollection
---@field rootFrame any
---@field dispelFrame any
---@field hostilityFrame any
---@field innerBorder any
---@field auraFrame any
---@field cooldownFrame any
---@field parentFrame any
BuffWatcher_FramesCollection = {}

---@return BuffWatcher_FramesCollection
function BuffWatcher_FramesCollection:new()
    DevTool:AddData("fixme BuffWatcher_FramesCollection:new()")

    ---@type BuffWatcher_FramesCollection
    local result = {
        rootFrame = nil,
        cooldownFrame = nil,
        parentFrame = nil
    }

    return result
end