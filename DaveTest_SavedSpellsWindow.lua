local SavedSpellRow = {}
function SavedSpellRow:new(parent)
    self = {}

    local currentSpell = nil
    local RemoveEventName = "SPELL_REMOVE"
    local indexedRecords = {}

    local events = DaveTest_Callbacks:new()

    local savedSpellRowFrame = CreateFrame("Frame", "Spell Row", parent)

    local removeButton = DaveTest_Shared_Singleton.GetButton(
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
    
    local addButtonText = removeButton:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    addButtonText:SetText("Remove")
    addButtonText:SetPoint("CENTER", 0, 8)

    local textureFrame = savedSpellRowFrame:CreateTexture()
    textureFrame:SetPoint("LEFT", savedSpellRowFrame, "TOPLEFT", 125, 0)
    textureFrame:SetSize(32, 32)

    local spellTypeText = savedSpellRowFrame:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    spellTypeText:SetPoint("LEFT", savedSpellRowFrame, "TOPLEFT", 200, 0)

    local spellIdText = savedSpellRowFrame:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    spellIdText:SetPoint("LEFT", savedSpellRowFrame, "TOPLEFT", 300, 0)

    local spellNameText = savedSpellRowFrame:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    spellNameText:SetPoint("LEFT", savedSpellRowFrame, "TOPLEFT", 400, 0)

    local chkParty = CreateFrame("CheckButton", "MyCheckButton", UIParent)
    spellNameText:SetPoint("LEFT", savedSpellRowFrame, "TOPLEFT", 500, 0)
    chkParty:SetScript("OnClick", function() 
        print('clicked') 
    end)

    self.getFrame = function()
        return savedSpellRowFrame
    end

    self.setSpell = function(spell)
        currentSpell = spell

        local spellName, _ = GetSpellInfo(spell.spellId)
        local texture = GetSpellTexture(spell.spellId)

        spellIdText:SetText(spell.spellId)
        spellTypeText:SetText(DaveTest_Shared_Singleton.SpellTypeLabels[spell.buffType])
        spellNameText:SetText(spellName)
        textureFrame:SetTexture(texture)
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

    return self
end

DaveTest_SavedSpellsWindow = {}
function DaveTest_SavedSpellsWindow:new(parent, incomingStoredSpells)
    self = {}

    local pageSize = 10
    local mainFrame = nil
    local storedSpells = incomingStoredSpells
    local indexedRecords = {}
    local uiSpellRows = {}
    local spellRowHeight = 32
    local pager = Pager:new(pageSize, 0)

    local handleSpellRemove = function(...) 
        storedSpells.removeSpell(select(1, ...))
        self.UpdateWindow()
    end

    local handleSpellAdded = function()
        self.UpdateWindow()
    end

    local Export = function()
        DaveTest_WeakAuraInterface_Singleton.UpdateSpells()
    end

    local Initialize = function()
        local frame = CreateFrame("Frame", "DaveTest_LoggerWindow", parent, "BackdropTemplate")

        storedSpells.registerSpellAdded(handleSpellAdded)

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

        -- start spell rows
        for i=1,pageSize do 
            local newRow = SavedSpellRow:new(frame)
    
            newRow.getFrame():SetPoint("TOPLEFT", frame, "TOPLEFT", 0, -50 - i*spellRowHeight)
            newRow.getFrame():Show()
            newRow.getFrame():SetSize(50, 50)
            newRow.registerRemove(handleSpellRemove)
            
            table.insert(uiSpellRows, newRow)
        end
        -- end spell rows

        -- expport button start
        local exportButton = DaveTest_Shared_Singleton.GetButton(
            frame, 
            "Interface/Buttons/UI-DialogBox-Button-Up", 
            "Interface/Buttons/UI-DialogBox-Button-Down"
        )
        
        exportButton:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -300, 0)
        exportButton:SetWidth(100)
        exportButton:SetHeight(64)
        exportButton:SetScript("OnClick", function()
            Export()
        end)
    
        local refreshText = exportButton:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        refreshText:SetText("Export")
        refreshText:SetPoint("CENTER", 0, 8)
        -- refresh button end

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
    
        --fixme
        -- local text = "Showing page " .. pager.getCurrentPage() .. " of " .. pager.getTotalPageCount();
        -- pagerText:SetText(text)
    end
    
    self.UpdateWindow = function()
        local spells = storedSpells.getSpells()
        indexedRecords = GetIndexedRecords(spells)
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
