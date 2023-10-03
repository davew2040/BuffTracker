BuffWatcher_WeakAuraGenerator = {}

function BuffWatcher_WeakAuraGenerator:new()
    self = {};

    local baseCustomCastScript = "function(allstates, event, ...)\n    if (BuffWatcher_WeakAuraInterface_Singleton == nil \n        or not BuffWatcher_WeakAuraInterface_Singleton.IsRegistered()) then\n        return false\n    end\n    \n    \n    local castData = {\n        spellId = {0}\n    }\n    \n    return BuffWatcher_WeakAuraInterface_Singleton.DelegateTsu(allstates, event, \"{1}\", castData, ...)\nend"

    local getCustomCastScript = function(spellId, contextName)
        local modified = string.gsub(baseCustomCastScript, "{0}", spellId)
        modified = string.gsub(modified, "{1}", contextName)
        return modified
    end

    local getCastTrigger = function(spellId, contextName)
        local triggerCopy = CopyTable(BuffWatcher_WeakAuraGenerator.CastCustomTrigger)
        local modifiedScript = getCustomCastScript(spellId, contextName)
        DevTool:AddData(modifiedScript, "fixme modifiedScript")
        triggerCopy.custom = modifiedScript

        return triggerCopy
    end

    local spreadAuraIds = function(incomingAuraIds)
        local result = {}

        for k, _ in pairs(incomingAuraIds) do
            table.insert(result, tostring(k))
        end

        return result
    end

    local unitLabelFromFrameType = function(frameType)
        if frameType == BuffWatcher_Shared_Singleton.FrameTypes.Nameplate then
            return "nameplate"
        elseif frameType == BuffWatcher_Shared_Singleton.FrameTypes.Party then
            return "party"
        elseif frameType == BuffWatcher_Shared_Singleton.FrameTypes.Arena then
            return "arena"
        elseif frameType == BuffWatcher_Shared_Singleton.FrameTypes.Raid then
            return "raid"
        else
            error("Unrecognized frame type " .. frameType)
        end
    end

    local addDispelType = function(weakAura, multiplier)
        local borderSize = BuffWatcher_Configuration_Singleton.GetBorderSize()
        local borderOffset = BuffWatcher_Configuration_Singleton.GetBorderOffset()

        local borderSubregions = CopyTable(BuffWatcher_WeakAuraGenerator.DispelTypeBorders)
        for _, subregion in pairs(borderSubregions) do
            subregion.border_size = borderSize * multiplier
            subregion.border_offset = borderOffset * multiplier
        end

        BuffWatcher_Shared_Singleton.MergeIntoOrderedTable(weakAura.subRegions, borderSubregions)

        local borderConditions = CopyTable(BuffWatcher_WeakAuraGenerator.DispelTypeConditions)

        BuffWatcher_Shared_Singleton.MergeIntoOrderedTable(weakAura.conditions, borderConditions)

        DevTool:AddData({
            borderSubregions  = borderSubregions,
            borderConditions = borderConditions,
            weakAura = weakAura
        }, "fixme - borders added")
    end

    self.GenerateDynamicGroup = function(name, frameType)
        local copy = CopyTable(BuffWatcher_WeakAuraGenerator.DynamicGroupTemplate)
        copy.id = name

        local anchorType = "UNITFRAME"
        if (frameType == BuffWatcher_Shared_Singleton.FrameTypes.Nameplate) then
            anchorType = "NAMEPLATE"
        end

        copy.anchorPerUnit = anchorType

        return copy
    end

    self.GenerateBuffDebuff = function(buffId, isBuff, name, parent, size, frameType, showDispelType, sizeMultiplier)
        local copy = CopyTable(BuffWatcher_WeakAuraGenerator.BuffDebuffTemplate)

        copy.id = name
        copy.width = size
        copy.height = size
        copy.parent = parent

        local trigger = CopyTable(BuffWatcher_WeakAuraGenerator.BuffDebuffTrigger)

        local unitLabel = unitLabelFromFrameType(frameType)
        trigger.unit = unitLabel
        trigger.auraspellids[1] = tostring(buffId)

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

    self.GenerateCatchAllBuffDebuff = function(allAuraIds, isBuff, name, parent, size, frameType, showDispelType, sizeMultiplier)
        local copy = CopyTable(BuffWatcher_WeakAuraGenerator.BuffDebuffTemplate)

        copy.id = name
        copy.width = size
        copy.height = size
        copy.parent = parent

        local trigger = CopyTable(BuffWatcher_WeakAuraGenerator.CatchAllTrigger)

        local unitLabel = unitLabelFromFrameType(frameType)
        trigger.unit = unitLabel

        trigger.ignoreAuraSpellids = spreadAuraIds(allAuraIds)

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

    self.GenerateCast = function(name, spellId, parent, size, icon, contextName)
        local copy = CopyTable(BuffWatcher_WeakAuraGenerator.BuffDebuffTemplate)

        copy.id = name
        copy.width = size
        copy.height = size
        copy.parent = parent
        copy.displayIcon = icon

        local trigger = getCastTrigger(spellId, contextName)

        DevTool:AddData(trigger, "fixme cast trigger")

        copy.triggers[1].trigger = trigger

        return copy
    end

    return self
end

BuffWatcher_WeakAuraGenerator.DynamicGroupTemplate = {
    ["grow"] = "RIGHT",
    ["controlledChildren"] = {
    },
    ["borderBackdrop"] = "Blizzard Tooltip",
    ["xOffset"] = 0,
    ["yOffset"] = 0,
    ["anchorPoint"] = "CENTER",
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
    ["selfPoint"] = "TOP",
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
}

BuffWatcher_WeakAuraGenerator.BuffDebuffTemplate = {
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

BuffWatcher_WeakAuraGenerator.DispelTypeConditions = {
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
                ["property"] = "sub.4.border_visible",
            }, -- [1]
        },
    }, -- [1]
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
                ["property"] = "sub.5.border_visible",
            }, -- [1]
        },
    }, -- [2]
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
                ["property"] = "sub.6.border_visible",
            }, -- [1]
        },
    }, -- [3]
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
                ["property"] = "sub.7.border_visible",
            }, -- [1]
        },
    }, -- [4]
}

BuffWatcher_WeakAuraGenerator.CastCustomTrigger = {
    ["type"] = "custom",
    ["useIgnoreExactSpellId"] = true,
    ["subeventPrefix"] = "SPELL",
    ["events"] = "export_watcher_data CLEU:SPELL_CAST_SUCCESS UNIT_AURA NAME_PLATE_UNIT_ADDED NAME_PLATE_UNIT_REMOVED",
    ["spellIds"] = {
    },
    ["custom"] = "function(allstates, event, ...)\n    if (BuffWatcher_WeakAuraInterface_Singleton == nil \n        or not BuffWatcher_WeakAuraInterface_Singleton.IsRegistered()) then\n        return false\n    end\n    \n    return BuffWatcher_WeakAuraInterface_Singleton.DelegateTsu(allstates, event, \"PartyBuffs\", ...)\nend",
    ["names"] = {
    },
    ["check"] = "event",
    ["custom_type"] = "stateupdate",
}

BuffWatcher_WeakAuraGenerator_Singleton = BuffWatcher_WeakAuraGenerator:new()