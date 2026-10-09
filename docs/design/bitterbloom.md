# Bitterbloom – Design der Bitterblüte

Stand: 09.10.2026. Regelwerk dafür, wie die Bitterblüte und alles Befallene aussieht und sich verhält: Gegenstände, Umgebung, Wesen, Effekte. Ziel: Man erkennt Befall **auf den ersten Blick**, egal ob als 16×16-Icon im Grimoire oder als großes Wesen im Wald. Ergänzt `game_design.md` (Lore, Abschnitt 9).

Legende: ✅ entschieden · 💡 Idee, gefällt, noch nicht fest · 🔮 später · ❓ offen · ❌ verworfen

---

## 1. Der Kern

- ✅ **Die Bitterblüte ist Verfall, der nicht sein durfte.** Vespera wollte ihr Altern aufhalten; der unterdrückte Verfall wucherte als Blüte (Lore, `game_design.md` 9).
- ✅ Deshalb sieht Befallenes nicht nur krank aus, sondern **festgehalten**: überreif, prall, zu lange am Leben gehalten. Kein Alien-Monster, sondern ein extrem aggressiver Symbiont, eine aus dem Ruder gelaufene Naturgewalt mit morbider Schönheit.
- ✅ **Heilung** heißt: Die Blüte fällt ab, und die Dinge dürfen endlich wieder normal welken und vergehen.
- ✅ **Gleichgewicht statt Sieg:** Am Ende wird die Blüte gebändigt, nicht vernichtet (siehe 7).

## 2. Visuelle DNA

### Farben
- ✅ **Oliv und Fahlgrau** = sterbende, ausgesaugte Substanz (Palette: Welk oliv `#7C7C68`, Laub dunkel `#1D3436`, Welk dunkel `#181A28`).
- ✅ **Tiefschwarz** = Nekrose, Erstickung (Adernetze, Risse).
- ✅ **Magenta** = die aktive, parasitäre Kraft. **Nur Knospen, Sporen und Risse leuchten Magenta**, nichts sonst. So bleiben sie im Wald und im Nebel sofort als gefährliche oder interaktive Punkte erkennbar.
- ✅ Gesundes Grün des Waldes bleibt klar davon getrennt.
- ✅ Schwarze Fingerspitzen bleiben ein reines Hexen-Merkmal und haben nichts mit der Blüte zu tun. Die Blüte ist nie schwarz-glänzend, sondern oliv mit Magenta.

### Formen
- ✅ **Asymmetrisch, strangulierend, aufplatzend.**
- ✅ Ranken wuchern **nicht buschig** wie Efeu, sondern wickeln sich **spiralförmig wie enger Draht oder ein Korsett** um ihre Wirte (Stämme, Ruinen, Felsen) und schneiden ein.
- ✅ Befallenes **bricht von innen auf**: Risse, aus denen weiche, fleischige Magenta-Knospen dringen.
- ✅ **Knospen** wirken wie **geschlossene, fleischige Hände oder Kokons** (ein Echo auf Vespera). Erst tief im Wald, nahe den Blütenherzen, öffnen sie sich zu **stacheligen, asymmetrischen Blüten**.

### Bewegung
- ✅ Befallene Kernobjekte **atmen**: Die Magenta-Teile glimmen langsam auf und dunkeln wieder ab (einfacher Loop).
- ✅ Alles fühlt sich **klebrig, schwer und zäh** an.

## 3. Gegenstände und Zutaten

- ✅ (09.10.) **Normale Items können nicht befallen sein.** Es gibt keine befallenen Varianten von Alraune, Pilz & Co., und Befall springt nie auf Inventar oder Garten über. Die Bitterblüte ist eine Sache der **Welt**: Umgebung und Wesen.
- 💡 Stattdessen werden **Teile der Blüte selbst zu Zutaten**: z. B. Blütenknospe (Magenta), Rankenstück (oliv), Sporen. Wesen lassen sie beim Reinigen fallen. Das ersetzt die frühere Regel „verdorbene Zutaten von gereinigten Wesen“ (`game_design.md`, Abschnitt 6) und bleibt die Quelle der stärksten Tränke.
- ✅ Diese Blüten-Zutaten folgen der DNA aus Abschnitt 2 und haben immer **mindestens einen Magenta-Punkt**.
- ❌ Entsättigte „befallene“ Versionen normaler Items (Test vom 09.10.).

## 3b. Referenzbild

