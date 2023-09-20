
DaveTest_AddEditSavedCast = {}
function DaveTest_AddEditSavedCast:new(parent)
    self = {}

    local mainFrame = nil

    local txtSpellName = nil
    local chkParty = nil
    local chkArenas = nil
    local chkEnemyNameplates = nil
    local chkGlow = nil
    local chkRaids = nil
    local multiplierSlider = nil
    local activeModel = nil

    -- self.StoredSpellFromCastRecord = function(spellRecord)
    --     return {
    --         spellId = spellRecord.spellId,
    --         buffType = spellRecord.type,
    --         version = 1,
    --         showInParty = true,
    --         showInArena = true,
    --         showInRaid = true,
    --         showOnNameplates = true, 
    --         duration = 0,
    --         showGlow = false,
    --         sizeMultiplier = 1,
    --     }

    local localOnSave = function() end

    local setSavedSpell = function(spell)
        activeModel = DaveTest_Shared_Singleton.CreateShallowCopy(spell)

        local spellName = GetSpellInfo(spell.spellId)

        txtSpellName:SetText(spellName)
        chkParty:SetChecked(spell.showInParty)
        chkArenas:SetChecked(spell.showInArena)
        chkRaids:SetChecked(spell.showInRaid)
        chkEnemyNameplates:SetChecked(spell.showOnNameplates)
        chkGlow:SetChecked(spell.showGlow)
        
        multiplierSlider:SetValue(spell.sizeMultiplier)
    end

    local getModel = function()
        return DaveTest_Shared_Singleton.CreateShallowCopy(activeModel)
    end

    local Initialize = function(parent)
        local frame = CreateFrame("Frame", "DaveTest_AddEditSavedCastw", parent, "BackdropTemplate")

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
        frame:SetBackdropColor(0, 1, 0, 1)

        local vLast = -50
        local xCol1 = 20
        local xCol2 = 250

        local spellLabel = frame:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
        spellLabel:SetPoint("LEFT", frame, "TOPLEFT", xCol1, vLast)  
        spellLabel:SetText("Spell:") 

        -- filter spell name
        txtSpellName = frame:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
        txtSpellName:SetPoint("LEFT", frame, "TOPLEFT", xCol2, vLast)  
        txtSpellName:SetText("XYZ") 
        
        vLast = vLast - 50

        local showInPartyLabel = frame:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
        showInPartyLabel:SetPoint("LEFT", frame, "TOPLEFT", xCol1, vLast)  
        showInPartyLabel:SetText("Show in Party:") 

        chkParty = CreateFrame("CheckButton", "MyCheckButton", frame, "UICheckButtonTemplate")
        chkParty:SetPoint("LEFT", frame, "TOPLEFT", xCol2, vLast)
        chkParty:SetScript("OnClick", function(control) 
            activeModel.showInParty = chkParty:GetChecked()
        end)

        vLast = vLast - 50

        local showInArenasLabel = frame:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
        showInArenasLabel:SetPoint("LEFT", frame, "TOPLEFT", xCol1, vLast)  
        showInArenasLabel:SetText("Show on Arena Enemies:") 

        chkArenas = CreateFrame("CheckButton", "MyCheckButton", frame, "UICheckButtonTemplate")
        chkArenas:SetPoint("LEFT", frame, "TOPLEFT", xCol2, vLast)
        chkArenas:SetScript("OnClick", function() 
            --fixme
        end)

        vLast = vLast - 50

        local showOnEnemyNameplates = frame:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
        showOnEnemyNameplates:SetPoint("LEFT", frame, "TOPLEFT", xCol1, vLast)  
        showOnEnemyNameplates:SetText("Show on Enemy Nameplates:") 

        chkEnemyNameplates = CreateFrame("CheckButton", "MyCheckButton", frame, "UICheckButtonTemplate")
        chkEnemyNameplates:SetPoint("LEFT", frame, "TOPLEFT", xCol2, vLast)
        chkEnemyNameplates:SetScript("OnClick", function() 
            --fixme
        end)

        vLast = vLast - 50

        local showInRaidsLabel = frame:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
        showInRaidsLabel:SetPoint("LEFT", frame, "TOPLEFT", xCol1, vLast)  
        showInRaidsLabel:SetText("Show in Raids:") 

        chkRaids = CreateFrame("CheckButton", "MyCheckButton", frame, "UICheckButtonTemplate")
        chkRaids:SetPoint("LEFT", frame, "TOPLEFT", xCol2, vLast)
        chkRaids:SetScript("OnClick", function() 
            --fixme
        end)

        vLast = vLast - 50

        local glowLabel = frame:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
        glowLabel:SetPoint("LEFT", frame, "TOPLEFT", xCol1, vLast)  
        glowLabel:SetText("Glow:") 

        chkGlow = CreateFrame("CheckButton", "MyCheckButton", frame, "UICheckButtonTemplate")
        chkGlow:SetPoint("LEFT", frame, "TOPLEFT", xCol2, vLast)
        chkGlow:SetScript("OnClick", function() 
            print('fixme chkGlow clicked')
        end)

        vLast = vLast - 50

        local sizeMultiplierLabel = frame:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
        showInRaidsLabel:SetPoint("LEFT", frame, "TOPLEFT", xCol1, vLast)  
        showInRaidsLabel:SetText("Size Multiplier:") 

        multiplierSlider = CreateFrame("Slider", "MyCheckButton", frame, "MinimalSliderWithSteppersTemplate")
        multiplierSlider:SetPoint("LEFT", frame, "TOPLEFT", xCol2, vLast)
        local formatters = {}
        formatters[MinimalSliderWithSteppersMixin.Label.Right] = CreateMinimalSliderFormatter(MinimalSliderWithSteppersMixin.Label.Right);
        multiplierSlider:Init(1, 0.25, 2.0, 7, formatters);

        self.cbrHandles = EventUtil.CreateCallbackHandleContainer();
        self.cbrHandles:RegisterCallback(
            multiplierSlider, 
            MinimalSliderWithSteppersMixin.Event.OnValueChanged, 
            function(value)
                print(value.Slider:GetValue()) 
            end, 
            multiplierSlider
        );

        vLast = vLast - 50

        -- start OK button
        local okayButton = DaveTest_Shared_Singleton.GetButton(
            frame, 
            "Interface/Buttons/UI-DialogBox-Button-Up", 
            "Interface/Buttons/UI-DialogBox-Button-Down"
        )
        
        okayButton:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -150, 0)
        okayButton:SetWidth(100)
        okayButton:SetHeight(64)
        okayButton:SetScript("OnClick", function()
            local model = getModel()
            localOnSave(model)
        end)
    
        local okayText = okayButton:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        okayText:SetText("OK")
        okayText:SetPoint("CENTER", 0, 8)
        -- end OK button

        -- start cancel button
        local cancelButton = DaveTest_Shared_Singleton.GetButton(
            frame, 
            "Interface/Buttons/UI-DialogBox-Button-Up", 
            "Interface/Buttons/UI-DialogBox-Button-Down"
        )
        
        cancelButton:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -25, 0)
        cancelButton:SetWidth(100)
        cancelButton:SetHeight(64)
        cancelButton:SetScript("OnClick", function()
            self.Hide()
        end)
    
        local cancelText = cancelButton:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        cancelText:SetText("Cancel")
        cancelText:SetPoint("CENTER", 0, 8)
        -- end cancel button

        return frame
    end

    self.Show = function(spell, onSave)
        setSavedSpell(spell)
        localOnSave = onSave
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
