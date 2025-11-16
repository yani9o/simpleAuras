-- Utility: skin frame with backdrop
function sA:SkinFrame(frame, bg, border)
  frame:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8x8", edgeFile = "Interface\\Buttons\\WHITE8x8", edgeSize = 1 })
  local bgr = bg or {0.1, 0.1, 0.1, 0.95}
  local bdr = border or {0, 0, 0, 1}
  frame:SetBackdropColor(bgr[1], bgr[2], bgr[3], bgr[4] or 1)
  frame:SetBackdropBorderColor(bdr[1], bdr[2], bdr[3], bdr[4] or 1)
end

-- Deep copy helper
local function deepCopy(tbl)
  local t = {}
  for k, v in pairs(tbl) do
    t[k] = (type(v) == "table") and deepCopy(v) or v
  end
  return t
end

-- Create Test frames (used by editor preview)
function sA:CreateTestAuras()

	if not sA.SettingsLoaded then return end

	if sA.TestAura then sA.TestAura:Hide() sA.TestAura = nil end
	if sA.TestAuraDual then sA.TestAuraDual:Hide() sA.TestAuraDual = nil end
	if sA.draggers[0] then sA.draggers[0]:Hide() sA.draggers[0] = nil end

	local TestAura = CreateFrame("Frame", "sATest", UIParent)
	TestAura:SetFrameStrata("BACKGROUND")
	TestAura:SetFrameLevel(128)
	TestAura.texture = TestAura:CreateTexture(nil, "ARTWORK")
	TestAura.texture:SetAllPoints(TestAura)
	TestAura.durationtext = TestAura:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	TestAura.durationtext:SetFont("Fonts\\FRIZQT__.TTF", 12, "OUTLINE")
	TestAura.durationtext:SetPoint("CENTER", TestAura, "CENTER", 0, 0)
	TestAura.stackstext = TestAura:CreateFontString(nil, "OVERLAY", "GameFontWhite")
	TestAura.stackstext:SetFont("Fonts\\FRIZQT__.TTF", 10, "OUTLINE")
	TestAura.stackstext:SetPoint("TOPLEFT", TestAura.durationtext, "CENTER", 1, -6)
	TestAura:Hide()

	local dragger = CreateFrame("Frame", "sADragger" .. 0, TestAura)
	dragger:SetAllPoints(TestAura)
	dragger:SetFrameStrata("HIGH")
	dragger:EnableMouse(true)
	dragger:RegisterForDrag("LeftButton")
	dragger:SetBackdrop({edgeFile = "Interface\\Buttons\\WHITE8x8",edgeSize = 1,})
	dragger:SetBackdropBorderColor(0, 1, 0, 0.5) -- Green, semi-transparent

	dragger:SetScript("OnDragStart", function(self)
		TestAura:SetMovable(true)
		TestAura:StartMoving()
	end)

	dragger:SetScript("OnDragStop", function(self)
		TestAura:SetMovable(false)
		TestAura:StopMovingOrSizing()
		
		local frameX, frameY = TestAura:GetCenter()
		local screenWidth, screenHeight = GetScreenWidth(), GetScreenHeight()
		
		local offsetX = frameX - (screenWidth / 2)
		local offsetY = frameY - (screenHeight / 2)
	
		offsetX = math.floor(offsetX + 0.5)
		offsetY = math.floor(offsetY + 0.5)
		
		simpleAuras.auras[gui.auraEdit].xpos = offsetX
		simpleAuras.auras[gui.auraEdit].ypos = offsetY
		
		gui.editor.x:SetText(offsetX)
		gui.editor.y:SetText(offsetY)
		
		sA.frames[gui.auraEdit] = nil
		sA.draggers[gui.auraEdit] = nil
		if sA.TestAuraDual and sA.TestAuraDual:IsVisible() then
			sA.TestAuraDual:SetPoint("CENTER", UIParent, "CENTER", -(offsetX), offsetY)
		end

	end)

	sA.TestAura = TestAura
	dragger:Hide()
	sA.draggers[0] = dragger
	
	local TestAuraDual = CreateFrame("Frame", "sATestDual", UIParent)
	TestAuraDual:SetFrameStrata("BACKGROUND")
	TestAuraDual:SetFrameLevel(128)
	TestAuraDual.texture = TestAuraDual:CreateTexture(nil, "ARTWORK")
	TestAuraDual.texture:SetAllPoints(TestAuraDual)
	TestAuraDual.durationtext = TestAuraDual:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	TestAuraDual.durationtext:SetFont("Fonts\\FRIZQT__.TTF", 12, "OUTLINE")
	TestAuraDual.durationtext:SetPoint("CENTER", TestAuraDual, "CENTER", 0, 0)
	TestAuraDual.stackstext = TestAuraDual:CreateFontString(nil, "OVERLAY", "GameFontWhite")
	TestAuraDual.stackstext:SetFont("Fonts\\FRIZQT__.TTF", 10, "OUTLINE")
	TestAuraDual.stackstext:SetPoint("TOPLEFT", TestAuraDual.durationtext, "CENTER", 1, -6)
	TestAuraDual:Hide()
	sA.TestAuraDual = TestAuraDual
	
end

-- Main GUI frame
if not gui then
  gui = CreateFrame("Frame", "sAGUI", UIParent)
  gui:SetFrameStrata("HIGH")
  gui:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
  gui:SetWidth(300)
  gui:SetHeight(450)
  gui:SetMovable(true)
  gui:EnableMouse(true)
  gui:RegisterForDrag("LeftButton")
  gui:SetScript("OnDragStart", function() gui:StartMoving() end)
  gui:SetScript("OnDragStop", function() gui:StopMovingOrSizing() end)
  sA:SkinFrame(gui)

  local title = gui:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  title:SetPoint("TOP", 0, -5)
  title:SetText("simpleAuras v" .. (sA.VERSION or "1.0"))

  -- ScrollFrame for aura list
  gui.scrollFrame = CreateFrame("ScrollFrame", "sAGUIScrollFrame", gui)
  gui.scrollFrame:SetPoint("TOPLEFT", 20, -30)
  gui.scrollFrame:SetPoint("BOTTOMRIGHT", -20, 10)
  
  -- Content frame (holds the aura rows)
  gui.scrollContent = CreateFrame("Frame", "sAGUIScrollContent", gui.scrollFrame)
  gui.scrollContent:SetWidth(260)
  gui.scrollContent:SetHeight(1) -- Will be adjusted dynamically
  gui.scrollFrame:SetScrollChild(gui.scrollContent)
  
  -- MouseWheel support
  gui.scrollFrame:EnableMouseWheel(true)
  gui.scrollFrame:SetScript("OnMouseWheel", function()
    local scroll = gui.scrollFrame:GetVerticalScroll()
    local maxScroll = gui.scrollContent:GetHeight() - gui.scrollFrame:GetHeight()
    if maxScroll < 0 then maxScroll = 0 end
    
    local delta = arg1 or 0
    local newScroll = scroll - (delta * 25) -- 25px per scroll step (one row)
    
    if newScroll < 0 then newScroll = 0 end
    if newScroll > maxScroll then newScroll = maxScroll end
    
    gui.scrollFrame:SetVerticalScroll(newScroll)
  end)

  gui:Hide()
  table.insert(UISpecialFrames, "sAGUI")
end

-- Add button
local addBtn = CreateFrame("Button", nil, gui)
addBtn:SetPoint("TOPLEFT", 2, -2)
addBtn:SetWidth(20)
addBtn:SetHeight(20)
sA:SkinFrame(addBtn, {0.2, 0.2, 0.2, 1})
addBtn.text = addBtn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
addBtn.text:SetPoint("CENTER", addBtn, "CENTER", 0, 0)
addBtn.text:SetText("+")
addBtn:SetFontString(addBtn.text)
addBtn:SetScript("OnClick", function() sA:AddAura() end)
addBtn:SetScript("OnEnter", function() addBtn:SetBackdropColor(0.1, 0.4, 0.1, 1) end)
addBtn:SetScript("OnLeave", function() addBtn:SetBackdropColor(0.2, 0.2, 0.2, 1) end)

-- Export All button
local exportAllBtn = CreateFrame("Button", nil, gui)
exportAllBtn:SetPoint("TOPLEFT", addBtn, "TOPRIGHT", 5, 0)
exportAllBtn:SetWidth(20)
exportAllBtn:SetHeight(20)
sA:SkinFrame(exportAllBtn, {0.2, 0.2, 0.2, 1})
exportAllBtn.text = exportAllBtn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
exportAllBtn.text:SetPoint("CENTER", exportAllBtn, "CENTER", 0, 0)
exportAllBtn.text:SetText("e")
exportAllBtn:SetScript("OnClick", function() sA:ExportAllAuras() end)
exportAllBtn:SetScript("OnEnter", function() exportAllBtn:SetBackdropColor(0.5, 0.5, 0.5, 1) end)
exportAllBtn:SetScript("OnLeave", function() exportAllBtn:SetBackdropColor(0.2, 0.2, 0.2, 1) end)

-- Import button
local importBtn = CreateFrame("Button", nil, gui)
importBtn:SetPoint("TOPLEFT", exportAllBtn, "TOPRIGHT", 5, 0)
importBtn:SetWidth(20)
importBtn:SetHeight(20)
sA:SkinFrame(importBtn, {0.2, 0.2, 0.2, 1})
importBtn.text = importBtn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
importBtn.text:SetPoint("CENTER", importBtn, "CENTER", 0, 0)
importBtn.text:SetText("i")
importBtn:SetScript("OnClick", function() sA:ShowImportFrame() end)
importBtn:SetScript("OnEnter", function() importBtn:SetBackdropColor(0.5, 0.5, 0.5, 1) end)
importBtn:SetScript("OnLeave", function() importBtn:SetBackdropColor(0.2, 0.2, 0.2, 1) end)

-- Close button
local closeBtn = CreateFrame("Button", nil, gui)
closeBtn:SetPoint("TOPRIGHT", -2, -2)
closeBtn:SetWidth(20)
closeBtn:SetHeight(20)
sA:SkinFrame(closeBtn, {0.2, 0.2, 0.2, 1})
closeBtn.text = closeBtn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
closeBtn.text:SetPoint("CENTER", 0.5, 1)
closeBtn.text:SetText("x")
closeBtn:SetFontString(closeBtn.text)
closeBtn:SetScript("OnClick", function()
  gui:Hide()
  if sA.TestAura then sA.TestAura:Hide() end
  if sA.TestAuraDual then sA.TestAuraDual:Hide() end
end)
closeBtn:SetScript("OnEnter", function() closeBtn:SetBackdropColor(0.5, 0.5, 0.5, 1) end)
closeBtn:SetScript("OnLeave", function() closeBtn:SetBackdropColor(0.2, 0.2, 0.2, 1) end)

