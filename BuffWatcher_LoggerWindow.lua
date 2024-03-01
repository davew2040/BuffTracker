local AceGUI = LibStub("AceGUI-3.0")

BuffWatcher_LoggerWindow = {}

---@param incomingStoredSpells BuffWatcher_StoredSpellsRegistry
---@param loggerModule BuffWatcher_LoggerModule
function BuffWatcher_LoggerWindow:new(incomingStoredSpells, loggerModule)
    self = {}

    local SpellTypes = BuffWatcher_Shared_Singleton.SpellTypes
    local SpellTypeLabels = BuffWatcher_Shared_Singleton.SpellTypeLabels

    ---@class BuffWatcher_LoggerWindow_SpellFilters
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
    ---@type BuffWatcher_LoggerWindow_SpellRow[]
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

    local handleSpellAdd = function(...) 
        local spellRecord = select(1, ...)
        storedSpells.addSpell(spellRecord)
        self.UpdateWindow()
    end

    ---@param castRecord BuffWatcher_CastRecord
    ---@param filter BuffWatcher_LoggerWindow_SpellFilters
    local meetsFilter = function(castRecord, filter) 
        if (filter.spellType ~= SpellTypes.Any and castRecord.type ~= filter.spellType) then
            return false
        end

        if (filter.name ~= nil and filter.name ~= "") then
            if string.find(castRecord.loweredName, filter.name) == nil then
                return false
            end
        end

        if (filter.caster ~= nil and filter.caster ~= "") then
            if string.find(castRecord.loweredCaster, filter.caster) == nil then
                return false
            end
        end

        return true
    end

    local applyFilters = function(castRecords, filters)
        local filtered = {}

        for k,v in pairs(castRecords) do
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
        filterCasterName:SetCallback("OnTextChanged", function(control, event, text)
            setCasterNameFilter(text ~= nil and text or "")
        end)

        filtersHolderFrame:AddChild(filterCasterName)
    
        -- spell rows start
        for i=1,pageSize do 
            local newRow = BuffWatcher_LoggerWindow_SpellRow:new(incomingStoredSpells)
   
            frame:AddChild(newRow.getFrame())

            newRow.registerAdd(handleSpellAdd)
            
            table.insert(uiSpellRows, newRow)
        end
        -- spell rows end

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

        pagerText = AceGUI:Create("Label")
        pagerText:SetJustifyH("CENTER")
        pagerText:SetJustifyV("MIDDLE")

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
        spellRecords = loggerModule.GetSpellRecords()
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
