---@class Pager
Pager = {}

function Pager:new(pageSize, itemCount)
    local self = {};

    local currentPage = 1
    local totalPageCount = math.floor((itemCount-1) / pageSize) + 1

    if (itemCount == 0) then
        totalPageCount = 0
    end

    local pageStart = function()
         return (currentPage-1)*pageSize + 1
    end

    local hypotheticalPageEnd = function()
        return pageStart() + pageSize - 1
    end

    local actualPageEnd = function()
        return math.min(hypotheticalPageEnd(), itemCount)
    end

    self.totalPageCount = math.floor(itemCount / pageSize) + 1

    self.hasNextPage = function()
        return actualPageEnd() < itemCount
    end

    self.hasPreviousPage = function() 
        return currentPage ~= 1
    end

    self.goNextPage = function()
        if (self.hasNextPage()) then
            currentPage = currentPage + 1
        end
    end

    self.goPreviousPage = function()
        if (self.hasPreviousPage()) then
            currentPage = currentPage - 1
        end
    end

    self.getPageStart = function()
        return pageStart();
    end

    self.getPageEnd = function()
        return actualPageEnd()
    end

    self.getTotalPageCount = function()
        return totalPageCount
    end

    self.getCurrentPage = function()
        return currentPage
    end

    return self;
end