-- Refresh list of configured auras
function sA:RefreshAuraList()

  if not sA.SettingsLoaded then return end

  -- hide old rows
  for _, entry in ipairs(gui.list or {}) do entry:Hide() end
  gui.list = {}

  if not simpleAuras or not simpleAuras.auras then return end

  local totalAuras = table.getn(simpleAuras.auras)
  
  -- Update scroll content height based on number of auras
  local contentHeight = totalAuras * 25 + 5
  gui.scrollContent:SetHeight(contentHeight)

  for i, aura in ipairs(simpleAuras.auras) do
    local id = i
    local row = CreateFrame("Button", nil, gui.scrollContent)
    row:SetWidth(260)
    row:SetHeight(20)
    row:SetPoint("TOPLEFT", 0, -(id - 1) * 25)
    row:SetFrameStrata("HIGH")
    sA:SkinFrame(row, {0.2, 0.2, 0.2, 1})

    row:EnableMouse(true)
    row:SetMovable(true)
    row:RegisterForDrag("LeftButton")

    -- store index (avoid closed-over 'aura')
    row.auraId = id

    -- drag start: move the row
    row:SetScript("OnDragStart", function()
      row:StartMoving()
      row:SetFrameStrata("DIALOG")
      row:SetClampedToScreen(true)
    end)

    -- drag stop: compute drop index using cursor Y and scroll content, then reorder table
    row:SetScript("OnDragStop", function()
      row:StopMovingOrSizing()
      row:SetFrameStrata("HIGH")

      -- get cursor position in frame coordinates
      local _, cursorY = GetCursorPosition()
      local scale = row:GetEffectiveScale() or gui:GetEffectiveScale() or 1
      cursorY = cursorY / scale

      local contentTop = gui.scrollContent:GetTop()
      if not contentTop then
        sA:RefreshAuraList()
        return
      end

      -- Get current scroll position
      local scrollOffset = gui.scrollFrame:GetVerticalScroll()
      
      -- relative offset from content top to cursor (including scroll)
      local offsetFromTop = (contentTop - cursorY) + scrollOffset

      -- rows have spacing 25 px per row; compute target index
      local targetIndex = math.floor(offsetFromTop / 25) + 1

      -- clamp
      local total = table.getn(simpleAuras.auras)
      if targetIndex < 1 then targetIndex = 1 end
      if targetIndex > total then targetIndex = total end

      local fromIndex = row.auraId
      if fromIndex and fromIndex ~= targetIndex then
        local moved = table.remove(simpleAuras.auras, fromIndex)
        table.insert(simpleAuras.auras, targetIndex, moved)
      end

      -- rebuild list and reopen editor for moved aura (now at targetIndex)
      sA:RefreshAuraList()
      if gui.editor then
        if sA.TestAura then sA.TestAura:Hide() end
        if sA.TestAuraDual then sA.TestAuraDual:Hide() end
        gui.editor:Hide()
        gui.editor = nil
        if fromIndex and fromIndex ~= targetIndex then
          sA:EditAura(targetIndex)
        end
      end
    end)

    -- hover colors (lookup current aura at runtime to avoid nil indexing)
    row:SetScript("OnEnter", function()
      row:SetBackdropColor(0.5, 0.5, 0.5, 1)
    end)

    row:SetScript("OnLeave", function()
      local current = simpleAuras and simpleAuras.auras and simpleAuras.auras[row.auraId]
      if gui.auraEdit == row.auraId then
        row:SetBackdropColor(0.5, 0.5, 0.5, 1)
      elseif current and current.enabled == 0 then
        row:SetBackdropColor(0.4, 0.1, 0.1, 1)
      else
        row:SetBackdropColor(0.2, 0.2, 0.2, 1)
      end
    end)

    -- label
    row.text = row:CreateFontString(nil, "ARTWORK", "GameFontWhite")
    row.text:SetPoint("LEFT", 5, 0)
    row.text:SetText("[" .. id .. "] " .. (aura.name ~= "" and aura.name or "<unnamed>"))
    row.text:SetTextColor(unpack(aura.auracolor or {1, 1, 1}))

    -- initial backdrop state
    if gui.auraEdit == id then
      row:SetBackdropColor(0.5, 0.5, 0.5, 1)
    elseif aura.enabled == 0 then
      row:SetBackdropColor(0.4, 0.1, 0.1, 1)
    end

    -- click to edit
    row:SetScript("OnClick", function()
      if gui.editor then
        if sA.TestAura then sA.TestAura:Hide() end
        if sA.TestAuraDual then sA.TestAuraDual:Hide() end
        gui.editor:Hide()
        gui.editor = nil
      end
      sA:CreateTestAuras()
      sA:EditAura(id)
    end)

    -- up button (swap with previous)
    if id > 1 then
      local up = CreateFrame("Button", nil, row)
      up:SetWidth(15)
      up:SetHeight(15)
      up:SetPoint("RIGHT", row, "RIGHT", -19, 0)
      sA:SkinFrame(up, {0.15, 0.15, 0.15, 1})
      up.text = up:CreateFontString(nil, "OVERLAY", "GameFontWhite")
      up.text:SetFont("Fonts\\FRIZQT__.TTF", 24)
      up.text:SetPoint("CENTER", up, "CENTER", -1, -8)
      up.text:SetText("ˆ")
      up:SetFontString(up.text)
      up:SetScript("OnEnter", function() up:SetBackdropColor(0.5, 0.5, 0.5, 1) end)
      up:SetScript("OnLeave", function() up:SetBackdropColor(0.2, 0.2, 0.2, 1) end)
      up:SetScript("OnClick", function()
        simpleAuras.auras[id], simpleAuras.auras[id - 1] = simpleAuras.auras[id - 1], simpleAuras.auras[id]
        sA:RefreshAuraList()
        if gui.editor then
          if sA.TestAura then sA.TestAura:Hide() end
          if sA.TestAuraDual then sA.TestAuraDual:Hide() end
          gui.editor:Hide()
          gui.editor = nil
          sA:EditAura(id - 1)
        end
      end)
    end

    -- down button (swap with next)
    if id < table.getn(simpleAuras.auras) then
      local down = CreateFrame("Button", nil, row)
      down:SetWidth(15)
      down:SetHeight(15)
      down:SetPoint("RIGHT", row, "RIGHT", -2, 0)
      sA:SkinFrame(down, {0.15, 0.15, 0.15, 1})
      down.text = down:CreateFontString(nil, "OVERLAY", "GameFontWhite")
      down.text:SetFont("Fonts\\FRIZQT__.TTF", 24)
      down.text:SetPoint("CENTER", down, "CENTER", -1, -8)
      down.text:SetText("ˇ")
      down:SetFontString(down.text)
      down:SetScript("OnEnter", function() down:SetBackdropColor(0.5, 0.5, 0.5, 1) end)
      down:SetScript("OnLeave", function() down:SetBackdropColor(0.2, 0.2, 0.2, 1) end)
      down:SetScript("OnClick", function()
        simpleAuras.auras[id], simpleAuras.auras[id + 1] = simpleAuras.auras[id + 1], simpleAuras.auras[id]
        sA:RefreshAuraList()
        if gui.editor then
          if sA.TestAura then sA.TestAura:Hide() end
          if sA.TestAuraDual then sA.TestAuraDual:Hide() end
          gui.editor:Hide()
          gui.editor = nil
          sA:EditAura(id + 1)
        end
      end)
    end

    gui.list[id] = row
  end

end

-- Save aura data from editor
function sA:SaveAura(id)
  local ed = gui.editor
  if not ed then return end
  local data = simpleAuras.auras[id]
  data.name            = ed.name:GetText()
  data.enabled         = ed.enabled.value
  data.layer           = tonumber(ed.layer:GetText()) or 0
  if sA.SuperWoW then
	data.myCast          = ed.myCast.value
  end
  data.auracolor       = ed.auracolor
  data.autodetect      = ed.autoDetect.value
  data.texture         = ed.texturePath:GetText()
  data.scale           = tonumber(ed.scale:GetText())
  data.xpos            = tonumber(ed.x:GetText())
  data.ypos            = tonumber(ed.y:GetText())
  data.duration        = ed.duration.value
  data.stacks          = ed.stacks.value
  data.durationSize    = tonumber(ed.durationSize:GetText()) or 20
  data.stacksSize      = tonumber(ed.stacksSize:GetText()) or 14
  data.lowduration     = ed.lowduration.value
  data.lowdurationvalue= tonumber(ed.lowdurationvalue:GetText())
  data.lowdurationcolor= ed.lowdurationcolor
  data.type            = ed.typeButton.text:GetText()
  data.unit            = ed.unitButton.text:GetText()
  data.showCD          = ed.showCD.text:GetText()
  data.equipped        = ed.equipped.value
  data.inCombat        = ed.inCombat.value
  data.outCombat       = ed.outCombat.value
  data.inRaid          = ed.inRaid.value
  data.inParty         = ed.inParty.value
  data.invert          = ed.invert.value
  data.dual            = ed.dual.value

  ed.name:ClearFocus()
  ed.layer:ClearFocus()
  ed.texturePath:ClearFocus()
  ed.scale:ClearFocus()
  ed.x:ClearFocus()
  ed.y:ClearFocus()
  ed.lowdurationvalue:ClearFocus()
  ed.durationSize:ClearFocus()
  ed.stacksSize:ClearFocus()

  if sA.TestAura then sA.TestAura:Hide() end
  if sA.TestAuraDual then sA.TestAuraDual:Hide() end
  ed:Hide()
  gui.editor = nil
  gui.auraEdit = nil
  sA:EditAura(id)
  
end

-- Add new aura (optionally copy from existing)
function sA:AddAura(copyId)
  table.insert(simpleAuras.auras, {})
  local newId = table.getn(simpleAuras.auras)
  if copyId and simpleAuras.auras[copyId] then
    simpleAuras.auras[newId] = deepCopy(simpleAuras.auras[copyId])
  else
    simpleAuras.auras[newId] = {["enabled"]=1,["layer"]=0,["myCast"]=1,["name"]="",["auracolor"]={[1]=1,[2]=1,[3]=1,[4]=1},["autodetect"]=0,["texture"]="Interface\\Icons\\INV_Misc_QuestionMark",["scale"]=1,["xpos"]=0,["ypos"]=0,["duration"]=0,["stacks"]=0,["durationSize"]=20,["stacksSize"]=14,["type"]="Buff",["unit"]="Player",["showCD"]="Always",["equipped"]=0,["lowduration"]=0,["lowdurationcolor"]={[1]=1,[2]=0,[3]=0,[4]=1},["lowdurationvalue"]=5,["inCombat"]=1,["outCombat"]=1,["inParty"]=0,["inRaid"]=0,["invert"]=0,["dual"]=0}
  end
  if gui.editor and gui.editor:IsShown() then
    gui.editor:Hide()
    gui.editor = nil
    if sA.TestAura then sA.TestAura:Hide() end
    if sA.TestAuraDual then sA.TestAuraDual:Hide() end
  end
  sA:UpdateAuras()
  sA:EditAura(newId)
end

