---@class BuffWatcher_LoggerModule
BuffWatcher_LoggerModule = {}

function BuffWatcher_LoggerModule:new()
    self = {}

    local SpellTypes = BuffWatcher_Shared_Singleton.SpellTypes
    local SpellTypeLabels = BuffWatcher_Shared_Singleton.SpellTypeLabels

    local spellFilters = {
        spellType = SpellTypes.Any,
        name = "",
        caster = ""
    }

    local mainFrame = nil
    local spellRecords = {}

    local addUnitAura = function(isBuff, sourceUnit, auraInfo)
        local type = isBuff and SpellTypes.Buff or SpellTypes.Debuff
        local name = auraInfo[1]
        local spellId = auraInfo[10]
        local sourceName = UnitName(sourceUnit)

        local buffRecord = BuffWatcher_CastRecord:new(type, spellId, name, sourceName)

        if (spellRecords[buffRecord.key] == nil) then
            spellRecords[buffRecord.key] = buffRecord
        end
    end

    local checkUnitBuffs = function(unit)
        for i=1,40 do
            local buff = {UnitBuff(unit, i)}
            if (#buff == 0) then
                break
            end
            addUnitAura(true, unit, buff)
        end

        for i=1,40 do
            local buff = {UnitDebuff(unit, i)}
            if (#buff == 0) then
                break
            end
            addUnitAura(false, unit, buff)
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
        if (event == "COMBAT_LOG_EVENT_UNFILTERED") then
            local eventInfo = {CombatLogGetCurrentEventInfo()}
            local subevent = eventInfo[2]
            local sourceGuid = eventInfo[4]
            local sourceName = eventInfo[5]

            if (subevent == "SPELL_CAST_SUCCESS") then
                local spellId = eventInfo[12]
                local spellName = eventInfo[13]

                local spellRecord = BuffWatcher_CastRecord:new(SpellTypes.Cast, spellId, spellName, nameOnly(sourceName))

                if (spellRecords[spellRecord.key] == nil) then
                    spellRecords[spellRecord.key] = spellRecord
                end
            end
        elseif (event == "UNIT_AURA") then
            local auraInfo = select(2, ...)
            local targetUnit = select(1, ...)
            if (auraInfo.addedAuras ~= nil) then
                for i,v in ipairs(auraInfo.addedAuras) do
                    local sourceUnit = v.sourceUnit
                    if (sourceUnit == nil) then
                        break
                    end

                    local unitName = UnitName(sourceUnit)
                    if (unitName == nil) then
                        break
                    end

                    if (v.isHelpful) then
                        buffRecord = BuffWatcher_CastRecord:new(SpellTypes.Buff, v.spellId, v.name, unitName)
                    else
                        buffRecord = BuffWatcher_CastRecord:new(SpellTypes.Debuff, v.spellId, v.name, unitName)
                    end

                    if (spellRecords[buffRecord.key] == nil) then
                        spellRecords[buffRecord.key] = buffRecord
                    end
                end
            end

            if (auraInfo.updatedAuraInstanceIDs ~= nil) then
                for i,v in ipairs(auraInfo.updatedAuraInstanceIDs) do
                    local updateInfo = C_UnitAuras.GetAuraDataByAuraInstanceID(targetUnit, v)
                    if (updateInfo ~= nil) then

                        local sourceUnit = updateInfo.sourceUnit
                        if (sourceUnit == nil) then
                            break
                        end
    
                        local unitName = UnitName(sourceUnit)
                        if (unitName == nil) then
                            break
                        end

                        local buffRecord = nil
                        if (updateInfo.isHelpful) then
                            buffRecord = BuffWatcher_CastRecord:new(SpellTypes.Buff, updateInfo.spellId, updateInfo.name, unitName)
                        else
                            buffRecord = BuffWatcher_CastRecord:new(SpellTypes.Debuff, updateInfo.spellId, updateInfo.name, unitName)
                        end

                        if (spellRecords[buffRecord.key] == nil) then
                            spellRecords[buffRecord.key] = buffRecord
                        end
                    end
                end
            end
        elseif (event == "NAME_PLATE_UNIT_ADDED") then
             local targetUnit = select(1, ...)
             checkUnitBuffs(targetUnit)
        end
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

    self.GetSpellRecords = function()
        return CopyTable(spellRecords)
    end

    return self
end
