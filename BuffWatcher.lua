

BuffWatcher = LibStub("AceAddon-3.0"):NewAddon("BuffWatcher", "AceConsole-3.0", "AceEvent-3.0")
local AC = LibStub("AceConfig-3.0")
local ACD = LibStub("AceConfigDialog-3.0")
local AceGUI = LibStub("AceGUI-3.0")
local LibSerialize = LibStub("LibSerialize")

local mainWindow = nil

local defaults = {
	profile = {
		message = "Welcome Home!",
		showOnScreen = true,
        iconSize = 32
	},
}

function BuffWatcher:OnInitialize()
	self:Print("Loading BuffWatcher addon...")

	self:RegisterChatCommand("bw", "SlashCommand")
	self:RegisterChatCommand("buffwatcher", "SlashCommand")
end

function BuffWatcher:OnEnable()
    local contextDefaults = BuffWatcher_DefaultContextValues:new()

    BuffWatcher_DbAccessor_Singleton.OnInitialize(contextDefaults);

    local loggerModule = BuffWatcher_LoggerModule:new()
    local storedSpellsRegistry = BuffWatcher_StoredSpellsRegistry:new()
    local configuration = BuffWatcher_Configuration:new(BuffWatcher_DbAccessor_Singleton)
    local contextStore = BuffWatcher_AuraContextStore:new(BuffWatcher_DbAccessor_Singleton, configuration, storedSpellsRegistry, contextDefaults)
    local settingsDialog = BuffWatcher_SettingsDialog:new(BuffWatcher_DbAccessor_Singleton, contextStore, contextDefaults)
    local weakAuraGenerator = BuffWatcher_WeakAuraGenerator:new(configuration)
    local weakAuraExporter = BuffWatcher_WeakAuraExporter:new(configuration, weakAuraGenerator)
    local weakAurasInterface = BuffWatcher_WeakAuraInterface:new(configuration, contextStore)
    
    BuffWatcher_WeakAuraInterface_Singleton = weakAurasInterface

    settingsDialog.Initialize(BuffWatcher)

    weakAurasInterface.RegisterSpells(storedSpellsRegistry)

    mainWindow = BuffWatcher_MainWindow:new(storedSpellsRegistry, loggerModule, weakAurasInterface, weakAuraExporter, contextStore)

    mainWindow.GetFrame():Hide()

    self:RegisterEvent("NAME_PLATE_UNIT_ADDED")
    self:RegisterEvent("GROUP_ROSTER_UPDATE")
end

function BuffWatcher:OnDisable()
	-- Called when the addon is disabled
end

function BuffWatcher:NAME_PLATE_UNIT_ADDED(...)
    -- FIXME - make this work for default frames
    -- local plateName = select(1, ...)
    -- local nameplate = C_NamePlate.GetNamePlateForUnit(plateName)
    -- if (not nameplate) then
    --     return
    -- end
    -- local frame = nameplate.UnitFrame
    -- if (not frame) then
    --     return
    -- end
    -- if not nameplate or frame:IsForbidden() then return end
    -- frame.BuffFrame:ClearAllPoints()
    -- frame.BuffFrame:SetAlpha(0)
end

function BuffWatcher:GROUP_ROSTER_UPDATE(...)
    print("party members changed")
end

function BuffWatcher:SlashCommand()
    mainWindow.Show()
end