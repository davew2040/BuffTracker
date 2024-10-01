local AceGUI = LibStub("AceGUI-3.0")
local AceConfig = LibStub("AceConfig-3.0")
local AceConfigDialog = LibStub("AceConfigDialog-3.0")

---@class BuffWatcher_AddEditSavedCast
BuffWatcher_AddEditSavedCast = {}

function BuffWatcher_AddEditSavedCast:new()
    self = {}

    local mainFrame = nil

    local mainPanel = nil

    local labelSpellname = nil
    local txtSpellName = nil
    local chkHide = nil
    local chkParty = nil
    local chkArenas = nil
    local chkEnemyNameplates = nil
    local chkBattlegrounds = nil
    local chkGlow = nil
    local chkRaids = nil
    local chkOwnOnly = nil
    local multiplierSlider = nil
    ---@type BuffWatcher_StoredSpell
    local activeModel = nil

    ---@type fun(model: BuffWatcher_StoredSpell)
    local localOnSave = function(model) end

    ---@param spell BuffWatcher_StoredSpell
    local setSavedSpell = function(spell)
        activeModel = CopyTable(spell)

        local spellInfo = BuffWatcher_Blizzard_Wrapper.GetSpellInfo(spell.spellId)

        mainFrame:SetTitle("Add/Edit Spell - " .. spellInfo.name)
    end

    local initializeActionsBar = function(parent)
        local actionsBarFrame = AceGUI:Create("SimpleGroup")
        actionsBarFrame:SetLayout("Manual")
        actionsBarFrame:SetFullWidth(true)

        local cancelButton = AceGUI:Create("Button")
        cancelButton:SetText("Cancel")
        cancelButton:SetWidth(125)
        cancelButton:SetPoint("BOTTOMRIGHT", parent.frame, "BOTTOMRIGHT", -20, 20)
        cancelButton:SetCallback("OnClick", function(control, event)
            mainFrame:Hide()
        end)
        actionsBarFrame:AddChild(cancelButton)

        local saveButton = AceGUI:Create("Button")
        saveButton:SetText("Save")
        saveButton:SetWidth(125)
        saveButton:SetPoint("BOTTOMRIGHT", cancelButton.frame, "BOTTOMLEFT", -10, 0)
        saveButton:SetCallback("OnClick", function(control, event)
            DevTool:AddData(activeModel, "fixme activeModel")
            localOnSave(activeModel)
        end)
        actionsBarFrame:AddChild(saveButton)

        return actionsBarFrame
    end

    local Initialize = function(parent)
        local frame = AceGUI:Create("Window")
        frame:SetTitle("Add/Edit Stored Spell")
        frame:SetLayout("List")

        mainPanel = AceGUI:Create("SimpleGroup")
        mainPanel:SetFullWidth(true)
        frame:AddChild(mainPanel)

        frame:AddChild(initializeActionsBar(frame))

        local spellOptions = {
            type = "group",
            args = {
              hide = {
                name = "Hide",
                desc = "Determines whether this aura is always hidden.",
                type = "toggle",
                ---@param 
                set = function(info,val) 
                    activeModel.hide = val
                end,
                get = function(info) 
                    return activeModel.hide
                 end
              },
              nameplates = {
                name = "Nameplates",
                desc = "Determines whether this aura is shown on nameplates.",
                type = "toggle",
                ---@param 
                set = function(info,val) 
                    activeModel.showOnNameplates = val
                end,
                get = function(info) 
                    return activeModel.showOnNameplates
                 end
              },
              party = {
                name = "Party",
                desc = "Determines whether this aura is shown on party frames.",
                type = "toggle",
                ---@param 
                set = function(info,val) 
                    activeModel.showInParty = val
                end,
                get = function(info) 
                    return activeModel.showInParty
                 end
              },
              raid = {
                name = "Raids",
                desc = "Determines whether this aura is shown on raid frames.",
                type = "toggle",
                ---@param 
                set = function(info,val) 
                    activeModel.showInRaid = val
                end,
                get = function(info) 
                    return activeModel.showInRaid
                 end
              },
              arenas = {
                name = "Arenas",
                desc = "Determines whether this aura is shown on arena frames.",
                type = "toggle",
                ---@param 
                set = function(info,val) 
                    activeModel.showInArena = val
                end,
                get = function(info) 
                    return activeModel.showInArena
                 end
              },
              battlegrounds = {
                name = "Battlegrounds",
                desc = "Determines whether this aura is shown in battlegrounds.",
                type = "toggle",
                ---@param 
                set = function(info,val) 
                    activeModel.showInBattlegrounds = val
                end,
                get = function(info) 
                    return activeModel.showInBattlegrounds
                 end
              },
              ownOnly = {
                name = "Show Own Only",
                desc = "Determines whether this aura is only shown for your spells.",
                type = "toggle",
                ---@param 
                set = function(info,val) 
                    activeModel.ownOnly = val
                end,
                get = function(info) 
                    return activeModel.ownOnly
                 end
              },
              isMinorAura = {
                name = "Minor Aura",
                desc = "Flags this auras as a minor aura, which will then use minor aura settings.",
                type = "toggle",
                ---@param 
                set = function(info,val) 
                    activeModel.isMinorAura = val
                end,
                get = function(info) 
                    return activeModel.isMinorAura
                 end
              },
              priority = {
                name = "Priority",
                desc = "Sets priority for this spell",
                type = "range",
                step = 1,
                min = 1,
                max = 10,
                ---@param 
                set = function(info,val) 
                    activeModel.priority = val
                end,
                get = function(info) 
                    return activeModel.priority
                end,
                disabled = function(info)
                    return activeModel.isMinorAura
                end
              },
              multiplier = {
                name = "Size Multiplier",
                desc = "Sets the size multiplier for icons of this spell",
                type = "range",
                step = 0.1,
                min = 0.1,
                max = 3.0,
                ---@param 
                set = function(info,val) 
                    activeModel.sizeMultiplier = val
                end,
                get = function(info) 
                    return activeModel.sizeMultiplier
                end,
                disabled = function(info)
                    return activeModel.isMinorAura
                end
              },
            }
          }

        DevTool:AddData('fixme after myOptionsTable')

        AceConfig:RegisterOptionsTable("BuffWatcher_temp_options", spellOptions)

        DevTool:AddData(testFrame, "fixme parent")
        
        return frame
    end

    ---@param spell BuffWatcher_StoredSpell
    ---@param onSave fun(model: BuffWatcher_StoredSpell)
    self.Show = function(spell, onSave)
        setSavedSpell(spell)
        localOnSave = onSave
        AceConfigDialog:Open("BuffWatcher_temp_options", mainPanel)
        mainFrame:Show()
    end

    self.Hide = function()
        mainFrame:Hide()
    end

    self.GetFrame = function()
        return mainFrame
    end

    mainFrame = Initialize()

    return self
end
