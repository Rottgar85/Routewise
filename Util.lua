local _, WF = ...
local U = {}
WF.Util = U

-- Map-Koordinate (0..1 oder 0..100) -> Weltkoordinate (Yards) + Kontinent
function U.ToWorld(mapID, x, y)
  if x > 1 then x, y = x / 100, y / 100 end
  local cont, pos = C_Map.GetWorldPosFromMapPos(mapID, CreateVector2D(x, y))
  if not cont or not pos then return nil end
  local wx, wy = pos:GetXY()
  return cont, wx, wy
end

function U.Dist(ax, ay, bx, by)
  local dx, dy = ax - bx, ay - by
  return math.sqrt(dx * dx + dy * dy)
end

-- Spielerposition in Weltkoordinaten. In Instanzen/geschützten Kontexten nil.
function U.PlayerWorld()
  local mapID = C_Map.GetBestMapForUnit("player")
  if not mapID then return nil end
  local p = C_Map.GetPlayerMapPosition(mapID, "player")
  if not p then return nil end
  local x, y = p:GetXY()
  local cont, wx, wy = U.ToWorld(mapID, x, y)
  return cont, wx, wy, mapID, x, y
end

function U.FormatTime(sec)
  sec = math.floor(sec + 0.5)
  if sec >= 3600 then return string.format("%d:%02d:%02d h", sec / 3600, (sec % 3600) / 60, sec % 60) end
  return string.format("%d:%02d min", sec / 60, sec % 60)
end

-- Aktuelle effektive Reisegeschwindigkeit an Land (Reittier, falls bekannt)
function U.GroundSpeed()
  local _, run = GetUnitSpeed("player")
  local s = math.max(run or 0, WF.db.walkSpeed)
  if IsMounted() and run and run > WF.db.mountSpeed then WF.db.mountSpeed = run end
  return math.max(s, IsMounted() and WF.db.mountSpeed or WF.db.walkSpeed)
end
