---@class BuffWatcher_BorderConfiguration
---@field index integer
---@field color BuffWatcher_Color
BuffWatcher_BorderConfiguration = {}

---@class BuffWatcher_WeakAuraGenerator
BuffWatcher_WeakAuraGenerator = {}

---@param configuration BuffWatcher_Configuration
function BuffWatcher_WeakAuraGenerator:new(configuration)
    self = {};

    local InitialSubregionIndex = 4

    local baseCustomCastScript = "function(allstates, event, ...)\n    if (BuffWatcher_WeakAuraInterface_Singleton == nil \n        or not BuffWatcher_WeakAuraInterface_Singleton.IsRegistered()) then\n        return false\n    end\n    \n    \n    local castData = {\n        spellId = {0}\n    }\n    \n    return BuffWatcher_WeakAuraInterface_Singleton.DelegateTsu(allstates, event, \"{1}\", castData, ...)\nend"
    local baseCustomGrowScript = "function(newPositions, activeRegions, ...)\n    if (BuffWatcher_WeakAuraInterface_Singleton == nil \n        or not BuffWatcher_WeakAuraInterface_Singleton.IsRegistered()) then\n        return\n    end\n    \n    return BuffWatcher_WeakAuraInterface_Singleton.DelegateCustomGrow(\"{0}\", newPositions, activeRegions, ...)\nend"
    local baseCustomGeneralScript = "function(allstates, event, ...)\n    if (BuffWatcher_WeakAuraInterface_Singleton == nil \n        or not BuffWatcher_WeakAuraInterface_Singleton.IsRegistered()) then\n        return false\n    end\n    \n    \n     return BuffWatcher_WeakAuraInterface_Singleton.DelegateTsu(allstates, event, \"{0}\", ...)\nend"
	local customVariables = [[
    {
        outlineType = {
            display = "Outline Type",
            type = "select",
            values = {
                ["none"] = "none", 
                ["buff"] = "buff", 
                ["debuff"] = "debuff"
            }
        }
    }
    ]]

    local BorderConfigurationKeys = {
        buff = "buff",
        debuff = "debuff"
    }

    ---@type table<string, BuffWatcher_BorderConfiguration>
    local BorderConfigurations = {
        [BorderConfigurationKeys.buff] = {
            index = 1,
            color = BuffWatcher_Color:new(0, 1, 0, 1)
        },
        [BorderConfigurationKeys.debuff] = {
            index = 2,
            color = BuffWatcher_Color:new(1, 0, 0, 1)
        }
    }

    ---@param spellId integer
    ---@param contextName string
    ---@return string
    local getCustomCastScript = function(spellId, contextName)
        local modified = string.gsub(baseCustomCastScript, "{0}", spellId)
        modified = string.gsub(modified, "{1}", contextName)
        return modified
    end

    ---@param contextName string
    ---@return string
    local getCustomGrowScript = function(contextName)
        local modified = string.gsub(baseCustomGrowScript, "{0}", contextName)
        return modified
    end

    ---@param contextName string
    ---@return string
    local getCustomGeneralScript = function(contextName)
        local modified = string.gsub(baseCustomGeneralScript, "{0}", contextName)
        return modified
    end

    ---@param index integer
    ---@return string
    local getBorderVisibilityPropertyTag = function(index)
        return "sub." .. tostring(index) .. ".border_visible"
    end

    local getScriptTriggerEvents = function()
        return "UNIT_AURA, ARENA_TEAM_ROSTER_UPDATE, GROUP_ROSTER_UPDATE, NAME_PLATE_UNIT_REMOVED, NAME_PLATE_UNIT_ADDED, COMBAT_LOG_EVENT_UNFILTERED:SPELL_CAST_SUCCESS, STATUS, CLEU:UNIT_DIED, PLAYER_ENTERING_WORLD, PARTY_CONVERTED_TO_RAID"
    end

    ---@param type BuffWatcher_TriggerType
    local getCustomInitScript = function(type)	
        local script = "if (aura_env) then\n   aura_env.config.triggerType = " .. type.. "\nend"
        return script
    end

    ---@return any
    local getAuthorOptions = function()
        local options = {
            {
                ["type"] = "select",
                ["values"] = {
                },
                ["key"] = "triggerType",
                ["name"] = "Trigger Type",
                ["default"] = 1,
                ["width"] = 1,
            },
        }

        for _,v in ipairs(BuffWatcher_Shared.TriggerTypeLabels) do
            table.insert(options[1].values, v)
        end

        return options
    end

    ---@param spellId integer
    ---@param contextName string
    ---@return table<string, any>
    local getCastTrigger = function(spellId, contextName)
        local triggerCopy = BuffWatcher_Shared:CopyTable(BuffWatcher_WeakAuraGenerator.CastCustomTrigger)
        local modifiedScript = getCustomCastScript(spellId, contextName)

        triggerCopy.custom = modifiedScript

        return triggerCopy
    end

    ---@param incomingAuraIds number[]
    ---@return table<integer, string>
    local spreadAuraIds = function(incomingAuraIds)
        local result = {}

        for k, _ in pairs(incomingAuraIds) do
            table.insert(result, tostring(k))
        end

        return result
    end

    ---@param frameType FrameTypes
    ---@return string
    local unitLabelFromFrameType = function(frameType)
        if frameType == BuffWatcher_Shared_Singleton.FrameTypes.Nameplate then
            return "nameplate"
        elseif frameType == BuffWatcher_Shared_Singleton.FrameTypes.Party then
            return "group"
        elseif frameType == BuffWatcher_Shared_Singleton.FrameTypes.Arena then
            return "arena"
        elseif frameType == BuffWatcher_Shared_Singleton.FrameTypes.Raid then
            return "group"
        else
            error("Unrecognized frame type " .. tostring(frameType))
        end
    end

    ---@param borders any[]
    ---@param borderColor BuffWatcher_Color
    ---@param borderSize integer
    ---@param borderOffset integer
    local addBorder = function(borders, borderColor, borderSize, borderOffset)
        local borderCopy = CopyTable(BuffWatcher_WeakAuraGenerator.BorderTemplate)

        borderCopy.border_size = borderSize
        borderCopy.border_offset = borderOffset
        borderCopy.border_color[1] = borderColor.red
        borderCopy.border_color[2] = borderColor.green
        borderCopy.border_color[3] = borderColor.blue

        table.insert(borders, borderCopy)
    end

    ---@param conditions any[]
    ---@param borderIndices table<string, integer>
    local addConditionsBuffDebuff = function(conditions, borderIndices)
        local buff = CopyTable(BuffWatcher_WeakAuraGenerator.ConditionBuffDebuffOutlineTemplate)
        buff["check"]["value"] = "buff"
        buff["changes"][1]["property"] = getBorderVisibilityPropertyTag(borderIndices[BorderConfigurationKeys.buff])

        table.insert(conditions, buff)

        local debuff = CopyTable(BuffWatcher_WeakAuraGenerator.ConditionBuffDebuffOutlineTemplate)
        debuff["check"]["value"] = "debuff"
        debuff["changes"][1]["property"] = getBorderVisibilityPropertyTag(borderIndices[BorderConfigurationKeys.debuff])

        table.insert(conditions, debuff)

        DevTool:AddData(CopyTable(borderIndices, true), "fixme borderIndices")
    end

    ---@param weakAura any
    ---@param multiplier number
    local addBorderAndConditions = function(weakAura, multiplier)
        local borderSize = configuration.GetBorderSize()
        local borderOffset = configuration.GetBorderOffset()
        ---@type any[]
        local newSubregions = {}
        ---@type table<string, integer>
        local borderIndices = {}

        DevTool:AddData(CopyTable(weakAura, true), "fixme initial aura")

        local orderedKeys = {
            [1] = BorderConfigurationKeys.buff,
            [2] = BorderConfigurationKeys.debuff
        }
        local borderIndex = InitialSubregionIndex
        for _,orderedKey in ipairs(orderedKeys) do
            addBorder(newSubregions, BorderConfigurations[orderedKey].color, configuration.GetBorderSize(), configuration.GetBorderOffset())

            borderIndices[orderedKey] = borderIndex
            borderIndex = borderIndex + 1
        end

        BuffWatcher_Shared_Singleton.MergeIntoOrderedTable(weakAura.subRegions, newSubregions)

        ---@type any[]
        local borderConditions = {}
    
        addConditionsBuffDebuff(borderConditions, borderIndices)

        BuffWatcher_Shared_Singleton.MergeIntoOrderedTable(weakAura.conditions, borderConditions)

        DevTool:AddData(CopyTable(weakAura, true), "fixme after border add")
    end

    ---@param weakAura any
    ---@param multiplier number
    local addDispelType = function(weakAura, multiplier)
        local borderSize = configuration.GetBorderSize()
        local borderOffset = configuration.GetBorderOffset()

        local borderSubregions = CopyTable(BuffWatcher_WeakAuraGenerator.DispelTypeBorders)

        for _, subregion in pairs(borderSubregions) do
            subregion.border_size = borderSize * multiplier
            subregion.border_offset = borderOffset * multiplier
        end

        BuffWatcher_Shared_Singleton.MergeIntoOrderedTable(weakAura.subRegions, borderSubregions)

        local borderConditions = CopyTable(BuffWatcher_WeakAuraGenerator.BorderConditions)

        BuffWatcher_Shared_Singleton.MergeIntoOrderedTable(weakAura.conditions, borderConditions)
    end

    ---@param isHostile boolean
    ---@return string
    local getHostilityValue = function(isHostile)
        return (isHostile and "hostile") or "friendly"
    end

    ---@param aura any
    ---@param isBuff boolean
    local addBuffDebuffBorders = function(aura, isBuff)
        local color = configuration.GetBuffColor()
        if (not isBuff) then
            color = configuration.GetDebuffColor()
        end

        local colorObject = {}

        table.insert(colorObject, color.red)
        table.insert(colorObject, color.green)
        table.insert(colorObject, color.blue)
        table.insert(colorObject, color.alpha)

        aura["subRegions"][BuffDebuffBorderIndex]["border_color"] = colorObject
        aura["subRegions"][BuffDebuffBorderIndex]["border_visible"] = true

        DevTool:AddData(CopyTable(aura), "fixme aura after border")
    end

    ---@param name string
    ---@param frameType FrameTypes
    ---@param contextKey string
    ---@param context BuffWatcher_AuraContext
    ---@param useCustomGrow boolean
    ---@return any
    self.GenerateDynamicGroup = function(name, frameType, contextKey, context, useCustomGrow)
        local copy = CopyTable(BuffWatcher_WeakAuraGenerator.DynamicGroupTemplate)
        copy.id = name
        copy.groupIcon = context.GetIcon()
        copy.xOffset = context.GetXOffset()
        copy.yOffset = context.GetYOffset()
        copy.selfPoint = context.GetSelfAnchorPoint()
        copy.anchorPoint = context.GetTargetAnchorPoint()

        local anchorType = "UNITFRAME"
        if (frameType == BuffWatcher_Shared_Singleton.FrameTypes.Nameplate) then
            anchorType = "NAMEPLATE"
        end

        copy.anchorPerUnit = anchorType

        if (useCustomGrow) then
            copy["grow"] = "CUSTOM"
            copy["growOn"] = "unit"
            copy["customGrow"] = getCustomGrowScript(contextKey)
        end

        return copy
    end

    ---@param buffId number
    ---@param isBuff boolean
    ---@param name string
    ---@param isHostile boolean
    ---@param parent string
    ---@param size number
    ---@param frameType FrameTypes
    ---@param showDispelType boolean
    ---@param sizeMultiplier number
    ---@param ownOnly boolean
    self.GenerateBuffDebuff = function(buffId, isBuff, name, isHostile, parent, size, frameType, showDispelType, sizeMultiplier, ownOnly)
        local copy = CopyTable(BuffWatcher_WeakAuraGenerator.BaseAuraTemplate)

        copy.id = name
        copy.width = size
        copy.height = size
        copy.parent = parent

        addBuffDebuffBorders(copy, isBuff)

        local trigger = CopyTable(BuffWatcher_WeakAuraGenerator.BuffDebuffTrigger)

        local unitLabel = unitLabelFromFrameType(frameType)
        trigger.unit = unitLabel
        trigger.auraspellids[1] = tostring(buffId)
        trigger.hostility = (isHostile and "hostile") or "friendly"

        if (ownOnly) then
            trigger.ownOnly = ownOnly
        end

        local debuffType = "HARMFUL"
        if (isBuff) then
            debuffType = "HELPFUL"
        end
        trigger.debuffType = debuffType

        copy.triggers[1].trigger = trigger

        if (showDispelType) then
            addDispelType(copy, sizeMultiplier)
        end

        return copy
    end

    ---@param auraIds number[]
    ---@param isBuff boolean
    ---@param name string
    ---@param isHostile boolean
    ---@param parent string
    ---@param size number
    ---@param frameType FrameTypes
    ---@param showDispelType boolean
    self.GenerateMultiBuffDebuff = function(auraIds, isBuff, name, isHostile, parent, size, frameType, showDispelType)
        local copy = CopyTable(BuffWatcher_WeakAuraGenerator.BaseAuraTemplate)
        copy.authorOptions = getAuthorOptions()

        copy.id = name
        copy.width = size
        copy.height = size
        copy.parent = parent

        addBuffDebuffBorders(copy, isBuff)

        local triggerType = BuffWatcher_TriggerType.Buff
        if (not isBuff) then
            triggerType = BuffWatcher_TriggerType.Debuff
        end
        copy.config.triggerType = triggerType

        local trigger = CopyTable(BuffWatcher_WeakAuraGenerator.BuffDebuffTrigger)

        local unitLabel = unitLabelFromFrameType(frameType)
        trigger.unit = unitLabel
        trigger.auraspellids = spreadAuraIds(auraIds)
        trigger.hostility = (isHostile and "hostile") or "friendly"

        local debuffType = "HARMFUL"
        if (isBuff) then
            debuffType = "HELPFUL"
        end
        trigger.debuffType = debuffType

        copy.triggers[1].trigger = trigger

        if (showDispelType) then
            addDispelType(copy, 1)
        end

        return copy
    end

    ---@param allAuraIds number[]
    ---@param isBuff boolean
    ---@param name string
    ---@param isHostile boolean
    ---@param parent string
    ---@param size number
    ---@param frameType FrameTypes
    ---@param showDispelType boolean
    ---@param sizeMultiplier number
    ---@param ownOnly boolean
    self.GenerateCatchAllBuffDebuff = function(allAuraIds, isBuff, name, isHostile, parent, size, frameType, showDispelType, sizeMultiplier, ownOnly)
        local copy = CopyTable(BuffWatcher_WeakAuraGenerator.BaseAuraTemplate)
        copy.authorOptions = getAuthorOptions()
        copy.config.triggerType = BuffWatcher_TriggerType.CatchAll

        copy.id = name
        copy.width = size
        copy.height = size
        copy.parent = parent

        addBuffDebuffBorders(copy, isBuff)

        local trigger = CopyTable(BuffWatcher_WeakAuraGenerator.CatchAllTrigger)

        local unitLabel = unitLabelFromFrameType(frameType)
        trigger.unit = unitLabel

        if (ownOnly) then
            trigger.ownOnly = true
        end

        trigger.ignoreAuraSpellids = spreadAuraIds(allAuraIds)

        local debuffType = "HARMFUL"
        if (isBuff) then
            debuffType = "HELPFUL"
        end
        trigger.debuffType = debuffType
        
        trigger.hostility = (isHostile and "hostile") or "friendly"

        copy.triggers[1].trigger = trigger

        if (showDispelType) then
            addDispelType(copy, sizeMultiplier)
        end

        return copy
    end

    ---@param name string
    ---@param spellId number
    ---@param parent string
    ---@param size number
    ---@param icon string
    ---@param contextName string
    ---@param ownOnly boolean
    self.GenerateCast = function(name, spellId, parent, size, icon, contextName, ownOnly)
        local copy = CopyTable(BuffWatcher_WeakAuraGenerator.BaseAuraTemplate)
        copy.authorOptions = getAuthorOptions()
        copy.config.triggerType = BuffWatcher_TriggerType.Cast

        copy.id = name
        copy.width = size
        copy.height = size
        copy.parent = parent
        copy.displayIcon = icon

        local trigger = getCastTrigger(spellId, contextName)

        if (ownOnly) then
            trigger.ownOnly = ownOnly
        end

        copy.triggers[1].trigger = trigger

        return copy
    end

    ---@param name string
    ---@param icon number
    ---@param isHostile boolean
    ---@param parent string
    ---@param size number
    ---@param frameType FrameTypes
    self.GenerateAnchor = function(name, icon, isHostile, parent, size, frameType)
        local auraCopy = CopyTable(BuffWatcher_WeakAuraGenerator.BaseAuraTemplate)

        auraCopy.iconSource = 0
        auraCopy.id = name
        auraCopy.width = size
        auraCopy.height = size
        auraCopy.parent = parent
        auraCopy.icon = true
        auraCopy.displayIcon = icon

        local trigger = CopyTable(BuffWatcher_WeakAuraGenerator.AnchorTrigger)

        local unitLabel = unitLabelFromFrameType(frameType)
        trigger.unit = unitLabel

        local hostilityValue = getHostilityValue(isHostile)
        trigger.hostility = hostilityValue

        if (frameType == BuffWatcher_Shared_Singleton.FrameTypes.Nameplate) then
            trigger.use_nameplateType = true
            trigger.nameplateType = hostilityValue
        else
            trigger.use_nameplateType = false
        end

        auraCopy.triggers[1].trigger = trigger

        return auraCopy
    end

    ---@param name string
    ---@param parent string
    ---@param context BuffWatcher_AuraContext
    ---@param size number
    ---@param sizeMultiplier number
    self.GenerateScriptAura = function(name, parent, context, size, sizeMultiplier)
        local copy = CopyTable(BuffWatcher_WeakAuraGenerator.BaseAuraTemplate)

        copy.id = name
        copy.width = size
        copy.height = size
        copy.parent = parent

        local trigger = CopyTable(BuffWatcher_WeakAuraGenerator.ScriptTrigger)

        trigger["custom"] = getCustomGeneralScript(context.GetKey())
        trigger["customVariables"] = customVariables
        
        copy.triggers[1].trigger = trigger

        addBorderAndConditions(copy, sizeMultiplier)

        return copy
    end

    return self
