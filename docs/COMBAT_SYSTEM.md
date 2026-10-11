# Kampfsystem

Stand: 11.10.2026, Branch `combat-overhaul` (Schritte K1 bis K6).
Design-Grundlage: `docs/design/game_design.md`, Abschnitt 7 (Entscheidungen vom 10.10.).

Kurz: Mit **F** zieht die Hexe Digitalis. Linksklick ist ein schneller leichter Angriff, Rechtsklick ein langsamerer starker mit kurzem Ausholen. Digitalis hat zwei Formen, den **Stab** (Fernkampf) und die **Sichel** (Nahkampf), gewechselt wird sofort mit 1, 2 oder dem Mausrad. **Shift** weicht aus. **Q** benutzt den gewählten Kampftrank, **R** wechselt die Sorte. Gegner kündigen jeden Angriff mit einer Spur am Boden an.

---

## 1. Architektur

Alles Kampfliche hängt als eigene kleine Nodes unter dem Player, damit `player.gd` klein bleibt. Werte stehen in Daten-Dateien, nicht im Code.

```text
Player (player.gd)          Laufen, Blickrichtung, Tempo-Bremsen (set_speed_modifier), Dash-Bewegung
├─ Combat (combat.gd)       Kampfmodus, Formen, Angriffsablauf (READY/WINDUP), Puffer, Ausweichen
│   ├─ Digitalis            zeigt Stab oder Sichel neben der Hexe, Ausholen-Glühen
│   └─ Reticle              Fadenkreuz an der Maus, Ring beim Ausholen
├─ CombatPotions            Trank-Schnellzugriff (Q/R), Zielkreis, Wurf, Dornennebel
├─ Vitals (vitals.gd)       Leben, Hexenkraft, Unverwundbarkeit; Signale damaged/healed/died
├─ VitalsFeedback           Treffer: Aufblitzen, Wackeln, Blinken; Heilen: Funken
├─ PotionEffects            Trinken außerhalb des Kampfs (Q/Rechtsklick), auch Heiltrank
└─ SunExposure              Sonnenschaden ab 6 Uhr (nicht Teil des Kampfs, nutzt aber Vitals)

Welt
├─ Spell (spell.gd)         Geschoss des Stabs, platzt optional im Kreis
├─ Slash (slash.gd)         Hieb der Sichel, trifft geometrisch (Abstand + Winkel), schneidet Wildgras
├─ BlightBeetle             Gegner (Gruppe "blighted"), Telegraph-Spur (ChargeLane)
└─ WildGrowth               lässt Käfer wachsen, bei Neumond-Flut zusätzliche nur für die Nacht

UI
├─ CombatBar (combat_bar.gd)  ersetzt im Kampf die Hotbar-Plätze: Formen + Trank-Platz
├─ VitalsBar                  Leben und Hexenkraft oben links
└─ ControlsMenu               Steuerungsseite, rechte Spalte "Im Kampf"
```

**Daten statt Code**

| Was | Wo | Klasse |
|---|---|---|
| Digitalis-Formen | `data/digitalis/staff.tres`, `sickle.tres` | `DigitalisForm` (id, Name, Icon, `light`, `heavy`) |
| Angriffe | in den Form-Dateien als Unter-Ressourcen | `AttackData` (Art BOLT/SLASH, Schaden, Kosten, Abklingzeit, Ausholen, Rückstoß, Farbe, Klang, Reichweite …) |
| Kampftränke | `data/items/potion_mending.tres`, `potion_ember_bomb.tres`, `potion_thorn_mist.tres` | `ItemData` (Gruppen „Drink“ und „Throw“) |
| Rezepte | `data/recipes/potion_*.tres` | `RecipeData` |
| Gegner-Varianten | `scenes/world/blight_beetle.tscn`, `blight_beetle_horned.tscn` | `BlightBeetle` (Exporte) |
| Bekannte Formen | Grimoire (gespeichert unter `forms`) | `Grimoire.known_forms()`, `learn_form()`, Belohnung `DIGITALIS_FORM` |

**Eine neue Form** ist eine neue `.tres` in `data/digitalis/` plus `Grimoire.learn_form("id")` (oder eine Grimoire-Belohnung). Braucht sie eine neue Angriffsart (z. B. eine Peitsche, die heranzieht), kommt in `AttackData.Kind` ein Wert dazu und in `Combat._fire()` ein Zweig.

**Ein neuer Gegner** braucht nur: Gruppe `blighted`, `take_hit(damage, knockback, stagger := true)`, optional `apply_slow(factor, seconds)`, und ein Signal `collected`, wenn er über `WildGrowth` wächst. Angriffe sollen sich sichtbar ankündigen (siehe Abschnitt 4).

