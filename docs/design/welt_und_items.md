# Weltgraph und Item-Kreislauf

Stand: 16.10.2026 · Basis: Branch `overworld` · Ergänzt `overworld_plan.md` (Schritt W4) und `game_design.md` (Abschnitte 3, 6, 8, 10)

Legende: ✅ vorhanden oder entschieden · 🔮 Vorschlag (nicht entschieden) · 🆕 neues Item oder neuer Ort · ❓ offen

**So ist das Dokument gedacht:** Abschnitt 9 ist eine Liste mit allen Vorschlägen. Du hakst ab oder streichst, der Rest des Dokuments erklärt, warum. Nichts davon wird gebaut, bevor du entschieden hast.

---

## 0. Kurzfassung

Das Problem vom 15.10.: Belohnungen ergeben keinen Sinn, solange unklar ist, wofür man sie braucht. Im Code bestätigt sich das: Dämmerbeeren haben keine einzige Verwendung, Eulenfeder und Mondmoos nur den Pfadwechsel, und die drei Trinktränke machen vor allem Licht oder eine längere Nacht, ohne dass die Welt darauf reagiert.

Der Vorschlag verbindet beides:

1. **Die Welt hat sichtbare Sperren.** Jede wird mit etwas aus dem Kreislauf geöffnet: einem Trank, einer Digitalis-Form, einem Tausch oder einer Mondphase.
2. **Jedes Item hat mindestens zwei Verwendungen.** Mindestens eine davon öffnet oder verbessert etwas, statt nur eine Zahl zu erhöhen.
3. **Jeder Ort hat eine eigene Ressource**, die nachwächst. So gibt es immer einen Grund, wiederzukommen (Regel aus `game_design.md`, Abschnitt 4).
4. **Gesuche am Anschlagbrett** geben jeder Nacht ein kleines Ziel: Das war dein Kritikpunkt vom 11.10.

Für Akt 1 reichen 9 Orte (5 gibt es schon), 8 Sperren, 6 neue Items und 2 neue Tränke. Technisch kommen dafür drei kleine Bausteine dazu (Abschnitt 8). Alles Weitere sind Daten.

---

## 1. Bestand (im Code geprüft)

### Items und wofür sie heute gut sind

| Item | Quelle heute | Verwendung heute |
|---|---|---|
| 6 Samen | Start (Alraune, Geisterfarn, Laternenbeere je 3), Ernte gibt Samen zurück, Herbalism-Stufen (Mondkelch, Blutrose, Nachtschatten) | Pflanzen |
| Alraune, Geisterfarn, Laternenbeere | Garten | Rezepte |
| Mondkelch | Garten, reift nur bei Vollmond | Flüssiges Mondlicht, Mondernte |
| Nachtschatten | Garten (Samen erst über Herbalism) | Irrlicht, Flüssiges Mondlicht, Ewige Nacht |
| Blutrose | Garten | nur Ewige Nacht |
| Wildkraut | Unkraut ausreißen (Garten, Wald) | nur Dornennebel |
| Glutmorchel | Wald, wächst nach 3 Nächten nach | nur Glutbombe |
| Dämmerbeeren | Wald, Strauch trägt alle paar Nächte | **nichts** (nur Herbarium-Eintrag) |
| Eulenfeder | Wald, unter dem Eulenbaum, selten | nur Pfadwechsel (3 Stück) |
| Mondmoos | Wald, voll nur bei Vollmond | nur Pfadwechsel (2 Stück) |
| Bitterblütenblatt | Käfer reinigen | Glutbombe, Dornennebel |

### Tränke

| Trank | Rezept heute | Wirkung heute | Reagiert die Welt darauf? |
|---|---|---|---|
| Wachstum | Alraune + Geisterfarn | Garten 3×3 +1 Stufe | nur Beete |
| Mondernte | Alraune + Geisterfarn + Mondkelch | Garten 3×3 reif | nur Beete |
| Hexenschlamm | Fehlschlag | 1 Pflanze +1 | nur Beete |
| Irrlicht | Laternenbeere + Nachtschatten | Licht folgt der Hexe | nein |
| Flüssiges Mondlicht | Laternenbeere + Nachtschatten + Mondkelch | großes Licht | nein (verborgene Items sind geplant, nicht gebaut) |
| Ewige Nacht | Blutrose + Nachtschatten + Alraune | Nacht dauert länger | ja, indirekt |
| Heiltrank | Geisterfarn + Laternenbeere | +4 Leben | Kampf |
| Glutbombe | Glutmorchel + Bitterblütenblatt | Wurf, Schaden | Kampf |
| Dornennebel | Wildkraut + Bitterblütenblatt | Wurf, verlangsamt | Kampf |

