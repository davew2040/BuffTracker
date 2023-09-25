local SpellRow = {}
function SpellRow:new(parent)
    self = {}

    local currentSpell = nil
    local AddEventName = "SPELL_ADD"

    local events = BuffWatcher_Callbacks:new()

    local spellRowFrame = CreateFrame("Frame", "Spell Row", parent)

    local addButton = BuffWatcher_Shared_Singleton.GetButton(
        spellRowFrame, 
        "Interface/Buttons/UI-DialogBox-Button-Up", 
        "Interface/Buttons/UI-DialogBox-Button-Down"
    )
    
    addButton:SetPoint("TOPLEFT", spellRowFrame, "TOPLEFT", 0, 13)
    addButton:SetWidth(75)
    addButton:SetHeight(40)
    addButton:SetScript("OnClick", function()
        events.fire(AddEventName, currentSpell)
    end)
    
    local addButtonText = addButton:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    addButtonText:SetText("Add")
    addButtonText:SetPoint("CENTER", 0, 8)

    local textureFrame = spellRowFrame:CreateTexture()
    textureFrame:SetPoint("LEFT", spellRowFrame, "TOPLEFT", 125, 0)
    textureFrame:SetSize(32, 32)

    local spellTypeText = spellRowFrame:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    spellTypeText:SetPoint("LEFT", spellRowFrame, "TOPLEFT", 200, 0)

    local spellIdText = spellRowFrame:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    spellIdText:SetPoint("LEFT", spellRowFrame, "TOPLEFT", 300, 0)

    local spellNameText = spellRowFrame:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    spellNameText:SetPoint("LEFT", spellRowFrame, "TOPLEFT", 400, 0)

    local sourceNameText = spellRowFrame:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    sourceNameText:SetPoint("LEFT", spellRowFrame, "TOPLEFT", 650, 0)

    self.getFrame = function()
        return spellRowFrame
    end

    self.setSpell = function(spell)
        currentSpell = spell

        local spellName, _ = GetSpellInfo(spell.spellId)
        local texture = GetSpellTexture(spell.spellId)

        spellIdText:SetText(spell.spellId)
        spellTypeText:SetText(BuffWatcher_Shared_Singleton.SpellTypeLabels[spell.type])
        spellNameText:SetText(spellName)
        sourceNameText:SetText(spell.sourceName)
        textureFrame:SetTexture(texture)
    end

    self.clearSpell = function()
        currentSpell = nil

        spellIdText:SetText('(none)')
        spellNameText:SetText('(none)')
        sourceNameText:SetText('(none)')
        textureFrame:SetTexture(nil)
    end

    self.getSpell = function()
        return currentSpell;
    end

    self.registerAdd = function(fn)
        events.registerCallback(AddEventName, fn)
    end

    return self
end

