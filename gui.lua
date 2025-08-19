-- Deep copy helper
local function deepCopy(tbl)
  local t = {}
  for k, v in pairs(tbl) do
    t[k] = (type(v) == "table") and deepCopy(v) or v
  end
  return t
end

-- Create Test frames (used by editor preview)
local TestAura = CreateFrame("Frame", "sATest", UIParent)
TestAura:SetFrameStrata("BACKGROUND")
TestAura:SetFrameLevel(128)
TestAura.texture = TestAura:CreateTexture(nil, "BACKGROUND")
TestAura.texture:SetAllPoints(TestAura)
TestAura.durationtext = TestAura:CreateFontString(nil, "OVERLAY", "GameFontNormal")
TestAura.durationtext:SetFont("Fonts\\FRIZQT__.TTF", 12, "OUTLINE")
TestAura.durationtext:SetPoint("CENTER", TestAura, "CENTER", 0, 0)
TestAura.stackstext = TestAura:CreateFontString(nil, "OVERLAY", "GameFontWhite")
TestAura.stackstext:SetFont("Fonts\\FRIZQT__.TTF", 10, "OUTLINE")
TestAura.stackstext:SetPoint("TOPLEFT", TestAura.durationtext, "CENTER", 1, -6)
TestAura:Hide()
sA.TestAura = TestAura

local TestAuraDual = CreateFrame("Frame", "sATestDual", UIParent)
TestAuraDual:SetFrameStrata("BACKGROUND")
TestAuraDual:SetFrameLevel(128)
TestAuraDual.texture = TestAuraDual:CreateTexture(nil, "BACKGROUND")
TestAuraDual.texture:SetAllPoints(TestAuraDual)
TestAuraDual.durationtext = TestAuraDual:CreateFontString(nil, "OVERLAY", "GameFontNormal")
TestAuraDual.durationtext:SetFont("Fonts\\FRIZQT__.TTF", 12, "OUTLINE")
TestAuraDual.durationtext:SetPoint("CENTER", TestAuraDual, "CENTER", 0, 0)
TestAuraDual.stackstext = TestAuraDual:CreateFontString(nil, "OVERLAY", "GameFontWhite")
TestAuraDual.stackstext:SetFont("Fonts\\FRIZQT__.TTF", 10, "OUTLINE")
TestAuraDual.stackstext:SetPoint("TOPLEFT", TestAuraDual.durationtext, "CENTER", 1, -6)
TestAuraDual:Hide()
sA.TestAuraDual = TestAuraDual

table.insert(UISpecialFrames, "sATest")
table.insert(UISpecialFrames, "sATestDual")

-- Main GUI frame
if not gui then
  gui = CreateFrame("Frame", "sAGUI", UIParent)
  gui:SetFrameStrata("HIGH")
  gui:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
  gui:SetWidth(300)
  gui:SetHeight(400)
  gui:SetMovable(true)
  gui:EnableMouse(true)
  gui:RegisterForDrag("LeftButton")
  gui:SetScript("OnDragStart", function() gui:StartMoving() end)
  gui:SetScript("OnDragStop", function() gui:StopMovingOrSizing() end)
  sA:SkinFrame(gui)

  local title = gui:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  title:SetPoint("TOP", 0, -5)
  title:SetText("simpleAuras")

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
addBtn:SetScript("OnClick", function() AddAura() end)
addBtn:SetScript("OnEnter", function() addBtn:SetBackdropColor(0.1, 0.4, 0.1, 1) end)
addBtn:SetScript("OnLeave", function() addBtn:SetBackdropColor(0.2, 0.2, 0.2, 1) end)

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
function RefreshAuraList()
  for _, entry in ipairs(gui.list or {}) do entry:Hide() end
  gui.list = {}

  for i, aura in ipairs(simpleAuras.auras) do
    local id = i
    local row = CreateFrame("Button", nil, gui)
    row:SetWidth(260)
    row:SetHeight(20)
    row:SetPoint("TOPLEFT", 20, -30 - (id - 1) * 22)
    sA:SkinFrame(row, {0.2, 0.2, 0.2, 1})
    row:SetScript("OnEnter", function() row:SetBackdropColor(0.5, 0.5, 0.5, 1) end)
    row:SetScript("OnLeave", function() row:SetBackdropColor(0.2, 0.2, 0.2, 1) end)

    row.text = row:CreateFontString(nil, "ARTWORK", "GameFontWhite")
    row.text:SetPoint("LEFT", 5, 0)
    row.text:SetText("[" .. id .. "] " .. (aura.name ~= "" and aura.name or "<unnamed>"))
    row.text:SetTextColor(unpack(aura.auracolor or {1, 1, 1}))
    row:SetScript("OnClick", function()
      if gui.editor then
        if sA.TestAura then sA.TestAura:Hide() end
        if sA.TestAuraDual then sA.TestAuraDual:Hide() end
        gui.editor:Hide()
        gui.editor = nil
      end
      sA:EditAura(id)
    end)

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
        simpleAuras.auras[id], simpleAuras.auras[id-1] = simpleAuras.auras[id-1], simpleAuras.auras[id]
        RefreshAuraList()
		if gui.editor then
          if sA.TestAura then sA.TestAura:Hide() end
          if sA.TestAuraDual then sA.TestAuraDual:Hide() end
          gui.editor:Hide()
          gui.editor = nil
		  sA:EditAura(id-1)
        end
      end)
    end

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
        simpleAuras.auras[id], simpleAuras.auras[id+1] = simpleAuras.auras[id+1], simpleAuras.auras[id]
        RefreshAuraList()
		if gui.editor then
          if sA.TestAura then sA.TestAura:Hide() end
          if sA.TestAuraDual then sA.TestAuraDual:Hide() end
          gui.editor:Hide()
          gui.editor = nil
		  sA:EditAura(id+1)
        end
      end)
    end

    gui.list[id] = row
  end