### Was in Daten schon da ist, aber keinen Weg ins Spiel hat
- Kessel-Kapazität (Datenwert, Standard 3), Truhe 16 → 24 Plätze.
- Grimoire-Belohnungen `LOCATION` und `DIGITALIS_FORM`, Gerüchte (`hint_ingredient`) sind angebunden.
- Formen Thornwhip und Rootmaul stehen im Design, gebaut sind Stab und Sichel.

### Orte
Unterschlupf, Garten, Seewald, tiefer Wald, Dorf (alle flach) und der Höhen-Test. Sammeln geht heute **nur im tiefen Wald** (und Unkraut im Garten). Seewald und Dorf haben nichts zu holen.

---

## 2. Regeln für den Kreislauf (🔮)

1. **Zwei Verwendungen pro Item**, davon mindestens eine, die etwas Neues möglich macht (Sperre, Tausch, Upgrade, Rezept), nicht nur „mehr“.
2. **Eine Ressource pro Ort**, die nachwächst. Wer sie will, muss wiederkommen.
3. **Tränke sind die Schlüssel der Welt.** Jede Trinkwirkung hat mindestens eine Stelle in der Welt, an der sie etwas öffnet. Wurf- und Gießtränke wirken auch außerhalb von Kampf und Garten.
4. **Seltenheit über den Mond statt über Zufall.** Was selten ist, hängt an einer Mondphase. Dann kann man planen („in drei Nächten ist Vollmond, dann gehe ich zur Insel“).
5. **Drei Wertstufen:**
   - **Alltag:** Garten, Wildkraut. Für Gesuche, einfache Tränke, Tausch.
   - **Besonders:** Wald, Mond, Orte. Für Sperren und Upgrades.
   - **Blüte:** vom Reinigen. Für die stärksten Tränke und für Gnarl.
6. **Rezepte folgen Eigenschaften.** Jede Zutat hat eine Eigenschaft, Rezepte kombinieren sie. Dann sind Rezepte logisch, und man kann sie erraten (passt zu „Was passiert, wenn ich das mache?“). Die heutigen Rezepte passen fast alle schon dazu:

| Eigenschaft | Zutaten |
|---|---|
| Licht | Laternenbeere |
| Wachstum | Alraune |
| Heilung, Geist | Geisterfarn |
| Mond | Mondkelch (stark), Mondmoos (schwach), 🆕 Mondwasser |
| Schatten | Nachtschatten |
| Dämmerung, Verbergen | Dämmerbeeren |
| Blut, Zeit | Blutrose |
| Feuer | Glutmorchel |
| Dorn, Erde | Wildkraut |
| Fokus | 🆕 Höhlenkristall |
| Blüte (Verstärker, gefährlich) | Bitterblütenblatt, 🆕 Blütenknospe |

---

## 3. Weltgraph (🔮)

Lage nach der KI-Karte. Höhe: 0 tief, 1 normal, 2 hoch (wie im Höhen-Test).

```text
 Höhe 2   [Ruinen]=====Wurzelbrücke S3=====[Uraltbaum + Garten]                 [Friedhof]
          (Akt 2)                            │ Treppe (offen)                      ║ Nordpfad S6
                                             │                                     ║
 Höhe 1        Wasserfall ──Höhle S2──► [Seewald, Hütte]──Waldweg──────────────[Dorf]══Schluchtbrücke S7══[Berge]
                            (dunkel)     │  ╲ Insel S1 (See, Höhe 0)    └─Hexenpforte─┘                  (Akt 2)
                                         │   ╲
 Höhe 0   [Sumpf] ◄═══Ranken-Treppe S4═══╯    │ Süd
          (Ugo)                               │
 Höhe 1                                [Tiefer Wald: Hexenring, Befall]══Blütennebel S5══[Turmruine: Blütenherz 1]
                                              ║
 Höhe 0                                [Moor]  S8, erst nach Blütenherz 1 (Akt 2)
```

