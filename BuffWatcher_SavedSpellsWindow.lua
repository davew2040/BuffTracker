local SavedSpellRow = {}

function SavedSpellRow:new(parent)
    self = {}

    local currentSpell = nil
    local RemoveEventName = "SPELL_REMOVE"
    local EditEventName = "SPELL_EDIT"
    local indexedRecords = {}

    local events = BuffWatcher_Callbacks:new()

    local savedSpellRowFrame = CreateFrame("Frame", "Spell Row", parent)

    local removeButton = BuffWatcher_Shared_Singleton.GetButton(
        savedSpellRowFrame, 
        "Interface/Buttons/UI-DialogBox-Button-Up", 
        "Interface/Buttons/UI-DialogBox-Button-Down"
    )
    
    removeButton:SetPoint("TOPLEFT", savedSpellRowFrame, "TOPLEFT", 0, 13)
    removeButton:SetWidth(75)
    removeButton:SetHeight(40)
    removeButton:SetScript("OnClick", function()
        events.fire(RemoveEventName, currentSpell)
    end)
    
    local removeButtonText = removeButton:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    removeButtonText:SetText("Remove")
    removeButtonText:SetPoint("CENTER", 0, 8)

    local editButton = BuffWatcher_Shared_Singleton.GetButton(
        savedSpellRowFrame, 
        "Interface/Buttons/UI-DialogBox-Button-Up", 
        "Interface/Buttons/UI-DialogBox-Button-Down"
    )
    
    editButton:SetPoint("TOPLEFT", savedSpellRowFrame, "TOPLEFT", 85, 13)
    editButton:SetWidth(75)
    editButton:SetHeight(40)
    editButton:SetScript("OnClick", function()
        events.fire(EditEventName, currentSpell)
    end)
    
    local editButtonText = editButton:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    editButtonText:SetText("Edit")
    editButtonText:SetPoint("CENTER", 0, 8)

    local textureFrame = savedSpellRowFrame:CreateTexture()
    textureFrame:SetPoint("LEFT", savedSpellRowFrame, "TOPLEFT", 200, 0)
    textureFrame:SetSize(32, 32)

    local spellTypeText = savedSpellRowFrame:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    spellTypeText:SetPoint("LEFT", savedSpellRowFrame, "TOPLEFT", 275, 0)

    local spellIdText = savedSpellRowFrame:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    spellIdText:SetPoint("LEFT", savedSpellRowFrame, "TOPLEFT", 375, 0)

    local spellNameText = savedSpellRowFrame:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    spellNameText:SetPoint("LEFT", savedSpellRowFrame, "TOPLEFT", 475, 0)

    local chkParty = CreateFrame("CheckButton", "MyCheckButton", savedSpellRowFrame, "UICheckButtonTemplate")
    chkParty:SetPoint("LEFT", savedSpellRowFrame, "TOPLEFT", 625, 0)
    chkParty:SetEnabled(false)

    local chkArena = CreateFrame("CheckButton", "MyCheckButton", savedSpellRowFrame, "UICheckButtonTemplate")
    chkArena:SetPoint("LEFT", savedSpellRowFrame, "TOPLEFT", 675, 0)
    chkArena:SetEnabled(false)

    local chkNameplates = CreateFrame("CheckButton", "MyCheckButton", savedSpellRowFrame, "UICheckButtonTemplate")
    chkNameplates:SetPoint("LEFT", savedSpellRowFrame, "TOPLEFT", 725, 0)
    chkNameplates:SetEnabled(false)

    local chkRaids = CreateFrame("CheckButton", "MyCheckButton", savedSpellRowFrame, "UICheckButtonTemplate")
    chkRaids:SetPoint("LEFT", savedSpellRowFrame, "TOPLEFT", 800, 0)
    chkRaids:SetEnabled(false)

    self.getFrame = function()
        return savedSpellRowFrame
    end

    self.setSpell = function(spell)
        currentSpell = spell

        local spellName, _ = GetSpellInfo(spell.spellId)
        local texture = GetSpellTexture(spell.spellId)

        spellIdText:SetText(spell.spellId)
        spellTypeText:SetText(BuffWatcher_Shared_Singleton.SpellTypeLabels[spell.buffType])
        spellNameText:SetText(spellName)
        textureFrame:SetTexture(texture)
        chkParty:SetChecked(spell.showInParty)
    end

    self.clearSpell = function()
        currentSpell = nil

        spellIdText:SetText('(none)')
        spellNameText:SetText('(none)')
        textureFrame:SetTexture(nil)
    end

    self.getSpell = function()
        return currentSpell;
    end

    self.registerRemove = function(fn)
        events.registerCallback(RemoveEventName, fn)
    end

    self.registerEdit = function(fn)
        events.registerCallback(EditEventName, fn)
    end

    return self
end

