# Hexen-Spiel – Design-Entscheidungen (Stand 07.10.2026)

Ergänzt die Ideensammlung in `CLAUDE.md`. Gleiche Legende:

- ✅ **Entschieden** – gilt verbindlich
- 💡 **Idee** – von Robin gewünscht, Umsetzung später
- 🔮 **Vorschlag** – von Claude, noch nicht ausdrücklich bestätigt

Nichts aus 💡/🔮 eigenmächtig bauen. Die Ideen dienen dazu, heutige
Entscheidungen so zu treffen, dass sie später ohne Rewrite möglich sind.

---

## 1. Tagesrhythmus

✅ Gespielt wird nachts. Tagsüber schläft die Hexe, der Tag wird übersprungen.
✅ Eine Nacht dauert 12 Minuten (ist im Code bereits so, `DayCycle`).
✅ **Bett**: Schlafen überspringt den Tag bis zur nächsten Nacht (18:00) und **speichert**.
✅ **Hexenfeuer** bleibt als Zeitraffer erhalten (Bett = Tag überspringen, Feuer = Zeitraffer).
✅ Mondzyklus: 8 Nächte. Die Mondphase wird unter der Uhr angezeigt (in der Draufsicht sieht man den Himmel nicht).
🔮 **Morgen-Moment**: Beim Aufwachen kurz zeigen, was über den Tag passiert ist (Pflanzen gewachsen, Trank fertig).
🔮 Technisch: "neuer Tag" bleibt ein zentrales Signal (`DayCycle.day_passed`), auf das Pflanzen, Kessel, Mond und später NPCs hören.
💡 Später eine zweite Welt: Menschendorf am Tag.
🔮 Später: Träume beim Schlafen mit Hinweisen auf Rezepte oder Lore.

**Offen – Sonnenaufgang, wenn die Hexe draußen ist.** Automatisch nach Hause gezogen werden gefällt noch nicht. Optionen:
- Müdigkeit: ab Dämmerung langsamer, Bild verschwimmt; schläft sie draußen ein, beginnt die nächste Nacht später.
- Das Licht brennt: draußen keine Magie mehr, Schaden (weniger cozy).
- Die Welt schläft ein (Claudes Empfehlung): alles wird still, Pflanzen schließen sich, Lichter gehen aus; man kann laufen, aber nichts mehr tun, bis man ins Bett geht.

## 2. Orte und Szenen

✅ Unterschlupf → Weg in den **Garten** (eigene Szene, hier wird angebaut) → weiter in den **Wald** (nur sammeln, nicht anbauen).
✅ Beete können nur im Garten angelegt werden und sind wieder entfernbar.
**Offen – Unterschlupf:** Hütte oder etwas Moderneres. Ideen: alte Kirche (Buntglas als Lichtquelle, Kerzen, Altar als Brauort), umgebautes Gewächshaus, alter Wasserturm. Das Bett ist so gestaltet, dass es zu Hütte und Kirche passt.

## 3. Garten

### Beete und Samen
🔮 **Beet anlegen = "Erde wecken"**: Die Hexe schnippt mit ihren schwarzen Fingern, der Boden wird dunkel und locker, Magenta-Funken steigen auf. Progression später: erst 1 Feld, dann 3×3.
✅ Startsamen im Inventar: **Alraune, Geisterfarn, Laternenbeere** (je 3). Nachtschatten, Mondkelch und Blutrose findet man später.
✅ Vorerst gibt jede Ernte **1 Samen** derselben Sorte zurück, damit man den Piloten durchtesten kann. Kann später wieder raus oder anders gelöst werden.
💡 Später: Samen droppen beim "Aufräumen" der Umgebung.
💡 Später: Händler, bei dem man Items gegen seltenere Samen **tauscht** (kein Geld wie in Stardew).
💡 Viel mehr Pflanzen mit sehr unterschiedlicher Nutzung, auch Pflanzen, die **zu Gegenständen wachsen** (Waffen, Werkzeuge für die Overworld).