| Ort | Höhe | Szene | Eigene Ressource | Wer lebt dort | Ab wann |
|---|---|---|---|---|---|
| Unterschlupf | innen | ✅ `shelter.tscn` | – | – | Nacht 1 |
| Garten | 2 (Plateau, Stützmauer nach Süden) | ✅ `garden.tscn`, bekommt Höhe | Gartenpflanzen | – | Nacht 1 |
| Seewald | 1, See und Insel 0 | ✅ `lakewood.tscn`, bekommt Höhe | 🆕 Weidenrinde (Trauerweiden), 🆕 Mondwasser (am See, nur Vollmond) | 🔮 Mother Moss in der Uferhütte | Nacht 1 |
| Insel im See | 0 | Teil des Seewalds | wilde Mondkelch-Samen, eine Grimoire-Seite | – | erster Vollmond |
| Wasserfall-Höhle | innen, dunkel | 🆕 klein | 🆕 Höhlenkristall | – | mit Irrlicht |
| Dorf | 1 | ✅ `village.tscn` | Gesuche, Kräutergärtchen (Wildkraut) | ✅ Nachtwächter, 🔮 Gnarl (Werkstatt) | Nacht 1 |
| Tiefer Wald | 1 | ✅ `forest.tscn` | Glutmorchel, Dämmerbeeren, Eulenfeder, Mondmoos, Blüten-Zutaten | ✅ Eule | Nacht 1 |
| Sumpf | 0 | 🆕 | 🆕 Sumpflicht (Irrlicht-Pilz), wilder Nachtschatten | 🔮 Ugo (Halbmond) | Zyklus 1–2 |
| Turmruine | 1 | 🆕 | Blüten-Zutaten (stark) | Blütenherz 1 | Ende Akt 1 |
| Friedhof | 1 | 🆕 (Akt 2) | 🆕 Grabmoos | ❓ | Akt 2 |
| Ruinen, Berge, Moor | 2 / 2 / 0 | 🆕 (Akt 2) | Seiten / Sternensplitter / ❓ | ❓ | Akt 2 |

**Warum diese Reihenfolge:** Der Seewald wird vom leeren Übergang zum zweiten Zuhause (Hütte, Insel, Höhle). Das Dorf bleibt Hub für Tausch und Gesuche. Der Sumpf ist das erste „neue“ Gebiet, das man sich selbst erarbeitet. Der tiefe Wald führt zum Akt-1-Finale.

---

## 4. Sperren (🔮)

Jede Sperre sieht man, bevor man sie öffnen kann. Geöffnet bleibt geöffnet (Flag in `WorldState`), außer sie hängt am Mond.

| # | Sperre | Ort | Was man sieht | Lösung | Was sie öffnet | Akt / Zeit |
|---|---|---|---|---|---|---|
| ✅ S0 | Hexenpforte | Seewald ↔ Dorf | verriegeltes Tor | Gespräch mit dem Nachtwächter | Abkürzung | gebaut |
| S1 | **Mondsteg** | Seewald, See | Die Mondspiegelung zeigt schon auf die Insel | **bei Vollmond** von selbst begehbar, sonst nach **Flüssigem Mondlicht** | Insel: wilde Mondkelch-Samen, Grimoire-Seite | Akt 1, erster Vollmond |
| S2 | **Dunkle Höhle** hinter dem Wasserfall | Seewald | Spalt hinter dem Wasser, man hört Tropfen | **Irrlicht** getrunken: Ohne Licht kehrt die Hexe um („Zu dunkel“) | Höhlenkristall (für Upgrades), Lore | Akt 1, Zyklus 1 |
| S3 | **Verdorrte Wurzelbrücke** | Garten ↔ Ruinen, über den Bach | Wurzeln hängen schlaff über die Schlucht | **Wachstumstrank** darauf gießen: Die Brücke wächst zusammen | Ruinen (Akt 2) | später |
| S4 | **Ranken-Treppe** | Seewald ↔ Sumpf | Treppe nach unten, von ruhigen Bitterblüten-Ranken zugewachsen | **Glutbombe** werfen (verbrennt sie) oder **Sichel II** | Sumpf, Ugo | Akt 1, Zyklus 1–2 |
| S5 | **Blütennebel** | tiefer Wald ↔ Turmruine | Magenta-Nebel, Knospen glimmen durch | 🆕 **Reinigungsnebel** (Wurftrank) lichtet ihn für die Nacht. Erst nach dem Blütenherz bleibt er weg | Turmruine, Blütenherz 1 | Ende Akt 1 |
| S6 | **Nordpfad zum Friedhof** | Dorf | Tor mit Kette, Laterne dahinter | Nachtwächter gibt den Schlüssel, wenn man ihm etwas vom Bruder bringt (Fund im tiefen Wald) | Friedhof | Akt 2 |
| S7 | **Eingestürzte Schluchtbrücke** | Dorf ↔ Berge | halbe Brücke, Seile hängen | **Gesuch-Kette** am Anschlagbrett: Material bringen, Gnarl baut | Berge | Akt 2 |
| S8 | **Moor** | tiefer Wald, Süden | toter Wald im Nebel | Blütenherz 1 gereinigt | Moor, Apprentice | Akt 2 |

