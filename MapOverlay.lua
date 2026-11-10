-- MapOverlay: zeichnet die Route als Linien auf die Weltkarte.
-- Minimap: über den nativen User-Waypoint (Navigator) – eigene Minimap-Linien sind
-- ohne Bibliothek (HereBeDragons-Pins) fehleranfällig und hier bewusst ausgelassen.
local _, WF = ...

local COLORS = { walk = {1,1,1}, taxi = {0.2,0.8,1}, ship = {0.3,0.5,1}, zeppelin = {1,0.6,0.1}, tram = {0.8,0.8,0.2} }
local pool = {}

local function clear() for _, l in ipairs(pool) do l:Hide() end end

local function toMap(n, mapID)
  local _, pos = C_Map.GetMapPosFromWorldPos(n.cont, CreateVector2D(n.wx, n.wy), mapID)
  if not pos then return nil end
  local x, y = pos:GetXY()
  if x < 0 or x > 1 or y < 0 or y > 1 then return nil end
  return x, y
end

local function draw()
  clear()
  local route = WF.Navigator.route
  if not route or not WorldMapFrame:IsShown() then return end
  local canvas = (WorldMapFrame.GetCanvas and WorldMapFrame:GetCanvas())
    or (WorldMapFrame.ScrollContainer and WorldMapFrame.ScrollContainer.Child)
  local mapID = WorldMapFrame:GetMapID()
  if not canvas or not mapID then return end
  local w, h = canvas:GetSize()
  local i = 0
  for idx, l in ipairs(route) do
    local ax, ay = toMap(l.from, mapID); local bx, by = toMap(l.to, mapID)
    if ax and bx then
      i = i + 1
      local line = pool[i] or canvas:CreateLine(nil, "OVERLAY"); pool[i] = line
      line:SetThickness(idx == WF.Navigator.leg and 6 or 3)
      line:SetColorTexture(unpack(COLORS[l.mode] or {1,1,1}))
      line:SetStartPoint("TOPLEFT", canvas, ax * w, -ay * h)
      line:SetEndPoint("TOPLEFT", canvas, bx * w, -by * h)
      line:Show()
    end
  end
end

WF:On("ROUTE_CHANGED", draw)
WF:On("LEG_CHANGED", draw)
WF:On("READY", function()
  WorldMapFrame:HookScript("OnShow", draw)
  hooksecurefunc(WorldMapFrame, "OnMapChanged", draw)
end)
