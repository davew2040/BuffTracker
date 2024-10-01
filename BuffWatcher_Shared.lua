
---@class BuffWatcher_Shared
BuffWatcher_Shared = {}

function BuffWatcher_Shared:new()
    self = {};

    self.SufPartyFramePrefix = 'SUFHeaderpartyUnitButton';
    self.SufRaidFramePrefix = 'SUFHeaderraidUnitButton';

    ---@type table<integer, string>
    self.partyUnitsByIndex = {}
    ---@type table<integer, string>
    self.raidUnitsByIndex = {}
    ---@type table<integer, string>
    self.arenaUnitsByIndex = {}
    ---@type table<integer, string>
    self.nameplateUnitsByIndex = {}

    ---@type table<string, boolean>
    self.partyUnits = {}
    ---@type table<string, boolean>
    self.raidUnits = {}
    ---@type table<string, boolean>
    self.arenaUnits = {}
    ---@type table<string, boolean>
    self.nameplateUnits = {}


    ---@param castRecord BuffWatcher_CastRecord
    ---@return string
    self.GetCastRecordKey = function(castRecord) 
        return castRecord.type .. ":" .. castRecord.spellId
    end

    ---@param spellRecord BuffWatcher_CastRecord
    ---@return BuffWatcher_StoredSpell
    self.StoredSpellFromCastRecord = function(spellRecord)
        local base = BuffWatcher_Shared.GetDefaultStoredSpell()

        base.buffType = spellRecord.type
        base.spellId = spellRecord.spellId

        return base
    end

    self.IsPartyUnit = function(unitName) 
        return self.partyUnits[unitName] ~= nil
    end

    self.IsRaidUnit = function(unitName) 
        return self.raidUnits[unitName] ~= nil
    end

    self.IsArenaUnit = function(unitName) 
        return self.arenaUnits[unitName] ~= nil
    end

    ---@param unitName string
    ---@return boolean
    self.IsNameplateUnit = function(unitName) 
        return self.nameplateUnits[unitName] ~= nil
    end

    self.IsPartyOrRaidUnit = function(unitName) 
        return self.IsRaidUnit(unitName) or self.IsPartyUnit(unitName)
    end

    self.NormalizeUnit = function(unitName)
        if (unitName == 'player') then
            if (IsInGroup() or IsInRaid()) then
                return self.FindPlayerUnit()
            end
        end

        return unitName
    end

    self.FindPlayerUnit = function()
        if (IsInGroup() and GetNumGroupMembers() == 1) then
            return 'party1'
        elseif (IsInRaid() and GetNumGroupMembers() == 1) then
            return 'raid1'
        end

        if (IsInGroup()) then
            for i = 1, GetNumGroupMembers() do
                local partyUnit = 'party' .. i
                if UnitIsPlayer(partyUnit) then
                    return partyUnit
                end
            end
        end

        if (IsInRaid()) then
            for i = 1, GetNumGroupMembers() do
                local partyUnit = 'raid' .. i
                if UnitIsPlayer(partyUnit) then
                    return partyUnit
                end
            end
        end

        return 'player'
    end

    self.SimpleTableMerge = function(t1, t2)
        local merged = {}

        for k,v in pairs(t1) do
            merged[k] = v
        end

        for k,v in pairs(t2) do
            if (merged[k] == nil) then
                merged[k] = v
            end
        end

        return merged
    end

    ---@param destination table
    ---@param toMerge table
    self.MergeIntoOrderedTable = function(destination, toMerge)
        for _,v in pairs(toMerge) do
            table.insert(destination, v)
        end
    end

    self.GetButton = function(parent, unpressedTexture, pressedTexture)
        local button = CreateFrame("Button", "random button title", parent)
    
        local ntex = button:CreateTexture()
        ntex:SetTexture(unpressedTexture)
        ntex:SetAllPoints()	
        button:SetNormalTexture(ntex)
        
        local ptex = button:CreateTexture()
        ptex:SetTexture(pressedTexture)
        ptex:SetAllPoints()
        button:SetPushedTexture(ptex)
        
        return button;
    end

    self.Select = function(source, fn)
        local mapped = {}

        for k,v in source do
            mapped[k] = fn(v)
        end

        return mapped
    end

    self.GetTableKeyCount = function(table)
        local count = 0
        for _ in pairs(table) do count = count + 1 end
        return count
    end

    self.UnitNameMatchesFrameType = function(unitName, frameType)
        if (self.IsNameplateUnit(unitName) and frameType == self.FrameTypes.Nameplate) then
            return true
        elseif (self.IsPartyUnit(unitName) and frameType == self.FrameTypes.Party) then
            return true
        elseif (self.IsArenaUnit(unitName) and frameType == self.FrameTypes.Arena) then
            return true
        elseif (self.IsRaidUnit(unitName) and frameType == self.FrameTypes.Raid) then 
            return true
        end

        return false
    end

    self.GetAuraIndexByPriority = function(priority)
        return 11-(priority or 10)
    end

    self.TableKeyFilter = function(table, filterFn)
        local dest = {}

        for k,v in pairs(table) do
            if (filterFn(k)) then
                dest[k] = v
            end
        end

        return dest
    end

    ---@generic T, U
    ---@param table table<T,U>
    ---@param filterFn fun(input: T): boolean
    ---@return table<T, U>
    self.TableValueFilter = function(table, filterFn)
        ---@table<T, U>
        local dest = {}

        for k,v in pairs(table) do
            if (filterFn(v)) then
                dest[k] = v
            end
        end

        return dest
    end

    self.TableIPairsValueFilter = function(source, filterFn)
        local dest = {}

        for k,v in ipairs(source) do
            if (filterFn(v)) then
                tinsert(dest, v)
            end
        end

        return dest
    end

    self.TransformTable = function(t, keyFn, valueFn)
        local dest = {}

        for k,v in pairs(t) do
            dest[keyFn(k,v)] = valueFn(k,v)
        end

        return dest
    end

    self.ValidateObjectCopy = function(source, copy)
        for k,v in pairs(source) do
            if (copy[k] == nil) then
                error("Missing object key ".. k)
            end

            if (type(source[k]) ~= type(copy[k])) then
                local sourceTypeString = tostring(type(source[k]))
                local copyTypeString  tostring(type(copy[k]))
                error("Type mismatch on key " .. k .. " source = " .. sourceTypeString .. " copy = " .. copyTypeString)
            end

            if (type(source[k]) == "table") then
                self.ValidateObjectCopy(source[k], copy[k])
            end
        end

        return true
    end

    self.SetBackgroundColor = function(frame, r, g, b, a)
        Mixin(frame, BackdropTemplateMixin)

        local backdropInfo =
        {
            bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
            edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
            tile = true,
            tileEdge = true,
            tileSize = 8,
            edgeSize = 8,
            insets = { left = 1, right = 1, top = 1, bottom = 1 },
        }

        frame:SetBackdrop(backdropInfo)
        frame:SetBackdropColor(r, g, b, a)
    end

    ---@enum SpellTypes
    self.SpellTypes = {
        Any = 1,
        Cast = 2,
        Buff = 3,
        Debuff = 4
    }

    self.SpellTypeLabels = {
        [self.SpellTypes.Any] = "Any",
        [self.SpellTypes.Cast] = "Cast",
        [self.SpellTypes.Buff] = "Buff",
        [self.SpellTypes.Debuff] = "Debuff"
    }

    ---@enum FrameTypes
    self.FrameTypes = {
        Party = 1,
        Arena = 2,
        Raid = 3,
        Nameplate = 4,
        Battleground = 5
    }

    local initialize = function()
        for i=1, 20 do
            self.partyUnitsByIndex[i] = "party" .. i
            self.partyUnits["party" .. i] = true
        end

        for i=1, 40 do
            self.raidUnitsByIndex[i] = "raid" .. i
            self.raidUnits["raid" .. i] = true
        end

        for i=1, 25 do
            self.arenaUnitsByIndex[i] = "arena" .. i
            self.arenaUnits["arena" .. i] = true
        end

        for i=1, 40 do
            self.nameplateUnitsByIndex[i] = "nameplate" .. i
            self.nameplateUnits["nameplate" .. i] = true
        end
    end

    initialize()

    return self;