**Warum genau diese:** S1 nutzt den Mondzyklus und einen Trank, der heute nur Licht macht. S2 gibt dem Irrlicht einen Zweck. S3 nutzt einen Gießtrank außerhalb des Gartens. S4 verbindet Kampf (Glutbombe) mit Erkunden. S5 ist das Akt-1-Ziel und braucht die stärksten Zutaten. S6 und S7 hängen an NPCs.

---

## 5. Items im Kreislauf (🔮)

Neue Verwendungen fett, neue Items mit 🆕.

| Item | Quellen | Verwendungen |
|---|---|---|
| Samen (6) | Start, Ernte, Herbalism, **Mother Moss (Tausch)**, **Insel (Mondkelch)** | Pflanzen, **Gesuche** |
| Alraune | Garten | Wachstum, Mondernte, Ewige Nacht, **Gesuche** |
| Geisterfarn | Garten | Heilung, Wachstum, Mondernte, **Reinigungsnebel** |
| Laternenbeere | Garten | Heiltrank, Irrlicht, Mondlicht, **Gesuche** (Dorf braucht Licht) |
| Mondkelch | Garten (Vollmond), **Insel** | Mondlicht, Mondernte, **Opfer am Lesepult** |
| Nachtschatten | Garten (spät), **Sumpf (wild)** | Ewige Nacht, **Schatten-Tränke in Akt 2** |
| Blutrose | Garten | Ewige Nacht, **Opfer** (Blut für befallene Seiten), **Geschenk** (Freundschaft) |
| Wildkraut | Unkraut, **Dorf-Kräutergärtchen** | Dornennebel, **Gesuche** (häufigste Bitte) |
| Glutmorchel | tiefer Wald | Glutbombe, **Gnarl** (Holz härten) |
| Dämmerbeeren | tiefer Wald | **Irrlicht (neues Rezept, siehe unten)**, **🆕 Dämmertrank**, **Lieblingsgeschenk des Nachtvolks**, **Tausch bei Mother Moss** |
| Eulenfeder | tiefer Wald, selten | Pfadwechsel, **Opfer am Lesepult**, **Thornwhip-Upgrade (Akt 2)** |
| Mondmoos | tiefer Wald, Vollmond | Pfadwechsel, **Flüssiges Mondlicht (neues Rezept)**, **Opfer mit Mondbedingung** |
| Bitterblütenblatt | Käfer reinigen | Glutbombe, Dornennebel, **Gnarl** |
| 🆕 Blütenknospe | stärkere Wesen, Turmruine | **Reinigungsnebel**, **Gnarl (Stufe II)** |
| 🆕 Weidenrinde | Seewald, Trauerweiden, alle 3 Nächte | **Heiltrank II** (stärker), **Gnarl** (Griff), **Gesuche** |
| 🆕 Mondwasser | Seewald, am See, nur Vollmond | **Reinigungsnebel**, **Opfer mit Mondbedingung** |
| 🆕 Höhlenkristall | Wasserfall-Höhle, wächst langsam nach | **Gnarl: Upgrades**, **Kessel-Upgrade** |
| 🆕 Sumpflicht | Sumpf | **Irrlicht II** (Licht greift mit an, 💡 vom 09.10.), **Tausch bei Ugo** |

### Rezepte (🔮 Änderungen)

