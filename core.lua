-- Globals & defaults
simpleAuras = simpleAuras or {}
sA = { frames = {}, dualframes = {} }

simpleAuras.auras   = simpleAuras.auras   or {}
simpleAuras.refresh = simpleAuras.refresh or 10

sA.SuperWoW = SetAutoloot and true or false
sA.debuffTimers = CleveRoids and CleveRoids.debuffTimers or {}

sAinCombat = nil

-- Parent frame
local sAParent = CreateFrame("Frame", "sAParentFrame", nil)
sAParent:SetFrameStrata("BACKGROUND")
sAParent:SetAllPoints(UIParent)

-- Utility: skin frame with backdrop
function sA:SkinFrame(frame, bg, border)
  frame:SetBackdrop({
    bgFile   = "Interface\\Buttons\\WHITE8x8",
    edgeFile = "Interface\\Buttons\\WHITE8x8",
    edgeSize = 1,
  })
  frame:SetBackdropColor(unpack(bg or {0.1, 0.1, 0.1, 0.95}))
  frame:SetBackdropBorderColor(unpack(border or {0, 0, 0, 1}))
end

-- Get Icon and Cooldown
function sA:GetCooldownInfo(spellName)
    local i = 1
    while true do
        local name, rank = GetSpellName(i, "spell")
        if not name then break end

        if name == spellName then
            local start, duration, enabled = GetSpellCooldown(i, "spell")
            local texture = GetSpellTexture(i, "spell")

            local remaining = nil
            if duration > 0 and enabled == 1 then
                -- Real cooldowns always have duration > 1.5
                if duration > 1.5 then
                    remaining = (start + duration) - GetTime()
                    if remaining <= 0 then remaining = nil end
                end
            end

            return texture, remaining, 0
			
        end
        i = i + 1
    end
    return nil, nil, nil
end

-- Get Icon, Duration and Stacks
function sA:GetAuraInfo(name, unit, auratype)

	if auraType == "Cooldown" then
		
		local texture, remaining_time, stacks = self:GetCooldownInfo(name)
		
		return texture, remaining_time, 1
		
	else

		local found_aura = false
		local remaining_time = 0
		local stacks = 0
		local spellID = nil

		local function find_aura()
			local function search(is_debuff)
				local i = (unit == "Player") and 0 or 1
				while true do
					local tex, s, sid, rem
					if unit == "Player" then
					
						local buffType = is_debuff and "HARMFUL" or "HELPFUL"
						local bid = GetPlayerBuff(i, buffType)
						local spellID = GetPlayerBuffID(bid)
						tex, s, sid, rem = GetPlayerBuffTexture(bid), GetPlayerBuffApplications(bid), spellID, GetPlayerBuffTimeLeft(bid)
						
					else
						if is_debuff then
							tex, s, _, sid, rem = UnitDebuff(unit, i)
						else
							tex, s, sid, rem = UnitBuff(unit, i)
						end
					end

					if not tex then break end

					if sid and name == SpellInfo(sid) then
						return true, s, sid, rem, tex
					end
					i = i + 1
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

		found_aura, stacks, spellID, remaining_time, texture = find_aura()
		
		if found_aura then
			if not remaining_time or remaining_time == 0 then
				if spellID and sA.debuffTimers then
					local _, unitGUID = UnitExists(unit)
					if unitGUID then
						unitGUID = string.upper(string.gsub(unitGUID, "^0x", ""))
						local target_timers = sA.debuffTimers[unitGUID]
						if target_timers and target_timers[spellID] then
							local expiry_time = target_timers[spellID]
							if expiry_time > GetTime() then
								remaining_time = expiry_time - GetTime()
							else
								remaining_time = 0
							end
						end
					end
				end
			end
			return texture, remaining_time, stacks
		end
		
	end
	
end

