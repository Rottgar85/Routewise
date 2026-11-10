# Routewise veröffentlichen

GitHub baut die ZIP automatisch und lädt sie zu CurseForge (und auf Wunsch zu Wago) hoch.
Diese Datei, `docs/` und der Ordner `.github` landen nicht in der ZIP.

## Einmal einrichten

1. **GitHub-Repository** `Rottgar85/Routewise` anlegen und den Ordner hochladen (`git push -u origin main`).
2. **CurseForge-Projekt** anlegen: curseforge.com → *Create a Project* → World of Warcraft → Addon.
   Name „Routewise – In-game GPS“, Kategorie *Map & Minimap*, Spielversion **WoW Forever**,
   Beschreibung aus `docs/CURSEFORGE.md` einfügen.
3. Die **Projekt-ID** steht schon in `Routewise.toc`: `## X-Curse-Project-ID: 1796421`
   (curseforge.com/projects/1796421)
4. **API-Token** auf curseforge.com → Profil → *API Tokens* erzeugen und auf GitHub als Secret
   `CF_API_KEY` hinterlegen (Repository → Settings → Secrets and variables → Actions → New repository secret).

Für Wago zusätzlich: `## X-Wago-ID: abcdef12` in die `.toc` und das Secret `WAGO_API_TOKEN`
(addons.wago.io → Account → API Keys). Das GitHub-Token ist automatisch vorhanden.

## Lua-Code lokal prüfen (luacheck)

- `luacheck.exe` (v1.2.0, github.com/lunarmodules/luacheck/releases) liegt in `.tools/` – nicht im Git, nicht in der ZIP
- Von Hand: `.\.tools\luacheck.exe . --no-color`
- Automatisch vor jedem `git push` über `.githooks/pre-push`; bei Fehlern wird der Push abgebrochen.
  Einmal pro Klon einschalten: `git config core.hooksPath .githooks`

## Neue Version veröffentlichen

1. In `Routewise.toc` die `## Version:` erhöhen und in `CHANGELOG.md` eintragen, was neu ist
   (zuerst **English**, dann **Deutsch**). Das kann der Agent `routewise-release` vorbereiten.
2. Änderungen hochladen (commit und push). GitHub prüft dabei den Lua-Code (Check).
3. Einen Tag mit der Version setzen und hochladen, zum Beispiel:
   `git tag v0.1.0` und dann `git push origin v0.1.0`
4. Unter „Actions“ im Repository siehst du, wie die ZIP gebaut und hochgeladen wird.
   Die fertige ZIP liegt danach auch unter „Releases“.

## Ohne GitHub: ZIP von Hand hochladen

Auf curseforge.com → Projekt → „Upload File“ die fertige ZIP wählen, als Spielversion **WoW Forever**
angeben, Release-Typ „Release“ (oder „Beta“ für 0.x) und den Abschnitt der neuen Version aus
`CHANGELOG.md` als Changelog einfügen. Die ZIP muss den Ordner `Routewise` enthalten,
ohne `.git`, `.github`, `.claude`, `.tools` und `docs`.
