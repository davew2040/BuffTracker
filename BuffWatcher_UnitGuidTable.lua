---@class BuffWatcher_UnitGuidTable
BuffWatcher_UnitGuidTable = {}

function BuffWatcher_UnitGuidTable:new()
    self = {};

    ---@type table<string, string>
    local unitToGuid = {}

    ---@type table<string, table<string, boolean>>
    local guidToUnits = {}


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
            guidToUnits[guid] = {}
        end
        guidToUnits[guid][unit] = true
    end

    ---@param guid string
    ---@return table<string, boolean>
    self.GetUnitsByGuid = function(guid)
        if guidToUnits[guid] == nil then
            return {}
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

        unitToGuid[unit] = nil
        
        if (guidToUnits[guid] ~= nil) then
            guidToUnits[guid][unit] = nil

            if (BuffWatcher_Shared_Singleton.GetTableKeyCount(guidToUnits[guid]) == 0) then
                guidToUnits[guid] = nil
            end
        end
    end

    ---@param guid string
    self.UnlinkGuid = function(guid)
        local unit = guidToUnits[guid]

        guidToUnits[guid] = nil
        unitToGuid[unit] = nil
    end

    self.Reset = function()
        guidToUnits = {}
        unitToGuid = {}
    end

    ---@return table<string, boolean>
    self.GetAllGuids = function()
        return BuffWatcher_Shared_Singleton.TransformTable(
            guidToUnits, 
            function(key) return key end, 
            function(value) return true end
        )
    end

    return self;
end