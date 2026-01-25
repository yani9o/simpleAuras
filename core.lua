-- Perf: cache globals
local floor, format = math.floor, string.format
local getn = table.getn
local unpack = unpack

-- Parent frame
local sAParent = CreateFrame("Frame", "sAParentFrame", UIParent)
sAParent:SetFrameStrata("BACKGROUND")
sAParent:SetAllPoints(UIParent)

function sA:ShouldAuraBeActive(aura, inCombat, inRaid, inParty)
  -- This check is now more robust and will correctly filter out new, empty auras.
  if not aura or not aura.name or aura.name == "" then return false end

  local enabled = (aura.enabled == nil or aura.enabled == 1)
  if not enabled then return false end

  local combatCheck = aura.inCombat == 1
  local outCombatCheck = aura.outCombat == 1
  local raidCheck = aura.inRaid == 1
  local partyCheck = aura.inParty == 1
  
  -- Rule: If no conditions are set at all, the aura should never be active.
  local anyConditionSet = combatCheck or outCombatCheck or raidCheck or partyCheck
  if not anyConditionSet then
      return false
  end

  -- Part 1: Evaluate Combat State requirement
  local combatStateOK = false
  local combatStateRequired = combatCheck or outCombatCheck
  if not combatStateRequired then
      -- If no combat condition is specified, it's considered met.
      combatStateOK = true
  else
      -- If a combat condition IS specified, check if it's met.
      if (combatCheck and inCombat) or (outCombatCheck and not inCombat) then
          combatStateOK = true
      end
  end

  -- Part 2: Evaluate Group State requirement
  local groupStateOK = false
  local groupStateRequired = raidCheck or partyCheck
  if not groupStateRequired then
      -- If no group condition is specified, it's considered met.
      groupStateOK = true
  else
      -- If a group condition IS specified, check if it's met.
      if (raidCheck and inRaid) or (partyCheck and inParty) then
          groupStateOK = true
      end
  end

  -- Final Decision: Both categories of conditions must be met.
  return combatStateOK and groupStateOK
end

