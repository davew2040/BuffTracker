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
---@param configuration BuffWatcher_Configuration
---@param objectPool BuffWatcher_MiscellaneousObjectPool
---@return BuffWatcher_FrameManagerNew
function BuffWatcher_FrameManagerNew:new(context, configuration, objectPool)
    ---@type BuffWatcher_FrameManagerNew
    self = {};

    ---@type table<string, table<string, boolean>> | nil
    local lastFrameMap = nil

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
            return BuffWatcher_Shared.EmptyTable
        end

        return frameInfo.frames
    end

    -- entirely for debugging
    ---@return boolean
    local shouldLog = function()
        return context.getFrameType() == BuffWatcher_FrameTypes.Raid --and context.includeBuffsAndCasts() == true
    end

    -- ---@param wowFrame BuffWatcher_Blizzard_Frame
    -- ---@return table<string, BuffWatcher_FrameData>
    -- local getAurasForFrame = function(wowFrame)
    --     return frameToAuraData[wowFrame]
    -- end

    ---comment
    ---@param frameData BuffWatcher_FrameData
    local framePrioritizer = function(frameData)
        return frameData.auraInstance.priority
    end

    ---@param wowFrame BuffWatcher_Blizzard_Frame
    local redrawAurasByFrame = function(wowFrame)
        local auraFrames = frameToAuraData[wowFrame]

        local orderedAuras = objectPool.GetObject()

        ---@type table<integer, BuffWatcher_FrameData>
        BuffWatcher_Shared.OrderValuesByDescending(
            auraFrames, 
            orderedAuras,
            framePrioritizer
        )

        local x = 0
        for _, auraFrame in ipairs(orderedAuras) do
            auraFrame.auraFrame.SetOffsets(x, 0)

            if (context.GetGrowthDirection() == BuffWatcher_GrowDirection.Left) then
                x = x - auraFrame.auraFrame.GetWidth() - configuration.GetAuraSpacing()
            else 
                x = x + auraFrame.auraFrame.GetWidth() + configuration.GetAuraSpacing()
            end
        end

        objectPool.ReleaseObject(orderedAuras)
    end

    ---@param guid string
    ---@return nil
    local redrawAurasByGuid = function(guid) 
        local frames = getFramesForGuid(guid)

        for frame, _ in pairs(frames) do
            redrawAurasByFrame(frame)
        end
    end

    local initializeFrameAuraData = function()
        for guid, frameData in pairs(currentGuidsToFrames) do
            for frame, _ in pairs(frameData.frames) do
                frameToAuraData[frame] = objectPool.GetObject()
            end
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


    ---@param units table<string, boolean>
    ---@return table<string, table<string, boolean>> -- object pool result
    local buildFrameMap = function(units)
        ---@type table<string, table<string, boolean>>
        local result = objectPool.GetObject()

        for unit, _ in pairs(units) do
            if (UnitExists(unit)) then
                local frames = getTargetFrames(unit)

                result[unit] = objectPool.GetObject()

                for frame, _ in pairs(frames) do
                    result[unit][frame:GetName()] = true
                end
            end
        end

        return result
    end

    local removeGuid = function(guid)
        local frames = getFramesForGuid(guid)

        for frame, _ in pairs(frames) do
            local auras = frameToAuraData[frame]

            if (auras ~= nil) then
                for key, auraInfo in pairs(auras) do
                    context.ReleaseFrame(auraInfo.auraFrame)
                end

                objectPool.ReleaseObject(frameToAuraData[frame])
                frameToAuraData[frame] = nil
            else
                DevTool:AddData("fixme encountered nil auras attached to guid " .. guid)
            end
        end
        
        currentGuidsToFrames[guid] = nil
    end

    ---@param frameMap table<string, table<string, boolean>>
    local releaseFrameMap = function(frameMap)
        for k,v in pairs(frameMap) do
            objectPool.ReleaseObject(v)
        end

        objectPool.ReleaseObject(frameMap)
    end

    self.Clear = function()
        DevTool:AddData("fixme FrameManager Clear")

        if (shouldLog()) then
            DevTool:AddData(frameToAuraData, "fixme frameToAuraData before Clear")
        end

        local guidsOnly = objectPool.GetObject()

        BuffWatcher_Shared.CopyKeysInto(currentGuidsToFrames, guidsOnly)

        for guid, _ in pairs(guidsOnly) do
            removeGuid(guid)
        end

        if (lastFrameMap ~= nil) then
            releaseFrameMap(lastFrameMap)
        end

        objectPool.ReleaseObject(guidsOnly)

        local units = context.GetPotentialUnits()

        lastFrameMap = buildFrameMap(units)
    end

    ---@param wowFrame BuffWatcher_Blizzard_Frame
    ---@param stateKey string
    local removeAuraFromFrame = function(wowFrame, stateKey)
        local frameAuras = frameToAuraData[wowFrame]
        local frameToRemove = frameAuras[stateKey]

        context.ReleaseFrame(frameToRemove.auraFrame)
        frameAuras[stateKey] = nil
    end

    local removeAuraFromGuid = function(guid, stateKey)
        local frames = getFramesForGuid(guid)

        for wowFrame, _ in pairs(frames) do
            removeAuraFromFrame(wowFrame, stateKey)
        end
    end

    ---comment
    ---@param wowFrame BuffWatcher_Blizzard_Frame
    ---@param stateKey string
    local addAuraToFrame = function(wowFrame, stateKey) 
        local auraInstance = context.GetAuraInstanceByKey(stateKey)
        local auraFrame = context.GetSingleAuraFrame(auraInstance, wowFrame)
        
        ---@type BuffWatcher_FrameData
        local frameEntry = {
            stateKey = stateKey,
            auraFrame = auraFrame,
            auraInstance = auraInstance
        }

        frameToAuraData[wowFrame][stateKey] = frameEntry
    end

    local addAuraToGuid = function(guid, stateKey) 
        local wowFrames = getFramesForGuid(guid)

        for wowFrame, _ in pairs(wowFrames) do
            if (wowFrames[stateKey] == nil) then
                addAuraToFrame(wowFrame, stateKey)
            end
        end
    end

    ---@param guid string
    ---@param stateKey string
    self.AuraRemoved = function(guid, stateKey)
        self.GuidRefreshed(guid)
    end

    ---@param guid string
    ---@param stateKey string
    self.AuraUpdated = function(guid, stateKey)
        local frames = getFramesForGuid(guid)

        for wowFrame, _ in pairs(frames) do
            local aura = frameToAuraData[wowFrame][stateKey]

            if (aura ~= nil) then
                aura.auraFrame.UpdateCooldown()
            end
        end
    end

    ---@param guid string
    ---@param stateKey string
    self.AuraAdded = function(guid, stateKey)
        self.GuidRefreshed(guid)
    end

    ---@param unitGuid string
    ---@return boolean
    self.GuidRefreshed = function(unitGuid)
        local framesForGuid = getFramesForGuid(unitGuid)

        local hasUpdates = false
        local newKeys = context.GetKeysByGuid(unitGuid)

        for _, frame in pairs(framesForGuid) do
            local currentFrameKeys = frameToAuraData[frame]

            local diff = BuffWatcher_Shared.KeyDiff(currentFrameKeys, newKeys, objectPool)
         
            for removedKey, _ in pairs(diff.removed) do
                ---@cast removedKey string

                removeAuraFromFrame(frame, removedKey)

                hasUpdates = true
            end

            for newKey, _ in pairs(diff.added) do
                ---@cast newKey string

                addAuraToGuid(unitGuid, newKey)

                hasUpdates = true
            end

            BuffWatcher_Shared.ReleaseKeyDiff(diff, objectPool)
        end

        if hasUpdates then
            redrawAurasByGuid(unitGuid)
        end

        return hasUpdates
    end

    ---@param units table<string, boolean>
    ---@return table<string, BuffWatcher_GuidFrameData>
    local buildGuidsToFrames = function(units)
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
                        frameAuras = {},
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

    ---Compares two frame maps, returns true if equal
    ---@param one table<string, table<string, boolean>>
    ---@param two table<string, table<string, boolean>>
    ---@return boolean
    local compareFrameMaps = function(one, two)
        if (one == nil or two == nil) and (one ~= two) then
            return false
        end
        
        if BuffWatcher_Shared_Singleton.GetTableKeyCount(one) ~= BuffWatcher_Shared_Singleton.GetTableKeyCount(two) then
            return false
        end

        for unit, oneFrames in pairs(one) do
            if (two[unit] == nil) then
                return false
            end

            local twoFrames = two[unit]

            if BuffWatcher_Shared_Singleton.GetTableKeyCount(oneFrames) ~= BuffWatcher_Shared_Singleton.GetTableKeyCount(twoFrames) then
                return false
            end

            for frame, _ in pairs(oneFrames) do
                if twoFrames[frame] == nil then
                    return false
                end
            end
        end

        return true
    end

    self.FramesChanged = function()
        if (context.isNameplate()) then
            return
        end

        local units = context.GetPotentialUnits()

        local nextFrameMap = buildFrameMap(units)

        -- if frames have *actually* changed, because we get excessive events from LibGetFrame
        if not compareFrameMaps(nextFrameMap, lastFrameMap) then
            self.DoFullUpdate()
        end
    end

    self.DoFullUpdate = function()
        self.Clear()

        currentGuidsToFrames = buildGuidsToFrames(context.GetPotentialUnits())

        initializeFrameAuraData()

        for guid, _ in pairs(currentGuidsToFrames) do
            self.GuidRefreshed(guid)
        end
    end

    ---@param unit string
    self.NameplateUnitAdded = function(unit)
        local unitGuid = UnitGUID(unit)

        local newFrames = getTargetFrames(unit)

        currentGuidsToFrames[unitGuid] = {
            guid = unitGuid,
            frames = getTargetFrames(unit),
            unitName = UnitName(unit),
            units = {
                [unit] = unit
            }
        }

        for frame, _ in pairs(newFrames) do
            frameToAuraData[frame] = objectPool.GetObject()
        end

        self.GuidRefreshed(unitGuid)
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

        removeGuid(unitGuid)
    end

    return self;
end