BuffWatcher_SavedSpellsWindow = {}
function BuffWatcher_SavedSpellsWindow:new(parent, incomingStoredSpells, addEditCastWindow)
    self = {}

    local pageSize = 10
    local mainFrame = nil
    local storedSpellsRegistry = incomingStoredSpells
    local activeStoredSpells = {}
    local indexedRecords = {}
    local uiSpellRows = {}
    local pagerText = nil
    local spellRowHeight = 32
    local pager = Pager:new(pageSize, 0)

    local handleSpellRemove = function(...) 
        storedSpellsRegistry.removeSpell(select(1, ...))
        self.UpdateWindow()
    end

    local handleSpellEdit = function(...) 
        local editTarget = select(1, ...)

        DevTool:AddData(editTarget, "fixme incoming editTarget")

        addEditCastWindow.Show(editTarget, function(editedModel)

            DevTool:AddData(editedModel, "fixme editedModel")

            DevTool:AddData(CopyTable(editTarget), "fixme editTarget before")
            editTarget.showInParty = editedModel.showInParty
            editTarget.sizeMultiplier = editedModel.sizeMultiplier

            DevTool:AddData(editTarget, "fixme editTarget after")

            DevTool:AddData(activeStoredSpells, "fixme activeStoredSpells")
            storedSpellsRegistry.saveSpellsToDatabase(activeStoredSpells)

            addEditCastWindow:Hide()
        end)

        self.UpdateWindow()
    end

    local Export = function()
        BuffWatcher_WeakAuraInterface_Singleton.UpdateSpells()
    end

    local handleSpellAdded = function()
        Export()
        self.UpdateWindow()
    end

    local UpdateSpellRows = function()
        local currentPageCount = pager.getPageEnd() - pager.getPageStart()
    
        local rowIndex = 1
        for i=pager.getPageStart(), pager.getPageEnd() do
            uiSpellRows[rowIndex].setSpell(indexedRecords[i])
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

    local Initialize = function()
        local frame = CreateFrame("Frame", "BuffWatcher_LoggerWindow", parent, "BackdropTemplate")

        storedSpellsRegistry.registerSpellAdded(handleSpellAdded)

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

        local partyLabel = labelsFrame:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
        partyLabel:SetPoint("LEFT", labelsFrame, "TOPLEFT", 600, 0)  
        partyLabel:SetText("PARTY") 

        local arenaLabel = labelsFrame:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
        arenaLabel:SetPoint("LEFT", labelsFrame, "TOPLEFT", 650, 0)  
        arenaLabel:SetText("ARENA") 
        
        local nameplatesLabel = labelsFrame:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
        nameplatesLabel:SetPoint("LEFT", labelsFrame, "TOPLEFT", 700, 0)  
        nameplatesLabel:SetText("ARENA") 

        local raidsLabel = labelsFrame:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
        raidsLabel:SetPoint("LEFT", labelsFrame, "TOPLEFT", 750, 0)  
        raidsLabel:SetText("RAIDS") 

        -- end grid labels

        -- start spell rows
        for i=1,pageSize do 
            local newRow = SavedSpellRow:new(frame)
    
            newRow.getFrame():SetPoint("TOPLEFT", frame, "TOPLEFT", 15, -145 - i*spellRowHeight)
            newRow.getFrame():Show()
            newRow.getFrame():SetSize(700, 50)
            newRow.registerRemove(handleSpellRemove)
            newRow.registerEdit(handleSpellEdit)

            table.insert(uiSpellRows, newRow)
        end
        -- end spell rows

        -- export button start
        local exportButton = BuffWatcher_Shared_Singleton.GetButton(
            frame, 
            "Interface/Buttons/UI-DialogBox-Button-Up", 
            "Interface/Buttons/UI-DialogBox-Button-Down"
        )
        
        exportButton:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -400, 5)
        exportButton:SetWidth(100)
        exportButton:SetHeight(64)
        exportButton:SetScript("OnClick", function()
            --Export()
            
            DevTool:AddData(WeakAuras, "WeakAuras")
            DevTool:AddData(WeakAurasSaved, "WeakAurasSaved")

            local byKey = BuffWatcher_Shared_Singleton.TableKeyFilter(WeakAurasSaved.displays, 
                function(key) return key == "Buff Watcher Copy Source" end
            )

            --WeakAurasSaved.displays["Buff Watcher Copy Result"] = CopyTable(byKey["Buff Watcher Copy Source"])

            local copied = CopyTable(byKey["Buff Watcher Copy Source"])
            copied.id = "Buff Watcher Copy Result"
            copied.uid = nil
            WeakAuras.Add(copied)
        end)
    
        -- start refresh button
        local refreshText = exportButton:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        refreshText:SetText("Export")
        refreshText:SetPoint("CENTER", 0, 8)
        -- end refresh button

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
                UpdateSpellRows()
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
                UpdateSpellRows()
            end
        )
    
        pagerText = frame:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
        pagerText:SetPoint("CENTER", frame, "BOTTOMRIGHT", -160, 45)
        pagerText:SetText("test text")

        return frame
    end

    local GetIndexedRecords = function(sourceRecords)
        local indexedRecords = {}

        local i = 1
        for k,v in pairs(sourceRecords) do 
            indexedRecords[i] = v
            i = i + 1
        end
    
        return indexedRecords
    end
    
    self.UpdateWindow = function()
        activeStoredSpells = storedSpellsRegistry.getSpells()
        indexedRecords = GetIndexedRecords(activeStoredSpells)
        pager = Pager:new(pageSize, #indexedRecords)
        UpdateSpellRows()
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
