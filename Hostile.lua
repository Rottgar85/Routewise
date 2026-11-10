-- Hostile: feindliche Lager/Städte meiden – für Horde und Allianz gleichermaßen.
-- Quelle sind die Spieldaten: jeder Flugmeister der Gegenfraktion (C_TaxiMap) markiert
-- eine feindliche Siedlung. Neutrale Orte (Ratschet, Beutebucht, Gadgetzan) bleiben frei.
local _, WF = ...
local H = {}
WF.Hostile = H
local U = WF.Util

local zones, built = {}, false
WF:On("GRAPH_DIRTY", function() built = false end)

local function enemyFaction()
  -- Enum.FlightPathFaction: 1 Horde, 2 Allianz
  return UnitFactionGroup("player") == "Horde" and 2 or 1
end

function H.Zones()
  if built then return zones end
  wipe(zones)
  local enemy = enemyFaction()
  for _, n in ipairs(WF.Taxi.GetNodes()) do
    if n.faction == enemy then
      local cont, wx, wy = U.ToWorld(n.mapID, n.x, n.y)
      if cont then
        -- Hauptstädte großzügiger meiden als kleine Lager
        local info = C_Map.GetMapInfoAtPosition and C_Map.GetMapInfoAtPosition(n.mapID, n.x, n.y)
        local city = info and info.mapType == Enum.UIMapType.City
        zones[#zones + 1] = { cont = cont, wx = wx, wy = wy, r = city and WF.db.hostileCityRadius or WF.db.hostileRadius,
                              name = n.taxiName }
      end
    end
  end
  built = true
  return zones
end

-- Abstand Punkt -> Strecke und Lotfußpunkt
local function segDist(px, py, ax, ay, bx, by)
  local dx, dy = bx - ax, by - ay
  local len2 = dx * dx + dy * dy
  local t = len2 > 0 and math.max(0, math.min(1, ((px - ax) * dx + (py - ay) * dy) / len2)) or 0
  local qx, qy = ax + t * dx, ay + t * dy
  return U.Dist(px, py, qx, qy), qx, qy, t
end

local function inside(z, n) return n.cont == z.cont and U.Dist(n.wx, n.wy, z.wx, z.wy) < z.r end

-- Erste feindliche Zone, die die Strecke a->b schneidet (Start/Ziel selbst darin -> ignorieren)
function H.Blocking(a, b)
  if not WF.db.avoidHostile or a.cont ~= b.cont then return nil end
  for _, z in ipairs(H.Zones()) do
    if z.cont == a.cont and not inside(z, a) and not inside(z, b) then
      local d, qx, qy, t = segDist(z.wx, z.wy, a.wx, a.wy, b.wx, b.wy)
      if d < z.r and t > 0 and t < 1 then return z, qx, qy end
    end
  end
end

-- Umweg-Wegpunkt: vom Zentrum der Zone in Richtung des Lotfußpunkts, außerhalb des Radius
function H.Detour(z, qx, qy)
  local dx, dy = qx - z.wx, qy - z.wy
  local len = math.sqrt(dx * dx + dy * dy)
  if len < 1 then dx, dy, len = 1, 0, 1 end
  local k = z.r * 1.3 / len
  return { cont = z.cont, wx = z.wx + dx * k, wy = z.wy + dy * k, label = z.name, detour = true }
end

-- Zusätzliche Kosten für den Pathfinder (macht Wege durch Feindgebiet unattraktiv)
function H.Penalty(a, b)
  local z = H.Blocking(a, b)
  if not z then return 0 end
  return (z.r * 0.6) / U.GroundSpeed() + WF.db.hostilePenalty
end

-- Fußweg-Leg in Teilstücke um feindliche Zonen herum zerlegen (max. 6 Umwege)
function H.SplitWalk(a, b, out, depth)
  depth = depth or 0
  local z, qx, qy = H.Blocking(a, b)
  if not z or depth > 6 then out[#out + 1] = b; return end
  local w = H.Detour(z, qx, qy)
  H.SplitWalk(a, w, out, depth + 1)
  H.SplitWalk(w, b, out, depth + 1)
end
