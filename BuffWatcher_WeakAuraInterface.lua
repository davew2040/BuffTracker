BuffWatcher_WeakAuraInterface = {}

function BuffWatcher_WeakAuraInterface:new()
    self = {};

    local storedSpellsRegistry = nil
    local initialized = false
    local contexts = {}

    local resetNameplatesMap = function(context)
        context.unlinkAllNameplates()
        for i=1, 40 do
            local u = "nameplate"..i
            if UnitExists(u) then
                local guid = UnitGUID(u)
                context.linkNameplateToGuid(u, guid)
            end
        end
    end

    local initialize = function()
        initialized = true
    end

    local buildContexts = function(storedSpells)
        local newContexts = {}

        -- local nameplateDebuffs = BuffWatcher_AuraContext:new(
        --     storedSpells, 
        --     function(spells)
        --         local buffs = {}
        --         local debuffs = {}
        --         local casts = {}

        --         for k,spell in pairs(spells) do
        --             local key = spell.spellId

        --             if (spell.buffType == BuffWatcher_Shared_Singleton.SpellTypes.Debuff and spell.showOnNameplates == true) then
        --                 debuffs[key] = spell
        --             end
        --         end

        --         return {
        --             buffs = buffs,
        --             debuffs = debuffs,
        --             casts = casts
        --         }
        --     end, 
        --     true, 
        --     "NameplateDebuffs",
        --     BuffWatcher_Shared_Singleton.FrameTypes.Nameplate,
        --     false, 
        --     true, 
        --     false
        -- )
        -- newContexts[nameplateDebuffs.getName()] = nameplateDebuffs

        local friendlyNameplateBuffs = BuffWatcher_AuraContext:new(
            storedSpells, 
            function(spells)
                local buffs = {}
                local debuffs = {}
                local casts = {}

                for k,spell in pairs(spells) do
                    local key = spell.spellId

                    if (spell.buffType == BuffWatcher_Shared_Singleton.SpellTypes.Buff and spell.showOnNameplates == true) then
                        buffs[key] = spell
                    elseif (spell.buffType == BuffWatcher_Shared_Singleton.SpellTypes.Cast and spell.showOnNameplates == true) then
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
            "FriendlyNameplateBuffs",
            BuffWatcher_Shared_Singleton.FrameTypes.Nameplate,
            true, 
            false, 
            false
        )
        newContexts[friendlyNameplateBuffs.getName()] = friendlyNameplateBuffs

        local partyBuffs = BuffWatcher_AuraContext:new(
            storedSpells, 
            function(spells)
                local buffs = {}
                local debuffs = {}
                local casts = {}

                for k,spell in pairs(spells) do
                    local key = spell.spellId

                    if (spell.buffType == BuffWatcher_Shared_Singleton.SpellTypes.Buff and spell.showInParty == true) then
                        buffs[key] = spell
                    elseif (spell.buffType == BuffWatcher_Shared_Singleton.SpellTypes.Cast and spell.showInParty == true) then
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
            "PartyBuffs",
            BuffWatcher_Shared_Singleton.FrameTypes.Party,
            true,
            false, 
            true
        )
        newContexts[partyBuffs.getName()] = partyBuffs

        return newContexts
    end

    local hasSufPartyFrames = function()
        local firstFrame = BuffWatcher_Shared_Singleton.SufPlayerFramePrefix .. '1'
        return _G[firstFrame] ~= nil
    end

    self.RegisterSpells = function(incomingStoredSpellsRegistry)
        storedSpellsRegistry = incomingStoredSpellsRegistry

        contexts = buildContexts(storedSpellsRegistry)

        for k, context in pairs(contexts) do
            resetNameplatesMap(context)
        end
    end

    self.UpdateSpells = function()
        for k,v in pairs(contexts) do
            v:UpdateSpells()
        end
    end

    local getBuffDebuffStateKey = function(type, spellId, targetGuid, auraId, contextName) 
        return type .. ":" .. spellId .. ":" .. targetGuid .. ":" .. auraId .. ":" .. contextName
    end


    local handleBuffAddOrUpdate = function(allstates, context, addedAura, targetUnit, normalizedUnit, targetGuid)
        if (not context.includeBuffsAndCasts() or not BuffWatcher_Shared_Singleton.UnitNameMatchesFrameType(normalizedUnit, context.getFrameType())) then
            return false
        end

        local weakAuraBundle = context.GetWeakAuraBundle()
        local auraId = addedAura.auraInstanceID
        local spellInfo = {GetSpellInfo(addedAura.spellId)}

        if (weakAuraBundle.buffs[addedAura.spellId] ~= nil) then
            local watcherInfo = weakAuraBundle.buffs[addedAura.spellId]
            local key = getBuffDebuffStateKey(watcherInfo.buffType, watcherInfo.spellId, targetGuid, auraId, context.getName())

            if (allstates[key] == nil) then
                DevTool:AddData(key, "fixme adding new in add/update")
                context.addAuraIdToKeyEntry(auraId, key)
                context.addKeyByGuid(targetGuid, key)

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
                    sizeMultiplier = watcherInfo.sizeMultiplier,
                    unit = normalizedUnit,
                    index = BuffWatcher_Shared_Singleton.GetAuraIndexByPriority(watcherInfo.priority),
                    targetGuid = targetGuid
                }
            else
                DevTool:AddData(key, "fixme handling update in add/update")
                allstates[key].duration = addedAura.duration
                allstates[key].expirationTime = addedAura.expirationTime
                allstates[key].changed = true
            end

            return true
        elseif (context.showUnlistedAuras()) then
            local key = getBuffDebuffStateKey(BuffWatcher_Shared_Singleton.SpellTypes.Buff, addedAura.spellId, targetGuid, auraId, context.getName())
            
            context.addAuraIdToKeyEntry(auraId, key)
            context.addKeyByGuid(targetGuid, key)

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
                    sizeMultiplier = BuffWatcher_Configuration_Singleton.GetUnlistedMultiplier(),
                    index = 10,
                    unit = normalizedUnit,
                    targetGuid = targetGuid
                }
            else
                allstates[key].duration = addedAura.duration
                allstates[key].expirationTime = addedAura.expirationTime
                allstates[key].changed = true
            end

            return true
        end
    end

    local handleBuffsAndDebuffs = function(
        allstates, 
        ---@type BuffWatcher_AuraContext
        context, 
        ...)
        local hasUpdates = false

        local targetUnit = select(1, ...)
        local targetGuid = UnitGUID(targetUnit)
        local normalizedUnit = BuffWatcher_Shared_Singleton.NormalizeUnit(targetUnit)
        local auraData = select(2, ...)

        if (not BuffWatcher_Shared_Singleton.UnitNameMatchesFrameType(normalizedUnit, context.getFrameType())) then
            return false
        end
        
        if (auraData.addedAuras ~= nil) then
            for i,addedAura in ipairs(auraData.addedAuras) do 
                if (addedAura.isHelpful and context.includeBuffsAndCasts()) then
                    local result = handleBuffAddOrUpdate(allstates, context, addedAura, targetUnit, normalizedUnit, targetGuid)
                    if (result) then
                        hasUpdates = true
                    end

                    if (addedAura.sourceUnit == 'player') then
                        DevTool:AddData({ allstates = allstates, auraData = addedAura }, "fixme added")    
                    end

                --elseif (addedAura.isHarmful and weakAuraBundle.debuffs[addedAura.spellId] ~= nil) then
                    -- local auraId = addedAura.auraInstanceID
                    -- local watcherInfo = weakAuraBundle.debuffs[addedAura.spellId]
                    -- local spellInfo = {GetSpellInfo(addedAura.spellId)}
                    -- local key = getStateKey(watcherInfo.buffType, watcherInfo.spellId, targetGuid, auraId, context.getName())
                    
                    -- context.addKeyByGuid(targetGuid, key)
                    -- context.addKeyByAuraId(auraId, key)

                    -- --DevTool:AddData({ aura = addedAura, target = targetUnit, guid = targetGuid, weakauras = weakAuraBundle }, "fixme debuff aura")

                    -- if (allstates[key] == nil) then
                    --     allstates[key] = {
                    --         show = true,
                    --         changed = true,
                    --         progressType = "timed",
                    --         duration = addedAura.duration,
                    --         name = addedAura.name,
                    --         icon = spellInfo[3],
                    --         caster = addedAura.sourceUnit,
                    --         autoHide = true,
                    --         showGlow = true,
                    --         sizeMultiplier = 3,
                    --         unit = guidToNameplatesMap[targetGuid],
                    --         index = 1,
                    --         targetGuid = targetGuid
                    --     }
                    -- end

                    -- hasUpdates = true
                end
            end
        end

        if (auraData.removedAuraInstanceIDs ~= nil) then
            for i,removedAuraId in ipairs(auraData.removedAuraInstanceIDs) do
                local key = context.getKeyByAuraId(removedAuraId) 

                if (key ~= nil) then
                    if (allstates[key] ~= nil) then
                        allstates[key].show = false
                        allstates[key].changed = true
                        context.removeKeyByGuid(allstates[key].targetGuid, key)
                        hasUpdates = true
                    end

                    context.removeAuraIdToKeyEntry(removedAuraId)
                end
            end
        end

        if (auraData.updatedAuraInstanceIDs ~= nil) then
            for i,updatedAuraId in ipairs(auraData.updatedAuraInstanceIDs) do
                local updateInfo = C_UnitAuras.GetAuraDataByAuraInstanceID(targetUnit, updatedAuraId)

                if (updateInfo ~= nil) then
                    if (updateInfo.sourceUnit == 'player') then
                        DevTool:AddData({ allstates = allstates, auraData = updateInfo }, "fixme updates")    
                    end

                    hasUpdates = handleBuffAddOrUpdate(allstates, context, updateInfo, targetUnit, normalizedUnit, targetGuid)
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
        return storedSpellsRegistry ~= nil
    end

    self.DelegateTsu = function(allstates, event, contextName, ...)
        local context = contexts[contextName]
        if (context == nil) then
            return false
        end

        local spellData = {...}
        local hasUpdates = false

        local eventSubtype = select(2, ...)

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
            -- fixme - this is probably the wrong guid?
 
            local guid = context.getGuidByNameplate(nameplate)

            if (guid ~= nil) then
                for stateKey, _ in context.getKeysByGuid(guid) do
                    if (allstates[stateKey] ~= nil) then
                        allstates[stateKey].unit = nil
                        allstates[stateKey].changed = true
                        hasUpdates = true
                    end
                end
    
                context.unlinkNameplateFromGuid(nameplate, guid)
            end
        elseif (event == "NAME_PLATE_UNIT_ADDED") then
            local nameplate = select(1, ...)
            local unitGuid = UnitGUID(nameplate)

            for stateKey,_ in context.getKeysByGuid(unitGuid) do

                DevTool:AddData({key = stateKey, unitGuid = unitGuid, nameplate = nameplate }, "fixme NAME_PLATE_UNIT_ADDED")

                if (allstates[stateKey] ~= nil) then
                    allstates[stateKey].unit = nameplate
                    allstates[stateKey].changed = true
                    hasUpdates = true
                end
            end

            context.linkNameplateToGuid(nameplate, unitGuid)
        end
    
        return hasUpdates
    end

    self.DelegateCustomGrow = function(contextName, newPositions, activeRegions)
        local testParents = {}
    
        local context = contexts[contextName]

        DevTool:AddData("DelegateCustomGrow", "DelegateCustomGrow")

        if (context == nil) then
            error("Couldn't find context " .. contextName)
        end

        local xPos = 0

        if (context.isUnitframe()) then
            for i = 1, #activeRegions do
                local activeRegion = activeRegions[i]
                local state = CopyTable(activeRegions[i].region.state)

                if (state.unit ~= nil and (BuffWatcher_Shared_Singleton.IsPartyOrRaidUnit(state.unit))) then
                    
                    local frame = self.GetUnitFrame(state.unit)
    
                    if (newPositions[frame] == nil) then 
                        newPositions[frame] = {}
                    end 
    
                    local baseSize = activeRegion.data.width
                    local adjustedSize = baseSize * state.sizeMultiplier
    
                    activeRegion.region:SetRegionWidth(adjustedSize)
                    activeRegion.region:SetRegionHeight(adjustedSize)
    
                    newPositions[frame][activeRegions[i]] = {
                        xPos,
                        0
                    }
                    xPos = xPos + adjustedSize
                end
            end
        else -- nameplate
            for i = 1, #activeRegions do
                local activeRegion = activeRegions[i]
                local state = CopyTable(activeRegions[i].region.state)

                DevTool:AddData(state, "fixme nameplate state")

                if (state.unit ~= nil and (BuffWatcher_Shared_Singleton.IsNameplateUnit(state.unit))) then
                    local frame = C_NamePlate.GetNamePlateForUnit(state.unit)
    
                    if (frame == nil) then
                        DevTool:AddData({frame = frame, unit = state.unit}, "fixme nil nameplate")
                    end

                    if (newPositions[frame] == nil) then 
                        newPositions[frame] = {}
                    end 
    
                    local baseSize = activeRegion.data.width
                    local adjustedSize = baseSize * state.sizeMultiplier
    
                    activeRegion.region:SetRegionWidth(adjustedSize)
                    activeRegion.region:SetRegionHeight(adjustedSize)
    
                    newPositions[frame][activeRegions[i]] = {
                        xPos,
                        0
                    }
                    xPos = xPos + adjustedSize
                end
            end
        end
    end

    local findPlayerUnit = function()
        if (IsInGroup() and GetNumGroupMembers() == 1) then
            return 'party1'
        elseif (IsInRaid() and GetNumGroupMembers() == 1) then
            return 'raid1'
        end

        for i = 1, GetNumGroupMembers() do
            local partyUnit = 'party' .. i
            if UnitIsPlayer(partyUnit) then
                return partyUnit
            end
        end
        return nil
    end

    self.GetUnitFrame = function(unitName)
        if (unitName == 'player') then
            unitName = findPlayerUnit()
        end
        if string.find(unitName, 'party') == 1 then
            if not IsInGroup() then
                return nil
            end
            local sub = string.sub(unitName, 6, -1)
            local partyIndex = tonumber(sub)

            if (hasSufPartyFrames()) then
                local frameName = BuffWatcher_Shared_Singleton.SufPlayerFramePrefix .. partyIndex
                return _G[frameName]
            else
                return _G[unitName]
            end
        end

        if string.find(unitName, 'raid') == 1 then
            if not IsInRaid() then
                return nil
            end
            local sub = string.sub(6, -1)
            local partyIndex = tonumber(sub)
            print(sub)

            if (hasSufPartyFrames()) then
                local frameName = BuffWatcher_Shared_Singleton.SufPlayerFramePrefix .. partyIndex
                return _G[frameName]
            else
                return _G[unitName]
            end
        end
    end

    return self
end

BuffWatcher_WeakAuraInterface_Singleton = BuffWatcher_WeakAuraInterface:new()