# Routewise

WoW-Addon (Lua 5.1) für **WoW Forever** (Interface 16001, `WOW_PROJECT_CAMELOT`): Routenplaner/Navi mit Flugmeistern, Schiffen, Zeppelinen, Tiefenbahn und Fußwegen. Elf Sprachen.

Forever läuft auf dem Midnight-Retail-Client (Patch 1.60.x enthält die Modern-API bis 12.1.5): `Settings`, `C_SuperTrack`, `C_Map`-Wegpunkte, `C_EncounterJournal` sind vorhanden, die Midnight-Einschränkungen für Addons (Secret Values im Kampf) gelten auch hier. `C_TaxiMap.GetTaxiNodesForMap` liefert `isUndiscovered`, kein `state`.

Dieser Ordner ist gleichzeitig der installierte Addon-Ordner (`_forever_\Interface\AddOns\Routewise`): Änderungen sind nach `/reload` sofort im Spiel.

## Aufbau (Ladereihenfolge wie in `Routewise.toc`)

- `Core.lua` – Namespace `WF` (auch global `Routewise`), interner Event-Bus `WF:On`/`WF:Fire` (`INIT`, `READY`, `GRAPH_DIRTY`, `ROUTE_CHANGED` …), SavedVariables `RoutewiseDB` (accountweit, mit Defaults) und `RoutewiseCharDB` (bekannte Flugmeister).
- `Locale.lua` – `WF.L`, Texte je Client-Sprache, fehlende Einträge fallen auf Englisch zurück. Neue Keys immer zuerst in `T.enUS`.
- `Util.lua` – Hilfsfunktionen (`WF.Util`): Position, Zeitformat …
- `Data/Transport.lua`, `Data/Instances.lua` – feste Daten: Schiffe/Zeppeline/Bahn, Instanzeingänge.
- `MapResolver.lua` (Zonen/Karten), `Taxi.lua` (Flugmeister, gemessene Flugzeiten), `Hostile.lua` (feindliche Lager/Städte), `Graph.lua` + `Pathfinder.lua` (Routenberechnung), `Navigator.lua` (aktive Route, Etappen, Neuberechnung).
- `NavHUD.lua` (Navi-Anzeige), `MapOverlay.lua` (Weltkarte), `UI.lua` (Routenmenü, Minikarten-Knopf), `Dungeons.lua` (Instanzliste aus Dungeon-Kompendium + Liste), `Options.lua` (Einstellungen), `Commands.lua` (`/rwise`).
- `Media/` – Texturen (TGA).

Neue Dateien in `Routewise.toc` eintragen, in der richtigen Reihenfolge.

## Agenten

- `wow-addon-dev` – Funktionen bauen und Fehler beheben.
- `routewise-reviewer` – nach Änderungen auf Syntax, nil-Fehler, Taint und Ladereihenfolge prüfen (lokal: `.\.tools\luacheck.exe . --no-color`; luacheck läuft auch in GitHub Actions).
- `wow-api-checker` – API/Events/Interface-Nummer gegen warcraft.wiki.gg und wow-ui-source prüfen.
- `routewise-release` – Version und CHANGELOG für ein CurseForge-Release vorbereiten.

## Veröffentlichen

Wie GuildPride und Scales: Tag `vX.Y.Z` pushen → GitHub Actions + BigWigs-Packager → CurseForge. Siehe `VEROEFFENTLICHEN.md`. CurseForge-Projekt-ID: 1796421 (in `Routewise.toc`). Version steht in `Routewise.toc` (`## Version:`), CHANGELOG zweisprachig (English, dann Deutsch).
