-- MapResolver: Zonenname -> uiMapID (robust gegen abweichende IDs in Forever)
local _, WF = ...
local R = {}
WF.MapResolver = R
local byName, zones, visited = {}, {}, {}

local function isZoneType(t)
  if not Enum or not Enum.UIMapType then return true end
  return t == Enum.UIMapType.Zone or t == Enum.UIMapType.City
end

local function index(mapID, depth)
  if not mapID or visited[mapID] or depth > 8 then return end
  visited[mapID] = true
  local info = C_Map.GetMapInfo(mapID)
  if not info then return end
  if info.name and info.name ~= "" then
    local key = info.name:lower()
    if not byName[key] then
      byName[key] = mapID
      if isZoneType(info.mapType) then zones[#zones + 1] = { name = info.name, mapID = mapID } end
    end
  end
  local ok, children = pcall(C_Map.GetMapChildrenInfo, mapID)
  for _, child in ipairs(ok and children or {}) do index(child.mapID, depth + 1) end
end

-- Wurzeln suchen: bekannte IDs + vom Spielerstandort bis zur obersten Karte hoch
local function roots()
  local out = { 946, 947, 12, 13, 1414, 1415 }
  local m = C_Map.GetBestMapForUnit and C_Map.GetBestMapForUnit("player")
  local guard = 0
  while m and guard < 10 do
    out[#out + 1] = m
    local info = C_Map.GetMapInfo(m)
    m = info and info.parentMapID ~= 0 and info.parentMapID or nil
    guard = guard + 1
  end
  return out
end

function R.EnsureIndex()
  if #zones > 0 then return end
  for _, id in ipairs(roots()) do index(id, 0) end
  -- Letzter Rückfall: IDs direkt durchprobieren
  if #zones == 0 then for id = 1, 2500 do if not visited[id] then index(id, 7) end end end
  table.sort(zones, function(a, b) return a.name < b.name end)
end

WF:On("INIT", R.EnsureIndex)
WF:On("READY", function() C_Timer.After(3, R.EnsureIndex) end)

function R.Find(name)
  if not name then return nil end
  if type(name) == "table" then
    for _, n in ipairs(name) do local id = R.Find(n); if id then return id end end
    return nil
  end
  R.EnsureIndex()
  local id = byName[name:lower()]
  if not id then
    for n, m in pairs(byName) do if n:find(name:lower(), 1, true) then return m end end
  end
  return id
end

function R.ResolveNode(node)
  if node.cont then return node end
  local mapID = (node.map and C_Map.GetMapInfo(node.map) and node.map) or R.Find(node.zone)
  if not mapID then return nil end
  local cont, wx, wy = WF.Util.ToWorld(mapID, node[1], node[2])
  if not cont then return nil end
  node.mapID, node.cont, node.wx, node.wy = mapID, cont, wx, wy
  return node
end

function R.Zones()
  R.EnsureIndex()
  return zones
end