-------------------------------------------------
-- Cooldown info by spell name
-- Returns: texture, remaining, isInBag
-- isInBag: 1 = item found in bag (not equipped), 0 = spell or equipped item
-------------------------------------------------
function sA:GetCooldownInfo(spellName)
  -- First check spellbook
  local i = 1
  while true do
    local name = GetSpellName(i, "spell")
    if not name then break end

    if name == spellName then
      local start, duration, enabled = GetSpellCooldown(i, "spell")
      local texture = GetSpellTexture(i, "spell")

      local remaining
      if enabled == 1 and duration and duration > 1.5 then
        remaining = (start + duration) - GetTime()
        if remaining <= 0 then remaining = nil end
      end

      return texture, remaining, 0
    end
    i = i + 1
  end
  
  -- Initialize cache if needed
  if not sA.itemIDCache then sA.itemIDCache = {} end
  
  -- If not found in spellbook, search bags for items and cache itemID
  for bag = 0, 4 do
    local numSlots = GetContainerNumSlots(bag)
    if numSlots then
      for slot = 1, numSlots do
        local itemLink = GetContainerItemLink(bag, slot)
        if itemLink then
          -- Parse itemLink directly: |Hitem:12345:0:0:0|h[Item Name]|h|r
          local _, _, itemID, itemName = string.find(itemLink, "|Hitem:(%d+):%d+:%d+:%d+|h%[([^%]]+)%]|h")
          
          if itemID and itemName and itemName == spellName then
            itemID = tonumber(itemID)
            
            -- Cache itemID for future lookups
            sA.itemIDCache[spellName] = itemID
            
            -- Get texture from GetContainerItemInfo (always works, unlike GetItemInfo)
            local texture, itemCount = GetContainerItemInfo(bag, slot)
            
            local start, duration, enabled = GetContainerItemCooldown(bag, slot)
            
            local remaining
            if enabled == 1 and duration and duration > 1.5 then
              remaining = (start + duration) - GetTime()
              if remaining <= 0 then remaining = nil end
            end
            
            -- Item found in bag (not equipped)
            return texture, remaining, 1
          end
        end
      end
    end
  end
  
  -- If not found in bags, search equipped items (trinkets, etc)
  local inventorySlots = {
    "HeadSlot", "NeckSlot", "ShoulderSlot", "BackSlot", "ChestSlot",
    "ShirtSlot", "TabardSlot", "WristSlot", "HandsSlot", "WaistSlot",
    "LegsSlot", "FeetSlot", "Finger0Slot", "Finger1Slot",
    "Trinket0Slot", "Trinket1Slot", "MainHandSlot", "SecondaryHandSlot",
    "RangedSlot", "AmmoSlot"
  }
  
  for _, slotName in ipairs(inventorySlots) do
    local invSlot = GetInventorySlotInfo(slotName)
    if invSlot then
      local itemLink = GetInventoryItemLink("player", invSlot)
      if itemLink then
        -- Parse itemLink: |Hitem:12345:0:0:0|h[Item Name]|h|r
        local _, _, itemID, itemName = string.find(itemLink, "|Hitem:(%d+):%d+:%d+:%d+|h%[([^%]]+)%]|h")
        
        if itemID and itemName and itemName == spellName then
          itemID = tonumber(itemID)
          
          -- Cache itemID for future lookups
          sA.itemIDCache[spellName] = itemID
          
          -- Get texture from inventory item
          local texture = GetInventoryItemTexture("player", invSlot)
          
          local start, duration, enabled = GetInventoryItemCooldown("player", invSlot)
          
          local remaining
          if enabled == 1 and duration and duration > 1.5 then
            remaining = (start + duration) - GetTime()
            if remaining <= 0 then remaining = nil end
          end
          
          -- No warning for equipped items (they're where they should be)
          return texture, remaining, 0
        end
      end
    end
  end
  
  -- Fallback: item was consumed or moved, keep showing aura without cooldown
  -- Texture will be taken from aura.texture (user-configured or autodetected earlier)
  -- Note: GetItemCooldown(itemID) doesn't exist in Vanilla 1.12
  -- We can't track cooldown without item location (bag/slot or inventory slot)
  
  return nil, nil, 0
end

-------------------------------------------------
-- Poison info (weapon enchantments)
-- Returns: hasEnchant, duration, charges, texture
-- unit can be "MH" (MainHand) or "OH" (OffHand)
-------------------------------------------------
function sA:GetPoisonInfo(unit)
  local mh, mhtime, mhcharge, oh, ohtime, ohcharge = GetWeaponEnchantInfo()
  
  local hasEnchant, timeLeft, charges
  
  if unit == "MH" then
    hasEnchant = mh
    timeLeft = mhtime
    charges = mhcharge
  elseif unit == "OH" then
    hasEnchant = oh
    timeLeft = ohtime
    charges = ohcharge
  else
    return nil, nil, nil, nil
  end
  
  if not hasEnchant then
    return nil, nil, nil, nil
  end
  
  -- Convert milliseconds to seconds for duration
  local duration = timeLeft and (timeLeft / 1000) or nil
  
  -- Get texture from weapon enchant tooltip
  -- For now, we'll use a default poison texture or get from tooltip
  -- In WoW, poison icons are usually obtained from GetInventoryItemTexture
  local texture = "Interface\\Icons\\INV_Potion_19"
  
  -- Try to get actual poison texture from equipped weapon slot
  local slotID = (unit == "MH") and 16 or 17  -- 16=MainHand, 17=OffHand
  local itemTexture = GetInventoryItemTexture("player", slotID)
  if itemTexture then
    -- For poisons, we can't directly get the poison icon, but we can use weapon texture as fallback
    -- In practice, user should set texture manually or we use default
    texture = itemTexture
  end
  
  return hasEnchant, duration, charges, texture
end

-------------------------------------------------
-- Reactive spell info (proc-based abilities)
-- Returns: spellID (index in spellbook), texture
-------------------------------------------------
function sA:GetReactiveInfo(spellName)
  -- Find spell in spellbook and get texture for icon autodetect
  local i = 1
  while true do
    local name = GetSpellName(i, "spell")
    if not name then break end

    if name == spellName then
      local texture = GetSpellTexture(i, "spell")
      return i, texture
    end
    i = i + 1
  end
  
  -- Not found in spellbook - spell doesn't exist for this character
  return nil, nil
end

-------------------------------------------------
-- Handle reactive spell activation (from COMBAT_TEXT_UPDATE)
-- This is called when a specific reactive ability becomes available
-------------------------------------------------
function sA:HandleReactiveActivation(spellName)
  if not spellName or spellName == "" then return end
  if not simpleAuras or not simpleAuras.auras then return end
  
  local currentTime = GetTime()
  local knownDuration = simpleAuras.reactiveDurations[spellName]
  
  -- Find auras tracking this reactive spell
  for id, aura in ipairs(simpleAuras.auras) do
    if aura and aura.name == spellName and aura.type == "Reactive" then
      
      -- Initialize state
      sA.reactiveTimers[spellName] = sA.reactiveTimers[spellName] or {
        expiry = nil,
        warnedOnce = false
      }
      
      local state = sA.reactiveTimers[spellName]
      
      -- Get spell info (texture)
      local spellID, texture = self:GetReactiveInfo(spellName)
      
      if spellID and texture then
        
        if knownDuration then
          -- Duration is known, set/refresh timer
          local oldExpiry = state.expiry
          
          state.expiry = currentTime + knownDuration
          state.warnedOnce = false
          
          -- Auto-detect texture (always update from spellbook)
          if texture and (aura.autodetect == 1 or aura.texture == "Interface\\Icons\\INV_Misc_QuestionMark") then
            aura.texture = texture
            simpleAuras.auras[id].texture = texture
          end
          
          -- Update cache for immediate rendering
          sA.activeAuras[id] = sA.activeAuras[id] or {}
          sA.activeAuras[id].active = true
          sA.activeAuras[id].expiry = state.expiry
          sA.activeAuras[id].icon = texture
          sA.activeAuras[id].stacks = 0
          sA.activeAuras[id].lastScan = currentTime
          
          if simpleAuras.showlearning == 1 then
            local remaining = oldExpiry and (oldExpiry - currentTime) or 0
            if oldExpiry and oldExpiry > currentTime then
              sA:Msg("Reactive '" .. spellName .. "' REFRESHED! Was: " .. floor(remaining + 0.5) .. "s remaining → Now: " .. knownDuration .. "s")
            else
              sA:Msg("Reactive '" .. spellName .. "' ACTIVATED - timer: " .. knownDuration .. "s")
            end
          end
          
        else
          -- Duration unknown - show warning ONCE
          if not state.warnedOnce then
            sA:Msg("Reactive spell '" .. spellName .. "' needs manual duration setup!")
            sA:Msg("Use: /sa reactduration \"" .. spellName .. "\" X")
            sA:Msg("Common durations: Riposte/Overpower=5s, Surprise Attack=6s")
            state.warnedOnce = true
          end
          
          -- Don't show icon without duration
          sA.activeAuras[id] = sA.activeAuras[id] or {}
          sA.activeAuras[id].active = false
          sA.activeAuras[id].expiry = nil
        end
      else
        -- Spell not found or no texture
        if simpleAuras.showlearning == 1 then
          sA:Msg("ERROR: Spell '" .. spellName .. "' not found in spellbook!")
          sA:Msg("Make sure spell name is correct and you have it in your spellbook.")
        end
      end
      
      break  -- Found the aura, no need to continue
    end
  end
end

-------------------------------------------------
-- Handle reactive spell usage (from UNIT_CASTEVENT)
-- This is called when player casts a spell - checks if it's an active reactive spell
-------------------------------------------------
function sA:HandleReactiveSpellUsed(spellName)
  if not spellName or spellName == "" then return end
  
  local state = sA.reactiveTimers[spellName]
  
  -- Check if this reactive spell is currently active
  if state and state.expiry and state.expiry > GetTime() then
    -- Deactivate the reactive spell
    state.expiry = nil
    
    -- Update cache
    for id, aura in ipairs(simpleAuras.auras or {}) do
      if aura and aura.name == spellName and aura.type == "Reactive" then
        sA.activeAuras[id] = sA.activeAuras[id] or {}
        sA.activeAuras[id].active = false
        sA.activeAuras[id].expiry = nil
        
        if simpleAuras.showlearning == 1 then
          sA:Msg("Reactive spell '" .. spellName .. "' used - deactivated")
        end
        break
      end
    end
  end
end

-------------------------------------------------
-- Update poison data (fixed 3-second interval + event-driven)
-- This function FETCHES poison info from GetWeaponEnchantInfo() and STORES it in cache
-- Called by:
--   - UNIT_INVENTORY_CHANGED events (immediate)
--   - Fixed 3-second timer (independent of refresh rate)
-------------------------------------------------
function sA:UpdatePoisonData()
  if not simpleAuras or not simpleAuras.auras then return end
  
  local currentTime = GetTime()
  
  for id, aura in ipairs(simpleAuras.auras) do
    if aura and aura.name and aura.name ~= "" and aura.type == "Poison" then
      
      sA.activeAuras[id] = sA.activeAuras[id] or {
        active = false,
        expiry = nil,
        stacks = 0,
        icon = nil,
        spellID = nil,
        lastUpdate = 0,
        lastScan = 0
      }
      
      -- Get poison info for the specified unit (MH or OH)
      local hasEnchant, duration, charges, texture = self:GetPoisonInfo(aura.unit)
      
      if hasEnchant then
        -- Poison is present
        local expiry = nil
        if duration and duration > 0 then
          expiry = currentTime + duration
        end
        
        sA.activeAuras[id].active = true
        sA.activeAuras[id].expiry = expiry
        sA.activeAuras[id].stacks = charges or 0
        sA.activeAuras[id].icon = texture
        sA.activeAuras[id].spellID = nil  -- Poisons don't have spell IDs
        sA.activeAuras[id].lastUpdate = currentTime
        sA.activeAuras[id].lastScan = currentTime
        
        -- Auto-detect texture
        if aura.autodetect == 1 and texture and aura.texture ~= texture then
          aura.texture = texture
          simpleAuras.auras[id].texture = texture
        end
      else
        -- No poison on this weapon
        sA.activeAuras[id].active = false
        sA.activeAuras[id].expiry = nil
        sA.activeAuras[id].stacks = 0
        sA.activeAuras[id].lastUpdate = currentTime
        sA.activeAuras[id].lastScan = currentTime
        -- Note: sA.activeAuras[id].icon is preserved from last scan
      end
    end
  end
end

-------------------------------------------------
-- Update reactive spell data (periodic scan - checks expiration only)
-- This function monitors reactive spell state
-- Main activation is handled by COMBAT_TEXT_UPDATE → HandleReactiveActivation()
-- Duration must be set manually via /sa reactduration
-------------------------------------------------
function sA:UpdateReactiveData()
  if not simpleAuras or not simpleAuras.auras then return end
  
  local currentTime = GetTime()
  
  for id, aura in ipairs(simpleAuras.auras) do
    if aura and aura.name and aura.name ~= "" and aura.type == "Reactive" then
      
      local spellID, texture = self:GetReactiveInfo(aura.name)
      local state = sA.reactiveTimers[aura.name]
      
      if state and state.expiry then
        
        -- Check if timer expired naturally
        if state.expiry < currentTime then
          -- Proc expired - only update if was active
          if sA.activeAuras[id] and sA.activeAuras[id].active then
            state.expiry = nil
            
            sA.activeAuras[id].active = false
            sA.activeAuras[id].expiry = nil
          end
          
        else
          -- Still active - only update cache if not already set or expiry changed
          local needsUpdate = false
          if not sA.activeAuras[id] or not sA.activeAuras[id].active then
            needsUpdate = true
          elseif sA.activeAuras[id].expiry ~= state.expiry then
            needsUpdate = true
          end
          
          if needsUpdate then
            sA.activeAuras[id] = sA.activeAuras[id] or {}
            sA.activeAuras[id].active = true
            sA.activeAuras[id].expiry = state.expiry
            sA.activeAuras[id].icon = texture
            sA.activeAuras[id].stacks = 0
            sA.activeAuras[id].lastScan = currentTime
          end
        end
      end
    end
  end
end

-------------------------------------------------
-- SuperWoW-aware aura search
-------------------------------------------------
local function find_aura(name, unit, auratype, myCast)
  local found, foundstacks, foundsid, foundrem, foundtex
  local function search(is_debuff)
    local i = (unit == "Player") and 0 or 1
    while true do
      local tex, stacks, sid, rem
      if unit == "Player" then
        local buffType = is_debuff and "HARMFUL" or "HELPFUL"
        local bid = GetPlayerBuff(i, buffType)
        tex, stacks, sid, rem = GetPlayerBuffTexture(bid), GetPlayerBuffApplications(bid), GetPlayerBuffID(bid), GetPlayerBuffTimeLeft(bid)
      else
        if is_debuff then
          tex, stacks, caster, sid, rem = UnitDebuff(unit, i)
        else
          tex, stacks, sid, rem = UnitBuff(unit, i)
        end
		
      end

      if not tex then break end
      if sid and name == SpellInfo(sid) then
		found, foundstacks, foundsid, foundrem, foundtex = 1, stacks, sid, rem, tex
		local _, unitGUID = UnitExists(unit)
		if unitGUID then unitGUID = gsub(unitGUID, "^0x", "") end
		if sA.auraTimers[unitGUID] and sA.auraTimers[unitGUID][sid] and sA.auraTimers[unitGUID][sid].castby and sA.auraTimers[unitGUID][sid].castby == sA.playerGUID
		or (unit == "Player") then
			return true, stacks, sid, rem, tex
		end
      end
      i = i + 1
    end
	if found == 1 and myCast == 0 then
		return true, foundstacks, foundsid, foundrem, foundtex
	end
    return false
  end

  local was_found, s, sid, rem, tex
  if auratype == "Buff" then
	was_found, s, sid, rem, tex = search(false)
  else
	was_found, s, sid, rem, tex = search(true)
	if not was_found then
		was_found, s, sid, rem, tex = search(false)
	end
  end
  
  return was_found, s, sid, rem, tex
end

-------------------------------------------------
-- Get Icon / Duration / Stacks (SuperWoW)
-------------------------------------------------
function sA:GetSuperAuraInfos(name, unit, auratype, myCast)
  if auratype == "Cooldown" then
    local texture, remaining_time = self:GetCooldownInfo(name)
    return _, texture, remaining_time, 1
  end

  local found, stacks, spellID, remaining_time, texture = find_aura(name, unit, auratype, myCast)
  if not found then return end

  -- Fallback for missing remaining_time
  if (not remaining_time or remaining_time == 0) and spellID and sA.auraTimers then
    local _, unitGUID = UnitExists(unit)
    if unitGUID then
      unitGUID = gsub(unitGUID, "^0x", "")
      local timers = sA.auraTimers[unitGUID]
      if timers and timers[spellID] and timers[spellID].duration then
        local expiry = timers[spellID].duration
        remaining_time = (expiry > GetTime()) and (expiry - GetTime()) or 0
      end
    end
  end
  return spellID, texture, remaining_time, stacks
end

-------------------------------------------------
-- Tooltip-based aura info (no SuperWoW)
-------------------------------------------------
function sA:GetAuraInfos(auraname, unit, auratype)
  if auratype == "Cooldown" then
    local texture, remaining_time = self:GetCooldownInfo(auraname)
    return texture, remaining_time, 1
  end

  if not sAScanner then
    sAScanner = CreateFrame("GameTooltip", "sAScanner", sAParent, "GameTooltipTemplate")
    sAScanner:SetOwner(sAParent, "ANCHOR_NONE")
  end

  local function AuraInfo(unit, index, kind)
    sAScanner:ClearLines()

    local name, icon, duration, stacks
    if unit == "Player" then
      local buffindex = GetPlayerBuff(index - 1, (kind == "Buff") and "HELPFUL" or "HARMFUL")
      sAScanner:SetPlayerBuff(buffindex)
      icon, duration, stacks = GetPlayerBuffTexture(buffindex), GetPlayerBuffTimeLeft(buffindex), GetPlayerBuffApplications(buffindex)
    else
      if kind == "Buff" then
        sAScanner:SetUnitBuff(unit, index)
        icon = UnitBuff(unit, index)
      else
        sAScanner:SetUnitDebuff(unit, index)
        icon = UnitDebuff(unit, index)
      end
      duration = 0
    end
    name = sAScannerTextLeft1:GetText()
    return name, icon, duration, stacks
  end

  local i = 1
  while true do
    local name, icon, duration, stacks = AuraInfo(unit, i, auratype)
    if not name then break end
    if name == auraname then
      return icon, duration, stacks
    end
    i = i + 1
  end
end

-------------------------------------------------
-- Frame creation helpers
-------------------------------------------------
local FONT = "Fonts\\FRIZQT__.TTF"

local function CreateAuraFrame(id)
  local f = CreateFrame("Frame", "sAAura" .. id, UIParent)
  f:SetFrameStrata("BACKGROUND")
  f:SetMovable(true)
  f:SetClampedToScreen(true)
  f:SetUserPlaced(true) -- Tell WoW that this frame's position is managed by the user

  f.texture = f:CreateTexture(nil, "ARTWORK")
  f.texture:SetAllPoints(f)

  f.durationtext = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  f.durationtext:SetFont(FONT, 12, "OUTLINE")
  f.durationtext:SetPoint("CENTER", f, "CENTER", 0, 0)

  f.stackstext = f:CreateFontString(nil, "OVERLAY", "GameFontWhite")
  f.stackstext:SetFont(FONT, 10, "OUTLINE")
  f.stackstext:SetPoint("CENTER", f, "CENTER", 0, 0)

  return f
end

local function CreateDraggerFrame(id, auraFrame)
  local dragger = CreateFrame("Frame", "sADragger" .. id, auraFrame)
  dragger:SetAllPoints(auraFrame)
  dragger:SetFrameStrata("HIGH")
  dragger:EnableMouse(true)
  dragger:RegisterForDrag("LeftButton")

  dragger:SetScript("OnDragStart", function(self)
    auraFrame:StartMoving()
  end)

  dragger:SetScript("OnDragStop", function(self)
    auraFrame:StopMovingOrSizing()
    
    -- We must calculate the offset from the screen's center because
    -- SetPoint uses a center-based coordinate system, while GetPoint
    -- returns coordinates from a corner anchor. This mismatch
    -- was causing auras to fly off-screen after being moved.
    local frameX, frameY = auraFrame:GetCenter()
    local screenWidth, screenHeight = GetScreenWidth(), GetScreenHeight()
    
    local offsetX = frameX - (screenWidth / 2)
    local offsetY = frameY - (screenHeight / 2)

    -- Round coordinates to prevent floating point issues in SavedVariables
    simpleAuras.auras[id].xpos = math.floor(offsetX + 0.5)
    simpleAuras.auras[id].ypos = math.floor(offsetY + 0.5)
	
	-- if gui.editor then
	  -- gui.editor:Hide()
	  -- gui.editor = nil
	  -- sA:EditAura(id)
	-- end
	
  end)
  
  -- Add a border to make it visible
  dragger:SetBackdrop({
    edgeFile = "Interface\\Buttons\\WHITE8x8",
    edgeSize = 1,
  })
  dragger:SetBackdropBorderColor(0, 1, 0, 0.5) -- Green, semi-transparent
  dragger:Hide()
  return dragger
end

local function CreateDualFrame(id)
  local f = CreateAuraFrame(id)
  f.texture:SetTexCoord(1, 0, 0, 1)
  -- Stacks are centered like in CreateAuraFrame (already set in CreateAuraFrame)
  return f
end

-------------------------------------------------
-- Initialize aura cache on addon load
-------------------------------------------------
function sA:InitializeAuraCache()
  if not simpleAuras or not simpleAuras.auras then return end
  
  -- Pre-populate cache for all configured auras
  for id, aura in ipairs(simpleAuras.auras) do
    if aura and aura.name and aura.name ~= "" then
      sA.activeAuras[id] = {
        active = false,
        expiry = nil,
        stacks = 0,
        icon = nil,
        spellID = nil,
        lastUpdate = 0,
        lastScan = 0  -- Track when we last scanned (for periodic refresh)
      }
    end
  end
  
  -- Do initial data fetch for all units
  self:UpdateAuraDataForUnit("Player")
  self:UpdateAuraDataForUnit("Target")
  self:UpdateCooldownData()
  self:UpdateReactiveData()
  self:UpdatePoisonData()
end

-------------------------------------------------
-- Update cached aura data for specific unit (event-driven + periodic fallback)
-- This function FETCHES data from WoW API and STORES it in cache
-- Called by: 
--   - UNIT_AURA events (immediate)
--   - PLAYER_TARGET_CHANGED (immediate)
--   - Periodic scan at simpleAuras.refresh rate (default: 5/sec)
-------------------------------------------------
function sA:UpdateAuraDataForUnit(unitFilter)
  if not simpleAuras or not simpleAuras.auras then return end
  
  local currentTime = GetTime()
  
  for id, aura in ipairs(simpleAuras.auras) do
    -- Only process auras for this unit (skip Cooldown, Reactive, and Poison - they have their own handlers)
    if aura and aura.name and aura.name ~= "" and aura.unit == unitFilter and aura.type ~= "Cooldown" and aura.type ~= "Reactive" and aura.type ~= "Poison" then
      
      -- Initialize cache entry
      sA.activeAuras[id] = sA.activeAuras[id] or {
        active = false,
        expiry = nil,
        stacks = 0,
        icon = nil,
        spellID = nil,
        lastUpdate = 0,
        lastScan = 0
      }
      
      local spellID, icon, duration, stacks
      
      if sA.SuperWoW then
        spellID, icon, duration, stacks = self:GetSuperAuraInfos(aura.name, aura.unit, aura.type, aura.myCast)
      else
        icon, duration, stacks = self:GetAuraInfos(aura.name, aura.unit, aura.type)
      end
      
      if icon then
        -- Aura found - calculate expiry time
        local expiry = nil
        
        if duration and duration > 0 then
          expiry = currentTime + duration
        else
          -- Try to get from auraTimers fallback
          local _, unitGUID = UnitExists(aura.unit == "Player" and "player" or "target")
          if unitGUID and spellID then
            unitGUID = gsub(unitGUID, "^0x", "")
            if sA.auraTimers[unitGUID] and sA.auraTimers[unitGUID][spellID] then
              expiry = sA.auraTimers[unitGUID][spellID].duration
            end
          end
        end
        
        sA.activeAuras[id].active = true
        sA.activeAuras[id].expiry = expiry
        sA.activeAuras[id].stacks = stacks or 0
        sA.activeAuras[id].icon = icon
        sA.activeAuras[id].spellID = spellID
        sA.activeAuras[id].lastUpdate = currentTime
        sA.activeAuras[id].lastScan = currentTime
        
        -- Auto-detect texture
        if aura.autodetect == 1 and aura.texture ~= icon then
          aura.texture = icon
          simpleAuras.auras[id].texture = icon
        end
      else
        -- Aura not found
        sA.activeAuras[id].active = false
        sA.activeAuras[id].expiry = nil
        sA.activeAuras[id].lastUpdate = currentTime
        sA.activeAuras[id].lastScan = currentTime
      end
    end
  end
end

-------------------------------------------------
-- Update cooldown data (event-driven + periodic fallback)
-- This function FETCHES cooldown info from WoW API and STORES it in cache
-- Called by:
--   - SPELL_UPDATE_COOLDOWN events (immediate)
--   - Periodic scan at simpleAuras.refresh rate (default: 5/sec)
-------------------------------------------------
function sA:UpdateCooldownData()
  if not simpleAuras or not simpleAuras.auras then return end
  
  local currentTime = GetTime()
  
  for id, aura in ipairs(simpleAuras.auras) do
    if aura and aura.name and aura.name ~= "" and aura.type == "Cooldown" then
      
      sA.activeAuras[id] = sA.activeAuras[id] or {
        active = false,
        expiry = nil,
        stacks = 0,
        icon = nil,
        spellID = nil,
        isInBag = 0,
        lastUpdate = 0,
        lastScan = 0
      }
      
      local texture, remaining_time, isInBag = self:GetCooldownInfo(aura.name)
      
      -- Check if we found the spell/item (texture found OR remaining_time exists from fallback)
      if texture or remaining_time then
        local expiry = nil
        if remaining_time and remaining_time > 0 then
          expiry = currentTime + remaining_time
        end
        
        sA.activeAuras[id].active = true
        sA.activeAuras[id].expiry = expiry
        sA.activeAuras[id].isInBag = isInBag or 0
        
        -- Update icon only if texture was returned (not nil)
        if texture then
          sA.activeAuras[id].icon = texture
          
          -- Auto-detect texture (works for both spells and items)
          if aura.autodetect == 1 and aura.texture ~= texture then
            aura.texture = texture
            simpleAuras.auras[id].texture = texture
          end
        end
        -- else: keep previous icon in cache
        
        sA.activeAuras[id].stacks = 0
        sA.activeAuras[id].lastUpdate = currentTime
        sA.activeAuras[id].lastScan = currentTime
      else
        -- Item/spell not found (ended, on cooldown, or missing)
        -- Keep last known icon in cache so it doesn't show question mark
        sA.activeAuras[id].active = false
        sA.activeAuras[id].expiry = nil
        sA.activeAuras[id].isInBag = 0
        sA.activeAuras[id].lastUpdate = currentTime
        sA.activeAuras[id].lastScan = currentTime
        -- Note: sA.activeAuras[id].icon is preserved from last scan
      end
    end
  end
end

-------------------------------------------------
-- Update aura display (RENDERING ONLY - uses cached data)
-- This function does NOT fetch data from API, only renders GUI
-- Called by: OnUpdate at FIXED 20 FPS (0.05 sec intervals)
-- Data source: sA.activeAuras cache (populated by UpdateAuraDataForUnit/UpdateCooldownData)
-- Only calculates: remaining = expiry - GetTime() (simple math!)
-------------------------------------------------
function sA:UpdateAuras()

  if not sA.SettingsLoaded then return end

  -- hide test/editor when not editing
  if not (gui and gui.editor and gui.editor:IsVisible()) then
    if sA.TestAura     then sA.TestAura:Hide() end
    if sA.TestAuraDual then sA.TestAuraDual:Hide() end
    if gui and gui.editor then gui.editor:Hide(); gui.editor = nil end
  end

  -- Get the current player status once per cycle
  local hasTarget = UnitExists("target")
  local inCombat = UnitAffectingCombat("player")
  local inRaid = UnitInRaid("player")
  local inParty = GetNumPartyMembers() > 0 and not inRaid

  for id, aura in ipairs(simpleAuras.auras) do
    -- Add a guard clause to skip invalid/empty auras completely.
    -- This prevents errors when a new, unconfigured aura exists.
    if aura and aura.name then
      local show, icon, duration, stacks
      local currentDuration, currentStacks, currentDurationtext, spellID = 600, 20, "", nil

      local frame     = self.frames[id]     or CreateAuraFrame(id)
      local dualframe = self.dualframes[id] or (aura.dual == 1 and CreateDualFrame(id))
      local dragger   = self.draggers[id]   or CreateDraggerFrame(id, frame)
      self.frames[id] = frame
      self.draggers[id] = dragger
      if aura.dual == 1 and aura.type ~= "Cooldown" and aura.type ~= "Reactive" then self.dualframes[id] = dualframe end
      
      local isEnabled = (aura.enabled == nil or aura.enabled == 1)
      local shouldShow

      if gui and gui:IsVisible() then
        -- SCENARIO 2 & 3: CONFIG or EDIT MODE
        -- Show all ENABLED auras, unless the editor is open for a DIFFERENT aura.
        shouldShow = isEnabled and not (gui.editor and gui.editor:IsVisible())
		
      else
	  
        -- SCENARIO 1: NORMAL GAMEPLAY MODE
        local conditionsMet = self:ShouldAuraBeActive(aura, inCombat, inRaid, inParty)
        show = 0 -- Default to not showing
        
        if conditionsMet then
          -- Check for target existence if required by the aura
          local targetCheckPassed = (aura.unit ~= "Target" or hasTarget)
          
          if targetCheckPassed then
            -- Get aura data (icon indicates presence)
            if aura.type == "Reactive" then
              -- Reactive spells use cached data from HandleReactiveActivation
              local auraData = sA.activeAuras[id]
              if auraData and auraData.active and auraData.expiry and auraData.expiry > GetTime() then
                icon = auraData.icon
                duration = auraData.expiry - GetTime()
                stacks = 0
              else
                icon = nil
                duration = nil
                stacks = 0
              end
            elseif aura.type == "Poison" then
              -- Poison: use cached data from UpdatePoisonData
              local auraData = sA.activeAuras[id]
              if auraData and auraData.active then
                icon = auraData.icon
                if auraData.expiry then
                  duration = auraData.expiry - GetTime()
                  if duration <= 0 then duration = nil end
                else
                  duration = nil
                end
                stacks = auraData.stacks or 0
              else
                icon = nil
                duration = nil
                stacks = 0
              end
            else
              -- Buff/Debuff/Cooldown: get from API
              if sA.SuperWoW then
                  spellID, icon, duration, stacks = self:GetSuperAuraInfos(aura.name, aura.unit, aura.type, aura.myCast)
              else
                  icon, duration, stacks = self:GetAuraInfos(aura.name, aura.unit, aura.type)
              end
            end
            
            local auraIsPresent = icon and 1 or 0
            
            -- Apply inversion logic
            if aura.type == "Cooldown" then
              local onCooldown = duration and duration > 0
              show = (((aura.showCD == "No CD" or aura.showCD == "Always") and not onCooldown) or ((aura.showCD == "CD" or aura.showCD == "Always") and onCooldown)) and 1 or 0
            elseif aura.type == "Reactive" or aura.type == "Poison" then
              -- For reactive spells and poisons: show when present
              show = auraIsPresent
            elseif aura.invert == 1 then
              show = 1 - auraIsPresent
            else
              show = auraIsPresent
            end
          end
        end
        
        shouldShow = (show == 1)
		
      end
      
      -- This handles hiding the aura if the editor for it is open
      if gui.editor and gui.editor:IsVisible() then
          shouldShow = false
      end

      if shouldShow then
        -- Get fresh aura data only if we are going to show it
        if aura.type == "Reactive" then
          -- Reactive: use cached data (updated by COMBAT_TEXT_UPDATE events)
          local auraData = sA.activeAuras[id]
          if auraData and auraData.active and auraData.expiry and auraData.expiry > GetTime() then
            icon = auraData.icon
            duration = auraData.expiry - GetTime()
            stacks = 0
          end
        elseif aura.type == "Poison" then
          -- Poison: use cached data (updated by UpdatePoisonData)
          local auraData = sA.activeAuras[id]
          if auraData and auraData.active then
            icon = auraData.icon
            if auraData.expiry then
              duration = auraData.expiry - GetTime()
              if duration <= 0 then duration = nil end
            else
              duration = nil
            end
            stacks = auraData.stacks or 0
          end
        elseif not (icon or aura.name) then -- Data might not have been fetched in /sa mode
		  spellID = nil
          if sA.SuperWoW then
            spellID, icon, duration, stacks = self:GetSuperAuraInfos(aura.name, aura.unit, aura.type)
          else
            icon, duration, stacks = self:GetAuraInfos(aura.name, aura.unit, aura.type)
          end
        end

        if icon then
          currentDuration = duration
          currentStacks = stacks
          if aura.autodetect == 1 and aura.texture ~= icon then
              aura.texture, simpleAuras.auras[id].texture = icon, icon
          end
        end
        
        -------------------------------------------------
        -- Duration text
        -------------------------------------------------
        if aura.duration == 1 and currentDuration then
          if sA.SuperWoW and sA.learnNew[spellID] and sA.learnNew[spellID] == 1 then
			currentDurationtext = "learning"
          elseif currentDuration > 100 then
            currentDurationtext = floor(currentDuration / 60 + 0.5) .. "m"
		  elseif currentDuration <= (aura.lowdurationvalue or 5) then
            currentDurationtext = format("%.1f", floor(currentDuration * 10 + 0.5) / 10)
          else
            currentDurationtext = floor(currentDuration + 0.5)
          end
        end

        if currentDurationtext == "0.0" then
          currentDurationtext = 0
        end

        -------------------------------------------------
        -- Apply visuals
        -------------------------------------------------
        local scale = aura.scale or 1
		if currentDurationtext == "learning" then
			textscale = scale/2
		else
			textscale = scale
		end
        frame:SetPoint("CENTER", UIParent, "CENTER", aura.xpos or 0, aura.ypos or 0)
        frame:SetFrameLevel(aura.layer or 0)
        frame:SetWidth(48 * scale)
  	    frame:SetHeight(48 * scale)
        
        -- For Reactive: use icon from cache if available
        local textureToUse = aura.texture
        if aura.type == "Reactive" and icon then
          textureToUse = icon
        end
        
        frame.texture:SetTexture(textureToUse)
        frame.durationtext:SetText((aura.duration == 1 and (sA.SuperWoW or aura.unit == "Player" or aura.type == "Cooldown" or aura.type == "Reactive" or aura.type == "Poison")) and currentDurationtext or "")
        frame.stackstext:SetText((aura.stacks == 1) and currentStacks or "")
        
        -- Position duration and stacks based on settings
        if aura.duration == 1 and aura.stacks == 1 then
          -- Both enabled: move duration up, stacks down
          frame.durationtext:SetPoint("CENTER", frame, "CENTER", 0, 8)
          frame.stackstext:SetPoint("CENTER", frame, "CENTER", 0, -8)
          local durationFontSize = (aura.durationSize or 20) * textscale
          frame.durationtext:SetFont(FONT, durationFontSize, "OUTLINE")
        elseif aura.duration == 1 then
          -- Only duration enabled: center duration
          frame.durationtext:SetPoint("CENTER", frame, "CENTER", 0, 0)
          frame.stackstext:SetPoint("CENTER", frame, "CENTER", 0, 0)
          local durationFontSize = (aura.durationSize or 20) * textscale
          frame.durationtext:SetFont(FONT, durationFontSize, "OUTLINE")
        else
          -- Duration disabled: center stacks (if enabled)
          frame.durationtext:SetPoint("CENTER", frame, "CENTER", 0, 0)
          frame.stackstext:SetPoint("CENTER", frame, "CENTER", 0, 0)
        end
        
        if aura.stacks == 1 then 
          local stacksFontSize = (aura.stacksSize or 14) * scale
          frame.stackstext:SetFont(FONT, stacksFontSize, "OUTLINE") 
        end

        -- Check for equipped item warning (should be equipped but in bag)
        local auraData = sA.activeAuras[id]
        local hasEquippedWarning = aura.equipped == 1 and auraData and auraData.isInBag == 1
        
        local color
        if hasEquippedWarning then
          -- Red tint for items that should be equipped but are in bags
          color = {1, 0, 0, 1}
        elseif aura.lowduration == 1 and currentDuration and currentDuration <= aura.lowdurationvalue then
          color = aura.lowdurationcolor or {1, 0, 0, 1}
        else
          color = aura.auracolor or {1, 1, 1, 1}
        end

        local r, g, b, alpha = unpack(color)
        if aura.type == "Cooldown" and currentDuration then
          frame.texture:SetVertexColor(r * 0.5, g * 0.5, b * 0.5, alpha)
        else
          frame.texture:SetVertexColor(r, g, b, alpha)
        end

        local durationcolor = {1.0, 0.82, 0.0, alpha}
        local stackcolor    = {1, 1, 1, alpha}
        if (sA.SuperWoW or aura.unit == "Player" or aura.type == "Cooldown" or aura.type == "Reactive" or aura.type == "Poison") and (currentDuration and currentDuration <= (aura.lowdurationvalue or 5)) and currentDurationtext ~= "learning" then
          durationcolor = {1, 0, 0, alpha}
        end
        frame.durationtext:SetTextColor(unpack(durationcolor))
        frame.stackstext:SetTextColor(unpack(stackcolor))
        frame:Show()

        -------------------------------------------------
        -- Dual frame
        -------------------------------------------------
        if aura.dual == 1 and aura.type ~= "Cooldown" and aura.type ~= "Reactive" and aura.type ~= "Poison" and dualframe then
          dualframe:SetPoint("CENTER", UIParent, "CENTER", -(aura.xpos or 0), aura.ypos or 0)
          dualframe:SetFrameLevel(aura.layer or 0)
          dualframe:SetWidth(48 * scale)
  		    dualframe:SetHeight(48 * scale)
          dualframe.texture:SetTexture(aura.texture)
          if aura.type == "Cooldown" and currentDuration then
            dualframe.texture:SetVertexColor(r * 0.5, g * 0.5, b * 0.5, alpha)
          else
            dualframe.texture:SetVertexColor(r, g, b, alpha)
          end
          dualframe.durationtext:SetText((aura.duration == 1 and (sA.SuperWoW or aura.unit == "Player" or aura.type == "Cooldown" or aura.type == "Reactive" or aura.type == "Poison")) and currentDurationtext or "")
          dualframe.stackstext:SetText((aura.stacks == 1) and currentStacks or "")
          
          -- Position duration and stacks based on settings (same as main frame)
          if aura.duration == 1 and aura.stacks == 1 then
            -- Both enabled: move duration up, stacks down
            dualframe.durationtext:SetPoint("CENTER", dualframe, "CENTER", 0, 8)
            dualframe.stackstext:SetPoint("CENTER", dualframe, "CENTER", 0, -8)
            local durationFontSize = (aura.durationSize or 20) * scale
            dualframe.durationtext:SetFont(FONT, durationFontSize, "OUTLINE")
          elseif aura.duration == 1 then
            -- Only duration enabled: center duration
            dualframe.durationtext:SetPoint("CENTER", dualframe, "CENTER", 0, 0)
            dualframe.stackstext:SetPoint("CENTER", dualframe, "CENTER", 0, 0)
            local durationFontSize = (aura.durationSize or 20) * scale
            dualframe.durationtext:SetFont(FONT, durationFontSize, "OUTLINE")
          else
            -- Duration disabled: center stacks (if enabled)
            dualframe.durationtext:SetPoint("CENTER", dualframe, "CENTER", 0, 0)
            dualframe.stackstext:SetPoint("CENTER", dualframe, "CENTER", 0, 0)
          end
          
          if aura.stacks == 1 then 
            local stacksFontSize = (aura.stacksSize or 14) * scale
            dualframe.stackstext:SetFont(FONT, stacksFontSize, "OUTLINE") 
          end
          dualframe.durationtext:SetTextColor(unpack(durationcolor))
          dualframe:Show()
        elseif dualframe then
          dualframe:Hide()
        end
      else
        if frame     then frame:Hide()     end
        if dualframe then dualframe:Hide() end
      end
    else
      -- This is a new/empty aura, make sure its frame is hidden if it exists
      if self.frames[id] then self.frames[id]:Hide() end
      if self.dualframes[id] then self.dualframes[id]:Hide() end
    end
  end
end