-- Editor window / show and build controls
function sA:EditAura(id)
  local aura = simpleAuras.auras[id]
  if not aura then return end
  gui.auraEdit = id
  sA.TestAura:SetMovable(false)

  local ed = gui.editor
  if not ed then
    ed = CreateFrame("Frame", "sAEdit", gui)
    ed:SetWidth(300)
    ed:SetHeight(450)
    ed:SetPoint("LEFT", gui, "RIGHT", 10, 0)
    sA:SkinFrame(ed)
    ed:SetMovable(true)
    ed:EnableMouse(true)
    ed:RegisterForDrag("LeftButton")
    ed:SetScript("OnDragStart", function() ed:StartMoving() end)
    ed:SetScript("OnDragStop", function() ed:StopMovingOrSizing() end)
    table.insert(UISpecialFrames, "sAEdit")

    ed.title = ed:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    ed.title:SetPoint("TOP", ed, "TOP", 0, -5)

    -- Enabled Checkbox
    ed.enabled = CreateFrame("Button", nil, ed)
    ed.enabled:SetWidth(16)
    ed.enabled:SetHeight(16)
    ed.enabled:SetPoint("TOPLEFT", ed, "TOPLEFT", 12.5, -35)
    sA:SkinFrame(ed.enabled, {0.15,0.15,0.15,1})
    ed.enabled:SetScript("OnEnter", function() ed.enabled:SetBackdropColor(0.5,0.5,0.5,1) end)
    ed.enabled:SetScript("OnLeave", function() ed.enabled:SetBackdropColor(0.15,0.15,0.15,1) end)
    ed.enabled.checked = ed.enabled:CreateTexture(nil, "OVERLAY")
    ed.enabled.checked:SetTexture("Interface\\Buttons\\WHITE8x8")
    ed.enabled.checked:SetVertexColor(1, 0.8, 0.06, 1)
    ed.enabled.checked:SetPoint("CENTER", ed.enabled, "CENTER", 0, 0)
    ed.enabled.checked:SetWidth(7)
    ed.enabled.checked:SetHeight(7)
    ed.enabled.value = 1
    ed.enabled:SetScript("OnClick", function(self)
      ed.enabled.value = 1 - (ed.enabled.value or 0)
      if ed.enabled.value == 1 then ed.enabled.checked:Show() else ed.enabled.checked:Hide() end
	  sA:SaveAura(id)
    end)
    ed.enabledLabel = ed:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    ed.enabledLabel:SetPoint("LEFT", ed.enabled, "RIGHT", 5, 0)
    ed.enabledLabel:SetText("Enabled")

    -- Layer input (frame stacking order)
    ed.layerLabel = ed:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    ed.layerLabel:SetPoint("LEFT", ed.enabledLabel, "RIGHT", 15, 0)
    ed.layerLabel:SetText("Layer:")
    
    ed.layer = CreateFrame("EditBox", nil, ed)
    ed.layer:SetPoint("LEFT", ed.layerLabel, "RIGHT", 5, 0)
    ed.layer:SetWidth(30)
    ed.layer:SetHeight(20)
    ed.layer:SetJustifyH("CENTER")
    ed.layer:SetMultiLine(false)
    ed.layer:SetAutoFocus(false)
    ed.layer:SetFontObject(GameFontHighlightSmall)
    ed.layer:SetTextColor(1,1,1)
    ed.layer:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8x8", edgeFile = "Interface\\Buttons\\WHITE8x8", edgeSize = 1 })
    ed.layer:SetBackdropColor(0.1,0.1,0.1,1)
    ed.layer:SetBackdropBorderColor(0,0,0,1)
    ed.layer:SetScript("OnEnterPressed", function() sA:SaveAura(id) end)

	if sA.SuperWoW then
		-- MyCast Checkbox
		ed.myCast = CreateFrame("Button", nil, ed)
		ed.myCast:SetWidth(16)
		ed.myCast:SetHeight(16)
		ed.myCast:SetPoint("LEFT", ed.layer, "RIGHT", 10, 0)
		sA:SkinFrame(ed.myCast, {0.15,0.15,0.15,1})
		ed.myCast:SetScript("OnEnter", function() ed.myCast:SetBackdropColor(0.5,0.5,0.5,1) end)
		ed.myCast:SetScript("OnLeave", function() ed.myCast:SetBackdropColor(0.15,0.15,0.15,1) end)
		ed.myCast.checked = ed.myCast:CreateTexture(nil, "OVERLAY")
		ed.myCast.checked:SetTexture("Interface\\Buttons\\WHITE8x8")
		ed.myCast.checked:SetVertexColor(1, 0.8, 0.06, 1)
		ed.myCast.checked:SetPoint("CENTER", ed.myCast, "CENTER", 0, 0)
		ed.myCast.checked:SetWidth(7)
		ed.myCast.checked:SetHeight(7)
		ed.myCast.value = 1
		ed.myCast:SetScript("OnClick", function(self)
		  ed.myCast.value = 1 - (ed.myCast.value or 0)
		  if ed.myCast.value == 1 then ed.myCast.checked:Show() else ed.myCast.checked:Hide() end
		  sA:SaveAura(id)
		end)
		ed.myCastLabel = ed:CreateFontString(nil, "OVERLAY", "GameFontNormal")
		ed.myCastLabel:SetPoint("LEFT", ed.myCast, "RIGHT", 5, 0)
		ed.myCastLabel:SetText("My Casts only")
	end
 
    -- Name
    ed.nameLabel = ed:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    ed.nameLabel:SetPoint("TOPLEFT", ed.enabled, "BOTTOMLEFT", 0, -15)
    ed.nameLabel:SetText("Aura Name:")
    ed.name = CreateFrame("EditBox", nil, ed)
    ed.name:SetPoint("LEFT", ed.nameLabel, "RIGHT", 5, 0)
    ed.name:SetWidth(198)
    ed.name:SetHeight(20)
    ed.name:SetMultiLine(false)
    ed.name:SetAutoFocus(false)
    ed.name:SetFontObject(GameFontHighlightSmall)
    ed.name:SetTextColor(1, 1, 1)
    ed.name:SetMaxLetters(100)
    ed.name:SetTextInsets(4, 4, 4, 4)
    ed.name:SetJustifyH("LEFT")
    ed.name:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8x8", edgeFile = "Interface\\Buttons\\WHITE8x8", edgeSize = 1 })
    ed.name:SetBackdropColor(0.1, 0.1, 0.1, 1)
    ed.name:SetBackdropBorderColor(0, 0, 0, 1)
    ed.name:SetScript("OnEnterPressed", function() sA:SaveAura(id) end)

    -- Separator
    local lineone = ed:CreateTexture(nil, "OVERLAY")
    lineone:SetTexture("Interface\\Buttons\\WHITE8x8")
    lineone:SetVertexColor(1, 0.8, 0.06, 1)
    lineone:SetPoint("TOPLEFT", ed.nameLabel, "BOTTOMLEFT", 0, -15)
    lineone:SetWidth(275)
    lineone:SetHeight(1)

    -- Texture label + color picker + autodetect
    ed.texLabel = ed:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    ed.texLabel:SetPoint("TOPLEFT", lineone, "BOTTOMLEFT", 0, -15)
    ed.texLabel:SetText("Icon/Texture:")

    ed.auracolorpicker = CreateFrame("Button", nil, ed)
    ed.auracolorpicker:SetWidth(24)
    ed.auracolorpicker:SetHeight(12)
    ed.auracolorpicker:SetPoint("LEFT", ed.texLabel, "RIGHT", 5, 0)
    sA:SkinFrame(ed.auracolorpicker, {1,1,1,1})
    ed.auracolorpicker.prev = ed.auracolorpicker:CreateTexture(nil, "OVERLAY")
    ed.auracolorpicker.prev:SetAllPoints(ed.auracolorpicker)

    -- Autodetect checkbox
    ed.autoDetect = CreateFrame("Button", nil, ed)
    ed.autoDetect:SetWidth(16)
    ed.autoDetect:SetHeight(16)
    ed.autoDetect:SetPoint("LEFT", ed.auracolorpicker, "RIGHT", 73, 0)
    sA:SkinFrame(ed.autoDetect, {0.15,0.15,0.15,1})
    ed.autoDetect:SetScript("OnEnter", function() ed.autoDetect:SetBackdropColor(0.5,0.5,0.5,1) end)
    ed.autoDetect:SetScript("OnLeave", function() ed.autoDetect:SetBackdropColor(0.15,0.15,0.15,1) end)
    ed.autoDetect.checked = ed.autoDetect:CreateTexture(nil, "OVERLAY")
    ed.autoDetect.checked:SetTexture("Interface\\Buttons\\WHITE8x8")
    ed.autoDetect.checked:SetVertexColor(1, 0.8, 0.06, 1)
    ed.autoDetect.checked:SetPoint("CENTER", ed.autoDetect, "CENTER", 0, 0)
    ed.autoDetect.checked:SetWidth(7)
    ed.autoDetect.checked:SetHeight(7)
    ed.autoDetect.value = 0
    ed.autoDetect:SetScript("OnClick", function(self)
      ed.autoDetect.value = 1 - (ed.autoDetect.value or 0)
      if ed.autoDetect.value == 1 then ed.autoDetect.checked:Show() else ed.autoDetect.checked:Hide() end
	  sA:SaveAura(id)
    end)

    ed.autoLabel = ed:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    ed.autoLabel:SetPoint("LEFT", ed.autoDetect, "RIGHT", 5, 1)
    ed.autoLabel:SetText("Autodetect")

    -- Texture input + browse
    ed.texturePath = CreateFrame("EditBox", nil, ed)
    ed.texturePath:SetPoint("TOPLEFT", ed.texLabel, "BOTTOMLEFT", 0, -10)
    ed.texturePath:SetWidth(200)
    ed.texturePath:SetHeight(20)
    ed.texturePath:SetMultiLine(false)
    ed.texturePath:SetAutoFocus(false)
    ed.texturePath:SetTextInsets(4, 4, 4, 4)
    ed.texturePath:SetFontObject(GameFontHighlightSmall)
    ed.texturePath:SetTextColor(1,1,1)
    ed.texturePath:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8x8", edgeFile = "Interface\\Buttons\\WHITE8x8", edgeSize = 1 })
    ed.texturePath:SetBackdropColor(0.1,0.1,0.1,1)
    ed.texturePath:SetBackdropBorderColor(0,0,0,1)
    ed.texturePath:SetScript("OnEnterPressed", function() sA:SaveAura(id) end)

    ed.browseBtn = CreateFrame("Button", nil, ed)
    ed.browseBtn:SetWidth(60)
    ed.browseBtn:SetHeight(20)
    ed.browseBtn:SetPoint("LEFT", ed.texturePath, "RIGHT", 15, 0)
    sA:SkinFrame(ed.browseBtn, {0.2,0.2,0.2,1})
    ed.browseBtn.text = ed.browseBtn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    ed.browseBtn.text:SetPoint("CENTER", ed.browseBtn, "CENTER", 0, 0)
    ed.browseBtn.text:SetText("Browse")
    ed.browseBtn:SetScript("OnEnter", function() ed.browseBtn:SetBackdropColor(0.5,0.5,0.5,1) end)
    ed.browseBtn:SetScript("OnLeave", function() ed.browseBtn:SetBackdropColor(0.2,0.2,0.2,1) end)

    -- Scale / position inputs
    ed.scaleLabel = ed:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    ed.scaleLabel:SetPoint("TOPLEFT", ed.texturePath, "TOPLEFT", 0, -30)
    ed.scaleLabel:SetText("Scale:")
    ed.scale = CreateFrame("EditBox", nil, ed)
    ed.scale:SetPoint("LEFT", ed.scaleLabel, "RIGHT", 5, 0)
    ed.scale:SetWidth(30)
    ed.scale:SetHeight(20)
	ed.scale:SetJustifyH("CENTER")
    ed.scale:SetMultiLine(false)
    ed.scale:SetAutoFocus(false)
    ed.scale:SetFontObject(GameFontHighlightSmall)
    ed.scale:SetTextColor(1,1,1)
    ed.scale:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8x8", edgeFile = "Interface\\Buttons\\WHITE8x8", edgeSize = 1 })
    ed.scale:SetBackdropColor(0.1,0.1,0.1,1)
    ed.scale:SetBackdropBorderColor(0,0,0,1)
    ed.scale:SetScript("OnEnterPressed", function() sA:SaveAura(id) end)

    ed.xLabel = ed:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    ed.xLabel:SetPoint("LEFT", ed.scale, "RIGHT", 28, 0)
    ed.xLabel:SetText("x pos:")
    ed.x = CreateFrame("EditBox", nil, ed)
    ed.x:SetPoint("LEFT", ed.xLabel, "RIGHT", 5, 0)
    ed.x:SetWidth(30)
    ed.x:SetHeight(20)
	ed.x:SetJustifyH("CENTER")
    ed.x:SetMultiLine(false)
    ed.x:SetAutoFocus(false)
    ed.x:SetFontObject(GameFontHighlightSmall)
    ed.x:SetTextColor(1,1,1)
    ed.x:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8x8", edgeFile = "Interface\\Buttons\\WHITE8x8", edgeSize = 1 })
    ed.x:SetBackdropColor(0.1,0.1,0.1,1)
    ed.x:SetBackdropBorderColor(0,0,0,1)
    ed.x:SetScript("OnEnterPressed", function() sA:SaveAura(id) end)

    ed.yLabel = ed:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    ed.yLabel:SetPoint("LEFT", ed.x, "RIGHT", 30, 0)
    ed.yLabel:SetText("y pos:")
    ed.y = CreateFrame("EditBox", nil, ed)
    ed.y:SetPoint("LEFT", ed.yLabel, "RIGHT", 5, 0)
    ed.y:SetWidth(30)
    ed.y:SetHeight(20)
	ed.y:SetJustifyH("CENTER")
    ed.y:SetMultiLine(false)
    ed.y:SetAutoFocus(false)
    ed.y:SetFontObject(GameFontHighlightSmall)
    ed.y:SetTextColor(1,1,1)
    ed.y:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8x8", edgeFile = "Interface\\Buttons\\WHITE8x8", edgeSize = 1 })
    ed.y:SetBackdropColor(0.1,0.1,0.1,1)
    ed.y:SetBackdropBorderColor(0,0,0,1)
    ed.y:SetScript("OnEnterPressed", function() sA:SaveAura(id) end)

    -- Duration / stacks checkboxes
    ed.duration = CreateFrame("Button", nil, ed)
    ed.duration:SetWidth(16)
    ed.duration:SetHeight(16)
    ed.duration:SetPoint("TOPLEFT", ed.scaleLabel, "BOTTOMLEFT", 0, -15)
    sA:SkinFrame(ed.duration, {0.15,0.15,0.15,1})
    ed.duration:SetScript("OnEnter", function() ed.duration:SetBackdropColor(0.5,0.5,0.5,1) end)
    ed.duration:SetScript("OnLeave", function() ed.duration:SetBackdropColor(0.15,0.15,0.15,1) end)
    ed.duration.checked = ed.duration:CreateTexture(nil, "OVERLAY")
    ed.duration.checked:SetTexture("Interface\\Buttons\\WHITE8x8")
    ed.duration.checked:SetVertexColor(1,0.8,0.06,1)
    ed.duration.checked:SetPoint("CENTER", ed.duration, "CENTER", 0, 0)
    ed.duration.checked:SetWidth(7)
    ed.duration.checked:SetHeight(7)
    ed.duration.value = 0
    ed.duration:SetScript("OnClick", function(self)
      ed.duration.value = 1 - (ed.duration.value or 0)
      if ed.duration.value == 1 then ed.duration.checked:Show() else ed.duration.checked:Hide() end
	  sA:SaveAura(id)
    end)
    ed.durationLabel = ed:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    ed.durationLabel:SetPoint("LEFT", ed.duration, "RIGHT", 5, 0)
    ed.durationLabel:SetText("Show Duration")

    ed.stacks = CreateFrame("Button", nil, ed)
    ed.stacks:SetWidth(16)
    ed.stacks:SetHeight(16)
    ed.stacks:SetPoint("LEFT", ed.durationLabel, "RIGHT", 65, 0)
    sA:SkinFrame(ed.stacks, {0.15,0.15,0.15,1})
    ed.stacks:SetScript("OnEnter", function() ed.stacks:SetBackdropColor(0.5,0.5,0.5,1) end)
    ed.stacks:SetScript("OnLeave", function() ed.stacks:SetBackdropColor(0.15,0.15,0.15,1) end)
    ed.stacks.checked = ed.stacks:CreateTexture(nil, "OVERLAY")
    ed.stacks.checked:SetTexture("Interface\\Buttons\\WHITE8x8")
    ed.stacks.checked:SetVertexColor(1,0.8,0.06,1)
    ed.stacks.checked:SetPoint("CENTER", ed.stacks, "CENTER", 0, 0)
    ed.stacks.checked:SetWidth(7)
    ed.stacks.checked:SetHeight(7)
    ed.stacks.value = 0
    ed.stacks:SetScript("OnClick", function(self)
      ed.stacks.value = 1 - (ed.stacks.value or 0)
      if ed.stacks.value == 1 then ed.stacks.checked:Show() else ed.stacks.checked:Hide() end
	  sA:SaveAura(id)
    end)
    ed.stacksLabel = ed:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    ed.stacksLabel:SetPoint("LEFT", ed.stacks, "RIGHT", 5, 0)
    ed.stacksLabel:SetText("Show Stacks")

    -- Duration size input
    ed.durationSizeLabel = ed:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    ed.durationSizeLabel:SetPoint("TOPLEFT", ed.duration, "BOTTOMLEFT", 0, -15)
    ed.durationSizeLabel:SetText("Duration Size:")
    ed.durationSize = CreateFrame("EditBox", nil, ed)
    ed.durationSize:SetPoint("LEFT", ed.durationSizeLabel, "RIGHT", 5, 0)
    ed.durationSize:SetWidth(40)
    ed.durationSize:SetHeight(20)
    ed.durationSize:SetJustifyH("CENTER")
    ed.durationSize:SetMultiLine(false)
    ed.durationSize:SetAutoFocus(false)
    ed.durationSize:SetFontObject(GameFontHighlightSmall)
    ed.durationSize:SetTextColor(1,1,1)
    ed.durationSize:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8x8", edgeFile = "Interface\\Buttons\\WHITE8x8", edgeSize = 1 })
    ed.durationSize:SetBackdropColor(0.1,0.1,0.1,1)
    ed.durationSize:SetBackdropBorderColor(0,0,0,1)
    ed.durationSize:SetScript("OnEnterPressed", function() sA:SaveAura(id) end)

    -- Stacks size input
    ed.stacksSizeLabel = ed:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    ed.stacksSizeLabel:SetPoint("LEFT", ed.durationSize, "RIGHT", 30, 0)
    ed.stacksSizeLabel:SetText("Stacks Size:")
    ed.stacksSize = CreateFrame("EditBox", nil, ed)
    ed.stacksSize:SetPoint("LEFT", ed.stacksSizeLabel, "RIGHT", 5, 0)
    ed.stacksSize:SetWidth(40)
    ed.stacksSize:SetHeight(20)
    ed.stacksSize:SetJustifyH("CENTER")
    ed.stacksSize:SetMultiLine(false)
    ed.stacksSize:SetAutoFocus(false)
    ed.stacksSize:SetFontObject(GameFontHighlightSmall)
    ed.stacksSize:SetTextColor(1,1,1)
    ed.stacksSize:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8x8", edgeFile = "Interface\\Buttons\\WHITE8x8", edgeSize = 1 })
    ed.stacksSize:SetBackdropColor(0.1,0.1,0.1,1)
    ed.stacksSize:SetBackdropBorderColor(0,0,0,1)
    ed.stacksSize:SetScript("OnEnterPressed", function() sA:SaveAura(id) end)

    -- Conditions (unit / type)
    local linetwo = ed:CreateTexture(nil, "OVERLAY")
    linetwo:SetTexture("Interface\\Buttons\\WHITE8x8")
    linetwo:SetVertexColor(1, 0.8, 0.06, 1)
    linetwo:SetPoint("TOPLEFT", ed.durationSizeLabel, "BOTTOMLEFT", 0, -15)
    linetwo:SetWidth(275)
    linetwo:SetHeight(1)

    ed.conditionsLabel = ed:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    ed.conditionsLabel:SetPoint("TOP", linetwo, "BOTTOM", 0, -15)
    ed.conditionsLabel:SetJustifyH("CENTER")
    ed.conditionsLabel:SetText("Conditions")

    -- Type dropdown
    ed.typeLabel = ed:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	ed.typeLabel:SetPoint("TOPLEFT", linetwo, "BOTTOMLEFT", 0, -45)
    ed.typeLabel:SetText("Type:")
    ed.typeButton = CreateFrame("Button", nil, ed)
    ed.typeButton:SetWidth(80)
    ed.typeButton:SetHeight(20)
    ed.typeButton:SetPoint("LEFT", ed.typeLabel, "RIGHT", 5, 0)
    sA:SkinFrame(ed.typeButton, {0.2,0.2,0.2,1})
    ed.typeButton.text = ed.typeButton:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    ed.typeButton.text:SetPoint("CENTER", ed.typeButton, "CENTER", 0, 0)
    ed.typeButton:SetScript("OnEnter", function() ed.typeButton:SetBackdropColor(0.5,0.5,0.5,1) end)
    ed.typeButton:SetScript("OnLeave", function() ed.typeButton:SetBackdropColor(0.2,0.2,0.2,1) end)
    ed.typeButton:SetScript("OnClick", function(self)
      if not ed.typeButton.menu then
        local menu = CreateFrame("Frame", nil, ed)
        menu:SetPoint("TOPLEFT", ed.typeButton, "BOTTOMLEFT", 0, -2)
        menu:SetFrameStrata("DIALOG")
        menu:SetFrameLevel(10)
        menu:SetWidth(80)
        menu:SetHeight(100)
        sA:SkinFrame(menu, {0.15,0.15,0.15,1})
        menu:Hide()
        ed.typeButton.menu = menu
        local function makeChoice(text, index)
          local b = CreateFrame("Button", nil, menu)
          b:SetWidth(80)
          b:SetHeight(20)
          b:SetPoint("TOPLEFT", menu, "TOPLEFT", 0, -((index - 1) * 20))
          sA:SkinFrame(b, {0.2,0.2,0.2,1})
          b.text = b:CreateFontString(nil, "OVERLAY", "GameFontWhite")
          b.text:SetPoint("CENTER", b, "CENTER", 0, 0)
          b.text:SetText(text)
          b:SetScript("OnEnter", function() b:SetBackdropColor(0.5,0.5,0.5,1) end)
          b:SetScript("OnLeave", function() b:SetBackdropColor(0.2,0.2,0.2,1) end)
          b:SetScript("OnClick", function()
            ed.typeButton.text:SetText(text)
            aura.type = text
            menu:Hide()
            sA:SaveAura(id)
          end)
        end
        makeChoice("Buff", 1)
        makeChoice("Debuff", 2)
        makeChoice("Cooldown", 3)
        makeChoice("Reactive", 4)
        makeChoice("Poison", 5)
      end
      local menu = ed.typeButton.menu
      if menu:IsVisible() then menu:Hide() else menu:Show() end
    end)

    -- Unit dropdown
	ed.unitLabel = ed:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	ed.unitLabel:SetPoint("LEFT", ed.typeButton, "RIGHT", 42, 0)
	ed.unitLabel:SetText("Unit:")
	ed.unitButton = CreateFrame("Button", nil, ed)
	ed.unitButton:SetWidth(80)
	ed.unitButton:SetHeight(20)
	ed.unitButton:SetPoint("LEFT", ed.unitLabel, "RIGHT", 5, 0)
	sA:SkinFrame(ed.unitButton, {0.2,0.2,0.2,1})
	ed.unitButton.text = ed.unitButton:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	ed.unitButton.text:SetPoint("CENTER", ed.unitButton, "CENTER", 0, 0)
	ed.unitButton:SetScript("OnEnter", function() ed.unitButton:SetBackdropColor(0.5,0.5,0.5,1) end)
	ed.unitButton:SetScript("OnLeave", function() ed.unitButton:SetBackdropColor(0.2,0.2,0.2,1) end)
	ed.unitButton:SetScript("OnClick", function(self)
	  if not ed.unitButton.menu then
		local menu = CreateFrame("Frame", nil, ed)
		menu:SetPoint("TOPLEFT", ed.unitButton, "BOTTOMLEFT", 0, -2)
		menu:SetFrameStrata("DIALOG")
		menu:SetFrameLevel(10)
		menu:SetWidth(80)
		menu:SetHeight(40)
		sA:SkinFrame(menu, {0.15,0.15,0.15,1})
		menu:Hide()
		ed.unitButton.menu = menu
		local function makeChoice(text, index)
		  local b = CreateFrame("Button", nil, menu)
		  b:SetWidth(80)
		  b:SetHeight(20)
		  b:SetPoint("TOPLEFT", menu, "TOPLEFT", 0, -((index - 1) * 20))
		  sA:SkinFrame(b, {0.2,0.2,0.2,1})
		  b.text = b:CreateFontString(nil, "OVERLAY", "GameFontWhite")
		  b.text:SetPoint("CENTER", b, "CENTER", 0, 0)
		  b.text:SetText(text)
		  b:SetScript("OnEnter", function() b:SetBackdropColor(0.5,0.5,0.5,1) end)
		  b:SetScript("OnLeave", function() b:SetBackdropColor(0.2,0.2,0.2,1) end)
		  b:SetScript("OnClick", function()
			ed.unitButton.text:SetText(text)
			aura.unit = text
			menu:Hide()
			sA:SaveAura(id)
		  end)
		  return b
		end
		
		-- Clear existing choices if menu already exists
		if menu.choices then
		  for _, btn in ipairs(menu.choices) do
			btn:Hide()
		  end
		end
		menu.choices = {}
		
		-- Add choices based on aura type
		local currentAura = simpleAuras.auras[id]
		if currentAura and currentAura.type == "Poison" then
		  menu:SetHeight(40)
		  table.insert(menu.choices, makeChoice("MH", 1))
		  table.insert(menu.choices, makeChoice("OH", 2))
		else
		  menu:SetHeight(40)
		  table.insert(menu.choices, makeChoice("Player", 1))
		  table.insert(menu.choices, makeChoice("Target", 2))
		end
	  end
	  local menu = ed.unitButton.menu
	  if menu:IsVisible() then menu:Hide() else menu:Show() end
	end)
	
	-- Equipped checkbox (for Cooldown items like trinkets) - between Type and Always
	ed.equipped = CreateFrame("Button", nil, ed)
	ed.equipped:SetWidth(16)
	ed.equipped:SetHeight(16)
	ed.equipped:SetPoint("LEFT", ed.typeButton, "RIGHT", 10, 0)
	sA:SkinFrame(ed.equipped, {0.15,0.15,0.15,1})
	ed.equipped:SetScript("OnEnter", function() ed.equipped:SetBackdropColor(0.5,0.5,0.5,1) end)
	ed.equipped:SetScript("OnLeave", function() ed.equipped:SetBackdropColor(0.15,0.15,0.15,1) end)
	ed.equipped.checked = ed.equipped:CreateTexture(nil, "OVERLAY")
	ed.equipped.checked:SetTexture("Interface\\Buttons\\WHITE8x8")
	ed.equipped.checked:SetVertexColor(1,0.8,0.06,1)
	ed.equipped.checked:SetPoint("CENTER", ed.equipped, "CENTER", 0, 0)
	ed.equipped.checked:SetWidth(7)
	ed.equipped.checked:SetHeight(7)
	ed.equipped.value = 0
	ed.equipped:SetScript("OnClick", function(self)
	  ed.equipped.value = 1 - (ed.equipped.value or 0)
	  if ed.equipped.value == 1 then ed.equipped.checked:Show() else ed.equipped.checked:Hide() end
	  sA:SaveAura(id)
	end)
	ed.equippedLabel = ed:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	ed.equippedLabel:SetPoint("LEFT", ed.equipped, "RIGHT", 5, 0)
	ed.equippedLabel:SetText("Equipped")
	ed.equipped:Hide()

	-- Cooldown option (Always/CD/No CD) - after Equipped checkbox
	ed.showCD = CreateFrame("Button", nil, ed)
	ed.showCD:SetWidth(80)
	ed.showCD:SetHeight(20)
	ed.showCD:SetPoint("LEFT", ed.equippedLabel, "RIGHT", 15, 0)
	sA:SkinFrame(ed.showCD, {0.2,0.2,0.2,1})
	ed.showCD.text = ed.showCD:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	ed.showCD.text:SetPoint("CENTER", ed.showCD, "CENTER", 0, 0)
	ed.showCD:SetScript("OnEnter", function() ed.showCD:SetBackdropColor(0.5,0.5,0.5,1) end)
	ed.showCD:SetScript("OnLeave", function() ed.showCD:SetBackdropColor(0.2,0.2,0.2,1) end)
	ed.showCD:SetScript("OnClick", function(self)
	  if not ed.showCD.menu then
		local menu = CreateFrame("Frame", nil, ed)
		menu:SetPoint("TOPLEFT", ed.showCD, "BOTTOMLEFT", 0, -2)
		menu:SetFrameStrata("DIALOG")
		menu:SetFrameLevel(10)
		menu:SetWidth(80)
		menu:SetHeight(40)
		sA:SkinFrame(menu, {0.15,0.15,0.15,1})
		menu:Hide()
		ed.showCD.menu = menu
		local function makeChoice(text, index)
		  local b = CreateFrame("Button", nil, menu)
		  b:SetWidth(80)
		  b:SetHeight(20)
		  b:SetPoint("TOPLEFT", menu, "TOPLEFT", 0, -((index - 1) * 20))
		  sA:SkinFrame(b, {0.2,0.2,0.2,1})
		  b.text = b:CreateFontString(nil, "OVERLAY", "GameFontWhite")
		  b.text:SetPoint("CENTER", b, "CENTER", 0, 0)
		  b.text:SetText(text)
		  b:SetScript("OnEnter", function() b:SetBackdropColor(0.5,0.5,0.5,1) end)
		  b:SetScript("OnLeave", function() b:SetBackdropColor(0.2,0.2,0.2,1) end)
		  b:SetScript("OnClick", function()
			ed.showCD.text:SetText(text)
			aura.showCD = text
			menu:Hide()
			sA:SaveAura(id)
		  end)
		end
		makeChoice("Always", 1)
		makeChoice("CD", 2)
		makeChoice("No CD", 3)
	  end
	  local menu = ed.showCD.menu
	  if menu:IsVisible() then menu:Hide() else menu:Show() end
	end)
	ed.showCD:Hide()

    -- Low duration options
    ed.lowduration = CreateFrame("Button", nil, ed)
    ed.lowduration:SetWidth(16)
    ed.lowduration:SetHeight(16)
    ed.lowduration:SetPoint("TOPLEFT", ed.typeLabel, "BOTTOMLEFT", 0, -15)
    sA:SkinFrame(ed.lowduration, {0.15,0.15,0.15,1})
    ed.lowduration:SetScript("OnEnter", function() ed.lowduration:SetBackdropColor(0.5,0.5,0.5,1) end)
    ed.lowduration:SetScript("OnLeave", function() ed.lowduration:SetBackdropColor(0.15,0.15,0.15,1) end)
    ed.lowduration.checked = ed.lowduration:CreateTexture(nil, "OVERLAY")
    ed.lowduration.checked:SetTexture("Interface\\Buttons\\WHITE8x8")
    ed.lowduration.checked:SetVertexColor(1,0.8,0.06,1)
    ed.lowduration.checked:SetPoint("CENTER", ed.lowduration, "CENTER", 0, 0)
    ed.lowduration.checked:SetWidth(7)
    ed.lowduration.checked:SetHeight(7)
    ed.lowduration.value = 0
    ed.lowduration:SetScript("OnClick", function(self)
      ed.lowduration.value = 1 - (ed.lowduration.value or 0)
      if ed.lowduration.value == 1 then ed.lowduration.checked:Show() else ed.lowduration.checked:Hide() end
	  sA:SaveAura(id)
    end)
    ed.lowdurationLabel = ed:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    ed.lowdurationLabel:SetPoint("LEFT", ed.lowduration, "RIGHT", 5, 0)
    ed.lowdurationLabel:SetText("Low Duration Color")

    ed.lowdurationcolorpicker = CreateFrame("Button", nil, ed)
    ed.lowdurationcolorpicker:SetWidth(24)
    ed.lowdurationcolorpicker:SetHeight(12)
    ed.lowdurationcolorpicker:SetPoint("LEFT", ed.lowdurationLabel, "RIGHT", 10, 0)
    sA:SkinFrame(ed.lowdurationcolorpicker, {1,1,1,1})
    ed.lowdurationcolorpicker.prev = ed.lowdurationcolorpicker:CreateTexture(nil, "OVERLAY")
    ed.lowdurationcolorpicker.prev:SetAllPoints(ed.lowdurationcolorpicker)

    ed.lowdurationLabelprefix = ed:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    ed.lowdurationLabelprefix:SetPoint("LEFT", ed.lowdurationcolorpicker, "RIGHT", 20, 0)
    ed.lowdurationLabelprefix:SetText("(<=")

    ed.lowdurationvalue = CreateFrame("EditBox", nil, ed)
    ed.lowdurationvalue:SetPoint("LEFT", ed.lowdurationLabelprefix, "RIGHT", 2, 0)
    ed.lowdurationvalue:SetWidth(30)
    ed.lowdurationvalue:SetHeight(20)
	ed.lowdurationvalue:SetJustifyH("CENTER")
    ed.lowdurationvalue:SetMultiLine(false)
    ed.lowdurationvalue:SetAutoFocus(false)
    ed.lowdurationvalue:SetFontObject(GameFontHighlightSmall)
    ed.lowdurationvalue:SetTextColor(1,1,1)
    ed.lowdurationvalue:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8x8", edgeFile = "Interface\\Buttons\\WHITE8x8", edgeSize = 1 })
    ed.lowdurationvalue:SetBackdropColor(0.1,0.1,0.1,1)
    ed.lowdurationvalue:SetBackdropBorderColor(0,0,0,1)
    ed.lowdurationvalue:SetScript("OnEnterPressed", function() sA:SaveAura(id) end)

    ed.lowdurationLabelsuffix = ed:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    ed.lowdurationLabelsuffix:SetPoint("LEFT", ed.lowdurationvalue, "RIGHT", 2, 0)
    ed.lowdurationLabelsuffix:SetText("sec)")

    -- In Combat checkbox
    ed.inCombat = CreateFrame("Button", nil, ed)
    ed.inCombat:SetWidth(16)
    ed.inCombat:SetHeight(16)
    ed.inCombat:SetPoint("TOPLEFT", ed.lowduration, "BOTTOMLEFT", 0, -15)
    sA:SkinFrame(ed.inCombat, {0.15,0.15,0.15,1})
    ed.inCombat:SetScript("OnEnter", function() ed.inCombat:SetBackdropColor(0.5,0.5,0.5,1) end)
    ed.inCombat:SetScript("OnLeave", function() ed.inCombat:SetBackdropColor(0.15,0.15,0.15,1) end)
    ed.inCombat.checked = ed.inCombat:CreateTexture(nil, "OVERLAY")
    ed.inCombat.checked:SetTexture("Interface\\Buttons\\WHITE8x8")
    ed.inCombat.checked:SetVertexColor(1, 0.8, 0.06, 1)
    ed.inCombat.checked:SetPoint("CENTER", ed.inCombat, "CENTER", 0, 0)
    ed.inCombat.checked:SetWidth(7)
    ed.inCombat.checked:SetHeight(7)
    ed.inCombat.value = 0
    ed.inCombat:SetScript("OnClick", function(self)
      ed.inCombat.value = 1 - (ed.inCombat.value or 0)
      if ed.inCombat.value == 1 then ed.inCombat.checked:Show() else ed.inCombat.checked:Hide() end
	  sA:SaveAura(id)
    end)

    ed.incombatLabel = ed:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    ed.incombatLabel:SetPoint("LEFT", ed.inCombat, "RIGHT", 5, 1)
    ed.incombatLabel:SetText("In Combat")

    -- Out of Combat checkbox
    ed.outCombat = CreateFrame("Button", nil, ed)
    ed.outCombat:SetWidth(16)
    ed.outCombat:SetHeight(16)
    ed.outCombat:SetPoint("LEFT", ed.incombatLabel, "RIGHT", 77, 0)
    sA:SkinFrame(ed.outCombat, {0.15,0.15,0.15,1})
    ed.outCombat:SetScript("OnEnter", function() ed.outCombat:SetBackdropColor(0.5,0.5,0.5,1) end)
    ed.outCombat:SetScript("OnLeave", function() ed.outCombat:SetBackdropColor(0.15,0.15,0.15,1) end)
    ed.outCombat.checked = ed.outCombat:CreateTexture(nil, "OVERLAY")
    ed.outCombat.checked:SetTexture("Interface\\Buttons\\WHITE8x8")
    ed.outCombat.checked:SetVertexColor(1, 0.8, 0.06, 1)
    ed.outCombat.checked:SetPoint("CENTER", ed.outCombat, "CENTER", 0, 0)
    ed.outCombat.checked:SetWidth(7)
    ed.outCombat.checked:SetHeight(7)
    ed.outCombat.value = 0
    ed.outCombat:SetScript("OnClick", function(self)
      ed.outCombat.value = 1 - (ed.outCombat.value or 0)
      if ed.outCombat.value == 1 then ed.outCombat.checked:Show() else ed.outCombat.checked:Hide() end
	  sA:SaveAura(id)
    end)

    ed.outcombatLabel = ed:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    ed.outcombatLabel:SetPoint("LEFT", ed.outCombat, "RIGHT", 5, 1)
    ed.outcombatLabel:SetText("Out of Combat")

    -- In Party checkbox
    ed.inParty = CreateFrame("Button", nil, ed)
    ed.inParty:SetWidth(16)
    ed.inParty:SetHeight(16)
    ed.inParty:SetPoint("TOPLEFT", ed.inCombat, "BOTTOMLEFT", 0, -15)
    sA:SkinFrame(ed.inParty, {0.15,0.15,0.15,1})
    ed.inParty:SetScript("OnEnter", function() ed.inParty:SetBackdropColor(0.5,0.5,0.5,1) end)
    ed.inParty:SetScript("OnLeave", function() ed.inParty:SetBackdropColor(0.15,0.15,0.15,1) end)
    ed.inParty.checked = ed.inParty:CreateTexture(nil, "OVERLAY")
    ed.inParty.checked:SetTexture("Interface\\Buttons\\WHITE8x8")
    ed.inParty.checked:SetVertexColor(1, 0.8, 0.06, 1)
    ed.inParty.checked:SetPoint("CENTER", ed.inParty, "CENTER", 0, 0)
    ed.inParty.checked:SetWidth(7)
    ed.inParty.checked:SetHeight(7)
    ed.inParty.value = 0
    ed.inParty:SetScript("OnClick", function(self)
      ed.inParty.value = 1 - (ed.inParty.value or 0)
      if ed.inParty.value == 1 then ed.inParty.checked:Show() else ed.inParty.checked:Hide() end
	  sA:SaveAura(id)
    end)
    ed.inpartyLabel = ed:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    ed.inpartyLabel:SetPoint("LEFT", ed.inParty, "RIGHT", 5, 1)
    ed.inpartyLabel:SetText("In Party")

    -- In Raid checkbox
    ed.inRaid = CreateFrame("Button", nil, ed)
    ed.inRaid:SetWidth(16)
    ed.inRaid:SetHeight(16)
    ed.inRaid:SetPoint("TOPLEFT", ed.outCombat, "BOTTOMLEFT", 0, -15)
    sA:SkinFrame(ed.inRaid, {0.15,0.15,0.15,1})
    ed.inRaid:SetScript("OnEnter", function() ed.inRaid:SetBackdropColor(0.5,0.5,0.5,1) end)
    ed.inRaid:SetScript("OnLeave", function() ed.inRaid:SetBackdropColor(0.15,0.15,0.15,1) end)
    ed.inRaid.checked = ed.inRaid:CreateTexture(nil, "OVERLAY")
    ed.inRaid.checked:SetTexture("Interface\\Buttons\\WHITE8x8")
    ed.inRaid.checked:SetVertexColor(1, 0.8, 0.06, 1)
    ed.inRaid.checked:SetPoint("CENTER", ed.inRaid, "CENTER", 0, 0)
    ed.inRaid.checked:SetWidth(7)
    ed.inRaid.checked:SetHeight(7)
    ed.inRaid.value = 0
    ed.inRaid:SetScript("OnClick", function(self)
      ed.inRaid.value = 1 - (ed.inRaid.value or 0)
      if ed.inRaid.value == 1 then ed.inRaid.checked:Show() else ed.inRaid.checked:Hide() end
	  sA:SaveAura(id)
    end)
    ed.inraidLabel = ed:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    ed.inraidLabel:SetPoint("LEFT", ed.inRaid, "RIGHT", 5, 1)
    ed.inraidLabel:SetText("In Raid")

    -- Invert / Dual
    ed.invert = CreateFrame("Button", nil, ed)
    ed.invert:SetWidth(16)
    ed.invert:SetHeight(16)
    ed.invert:SetPoint("BOTTOMLEFT", ed, "BOTTOMLEFT", 52.5, 30)
    sA:SkinFrame(ed.invert, {0.15,0.15,0.15,1})
    ed.invert:SetScript("OnEnter", function() ed.invert:SetBackdropColor(0.5,0.5,0.5,1) end)
    ed.invert:SetScript("OnLeave", function() ed.invert:SetBackdropColor(0.15,0.15,0.15,1) end)
    ed.invert.checked = ed.invert:CreateTexture(nil, "OVERLAY")
    ed.invert.checked:SetTexture("Interface\\Buttons\\WHITE8x8")
    ed.invert.checked:SetVertexColor(1,0.8,0.06,1)
    ed.invert.checked:SetPoint("CENTER", ed.invert, "CENTER", 0, 0)
    ed.invert.checked:SetWidth(7)
    ed.invert.checked:SetHeight(7)
    ed.invert.value = 0
    ed.invert:SetScript("OnClick", function(self)
      ed.invert.value = 1 - (ed.invert.value or 0)
      if ed.invert.value == 1 then ed.invert.checked:Show() else ed.invert.checked:Hide() end
	  sA:SaveAura(id)
    end)
    ed.invertLabel = ed:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    ed.invertLabel:SetPoint("LEFT", ed.invert, "RIGHT", 5, 0)
	ed.invertLabel:SetText("Invert")

    ed.dual = CreateFrame("Button", nil, ed)
    ed.dual:SetWidth(16)
    ed.dual:SetHeight(16)
    ed.dual:SetPoint("LEFT", ed.invertLabel, "RIGHT", 90, 0)
    sA:SkinFrame(ed.dual, {0.15,0.15,0.15,1})
    ed.dual:SetScript("OnEnter", function() ed.dual:SetBackdropColor(0.5,0.5,0.5,1) end)
    ed.dual:SetScript("OnLeave", function() ed.dual:SetBackdropColor(0.15,0.15,0.15,1) end)
    ed.dual.checked = ed.dual:CreateTexture(nil, "OVERLAY")
    ed.dual.checked:SetTexture("Interface\\Buttons\\WHITE8x8")
    ed.dual.checked:SetVertexColor(1,0.8,0.06,1)
    ed.dual.checked:SetPoint("CENTER", ed.dual, "CENTER", 0, 0)
    ed.dual.checked:SetWidth(7)
    ed.dual.checked:SetHeight(7)
    ed.dual.value = 0
    ed.dual:SetScript("OnClick", function(self)
      ed.dual.value = 1 - (ed.dual.value or 0)
      if ed.dual.value == 1 then ed.dual.checked:Show() else ed.dual.checked:Hide() end
	  sA:SaveAura(id)
    end)
    ed.dualLabel = ed:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    ed.dualLabel:SetPoint("LEFT", ed.dual, "RIGHT", 5, 0)
    ed.dualLabel:SetText("Dual")
	
	if aura.type == "Cooldown" then
		ed.unitLabel:Hide()
		ed.unitButton:Hide()
		ed.invert:Hide()
		ed.invertLabel:Hide()
		ed.dual:Hide()
		ed.dualLabel:Hide()
		ed.showCD:Show()
		ed.equipped:Show()
		ed.equippedLabel:Show()
	elseif aura.type == "Reactive" then
		ed.unitLabel:Hide()
		ed.unitButton:Hide()
		ed.invert:Hide()
		ed.invertLabel:Hide()
		ed.dual:Hide()
		ed.dualLabel:Hide()
		ed.showCD:Hide()
		ed.equipped:Hide()
		ed.equippedLabel:Hide()
	elseif aura.type == "Poison" then
		-- Poison: show Unit dropdown (MH/OH), hide some options
		if ed.unitLabel then ed.unitLabel:Show() end
		if ed.unitButton then ed.unitButton:Show() end
		ed.invert:Hide()
		ed.invertLabel:Hide()
		ed.dual:Hide()
		ed.dualLabel:Hide()
		ed.showCD:Hide()
		ed.equipped:Hide()
		ed.equippedLabel:Hide()
		-- Rebuild menu for Poison type
		if ed.unitButton.menu then
		  ed.unitButton.menu = nil
		end
	else
		-- Buff/Debuff: show all options
		if ed.unitLabel then ed.unitLabel:Show() end
		if ed.unitButton then ed.unitButton:Show() end
		ed.invert:Show()
		ed.invertLabel:Show()
		ed.dual:Show()
		ed.dualLabel:Show()
		ed.showCD:Hide()
		ed.equipped:Hide()
		ed.equippedLabel:Hide()
	end

    -- Delete / Close / Copy buttons
    ed.delete = CreateFrame("Button", nil, ed)
    ed.delete:SetPoint("BOTTOM", 0, 8)
    ed.delete:SetWidth(60)
    ed.delete:SetHeight(20)
    sA:SkinFrame(ed.delete, {0.2,0.2,0.2,1})
    ed.delete.text = ed.delete:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    ed.delete.text:SetPoint("CENTER", ed.delete, "CENTER", 0, 0)
    ed.delete.text:SetText("Delete")
    ed.delete:SetScript("OnEnter", function() ed.delete:SetBackdropColor(0.4,0.1,0.1,1) end)
    ed.delete:SetScript("OnLeave", function() ed.delete:SetBackdropColor(0.2,0.2,0.2,1) end)

    ed.close = CreateFrame("Button", nil, ed)
    ed.close:SetPoint("TOPRIGHT", -2, -2)
    ed.close:SetWidth(20)
    ed.close:SetHeight(20)
    sA:SkinFrame(ed.close, {0.2,0.2,0.2,1})
    ed.close.text = ed.close:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    ed.close.text:SetPoint("CENTER", 0.5, 1)
    ed.close.text:SetText("x")
    ed.close:SetScript("OnEnter", function() ed.close:SetBackdropColor(0.5,0.5,0.5,1) end)
    ed.close:SetScript("OnLeave", function() ed.close:SetBackdropColor(0.2,0.2,0.2,1) end)

    ed.copy = CreateFrame("Button", nil, ed)
    ed.copy:SetPoint("TOPLEFT", 2, -2)
    ed.copy:SetWidth(20)
    ed.copy:SetHeight(20)
    sA:SkinFrame(ed.copy, {0.2,0.2,0.2,1})
    ed.copy.text = ed.copy:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    ed.copy.text:SetPoint("CENTER", 0.5, 1)
    ed.copy.text:SetText("c")
    ed.copy:SetScript("OnEnter", function() ed.copy:SetBackdropColor(0.1,0.4,0.1,1) end)
    ed.copy:SetScript("OnLeave", function() ed.copy:SetBackdropColor(0.2,0.2,0.2,1) end)

    -- Export Single button
    ed.export = CreateFrame("Button", nil, ed)
    ed.export:SetPoint("TOPLEFT", ed.copy, "TOPRIGHT", 5, 0)
    ed.export:SetWidth(20)
    ed.export:SetHeight(20)
    sA:SkinFrame(ed.export, {0.2,0.2,0.2,1})
    ed.export.text = ed.export:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    ed.export.text:SetPoint("CENTER", 0.5, 1)
    ed.export.text:SetText("e")
    ed.export:SetScript("OnEnter", function() ed.export:SetBackdropColor(0.5,0.5,0.5,1) end)
    ed.export:SetScript("OnLeave", function() ed.export:SetBackdropColor(0.2,0.2,0.2,1) end)

    gui.editor = ed
  end

  -- Populate fields with aura values
  ed.title:SetText("[" .. tostring(id) .. "] " .. (aura.name ~= "" and aura.name or "<unnamed>"))
  ed.enabled.value = aura.enabled or 1
  if ed.enabled.value == 1 then ed.enabled.checked:Show() else ed.enabled.checked:Hide() end
  ed.layer:SetText(aura.layer or 0)
  if ed.myCast then
	  ed.myCast.value = aura.myCast or 0
	  if ed.myCast.value == 1 then ed.myCast.checked:Show() else ed.myCast.checked:Hide() end
  end
  ed.name:SetText(aura.name or "")
  ed.auracolor = aura.auracolor or {1,1,1,1}
  ed.auracolorpicker = ed.auracolorpicker -- ensure exists
  ed.auracolorpicker.prev:SetTexture(unpack(ed.auracolor))

  ed.autoDetect.value = aura.autodetect or 0
  if ed.autoDetect.value == 1 then ed.autoDetect.checked:Show() else ed.autoDetect.checked:Hide() end

  ed.texturePath:SetText(aura.texture or "")
  ed.scale:SetText(aura.scale or 1)
  ed.x:SetText(aura.xpos or 0)
  ed.y:SetText(aura.ypos or 0)

  ed.duration.value = aura.duration or 0
  if ed.duration.value == 1 then ed.duration.checked:Show() else ed.duration.checked:Hide() end
  ed.durationSize:SetText(aura.durationSize or 20)

  ed.stacks.value = aura.stacks or 0
  if ed.stacks.value == 1 then ed.stacks.checked:Show() else ed.stacks.checked:Hide() end
  ed.stacksSize:SetText(aura.stacksSize or 14)

  ed.lowduration.value = aura.lowduration or 0
  if ed.lowduration.value == 1 then ed.lowduration.checked:Show() else ed.lowduration.checked:Hide() end
  ed.lowdurationvalue:SetText(aura.lowdurationvalue or 5)
  ed.lowdurationcolor = aura.lowdurationcolor or {1,0,0,1}
  ed.lowdurationcolorpicker.prev:SetTexture(unpack(ed.lowdurationcolor))

  ed.typeButton.text:SetText(aura.type or "Buff")
  if ed.unitButton then
	ed.unitButton.text:SetText(aura.unit or "Player")
  end
  if ed.showCD then
	ed.showCD.text:SetText(aura.showCD or "Always")
  end
  ed.equipped.value = aura.equipped or 0
  if ed.equipped.value == 1 then ed.equipped.checked:Show() else ed.equipped.checked:Hide() end
  ed.inCombat.value = aura.inCombat or 0
  if ed.inCombat.value == 1 then ed.inCombat.checked:Show() else ed.inCombat.checked:Hide() end
  ed.outCombat.value = aura.outCombat or 0
  if ed.outCombat.value == 1 then ed.outCombat.checked:Show() else ed.outCombat.checked:Hide() end
  ed.inRaid.value = aura.inRaid or 0
  if ed.inRaid.value == 1 then ed.inRaid.checked:Show() else ed.inRaid.checked:Hide() end
  ed.inParty.value = aura.inParty or 0
  if ed.inParty.value == 1 then ed.inParty.checked:Show() else ed.inParty.checked:Hide() end
  ed.invert.value = aura.invert or 0
  if ed.invert.value == 1 then ed.invert.checked:Show() else ed.invert.checked:Hide() end
  ed.dual.value = aura.dual or 0
  if ed.dual.value == 1 then ed.dual.checked:Show() else ed.dual.checked:Hide() end

  ed.export:SetScript("OnClick", function() sA:ExportSingleAura(id) end)

  -- Show Test aura(s)
  sA.TestAura:SetPoint("CENTER", UIParent, "CENTER", aura.xpos or 0, aura.ypos or 0)
  sA.TestAura:SetWidth(48*(aura.scale or 1))
  sA.TestAura:SetHeight(48*(aura.scale or 1))
  sA.TestAura.texture:SetTexture(aura.texture)
  sA.TestAura.texture:SetVertexColor(unpack(aura.auracolor or {1,1,1,1}))
  -- Position duration and stacks based on settings
  if aura.duration == 1 and aura.stacks == 1 then
    -- Both enabled: move duration up, stacks down
    sA.TestAura.durationtext:SetPoint("CENTER", sA.TestAura, "CENTER", 0, 8)
    sA.TestAura.stackstext:SetPoint("CENTER", sA.TestAura, "CENTER", 0, -8)
    local durationFontSize = (aura.durationSize or 20) * (aura.scale or 1)
    sA.TestAura.durationtext:SetText("60") 
    sA.TestAura.durationtext:SetFont("Fonts\\FRIZQT__.TTF", durationFontSize, "OUTLINE") 
  elseif aura.duration == 1 then
    -- Only duration enabled: center duration
    sA.TestAura.durationtext:SetPoint("CENTER", sA.TestAura, "CENTER", 0, 0)
    sA.TestAura.stackstext:SetPoint("CENTER", sA.TestAura, "CENTER", 0, 0)
    local durationFontSize = (aura.durationSize or 20) * (aura.scale or 1)
    sA.TestAura.durationtext:SetText("60") 
    sA.TestAura.durationtext:SetFont("Fonts\\FRIZQT__.TTF", durationFontSize, "OUTLINE") 
  else
    -- Duration disabled: center stacks (if enabled)
    sA.TestAura.durationtext:SetPoint("CENTER", sA.TestAura, "CENTER", 0, 0)
    sA.TestAura.stackstext:SetPoint("CENTER", sA.TestAura, "CENTER", 0, 0)
    sA.TestAura.durationtext:SetText("") 
  end
  if aura.stacks == 1 then 
    local stacksFontSize = (aura.stacksSize or 14) * (aura.scale or 1)
    sA.TestAura.stackstext:SetText("20") 
    sA.TestAura.stackstext:SetFont("Fonts\\FRIZQT__.TTF", stacksFontSize, "OUTLINE") 
  else 
    sA.TestAura.stackstext:SetText("") 
  end
	  
	  local _, _, _, durationalpha = unpack(aura.auracolor or {1,1,1,1})
	  local durationcolor = {1.0, 0.82, 0.0, durationalpha}
	  local stackcolor = {1, 1, 1, durationalpha}

	  sA.TestAura.durationtext:SetTextColor(unpack(durationcolor))
	  sA.TestAura.stackstext:SetTextColor(unpack(stackcolor))
	  sA.TestAuraDual.durationtext:SetTextColor(unpack(durationcolor))
	  sA.TestAuraDual.stackstext:SetTextColor(unpack(stackcolor))
	  
  sA.TestAura:Show()
  
  if aura.dual == 1 and aura.type ~= "Cooldown" then
    sA.TestAuraDual:SetPoint("CENTER", UIParent, "CENTER", -(aura.xpos or 0), aura.ypos or 0)
    sA.TestAuraDual:SetWidth(48*(aura.scale or 1))
    sA.TestAuraDual:SetHeight(48*(aura.scale or 1))
    sA.TestAuraDual.texture:SetTexture(aura.texture)
    sA.TestAuraDual.texture:SetTexCoord(1,0,0,1)
    sA.TestAuraDual.texture:SetVertexColor(unpack(aura.auracolor or {1,1,1,1}))
    -- Position duration and stacks based on settings (same as main frame)
    if aura.duration == 1 and aura.stacks == 1 then
      -- Both enabled: move duration up, stacks down
      sA.TestAuraDual.durationtext:SetPoint("CENTER", sA.TestAuraDual, "CENTER", 0, 8)
      sA.TestAuraDual.stackstext:SetPoint("CENTER", sA.TestAuraDual, "CENTER", 0, -8)
      local durationFontSize = (aura.durationSize or 20) * aura.scale
      sA.TestAuraDual.durationtext:SetText("60") 
      sA.TestAuraDual.durationtext:SetFont("Fonts\\FRIZQT__.TTF", durationFontSize, "OUTLINE") 
    elseif aura.duration == 1 then
      -- Only duration enabled: center duration
      sA.TestAuraDual.durationtext:SetPoint("CENTER", sA.TestAuraDual, "CENTER", 0, 0)
      sA.TestAuraDual.stackstext:SetPoint("CENTER", sA.TestAuraDual, "CENTER", 0, 0)
      local durationFontSize = (aura.durationSize or 20) * aura.scale
      sA.TestAuraDual.durationtext:SetText("60") 
      sA.TestAuraDual.durationtext:SetFont("Fonts\\FRIZQT__.TTF", durationFontSize, "OUTLINE") 
    else
      -- Duration disabled: center stacks (if enabled)
      sA.TestAuraDual.durationtext:SetPoint("CENTER", sA.TestAuraDual, "CENTER", 0, 0)
      sA.TestAuraDual.stackstext:SetPoint("CENTER", sA.TestAuraDual, "CENTER", 0, 0)
      sA.TestAuraDual.durationtext:SetText("") 
    end
    if aura.stacks == 1 then 
      local stacksFontSize = (aura.stacksSize or 14) * aura.scale
      sA.TestAuraDual.stackstext:SetText("20") 
      sA.TestAuraDual.stackstext:SetFont("Fonts\\FRIZQT__.TTF", stacksFontSize, "OUTLINE") 
    else 
      sA.TestAuraDual.stackstext:SetText("") 
    end
    sA.TestAuraDual:Show()
  else
    sA.TestAuraDual:Hide()
  end

  -- Editor button handlers
  ed.close:SetScript("OnClick", function() ed:Hide(); gui.editor = nil; sA.TestAura:Hide(); sA.TestAuraDual:Hide(); gui.auraEdit = nil; sA:RefreshAuraList(); end)
  ed.copy:SetScript("OnClick", function() sA:AddAura(id) end)

  ed.delete:SetScript("OnClick", function()
    if ed.confirm then ed.confirm:Show(); return end
    ed.confirm = CreateFrame("Frame", nil, ed)
    ed.confirm:EnableMouse(true)
    ed.confirm:SetFrameStrata("DIALOG")
    ed.confirm:SetFrameLevel(10)
    ed.confirm:SetPoint("CENTER", ed, "CENTER", 0, 0)
    ed.confirm:SetWidth(250)
    ed.confirm:SetHeight(80)
    sA:SkinFrame(ed.confirm, {0.15,0.15,0.15,1})
    local msg = ed.confirm:CreateFontString(nil, "OVERLAY", "GameFontWhite")
    msg:SetPoint("TOP", 0, -20)
    msg:SetText("Delete '["..id.."] "..(aura.name ~= "" and aura.name or "<unnamed>").."'?")
    msg:SetTextColor(1,0,0)

    local yes = CreateFrame("Button", nil, ed.confirm)
    yes:SetPoint("BOTTOMLEFT", 30, 10)
    yes:SetWidth(60)
    yes:SetHeight(20)
    sA:SkinFrame(yes, {0.2,0.2,0.2,1})
    yes.text = yes:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    yes.text:SetPoint("CENTER", yes, "CENTER", 0, 0)
    yes.text:SetText("Yes")
    yes:SetScript("OnEnter", function() yes:SetBackdropColor(0.4,0.1,0.1,1) end)
    yes:SetScript("OnLeave", function() yes:SetBackdropColor(0.2,0.2,0.2,1) end)
    yes:SetScript("OnClick", function()
      table.remove(simpleAuras.auras, id)
	  if sA.frames[id] then sA.frames[id]:Hide() end
	  if sA.dualframes[id] then sA.dualframes[id]:Hide() end
      sA.frames = {}
      sA.dualframes = {}
      sA.draggers = {}
      ed.confirm:Hide()
      ed:Hide()
      gui.editor = nil
      gui.auraEdit = nil
      sA:RefreshAuraList()
      sA.TestAura:Hide()
      sA.TestAuraDual:Hide()
    end)

    local no = CreateFrame("Button", nil, ed.confirm)
    no:SetPoint("BOTTOMRIGHT", -30, 10)
    no:SetWidth(60)
    no:SetHeight(20)
    sA:SkinFrame(no, {0.2,0.2,0.2,1})
    no.text = no:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    no.text:SetPoint("CENTER", no, "CENTER", 0, 0)
    no.text:SetText("No")
    no:SetScript("OnEnter", function() no:SetBackdropColor(0.5,0.5,0.5,1) end)
    no:SetScript("OnLeave", function() no:SetBackdropColor(0.2,0.2,0.2,1) end)
    no:SetScript("OnClick", function() ed.confirm:Hide() end)
  end)

  -- Color pickers behavior
  ed.auracolorpicker:SetScript("OnClick", function(self)
    local r0,g0,b0,a0 = unpack(ed.auracolor or {1,1,1,1})
    ColorPickerFrame.func = function()
      local r,g,b = ColorPickerFrame:GetColorRGB()
      local a = 1 - OpacitySliderFrame:GetValue()
      r = math.floor(r * 100 + 0.5) / 100
      g = math.floor(g * 100 + 0.5) / 100
      b = math.floor(b * 100 + 0.5) / 100
      a = math.floor(a * 100 + 0.5) / 100
      ed.auracolorpicker.prev:SetTexture(r,g,b,a)
      sA.TestAura.texture:SetVertexColor(r,g,b,a)
      if simpleAuras.auras[id] and simpleAuras.auras[id].dual == 1 then sA.TestAuraDual.texture:SetVertexColor(r,g,b,a) end
      if gui.list[id] then gui.list[id].text:SetTextColor(r,g,b,a) end
	  if not this:GetParent():IsShown() then
        simpleAuras.auras[id].auracolor = {r, g, b, a}
        ed.auracolor = {r, g, b, a}
	  end
    end
    ColorPickerFrame.cancelFunc = function()
      ed.auracolor = {r0,g0,b0,a0}
      ed.auracolorpicker.prev:SetTexture(r0,g0,b0,a0)
      sA.TestAura.texture:SetVertexColor(r0,g0,b0,a0)
      if simpleAuras.auras[id] and simpleAuras.auras[id].dual == 1 then
        sA.TestAuraDual.texture:SetVertexColor(r0,g0,b0,a0)
      end
      if gui.list[id] then gui.list[id].text:SetTextColor(r0,g0,b0,a0) end
    end
    ColorPickerFrame:SetColorRGB(r0,g0,b0)
    ColorPickerFrame.hasOpacity = true
    ColorPickerFrame.opacityFunc = ColorPickerFrame.func
    ColorPickerFrame.opacity = 1 - (a0 or 0)
    ColorPickerFrame:SetFrameStrata("DIALOG")
    ShowUIPanel(ColorPickerFrame)
  end)

  ed.lowdurationcolorpicker:SetScript("OnClick", function(self)
    local r0,g0,b0,a0 = unpack(ed.lowdurationcolor or {1,0,0,1})
    ColorPickerFrame.func = function()
      local r,g,b = ColorPickerFrame:GetColorRGB()
      local a = 1 - OpacitySliderFrame:GetValue()
      r = math.floor(r * 100 + 0.5) / 100
      g = math.floor(g * 100 + 0.5) / 100
      b = math.floor(b * 100 + 0.5) / 100
      a = math.floor(a * 100 + 0.5) / 100
      ed.lowdurationcolorpicker.prev:SetTexture(r,g,b,a)
      sA.TestAura.texture:SetVertexColor(r,g,b,a)
      if simpleAuras.auras[id] and simpleAuras.auras[id].dual == 1 then sA.TestAuraDual.texture:SetVertexColor(r,g,b,a) end
	  if not this:GetParent():IsShown() then
        simpleAuras.auras[id].lowdurationcolor = {r, g, b, a}
        ed.lowdurationcolor = {r, g, b, a}
        sA.TestAura.texture:SetVertexColor(unpack(aura.auracolor or {1,1,1,1}))
        if simpleAuras.auras[id] and simpleAuras.auras[id].dual == 1 then sA.TestAuraDual.texture:SetVertexColor(unpack(aura.auracolor or {1,1,1,1})) end
	  end
    end
    ColorPickerFrame.cancelFunc = function()
      ed.lowdurationcolor = {r0,g0,b0,a0}
      ed.lowdurationcolorpicker.prev:SetTexture(r0,g0,b0,a0)
      sA.TestAura.texture:SetVertexColor(unpack(aura.auracolor or {1,1,1,1}))
      if simpleAuras.auras[id] and simpleAuras.auras[id].dual == 1 then sA.TestAuraDual.texture:SetVertexColor(unpack(aura.auracolor or {1,1,1,1})) end
    end
    ColorPickerFrame:SetColorRGB(r0,g0,b0)
    ColorPickerFrame.hasOpacity = true
    ColorPickerFrame.opacityFunc = ColorPickerFrame.func
    ColorPickerFrame.opacity = 1 - (a0 or 0)
    ColorPickerFrame:SetFrameStrata("DIALOG")
    ShowUIPanel(ColorPickerFrame)
  end)

  -- Browse textures
  ed.browseBtn:SetScript("OnClick", function(self)
    if ed.browseFrame then ed.browseFrame:Show(); return end
    local bf = CreateFrame("Frame", nil, ed)
    bf:EnableMouse(true)
    bf:SetAllPoints(ed)
    bf:SetFrameStrata("DIALOG")
    sA:SkinFrame(bf)
    ed.browseFrame = bf

    bf.title = bf:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    bf.title:SetPoint("TOP", bf, "TOP", 0, -5)
    bf.title:SetText("Select Texture")

    local close = CreateFrame("Button", nil, bf)
    close:SetWidth(20)
    close:SetHeight(20)
    close:SetPoint("TOPRIGHT", -2, -2)
    sA:SkinFrame(close, {0.2,0.2,0.2,1})
    close.text = close:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    close.text:SetPoint("CENTER", close, "CENTER", 0, 0)
    close.text:SetText("x")
    close:SetScript("OnEnter", function() close:SetBackdropColor(0.5,0.5,0.5,1) end)
    close:SetScript("OnLeave", function() close:SetBackdropColor(0.2,0.2,0.2,1) end)
    close:SetScript("OnClick", function() bf:Hide() end)

    local scroll = CreateFrame("ScrollFrame", nil, bf)
    scroll:SetPoint("TOPLEFT", 10, -30)
    scroll:SetPoint("BOTTOMRIGHT", -10, 40)
    local content = CreateFrame("Frame", nil, scroll)
    local total = 246
    local numPerRow = 6
    local size = 36
    local padding = 4
    local rows = math.ceil(total / numPerRow)
    content:SetWidth(numPerRow * (size + padding))
    content:SetHeight(rows * (size + padding) - (size/2) - padding + 1)
    scroll:SetScrollChild(content)

    local wheel = CreateFrame("Frame", nil, scroll)
    wheel:SetAllPoints(scroll)
    wheel:EnableMouseWheel(true)
    wheel:SetScript("OnMouseWheel", function()
    local dir = arg1 or 0
      local step = 30
      local current = scroll:GetVerticalScroll() or 0
      local max = (content:GetHeight() or 0) - (scroll:GetHeight() or 1)
      local target = math.max(0, math.min(current - dir * step, max))
      scroll:SetVerticalScroll(target)
    end)

    for i = 1, total do
      local btn = CreateFrame("Button", nil, content)
      local row = math.floor((i - 1) / numPerRow)
      local col = math.mod(i - 1, numPerRow)
      btn:SetWidth(size)
      btn:SetHeight(size)
      btn:SetPoint("TOPLEFT", col * (size + padding) + 22, -row * (size + padding))
      local tex = btn:CreateTexture(nil, "ARTWORK")
      tex:SetAllPoints(btn)
      tex:SetTexture("Interface\\AddOns\\simpleAuras\\Auras\\Aura" .. i)
      btn.texturePath = "Interface\\AddOns\\simpleAuras\\Auras\\Aura" .. i
      btn:SetScript("OnClick", function(self)
        selectedTexture = btn.texturePath
        for _, child in ipairs({content:GetChildren()}) do
          child:SetBackdropColor(0.2, 0.2, 0.2, 1)
        end
        sA:SkinFrame(btn, {0.5, 0.5, 0.5, 1})
      end)
	  if aura.texture and aura.texture == btn.texturePath then
        sA:SkinFrame(btn, {0.5, 0.5, 0.5, 1})
	  else
        sA:SkinFrame(btn, {0.2,0.2,0.2,1})
	  end
		
    end

    local select = CreateFrame("Button", nil, bf)
    select:SetWidth(80)
    select:SetHeight(20)
    select:SetPoint("BOTTOM", 0, 10)
    sA:SkinFrame(select, {0.2,0.2,0.2,1})
    select:SetScript("OnEnter", function() select:SetBackdropColor(0.5,0.5,0.5,1) end)
    select:SetScript("OnLeave", function() select:SetBackdropColor(0.2,0.2,0.2,1) end)
    select.text = select:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    select.text:SetPoint("CENTER", select, "CENTER", 0, 0)
    select.text:SetText("Select")
    select:SetScript("OnClick", function()
      if selectedTexture then
        ed.texturePath:SetText(selectedTexture)
        ed.browseFrame:Hide()
        sA:SaveAura(id)
      end
    end)
	
    local scrollbar = CreateFrame("Slider", nil, bf)
    scrollbar:SetOrientation("VERTICAL")
    scrollbar:SetWidth(10)
    scrollbar:SetPoint("TOPRIGHT", scroll, "TOPRIGHT", 4, 0)
    scrollbar:SetPoint("BOTTOMRIGHT", scroll, "BOTTOMRIGHT", 4, 0)
    sA:SkinFrame(scrollbar, {0.2, 0.2, 0.2, 1})
    
    local thumb = scrollbar:CreateTexture(nil, "OVERLAY")
    thumb:SetTexture("Interface\\Buttons\\WHITE8x8")
    thumb:SetVertexColor(1, 0.8, 0.1, 1)
    thumb:SetWidth(6)
    thumb:SetHeight(30)
    scrollbar:SetThumbTexture(thumb)
    scrollbar:SetMinMaxValues(0, 1)
    scrollbar:SetValueStep(1)
    scrollbar:SetValue(0)
    scrollbar:SetScript("OnValueChanged", function()
      scroll:SetVerticalScroll(scrollbar:GetValue())
    end)
    scroll:SetScript("OnVerticalScroll", function()
      scrollbar:SetValue(scroll:GetVerticalScroll())
    end)
    scrollbar:SetScript("OnValueChanged", function()
      scroll:SetVerticalScroll(scrollbar:GetValue())
    end)
    scroll:SetScript("OnVerticalScroll", function()
      scrollbar:SetValue(scroll:GetVerticalScroll())
    end)
    local contentHeight = content:GetHeight()
    local visibleHeight = scroll:GetHeight()
    local maxScroll = math.max(0, contentHeight - visibleHeight - 350)
    scrollbar:SetMinMaxValues(0, maxScroll)
    scrollbar:SetValue(0)
	
  end)
  
  sA:RefreshAuraList()

  -- ensure editor visible
  ed:Show()
