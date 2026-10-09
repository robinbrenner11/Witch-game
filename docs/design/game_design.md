# Bitterbloom – Game Design

Stand: 08.10.2026. Zusammenfassung der Design-Session zu Kern-Loop, Fortschritt, Entdecken, Items und Magie, Kampf, NPCs und Lore. Ergänzt `design_entscheidungen_2026-10-07.md`. Wo sich beide widersprechen, gilt **dieses Dokument**.

Legende: ✅ entschieden · 💡 Idee, gefällt, noch nicht fest · 🔮 später / nach Akt 1 · ❓ offen · ❌ verworfen

---

## 1. Spielidee

**Elevator Pitch:** Bitterbloom ist ein Cozy RPG mit Action-Elementen, das nur nachts spielt. Eine junge Hexe folgt dem Ruf einer Fingerhut-Blume in den verlassenen Garten einer geflohenen Hexe. Sie baut sich dort ein Zuhause auf, braut Tränke, freundet sich mit dem Nachtvolk an und dringt immer tiefer in einen Wald vor, den die Bitterblüte langsam zerfrisst. Diese Fäulnis hat die alte Hexe selbst ausgelöst.

**Warum macht es Spaß?**
- **Die Nacht gehört dir.** Garten, Wald, Brauen, Tauschen, Kämpfen: Du entscheidest jede Nacht selbst, was du tust.
- **Jede Freischaltung ist eine neue Möglichkeit**, keine bessere Zahl: eine neue Waffenform, ein neues Gebiet, ein neuer Trank, ein neuer NPC.
- **Kämpfen fühlt sich gut an.** Du zielst in Echtzeit mit der Maus, die Fingerhut-Waffe verwandelt sich, und Wurftränke kommen dazu. Besiegte Wesen werden gereinigt, nicht getötet.
- **Die Welt heilt sichtbar.** Geheilte Gebiete bleiben lebendig und haben dauerhaft einen Grund, wiederzukommen.
- **Ein Geheimnis zieht dich weiter:** Was hat Vespera Hollow getan, und warum hat der Fingerhut gerade dich gerufen?
- **Kein Ende, nur ein Höhepunkt.** Nach der Hauptgeschichte bist du die Hüterin des Waldes, und das Spiel wächst mit jedem Update weiter.

**Grundhaltung**
- ✅ Genre: **Cozy RPG mit Action-Elementen**, kein reines Cozy Game.
- ✅ Ein langes Projekt, an dem immer weitergearbeitet wird. Das Spiel soll sich nie „fertig durchgespielt“ anfühlen.
- ✅ Vorgehen: **Akt 1 zuerst vollständig spielbar**, dann Stück für Stück erweitern.
- ✅ **Das Spiel wird auf Englisch umgestellt**, also alle Spieltexte, Namen und die UI. Siehe Abschnitt 11.

---

## 2. Kern-Loop

### Eine Nacht
1. Aufwachen im Garten.
2. Selbst planen: Garten pflegen, brauen, sammeln, NPCs besuchen, tauschen, in befallene Gebiete gehen und kämpfen.
3. Schlafen gehen. Der Kessel braut über Nacht, Pflanzen wachsen, manchmal kommt ein Traum.

✅ Es gibt keine Pflicht-Quest pro Nacht. Das Tempo ist wie bei Stardew.

### Ein Mondzyklus (8 Nächte)
- ✅ Jede Phase soll etwas Besonderes haben. Die genauen Effekte sind teils noch offen, siehe Abschnitt 5.
- ✅ 🌑 **Neumond:** Die Bitterblüte ist am stärksten.
- ✅ 🌓 **Halbmond:** Halbmondmarkt, Händler und Wanderer kommen.
- ✅ 🌕 **Vollmond:** Der Mondkelch wird reif, der Hexenring ist aktiv. **Nicht jeder Vollmond ist ein Fest.**
- ✅ Seltene Ereignisse wie der Sternenschauer werden nur von NPCs angekündigt.

### Langfristig
- ✅ Alles gleichzeitig, ohne feste Reihenfolge:
  - Zuhause aufbauen;
  - stärker werden und starke Gegner besiegen;
  - Freundschaften mit NPCs;
  - erkunden;
  - die Lore aufdecken.
- ✅ Besondere Nächte, in denen eine große Sache passiert:
  - einen Begleiter finden;
  - ein Blütenherz reinigen;
  - ein neuer NPC kommt dazu.

