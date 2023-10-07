local AceGUI = LibStub("AceGUI-3.0")
local AceConfig = LibStub("AceConfig-3.0")
local AceConfigDialog = LibStub("AceConfigDialog-3.0")

BuffWatcher_SettingsDialog = {}

function BuffWatcher_SettingsDialog:new(dbAccessor)
    self = {}

    local currentConfig = {}

    local options = {
        name = "BuffWatcher",
        handler = BuffWatcher,
        type = "group",
        args = {
            msg = {
                type = "input",
                name = "Message",
                desc = "The message to be displayed when you get home.",
                usage = "<Your message>",
                get = "GetMessage",
                set = "SetMessage",
            },
            showOnScreen = {
                type = "toggle",
                name = "Show on Screen",
                desc = "Toggles the display of the message on the screen.",
                get = "IsShowOnScreen",
                set = "ToggleShowOnScreen"
            },
            iconSize = {
                name = "Icon Size",
                desc = "The default size of icons.",
                type = "range",
                min = 16,
                max = 128,
                step = 1,
                get = "GetIconSize",
                set = "SetIconSize",
            }
        },
    }

    local initializeHandlers = function(addonRoot) 
        function addonRoot:GetMessage(info)
            return currentConfig.message
        end

        function addonRoot:SetMessage(info, value)
            DevTool:AddData(CopyTable(info), "fixme info SetMessage")
            currentConfig.message = value
        end

        function addonRoot:IsShowOnScreen(info)
            return currentConfig.showOnScreen
        end

        function addonRoot:ToggleShowOnScreen(info, value)
            DevTool:AddData(CopyTable(info), "fixme info ToggleShowOnScreen")
            currentConfig.showOnScreen = value
        end

        function addonRoot:GetIconSize(info)
            return currentConfig.iconSize
        end

        function addonRoot:SetIconSize(info, value)
            DevTool:AddData(CopyTable(info), "fixme info SetIconSize")
            currentConfig.iconSize = value
        end
    end

    self.Initialize = function(test, addonRoot)
        currentConfig = dbAccessor.GetOptions()

        initializeHandlers(addonRoot)

        AceConfig:RegisterOptionsTable("BuffWatcher_options", options)
        local optionsFrame = AceConfigDialog:AddToBlizOptions("BuffWatcher_options", "BuffWatcher")
    end

    return self
end