### Wachstum
✅ Pflanzen wachsen 1 Stufe pro Nacht (4 Stufen, nach 3 Nächten reif).
✅ Reife Pflanzen bleiben stehen, kein Verwelken (auch nützlich für Pflanzen, die man wegen Licht oder Auren stehen lässt).
💡 Gießen oder andere Wachstumsförderung (die Beet-Grafiken haben schon trockene/nasse Varianten).
💡 Pflanzen mit positiver Aura (z. B. um eine besondere Pflanze herum wachsen nur perfekte Pflanzen).
🔮 Regel: Natürliches Wachstum über Nacht kann blockiert sein (Nachtschatten, Blutrose). **Magie** (Hexenschlamm, Tränke) setzt sich darüber hinweg – Ausnahme Mondkelch, der braucht immer Vollmond.

### Pflanzen-Besonderheiten

| Pflanze | ID | Besonderheit | Leuchten |
|---|---|---|---|
| Mondkelch | `moon_chalice` | ✅ sehr besondere Zutat: bleibt auf Stufe 3 stehen, wird nur in einer Vollmondnacht reif | ✅ ja, schwächer und kleinerer Radius |
| Laternenbeere | `lantern_berry` | – | ✅ ja |
| Alraune | `mandrake` | ✅ keine (schreit nicht) | ✅ nein |
| Nachtschatten | `nightshade` | ✅ hemmt alle 8 Nachbarn (auch diagonal), außer anderen Nachtschatten; sichtbar als Kuppel (siehe unten) | nein |
| Blutrose | `blood_rose` | ✅ wächst ab Stufe 3 nicht mehr von allein, nur Magie bringt sie zur Blüte | nein |
| Geisterfarn | `ghost_fern` | ✅ keine | ✅ nein |

💡 Später: Blut von besiegten Gegnern als (besserer) Weg, die Blutrose zum Blühen zu bringen. Bis zum Kampfsystem reichen Hexenschlamm oder ein Gartentrank.

### Nachtschatten-Kuppel
✅ Statt Ranken: eine **geisterhaft blaue, halbtransparente Kuppel** über dem 3×3-Bereich, die **leicht pocht** (Frames 0-1-2-1, Frame 0 länger halten).
✅ Pflanzen unter der Kuppel **welken**: entsättigt und kühl-dunkel eingefärbt (in Godot per `modulate`, keine eigenen Grafiken).
✅ Die Kuppel erscheint, sobald der Nachtschatten anfängt zu hemmen (ab Stufe 2).
✅ Mehrere Nachtschatten nebeneinander: Die Kuppeln **überschneiden sich nicht, sondern wachsen ineinander** zu einer gemeinsamen Glocke. Umsetzung als Shader (siehe Coding-Prompt), das Einzel-Sprite `nightshade_dome.png` ist Referenz/Fallback.
✅ Die Hexe bekommt beim Betreten des Kuppelbereichs bzw. beim Ernten einen **Debuff**. Icon existiert (`debuff_nightshade.png`).
💡 Ausgestaltung des Debuffs **später**. Claudes Vorschlag zum Merken: Betreten = 30 % langsamer, solange sie drin ist (klingt 5 s nach); Ernten = nächster Trank dieser Nacht wird schwächer ("Welke Finger").

## 4. Hexenschlamm und Wachstum durch Magie

✅ Der Fehlschlag-Trank heißt **Hexenschlamm** (`potion_sludge`).
✅ Er entsteht, wenn eine Kombination kein Rezept ist (auch zweimal dieselbe Zutat).
✅ Hexenschlamm ist **Dünger**: eine einzelne Pflanze wächst sofort 1 Stufe.
✅ **Wachstumstrank**: alle Pflanzen im 3×3-Bereich wachsen sofort 1 Stufe.
🔮 Weder Schlamm noch Tränke heben den Mondkelch über Stufe 3.
🔮 Später: Selten lässt Schlamm-Dünger eine Pflanze zu einer seltenen Variante mutieren.

## 5. Brauen

### Regeln
✅ Gebraut wird **über Nacht**, 1 Trank pro Brauvorgang.
✅ Je nach Trank wird er **getrunken oder ausgegossen**.
✅ Für den Anfang höchstens 5 Rezepte: 2 mit zwei Zutaten, 3 mit drei Zutaten. Dreier-Rezepte haben stärkere Effekte. Reihenfolge egal.
✅ Das **Rezeptbuch** ist das alte Buch einer verstorbenen Hexe, das man am Anfang findet und nach und nach füllt.
✅ Hinweise: lose Seiten aus diesem Buch, anfangs im Haus, später auf der Map verteilt, auch als unsichtbare Items.

