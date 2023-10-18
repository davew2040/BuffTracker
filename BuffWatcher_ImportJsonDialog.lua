local AceGUI = LibStub("AceGUI-3.0")

---@class BuffWatcher_ImportJsonDialog
BuffWatcher_ImportJsonDialog = {}

---@param spellRegistry BuffWatcher_StoredSpellsRegistry
function BuffWatcher_ImportJsonDialog:new(spellRegistry)
    self = {}

    local mainFrame = nil

    local importSpells = function(text)
        local parsed = BuffWatcher_json.parse(text)
        if (#parsed == 0) then
            error("Parsed data has no entries.")
        end
        ---@cast parsed any[]
        DevTool:AddData(parsed, "fixme parsed")

        spellRegistry.importSpells(parsed)
    end

    local Initialize = function()
        local mainFrame = AceGUI:Create("Frame")
        mainFrame:SetLayout("List")
        mainFrame:SetTitle("Import Configuration")
        mainFrame.frame:SetResizable(false)

        local textBox = AceGUI:Create("MultiLineEditBox")
        textBox:SetNumLines(27)
        textBox:SetFullWidth(true)
        textBox:SetLabel("Import")
        textBox:SetCallback("OnEnterPressed", function(frame, event, text)
            importSpells(text)
        end)
        -- textBox:SetPoint("TOPLEFT", mainFrame.frame, "TOPLEFT", 15, -30)
        -- textBox:SetPoint("BOTTOMRIGHT", mainFrame.frame, "BOTTOMRIGHT", -20, 40)

        mainFrame:AddChild(textBox)
    end

    self.GetFrame = function()
        return mainFrame
    end

    mainFrame = Initialize()

    return self
end
