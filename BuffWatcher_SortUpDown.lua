local AceGUI = LibStub("AceGUI-3.0")

---@class BuffWatcher_SortUpDown
BuffWatcher_SortUpDown = {}

BuffWatcher_SortUpDown.IconSize = 12

function BuffWatcher_SortUpDown:new()
    self = {}

    local CallbackLabels = {
        Up = "Up",
        Down = "Down"
    }

    local BufferWidth = 3

    local callbacks = BuffWatcher_Callbacks:new()

    local mainFrame = nil

    local Initialize = function(addEditCastWindow)
        local frame = AceGUI:Create("SimpleGroup")
        frame:SetLayout("Manual")

        frame:SetWidth(BuffWatcher_SortUpDown.IconSize)
        frame:SetHeight(BuffWatcher_SortUpDown.IconSize*2 + BufferWidth)

        local upArrow = AceGUI:Create("Icon")
        upArrow:SetWidth(BuffWatcher_SortUpDown.IconSize)
        upArrow:SetHeight(BuffWatcher_SortUpDown.IconSize)
        upArrow:SetPoint("TOPLEFT", frame.frame, "TOPLEFT", 0, 0)
        upArrow:SetImage("Interface\\ICONS\\Misc_arrowlup")
        upArrow.image:SetTexCoord(0, 1, 0, 1)
        upArrow.image:SetPoint("TOPLEFT")
        upArrow.image:SetWidth(BuffWatcher_SortUpDown.IconSize)
        upArrow.image:SetHeight(BuffWatcher_SortUpDown.IconSize)
        upArrow:SetCallback("OnClick", function(control, event) 
            callbacks.fire(CallbackLabels.Up)
        end)

        frame:AddChild(upArrow)
    
        local downArrow = AceGUI:Create("Icon")
        downArrow:SetWidth(BuffWatcher_SortUpDown.IconSize)
        downArrow:SetHeight(BuffWatcher_SortUpDown.IconSize)
        downArrow:SetPoint("TOPLEFT", upArrow.frame, "BOTTOMLEFT", 0, -BufferWidth)
        downArrow:SetImage("Interface\\ICONS\\Misc_arrowdown")
        downArrow.image:SetPoint("TOPLEFT")
        downArrow.image:SetWidth(BuffWatcher_SortUpDown.IconSize)
        downArrow.image:SetHeight(BuffWatcher_SortUpDown.IconSize)
        downArrow:SetCallback("OnClick", function(control, event) 
            callbacks.fire(CallbackLabels.Down)
        end)

        frame:AddChild(downArrow)

        return frame
    end

    ---@return any
    self.GetFrame = function()
        return mainFrame
    end

    ---@param fn fun()
    self.RegisterSortUp = function(fn)
        callbacks.registerCallback(CallbackLabels.Up, fn)
    end


    ---@param fn fun()
    self.RegisterSortDown = function(fn)
        callbacks.registerCallback(CallbackLabels.Down, fn)
    end

    ---@param fn fun()
    self.UnregisterSortUp = function(fn)
        callbacks.unregisterCallback(CallbackLabels.Up, fn)
    end

    ---@param fn fun()
    self.UnregisterSortDown = function(fn)
        callbacks.unregisterCallback(CallbackLabels.Down, fn)
    end

    mainFrame = Initialize()

    return self
end
