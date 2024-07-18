---@class BuffWatcher_AuraFrameOld
BuffWatcher_AuraFrameOld = {}

---@param parentFrame any
---@param aura BuffWatcher_AuraInstance
---@param framePool any
---@param cooldownFramePool any
---@param texturePool any
---@param auraInstance BuffWatcher_AuraInstance
---@param context BuffWatcher_AuraContext
---@param alpha number
---@param auraTitle string
---@return BuffWatcher_AuraFrameOld
function BuffWatcher_AuraFrameOld:new(parentFrame, aura, framePool, cooldownFramePool, texturePool, auraInstance, context, alpha, auraTitle)
    self = {}

    ---@type BuffWatcher_FramesCollection
    local frames = BuffWatcher_FramesCollection:new()

    --- gets the default UI level of the frame
    ---@return integer
    local getFrameLevel = function()
        return 300
    end

    -- self.traceScale = function(frame, level)
    --     local scale = frame:GetScale()
    --     DevTool:AddData({scale = frame:GetScale(), frame = frame, level = level}, "fixme tracescale " .. context.getName())

    --     local parent = frame:GetParent()
    --     if (parent ~= nil) then
    --         scale = scale * self.traceScale(parent, level+1)
    --     end
    --     return scale
    -- end

    ---@param parentFrame any
    ---@param aura BuffWatcher_AuraInstance
    ---@param borders BuffWatcher_BorderDefinition[]
    ---@param borderIndex integer
    ---@param currentSize integer
    ---@param lastBorderWidth integer
    ---@param auraTitle string
    self.BuildFrames = function(parentFrame, aura, borders, borderIndex, currentSize, lastBorderWidth, auraTitle)
        if (borderIndex > #borders) then -- if we've previously added all the borders, then add the main aura frame
            local auraFrame = framePool:Acquire() -- CreateFrame("Frame", "test spell frame", borderFrame)

            auraFrame:SetParent(parentFrame)
            auraFrame:SetFrameLevel(borderIndex + getFrameLevel())
            auraFrame:SetSize(currentSize, currentSize)
            auraFrame:SetPoint("TOPLEFT", parentFrame, "TOPLEFT", lastBorderWidth, -lastBorderWidth)

            auraFrame.texture = auraFrame:CreateTexture("BuffWatcher texture frame - " .. auraTitle)
            auraFrame.texture:SetTexture(auraInstance.icon)
            auraFrame.texture:SetAllPoints(auraFrame)
            auraFrame.texture:SetTexCoord(0.07, 0.93, 0.07, 0.93)
            
            table.insert(frames.allFrames, auraFrame)

            auraFrame:Show()

            if (aura.showCooldown) then
                local cooldownFrame = cooldownFramePool:Acquire()
                cooldownFrame:SetParent(auraFrame)
                cooldownFrame:SetAllPoints()
                cooldownFrame:SetCooldown(aura.expirationTime-aura.duration, aura.duration)
                cooldownFrame:SetReverse(true)

                frames.cooldownFrame = cooldownFrame
                cooldownFrame:Show()
           end
        elseif (borderIndex == 1) then
            local outerBorderFrame = framePool:Acquire() 

            local currentBorder = borders[borderIndex]

            outerBorderFrame:SetParent(parentFrame)
            outerBorderFrame:SetFrameLevel(borderIndex + getFrameLevel())
            outerBorderFrame:SetSize(currentSize, currentSize)
            outerBorderFrame:SetIgnoreParentScale(true)
            outerBorderFrame:SetAlpha(alpha)
            outerBorderFrame:SetScale(0.5)
            -- We expect that these values are updated through the SetOffsets method later
            outerBorderFrame:SetPoint(context.GetSelfAnchorPoint(), parentFrame, context.GetTargetAnchorPoint(), 0, 0) 

            outerBorderFrame.texture = outerBorderFrame:CreateTexture("BuffWatcher border frame " .. borderIndex .. ' ' .. auraTitle)
            outerBorderFrame.texture:SetAllPoints(outerBorderFrame)
            outerBorderFrame.texture:SetColorTexture(currentBorder.color.red, currentBorder.color.green, currentBorder.color.blue)

            table.insert(frames.allFrames, outerBorderFrame)
            frames.rootFrame = outerBorderFrame

            self.BuildFrames(outerBorderFrame, aura, borders, borderIndex+1, currentSize - 2*currentBorder.width, currentBorder.width, auraTitle)

            outerBorderFrame:Show()
        else
            local innerBorderFrame =  framePool:Acquire() 

            local currentBorder = borders[borderIndex]

            innerBorderFrame:SetParent(parentFrame)
            innerBorderFrame:SetFrameLevel(borderIndex + getFrameLevel())
            innerBorderFrame:SetSize(currentSize, currentSize)
            innerBorderFrame:SetPoint("TOPLEFT", parentFrame, "TOPLEFT", lastBorderWidth, -lastBorderWidth)

            innerBorderFrame.texture = innerBorderFrame:CreateTexture("BuffWatcher border frame " .. borderIndex .. ' ' .. auraTitle)
            innerBorderFrame.texture:SetAllPoints(innerBorderFrame)
            innerBorderFrame.texture:SetColorTexture(currentBorder.color.red, currentBorder.color.green, currentBorder.color.blue)

            table.insert(frames.allFrames, innerBorderFrame)

            self.BuildFrames(innerBorderFrame, aura, borders, borderIndex+1, currentSize - 2*currentBorder.width, currentBorder.width, auraTitle)

            innerBorderFrame:Show()
        end
    end

    self.BuildFrames(parentFrame, aura, auraInstance.borders, 1, auraInstance.actualSize, 0, auraTitle)

    self.Dispose = function()
        for _, frame in ipairs(frames.allFrames) do
            frame:SetParent(nil)
            frame:Hide()
            framePool:Release(frame)

            if (frame.texture ~= nil) then
                frame.texture:Hide()
                frame.texture:SetParent(nil)
            end
        end
        
        if (frames.cooldownFrame ~= nil) then 
            frames.cooldownFrame:Hide()
            frames.cooldownFrame:SetParent(nil)
            cooldownFramePool:Release(frames.cooldownFrame)
        end
    end

    self.Dispose = function()
        for _, frame in ipairs(frames.allFrames) do
            frame:SetParent(nil)
            frame:Hide()
            framePool:Release(frame)

            if (frame.texture ~= nil) then
                frame.texture:Hide()
                frame.texture:SetParent(nil)
            end
        end
        
        if (frames.cooldownFrame ~= nil) then 
            frames.cooldownFrame:Hide()
            frames.cooldownFrame:SetParent(nil)
            cooldownFramePool:Release(frames.cooldownFrame)
        end
    end

    ---@param x integer
    ---@param y integer
    self.SetOffsets = function(x, y)
        frames.rootFrame:SetPoint(context.GetSelfAnchorPoint(), parentFrame, context.GetTargetAnchorPoint(), x + context.GetXOffset(), y + context.GetYOffset())
    end

    self.GetWidth = function()
        return auraInstance.actualSize
    end

    self.UpdateCooldown = function()
        if (frames.cooldownFrame ~= nil) then
            frames.cooldownFrame:SetCooldown(aura.expirationTime-aura.duration, aura.duration)
        end
    end

    ---@param newParent BuffWatcher_Blizzard_Frame
    self.SetParent = function(newParent)
        frames.rootFrame:SetParent(newParent)
    end

    return self
end
