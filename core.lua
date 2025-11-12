-- Perf: cache globals
local floor, format = math.floor, string.format
local getn = table.getn
local unpack = unpack
local GetTime = GetTime
local UnitExists = UnitExists
local UnitAffectingCombat = UnitAffectingCombat
local UnitInRaid = UnitInRaid
local GetNumPartyMembers = GetNumPartyMembers
local gsub = string.gsub

-- Parent frame
local sAParent = CreateFrame("Frame", "sAParentFrame", UIParent)
sAParent:SetFrameStrata("BACKGROUND")
sAParent:SetAllPoints(UIParent)

---------------------------------------------------
-- Aura Condition Evaluation (uses cached state)
---------------------------------------------------
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
-- Cooldown info by spell name with caching
-------------------------------------------------
local cooldownCache = {}
local COOLDOWN_CACHE_TIME = 0.5

function sA:GetCooldownInfo(spellName)
  local now = GetTime()
  local cached = cooldownCache[spellName]
  
  -- Return cached result if fresh enough
  if cached and (now - cached.time) < COOLDOWN_CACHE_TIME then
    return cached.texture, cached.remaining, cached.stacks
  end
  
  local i = 1
  while true do
    local name = GetSpellName(i, "spell")
    if not name then break end

    if name == spellName then
      local start, duration, enabled = GetSpellCooldown(i, "spell")
      local texture = GetSpellTexture(i, "spell")

      local remaining
      if enabled == 1 and duration and duration > 1.5 then
        remaining = (start + duration) - now
        if remaining <= 0 then remaining = nil end
      end

      -- Cache the result
      cooldownCache[spellName] = {
        texture = texture,
        remaining = remaining,
        stacks = 0,
        time = now
      }
      
      return texture, remaining, 0
    end
    i = i + 1
  end
  
  -- Cache negative result too
  cooldownCache[spellName] = {
    texture = nil,
    remaining = nil,
    stacks = 0,
    time = now
  }
  return nil, nil, 0
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
-- Test frames
-------------------------------------------------
function sA:UpdateTestFrame(aura)
  if not (gui and gui.editor and gui.editor:IsVisible()) then return end
  if not sA.TestAura then return end

  local TestAura = sA.TestAura
  local TestAuraDual = sA.TestAuraDual
  local scale = aura.scale or 1

  TestAura:SetPoint("CENTER", UIParent, "CENTER", aura.xpos or 0, aura.ypos or 0)
  TestAura:SetWidth(48 * scale)
  TestAura:SetHeight(48 * scale)
  TestAura:SetFrameLevel(128)
  TestAura.texture:SetTexture(aura.texture)
  TestAura.durationtext:SetFont(FONT, 20 * scale, "OUTLINE")
  TestAura.stackstext:SetFont(FONT, 14 * scale, "OUTLINE")
  
  local r, g, b, alpha = unpack(aura.auracolor or {1, 1, 1, 1})
  TestAura.texture:SetVertexColor(r, g, b, alpha)
  TestAura.durationtext:SetTextColor(1.0, 0.82, 0.0, alpha)
  TestAura.stackstext:SetTextColor(1, 1, 1, alpha)
  
  if aura.duration == 1 then TestAura.durationtext:SetText("12") else TestAura.durationtext:SetText("") end
  if aura.stacks == 1 then TestAura.stackstext:SetText("3") else TestAura.stackstext:SetText("") end
  TestAura:Show()

  if aura.dual == 1 and aura.type ~= "Cooldown" then
    TestAuraDual:SetPoint("CENTER", UIParent, "CENTER", -(aura.xpos or 0), aura.ypos or 0)
    TestAuraDual:SetWidth(48 * scale)
    TestAuraDual:SetHeight(48 * scale)
    TestAuraDual:SetFrameLevel(128)
    TestAuraDual.texture:SetTexture(aura.texture)
    TestAuraDual.texture:SetVertexColor(r, g, b, alpha)
    TestAuraDual.durationtext:SetFont(FONT, 20 * scale, "OUTLINE")
    TestAuraDual.stackstext:SetFont(FONT, 14 * scale, "OUTLINE")
    TestAuraDual.durationtext:SetTextColor(1.0, 0.82, 0.0, alpha)
    if aura.duration == 1 then TestAuraDual.durationtext:SetText("12") else TestAuraDual.durationtext:SetText("") end
    if aura.stacks == 1 then TestAuraDual.stackstext:SetText("3") else TestAuraDual.stackstext:SetText("") end
    TestAuraDual:Show()
  else
    TestAuraDual:Hide()
  end
