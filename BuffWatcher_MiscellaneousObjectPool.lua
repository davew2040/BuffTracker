---@class BuffWatcher_MiscellaneousObjectPool
BuffWatcher_MiscellaneousObjectPool = {}

---@return BuffWatcher_MiscellaneousObjectPool
function BuffWatcher_MiscellaneousObjectPool:new()
    self = {}

    local pool = CreateObjectPool(
        function(pool)
            return {}
        end,
        function(pool, widget)
            BuffWatcher_Shared.ResetTable(widget)
        end
    )

    ---@return table
    self.GetObject = function()
        return pool:Acquire()
    end
    
    ---@param t table
    self.ReleaseObject = function(t)
        pool:Release(t)
    end

    return self
end
