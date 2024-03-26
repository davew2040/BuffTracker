local AceGUI = LibStub("AceGUI-3.0")

---@class BuffWatcher_MainWindow
BuffWatcher_MainWindow = {}

---@param incomingStoredSpells BuffWatcher_StoredSpellsRegistry
---@param loggerModule BuffWatcher_LoggerModule
---@param weakAuraExporter BuffWatcher_WeakAuraExporter
---@param contextStore BuffWatcher_AuraContextStore
function BuffWatcher_MainWindow:new(incomingStoredSpells, loggerModule, weakAuraExporter, contextStore)
    self = {}

    local isShowing = false
    local mainFrame = nil
    local tabHolder = nil
    
    local loggerWindow = nil
    local savedSpellsWindow = nil
    ---@type BuffWatcher_AddEditSavedCast
    local addEditCastWindow = nil
    local storedSpells = incomingStoredSpells
    local frames = {}
    
    local loggerFrameKey = "loggerFrameKey"
    local spellsFrameKey = "spellsFrameKey"

    local TabKeys = {
        Spells = "SPELLS",
        Logger = "LOGGER"
    }

    local showFrame = function(frameKey)
        for k,v in pairs(frames) do
            if (k == frameKey) then
                frames[k].frame:Show()
            else
                frames[k].frame:Hide()
            end
        end
    end

    local selectTab = function(tabKey)
        if (tabKey == TabKeys.Logger) then
            showFrame(loggerFrameKey)
            loggerWindow.UpdateWindow()
        else
            showFrame(spellsFrameKey)
            savedSpellsWindow.UpdateWindow()
        end
    end

    local initializeFrames = function(addEditCastWindow, tabControl)
        local loggerWindowFrame = AceGUI:Create("SimpleGroup", "Logger Window Frame")
        loggerWindowFrame:SetPoint("TOPLEFT", tabControl.frame, "TOPLEFT", 15, -45)
        loggerWindowFrame:SetPoint("BOTTOMRIGHT", tabControl.frame, "BOTTOMRIGHT", 0, 0)
        loggerWindowFrame:SetFullHeight(true)
   
        loggerWindow = BuffWatcher_LoggerWindow:new(storedSpells, loggerModule)

        loggerWindowFrame:AddChild(loggerWindow.GetFrame())

        frames[loggerFrameKey] = loggerWindowFrame

        local savedSpellsFrame = AceGUI:Create("SimpleGroup", "Saved Spells Frame")
        savedSpellsFrame:SetPoint("TOPLEFT", tabControl.frame, "TOPLEFT", 15, -45)
        savedSpellsFrame:SetPoint("BOTTOMRIGHT", tabControl.frame, "BOTTOMRIGHT", 0, 0)
        savedSpellsFrame:SetFullHeight(true)

        savedSpellsWindow = BuffWatcher_SavedSpellsWindow:new(storedSpells, addEditCastWindow, weakAuraExporter, contextStore)

        savedSpellsFrame:AddChild(savedSpellsWindow.GetFrame())

        frames[spellsFrameKey] = savedSpellsFrame

        tabHolder:AddChild(savedSpellsFrame)
        tabHolder:AddChild(loggerWindowFrame)
    end

    local Initialize = function(addEditCastWindow)
        local frame = AceGUI:Create("Frame")

        frame:SetTitle("Buff Watcher")
        frame:SetCallback("OnClose", frame.frame:Hide())
        frame:SetLayout("Fill")
        frame:SetWidth(1200)
        frame:SetHeight(750)

        addEditCastWindow = BuffWatcher_AddEditSavedCast:new()
        addEditCastWindow:Hide()

        -- Callback function for OnGroupSelected
        local function SelectGroup(container, event, group)
            selectTab(group)
        end

        tabHolder =  AceGUI:Create("TabGroup")

        tabHolder:SetFullWidth(true)
        tabHolder:SetFullHeight(true)
        tabHolder:SetLayout("Manual")
        tabHolder:SetTabs({
            {text="Saved Spells", value=TabKeys.Spells}, 
            {text="Logger", value=TabKeys.Logger}
        })
        tabHolder:SetCallback("OnGroupSelected", SelectGroup)
        
        frame:AddChild(tabHolder)

        initializeFrames(addEditCastWindow, tabHolder)

        tabHolder:SelectTab(TabKeys.Logger)
        selectTab(TabKeys.Logger)

        return frame
    end

    self.GetFrame = function()
        return mainFrame
    end

    self.Show = function()
        loggerWindow.UpdateWindow()
        mainFrame.frame:Show()
    end

    mainFrame = Initialize()

    return self
end
