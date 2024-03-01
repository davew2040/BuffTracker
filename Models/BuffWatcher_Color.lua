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

---@param hex string
---@return BuffWatcher_Color
function BuffWatcher_Color:newByHex6(hex)
    local redHex = string.sub(hex, 1, 2)
    local greenHex = string.sub(hex, 3, 4)
    local blueHex = string.sub(hex, 5, 6)

    local redInt = tonumber(redHex, 16)
    local greenInt = tonumber(greenHex, 16)
    local blueInt = tonumber(blueHex, 16)

    ---@type BuffWatcher_Color
    self = {
        red = redInt / 255.0,
        green = greenInt / 255.0,
        blue = blueInt / 255.0,
        alpha = 1.0
    }

    return self
end