end

BuffWatcher_WeakAuraGenerator.GetScriptTriggerEvents = function()
    return "UNIT_AURA, ARENA_TEAM_ROSTER_UPDATE, GROUP_ROSTER_UPDATE, NAME_PLATE_UNIT_REMOVED, NAME_PLATE_UNIT_ADDED, COMBAT_LOG_EVENT_UNFILTERED:SPELL_CAST_SUCCESS, STATUS, CLEU:UNIT_DIED, PLAYER_ENTERING_WORLD, PARTY_CONVERTED_TO_RAID"
end


BuffWatcher_WeakAuraGenerator.DynamicGroupTemplate = {
    ["grow"] = "RIGHT",
    ["controlledChildren"] = {
    },
    ["borderBackdrop"] = "Blizzard Tooltip",
    ["xOffset"] = 0,
    ["yOffset"] = 0,
    ["anchorPoint"] = "CENTER",
    ["selfPoint"] = "TOP",
    ["borderColor"] = {
        0, -- [1]
        0, -- [2]
        0, -- [3]
        1, -- [4]
    },
    ["space"] = 2,
    ["actions"] = {
        ["start"] = {
        },
        ["init"] = {
        },
        ["finish"] = {
        },
    },
    ["triggers"] = {
        {
            ["trigger"] = {
                ["names"] = {
                },
                ["type"] = "aura2",
                ["spellIds"] = {
                },
                ["subeventSuffix"] = "_CAST_START",
                ["unit"] = "player",
                ["subeventPrefix"] = "SPELL",
                ["event"] = "Health",
                ["debuffType"] = "HELPFUL",
            },
            ["untrigger"] = {
            },
        }, -- [1]
    },
    ["columnSpace"] = 1,
    ["radius"] = 200,
    ["align"] = "CENTER",
    ["stagger"] = 0,
    ["subRegions"] = {
    },
    ["load"] = {
        ["size"] = {
            ["multi"] = {
            },
        },
        ["spec"] = {
            ["multi"] = {
            },
        },
        ["class"] = {
            ["multi"] = {
            },
        },
        ["talent"] = {
            ["multi"] = {
            },
        },
    },
    ["useLimit"] = false,
    ["backdropColor"] = {
        1, -- [1]
        1, -- [2]
        1, -- [3]
        0.5, -- [4]
    },
    ["arcLength"] = 360,
    ["animate"] = false,
    ["animation"] = {
        ["start"] = {
            ["type"] = "none",
            ["easeStrength"] = 3,
            ["duration_type"] = "seconds",
            ["easeType"] = "none",
        },
        ["main"] = {
            ["type"] = "none",
            ["easeStrength"] = 3,
            ["duration_type"] = "seconds",
            ["easeType"] = "none",
        },
        ["finish"] = {
            ["type"] = "none",
            ["easeStrength"] = 3,
            ["duration_type"] = "seconds",
            ["easeType"] = "none",
        },
    },
    ["scale"] = 1,
    ["centerType"] = "LR",
    ["border"] = false,
    ["borderEdge"] = "Square Full White",
    ["regionType"] = "dynamicgroup",
    ["borderSize"] = 2,
    ["sort"] = "none",
    ["rotation"] = 0,
    ["fullCircle"] = true,
    ["constantFactor"] = "RADIUS",
    ["limit"] = 5,
    ["borderOffset"] = 4,
    ["gridType"] = "RD",
    ["borderInset"] = 1,
    ["id"] = "INSERT ID HERE",
    ["gridWidth"] = 5,
    ["frameStrata"] = 1,
    ["anchorFrameType"] = "SCREEN",
    ["anchorPerUnit"] = "INSERT ANCHOR PER UNIT",
    ["useAnchorPerUnit"] = true,
    ["rowSpace"] = 1,
    ["config"] = {
    },
    ["authorOptions"] = {
    },
    ["internalVersion"] = 66,
    ["conditions"] = {
    },
    ["information"] = {
    },
}

