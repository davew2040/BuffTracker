DaveTest_WeakAuraInterface = {}

function DaveTest_WeakAuraInterface:new()
    self = {};

    local context = {
        --spell bundle
        --stateKeysByAuraId 
        --nameplatesByGuid
        --stateKeysByGuid
    }

    local storedSpells = nil
    local savedWeakAuraBundle = nil
    local keysByAuraId = {}
    local nameplatesByGuid = {}
    local keysByGuid = {}
    local initialized = false

    self.RegisterSpells = function(incomingStoredSpells)
        storedSpells = incomingStoredSpells
    end

    local getStateKey = function(type, spellId, targetGuid, auraId) 
        return type .. ":" .. spellId .. ":" .. targetGuid .. ":" .. auraId
    end

    local addKeyByGuid = function(targetGuid, key)
        if (keysByGuid[targetGuid] == nil) then
            keysByGuid[targetGuid] = {}
        end
        keysByGuid[targetGuid][key] = true 
    end

    local removeKeyByGuid = function(targetGuid, key)
        if (keysByGuid[targetGuid] == nil) then
            return
        end

        keysByGuid[targetGuid][key] = nil
        local tableKeyCount = DaveTest_Shared_Singleton.GetTableKeyCount(keysByGuid[targetGuid])
        if (tableKeyCount == 0) then
            keysByGuid[targetGuid] = nil
        end
    end

    local getKeysByGuid = function(targetGuid) 
        local keys = {}
        if (keysByGuid[targetGuid] == nil) then
            return pairs(keys)
        end
        return pairs(keysByGuid[targetGuid])
    end

    local bundleSpellData = function()
        local buffs = {}
        local debuffs = {}
        local casts = {}

        local spells = DaveTest_DbAccessor_Singleton.GetSpells()

        for k,v in pairs(spells) do
            if (v.buffType == DaveTest_Shared_Singleton.SpellTypes.Buff) then
                buffs[v.spellId] = v
            elseif (v.buffType == DaveTest_Shared_Singleton.SpellTypes.Debuff) then
                debuffs[v.spellId] = v
            elseif (v.buffType == DaveTest_Shared_Singleton.SpellTypes.Cast) then
                casts[v.spellId] = v
            end
        end

        return {
            buffs = buffs,
            debuffs = debuffs,
            casts = casts
        }
    end

    local resetNameplatesMap = function()
        nameplatesByGuid = {}
        for i=1, 40 do
            local u = "nameplate"..i
            if UnitExists(u) then
                local G = UnitGUID(u)
                nameplatesByGuid[guid] = u
            end
        end
    end

    local getWeakAuraBundle = function()
        if (savedWeakAuraBundle == nil) then
            savedWeakAuraBundle = bundleSpellData()
        end

        return savedWeakAuraBundle
    end

    local handleBuffsAndDebuffs = function(allstates, ...)
        local weakAuraBundle = getWeakAuraBundle()
        local hasUpdates = false

        local targetUnit = select(1, ...)
        local targetGuid = UnitGUID(targetUnit)
        local auraData = select(2, ...)

        local target = select(1, ...)

        if (targetUnit == "target") then
            return false
        end
        
        if (auraData.addedAuras ~= nil) then
            for i,addedAura in ipairs(auraData.addedAuras) do
                if (addedAura.isHelpful and weakAuraBundle.buffs[addedAura.spellId] ~= nil and targetUnit ~= "target") then
                    
                    -- DevTool:AddData(targetGuid, "adding aura to unit ".. targetGuid)
                    -- name, realm = UnitName(targetUnit)
                    -- DevTool:AddData(name, "adding aura to name ".. (name or 'none'))
                    -- DevTool:AddData(realm, "adding aura to realm ".. (realm or 'none'))

                    -- local watcherInfo = weakAuraBundle.buffs[spellId]
                    -- for i = 1, GetNumGroupMembers() do
                    --     local prefix = IsInRaid() and "raid" or "party" -- ternary operator equivalent
                    --     local unit = prefix .. i

                    --     local usePlayer = not IsInRaid() and addedAura.sourceUnit == UnitName("player")
                        
                    --     if usePlayer then -- Technically not accurate if same name across realms
                    --         unit = "player"
                    --     end
                        
                    --     if addedAura.sourceUnit == unit or usePlayer then
                    --         local spellInfo = {GetSpellInfo(addedAura.spellId)}

                    --         local key = watcherInfo.buffType .. ":" .. watcherInfo.spellId .. ":" .. unit

                    --         if (addedAura.sourceUnit == "player") then
                    --             print('fixme adding ' .. key)
                    --         end        

                    --         allstates[key] = {
                    --             show = true,
                    --             changed = true,
                    --             progressType = "timed",
                    --             duration = 5,
                    --             name = addedAura.name,
                    --             icon = spellInfo[3],
                    --             caster = addedAura.sourceUnit,
                    --             autoHide = true,
                    --             unit = unit,
                    --             targetGuid = targetGuid
                    --         }

                    --         hasUpdates = true
                    --     end
                    -- end
                elseif (addedAura.isHarmful and weakAuraBundle.debuffs[addedAura.spellId] ~= nil and targetUnit ~= "target") then
                    local auraId = addedAura.auraInstanceID
                    local watcherInfo = weakAuraBundle.debuffs[addedAura.spellId]
                    local spellInfo = {GetSpellInfo(addedAura.spellId)}
                    local key = getStateKey(watcherInfo.buffType, watcherInfo.spellId, targetGuid, auraId)
                    
                    addKeyByGuid(targetGuid, key)
                    keysByAuraId[auraId] = key

                    DevTool:AddData(key, 'adding key ' .. key)

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
                        removeKeyByGuid(allstates[key].targetGuid, key)
                        hasUpdates = true
                    end
                    keysByAuraId[removedAuraId] = nil
                end
            end
        end

        if (auraData.updatedAuraInstanceIDs ~= nil) then
            for i,updatedAuraId in ipairs(auraData.updatedAuraInstanceIDs) do
                local key = keysByAuraId[updatedAuraId] 
                if (key ~= nil) then
                    if (allstates[key] == nil) then
                        keysByAuraId[updatedAuraId] = nil
                    else                
                        local getUpdateInfo = C_UnitAuras.GetAuraDataByAuraInstanceID(targetUnit, updatedAuraId)
                        if (getUpdateInfo == nil) then
                            keysByAuraId[updatedAuraId] = nil
                            break
                        end
                        allstates[key].expirationTime = getUpdateInfo.expirationTime
                        allstates[key].changed = true
                        hasUpdates = true
                    end
                end
            end
        end

        return hasUpdates
    end

    self.IsRegistered = function()
        return storedSpells ~= nil
    end

    self.UpdateSpells = function()
        savedWeakAuraBundle = bundleSpellData()
    end

    self.DelegateTsu = function(allstates, event, ...)
        if (not initialized) then
            resetNameplatesMap()
            initialized = true
        end

        local spellData = {...}
        local hasUpdates = false

        local eventSubtype = select(2, ...)

        if (event == "COMBAT_LOG_EVENT_UNFILTERED" and eventSubtype == "SPELL_CAST_SUCCESS") then
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
            local result = handleBuffsAndDebuffs(allstates, ...) 
            if (result == true) then
                hasUpdates = true
            end
        elseif (event == "NAME_PLATE_UNIT_REMOVED") then
            local unit = select(1, ...)
            local unitGuid = UnitGUID(unit)

            if (nameplatesByGuid[unitGuid] ~= nil) then
                for k,v in getKeysByGuid(unitGuid) do
                    if (allstates[k] ~= nil) then
                        DevTool:AddData(nameplatesByGuid, 'removing unit ' .. unit .. ' guid ' .. unitGuid .. ' from key ' .. k)
                        allstates[k].unit = nil
                        allstates[k].changed = true
                        allstates[k].targetGuid = nil
                        hasUpdates = true
                    end
                end
            end

            nameplatesByGuid[unitGuid] = nil
        elseif (event == "NAME_PLATE_UNIT_ADDED") then
            local unit = select(1, ...)
            local unitGuid = UnitGUID(unit)

            for k,v in getKeysByGuid(unitGuid) do
                if (allstates[k] ~= nil) then
                    DevTool:AddData(nameplatesByGuid, 'associating unit ' .. unit .. ' guid ' .. unitGuid .. ' with key ' .. k)
                    allstates[k].unit = unit
                    allstates[k].changed = true
                    allstates[k].targetGuid = unitGuid
                    hasUpdates = true
                end
            end

            nameplatesByGuid[unitGuid] = unit
        end
    
        return hasUpdates
    end

    return self;
end

DaveTest_WeakAuraInterface_Singleton = DaveTest_WeakAuraInterface:new()