`docs/art/referenz/bitterbloom_concept.jpg` (09.10.): befallener Baum im tiefen Wald (Phase 2–3). Was es festlegt:
- ✅ **Holz des Wirts wird knochenbleich bis aschgrau**, mit **tiefen schwarzen Rissen** in der Rinde.
- ✅ **Dicke, seilartige olive Ranken** winden sich spiralförmig um Stamm und Äste (Korsett); dünne Ausläufer hängen herab wie Flechten.
- ✅ **Magenta-Knospen sind glänzend, prall und fleischig**, mit Glanzlicht; sie quellen **aus den Rissen** hervor. Um sie herum ein Magenta-Schein, im Schatten des Stamms glimmen Magenta-Adern.
- ✅ Feine **Magenta-Partikel** schweben in der Luft.
- ✅ Am Boden: Bodennebel, **schwarze Dornenranken als Silhouetten**, tote Wurzeln. Im Hintergrund kahle Bäume mit olivem Moos und Ruinen.
- ✅ **Jedes befallene Objekt hat mindestens einen Magenta-Punkt** (Lesbarkeit, auch klein).
- Hinweis: Das Bild ist Konzeptkunst in hoher Auflösung. Im Spiel gilt der Pixel-Stil aus `CLAUDE.md` (32er-Raster, harte Kanten, keine Verläufe; Schein über Licht-Nodes).

## 4. Umgebung: der Wald wird ausgetrunken

Der Wald wird nicht durch neue, aggressive Bäume ersetzt, sondern **ausgetrunken**. Je tiefer man geht, desto mehr entzieht die Blüte der Welt das Leben.

| Phase | Gebiet | Aussehen |
|---|---|---|
| 1 | Randgebiet | normale Tiles; vereinzelt olive Ranken über dem Boden; einige Pflanzen mit braunen Rändern |
| 2 | tieferer Wald | Bäume verlieren ihr Laub, Holz wird aschfahl; Ranken wickeln sich um Stämme; **Magenta übernimmt** die visuelle Herrschaft |
| 3 | Epizentrum (Blütenherz) | Boden fast nur noch verworrenes Wurzelwerk; keine normale Vegetation mehr; offene, stachelige Blüten; das Herz pulsiert |

- ✅ Bäume, Ruinen und Felsen bekommen eine **zusätzliche Ebene** mit oliven Korkenzieher-Ranken, die ins Holz schneiden (wiederverwendbar über vorhandene Objekte).
- ✅ Normale Vegetation verliert ihre Blätter und wird zu **stacheligen, abweisenden Silhouetten**.
- ✅ Der Boden wird von einem **dunklen Wurzelmuster** überzogen.
- 💡 In Godot die **Sättigung der Hintergrundebenen** in befallenen Gebieten leicht senken, damit Magenta noch härter heraussticht.
- 💡 In stark befallenen Zonen schweben **langsame, schwere Magenta-Partikel**.

## 5. Interaktion: Was ruhig ist, ist Hindernis. Was pulsiert, reagiert.

- ✅ **Normale Ranken sind passive Barrieren:**
  - kleine Ranken schneidet die **Sickle**;
  - Ranken über Lücken zieht die **Thornwhip**;
  - **dichte Rankenwände** lösen sich erst, wenn das **Blütenherz** des Gebiets gereinigt ist.
- ✅ **Greifende Ranken** sind ein eigener Gegnertyp, erkennbar an **pulsierenden Magenta-Knospen**. Lese-Regel für die Spielerin: Glimmen = Vorsicht.
- ✅ Beim Zerschneiden oder Reinigen spritzt kein flüssiger Saft, sondern **dicke, dunkel-olive Tropfen**, die träge zu Boden fallen.
- ❓ Welche Tränke (Wurftränke) gegen Ranken helfen.

## 6. Wesen (Gegner)

- ✅ Keine Zombies, sondern **gestresste, übernommene Wirte**, die aus dem Gleichgewicht geraten sind.
- ✅ **Asymmetrie** im Sprite: z. B. ein Hirsch mit normalem Geweih links, rechts eine wuchernde Rankenmasse, die ihn beim Laufen aus dem Tritt bringt.
- ✅ **Milchig-trübe Augen.**
- ✅ **Unregelmäßige Animation:** lethargisches Schleppen im Wechsel mit plötzlichen, ruckartigen Ausbrüchen, wenn der Parasit zuckt.
- ✅ (bestehend) **Reinigen statt töten:** Die Blüte fällt ab, das geheilte Tier läuft davon und lässt eine verdorbene Zutat zurück.
- 🔮 Große Wesen erst, wenn die Regeln an Items und Umgebung funktionieren.