BuffWatcher_WeakAuraGenerator.BuffDebuffTrigger = {
    ["showClones"] = true,
    ["type"] = "aura2",
    ["subeventSuffix"] = "_CAST_START",
    ["event"] = "Health",
    ["subeventPrefix"] = "SPELL",
    ["auraspellids"] = {
        "139", -- [1]
    },
    ["useExactSpellId"] = true,
    ["spellIds"] = {
    },
    ["auranames"] = {
    },
    ["useName"] = false,
    ["names"] = {
    },
    ["unit"] = "INSERT UNIT TYPE HERE",
    ["debuffType"] = "HELPFUL",
    ["useHostility"] = true,
    ["hostility"] = "hostile"
}

BuffWatcher_WeakAuraGenerator.CatchAllTrigger = {
    ["showClones"] = true,
    ["type"] = "aura2",
    ["subeventSuffix"] = "_CAST_START",
    ["useIgnoreExactSpellId"] = true,
    ["event"] = "Health",
    ["subeventPrefix"] = "SPELL",
    ["spellIds"] = {
    },
    ["names"] = {
    },
    ["unit"] = "party",
    ["ignoreAuraSpellids"] = {
    },
    ["useExactSpellId"] = false,
    ["debuffType"] = "HARMFUL",
    ["useHostility"] = true,
    ["hostility"] = "hostile",
    ["useTotal"] = true,
    ["total"] = "0",
    ["totalOperator"] = "~=",
}

