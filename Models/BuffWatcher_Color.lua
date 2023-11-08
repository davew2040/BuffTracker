---@class BuffWatcher_Color
---@field red number
---@field green number
---@field blue number
---@field alpha number
BuffWatcher_Color = {}

---@param red number
---@param green number
---@param blue number
---@param alpha number
---@return BuffWatcher_Color
function BuffWatcher_Color:new(red, green, blue, alpha)
    ---@type BuffWatcher_Color
    self = {
        red = red,
        green = green,
        blue = blue,
        alpha = alpha
    }

    return self
end