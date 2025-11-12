local f = CreateFrame("Frame")
f:RegisterEvent("VARIABLES_LOADED")
f:SetScript("OnEvent", function()
	
		---------------------------------------------------
		-- SavedVariables Initialization
		---------------------------------------------------

		-- Ensure tables exist
		simpleAuras = simpleAuras or {}
		simpleAuras.auras   = simpleAuras.auras   or {}
		simpleAuras.refresh = simpleAuras.refresh or 5
		if sA.SuperWoW then
		  simpleAuras.auradurations = simpleAuras.auradurations or {}
		  simpleAuras.updating      = simpleAuras.updating or 0
		  simpleAuras.showlearning  = simpleAuras.showlearning or 0
		  simpleAuras.learnall      = simpleAuras.learnall or 0
		end
		
		sA.SettingsLoaded = 1
		
		sA:CreateTestAuras()

		table.insert(UISpecialFrames, "sATest")
		table.insert(UISpecialFrames, "sATestDual")

end)

-- runtime only
sA = sA or { auraTimers = {}, learnCastTimers = {}, learnNew = {}, frames = {}, dualframes = {}, draggers = {} }
sA.SuperWoW = SetAutoloot and true or false
local _, playerGUID = UnitExists("player")
sA.playerGUID = playerGUID
sA.SettingsLoaded = nil

-- perf: cache globals we use a lot (Lua 5.0-safe)
local gsub   = string.gsub
local find   = string.find
local lower  = string.lower
local floor  = math.floor
local tinsert = table.insert
local getn   = table.getn
local GetTime = GetTime

-- message helper
sA.PREFIX = "|c194b7dccsimple|cffffffffAuras: "
function sA:Msg(msg)
  DEFAULT_CHAT_FRAME:AddMessage(self.PREFIX .. msg)
end

---------------------------------------------------
-- Helper Functions
---------------------------------------------------

local function GetAuraDurationBySpellID(spellID, casterGUID)
  if not spellID or not casterGUID then return nil end
  if type(simpleAuras.auradurations[spellID]) ~= "table" then
	simpleAuras.auradurations[spellID] = nil
	return nil
  end
  return simpleAuras.auradurations[spellID][casterGUID]
end

local function getAuraID(spellName)
    local auraFound = {}
    for auraID, aura in ipairs(simpleAuras.auras) do
        if aura.name == spellName then
            table.insert(auraFound, auraID)
        end
    end
    if getn(auraFound) > 0 then
        return auraFound
    else
        return {}
    end
end