end

---@generic T 
---@generic U 
---@param source table<T,U>
---@return table<T, U> 
function BuffWatcher_Shared:CopyTable(source)
    return CopyTable(source)
end

--- Attempts to push values from a table into a target table, if possible
---@param target table<any,any>
---@param patcher table<any,any>
BuffWatcher_Shared.PatchTable = function(target, patcher)
    for k,v in pairs(target) do
        if (patcher[k] ~= nil and type(target[k]) == type(patcher[k])) then
            target[k] = patcher[k]
        end
    end
end

---@return BuffWatcher_StoredSpell
function BuffWatcher_Shared.GetDefaultStoredSpell()
    ---@type BuffWatcher_StoredSpell
    local default = {
        spellId = 0,
        buffType = BuffWatcher_Shared_Singleton.SpellTypes.Any,
        version = 1,
        hide = false,
        showInParty = true,
        showInArena = true,
        showInRaid = true,
        showOnNameplates = true, 
        showDispelTypeOutline = true,
        duration = 10,
        isMinorAura = false,
        showGlow = false,
        sizeMultiplier = 1,
        priority = 5,
        ownOnly = false,
        showInBattlegrounds = false
    }
    return default
end

---@generic T, U
---@param source table<any, T>
---@param sortPicker fun(input: T): U
function BuffWatcher_Shared.SortBy(source, sortPicker)
    table.sort(source, function(a, b)
        return sortPicker(a) < sortPicker(b)
    end
    )
