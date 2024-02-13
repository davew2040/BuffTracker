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
        print("UNIT DIED")
    end,
    SPELL_CAST_SUCCESS = function(self, eventData) 
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
    DevTool:AddData("lgfUpdate")
    watcherService.RefreshLoaded()
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

    LGF.RegisterCallback("BuffWatcher", "GETFRAME_REFRESH", lgfUpdate)
    LGF.RegisterCallback("BuffWatcher", "FRAME_UNIT_UPDATE", lgfUpdate)
    LGF.RegisterCallback("BuffWatcher", "FRAME_UNIT_REMOVED", lgfUpdate)
end

function BuffWatcher:OnDisable()
	-- Called when the addon is disabled
end

function BuffWatcher:UNIT_AURA(...)
    DevTool:AddData({...}, "UNIT_AURA")

    watcherService.HandleEvent_UnitAura(select(2, ...), select(3, ...))
end

function BuffWatcher:COMBAT_LOG_EVENT_UNFILTERED(...)
    local eventData = {CombatLogGetCurrentEventInfo()}
    local subevent = eventData[2]

    if (cleuEvents[subevent] ~= nil) then
        cleuEvents[subevent](self, eventData)
    end
end

function BuffWatcher:SPELL_CAST_SUCCESS(eventData)
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
    --DevTool:AddData({...}, "NAME_PLATE_UNIT_REMOVED")
    watcherService.HandleEvent_NameplateRemoved(select(2, ...))
end

function BuffWatcher:GROUP_ROSTER_UPDATE(...)
    -- local parentFrame = LGF.GetUnitFrame("player", 
    -- { 
    --     ignorePlayerFrame = true, 
    --     ignoreTargetFrame = true, 
    --     ignoreTargettargetFrame = true 
    -- })

    -- local iconSize = 24
    -- local borderSize = 1

    -- pool = CreateFramePool("Frame", UIParent)
    -- local frame = pool:Acquire()

    -- -- frame:SetFrameLevel(99)
    -- -- frame:SetSize(64, 64)
    -- -- frame:SetPoint("TOPLEFT", UIParent, "TOPLEFT", 300, -300)
    -- -- frame.texture = frame:CreateTexture()
    -- -- frame.texture:SetAllPoints(frame)
    -- -- frame.texture:SetColorTexture(0.7, 0, 0)
    -- -- frame:Show()

    -- -- local frame2 = CreateFrame("Frame", "test spell frame", UIParent)
    -- -- frame2:SetFrameLevel(99)
    -- -- frame2:SetSize(64, 64)
    -- -- frame2:SetPoint("TOPLEFT", UIParent, "TOPLEFT", 200, -200)
    -- -- frame2.texture = frame2:CreateTexture()
    -- -- frame2.texture:SetAllPoints(frame2)
    -- -- frame2.texture:SetColorTexture(0.7, 0, 0)


    -- for x=1,10 do
    --     for y=1,10 do
    --         local outerBorderFrame =  pool:Acquire() -- CreateFrame("Frame", "test spell frame", parentFrame)
    --         DevTool:AddData(outerBorderFrame, "fixme outerBorderFrame")
    --         outerBorderFrame:SetFrameLevel(99)
    --         outerBorderFrame:SetSize(iconSize + borderSize*4, iconSize + borderSize*4)
    --         outerBorderFrame:SetPoint("TOPLEFT", parentFrame, "TOPLEFT", x*100, -y*100)
    --         outerBorderFrame.texture = outerBorderFrame:CreateTexture()
    --         outerBorderFrame.texture:SetAllPoints(outerBorderFrame)
    --         outerBorderFrame.texture:SetColorTexture(0.7, 0, 0)
    --         outerBorderFrame:Show()

    --         local borderFrame = pool:Acquire() -- CreateFrame("Frame", "test spell frame", outerBorderFrame)
    --         borderFrame:SetFrameLevel(100)
    --         borderFrame:SetSize(iconSize + borderSize*2, iconSize + borderSize*2)
    --         borderFrame:SetPoint("TOPLEFT", outerBorderFrame, "TOPLEFT", borderSize, -borderSize)
    --         borderFrame.texture = borderFrame:CreateTexture()
    --         borderFrame.texture:SetAllPoints(borderFrame)
    --         borderFrame.texture:SetColorTexture(0, 0, 0)
    --         borderFrame:Show()

    --         local frame = pool:Acquire() -- CreateFrame("Frame", "test spell frame", borderFrame)
    --         frame:SetFrameLevel(101)
    --         frame:SetSize(iconSize, iconSize)
    --         frame:SetPoint("TOPLEFT", borderFrame, "TOPLEFT", borderSize, -borderSize)
    --         -- frame:SetPoint("TOPRIGHT", borderFrame, "TOPRIGHT", borderSize, borderSize)
    --         -- frame:SetPoint("BOTTOMLEFT", borderFrame, "BOTTOMLEFT", -borderSize, -borderSize)
    --         -- frame:SetPoint("BOTTOMRIGHT", borderFrame, "BOTTOMRIGHT", borderSize, -borderSize)
    --         frame.texture = frame:CreateTexture("test texture frame", "OVERLAY", nil, -8)
    --         frame.texture:SetTexture(1360764)
    --         frame.texture:SetAllPoints(frame)
    --         frame.texture:SetTexCoord(0.07, 0.93, 0.07, 0.93)

    --         local myCooldown = CreateFrame("Cooldown", "myCooldown", frame, "CooldownFrameTemplate")
    --         myCooldown:SetAllPoints()
    --         myCooldown:SetCooldown(GetTime(), 10)

    --         frame:Show()

    --         -- local border1 = CreateFrame("Frame", "MyAddonBorder1", frame)
    --         -- Mixin(border1, BackdropTemplateMixin)

    --         -- border1:SetPoint("TOPLEFT", frame, "TOPLEFT", -x, x)
    --         -- border1:SetPoint("TOPRIGHT", frame, "TOPRIGHT", x, x)
    --         -- border1:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", -x, -x)
    --         -- border1:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", x, -x)
    --         -- border1:SetBackdrop({
    --         --     edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
    --         --     edgeSize = x*4
    --         -- })
    --         -- border1:SetBackdropBorderColor(1, 0, 0, 1)
    --     end
    -- end



    print("GROUP_ROSTER_UPDATE")
    LGF:ScanForUnitFrames()
end


function BuffWatcher:ARENA_TEAM_ROSTER_UPDATE(...)
    print("ARENA_TEAM_ROSTER_UPDATE")
end

function BuffWatcher:PLAYER_ENTERING_WORLD(...)
    LGF:ScanForUnitFrames()
end

function BuffWatcher:PARTY_CONVERTED_TO_RAID(...)
    watcherService.RefreshLoaded()
end

function BuffWatcher:SlashCommand()
    mainWindow.Show()
end