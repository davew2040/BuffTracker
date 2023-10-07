

BuffWatcher = LibStub("AceAddon-3.0"):NewAddon("BuffWatcher", "AceConsole-3.0", "AceEvent-3.0")
local AC = LibStub("AceConfig-3.0")
local ACD = LibStub("AceConfigDialog-3.0")
local AceGUI = LibStub("AceGUI-3.0")

local mainWindow = nil

local defaults = {
	profile = {
		message = "Welcome Home!",
		showOnScreen = true,
        iconSize = 32
	},
}

local storedSpellsRegistry = BuffWatcher_StoredSpellsRegistry:new()

local settingsDialog = BuffWatcher_SettingsDialog:new(BuffWatcher_DbAccessor_Singleton)

function BuffWatcher:OnInitialize()
	-- Called when the addon is loaded
	--self:Print("Hello World!")

	--AC:RegisterOptionsTable("BuffWatcher_options", options)
	--self.optionsFrame = ACD:AddToBlizOptions("BuffWatcher_options", "BuffWatcher")

	self:RegisterChatCommand("bw", "SlashCommand")
	self:RegisterChatCommand("buffwatcher", "SlashCommand")

    -- local testFrame = AceGUI:Create("Frame", "Test Frame")
    -- testFrame:SetTitle("Test Frame")
    -- testFrame:SetLayout("List")

    -- local innerGroup = AceGUI:Create("SimpleGroup")
    -- innerGroup:SetLayout("List")
    -- testFrame:AddChild(innerGroup)

    -- local testButton = AceGUI:Create("Button", "Test Button")
    -- testButton:SetText("Test Button")
    -- testButton:SetCallback("OnClick", function(control, event) 
    --     DevTool:AddData(currentConfig.profile, "fixme currentConfig.profile")
    -- end)

    -- testFrame:AddChild(testButton)

    -- ACD:Open("BuffWatcher_options", innerGroup)
end

function BuffWatcher:OnEnable()
    BuffWatcher_DbAccessor_Singleton:OnInitialize();
    settingsDialog:Initialize(BuffWatcher)

    BuffWatcher_WeakAuraInterface_Singleton.RegisterSpells(storedSpellsRegistry)

    mainWindow = BuffWatcher_MainWindow:new(storedSpellsRegistry)

    mainWindow.GetFrame():Hide()

    self:RegisterEvent("NAME_PLATE_UNIT_ADDED")
end

function BuffWatcher:OnDisable()
	-- Called when the addon is disabled
end

function BuffWatcher:NAME_PLATE_UNIT_ADDED(...)
    local plateName = select(1, ...)
    local nameplate = C_NamePlate.GetNamePlateForUnit(plateName)
    if (not nameplate) then
        return
    end
    local frame = nameplate.UnitFrame
    if (not frame) then
        return
    end
    if not nameplate or frame:IsForbidden() then return end
    frame.BuffFrame:ClearAllPoints()
    frame.BuffFrame:SetAlpha(0)
end

function BuffWatcher:SlashCommand()
    mainWindow:GetFrame().frame:Show()
end