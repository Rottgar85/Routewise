-- Commands: /rwise öffnet das Menü; Unterbefehle für Power-User
local _, WF = ...
local U = WF.Util

SLASH_ROUTEWISE1, SLASH_ROUTEWISE2 = "/routewise", "/rwise"
SlashCmdList.ROUTEWISE = function(msg)
  local cmd = (msg:match("^(%S*)") or ""):lower()
  if cmd == "" then WF.UI.Toggle()
  elseif cmd == "options" or cmd == "config" then WF.OpenOptions()
  elseif cmd == "debug" then
    local z = #WF.MapResolver.Zones()
    local d = WF.Dungeons.Build()
    local raids = 0; for _, i in ipairs(d) do if i.raid then raids = raids + 1 end end
    local taxi, knownTaxi = WF.Taxi.GetNodes(), 0
    for _, n in ipairs(taxi) do if n.known then knownTaxi = knownTaxi + 1 end end
    WF:Print(("Zones: %d | Instances: %d (raids: %d) | from game data: %d | from list: %d | flight masters: %d (known: %d)"):format(
      z, #d, raids, WF.Dungeons.stats.ej, WF.Dungeons.stats.static, #taxi, knownTaxi))
    local m = C_Map.GetBestMapForUnit("player"); local info = m and C_Map.GetMapInfo(m)
    WF:Print(("Map: %s (%s), type %s"):format(info and info.name or "?", tostring(m), tostring(info and info.mapType)))
  elseif cmd == "map" then WF.UI.FromMapWaypoint()
  elseif cmd == "stop" then WF.Navigator.Stop()
  elseif cmd == "here" then
    local _, _, _, mapID, x, y = U.PlayerWorld()
    local info = mapID and C_Map.GetMapInfo(mapID)
    if mapID then WF:Print(("%s (%d): %.1f, %.1f"):format(info and info.name or "?", mapID, x * 100, y * 100)) end
  elseif cmd == "arrow" then
    WF.db.arrowEnabled = not WF.db.arrowEnabled
    if WF.NavHUD and WF.NavHUD.Refresh then WF.NavHUD.Refresh() end
    WF:Print(WF.L.OPT_ARROW .. ": " .. (WF.db.arrowEnabled and "|cff33ff33ON|r" or "|cffff3333OFF|r"))
  else WF.UI.Toggle() end
end