-- SuperWoW: learn and track aura durations
if sA.SuperWoW then
  local sADuration = CreateFrame("Frame")
  sADuration:RegisterEvent("RAW_COMBATLOG")
  sADuration:RegisterEvent("UNIT_CASTEVENT")
  sADuration:SetScript("OnEvent", function()
    local timestamp = GetTime()

    if event == "RAW_COMBATLOG" and simpleAuras.auradurations then
      local raw = arg2
      if not raw or not find(raw, "fades from") then return end

      local _, _, spellName  = string.find(raw, "^(.-) fades from ")
      local _, _, targetGUID = string.find(raw, "from (.-).$")

      if lower(targetGUID or "") == "you" then _, targetGUID = UnitExists("player") end
      targetGUID = gsub(targetGUID or "", "^0x", "")
      if not spellName or targetGUID == "" then return end
      if not sA.auraTimers[targetGUID] then return end

      for spellID in pairs(sA.auraTimers[targetGUID]) do
        local n = SpellInfo(spellID)
        if n then
          n = gsub(n, "%s*%(%s*Rank%s+%d+%s*%)", "")
          if n == spellName then
            -- if we were learning this duration, compute actual
			
            if sA.learnCastTimers[targetGUID] and sA.learnCastTimers[targetGUID][spellID] and sA.learnCastTimers[targetGUID][spellID].duration then
              local castTime = sA.learnCastTimers[targetGUID][spellID].duration
              local actual   = timestamp - castTime
			  local casterGUID = sA.learnCastTimers[targetGUID][spellID].castby
			  simpleAuras.auradurations[spellID] = simpleAuras.auradurations[spellID] or {}
              simpleAuras.auradurations[spellID][casterGUID] = floor(actual + 0.5)
			  sA.learnNew[spellID] = nil
              if simpleAuras.updating == 1 then
                sA:Msg("Updated " .. spellName .. " (ID:"..spellID..") to: " .. floor(actual + 0.5) .. "s")
              elseif simpleAuras.showlearning == 1 then
				sA:Msg("Learned " .. spellName .. " (ID:"..spellID..") duration: " .. floor(actual + 0.5) .. "s")
			  end
              sA.learnCastTimers[targetGUID][spellID].duration = nil
              sA.learnCastTimers[targetGUID][spellID].castby = nil
            end
			
			if sA.auraTimers[targetGUID][spellID].duration <= timestamp then
				sA.auraTimers[targetGUID][spellID] = nil
			end
			
            if not next(sA.auraTimers[targetGUID]) then
              sA.auraTimers[targetGUID] = nil
            end
            break
          end
        end
      end

    elseif event == "UNIT_CASTEVENT" and simpleAuras.auradurations then
      local casterGUID, targetGUID, evType, spellID = arg1, arg2, arg3, arg4
      if evType ~= "CAST" or not spellID then return end
	  
      local spellName = SpellInfo(spellID)
	  local auraIDs = getAuraID(spellName)

	  if ((auraIDs and getn(auraIDs) > 0) or simpleAuras.learnall == 1) and spellID then

		  if sA.playerGUID then
			sA.playerGUID = gsub(sA.playerGUID, "^0x", "")
		  else
			local _, playerGUID = UnitExists("player")
			sA.playerGUID = playerGUID
		  end
		  
		  casterGUID = gsub(casterGUID or "", "^0x", "")
		  if targetGUID then targetGUID = gsub(targetGUID, "^0x", "") end

		  local dur = GetAuraDurationBySpellID(spellID,casterGUID)
	  
		  if dur and dur > 0 and simpleAuras.updating == 0 and casterGUID == sA.playerGUID then
			sA.auraTimers[targetGUID] = sA.auraTimers[targetGUID] or {}
			sA.auraTimers[targetGUID][spellID] = sA.auraTimers[targetGUID][spellID] or {}
			if not sA.auraTimers[targetGUID][spellID].duration or (dur + timestamp) > sA.auraTimers[targetGUID][spellID].duration then
				sA.auraTimers[targetGUID][spellID].duration = timestamp + dur
				sA.auraTimers[targetGUID][spellID].castby = casterGUID
			end
			sA.learnNew[spellID] = nil
		  elseif casterGUID == sA.playerGUID then

			local showLearn = nil
						
			if not targetGUID or targetGUID == "" then targetGUID = sA.playerGUID end
			
			sA.learnCastTimers[targetGUID] = sA.learnCastTimers[targetGUID] or {}
			sA.learnCastTimers[targetGUID][spellID] = sA.learnCastTimers[targetGUID][spellID] or {}
			sA.learnCastTimers[targetGUID][spellID].duration = timestamp
			sA.learnCastTimers[targetGUID][spellID].castby = casterGUID
			
			sA.auraTimers[targetGUID] = sA.auraTimers[targetGUID] or {}
			sA.auraTimers[targetGUID][spellID] = sA.auraTimers[targetGUID][spellID] or {}
			sA.auraTimers[targetGUID][spellID].duration = 0
			sA.auraTimers[targetGUID][spellID].castby = casterGUID
									
			for _, auraID in ipairs(auraIDs) do
				if simpleAuras.auras[auraID].unit ~= "Player" and simpleAuras.auras[auraID].type ~= "Cooldown" then
					showLearn = true
					break
				end
			end
						
			if showLearn and casterGUID == sA.playerGUID and targetGUID ~= sA.playerGUID then
				sA.learnNew[spellID] = 1
			end
			
			if simpleAuras.updating == 1 then
			  sA:Msg("Updating " .. (spellName or spellID) .. " (ID:"..spellID..")...")
			elseif simpleAuras.showlearning == 1 then
			  sA:Msg("Learning " .. (spellName or spellID) .. " (ID:"..spellID..")...")
			end
			
		  end
		  
	  end
	  
    end
  end)
