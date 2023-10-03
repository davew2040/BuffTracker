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

        -- debug color
        -- frame.frame:SetBackdropColor(1, 0, 0, 1)

        -- buff type picker start
        -- local function WPDropDownDemo_OnClick(ref)
        --     UIDropDownMenu_SetSelectedValue(buffPickerDropdown, ref.value)
        --     setSpellTypeFilter(ref.value)
        -- end
    
        -- local function WPDropDownDemo_Menu(frame, level, menuList)
        --     local OrderedSpellTypes = {
        --         [1] = SpellTypes.Any,
        --         [2] = SpellTypes.Buff,
        --         [3] = SpellTypes.Debuff,
        --         [4] = SpellTypes.Cast
        --     }

        --     for k, v in pairs(OrderedSpellTypes) do
        --         local info = UIDropDownMenu_CreateInfo()

        --         info.value = v
        --         info.text = SpellTypeLabels[v]
        --         info.checked = false
        --         info.func = WPDropDownDemo_OnClick

        --         UIDropDownMenu_AddButton(info)
        --     end
        -- end

        
        -- Create the dropdown control

        -- end buff type picker

        -- start filter labels
        
        local labelsHolderFrame = AceGUI:Create("SimpleGroup", "Labels Holder Frame")
        labelsHolderFrame:SetFullWidth(true)
        labelsHolderFrame:SetLayout("Flow")
        frame:AddChild(labelsHolderFrame)

        local filterTypeLabel = AceGUI:Create("Label") --CreateFrame("Frame", nil, frame)
        DevTool:AddData(filterTypeLabel, "fixme filterTypeLabel")
        filterTypeLabel:SetWidth(50)
        filterTypeLabel:SetHeight(50)
        filterTypeLabel:SetText("TYPE")

        labelsHolderFrame:AddChild(filterTypeLabel)

        local filterSpellLabel = AceGUI:Create("Label") --CreateFrame("Frame", nil, frame)
        filterSpellLabel:SetWidth(50)
        filterSpellLabel:SetHeight(50)
        filterSpellLabel:SetText("SPELL")

        labelsHolderFrame:AddChild(filterSpellLabel)

        local filterCasterLabel = AceGUI:Create("Label") --CreateFrame("Frame", nil, frame)
        filterCasterLabel:SetWidth(50)
        filterCasterLabel:SetHeight(50)
        filterCasterLabel:SetText("CASTER")

        labelsHolderFrame:AddChild(filterCasterLabel)

        -- end filter labels

        -- start grid labels

        -- local labelsFrame = CreateFrame("Frame", nil, frame)
        -- labelsFrame:SetPoint("TOPLEFT", frame, "TOPLEFT", 15, -120) 
        -- labelsFrame:Show()
        -- labelsFrame:SetSize(50, 50)

        -- local spellTypeLabel = labelsFrame:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
        -- spellTypeLabel:SetPoint("LEFT", labelsFrame, "TOPLEFT", 200, 0)  
        -- spellTypeLabel:SetText("TYPE") 

        -- local spellIdLabel = labelsFrame:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
        -- spellIdLabel:SetPoint("LEFT", labelsFrame, "TOPLEFT", 300, 0)  
        -- spellIdLabel:SetText("SPELL ID") 

        -- local spellNameLabel = labelsFrame:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
        -- spellNameLabel:SetPoint("LEFT", labelsFrame, "TOPLEFT", 400, 0)  
        -- spellNameLabel:SetText("SPELL NAME") 

        -- local spellCasterLabel = labelsFrame:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
        -- spellCasterLabel:SetPoint("LEFT", labelsFrame, "TOPLEFT", 650, 0)  
        -- spellCasterLabel:SetText("CASTER") 

        -- end grid labels

        -- buff type picker end       

   -- buff type picker start
        -- local function WPDropDownDemo_OnClick(ref)
        --     UIDropDownMenu_SetSelectedValue(buffPickerDropdown, ref.value)
        --     setSpellTypeFilter(ref.value)
        -- end
    
        -- local function WPDropDownDemo_Menu(frame, level, menuList)
        --     local OrderedSpellTypes = {
        --         [1] = SpellTypes.Any,
        --         [2] = SpellTypes.Buff,
        --         [3] = SpellTypes.Debuff,
        --         [4] = SpellTypes.Cast
        --     }

        --     for k, v in pairs(OrderedSpellTypes) do
        --         local info = UIDropDownMenu_CreateInfo()

        --         info.value = v
        --         info.text = SpellTypeLabels[v]
        --         info.checked = false
        --         info.func = WPDropDownDemo_OnClick

        --         UIDropDownMenu_AddButton(info)
        --     end
        -- end

        local filtersHolderFrame = AceGUI:Create("SimpleGroup", "Filters Holder Frame")
        filtersHolderFrame:SetLayout("Flow")
        filtersHolderFrame:SetFullWidth(true)
        frame:AddChild(filtersHolderFrame)

        local filterSpellType = AceGUI:Create("Dropdown")

        filterSpellType:SetLabel("Select an Option:") 

        local OrderedSpellTypes = {
            [1] = SpellTypes.Any,
            [2] = SpellTypes.Buff,
            [3] = SpellTypes.Debuff,
            [4] = SpellTypes.Cast
        }

        local dropdownItems = {}

        for k, v in pairs(OrderedSpellTypes) do
            -- table.insert(dropdownItems, {
            --     text = SpellTypeLabels[v],
            --     value = v
            -- })
            dropdownItems[k] = SpellTypeLabels[v]
        end

        DevTool:AddData(dropdownItems, "fixme dropdownItems")

        filterSpellType:SetList(dropdownItems)
        filterSpellType:SetValue(SpellTypes.Any)
        filterSpellType:SetCallback("OnValueChanged", function(key)
            print("dropdownSpellType " .. tostring(key))
            setSpellTypeFilter(key)
        end)

        filtersHolderFrame:AddChild(filterSpellType)

        local filterSpellName = AceGUI:Create("EditBox")
            
        filterSpellName:SetWidth(100);
        filterSpellName:SetHeight(50);
        filterSpellName:SetCallback("OnTextChanged", function(control, event, text)
            setSpellNameFilter(text ~= nil and text or "")
        end)

        filtersHolderFrame:AddChild(filterSpellName)

        local filterCasterName = AceGUI:Create("EditBox")
            
        filterCasterName:SetWidth(100);
        filterCasterName:SetHeight(50);
        filterCasterName:SetCallback("OnTextChanged", function(text)
            setCasterNameFilter(text ~= nil and text or "")
        end)

        filtersHolderFrame:AddChild(filterCasterName)
    
        -- end buff type picker

        -- -- filter spell name

        -- local filterSpellName = CreateFrame("Editbox", nil, frame, "InputBoxTemplate")
        -- filterSpellName:SetPoint("TOPLEFT", frame, "TOPLEFT", 175, -35);
        -- filterSpellName:SetWidth(100);
        -- filterSpellName:SetHeight(50);
        -- filterSpellName:SetMovable(false);
        -- filterSpellName:SetAutoFocus(false);
        -- filterSpellName:SetScript("OnTextChanged", function(...)
        --     local ctl = select(1, ...)
        --     local textValue = ctl:GetText()
        --     setSpellNameFilter(textValue ~= nil and textValue or "")
        -- end)
        -- -- end filter spell name

        -- -- filter caster name
        -- local filterCasterName = CreateFrame("Editbox", nil, frame, "InputBoxTemplate")
        -- filterCasterName:SetPoint("TOPLEFT", frame, "TOPLEFT", 300, -35);
        -- filterCasterName:SetWidth(100);
        -- filterCasterName:SetHeight(50);
        -- filterCasterName:SetMovable(false);
        -- filterCasterName:SetAutoFocus(false);
        -- filterCasterName:SetScript("OnTextChanged", function(...)
        --     local ctl = select(1, ...)
        --     local textValue = ctl:GetText()
        --     setCasterNameFilter(textValue ~= nil and textValue or "")
        -- end)
        -- -- end caster spell name

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

        local nextButton = AceGUI:Create("Button")
        nextButton:SetText("Next")
        nextButton:SetWidth(40)
        nextButton:SetHeight(40)
        nextButton:SetCallback("OnClick", 
            function()
                pager.goNextPage()
                self.UpdateSpellRows()
            end
        )
    
        actionsHolderFrame:AddChild(nextButton)

        pagerText = AceGUI:Create("Label")
        pagerText:SetWidth(120)
        pagerText:SetHeight(40)
        pagerText:SetCallback("OnClick", 
            function()
                pager.goPreviousPage()
                self.UpdateSpellRows()
            end
        )
    
        actionsHolderFrame:AddChild(pagerText)

        local prevButton = AceGUI:Create("Button")
        prevButton:SetText("Prev")
        prevButton:SetWidth(40)
        prevButton:SetHeight(40)
        prevButton:SetCallback("OnClick", 
            function()
                pager.goPreviousPage()
                self.UpdateSpellRows()
            end
        )
    
        actionsHolderFrame:AddChild(prevButton)

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

    self.Show = function()
        self.UpdateWindow()
        mainFrame:Show()
        isShowing = true
    end

    self.Hide = function()
        mainFrame:Hide()
        isShowing = false
    end

    self.GetFrame = function()
        return mainFrame
    end

    mainFrame = Initialize()

    return self
end
