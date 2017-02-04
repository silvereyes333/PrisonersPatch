-- Prisoner's Patch Addon for Elder Scrolls Online
-- Author: silvereyes

local PrisonersPatch = {
    name = "PrisonersPatch",
    title = "Prisoner's Patch",
    version = "1.1.0",
    author = "|c99CCEFsilvereyes|r,",
    debugMode = false,
}

local EQUIP_TYPES =
{
    EQUIP_SLOT_HEAD,
    EQUIP_SLOT_CHEST,
    EQUIP_SLOT_SHOULDERS,
    EQUIP_SLOT_WAIST,
    EQUIP_SLOT_HAND,
    EQUIP_SLOT_LEGS,
    EQUIP_SLOT_FEET,
    EQUIP_SLOT_NECK,
    EQUIP_SLOT_RING1,
    EQUIP_SLOT_RING2,
    EQUIP_SLOT_MAIN_HAND,
    EQUIP_SLOT_OFF_HAND,
}

local PRISONERS_SET_NAME = 
{
    ["en"] = "Prisoner's Rags",
    ["de"] = "Lumpen des Gefangenen^p",
    ["fr"] = "Haillons de prisonnier^pmd",  
}

--[[ Gets the slot index of the first equipment slot containing a Prisoner's Rags item, if the
     5-slot bonus is active.  Otherwise, returns nil. ]]
function PrisonersPatch:GetFirstPrisonersSlot()

    -- Get the name of the Prisoner's Rags set in the current locale
    local languageCode = GetCVar("Language.2")
    local prisonersSetName = PRISONERS_SET_NAME[languageCode]
    if not prisonersSetName then
        return -- unsupported language code
    end
    
    -- Examine each slot's equipment
    for i, equipSlot in ipairs(EQUIP_TYPES) do
        local itemLink = GetItemLink(BAG_WORN, equipSlot)
        local hasSet, setName, numBonuses, numEquipped, maxEquipped = GetItemLinkSetInfo(itemLink)
        
        -- The slot has a Prisoner's Rag item
        if hasSet and setName == prisonersSetName then
            
            -- The item set isn't complete, so the bug doesn't apply
            if numEquipped < maxEquipped then
                return
            end
            
            -- The item set is complete, so return the slot index.
            return equipSlot
        end
    end
    
    -- Return nil. Nothing applicable found.
end

--[[ Handles inventory item slot update events and raise any callbacks queued up. ]]
local function OnInventorySingleSlotUpdate(eventCode, bagId, slotId)

    local self = PrisonersPatch

    if self.itemLink == nil or self.equipSlotIndex == nil or bagId ~= BAG_BACKPACK then
        return
    end
    
    local itemLink = GetItemLink(bagId, slotId)
    if itemLink ~= self.itemLink then
        return
    end
    
    EVENT_MANAGER:UnregisterForEvent(self.name, eventCode)
    
    -- Re-equip the item
    local equipSlotIndex = self.equipSlotIndex
    self.itemLink = nil
    self.equipSlotIndex = nil
    
    if self.debugMode then
        d("Equipping "..itemLink.." from bag "..tostring(bagId).." slot "..slotId.." to equipment slot "..tostring(equipSlotIndex))
    end
    EquipItem(bagId, slotId, equipSlotIndex)
end

-- Run every time the player logs in or re-zones
local function OnPlayerActivated(eventCode)

    local self = PrisonersPatch
    
    local firstPrisonersSlot = self:GetFirstPrisonersSlot()
    if not firstPrisonersSlot then
        if self.debugMode then
            d("No prisoner's rags items found")
        end
        return
    end
    
    self.itemLink = GetItemLink(BAG_WORN, firstPrisonersSlot)
    self.equipSlotIndex = firstPrisonersSlot
    -- Listen for bag slot update events so that we can process the callback
    EVENT_MANAGER:RegisterForEvent(PrisonersPatch.name, EVENT_INVENTORY_SINGLE_SLOT_UPDATE, OnInventorySingleSlotUpdate)
    
    -- Unequip the first Prisoner's Rags item
    if self.debugMode then
        d("Unequipping "..self.itemLink.." from slot "..self.equipSlotIndex)
    end
    UnequipItem(firstPrisonersSlot)
end

-- Register events
EVENT_MANAGER:RegisterForEvent(PrisonersPatch.name, EVENT_PLAYER_ACTIVATED, OnPlayerActivated)