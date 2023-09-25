function(allstates, event, ...)
    if (BuffWatcher_WeakAuraInterface_Singleton == nil 
        or not BuffWatcher_WeakAuraInterface_Singleton.IsRegistered()) then
        return false
    end

    return BuffWatcher_WeakAuraInterface_Singleton.DelegateTsu(allstates, event, ...)
end