BuffWatcher_WeakAuraGenerator.ScriptTrigger = {
    ["auranames"] = {
    },
    ["useHostility"] = true,
    ["showClones"] = true,
    ["useName"] = false,
    ["custom_type"] = "stateupdate",
    ["event"] = "Health",
    ["names"] = {
    },
    ["spellIds"] = {
    },
    ["custom"] = "INSERT SCRIPT HERE",
    ["events"] = BuffWatcher_WeakAuraGenerator.GetScriptTriggerEvents(),
    ["useExactSpellId"] = true,
    ["check"] = "event",
    ["type"] = "custom",
    ["customVariables"] = "INSERT CUSTOM VARIABLES HERE",
}


BuffWatcher_WeakAuraGenerator.BaseAuraTemplate = {
    ["iconSource"] = -1,
    ["color"] = {
        1, -- [1]
        1, -- [2]
        1, -- [3]
        1, -- [4]
    },
    ["yOffset"] = 0,
    ["anchorPoint"] = "CENTER",
    ["cooldownSwipe"] = true,
    ["cooldownEdge"] = false,
    ["icon"] = true,
    ["triggers"] = {
        {
            ["trigger"] = {
                -- replace me
            },
            ["untrigger"] = {
            },
        }, -- [1]
        ["activeTriggerMode"] = -10,
    },
    ["internalVersion"] = 66,
    ["keepAspectRatio"] = false,
    ["selfPoint"] = "CENTER",
    ["desaturate"] = false,
    ["subRegions"] = {
        {
            ["type"] = "subbackground",
        }, -- [1]
        {
            ["text_shadowXOffset"] = 0,
            ["text_text_format_s_format"] = "none",
            ["text_text"] = "%s",
            ["text_shadowColor"] = {
                0, -- [1]
                0, -- [2]
                0, -- [3]
                1, -- [4]
            },
            ["text_selfPoint"] = "AUTO",
            ["text_automaticWidth"] = "Auto",
            ["text_fixedWidth"] = 64,
            ["anchorYOffset"] = 0,
            ["text_justify"] = "CENTER",
            ["rotateText"] = "NONE",
            ["type"] = "subtext",
            ["text_color"] = {
                1, -- [1]
                1, -- [2]
                1, -- [3]
                1, -- [4]
            },
            ["text_font"] = "Friz Quadrata TT",
            ["text_shadowYOffset"] = 0,
            ["text_wordWrap"] = "WordWrap",
            ["text_visible"] = true,
            ["text_anchorPoint"] = "INNER_BOTTOMRIGHT",
            ["text_fontSize"] = 12,
            ["anchorXOffset"] = 0,
            ["text_fontType"] = "OUTLINE",
        }, -- [2]
        {
            ["glowFrequency"] = 0.25,
            ["type"] = "subglow",
            ["useGlowColor"] = false,
            ["glowType"] = "buttonOverlay",
            ["glowLength"] = 10,
            ["glowYOffset"] = 0,
            ["glowColor"] = {
                1, -- [1]
                1, -- [2]
                1, -- [3]
                1, -- [4]
            },
            ["glowDuration"] = 1,
            ["glowXOffset"] = 0,
            ["glow"] = false,
            ["glowScale"] = 1,
            ["glowThickness"] = 1,
            ["glowLines"] = 8,
            ["glowBorder"] = false,
        }, -- [3]
    },
    ["height"] = -1,
    ["load"] = {
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
            ["multi"] = {
            },
        },
    },
    ["regionType"] = "icon",
    ["cooldown"] = true,
    ["parent"] = "INSERT PARENT HERE",
    ["xOffset"] = 0,
    ["authorOptions"] = {
        {
            ["type"] = "select",
            ["values"] = {
                "Buffs", -- [1]
                "Debuffs", -- [2]
                "Cast", -- [3]
                "Catch All", -- [4]
            },
            ["key"] = "triggerType",
            ["name"] = "Trigger Type",
            ["default"] = 1,
            ["width"] = 1,
        }, -- [1]
    },
    ["cooldownTextDisabled"] = false,
    ["zoom"] = 0,
    ["useCooldownModRate"] = true,
    ["config"] = {
    },
    ["id"] = "INSERT NAME HERE",
    ["anchorFrameType"] = "SCREEN",
    ["alpha"] = 1,
    ["width"] = -1,
    ["frameStrata"] = 1,
    ["inverse"] = false,
    ["actions"] = {
        ["start"] = {
        },
        ["init"] = {
            ["do_custom"] = true,
            ["custom"] = "",
        },
        ["finish"] = {
        },
    },
    ["conditions"] = {
    },
    ["information"] = {
    },
    ["animation"] = {
        ["start"] = {
            ["type"] = "none",
            ["easeStrength"] = 3,
            ["duration_type"] = "seconds",
            ["easeType"] = "none",
        },
        ["main"] = {
            ["type"] = "none",
            ["easeStrength"] = 3,
            ["duration_type"] = "seconds",
            ["easeType"] = "none",
        },
        ["finish"] = {
            ["type"] = "none",
            ["easeStrength"] = 3,
            ["duration_type"] = "seconds",
            ["easeType"] = "none",
        },
    },
}