---

## 3. Fortschritt

### Grundregel
- ✅ Großer Fortschritt bedeutet **neue Gebiete** und **Hexenstärke**.
- ✅ Große Freischaltungen bringen immer **eine neue Aktion oder einen neuen Ort**. Leveln (bessere Tränke, perfekte Pflanzen) ist der kleine Fortschritt dazwischen.

### Das Grimoire: der rote Faden
- ✅ Das Grimoire von Vespera Hollow ist **das zentrale Element des Spiels**:
  - Fortschrittsanzeige;
  - Rezeptbuch;
  - Kompendium;
  - Erzählweg.
- ✅ Seine Seiten sind verstreut. Jede Seite bringt Rezept, Lore und Freischaltung.
- 💡 Manche Seiten verlangen ein „Opfer“ (Zutaten), dann stellt sich die Seite wieder her.
- ✅ **Inhalt und Design des Buchs werden in einer eigenen Session komplett überarbeitet.**

### Kapitel = Disziplinen (Levelsysteme)

Jede Disziplin steigt durch Tun auf. Viele Levelsysteme sind gewollt, und alle laufen im Buch zusammen.

| Kapitel (englisch, Vorschlag) | Steigt durch | Bringt zum Beispiel |
|---|---|---|
| Herbalism (Kräuterkunde) | Pflanzen, Ernten | bessere Qualität, perfekte Pflanzen, neue Samen |
| Brewing (Braukunst) | Brauen | stärkere Tränke, neue Rezepte, mehrere auf einmal |
| Wildcraft (Wildkunde) | Sammeln, Erkunden | seltene Funde, Sternensplitter, versteckte Orte |
| Warding (Bannkunst) | Kämpfen, Zaubern | Angriffs- und Schutzzauber, Kampftränke |
| Bonding (Bindung) | Zeit mit dem Begleiter | Fähigkeiten der Katze und später weiterer Begleiter |
| Vespera's Journal (Tagebuch) | gefundene Seiten | Lore, große Freischaltungen |
| Anhang: Herbarium und Bestiarium | Entdecken | Belohnungen für volle Seiten |

- ✅ **Hexenpfade:** Bei Meilenstein-Stufen (z. B. 5 und 10) wählt man zwischen zwei Vorteilen.
- ✅ **Technik:** ein einziges, datengetriebenes Disziplin-System (Disziplin, Erfahrungspunkte, Stufen, Belohnungen als Daten), keine sechs Einzelsysteme. Später leicht erweiterbar.

### Rezepte entdecken
- ✅ Drei Wege:
  - Ausprobieren im Kessel;
  - Grimoire-Seiten;
  - Gerüchte von NPCs und aus der Welt.
- 🔮 Mehr Zutaten und Rezepte erst, wenn das Spiel einigermaßen rund ist.

### Tausch (kein Geld)
- ✅ Der Tausch bringt alles:
  - Samen und Zutaten;
  - Upgrades für Kessel und Garten;
  - Möbel und Deko;
  - Grimoire-Seiten und Hinweise;
  - Werkzeuge, Waffen und Ausrüstung.
- 💡 Jeder NPC hat einen Schwerpunkt.
- ✅ Ablauf, **mit Fokus auf B**:
  - A: Halbmondmarkt mit festen Tauschlisten;
  - B: NPCs, die in der Welt verteilt sind und wechselnde Gesuche haben.

### Herstellen
- 💡 **Crafting über den Kessel**: Der Kessel braut nicht nur, sondern stellt auch Dinge her. ❓ Wie genau, muss noch gründlich durchdacht werden.

### Akt-Struktur
- 💡 Akt 1: Garten und Wald (ungefähr 3 Mondzyklen).
- 💡 Akt 2: Dorf und Nachtvolk.
- 💡 Danach geht es immer tiefer in den Wald, dann kommen Erweiterungen.
- ✅ Early Game darf lange dauern.

---

## 4. Geheilte Gebiete (keine Einweg-Level)

