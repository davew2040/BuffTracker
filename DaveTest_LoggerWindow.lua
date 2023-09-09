local SpellRow = {}
function SpellRow:new(parent)
    self = {}

    local currentSpell = nil

    local spellRowFrame = CreateFrame("Frame", "Test Frame", parent)

    local textureFrame = spellRowFrame:CreateTexture()
    textureFrame:SetPoint("LEFT", spellRowFrame, "TOPLEFT", 25, 0)
    textureFrame:SetSize(32, 32)

    local spellTypeText = spellRowFrame:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    spellTypeText:SetPoint("LEFT", spellRowFrame, "TOPLEFT", 100, 0)

    local spellIdText = spellRowFrame:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    spellIdText:SetPoint("LEFT", spellRowFrame, "TOPLEFT", 200, 0)

    local spellNameText = spellRowFrame:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    spellNameText:SetPoint("LEFT", spellRowFrame, "TOPLEFT", 300, 0)

    local sourceNameText = spellRowFrame:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    sourceNameText:SetPoint("LEFT", spellRowFrame, "TOPLEFT", 550, 0)

    self.getFrame = function()
        return spellRowFrame
    end

    self.setSpell = function(spell)
        currentSpell = spell

        local spellName, _ = GetSpellInfo(spell.spellId)
        local texture = GetSpellTexture(spell.spellId)

        spellIdText:SetText(spell.spellId)
        spellTypeText:SetText(spell.type)
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

    return self
end

