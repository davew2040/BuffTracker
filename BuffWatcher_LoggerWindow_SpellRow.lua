local AceGUI = LibStub("AceGUI-3.0")

BuffWatcher_LoggerWindow_SpellRow = {}

function BuffWatcher_LoggerWindow_SpellRow:new()
    self = {}

    local currentSpell = nil
    local AddEventName = "SPELL_ADD"
    local ButtonHeight = 30

    local events = BuffWatcher_Callbacks:new()

    local spellRowFrame = AceGUI:Create("SimpleGroup", "Spell Row Frame")
    spellRowFrame:SetLayout("Flow") -- Set the layout to "Flow" for a simple container
    spellRowFrame:SetFullWidth(true)
    spellRowFrame:SetHeight(25)

    local addButton = AceGUI:Create("Button")

    addButton:SetText("Add")
    addButton:SetWidth(75)
    addButton:SetHeight(ButtonHeight)
    addButton:SetCallback("OnClick", function()
        events.fire(AddEventName, currentSpell)
    end)

    spellRowFrame:AddChild(addButton)

    local textureFrame = AceGUI:Create("Icon")
    textureFrame:SetImageSize(32, 32)
    spellRowFrame:AddChild(textureFrame)

    local spellTypeText = AceGUI:Create("Label")
    spellRowFrame:AddChild(spellTypeText)

    local spellIdText = AceGUI:Create("Label")
    spellRowFrame:AddChild(spellIdText)

    local spellNameText = AceGUI:Create("Label")
    spellRowFrame:AddChild(spellNameText)

    local sourceNameText = AceGUI:Create("Label")
    spellRowFrame:AddChild(sourceNameText)

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
        textureFrame:SetImage(texture)
    end

    self.clearSpell = function()
        currentSpell = nil

        spellIdText:SetText('(none)')
        spellNameText:SetText('(none)')
        sourceNameText:SetText('(none)')
        textureFrame:SetImage(nil)
    end

    self.getSpell = function()
        return currentSpell;
    end

    self.registerAdd = function(fn)
        events.registerCallback(AddEventName, fn)
    end

    return self
end