- ✅ Jedes Gebiet hat **nach der Heilung einen dauerhaften Grund**, wiederzukommen.
- 💡 Regel: Jedes Gebiet bekommt mindestens 3 der folgenden 7 Dinge:
  1. **Eigene Ressource**, die es nur dort gibt und die nachwächst.
  2. **Bewohner oder Funktion**: ein NPC, Händler oder Lehrer, eine Quelle für stärkere Tränke, ein Wildbeet.
  3. **Mondereignis**, das nur dort passiert.
  4. **Kompendium-Einträge**, nur dort und nur in bestimmten Mondphasen.
  5. **Hexenring als Schnellreise**, der durch die Heilung erwacht.
  6. **Kleine Rückfälle** bei Neumond: optional, kurz, mit verdorbenen Zutaten.
  7. **Pflegen**: Mit ausgebrachter Wildsaat wird das Gebiet über die Zeit reicher.

---

## 5. Entdecken und Mondphasen

- ✅ Experimentieren im Kessel ist erlaubt. Fehlschläge ergeben Hexenschlamm.

| Nacht | Phase | Effekt |
|---|---|---|
| 1 | 🌑 New Moon | ✅ Die Blüte ist am stärksten (mehr Befall, Rückfälle, verdorbene Zutaten) |
| 2–3 | 🌒 Waxing | ❓ offen. ❌ nicht „Pflanzen wachsen besser“. Darf auch ohne Effekt bleiben. |
| 4 | 🌓 Half Moon | ✅ Halbmondmarkt, Händler und Wanderer |
| 5–7 | 🌔 Gibbous | ❓ offen. ❌ nicht „Sammelobjekte leuchten“. |
| 8 | 🌕 Full Moon | ✅ Mondkelch reif, Hexenring aktiv, manchmal ein Fest |

- ✅ **Seltene Ereignisse**, ungefähr eines pro Zyklus. Beispiele:
  - Sternenschauer (Sternensplitter in der nächsten Nacht);
  - 💡 Blutmond;
  - 💡 Nebelnacht;
  - 💡 Glühwürmchenzug.
- ✅ Angekündigt werden sie **nur von NPCs**.
- ✅ Das Kompendium ist ein Anhang im Grimoire.

**Umsetzungsstand (08.10.2026):** Autoload `Moon` (`scripts/systems/moon.gd`), 8 Nächte wie in der Tabelle, Nacht 1 eines neuen Spiels ist Neumond. Abfragen: `Moon.phase()`, `is_new()`, `is_half()`, `is_full()`, `cycle()`, `nights_until()`, Signal `phase_changed`. Schon spürbar: Nachtfärbung je Phase (Neumond tiefer, Vollmond silbriger), Meldung zu Beginn von Neumond, Halbmond und Vollmond, Hexenring leuchtet bei Vollmond stärker (Funktion folgt), Mondkelch und Mondmoos, Vollmond-Musik, Vollmond-Vorschau im Grimoire. Noch offen, weil die Systeme fehlen: Bitterblüte bei Neumond, Halbmondmarkt, Fest, seltene Ereignisse.

---

## 6. Items, Tränke und Magie

### Magie
- ✅ **Hexenkraft-Leiste + Tränke.** Kleine Zauber (Schnippen, Schweben, Angriffe) kosten Hexenkraft. Tränke sind starke Einmal-Effekte und füllen Hexenkraft nach.

### Die Waffe: Digitalis
- ✅ Der Zauberstab ist ein **Fingerhut** und heißt **Digitalis**.
- ✅ Er **wächst am Anfang des Spiels schon im Garten und wartet auf die Hexe.**
- ✅ Er **verwandelt sich in verschiedene Waffen**. Jede Form lässt sich upgraden und im Kampf einsetzen.
- ✅ Auch in der Overworld wird er benutzt: Erde wecken, Holz und Steine wegräumen und mehr.
- 💡 Formen:

| Form | Kampf | Overworld |
|---|---|---|
| Staff (Grundform) | Fernzauber | Erde wecken, Ausgießen |
| Sickle | schneller Nahkampf | Gras, Unkraut und Ranken schneiden |
| Thornwhip | Reichweite, Gegner heranziehen | Dinge greifen, über Lücken schwingen |
| Rootmaul | langsam, wuchtig | Steine und Holz zerschlagen |

- 💡 Neue Formen gibt es über Grimoire-Seiten oder beim Heilen eines Gebiets.
- 💡 Upgrades macht Gnarl (siehe NPCs).

### Trankarten
- ✅ Alle vier:
  - 🌱 **Ausgießen** auf Pflanzen und Boden;
  - 🧪 **Trinken** für Effekte auf sich selbst;
  - 💥 **Werfen** im Kampf;
  - 🎁 **für NPCs**, zum Tauschen.

