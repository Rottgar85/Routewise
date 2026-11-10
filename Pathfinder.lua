-- Pathfinder: Dijkstra mit Binär-Heap über den Graphen + temporäre Start/Ziel-Knoten
local _, WF = ...
local P = {}
WF.Pathfinder = P

local function push(h, item)
  h[#h + 1] = item; local i = #h
  while i > 1 do local p = math.floor(i / 2)
    if h[p][1] <= h[i][1] then break end
    h[p], h[i] = h[i], h[p]; i = p end
end
local function pop(h)
  local top = h[1]; h[1] = h[#h]; h[#h] = nil; local i = 1
  while true do local l, r, s = 2 * i, 2 * i + 1, i
    if h[l] and h[l][1] < h[s][1] then s = l end
    if h[r] and h[r][1] < h[s][1] then s = r end
    if s == i then break end
    h[s], h[i] = h[i], h[s]; i = s end
  return top
end

-- start/goal: { cont, wx, wy, mapID, label }
-- Rückgabe: Liste von Legs { from, to, mode, cost } und Gesamtzeit
function P.Find(start, goal)
  local nodes, edges = WF.Graph.Get()
  local G = WF.Graph
  start.id, goal.id = "__START", "__GOAL"
  local function neighbors(id)
    local out = {}
    if id == "__START" then
      for nid, n in pairs(nodes) do local c = G.WalkCost(start, n); if c then out[#out+1] = { to = nid, cost = c, mode = "walk" } end end
      local c = G.WalkCost(start, goal); if c then out[#out+1] = { to = "__GOAL", cost = c, mode = "walk" } end
      return out
    end
    for _, e in ipairs(edges[id] or {}) do out[#out+1] = e end
    local c = G.WalkCost(nodes[id], goal); if c then out[#out+1] = { to = "__GOAL", cost = c, mode = "walk" } end
    return out
  end
  local function nodeOf(id) return id == "__START" and start or id == "__GOAL" and goal or nodes[id] end

  local dist, prev, heap = { __START = 0 }, {}, {}
  push(heap, { 0, "__START" })
  while #heap > 0 do
    local d, id = unpack(pop(heap))
    if id == "__GOAL" then break end
    if d <= (dist[id] or math.huge) then
      for _, e in ipairs(neighbors(id)) do
        local nd = d + e.cost
        if nd < (dist[e.to] or math.huge) then
          dist[e.to] = nd; prev[e.to] = { from = id, edge = e }; push(heap, { nd, e.to })
        end
      end
    end
  end
  if not dist.__GOAL then return nil end

  local legs, id = {}, "__GOAL"
  while prev[id] do
    local p = prev[id]
    table.insert(legs, 1, { from = nodeOf(p.from), to = nodeOf(id), mode = p.edge.mode, cost = p.edge.cost })
    id = p.from
  end
  -- Aufeinanderfolgende Fußwege zusammenfassen
  local merged = {}
  for _, l in ipairs(legs) do
    local last = merged[#merged]
    if last and last.mode == "walk" and l.mode == "walk" then last.to = l.to; last.cost = last.cost + l.cost
    else merged[#merged + 1] = l end
  end
  -- Fußwege um feindliche Lager/Städte herumführen (zusätzliche Wegpunkte)
  local final = {}
  for _, l in ipairs(merged) do
    if l.mode == "walk" and WF.db.avoidHostile then
      local pts, prevPt = {}, l.from
      WF.Hostile.SplitWalk(l.from, l.to, pts)
      local total = 0
      for _, p in ipairs(pts) do total = total + WF.Util.Dist(prevPt.wx, prevPt.wy, p.wx, p.wy); prevPt = p end
      prevPt = l.from
      for _, p in ipairs(pts) do
        local d = WF.Util.Dist(prevPt.wx, prevPt.wy, p.wx, p.wy)
        final[#final + 1] = { from = prevPt, to = p, mode = "walk", cost = total > 0 and l.cost * d / total or l.cost }
        prevPt = p
      end
    else final[#final + 1] = l end
  end
  return final, dist.__GOAL
end