BuffWatcher_WeakAuraGenerator.BorderTemplate ={
    ["border_size"] = 2,
    ["border_offset"] = 3,
    ["border_color"] = {
        1, -- [1]
        1, -- [2]
        1, -- [3]
        1, -- [4]
    },
    ["border_visible"] = false,
    ["border_edge"] = "1 Pixel",
    ["type"] = "subborder",
}

BuffWatcher_WeakAuraGenerator.DispelTypeBorders = {
    {
        ["border_size"] = 2,
        ["border_offset"] = 3,
        ["border_color"] = {
            0, -- [1]
            0.7686275243759155, -- [2]
            1, -- [3]
            1, -- [4]
        },
        ["border_visible"] = false,
        ["border_edge"] = "1 Pixel",
        ["type"] = "subborder",
    }, 
    {
        ["border_offset"] = 3,
        ["type"] = "subborder",
        ["border_color"] = {
            0, -- [1]
            0.7764706611633301, -- [2]
            0.09803922474384308, -- [3]
            1, -- [4]
        },
        ["border_visible"] = false,
        ["border_edge"] = "Square Full White",
        ["border_size"] = 2,
    },
    {
        ["border_size"] = 2,
        ["border_offset"] = 3,
        ["border_color"] = {
            0.8627451658248901, -- [1]
            0.7764706611633301, -- [2]
            0, -- [3]
            1, -- [4]
        },
        ["border_visible"] = false,
        ["border_edge"] = "Square Full White",
        ["type"] = "subborder",
    }, 
    {
        ["type"] = "subborder",
        ["border_size"] = 2,
        ["border_color"] = {
            0.6470588445663452, -- [1]
            0, -- [2]
            0.8627451658248901, -- [3]
            1, -- [4]
        },
        ["border_visible"] = false,
        ["border_edge"] = "Square Full White",
        ["border_offset"] = 3,
    }
}

