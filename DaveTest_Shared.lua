DaveTest_Shared = {}

function DaveTest_Shared:new()
    self = {};

    self.GetCastRecordKey = function(castRecord) 
        return castRecord.type .. ":" .. castRecord.spellId
    end

    self.BuildSpellCastRecord = function(type, spellId, sourceName)
        local record = {
            type = type,
            spellId = spellId,
            sourceName = sourceName
        }

        record.key = self.GetCastRecordKey(record)

        return record;
    end


    return self;
end

DaveTest_Shared_Singleton = DaveTest_Shared:new();