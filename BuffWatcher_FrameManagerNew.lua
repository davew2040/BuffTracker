local LGF = LibStub("LibGetFrame-1.0")

---@class BuffWatcher_AuraFrameData
---@field stateKey string
---@field auraFrame BuffWatcher_AuraFrame
---@field auraInstance BuffWatcher_AuraInstance
BuffWatcher_FrameData = {}

---@class BuffWatcher_GuidFrameData
---@field guid string
---@field unitName string
---@field framesWithAuras table<BuffWatcher_Blizzard_Frame, table<string, BuffWatcher_AuraFrameData>>
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

    -- -- maps frames to state keys to aura frame information
    -- ---@type table<BuffWatcher_Blizzard_Frame, table<string, BuffWatcher_FrameData>>
    -- local frameToAuraData = {}

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

    ---@param frameData BuffWatcher_AuraFrameData
    local framePrioritizer = function(frameData)
        return frameData.auraInstance.priority
    end

    ---@param auras table<string, BuffWatcher_AuraFrameData>
    local redrawAuras = function(auras)
        ---@type table<integer, BuffWatcher_AuraFrameData>
        local orderedAuras = objectPool.GetObject()

        BuffWatcher_Shared.OrderValuesByDescending(
            auras, 
            orderedAuras,
            framePrioritizer
        )

        local x = 0
        for _, auraInfo in ipairs(orderedAuras) do
            auraInfo.auraFrame.SetOffsets(x, 0)

            if (context.GetGrowthDirection() == BuffWatcher_GrowDirection.Left) then
                x = x - auraInfo.auraFrame.GetWidth() - configuration.GetAuraSpacing()
            else 
                x = x + auraInfo.auraFrame.GetWidth() + configuration.GetAuraSpacing()
            end
        end

        objectPool.ReleaseObject(orderedAuras)
    end

    ---@param guid string
    ---@return nil
    local redrawAurasByGuid = function(guid) 
        local frames = currentGuidsToFrames[guid].framesWithAuras

        for frame, auras in pairs(frames) do
            redrawAuras(auras)
        end
    end

    -- fixme - remove when done debugging
    -- local initializeFrameAuraData = function()
    --     for guid, frameData in pairs(currentGuidsToFrames) do
    --         for frame, _ in pairs(frameData.frames) do
    --             frameToAuraData[frame] = objectPool.GetObject()
    --         end
    --     end
    -- end


    ---@param targetUnit string
    ---@return table<BuffWatcher_Blizzard_Frame, BuffWatcher_Blizzard_Frame>
    local getTargetFrames = function(targetUnit)
        ---@type table<BuffWatcher_Blizzard_Frame, BuffWatcher_Blizzard_Frame>
        local result = objectPool.GetObject()

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

                objectPool.ReleaseObject(frames)
            end
        end

        return result
    end

    ---@param guidFrameData BuffWatcher_GuidFrameData
    local releaseGuidFrameData = function(guidFrameData)
        for blizzardFrame, auras in pairs(guidFrameData.framesWithAuras) do
            for auraKey, auraInfo in pairs(auras) do
                context.ReleaseAuraFrame(auraInfo.auraFrame)
            end

            objectPool.ReleaseObject(auras)
        end

        objectPool.ReleaseObject(guidFrameData)
    end

    local removeGuid = function(guid)
        releaseGuidFrameData(currentGuidsToFrames[guid])
        
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
        local guidsOnly = objectPool.GetObject()

        BuffWatcher_Shared.CopyKeysInto(currentGuidsToFrames, guidsOnly)

        for guid, _ in pairs(guidsOnly) do
            removeGuid(guid)
        end

        if (lastFrameMap ~= nil) then
            releaseFrameMap(lastFrameMap)
        end

        objectPool.ReleaseObject(guidsOnly)

        lastFrameMap = nil
    end

    ---comment
    ---@param frameAuras table<string, BuffWatcher_AuraFrameData>
    ---@param stateKey string
    local removeAuraFromFrame = function(frameAuras, stateKey)
        local frameToRemove = frameAuras[stateKey]
            
        context.ReleaseAuraFrame(frameToRemove.auraFrame)
        frameAuras[stateKey] = nil
    end

    ---comment
    ---@param stateKey string
    ---@param wowFrame BuffWatcher_Blizzard_Frame
    ---@param frameAuras table<string, BuffWatcher_AuraFrameData>
    local addAuraToFrame = function(stateKey, wowFrame, frameAuras) 
        local auraInstance = context.GetAuraInstanceByKey(stateKey)
        local auraFrame = context.GetSingleAuraFrame(auraInstance, wowFrame)
        
        ---@type BuffWatcher_AuraFrameData
        local frameEntry = {
            stateKey = stateKey,
            auraFrame = auraFrame,
            auraInstance = auraInstance
        }

        frameAuras[stateKey] = frameEntry
    end

    local addAuraToGuid = function(guid, stateKey) 
        for wowFrame, auras in pairs(currentGuidsToFrames[guid].framesWithAuras) do
            if (auras[stateKey] == nil) then
                addAuraToFrame(stateKey, wowFrame, auras)
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

        if (currentGuidsToFrames[guid] == nil) then
            DevTool:AddData("fixme attempted to add aura on missing guid " .. guid)
            return
        end

        local framesWithAuras = currentGuidsToFrames[guid].framesWithAuras

        for wowFrame, auras in pairs(framesWithAuras) do
            local aura = auras[stateKey]

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
        local guidFrameInfo = currentGuidsToFrames[unitGuid]

        if (guidFrameInfo == nil) then
            DevTool:AddData("fixme attempted to refresh auras on missing guid " .. unitGuid)
            return false
        end

        local hasUpdates = false
        local newKeys = context.GetKeysByGuid(unitGuid)

        for wowFrame, currentFrameAuras in pairs(guidFrameInfo.framesWithAuras) do
            local diff = BuffWatcher_Shared.KeyDiff(currentFrameAuras, newKeys, objectPool)
         
            for removedKey, _ in pairs(diff.removed) do
                ---@cast removedKey string

                removeAuraFromFrame(currentFrameAuras, removedKey)

                hasUpdates = true
            end

            for newKey, _ in pairs(diff.added) do
                ---@cast newKey string

                addAuraToFrame(newKey, wowFrame, currentFrameAuras)

                hasUpdates = true
            end

            BuffWatcher_Shared.ReleaseKeyDiff(diff, objectPool)
        end

        if hasUpdates then
            redrawAurasByGuid(unitGuid)
        end

        return hasUpdates
    end

    ---@param unit string
    ---@param unitGuid string
    ---@return BuffWatcher_GuidFrameData
    local getNewFrameEntry = function(unit, unitGuid)
        local frames = getTargetFrames(unit)

        ---@type table<BuffWatcher_Blizzard_Frame, table<string, BuffWatcher_AuraFrameData>>
        local framesWithAuras = objectPool.GetObject()
        
        for frame, _ in pairs(frames) do
            framesWithAuras[frame] = objectPool.GetObject()
        end

        objectPool.ReleaseObject(frames)

        ---@type BuffWatcher_GuidFrameData
        local newEntry = objectPool.GetObject()
        
        newEntry.guid = unitGuid
        newEntry.unitName = UnitName(unit)
        newEntry.framesWithAuras = framesWithAuras
        newEntry.units = {
            [unit] = unit
        }

        return newEntry
    end

    ---@param units table<string, boolean>
    ---@return table<string, BuffWatcher_GuidFrameData>
    local buildGuidsToFrames = function(units)
        ---@type table<string, BuffWatcher_GuidFrameData>
        local result = {}

        for unit, _ in pairs(units) do
            if (UnitExists(unit)) then
                local unitGuid = UnitGUID(unit)

                if (unitGuid == nil) then 
                    DevTool:AddData("fixme encountered nil unit guid in buildGuidsToFrames for unit " .. unit .. " with unit name " .. UnitName(unit))
                else 

                    if (result[unitGuid] == nil) then
                        local newEntry = getNewFrameEntry(unit, unitGuid)

                        result[unitGuid] = newEntry
                    else
                        result[unitGuid].units[unit] = unit
                    end
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

        lastFrameMap = buildFrameMap(context.GetPotentialUnits())

        currentGuidsToFrames = buildGuidsToFrames(context.GetPotentialUnits())

        for guid, _ in pairs(currentGuidsToFrames) do
            self.GuidRefreshed(guid)
        end
    end

    ---@param unit string
    self.NameplateUnitAdded = function(unit)
        local unitGuid = UnitGUID(unit)

        if (currentGuidsToFrames[unitGuid] ~= nil) then
            DevTool:AddData("fixme in FrameManager NameplateUnitAdded discovered existing unit ".. unit .. " for unit name " .. UnitName(unit))
        end

        currentGuidsToFrames[unitGuid] = getNewFrameEntry(unit, unitGuid)

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