end

-- Save aura data from editor
function SaveAura(id)
  local ed = gui.editor
  if not ed then return end
  local data = simpleAuras.auras[id]
  data.name            = ed.name:GetText()
  data.auracolor       = ed.auracolor
  data.autodetect      = ed.autoDetect.value
  data.texture         = ed.texturePath:GetText()
  data.scale           = tonumber(ed.scale:GetText())
  data.xpos            = tonumber(ed.x:GetText())
  data.ypos            = tonumber(ed.y:GetText())
  data.duration        = ed.duration.value
  data.stacks          = ed.stacks.value
  data.lowduration     = ed.lowduration.value
  data.lowdurationvalue= tonumber(ed.lowdurationvalue:GetText())
  data.lowdurationcolor= ed.lowdurationcolor
  data.unit            = ed.unitButton.text:GetText()
  data.type            = ed.typeButton.text:GetText()
  data.inCombat        = ed.inCombat.value
  data.outCombat       = ed.outCombat.value
  data.invert          = ed.invert.value
  data.dual            = ed.dual.value

  ed.name:ClearFocus()
  ed.texturePath:ClearFocus()
  ed.scale:ClearFocus()
  ed.x:ClearFocus()
  ed.y:ClearFocus()
  ed.lowdurationvalue:ClearFocus()

  if sA.TestAura then sA.TestAura:Hide() end
  if sA.TestAuraDual then sA.TestAuraDual:Hide() end
  ed:Hide()
  gui.editor = nil
  RefreshAuraList()
  sA:EditAura(id)
end

-- Add new aura (optionally copy from existing)
function AddAura(copyId)
  table.insert(simpleAuras.auras, {})
  local newId = table.getn(simpleAuras.auras)
  if copyId and simpleAuras.auras[copyId] then
    simpleAuras.auras[newId] = deepCopy(simpleAuras.auras[copyId])
  else
    simpleAuras.auras[newId] = { name = "", texture = "Interface\\Icons\\INV_Misc_QuestionMark" }
  end
  if gui.editor and gui.editor:IsShown() then
    gui.editor:Hide()
    gui.editor = nil
    if sA.TestAura then sA.TestAura:Hide() end
    if sA.TestAuraDual then sA.TestAuraDual:Hide() end
  end
  sA:UpdateAuras()
  RefreshAuraList()
  sA:EditAura(newId)
end