## 7. Neumond und Nebel

- ✅ (bestehend) Bei **Neumond** ist die Blüte am stärksten.
- 💡 **Nebel-Shader:** In befallenen Gebieten wabert schwerer Bodennebel (Noise-Shader, der langsam wandert). Bei Neumond steigt er höher, die Sicht wird schlechter, die Magenta-Knospen glimmen durch den Dunst.
- ✅ Bei Neumond kriechen Ranken als **kurze, optionale Rückfälle** in schon geheilte Gebiete zurück (mit verdorbenen Zutaten), nicht dauerhaft.
- ✅ (bestehend) **Ausläufer in neue Gebiete** (Sumpf, Berge, Moor …) sind der Rahmen für spätere Updates: Dort blockiert vorher eine undurchdringliche Rankenwand den Weg.

## 8. Gebändigt (nach dem Höhepunkt)

- ✅ Die **Dornen ziehen sich zurück**; das aggressive Pulsieren weicht einem **ruhigen, stetigen Glimmen**.
- ✅ **Symbiose:** Die gezähmte Blüte wächst bevorzugt auf **Totholz** und hilft beim Zersetzen, statt gesunde Bäume zu würgen. Sie blockiert keine Wege mehr.
- 💡 Ranken bilden **natürliche Brücken** über Abgründe.

## 9. Reihenfolge der Grafiken

1. **Blüten-Zutaten** (Knospe, Rankenstück, Sporen) als Icons.
2. Ranken-Ebene für vorhandene Objekte (Baum, Fels), Ranken auf dem Boden, Rankenwand.
3. Boden und Vegetation in Phase 2 und 3; Knospen und offene Blüten.
4. Effekte: Atmen, olive Tropfen, Partikel, Nebel.
5. Wesen (erst klein, dann groß).
6. Gebändigte Varianten.

## 10. Aufteilung der Grafiken (09.10.)

- ✅ **Große Welt-Sprites** (befallene Bäume, Felsen, Rankenwand, Blütenherz, Wurzelboden) erzeugt Robin mit seinem Bild-KI-Workflow nach `docs/prompts/grafik_auftrag_bitterbloom.md`.
- ✅ **Kleine Teile** macht Claude per Generator (`docs/art/item_generators/bitterbloom_small.py`):
  - Blüten-Zutaten als Icons 16×16: `blight_bud` (Knospe), `blight_vine` (Rankenstück), `blight_spores` (Sporen);
  - `blight_bud_overlay` (6 Frames à 16×16, „Atmen“) + `_glow`: glatte, glänzende Knospe, die aus einem schwarzen Riss quillt; zum Draufsetzen auf vorhandene Objekte;
  - `blight_drop` (4 Frames à 5×8): dicker oliver Tropfen, hängt, fällt träge, klatscht platt (beim Schneiden und Reinigen);
  - `blight_spore` (2 Frames à 3×3): schwebende Magenta-Spore (Partikel in stark befallenen Zonen).

## 11. Technik-Hinweise für Claude Code

- **Atmen:** Glow-Ebenen (`*_glow.png`) per `modulate.a` langsam zwischen ca. 0,55 und 1,0 pendeln lassen (Periode ca. 3 s, Startphase zufällig), dazu ein schwaches `PointLight2D` in Magenta mit derselben Kurve. Bei Neumond etwas schneller und heller.
- **Nebel:** ein `ColorRect` über dem Boden des befallenen Gebiets (unter Figuren und Objekten) mit einem einfachen Shader: zwei Lagen Noise, die langsam gegeneinander wandern; Farbe Fahlgrau-Violett, Deckkraft nach oben auslaufend. Pixelig halten: Noise auf das 1-px-Raster runden (z. B. `floor(UV * Größe) / Größe`) und die Deckkraft in wenigen harten Stufen ausgeben, damit es zu „keine weichen Verläufe“ passt. Parameter `height` und `density`; bei Neumond beide höher.
- **Sättigung:** In befallenen Gebieten die Hintergrund-Ebenen über einen `CanvasModulate` bzw. Shader leicht entsättigen; Glow-Ebenen davon ausnehmen.
- **Partikel:** `CPUParticles2D` mit den Texturen `blight_spore` (langsam aufsteigend, wenige) und `blight_drop` (beim Schneiden, mit Schwerkraft, träge).
