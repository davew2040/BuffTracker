
---@class BuffWatcher_Shared
BuffWatcher_Shared = {}

function BuffWatcher_Shared:new()
    self = {};

    self.SufPlayerFramePrefix = 'SUFHeaderpartyUnitButton';

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
        return string.find(unitName, 'party') == 1
    end

    self.IsRaidUnit = function(unitName) 
        return string.find(unitName, 'raid') == 1
    end

    self.IsArenaUnit = function(unitName) 
        return string.find(unitName, 'arena') == 1
    end

    self.IsNameplateUnit = function(unitName) 
        return string.find(unitName, 'nameplate') == 1
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

    ---@generic T 
    ---@generic U
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

    self.TableValueFilter = function(table, filterFn)
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

    self.TransformTable = function(table, keyFn, valueFn)
        local dest = {}

        for k,v in pairs(table) do
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
        Nameplate = 4
    }

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
        ownOnly = false
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
---@param source table<any, T>
---@param sortPicker fun(input: T): U
function BuffWatcher_Shared.SortByDescending(source, sortPicker)
    table.sort(source,
        function(a, b)
            return sortPicker(a) > sortPicker(b)
        end
    )
end


BuffWatcher_Shared_Singleton = BuffWatcher_Shared:new();