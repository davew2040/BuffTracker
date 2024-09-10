local AceGUI = LibStub("AceGUI-3.0")

---@class BuffWatcher_LoggerWindow_SpellRow
BuffWatcher_LoggerWindow_SpellRow = {}

---@param spellRegistry BuffWatcher_StoredSpellsRegistry
function BuffWatcher_LoggerWindow_SpellRow:new(spellRegistry)
    self = {}

    local currentSpell = nil
    local AddEventName = "SPELL_ADD"
    local ButtonHeight = 30

    ---@type table<string, BuffWatcher_StoredSpell>
    local storedSpells = {}

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

    ---@param castRecord BuffWatcher_CastRecord
    self.setSpell = function(castRecord)
        storedSpells = spellRegistry.GetSpells()
        currentSpell = castRecord

        local spellInfo = BuffWatcher_Blizzard_Wrapper.GetSpellInfo(castRecord.spellId)

        local texture = C_Spell.GetSpellTexture(castRecord.spellId)

        spellIdText:SetText(castRecord.spellId)
        spellTypeText:SetText(BuffWatcher_Shared_Singleton.SpellTypeLabels[castRecord.type])
        spellNameText:SetText(spellInfo.name)
        sourceNameText:SetText(castRecord.sourceName)
        textureFrame:SetImage(texture)

        local castKey = BuffWatcher_CastRecord.GetKey(castRecord)
        local spellIsStored = storedSpells[castKey] ~= nil

        addButton:SetDisabled(spellIsStored)
        addButton:SetText(spellIsStored and 'Added' or 'Add')
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