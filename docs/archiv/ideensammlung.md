# Archiv: Ideensammlung (bis 16.10.2026 in CLAUDE.md)

Stand der Ideen aus der Anfangszeit. Überholt durch `docs/design/game_design.md` und die neueren Dokumente (Übersicht: `docs/START.md`). Hier stehen noch die ursprünglichen Wünsche zu Hauptfigur, Sound, Umgebung, Begleitern und Progression. Die technischen Leitplanken stehen jetzt in `CLAUDE.md`, Abschnitt 12.

# Hexen-Spiel – Ideensammlung

Sammlung aller bisherigen Ideen zum Spiel. Ergänzt `CLAUDE.md` (dort stehen die verbindlichen Regeln).

**Legende**
- ✅ **Entschieden** – gilt verbindlich
- 💡 **Idee** – von Robin gewünscht, Umsetzung später
- 🔮 **Vorschlag** – von Claude ergänzt, noch nicht entschieden

**Wichtig für Claude:** Nichts aus dem Bereich 💡/🔮 eigenmächtig bauen. Die Ideen dienen dazu, heutige Entscheidungen so zu treffen, dass diese Features später ohne Rewrite möglich sind.

**Neuere Entscheidungen** stehen in eigenen Dateien und gehen dieser Sammlung bei Widersprüchen vor:
- `docs/design/grimoire.md` (08.10.2026) – **neueste Quelle zum Grimoire**: Kapitel, Seiten, Opfer, Disziplinen, Hexenpfade, Optik, Technik
- `docs/design/game_design.md` (08.10.2026) – **neueste Quelle zum Gesamtdesign**: Kern-Loop, Mondphasen, Fortschritt, Digitalis, Kampf, NPCs, Lore, Umsetzungsreihenfolge. Überholt in dieser Sammlung u. a. Hexenpfade, Nahkampf, Altar und die Reihenfolge in Abschnitt 9
- `docs/auftrag_einbau_grafiken.md` (08.10.2026) – laufender Einbau der neuen Grafiken in Schritten
- `docs/design/design_entscheidungen_2026-10-07.md` – Tagesrhythmus, Bett, Garten, Nachtschatten, Hexenschlamm, Brauen, 5 Rezepte, Grafikregeln
- `docs/design/checkliste_basics.md` – was vor den großen Erweiterungen noch fehlt (abhaken, wenn erledigt)
- `docs/design/dorf_hub_plan.md` (12.10.2026) – Dorf-Hub: Layout, Nachtwächter, NPC-/Dialog-/Freischaltungs-System, Meilensteine M1–M8 und Robins Entscheidungen
- `docs/design/overworld_plan.md` (16.10.2026) – Overworld mit Höhen: Weltgraph aus der KI-Karte, Baupläne in Aseprite, World-Builder, Klippen-Layer, Platzhalter-Atlas, Schritte W1–W7
- `docs/design/welt_und_items.md` (16.10.2026, von Robin angenommen) – **neueste Quelle zu Weltgraph, Sperren und Item-Kreislauf**: Orte und Ressourcen, Sperren S1–S8, Verwendungen aller Items, Rezept-Änderungen, Upgrades bei Gnarl, Gesuche, Umsetzungsreihenfolge

---

## 1. Identität und Stil

✅ **Dark Cozy Witchcraft**: mysteriös, leicht düster, aber gemütlich. Nicht „Stardew mit Hexenhüten", nicht reines Gothic.
✅ 2D-Pixel-Art, Top-down, keine Isometrie, 32×32-Tiles
✅ Dunkle Welt mit warmen Lichtinseln; Cozyness durch den Kontrast zwischen Dunkelheit und Wärme
✅ Stimmung: mysteriös-sexy, aber cozy
✅ Figurenproportionen schlank
✅ Kamerazoom mittel (nicht ganz nah, aber nicht zu viel Welt)
✅ Palette und Farbsemantik: siehe `CLAUDE.md`

### Hauptfigur
✅ Stylische, selbstbewusste, dunkelhäutige moderne Hexe, **ohne Hut**
✅ Goldene Akzente auf der Haut, **komplett schwarze Finger** (als wäre sie von der Dunkelheit verschlungen)
✅ Akzentfarben Gold und Magenta, insgesamt sehr dunkel und divenhaft
✅ Konzeptskizze (ChatGPT) und erster Pixel-Sprite (Gemini) existieren

