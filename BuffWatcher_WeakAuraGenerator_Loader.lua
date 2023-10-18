---@class BuffWatcher_WeakAuraGenerator_Loader
BuffWatcher_WeakAuraGenerator_Loader = {}

function BuffWatcher_WeakAuraGenerator_Loader:new()
    self = {};


    return self
end

BuffWatcher_WeakAuraGenerator_Loader.ArenaOnlyLoaderTemplate = {
    ["use_size"] = false,
    ["use_never"] = false,
    ["talent"] = {
        ["multi"] = {
        },
    },
    ["class"] = {
        ["multi"] = {
        },
    },
    ["spec"] = {
        ["multi"] = {
        },
    },
    ["size"] = {
        ["single"] = "arena",
        ["multi"] = {
            ["ratedarena"] = true,
            ["arena"] = true,
        },
    },
}