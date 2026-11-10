-- Navigator: führt den Spieler Leg für Leg, erkennt Ankunft/Abweichung, plant neu
local _, WF = ...
local N = {}
WF.Navigator = N
local U = WF.Util

local L = WF.L

N.route, N.leg, N.goal, N.total = nil, 1, nil, 0

local function label(n)
  if n.label then return n.label end
  local info = n.mapID and C_Map.GetMapInfo(n.mapID)
  return n.taxiName or (info and info.name) or "?"
end

N.Label = label
function N.Describe(l)
  if l.mode == "walk" and l.to.detour then return L.AROUND:format(label(l.to)) end
  return (L[l.mode]):format(label(l.to))
end

-- Aktuelles Ziel des Pfeils: bei Fußweg das Leg-Ende, sonst der Einstiegspunkt
function N.CurrentTarget()
  local l = N.route and N.route[N.leg]
  if not l then return nil end
  return l.mode == "walk" and l.to or l.from, l
end

local function setNativeWaypoint(n)
  -- Ziel ist der Kartenwegpunkt des Spielers: den nicht überschreiben
  if not WF.db.useNativeWaypoint or not n or not n.mapID or (N.goal and N.goal.userWaypoint) then return end
  if not (C_Map.SetUserWaypoint and C_Map.CanSetUserWaypointOnMap and UiMapPoint) then return end
  local pos = C_Map.GetMapPosFromWorldPos and select(2, C_Map.GetMapPosFromWorldPos(n.cont, CreateVector2D(n.wx, n.wy), n.mapID))
  if not pos then return end
  if C_Map.CanSetUserWaypointOnMap(n.mapID) then
    C_Map.SetUserWaypoint(UiMapPoint.CreateFromVector2D(n.mapID, pos))
    N.ownWaypoint = true
    if C_SuperTrack and C_SuperTrack.SetSuperTrackedUserWaypoint then
      C_SuperTrack.SetSuperTrackedUserWaypoint(false) -- nur Kartenpin; Richtung zeigt unser eigener Pfeil
    end
  end
end

-- rerouting = true: automatische Neuplanung unterwegs (leise; ohne Route wird die Navigation beendet)
function N.Start(goal, rerouting)
  local cont, wx, wy, mapID = U.PlayerWorld()
  if not cont then if not rerouting then WF:Print(L.NOPOS) end; return end
  local route, total = WF.Pathfinder.Find({ cont = cont, wx = wx, wy = wy, mapID = mapID, label = L.START }, goal)
  if not route then
    WF:Print(L.NOROUTE .. " " .. L.NOTAXI)
    if rerouting then N.Stop() end
    return
  end
  N.route, N.leg, N.goal, N.total = route, 1, goal, total
  if not rerouting then WF:Print(L.TOTAL:format(U.FormatTime(total))) end
  setNativeWaypoint(N.CurrentTarget())
  WF:Fire("ROUTE_CHANGED", route)
end

-- Neuplanung höchstens alle 5 s (verhindert Dauerschleifen und Chat-Spam)
local lastReroute = 0
local function reroute()
  if not N.goal or GetTime() - lastReroute < 5 then return end
  lastReroute = GetTime()
  N.Start(N.goal, true)
end

function N.Stop()
  N.route = nil
  -- nur den eigenen Pin entfernen, nie einen Wegpunkt, den der Spieler selbst gesetzt hat
  if N.ownWaypoint and C_Map.ClearUserWaypoint then C_Map.ClearUserWaypoint() end
  N.ownWaypoint = nil
  WF:Fire("ROUTE_CHANGED", nil)
end

-- Verbleibende Zeit = Rest des aktuellen Legs (live) + Folge-Legs
function N.Remaining(cont, wx, wy)
  local t, l = 0, N.route[N.leg]
  local speed = U.GroundSpeed()
  if l.mode == "walk" then
    if l.to.cont == cont then t = U.Dist(wx, wy, l.to.wx, l.to.wy) * WF.db.detourFactor / speed end
  else
    local from, to = l.from, l.to
    local boarded = UnitOnTaxi("player") or from.cont ~= cont
      or U.Dist(wx, wy, from.wx, from.wy) > WF.db.arrivalRadius * 4
    if not boarded then
      -- noch zum Einstieg laufen + volle Fahrt
      t = U.Dist(wx, wy, from.wx, from.wy) * WF.db.detourFactor / speed + l.cost
    elseif from.cont == cont and to.cont == cont then
      -- unterwegs: Anteil der Fahrt nach verbleibender Strecke zum Ziel
      local full = U.Dist(from.wx, from.wy, to.wx, to.wy)
      t = full > 0 and l.cost * math.min(1, U.Dist(wx, wy, to.wx, to.wy) / full) or 0
    else
      t = l.cost
    end
  end
  for i = N.leg + 1, #N.route do t = t + N.route[i].cost end
  return t
end

local function advance()
  N.leg = N.leg + 1
  if N.leg > #N.route then WF:Print(L.ARRIVED); N.Stop(); return end
  WF:Print(L.NEXT:format(N.Describe(N.route[N.leg])))
  setNativeWaypoint(N.CurrentTarget())
  WF:Fire("LEG_CHANGED", N.leg)
end

-- Update-Schleife (5x pro Sekunde reicht; der Pfeil rendert eigenständig)
local wasOnTaxi, acc = false, 0
CreateFrame("Frame"):SetScript("OnUpdate", function(_, dt)
  acc = acc + dt; if acc < 0.2 or not N.route then return end; acc = 0
  local l = N.route[N.leg]
  local onTransport = UnitOnTaxi("player")
  if wasOnTaxi and not onTransport and l.mode == "taxi" then advance(); wasOnTaxi = false; return end
  wasOnTaxi = onTransport
  local cont, wx, wy = U.PlayerWorld()
  if not cont or onTransport then return end
  local tgt = N.CurrentTarget()
  if l.mode == "walk" then
    if tgt.cont == cont and U.Dist(wx, wy, tgt.wx, tgt.wy) < WF.db.arrivalRadius then advance() end
  elseif l.mode ~= "taxi" then
    -- Schiff/Zeppelin/Bahn: angekommen, wenn wir nahe am Ziel-Anleger sind
    if l.to.cont == cont and U.Dist(wx, wy, l.to.wx, l.to.wy) < WF.db.arrivalRadius * 4 then advance() end
  end
  -- Abweichung: auf anderem Kontinent als erwartet oder weit weg vom Ziel -> neu planen
  if N.route and l.mode == "walk" and tgt.cont ~= cont then reroute() end
end)

-- Ladebildschirm/Teleport: nur neu planen, wenn wir auf einem Kontinent sind, den das aktuelle Leg nicht berührt
local ev = CreateFrame("Frame")
ev:RegisterEvent("ZONE_CHANGED_NEW_AREA")
ev:SetScript("OnEvent", function()
  if not N.route or UnitOnTaxi("player") then return end
  C_Timer.After(1, function()
    local l = N.route and N.route[N.leg]
    local cont = U.PlayerWorld()
    if l and cont and cont ~= l.from.cont and cont ~= l.to.cont then reroute() end
  end)
end)
