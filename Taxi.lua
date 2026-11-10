-- Taxi: Flugmeister kommen direkt aus den Spieldaten von Forever (C_TaxiMap),
-- nicht aus einer eigenen Liste. Dazu: tatsächliche Flugverbindungen und Flugzeiten lernen.
local _, WF = ...
local T = {}
WF.Taxi = T

local CONTINENTS = { { id = 1414, "Kalimdor" }, { id = 1415, "Eastern Kingdoms", "Östliche Königreiche" } }

-- Nur diese Typen bedeuten "Flugpunkt hat der Charakter" (Forever meldet unbekannte als "DISTANT")
local KNOWN_TYPES = { CURRENT = true, REACHABLE = true }

local function ContinentMap(names)
  return (C_Map.GetMapInfo(names.id) and names.id) or WF.MapResolver.Find(names)
end

-- Alle Flugmeister der Kontinente mit Status (bekannt/unbekannt) und Fraktion
function T.GetNodes()
  local out = {}
  if not C_TaxiMap or not C_TaxiMap.GetTaxiNodesForMap then return out end
  for _, names in ipairs(CONTINENTS) do
    local mapID = ContinentMap(names)
    local seen = mapID and WF.char.taxiSeen[mapID]
    for _, n in ipairs(mapID and C_TaxiMap.GetTaxiNodesForMap(mapID) or {}) do
      -- Auf einem Kontinent, dessen Flugkarte der Charakter schon offen hatte, zählt nur, was das Spiel dort
      -- als erreichbar gemeldet hat; sonst "isUndiscovered" (MapTaxiNodeInfo hat kein "state").
      local learned = WF.char.knownTaxi[n.name] == true
      local known = learned or (not seen and n.isUndiscovered == false)
      local x, y = n.position:GetXY()
      out[#out + 1] = { id = "TAXI_" .. n.nodeID, nodeID = n.nodeID, taxiName = n.name, known = known,
                        mapID = mapID, x = x, y = y, kind = "taxi",
                        faction = n.faction } -- Enum.FlightPathFaction: 0 neutral, 1 Horde, 2 Allianz
    end
  end
  return out
end

-- Beim Öffnen der Flugkarte: echte Direktverbindungen lernen (welche Strecken Forever anbietet)
local f = CreateFrame("Frame")
f:RegisterEvent("TAXIMAP_OPENED")
f:RegisterEvent("PLAYER_CONTROL_GAINED")
local flight, currentName, pending

f:SetScript("OnEvent", function(_, e)
  if e == "TAXIMAP_OPENED" then
    local links, listed = WF.db.taxiLinks, {}
    for i = 1, NumTaxiNodes() do
      local name, typ = TaxiNodeName(i), TaxiNodeGetType(i)
      if name then
        listed[name] = true
        WF.char.knownTaxi[name] = KNOWN_TYPES[typ] or nil
      end
      if typ == "CURRENT" then currentName = name end
      -- Hops dieser Strecke: jede Teilstrecke ist eine echte Flugverbindung
      for r = 1, GetNumRoutes(i) do
        local a = TaxiNodeName(TaxiGetNodeSlot(i, r, true))
        local b = TaxiNodeName(TaxiGetNodeSlot(i, r, false))
        if a and b then links[a .. ">" .. b] = true; links[b .. ">" .. a] = true end
      end
    end
    -- Kontinent dieser Flugkarte merken: dort gilt ab jetzt nur noch das Gelernte
    if C_TaxiMap and C_TaxiMap.GetTaxiNodesForMap then
      for _, names in ipairs(CONTINENTS) do
        local mapID = ContinentMap(names)
        for _, n in ipairs(mapID and C_TaxiMap.GetTaxiNodesForMap(mapID) or {}) do
          if listed[n.name] then WF.char.taxiSeen[mapID] = true; break end
        end
      end
    end
    WF:Fire("GRAPH_DIRTY")
  elseif e == "PLAYER_CONTROL_GAINED" and flight then
    local dt = GetTime() - flight.t0
    if dt > 5 then WF.db.flightTimes[flight.from .. ">" .. flight.to] = dt; WF:Fire("GRAPH_DIRTY") end
    flight = nil
  end
end)

hooksecurefunc("TakeTaxiNode", function(i)
  pending = TaxiNodeName(i)
  C_Timer.After(1, function()
    if UnitOnTaxi("player") and currentName then flight = { from = currentName, to = pending, t0 = GetTime() - 1 } end
  end)
end)

function T.FlightTime(a, b, dist)
  return WF.db.flightTimes[a.taxiName .. ">" .. b.taxiName] or (dist * 1.25 / WF.db.taxiSpeed)
end
