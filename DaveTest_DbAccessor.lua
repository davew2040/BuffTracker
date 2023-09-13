DaveTest_DbAccessor = {}

function DaveTest_DbAccessor:new()
    self = {};

    local GetDefaultDb = function()
        return {
            options = {},
            savedSpells = {}
        }
    end

    local DbIsEmpty = function()
        if (DaveTestDB == nil) then
            return true
        end

        local count = 0
        for k,v in pairs(DaveTestDB) do
            count = count + 1
        end
        return count == 0
    end

    local OnAddonLoaded = function()
        if (DbIsEmpty()) then
            DaveTestDB = GetDefaultDb()
        end
    end

    local frame = CreateFrame("Frame", "Spell Row", UIParent)

    frame:RegisterEvent("ADDON_LOADED")
    frame:SetScript("OnEvent", function(loadingFrame, event, addon)
        if (addon == "DaveTest") then
            OnAddonLoaded()
        end
    end)

    self.SaveStoredSpells = function(newStoredSpells)
        DaveTestDB.savedSpells = newStoredSpells
    end

    self.GetSpells = function()
        if (DbIsEmpty()) then
            print ('returning empty spells')
            return {}
        end
        return DaveTestDB.savedSpells
    end

    return self;
end

DaveTest_DbAccessor_Singleton = DaveTest_DbAccessor:new()