end

-------------------------------------------------
-- Create Aura Frames
-------------------------------------------------
local function CreateAuraFrame(id)
  local f = CreateFrame("Frame", "sAFrame" .. id, sAParent)
  f:SetFrameStrata("BACKGROUND")
  f.texture = f:CreateTexture(nil, "ARTWORK")
  f.texture:SetAllPoints(f)
  f.durationtext = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  f.durationtext:SetPoint("CENTER", f, "CENTER", 0, 0)
  f.stackstext = f:CreateFontString(nil, "OVERLAY", "GameFontWhite")
  f.stackstext:SetPoint("TOPLEFT", f.durationtext, "CENTER", 1, -6)
  f:Hide()
  return f
end

local function CreateDraggerFrame(id, frame)
  local dragger = CreateFrame("Frame", "sADragger" .. id, frame)
  dragger:SetAllPoints(frame)
  dragger:SetFrameStrata("HIGH")
  dragger:EnableMouse(true)
  dragger:RegisterForDrag("LeftButton")
  dragger:SetBackdrop({edgeFile = "Interface\\Buttons\\WHITE8x8", edgeSize = 1})
  dragger:SetBackdropBorderColor(0, 1, 0, 0.5)

  dragger:SetScript("OnDragStart", function()
    frame:SetMovable(true)
    frame:StartMoving()
  end)

  dragger:SetScript("OnDragStop", function()
    frame:StopMovingOrSizing()
    frame:SetMovable(false)
    
    local frameX, frameY = frame:GetCenter()
    local screenWidth, screenHeight = GetScreenWidth(), GetScreenHeight()
    
    local offsetX = frameX - (screenWidth / 2)
    local offsetY = frameY - (screenHeight / 2)
    offsetX = floor(offsetX + 0.5)
    offsetY = floor(offsetY + 0.5)
    
    simpleAuras.auras[id].xpos = offsetX
    simpleAuras.auras[id].ypos = offsetY
  end)

  dragger:Hide()
  return dragger
end

local function CreateDualFrame(id)
  local f = CreateAuraFrame(id)
  f.texture:SetTexCoord(1, 0, 0, 1)
  f.stackstext:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -2, 2)
  return f
end

-------------------------------------------------
-- Update aura display (uses event-driven state)
-------------------------------------------------
local function IsAuraActive(aura)
  return aura and aura.name and aura.name ~= "" and (aura.enabled == nil or aura.enabled == 1)
end

