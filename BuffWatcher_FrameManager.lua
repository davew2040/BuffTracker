local LGF = LibStub("LibGetFrame-1.0")

---@class BuffWatcher_FrameData
---@field stateKey string
---@field auraFrame BuffWatcher_AuraFrame
---@field auraInstance BuffWatcher_AuraInstance
BuffWatcher_FrameData = {}

---@class BuffWatcher_FrameManager
BuffWatcher_FrameManager = {}

---@param context BuffWatcher_AuraContext
---@return BuffWatcher_FrameManager
function BuffWatcher_FrameManager:new(context)
    self = {};

    ---@type table<string, table<BuffWatcher_BlizzardFrameWrapper, boolean>>
    local guidsToFrames = {}

    ---@type table<BuffWatcher_BlizzardFrameWrapper, table<string, BuffWatcher_FrameData>>
    local wowFramesToAuraFrames = {}

    local initialize = function()
    end
    
    initialize()

    ---@param wowFrame BuffWatcher_BlizzardFrameWrapper
    ---@param guid string
    local associateFrameToGuid = function(wowFrame, guid)
        wowFramesToAuraFrames[wowFrame] = {}

        if guidsToFrames[guid] == nil then
            guidsToFrames[guid] = {}
        end

        guidsToFrames[guid][wowFrame] = true
    end


    ---@param wowFrame BuffWatcher_BlizzardFrameWrapper
    ---@param guid string
    local detachFrameFromGuid = function(wowFrame, guid)
        wowFramesToAuraFrames[wowFrame] = nil

        guidsToFrames[guid][wowFrame] = nil

        if (BuffWatcher_Shared_Singleton.GetTableKeyCount(guidsToFrames[guid]) == 0) then
            guidsToFrames[guid] = nil
        end
    end

    ---@param wowFrame BuffWatcher_BlizzardFrameWrapper
    ---@param guid string
    ---@param auraFrames table<string, BuffWatcher_FrameData>
    local attachAuraFramesToWowFrame = function(wowFrame, guid, auraFrames)
        if wowFramesToAuraFrames[wowFrame] ~= nil then
            wowFramesToAuraFrames[wowFrame] = auraFrames
        end
    end

    ---@param guid string
    ---@return table<BuffWatcher_BlizzardFrameWrapper, boolean>
    local getFramesForGuid = function(guid)
        local frames = guidsToFrames[guid]

        if (frames == nil) then 
            frames = {}
        end

        return frames
    end

    ---@param wowFrame BuffWatcher_BlizzardFrameWrapper
    ---@return table<string, BuffWatcher_FrameData>
    local getAurasForFrame = function(wowFrame)
        if (wowFramesToAuraFrames[wowFrame] == nil) then
            return {}
        end

        return wowFramesToAuraFrames[wowFrame]
    end

    ---@param wowFrame BuffWatcher_BlizzardFrameWrapper
    local redrawAurasByFrame = function(wowFrame)
        local auraFrames = getAurasForFrame(wowFrame)

        ---@type table<integer, BuffWatcher_FrameData>
        local orderedAuras = BuffWatcher_Shared.OrderValuesByDescending(auraFrames, 
            function(key)
                ---@cast key BuffWatcher_FrameData
                return key.auraInstance.priority
            end
        )

        local x = 0
        for _, auraFrame in ipairs(orderedAuras) do
            auraFrame.auraFrame.SetOffsets(x, 0)

            if (context.GetGrowthDirection() == BuffWatcher_GrowDirection.Left) then
                x = x - auraFrame.auraFrame.GetWidth() - 2
            else 
                x = x + auraFrame.auraFrame.GetWidth() + 2
            end
        end
    end

    ---@param guid string
    ---@return nil
    local redrawAurasByGuid = function(guid) 
        local frames = getFramesForGuid(guid)

        for frame, _ in pairs(frames) do
            redrawAurasByFrame(frame)
        end
    end

    local redrawAll = function()
        for guid, _ in pairs(guidsToFrames) do
            redrawAurasByGuid(guid)
        end
    end

    ---@param targetUnit string
    ---@return BuffWatcher_BlizzardFrameWrapper[]
    local getTargetFrames = function(targetUnit)
        local result = {}

        if (context.isNameplate()) then
            local nameplateFrame = C_NamePlate.GetNamePlateForUnit(targetUnit)
            
            if (nameplateFrame ~= nil) then
                table.insert(result, BuffWatcher_BlizzardFrameWrapper:new(nameplateFrame))
            end
        else
            local frames = LGF.GetUnitFrame(targetUnit, { 
                ignorePlayerFrame = true, 
                ignoreTargetFrame = true, 
                ignoreTargettargetFrame = true,
                returnAll = true
            })

            if (frames ~= nil) then
                for _, frame in pairs(frames) do
                    table.insert(result, BuffWatcher_BlizzardFrameWrapper:new(frame))
                end
            end
        end

        return result
    end

    ---@param guid string
    ---@param frames BuffWatcher_BlizzardFrameWrapper[]
    local addGuidAuras = function(guid, frames)
        local stateKeys = context.GetKeysByGuid(guid)

        for _, wrappedFrame in ipairs(frames) do
            --DevTool:AddData(wrappedFrame, "fixme processing wrappedFrame")
            ---@type table<string, BuffWatcher_FrameData>
            local newAuraFrames = {}

            for stateKey, _ in pairs(stateKeys) do
                -- DevTool:AddData(stateKey, "fixme processing auraframe")
                local auraInstance = context.GetAuraInstanceByKey(stateKey)
                local auraFrame = context.GetSingleAuraFrame(auraInstance, wrappedFrame.GetFrame())
                
                ---@type BuffWatcher_FrameData
                local frameEntry = {
                    stateKey = stateKey,
                    auraFrame = auraFrame,
                    auraInstance = auraInstance
                }
                newAuraFrames[stateKey] = frameEntry
            end

            attachAuraFramesToWowFrame(wrappedFrame, guid, newAuraFrames)
        end

        redrawAurasByGuid(guid)
    end

    ---@param unitName string
    ---@param frames BuffWatcher_BlizzardFrameWrapper[]
    local addUnitAuras = function(unitName, frames)
        local unitGuid = UnitGUID(unitName)
        local stateKeys = context.GetKeysByGuid(unitGuid)

        -- DevTool:AddData(wrappedFrames, "fixme wrappedFrames")
        -- DevTool:AddData(CopyTable(stateKeys), "fixme processing stateKeys")

        for _, wrappedFrame in ipairs(frames) do
            --DevTool:AddData(wrappedFrame, "fixme processing wrappedFrame")
            ---@type table<string, BuffWatcher_FrameData>
            local newAuraFrames = {}

            for stateKey, _ in pairs(stateKeys) do
                -- DevTool:AddData(stateKey, "fixme processing auraframe")
                local auraInstance = context.GetAuraInstanceByKey(stateKey)
                if (context.FilterEvent(unitName)) then
                    local auraFrame = context.GetSingleAuraFrame(auraInstance, wrappedFrame.GetFrame())
                    
                    ---@type BuffWatcher_FrameData
                    local frameEntry = {
                        stateKey = stateKey,
                        auraFrame = auraFrame,
                        auraInstance = auraInstance
                    }
                    newAuraFrames[stateKey] = frameEntry
                end
            end

            attachAuraFramesToWowFrame(wrappedFrame, unitGuid, newAuraFrames)
        end

        redrawAurasByGuid(unitGuid)
    end

    local clearAurasForGuid = function(unitGuid)
        local frames = getFramesForGuid(unitGuid) 

        for frame, _ in pairs(frames) do
            local auras = getAurasForFrame(frame)

            for key, auraData in pairs(auras) do
                auraData.auraFrame.Dispose()
            end

            wowFramesToAuraFrames[frame] = {}
        end

        redrawAurasByGuid(unitGuid)
    end

    ---@param guid string
    ---@param frame BuffWatcher_BlizzardFrameWrapper
    local addGuidAurasToFrame = function(guid, frame)
        local stateKeys = context.GetKeysByGuid(guid)

        --DevTool:AddData(wrappedFrame, "fixme processing wrappedFrame")
        ---@type table<string, BuffWatcher_FrameData>
        local newAuraFrames = {}

        for stateKey, _ in pairs(stateKeys) do
            -- DevTool:AddData(stateKey, "fixme processing auraframe")
            local auraInstance = context.GetAuraInstanceByKey(stateKey)
            local auraFrame = context.GetSingleAuraFrame(auraInstance, frame.GetFrame())
            
            ---@type BuffWatcher_FrameData
            local frameEntry = {
                stateKey = stateKey,
                auraFrame = auraFrame,
                auraInstance = auraInstance
            }
            newAuraFrames[stateKey] = frameEntry
        end

        attachAuraFramesToWowFrame(frame, guid, newAuraFrames)

        redrawAurasByGuid(guid)
    end

    local addAllAurasForGuid = function(unitGuid)
        local frames = getFramesForGuid(unitGuid)
        for frame, _ in pairs(frames) do
            addGuidAurasToFrame(unitGuid, frame)
        end
    end

    ---@param units table<string, boolean>
    self.DoFullUpdate = function(units)
        --DevTool:AddData("fixme DoFullUpdate")
        self.Reset()

        for unit, _ in pairs(units) do
            local frames = getTargetFrames(unit)

            for _, frame in ipairs(frames) do
                -- if this frame isn't already present in our set, then add it
                if (wowFramesToAuraFrames[frame] == nil) then
                    local guid = UnitGUID(unit)
                    associateFrameToGuid(frame, guid)
                    addGuidAurasToFrame(guid, frame)
                end
            end
        end
    end

    self.Reset = function()
        for _, auraEntries in pairs(wowFramesToAuraFrames) do
            for _, auraEntry in pairs(auraEntries) do
                auraEntry.auraFrame.Dispose()
            end
        end

        guidsToFrames = {}
        wowFramesToAuraFrames = {}
    end

    ---@param guid string
    ---@param stateKey string
    self.AuraRemoved = function(guid, stateKey)
        local frames = getFramesForGuid(guid)

        for wowFrame, _ in pairs(frames) do
            local aurasForFrame = getAurasForFrame(wowFrame)
            local aura = aurasForFrame[stateKey]

            if (aura ~= nil) then
                aura.auraFrame.Dispose()
            else
                DevTool:AddData({ guid = guid, stateKey = stateKey }, "error - encountered nil aura")
            end
            
            aurasForFrame[stateKey] = nil
        end

        redrawAurasByGuid(guid)
    end

    ---@param guid string
    ---@param stateKey string
    self.AuraUpdated = function(guid, stateKey)
        local frames = getFramesForGuid(guid)

        for wowFrame, _ in pairs(frames) do
            local aura = getAurasForFrame(wowFrame)[stateKey]

            if (aura ~= nil) then
                aura.auraFrame.UpdateCooldown()
            end
        end
    end

    ---@param guid string
    ---@param stateKey string
    self.AuraAdded = function(guid, stateKey)
        local frames = getFramesForGuid(guid)

        for wowFrame, _ in pairs(frames) do
            local auras = getAurasForFrame(wowFrame)

            local auraInstance = context.GetAuraInstanceByKey(stateKey)
            local auraFrame = context.GetSingleAuraFrame(auraInstance, wowFrame.GetFrame())
            
            ---@type BuffWatcher_FrameData
            local frameEntry = {
                stateKey = stateKey,
                auraFrame = auraFrame,
                auraInstance = auraInstance
            }
            auras[stateKey] = frameEntry
        end

        redrawAurasByGuid(guid)
    end

    ---@param unitGuid string
    self.GuidRefreshed = function(unitGuid)
        clearAurasForGuid(unitGuid)
        addAllAurasForGuid(unitGuid)
    end

    ---@param unitName string
    self.UnitAdded = function(unitName)
        local frames = getTargetFrames(unitName)

        if (#frames > 0) then
            local guid = UnitGUID(unitName)
            for _, frame in ipairs(frames) do
                associateFrameToGuid(frame, guid)
            end
            addUnitAuras(unitName, frames)
        end
    end

    ---@param unitGuid string
    self.UnitRemoved = function(unitGuid)
        clearAurasForGuid(unitGuid)
        local oldFrames = getFramesForGuid(unitGuid)

        for frame, _ in pairs(oldFrames) do
            detachFrameFromGuid(frame, unitGuid)
        end

        redrawAurasByGuid(unitGuid)
    end

    self.DoFullClear = function()
        self.DoFullUpdate(context.GetPotentialUnits())
    end

    return self;
end