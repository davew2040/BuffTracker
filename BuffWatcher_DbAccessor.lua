BuffWatcher_DbAccessor = {}

function BuffWatcher_DbAccessor:new()
    self = {};

    local db;

    local GetDefaultDb = function()
        return {
            global = {
                options = {
                    message = "Welcome Home!",
                    showOnScreen = true,
                    iconSize = 32
                },
                savedSpells = {}
            }
          }

        -- return {
        --     options = {},
        --     savedSpells = {}
        -- }
    end

    self.SaveStoredSpells = function(newStoredSpells)
        db.savedSpells = newStoredSpells
    end

    self.GetSpells = function()
        return db.global.savedSpells
    end

    self.GetOptions = function()
        return db.global.options
    end

    self.OnInitialize = function()
        db = LibStub("AceDB-3.0"):New("BuffWatcherDB", GetDefaultDb())
        DevTool:AddData(db, "fixme db accessor init")
    end

    return self;
end

BuffWatcher_DbAccessor_Singleton = BuffWatcher_DbAccessor:new()