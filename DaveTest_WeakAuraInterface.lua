DaveTest_WeakAuraInterface = {}

function DaveTest_WeakAuraInterface:new()
    self = {};

    local storedSpells = nil
    local initialized = false
    local contexts = {}

    local resetNameplatesMap = function(context)
        local nameplatesByGuid = {}
        for i=1, 40 do
            local u = "nameplate"..i
            if UnitExists(u) then
                local guid = UnitGUID(u)
                nameplatesByGuid[guid] = u
            end
        end
        context.setNameplatesByGuid(nameplatesByGuid)
    end

    local initialize = function()
        initialized = true
    end

    local buildContexts = function(storedSpells)
        local newContexts = {}

        local nameplateDebuffs = DaveTest_AuraContext:new(
            storedSpells, 
            function(spells)
                local buffs = {}
                local debuffs = {}
                local casts = {}

                for k,spell in pairs(spells) do
                    local key = spell.spellId

                    if (spell.buffType == DaveTest_Shared_Singleton.SpellTypes.Debuff and spell.showOnNameplates == true) then
                        debuffs[key] = spell
                    end
                end

                return {
                    buffs = buffs,
                    debuffs = debuffs,
                    casts = casts
                }
            end, 
            true, 
            "NameplateDebuffs"
        )
        newContexts[nameplateDebuffs.getName()] = nameplateDebuffs

        local friendlyNameplateBuffs = DaveTest_AuraContext:new(
            storedSpells, 
            function(spells)
                local buffs = {}
                local debuffs = {}
                local casts = {}

                for k,spell in pairs(spells) do
                    local key = spell.spellId

                    if (spell.buffType == DaveTest_Shared_Singleton.SpellTypes.Buff and spell.showOnNameplates == true) then
                        buffs[key] = spell
                    elseif (spell.buffType == DaveTest_Shared_Singleton.SpellTypes.Cast and spell.showOnNameplates == true) then
                        casts[key] = spell
                    end
                end

                return {
                    buffs = buffs,
                    debuffs = debuffs,
                    casts = casts
                }
            end, 
            true, 
            "FriendlyNameplateBuffs"
        )
        newContexts[friendlyNameplateBuffs.getName()] = friendlyNameplateBuffs

        local partyBuffs = DaveTest_AuraContext:new(
            storedSpells, 
            function(spells)
                local buffs = {}
                local debuffs = {}
                local casts = {}

                for k,spell in pairs(spells) do
                    local key = spell.spellId

                    if (spell.buffType == DaveTest_Shared_Singleton.SpellTypes.Buff and spell.showInParty == true) then
                        buffs[key] = spell
                    elseif (spell.buffType == DaveTest_Shared_Singleton.SpellTypes.Cast and spell.showInParty == true) then
                        casts[key] = spell
                    end
                end

                return {
                    buffs = buffs,
                    debuffs = debuffs,
                    casts = casts
                }
            end, 
            false, 
            "PartyBuffs"
        )
        newContexts[partyBuffs.getName()] = partyBuffs

        return newContexts
    end

    self.RegisterSpells = function(incomingStoredSpells)
        storedSpells = incomingStoredSpells

        contexts = buildContexts(storedSpells)

        for k, context in pairs(contexts) do
            resetNameplatesMap(context)
        end
    end

    self.UpdateSpells = function()
        for k,v in pairs(contexts) do
            v:UpdateSpells()
        end
    end

    local getStateKey = function(type, spellId, targetGuid, auraId, contextName) 
        return type .. ":" .. spellId .. ":" .. targetGuid .. ":" .. auraId .. ":" .. contextName
    end

    local unitIsNameplate = function(unit)
        return string.find(unit, "nameplate") == 1
    end

    local handleBuffsAndDebuffs = function(allstates, context, ...)
        local weakAuraBundle = context.GetWeakAuraBundle()
        local hasUpdates = false

        local targetUnit = select(1, ...)
        local targetGuid = UnitGUID(targetUnit)
        local auraData = select(2, ...)

        if (context.isNameplate() and targetUnit ~= nil and not unitIsNameplate(targetUnit)) then
            return false
        end
        
        local keysByAuraId = context.getKeysByAuraId()
        local nameplatesByGuid = context.getNameplatesByGuid()

        if (targetUnit == "target") then
            return false
        end
    
        if (auraData.addedAuras ~= nil) then
            if (targetUnit == "player") then
                --DevTool:AddData(auraData.addedAuras, "fixme player aura added")
            end

            for i,addedAura in ipairs(auraData.addedAuras) do
                if (addedAura.isHelpful) then
                    local auraId = addedAura.auraInstanceID
                    local spellInfo = {GetSpellInfo(addedAura.spellId)}

                    --DevTool:AddData({ aura = addedAura, target = targetUnit, guid = targetGuid, weakauras = weakAuraBundle }, "isHelpful")

                    if (weakAuraBundle.buffs[addedAura.spellId] ~= nil) then

                        --DevTool:AddData({ aura = addedAura, target = targetUnit, guid = targetGuid, weakauras = weakAuraBundle }, "fixme buff inside check")

                        local watcherInfo = weakAuraBundle.buffs[addedAura.spellId]
                        local key = getStateKey(watcherInfo.buffType, watcherInfo.spellId, targetGuid, auraId, context.getName())

                        context.addKeyByGuid(targetGuid, key)
                        --DevTool:AddData({ aura = addedAura, target = targetUnit, guid = targetGuid, weakauras = weakAuraBundle }, "fixme buff addedAura")

                        keysByAuraId[auraId] = key

                        allstates[key] = {
                            show = true,
                            changed = true,
                            progressType = "timed",
                            duration = addedAura.duration,
                            name = addedAura.name,
                            icon = spellInfo[3],
                            caster = addedAura.sourceUnit,
                            autoHide = true,
                            showGlow = true,
                            sizeMultiplier = 1.5,
                            unit = targetUnit,
                            targetGuid = targetGuid
                        }

                        hasUpdates = true
                    else
                        local key = getStateKey(DaveTest_Shared_Singleton.SpellTypes.Buff, addedAura.spellId, targetGuid, auraId, context.getName())
                        
                        context.addKeyByGuid(targetGuid, key)
                        keysByAuraId[auraId] = key

                        if (allstates[key] == nil) then
                            allstates[key] = {
                                show = true,
                                changed = true,
                                progressType = "timed",
                                duration = addedAura.duration,
                                name = addedAura.name,
                                icon = spellInfo[3],
                                caster = addedAura.sourceUnit,
                                autoHide = true,
                                showGlow = false,
                                sizeMultiplier = 1,
                                unit = targetUnit,
                                targetGuid = targetGuid
                            }
                        end

                        hasUpdates = true
                    end
                elseif (addedAura.isHarmful and weakAuraBundle.debuffs[addedAura.spellId] ~= nil) then
                    local auraId = addedAura.auraInstanceID
                    local watcherInfo = weakAuraBundle.debuffs[addedAura.spellId]
                    local spellInfo = {GetSpellInfo(addedAura.spellId)}
                    local key = getStateKey(watcherInfo.buffType, watcherInfo.spellId, targetGuid, auraId, context.getName())
                    
                    context.addKeyByGuid(targetGuid, key)
                    keysByAuraId[auraId] = key

                    --DevTool:AddData({ aura = addedAura, target = targetUnit, guid = targetGuid, weakauras = weakAuraBundle }, "fixme debuff aura")

                    if (allstates[key] == nil) then
                        allstates[key] = {
                            show = true,
                            changed = true,
                            progressType = "timed",
                            duration = addedAura.duration,
                            name = addedAura.name,
                            icon = spellInfo[3],
                            caster = addedAura.sourceUnit,
                            autoHide = true,
                            showGlow = true,
                            sizeMultiplier = 3,
                            unit = nameplatesByGuid[targetGuid],
                            targetGuid = targetGuid
                        }
                    end

                    hasUpdates = true
                end
            end
        end

        if (auraData.removedAuraInstanceIDs ~= nil) then
            for i,removedAuraId in ipairs(auraData.removedAuraInstanceIDs) do
                local key = keysByAuraId[removedAuraId] 

                if (key ~= nil) then
                    if (allstates[key] ~= nil) then
                        allstates[key].show = false
                        allstates[key].changed = true
                        context.removeKeyByGuid(allstates[key].targetGuid, key)
                        hasUpdates = true
                    end
                    keysByAuraId[removedAuraId] = nil
                end
            end
        end

        if (auraData.updatedAuraInstanceIDs ~= nil) then
            for i,updatedAuraId in ipairs(auraData.updatedAuraInstanceIDs) do
                local getUpdateInfo = C_UnitAuras.GetAuraDataByAuraInstanceID(targetUnit, updatedAuraId)
                if (targetUnit == "player") then
                    --DevTool:AddData(getUpdateInfo, "fixme player aura updated")
                end
                local key = keysByAuraId[updatedAuraId] 
                if (key ~= nil) then
                    
                    --DevTool:AddData({ addedAura = getUpdateInfo, key = key }, "fixme aura key found")
                    if (allstates[key] == nil) then
                        keysByAuraId[updatedAuraId] = nil
                    else                
                        if (getUpdateInfo == nil) then
                            keysByAuraId[updatedAuraId] = nil
                            break
                        end
                        allstates[key].expirationTime = getUpdateInfo.expirationTime
                        allstates[key].duration = getUpdateInfo.duration
                        allstates[key].changed = true
                        hasUpdates = true
                    end
                end
            end
        end

        return hasUpdates
    end

    local handleCasts = function(allstates, context, ...)
        return false
        -- local weakAuraBundle = context.GetWeakAuraBundle()
        -- local hasUpdates = false

        -- local targetUnit = select(1, ...)9

        -- if (targetUnit == "target") then
        --     return false
        -- end

        -- local targetGuid = UnitGUID(targetUnit)
        -- local auraData = select(2, ...)

        -- local target = select(1, ...)

        -- local keysByAuraId = sharedContext.getKeysByAuraId()
        -- local nameplatesByGuid = sharedContext.getNameplatesByGuid()

        -- return hasUpdates
    end

    self.IsRegistered = function()
        return storedSpells ~= nil
    end

    -- self.HandleSharedEvents = function(allstates, event, ...)
    --     if (not initialized) then
    --         initialize()
    --         initialized = true
    --     end

    --     local nameplatesByGuid = context.getNameplatesByGuid()
        
    --     if (event == "NAME_PLATE_UNIT_REMOVED") then
    --         local unit = select(1, ...)
    --         local unitGuid = UnitGUID(unit)

    --         DevTool:AddData({ allstates = allstates, nameplatesByGuid = nameplatesByGuid, removed = unit },  "fixme nameplate removed")

    --         if (nameplatesByGuid[unitGuid] ~= nil) then
    --             for key, _ in context.getKeysByGuid(unitGuid) do
    --                 if (allstates[key] ~= nil) then
    --                     DevTool:AddData(nameplatesByGuid, 'removing unit ' .. unit .. ' guid ' .. unitGuid .. ' from key ' .. key)
    --                     allstates[key].unit = nil
    --                     allstates[key].changed = true
    --                     allstates[key].targetGuid = nil
    --                     hasUpdates = true
    --                 end
    --             end
    --         end

    --         nameplatesByGuid[unitGuid] = nil
    --     elseif (event == "NAME_PLATE_UNIT_ADDED") then
    --         local unit = select(1, ...)
    --         local unitGuid = UnitGUID(unit)

    --         DevTool:AddData({ allstates = allstates, nameplatesByGuid = nameplatesByGuid, added = unit }, "fixme nameplate added")

    --         for k,_ in context.getKeysByGuid(unitGuid) do
    --             if (allstates[k] ~= nil) then
    --                 DevTool:AddData(nameplatesByGuid, 'associating unit ' .. unit .. ' guid ' .. unitGuid .. ' with key ' .. k)
    --                 allstates[k].unit = unit
    --                 allstates[k].changed = true
    --                 allstates[k].targetGuid = unitGuid
    --                 hasUpdates = true
    --             end
    --         end

    --         nameplatesByGuid[unitGuid] = unit
    --     end
    -- end

    self.DelegateTsu = function(allstates, event, contextName, ...)
        local context = contexts[contextName]
        if (context == nil) then
            return false
        end

        if (not initialized) then
            initialize()
            initialized = true
        end

        local spellData = {...}
        local hasUpdates = false

        local eventSubtype = select(2, ...)

        local nameplatesByGuid = context.getNameplatesByGuid()

        if (event == "COMBAT_LOG_EVENT_UNFILTERED" and eventSubtype == "SPELL_CAST_SUCCESS") then
            local result = handleCasts(allstates, context, ...) 
            if (result == true) then
                hasUpdates = true
            end
            -- local spellId = select(12, ...)
            -- local sourceName = select(5, ...)
            -- local sourceGuid = select(4, ...)

            -- local weakAuraBundle = getWeakAuraBundle()
            -- local watcherInfo = weakAuraBundle.casts[spellId]

            -- if (watcherInfo == nil) then
            --     return false
            -- end

            -- for i = 1, GetNumGroupMembers() do
            --     local prefix = IsInRaid() and "raid" or "party" -- ternary operator equivalent
            --     local unit = prefix .. i

            --     local usePlayer = not IsInRaid() and sourceName == UnitName("player")
                
            --     if usePlayer then -- Technically not accurate if same name across realms
            --         unit = "player"
            --     end
                
            --     local unitGuid = UnitGUID(unit)
                
            --     if unitGuid == sourceGuid or usePlayer then
            --         local spellInfo = {GetSpellInfo(spellId)}

            --         local key = watcherInfo.buffType .. ":" .. watcherInfo.spellId .. ":" .. unit

            --         allstates[key] = {
            --             show = true,
            --             changed = true,
            --             progressType = "timed",
            --             duration = 10,
            --             name = sourceName,
            --             icon = spellInfo[3],
            --             caster = sourceName,
            --             autoHide = true,
            --             unit = unit
            --         }

            --         return true
            --     end

            --     return true
        elseif (event == "UNIT_AURA") then     
            local result = handleBuffsAndDebuffs(allstates, context, ...) 
            if (result == true) then
                hasUpdates = true
            end
        elseif (event == "NAME_PLATE_UNIT_REMOVED") then
            local nameplate = select(1, ...)
            local unitGuid = UnitGUID(nameplate)

            if (nameplatesByGuid[unitGuid] ~= nil) then
                for key, _ in context.getKeysByGuid(unitGuid) do
                    if (allstates[key] ~= nil) then
                        allstates[key].unit = nil
                        allstates[key].changed = true
                        allstates[key].targetGuid = nil
                        hasUpdates = true
                    end
                end
            end

            nameplatesByGuid[unitGuid] = nil
        elseif (event == "NAME_PLATE_UNIT_ADDED") then
            local nameplate = select(1, ...)
            local unitGuid = UnitGUID(nameplate)

            for k,_ in context.getKeysByGuid(unitGuid) do
                if (allstates[k] ~= nil) then
                    allstates[k].unit = nameplate
                    allstates[k].changed = true
                    allstates[k].targetGuid = unitGuid
                    hasUpdates = true
                end
            end

            nameplatesByGuid[unitGuid] = nameplate
        end
    
        return hasUpdates
    end

    self.DelegateCustomGrow = function(newPositions, activeRegions)
        DevTool:AddData(newPositions, "fixme newPositions")
        DevTool:AddData(activeRegions, "fixme activeRegions")
        local testParents = {}
        -- this function will produce a parabola shape
        for i = 1, #activeRegions do
            local uid = activeRegions[i].data.uid
            local parent = activeRegions[i].parent
            local state = CopyTable(activeRegions[i].region.state)
            local nameplate = {}
            if (state.unit ~= nil) then
                nameplate = C_NamePlate.GetNamePlateForUnit(state.unit)
            end
            testParents[i] = {
                parent = parent,
                relative = parent.relativeTo,
                rect = {parent.relativeTo:GetRect()},
                left = {parent.relativeTo:GetLeft()},
                center = {parent.relativeTo:GetCenter() },
                name = parent.relativeTo:GetName(),
                uid = uid,
                state = state,
                nameplate = nameplate
                --x = parent:GetXOffsetRelative()
            }
            if (nameplate ~= nil) then
                DevTool:AddData(nameplate, "fixme nameplate")
            end

            local realUnit = state.unit
            if (realUnit == 'player') then
                realUnit = 'party1'
            end
            if (string.find(realUnit, 'party') == 1) then
                local frame = _G["SUFHeaderpartyUnitButton1"]
                DevTool:AddData(frame, "fixme SUF frame")
                if (newPositions[frame] == nil) then 
                    newPositions[frame] = {}
                end
                newPositions[frame][activeRegions[i]] = {
                    40 * (i),
                    0
                }
            end

            
            
        end
        DevTool:AddData(testParents, "fixme testParents")
    end

    return self;
end

DaveTest_WeakAuraInterface_Singleton = DaveTest_WeakAuraInterface:new()