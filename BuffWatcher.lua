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
    ---@param self any
    ---@param eventData BuffWatcher_Blizzard_CombatLogEntry
    UNIT_DIED = function(self, eventData) 
        BuffWatcher.UNIT_DIED(self, eventData)
    end,

    ---@param self any
    ---@param eventData BuffWatcher_Blizzard_CombatLogEntry
    SPELL_CAST_SUCCESS = function(self, eventData)
        BuffWatcher.SPELL_CAST_SUCCESS(self, eventData)
    end
}

---@type BuffWatcher_MiscellaneousObjectPool
local pool = nil

function BuffWatcher:OnInitialize()
	self:Print("Loading BuffWatcher addon...")

	self:RegisterChatCommand("bw", "SlashCommand")
	self:RegisterChatCommand("buffwatcher", "SlashCommand")
end

local lgfUpdate = function(...)
    local updateType = select(1, ...)

    -- DevTool:AddData({...}, "fixme lgfUpdate")

    -- if (updateType ~= "GETFRAME_REFRESH") then
    --     DevTool:AddData({...}, "fixme lgfUpdate not refresh")
    -- end

    watcherService.FramesChanged()
end

function BuffWatcher:OnEnable()
    DevTool:AddData("fixme OnEnable")

    pool = BuffWatcher_MiscellaneousObjectPool:new()

    local contextDefaults = BuffWatcher_DefaultContextValues:new()

    BuffWatcher_DbAccessor_Singleton.OnInitialize(contextDefaults);

    local loggerModule = BuffWatcher_LoggerModule:new()
    local storedSpellsRegistry = BuffWatcher_StoredSpellsRegistry:new()
    local configuration = BuffWatcher_Configuration:new(BuffWatcher_DbAccessor_Singleton)
    local contextStore = BuffWatcher_AuraContextStore:new(BuffWatcher_DbAccessor_Singleton, configuration, storedSpellsRegistry, contextDefaults, pool)
    local settingsDialog = BuffWatcher_SettingsDialog:new(BuffWatcher_DbAccessor_Singleton, contextStore, contextDefaults)
    local weakAuraGenerator = BuffWatcher_WeakAuraGenerator:new(configuration)
    local weakAuraExporter = BuffWatcher_WeakAuraExporter:new(configuration, weakAuraGenerator)
    watcherService = BuffWatcher_WatcherService:new(configuration, contextStore, pool)

    DevTool:AddData("fixme watcherService loaded")


    --BuffWatcher_WeakAuraInterface_Singleton = weakAurasInterface

    settingsDialog.Initialize(BuffWatcher)

    --weakAurasInterface.RegisterSpells(storedSpellsRegistry)

    DevTool:AddData("fixme BuffWatcher_MainWindow:new started")


    mainWindow = BuffWatcher_MainWindow:new(storedSpellsRegistry, loggerModule, weakAuraExporter, contextStore)

    DevTool:AddData("fixme mainwindow started")


    mainWindow.GetFrame():Hide()

    --UNIT_AURA, ARENA_TEAM_ROSTER_UPDATE, GROUP_ROSTER_UPDATE, NAME_PLATE_UNIT_REMOVED, NAME_PLATE_UNIT_ADDED, COMBAT_LOG_EVENT_UNFILTERED:SPELL_CAST_SUCCESS, STATUS, CLEU:UNIT_DIED, PLAYER_ENTERING_WORLD, PARTY_CONVERTED_TO_RAID

    DevTool:AddData("registering events")

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
    watcherService.HandleEvent_UnitAura(select(2, ...), select(3, ...))
end

function BuffWatcher:COMBAT_LOG_EVENT_UNFILTERED(...)
    ---@type BuffWatcher_Blizzard_CombatLogEntry
    local eventData = pool.GetObject() 

    local timestamp, subevent, hideCaster, sourceGUID, sourceName, sourceFlags, sourceRaidFlags, destGUID, destName, destFlags,	destRaidFlags, param12 = CombatLogGetCurrentEventInfo()

    eventData.timestamp = timestamp
    eventData.subevent = subevent
    eventData.hideCaster = hideCaster
    eventData.sourceGUID = sourceGUID
    eventData.destGUID = destGUID

    if (eventData.subevent == 'SPELL_CAST_SUCCESS') then
        eventData.spellID = param12
    end

    if (cleuEvents[subevent] ~= nil) then
        cleuEvents[subevent](self, eventData)
    end

    pool.ReleaseObject(eventData)
end

---@param eventData BuffWatcher_Blizzard_CombatLogEntry
function BuffWatcher:SPELL_CAST_SUCCESS(eventData)
    watcherService.HandleEvent_Cast(eventData)
end

---@param eventData BuffWatcher_Blizzard_CombatLogEntry
function BuffWatcher:UNIT_DIED(eventData)
    watcherService.HandleEvent_UnitDied(eventData)
end

function BuffWatcher:NAME_PLATE_UNIT_ADDED(...)
    watcherService.HandleEvent_NameplateAdded(select(2, ...))
end

function BuffWatcher:NAME_PLATE_UNIT_REMOVED(...)
    watcherService.HandleEvent_NameplateRemoved(select(2, ...))
end

function BuffWatcher:GROUP_ROSTER_UPDATE(...)
    DevTool:AddData({...}, "fixme GROUP_ROSTER_UPDATE")
    watcherService.RefreshLoaded()
    watcherService.HandleEvent_GroupRosterUpdate()
    LGF:ScanForUnitFrames()
end


function BuffWatcher:ARENA_TEAM_ROSTER_UPDATE(...)
    print("ARENA_TEAM_ROSTER_UPDATE")
end

function BuffWatcher:ARENA_OPPONENT_UPDATE(...)
--     print("ARENA_OPPONENT_UPDATE")
     DevTool:AddData({...}, "fixme ARENA_OPPONENT_UPDATE")
    
    watcherService.ArenaOpponentUpdate()
end

function BuffWatcher:PLAYER_ENTERING_WORLD(...)
    --print("PLAYER_ENTERING_WORLD")
    watcherService.PlayerEnteringWorld()

    DevTool:AddData({ 
        isBattleground = BuffWatcher_Shared.PlayerInBattleground(),
        bestMap = C_Map.GetBestMapForUnit("player")
    }, "fixme PLAYER_ENTERING_WORLD info")
    
    LGF:ScanForUnitFrames()
end

function BuffWatcher:PARTY_CONVERTED_TO_RAID(...)
    --print("PARTY_CONVERTED_TO_RAID")
    watcherService.RefreshLoaded()
end


local benchmarkRoutine = function()
    for i=1,40 do
        ---@type BuffWatcher_Blizzard_AuraData
        local auraData = C_UnitAuras.GetAuraDataByIndex('player', i, "HELPFUL")
    end

    for i=1,40 do
        ---@type BuffWatcher_Blizzard_AuraData
        local auraData = C_UnitAuras.GetAuraDataByIndex('player', i, "HARMFUL")

    end
end


function BuffWatcher:RunBenchmark(value)
    local iterations = 10000


    BuffWatcher_Shared.Benchmark(benchmarkRoutine, iterations)
end

function BuffWatcher:SlashCommand(input)
    local command = self:GetArgs(input, 1)
    if (command == next) then
        mainWindow.Show()
    else
        command = string.lower(command)

        if (command == "show") then
            mainWindow.Show()
        elseif (command == "bench") then
            self:RunBenchmark(self:GetArgs(input, 2))
        end
    end
end