end

-------------------------------------------------
-- Import/Export Functions (Custom Implementation)
-------------------------------------------------

local function serializeValue(val)
    local vtype = type(val)
    if vtype == "string" then
        return string.format("%q", val)
    elseif vtype == "number" or vtype == "boolean" then
        return tostring(val)
    elseif vtype == "table" then
        local parts = {}
        for k, v in pairs(val) do
            -- Keys must also be serialized correctly
            local keyStr = serializeValue(k)
            local valStr = serializeValue(v)
            if valStr ~= "nil" then -- Don't save nil values
                table.insert(parts, string.format("[%s]=%s", keyStr, valStr))
            end
        end
        return "{" .. table.concat(parts, ",") .. "}"
    else
        return "nil"
    end
end

local function Serialize(data)
    if type(data) ~= "table" then return nil end
    return serializeValue(data)
end

local function Deserialize(str)
    if not str or type(str) ~= "string" or str == "" then
        return false, "Invalid input string"
    end

    local func, err = loadstring(str)
    if not func then
        return false, "Syntax error: " .. (err or "unknown")
    end

    -- Use pcall to safely execute the loaded string
    local success, result = pcall(func)
    if not success then
        return false, "Execution error: " .. (result or "unknown")
    end

    return true, result
end

function sA:ShowExportFrame(exportString)

	if sAExportFrame then
		if sAExportFrame:IsVisible() then sAExportFrame:Hide() end
		sAExportFrame = nil
	end

    if not exportString then
        sA:Msg("Nothing to export.")
        return
    end
    
	if sAImportFrame and sAImportFrame:IsVisible() then
		sAImportFrame:Hide()
	end

    if not sAExportFrame then
        frame = CreateFrame("Frame", "sAExportFrame", UIParent)
        frame:SetFrameStrata("DIALOG")
        frame:SetPoint("CENTER", 0, 0)
        frame:SetWidth(400)
        frame:SetHeight(200)
        sA:SkinFrame(frame)
        frame:SetMovable(true)
        frame:EnableMouse(true)
        frame:RegisterForDrag("LeftButton")
        frame:SetScript("OnDragStart", function() frame:StartMoving() end)
        frame:SetScript("OnDragStop", function() frame:StopMovingOrSizing() end)

        frame.title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        frame.title:SetPoint("TOP", 0, -10)
        frame.title:SetText("Exported Aura String")
		
		
		frame.scroll = CreateFrame("ScrollFrame", "sAExportScrollFrame", frame)
        frame.scroll:SetPoint("TOPLEFT", 15, -30)
        frame.scroll:SetPoint("BOTTOMRIGHT", -15, 40)

        frame.editBox = CreateFrame("EditBox", "sAExportEditBox", frame.scroll)
        frame.editBox:SetMultiLine(true)
        frame.editBox:SetAutoFocus(false)
        frame.editBox:SetFontObject(GameFontHighlightSmall)
        frame.editBox:SetWidth(370)
        frame.editBox:SetHeight(120)
		frame.editBox:SetTextInsets(4, 4, 4, 4)
        frame.editBox:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8x8", edgeFile = "Interface\\Buttons\\WHITE8x8", edgeSize = 1 })
		frame.editBox:SetBackdropColor(0.1, 0.1, 0.1, 1)
		frame.editBox:SetBackdropBorderColor(0, 0, 0, 1)
		frame.editBox:SetScript("OnEscapePressed", function() frame.editBox:ClearFocus() end)
        frame.scroll:SetScrollChild(frame.editBox)
        
        frame.closeBtn = CreateFrame("Button", "sAExportCloseButton", frame)
        frame.closeBtn:SetPoint("BOTTOM", 0, 10)
        frame.closeBtn:SetWidth(80)
        frame.closeBtn:SetHeight(22)
        sA:SkinFrame(frame.closeBtn, {0.2, 0.2, 0.2, 1})
        frame.closeBtn.text = frame.closeBtn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        frame.closeBtn.text:SetPoint("CENTER", 0, 1)
        frame.closeBtn.text:SetText("Close")
        frame.closeBtn:SetScript("OnClick", function() frame:Hide() end)
        frame.closeBtn:SetScript("OnEnter", function() frame.closeBtn:SetBackdropColor(0.5, 0.5, 0.5, 1) end)
        frame.closeBtn:SetScript("OnLeave", function() frame.closeBtn:SetBackdropColor(0.2, 0.2, 0.2, 1) end)
		
		sAExportFrame = frame
		
    end

    local editBox = sAExportFrame.editBox
    editBox:SetText(exportString)
    editBox:SetFocus()
    editBox:HighlightText()
    frame:Show()
