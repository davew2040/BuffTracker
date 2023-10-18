local AceGUI = LibStub("AceGUI-3.0")
local AceConfig = LibStub("AceConfig-3.0")
local AceConfigDialog = LibStub("AceConfigDialog-3.0")

BuffWatcher_SettingsDialog = {}

---@param dbAccessor BuffWatcher_DbAccessor
---@param contextStore BuffWatcher_AuraContextStore
---@param defaultContextValues any
function BuffWatcher_SettingsDialog:new(dbAccessor, contextStore, defaultContextValues)
    self = {}

    ---@type BuffWatcher_SavedDbOptions
    local currentModel = nil

    local dummy = true

    ---@param picker fun(model: BuffWatcher_SavedDbOptions): any
    local buildRootGetter = function(picker)
        return function(info) 
            return picker(currentModel) 
        end
    end

    ---@param picker fun(model: BuffWatcher_SavedDbOptions, value: any)
    local buildRootSetter = function(picker)
        return function(info, value) 
            picker(currentModel, value)
            dbAccessor.SetOptions(currentModel)
        end
    end

    local getContextSubgroups = function(contextDefaults)
        local subgroups = {}

        local settings = contextDefaults.GetFixedDefaults()

        for k,v in pairs(settings) do
            subgroups[k] = {
                name = v.friendlyName,
                handler = BuffWatcher,
                type = "group",
                childGroups = "tree",
                args = {
                    showUnlistedAuras = {
                        type = "toggle",
                        name = "Show Other Auras",
                        desc = "Toggles whether relevant auras not associated with this group to also be displayed.",
                        get = self.BuildGenericAuraGroupGetter("showUnlistedAuras"),
                        set = self.BuildGenericAuraGroupSetter("showUnlistedAuras")
                    },
                    showDispelType = {
                        type = "toggle",
                        name = "Show Dispel Type",
                        desc = "Toggles whether a border indicating the dispel type should be shown on these auras.",
                        get = self.BuildGenericAuraGroupGetter("showDispelType"),
                        set = self.BuildGenericAuraGroupSetter("showDispelType")
                    },
                    useDefaultIconSize = {
                        type = "toggle",
                        name = "Use Default Icon Size",
                        desc = "Toggles whether the default icon size should be used for this group.",
                        get = self.BuildGenericAuraGroupGetter("useDefaultIconSize"),
                        set = self.BuildGenericAuraGroupSetter("useDefaultIconSize")
                    },
                    customIconSize = {
                        name = "Custom Icon Size",
                        desc = "The custom icon size to be used, if not using the default.",
                        type = "range",
                        min = 16,
                        max = 128,
                        step = 1,
                        get = self.BuildGenericAuraGroupGetter("customIconSize"),
                        set = self.BuildGenericAuraGroupSetter("customIconSize")
                    }
                }
            }
        end

        return subgroups
    end

    local getOptions = function()
        return {
            name = "BuffWatcher",
            handler = BuffWatcher,
            childGroups = "tab",
            type = "group",
            args = {
                iconSize = {
                    name = "Icon Size",
                    desc = "The default size of icons.",
                    type = "range",
                    min = 16,
                    max = 128,
                    step = 1,
                    get = buildRootGetter(function(model) return model.iconSize end),
                    set = buildRootSetter(function(model, value) model.iconSize = value end),
                },
                unlistedMultiplier = {
                    name = "Unlisted Icon Multiplier",
                    desc = "Size multiplier on icons that are NOT registered.",
                    type = "range",
                    min = 0.1,
                    max = 5,
                    step = 0.1,
                    get = buildRootGetter(function(model) return model.unlistedMultiplier end),
                    set = buildRootSetter(function(model, value) model.unlistedMultiplier = value end),
                },
                showTestAnchors = {
                    type = "toggle",
                    name = "Show Test Anchors",
                    desc = "Toggles whether test anchors should be added to groups to indicate position of group.",
                    get = buildRootGetter(function(model) return model.addTestAnchors end),
                    set = buildRootSetter(function(model, value) model.addTestAnchors = value end),
                },
                auraGroups = {
                    name = "Aura Groups",
                    handler = BuffWatcher,
                    type = "group",
                    childGroups = "tree",
                    args = getContextSubgroups(defaultContextValues)
                },
            },
        }
    end

    local initializeHandlers = function(addonRoot) 
        function addonRoot:GetMessage(info)
            return currentModel.message
        end

        function addonRoot:SetMessage(info, value)
            DevTool:AddData(CopyTable(info), "fixme info SetMessage")
            currentModel.message = value
        end

        function addonRoot:IsShowOnScreen(info)
            return currentModel.showOnScreen
        end

        function addonRoot:ToggleShowOnScreen(info, value)
            DevTool:AddData(CopyTable(info), "fixme info ToggleShowOnScreen")
            currentModel.showOnScreen = value
        end

        function addonRoot:GetIconSize(info)
            return currentModel.iconSize
        end

        function addonRoot:SetIconSize(info, value)
            DevTool:AddData(CopyTable(info), "fixme info SetIconSize")
            currentModel.iconSize = value
        end

        function addonRoot:GetUnlistedMultiplier(info)
            return currentModel.unlistedMultiplier
        end

        function addonRoot:SetUnlistedMultiplier(info, value)
            DevTool:AddData(CopyTable(info), "fixme info SetUnlistedMultiplier")
            currentModel.unlistedMultiplier = value
            
        end
    end

    self.Initialize = function(addonRoot)
        currentModel = dbAccessor.GetOptions()

        if (currentModel ~= nil) then
            --DevTool:AddData(CopyTable(currentModel), "fixme dbaccessor result")
        end

        initializeHandlers(addonRoot)

        AceConfig:RegisterOptionsTable("BuffWatcher_options", getOptions())
        local optionsFrame = AceConfigDialog:AddToBlizOptions("BuffWatcher_options", "BuffWatcher")
    end

    self.BuildGenericAuraGroupGetter = function(settingName)
        local getter = function(info)
            local groupKey = info[2]
            local value = currentModel.groupUserSettings[groupKey][settingName]
            return value
        end

        return getter
    end

    self.BuildGenericAuraGroupSetter = function(settingName)
        local setter = function(info, value)
            local groupKey = info[2]
            currentModel.groupUserSettings[groupKey][settingName] = value
            dbAccessor.SetOptions(currentModel)
        end

        return setter
    end
    
    return self
end
