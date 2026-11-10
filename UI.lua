-- UI: Hauptmenü im Stil von Google Maps.
--   Kopf:   Suchleiste mit Lupe
--   Karte:  "Dein Standort" (blauer Punkt) -> Ziel (roter Pin), Verkehrsmittel-Chips
--   Leiste: große Reisezeit + Ankunftszeit + blauer "Starten"-Knopf
--   Liste:  Schritte als Zeilen mit Symbol, Text und Dauer
-- Alle Texte aus WF.L (Deutsch/Englisch je nach Client).
local _, WF = ...
local L, U = WF.L, WF.Util
local UI = {}
WF.UI = UI

-- Farben (Google-Maps-ähnlich, dunkles Thema passend zu WoW)
local C = {
  bg = {0.11, 0.12, 0.14, 0.97}, card = {0.17, 0.18, 0.21, 1}, line = {0.28, 0.29, 0.33, 1},
  blue = {0.10, 0.45, 0.91}, blueHi = {0.20, 0.55, 1.0}, red = {0.92, 0.26, 0.21},
  green = {0.20, 0.70, 0.33}, text = {0.95, 0.95, 0.95}, sub = {0.62, 0.64, 0.68},
}
local MODEICON = {
  walk = "Interface\\Icons\\Ability_Tracking", taxi = "Interface\\Icons\\Ability_Mount_Gryphon_01",
  ship = "Interface\\Icons\\INV_Misc_Anchor", zeppelin = "Interface\\Icons\\INV_Misc_Bomb_04",
  tram = "Interface\\Icons\\INV_Gizmo_02",
}
local DUNGEON_ICON = "|TInterface\\Minimap\\Dungeon:14|t"
local RAID_ICON    = "|TInterface\\Minimap\\Raid:14|t"
local ZONE_ICON    = "|TInterface\\Icons\\INV_Misc_Map_01:14|t"

local function fill(parent, col, layer)
  local t = parent:CreateTexture(nil, layer or "BACKGROUND"); t:SetAllPoints(); t:SetColorTexture(unpack(col)); return t
end
local function text(parent, size, col, flags)
  local fs = parent:CreateFontString(nil, "OVERLAY")
  fs:SetFont(STANDARD_TEXT_FONT, size, flags); fs:SetTextColor(unpack(col or C.text)); fs:SetJustifyH("LEFT")
  return fs
end
local function dot(parent, col, size)
  local t = parent:CreateTexture(nil, "ARTWORK"); t:SetSize(size, size)
  t:SetTexture("Interface\\COMMON\\Indicator-Gray"); t:SetVertexColor(unpack(col)); return t
end
local function flatButton(parent, label, w, h, col, colHi)
  local b = CreateFrame("Button", nil, parent)
  b:SetSize(w, h)
  b.bg = fill(b, col, "BACKGROUND")
  b.fs = text(b, 13, C.text, ""); b.fs:SetPoint("CENTER"); b.fs:SetJustifyH("CENTER"); b.fs:SetText(label)
  b:SetScript("OnEnter", function() b.bg:SetColorTexture(unpack(colHi or col)) end)
  b:SetScript("OnLeave", function() b.bg:SetColorTexture(unpack(col)) end)
  return b
end

-- Hauptfenster -----------------------------------------------------------------
local f = CreateFrame("Frame", "RoutewiseFrame", UIParent)
f:SetSize(360, 600); f:SetPoint("CENTER"); f:SetFrameStrata("HIGH"); f:Hide()
f:SetMovable(true); f:EnableMouse(true); f:RegisterForDrag("LeftButton"); f:SetClampedToScreen(true)
f:SetScript("OnDragStart", f.StartMoving); f:SetScript("OnDragStop", f.StopMovingOrSizing)
tinsert(UISpecialFrames, "RoutewiseFrame")
fill(f, C.bg)

