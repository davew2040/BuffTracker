---@class BuffWatcher_Tests
BuffWatcher_Tests = {}

function BuffWatcher_Tests.GroupCompareTests_AddAndUpdate()
    ---@type BuffWatcher_UnitToGuidLinkage
    local old = {
        unitToGuid = {
            party1 = 'G1',
            party2 = 'G2',
            player = 'G3'
        },
        guidToUnit = {
            G1 = 'party1',
            G2 = 'party2',
            G3 = 'player'
        }
    }

    ---@type BuffWatcher_UnitToGuidLinkage
    local new = {
        unitToGuid = {
            party1 = 'G4',
            party2 = 'G1',
            player = 'G3',
            party3 = 'G2',
        },
        guidToUnit = {
            G4 = 'party1',
            G1 = 'party2',
            G3 = 'player',
            G2 = 'party3'
        }
    }

    local compare = BuffWatcher_Shared.CompareUnitToGuidMaps(old, new)

    DevTool:AddData(compare, "test GroupCompareTests_AddAndUpdate")
end

function BuffWatcher_Tests.GroupCompareTests_Remove()
    ---@type BuffWatcher_UnitToGuidLinkage
    local old = {
        unitToGuid = {
            party1 = 'G1',
            party2 = 'G2',
            player = 'G3'
        },
        guidToUnit = {
            G1 = 'party1',
            G2 = 'party2',
            G3 = 'player'
        }
    }

    ---@type BuffWatcher_UnitToGuidLinkage
    local new = {
        unitToGuid = {
            party1 = 'G1',
            player = 'G3'
        },
        guidToUnit = {
            G4 = 'party1',
            G3 = 'player',
        }
    }

    local compare = BuffWatcher_Shared.CompareUnitToGuidMaps(old, new)

    DevTool:AddData(compare, "test GroupCompareTests_Remove")
end


function BuffWatcher_Tests.GroupCompareTests_RaidSwitch()
    ---@type BuffWatcher_UnitToGuidLinkage
    local old = {
        unitToGuid = {
            party1 = 'G1',
            party2 = 'G2',
            player = 'G3'
        },
        guidToUnit = {
            G1 = 'party1',
            G2 = 'party2',
            G3 = 'player'
        }
    }

    ---@type BuffWatcher_UnitToGuidLinkage
    local new = {
        unitToGuid = {
            raid1 = 'G1',
            raid2 = 'G2',
            player = 'G3'
        },
        guidToUnit = {
            G1 = 'raid1',
            G2 = 'raid2',
            G3 = 'player'
        }
    }

    local compare = BuffWatcher_Shared.CompareUnitToGuidMaps(old, new)

    DevTool:AddData(compare, "test GroupCompareTests_RaidSwitch")
end