BuffWatcher_WeakAuraGenerator.ConditionBuffDebuffOutlineTemplate = {
    ["check"] = {
        ["trigger"] = 1,
        ["variable"] = "outlineType",
        ["op"] = "==",
        ["value"] = "buff",
    },
    ["changes"] = {
        {
            ["value"] = true,
            ["property"] = "sub.1.border_visible",
        }, -- [1]
    }
}

BuffWatcher_WeakAuraGenerator.ConditionDispelTypeTemplate = {
    ["check"] = {
        ["trigger"] = 1,
        ["variable"] = "debuffClass",
        ["value"] = "INSERT_DISPEL_TYPE",
        ["op"] = "==",
    },
    ["changes"] = {
        {
            ["value"] = true,
            ["property"] = "sub.1.border_visible",
        }, -- [1]
    },
}

BuffWatcher_WeakAuraGenerator.BorderConditions = {
    {
        ["check"] = {
            ["trigger"] = 1,
            ["variable"] = "outlineType",
            ["op"] = "==",
            ["value"] = "buff",
        },
        ["changes"] = {
            {
                ["value"] = true,
                ["property"] = "sub.1.border_visible",
            }, -- [1]
        },
    }, -- [1]
    {
        ["check"] = {
            ["trigger"] = 1,
            ["variable"] = "outlineType",
            ["value"] = "debuff",
            ["op"] = "==",
        },
        ["changes"] = {
            {
                ["value"] = true,
                ["property"] = "sub.1.border_visible",
            }, -- [1]
        },
    }, -- [2]
    {
        ["check"] = {
            ["trigger"] = 1,
            ["variable"] = "debuffClass",
            ["value"] = "magic",
            ["op"] = "==",
        },
        ["changes"] = {
            {
                ["value"] = true,
                ["property"] = "sub.1.border_visible",
            }, -- [1]
        },
    }, -- [3]
    {
        ["check"] = {
            ["trigger"] = 1,
            ["variable"] = "debuffClass",
            ["op"] = "==",
            ["value"] = "poison",
        },
        ["changes"] = {
            {
                ["value"] = true,
                ["property"] = "sub.1.border_visible",
            }, -- [1]
        },
    }, -- [4]
    {
        ["check"] = {
            ["trigger"] = 1,
            ["variable"] = "debuffClass",
            ["value"] = "disease",
            ["op"] = "==",
        },
        ["changes"] = {
            {
                ["value"] = true,
                ["property"] = "sub.1.border_visible",
            }, -- [1]
        },
    }, -- [5]
    {
        ["check"] = {
            ["trigger"] = 1,
            ["op"] = "==",
            ["value"] = "curse",
            ["variable"] = "debuffClass",
        },
        ["changes"] = {
            {
                ["value"] = true,
                ["property"] = "sub.1.border_visible",
            }, -- [1]
        },
    }, -- [6]
}

