---@class BuffWatcher_AuraFramePool
BuffWatcher_AuraFramePool = {}

---@param framePool any
---@param cooldownFramePool any
---@return BuffWatcher_AuraFramePool
function BuffWatcher_AuraFramePool:new(framePool, cooldownFramePool)
    self = {}

    local pool = CreateObjectPool(
        function(pool)
            return BuffWatcher_AuraFrame:new(framePool, cooldownFramePool)
        end
        -- ---@param pool any
        -- ---@param widget BuffWatcher_AuraFrame
        -- function(pool, widget)
        --     DevTool:AddData({ pool = pool, widget = widget  }, "fixme object pool resetter")
        --     widget.SetInactive()
        -- end
    )

    ---@return BuffWatcher_AuraFrame
    self.GetAuraFrame = function()
        return pool:Acquire()
    end
    
    ---@param auraFrame BuffWatcher_AuraFrame
    self.ReleaseAuraFrame = function(auraFrame)
        auraFrame.SetInactive()
        pool:Release(auraFrame)
    end

    return self
end