| Trank | Heute | Vorschlag | Warum |
|---|---|---|---|
| Irrlicht | Laternenbeere + Nachtschatten | **Laternenbeere + Dämmerbeeren** | Nachtschatten ist seit 11.10. Lategame, das Irrlicht soll aber früh die Höhle öffnen. Dämmerbeeren bekommen ihre erste Verwendung |
| Flüssiges Mondlicht | Laternenbeere + Nachtschatten + Mondkelch | **Laternenbeere + Mondmoos + Mondkelch** | Mond-Trank aus Mond-Zutaten, öffnet den Mondsteg ohne Nachtschatten |
| 🆕 Reinigungsnebel (Wurf) | – | **Geisterfarn + Mondwasser + Blütenknospe** | Kandidat aus `game_design.md` 7. Lichtet Blütennebel, im Kampf: Gegner 2 s wehrlos |
| 🆕 Dämmertrank (Trinken) | – | **Dämmerbeeren + Nachtschatten** | Gegner bemerken die Hexe erst aus halber Entfernung. Schleichen statt Kämpfen, passt zu „mysteriös“ |
| Heiltrank II | – | **Geisterfarn + Laternenbeere + Weidenrinde** | Dreier-Rezept mit stärkerer Wirkung (Regel vom 07.10.) |

Die übrigen Rezepte bleiben. Die Wurftränke bleiben vorläufig, wie im Kampf-Dokument vermerkt.

### Was die Trinktränke in der Welt öffnen