-- Kopfzeile mit Titel und Schließen
local head = CreateFrame("Frame", nil, f); head:SetPoint("TOPLEFT"); head:SetPoint("TOPRIGHT"); head:SetHeight(30)
local title = text(head, 13, C.sub); title:SetPoint("LEFT", 12, 0); title:SetText(L.TITLE)
local close = CreateFrame("Button", nil, head, "UIPanelCloseButtonNoScripts")
close:SetPoint("RIGHT", -2, 0); close:SetScript("OnClick", function() f:Hide() end)

-- Suchleiste (abgerundete Karte mit Lupe) ---------------------------------------
local bar = CreateFrame("Frame", nil, f); bar:SetPoint("TOPLEFT", 12, -34); bar:SetPoint("TOPRIGHT", -12, -34); bar:SetHeight(36)
fill(bar, C.card)
local lupe = bar:CreateTexture(nil, "ARTWORK"); lupe:SetSize(16, 16); lupe:SetPoint("LEFT", 10, 0)
lupe:SetAtlas("common-search-magnifyingglass"); if not lupe:GetAtlas() then lupe:SetTexture("Interface\\Common\\UI-Searchbox-Icon") end
local search = CreateFrame("EditBox", nil, bar)
search:SetPoint("LEFT", lupe, "RIGHT", 8, 0); search:SetPoint("RIGHT", -10, 0); search:SetHeight(30)
search:SetFont(STANDARD_TEXT_FONT, 14, ""); search:SetTextColor(unpack(C.text)); search:SetAutoFocus(false)
local ph = text(search, 14, C.sub); ph:SetPoint("LEFT"); ph:SetText(L.SEARCH)

-- Vorschlagsliste
local chosen
local pick -- Auswahlliste (wird weiter unten erstellt)
local sug = CreateFrame("Frame", nil, f); sug:SetPoint("TOPLEFT", bar, "BOTTOMLEFT", 0, -2); sug:SetPoint("TOPRIGHT", bar, "BOTTOMRIGHT", 0, -2)
sug:SetFrameLevel(f:GetFrameLevel() + 20); fill(sug, C.card); sug:Hide()
local rows = {}
for i = 1, 8 do
  local b = CreateFrame("Button", nil, sug); b:SetHeight(26)
  b:SetPoint("TOPLEFT", 0, -(i - 1) * 26); b:SetPoint("TOPRIGHT", 0, -(i - 1) * 26)
  local hl = fill(b, C.line, "HIGHLIGHT")
  b.fs = text(b, 12); b.fs:SetPoint("LEFT", 10, 0); b.fs:SetPoint("RIGHT", -10, 0); b.fs:SetWordWrap(false)
  b:SetScript("OnClick", function(self) UI.Choose(self.item) end)
  rows[i] = b
end

local function refreshSuggest()
  local q = search:GetText():lower()
  ph:SetShown(q == "")
  if q == "" or (chosen and chosen.name:lower() == q) then sug:Hide(); return end
  local n = 0
  local function add(z, label)
    if n < #rows and (z.name:lower():find(q, 1, true) or (z.zone and z.zone:lower():find(q, 1, true))) then
      n = n + 1; rows[n].item = z; rows[n].fs:SetText(label); rows[n]:Show()
    end
  end
  for _, d in ipairs(WF.Dungeons.Build()) do
    add(d, (d.raid and RAID_ICON or DUNGEON_ICON) .. "  " .. d.name .. (d.raid and "  |cffff8000Raid|r" or "")
      .. "  |cff9a9ea8" .. d.zone .. "|r")
  end
  for _, z in ipairs(WF.MapResolver.Zones()) do add(z, ZONE_ICON .. "  " .. z.name) end
  for i = n + 1, #rows do rows[i]:Hide() end
  sug:SetHeight(n * 26); sug:SetShown(n > 0)
end
search:SetScript("OnTextChanged", function(_, user) if user then chosen = nil; if pick then pick:Hide() end end refreshSuggest() end)
search:SetScript("OnEnterPressed", function() if rows[1]:IsShown() then rows[1]:Click() end end)
search:SetScript("OnEscapePressed", function(self) self:ClearFocus(); sug:Hide() end)