function sA:UpdateAuras()

  if not sA.SettingsLoaded then return end

  -- hide test/editor when not editing
  if not (gui and gui.editor and gui.editor:IsVisible()) then
    if sA.TestAura     then sA.TestAura:Hide() end
    if sA.TestAuraDual then sA.TestAuraDual:Hide() end
    if gui and gui.editor then gui.editor:Hide(); gui.editor = nil end
  end

  -- EVENT-DRIVEN: Use cached game state from events (no polling)
  -- State is updated by events: PLAYER_REGEN_*, RAID_ROSTER_UPDATE, 
  -- PARTY_MEMBERS_CHANGED, PLAYER_TARGET_CHANGED
  local inCombat = sA.gameState.inCombat
  local inRaid = sA.gameState.inRaid
  local inParty = sA.gameState.inParty
  local hasTarget = sA.gameState.hasTarget

  for id, aura in ipairs(simpleAuras.auras) do
    -- OPTIMIZATION: Quick check to skip disabled auras entirely
    if not IsAuraActive(aura) then
      if self.frames[id] then self.frames[id]:Hide() end
      if self.dualframes[id] then self.dualframes[id]:Hide() end
    else
      local show, icon, duration, stacks
      local currentDuration, currentStacks, currentDurationtext, spellID = 600, 20, "", nil

      local frame     = self.frames[id]     or CreateAuraFrame(id)
      local dualframe = self.dualframes[id] or (aura.dual == 1 and CreateDualFrame(id))
      local dragger   = self.draggers[id]   or CreateDraggerFrame(id, frame)
      self.frames[id] = frame
      self.draggers[id] = dragger
      if aura.dual == 1 and aura.type ~= "Cooldown" then self.dualframes[id] = dualframe end
      
      local isEnabled = true -- Already checked above
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
            if sA.SuperWoW then
                spellID, icon, duration, stacks = self:GetSuperAuraInfos(aura.name, aura.unit, aura.type, aura.myCast)
            else
                icon, duration, stacks = self:GetAuraInfos(aura.name, aura.unit, aura.type)
            end
            
            local auraIsPresent = icon and 1 or 0
            
            -- Apply inversion logic
            if aura.type == "Cooldown" then
              local onCooldown = duration and duration > 0
              show = (((aura.showCD == "No CD" or aura.showCD == "Always") and not onCooldown) or ((aura.showCD == "CD" or aura.showCD == "Always") and onCooldown)) and 1 or 0
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
        if not (icon or aura.name) then -- Data might not have been fetched in /sa mode
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
		local textscale
		if currentDurationtext == "learning" then
			textscale = scale/2
		else
			textscale = scale
		end
        frame:SetPoint("CENTER", UIParent, "CENTER", aura.xpos or 0, aura.ypos or 0)
        frame:SetFrameLevel(128 - id)
        frame:SetWidth(48 * scale)
  	    frame:SetHeight(48 * scale)
        frame.texture:SetTexture(aura.texture)
        frame.durationtext:SetText((aura.duration == 1 and (sA.SuperWoW or aura.unit == "Player" or aura.type == "Cooldown")) and currentDurationtext or "")
        frame.stackstext:SetText((aura.stacks == 1) and currentStacks or "")
        if aura.duration == 1 then frame.durationtext:SetFont(FONT, 20 * textscale, "OUTLINE") end
        if aura.stacks   == 1 then frame.stackstext:SetFont(FONT, 14 * scale, "OUTLINE") end

        local color = (aura.lowduration == 1 and currentDuration and currentDuration <= aura.lowdurationvalue)
          and (aura.lowdurationcolor or {1, 0, 0, 1})
          or  (aura.auracolor or {1, 1, 1, 1})

        local r, g, b, alpha = unpack(color)
        if aura.type == "Cooldown" and currentDuration then
          frame.texture:SetVertexColor(r * 0.5, g * 0.5, b * 0.5, alpha)
        else
          frame.texture:SetVertexColor(r, g, b, alpha)
        end

        local durationcolor = {1.0, 0.82, 0.0, alpha}
        local stackcolor    = {1, 1, 1, alpha}
        if (sA.SuperWoW or aura.unit == "Player" or aura.type == "Cooldown") and (currentDuration and currentDuration <= (aura.lowdurationvalue or 5)) and currentDurationtext ~= "learning" then
          durationcolor = {1, 0, 0, alpha}
        end
        frame.durationtext:SetTextColor(unpack(durationcolor))
        frame.stackstext:SetTextColor(unpack(stackcolor))
        frame:Show()

        -------------------------------------------------
        -- Dual frame
        -------------------------------------------------
        if aura.dual == 1 and aura.type ~= "Cooldown" and dualframe then
          dualframe:SetPoint("CENTER", UIParent, "CENTER", -(aura.xpos or 0), aura.ypos or 0)
          dualframe:SetFrameLevel(128 - id)
          dualframe:SetWidth(48 * scale)
  		    dualframe:SetHeight(48 * scale)
          dualframe.texture:SetTexture(aura.texture)
          if aura.type == "Cooldown" and currentDuration then
            dualframe.texture:SetVertexColor(r * 0.5, g * 0.5, b * 0.5, alpha)
          else
            dualframe.texture:SetVertexColor(r, g, b, alpha)
          end
          dualframe.durationtext:SetText((aura.duration == 1 and (sA.SuperWoW or aura.unit == "Player" or aura.type == "Cooldown")) and currentDurationtext or "")
          dualframe.stackstext:SetText((aura.stacks == 1) and currentStacks or "")
          if aura.duration == 1 then dualframe.durationtext:SetFont(FONT, 20 * scale, "OUTLINE") end
          if aura.stacks   == 1 then dualframe.stackstext:SetFont(FONT, 14 * scale, "OUTLINE") end
          dualframe.durationtext:SetTextColor(unpack(durationcolor))
          dualframe:Show()
        elseif dualframe then
          dualframe:Hide()
        end
      else
        if frame     then frame:Hide()     end
        if dualframe then dualframe:Hide() end
      end
    end
  end
end
