---@class BuffWatcher_UnitGuidTable
BuffWatcher_UnitGuidTable = {}

function BuffWatcher_UnitGuidTable:new()
    self = {};

    ---@type table<string, string>
    local unitToGuid = {}

    ---@type table<string, string>
    local guidToUnit = {}


    self.GetUnitsToGuid = function()
        return unitToGuid
    end

    self.GetGuidsToUnits = function()
        return guidToUnit
    end

    ---@param unit string
    ---@param guid string
    self.LinkUnitToGuid = function(unit, guid)
        unitToGuid[unit] = guid
        guidToUnit[guid] = unit
    end

    ---@param guid string
    ---@return string
    self.GetUnitByGuid = function(guid)
        return guidToUnit[guid]
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
        guidToUnit[guid] = nil
    end

    ---@param guid string
    self.UnlinkGuid = function(guid)
        local unit = guidToUnit[guid]

        guidToUnit[guid] = nil
        unitToGuid[unit] = nil
    end

    self.Reset = function()
        guidToUnit = {}
        unitToGuid = {}
    end

    ---@return table<string, boolean>
    self.GetAllGuids = function()
        return BuffWatcher_Shared_Singleton.TransformTable(
            guidToUnit, 
            function(key) return key end, 
            function(value) return true end
        )
    end

    return self;
end