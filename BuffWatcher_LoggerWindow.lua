local AceGUI = LibStub("AceGUI-3.0")

BuffWatcher_LoggerWindow = {}

function BuffWatcher_LoggerWindow:new(incomingStoredSpells)
    self = {}

    local SpellTypes = BuffWatcher_Shared_Singleton.SpellTypes
    local SpellTypeLabels = BuffWatcher_Shared_Singleton.SpellTypeLabels

    local spellFilters = {
        spellType = SpellTypes.Any,
        name = "",
        caster = ""
    }
    local mainFrame = nil
    local pageSize = 10
    local spellRowHeight = 32
    local spellRecords = {}
    local filteredSpellRecords = {}
    local uiSpellRows = {}
    local indexedSpellRecords = {}
    local pagerText = nil
    local buffPickerDropdown = nil
    local foundSpells = {}
    local isShowing = false
    local storedSpells = incomingStoredSpells

    local pager = Pager:new(pageSize, 0)

    local GetIndexedRecords = function(spellRecords)
        local iSpellRecords = {}
    
        local i = 1
        for k,v in pairs(spellRecords) do -- might need to use ipairs() instead?
            iSpellRecords[i] = v
            i = i + 1
        end
    
        return iSpellRecords
    end

    local addUnitAura = function(isBuff, sourceUnit, auraInfo)
        local type = isBuff and SpellTypes.Buff or SpellTypes.Debuff
        local name = auraInfo[1]
        local spellId = auraInfo[10]
        local sourceName = UnitName(sourceUnit)

        local buffRecord = BuffWatcher_Shared_Singleton.BuildSpellCastRecord(type, spellId, name, sourceName)

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

                local spellRecord = BuffWatcher_Shared_Singleton.BuildSpellCastRecord(SpellTypes.Cast, spellId, spellName, nameOnly(sourceName))

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
                        buffRecord = BuffWatcher_Shared_Singleton.BuildSpellCastRecord(SpellTypes.Buff, v.spellId, v.name, unitName)
                    else
                        buffRecord = BuffWatcher_Shared_Singleton.BuildSpellCastRecord(SpellTypes.Debuff, v.spellId, v.name, unitName)
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
                            buffRecord = BuffWatcher_Shared_Singleton.BuildSpellCastRecord(SpellTypes.Buff, updateInfo.spellId, updateInfo.name, unitName)
                        else
                            buffRecord = BuffWatcher_Shared_Singleton.BuildSpellCastRecord(SpellTypes.Debuff, updateInfo.spellId, updateInfo.name, unitName)
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

    local handleSpellAdd = function(...) 
        local spellRecord = select(1, ...)
        storedSpells.addSpell(spellRecord)
    end

    local meetsFilter = function(spellRecord, filter) 
        if (storedSpells.hasSpell(spellRecord)) then
            return false
        end

        if (filter.spellType ~= SpellTypes.Any and spellRecord.type ~= filter.spellType) then
            return false
        end

        if (filter.name ~= nil and filter.name ~= "") then
            if string.find(spellRecord.loweredName, filter.name) == nil then
                return false
            end
        end

        if (filter.caster ~= nil and filter.caster ~= "") then
            if string.find(spellRecord.loweredCaster, filter.caster) == nil then
                return false
            end
        end

        return true
    end

    local applyFilters = function(spellRecords, filters)
        local filtered = {}

        for k,v in pairs(spellRecords) do
            if (meetsFilter(v, filters) == true) then
                filtered[k] = v
            end
        end

        return filtered
    end

    local setSpellTypeFilter = function(newType)
        spellFilters.spellType = newType
        self.UpdateWindow()
    end

    local setSpellNameFilter = function(newFilter)
        DevTool:AddData(newFilter, "fixme newFilter")
        spellFilters.name = string.lower(newFilter)
        self.UpdateWindow()
    end

    local setCasterNameFilter = function(newFilter)
        spellFilters.caster = string.lower(newFilter)
        self.UpdateWindow()
    end

    local Initialize = function()
        local frame = AceGUI:Create("SimpleGroup", "BuffWatcher_LoggerWindow")
        frame:SetLayout("List")
        frame:SetFullWidth(true)
 
        local filtersHolderFrame = AceGUI:Create("SimpleGroup", "Filters Holder Frame")
        filtersHolderFrame:SetLayout("Flow")
        filtersHolderFrame:SetFullWidth(true)
        frame:AddChild(filtersHolderFrame)

        local filterSpellType = AceGUI:Create("Dropdown")
        filterSpellType:SetLabel("Spell Type:") 

        local OrderedSpellTypes = {
            [1] = SpellTypes.Any,
            [2] = SpellTypes.Buff,
            [3] = SpellTypes.Debuff,
            [4] = SpellTypes.Cast
        }

        local dropdownItems = {}

        for k, v in pairs(OrderedSpellTypes) do
            dropdownItems[v] = SpellTypeLabels[v]
        end

        filterSpellType:SetList(dropdownItems)
        filterSpellType:SetValue(SpellTypes.Any)
        filterSpellType:SetCallback("OnValueChanged", function(control, event, key)
            print("dropdownSpellType " .. tostring(key))
            setSpellTypeFilter(key)
        end)

        filtersHolderFrame:AddChild(filterSpellType)

        local filterSpellName = AceGUI:Create("EditBox")
            
        filterSpellName:SetWidth(100);
        filterSpellName:SetHeight(25);
        filterSpellName:SetLabel("Spell Name:");
        filterSpellName:SetCallback("OnTextChanged", function(control, event, text)
            setSpellNameFilter(text ~= nil and text or "")
        end)

        filtersHolderFrame:AddChild(filterSpellName)

        local filterCasterName = AceGUI:Create("EditBox")
            
        filterCasterName:SetWidth(100);
        filterCasterName:SetHeight(50);
        filterCasterName:SetLabel("Caster:");
        filterCasterName:SetCallback("OnTextChanged", function(text)
            setCasterNameFilter(text ~= nil and text or "")
        end)

        filtersHolderFrame:AddChild(filterCasterName)
    
        -- spell rows start
        for i=1,pageSize do 
            local newRow = BuffWatcher_LoggerWindow_SpellRow:new()
   
            frame:AddChild(newRow.getFrame())

            newRow.registerAdd(handleSpellAdd)
            
            table.insert(uiSpellRows, newRow)
        end
        -- spell rows end
    
        -- refresh button start
        -- local refreshButton = BuffWatcher_Shared_Singleton.GetButton(
        --     frame, 
        --     "Interface/Buttons/UI-DialogBox-Button-Up", 
        --     "Interface/Buttons/UI-DialogBox-Button-Down"
        -- )
        
        -- refreshButton:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -350, 5)
        -- refreshButton:SetWidth(100)
        -- refreshButton:SetHeight(64)
        -- refreshButton:SetScript("OnClick", function()
        --     self.UpdateWindow()
        -- end)
    
        -- local refreshText = refreshButton:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        -- refreshText:SetText("Refresh")
        -- refreshText:SetPoint("CENTER", 0, 8)
        -- -- refresh button end

        local actionsHolderFrame = AceGUI:Create("SimpleGroup", "Actions Holder Frame")
        actionsHolderFrame:SetLayout("Flow")
        actionsHolderFrame:SetFullWidth(true)
        frame:AddChild(actionsHolderFrame)

        local refreshButton = AceGUI:Create("Button")
        refreshButton:SetText("Refresh")
        refreshButton:SetWidth(100)
        refreshButton:SetHeight(64)
        refreshButton:SetCallback("OnClick", function()
            self.UpdateWindow()
        end)

        actionsHolderFrame:AddChild(refreshButton)

        local prevButton = AceGUI:Create("Button")
        prevButton:SetText("Prev")
        prevButton:SetWidth(60)
        prevButton:SetHeight(40)
        prevButton:SetCallback("OnClick", 
            function()
                pager.goPreviousPage()
                self.UpdateSpellRows()
            end
        )
    
        actionsHolderFrame:AddChild(prevButton)

        -- local pagerTextHolder = AceGUI:Create("SimpleGroup")
        -- pagerTextHolder:SetLayout("Fill")
        -- pagerTextHolder:SetWidth(200)
        -- pagerTextHolder:SetHeight(200)

        -- actionsHolderFrame:AddChild(pagerTextHolder)

        -- local pagerTextInnerHolder = AceGUI:Create("SimpleGroup")
        -- pagerTextInnerHolder:SetLayout("Fill")
        -- -- pagerTextInnerHolder:SetWidth(250)
        -- -- pagerTextInnerHolder:SetHeight(250)
        -- pagerTextInnerHolder:SetPoint("TOPLEFT", pagerTextHolder.frame, "TOPLEFT", -25, 25)
        -- pagerTextInnerHolder:SetPoint("BOTTOMRIGHT", pagerTextHolder.frame, "BOTTOMRIGHT", 25, -25)

        -- --pagerTextHolder:AddChild(pagerTextInnerHolder)

        -- local testBlizzardFrame = CreateFrame("Frame", pagerTextHolder.frame)
        -- testBlizzardFrame:SetWidth(300)
        -- testBlizzardFrame:SetHeight(300)
        -- testBlizzardFrame:SetPoint("CENTER", pagerTextHolder.frame, "CENTER", 0, 0)


        pagerText = AceGUI:Create("Label")
        pagerText:SetJustifyH("CENTER")
        pagerText:SetJustifyV("MIDDLE")
        --pagerText.frame:SetPoint("BOTTOMRIGHT", pagerTextHolder.frame, "BOTTOMRIGHT", 0, 0)

        actionsHolderFrame:AddChild(pagerText)

        local nextButton = AceGUI:Create("Button")
        nextButton:SetText("Next")
        nextButton:SetWidth(60)
        nextButton:SetHeight(40)
        nextButton:SetCallback("OnClick", 
            function()
                pager.goNextPage()
                self.UpdateSpellRows()
            end
        )
    
        actionsHolderFrame:AddChild(nextButton)

        -- local prevButton = BuffWatcher_Shared_Singleton.GetButton(
        --     frame, 
        --     "Interface/Buttons/UI-SpellbookIcon-PrevPage-Up", 
        --     "Interface/Buttons/UI-SpellbookIcon-PrevPage-Down"
        -- )
    
        -- prevButton:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -250, 25)
        -- prevButton:SetWidth(40)
        -- prevButton:SetHeight(40)
        -- prevButton:SetScript("OnClick", 
        --     function()
        --         pager.goPreviousPage()
        --         self.UpdateSpellRows()
        --     end
        -- )

        -- pagerText = frame:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
        -- pagerText:SetPoint("CENTER", frame, "BOTTOMRIGHT", -160, 45)
        -- pagerText:SetText("test text")

        frame.frame:RegisterEvent("ADDON_LOADED")
        frame.frame:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
        frame.frame:RegisterEvent("NAME_PLATE_UNIT_ADDED")
        frame.frame:RegisterEvent("UNIT_AURA")
        frame.frame:SetScript("OnEvent", OnEvent)

        -- make sure we get the player's buffs in there at least once
        checkUnitBuffs("player")

        return frame
    end

    self.UpdateSpellRows = function()
        local currentPageCount = pager.getPageEnd() - pager.getPageStart()
    
        local rowIndex = 1
        for i=pager.getPageStart(), pager.getPageEnd() do
            uiSpellRows[rowIndex].setSpell(indexedSpellRecords[i])
            uiSpellRows[rowIndex].getFrame().frame:Show()
            rowIndex = rowIndex + 1
        end
    
        while (rowIndex <= pageSize) do
            uiSpellRows[rowIndex].clearSpell()
            uiSpellRows[rowIndex].getFrame().frame:Hide()
            rowIndex = rowIndex + 1
        end
    
        local text = ''
        if pager.getTotalPageCount() == 0 then
            text = 'No Entries'
        else
            text = "Showing page " .. pager.getCurrentPage() .. " of " .. pager.getTotalPageCount();
        end

        pagerText:SetText(text)
    end
    
    self.UpdateWindow = function()
        local filteredRecords = applyFilters(spellRecords, spellFilters)
        indexedSpellRecords = GetIndexedRecords(filteredRecords)
        pager = Pager:new(pageSize, #indexedSpellRecords)
        self.UpdateSpellRows()
    end

    self.GetFrame = function()
        return mainFrame
    end

    mainFrame = Initialize()

    return self
end
