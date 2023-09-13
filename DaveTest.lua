
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
    end
end

f:RegisterEvent("ADDON_LOADED")

f:SetScript("OnEvent", f.OnEvent)

SLASH_DAVETEST1 = "/dtest"

SlashCmdList.DAVETEST = function(msg, _)
    DaveTest_Frame:Show()
end