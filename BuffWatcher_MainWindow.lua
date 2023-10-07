local AceGUI = LibStub("AceGUI-3.0")

BuffWatcher_MainWindow = {}

function BuffWatcher_MainWindow:new(incomingStoredSpells)
    self = {}

    local isShowing = false
    local mainFrame = nil
    local tab = nil
    
    local loggerWindow = nil
    local savedSpellsWindow = nil
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
        tab:SelectTab("tabLogger")

        if (tabKey == TabKeys.Logger) then
            showFrame(loggerFrameKey)
            loggerWindow.UpdateWindow()
        else
            --showFrame("SDFSLF")
        end
    end

    local initializeFrames = function(addEditCastWindow, tabControl)
        local loggerWindowFrame = AceGUI:Create("SimpleGroup", "Logger Window Frame")
        loggerWindowFrame:SetFullWidth(true)
        loggerWindowFrame:SetFullHeight(true)
   
        loggerWindow = BuffWatcher_LoggerWindow:new(storedSpells)

        loggerWindowFrame:AddChild(loggerWindow.GetFrame())

        frames[loggerFrameKey] = loggerWindowFrame

        -- local savedSpellsFrame = AceGUI:Create("SimpleGroup", "Saved Spells Frame")
        -- savedSpellsFrame:SetFullWidth(true)
        -- savedSpellsFrame:SetFullHeight(true)
   
        -- savedSpellsWindow = BuffWatcher_SavedSpellsWindow:new(storedSpells, addEditCastWindow)

        --savedSpellsFrame:AddChild(savedSpellsWindow.GetFrame())

        --frames[spellsFrameKey] = savedSpellsFrame

        tab:AddChild(loggerWindowFrame)
    end

    local Initialize = function(addEditCastWindow)
        local frame = AceGUI:Create("Frame")

        frame:SetTitle("Buff Watcher")
        frame:SetStatusText("AceGUI-3.0 Example Container Frame")
        frame:SetCallback("OnClose", frame.frame:Hide())
        frame:SetLayout("Fill")
        frame:SetWidth(1200)
        frame:SetHeight(750)

        -- local SavedSpellsTab = CreateFrame('Button', "$parentTab1", frame, "OptionsFrameTabButtonTemplate");
        -- SavedSpellsTab:SetID(1);
        -- SavedSpellsTab:SetText('Saved Spells');
        -- SavedSpellsTab:SetPoint("CENTER", frame, "TOPLEFT", 100, -50);
        -- SavedSpellsTab:SetSize(125, 35)
        -- SavedSpellsTab:SetScript("OnClick", function(...)
        --     self.OpenSavedSpellsTab()
        -- end)

        -- local WatcherTab = CreateFrame('Button', "$parentTab2", frame, "OptionsFrameTabButtonTemplate");
        -- WatcherTab:SetID(2);
        -- WatcherTab:SetText('Event Watcher');
        -- WatcherTab:SetPoint("LEFT", SavedSpellsTab, "RIGHT", 0, 0);
        -- WatcherTab:SetSize(125, 35)
        -- WatcherTab:SetScript("OnClick", function(...)
        --     self.OpenWatcherTab()
        -- end)

        -- local tabContentFrame = CreateFrame("Frame", nil, frame)
        -- tabContentFrame:SetPoint("TOPLEFT", SavedSpellsTab, "BOTTOMLEFT", 0, -10)
        -- tabContentFrame:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -20, 20)

        addEditCastWindow = BuffWatcher_AddEditSavedCast:new(UIParent)

        -- addEditCastWindow:GetFrame():SetSize(800, 800)
        -- addEditCastWindow:GetFrame():SetPoint("CENTER")
        -- addEditCastWindow:GetFrame():SetScale(0.5)
        -- addEditCastWindow:GetFrame():EnableMouse(true)
        -- addEditCastWindow:GetFrame():SetMovable(true)

        -- addEditCastWindow:GetFrame():SetScript("OnDragStart", addEditCastWindow.StartMoving)
        -- addEditCastWindow:GetFrame():SetScript("OnDragStop", addEditCastWindow.StopMovingOrSizing)
        -- addEditCastWindow:GetFrame():SetScript("OnHide", addEditCastWindow.StopMovingOrSizing)

        -- addEditCastWindow.Hide()

        -- local loggerWindowFrame = AceGUI:Create("SimpleGroup", "Logger Window Frame")
        -- --loggerWindowFrame:SetTitle("loggerWindowFrame")
        -- loggerWindowFrame:SetFullWidth(true)
        -- loggerWindowFrame:SetFullHeight(true)
   
        -- loggerWindow = BuffWatcher_LoggerWindow:new(storedSpells)

        -- loggerWindowFrame:AddChild(loggerWindow.GetFrame())

        -- frames[loggerWindowFrame] = loggerWindowFrame

        -- local loggerWindowFrame = AceGUI:Create("SimpleGroup", "Logger Window Frame")
        -- --loggerWindowFrame:SetTitle("loggerWindowFrame")
        -- loggerWindowFrame:SetFullWidth(true)
        -- loggerWindowFrame:SetFullHeight(true)
   
        -- loggerWindow = BuffWatcher_LoggerWindow:new(storedSpells)

        -- loggerWindowFrame:AddChild(loggerWindow.GetFrame())

        -- frames[loggerWindowFrame] = loggerWindowFrame

        -- savedSpellsWindow = BuffWatcher_SavedSpellsWindow:new(tabContentFrame, storedSpells, addEditCastWindow)
        -- savedSpellsWindow:GetFrame():SetPoint("TOPLEFT", tabContentFrame, "TOPLEFT", 0, 0)
        -- savedSpellsWindow:GetFrame():SetPoint("BOTTOMRIGHT", tabContentFrame, "BOTTOMRIGHT", 0, 0)

        -- Callback function for OnGroupSelected
        local function SelectGroup(container, event, group)
            selectTab(group)
        end

        tab =  AceGUI:Create("TabGroup")

        tab:SetFullWidth(true)
        tab:SetFullHeight(true)
        tab:SetLayout("List")
        tab:SetTabs({
            {text="Saved Spells", value=TabKeys.Spells}, 
            {text="Logger", value=TabKeys.Logger}
        })
        tab:SetCallback("OnGroupSelected", SelectGroup)
        
        frame:AddChild(tab)
        
        initializeFrames(addEditCastWindow, tab)

        selectTab(TabKeys.Logger)

        --self.OpenWatcherTab()

        return frame
    end

    self.OpenWatcherTab = function()
        loggerWindowFrame.frame:Show()
        --savedSpellsWindow:Hide()
    end

    self.OpenSavedSpellsTab = function()
        --savedSpellsWindow:Show()
        loggerWindowFrame.frame:Hide()
    end

    self.GetFrame = function()
        return mainFrame
    end

    mainFrame = Initialize()

    return self
end
