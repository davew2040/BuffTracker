---@class BuffWatcher_AuraFrame
BuffWatcher_AuraFrame = {}

---@param framePool any
---@param cooldownFramePool any
---@return BuffWatcher_AuraFrame
function BuffWatcher_AuraFrame:new(framePool, cooldownFramePool)
    self = {}

    ---@type BuffWatcher_FramesCollection
    local frames = nil

    ---@type BuffWatcher_AuraContext?
    local savedContext = nil

    ---@type any
    local savedParentFrame = nil

    ---@type BuffWatcher_AuraInstance?
    local savedAuraInstance = nil

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

    ---@return BuffWatcher_FramesCollection
    local initializeFrames = function()
        local newFrames = BuffWatcher_FramesCollection:new()

        --outer 
        local outerBorderFrame = framePool:Acquire() 

        outerBorderFrame:SetParent(UIParent)
        outerBorderFrame:SetIgnoreParentScale(true)
        outerBorderFrame:SetScale(0.5)
        -- We expect that these values are updated through the SetOffsets method later

        outerBorderFrame.texture = outerBorderFrame:CreateTexture("BuffWatcher frame outerBorderFrame")
        outerBorderFrame.texture:SetAllPoints(outerBorderFrame)
        outerBorderFrame.texture:SetColorTexture(0, 0, 0)

        newFrames.rootFrame = outerBorderFrame

        outerBorderFrame:Show()
        
        --- dispelFrame
        local dispelFrame = framePool:Acquire() 

        dispelFrame:SetParent(outerBorderFrame)

        dispelFrame.texture = dispelFrame:CreateTexture("BuffWatcher frame dispelFrame")
        dispelFrame.texture:SetAllPoints(dispelFrame)

        newFrames.dispelFrame = dispelFrame
        dispelFrame:Show()

        --- hostilityFrame
        local hostilityFrame = framePool:Acquire() 

        hostilityFrame:SetParent(dispelFrame)
        hostilityFrame.texture = hostilityFrame:CreateTexture("BuffWatcher frame hostilityFrame")
        hostilityFrame.texture:SetAllPoints(hostilityFrame)

        newFrames.hostilityFrame = hostilityFrame
        hostilityFrame:Show()

        --- innerFrame
        local innerFrame = framePool:Acquire() 

        innerFrame:SetParent(hostilityFrame)

        innerFrame.texture = innerFrame:CreateTexture("BuffWatcher frame innerFrame")
        innerFrame.texture:SetAllPoints(innerFrame)
        innerFrame.texture:SetColorTexture(0, 0, 0)

        newFrames.innerBorder = innerFrame
        innerFrame:Show()

        -- auraframe
        local auraFrame = framePool:Acquire() -- CreateFrame("Frame", "test spell frame", borderFrame)

        auraFrame:SetParent(innerFrame)

        auraFrame.texture = auraFrame:CreateTexture("BuffWatcher frame auraFrame")
        auraFrame.texture:SetAllPoints(auraFrame)
        auraFrame.texture:SetTexCoord(0.07, 0.93, 0.07, 0.93)
        
        newFrames.auraFrame = auraFrame
        auraFrame:Show()

        local cooldownFrame = cooldownFramePool:Acquire()
        cooldownFrame:SetParent(auraFrame)
        cooldownFrame:SetAllPoints()
        cooldownFrame:SetReverse(true)

        newFrames.cooldownFrame = cooldownFrame
        cooldownFrame:Show()

        return newFrames
    end

    self.Dispose = function()
        -- TODO
        -- for _, frame in ipairs(frames.allFrames) do
        --     frame:SetParent(nil)
        --     frame:Hide()
        --     framePool:Release(frame)

        --     if (frame.texture ~= nil) then
        --         frame.texture:Hide()
        --         frame.texture:SetParent(nil)
        --     end
        -- end
        
        -- if (frames.cooldownFrame ~= nil) then 
        --     frames.cooldownFrame:Hide()
        --     frames.cooldownFrame:SetParent(nil)
        --     cooldownFramePool:Release(frames.cooldownFrame)
        -- end
    end

    self.SetInactive = function()
        if (frames.rootFrame ~= nil) then
            frames.rootFrame:Hide()
            frames.rootFrame:SetParent(UIParent)
        end

        savedContext = nil
        savedParentFrame = nil
        savedAuraInstance = nil
    end

    ---@param aura BuffWatcher_AuraInstance
    ---@param context BuffWatcher_AuraContext
    ---@param parentFrame any
    ---@param alpha number
    self.SetAura = function(aura, context, parentFrame, alpha)
        savedContext = context
        savedParentFrame = parentFrame
        savedAuraInstance = aura

        local currentWidth = aura.actualSize

        frames.rootFrame:SetParent(parentFrame)
        frames.rootFrame:SetSize(currentWidth, currentWidth)
        frames.rootFrame:SetPoint(context.GetSelfAnchorPoint(), parentFrame, context.GetTargetAnchorPoint(), 0, 0) 
        frames.rootFrame:SetAlpha(alpha)
        frames.rootFrame:Show()

        if (savedAuraInstance.borders.showDispel) then
            currentWidth = currentWidth - aura.borders.outerWidth
            frames.dispelFrame:SetPoint("TOPLEFT", frames.rootFrame, "TOPLEFT",  aura.borders.outerWidth, - aura.borders.outerWidth)
            frames.dispelFrame:SetPoint("BOTTOMRIGHT", frames.rootFrame, "BOTTOMRIGHT", -aura.borders.outerWidth, aura.borders.outerWidth)
            frames.dispelFrame.texture:SetColorTexture(
                aura.borders.dispelColor.red, 
                aura.borders.dispelColor.green, 
                aura.borders.dispelColor.blue
            )
        else
            frames.dispelFrame:SetAllPoints(frames.rootFrame)
        end

        frames.hostilityFrame:SetPoint("TOPLEFT", frames.dispelFrame, "TOPLEFT", aura.borders.dispelWidth, -aura.borders.dispelWidth)
        frames.hostilityFrame:SetPoint("BOTTOMRIGHT", frames.dispelFrame, "BOTTOMRIGHT", -aura.borders.dispelWidth, aura.borders.dispelWidth)
        frames.hostilityFrame.texture:SetColorTexture(
            aura.borders.hostilityColor.red,
            aura.borders.hostilityColor.green,
            aura.borders.hostilityColor.blue
        )
        frames.innerBorder:SetPoint("TOPLEFT", frames.hostilityFrame, "TOPLEFT", aura.borders.hostilityWidth, -aura.borders.hostilityWidth)
        frames.innerBorder:SetPoint("BOTTOMRIGHT", frames.hostilityFrame, "BOTTOMRIGHT", -aura.borders.hostilityWidth, aura.borders.hostilityWidth)

        frames.auraFrame.texture:SetTexture(aura.icon)
        frames.auraFrame:SetPoint("TOPLEFT", frames.innerBorder, "TOPLEFT", aura.borders.innerWidth, -aura.borders.innerWidth)
        frames.auraFrame:SetPoint("BOTTOMRIGHT", frames.innerBorder, "BOTTOMRIGHT", -aura.borders.innerWidth, aura.borders.innerWidth)

        if aura.showCooldown then
            frames.cooldownFrame:Show()
            frames.cooldownFrame:SetCooldown(aura.expirationTime-aura.duration, aura.duration)
        else
            frames.cooldownFrame:Hide()
        end
    end

    ---@param x integer
    ---@param y integer
    self.SetOffsets = function(x, y)
        frames.rootFrame:SetPoint(
            savedContext.GetSelfAnchorPoint(), 
            savedParentFrame, 
            savedContext.GetTargetAnchorPoint(), 
            x + savedContext.GetXOffset(), 
            y + savedContext.GetYOffset()
        )
    end

    self.GetWidth = function()
        return savedAuraInstance and savedAuraInstance.actualSize or 0
    end

    self.UpdateCooldown = function()
        if (frames.cooldownFrame ~= nil) then
            frames.cooldownFrame:SetCooldown(savedAuraInstance.expirationTime-savedAuraInstance.duration, savedAuraInstance.duration)
        end
    end

    ---@param newParent BuffWatcher_Blizzard_Frame
    self.SetParent = function(newParent)
        frames.rootFrame:SetParent(newParent)
    end

    frames = initializeFrames()

    return self
end