end

---@generic T, U
---@param source table<T, any>
---@param sortPicker fun(input: T): U
---@return table<integer, T>
function BuffWatcher_Shared.OrderKeysBy(source, sortPicker)
    local copy = {}

    for k,_ in pairs(source) do
        table.insert(copy, k)
    end

    table.sort(
        copy, 
        function(a, b)
            return sortPicker(a) < sortPicker(b)
        end
    )

    return copy
end


---@generic T, U
---@param source table<T, any>
---@param sortPicker fun(input: T): U
---@return table<any, T>
function BuffWatcher_Shared.OrderValuesBy(source, sortPicker)

    local copy = {}

    for _,v in pairs(source) do
        table.insert(copy, v)
    end

    table.sort(
        copy, 
        function(a, b)
            return sortPicker(a) < sortPicker(b)
        end
    )

    return copy
end


---@generic T, U
---@param source table<T, any>
---@param sortPicker fun(input: T): U
---@return any
function BuffWatcher_Shared.OrderKeysByDescending(source, sortPicker)
    local copy = {}

    for k,_ in pairs(source) do
        table.insert(copy, k)
    end

    table.sort(
        copy, 
        function(a, b)
            return sortPicker(a) > sortPicker(b)
        end
    )

    return copy
end


---@generic T, U
---@param source table<T, any>
---@param destination table<T, any>
---@param sortPicker fun(input: T): U
---@return any
function BuffWatcher_Shared.OrderValuesByDescending(source, destination, sortPicker)

    for _,v in pairs(source) do
        table.insert(destination, v)
    end

    table.sort(
        destination, 
        function(a, b)
            return sortPicker(a) > sortPicker(b)
        end
    )
end

---@generic T, U
---@param source table<any, T>
---@param sortPicker fun(input: T): U
function BuffWatcher_Shared.SortByDescending(source, sortPicker)
    table.sort(source,
        function(a, b)
            return sortPicker(a) > sortPicker(b)
        end
    )
end


---@generic T, U
---@param source table<any, T>
---@param sortPicker fun(input: T): U
---@return table<any, T>
function BuffWatcher_Shared.OrderByDescending(source, sortPicker)
    local copy = CopyTable(source)

    table.sort(source, function(a, b)
        return sortPicker(a) > sortPicker(b)
    end
    )

    return copy
end

---@return boolean
function BuffWatcher_Shared.PlayerInBattleground()
    local result = C_PvP.IsBattleground()
    local isBattleground = result ~= nil and result == true

    if isBattleground then
        return true
    end

    local brawlActive = C_PvP.IsInBrawl()
    
    if brawlActive then 
        return true
    end

    return false
end

---@return boolean
function BuffWatcher_Shared.PlayerInArena()
    local _, instanceType = GetInstanceInfo()

    return instanceType == "arena"
