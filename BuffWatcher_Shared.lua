BuffWatcher_Shared = {}

function BuffWatcher_Shared:new()
    self = {};

    self.SufPlayerFramePrefix = 'SUFHeaderpartyUnitButton';

    self.GetCastRecordKey = function(castRecord) 
        return castRecord.type .. ":" .. castRecord.spellId
    end

    self.GetStoredSpellKey = function(storedSpell) 
        return storedSpell.buffType .. ":" .. storedSpell.spellId
    end

    self.BuildSpellCastRecord = function(type, spellId, spellName, sourceName)
        local record = {
            type = type,
            spellId = spellId,
            loweredName = string.lower(spellName),
            sourceName = sourceName, 
            loweredCaster = string.lower(sourceName), 
            duration = 0
        }

        record.key = self.GetCastRecordKey(record)

        return record;
    end

    self.GetDefaultStoredSpell = function()
        return {
            spellId = 0,
            buffType = BuffWatcher_Shared_Singleton.SpellTypes.Any,
            version = 1,
            showInParty = true,
            showInArena = true,
            showInRaid = true,
            showOnNameplates = true, 
            showDispelTypeOutline = true,
            duration = 10,
            showGlow = false,
            sizeMultiplier = 1,
            priority = 5,
        }
    end

    self.StoredSpellFromCastRecord = function(spellRecord)
        local base = self.GetDefaultStoredSpell()

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

    self.CreateShallowCopy = function(src)
        local copy = {}

        for index, value in pairs(src) do
            if type(value) ~= "table" then
                copy[index] = value
            end
        end

        return copy
    end

    self.CopyKeys = function(src)
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

    self.FrameTypes = {
        Party = 1,
        Arena = 2,
        Raid = 3,
        Nameplate = 4
    }

    return self;
end

BuffWatcher_Shared_Singleton = BuffWatcher_Shared:new();