function sA:GetAuraInfoBase(auraname, unit, auraType)

	if auraType == "Cooldown" then
		
		local texture, remaining_time, stacks = self:GetCooldownInfo(auraname)
		return texture, remaining_time, 1
		
	else

		local function AuraInfo(unit, index, auraType)
			local name, icon, duration, stacks

			if not sAScanner then
				sAScanner = CreateFrame("GameTooltip", "sAScanner", sAParent, "GameTooltipTemplate")
				sAScanner:SetOwner(sAParent, "ANCHOR_NONE")
			end
			sAScanner:ClearLines()

			if unit == "Player" then
				local buffindex
				if auraType == "Buff" then
					buffindex = GetPlayerBuff(index - 1, "HELPFUL")
				else
					buffindex = GetPlayerBuff(index - 1, "HARMFUL")
				end
				sAScanner:SetPlayerBuff(buffindex)
				icon = GetPlayerBuffTexture(buffindex)
				duration = GetPlayerBuffTimeLeft(buffindex)
				stacks = GetPlayerBuffApplications(buffindex)
			else
				if auraType == "Buff" then
					sAScanner:SetUnitBuff(unit, index)
					icon = UnitBuff(unit, index)
				else
					sAScanner:SetUnitDebuff(unit, index)
					icon = UnitDebuff(unit, index)
				end
				duration = 0 -- temp for non-player units
			end

			name = sAScannerTextLeft1:GetText()
			
			return name, icon, duration, stacks
		
		end
		
		local i = 1
		while true do
			local name, icon, duration, stacks = AuraInfo(unit, i, auraType)
			if not name then break end
			if name == auraname then
				return icon, duration, stacks
			end
			i = i + 1
		end
		
	end
	
end

-- Create aura display frame
local function CreateAuraFrame(id)
  local f = CreateFrame("Frame", "sAAura" .. id, UIParent)
  f:SetFrameStrata("BACKGROUND")
  f.durationtext = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  f.durationtext:SetFont("Fonts\\FRIZQT__.TTF", 12, "OUTLINE")
  f.durationtext:SetPoint("CENTER", f, "CENTER", 0, 0)
  f.stackstext = f:CreateFontString(nil, "OVERLAY", "GameFontWhite")
  f.stackstext:SetFont("Fonts\\FRIZQT__.TTF", 10, "OUTLINE")
  f.stackstext:SetPoint("TOPLEFT", f.durationtext, "CENTER", 1, -6)
  f.texture = f:CreateTexture(nil, "BACKGROUND")
  f.texture:SetAllPoints(f)
  return f
end

-- Create mirrored dual frame
local function CreateDualFrame(id)
  local f = CreateAuraFrame(id)
  f.texture:SetTexCoord(1, 0, 0, 1)
  f.durationtext:SetPoint("CENTER", f, "CENTER", 0, 0)
  f.stackstext:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -2, 2)
  return f
end