### Die 5 Rezepte

| Zutaten | ID | Name | Wirkung | Nutzung | Fundweg |
|---|---|---|---|---|---|
| Alraune + Geisterfarn | `potion_growth` | Wachstumstrank | Pflanzen im 3×3 sofort +1 Stufe | ausgießen | Ausprobieren |
| Laternenbeere + Nachtschatten | `potion_will_o_wisp` | Irrlicht | ein kleines Licht folgt der Hexe für den Rest der Nacht | trinken | Ausprobieren |
| Alraune + Geisterfarn + Mondkelch | `potion_moon_harvest` | Mondernte | alle Pflanzen im 3×3 sofort reif (Mondkelch ausgenommen) | ausgießen | Ausprobieren |
| Laternenbeere + Nachtschatten + Mondkelch | `potion_liquid_moonlight` | Flüssiges Mondlicht | großes Licht um die Hexe, verborgene Items werden sichtbar | trinken | Grimoire-Seite |
| Blutrose + Nachtschatten + Alraune | `potion_endless_night` | Ewige Nacht | die aktuelle Nacht dauert länger (🔮 +50 %) | trinken | Grimoire-Seite |

Idee dahinter: Zwei Dreier-Rezepte sind ein bekanntes Zweier-Rezept plus Mondkelch – wer neugierig einen Mondkelch dazuwirft, entdeckt sie selbst.
💡 Später: Stärke eines Tranks oder Zaubers bestimmt, wie viel länger die Nacht wird.
💡 Später: Flüssiges Mondlicht zeigt auch unsichtbare Durchgänge.
🔮 Die übrigen (Schlamm-)Kombinationen können später echte Rezepte werden, wenn neue Zutaten dazukommen.

Beschreibungstexte im Spiel (bereits nach den Schriftregeln: keine Gedankenstriche, keine deutschen Anführungszeichen, keine Auslassungspunkte):

| Trank | Beschreibung |
|---|---|
| Wachstumstrank | Die Wurzeln flüstern sich gegenseitig Mut zu. |
| Irrlicht | Folge ihm nicht. Oder doch. |
| Mondernte | Der Mond hat es eilig heute Nacht. |
| Flüssiges Mondlicht | Was du siehst, hat dich schon lange gesehen. |
| Ewige Nacht | Die Sonne kann warten. Du nicht. |

### Brau-Fenster am Kessel
✅ Per E am Kessel öffnet sich ein Fenster, Zutaten per **Drag & Drop** aus dem Inventar.
✅ **Mitwachsende Felder im Bogen über einem Kessel**: Anfangs ein leeres Feld; ist es belegt, erscheint das nächste – bis die Kapazität erreicht ist. Kein festes Raster, weil die Reihenfolge egal ist und Zweier- wie Dreier-Rezepte sich "fertig" anfühlen sollen.
✅ **Kessel aufrüstbar**: Start-Kapazität 3, später mehr (4, 5 …). Kapazität als Datenwert, nicht fest im Code.
✅ **Kapazitäts-Rauten** unter dem Kessel zeigen belegt/frei.
✅ Ab 2 Zutaten: Sud glüht magenta, Pfeil funkelt, Brauen-Knopf aktiv.
🔮 Ergebnis-Feld: bei bekannten Rezepten der Trank mit Name, bei unbekannten "?" bzw. "???" – das Ergebnis zeigt sich erst am nächsten Morgen.
🔮 Kleine Animationen: nächstes leeres Feld pulsiert leicht; abgelegte Zutat "plumpst" in den Kessel.

## 6. Grafik