### Bestehende Tränke (Namen englisch)

| ID | Name | Wirkung | Art |
|---|---|---|---|
| `potion_growth` | Growth Potion | Pflanzen im 3×3 sofort +1 Stufe | Ausgießen |
| `potion_will_o_wisp` | Will-o'-Wisp | kleines Licht folgt der Hexe für den Rest der Nacht | Trinken |
| `potion_moon_harvest` | Moon Harvest | Pflanzen im 3×3 sofort reif (Mondkelch ausgenommen) | Ausgießen |
| `potion_liquid_moonlight` | Liquid Moonlight | großes Licht, verborgene Items werden sichtbar | Trinken |
| `potion_endless_night` | Endless Night | die Nacht dauert länger | Trinken |
| `potion_sludge` | Witch's Muck (✅ 08.10.) | Dünger, eine Pflanze +1 Stufe | Ausgießen |

- ❓ Wurftränke für den Kampf und Tränke für NPCs sind neu und noch nicht ausgearbeitet.

### Kreuzungen im Garten (💡 09.10.)
- 💡 **Kreuzblumen** wie bei Animal Crossing: Stehen zwei passende Pflanzen nebeneinander, kann über Nacht auf einem freien Nachbarbeet eine **Kreuzung** entstehen (neue Farbe oder neue Sorte).
- 🔮 Passt zu „Was passiert wohl, wenn ich das mache?“ und zum Nachbar-Prinzip, das der Nachtschatten schon hat (er hemmt seine Nachbarn, Kreuzungen wären das positive Gegenstück).
- 🔮 Technisch: Prüfung beim Nachtwechsel im Autoload `Garden`, Kreuzungsregeln als Daten (Elternpaar → Ergebnis, Chance). Mondphasen könnten die Chance beeinflussen (z. B. Vollmond höher, über `Moon`).
- 🔮 Zeitpunkt: wenn es mehr Pflanzenarten gibt (siehe Rezepte entdecken, 🔮 mehr Zutaten später).

### Sammelobjekte im Wald (Grafiken fertig)

| Grafik | Name | Wofür | Wächst nach |
|---|---|---|---|
| Pilz | Ember Morel | Zutat (z. B. späterer Feuertrank) | nach 3 Nächten |
| Beerenstrauch | Dusk Berries | Tausch, Geschenk für NPCs | Strauch trägt alle 4 Nächte |
| Feder | Owl Feather | Grimoire-Opfer und Tausch, selten | zufällig, unter dem Eulenbaum |
| Mondmoos | Moonmoss | Zutat, nur bei Vollmond voll | jeden Vollmond |

- ✅ **Verdorbene Zutaten** von gereinigten Wesen sind wertvoll. Sie ergeben die stärksten Tränke.
- ✅ **Nachtschatten** findet man später auch im tiefen Wald und kann ihn zum eigenen Vorteil nutzen.
- ✅ Die **Truhe** im Unterschlupf ist das Lager.

---

## 7. Kampf

- ✅ Kämpfen soll **Spaß machen und ein großer Teil des Spiels** sein.
- ✅ **Echtzeit, Zielen per Maus** (wie Hades oder LoL): WASD zum Laufen, die Maus zum Zielen.
- ✅ Es gibt einen **Kampfmodus**, damit sich die Tasten nicht mit Ernten, Ausgießen und Trinken in die Quere kommen.
- 💡 Den Kampfmodus aktiviert man per Taste (Digitalis ziehen). Er schaltet sich auch automatisch ein, sobald ein Gegner angreift.
- 💡 Belegung im Kampfmodus:
  - Linksklick: Angriff der Form;
  - Rechtsklick: Spezialangriff;
  - Mausrad oder 1–4: Form wechseln;
  - eigene Tasten für Wurftränke;
  - Shift: Ausweichen. Das ist das Schweben als kurzer Dash.
