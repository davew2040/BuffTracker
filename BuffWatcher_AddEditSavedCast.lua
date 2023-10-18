local AceGUI = LibStub("AceGUI-3.0")

---@class BuffWatcher_AddEditSavedCast
BuffWatcher_AddEditSavedCast = {}

function BuffWatcher_AddEditSavedCast:new()
    self = {}

    local mainFrame = nil

    local labelSpellname = nil
    local txtSpellName = nil
    local chkHide = nil
    local chkParty = nil
    local chkArenas = nil
    local chkEnemyNameplates = nil
    local chkGlow = nil
    local chkRaids = nil
    local chkOwnOnly = nil
    local multiplierSlider = nil
    ---@type BuffWatcher_StoredSpell
    local activeModel = nil

    ---@type fun(model: BuffWatcher_StoredSpell)
    local localOnSave = function(model) end

    ---@param spell BuffWatcher_StoredSpell
    local setSavedSpell = function(spell)
        activeModel = CopyTable(spell)

        local spellName = GetSpellInfo(spell.spellId)

        mainFrame:SetTitle("Add/Edit Spell - " .. spellName)
        
        DevTool:AddData(CopyTable(spell), "fixme add edit spell open")

        chkHide:SetValue(spell.hide)
        chkParty:SetValue(spell.showInParty)
        chkArenas:SetValue(spell.showInArena)
        chkRaids:SetValue(spell.showInRaid)
        chkOwnOnly:SetValue(spell.ownOnly)
        chkEnemyNameplates:SetValue(spell.showOnNameplates)
        -- chkGlow:SetChecked(spell.showGlow)

        -- multiplierSlider:SetValue(spell.sizeMultiplier)
    end

    local initializeActionsBar = function(parent)
        local actionsBarFrame = AceGUI:Create("SimpleGroup")
        actionsBarFrame:SetLayout("Manual")
        actionsBarFrame:SetFullWidth(true)

        local cancelButton = AceGUI:Create("Button")
        cancelButton:SetText("Cancel")
        cancelButton:SetWidth(125)
        cancelButton:SetPoint("BOTTOMRIGHT", parent.frame, "BOTTOMRIGHT", -20, 20)
        cancelButton:SetCallback("OnClick", function(control, event)
            mainFrame:Hide()
        end)
        actionsBarFrame:AddChild(cancelButton)

        local saveButton = AceGUI:Create("Button")
        saveButton:SetText("Save")
        saveButton:SetWidth(125)
        saveButton:SetPoint("BOTTOMRIGHT", cancelButton.frame, "BOTTOMLEFT", -10, 0)
        saveButton:SetCallback("OnClick", function(control, event)
            localOnSave(activeModel)
        end)
        actionsBarFrame:AddChild(saveButton)

        return actionsBarFrame
    end

    local Initialize = function(parent)
        local frame = AceGUI:Create("Window")
        frame:SetTitle("Add/Edit Stored Spell")
        frame:SetLayout("List")

        DevTool:AddData(frame, "fixme addedit cast window frame")

        chkHide = AceGUI:Create("CheckBox")
        chkHide:SetLabel("Hide")
        chkHide:SetCallback("OnValueChanged", function(control, event, newValue)
            activeModel.hide = newValue
        end)
        frame:AddChild(chkHide)

        chkEnemyNameplates = AceGUI:Create("CheckBox")
        chkEnemyNameplates:SetLabel("Show on Nameplates")
        chkEnemyNameplates:SetCallback("OnValueChanged", function(control, event, newValue)
            activeModel.showOnNameplates = newValue
        end)
        frame:AddChild(chkEnemyNameplates)

        chkParty = AceGUI:Create("CheckBox")
        chkParty:SetLabel("Show on Party Frames")
        chkParty:SetCallback("OnValueChanged", function(control, event, newValue)
            activeModel.showInParty = newValue
        end)
        frame:AddChild(chkParty)

        chkArenas = AceGUI:Create("CheckBox")
        chkArenas:SetLabel("Show on Arena Frames")
        chkArenas:SetCallback("OnValueChanged", function(control, event, newValue)
            activeModel.showInArena = newValue
        end)
        frame:AddChild(chkArenas)

        chkRaids = AceGUI:Create("CheckBox")
        chkRaids:SetLabel("Show on Raid Frames")
        chkRaids:SetCallback("OnValueChanged", function(control, event, newValue)
            activeModel.showInRaid = newValue
        end)
        frame:AddChild(chkRaids)

        chkOwnOnly = AceGUI:Create("CheckBox")
        chkOwnOnly:SetLabel("Show Own Only")
        chkOwnOnly:SetCallback("OnValueChanged", function(control, event, newValue)
            activeModel.ownOnly = newValue
        end)
        frame:AddChild(chkOwnOnly)

        frame:AddChild(initializeActionsBar(frame))

        return frame
    end

    ---@param spell BuffWatcher_StoredSpell
    ---@param onSave fun(model: BuffWatcher_StoredSpell)
    self.Show = function(spell, onSave)
        setSavedSpell(spell)
        localOnSave = onSave
        mainFrame:Show()
    end

    self.Hide = function()
        mainFrame:Hide()
    end

    self.GetFrame = function()
        return mainFrame
    end

    mainFrame = Initialize()

    return self
end