BuffWatcher_LoggerWindow = {}
function BuffWatcher_LoggerWindow:new(parent, incomingStoredSpells)
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
            local updateInfo = select(2, ...)
            if (updateInfo.addedAuras ~= nil) then
                for i,v in ipairs(updateInfo.addedAuras) do
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
        spellFilters.name = string.lower(newFilter)
        self.UpdateWindow()
    end

    local setCasterNameFilter = function(newFilter)
        spellFilters.caster = string.lower(newFilter)
        self.UpdateWindow()
    end

    local Initialize = function(parent)
        local frame = CreateFrame("Frame", "BuffWatcher_LoggerWindow", parent, "BackdropTemplate")

        local backdropInfo =
        {
            bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
            edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
            tile = true,
            tileEdge = true,
            tileSize = 8,
            edgeSize = 8,
            insets = { left = 1, right = 1, top = 1, bottom = 1 },
        }

        frame:SetBackdrop(backdropInfo)
        -- debug color
        frame:SetBackdropColor(0, 0, 0, 1)

        -- buff type picker start
        local function WPDropDownDemo_OnClick(ref)
            UIDropDownMenu_SetSelectedValue(buffPickerDropdown, ref.value)
            setSpellTypeFilter(ref.value)
        end
    
        local function WPDropDownDemo_Menu(frame, level, menuList)
            local OrderedSpellTypes = {
                [1] = SpellTypes.Any,
                [2] = SpellTypes.Buff,
                [3] = SpellTypes.Debuff,
                [4] = SpellTypes.Cast
            }

            for k, v in pairs(OrderedSpellTypes) do
                local info = UIDropDownMenu_CreateInfo()

                info.value = v
                info.text = SpellTypeLabels[v]
                info.checked = false
                info.func = WPDropDownDemo_OnClick

                UIDropDownMenu_AddButton(info)
            end
        end
        -- end buff type picker

        -- start filter labels
        local filterLabelsFrame = CreateFrame("Frame", nil, frame)
        filterLabelsFrame:SetPoint("TOPLEFT", frame, "TOPLEFT", 25, -30) 
        filterLabelsFrame:Show()
        filterLabelsFrame:SetSize(50, 50)

        local filterTypeLabel = filterLabelsFrame:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
        filterTypeLabel:SetPoint("LEFT", filterLabelsFrame, "TOPLEFT", 0, 0)  
        filterTypeLabel:SetText("TYPE") 

        local filterSpellLabel = filterLabelsFrame:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
        filterSpellLabel:SetPoint("LEFT", filterLabelsFrame, "TOPLEFT", 150, 0)  
        filterSpellLabel:SetText("SPELL") 

        local filterCasterLabel = filterLabelsFrame:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
        filterCasterLabel:SetPoint("LEFT", filterLabelsFrame, "TOPLEFT", 275, 0)  
        filterCasterLabel:SetText("CASTER") 
        -- end filter labels

        -- start grid labels
        local labelsFrame = CreateFrame("Frame", nil, frame)
        labelsFrame:SetPoint("TOPLEFT", frame, "TOPLEFT", 15, -120) 
        labelsFrame:Show()
        labelsFrame:SetSize(50, 50)

        local spellTypeLabel = labelsFrame:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
        spellTypeLabel:SetPoint("LEFT", labelsFrame, "TOPLEFT", 200, 0)  
        spellTypeLabel:SetText("TYPE") 

        local spellIdLabel = labelsFrame:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
        spellIdLabel:SetPoint("LEFT", labelsFrame, "TOPLEFT", 300, 0)  
        spellIdLabel:SetText("SPELL ID") 

        local spellNameLabel = labelsFrame:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
        spellNameLabel:SetPoint("LEFT", labelsFrame, "TOPLEFT", 400, 0)  
        spellNameLabel:SetText("SPELL NAME") 

        local spellCasterLabel = labelsFrame:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
        spellCasterLabel:SetPoint("LEFT", labelsFrame, "TOPLEFT", 650, 0)  
        spellCasterLabel:SetText("CASTER") 
        -- end grid labels

        buffPickerDropdown = CreateFrame("Frame", "WPDemoDropDown", frame, "UIDropDownMenuTemplate")
        buffPickerDropdown:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, -45)
        
        UIDropDownMenu_SetWidth(buffPickerDropdown, 125) 
        UIDropDownMenu_Initialize(buffPickerDropdown, WPDropDownDemo_Menu)
        UIDropDownMenu_SetSelectedValue(buffPickerDropdown, SpellTypes.Any)
        -- buff type picker end       

        -- filter spell name
        local filterSpellName = CreateFrame("Editbox", nil, frame, "InputBoxTemplate")
        filterSpellName:SetPoint("TOPLEFT", frame, "TOPLEFT", 175, -35);
        filterSpellName:SetWidth(100);
        filterSpellName:SetHeight(50);
        filterSpellName:SetMovable(false);
        filterSpellName:SetAutoFocus(false);
        filterSpellName:SetScript("OnTextChanged", function(...)
            local ctl = select(1, ...)
            local textValue = ctl:GetText()
            setSpellNameFilter(textValue ~= nil and textValue or "")
        end)
        -- end filter spell name

        -- filter caster name
        local filterCasterName = CreateFrame("Editbox", nil, frame, "InputBoxTemplate")
        filterCasterName:SetPoint("TOPLEFT", frame, "TOPLEFT", 300, -35);
        filterCasterName:SetWidth(100);
        filterCasterName:SetHeight(50);
        filterCasterName:SetMovable(false);
        filterCasterName:SetAutoFocus(false);
        filterCasterName:SetScript("OnTextChanged", function(...)
            local ctl = select(1, ...)
            local textValue = ctl:GetText()
            setCasterNameFilter(textValue ~= nil and textValue or "")
        end)
        -- end caster spell name

        -- spell rows start
        for i=1,pageSize do 
            local newRow = SpellRow:new(frame)
    
            newRow.getFrame():SetPoint("TOPLEFT", frame, "TOPLEFT", 15, -135 - i*spellRowHeight)
            newRow.getFrame():Show()
            newRow.getFrame():SetSize(50, 50)
            newRow.registerAdd(handleSpellAdd)
            
            table.insert(uiSpellRows, newRow)
        end
        -- spell rows end
    
        -- refresh button start
        local refreshButton = BuffWatcher_Shared_Singleton.GetButton(
            frame, 
            "Interface/Buttons/UI-DialogBox-Button-Up", 
            "Interface/Buttons/UI-DialogBox-Button-Down"
        )
        
        refreshButton:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -350, 5)
        refreshButton:SetWidth(100)
        refreshButton:SetHeight(64)
        refreshButton:SetScript("OnClick", function()
            self.UpdateWindow()
        end)
    
        local refreshText = refreshButton:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        refreshText:SetText("Refresh")
        refreshText:SetPoint("CENTER", 0, 8)
        -- refresh button end
    
        local nextButton = BuffWatcher_Shared_Singleton.GetButton(
            frame,
            "Interface/Buttons/UI-SpellbookIcon-NextPage-Up",
            "Interface/Buttons/UI-SpellbookIcon-NextPage-Down"
        )
    
        nextButton:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -25, 25)
        nextButton:SetWidth(40)
        nextButton:SetHeight(40)
        nextButton:SetScript("OnClick", 
            function()
                pager.goNextPage()
                self.UpdateSpellRows()
            end
        )
    
        local prevButton = BuffWatcher_Shared_Singleton.GetButton(
            frame, 
            "Interface/Buttons/UI-SpellbookIcon-PrevPage-Up", 
            "Interface/Buttons/UI-SpellbookIcon-PrevPage-Down"
        )
    
        prevButton:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -250, 25)
        prevButton:SetWidth(40)
        prevButton:SetHeight(40)
        prevButton:SetScript("OnClick", 
            function()
                pager.goPreviousPage()
                self.UpdateSpellRows()
            end
        )
    
        pagerText = frame:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
        pagerText:SetPoint("CENTER", frame, "BOTTOMRIGHT", -160, 45)
        pagerText:SetText("test text")

        frame:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
        frame:RegisterEvent("UNIT_AURA")
        frame:SetScript("OnEvent", OnEvent)

        return frame
    end

    self.UpdateSpellRows = function()
        local currentPageCount = pager.getPageEnd() - pager.getPageStart()
    
        local rowIndex = 1
        for i=pager.getPageStart(), pager.getPageEnd() do
            uiSpellRows[rowIndex].setSpell(indexedSpellRecords[i])
            uiSpellRows[rowIndex].getFrame():Show()
            rowIndex = rowIndex + 1
        end
    
        while (rowIndex <= pageSize) do
            uiSpellRows[rowIndex].clearSpell()
            uiSpellRows[rowIndex].getFrame():Hide()
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