- 💡 Die Hotbar zeigt im Kampfmodus Formen und Wurftränke.
- ✅ **Reinigen statt töten:** Die Blüte fällt von besiegten Wesen ab, das geheilte Tier läuft davon und lässt eine verdorbene Zutat zurück.
- ✅ **Gegner** sind von der Blüte befallene Wesen, Pflanzen, Käfer usw. Kreative Monster sind ausdrücklich erwünscht.
- ✅ **Blütenherz:** Jedes befallene Gebiet hat einen Boss. Ist er gereinigt, heilt das Gebiet.
- ✅ **Niederlage:** Die Nacht endet, man wacht im Garten auf, und **ein paar Dinge aus dem Inventar gehen verloren** (keine Ausrüstung).
- ✅ **Der Garten ist eine sichere Zone.**
- 💡 **Irrlicht greift mit an (09.10.):** Das Licht aus dem Will-o'-Wisp-Trank folgt der Hexe nicht nur, sondern macht im Kampf einen **Zusatzangriff** (z. B. kleiner Funke auf nahe Gegner).
  - 🔮 Ein schöner erster Schritt Richtung Begleiter im Kampf, bevor die Katze kommt. Erst sinnvoll, wenn der Kampf-Prototyp steht.

---

## 8. Dorf und NPCs

- ✅ Die Welt ist zweigeteilt:
  - ein **kleines Menschendorf** am Rand, in dem ein paar Menschen nachts wach sind;
  - das **Nachtvolk**, verteilt im Wald.
- ✅ Der **Halbmondmarkt** bringt beide zusammen.
- ✅ Die Menschen kennen nur Gerüchte über die Blüte, das Nachtvolk ist direkt betroffen. Je näher man der Blüte kommt, desto mehr hat sie mit den NPCs selbst zu tun.

| NPC | Wer | Funktion | Verbindung zur Blüte | Ab wann |
|---|---|---|---|---|
| Mother Moss | uraltes Moosweiblein | Samen tauschen, Herbarium | Ihre Waldverwandten sind befallen | Anfang |
| The Night Watchman | einziger Mensch, der nachts durchs Dorf geht | Gerüchte, kündigt seltene Ereignisse an | Sein Bruder ging vor 10 Jahren in den Wald und kam nie zurück | Anfang |
| Gnarl | Wichtel und Wurzelschnitzer | Upgrades für die Digitalis-Formen | Schnitzt aus befallenem Holz, und das macht ihn langsam krank | Anfang |
| The Owl | die Eule vom toten Baum | Grimoire-Hinweise, Lore | Sie kannte Vespera | Anfang |
| Ugo | Krötenhändler | seltene Ware, Ausrüstung | Handelt heimlich mit verdorbenen Zutaten | Anfang, bei Halbmond |
| The Apprentice | ehemalige Lehrling von Vespera | Story, große Enthüllungen | Sie weiß, was Vespera getan hat | ✅ später, durch eine Aktion (z. B. das erste Blütenherz gereinigt) |

- ✅ **Neue NPCs erscheinen nur durch eine Aktion des Spielers**, nie einfach nach Zeit.
- ✅ **Beziehungen:** zuerst nur Freundschaft (Herzen, Geschenke, persönliche Geschichten).
- 🔮 Romanzen vielleicht später als Update.
- 💡 Die Katze ist die erste Begleiterin, als Belohnung am Ende von Zyklus 1 oder 2.

---

## 9. Lore

### Die Hauptfigur
- ✅ Eine junge Hexe. **Der Spieler benennt sie zu Beginn selbst.**
- ✅ Sie folgt dem **Ruf des Fingerhuts (Digitalis)**, der im verlassenen Garten auf sie wartet.
- 💡 Sie war ohnehin auf der Suche nach einem Ort für sich.
- ❓ Warum Digitalis gerade sie gerufen hat, wird im Lauf der Geschichte enthüllt.
- ✅ **Schwarze Fingerspitzen:** ein Hexen-Ding, das **nichts** mit der Blüte zu tun hat. Jede Hexe hat sie, denn Magie färbt die Finger.
- 💡 Je mächtiger eine Hexe, desto dunkler die Finger. Bei der Spielfigur ist das allerdings kaum sichtbar, also eher Lore als Grafik.
- 💡 Vesperas Hände waren ganz schwarz.

### Die alte Hexe
- ✅ Name: **Vespera Hollow**. Der Name klingt nach einer einst mächtigen, nun hohlen und flüchtigen Gestalt.
- ✅ Die Dorfbewohner nennen sie später **Mother Blight**, weil sie ihr die Schuld am Verfall des Waldes geben.
- ✅ Sie lebt noch und ist geflohen.
- 💡 Sie kann später einmal auftauchen.
- ✅ **Backstory:** Sie wollte ihren **eigenen Verfall und ihr Altern aufhalten**. Ihr Unsterblichkeitszauber ging schief, und der unterdrückte Verfall wucherte als Bitterblüte.
- 💡 Der Unterschlupf, der hohle Uraltbaum, war ihr Zuhause. Das passt zum Namen „Hollow“.

