DaveTest_Shared = {}

function DaveTest_Shared:new()
    self = {};

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

    self.GetDefaultStoredSpell = function(spellRecord)
        return {
            spellId = 0,
            buffType = DaveTest_Shared_Singleton.SpellTypes.Any,
            version = 1,
            showInParty = true,
            showInArena = true,
            showInRaid = true,
            showOnNameplates = true, 
            duration = 0,
            showGlow = false,
            sizeMultiplier = 1,
        }
    end

    self.StoredSpellFromCastRecord = function(spellRecord)
        return {
            spellId = spellRecord.spellId,
            buffType = spellRecord.type,
            version = 1,
            showInParty = true,
            showInArena = true,
            showInRaid = true,
            showOnNameplates = true, 
            duration = 0,
            showGlow = false,
            sizeMultiplier = 1,
        }
    end

    self.CreateShallowCopy =  function(src)
        local copy = {}

        for index, value in pairs(src) do
            if type(value) ~= "table" then
                copy[index] = value
            end
        end

        return copy
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

    return self;
end

DaveTest_Shared_Singleton = DaveTest_Shared:new();