end

---@return table<string, string>
function BuffWatcher_Shared.GetGroupUnits()
    ---@type table<string, string>
    local result = {}

    if GetNumGroupMembers() == 0 then
        return result
    end

    local playerGuid = UnitGUID('player')
    DevTool:AddData(playerGuid, "fixme playerGuid")

    result['player'] = playerGuid

    for i=1, GetNumGroupMembers() do
        if IsInRaid() then
            local raidUnit = BuffWatcher_Shared_Singleton.raidUnitsByIndex[i]
            local raidUnitGuid = UnitGUID(raidUnit)
            if (raidUnitGuid ~= nil and raidUnitGuid ~= playerGuid) then
                result[raidUnit] = raidUnitGuid 
            end
        elseif IsInGroup() then
            local partyUnit = BuffWatcher_Shared_Singleton.partyUnitsByIndex[i]
            local partyUnitGuid = UnitGUID(partyUnit)
            if (partyUnitGuid ~= nil and partyUnitGuid ~= playerGuid) then
                result[partyUnit] = partyUnitGuid 
            end
        end
    end

    return result
end

---@param table table
---@return boolean
function BuffWatcher_Shared.TableHasKeys(table)
    for _ in pairs(table) do
        return true
    end
    return false
end

---@generic T, U
---@param t table<T, U>
---@return T
function BuffWatcher_Shared.FirstKeyOrDefault(t)
    for k,_ in pairs(t) do
        return k
    end

    return nil
end

---@param guid string
---@return boolean
function BuffWatcher_Shared.GuidIsNpc(guid)
    local prefix = guid:sub(1,8);
    return prefix == "Creature"
end

---@param unitName string
---@return boolean
function BuffWatcher_Shared.UnitIsFriendly(unitName)
    return UnitIsFriend('player', unitName)
end

---@param unit string
---@return boolean
function BuffWatcher_Shared.UnitIsMinor(unit)
    if (unit ~= nil) then
        local classification = UnitClassification(unit)
        if (classification == "minus" or classification == "trivial") then
            return true
        end
    end

    return false
end

function BuffWatcher_Shared.IsUnitInSameZone(unit)
    local playerZone = C_Map.GetBestMapForUnit("player")
    local unitZone = C_Map.GetBestMapForUnit(unit)

    if playerZone and unitZone and playerZone == unitZone then
        return true
    else
        return false
    end
end


---@param map table<string, string>
---@return table<string, string>
function BuffWatcher_Shared.InvertStringMap(map)
    ---@type table<string, string>
    local inverted = {}

    for k,v in pairs(map) do
        inverted[v] = k
    end

    return inverted
end

-- Would be awfully nice if I could get generic type annotations working for this
---@generic T, U
---@param old table<T, U>
---@param new table<T, U>
---@param objectPool BuffWatcher_MiscellaneousObjectPool
---@return BuffWatcher_KeyDiffResult --- object pool object
BuffWatcher_Shared.KeyDiff = function(old, new, objectPool)
    ---@type BuffWatcher_KeyDiffResult
    local diff = objectPool.GetObject()
    diff.added = objectPool.GetObject()
    diff.removed = objectPool.GetObject()

    for newKey,v in pairs(new) do
        if (old[newKey] == nil) then
            diff.added[newKey] = v
        end
    end

    for oldKey,v in pairs(old) do
        if (new[oldKey] == nil) then
            diff.removed[oldKey] = v
        end
    end

    return diff
end

-- Would be awfully nice if I could get generic type annotations working for this
---@generic T, U
---@param keyDiff BuffWatcher_KeyDiffResult
---@param objectPool BuffWatcher_MiscellaneousObjectPool
BuffWatcher_Shared.ReleaseKeyDiff = function(keyDiff, objectPool)
    objectPool.ReleaseObject(keyDiff.added)
    objectPool.ReleaseObject(keyDiff.removed)

    objectPool.ReleaseObject(keyDiff)
end


---@param t table
---@return boolean
BuffWatcher_Shared.Any = function(t)
    for _ in pairs(t) do
        return true
    end
    
    return false
end