### Die Bitterblüte
- ✅ Die **Hauptgegenspielerin**. Sie breitet sich wie ein Parasit aus und nimmt die Umgebung ein.
- ✅ Der **Wald ist ein Hauptteil** des Spiels. Man taucht immer tiefer ein, und der Wald verfault und stirbt durch die Blüte immer mehr ab.
- ✅ **Kein klassisches Ende.** Die Blüte wird nicht vernichtet, sondern verstanden und gebändigt: **Gleichgewicht statt Sieg**. Verfall gehört zur Natur, und Vesperas Fehler war, ihn bekämpfen zu wollen.
- ✅ Nach dem Story-Höhepunkt ist die Hexe die Hüterin des Waldes, und das Spiel geht weiter.
- ✅ Die Blüte flammt bei Neumond wieder auf und hat Ausläufer in neue Gebiete (Sumpf, Berge, Moor …). Das ist der Rahmen für spätere Updates.
- 💡 Nebel als Effekt in befallenen Gebieten.

### Wie erzählt wird
- ✅ Alle vier Wege:
  - Grimoire-Seiten (Vespera's Journal);
  - NPC-Gespräche;
  - Orte (verlassene Hütten, Inschriften, die befallenen Gebiete);
  - **Träume**: Nach bestimmten Seiten träumt man beim Schlafen eine Erinnerung von Vespera.

### Was der Spieler wann erfährt (💡 Vorschlag)
1. **Intro:** Vor zehn Jahren erwachte die Bitterblüte. Das Dorf hält sie in Schach, gerade so. Die alte Hexe floh, ihr Garten wartet.
2. **Akt 1:**
   - Der Nachtwächter erzählt Gerüchte.
   - Die Eule erzählt von Vespera.
   - Die ersten Seiten zeigen, wie mächtig Vespera war.
   - Man hört zum ersten Mal den Namen „Mother Blight“.
3. **Erstes Blütenherz gereinigt:** Die Apprentice taucht auf. Vespera fürchtete das Altern.
4. **Akt 2 und später:**
   - Träume zeigen den Zauber.
   - Die NPCs sind immer persönlicher betroffen.
   - Man erfährt, warum Digitalis die Hexe gerufen hat.
5. **Höhepunkt:** Gleichgewicht mit der Blüte. Vielleicht eine Begegnung mit Vespera.

---

## 10. Freischaltungen in Akt 1 (💡 Vorschlag)

| # | Freischaltung | Wann ungefähr | Wodurch |
|---|---|---|---|
| 1 | Digitalis (Staff), Garten, erste Grimoire-Seite | Nacht 1 | Ankunft, Wildgras wegräumen |
| 2 | Wald (Lichtung), erster Trank | Nacht 2 | erste Ernte, Kessel |
| 3 | Hexenring (noch ruhend) | Nacht 3 | Erkunden |
| 4 | erster Besuch und erster Tausch | Nacht 4–5 | NPC am Gartentor |
| 5 | Weg ins Dorf, Halbmondmarkt | Zyklus 1–2 | NPC-Hilfe |
| 6 | Katze | Ende Zyklus 1 oder 2 | Vollmond-Ereignis |
| 7 | Kampfmodus, Sickle, erster Befall | Zyklus 2 | Gnarl, befallene Waldecke |
| 8 | erstes Blütenherz gereinigt: Gebiet heilt, Hexenring als Schnellreise, Apprentice erscheint | Ende Akt 1 (ungefähr Zyklus 3) | Bosskampf |

---

## 11. Umsetzungsreihenfolge (Vorschlag)

Kleine, testbare Schritte. Das Spiel soll so früh wie möglich Spaß machen.

0. **Aufräumen:**
   - Laufenden Grafik-Einbau abschließen (`docs/auftrag_einbau_grafiken.md`).
   - Den Schacht im Intro ersetzen (siehe 12).
   - **Englisch einrichten**, am besten mit Godots Übersetzungssystem (`tr()` und eine CSV-Tabelle). Englisch wird die Hauptsprache, Deutsch kann zweite Sprache bleiben. Das sollte früh passieren, solange es noch wenige Texte gibt.
1. **Mondphasen-System:** 8 Nächte mit Phasen-Abfrage für andere Systeme. Zuerst Neumond, Halbmond und Vollmond.
2. **Kampf-Prototyp:** früh bauen, weil der Kampf ein großer Teil des Spiels ist und am riskantesten. Dazu gehören:
   - Kampfmodus, Digitalis Staff, Zielen mit der Maus, Dash;
   - **ein** befallener Käfer, Reinigen statt töten, Niederlage.

   Testen, ob es Spaß macht, bevor mehr darauf aufbaut.
3. **Sammelobjekte**, Nachwachsen und die Truhe als Lager.
4. **Erster NPC:** Dialog-UI (Grafiken liegen bereit), Tausch mit fester Liste und einem Gesuch.
5. **Grimoire und Disziplinen:** erst nach der eigenen Grimoire-Session. Ein datengetriebenes System.
6. **Erstes befallenes Gebiet** mit Blütenherz und Heilung, inklusive der 3 Dinge für geheilte Gebiete.
7. Katze, seltene Ereignisse, die restlichen NPCs, weitere Formen und Wurftränke.

---

## 12. Korrekturen an bestehenden Dateien

- ❌ **Schacht:** Das war ein Missverständnis. Gemeint war „in Schach halten“, also zurückhalten, nicht ein Schacht als Ort. Anzupassen:
  - `docs/design/design_entscheidungen_2026-10-07.md`, Abschnitt 9: Monster „im Schacht halten“ wird zu „in Schach halten“, und der Dungeon im Schacht entfällt.
  - `scripts/intro.gd`: „Vor zehn Jahren kamen sie aus dem Schacht.“ Vorschlag für den neuen Intro-Text auf Englisch, nach den Schriftregeln (keine Gedankenstriche, keine typografischen Anführungszeichen, keine Auslassungspunkte):
    > Ten years ago, the Bitterbloom woke in the deep woods.
    > The villagers keep it at bay. Barely.
    > The old witch they now call Mother Blight fled and never returned.
    > Her garden has been waiting ever since.
- Die Rezeptbuch-Herkunft „verstorbene Hexe“ im alten Word-Dokument ist überholt. Das Buch gehört Vespera Hollow, die noch lebt.
- Mit der Umstellung auf Englisch bekommen alle Item-, Trank- und UI-Texte englische Namen. Die IDs sind schon englisch.
- **Ideensammlung in `CLAUDE.md`**, die durch dieses Dokument überholt ist:
  - **Hexenpfade:** Die drei Zirkel, die man am Start wählt, werden zur Wahl bei Meilenstein-Stufen.
  - **Keine Schwerter oder Nahkampf als Hauptsystem:** Digitalis hat jetzt auch Nahkampf-Formen (Sickle, Rootmaul).
  - **Waffen verzaubern am Altar:** Die Upgrades macht jetzt Gnarl, und Crafting läuft über den Kessel.
  - **Reihenfolge in Abschnitt 9:** Es gilt die Umsetzungsreihenfolge hier.
  - **Vampir-Nachbar und Friedhof** sind nicht verworfen, aber vorerst nicht eingeplant.
- In `CLAUDE.md` unter „Neuere Entscheidungen“ diese Datei als neueste Quelle eintragen.

---

## 13. Offene Fragen (❓)

1. Mondeffekte für die Nächte 2–3 und 5–7 (oder bewusst keine).
2. Crafting über den Kessel: wie genau.
3. Inhalt und Design des Grimoire (eigene Session): Seitenaufbau, Opfer, Belohnungen.
4. Wurftränke und NPC-Tränke: Rezepte, Wirkungen.
5. Warum Digitalis gerade diese Hexe gerufen hat.
6. ~~Englische Namen für Hexenschlamm und die übrigen Pflanzen und UI-Texte.~~ ✅ 08.10.2026: Witch's Muck, Blood Rose, Ghost Fern (Spores), Lantern Berry, Mandrake, Moon Chalice, Nightshade, Wild Herb. Alle Texte stehen in `data/translations/texts.csv`.
7. Wildgras und Unkraut: Was bringt das Wegräumen, und wächst es nach?
8. Erste Monster-Designs und das erste Blütenherz.
9. Was genau die Katze kann (Disziplin Bonding).