-- Auswahl-Reiter: Dungeons | Raids | Zonen  (Liste zum Anklicken, kein Tippen nötig) --
local tabs = CreateFrame("Frame", nil, f); tabs:SetPoint("TOPLEFT", bar, "BOTTOMLEFT", 0, -6)
tabs:SetPoint("TOPRIGHT", bar, "BOTTOMRIGHT", 0, -6); tabs:SetHeight(26)

pick = CreateFrame("Frame", nil, f); pick:SetPoint("TOPLEFT", tabs, "BOTTOMLEFT", 0, -4)
pick:SetPoint("BOTTOMRIGHT", -12, 12); pick:SetFrameLevel(f:GetFrameLevel() + 15); fill(pick, C.card); pick:Hide()
pick:EnableMouse(true)
local pickFilter = CreateFrame("EditBox", nil, pick, "SearchBoxTemplate")
pickFilter:SetPoint("TOPLEFT", 12, -6); pickFilter:SetPoint("TOPRIGHT", -8, -6); pickFilter:SetHeight(22)
pickFilter:SetAutoFocus(false)
local pickScroll = CreateFrame("ScrollFrame", nil, pick, "ScrollFrameTemplate")
pickScroll:SetPoint("TOPLEFT", 0, -34); pickScroll:SetPoint("BOTTOMRIGHT", -24, 4)
local pickList = CreateFrame("Frame", nil, pickScroll); pickList:SetSize(300, 10); pickScroll:SetScrollChild(pickList)
local pickRows, pickTab = {}, nil

local function pickRow(i)
  if pickRows[i] then return pickRows[i] end
  local b = CreateFrame("Button", nil, pickList); b:SetHeight(30)
  b:SetPoint("TOPLEFT", 0, -(i - 1) * 30); b:SetPoint("RIGHT", pickScroll, "RIGHT", 0, 0)
  fill(b, C.line, "HIGHLIGHT")
  b.fs = text(b, 12); b.fs:SetPoint("TOPLEFT", 10, -4); b.fs:SetPoint("RIGHT", -8, 0); b.fs:SetWordWrap(false)
  b.sub = text(b, 10, C.sub); b.sub:SetPoint("TOPLEFT", b.fs, "BOTTOMLEFT", 0, -2); b.sub:SetPoint("RIGHT", -8, 0)
  b:SetScript("OnClick", function(self) pick:Hide(); UI.Choose(self.item) end)
  pickRows[i] = b; return b
end

