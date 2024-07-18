---@class BuffWatcher_LoggerModule
BuffWatcher_LoggerModule = {}

function BuffWatcher_LoggerModule:new()
    self = {}

    local SpellTypes = BuffWatcher_Shared_Singleton.SpellTypes

    local mainFrame = nil
    ---@type table<string, BuffWatcher_CastRecord>
    local spellRecords = {}

    ---@param isBuff boolean
    ---@param sourceUnit string
    ---@param auraName string
    ---@param auraId number
    local addUnitAura = function(isBuff, sourceUnit, auraName, auraId)
        local type = isBuff and SpellTypes.Buff or SpellTypes.Debuff
        local sourceName = UnitName(sourceUnit)

        local key = BuffWatcher_CastRecord.GetKeyFromParams(type, auraId)
 
        if (spellRecords[key] == nil) then
            local auraRecord = BuffWatcher_CastRecord:new(type, auraId, auraName, sourceName)

            spellRecords[key] = auraRecord
        end
    end

    local checkUnitBuffs = function(unit)
        for i=1,40 do
            local name, icon, count, dispelType, duration, expirationTime, source, isStealable, nameplateShowPersonal, spellId = UnitBuff(unit, i)
            if (name == nil) then
                break
            end
            addUnitAura(true, unit, name, spellId)
        end

        for i=1,40 do
            local name, icon, count, dispelType, duration, expirationTime, source, isStealable, nameplateShowPersonal, spellId = UnitDebuff(unit, i)
            if (name == nil) then
                break
            end
            addUnitAura(false, unit, name, spellId)
        end
    end

    local nameOnly = function(fullname)
        if (fullname == nil) then
            return "(no source)"
        end

        local dashIndex = string.find(fullname, "-")

        if (dashIndex == nil) then
            return fullname
        end

        return string.sub(fullname, 0, dashIndex-1)
    end

    local OnEvent = function (ref, event, ...)
        -- if (event == "COMBAT_LOG_EVENT_UNFILTERED") then
        --     local timestamp, subevent, hideCaster, sourceGUID, sourceName, sourceFlags, sourceRaidFlags, destGUID, destName, destFlags,	destRaidFlags, spellId, spellName = CombatLogGetCurrentEventInfo()

        --     if (subevent == "SPELL_CAST_SUCCESS") then
        --         local spellRecordKey = BuffWatcher_CastRecord.GetKeyFromParams(SpellTypes.Cast, spellId)

        --         if (spellRecords[spellRecordKey] == nil) then
        --             local spellRecord = BuffWatcher_CastRecord:new(SpellTypes.Cast, spellId, spellName, nameOnly(sourceName))
        --             spellRecords[spellRecordKey] = spellRecord
        --         end
        --     end
        -- elseif (event == "UNIT_AURA") then
        --     local auraInfo = select(2, ...)
        --     local targetUnit = select(1, ...)

        --     if (auraInfo.addedAuras ~= nil) then
        --         for i,v in ipairs(auraInfo.addedAuras) do
        --             local sourceUnit = v.sourceUnit
        --             if (sourceUnit == nil) then
        --                 break
        --             end

        --             local unitName = UnitName(sourceUnit)
        --             if (unitName == nil) then
        --                 break
        --             end

        --             local spellType = v.isHelpful and SpellTypes.Buff or SpellTypes.Debuff

        --             local key = BuffWatcher_CastRecord.GetKeyFromParams(spellType, v.spellId)

        --             if (spellRecords[key] == nil) then
        --                 ---@type BuffWatcher_CastRecord
        --                 local buffRecord = BuffWatcher_CastRecord:new(spellType, v.spellId, v.name, unitName)

        --                 spellRecords[buffRecord.key] = buffRecord
        --             end
        --         end
        --     end

        --     if (auraInfo.updatedAuraInstanceIDs ~= nil) then
        --         for i,v in ipairs(auraInfo.updatedAuraInstanceIDs) do
        --             local updateInfo = C_UnitAuras.GetAuraDataByAuraInstanceID(targetUnit, v)
        --             if (updateInfo ~= nil) then

        --                 local sourceUnit = updateInfo.sourceUnit
        --                 if (sourceUnit == nil) then
        --                     break
        --                 end
    
        --                 local unitName = UnitName(sourceUnit)
        --                 if (unitName == nil) then
        --                     break
        --                 end
                        
        --                 local spellType = updateInfo.isHelpful and SpellTypes.Buff or SpellTypes.Debuff

        --                 local key = BuffWatcher_CastRecord.GetKeyFromParams(spellType, updateInfo.spellId)
    
        --                 if (spellRecords[key] == nil) then
        --                     ---@type BuffWatcher_CastRecord
        --                     local auraRecord = BuffWatcher_CastRecord:new(spellType, updateInfo.spellId, updateInfo.name, unitName)
    
        --                     spellRecords[auraRecord.key] = auraRecord
        --                 end
        --             end
        --         end
        --     end
        -- elseif (event == "NAME_PLATE_UNIT_ADDED") then
        --      local targetUnit = select(1, ...)
        --      checkUnitBuffs(targetUnit)
        -- end
    end

    local Initialize = function()
        local frame = CreateFrame("Frame")

        frame:RegisterEvent("ADDON_LOADED")
        frame:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
        frame:RegisterEvent("NAME_PLATE_UNIT_ADDED")
        frame:RegisterEvent("UNIT_AURA")
        frame:SetScript("OnEvent", OnEvent)

        -- make sure we get the player's buffs in there at least once
        checkUnitBuffs("player")

        return frame
    end
    
    mainFrame = Initialize()

    ---@returns table<string, BuffWatcher_CastRecord>
    self.GetSpellRecords = function()
        return CopyTable(spellRecords)
    end

    return self
end