| Trank | Kampf / Garten | Welt |
|---|---|---|
| Irrlicht | 💡 Zusatzangriff (später) | **Höhle S2**, dunkle Ecken in Sumpf und Ruinen |
| Flüssiges Mondlicht | – | **Mondsteg S1 an jeder Nacht**, macht Verborgenes sichtbar (Runen, versteckte Seiten, Mother Moss' Hütte?) |
| Ewige Nacht | – | **lange Ausflüge** (Sumpf, später Berge und Moor liegen weit weg) |
| Dämmertrank 🆕 | Gegner bemerken dich spät | an Blüten-Gebieten vorbeischleichen |
| Wachstum | Garten | **Wurzelbrücke S3**, später mehr Wurzeln und Ranken |
| Glutbombe | Schaden | **Ranken S4** |
| Reinigungsnebel 🆕 | Gegner wehrlos | **Blütennebel S5** |

---

## 6. Upgrades (🔮)

**Gnarl** sitzt anfangs im tiefen Wald und zieht in die leere Werkstatt im Dorf, sobald man ihm hilft. Laut Design schnitzt er aus befallenem Holz, und das macht ihn langsam krank. Deshalb will er Blüten-Zutaten als Material, und das erste Gesuch an ihn könnte ein Heiltrank sein. Jedes Upgrade bringt eine neue Möglichkeit, nicht nur mehr Schaden:

| Upgrade | Material | Neue Möglichkeit |
|---|---|---|
| Stab II | Höhlenkristall ×2 + Bitterblütenblatt ×3 | starker Zauber durchschlägt einen Gegner |
| Sichel II | Glutmorchel ×3 + Weidenrinde ×2 | schneidet ruhige Bitterblüten-Ranken (zweiter Weg durch S4) |
| Thornwhip (neue Form, Akt 2) | Grimoire-Seite + Eulenfeder ×3 | Gegner heranziehen, über Lücken schwingen |
| Kessel 4 Plätze | Höhlenkristall ×3 + Weidenrinde | Vierer-Rezepte möglich (Akt 2) |
| Truhe 24 Plätze | Gesuch-Kette im Dorf (Zimmermann) | mehr Lager |

Die Sichel ist heute zum Testen von Anfang an da (`START_FORMS`). Laut Design kommt sie über Gnarl. Vorschlag: Sie bleibt von Anfang an da (sie ist das Werkzeug für Gras und Unkraut), Gnarl macht nur die Upgrades.

---

## 7. Tausch und Gesuche (🔮)

Entschieden ist Tausch statt Geld mit Fokus auf verteilten NPCs mit wechselnden Gesuchen. Vorschlag für Akt 1:

**Anschlagbrett im Dorf: jede Nacht ein kleines Ziel.**
- Jede Nacht hängen 1–3 Zettel. Ein Zettel ist ein Gesuch: „Bringt mir 3 Laternenbeeren für die Kapelle“, Belohnung zum Beispiel Samen, Kerzen für den Unterschlupf oder ein Gerücht.
- Die Dorfbewohner sieht man nicht (sie schlafen). Sie schreiben Zettel. Das passt dazu, dass nachts nur wenige wach sind, und braucht keine Figuren-Grafiken.
- Zettel bleiben 3 Nächte hängen, dann kommt ein neuer. Manche kommen nur bei bestimmten Mondphasen („vor dem Vollmond …“).
- Ketten: Drei erfüllte Gesuche eines Bewohners schalten etwas frei (Truhe, Schluchtbrücke).

**NPCs mit Tausch:**

| NPC | Wo | Gibt | Will |
|---|---|---|---|
| Mother Moss | Hütte am Seewald-Ufer | Samen (auch seltene), Herbarium-Hinweise | Dämmerbeeren, Weidenrinde, Wildkraut |
| Gnarl | Werkstatt im Dorf | Upgrades | Kristall, Blüten-Zutaten, Morcheln |
| Ugo | Sumpf, beim Halbmondmarkt im Dorf | seltene Zutaten, Rezept-Hinweise | Sumpflicht, Hexenschlamm (er mag das Zeug), Tränke |
| Nachtwächter ✅ | Dorf | Gerüchte, Schlüssel zum Friedhof (Akt 2) | – |

Halbmondmarkt (✅ entschieden): Ugo und ein Wanderer kommen bei Halbmond auf den gemauerten Markt im Dorf, mit fester Tauschliste.

---

## 8. Technik (🔮, klein gehalten)

Fast alles sind neue Daten. Neu als Code wären nur drei Bausteine:

1. **`Gate`** (`scripts/world/gate.gd`): ein Hindernis mit Kollision und `interaction_prompt()`. Es öffnet sich, wenn eine Bedingung erfüllt ist, und setzt dann ein Flag. Bedingungen als Exporte:
   - `required_flag` (wie heute bei `Exit`);
   - `moon_phase` (offen nur bei Vollmond);
   - `active_effect` (offen, solange Irrlicht oder Mondlicht wirkt);
   - `pour_item` / `throw_item` (öffnet sich, wenn dieser Trank darauf gegossen oder geworfen wird).
   Ein gesperrter `Exit` (S2, S4) ist dann ein `Exit` plus ein `Gate` davor.
2. **Abfrage der Trankwirkung:** `PotionEffects.is_active("wisp")`. Die Wirkungen gibt es schon, sie sind nur nicht von außen abfragbar. Wurf- und Gießtränke melden sich bei Objekten in der Gruppe `potion_target` (eine Methode `on_potion(item)`), wie Gegner heute `take_hit` haben.
3. **Gesuche:** Daten `RequestData` (`data/requests/*.tres`: wer, was, wie viele, Belohnung als vorhandene `RewardData`, Mondbedingung) und ein Autoload `Requests` (welche Zettel hängen, im Spielstand gespeichert). Das Anschlagbrett zeigt sie in der vorhandenen Dialogbox, Abgeben über E. Die Belohnungstypen gibt es schon im Grimoire (`ITEM`, `RECIPE`, `LOCATION` …).

Tausch bei NPCs braucht danach nur noch die Antwort-Auswahl in der Dialogbox (Grafiken liegen bereit) und `TradeOffer`-Daten. Upgrades bei Gnarl sind Tausch mit der Belohnung „Form verbessern“ (neuer `RewardData`-Typ `UPGRADE`).

Neue Orte entstehen über den World-Builder als Graybox, neue Items als Datendateien mit Platzhalter-Icon. Grafiken kommen später von dir.

---

## 9. Deine Entscheidungen

✅ **16.10.2026: Robin hat dem Vorschlag als Ganzes zugestimmt** (Regeln, Weltgraph, Sperren, Items und Rezepte, Upgrades, Gesuche, Reihenfolge). Die Liste unten bleibt als Übersicht stehen. Wenn sich beim Bauen oder Testen etwas nicht gut anfühlt, wird der einzelne Punkt hier geändert.

**Regeln**
- [ ] R1 Zwei Verwendungen pro Item, mindestens eine öffnet etwas Neues
- [ ] R2 Eine nachwachsende Ressource pro Ort
- [ ] R3 Tränke öffnen Dinge in der Welt
- [ ] R4 Seltenheit über den Mond statt über Zufall
- [ ] R5 Rezepte folgen Eigenschaften (Tabelle in Abschnitt 2)

**Welt**
- [ ] W-a Weltgraph wie in Abschnitt 3 (Lage nach der KI-Karte)
- [ ] W-b Akt 1 = Garten, Seewald mit Insel und Höhle, Dorf, tiefer Wald, Sumpf, Turmruine. Friedhof, Ruinen, Berge, Moor erst in Akt 2
- [ ] W-c Mother Moss wohnt am Seewald-Ufer (macht den Seewald lebendig, war am 12.10. offen)

**Sperren** (einzeln)
- [ ] S1 Mondsteg (Vollmond oder Flüssiges Mondlicht)
- [ ] S2 Dunkle Höhle (Irrlicht)
- [ ] S3 Wurzelbrücke (Wachstumstrank, Akt 2)
- [ ] S4 Ranken-Treppe (Glutbombe oder Sichel II)
- [ ] S5 Blütennebel (Reinigungsnebel)
- [ ] S6 Friedhofsschlüssel vom Nachtwächter (Akt 2)
- [ ] S7 Schluchtbrücke über Gesuche (Akt 2)

**Items und Rezepte**
- [ ] I-a Neue Items: Weidenrinde, Mondwasser, Höhlenkristall, Sumpflicht, Blütenknospe (Grabmoos erst Akt 2)
- [ ] I-b Irrlicht neu: Laternenbeere + Dämmerbeeren
- [ ] I-c Flüssiges Mondlicht neu: Laternenbeere + Mondmoos + Mondkelch
- [ ] I-d Neuer Wurftrank Reinigungsnebel
- [ ] I-e Neuer Trinktrank Dämmertrank (Schleichen)
- [ ] I-f Heiltrank II mit Weidenrinde

**Upgrades, Tausch, Gesuche**
- [ ] U-a Gnarl in der Dorf-Werkstatt, Upgrades bringen neue Möglichkeiten (Tabelle Abschnitt 6)
- [ ] U-b Sichel bleibt von Anfang an da, Gnarl macht nur Upgrades
- [ ] G-a Anschlagbrett mit Zetteln als tägliches Ziel (unsichtbare Dorfbewohner)
- [ ] G-b Ugo mag Hexenschlamm

**Reihenfolge der Umsetzung** (Vorschlag, jeweils einzeln spielbar, alles Graybox)
1. Bausteine `Gate` und Trankwirkung abfragbar, dazu S2 (Höhle) als erster Test
2. Gesuche am Anschlagbrett (gibt sofort das Ziel pro Nacht)
3. Rezept-Änderungen und neue Items als Daten
4. Seewald mit Höhe neu bauen (Builder), Insel mit S1, Hütte für Mother Moss
5. Mother Moss mit Tausch (Antwort-Auswahl in der Dialogbox)
6. Sumpf mit S4 und Ugo, Halbmondmarkt
7. Gnarl und Upgrades
8. Turmruine, S5, Blütenherz 1

Offen und bewusst nicht hier: Mondeffekte für die Nächte 2–3 und 5–7, Crafting über den Kessel, die Katze, Freundschaften.

---

## 10. Umsetzungsstand

| Schritt | Stand | Was |
|---|---|---|
| 1 | ✅ 16.10. | `Gate` (`scripts/world/gate.gd`), `PotionEffects.is_active()`, Würfe melden sich bei der Gruppe `potion_target`, Gießen per E am Gate, `Level.darkness`. **S2 als Test:** Spalt hinter dem Wasserfall im Höhen-Test, offen nur mit Irrlicht oder Flüssigem Mondlicht, sonst „Zu dunkel“. Dahinter `scenes/world/waterfall_cave.tscn` (aus Bauplan, drinnen, dunkel) mit 3 Höhlenkristallen, die nach 4 Nächten nachwachsen. Neues Item `cave_crystal` (Platzhalter-Grafik) |
| 2–8 | offen | – |

Tests (headless, Prüfskripte nicht im Repo): Gate zu ohne Licht mit Meldung, E zeigt Hinweis, offen mit Irrlicht und mit Mondlicht, wieder zu ohne Licht, Höhle betreten und verlassen, Höhle dunkel und sonnensicher, Kristalle wachsen, pflücken und nachwachsen, Glutbombe öffnet ein Wurf-Gate dauerhaft, Wachstumstrank öffnet ein Gieß-Gate, falscher Trank tut nichts: 25 / 25. Höhen-Test weiter 24 / 24, alle 323 Szenen, Scripts und Ressourcen laden.

Noch nicht: Der Eingang liegt im Höhen-Test statt im Seewald (kommt mit Schritt 4). Der Kristall hat noch keine Verwendung (kommt mit Gnarl in Schritt 7) und keinen Herbarium-Eintrag.
