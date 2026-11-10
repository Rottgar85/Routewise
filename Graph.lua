-- Graph: Reisegraph aus Spieldaten (Flugmeister via C_TaxiMap) + Schiffs-/Zeppelinlinien
-- Kanten: { to, cost (s), mode }
local _, WF = ...
local G = {}
WF.Graph = G
local U = WF.Util

local nodes, edges, dirty = {}, {}, true
WF:On("GRAPH_DIRTY", function() dirty = true end)

local function factionOK(n)
  local fac = UnitFactionGroup("player")
  if n.kind == "taxi" then -- Enum.FlightPathFaction: 0 neutral, 1 Horde, 2 Allianz
    return not n.faction or n.faction == 0 or (n.faction == 1 and fac == "Horde") or (n.faction == 2 and fac == "Alliance")
  end
  if not n.faction then return true end
  return (n.faction == "A" and fac == "Alliance") or (n.faction == "H" and fac == "Horde")
end

local function addEdge(a, b, cost, mode)
  edges[a] = edges[a] or {}
  table.insert(edges[a], { to = b, cost = cost, mode = mode })
end

function G.WalkCost(a, b)
  if a.cont ~= b.cont then return nil end
  return U.Dist(a.wx, a.wy, b.wx, b.wy) * WF.db.detourFactor / U.GroundSpeed() + WF.Hostile.Penalty(a, b)
end

function G.Build()
  wipe(nodes); wipe(edges)
  -- 1) Flugmeister aus dem Spiel (nur bekannte, passende Fraktion)
  for _, n in ipairs(WF.Taxi.GetNodes()) do
    if n.known and factionOK(n) then
      local cont, wx, wy = U.ToWorld(n.mapID, n.x, n.y)
      if cont then n.cont, n.wx, n.wy = cont, wx, wy; nodes[n.id] = n end
    end
  end
  -- 2) Häfen, Zeppelintürme, Bahn aus Data/Transport.lua
  for id, n in pairs(WF.Data.Nodes) do
    n.id = id
    if factionOK(n) and WF.MapResolver.ResolveNode(n) then nodes[id] = n end
  end
  -- 3) Flüge: zwischen bekannten Flugmeistern desselben Kontinents (das Spiel fliegt Mehrfach-Hops automatisch)
  for a, na in pairs(nodes) do if na.kind == "taxi" then
    for b, nb in pairs(nodes) do if a ~= b and nb.kind == "taxi" and na.cont == nb.cont then
      addEdge(a, b, WF.Taxi.FlightTime(na, nb, U.Dist(na.wx, na.wy, nb.wx, nb.wy)) + WF.db.transferCost, "taxi")
    end end
  end end
  -- 4) Feste Linien (bidirektional, inkl. erwarteter Wartezeit)
  for _, r in ipairs(WF.Data.Routes) do
    local a, b = r[1], r[2]
    if nodes[a] and nodes[b] then
      local cost = (WF.db.flightTimes[a .. ">" .. b] or r.travel) + r.interval / 2 + WF.db.transferCost
      addEdge(a, b, cost, r.kind); addEdge(b, a, cost, r.kind)
    end
  end
  -- 5) Fußwege als Umstiege
  for a, na in pairs(nodes) do for b, nb in pairs(nodes) do
    if a ~= b then local c = G.WalkCost(na, nb); if c then addEdge(a, b, c, "walk") end end
  end end
  dirty = false
end

function G.Get()
  if dirty then G.Build() end
  return nodes, edges
end
