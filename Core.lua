-- Core: Namespace, Event-Bus, SavedVariables
local ADDON, WF = ...
_G.Routewise = WF

WF.modules = {}
local listeners = {}

-- Interner Event-Bus (entkoppelt die Module voneinander)
function WF:On(evt, fn) listeners[evt] = listeners[evt] or {}; table.insert(listeners[evt], fn) end
function WF:Fire(evt, ...) for _, fn in ipairs(listeners[evt] or {}) do fn(...) end end

local defaults = {
  walkSpeed     = 7.0,    -- yd/s zu Fuß
  mountSpeed    = 11.2,   -- yd/s mit 60%-Reittier (wird live gemessen, falls schneller)
  taxiSpeed     = 32.0,   -- yd/s Schätzwert für ungemessene Flüge
  transferCost  = 15,     -- s Strafe pro Umstieg (Ein-/Aussteigen, Gespräch mit NPC)
  detourFactor  = 1.35,   -- Fußweg ist nie Luftlinie
  arrowEnabled  = true,
  showMinimap   = true,
  openWithMap   = true,
  avoidHostile  = true,   -- feindliche Lager/Städte umgehen
  hostileRadius = 150,    -- yd um feindliche Lager
  hostileCityRadius = 350,-- yd um feindliche Hauptstädte
  hostilePenalty = 120,   -- s Strafe, falls ein Weg doch durch Feindgebiet führen würde
  useNativeWaypoint = true,
  arrivalRadius = 15,     -- yd
  rerouteDistance = 120,  -- yd Abweichung vom Leg, ab der neu geplant wird
}

local f = CreateFrame("Frame")
f:RegisterEvent("ADDON_LOADED")
f:RegisterEvent("PLAYER_LOGIN")
f:SetScript("OnEvent", function(_, event, arg1)
  if event == "ADDON_LOADED" and arg1 == ADDON then
    RoutewiseDB = RoutewiseDB or {}
    RoutewiseCharDB = RoutewiseCharDB or {}
    -- bis 0.1.0 wurden auch unbekannte Flugpunkte ("DISTANT") als bekannt gespeichert: einmal neu lernen
    if RoutewiseCharDB.taxiVer ~= 2 then
      RoutewiseCharDB.knownTaxi, RoutewiseCharDB.taxiSeen, RoutewiseCharDB.taxiVer = {}, {}, 2
    end
    RoutewiseCharDB.knownTaxi = RoutewiseCharDB.knownTaxi or {}
    RoutewiseCharDB.taxiSeen = RoutewiseCharDB.taxiSeen or {}
    -- ältere Versionen haben das beim Ziel "Kartenwegpunkt" dauerhaft abgeschaltet
    if RoutewiseDB.useNativeWaypoint == false then RoutewiseDB.useNativeWaypoint = nil end
    WF.db = setmetatable(RoutewiseDB, { __index = defaults })
    RoutewiseDB.flightTimes = RoutewiseDB.flightTimes or {}  -- gemessene Flugzeiten (accountweit)
    RoutewiseDB.taxiLinks = RoutewiseDB.taxiLinks or {}      -- echte Flugverbindungen aus dem Spiel
    WF.char = RoutewiseCharDB
  elseif event == "PLAYER_LOGIN" then
    WF:Fire("INIT")
    WF:Fire("READY")
  end
end)

function WF:Print(...) print("|cff33ccffRoutewise|r:", ...) end