**Ablauf eines Angriffs** (`Combat`): `request_attack(heavy)` → zu wenig Hexenkraft: Meldung, sonst bei `windup > 0` Zustand `WINDUP` (Hexe läuft langsamer, Digitalis glüht, Ring an der Maus schließt sich) → `_fire()` zieht Hexenkraft ab, startet die Abklingzeit, spielt den Klang aus den Daten und erzeugt `Spell` oder `Slash`. Ein Klick kurz vor Ende der Abklingzeit wird 0,15 s gepuffert. Gedrückt gehaltene linke Maustaste wiederholt den leichten Angriff.

---

## 2. Mechaniken

### Stab (Fernkampf)

| | Leicht (Linksklick) | Stark (Rechtsklick) |
|---|---|---|
| Schaden | 1 | 2, im Kreis (34 px) |
| Hexenkraft | 0,5 | 2,5 |
| Abklingzeit | 0,28 s | 0,7 s |
| Ausholen | – | 0,32 s, Tempo 45 % |
| Geschoss | 240 px/s, 190 px weit | 170 px/s, 150 px weit |

### Sichel (Nahkampf)

| | Leicht | Stark |
|---|---|---|
| Schaden | 1 | 2 |
| Hexenkraft | 0,4 | 2,0 |
| Abklingzeit | 0,26 s | 0,6 s |
| Ausholen | – | 0,26 s, Tempo 50 % |
| Bogen | 30 px, 110° | 44 px, 200° |
| Rückstoß | 40 | 140 |

Die Sichel schneidet im Kampf Wildgras und Unkraut, das im Bogen steht (Ertrag wie beim Ernten). Leichte Hiebe schwingen abwechselnd von links und rechts.

### Formwechsel
Sofort, ohne Wartezeit (Kombos erlaubt), mit 1–4 oder dem Mausrad. Ein laufendes Ausholen verfällt dabei. Kurzer Funke an der Spitze.

### Ausweichen (Shift)
In Laufrichtung, im Stehen zur Maus. 420 px/s für 0,14 s, danach 0,25 s unverwundbar, kostet 1 Hexenkraft, 0,5 s Abklingzeit. Bricht ein Ausholen ab (Ausweichen geht immer vor). Magenta-Nachbilder.

### Hexenkraft und Leben
Alles, was Zauberei ist, kostet Hexenkraft (8 + Hexenstärke/2, erholt sich mit 0,5/s). Leben (10) erholt sich im Kampf nicht von selbst, nur über Tränke oder Schlafen. Getroffen: 1 Schaden, 0,8 s unverwundbar, kurzer Rückstoß, Digitalis wird automatisch gezogen.

### Kampftränke (Q / R)
Kampftränke sind Items mit `use = THROW` oder Trinktränke mit `heal > 0`. Welche es gibt, ergibt sich aus der Tasche, ohne eigenes Menü.

| Trank | Art | Wirkung | Vorläufiges Rezept |
|---|---|---|---|
| Heiltrank | trinken | +4 Leben, +5 Hexenkraft; die Hexe steht kurz still | Geisterfarn + Laternenbeere |
| Glutbombe | werfen | 2 Schaden im Kreis (32 px), Rückstoß; trifft die Hexe nie | Glutmorchel + Bitterblütenblatt |
| Dornennebel | werfen | Zone 36 px, 4 s: verlangsamt auf 45 %, 1 Schaden pro Sekunde; bremst auch die Hexe | Wildkraut + Bitterblütenblatt |

Werfen: Q halten zeigt einen gestrichelten Kreis in Wirkgröße an der Maus (höchstens 200 px weit), Loslassen wirft im Bogen; der Trank landet genau dort. Werfen kostet keine Hexenkraft. Wegstecken von Digitalis bricht das Zielen ab.

### Gegner: befallener Käfer und Dornkäfer

| | Käfer | Dornkäfer |
|---|---|---|
| Leben | 4 | 6 |
| Anläufe pro Angriff | 1 | 2 (der zweite mit kürzerem Innehalten) |
| Anlauf | 150 px/s, 0,6 s | 160 px/s, 0,6 s |
| Aussehen | Aubergine-Panzer | Bordeaux-Panzer, Hörner mit glimmenden Spitzen |

Ablauf: umherkrabbeln → Hexe bemerken (110 px) → innehalten mit Telegraph (0,45 s) → Anlauf → verschnaufen (0,8 s, die Gelegenheit zum Zurückschlagen). Treffer bringen ihn kurz aus dem Tritt. Bei 0 Leben fällt die Blüte ab, der Käfer krabbelt geheilt davon und lässt ein Bitterblütenblatt liegen.

