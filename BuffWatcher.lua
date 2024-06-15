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
        BuffWatcher.UNIT_DIED(self, eventData)
    end,
    SPELL_CAST_SUCCESS = function(self, eventData, ...)
        BuffWatcher.SPELL_CAST_SUCCESS(self, eventData)
    end
}

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

---@param eventData any
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
    watcherService.RefreshLoaded()
    LGF:ScanForUnitFrames()
end


function BuffWatcher:ARENA_TEAM_ROSTER_UPDATE(...)
    print("ARENA_TEAM_ROSTER_UPDATE")
end

function BuffWatcher:ARENA_OPPONENT_UPDATE(...)
--     print("ARENA_OPPONENT_UPDATE")
--     DevTool:AddData({...}, "fixme ARENA_OPPONENT_UPDATE")
    
    watcherService.ArenaOpponentUpdate()
end

function BuffWatcher:PLAYER_ENTERING_WORLD(...)
    --print("PLAYER_ENTERING_WORLD")
    watcherService.PlayerEnteringWorld()
    
    LGF:ScanForUnitFrames()
end

function BuffWatcher:PARTY_CONVERTED_TO_RAID(...)
    --print("PARTY_CONVERTED_TO_RAID")
    watcherService.RefreshLoaded()
end

function BuffWatcher:RunBenchmark(value)
    local iterations = 1000000
    -- local sum = 0

    -- local intMap = { }
    -- intMap[123456789012] = 1

    -- local stringMap = { }
    -- stringMap["123456789012"] = 1

    -- BuffWatcher_Shared.Benchmark(function()
    --     local myTest = intMap[123456789012]
    --     sum = sum + myTest
    -- end, iterations)


    -- BuffWatcher_Shared.Benchmark(function()
    --     local key = tostring(123456789012)
    --     local key2 = tostring(123456789012)
    --     local myTest = stringMap[key]
    --     sum = sum + myTest
    -- end, iterations)
    local pool = CreateObjectPool(
        function()
            return {} 
        end
    )

    local test = nil


    BuffWatcher_Shared.Benchmark(function()
        if test ~= nil then
            pool:Release(test["testKey"])
            pool:Release(test)
        end

        test = pool:Acquire()

        test["testKey"] = pool:Acquire()
        test["testKey"]["testKey2"] = 42
    end, 100)

    BuffWatcher_Shared.Benchmark(function()
        if test ~= nil then
            pool:Release(test["testKey"])
            pool:Release(test)
        end

        test = pool:Acquire()

        test["testKey"] = pool:Acquire()
        test["testKey"]["testKey2"] = 42
    end, iterations)

    BuffWatcher_Shared.Benchmark(function()
        if test ~= nil then
            test = nil
        end

        test = {}

        test["testKey"] = {
            ["testKey2"] = 42
        }
    end, iterations)
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
