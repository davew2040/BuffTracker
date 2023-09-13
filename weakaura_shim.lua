function(allstates, event, ...)
    if (DaveTest_WeakAuraInterface_Singleton == nil 
        or not DaveTest_WeakAuraInterface_Singleton.IsRegistered()) then
        return false
    end

    return DaveTest_WeakAuraInterface_Singleton.DelegateTsu(allstates, event, ...)
end
