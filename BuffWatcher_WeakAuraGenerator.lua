---@class BuffWatcher_WeakAuraGenerator
BuffWatcher_WeakAuraGenerator = {}

---@param configuration BuffWatcher_Configuration
function BuffWatcher_WeakAuraGenerator:new(configuration)
    self = {};

    local baseCustomCastScript = "function(allstates, event, ...)\n    if (BuffWatcher_WeakAuraInterface_Singleton == nil \n        or not BuffWatcher_WeakAuraInterface_Singleton.IsRegistered()) then\n        return false\n    end\n    \n    \n    local castData = {\n        spellId = {0}\n    }\n    \n    return BuffWatcher_WeakAuraInterface_Singleton.DelegateTsu(allstates, event, \"{1}\", castData, ...)\nend"

    ---@param spellId integer
    ---@param contextName string
    ---@return string
    local getCustomCastScript = function(spellId, contextName)
        local modified = string.gsub(baseCustomCastScript, "{0}", spellId)
        modified = string.gsub(modified, "{1}", contextName)
        return modified
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
            return "party"
        elseif frameType == BuffWatcher_Shared_Singleton.FrameTypes.Arena then
            return "arena"
        elseif frameType == BuffWatcher_Shared_Singleton.FrameTypes.Raid then
            return "raid"
        else
            error("Unrecognized frame type " .. tostring(frameType))
        end
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

        local borderConditions = CopyTable(BuffWatcher_WeakAuraGenerator.DispelTypeConditions)

        BuffWatcher_Shared_Singleton.MergeIntoOrderedTable(weakAura.conditions, borderConditions)
    end

    ---@param isHostile boolean
    ---@return string
    local getHostilityValue = function(isHostile)
        return (isHostile and "hostile") or "friendly"
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

    ---@param allAuraIds number[]
    ---@param isBuff boolean
    ---@param name string
    ---@param isHostile boolean
    ---@param parent string
    ---@param size number
    ---@param frameType FrameTypes
    ---@param showDispelType boolean
    ---@param sizeMultiplier number
    self.GenerateCatchAllBuffDebuff = function(allAuraIds, isBuff, name, isHostile, parent, size, frameType, showDispelType, sizeMultiplier)
        local copy = CopyTable(BuffWatcher_WeakAuraGenerator.BaseAuraTemplate)

        copy.id = name
        copy.width = size
        copy.height = size
        copy.parent = parent

        local trigger = CopyTable(BuffWatcher_WeakAuraGenerator.CatchAllTrigger)

        local unitLabel = unitLabelFromFrameType(frameType)
        trigger.unit = unitLabel

        -- FIXME
        if (frameType == BuffWatcher_Shared_Singleton.FrameTypes.Nameplate) then
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


    --- party 
    -- ["triggers"] = {
    --     {
    --         ["trigger"] = {
    --             ["auranames"] = {
    --             },
    --             ["use_absorbMode"] = true,
    --             ["useHostility"] = true,
    --             ["names"] = {
    --             },
    --             ["auraspellids"] = {
    --                 "589", -- [1]
    --             },
    --             ["debuffType"] = "HARMFUL",
    --             ["showClones"] = true,
    --             ["useName"] = false,
    --             ["use_absorbHealMode"] = true,
    --             ["subeventSuffix"] = "_CAST_START",
    --             ["hostility"] = "hostile",
    --             ["percenthealth"] = {
    --                 "0", -- [1]
    --             },
    --             ["event"] = "Health",
    --             ["type"] = "unit",
    --             ["use_unit"] = true,
    --             ["spellIds"] = {
    --             },
    --             ["useExactSpellId"] = true,
    --             ["subeventPrefix"] = "SPELL",
    --             ["use_percenthealth"] = true,
    --             ["percenthealth_operator"] = {
    --                 ">", -- [1]
    --             },
    --             ["unit"] = "party",
    --         },
    --         ["untrigger"] = {
    --         },
    --     }, -- [1]



--- nameplate 
-- ["triggers"] = {
--     {
--         ["trigger"] = {
--             ["auranames"] = {
--             },
--             ["use_absorbMode"] = true,
--             ["useHostility"] = true,
--             ["hostility"] = "hostile",
--             ["nameplateType"] = "hostile",
--             ["useName"] = false,
--             ["debuffType"] = "HARMFUL",
--             ["showClones"] = true,
--             ["type"] = "unit",
--             ["use_absorbHealMode"] = true,
--             ["subeventSuffix"] = "_CAST_START",
--             ["unit"] = "nameplate",
--             ["percenthealth"] = {
--                 "0", -- [1]
--             },
--             ["event"] = "Health",
--             ["names"] = {
--             },
--             ["auraspellids"] = {
--                 "589", -- [1]
--             },
--             ["subeventPrefix"] = "SPELL",
--             ["spellIds"] = {
--             },
--             ["useExactSpellId"] = true,
--             ["use_nameplateType"] = true,
--             ["use_percenthealth"] = true,
--             ["percenthealth_operator"] = {
--                 ">", -- [1]
--             },
--             ["use_unit"] = true,
--         },
--         ["untrigger"] = {
--         },
--     }, -- [1]


-- ---@type table<string, any>
-- BuffWatcher_WeakAuraGenerator.AnchorTrigger = {
--     ["use_percenthealth"] = true,
--     ["percenthealth_operator"] = {
--         ">", -- [1]
--     },
--     ["percenthealth"] = {
--         "0", -- [1]
--     },
--     ["unit"] = "INSERT_UNIT_HERE",
--     ["useHostility"] = true,
--     ["hostility"] = "INSERT_HOSTILITY_HERE",
--     ["use_nameplateType"] = "INSERT_NAMEPLATE_TYPE_HERE",
--     ["nameplateType"] = "hostile",
-- }

-- ["BuffWatcher Spell - Enemy Nameplate Buffs - Test Anchor - 1"] = {
--     ["iconSource"] = 0,
--     ["xOffset"] = 0,
--     ["yOffset"] = 0,
--     ["anchorPoint"] = "CENTER",
--     ["cooldownSwipe"] = true,
--     ["cooldownEdge"] = false,
--     ["actions"] = {
--         ["start"] = {
--         },
--         ["init"] = {
--         },
--         ["finish"] = {
--         },
--     },
--     ["triggers"] = {
--         {
--             ["trigger"] = {
--                 ["names"] = {
--                 },
--                 ["type"] = "aura2",
--                 ["subeventPrefix"] = "SPELL",
--                 ["nameplateType"] = "hostile",
--                 ["subeventSuffix"] = "_CAST_START",
--                 ["percenthealth"] = {
--                     "0", -- [1]
--                 },
--                 ["event"] = "Health",
--                 ["unit"] = "nameplate",
--                 ["useHostility"] = true,
--                 ["hostility"] = "hostile",
--                 ["spellIds"] = {
--                 },
--                 ["use_unit"] = true,
--                 ["use_nameplateType"] = true,
--                 ["use_percenthealth"] = true,
--                 ["percenthealth_operator"] = {
--                     ">", -- [1]
--                 },
--                 ["debuffType"] = "HELPFUL",
--             },
--             ["untrigger"] = {
--             },
--         }, -- [1]
--         ["activeTriggerMode"] = -10,
--     },
--     ["internalVersion"] = 68,
--     ["keepAspectRatio"] = false,
--     ["selfPoint"] = "CENTER",
--     ["desaturate"] = false,
--     ["subRegions"] = {
--         {
--             ["type"] = "subbackground",
--         }, -- [1]
--         {
--             ["text_shadowXOffset"] = 0,
--             ["text_text_format_s_format"] = "none",
--             ["text_text"] = "%s",
--             ["text_shadowColor"] = {
--                 0, -- [1]
--                 0, -- [2]
--                 0, -- [3]
--                 1, -- [4]
--             },
--             ["text_selfPoint"] = "AUTO",
--             ["text_automaticWidth"] = "Auto",
--             ["text_fixedWidth"] = 64,
--             ["anchorYOffset"] = 0,
--             ["text_justify"] = "CENTER",
--             ["rotateText"] = "NONE",
--             ["type"] = "subtext",
--             ["text_color"] = {
--                 1, -- [1]
--                 1, -- [2]
--                 1, -- [3]
--                 1, -- [4]
--             },
--             ["text_font"] = "Friz Quadrata TT",
--             ["text_shadowYOffset"] = 0,
--             ["text_wordWrap"] = "WordWrap",
--             ["text_visible"] = true,
--             ["text_anchorPoint"] = "INNER_BOTTOMRIGHT",
--             ["text_fontSize"] = 12,
--             ["anchorXOffset"] = 0,
--             ["text_fontType"] = "OUTLINE",
--         }, -- [2]
--         {
--             ["glowFrequency"] = 0.25,
--             ["type"] = "subglow",
--             ["glowDuration"] = 1,
--             ["glowType"] = "buttonOverlay",
--             ["glowLength"] = 10,
--             ["glowYOffset"] = 0,
--             ["glowColor"] = {
--                 1, -- [1]
--                 1, -- [2]
--                 1, -- [3]
--                 1, -- [4]
--             },
--             ["useGlowColor"] = false,
--             ["glowXOffset"] = 0,
--             ["glow"] = false,
--             ["glowScale"] = 1,
--             ["glowThickness"] = 1,
--             ["glowLines"] = 8,
--             ["glowBorder"] = false,
--         }, -- [3]
--     },
--     ["height"] = 32,
--     ["load"] = {
--         ["use_never"] = false,
--         ["talent"] = {
--             ["multi"] = {
--             },
--         },
--         ["class"] = {
--             ["multi"] = {
--             },
--         },
--         ["spec"] = {
--             ["multi"] = {
--             },
--         },
--         ["size"] = {
--             ["multi"] = {
--             },
--         },
--     },
--     ["displayIcon"] = 450907,
--     ["regionType"] = "icon",
--     ["uid"] = "zF8GjtyD)Hq",
--     ["parent"] = "BuffWatcher Group - Enemy Nameplate Buffs",
--     ["useCooldownModRate"] = true,
--     ["anchorFrameParent"] = false,
--     ["cooldown"] = true,
--     ["animation"] = {
--         ["start"] = {
--             ["type"] = "none",
--             ["easeStrength"] = 3,
--             ["duration_type"] = "seconds",
--             ["easeType"] = "none",
--         },
--         ["main"] = {
--             ["type"] = "none",
--             ["easeStrength"] = 3,
--             ["duration_type"] = "seconds",
--             ["easeType"] = "none",
--         },
--         ["finish"] = {
--             ["type"] = "none",
--             ["easeStrength"] = 3,
--             ["duration_type"] = "seconds",
--             ["easeType"] = "none",
--         },
--     },
--     ["cooldownTextDisabled"] = false,
--     ["authorOptions"] = {
--     },
--     ["zoom"] = 0,
--     ["id"] = "BuffWatcher Spell - Enemy Nameplate Buffs - Test Anchor - 1",
--     ["color"] = {
--         1, -- [1]
--         1, -- [2]
--         1, -- [3]
--         1, -- [4]
--     },
--     ["alpha"] = 1,
--     ["anchorFrameType"] = "SCREEN",
--     ["icon"] = true,
--     ["config"] = {
--     },
--     ["inverse"] = false,
--     ["width"] = 32,
--     ["conditions"] = {
--     },
--     ["information"] = {
--     },
--     ["frameStrata"] = 1,
-- },

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

---@type table<string, any>
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

    --- party 
    -- ["triggers"] = {
    --     {
    --         ["trigger"] = {
    --             ["auranames"] = {
    --             },
    --             ["use_absorbMode"] = true,
    --             ["useHostility"] = true,
    --             ["names"] = {
    --             },
    --             ["auraspellids"] = {
    --                 "589", -- [1]
    --             },
    --             ["debuffType"] = "HARMFUL",
    --             ["showClones"] = true,
    --             ["useName"] = false,
    --             ["use_absorbHealMode"] = true,
    --             ["subeventSuffix"] = "_CAST_START",
    --             ["hostility"] = "hostile",
    --             ["percenthealth"] = {
    --                 "0", -- [1]
    --             },
    --             ["event"] = "Health",
    --             ["type"] = "unit",
    --             ["use_unit"] = true,
    --             ["spellIds"] = {
    --             },
    --             ["useExactSpellId"] = true,
    --             ["subeventPrefix"] = "SPELL",
    --             ["use_percenthealth"] = true,
    --             ["percenthealth_operator"] = {
    --                 ">", -- [1]
    --             },
    --             ["unit"] = "party",
    --         },
    --         ["untrigger"] = {
    --         },
    --     }, -- [1]



--- nameplate 
-- ["triggers"] = {
--     {
--         ["trigger"] = {
--             ["auranames"] = {
--             },
--             ["use_absorbMode"] = true,
--             ["useHostility"] = true,
--             ["hostility"] = "hostile",
--             ["nameplateType"] = "hostile",
--             ["use_nameplateType"] = true,
--             ["useName"] = false,
--             ["debuffType"] = "HARMFUL",
--             ["showClones"] = true,
--             ["type"] = "unit",
--             ["use_absorbHealMode"] = true,
--             ["subeventSuffix"] = "_CAST_START",
--             ["unit"] = "nameplate",
--             ["percenthealth"] = {
--                 "0", -- [1]
--             },
--             ["event"] = "Health",
--             ["names"] = {
--             },
--             ["auraspellids"] = {
--                 "589", -- [1]
--             },
--             ["subeventPrefix"] = "SPELL",
--             ["spellIds"] = {
--             },
--             ["useExactSpellId"] = true,
--             ["use_percenthealth"] = true,
--             ["percenthealth_operator"] = {
--                 ">", -- [1]
--             },
--             ["use_unit"] = true,
--         },
--         ["untrigger"] = {
--         },
--     }, -- [1]