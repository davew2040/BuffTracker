
local f = CreateFrame("Frame")

DaveTest_Frame = nil

local storedSpells = DaveTest_StoredSpells:new()

function f:OnEvent(event, ...)
    if (event == "ADDON_LOADED" and select(1, ...) == "DaveTest") then
        -- DaveTest_Frame = DaveTest_LoggerWindow:new(UIParent)

        -- DaveTest_Frame:GetFrame():SetScale(0.5)
        -- DaveTest_Frame:GetFrame():SetSize(800, 500)
        -- DaveTest_Frame:GetFrame():SetPoint("CENTER")

        -- DaveTest_Frame:Show()

        DaveTest_WeakAuraInterface_Singleton.RegisterSpells(storedSpells)

        DaveTest_Frame = DaveTest_MainWindow:new(UIParent, storedSpells)

       --DaveTest_Frame:GetFrame():SetFrameStrata("DIALOG");
        DaveTest_Frame:GetFrame():SetScale(0.5)
        DaveTest_Frame:GetFrame():SetSize(1000, 800)
        DaveTest_Frame:GetFrame():SetPoint("CENTER")

        DaveTest_Frame:Show()
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

SLASH_DAVETEST1 = "/dtest"

SlashCmdList.DAVETEST = function(msg, _)
    DaveTest_Frame:Show()
end