-- Editor window / show and build controls
function sA:EditAura(id)
  local aura = simpleAuras.auras[id]
  if not aura then return end

  local ed = gui.editor
  if not ed then
    ed = CreateFrame("Frame", "sAEdit", gui)
    ed:SetWidth(300)
    ed:SetHeight(400)
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

    -- Name
    ed.nameLabel = ed:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    ed.nameLabel:SetPoint("TOPLEFT", ed, "TOPLEFT", 12.5, -40)
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
    ed.name:SetJustifyH("LEFT")
    ed.name:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8x8", edgeFile = "Interface\\Buttons\\WHITE8x8", edgeSize = 1 })
    ed.name:SetBackdropColor(0.1, 0.1, 0.1, 1)
    ed.name:SetBackdropBorderColor(0, 0, 0, 1)
    ed.name:SetScript("OnEnterPressed", function() SaveAura(id) end)

    -- Separator
    local lineone = ed:CreateTexture(nil, "ARTWORK")
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
	  SaveAura(id)
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
    ed.texturePath:SetFontObject(GameFontHighlightSmall)
    ed.texturePath:SetTextColor(1,1,1)
    ed.texturePath:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8x8", edgeFile = "Interface\\Buttons\\WHITE8x8", edgeSize = 1 })
    ed.texturePath:SetBackdropColor(0.1,0.1,0.1,1)
    ed.texturePath:SetBackdropBorderColor(0,0,0,1)
    ed.texturePath:SetScript("OnEnterPressed", function() SaveAura(id) end)

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
    ed.scale:SetScript("OnEnterPressed", function() SaveAura(id) end)

    ed.xLabel = ed:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    ed.xLabel:SetPoint("LEFT", ed.scale, "RIGHT", 35, 0)
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
    ed.x:SetScript("OnEnterPressed", function() SaveAura(id) end)

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
    ed.y:SetScript("OnEnterPressed", function() SaveAura(id) end)

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
	  SaveAura(id)
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
	  SaveAura(id)
    end)
    ed.stacksLabel = ed:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    ed.stacksLabel:SetPoint("LEFT", ed.stacks, "RIGHT", 5, 0)
    ed.stacksLabel:SetText("Show Stacks")

    -- Conditions (unit / type)
    local linetwo = ed:CreateTexture(nil, "ARTWORK")
    linetwo:SetTexture("Interface\\Buttons\\WHITE8x8")
    linetwo:SetVertexColor(1, 0.8, 0.06, 1)
    linetwo:SetPoint("TOPLEFT", ed.duration, "BOTTOMLEFT", 0, -15)
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
        menu:SetHeight(40)
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
            SaveAura(id)
          end)
        end
        makeChoice("Buff", 1)
        makeChoice("Debuff", 2)
        makeChoice("Cooldown", 3)
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
			SaveAura(id)
		  end)
		end
		makeChoice("Player", 1)
		makeChoice("Target", 2)
	  end
	  local menu = ed.unitButton.menu
	  if menu:IsVisible() then menu:Hide() else menu:Show() end
	end)

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
	  SaveAura(id)
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
    ed.lowdurationvalue:SetScript("OnEnterPressed", function() SaveAura(id) end)

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
	  SaveAura(id)
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
	  SaveAura(id)
    end)

    ed.outcombatLabel = ed:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    ed.outcombatLabel:SetPoint("LEFT", ed.outCombat, "RIGHT", 5, 1)
    ed.outcombatLabel:SetText("Out of Combat")

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
	  SaveAura(id)
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
	  SaveAura(id)
    end)
    ed.dualLabel = ed:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    ed.dualLabel:SetPoint("LEFT", ed.dual, "RIGHT", 5, 0)
    ed.dualLabel:SetText("Dual")
	
	if aura.type == "Cooldown" then
		ed.unitLabel:Hide()
		ed.unitButton:Hide()
		ed.invertLabel:SetText("No CD")
		ed.dualLabel:SetText("CD")
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

    gui.editor = ed
  end

  -- Populate fields with aura values
  ed.title:SetText("[" .. tostring(id) .. "] " .. (aura.name ~= "" and aura.name or "<unnamed>"))
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

  ed.stacks.value = aura.stacks or 0
  if ed.stacks.value == 1 then ed.stacks.checked:Show() else ed.stacks.checked:Hide() end

  ed.lowduration.value = aura.lowduration or 0
  if ed.lowduration.value == 1 then ed.lowduration.checked:Show() else ed.lowduration.checked:Hide() end
  ed.lowdurationvalue:SetText(aura.lowdurationvalue or 5)
  ed.lowdurationcolor = aura.lowdurationcolor or {1,0,0,1}
  ed.lowdurationcolorpicker.prev:SetTexture(unpack(ed.lowdurationcolor))

  ed.typeButton.text:SetText(aura.type or "Buff")
  if ed.unitButton then
	ed.unitButton.text:SetText(aura.unit or "Player")
  end
  ed.inCombat.value = aura.inCombat or 0
  if ed.inCombat.value == 1 then ed.inCombat.checked:Show() else ed.inCombat.checked:Hide() end
  ed.outCombat.value = aura.outCombat or 0
  if ed.outCombat.value == 1 then ed.outCombat.checked:Show() else ed.outCombat.checked:Hide() end
  ed.invert.value = aura.invert or 0
  if ed.invert.value == 1 then ed.invert.checked:Show() else ed.invert.checked:Hide() end
  ed.dual.value = aura.dual or 0
  if ed.dual.value == 1 then ed.dual.checked:Show() else ed.dual.checked:Hide() end

  -- Show Test aura(s)
  sA.TestAura:SetPoint("CENTER", UIParent, "CENTER", aura.xpos or 0, aura.ypos or 0)
  sA.TestAura:SetWidth(48*(aura.scale or 1))
  sA.TestAura:SetHeight(48*(aura.scale or 1))
  sA.TestAura.texture:SetTexture(aura.texture)
  sA.TestAura.texture:SetVertexColor(unpack(aura.auracolor or {1,1,1,1}))
  if aura.duration == 1 then sA.TestAura.durationtext:SetText("60") sA.TestAura.durationtext:SetFont("Fonts\\FRIZQT__.TTF", (20*aura.scale), "OUTLINE") else sA.TestAura.durationtext:SetText("") end
  if aura.stacks == 1 then sA.TestAura.stackstext:SetText("20") sA.TestAura.stackstext:SetFont("Fonts\\FRIZQT__.TTF", (14*aura.scale), "OUTLINE") else sA.TestAura.stackstext:SetText("") end
	  
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
    if aura.duration == 1 then sA.TestAuraDual.durationtext:SetText("60") sA.TestAuraDual.durationtext:SetFont("Fonts\\FRIZQT__.TTF", (20*aura.scale), "OUTLINE") else sA.TestAuraDual.durationtext:SetText("") end
    if aura.stacks == 1 then sA.TestAuraDual.stackstext:SetText("20") sA.TestAuraDual.stackstext:SetFont("Fonts\\FRIZQT__.TTF", (14*aura.scale), "OUTLINE") else sA.TestAuraDual.stackstext:SetText("") end
    sA.TestAuraDual:Show()
  else
    sA.TestAuraDual:Hide()
  end

  -- Editor button handlers
  ed.close:SetScript("OnClick", function() ed:Hide(); gui.editor = nil; sA.TestAura:Hide(); sA.TestAuraDual:Hide() end)
  ed.copy:SetScript("OnClick", function() AddAura(id) end)

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
      ed.confirm:Hide()
      ed:Hide()
      gui.editor = nil
      RefreshAuraList()
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
      local tex = btn:CreateTexture(nil, "BACKGROUND")
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
        SaveAura(id)
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
    local maxScroll = math.max(0, contentHeight - visibleHeight - 313)
    scrollbar:SetMinMaxValues(0, maxScroll)
    scrollbar:SetValue(0)
	
  end)

  -- ensure editor visible
  ed:Show()