---@type table<BuffWatcher_TriggerType, string>
BuffWatcher_Shared.TriggerTypeLabels = {
    [BuffWatcher_TriggerType.Buff] = "Buffs",
    [BuffWatcher_TriggerType.Debuff] = "Debuffs",
    [BuffWatcher_TriggerType.Cast] = "Casts",
    [BuffWatcher_TriggerType.CatchAll] = "Catch All",
}

BuffWatcher_Shared.Benchmark = function(func, iterations, ...)
    iterations = iterations or 1000  -- Default to 1000 iterations if not specified
    local start_time_milliseconds = debugprofilestop()
    
    collectgarbage("collect")

    local memBefore = collectgarbage("count")

    for i = 1, iterations do
        func(...)
    end

    local end_time_milliseconds = debugprofilestop()
    local total_time_millisecconds = end_time_milliseconds - start_time_milliseconds
    local average_time = total_time_millisecconds / iterations
    
    local memAfter = collectgarbage("count")
    local memUsed = memAfter - memBefore

    print(string.format("Total time for %d iterations: %.6f milliseconds", iterations, total_time_millisecconds))
    print(string.format("Average time per iteration: %.6f milliseconds", average_time))
    print(string.format("Memory usage: %d bytes", memUsed))

    return average_time
end

---Computers distance between players, or nil if a comparison is not possible
---@param unit1 string
---@param unit2 string
---@return boolean
BuffWatcher_Shared.ComputeDistance = function(unit1, unit2)
    DevTool:AddData({unit1 = unit1, unit2 = unit2}, "starting")
    local y1, x1, _, instance1 = UnitPosition(unit1)

    DevTool:AddData({x1 = x1, y1 = y1, instance1 = instance1 }, "unit1")

    local y2, x2, _, instance2 = UnitPosition(unit2)

    DevTool:AddData({x2 = x2, y2 = y2, instance2 = instance2 }, "unit2")

    local result = instance1 == instance2 and ((x2 - x1) ^ 2 + (y2 - y1) ^ 2) ^ 0.5
    DevTool:AddData({unit1 = unit1, unit2 = unit2}, "ending")
    return result
end

---@param t table
BuffWatcher_Shared.ResetTable = function(t)
    for k in pairs(t) do
        t[k] = nil
    end
end

---@param target table
---@param source table
BuffWatcher_Shared.CopyTableValues = function(target, source)
    for k,v in pairs(source) do
        target[k] = v
    end
end

---comment Inserts keys into a target table where a predicate is true
---@param target table
---@param source table
---@param filterFn any
---@return nil
BuffWatcher_Shared.InsertKeysWhere = function(target, source, filterFn)
    for k,v in pairs(source) do
        if (filterFn(k)) then
            target[k] = v
        end
    end
end

---@generic T, U
---@param src table<T, U> 
---@param dest table<T, U> 
---@return table<T, boolean>
BuffWatcher_Shared.CopyKeysInto = function(src, dest)
    for key, _ in pairs(src) do
        dest[key] = true
    end

    return dest
end

BuffWatcher_Shared.CompareValues = function(one, two)
    local t1 = type(one)
    local t2 = type(two)

    if t1 ~= t2 then
        return false
    end

    if t1 == "table" then
        -- Check if both are tables and recursively compare their contents
        for k1, v1 in pairs(one) do
            if not BuffWatcher_Shared.CompareValues(v1, two[k1]) then
                return false
            end
        end

        for k2, v2 in pairs(two) do
            if not BuffWatcher_Shared.CompareValues(one[k2], v2) then
                return false
            end
        end

        return true
    else
        -- For non-table values, simply compare them directly
        return one == two
    end
end

--- Fills missing values with a provided set of default values
---@param target table<any,any>
---@param defaultValues table<any,any>
BuffWatcher_Shared.FillMissingValues = function(target, defaultValues)
    local copy = CopyTable(target)

    for defaultKey, defaultValue in pairs(defaultValues) do
        if (copy[defaultKey] == nil) then
            copy[defaultKey] = defaultValue
        end
    end

    return copy
end


---@type table
BuffWatcher_Shared.EmptyTable = {}

BuffWatcher_Shared_Singleton = BuffWatcher_Shared:new();