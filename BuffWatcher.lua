
local f = CreateFrame("Frame")

BuffWatcher_Frame = nil

local storedSpellsRegistry = BuffWatcher_StoredSpellsRegistry:new()

function f:OnEvent(event, ...)
    if (event == "ADDON_LOADED" and select(1, ...) == "BuffWatcher") then
        -- BuffWatcher_Frame = BuffWatcher_LoggerWindow:new(UIParent)

        -- BuffWatcher_Frame:GetFrame():SetScale(0.5)
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
    elseif (event == "NAME_PLATE_UNIT_ADDED") then
        -- TODO - make this an optional setting
        local plateName = select(1, ...)
        local nameplate = C_NamePlate.GetNamePlateForUnit(plateName)
        local frame = nameplate.UnitFrame
        if not nameplate or frame:IsForbidden() then return end
        frame.BuffFrame:ClearAllPoints()
        frame.BuffFrame:SetAlpha(0)
    end
end

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

f:RegisterEvent("ADDON_LOADED")
f:RegisterEvent("NAME_PLATE_UNIT_ADDED")

f:SetScript("OnEvent", f.OnEvent)

SLASH_BUFFWATCHER1 = "/bw"

SlashCmdList.BUFFWATCHER = function(msg, _)
    BuffWatcher_Frame:Show()
end