local AceGUI = LibStub("AceGUI-3.0")

---@class BuffWatcher_SavedSpellsWindow
BuffWatcher_SavedSpellsWindow = {}

BuffWatcher_SavedSpellsWindow.ColumnWidths = {
    REMOVE = 125,
    EDIT = 75, 
    ICON = 100, 
    SPELL_TYPE = 125,
    SPELL_ID = 75, 
    SPELL_NAME = 250,
    CHECK_BOX = 50
}

---@class BuffWatcher_SavedSpellsFilters
---@field name string
local BuffWatcher_SavedSpellsFilters = {
    name = ""
}

---@param incomingStoredSpells BuffWatcher_StoredSpellsRegistry
---@param addEditCastWindow BuffWatcher_AddEditSavedCast
---@param weakAuraExporter BuffWatcher_WeakAuraExporter
---@param contextStore BuffWatcher_AuraContextStore
function BuffWatcher_SavedSpellsWindow:new(incomingStoredSpells, addEditCastWindow, weakAuraExporter, contextStore)
    self = {}

    ---@param input table<integer, BuffWatcher_StoredSpell>
    local sortByNameAscending = function(input)
        ---@param spell BuffWatcher_StoredSpell
        BuffWatcher_Shared.SortBy(input, function(spell)
            local spellName = GetSpellInfo(spell.spellId)

            if (spellName ~= nil) then
                return spellName
            else
                DevTool:AddData(spell.spellId, "fixme bad spell id")
            end

            return ''
        end)
    end

    ---@param input table<integer, BuffWatcher_StoredSpell>
    local sortByNameDescending = function(input)
        ---@param spell BuffWatcher_StoredSpell
        BuffWatcher_Shared.SortByDescending(input, function(spell)
            local spellName = GetSpellInfo(spell.spellId)
            return spellName
        end)
    end

    local pageSize = 10
    local mainFrame = nil
    local storedSpellsRegistry = incomingStoredSpells
    ---@type table<string, BuffWatcher_StoredSpell>
    local activeStoredSpells = {}
    local indexedRecords = {}
    ---@type table<integer, BuffWatcher_SavedSpellsWindow_SpellRow>
    local uiSpellRows = {}
    local pagerText = nil
    local spellRowHeight = 32
    local pager = Pager:new(pageSize, 0)

    local sorter = sortByNameAscending

    ---@type BuffWatcher_SavedSpellsFilters
    local spellFilters = {
        name = "",
    }

    local handleSpellRemove = function(...) 
        storedSpellsRegistry.removeSpell(select(1, ...))
        self.UpdateWindow()
    end

    local handleSpellEdit = function(...)
        local editTarget = select(1, ...)

        addEditCastWindow.Show(editTarget, 
            function(editedModel)
                DevTool:AddData(editedModel, "fixme editedModel")
                
                local key = BuffWatcher_StoredSpell.GetStoredSpellKey(editedModel)
                activeStoredSpells[key] = editedModel
                DevTool:AddData(CopyTable(activeStoredSpells), "fixme activeStoredSpells before save")
                storedSpellsRegistry.saveSpellsToDatabase(activeStoredSpells)

                addEditCastWindow:Hide()
                
                self.UpdateWindow()
            end
        )
    end

    local handleSpellAdded = function()
        self.UpdateWindow()
    end

    local updateSpellRows = function()
        local currentPageCount = pager.getPageEnd() - pager.getPageStart()
    
        local rowIndex = 1
        for i=pager.getPageStart(), pager.getPageEnd() do
            uiSpellRows[rowIndex].SetSpell(indexedRecords[i])
            uiSpellRows[rowIndex].GetFrame().frame:Show()
            rowIndex = rowIndex + 1
        end
    
        while (rowIndex <= pageSize) do
            uiSpellRows[rowIndex].ClearSpell()
            uiSpellRows[rowIndex].GetFrame().frame:Hide()
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


    ---@param spellRecord BuffWatcher_StoredSpell
    ---@param filter BuffWatcher_SavedSpellsFilters
    ---@return boolean
    local meetsFilter = function(spellRecord, filter) 
        if (filter.name ~= nil and filter.name ~= "") then
            ---@type string
            local spellName = GetSpellInfo(spellRecord.spellId)
            
            if (spellName == nil) then
                return false 
            end

            if string.find(string.lower(spellName), filter.name) == nil then
                return false
            end
        end

        return true
    end

    ---@param spellRecords table<string, BuffWatcher_StoredSpell>
    ---@param filters BuffWatcher_SavedSpellsFilters
    ---@return table<string, BuffWatcher_StoredSpell>
    local applyFilters = function(spellRecords, filters)
        
        ---@type table<string, BuffWatcher_StoredSpell>
        local filtered = {}

        for k,v in pairs(spellRecords) do
            if (meetsFilter(v, filters) == true) then
                filtered[k] = v
            end
        end

        return filtered
    end
    

    local setSpellNameFilter = function(newFilter)
        spellFilters.name = string.lower(newFilter)
        self.UpdateWindow()
    end

    local initializeFilters = function(parent)
        local filtersHolderFrame = AceGUI:Create("SimpleGroup", "Filters Holder Frame")
        filtersHolderFrame:SetLayout("Flow")
        filtersHolderFrame:SetFullWidth(true)
        filtersHolderFrame:SetHeight(50)
        parent:AddChild(filtersHolderFrame)

        local filterSpellName = AceGUI:Create("EditBox")
            
        filterSpellName:SetWidth(150);
        filterSpellName:SetHeight(25);
        filterSpellName:SetLabel("Spell Name:");
        filterSpellName:SetCallback("OnTextChanged", function(control, event, text)
            setSpellNameFilter(text ~= nil and text or "")
        end)

        parent:AddChild(filterSpellName)
    end

    local setNameSortAscending = function()
        sorter = sortByNameAscending
        self.UpdateWindow()
    end

    local setNameSortDescending = function()
        sorter = sortByNameDescending
        self.UpdateWindow()
    end

    local initialize = function()
        local frame = AceGUI:Create("SimpleGroup")
        frame:SetLayout("List")
        frame:SetFullWidth(true)

        storedSpellsRegistry.registerSpellAdded(handleSpellAdded)

        initializeFilters(frame)

        -- start grid labels

        local labelsFrame = AceGUI:Create("SimpleGroup")
        labelsFrame:SetFullWidth(true)
        labelsFrame:SetLayout("Manual")
        labelsFrame:SetHeight(50)
        frame:AddChild(labelsFrame)

        local addLabelsFrame = function(text, anchorFrame, width, xOffset)
            local labelControl = AceGUI:Create("Label")
            labelControl:SetText(text)

            if (anchorFrame ~= nil) then
                labelControl:SetPoint("TOPLEFT", anchorFrame, "TOPRIGHT", xOffset, 0)
            else
                labelControl:SetPoint("TOPLEFT", labelsFrame.frame, "TOPLEFT", xOffset, -20)
            end
            labelControl:SetWidth(width)
            labelsFrame:AddChild(labelControl)

            return labelControl
        end

        local ColumnWidths = BuffWatcher_SavedSpellsWindow.ColumnWidths

        local spellTypeLabel = addLabelsFrame("TYPE", nil, ColumnWidths.SPELL_TYPE, ColumnWidths.REMOVE + ColumnWidths.EDIT + ColumnWidths.ICON)

        local spellIdLabel = addLabelsFrame("SPELL ID", spellTypeLabel.frame, ColumnWidths.SPELL_ID, 0)

        local spellNameLabel = addLabelsFrame("SPELL NAME", spellIdLabel.frame, ColumnWidths.SPELL_NAME, 0)

        local sortUpDown = BuffWatcher_SortUpDown:new()
        labelsFrame:AddChild(sortUpDown.GetFrame())
        sortUpDown.GetFrame():SetPoint("LEFT", spellNameLabel.frame, "LEFT", 80, 0)
        sortUpDown.RegisterSortUp(setNameSortAscending)
        sortUpDown.RegisterSortDown(setNameSortDescending)

        local partyLabel = addLabelsFrame("PARTY", spellNameLabel.frame, ColumnWidths.CHECK_BOX, 0)

        local arenaLabel = addLabelsFrame("ARENA", partyLabel.frame, ColumnWidths.CHECK_BOX, 0)

        local nameplatesLabel = addLabelsFrame("NAMEPLATES", arenaLabel.frame, ColumnWidths.CHECK_BOX, 0)

        local raidsLabel = addLabelsFrame("RAIDS", nameplatesLabel.frame, ColumnWidths.CHECK_BOX, 0)

        -- end grid labels

        -- start spell rows

        for i=1,pageSize do 
            local newRow = BuffWatcher_SavedSpellsWindow_SpellRow:new()

            newRow.registerRemove(handleSpellRemove)
            newRow.registerEdit(handleSpellEdit)

            frame:AddChild(newRow.GetFrame())

            table.insert(uiSpellRows, newRow)
        end
        -- end spell rows

        -- start actions frame
        local actionsHolderFrame = AceGUI:Create("SimpleGroup", "Actions Holder Frame")
        actionsHolderFrame:SetLayout("Flow")
        actionsHolderFrame:SetFullWidth(true)
        frame:AddChild(actionsHolderFrame)

        local importButton = AceGUI:Create("Button")
        importButton:SetText("Import")
        importButton:SetWidth(100)
        importButton:SetHeight(64)
        importButton:SetCallback("OnClick", function()
            BuffWatcher_ImportJsonDialog:new(storedSpellsRegistry)
        end)

        actionsHolderFrame:AddChild(importButton)

        local prevButton = AceGUI:Create("Button")
        prevButton:SetText("Prev")
        prevButton:SetWidth(60)
        prevButton:SetHeight(40)
        prevButton:SetCallback("OnClick", 
            function()
                pager.goPreviousPage()
                updateSpellRows()
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
                updateSpellRows()
            end
        )
    
        actionsHolderFrame:AddChild(nextButton)

        -- end actions frame

        return frame
    end

    ---@param sourceRecords table<string, BuffWatcher_StoredSpell>
    ---@return table<integer, BuffWatcher_StoredSpell>
    local getIndexedRows = function(sourceRecords)
        ---@type table<number, BuffWatcher_StoredSpell>
        local indexedRecords = {}

        local i = 1
        for k,v in pairs(sourceRecords) do 
            indexedRecords[i] = v
            i = i + 1
        end
    
        return indexedRecords
    end
    
    ---@param sourceSpells table<string, BuffWatcher_StoredSpell>
    ---@param sorter fun(input: table<integer, BuffWatcher_StoredSpell>)
    ---@return table<integer, BuffWatcher_StoredSpell>
    local sortAndIndexSpells = function(sourceSpells, sorter)
        ---@type table<integer, BuffWatcher_StoredSpell>
        local indexed = getIndexedRows(sourceSpells)

        sorter(indexed)

        return indexed
    end

    self.UpdateWindow = function()
        activeStoredSpells = storedSpellsRegistry.GetSpells()
        local filteredRecords = applyFilters(activeStoredSpells, spellFilters)
        indexedRecords = sortAndIndexSpells(filteredRecords, sorter)
        pager = Pager:new(pageSize, #indexedRecords)
        updateSpellRows()
    end

    self.GetFrame = function()
        return mainFrame
    end

    mainFrame = initialize()

    return self
end
