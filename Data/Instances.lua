-- Feste Liste der Instanzeingänge (Forever liefert keine Eingänge über die Spieldaten).
-- map = uiMapID der Classic-Zone (sprachunabhängig), x/y in Prozent.
-- n = Namen je Sprache; fehlende Sprachen fallen auf Englisch zurück.
-- Koordinaten sind Classic-Werte; mit "/rwise here" im Forever-Client prüfbar.
local _, WF = ...
WF.Data = WF.Data or {}

WF.Data.Instances = {
  -- Dungeons
  { map = 1454, 52.0, 49.0, n = { enUS = "Ragefire Chasm", deDE = "Der Flammenschlund", frFR = "Gouffre de Ragefeu", esES = "Sima Ígnea", ruRU = "Огненная пропасть" } },
  { map = 1413, 46.0, 36.0, n = { enUS = "Wailing Caverns", deDE = "Die Höhlen des Wehklagens", frFR = "Cavernes des lamentations", esES = "Cuevas de los Lamentos", ruRU = "Пещеры Стенаний" } },
  { map = 1436, 42.5, 71.7, n = { enUS = "The Deadmines", deDE = "Die Todesminen", frFR = "Les Mortemines", esES = "Las Minas de la Muerte", ruRU = "Мертвые копи" } },
  { map = 1421, 44.8, 67.8, n = { enUS = "Shadowfang Keep", deDE = "Burg Schattenfang", frFR = "Donjon d'Ombrecroc", esES = "Castillo de Colmillo Oscuro", ruRU = "Крепость Темного Клыка" } },
  { map = 1440, 14.1, 14.0, n = { enUS = "Blackfathom Deeps", deDE = "Die Tiefschwarze Grotte", frFR = "Profondeurs de Brassenoire", esES = "Cavernas de Brazanegra", ruRU = "Непроглядная Пучина" } },
  { map = 1453, 50.5, 66.3, n = { enUS = "The Stockade", deDE = "Das Verlies", frFR = "La Prison", esES = "Las Mazmorras", ruRU = "Тюрьма" } },
  { map = 1426, 24.3, 39.8, n = { enUS = "Gnomeregan", deDE = "Gnomeregan", frFR = "Gnomeregan", esES = "Gnomeregan", ruRU = "Гномреган" } },
  { map = 1413, 42.3, 89.9, n = { enUS = "Razorfen Kraul", deDE = "Kral der Klingenhauer", frFR = "Kraal de Tranchebauge", esES = "Horado Rajacieno", ruRU = "Лабиринты Иглошкурых" } },
  { map = 1420, 84.6, 30.6, n = { enUS = "Scarlet Monastery", deDE = "Das Scharlachrote Kloster", frFR = "Monastère Écarlate", esES = "Monasterio Escarlata", ruRU = "Монастырь Алого ордена" } },
  { map = 1413, 50.8, 92.8, n = { enUS = "Razorfen Downs", deDE = "Hügel der Klingenhauer", frFR = "Souilles de Tranchebauge", esES = "Zahúrda Rajacieno", ruRU = "Курганы Иглошкурых" } },
  { map = 1418, 44.5, 12.2, n = { enUS = "Uldaman", deDE = "Uldaman", frFR = "Uldaman", esES = "Uldaman", ruRU = "Ульдаман" } },
  { map = 1446, 38.7, 20.0, n = { enUS = "Zul'Farrak", deDE = "Zul'Farrak", frFR = "Zul'Farrak", esES = "Zul'Farrak", ruRU = "Зул'Фаррак" } },
  { map = 1443, 29.0, 62.5, n = { enUS = "Maraudon", deDE = "Maraudon", frFR = "Maraudon", esES = "Maraudon", ruRU = "Мародон" } },
  { map = 1435, 69.5, 53.5, n = { enUS = "The Temple of Atal'Hakkar", deDE = "Der Tempel von Atal'Hakkar", frFR = "Le temple d'Atal'Hakkar", esES = "El Templo de Atal'Hakkar", ruRU = "Храм Атал'Хаккара" } },
  { map = 1427, 34.8, 85.4, n = { enUS = "Blackrock Depths", deDE = "Die Schwarzfelstiefen", frFR = "Profondeurs de Rochenoire", esES = "Profundidades de Roca Negra", ruRU = "Глубины Черной горы" } },
  { map = 1428, 29.4, 38.0, n = { enUS = "Lower Blackrock Spire", deDE = "Untere Schwarzfelsspitze", frFR = "Pic de Rochenoire inférieur", esES = "Cumbre de Roca Negra Inferior", ruRU = "Нижняя часть пика Черной горы" } },
  { map = 1428, 29.4, 38.0, n = { enUS = "Upper Blackrock Spire", deDE = "Obere Schwarzfelsspitze", frFR = "Pic de Rochenoire supérieur", esES = "Cumbre de Roca Negra Superior", ruRU = "Верхняя часть пика Черной горы" } },
  { map = 1444, 59.0, 45.0, n = { enUS = "Dire Maul", deDE = "Düsterbruch", frFR = "Hache-Tripes", esES = "La Masacre", ruRU = "Забытый город" } },
  { map = 1423, 31.3, 15.7, n = { enUS = "Stratholme", deDE = "Stratholme", frFR = "Stratholme", esES = "Stratholme", ruRU = "Стратхольм" } },
  { map = 1422, 69.7, 73.2, n = { enUS = "Scholomance", deDE = "Scholomance", frFR = "Scholomance", esES = "Scholomance", ruRU = "Некроситет" } },
  -- Raids
  { map = 1427, 34.8, 85.4, raid = true, n = { enUS = "Molten Core", deDE = "Geschmolzener Kern", frFR = "Cœur du Magma", esES = "Núcleo de Magma", ruRU = "Огненные Недра" } },
  { map = 1445, 52.6, 76.8, raid = true, n = { enUS = "Onyxia's Lair", deDE = "Onyxias Hort", frFR = "Repaire d'Onyxia", esES = "Guarida de Onyxia", ruRU = "Логово Ониксии" } },
  { map = 1428, 29.4, 38.0, raid = true, n = { enUS = "Blackwing Lair", deDE = "Pechschwingenhort", frFR = "Repaire de l'Aile noire", esES = "Guarida Alanegra", ruRU = "Логово Крыла Тьмы" } },
  { map = 1434, 53.9, 17.6, raid = true, n = { enUS = "Zul'Gurub", deDE = "Zul'Gurub", frFR = "Zul'Gurub", esES = "Zul'Gurub", ruRU = "Зул'Гуруб" } },
  { map = 1451, 28.6, 92.4, raid = true, n = { enUS = "Ruins of Ahn'Qiraj", deDE = "Ruinen von Ahn'Qiraj", frFR = "Ruines d'Ahn'Qiraj", esES = "Ruinas de Ahn'Qiraj", ruRU = "Руины Ан'Киража" } },
  { map = 1451, 24.4, 87.4, raid = true, n = { enUS = "Temple of Ahn'Qiraj", deDE = "Tempel von Ahn'Qiraj", frFR = "Temple d'Ahn'Qiraj", esES = "Templo de Ahn'Qiraj", ruRU = "Храм Ан'Киража" } },
  { map = 1423, 39.9, 25.8, raid = true, n = { enUS = "Naxxramas", deDE = "Naxxramas", frFR = "Naxxramas", esES = "Naxxramas", ruRU = "Наксрамас" } },
}
