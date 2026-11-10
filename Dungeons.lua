-- Dungeons: Instanzeingänge.
-- 1) Spieldaten (C_EncounterJournal), Namen in Client-Sprache
-- 2) Rückfall/Ergänzung: feste Liste Data/Instances.lua (immer vorhanden)
local _, WF = ...
local D = {}
WF.Dungeons = D
local list, built = {}, false
D.stats = { ej = 0, static = 0 }

local function isRaid(e)
  if e.isRaid ~= nil then return e.isRaid end
  if e.journalInstanceID and EJ_GetInstanceInfo then
    local ok, r = pcall(function() return select(12, EJ_GetInstanceInfo(e.journalInstanceID)) end)
    return ok and r and true or false
  end
  return false
end

local function fromGame(seen)
  if not (C_EncounterJournal and C_EncounterJournal.GetDungeonEntrancesForMap) then return end
  if C_AddOns and C_AddOns.LoadAddOn and not C_AddOns.IsAddOnLoaded("Blizzard_EncounterJournal") then
    pcall(C_AddOns.LoadAddOn, "Blizzard_EncounterJournal")
  end
  for _, z in ipairs(WF.MapResolver.Zones()) do
    local ok, entrances = pcall(C_EncounterJournal.GetDungeonEntrancesForMap, z.mapID)
    for _, e in ipairs(ok and entrances or {}) do
      local key = (e.name or ""):lower()
      if e.position and not seen[key] then
        seen[key] = true
        local x, y = e.position:GetXY()
        list[#list + 1] = { name = e.name, zone = z.name, mapID = z.mapID, x = x, y = y, raid = isRaid(e), dungeon = true }
        D.stats.ej = D.stats.ej + 1
      end
    end
  end
end

local function fromStatic(seen)
  local loc = WF.locale == "esMX" and "esES" or WF.locale
  for _, i in ipairs(WF.Data.Instances) do
    local name = i.n[loc] or i.n.enUS
    local dup = false
    for _, v in pairs(i.n) do if seen[v:lower()] then dup = true end end
    if not dup then
      seen[name:lower()] = true
      local info = C_Map.GetMapInfo(i.map)
      list[#list + 1] = { name = name, zone = info and info.name or "?", mapID = info and i.map or nil,
                          x = i[1] / 100, y = i[2] / 100, raid = i.raid or false, dungeon = true }
      D.stats.static = D.stats.static + 1
    end
  end
end

function D.Build()
  if built then return list end
  wipe(list); D.stats.ej, D.stats.static = 0, 0
  local seen = {}
  fromGame(seen)
  fromStatic(seen)
  table.sort(list, function(a, b) return a.name < b.name end)
  built = D.stats.ej > 0 or #WF.MapResolver.Zones() > 0
  return list
end