end

---------------------------------------------------
-- Event-Driven State Tracking
---------------------------------------------------
-- Track combat/raid/party/target state changes with events instead of polling

sA.gameState = {
  inCombat = false,
  inRaid = false,
  inParty = false,
  hasTarget = false,
  needsUpdate = true  -- Flag to trigger update on state change
}

local sAStateTracker = CreateFrame("Frame")
sAStateTracker:RegisterEvent("PLAYER_REGEN_DISABLED")
sAStateTracker:RegisterEvent("PLAYER_REGEN_ENABLED")
sAStateTracker:RegisterEvent("RAID_ROSTER_UPDATE")
sAStateTracker:RegisterEvent("PARTY_MEMBERS_CHANGED")
sAStateTracker:RegisterEvent("PLAYER_TARGET_CHANGED")
sAStateTracker:SetScript("OnEvent", function()
  if event == "PLAYER_REGEN_DISABLED" then
    sA.gameState.inCombat = true
    sA.gameState.needsUpdate = true
    sAinCombat = true
  elseif event == "PLAYER_REGEN_ENABLED" then
    sA.gameState.inCombat = false
    sA.gameState.needsUpdate = true
    sAinCombat = nil
  elseif event == "RAID_ROSTER_UPDATE" then
    local wasInRaid = sA.gameState.inRaid
    sA.gameState.inRaid = UnitInRaid("player")
    if wasInRaid ~= sA.gameState.inRaid then
      sA.gameState.needsUpdate = true
    end
  elseif event == "PARTY_MEMBERS_CHANGED" then
    local wasInParty = sA.gameState.inParty
    sA.gameState.inParty = GetNumPartyMembers() > 0 and not sA.gameState.inRaid
    if wasInParty ~= sA.gameState.inParty then
      sA.gameState.needsUpdate = true
    end
  elseif event == "PLAYER_TARGET_CHANGED" then
    local hadTarget = sA.gameState.hasTarget
    sA.gameState.hasTarget = UnitExists("target")
    if hadTarget ~= sA.gameState.hasTarget then
      sA.gameState.needsUpdate = true
    end
  end
end)