✅ **Palette gelockert**: Die Palette bleibt Basis und Farbsemantik, aber Zwischentöne und passende Farben sind erlaubt, damit Verläufe natürlicher wirken (Schatten Richtung Blau/Violett, Lichter Richtung Warm). Weiterhin harte Pixel, kein Anti-Aliasing, keine weichen Gradienten, Licht oben links, Aubergine-Outlines. Richtwert 8–12 Farben pro Grafik. Neue Farben: `docs/art/neue_farben.md`.
✅ **UI-Grafiken werden ab jetzt in 1× gespeichert** und in Godot doppelt so groß angezeigt (Vorbereitung für einstellbare UI-Größe). Die Hotbar ist noch 2× vorskaliert und wird irgendwann neu exportiert.
✅ Irrlicht: Variante mit zwei herausschwebenden Funken.
✅ Bett: dunkles Ebenholz mit Goldknäufen, Bordeaux-Decke, keine Falten; schlafend mit Decke bis über die Nase (nur Haare + Goldnadel sichtbar).

## 7. Technische Leitplanken

- **Gemeinsamer Spielstand außerhalb der Szenen** (Autoload): Garten, Unterschlupf und Wald werden eigene Szenen, Pflanzen dürfen ihren Zustand nicht nur im Szenen-Node halten. Muss vor dem Szenenwechsel und dem Speichern stehen.
- **Ernte ergibt "Item X"**, nicht fest "Zutat" – damit Pflanzen später zu Waffen/Werkzeugen wachsen können.
- **Allgemeines Aura-System** in `PlantData` (Reichweite + Wirkung). Nachtschatten ist die erste negative Aura; positive Auren kommen später.
- **Rezepte als Datendateien mit Zutatenliste** (2–N Zutaten, beim Vergleich sortieren). Jeder Trank hat in den Item-Daten "trinken" oder "ausgießen".
- **Kessel-Kapazität als Datenwert** (für Upgrades).
- **Spieltexte**: Die Schrift kennt keine Gedankenstriche, keine deutschen Anführungszeichen, keine Auslassungspunkte. IDs sind englisch.

---

## 8. Nachträge aus der Umsetzung (07.10.2026, Coding-Session)

✅ Nachtschatten hemmt erst ab der **Blüte** (`aura_min_stage = 2`, Stufen ab 0 gezählt).
✅ Die Aura ist **kein Glas, sondern Nebel**: ziehende Schwaden, ausgefranster Rand, gerastert (Dither). Verschmelzen und Pochen wie geplant.
✅ Auch reife Pflanzen unter der Aura welken sichtbar (wichtig für den späteren Ernte-Debuff).
✅ Mit Trank in der Hand hat Ausgießen Vorrang vor Ernten; wächst nichts, wird geerntet und der Trank bleibt.
✅ Magie macht den Mondkelch nicht reif (`magic_can_ripen = false`). Wenn es Mondphasen gibt, wird er nur bei Vollmond reif.
✅ Inventar-Fenster mit **Tab**: Plätze 9–24 über der Hotbar, Drag & Drop, nur der Item-Name beim Darüberfahren (keine Box).
✅ **Beschreibungstexte** der Tränke stehen in den Item-Daten und kommen später ins **Rezeptbuch**, nicht ins Inventar.
✅ Hexenschlamm-Text: „Riecht nach Keller. Die Pflanzen lieben es.“
✅ **Trinken: Q oder Rechtsklick.** Ausgießen bleibt E auf ein Beet.
✅ Brau-Fenster: bekannte Kombinationen (schon einmal gebraut) zeigen Trank und Namen, unbekannte ???. Gelernt wird erst, wenn der Trank am Morgen fertig ist. Rechtsklick nimmt eine Zutat wieder heraus.
✅ Während der Kessel braut, ist das Fenster gesperrt (Knopf „Braut“). Fertige Tränke schweben über dem Kessel und werden mit E abgeholt.
💡 **Mülleimer** später als eigenes Objekt in der Welt, nicht im Inventar.
💡 Item-Details evtl. per Rechtsklick im Inventar – oder nur im Rezeptbuch (offen).
✅ **Bett und Kessel stehen im Garten**, nicht im Unterschlupf. Die Hexe wacht im Garten auf. Der Unterschlupf bleibt vorerst ein leerer Ort.
✅ **Schweben mit Shift**: 2,5× so schnell, die Hexe hebt per Magie leicht ab und hinterlässt magentafarbene Funken.
✅ **Kein Morgen-Moment**: Beim Aufwachen erscheint kein Text. Was über den Tag passiert ist, entdeckt man selbst im Garten.
