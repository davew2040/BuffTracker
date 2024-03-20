local LGF = LibStub("LibGetFrame-1.0")

---@class BuffWatcher_FrameData
---@field stateKey string
---@field auraFrame BuffWatcher_AuraFrame
---@field auraInstance BuffWatcher_AuraInstance
BuffWatcher_FrameData = {}

---@class BuffWatcher_GuidFrameData
---@field guid string
---@field unitName string
---@field frames table<BuffWatcher_Blizzard_Frame, BuffWatcher_Blizzard_Frame>
---@field units table<string, string>
BuffWatcher_GuidFrameData = {}

---@class BuffWatcher_FrameManager
BuffWatcher_FrameManager = {}

---@class BuffWatcher_FrameManagerNew
BuffWatcher_FrameManagerNew = {}

---@param context BuffWatcher_AuraContext
---@return BuffWatcher_FrameManagerNew
function BuffWatcher_FrameManagerNew:new(context)
    ---@type BuffWatcher_FrameManagerNew
    self = {};

    -- ---@type table<string, string>
    -- local stateKeysToGuids = {}

    ---@type table<string, BuffWatcher_GuidFrameData>
    local currentGuidsToFrames = {}

    -- maps frames to state keys to aura frame information
    ---@type table<BuffWatcher_Blizzard_Frame, table<string, BuffWatcher_FrameData>>
    local frameToAuraData = {}

    ---@param guid string
    ---@return table<BuffWatcher_Blizzard_Frame, BuffWatcher_Blizzard_Frame>
    local getFramesForGuid = function(guid)
        local frameInfo = currentGuidsToFrames[guid]

        if (frameInfo == nil) then 
            return {}
        end

        return frameInfo.frames
    end

    ---@return boolean
    local shouldLog = function()
        return context.getFrameType() == BuffWatcher_FrameTypes.Raid --and context.includeBuffsAndCasts() == true
    end

    ---@param wowFrame BuffWatcher_Blizzard_Frame
    ---@return table<string, BuffWatcher_FrameData>
    local getAurasForFrame = function(wowFrame)
        if (frameToAuraData[wowFrame] == nil) then
            frameToAuraData[wowFrame] = {}
        end

        return frameToAuraData[wowFrame]
    end

    ---@param wowFrame BuffWatcher_Blizzard_Frame
    local redrawAurasByFrame = function(wowFrame)
        local auraFrames = getAurasForFrame(wowFrame)

        ---@type table<integer, BuffWatcher_FrameData>
        local orderedAuras = BuffWatcher_Shared.OrderValuesByDescending(
            auraFrames, 
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
    ---@return table<BuffWatcher_Blizzard_Frame, BuffWatcher_Blizzard_Frame>
    local getTargetFrames = function(targetUnit)
        local result = {}

        if (context.isNameplate()) then
            local nameplateFrame = C_NamePlate.GetNamePlateForUnit(targetUnit)
            
            if (nameplateFrame ~= nil) then
                result[nameplateFrame] = nameplateFrame
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
                    result[frame] = frame
                end
            end
        end

        return result
    end


    ---@param unitGuid string
    ---@param frames table<BuffWatcher_Blizzard_Frame, BuffWatcher_Blizzard_Frame>
    local addAllGuidAurasToFrames = function(unitGuid, frames)
        local stateKeys = context.GetKeysByGuid(unitGuid)

        for frame, _ in pairs(frames) do
            --DevTool:AddData(wrappedFrame, "fixme processing wrappedFrame")

            for stateKey, _ in pairs(stateKeys) do
                -- DevTool:AddData(stateKey, "fixme processing auraframe")
                local auraInstance = context.GetAuraInstanceByKey(stateKey)
                local auraFrame = context.GetSingleAuraFrame(auraInstance, frame)
                
                ---@type BuffWatcher_FrameData
                local frameEntry = {
                    stateKey = stateKey,
                    auraFrame = auraFrame,
                    auraInstance = auraInstance
                }

                local auraSet = getAurasForFrame(frame)
                if auraSet[stateKey] ~= nil then
                    auraSet[stateKey].auraFrame.Dispose()
                end

                getAurasForFrame(frame)[stateKey] = frameEntry
            end
        end

        redrawAurasByGuid(unitGuid)
    end

    self.Clear = function()
        if (shouldLog()) then
            DevTool:AddData(frameToAuraData, "fixme frameToAuraData before Clear")
        end

        for frame, frameAuras in pairs(frameToAuraData) do
            for stateKey, auraInfo in pairs(frameAuras) do
                auraInfo.auraFrame.Dispose()
            end
        end

        frameToAuraData = {}
        currentGuidsToFrames = {}
    end

    ---@param guid string
    ---@param stateKey string
    self.AuraRemoved = function(guid, stateKey)
        local frames = getFramesForGuid(guid)

        for wowFrame, _ in pairs(frames) do
            if (frameToAuraData[wowFrame] ~= nil and frameToAuraData[wowFrame][stateKey] ~= nil) then
                local frameToRemove = frameToAuraData[wowFrame][stateKey]

                frameToRemove.auraFrame.Dispose()
                frameToAuraData[wowFrame][stateKey] = nil

                redrawAurasByFrame(wowFrame)
            end
        end
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
            local auraInstance = context.GetAuraInstanceByKey(stateKey)
            local auraFrame = context.GetSingleAuraFrame(auraInstance, wowFrame)
            
            ---@type BuffWatcher_FrameData
            local frameEntry = {
                stateKey = stateKey,
                auraFrame = auraFrame,
                auraInstance = auraInstance
            }
            getAurasForFrame(wowFrame)[stateKey] = frameEntry
        end

        redrawAurasByGuid(guid)
    end

    ---@param unitGuid string
    self.GuidRefreshed = function(unitGuid)

    end

    ---@return table<string, BuffWatcher_GuidFrameData>
    local buildGuidsToFrames = function()
        local units = context.GetPotentialUnits()

        ---@type table<string, BuffWatcher_GuidFrameData>
        local result = {}

        for unit, _ in pairs(units) do
            if (UnitExists(unit)) then
                local unitGuid = UnitGUID(unit)
                local frames = getTargetFrames(unit)

                if (result[unitGuid] == nil) then
                    ---@type BuffWatcher_GuidFrameData
                    local newEntry = {
                        guid = unitGuid, 
                        unitName = UnitName(unit),
                        frames = frames,
                        units = {
                            [unit] = unit
                        }
                    }
                    result[unitGuid] = newEntry
                else
                    result[unitGuid].units[unit] = unit
                end
            end
        end

        return result
    end


    -- for _, wrappedFrame in ipairs(frames) do
    --     --DevTool:AddData(wrappedFrame, "fixme processing wrappedFrame")
    --     ---@type table<string, BuffWatcher_FrameData>
    --     local newAuraFrames = {}

    --     for stateKey, _ in pairs(stateKeys) do
    --         -- DevTool:AddData(stateKey, "fixme processing auraframe")
    --         local auraInstance = context.GetAuraInstanceByKey(stateKey)
    --         if (context.FilterEvent(unitName)) then
    --             local auraFrame = context.GetSingleAuraFrame(auraInstance, wrappedFrame)
                
    --             ---@type BuffWatcher_FrameData
    --             local frameEntry = {
    --                 stateKey = stateKey,
    --                 auraFrame = auraFrame,
    --                 auraInstance = auraInstance
    --             }
    --             newAuraFrames[stateKey] = frameEntry
    --         end
    --     end

    --     attachAuraFramesToWowFrame(wrappedFrame, unitGuid, newAuraFrames)


    ---@param changeInfo table<string, BuffWatcher_KeyDiffChangedItems>
    local handleChangedGuids = function(changeInfo)
        for changedGuid, data in pairs(changeInfo) do
            ---@cast changedGuid string
            ---@cast data BuffWatcher_KeyDiffChangedItems
         
            -- if shouldLog() then
            --     DevTool:AddData(changeInfo, "fixme changeInfo for " .. changedGuid .. " context = " .. context.getName())
            -- end

            local framesDiff = BuffWatcher_Shared.KeyDiff(data.old.frames, data.new.frames)
            
            -- if shouldLog() then
            --     DevTool:AddData(framesDiff, "fixme framesDiff for " .. changedGuid .. " context = " .. context.getName())
            -- end

            ---@type table<BuffWatcher_Blizzard_Frame, BuffWatcher_Blizzard_Frame>
            local removedFrames = framesDiff.removed

            ---@type table<BuffWatcher_Blizzard_Frame, BuffWatcher_Blizzard_Frame>
            local addedFrames = framesDiff.added
            
            -- -- move auras across frames if possible
            -- while true do
            --     ---@type BuffWatcher_Blizzard_Frame
            --     local firstRemoved = BuffWatcher_Shared.FirstKeyOrDefault(removedFrames)
            --     if (firstRemoved == nil) then
            --         break
            --     end
                
            --     ---@type BuffWatcher_Blizzard_Frame
            --     local firstAdded = BuffWatcher_Shared.FirstKeyOrDefault(addedFrames)
            --     if (firstAdded == nil) then
            --         break
            --     end

            --     DevTool:AddData({firstRemoved = firstRemoved, firstAdded = firstAdded }, "fixme doing frame move of " .. firstRemoved.unit .. " to " .. firstAdded.unit)

            --     removedFrames[firstRemoved] = nil
            --     addedFrames[firstAdded] = nil

            --     if frameToAuraData[firstRemoved] == nil then
            --         frameToAuraData[firstRemoved] = {}
            --     end

            --     local sourceFrame = frameToAuraData[firstRemoved]

            --     if frameToAuraData[firstAdded] == nil then
            --         frameToAuraData[firstAdded] = {}
            --     end

            --     local destinationFrame = frameToAuraData[firstAdded]
                
            --     DevTool:AddData("fixme after frame move")

            --     for key, frameData in pairs(sourceFrame) do
            --         destinationFrame[key] = frameData
            --         sourceFrame[key] = nil
            --         frameData.auraFrame.SetParent(destinationFrame)
            --     end

            --     frameToAuraData[sourceFrame] = nil

            --     redrawAurasByFrame(firstAdded)
            -- end

            -- remove remaining frames
            while true do
                ---@type BuffWatcher_Blizzard_Frame

                local frameToRemove = BuffWatcher_Shared.FirstKeyOrDefault(removedFrames)
                if (frameToRemove == nil) then
                    break
                end

                removedFrames[frameToRemove] = nil

                local removedFrameData = frameToAuraData[frameToRemove]

                if (removedFrameData ~= nil) then
                    for key, frameData in pairs(removedFrameData) do
                        frameData.auraFrame.Dispose()
                    end
    
                    frameToAuraData[frameToRemove] = nil
                end
            end

            addAllGuidAurasToFrames(changedGuid, addedFrames)
        end
    end

    self.DoUpdate = function()
        --DevTool:AddData("fixme FrameManager:DoUpdate " .. context.getName())

        local newGuidsToFrames = buildGuidsToFrames()

        local diff = BuffWatcher_Shared.KeyDiff(currentGuidsToFrames, newGuidsToFrames)

        currentGuidsToFrames = newGuidsToFrames

        -- if (shouldLog() and (BuffWatcher_Shared_Singleton.GetTableKeyCount(diff.added) > 0 or BuffWatcher_Shared_Singleton.GetTableKeyCount(diff.removed) > 0)) then
        --     DevTool:AddData(currentGuidsToFrames, "fixme old guidsToFrames")
        --     DevTool:AddData(newGuidsToFrames, "fixme new guidsToFrames")
        --     DevTool:AddData(diff, "fixme diff of guidsToFrames")
        -- end

        -- first clear out removed GUID's
        for removedGuid, data in pairs(diff.removed) do
            ---@cast removedGuid string
            ---@cast data BuffWatcher_GuidFrameData

            if (shouldLog()) then
                DevTool:AddData("fixme removing guid " .. removedGuid)
            end

            DevTool:AddData(data, "fixme remove guid data")

            for wowFrame, _ in pairs(data.frames) do
                local existingFrameData = frameToAuraData[wowFrame]

                if (existingFrameData ~= nil) then
                    for _, auraData in pairs(existingFrameData) do
                        auraData.auraFrame.Dispose()
                    end
 
                    frameToAuraData[wowFrame] = nil
                else
                    DevTool:AddData(existingFrameData, "fixme attempted to remove frame that is not found in store")
                end
            end
        end

        -- then transition any guids with frame changes
        handleChangedGuids(diff.unchanged)

        -- then add any new guids
        for addedGuid, data in pairs(diff.added) do
            -- if (shouldLog()) then
            --     DevTool:AddData("adding guid " .. addedGuid)
            -- end

            addAllGuidAurasToFrames(addedGuid, data.frames)
        end

        -- if (shouldLog()) then
        --     DevTool:AddData(currentGuidsToFrames, "fixme after DoUpdate currentGuidsToFrames")
        --     DevTool:AddData(BuffWatcher_Shared_Singleton.GetTableKeyCount(frameToAuraData), "fixme after DoUpdate frameToAuraData count")
        --     DevTool:AddData(frameToAuraData, "fixme after DoUpdate frameToAuraData")
        -- end
    end

    self.DoFullUpdate = function()
        self.Clear()

        currentGuidsToFrames = buildGuidsToFrames()

        -- first clear out removed GUID's
        for guid, guidData in pairs(currentGuidsToFrames) do
            addAllGuidAurasToFrames(guid, guidData.frames)
        end
    end

    ---@param unit string
    self.NameplateUnitAdded = function(unit)
        local unitGuid = UnitGUID(unit)
        local frames = getTargetFrames(unit)

        currentGuidsToFrames[unitGuid] = {
            guid = unitGuid,
            frames = getTargetFrames(unit),
            unitName = UnitName(unit),
            units = {
                [unit] = unit
            }
        }

        addAllGuidAurasToFrames(unitGuid, frames)
    end

    ---@param unitGuid string
    self.NameplateUnitRemoved = function(unitGuid)
        if (unitGuid == nil) then
            DevTool:AddData("fixme NameplateUnitRemoved guid is nil")
            return
        end
        
        local guidInfo = currentGuidsToFrames[unitGuid]

        if guidInfo == nil then
            DevTool:AddData("fixme NameplateUnitRemoved guid not found " .. unitGuid)
            return
        end

        local frames = getFramesForGuid(unitGuid)

        for frame, _ in pairs(frames) do
            local auras = getAurasForFrame(frame)

            for key, auraInfo in pairs(auras) do
                auraInfo.auraFrame.Dispose()
            end

            frameToAuraData[frame] = nil
        end
        
        currentGuidsToFrames[unitGuid] = nil
    end

    return self;
end