local AceGUI = LibStub("AceGUI-3.0")

BuffWatcher_MainWindow = {}

function BuffWatcher_MainWindow:new(parent, incomingStoredSpells)
    self = {}

    local isShowing = false
    local mainFrame = nil
    
    local loggerWindow = nil
    local savedSpellsWindow = nil
    local addEditCastWindow = nil
    local storedSpells = incomingStoredSpells
    
    local Initialize = function(parent)
        local frame = AceGUI:Create("Frame")

        frame:SetTitle("Buff Watcher")
        frame:SetStatusText("AceGUI-3.0 Example Container Frame")
        frame:SetCallback("OnClose", function(widget) AceGUI:Release(widget) end)
        frame:SetLayout("Fill")
        frame:SetWidth(1000)
        frame:SetHeight(500)

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

        local loggerWindowFrame = AceGUI:Create("SimpleGroup", "Logger Window Frame")
        --loggerWindowFrame:SetTitle("loggerWindowFrame")
        loggerWindowFrame:SetFullWidth(true)
        loggerWindowFrame:SetFullHeight(true)
   
        loggerWindow = BuffWatcher_LoggerWindow:new(storedSpells)

        loggerWindowFrame:AddChild(loggerWindow.GetFrame())
        
        -- savedSpellsWindow = BuffWatcher_SavedSpellsWindow:new(tabContentFrame, storedSpells, addEditCastWindow)
        -- savedSpellsWindow:GetFrame():SetPoint("TOPLEFT", tabContentFrame, "TOPLEFT", 0, 0)
        -- savedSpellsWindow:GetFrame():SetPoint("BOTTOMRIGHT", tabContentFrame, "BOTTOMRIGHT", 0, 0)

        -- function that draws the widgets for the first tab
        local function DrawGroup1(container)
            -- local desc = AceGUI:Create("Label")
            -- desc:SetText("This is Tab 1")
            -- desc:SetFullWidth(true)
            -- container:AddChild(desc)
            
            -- local button = AceGUI:Create("Button")
            -- button:SetText("Tab 1 Button")
            -- button:SetWidth(200)
            -- container:AddChild(button)
        end
        
        -- function that draws the widgets for the second tab
        local function DrawGroup2(container)
            -- local desc = AceGUI:Create("Label")
            -- desc:SetText("This is Tab 2")
            -- desc:SetFullWidth(true)
            -- container:AddChild(desc)
            
            -- local button = AceGUI:Create("Button")
            -- button:SetText("Tab 2 Button")
            -- button:SetWidth(200)
            -- container:AddChild(button)
        end

        -- Callback function for OnGroupSelected
        local function SelectGroup(container, event, group)
            --container:ReleaseChildren()
            if group == "tab1" then
                loggerWindowFrame.frame:Show()
                DrawGroup1(container)
            elseif group == "tab2" then
                loggerWindowFrame.frame:Hide()
                DrawGroup2(container)
            end
        end

        -- Create the TabGroup
        -- local tab =  AceGUI:Create("TabGroup")
        -- tab:SetFullWidth(true)
        -- tab:SetFullHeight(true)

        -- tab:SetLayout("List")
        -- -- Setup which tabs to show
        -- tab:SetTabs({{text="Tab 1", value="tab1"}, {text="Tab 2", value="tab2"}})
        -- -- Register callback
        -- tab:SetCallback("OnGroupSelected", SelectGroup)
        -- -- Set initial Tab (this will fire the OnGroupSelected callback)
        -- tab:SelectTab("tab1")
        
        -- add to the frame container
        --frame:AddChild(tab)

        frame:AddChild(loggerWindowFrame)

        addEditCastWindow = BuffWatcher_AddEditSavedCast:new(UIParent)
        addEditCastWindow:GetFrame():SetSize(800, 800)
        addEditCastWindow:GetFrame():SetPoint("CENTER")
        addEditCastWindow:GetFrame():SetScale(0.5)
        addEditCastWindow:GetFrame():EnableMouse(true)
        addEditCastWindow:GetFrame():SetMovable(true)

        addEditCastWindow:GetFrame():SetScript("OnDragStart", addEditCastWindow.StartMoving)
        addEditCastWindow:GetFrame():SetScript("OnDragStop", addEditCastWindow.StopMovingOrSizing)
        addEditCastWindow:GetFrame():SetScript("OnHide", addEditCastWindow.StopMovingOrSizing)

        addEditCastWindow.Hide()

        --self.OpenWatcherTab()

        return frame
    end
    
    self.Show = function()
        mainFrame:Show()
        loggerWindow:Show()
        isShowing = true
    end

    self.Hide = function()
        mainFrame:Hide()
        loggerWindow:Hide()
        savedSpellsWindow:Hide()
        isShowing = false
    end

    self.OpenWatcherTab = function()
        loggerWindow:Show()
        savedSpellsWindow:Hide()
    end

    self.OpenSavedSpellsTab = function()
        savedSpellsWindow:Show()
        loggerWindow:Hide()
    end

    self.GetFrame = function()
        return mainFrame
    end

    mainFrame = Initialize()

    return self
end