end

-- Init
RefreshAuraList()

-- Slash Command
SLASH_sA1 = "/sa"
SLASH_sA2 = "/simpleauras"
SlashCmdList["sA"] = function(msg)

	-- Get Command
	if type(msg) ~= "string" then
		msg = ""
	end

	-- Get Command Arguments
	local cmd, val
	local s, e, a, b = string.find(msg, "^(%S*)%s*(%S*)$")
	if a then cmd = a else cmd = "" end
	if b then val = b else val = "" end
	
	-- hide / show or no command
	if cmd == "" or cmd == "show" or cmd == "hide" then
		if cmd == "show" then
			if not gui:IsVisible() then gui:Show() end
		elseif cmd == "hide" then
			if gui:IsVisible() then gui:Hide() sA.TestAura:Hide() sA.TestAuraDual:Hide() end
		else 
			if gui:IsVisible() then gui:Hide() sA.TestAura:Hide() sA.TestAuraDual:Hide() else gui:Show() end
		end
		RefreshAuraList()
		return
	end
	
	-- refresh command
	if cmd == "refresh" then
		local num = tonumber(val)
		if num and num >= 1 and num <= 100 then
			simpleAuras.refresh = num
			DEFAULT_CHAT_FRAME:AddMessage("refresh set to " .. num .. " times per second")
		else
			DEFAULT_CHAT_FRAME:AddMessage("Usage: /sa refresh X - Set refresh rate. (1 to 100 updates per second. Default: 10)")
			DEFAULT_CHAT_FRAME:AddMessage("Current refresh = " .. tostring(simpleAuras.refresh) .. " times per second")
		end
		return
	end

	-- Unknown command fallback
	DEFAULT_CHAT_FRAME:AddMessage("Usage:")
	DEFAULT_CHAT_FRAME:AddMessage("/sa or /sa show or /sa hide - Show/hide simpleAuras Settings")
	DEFAULT_CHAT_FRAME:AddMessage("/sa refresh X - Set refresh rate. (1 to 100 updates per second. Default: 10)")

end