local function source(tab)
  local out = {}
  if tab == "zone" then
    for _, z in ipairs(WF.MapResolver.Zones()) do out[#out + 1] = z end
  else
    for _, d in ipairs(WF.Dungeons.Build()) do
      if (tab == "raid") == (d.raid and true or false) then out[#out + 1] = d end
    end
  end
  return out
end

local function fillPicker()
  local q = (pickFilter:GetText() or ""):lower()
  local n = 0
  for _, item in ipairs(source(pickTab)) do
    if q == "" or item.name:lower():find(q, 1, true) or (item.zone and item.zone:lower():find(q, 1, true)) then
      n = n + 1
      local r = pickRow(n); r.item = item; r:Show()
      local icon = pickTab == "raid" and RAID_ICON or pickTab == "dungeon" and DUNGEON_ICON or ZONE_ICON
      r.fs:SetText(icon .. "  " .. item.name)
      r.sub:SetText(item.zone or "")
    end
  end
  for i = n + 1, #pickRows do pickRows[i]:Hide() end
  if n == 0 then
    local r = pickRow(1); r.item = nil; r:Show(); r.fs:SetText("|cff9a9ea8" .. L.NOENTRIES .. "|r"); r.sub:SetText("")
    r:SetScript("OnClick", nil)
  else
    pickRows[1]:SetScript("OnClick", function(self) if self.item then pick:Hide(); UI.Choose(self.item) end end)
  end
  pickList:SetHeight(math.max(n, 1) * 30)
end
pickFilter:HookScript("OnTextChanged", fillPicker)

local tabBtns = {}
local function selectTab(key)
  if pickTab == key and pick:IsShown() then pick:Hide(); pickTab = nil
  else pickTab = key; pickFilter:SetText(""); sug:Hide(); pick:Show(); pickScroll:SetVerticalScroll(0); fillPicker() end
  for k, b in pairs(tabBtns) do b.bg:SetColorTexture(unpack(k == pickTab and pick:IsShown() and C.blue or C.card)) end
end
local x = 0
for _, t in ipairs({ { "dungeon", L.TAB_DUNGEONS, DUNGEON_ICON }, { "raid", L.TAB_RAIDS, RAID_ICON }, { "zone", L.TAB_ZONES, ZONE_ICON } }) do
  local b = flatButton(tabs, t[3] .. " " .. t[2], 108, 26, C.card, C.line)
  b:SetPoint("LEFT", x, 0); x = x + 114
  b:SetScript("OnLeave", function() b.bg:SetColorTexture(unpack(t[1] == pickTab and pick:IsShown() and C.blue or C.card)) end)
  b:SetScript("OnClick", function() selectTab(t[1]) end)
  tabBtns[t[1]] = b
end
pick:SetScript("OnHide", function() for _, b in pairs(tabBtns) do b.bg:SetColorTexture(unpack(C.card)) end end)

-- Routenkarte: Start (blauer Punkt) ⋮ Ziel (roter Pin) ----------------------------
local trip = CreateFrame("Frame", nil, f); trip:SetPoint("TOPLEFT", tabs, "BOTTOMLEFT", 0, -8)
trip:SetPoint("TOPRIGHT", tabs, "BOTTOMRIGHT", 0, -8); trip:SetHeight(70); fill(trip, C.card)
local dStart = dot(trip, C.blue, 12); dStart:SetPoint("TOPLEFT", 12, -14)
local dDest = trip:CreateTexture(nil, "ARTWORK"); dDest:SetSize(14, 18); dDest:SetPoint("TOPLEFT", 11, -44)
dDest:SetAtlas("Waypoint-MapPin-Untracked"); if not dDest:GetAtlas() then dDest:SetTexture("Interface\\Minimap\\POIIcons") end
dDest:SetVertexColor(unpack(C.red))
for i = 0, 2 do local d = dot(trip, C.sub, 3); d:SetPoint("TOP", dStart, "BOTTOM", 0, -3 - i * 5) end
local startFs = text(trip, 12); startFs:SetPoint("LEFT", dStart, "RIGHT", 12, 0); startFs:SetPoint("RIGHT", -10, 0)
local destFs = text(trip, 12, C.sub); destFs:SetPoint("LEFT", dDest, "RIGHT", 11, 0); destFs:SetPoint("RIGHT", -10, 0)
local sep = trip:CreateTexture(nil, "ARTWORK"); sep:SetColorTexture(unpack(C.line)); sep:SetHeight(1)
sep:SetPoint("LEFT", startFs, "LEFT", 0, -15); sep:SetPoint("RIGHT", -10, 0)

local function refreshStart()
  local mapID = C_Map.GetBestMapForUnit("player")
  local info = mapID and C_Map.GetMapInfo(mapID)
  startFs:SetText(L.HERE .. "  |cff9a9ea8" .. (info and info.name or "?") .. "|r")
end
local zev = CreateFrame("Frame")
zev:RegisterEvent("ZONE_CHANGED"); zev:RegisterEvent("ZONE_CHANGED_NEW_AREA"); zev:RegisterEvent("PLAYER_ENTERING_WORLD")
zev:SetScript("OnEvent", function() if f:IsShown() then refreshStart() end end)

-- Kartenwegpunkt als Ziel (kleiner Link unter der Routenkarte)
local wpLink = CreateFrame("Button", nil, f); wpLink:SetSize(200, 18); wpLink:SetPoint("TOPLEFT", trip, "BOTTOMLEFT", 2, -6)
local wpFs = text(wpLink, 11, C.blueHi); wpFs:SetPoint("LEFT"); wpFs:SetText("+ " .. L.MAPWP)
wpLink:SetScript("OnEnter", function() wpFs:SetTextColor(1, 1, 1) end)
wpLink:SetScript("OnLeave", function() wpFs:SetTextColor(unpack(C.blueHi)) end)

-- Zusammenfassung: große Reisezeit, Ankunft, Verkehrsmittel-Chips, Starten-Knopf ---
local sum = CreateFrame("Frame", nil, f); sum:SetPoint("TOPLEFT", wpLink, "BOTTOMLEFT", -2, -6)
sum:SetPoint("RIGHT", bar, "RIGHT"); sum:SetHeight(84); fill(sum, C.card)
local bigTime = text(sum, 22, C.green, ""); bigTime:SetPoint("TOPLEFT", 12, -10)
local arrive = text(sum, 12, C.sub); arrive:SetPoint("LEFT", bigTime, "RIGHT", 10, -2)
local chips = {}
for i = 1, 6 do
  local t = sum:CreateTexture(nil, "ARTWORK"); t:SetSize(18, 18); t:SetPoint("TOPLEFT", 12 + (i - 1) * 24, -44)
  t:SetTexCoord(0.08, 0.92, 0.08, 0.92); chips[i] = t
end
local go = flatButton(sum, L.STARTBTN, 110, 30, C.blue, C.blueHi); go:SetPoint("BOTTOMRIGHT", -10, 10)
local stopB = flatButton(sum, L.STOP, 70, 30, C.line, {0.35, 0.36, 0.40, 1}); stopB:SetPoint("RIGHT", go, "LEFT", -6, 0)

-- Schrittliste ----------------------------------------------------------------
local stepsHdr = text(f, 12, C.sub); stepsHdr:SetPoint("TOPLEFT", sum, "BOTTOMLEFT", 2, -10); stepsHdr:SetText(L.ROUTE)
local scroll = CreateFrame("ScrollFrame", nil, f, "ScrollFrameTemplate")
scroll:SetPoint("TOPLEFT", stepsHdr, "BOTTOMLEFT", -2, -6); scroll:SetPoint("BOTTOMRIGHT", -26, 12)
local list = CreateFrame("Frame", nil, scroll); list:SetSize(310, 10); scroll:SetScrollChild(list)
local stepRows = {}
local function stepRow(i)
  if stepRows[i] then return stepRows[i] end
  local r = CreateFrame("Frame", nil, list); r:SetSize(310, 46)
  r:SetPoint("TOPLEFT", 0, -(i - 1) * 48)
  r.bg = fill(r, C.card)
  r.icon = r:CreateTexture(nil, "ARTWORK"); r.icon:SetSize(24, 24); r.icon:SetPoint("LEFT", 10, 0)
  r.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
  r.main = text(r, 12); r.main:SetPoint("TOPLEFT", r.icon, "TOPRIGHT", 10, 2); r.main:SetPoint("RIGHT", -60, 0)
  r.main:SetWordWrap(false)
  r.sub = text(r, 11, C.sub); r.sub:SetPoint("TOPLEFT", r.main, "BOTTOMLEFT", 0, -3); r.sub:SetPoint("RIGHT", -60, 0)
  r.sub:SetWordWrap(false)
  r.dur = text(r, 11, C.sub); r.dur:SetPoint("RIGHT", -10, 0); r.dur:SetJustifyH("RIGHT")
  r.bar = r:CreateTexture(nil, "ARTWORK"); r.bar:SetWidth(3); r.bar:SetPoint("TOPLEFT"); r.bar:SetPoint("BOTTOMLEFT")
  stepRows[i] = r; return r
end
local empty = text(list, 12, C.sub); empty:SetPoint("TOPLEFT", 4, -4); empty:SetWidth(300); empty:SetWordWrap(true)

-- Ziel auswählen / Route starten ---------------------------------------------------
local pending -- Ziel, das gewählt, aber noch nicht gestartet ist

local function preview(goal)
  pending = goal
  destFs:SetTextColor(unpack(C.text)); destFs:SetText(goal.label)
  -- Vorschau rechnen, ohne zu navigieren
  local cont, wx, wy, mapID = U.PlayerWorld()
  if not cont then return end
  local route, total = WF.Pathfinder.Find({ cont = cont, wx = wx, wy = wy, mapID = mapID, label = L.HERE }, goal)
  UI.Render(route, total, 0)
end

function UI.Choose(item)
  chosen = item; search:SetText(item.name); search:ClearFocus(); sug:Hide()
  if not item.mapID and item.zoneNames then item.mapID = WF.MapResolver.Find(item.zoneNames) end
  if not item.mapID then WF:Print(L.NOZONE:format(item.zone or item.name)); return end
  local x, y = item.dungeon and item.x or 0.5, item.dungeon and item.y or 0.5
  local cont, wx, wy = U.ToWorld(item.mapID, x, y)
  if not cont then WF:Print(L.NOPOS); return end
  preview({ cont = cont, wx = wx, wy = wy, mapID = item.mapID, label = item.name })
end

function UI.FromMapWaypoint(startNow)
  local wp = C_Map.GetUserWaypoint and C_Map.GetUserWaypoint()
  if not wp then WF:Print(L.NOWP); return end
  local x, y = wp.position:GetXY()
  local cont, wx, wy = U.ToWorld(wp.uiMapID, x, y)
  if not cont then WF:Print(L.NOPOS); return end
  local info = C_Map.GetMapInfo(wp.uiMapID)
  -- userWaypoint: der Navigator überschreibt diesen Wegpunkt nicht und löscht ihn am Ende nicht
  local goal = { cont = cont, wx = wx, wy = wy, mapID = wp.uiMapID, userWaypoint = true,
                 label = ("%s %.0f, %.0f"):format(info and info.name or L.MAPPOINT, x * 100, y * 100) }
  if startNow then WF.Navigator.Start(goal) else preview(goal) end
end
wpLink:SetScript("OnClick", function() UI.FromMapWaypoint(false) end)

go:SetScript("OnClick", function()
  if not pending and search:GetText() ~= "" then
    local id = WF.MapResolver.Find(search:GetText())
    if id then UI.Choose({ name = search:GetText(), mapID = id }) end
  end
  if pending then WF.Navigator.Start(pending) else WF:Print(L.NOZONE:format(search:GetText())) end
end)
stopB:SetScript("OnClick", function() WF.Navigator.Stop() end)

-- Darstellung einer Route (Vorschau oder aktive Navigation)
function UI.Render(route, total, activeLeg)
  for _, r in ipairs(stepRows) do r:Hide() end
  for _, c in ipairs(chips) do c:Hide() end
  if not route then
    bigTime:SetText(""); arrive:SetText("")
    empty:SetText(pending and (L.NOROUTE .. "\n\n" .. L.NOTAXI) or L.NOTAXI); empty:Show()
    go:SetEnabled(false); go:SetAlpha(0.5); return
  end
  empty:Hide(); go:SetEnabled(true); go:SetAlpha(1)
  bigTime:SetText(U.FormatTime(total))
  arrive:SetText(L.ARRIVAL:format(date("%H:%M", time() + total)))
  -- Chips: Folge der Verkehrsmittel ohne Wiederholungen
  local n, last = 0, nil
  for _, l in ipairs(route) do
    if l.mode ~= last and n < #chips then n = n + 1; chips[n]:SetTexture(MODEICON[l.mode]); chips[n]:Show(); last = l.mode end
  end
  for i, l in ipairs(route) do
    local r = stepRow(i); r:Show()
    r.icon:SetTexture(MODEICON[l.mode])
    r.main:SetText(WF.Navigator.Describe(l))
    r.sub:SetText(l.mode ~= "walk" and (L.BOARD .. ": " .. WF.Navigator.Label(l.from))
      or (math.floor(U.Dist(l.from.wx, l.from.wy, l.to.wx, l.to.wy) * 0.9144 + 0.5) .. " m"))
    r.dur:SetText(U.FormatTime(l.cost))
    local done, now = activeLeg > 0 and i < activeLeg, i == activeLeg
    r:SetAlpha(done and 0.45 or 1)
    r.bar:SetColorTexture(unpack(now and C.blue or C.card))
  end
  list:SetHeight(#route * 48)
end

function UI.RefreshRoute()
  local N = WF.Navigator
  if N.route then
    pending = N.goal
    destFs:SetTextColor(unpack(C.text)); destFs:SetText(N.goal.label or "?")
    UI.Render(N.route, N.total, N.leg)
  elseif pending then
    preview(pending)
  else
    destFs:SetTextColor(unpack(C.sub)); destFs:SetText(L.DEST)
    UI.Render(nil)
  end
end
WF:On("ROUTE_CHANGED", function(r) if not r then pending = nil end UI.RefreshRoute() end)
WF:On("LEG_CHANGED", UI.RefreshRoute)
f:SetScript("OnShow", function() refreshStart(); UI.RefreshRoute() end)

function UI.Toggle() f:SetShown(not f:IsShown()) end

-- An die Weltkarte andocken: Menü öffnet und schließt sich mit der Karte ----------
local docked = false
local function dock()
  if not WF.db.openWithMap then return end
  f:ClearAllPoints(); f:SetParent(WorldMapFrame); f:SetFrameStrata("HIGH")
  if WorldMapFrame.IsMaximized and WorldMapFrame:IsMaximized() then
    f:SetPoint("TOPRIGHT", WorldMapFrame, "TOPRIGHT", -10, -70)
  else
    f:SetPoint("TOPLEFT", WorldMapFrame, "TOPRIGHT", 4, 0)
  end
  f:Show(); docked = true
end
local function undock()
  if not docked then return end
  f:Hide(); f:SetParent(UIParent); f:ClearAllPoints(); f:SetPoint("CENTER"); docked = false
end
function UI.UpdateMapDock() if WorldMapFrame:IsShown() then if WF.db.openWithMap then dock() else undock() end end end
WF:On("READY", function()
  WorldMapFrame:HookScript("OnShow", dock)
  WorldMapFrame:HookScript("OnHide", undock)
  if WorldMapFrame.SynchronizeDisplayState then hooksecurefunc(WorldMapFrame, "SynchronizeDisplayState", function()
    if docked then dock() end end) end
end)

-- Minimap-Knopf ---------------------------------------------------------------
local mm = CreateFrame("Button", "RoutewiseMinimapButton", Minimap)
mm:SetSize(31, 31); mm:SetFrameStrata("MEDIUM"); mm:SetFrameLevel(8)
mm:SetHighlightTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight")
local ic = mm:CreateTexture(nil, "BACKGROUND"); ic:SetSize(20, 20); ic:SetPoint("CENTER")
ic:SetTexture("Interface\\Icons\\INV_Misc_Map_01")
local bd = mm:CreateTexture(nil, "OVERLAY"); bd:SetSize(53, 53); bd:SetPoint("TOPLEFT")
bd:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")
local function placeMM()
  local a = math.rad(WF.db.minimapAngle or 220)
  mm:ClearAllPoints(); mm:SetPoint("CENTER", Minimap, "CENTER", math.cos(a) * 80, math.sin(a) * 80)
end
mm:RegisterForDrag("LeftButton")
mm:SetScript("OnDragStart", function(self)
  self:SetScript("OnUpdate", function()
    local mx, my = Minimap:GetCenter(); local cx, cy = GetCursorPosition(); local s = Minimap:GetEffectiveScale()
    WF.db.minimapAngle = math.deg(math.atan2(cy / s - my, cx / s - mx)); placeMM()
  end)
end)
mm:SetScript("OnDragStop", function(self) self:SetScript("OnUpdate", nil) end)
mm:RegisterForClicks("LeftButtonUp", "RightButtonUp")
mm:SetScript("OnClick", function(_, btn) if btn == "RightButton" then WF.OpenOptions() else UI.Toggle() end end)
mm:SetScript("OnEnter", function(self)
  GameTooltip:SetOwner(self, "ANCHOR_LEFT"); GameTooltip:AddLine(L.TITLE); GameTooltip:AddLine(L.HINT, 1, 1, 1)
  GameTooltip:Show()
end)
mm:SetScript("OnLeave", GameTooltip_Hide)
function UI.SetMinimapShown(v) mm:SetShown(v) end
WF:On("READY", function() placeMM(); UI.SetMinimapShown(WF.db.showMinimap) end)
