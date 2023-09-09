
local f = CreateFrame("Frame")

DaveTest_Frame = nil-- CreateFrame("Frame", "DaveTest Title", UIParent, "BackdropTemplate")

function f:OnEvent(event, ...)
    if (event == "ADDON_LOADED" and select(1, ...) == "DaveTest") then
        DaveTest_Frame = DaveTest_LoggerWindow:new(UIParent)

        DaveTest_Frame:GetFrame():SetSize(800, 500)
        DaveTest_Frame:GetFrame():SetPoint("CENTER")
        DaveTest_Frame:GetFrame():Show()
    end
end

f:RegisterEvent("ADDON_LOADED")

f:SetScript("OnEvent", f.OnEvent)

SLASH_DAVETEST1 = "/dtest"

SlashCmdList.DAVETEST = function(msg, _)
    DaveTest_Frame:UpdateWindow()
    DaveTest_Frame:GetFrame():Show()
end