-- Options: eigene Seite unter ESC > Optionen > AddOns > Routewise
local _, WF = ...
local L = WF.L

WF:On("INIT", function()
  if not (Settings and Settings.RegisterVerticalLayoutCategory) then return end
  local cat = Settings.RegisterVerticalLayoutCategory("Routewise")

  local function checkbox(key, name, tip, default, onChange)
    local s = Settings.RegisterAddOnSetting(cat, "Routewise_" .. key, key, RoutewiseDB, "boolean", name, default)
    if onChange then s:SetValueChangedCallback(function(_, v) onChange(v) end) end
    Settings.CreateCheckbox(cat, s, tip)
  end

  checkbox("showMinimap", L.OPT_MINIMAP, L.OPT_MINIMAP_TIP, true, function(v) WF.UI.SetMinimapShown(v) end)
  checkbox("openWithMap", L.OPT_WITHMAP, L.OPT_WITHMAP_TIP, true, function(v) WF.UI.UpdateMapDock() end)
  checkbox("avoidHostile", L.OPT_HOSTILE, L.OPT_HOSTILE_TIP, true, function() WF:Fire("GRAPH_DIRTY") end)
  checkbox("arrowEnabled", L.OPT_ARROW, L.OPT_ARROW_TIP, true, function(v)
    if WF.Navigator.route then WF:Fire("ROUTE_CHANGED", WF.Navigator.route) end
  end)

  Settings.RegisterAddOnCategory(cat)
  WF.optionsCategory = cat
end)

function WF.OpenOptions()
  if WF.optionsCategory then Settings.OpenToCategory(WF.optionsCategory:GetID()) end
end
