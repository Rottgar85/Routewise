-- Statische Transportdaten.
-- WICHTIG: Koordinaten stammen aus Classic-Wissen und müssen im Forever-Client
-- mit "/rwise here" verifiziert werden. Zonen werden per Name aufgelöst (de/en),
-- damit abweichende uiMapIDs in Forever keine Rolle spielen.
local _, WF = ...

WF.Data = {}

-- Knoten: id = { zone = {en, de}, x, y, faction = "A"|"H"|nil (=neutral), kind }
WF.Data.Nodes = {
  -- Flugmeister werden NICHT hier gepflegt: sie kommen live aus C_TaxiMap (Taxi.lua).

  -- Hafen-/Turmpunkte
  SW_DOCK  = { map = 1453, zone = {"Stormwind City","Sturmwind"}, 22.0, 56.0, faction="A", kind="dock" },
  MEN_DOCK = { map = 1437, zone = {"Wetlands","Sumpfland"},        4.6, 57.1, faction="A", kind="dock" },
  AUB_DOCK = { map = 1439, zone = {"Darkshore","Dunkelküste"},    32.4, 43.8, faction="A", kind="dock" },
  THE_DOCK = { map = 1445, zone = {"Dustwallow Marsh","Düstermarschen"}, 71.6, 56.4, faction="A", kind="dock" },
  RAT_DOCK = { map = 1413, zone = {"The Barrens","Brachland"},    63.7, 38.6, kind="dock" },
  BB_DOCK  = { map = 1434, zone = {"Stranglethorn Vale","Schlingendorntal"}, 25.8, 73.1, kind="dock" },
  OG_ZEP   = { map = 1411, zone = {"Durotar","Durotar"},          50.8, 13.8, faction="H", kind="zeppelin" },
  UC_ZEP   = { map = 1420, zone = {"Tirisfal Glades","Tirisfal"}, 60.7, 58.8, faction="H", kind="zeppelin" },
  GROM_ZEP = { map = 1434, zone = {"Stranglethorn Vale","Schlingendorntal"}, 31.6, 29.1, faction="H", kind="zeppelin" },

  -- Sonstige: Tiefenbahn (Instanz-Übergang, als feste Verbindung modelliert)
  SW_TRAM  = { map = 1453, zone = {"Stormwind City","Sturmwind"}, 69.0, 31.0, kind="tram" },
  IF_TRAM  = { map = 1455, zone = {"Ironforge","Eisenschmiede"},  76.6, 51.0, kind="tram" },
}

-- Feste Verbindungen: from, to, Fahrzeit (s), Intervall (s) -> erwartete Wartezeit = Intervall/2
-- Werte sind Schätzungen; das Addon misst echte Zeiten und überschreibt sie.
WF.Data.Routes = {
  { "MEN_DOCK", "THE_DOCK", travel = 120, interval = 360, kind = "ship" },
  { "AUB_DOCK", "MEN_DOCK", travel = 100, interval = 300, kind = "ship" },
  { "RAT_DOCK", "BB_DOCK",  travel = 110, interval = 330, kind = "ship" },
  { "OG_ZEP",   "UC_ZEP",   travel = 140, interval = 340, kind = "zeppelin" },
  { "OG_ZEP",   "GROM_ZEP", travel = 140, interval = 340, kind = "zeppelin" },
  { "UC_ZEP",   "GROM_ZEP", travel = 140, interval = 340, kind = "zeppelin" },
  { "SW_TRAM",  "IF_TRAM",  travel = 60,  interval = 60,  kind = "tram" },
}

-- Teleporter, Ruhestein etc. lassen sich als "virtuelle Startkanten" ergänzen (siehe Graph.lua).
