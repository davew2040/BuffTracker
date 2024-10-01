local AceGUI = LibStub("AceGUI-3.0")
local AceConfig = LibStub("AceConfig-3.0")
local AceConfigDialog = LibStub("AceConfigDialog-3.0")

BuffWatcher_SettingsDialog = {}

---@param dbAccessor BuffWatcher_DbAccessor
---@param contextStore BuffWatcher_AuraContextStore
---@param defaultContextValues BuffWatcher_DefaultContextValues
function BuffWatcher_SettingsDialog:new(dbAccessor, contextStore, defaultContextValues)
    self = {}

    ---@type BuffWatcher_SavedDbOptions
    local currentModel = nil

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

    ---@return table<string, string>
    local getAnchorPoints = function()
        return {
            [BuffWatcher_AnchorPoints.TOPLEFT] = BuffWatcher_AnchorPoints.TOPLEFT,
            [BuffWatcher_AnchorPoints.TOP] = BuffWatcher_AnchorPoints.TOP,
            [BuffWatcher_AnchorPoints.TOPRIGHT] = BuffWatcher_AnchorPoints.TOPRIGHT,
            [BuffWatcher_AnchorPoints.LEFT] = BuffWatcher_AnchorPoints.LEFT,
            [BuffWatcher_AnchorPoints.CENTER] = BuffWatcher_AnchorPoints.CENTER,
            [BuffWatcher_AnchorPoints.RIGHT] = BuffWatcher_AnchorPoints.RIGHT,
            [BuffWatcher_AnchorPoints.BOTTOMLEFT] = BuffWatcher_AnchorPoints.BOTTOMLEFT,
            [BuffWatcher_AnchorPoints.BOTTOM] = BuffWatcher_AnchorPoints.BOTTOM,
            [BuffWatcher_AnchorPoints.BOTTOMRIGHT] = BuffWatcher_AnchorPoints.BOTTOMRIGHT,
        }
    end

    ---@param contextDefaults BuffWatcher_DefaultContextValues
    local getContextSubgroups = function(contextDefaults)
        local subgroups = {}

        local settings = contextDefaults.GetFixedDefaults()

        for groupKey,v in pairs(settings) do

            subgroups[groupKey] = {
                name = v.friendlyName,
                handler = BuffWatcher,
                type = "group",
                childGroups = "tree",
                args = {
                    showUnlistedAuras = {
                        name = "Show Other Auras",
                        desc = "Toggles whether relevant auras not associated with this group to also be displayed.",
                        type = "select",
                        values = {
                            [BuffWatcher_ShowUnlistedType.None] = "None",
                            [BuffWatcher_ShowUnlistedType.Any] = "Any",
                            [BuffWatcher_ShowUnlistedType.OwnOnly] = "Own Only",
                        },
                        get = self.BuildGenericAuraGroupGetter(
                            function(s) return s.showUnlistedAuras end
                        ),
                        set = self.BuildGenericAuraGroupSetter(
                            function(s, newValue) 
                                s.showUnlistedAuras = newValue 
                            end
                        )
                    },
                    xOffset = {
                        name = "Horizontal Offset",
                        desc = "The horizontal offset of the aura group",
                        type = "range",
                        min = -1000,
                        max = 1000,
                        step = 1,
                        get = self.BuildGenericAuraGroupGetter(
                            function(s) return s.xOffset end
                        ),
                        set = self.BuildGenericAuraGroupSetter(
                            function(s, newValue) 
                                s.xOffset = newValue 
                            end
                        )
                    },
                    yOffset = {
                        name = "Vertical Offset",
                        desc = "The vertical offset of the aura group",
                        type = "range",
                        min = -1000,
                        max = 1000,
                        step = 1,
                        get = self.BuildGenericAuraGroupGetter(
                            function(s) return s.yOffset end
                        ),
                        set = self.BuildGenericAuraGroupSetter(
                            function(s, newValue) 
                                s.yOffset = newValue 
                            end
                        )
                    },
                    showDispelType = {
                        type = "toggle",
                        name = "Show Dispel Type",
                        desc = "Toggles whether a border indicating the dispel type should be shown on these auras.",
                        get = self.BuildGenericAuraGroupGetter(
                            function(s) return s.showDispelType end
                        ),
                        set = self.BuildGenericAuraGroupSetter(
                            function(s, newValue) 
                                s.showDispelType = newValue 
                            end
                        )
                    },
                    useDefaultIconSize = {
                        type = "toggle",
                        name = "Use Default Icon Size",
                        desc = "Toggles whether the default icon size should be used for this group.",
                        get = self.BuildGenericAuraGroupGetter(
                            function(s) return s.useDefaultIconSize end
                        ),
                        set = self.BuildGenericAuraGroupSetter(
                            function(s, newValue) 
                                s.useDefaultIconSize = newValue 
                            end
                        )
                    },
                    customIconSize = {
                        name = "Custom Icon Size",
                        desc = "The custom icon size to be used, if not using the default.",
                        type = "range",
                        min = 16,
                        max = 128,
                        step = 1,
                        get = self.BuildGenericAuraGroupGetter(
                            function(s) return s.customIconSize end
                        ),
                        set = self.BuildGenericAuraGroupSetter(
                            function(s, newValue) 
                                s.customIconSize = newValue 
                            end
                        ),
                        disabled = function(info)
                            local groupKey = info[2]
                            return currentModel.groupUserSettings[groupKey].useDefaultIconSize
                        end
                    },
                    anchorPoint = {
                        name = "Target Anchor Point",
                        desc = "Determines the anchor point of the target frame that the aura set will be aligned with.",
                        type = "select",
                        values = getAnchorPoints(),
                        get = self.BuildGenericAuraGroupGetter(
                            function(s) return s.anchorPoint end
                        ),
                        set = self.BuildGenericAuraGroupSetter(
                            function(s, newValue) 
                                s.anchorPoint = newValue 
                            end
                        )
                    },   
                    selfPoint = {
                        name = "Self Anchor Point",
                        desc = "Determines the point of the aura frame that aura frames will be anchored from.",
                        type = "select",
                        values = getAnchorPoints(),
                        get = self.BuildGenericAuraGroupGetter(
                            function(s) return s.selfPoint end
                        ),
                        set = self.BuildGenericAuraGroupSetter(
                            function(s, newValue) 
                                s.selfPoint = newValue 
                            end
                        )
                    },   
                    growDirection = {
                        name = "Grow Direction",
                        desc = "Whether the aura group should grow left or right",
                        type = "select",
                        values = {
                            [BuffWatcher_GrowDirection.Left] = "Left",
                            [BuffWatcher_GrowDirection.Right] = "Right"
                        },
                        get = self.BuildGenericAuraGroupGetter(
                            function(s) return s.growDirection end
                        ),
                        set = self.BuildGenericAuraGroupSetter(
                            function(s, newValue) 
                                s.growDirection = newValue 
                            end
                        )
                    },                   
                    useDefaultUnlistedMultiplier = {
                        type = "toggle",
                        name = "Use Default Unlisted Multiplier",
                        desc = "Toggles whether the default unlisted multiplier should be used",
                        get = self.BuildGenericAuraGroupGetter(
                            function(s) return s.useDefaultUnlistedMultiplier end
                        ),
                        set = self.BuildGenericAuraGroupSetter(
                            function(s, newValue) 
                                s.useDefaultUnlistedMultiplier = newValue 
                            end
                        )
                    },
                    customUnlistedMultiplier = {
                        name = "Custom Unlisted Multiplier",
                        desc = "The custom unlisted icon multiplier to be used, if applicable",
                        type = "range",
                        min = 0.1,
                        max = 5,
                        step = 0.1,
                        get = self.BuildGenericAuraGroupGetter(
                            function(s) return s.customUnlistedMultiplier end
                        ),
                        set = self.BuildGenericAuraGroupSetter(
                            function(s, newValue) 
                                s.customUnlistedMultiplier = newValue 
                            end
                        ),
                        disabled = function(info)
                            local groupKey = info[2]
                            return currentModel.groupUserSettings[groupKey].useDefaultUnlistedMultiplier
                        end
                    },
                    minorAuraMultiplier = {
                        name = "Minor Aura Multiplier",
                        desc = "The icon size multiplier applied to auras marked as minor auras.",
                        type = "range",
                        min = 0.1,
                        max = 5,
                        step = 0.1,
                        get = self.BuildGenericAuraGroupGetter(
                            function(s) return s.minorAuraMultiplier end
                        ),
                        set = self.BuildGenericAuraGroupSetter(
                            function(s, newValue) 
                                s.minorAuraMultiplier = newValue 
                            end
                        )
                    },
                    minorAuraPriority = {
                        name = "Minor Aura Priority",
                        desc = "The priority value applied to auras marked as minor auras.",
                        type = "range",
                        min = 1,
                        max = 10,
                        step = 1,
                        get = self.BuildGenericAuraGroupGetter(
                            function(s) return s.minorAuraPriority end
                        ),
                        set = self.BuildGenericAuraGroupSetter(
                            function(s, newValue) 
                                s.minorAuraPriority = newValue 
                            end
                        )
                    },
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
                    get = buildRootGetter(function(model) return model.unitFrameIconSize end),
                    set = buildRootSetter(function(model, value) model.unitFrameIconSize = value end),
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

    self.Initialize = function(addonRoot)
        currentModel = dbAccessor.GetOptions()

        if (currentModel ~= nil) then
            --DevTool:AddData(CopyTable(currentModel), "fixme dbaccessor result")
        end

        AceConfig:RegisterOptionsTable("BuffWatcher_options", getOptions())
        local optionsFrame = AceConfigDialog:AddToBlizOptions("BuffWatcher_options", "BuffWatcher")
    end

    ---@param picker fun(groupSettings: BuffWatcher_AuraGroupUserSettings): any
    ---@return fun(info: any): any
    self.BuildGenericAuraGroupGetter = function(picker)
        ---@type fun(info: any): nil
        local getter = function(info)
            local groupKey = info[2]
            local value = picker(currentModel.groupUserSettings[groupKey])
            return value
        end

        return getter
    end

    ---@param valueSetter fun(groupSettings: BuffWatcher_AuraGroupUserSettings, newValue: any): any
    ---@return fun(info: any, value: any): nil
    self.BuildGenericAuraGroupSetter = function(valueSetter)
        ---@type fun(info: any, value: any): nil
        local setter = function(info, value)
            local groupKey = info[2]
            local groupSettings = currentModel.groupUserSettings[groupKey]
            valueSetter(groupSettings, value)
            dbAccessor.SetOptions(currentModel)
        end

        return setter
    end
    
    return self
end
