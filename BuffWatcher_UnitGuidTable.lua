---@class BuffWatcher_UnitGuidTable
BuffWatcher_UnitGuidTable = {}

---@param objectPool BuffWatcher_MiscellaneousObjectPool
function BuffWatcher_UnitGuidTable:new(objectPool)
    self = {};

    ---@type table<string, string>
    local unitToGuid = nil

    ---@type table<string, table<string, boolean>>
    local guidToUnits = nil

    ---@param toRelease table<string, table<string, boolean>>
    local releaseGuidToUnits = function(toRelease)
        for k,_ in pairs(toRelease) do
            objectPool.ReleaseObject(toRelease[k])
        end

        objectPool.ReleaseObject(toRelease)
    end

    self.GetUnitsToGuid = function()
        return unitToGuid
    end

    self.GetGuidsToUnits = function()
        return guidToUnits
    end

    ---@param unit string
    ---@param guid string
    self.LinkUnitToGuid = function(unit, guid)
        unitToGuid[unit] = guid

        if (guidToUnits[guid] == nil) then
            guidToUnits[guid] = objectPool.GetObject()
        end

        guidToUnits[guid][unit] = true
    end

    ---@param guid string
    ---@return table<string, boolean>
    self.GetUnitsByGuid = function(guid)
        if guidToUnits[guid] == nil then
            return BuffWatcher_Shared.EmptyTable
        end

        return guidToUnits[guid]
    end
    
    ---@param unit string
    ---@return string
    self.GetGuidByUnit = function(unit)
        return unitToGuid[unit]
    end

    ---@param unit string
    self.UnlinkUnit = function(unit)
        local guid = unitToGuid[unit]

        -- if (guid == nil) then
        --     local message = "FIXME unlinking unit " .. unit
        --     if (guid == nil) then
        --         message = message .. " from nil guid"
        --     else
        --             message = message .. " from guid " .. guid
        --     end
        --     DevTool:AddData({ unitToGuid = CopyTable(unitToGuid), guidToUnits = CopyTable(guidToUnits) }, message)

        -- end

        unitToGuid[unit] = nil

        if (guidToUnits[guid] ~= nil) then
            guidToUnits[guid][unit] = nil

            if (BuffWatcher_Shared_Singleton.GetTableKeyCount(guidToUnits[guid]) == 0) then
                objectPool.ReleaseObject(guidToUnits[guid])
                guidToUnits[guid] = nil
            end
        end
    end

    self.Reset = function()
        if (guidToUnits ~= nil) then
            releaseGuidToUnits(guidToUnits)
        end
        
        if (unitToGuid ~= nil) then
            objectPool.ReleaseObject(unitToGuid)
        end

        guidToUnits = objectPool.GetObject()
        unitToGuid = objectPool.GetObject()
    end

    self.Release = function()
        objectPool.ReleaseObject(guidToUnits)
        objectPool.ReleaseObject(unitToGuid)
    end

    self.Reset()

    return self;
end