### Neumond-Flut
`Moon.blight_surges()`: Neumond ab der zweiten Mondrunde (Nacht 9, 17 …). Dann bemerken Käfer die Hexe von weiter weg (×1,25), halten kürzer inne (×0,7), rennen schneller (×1,2) und verschnaufen kürzer (×0,75). Im Wald kommen für diese Nacht zwei Käfer dazu (ein normaler, ein Dornkäfer). Sie stehen nicht im Spielstand; wer gereinigt ist, kommt in derselben Nacht nicht wieder.

---

## 3. Steuerung

| Taste | Außerhalb des Kampfs | Im Kampf |
|---|---|---|
| F | Digitalis ziehen | Digitalis wegstecken |
| WASD | Laufen | Laufen (Blick folgt der Maus) |
| Maus | – | Zielen |
| Linksklick | – | Leichter Angriff (halten = wiederholen) |
| Rechtsklick | Trinken | Starker Angriff (kurzes Ausholen) |
| Shift | Schweben | Ausweichen |
| 1–8 / Mausrad | Hotbar-Platz | Form wählen (1–4) |
| Q | Trinken | Kampftrank: trinken, oder halten = zielen, loslassen = werfen |
| R | Erde wecken | Nächste Trank-Sorte |
| E | Benutzen | ruht |

Alle Tasten kommen aus der Eingabe-Zuordnung (`project.godot`: `attack_light`, `attack_heavy`, `potion_quick`, `potion_next`, dazu `combat`, `float`, `hotbar_*`). Texte zeigen sie über `InputHints`, nie fest geschrieben. Q liegt doppelt auf `use_item` und `potion_quick`; das geht, weil `PotionEffects` im Kampf und `CombatPotions` außerhalb nichts tun. Bei einem späteren Umbelegen-Menü beide getrennt anbieten.

Im Garten und im Unterschlupf (sichere Zonen) bleibt Digitalis weggesteckt.

---

## 4. Designentscheidungen

- **Formen und Angriffe als Daten** (`DigitalisForm`, `AttackData`): Balancing heißt Zahlen ändern, neue Formen brauchen keinen Umbau. Zwei Angriffsarten (BOLT, SLASH) reichen vorerst.
- **Zwei Zustände statt großer Zustandsmaschine** (READY, WINDUP) plus Abklingzeit und Eingabepuffer: genug für Ausholen, Abbrechen und schnelles Klicken, ohne Kombo-System.
- **Ausholen statt Wartezeit**: Der starke Angriff ist eine Entscheidung (langsamer laufen, kurz verwundbar), aber nie unkontrollierbar: Ausweichen und Formwechsel brechen ab.
- **Treffer der Sichel geometrisch** (Abstand und Winkel), nicht über Physik-Signale: jeder Hieb trifft jedes Wesen genau einmal, unabhängig von der Bildrate.
- **Bestehendes Ausweichen verbessert, nicht ersetzt**: unverwundbar, bricht Ausholen ab, Nachbilder.
- **Kampfleiste statt Menü**: Im Kampf stehen Formen und Trank an der Stelle der Hotbar-Plätze; die Meldungszeile bleibt. Die Hotbar-Auswahl wird im Kampf nicht verändert.
- **Telegraph in zwei Phasen**: Die Spur folgt der Hexe, steht 0,2 s vor dem Anlauf fest und leuchtet auf. Damit ist jeder Treffer vermeidbar, und Ausweichen zur Seite wird belohnt.
- **Neumond-Flut erst ab der zweiten Mondrunde** (Vorschlag, bitte bestätigen): Nacht 1 eines neuen Spiels ist Neumond; ohne Schonfrist wäre die allererste Nacht die schwerste.
- **Dornkäfer** als erste Variante (Vorschlag): gleiche Regeln, aber zwei Anläufe. Er kommt vorerst nur bei der Neumond-Flut vor. Entfernen: `surge_kinds` in `forest.tscn`.
- **Rückmeldung an der Hexe zentral** (`VitalsFeedback` hört auf `Vitals.damaged`/`healed`): Gegner müssen sich um Aufblitzen, Wackeln und Funken nicht kümmern.
- **Wackeln ganzzahlig** (±2 px), damit das Bild pixelscharf bleibt.
- **Klänge** aus dem bestehenden Generator (`docs/audio/sfx_generator/sfx.py`, Abschnitt Kampf); Angriffsklänge stehen als `sound` in den Angriffsdaten.