end

table.insert(UISpecialFrames, "sAExportFrame")

function sA:ExportAllAuras()
    local exportTable = {}
    for _, aura in ipairs(simpleAuras.auras) do
        table.insert(exportTable, deepCopy(aura))
    end
    
    local serialized = Serialize(exportTable)
    if serialized then
        sA:ShowExportFrame(serialized)
    else
        sA:Msg("Error during serialization.")
    end
end

function sA:ExportSingleAura(id)
    local auraToExport = deepCopy(simpleAuras.auras[id])
    local serialized = Serialize(auraToExport)

    if serialized then
        sA:ShowExportFrame(serialized)
    else
        sA:Msg("Error during serialization.")
    end
end

function sA:ShowImportFrame()

	if sAImportFrame then
		if sAImportFrame:IsVisible() then sAImportFrame:Hide() end
		sAImportFrame = nil
	end

	if sAExportFrame and sAExportFrame:IsVisible() then
		sAExportFrame:Hide()
	end

    if not sAImportFrame then
        frame = CreateFrame("Frame", "sAImportFrame", UIParent)
        frame:SetFrameStrata("DIALOG")
        frame:SetPoint("CENTER", 0, 0)
        frame:SetWidth(400)
        frame:SetHeight(200)
        sA:SkinFrame(frame)
        frame:SetMovable(true)
        frame:EnableMouse(true)
        frame:RegisterForDrag("LeftButton")
        frame:SetScript("OnDragStart", function() frame:StartMoving() end)
        frame:SetScript("OnDragStop", function() frame:StopMovingOrSizing() end)

        frame.title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        frame.title:SetPoint("TOP", 0, -10)
        frame.title:SetText("Paste Aura String to Import")
        
        frame.scroll = CreateFrame("ScrollFrame", "sAImportScrollFrame", frame)
        frame.scroll:SetPoint("TOPLEFT", 15, -30)
        frame.scroll:SetPoint("BOTTOMRIGHT", -15, 40)

        frame.editBox = CreateFrame("EditBox", "sAImportEditBox", frame.scroll)
        frame.editBox:SetMultiLine(true)
        frame.editBox:SetAutoFocus(false)
        frame.editBox:SetFontObject(GameFontHighlightSmall)
        frame.editBox:SetWidth(370)
        frame.editBox:SetHeight(120)
		frame.editBox:SetTextInsets(4, 4, 4, 4)
        frame.editBox:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8x8", edgeFile = "Interface\\Buttons\\WHITE8x8", edgeSize = 1 })
		frame.editBox:SetBackdropColor(0.1, 0.1, 0.1, 1)
		frame.editBox:SetBackdropBorderColor(0, 0, 0, 1)
		frame.editBox:SetScript("OnEscapePressed", function() frame.editBox:ClearFocus() end)
        frame.scroll:SetScrollChild(frame.editBox)

        frame.importBtn = CreateFrame("Button", "sAImportImportButton", frame)
        frame.importBtn:SetPoint("BOTTOMLEFT", 40, 10)
        frame.importBtn:SetWidth(80)
        frame.importBtn:SetHeight(22)
        sA:SkinFrame(frame.importBtn, {0.2, 0.2, 0.2, 1})
        frame.importBtn.text = frame.importBtn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        frame.importBtn.text:SetPoint("CENTER", 0, 1)
        frame.importBtn.text:SetText("Import")
        frame.importBtn:SetScript("OnClick", function()
            sA:ImportAuras(frame.editBox:GetText())
            frame:Hide()
        end)
        frame.importBtn:SetScript("OnEnter", function() frame.importBtn:SetBackdropColor(0.1, 0.4, 0.1, 1) end)
        frame.importBtn:SetScript("OnLeave", function() frame.importBtn:SetBackdropColor(0.2, 0.2, 0.2, 1) end)
        
        frame.cancelBtn = CreateFrame("Button", "sAImportCancelButton", frame)
        frame.cancelBtn:SetPoint("BOTTOMRIGHT", -40, 10)
        frame.cancelBtn:SetWidth(80)
        frame.cancelBtn:SetHeight(22)
        sA:SkinFrame(frame.cancelBtn, {0.2, 0.2, 0.2, 1})
        frame.cancelBtn.text = frame.cancelBtn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        frame.cancelBtn.text:SetPoint("CENTER", 0, 1)
        frame.cancelBtn.text:SetText("Cancel")
        frame.cancelBtn:SetScript("OnClick", function() frame:Hide() end)
        frame.cancelBtn:SetScript("OnEnter", function() frame.cancelBtn:SetBackdropColor(0.5, 0.5, 0.5, 1) end)
        frame.cancelBtn:SetScript("OnLeave", function() frame.cancelBtn:SetBackdropColor(0.2, 0.2, 0.2, 1) end)
		
		sAImportFrame = frame
		
    end
	
	local editBox = sAImportFrame.editBox
    editBox:SetText("")
    editBox:SetFocus()
    frame:Show()
	