---@type table<string, any>
BuffWatcher_WeakAuraGenerator.CastCustomTrigger = {
    ["type"] = "custom",
    ["useIgnoreExactSpellId"] = true,
    ["subeventPrefix"] = "SPELL",
    ["events"] = BuffWatcher_WeakAuraGenerator.GetScriptTriggerEvents(),
    ["spellIds"] = {
    },
    ["custom"] = "function(allstates, event, ...)\n    if (BuffWatcher_WeakAuraInterface_Singleton == nil \n        or not BuffWatcher_WeakAuraInterface_Singleton.IsRegistered()) then\n        return false\n    end\n    \n    return BuffWatcher_WeakAuraInterface_Singleton.DelegateTsu(allstates, event, \"PartyBuffs\", ...)\nend",
    ["names"] = {
    },
    ["check"] = "event",
    ["custom_type"] = "stateupdate"
}

---@type table<string, any>
BuffWatcher_WeakAuraGenerator.AnchorTrigger = {
    ["use_percenthealth"] = true,
    ["percenthealth_operator"] = {
        ">", -- [1]
    },
    ["percenthealth"] = {
        "0", -- [1]
    },
    ["event"] = "Health",
    ["unit"] = "INSERT_UNIT_HERE",
    ["type"] = "unit",
    ["useHostility"] = true,
    ["hostility"] = "INSERT_HOSTILITY_HERE",
    ["use_nameplateType"] = "INSERT_NAMEPLATE_TYPE_HERE",
    ["nameplateType"] = "hostile",
    ["use_unit"] = true,
    ["use_absorbMode"] = true,
	["use_absorbHealMode"] = true,
}