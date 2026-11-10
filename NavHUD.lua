-- NavHUD: Navigationsanzeige wie im Auto – mit eigenen Grafiken (Media/*.tga).
--
--   ┌──────────────────────────────────────────────┐
--   │  ( ▲ )   [↰] In 120 m                        │  ← oben: Navi-Grün
--   │  Pfeil       Links abbiegen                  │
--   │              › Fliege nach Späherkuppe       │
--   ├══════════════ Fortschritt ═══════════════════┤
--   │  8:40 min        2,3 km        Ankunft 15:12 │  ← unten: dunkel
--   └──────────────────────────────────────────────┘
--
-- Bedienung: Ziehen = verschieben · Strg+Mausrad = Größe · Rechtsklick = Menü
local ADDON, WF = ...
local L, U = WF.L, WF.Util
local H = {}
WF.NavHUD = H

local MEDIA = "Interface\\AddOns\\" .. ADDON .. "\\Media\\"
local YD2M = 0.9144

local COL = {
  walk  = { 0.05, 0.42, 0.24 },   -- Navi-Grün
  board = { 0.08, 0.32, 0.62 },   -- Blau: Einsteigen / unterwegs
  warn  = { 0.62, 0.16, 0.12 },   -- Rot: wenden
  done  = { 0.12, 0.50, 0.30 },
  bottom = { 0.09, 0.10, 0.12 },
}
local MODEICON = {
  taxi = "Interface\\Icons\\Ability_Mount_Gryphon_01", ship = "Interface\\Icons\\INV_Misc_Anchor",
  zeppelin = "Interface\\Icons\\INV_Misc_Bomb_04", tram = "Interface\\Icons\\INV_Gizmo_02",
}
local TURNICON = {
  STRAIGHT = "turn_straight", SLIGHT_LEFT = "turn_slight_left", SLIGHT_RIGHT = "turn_slight_right",
  TURN_LEFT = "turn_left", TURN_RIGHT = "turn_right", SHARP_LEFT = "turn_sharp_left", SHARP_RIGHT = "turn_sharp_right",
  UTURN = "turn_uturn", ARRIVE_DEST = "turn_arrive",
}

local function fmtDist(yd)
  local m = yd * YD2M
  if m >= 1000 then return L.KM:format(m / 1000) end
  if m >= 100 then m = math.floor(m / 10 + 0.5) * 10 else m = math.floor(m / 5 + 0.5) * 5 end
  return ("%d m"):format(m)
end

-- Rahmen -----------------------------------------------------------------------
local f = CreateFrame("Frame", "RoutewiseNavHUD", UIParent)
f:SetSize(360, 180); f:SetPoint("TOP", 0, -90); f:SetFrameStrata("MEDIUM"); f:SetClampedToScreen(true)
f:SetMovable(true); f:EnableMouse(true); f:EnableMouseWheel(true); f:RegisterForDrag("LeftButton")
f:Hide()

local function tex(layer, file, sub)
  local t = f:CreateTexture(nil, layer, nil, sub or 0); t:SetTexture(MEDIA .. file); return t
end
local shadow = tex("BACKGROUND", "hud_shadow", -1); shadow:SetPoint("TOPLEFT", -8, 4); shadow:SetPoint("BOTTOMRIGHT", 8, -10)
local top = tex("BACKGROUND", "hud_top", 0); top:SetAllPoints()
local bottom = tex("BACKGROUND", "hud_bottom", 0); bottom:SetAllPoints(); bottom:SetVertexColor(unpack(COL.bottom)); bottom:SetAlpha(0.96)

-- Fortschrittsbalken an der Trennkante
local progBg = f:CreateTexture(nil, "BORDER"); progBg:SetColorTexture(0, 0, 0, 0.35)
progBg:SetPoint("TOPLEFT", 0, -124); progBg:SetPoint("TOPRIGHT", 0, -124); progBg:SetHeight(4)
local prog = f:CreateTexture(nil, "ARTWORK"); prog:SetColorTexture(0.30, 0.80, 1.0, 1)
prog:SetPoint("TOPLEFT", progBg); prog:SetHeight(4); prog:SetWidth(1)

-- Linke Seite: Kreis mit eigenem Richtungspfeil
local disc = tex("BORDER", "circle"); disc:SetSize(106, 106); disc:SetPoint("TOPLEFT", 9, -9); disc:SetVertexColor(0, 0, 0, 0.30)
local ring = tex("ARTWORK", "ring", 0); ring:SetSize(106, 106); ring:SetPoint("CENTER", disc); ring:SetVertexColor(1, 1, 1, 0.25)
local arrow = tex("ARTWORK", "arrow", 2); arrow:SetSize(82, 82); arrow:SetPoint("CENTER", disc)
local modeIcon = f:CreateTexture(nil, "ARTWORK", nil, 1); modeIcon:SetSize(66, 66); modeIcon:SetPoint("CENTER", disc)
if modeIcon.SetMask then modeIcon:SetMask("Interface\\CharacterFrame\\TempPortraitAlphaMask") end
modeIcon:Hide()

-- Rechte Seite: Manöver-Symbol, Distanz, Anweisung, nächste Etappe
local turn = tex("ARTWORK", "turn_straight"); turn:SetSize(40, 40); turn:SetPoint("TOPLEFT", 126, -12)
local function fs(size, flags, r, g, b)
  local s = f:CreateFontString(nil, "OVERLAY"); s:SetFont(STANDARD_TEXT_FONT, size, flags or "")
  s:SetTextColor(r or 1, g or 1, b or 1); s:SetJustifyH("LEFT"); s:SetWordWrap(false); return s
end
local distFs = fs(26, "OUTLINE"); distFs:SetPoint("LEFT", turn, "RIGHT", 8, 0); distFs:SetPoint("RIGHT", f, "RIGHT", -12, 0)
local manFs  = fs(15); manFs:SetPoint("TOPLEFT", 128, -60); manFs:SetPoint("RIGHT", -12, 0)
local nextFs = fs(11, "", 0.82, 0.95, 0.88); nextFs:SetPoint("TOPLEFT", 128, -86); nextFs:SetPoint("RIGHT", -12, 0)
local stepFs = fs(10, "", 0.75, 0.88, 0.80); stepFs:SetPoint("TOPLEFT", 128, -104); stepFs:SetPoint("RIGHT", -12, 0)

-- Untere Leiste: Restzeit · Restdistanz · Ankunft
local timeFs = fs(17, "OUTLINE", 0.40, 0.90, 0.50); timeFs:SetPoint("BOTTOMLEFT", 14, 17)
local kmFs   = fs(14, "", 0.88, 0.88, 0.88); kmFs:SetPoint("BOTTOM", 0, 19); kmFs:SetJustifyH("CENTER")
local etaFs  = fs(14, "", 0.88, 0.88, 0.88); etaFs:SetPoint("BOTTOMRIGHT", -14, 19); etaFs:SetJustifyH("RIGHT")

-- Bedienung --------------------------------------------------------------------
f:SetScript("OnDragStart", f.StartMoving)
f:SetScript("OnDragStop", function(self)
  self:StopMovingOrSizing()
  local p, _, rp, x, y = self:GetPoint(); WF.db.hudPos = { p, rp, x, y }
end)
f:SetScript("OnMouseUp", function(_, btn) if btn == "RightButton" then WF.UI.Toggle() end end)
f:SetScript("OnMouseWheel", function(self, delta)
  if not IsControlKeyDown() then return end
  WF.db.hudScale = math.max(0.5, math.min(1.6, (WF.db.hudScale or 1) + delta * 0.05))
  self:SetScale(WF.db.hudScale)
end)
f:SetScript("OnEnter", function(self)
  GameTooltip:SetOwner(self, "ANCHOR_BOTTOM"); GameTooltip:AddLine(L.TITLE); GameTooltip:AddLine(L.HUD_HINT, 1, 1, 1, true)
  GameTooltip:Show()
end)
f:SetScript("OnLeave", GameTooltip_Hide)

-- Logik -----------------------------------------------------------------------
local function angleOf(dx, dy) return math.atan2(dy, dx) end -- 0 = Norden, positiv = links herum
local function norm(a) while a > math.pi do a = a - 2 * math.pi end while a < -math.pi do a = a + 2 * math.pi end return a end

local function turnKey(d)
  local deg = math.deg(d); local a = math.abs(deg); local left = deg > 0
  if a < 20 then return "STRAIGHT" end
  if a < 55 then return left and "SLIGHT_LEFT" or "SLIGHT_RIGHT" end
  if a < 135 then return left and "TURN_LEFT" or "TURN_RIGHT" end
  return left and "SHARP_LEFT" or "SHARP_RIGHT"
end
local BOARD = { taxi = "BOARD_TAXI", ship = "BOARD_SHIP", zeppelin = "BOARD_ZEP", tram = "BOARD_TRAM" }

-- Was passiert am Ende der aktuellen Etappe?  -> key/Text, Symbol, Folgetext
local function maneuver(px, py, tgt, leg, idx)
  local N = WF.Navigator
  if leg.mode ~= "walk" then return L[BOARD[leg.mode]] or L.BOARD, nil, MODEICON[leg.mode], N.Describe(leg) end
  local nextLeg = N.route[idx + 1]
  if not nextLeg then return L.ARRIVE_DEST, "turn_arrive", nil, N.Label(tgt) end
  if nextLeg.mode ~= "walk" then return L[BOARD[nextLeg.mode]] or L.BOARD, nil, MODEICON[nextLeg.mode], N.Describe(nextLeg) end
  local nxt = nextLeg.to
  if nxt.cont ~= tgt.cont then return L.STRAIGHT, "turn_straight", nil, N.Describe(nextLeg) end
  local k = turnKey(norm(angleOf(nxt.wx - tgt.wx, nxt.wy - tgt.wy) - angleOf(tgt.wx - px, tgt.wy - py)))
  return L[k], TURNICON[k], nil, N.Describe(nextLeg)
end

local function remainingDist(cont, px, py, tgt)
  local N = WF.Navigator
  local d = (tgt.cont == cont) and U.Dist(px, py, tgt.wx, tgt.wy) or 0
  for i = N.leg, #N.route do
    local l = N.route[i]
    if (i > N.leg or l.mode ~= "walk") and l.from.cont == l.to.cont then d = d + U.Dist(l.from.wx, l.from.wy, l.to.wx, l.to.wy) end
  end
  return d
end

local function setTop(c) top:SetVertexColor(c[1], c[2], c[3], 0.96) end
local function showArrow(on) arrow:SetShown(on); modeIcon:SetShown(not on) end
local function setTurn(file, icon)
  if file then turn:SetTexture(MEDIA .. file); turn:SetTexCoord(0, 1, 0, 1); turn:Show()
  elseif icon then turn:SetTexture(icon); turn:SetTexCoord(0.08, 0.92, 0.08, 0.92); turn:Show()
  else turn:Hide() end
end

local acc = 0
f:SetScript("OnUpdate", function(_, dt)
  acc = acc + dt; if acc < 0.04 then return end; acc = 0
  local N = WF.Navigator
  local tgt, leg = N.CurrentTarget()
  if not tgt then return end
  local cont, px, py = U.PlayerWorld()

  stepFs:SetText(L.STEP:format(N.leg, #N.route))
  if not cont then setTop(COL.walk); distFs:SetText(""); manFs:SetText(L.NOPOS); return end

  local remain = N.Remaining(cont, px, py)
  timeFs:SetText(U.FormatTime(remain))
  kmFs:SetText(fmtDist(remainingDist(cont, px, py, tgt)))
  etaFs:SetText(L.ARRIVAL:format(date("%H:%M", time() + remain)))
  local total = N.total > 0 and N.total or 1
  prog:SetWidth(math.max(1, f:GetWidth() * math.min(1, math.max(0, 1 - remain / total))))

  -- Unterwegs mit Flug/Schiff/Zeppelin
  if UnitOnTaxi("player") or (leg.mode ~= "walk" and tgt.cont ~= cont) then
    setTop(COL.board); showArrow(false); modeIcon:SetTexture(MODEICON[leg.mode] or MODEICON.taxi)
    setTurn(nil, nil); distFs:SetText(L.ONBOARD); manFs:SetText(N.Describe(leg)); nextFs:SetText("")
    return
  end
  if tgt.cont ~= cont then
    setTop(COL.walk); showArrow(false); modeIcon:SetTexture("Interface\\Icons\\INV_Misc_Map_01")
    setTurn(nil, nil); distFs:SetText(""); manFs:SetText(N.Describe(leg)); nextFs:SetText(L.OTHERCONT)
    return
  end

  -- Eigener Pfeil: relativ zur Blickrichtung, Farbe nach Genauigkeit
  showArrow(true)
  local rel = norm(angleOf(tgt.wx - px, tgt.wy - py) - (GetPlayerFacing() or 0))
  arrow:SetRotation(rel)
  local a = math.abs(math.deg(rel))
  if a < 15 then arrow:SetVertexColor(0.45, 1.0, 0.55)
  elseif a < 70 then arrow:SetVertexColor(1, 1, 1)
  elseif a < 140 then arrow:SetVertexColor(1.0, 0.85, 0.30)
  else arrow:SetVertexColor(1.0, 0.40, 0.35) end

  local d = U.Dist(px, py, tgt.wx, tgt.wy)
  local man, file, icon, nxt = maneuver(px, py, tgt, leg, N.leg)
  if a > 150 and d > 25 then
    setTop(COL.warn); setTurn("turn_uturn"); distFs:SetText(L.UTURN); manFs:SetText(man .. " – " .. fmtDist(d))
  else
    setTop(leg.mode ~= "walk" and COL.board or COL.walk); setTurn(file, icon)
    distFs:SetText(d * YD2M < 12 and L.NOW or L.IN_DIST:format(fmtDist(d)))
    manFs:SetText(man)
  end
  nextFs:SetText(nxt and ("› " .. nxt) or "")
end)

function H.Refresh() f:SetShown(WF.Navigator.route ~= nil and WF.db.arrowEnabled) end
WF:On("READY", function()
  local p = WF.db.hudPos
  if p then f:ClearAllPoints(); f:SetPoint(p[1], UIParent, p[2], p[3], p[4]) end
  f:SetScale(WF.db.hudScale or 1)
end)
WF:On("ROUTE_CHANGED", H.Refresh)
