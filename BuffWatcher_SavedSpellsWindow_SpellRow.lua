local AceGUI = LibStub("AceGUI-3.0")

---@class BuffWatcher_SavedSpellsWindow_SpellRow
BuffWatcher_SavedSpellsWindow_SpellRow = {}

function BuffWatcher_SavedSpellsWindow_SpellRow:new(parent)
    self = {}

    local ButtonHeight = 30

    local currentSpell = nil
    local RemoveEventName = "SPELL_REMOVE"
    local EditEventName = "SPELL_EDIT"
    local indexedRecords = {}

    local events = BuffWatcher_Callbacks:new()

    local savedSpellRowFrame = AceGUI:Create("SimpleGroup")
    savedSpellRowFrame:SetLayout("Flow")
    savedSpellRowFrame:SetFullWidth(true)
    savedSpellRowFrame:SetFullHeight(false)

    local removeButton = AceGUI:Create("Button")
    removeButton:SetText("Remove")
    removeButton:SetWidth(BuffWatcher_SavedSpellsWindow.ColumnWidths.REMOVE)
    removeButton:SetHeight(ButtonHeight)
    removeButton:SetCallback("OnClick", function()
        events.fire(RemoveEventName, currentSpell)
    end)
    savedSpellRowFrame:AddChild(removeButton)

    local editButton = AceGUI:Create("Button")
    editButton:SetText("Edit")
    editButton:SetWidth(BuffWatcher_SavedSpellsWindow.ColumnWidths.EDIT)
    editButton:SetHeight(ButtonHeight)
    editButton:SetCallback("OnClick", function()
        events.fire(EditEventName, currentSpell)
    end)
    savedSpellRowFrame:AddChild(editButton)

    local textureFrame = AceGUI:Create("Icon")
    textureFrame:SetImageSize(32, 32)
    textureFrame:SetWidth(BuffWatcher_SavedSpellsWindow.ColumnWidths.ICON)
    savedSpellRowFrame:AddChild(textureFrame)

    local spellTypeText = AceGUI:Create("Label")
    spellTypeText:SetWidth(BuffWatcher_SavedSpellsWindow.ColumnWidths.SPELL_TYPE)
    savedSpellRowFrame:AddChild(spellTypeText)

    local spellIdText = AceGUI:Create("Label")
    spellIdText:SetWidth(BuffWatcher_SavedSpellsWindow.ColumnWidths.SPELL_ID)
    savedSpellRowFrame:AddChild(spellIdText)

    local spellNameText = AceGUI:Create("Label")
    spellNameText:SetWidth(BuffWatcher_SavedSpellsWindow.ColumnWidths.SPELL_NAME)
    savedSpellRowFrame:AddChild(spellNameText)

    local chkParty = AceGUI:Create("CheckBox")
    chkParty:SetWidth(BuffWatcher_SavedSpellsWindow.ColumnWidths.CHECK_BOX)
    chkParty:SetDisabled(true)
    savedSpellRowFrame:AddChild(chkParty)

    local chkArena = AceGUI:Create("CheckBox")
    chkArena:SetDisabled(true)
    chkArena:SetWidth(BuffWatcher_SavedSpellsWindow.ColumnWidths.CHECK_BOX)
    savedSpellRowFrame:AddChild(chkArena)

    local chkNameplates = AceGUI:Create("CheckBox")
    chkNameplates:SetDisabled(true)
    chkNameplates:SetWidth(BuffWatcher_SavedSpellsWindow.ColumnWidths.CHECK_BOX)
    savedSpellRowFrame:AddChild(chkNameplates)

    local chkRaids = AceGUI:Create("CheckBox")
    chkRaids:SetDisabled(true)
    chkRaids:SetWidth(BuffWatcher_SavedSpellsWindow.ColumnWidths.CHECK_BOX)
    savedSpellRowFrame:AddChild(chkRaids)

    self.GetFrame = function()
        return savedSpellRowFrame
    end

    self.SetSpell = function(spell)
        currentSpell = spell

        local spellName, _ = GetSpellInfo(spell.spellId)
        local texture = GetSpellTexture(spell.spellId)

        spellIdText:SetText(spell.spellId)
        spellTypeText:SetText(BuffWatcher_Shared_Singleton.SpellTypeLabels[spell.buffType])
        spellNameText:SetText(spellName)
        textureFrame:SetImage(texture)
        chkParty:SetValue(spell.showInParty)
        chkArena:SetValue(spell.showInArena)
        chkNameplates:SetValue(spell.showOnNameplates)
        chkRaids:SetValue(spell.showInRaid)
    end

    self.ClearSpell = function()
        currentSpell = nil

        spellIdText:SetText('(none)')
        spellTypeText:SetText('(none)')
        spellNameText:SetText('(none)')
        textureFrame:SetImage(nil)
    end

    self.GetSpell = function()
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