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

    ---@type table<BuffWatcher_BlizzardFrameWrapper, string>
    local framesToGuids = {}

    ---@type table<string, table<BuffWatcher_BlizzardFrameWrapper, boolean>>
    local guidsToFrames = {}

    ---@type table<BuffWatcher_BlizzardFrameWrapper, table<string, BuffWatcher_FrameData>>
    local wowFramesToAuraFrames = {}

    local initialize = function()
    end
    
    initialize()

    ---@param wowFrame BuffWatcher_BlizzardFrameWrapper
    ---@param guid string
    ---@param auraFrames table<string, BuffWatcher_FrameData>
    local attachAuraFramesToWowFrame = function(wowFrame, guid, auraFrames)
        if framesToGuids[wowFrame] ~= nil then
            error("Frame already has guid associated")
        else
            framesToGuids[wowFrame] = guid
        end

        if wowFramesToAuraFrames[wowFrame] ~= nil then
            error("Frame already has auras associated")
        else
            wowFramesToAuraFrames[wowFrame] = auraFrames
        end

        if guidsToFrames[guid] == nil then
            guidsToFrames[guid] = {}
        end

        guidsToFrames[guid][wowFrame] = true
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
                x = x - auraFrame.auraFrame.GetWidth() - 1
            else 
                x = x + auraFrame.auraFrame.GetWidth() + 1
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
                local auraFrame = context.GetSingleAuraFrame(auraInstance, wrappedFrame.GetFrame())
                
                ---@type BuffWatcher_FrameData
                local frameEntry = {
                    stateKey = stateKey,
                    auraFrame = auraFrame,
                    auraInstance = auraInstance
                }
                newAuraFrames[stateKey] = frameEntry
            end
            DevTool:AddData({wrappedFrame = wrappedFrame, unitName = unitName, unitGuid = unitGuid, newAuraFrames = newAuraFrames}, "fixme attachAuraFramesToWowFrame")

            attachAuraFramesToWowFrame(wrappedFrame, unitGuid, newAuraFrames)
        end

        redrawAurasByGuid(unitGuid)
    end


    ---@param units table<string, boolean>
    self.DoFullUpdate = function(units)
        self.Reset()

        for unit, _ in pairs(units) do
            local frames = getTargetFrames(unit)

            if (#frames > 0) then
                addUnitAuras(unit, frames)
            end
        end

        -- DevTool:AddData(framesToGuids, "fixme framesToGuids")
        -- DevTool:AddData(guidsToFrames, "fixme guidsToFrames")
        -- DevTool:AddData(wowFramesToAuraFrames, "fixme wowFramesToAuraFrames")
    end

    self.Reset = function()
        for _, auraEntries in pairs(wowFramesToAuraFrames) do
            for _, auraEntry in pairs(auraEntries) do
                auraEntry.auraFrame.Dispose()
            end
        end

        framesToGuids = {}
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

            aura.auraFrame.Dispose()

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

            aura.auraFrame.UpdateCooldown()
        end
    end

    ---@param guid string
    ---@param stateKey string
    self.AuraAdded = function(guid, stateKey)
        DevTool:AddData(stateKey, "fixme AuraAdded")

        local frames = getFramesForGuid(guid)

        DevTool:AddData(frames, "fixme frames")

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
    self.UnitUpdated = function(unitGuid)
        DevTool:AddData({unitGuid = unitGuid, context = context.getName()}, "fixme UnitUpdated")
        self.DoFullUpdate(context.GetPotentialUnits())
    end

    ---@param unitGuid string
    self.UnitCleared = function(unitGuid)
        self.DoFullUpdate(context.GetPotentialUnits())
    end

    return self;
end