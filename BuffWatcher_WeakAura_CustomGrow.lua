function(newPositions, activeRegions)
    -- make a list of regionData for each frame
    DevTool:AddData(CopyTable(activeRegions, true), "fixme active regions")
    
    if (BuffWatcher_Shared_Singleton == nil) then
        return
    end

    local mapRegionsByFrame = function(regions)
        local frames = {}

        for _, regionData in ipairs(regions) do
            local unit = regionData.region.state and regionData.region.state.unit
            if unit then
                local frame = C_NamePlate.GetNamePlateForUnit(unit)
                if frame then
                    frames[frame] = frames[frame] or {}
                    tinsert(frames[frame], regionData)
                end
            end
        end

        return frames
    end

    local filteredCatchAll = BuffWatcher_Shared_Singleton.TableIPairsValueFilter(activeRegions,
        function(activeRegion) 
            return nil ~= string.find(activeRegion.id, "CATCH ALL")
        end
    )

    local filteredStandard = BuffWatcher_Shared_Singleton.TableIPairsValueFilter(activeRegions,
        function(activeRegion) 
            return nil == string.find(activeRegion.id, "CATCH ALL")
        end
    )

    local standardFrames = mapRegionsByFrame(filteredStandard)
    local catchAllFrames = mapRegionsByFrame(filteredCatchAll)

    DevTool:AddData(CopyTable(filteredCatchAll, true), "fixme filteredCatchAll")
    DevTool:AddData(CopyTable(filteredStandard, true), "fixme filteredStandard")

    DevTool:AddData(mapRegionsByFrame(activeRegions), true, "fixme activeRegions")
    DevTool:AddData(standardFrames, "fixme standardFrames")
    DevTool:AddData(catchAllFrames, "fixme catchAllFrames")

    local x,y = 0,0

    for frame, frameRegionData in pairs(standardFrames) do
        newPositions[frame] = newPositions[frame] or {}

        for i, regionData in ipairs(frameRegionData) do
            newPositions[frame][regionData] = { x, y }
            x = x + (regionData.data.width or regionData.region.width)
        end
    end

    for frame, frameRegionData in pairs(catchAllFrames) do
        newPositions[frame] = newPositions[frame] or {}

        for i, regionData in ipairs(frameRegionData) do
            newPositions[frame][regionData] = { x, y }
            y = y + (regionData.data.width or regionData.region.width)
        end
    end


    -- for frame, regionsData in pairs(mapRegionsByFrame(activeRegions)) do
    --     local totalWidth = #regionsData - 1
    --     for _, regionData in ipairs(regionsData) do
    --         totalWidth = totalWidth + (regionData.data.width or regionData.region.width)
    --     end
    --     local x, y = - totalWidth/2, - (#regionsData - 1)/2
    --     newPositions[frame] = {}
    --     for i, regionData in ipairs(regionsData) do
    --         x = x + (regionData.data.width or regionData.region.width) / 2
    --         newPositions[frame][regionData] = { x, y }
    --         x = x + (regionData.data.width or regionData.region.width) / 2
    --     end
    -- end


    -- for frame, frameRegionData in pairs(frames) do
    --     newPositions[frame] = newPositions[frame] or {}

    --     if (filteredStandard[frameRegionData] ~= nil) then
    --         DevTool:AddData("Found standard data")
    --         newPositions[frame][frameRegionData] = { x, y }
    --         y = y + frameRegionData.data.height
    --     end
    -- end

    -- for _, regionData in ipairs(filteredCatchAll) do
    --     local unit = regionData.region.state and regionData.region.state.unit
    --     if unit then
    --         local frame = C_NamePlate.GetNamePlateForUnit(unit)
    --         DevTool:AddData(frame, "fixme frame")
    --         if frame then
    --             frames[frame] = frames[frame] or {}
    --             tinsert(frames[frame], regionData)
    --         end
    --     end
    -- end
    
        DevTool:AddData(CopyTable(newPositions, true), "fixme newPositions")
end

