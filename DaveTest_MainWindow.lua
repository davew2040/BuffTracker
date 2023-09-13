DaveTest_MainWindow = {}

function DaveTest_MainWindow:new(parent, incomingStoredSpells)
    self = {}

    local isShowing = false
    local mainFrame = nil
    
    local loggerWindow = nil
    local savedSpellsWindow = nil
    local storedSpells = incomingStoredSpells
    
    local Initialize = function(parent)
        local frame = CreateFrame("Frame", "Tab Panel", parent, "BackdropTemplate");

        frame:SetBackdrop({
            bgFile = "Interface/DialogFrame/UI-DialogBox-Background",
            edgeFile = "Interface/DialogFrame/UI-DialogBox-Border",
            tile = true, tileSize = 32, edgeSize = 32,
            insets = { left = 11, right = 12, top = 12, bottom = 11 }
        });

        frame:EnableMouse(true)
        frame:SetMovable(true)
        frame:RegisterForDrag("LeftButton")

        frame:SetScript("OnDragStart", frame.StartMoving)
        frame:SetScript("OnDragStop", frame.StopMovingOrSizing)
        frame:SetScript("OnHide", frame.StopMovingOrSizing)
    
        local closeButton = CreateFrame("Button", "Close Button", frame, "UIPanelCloseButton")
        closeButton:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -10, -10)
        closeButton:SetScript("OnClick", function()
            self.Hide()
        end)

        local titleTexture = frame:CreateTexture();
        titleTexture:SetTexture("Interface/DialogFrame/UI-DialogBox-Header");
        titleTexture:SetWidth(280);
        titleTexture:SetHeight(64);
        titleTexture:SetPoint("TOP", frame, 0, 12);

        frame.texture = titleTexture;

        local titleText = frame:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall");
        titleText:SetText('Buff Watcher');
        titleText:SetPoint("TOP", frame, 0, -3);

        local SavedSpellsTab = CreateFrame('Button', "$parentTab1", frame, "OptionsFrameTabButtonTemplate");
        SavedSpellsTab:SetID(1);
        SavedSpellsTab:SetText('Saved Spells');
        SavedSpellsTab:SetPoint("CENTER", frame, "TOPLEFT", 100, -50);
        SavedSpellsTab:SetSize(125, 35)
        SavedSpellsTab:SetScript("OnClick", function(...)
            self.OpenSavedSpellsTab()
        end)

        local WatcherTab = CreateFrame('Button', "$parentTab2", frame, "OptionsFrameTabButtonTemplate");
        WatcherTab:SetID(2);
        WatcherTab:SetText('Event Watcher');
        WatcherTab:SetPoint("LEFT", SavedSpellsTab, "RIGHT", 0, 0);
        WatcherTab:SetSize(125, 35)
        WatcherTab:SetScript("OnClick", function(...)
            self.OpenWatcherTab()
        end)

        local tabContentFrame = CreateFrame("Frame", nil, frame)
        tabContentFrame:SetPoint("TOPLEFT", SavedSpellsTab, "BOTTOMLEFT", 0, -10)
        tabContentFrame:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -20, 20)

        loggerWindow = DaveTest_LoggerWindow:new(tabContentFrame, storedSpells)
        loggerWindow:GetFrame():SetPoint("TOPLEFT", tabContentFrame, "TOPLEFT", 0, 0)
        loggerWindow:GetFrame():SetPoint("BOTTOMRIGHT", tabContentFrame, "BOTTOMRIGHT", 0, 0)
        loggerWindow:GetFrame():SetScale(0.5)

        savedSpellsWindow = DaveTest_SavedSpellsWindow:new(tabContentFrame, storedSpells)
        savedSpellsWindow:GetFrame():SetPoint("TOPLEFT", tabContentFrame, "TOPLEFT", 0, 0)
        savedSpellsWindow:GetFrame():SetPoint("BOTTOMRIGHT", tabContentFrame, "BOTTOMRIGHT", 0, 0)
        --savedSpellsWindow:GetFrame():SetScale(0.5)

        self.OpenWatcherTab()

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