---------------------------------------------------
-- Throttled OnUpdate (only for what we can't event-ize)
---------------------------------------------------
-- This still needs OnUpdate for:
-- 1. Duration countdowns
-- 2. Move mode detection (key states)
-- 3. Buff/debuff scanning (no events for buff changes)

local sAEvent = CreateFrame("Frame", "sAEvent", UIParent)

-- Cache UI scale
local cachedUIScale = 1
local cacheScaleTime = 0
local SCALE_CACHE_INTERVAL = 1

-- Key check throttling
local lastKeyCheckTime = 0
local KEY_CHECK_INTERVAL = 0.1

sAEvent:SetScript("OnUpdate", function()

	local time = GetTime()
	local refreshRate = 1 / (simpleAuras.refresh or 5)
	if (time - (sAEvent.lastUpdate or 0)) < refreshRate then return end
	
  -- Cache the UI scale less frequently
  if (time - cacheScaleTime) >= SCALE_CACHE_INTERVAL then
    cachedUIScale = UIParent:GetEffectiveScale()
    sA.uiScale = cachedUIScale
    cacheScaleTime = time
  end

  -- Only check keys periodically for move mode
  if (time - lastKeyCheckTime) >= KEY_CHECK_INTERVAL then
    lastKeyCheckTime = time
    
    -- Handle Move Mode with Ctrl Key
    local mainFrame = _G["sAGUI"]
    if mainFrame and mainFrame:IsVisible() and IsControlKeyDown() and IsAltKeyDown() and IsShiftKeyDown() then

  	if sA.moveAuras ~= 1 then
  			
  		-- TestAura
  		if sA.TestAura and sA.TestAura:IsVisible() then
  			
  			sA.draggers[0]:Show()
  			gui:SetAlpha(0)
  			gui.editor:SetAlpha(0)
  			
  		else
  	  
  			-- Continuously show draggers for any visible frames while in move mode
  			for id, frame in pairs(sA.frames) do
  			  if frame:IsVisible() and sA.draggers[id] then
  				sA.draggers[id]:Show()
  				gui:SetAlpha(0)
  				if gui.editor then
  				  gui.editor:SetAlpha(0)
  				end
  			  end
  			end
  			
  		end

  		sA.moveAuras = 1

  	end
  	
    else

  	if sA.moveAuras == 1 then
  				
  		-- Hide all draggers when not in move mode
  	    for id, dragger in pairs(sA.draggers) do
  	      if dragger then
  			dragger:Hide()
  	        gui:SetAlpha(1)
  			if gui.editor then
  	          gui.editor:SetAlpha(1)
  			end
  		  end
  	    end
  		
  		-- Reload data if in editor
  		if gui.editor and gui.auraEdit and sA.draggers[0] and sA.draggers[0]:IsVisible() then
  			
  			sA:SaveAura(gui.auraEdit)
  			
  		end

  		sA.moveAuras = 0

  	end
  	
    end
  end
		
  sAEvent.lastUpdate = time
  
  -- Call UpdateAuras - this still needs to run on a timer for duration countdowns
  -- and buff/debuff scanning (since there's no event for those)
  sA:UpdateAuras()
		
end)

---------------------------------------------------
-- Slash Commands
---------------------------------------------------
SLASH_sA1 = "/sa"
SLASH_sA2 = "/simpleauras"
SlashCmdList["sA"] = function(msg)

	-- Get Command
	if type(msg) ~= "string" then
		msg = ""
	end

	-- Get Command Arguments
	local cmd, val
	local s, e, a, b, c = string.find(msg, "^(%S+)%s*(%S*)%s*(%S*)$")
	if a then cmd = a else cmd = "" end
	if b then val = b else val = "" end
	if c then fad = c else fad = "" end
	
	-- hide / show or no command
	if cmd == "" or cmd == "show" or cmd == "hide" then
		if gui.auraEdit then gui.auraEdit = nil end
		if cmd == "show" then
			if not gui:IsVisible() then gui:Show() end
		elseif cmd == "hide" then
			if gui:IsVisible() then gui:Hide() sA.TestAura:Hide() sA.TestAuraDual:Hide() end
		else 
			if gui:IsVisible() then gui:Hide() sA.TestAura:Hide() sA.TestAuraDual:Hide() else gui:Show() end
		end
		sA:RefreshAuraList()
		return
	end
	
	-- refresh command
	if cmd == "refresh" then
		local num = tonumber(val)
		if num and num >= 1 and num <= 10 then
			simpleAuras.refresh = num
			sA:Msg("Refresh set to " .. num .. " times per second")
		else
			sA:Msg("Usage: /sa refresh X - set refresh rate. (1 to 10 updates per second. Default: 5).")
			sA:Msg("Current refresh = " .. simpleAuras.refresh .. " times per second.")
		end
		return
	end
	
	-- learnall command
	if cmd == "learnall" then
		if sA.SuperWoW then
			local num = tonumber(val)
			if num and (num == 0 or num == 1) then
				simpleAuras.learnall = num
				sA:Msg("LearnAll set to " .. num)
			else
				sA:Msg("Usage: /sa learnall X - learn all AuraDurations, even if no Aura is set up. (1 = Active. Default: 0).")
				sA:Msg("Current LearnAll status = " .. simpleAuras.learnall)
			end
		else
			sA:Msg("/sa showlearning needs SuperWoW to be installed!")
		end
		return
	end
	
	-- refresh command
	if cmd == "update" or cmd == "relearn" then
		local num = tonumber(val)
		if num and (num == 0 or num == 1) then
			simpleAuras.updating = num
			sA:Msg("Aura durations update status set to " .. num)
		else
			sA:Msg("Usage: /sa update X - force aura durations updates (1 = re-learn aura durations. Default: 0).")
			sA:Msg("Current update status = " .. simpleAuras.updating)
		end
		return
	end
	
	-- manual learning of durations
	if cmd == "learn" then
		if sA.SuperWoW then
			local spell = tonumber(val)
			local fade = tonumber(fad)
			if spell and fade then
				local _, playerGUID = UnitExists("player")
				playerGUID = gsub(playerGUID, "^0x", "")
				simpleAuras.auradurations[spell] = simpleAuras.auradurations[spell] or {}
				simpleAuras.auradurations[spell][playerGUID] = fade
				sA:Msg("Set Duration of "..SpellInfo(spell).."("..spell..") to " .. fade .. " seconds.")
			else
				sA:Msg("Usage: /sa learn X Y - manually set duration Y of spellID X.")
			end
		else
			sA:Msg("/sa learn needs SuperWoW to be installed!")
		end
		return
	end
	
	-- track others
	if cmd == "showlearning" then
		if sA.SuperWoW then
			local num = tonumber(val)
			if num and (num == 0 or num == 1) then
				simpleAuras.showlearning = num
				sA:Msg("ShowLearning status set to " .. num)
			else
				sA:Msg("Usage: /sa showlearning X - shows learning of new AuraDurations in chat (1 = show. Default: 0).")
				sA:Msg("Current ShowLearning status = " .. simpleAuras.showlearning)
			end
			return
		else
			sA:Msg("/sa showlearning needs SuperWoW to be installed!")
		end
		return
	end
	
	-- delete
	if cmd == "forget" or cmd == "unlearn" or cmd == "delete" then
		if sA.SuperWoW then
			local arg = val
			if val and val == "all" then
				simpleAuras.auradurations = {}
				sA:Msg("Forgot all learned AuraDurations.")
			elseif val then
				local val = tonumber(val)
				if simpleAuras.auradurations[val] and type(simpleAuras.auradurations[val]) == "table" then
					simpleAuras.auradurations[val] = nil
					sA:Msg("Forgot learned AuraDuration for " .. SpellInfo(val) .. " (ID:"..val..").")
				else
					sA:Msg("No learned AuraDuration for SpellID " .. val.. ".")
				end
			else
				sA:Msg("Usage: /sa forget X - forget AuraDuration of SpellID X (or use 'all' instead to delete all durations).")
			end
		else
			sA:Msg("/sa forget needs SuperWoW to be installed!")
		end
		return
	end
	

	-- help or unknown command fallback
	sA:Msg("Usage:")
	sA:Msg("/sa or /sa show or /sa hide - show/hide simpleAuras Settings.")
	sA:Msg("/sa refresh X - set refresh rate. (1 to 10 updates per second. Default: 5).")
	if sA.SuperWoW then
		sA:Msg("/sa learn X Y - manually set duration Y of spellID X.")
		sA:Msg("/sa forget X - forget AuraDuration of SpellID X (or use 'all' instead to delete all durations).")
		sA:Msg("/sa update X - force AuraDurations updates (1 = re-learn aura durations. Default: 0).")
		sA:Msg("/sa showlearning X - shows learning of new AuraDurations in chat (1 = show. Default: 0).")
		sA:Msg("/sa learnall X - learn all AuraDurations, even if no Aura is set up. (1 = Active. Default: 0).")
	end

end
