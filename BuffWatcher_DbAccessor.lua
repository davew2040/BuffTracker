BuffWatcher_DbAccessor = {}

function BuffWatcher_DbAccessor:new()
    self = {};

    local GetDefaultDb = function()
        return {
            options = {},
            savedSpells = {}
        }
    end

    local DbIsEmpty = function()
        if (BuffWatcherDB == nil) then
            return true
        end

        local count = 0
        for k,v in pairs(BuffWatcherDB) do
            count = count + 1
        end
        return count == 0
    end

    local OnAddonLoaded = function()
        if (DbIsEmpty()) then
            BuffWatcherDB = GetDefaultDb()
        end
    end

    local frame = CreateFrame("Frame", "Spell Row", UIParent)

    frame:RegisterEvent("ADDON_LOADED")
    frame:SetScript("OnEvent", function(loadingFrame, event, addon)
        if (addon == "BuffWatcher") then
            OnAddonLoaded()
        end
    end)

    self.SaveStoredSpells = function(newStoredSpells)
        BuffWatcherDB.savedSpells = newStoredSpells
    end

    self.GetSpells = function()
        if (DbIsEmpty()) then
            return {}
        end
        return BuffWatcherDB.savedSpells
    end

    return self;
end

BuffWatcher_DbAccessor_Singleton = BuffWatcher_DbAccessor:new()