DaveTest_LoggerWindow = {}
function DaveTest_LoggerWindow:new(parent, spellCount, spellRowHeight, pager)
    self = {}

    local mainFrame = nil
    local pageSize = 12
    local spellRowHeight = 32
    local spellRecords = {}
    local uiSpellRows = {}
    local indexedSpellRecords = {}
    local pagerText = nil
    local dropDown = nil
    local foundSpells = {}

    local pager = Pager:new(pageSize, 0)

    local GetButton = function(parent, unpressedTexture, pressedTexture)
        local button = CreateFrame("Button", "random button title", parent)
    
        local ntex = button:CreateTexture()
        ntex:SetTexture(unpressedTexture)
        ntex:SetAllPoints()	
        button:SetNormalTexture(ntex)
        
        local ptex = button:CreateTexture()
        ptex:SetTexture(pressedTexture)
        ptex:SetAllPoints()
        button:SetPushedTexture(ptex)
        
        return button;
    end

    local GetIndexedRecords = function()
        local iSpellRecords = {}
    
        local i = 1
        for k,v in pairs(spellRecords) do -- might need to use ipairs() instead?
            iSpellRecords[i] = v
            i = i + 1
        end
    
        return iSpellRecords
    end

    local OnEvent = function (ref, event, ...)
        if (event == "COMBAT_LOG_EVENT_UNFILTERED") then
            local eventInfo = {CombatLogGetCurrentEventInfo()}
            local subevent = eventInfo[2]
            local sourceGuid = eventInfo[4]
            local sourceName = eventInfo[5]

            if (subevent == "SPELL_CAST_SUCCESS") then
                local spellId = eventInfo[12]
                local spellRecord = DaveTest_Shared_Singleton.BuildSpellCastRecord("SPELL_CAST", spellId, sourceName)

                if (spellRecords[spellRecord.key] == nil) then
                    spellRecords[spellRecord.key] = spellRecord
                end

                if (true) then -- sourceGuid == UnitGUID("player")) then
                    if (foundSpells[spellId] == nil) then
                        foundSpells[spellId] = true
                    end
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

                    local buffRecord = nil
                    if (v.isHelpful) then
                        buffRecord = DaveTest_Shared_Singleton.BuildSpellCastRecord("BUFF", v.spellId, unitName)
                    else
                        buffRecord = DaveTest_Shared_Singleton.BuildSpellCastRecord("DEBUFF", v.spellId, unitName)
                    end

                    if (spellRecords[buffRecord.key] == nil) then
                        spellRecords[buffRecord.key] = buffRecord
                    end
                end
            end
        end
    end

    local Initialize = function(parent)
        local frame = CreateFrame("Frame", "DaveTest_LoggerWindow", parent, "BackdropTemplate")

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
        
        frame:SetBackdropColor(0, 0, 0, .5)
        frame:SetBackdropBorderColor(0, 0, 0)
        frame:EnableMouse(true)
        frame:SetMovable(true)
        frame:RegisterForDrag("LeftButton")
        frame:SetScript("OnDragStart", frame.StartMoving)
        frame:SetScript("OnDragStop", frame.StopMovingOrSizing)
        frame:SetScript("OnHide", frame.StopMovingOrSizing)
    
        for i=1,pageSize do 
            local newRow = SpellRow:new(frame)
    
            newRow.getFrame():SetPoint("TOPLEFT", frame, "TOPLEFT", 0, -i*spellRowHeight)
            newRow.getFrame():Show()
            newRow.getFrame():SetSize(50, 50)
            
            table.insert(uiSpellRows, newRow)
        end
    
        local close = CreateFrame("Button", "YourCloseButtonName", frame, "UIPanelCloseButton")
        close:SetPoint("TOPRIGHT", frame, "TOPRIGHT")
        close:SetScript("OnClick", function()
            frame:Hide()
        end)

        close:SetPoint("TOPRIGHT", frame, "TOPRIGHT")
        close:SetScript("OnClick", function()
            frame:Hide()
        end)
    
        local exportButton = GetButton(
            frame, 
            "Interface/Buttons/UI-DialogBox-Button-Up", 
            "Interface/Buttons/UI-DialogBox-Button-Down"
        )
        
        exportButton:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -300, 0)
        exportButton:SetWidth(100)
        exportButton:SetHeight(64)
        exportButton:SetScript("OnClick", function()
            WeakAuras.ScanEvents("my_custom_event", {key = 6673})
        end)
    
        local exportText = exportButton:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        exportText:SetText("Export")
        exportText:SetPoint("CENTER", 0, 8)
    
        local nextButton = GetButton(
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
    
        local prevButton = GetButton(
            frame, 
            "Interface/Buttons/UI-SpellbookIcon-PrevPage-Up", 
            "Interface/Buttons/UI-SpellbookIcon-PrevPage-Down"
        )
    
        prevButton:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -200, 25)
        prevButton:SetWidth(40)
        prevButton:SetHeight(40)
        prevButton:SetScript("OnClick", 
            function()
                pager.goPreviousPage()
                self.UpdateSpellRows()
            end
        )
    
        pagerText = frame:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
        pagerText:SetPoint("CENTER", frame, "BOTTOMRIGHT", -135, 45)
        pagerText:SetText("test text")
    
        local function WPDropDownDemo_OnClick(self)
            UIDropDownMenu_SetSelectedValue(dropDown, self.value)
    
            if self.value == 1 then
                print("You can continue to believe whatever you want to believe.")
            elseif self.value == 2 then
                print("Let's see how deep the rabbit hole goes.")
            end
           end
    
        local function WPDropDownDemo_Menu(frame, level, menuList)
            local info = UIDropDownMenu_CreateInfo()
            info.func = WPDropDownDemo_OnClick
            info.text, info.value, info.checked = "Blue Pill", 1, false
            UIDropDownMenu_AddButton(info)
            info.text, info.value, info.checked = "Red Pill", 2, false
            UIDropDownMenu_AddButton(info)
        end
    
        local dropDown = CreateFrame("Frame", "WPDemoDropDown", frame, "UIDropDownMenuTemplate")
        dropDown:SetPoint("RIGHT", frame, "BOTTOMRIGHT", -450, 45)
        
        UIDropDownMenu_SetWidth(dropDown, 150) 
        UIDropDownMenu_Initialize(dropDown, WPDropDownDemo_Menu)
        UIDropDownMenu_SetSelectedValue(dropDown, 1)

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
    
        local text = "Showing page " .. pager.getCurrentPage() .. " of " .. pager.getTotalPageCount();
        pagerText:SetText(text)
    end
    
    self.UpdateWindow = function() 
        indexedSpellRecords = GetIndexedRecords()
        pager = Pager:new(pageSize, #indexedSpellRecords)
        self.UpdateSpellRows()
    end

    self.GetFrame = function()
        return mainFrame
    end

    mainFrame = Initialize()

    return self
end
