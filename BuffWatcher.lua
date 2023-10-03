

BuffWatcher = LibStub("AceAddon-3.0"):NewAddon("BuffWatcher", "AceConsole-3.0", "AceEvent-3.0")
local AC = LibStub("AceConfig-3.0")
local ACD = LibStub("AceConfigDialog-3.0")
local AceGUI = LibStub("AceGUI-3.0")

BuffWatcher_Frame = nil

local defaults = {
	profile = {
		message = "Welcome Home!",
		showOnScreen = true,
        iconSize = 32
	},
}

local currentConfig = CopyTable(defaults)


local storedSpellsRegistry = BuffWatcher_StoredSpellsRegistry:new()

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

function BuffWatcher:OnInitialize()
	-- Called when the addon is loaded
	self:Print("Hello World!")

	AC:RegisterOptionsTable("BuffWatcher_options", options)
	self.optionsFrame = ACD:AddToBlizOptions("BuffWatcher_options", "BuffWatcher")

	self:RegisterChatCommand("bw", "SlashCommand")
	self:RegisterChatCommand("buffwatcher", "SlashCommand")
end

function BuffWatcher:OnEnable()
    -- BuffWatcher_Frame = BuffWatcher_LoggerWindow:new(UIParent)

    -- BuffWatcher_Frame:GetFrame():SetScale(0.5)
    -- BuffWatcher_Frame:GetFrame():SetSize(800, 500)
    -- BuffWatcher_Frame:GetFrame():SetPoint("CENTER")

    -- BuffWatcher_Frame:Show()

    BuffWatcher_WeakAuraInterface_Singleton.RegisterSpells(storedSpellsRegistry)

    BuffWatcher_Frame = BuffWatcher_MainWindow:new(UIParent, storedSpellsRegistry)

    -- --BuffWatcher_Frame:GetFrame():SetFrameStrata("DIALOG");
    -- BuffWatcher_Frame:GetFrame():SetScale(0.5)
    -- BuffWatcher_Frame:GetFrame():SetSize(1000, 800)
    -- BuffWatcher_Frame:GetFrame():SetPoint("CENTER")

    -- BuffWatcher_Frame:Show()

    -- ACD:Open("BuffWatcher_options", BuffWatcher_Frame:GetFrame())

    self:RegisterEvent("NAME_PLATE_UNIT_ADDED")
end

function BuffWatcher:OnDisable()
	-- Called when the addon is disabled
end

function BuffWatcher:ADDON_LOADED()
    -- BuffWatcher_Frame = BuffWatcher_LoggerWindow:new(UIParent)

    -- BuffWatcher_Frame:GetFrame():SehctScale(0.5)
    -- BuffWatcher_Frame:GetFrame():SetSize(800, 500)
    -- BuffWatcher_Frame:GetFrame():SetPoint("CENTER")

    -- BuffWatcher_Frame:Show()

    BuffWatcher_WeakAuraInterface_Singleton.RegisterSpells(storedSpellsRegistry)

    BuffWatcher_Frame = BuffWatcher_MainWindow:new(UIParent, storedSpellsRegistry)

    --BuffWatcher_Frame:GetFrame():SetFrameStrata("DIALOG");
    BuffWatcher_Frame:GetFrame():SetScale(0.5)
    BuffWatcher_Frame:GetFrame():SetSize(1000, 800)
    BuffWatcher_Frame:GetFrame():SetPoint("CENTER")

    BuffWatcher_Frame:Show()
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

-- function f:OnEvent(event, ...)
--     if (event == "ADDON_LOADED" and select(1, ...) == "BuffWatcher") then
--         -- BuffWatcher_Frame = BuffWatcher_LoggerWindow:new(UIParent)

--         -- BuffWatcher_Frame:GetFrame():SetScale(0.5)
--         -- BuffWatcher_Frame:GetFrame():SetSize(800, 500)
--         -- BuffWatcher_Frame:GetFrame():SetPoint("CENTER")

--         -- BuffWatcher_Frame:Show()

--         BuffWatcher_WeakAuraInterface_Singleton.RegisterSpells(storedSpellsRegistry)

--         BuffWatcher_Frame = BuffWatcher_MainWindow:new(UIParent, storedSpellsRegistry)

--        --BuffWatcher_Frame:GetFrame():SetFrameStrata("DIALOG");
--         BuffWatcher_Frame:GetFrame():SetScale(0.5)
--         BuffWatcher_Frame:GetFrame():SetSize(1000, 800)
--         BuffWatcher_Frame:GetFrame():SetPoint("CENTER")

--         BuffWatcher_Frame:Show()
--     elseif (event == "NAME_PLATE_UNIT_ADDED") then
--         -- TODO - make this an optional setting
--         local plateName = select(1, ...)
--         local nameplate = C_NamePlate.GetNamePlateForUnit(plateName)
--         local frame = nameplate.UnitFrame
--         if not nameplate or frame:IsForbidden() then return end
--         frame.BuffFrame:ClearAllPoints()
--         frame.BuffFrame:SetAlpha(0)
--     end
-- end

-- local f = CreateFrame("Frame")
-- local events = {}

-- function events:NAME_PLATE_UNIT_ADDED(plate)
-- 	local unitId = plate
-- 	local nameplate = C_NamePlate.GetNamePlateForUnit(unitId)
-- 	local frame = nameplate.UnitFrame
-- 	if not nameplate or frame:IsForbidden() then return end
-- 	frame.BuffFrame:ClearAllPoints()
-- 	frame.BuffFrame:SetAlpha(0)
-- end

-- for j, u in pairs(events) do
-- 	f:RegisterEvent(j)
-- end

-- f:SetScript("OnEvent", function(self, event, ...) events[event](self, ...) end)

-- f:RegisterEvent("ADDON_LOADED")
-- f:RegisterEvent("NAME_PLATE_UNIT_ADDED")

-- f:SetScript("OnEvent", f.OnEvent)

function BuffWatcher:SlashCommand(msg)
    BuffWatcher_Frame:Show()
end

function BuffWatcher:GetMessage(info)
	return currentConfig.profile.message
end

function BuffWatcher:SetMessage(info, value)
	currentConfig.profile.message = value
end

function BuffWatcher:IsShowOnScreen(info)
	return currentConfig.profile.showOnScreen
end

function BuffWatcher:ToggleShowOnScreen(info, value)
	currentConfig.profile.showOnScreen = value
end

function BuffWatcher:GetIconSize(info)
	return currentConfig.profile.iconSize
end

function BuffWatcher:SetIconSize(info, value)
	currentConfig.profile.iconSize = value
end