### Sound
✅ Dreamy, warm, leicht melancholisch, feminin/magisch, nachts, sinnlich, mysteriös, soft, etwas urban/modern
✅ Stimmungsreferenz: SZA – *SOS Deluxe: LANA*

---

## 2. Umgebung und Atmosphäre

💡 **Kristalle** – leuchtend, als Lichtquellen
💡 **Kerzen** – überall verteilt
💡 **Ranken** – an Gebäuden und in der Welt
💡 Insgesamt hexiger Look der Umgebung

🔮 Ausbau-Vorschläge:
- Kristalle in Magenta als magische Lichtinseln; in Dungeons/Höhlen häufiger; evtl. sammelbar als Zutat
- Kerzen auf Fensterbänken, Grabsteinen, Treppen; heruntergebrannt mit Wachsspuren; nachts eigene Lichtquelle
- Ranken an Hauswänden, Zäunen, Ruinen; magische Ranken, die mit dem Spielfortschritt mitwachsen oder Wege freigeben
- Weitere Deko: Pilzringe (leuchtend), Glühwürmchen, Bodennebel, Kräuterbündel unter Dächern, Knochen-Windspiele, Kessel mit Dampf
- Orte unterscheiden sich über Farbgewichtung (siehe `CLAUDE.md`): Garten grün-warm, Dorf Kerzenlicht/Gold, Friedhof Nachtblau/Magenta

---

## 3. Farming und Tränke (Kern des Spiels)

✅ Pflanzen mit mehreren sichtbaren Wachstumsphasen (Samen → Keimling → wachsend → erntereif)
✅ Mehrere Pflanzenarten
✅ Pflanzen dienen später für Tränke, Quests, Magie, Handel, Geschenke, Crafting, Ereignisse

**Umgesetzt (Stand 07.10.2026)** – Details in `docs/design/design_entscheidungen_2026-10-07.md`:
✅ Garten-Zustand im Autoload `Garden` (wächst auch ohne geladene Szene), Wachstum 1 Stufe pro Nacht, Ernte gibt 1 Samen zurück
✅ Nachtschatten-Aura: hemmt die 8 Nachbarn ab der Blüte, Nachbarn welken (Shader), neblige blaue Aura, mehrere verschmelzen
✅ Hexenschlamm = Dünger (1 Pflanze), Wachstumstrank 3×3, Mondernte 3×3 sofort reif; Magie macht den Mondkelch nicht reif
✅ Brau-Fenster am Kessel: mitwachsende Felder, Kapazität 3 als Datenwert, 5 Rezepte, bekannte Mischungen mit Namen, sonst ???
✅ Brauen über Nacht, Abholen am Kessel; Trinken mit Q/Rechtsklick (Irrlicht, Flüssiges Mondlicht, Ewige Nacht)
✅ Bett: Schlafen überspringt den Tag bis 18:00 und speichert (Nacht, Inventar, Garten, Kessel)
✅ Inventar-Fenster (Tab) mit Drag & Drop, Spiel pausiert bei offenen Fenstern

🔮 Leitgedanke: **Kampf und Fortschritt entstehen aus dem Garten.** Pflanzen → Tränke → Zauber/Buffs. Dungeon-Beute (seltene Samen, Rezepte, Kristalle) fließt zurück in den Garten.

---

## 4. Welt, NPCs und Social-System

✅ Größere Nachbarschaft wie ein kleines Dorf mit vielen verschiedenen Figuren
💡 Vampir-Nachbar (noch nicht ausgearbeitet)
✅ NPCs sollen sich wie Personen anfühlen: Persönlichkeit, Beziehungen, Tagesabläufe, Geheimnisse, Vorlieben (siehe `CLAUDE.md`)

### Sidequests
💡 NPC-Sidequests
🔮 Quests mit Atmosphäre und Charakter, z. B. „Bring mir eine Pflanze, die nur bei Vollmond blüht", oder Quests, die ein Geheimnis eines NPCs aufdecken
🔮 Zeitpunkt: nach dem Dialogsystem

---

## 5. Dungeons

💡 Dungeons mit coolen Belohnungen und Waffen
🔮 Hexige Orte: Gruften unter dem Friedhof, überwucherte Ruinen, Höhle mit leuchtenden Pilzen und Kristallen
🔮 Beute statt klassischer Waffen: Zauberstäbe, Grimoire-Seiten (neue Zauber), Hexenhüte/Umhänge mit Effekten, seltene Samen, Kristalle als Trankzutaten

