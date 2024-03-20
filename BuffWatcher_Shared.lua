
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
        if (IsInGroup()) then
            return string.find(unitName, 'party') == 1
        elseif (IsInRaid()) then
            return string.find(unitName, 'raid') == 1
        end

        return false
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

    ---@generic T, U
    ---@param src table<T, U> 
    ---@return table<T, boolean>
    self.CopyKeys = function(src)
        ---@generic T 
        ---@type table<T, boolean>
        local copiedKeys = {}

        for key, _ in pairs(src) do
            copiedKeys[key] = true
        end

        return copiedKeys
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


---@param target table<any,any>
---@param patcher table<any,any>
function BuffWatcher_Shared:PatchTable(target, patcher)
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
---@param sortPicker fun(input: T): U
---@return any
function BuffWatcher_Shared.OrderValuesByDescending(source, sortPicker)

    local copy = {}

    for _,v in pairs(source) do
        table.insert(copy, v)
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

    return isBattleground
end

---@return boolean
function BuffWatcher_Shared.PlayerInArena()
    local _, instanceType = GetInstanceInfo()

    return instanceType == "arena"
end

---@return BuffWatcher_Blizzard_AuraData[]
function BuffWatcher_Shared.GetUnitAuras(unitName)
    ---@type BuffWatcher_Blizzard_AuraData[]
    local result = {}

    local i = 1
    while true do
        local unitAuraData = {UnitBuff(unitName, i)}

        DevTool:AddData(unitAuraData, "fixme unitAuraData")

        if (#unitAuraData == 0) then
            break
        end
        
        ---@type BuffWatcher_Blizzard_AuraData
        local newUnitAura = {
            name = unitAuraData[1],
            auraInstanceID = 0,
            isHelpful = true,
            isHarmful = false,
            icon = unitAuraData[2],
            count = unitAuraData[3],
            duration = unitAuraData[5],
            expirationTime = unitAuraData[6],
            sourceUnit = unitAuraData[7],
            spellId = unitAuraData[10]
        }

        table.insert(result, newUnitAura)
        i = i+1
    end

    i=1
    while true do
        local unitAuraData = {UnitDebuff(unitName, i)}

        if (#unitAuraData == 0) then
            break
        end
        
        ---@type BuffWatcher_Blizzard_AuraData
        local newUnitAura = {
            name = unitAuraData[1],
            auraInstanceID = 0,
            isHelpful = false,
            isHarmful = true,
            icon = unitAuraData[2],
            count = unitAuraData[3],
            duration = unitAuraData[5],
            expirationTime = unitAuraData[6],
            sourceUnit = unitAuraData[7],
            spellId = unitAuraData[10]
        }

        table.insert(result, newUnitAura)
        i = i+1
    end

    return result
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

---@param oldLinkage BuffWatcher_UnitToGuidLinkage
---@param newLinkage BuffWatcher_UnitToGuidLinkage
---@return BuffWatcher_UnitsComparisonResult
function BuffWatcher_Shared.CompareUnitToGuidMaps(oldLinkage, newLinkage)
    ---@type string[]
    local added = {}
    ---@type string[]
    local removed = {}
    ---@type table<string, string>
    local changed = {}

    for newUnit,_ in pairs(newLinkage.unitToGuid) do
        if (oldLinkage.unitToGuid[newUnit] == nil) then
            table.insert(added, newUnit)
        elseif (oldLinkage.unitToGuid[newUnit] ~= newLinkage.unitToGuid[newUnit]) then
            local targetGuid = newLinkage.unitToGuid[newUnit]
            local oldUnit = oldLinkage.guidToUnit[targetGuid]
            changed[newUnit] = oldUnit
        end
    end

    for oldUnit,_ in pairs(oldLinkage.unitToGuid) do
        if (newLinkage.unitToGuid[oldUnit] == nil) then
            table.insert(removed, oldUnit)
        end
    end

    ---@type BuffWatcher_UnitsComparisonResult
    local result = {
        addedUnits = added,
        removedUnits = removed,
        changedUnits = changed
    }

    return result
end

-- Would be awfully nice if I could get generic type annotations working for this
---@generic T, U
---@param old table<T, U>
---@param new table<T, U>
---@return BuffWatcher_KeyDiffResult
BuffWatcher_Shared.KeyDiff = function(old, new)
    ---@type BuffWatcher_KeyDiffResult
    local diff = {
        added = {},
        removed = {},
        unchanged = {}
    }

    for newKey,v in pairs(new) do
        if (old[newKey] == nil) then
            diff.added[newKey] = v
        else
            diff.unchanged[newKey] = {
                old = old[newKey],
                new = new[newKey]
            }
        end
    end

    for oldKey,v in pairs(old) do
        if (new[oldKey] == nil) then
            diff.removed[oldKey] = v
        end
    end

    return diff
end

---@type table<BuffWatcher_TriggerType, string>
BuffWatcher_Shared.TriggerTypeLabels = {
    [BuffWatcher_TriggerType.Buff] = "Buffs",
    [BuffWatcher_TriggerType.Debuff] = "Debuffs",
    [BuffWatcher_TriggerType.Cast] = "Casts",
    [BuffWatcher_TriggerType.CatchAll] = "Catch All",
}

BuffWatcher_Shared_Singleton = BuffWatcher_Shared:new();