-- Update aura display
function sA:UpdateAuras()
  if not gui.editor or not gui.editor:IsVisible() then
    if sA.TestAura then sA.TestAura:Hide() end
    if sA.TestAuraDual then sA.TestAuraDual:Hide() end
    if gui.editor then gui.editor:Hide(); gui.editor = nil end
  end

  for id, aura in ipairs(simpleAuras.auras) do
  
    local currentDuration, currentStacks, show, currentDurationtext = 600, 20, 0, ""

    if aura.name ~= "" and ((aura.inCombat == 1 and sAinCombat) or (aura.outCombat == 1 and not sAinCombat)) then
		local icon, duration, stacks
		if sA.SuperWoW and CleveRoids.ready then
			icon, duration, stacks = self:GetAuraInfo(aura.name, aura.unit, aura.type)
		else
			icon, duration, stacks = self:GetAuraInfoBase(aura.name, aura.unit, aura.type)
		end
        if icon then
          show, currentDuration, currentStacks = 1, duration, stacks
          if aura.autodetect == 1 and simpleAuras.auras[id].texture ~= icon then
            aura.texture = icon
            simpleAuras.auras[id].texture = icon
          end
		end
	  if aura.type == "Cooldown" then
		show = 0
		if aura.invert == 1 and not currentDuration then show = 1 end
		if aura.dual == 1 and currentDuration then show = 1 end
	  elseif aura.invert == 1 then
		show = 1 - show
	  end
    end

    local frame     = self.frames[id]     or CreateAuraFrame(id)
    local dualframe = self.dualframes[id] or (aura.dual == 1 and CreateDualFrame(id))
    self.frames[id]     = frame
    if aura.dual == 1 and aura.type ~= "Cooldown" then self.dualframes[id] = dualframe end

    if (show == 1 or (gui and gui:IsVisible())) and (not gui.editor or not gui.editor:IsVisible()) then
      local color = (aura.lowduration == 1 and currentDuration and currentDuration <= aura.lowdurationvalue)
        and (aura.lowdurationcolor or {1, 0, 0, 1})
        or  (aura.auracolor        or {1, 1, 1, 1})
	
	  if aura.duration == 1 then
		  if currentDuration and currentDuration > 100 then
			currentDurationtext = math.floor(currentDuration/60+0.5).."m"
		  else
			if currentDuration and (currentDuration <= aura.lowdurationvalue) then
			  currentDurationtext = string.format("%.1f", math.floor(currentDuration*10+0.5)/10)
			elseif currentDuration then
			  currentDurationtext = math.floor(currentDuration+0.5)
			end
		  end
	  end
	  
	  if currentDurationtext == "0.0" then
		currentDurationtext = 0
	  end
	  
	  frame:SetPoint("CENTER", UIParent, "CENTER", aura.xpos or 0, aura.ypos or 0)
      frame:SetFrameLevel(128 - id)
      frame:SetWidth(48*(aura.scale or 1))
      frame:SetHeight(48*(aura.scale or 1))
      frame.texture:SetTexture(aura.texture)
      frame.durationtext:SetText((aura.duration == 1 and ((sA.SuperWoW and CleveRoids.ready) or aura.unit == "Player" or aura.type == "Cooldown")) and currentDurationtext or "")
      frame.stackstext:SetText((aura.stacks   == 1) and currentStacks or "")
      if aura.duration == 1 then frame.durationtext:SetFont("Fonts\\FRIZQT__.TTF", (20*aura.scale), "OUTLINE") end
      if aura.stacks == 1 then frame.stackstext:SetFont("Fonts\\FRIZQT__.TTF", (14*aura.scale), "OUTLINE") end
	  
	  local r, g, b, durationalpha = unpack(color or {1,1,1,1})
	  
	  if aura.type == "Cooldown" and currentDuration then
		frame.texture:SetVertexColor(unpack({(r*0.5),(g*0.5),(b*0.5),durationalpha}))
	  else
		frame.texture:SetVertexColor(unpack(color))
	  end
	  
	  local durationcolor = {1.0, 0.82, 0.0, durationalpha}
	  local stackcolor = {1, 1, 1, durationalpha}
	  if ((sA.SuperWoW and CleveRoids.ready) or aura.unit == "Player" or aura.type == "Cooldown") and (currentDuration and currentDuration <= (aura.lowdurationvalue or 5)) then
          local _, _, _, durationalpha = unpack(aura.auracolor)
          durationcolor = {1, 0, 0, durationalpha}
          stackcolor = {1, 1, 1, durationalpha}
	  end

	  frame.durationtext:SetTextColor(unpack(durationcolor))
	  frame.stackstext:SetTextColor(unpack(stackcolor))

      frame:Show()

      if aura.dual == 1 and aura.type ~= "Cooldown" then
        dualframe:SetPoint("CENTER", UIParent, "CENTER", (-1 * (aura.xpos or 0)), aura.ypos or 0)
        dualframe:SetFrameLevel(128 - id)
        dualframe:SetWidth(48*(aura.scale or 1))
        dualframe:SetHeight(48*(aura.scale or 1))
        dualframe.texture:SetTexture(aura.texture)
	  
		  if aura.type == "Cooldown" and currentDuration then
			dualframe.texture:SetVertexColor(unpack({(r*0.5),(g*0.5),(b*0.5),durationalpha}))
		  else
			dualframe.texture:SetVertexColor(unpack(color))
		  end
	  
        dualframe.durationtext:SetText((aura.duration == 1 and ((sA.SuperWoW and CleveRoids.ready) or aura.unit == "Player" or aura.type == "Cooldown")) and currentDurationtext or "")
        dualframe.stackstext:SetText((aura.stacks   == 1) and currentStacks or "")
        if aura.duration == 1 then dualframe.durationtext:SetFont("Fonts\\FRIZQT__.TTF", (20*aura.scale), "OUTLINE") end
        if aura.stacks == 1 then dualframe.stackstext:SetFont("Fonts\\FRIZQT__.TTF", (14*aura.scale), "OUTLINE") end
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

-- Event frame for timed updates
local sAEvent = CreateFrame("Frame", "sAEvent", sAParent)
sAEvent:SetScript("OnUpdate", function()
  local time = GetTime()
  local refreshRate = 1 / simpleAuras.refresh
  if (time - (sAEvent.lastUpdate or 0)) < refreshRate then return end
  sAEvent.lastUpdate = time
  sA:UpdateAuras()
end)

local sACombat = CreateFrame("Frame")
sACombat:RegisterEvent("PLAYER_REGEN_DISABLED")
sACombat:RegisterEvent("PLAYER_REGEN_ENABLED")
sACombat:SetScript("OnEvent", function()
    if event == "PLAYER_REGEN_DISABLED" then
        sAinCombat = true
    elseif event == "PLAYER_REGEN_ENABLED" then
        sAinCombat = nil
    end
end)