---

## 6. Kampf und Magie

💡 Kampfsystem mit Magie (Hexe als Magierin)
🔮 Einstieg mit 2–3 Zaubern (z. B. Projektil, Flächenzauber, Schild); Mana oder Tränke als Ressource
🔮 Reiz durch Kombinationen (z. B. Giftzauber + Feuertrank → neuer Effekt) – passt zum Prinzip „Was passiert wohl, wenn ich das mache?"
🔮 Keine Schwerter/Nahkampf als Hauptsystem

---

## 7. Begleiter (Tiere und Wesen)

💡 Tiere oder magische Wesen als Begleiter, die Buffs geben
🔮 Als **Vertraute (Familiars)**: Katze, Rabe, Kröte, Fledermaus, später magische Wesen
🔮 Buffs nicht nur im Kampf, auch im Alltag:
- Kröte: Pflanzen wachsen schneller
- Rabe: findet seltene Items
- Katze: sieht versteckte Dinge in der Nacht
🔮 Eigene Persönlichkeit; Freischalten durch Füttern, Vertrauen, Quests
🔮 Gut geeignet als frühes, kleines cozy Feature (Tier folgt der Hexe + ein Gartenbonus)

---

## 8. Progression

### Begleiter leveln
💡 Begleiter können leveln
🔮 Höhere Stufen schalten **neue Fähigkeiten** frei statt nur höherer Zahlen (z. B. Kröte gießt erst ein Feld, später einen Bereich)
🔮 Leveln durch gemeinsame Zeit, Füttern mit Lieblingspflanzen aus dem Garten, Dungeon-Erfolge
🔮 Sichtbare Veränderung bei höherer Stufe (leuchtende Augen, Accessoire)

### Waffen leveln
💡 Waffen können leveln
🔮 Statt Waffen-XP lieber **Verzaubern/Aufwerten** an Arbeitstisch oder Altar mit Zutaten aus Garten und Dungeon (z. B. Kristall in Zauberstab einsetzen, Grimoire um Seiten erweitern)
🔮 Erzeugt Entscheidungen (Feuer- oder Giftkristall?)

### Hexenpfade / Skillbaum
💡 Start-„Zauber" wie ein Skillbaum, am Anfang wählbar – z. B. schnelleres Pflanzenwachstum, mehr Schaden oder mehr Sympathiepunkte bei NPCs
🔮 Drei Pfade/Zirkel, je mit Farbe aus der Palette:
- **Kräuterhexe** (Giftgrün): schnelleres Wachstum, mehr Ernte, bessere Tränke
- **Schattenhexe** (Magenta): mehr Zauberschaden, stärker in Dungeons
- **Herzhexe** (Bordeaux): mehr Sympathie, bessere Preise, Zugang zu Geheimnissen
🔮 Aufbau:
1. Start: Pfad wählen mit kleinem Bonus
2. Im Spiel: Skillpunkte über Level, Rituale oder Grimoire-Seiten
3. Fähigkeiten anderer Pfade lernbar, eigener Pfad nur günstiger
4. Optional: Ritual zum Pfadwechsel
🔮 Regeln: Keine Wahl sperrt Spielinhalte komplett; Pfade verschieben nur den Schwerpunkt

---

## 9. Vorgeschlagene Reihenfolge (🔮)

1. ✅ Beet und Pflanzenwachstum
2. ✅ Inventar, Ernte, Tränke brauen (Grundversion; Basics siehe `docs/design/checkliste_basics.md`)
3. Erster Begleiter: folgt der Hexe, gibt Gartenbonus
4. Dialog, NPCs, Sidequests
5. Startwahl Hexenpfad (sobald mind. Garten + NPCs existieren)
6. Kleiner Dungeon mit 2–3 Zaubern und einfachen Gegnern
7. Leveln der Begleiter, Verzaubern von Waffen, Skillbaum

---

## 11. Komfort und Einstellungen

💡 Größe der UI einstellbar (sehr viel später)
🔮 Nur ganzzahlige Stufen (1×, 2×, 3×), damit die Pixel scharf bleiben
🔮 Technisch: UI-Grafiken dafür in 1× speichern und die UI als Ganzes skalieren – die Hotbar-Grafiken sind aktuell noch in 2× vorskaliert und müssten dann einmal neu exportiert werden (Generator: `docs/art/ui_generator/hotbar.py`)
