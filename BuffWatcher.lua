BuffWatcher = LibStub("AceAddon-3.0"):NewAddon("BuffWatcher", "AceConsole-3.0", "AceEvent-3.0")

local AC = LibStub("AceConfig-3.0")
local ACD = LibStub("AceConfigDialog-3.0")
local AceGUI = LibStub("AceGUI-3.0")
local LibSerialize = LibStub("LibSerialize")
local LGF = LibStub("LibGetFrame-1.0")

---@type BuffWatcher_MainWindow
local mainWindow = nil
---@type BuffWatcher_WatcherService
local watcherService = nil

local cleuEvents = {
    UNIT_DIED = function(self, eventData) 
        --print("UNIT DIED")
    end,
    SPELL_CAST_SUCCESS = function(self, eventData, ...)
        BuffWatcher.SPELL_CAST_SUCCESS(self, eventData, ...)
    end
}

local pool = nil

function BuffWatcher:OnInitialize()
	self:Print("Loading BuffWatcher addon...")

	self:RegisterChatCommand("bw", "SlashCommand")
	self:RegisterChatCommand("buffwatcher", "SlashCommand")
end

local lgfUpdate = function(...)
    DevTool:AddData({...}, "lgfUpdate")
    watcherService.FramesChanged()
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
    watcherService = BuffWatcher_WatcherService:new(configuration, contextStore)

    --BuffWatcher_WeakAuraInterface_Singleton = weakAurasInterface

    settingsDialog.Initialize(BuffWatcher)

    --weakAurasInterface.RegisterSpells(storedSpellsRegistry)

    mainWindow = BuffWatcher_MainWindow:new(storedSpellsRegistry, loggerModule, weakAuraExporter, contextStore)

    mainWindow.GetFrame():Hide()

    --UNIT_AURA, ARENA_TEAM_ROSTER_UPDATE, GROUP_ROSTER_UPDATE, NAME_PLATE_UNIT_REMOVED, NAME_PLATE_UNIT_ADDED, COMBAT_LOG_EVENT_UNFILTERED:SPELL_CAST_SUCCESS, STATUS, CLEU:UNIT_DIED, PLAYER_ENTERING_WORLD, PARTY_CONVERTED_TO_RAID

    self:RegisterEvent("UNIT_AURA")
    self:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")

    self:RegisterEvent("NAME_PLATE_UNIT_ADDED")
    self:RegisterEvent("NAME_PLATE_UNIT_REMOVED")
    self:RegisterEvent("GROUP_ROSTER_UPDATE")
    --self:RegisterEvent("ARENA_TEAM_ROSTER_UPDATE")

    self:RegisterEvent("PLAYER_ENTERING_WORLD")
    self:RegisterEvent("ARENA_OPPONENT_UPDATE")

    LGF.RegisterCallback("BuffWatcher", "GETFRAME_REFRESH", lgfUpdate)
    LGF.RegisterCallback("BuffWatcher", "FRAME_UNIT_UPDATE", lgfUpdate)
    LGF.RegisterCallback("BuffWatcher", "FRAME_UNIT_REMOVED", lgfUpdate)
end

function BuffWatcher:OnDisable()
	-- Called when the addon is disabled
end

function BuffWatcher:UNIT_AURA(...)
    --DevTool:AddData({...}, "UNIT_AURA")

    watcherService.HandleEvent_UnitAura(select(2, ...), select(3, ...))
end

function BuffWatcher:COMBAT_LOG_EVENT_UNFILTERED(...)
    local eventData = {CombatLogGetCurrentEventInfo()}
    local subevent = eventData[2]

    if (cleuEvents[subevent] ~= nil) then
        cleuEvents[subevent](self, eventData)
    end
end

---@param eventData any
function BuffWatcher:SPELL_CAST_SUCCESS(eventData)
    watcherService.HandleEvent_Cast(eventData)
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

    --DevTool:AddData({...}, "NAME_PLATE_UNIT_ADDED")

    watcherService.HandleEvent_NameplateAdded(select(2, ...))
end

function BuffWatcher:NAME_PLATE_UNIT_REMOVED(...)
    -- DevTool:AddData({...}, "NAME_PLATE_UNIT_REMOVED")
    watcherService.HandleEvent_NameplateRemoved(select(2, ...))
end

function BuffWatcher:GROUP_ROSTER_UPDATE(...)
    watcherService.RefreshLoaded()
    LGF:ScanForUnitFrames()
end


function BuffWatcher:ARENA_TEAM_ROSTER_UPDATE(...)
    print("ARENA_TEAM_ROSTER_UPDATE")
end

function BuffWatcher:ARENA_OPPONENT_UPDATE(...)
    print("ARENA_OPPONENT_UPDATE")
    watcherService.ResetIfLoaded()
end

function BuffWatcher:PLAYER_ENTERING_WORLD(...)
    print("PLAYER_ENTERING_WORLD")
    watcherService.RefreshLoaded()
    LGF:ScanForUnitFrames()
end

function BuffWatcher:PARTY_CONVERTED_TO_RAID(...)
    print("PARTY_CONVERTED_TO_RAID")
    watcherService.RefreshLoaded()
end

function BuffWatcher:SlashCommand()
    mainWindow.Show()
end