end

table.insert(UISpecialFrames, "sAImportFrame")

function sA:ImportAuras(importString)
    if not importString or importString == "" then return end

	importString = "return " .. importString

    local success, data = Deserialize(importString)

    if not success then
        sA:Msg("Error: Invalid import string.")
        DEFAULT_CHAT_FRAME:AddMessage("|cFFFF0000sA Import Error: |r" .. tostring(data))
        return
    end

    if type(data) ~= "table" then
        sA:Msg("Error: Import data is not a valid table.")
        return
    end

    local importedCount = 0
    -- Check if it's a single aura (a table of settings) or multiple auras (an array of tables)
    if data[1] and type(data[1]) == "table" then -- It's likely an array of auras
        for _, auraData in ipairs(data) do
            if type(auraData) == "table" then
                table.insert(simpleAuras.auras, auraData)
                importedCount = importedCount + 1
            end
        end
    else -- It's likely a single aura
        table.insert(simpleAuras.auras, data)
        importedCount = 1
    end

    if importedCount > 0 then
        sA:Msg(importedCount .. " aura(s) imported successfully.")
		if importedCount == 1 then
			local newId = table.getn(simpleAuras.auras)
			sA:EditAura(newId)
		else
			sA:RefreshAuraList()
		end
    else
        sA:Msg("No valid auras found in the import string.")
    end
end

-- Init
sA:RefreshAuraList()