---

## 5. Testergebnisse (11.10.2026)

Automatische Tests in Godot 4.7.1 (headless), dazu Bildschirmfotos unter Xvfb:

| Test | Ergebnis |
|---|---|
| Alle Szenen, Scripts und Ressourcen laden, Warnungen als Fehler (außer den bekannten Verdeckungs-Warnungen) | 283 geprüft, 0 Fehler |
| Kampf (Formen, Ausholen, Ausweichen, Halten, Unkraut, Hexenkraft, Tränke, Kampfleiste) | 48 / 48 |
| Gegner (Telegraph folgt und steht fest, Ausweichen vermeidet Treffer, Treffer-Rückmeldung, Dornkäfer, Neumond-Flut, kein Wiederkommen) | 25 / 25 |
| Ablauf des Spiels (Garten, Brauen, Schlafen, Speichern, Laden, Niederlage …) | 47 / 47 |

Angeschaut: Kampfleiste, Zielkreis, Glutbombe im Flug und beim Platzen, Dornennebel, Telegraph (folgend und festgelegt), Dornkäfer, Steuerungsseite auf Deutsch und Englisch.

Nicht automatisch geprüft: wie sich der Kampf anfühlt (Tempo, Schwierigkeit) und wie die neuen Klänge klingen. Das braucht einen Test von Robin.

---

## 6. Bekannte Probleme und Platzhalter

- **Platzhalter-Grafiken**: Sichel-Form (Zeichnung in `digitalis.gd`), Sichel-Icon (`docs/art/item_generators/sickle_icon_platzhalter.py`), Trank-Icons (umgefärbter Wachstumstrank, `combat_potions_platzhalter.py`), Käfer und Dornkäfer, Telegraph-Spur, Geschosse und Hiebe. Eigene Grafiken einfach unter denselben Dateinamen speichern.
- **Keine Angriffs-Animation der Hexe**: Nur Digitalis animiert; die Hexe dreht sich zur Maus.
- **Rezepte vorläufig**, wie besprochen (Rezepte werden noch logisch überarbeitet).
- **Zum Testen**: F1 gibt (nur in Debug-Builds) je 3 Samen und 3 von jedem Kampftrank; N springt zur nächsten Nacht (Neumond-Flut ab Nacht 9).
- **Beide Formen von Anfang an** (`Grimoire.START_FORMS`), damit sie testbar sind. Wie die Sichel freigeschaltet wird, ist offen.
- **Dornennebel bremst auch die Hexe** (Entscheidung: Effekte treffen sie). Kann sich zäh anfühlen, im Spiel prüfen.
- **Klänge ungehört**: synthetisch erzeugt und auf Lautheit gebracht, aber noch nicht im Spiel angehört.
- Die Kampfleiste zeigt Tasten nur für die ersten vier Formen.
- Bekannte ältere Editor-Warnungen (Verdecken von `material`, `ready` u. a. in älteren Scripts) sind unverändert, siehe `docs/QUALITY_OVERHAUL.md`.

---

## 7. Vorschläge für später (nicht gebaut)

- **Treffer-Stopp**: bei starken Treffern 2–3 Frames anhalten, macht Schläge spürbar wuchtiger.
- **Angriffs-Pose der Hexe** (Robin zeichnet): ein, zwei Frames Ausholen und Zuschlagen pro Richtung.
- **Formen freischalten über das Grimoire**: Belohnung `DIGITALIS_FORM` ist schon vorbereitet; dritte Form z. B. die Dornenpeitsche aus der Tabelle in `game_design.md` (Reichweite, heranziehen), dann als neue `AttackData.Kind`.
- **Sichel in der Overworld**: Unkraut schneiden ohne Kampfmodus, mit eigener Bedienung (laut Design später getrennt vom Kampf).
- **Weitere Gegner mit eigenem Telegraph**: eine befallene Pflanze, die Sporen spuckt (Kreis am Boden vor dem Einschlag); Motten im Schwarm, die nur bei Licht angreifen.
- **Blütenherz (Boss)**: mehrere Phasen, jede mit eigenem, gut lesbarem Telegraph; darf fordernd sein.
- **Irrlicht hilft im Kampf** (Idee vom 09.10.): kleiner Funke auf nahe Gegner.
- **Kleine Synergien statt Kombo-System**: z. B. ein gestaggerter Käfer nimmt von der Sichel +1 Schaden. Nur wenn es sich im Test lohnt.
- **Weitere Wurftränke**: Reinigungsnebel, Giftwolke (aus der Kandidatenliste vom 10.10.).
