# Grafik-Auftrag: Bitterblüte in der Welt (Stand 09.10.2026)

Für die großen Welt-Sprites der Bitterblüte. Grundlage: `docs/design/bitterbloom.md` (Regeln) und das Referenzbild `docs/art/referenz/bitterbloom_concept.jpg`. Die kleinen Teile (Blüten-Zutaten, Knospen-Overlay, Tropfen, Partikel) macht Claude separat, siehe `docs/design/bitterbloom.md`, Abschnitt 10.

## Feste Regeln

- Pixel-Art im Stil der vorhandenen Flora (`assets/environment/flora/`, Übersicht `docs/art/vorschau/uebersicht_flora_3x.png`): **32er-Raster**, harte Pixel, kein Anti-Aliasing, **keine weichen Verläufe**, Licht von oben links, Aubergine-Kontur. Das Referenzbild ist hochauflösende Konzeptkunst; übernommen werden **Formen und Farben**, nicht die Detailtiefe.
- Palette `docs/art/hexen_palette.gpl` (Zwischentöne erlaubt, neue Töne auflisten). Bitterblüte:
  - Wirtsholz **knochenbleich bis aschgrau** (Knochen `#EADFCB`, Laken Schatten `#C6B8BE`, Laken Schatten tief `#9688A0`), **tiefe schwarze Risse** (Tiefschwarz `#0E0A14`);
  - Ranken **oliv** (Welk oliv `#7C7C68`, dunkler Ton dazu), Laub dunkel `#1D3436`;
  - Knospen **Magenta** (`#C2307A`, hell `#E458B1`, Glanzlicht `#FFD2EC`, Schatten `#5C1E4E`).
- **Magenta nur für Knospen, Risse und Sporen.** Jedes befallene Objekt hat mindestens einen Magenta-Punkt.
- **Leuchten nicht ins Bild malen.** Jede Grafik mit Magenta bekommt eine zweite Datei `*_glow.png` gleicher Größe, die **nur** die Magenta-Pixel enthält (Rest transparent). Das Spiel lässt diese Ebene „atmen“ (langsam heller und dunkler) und setzt den Schein mit Licht-Nodes.
- Formen: **asymmetrisch, strangulierend, aufplatzend.** Ranken wickeln sich **spiralförmig wie Draht oder Korsett** um den Wirt und schneiden ein; Knospen sind **prall, glänzend, fleischig** (wie geschlossene Hände oder Kokons) und quellen **aus Rissen**.
- **Fußpunkt unten Mitte**, Kollision nur am Fuß (wie in `docs/ASSETS.md`, Abschnitt Flora). Unbewegt (1 Frame), außer wo angegeben.

## Die Grafiken

### Phase 1 (Randgebiet)
| Datei | Größe | Inhalt |
|---|---|---|
| `blight_vines_ground_1–4.png` | 32×32 | einzelne olive Ranken, die über den Boden kriechen; transparent, als Deko auf normalen Boden-Tiles |
| `blight_vine_small.png` | 32×32 | kleiner Rankenknoten mit einer geschlossenen Knospe; **mit der Sickle schneidbar** (+ `_glow`) |

### Phase 2 (tieferer Wald)
| Datei | Größe | Inhalt |
|---|---|---|
| `tree_blighted.png` | 96×120 | wie `tree_dead.png`, aber Holz knochenbleich mit schwarzen Rissen, 2–3 dicke olive Ranken spiralförmig um Stamm und Äste, 3–5 Magenta-Knospen aus Rissen, hängende Rankenfäden (+ `_glow`) |
| `stump_blighted.png` | 32×32 | befallener Baumstumpf, eine Knospe (+ `_glow`) |
| `rock_blighted.png` | 32×32 | Fels mit Ranken-Korsett und Riss, eine Knospe (+ `_glow`) |
| `thorns_1–3.png` | 32×32 | kahle, **schwarze Dornenranken** als stachelige Silhouetten (statt Büschen) |

### Phase 3 (Epizentrum)
| Datei | Größe | Inhalt |
|---|---|---|
| `blight_wall.png` | 64×64 | dichte Rankenwand, links/rechts kachelbar; versperrt Wege, bis das Blütenherz gereinigt ist (+ `_glow`) |
| `blight_bloom_open.png` | 32×32 | offene, **stachelige, asymmetrische** Magenta-Blüte (nur nahe dem Herzen) (+ `_glow`) |
| `blight_heart.png` | 96×96, 6 Frames (576×96) | das Blütenherz: Knoten aus Wurzeln und Ranken mit großer, pulsierender Knospe in der Mitte; Frames = langsamer Herzschlag (+ `_glow` mit 6 Frames) |
| Boden „Wurzelwerk“ | wie `assets/environment/ground/` | Füll-Tiles aus verworrenem dunklen Wurzelwerk, im Aufbau von `ground_atlas_layout.json`; vorher mit Claude Code klären, welche Übergänge nötig sind |

## Prompt-Vorlage für die Bild-KI (englisch)

> 2D top-down pixel art game sprite, 32-pixel grid, hard pixel edges, no anti-aliasing, no soft gradients, light from top left, dark aubergine outline, transparent background. Dark cozy witchcraft forest. A [OBJEKT, z. B. dead tree] infested by the Bitterbloom: bone-pale ashen wood with deep black cracks, thick rope-like olive vines spiraling tightly around it like a corset, glossy plump fleshy magenta buds bursting out of the cracks, asymmetric. Limited palette: bone white, ash grey, black, olive, dark green, magenta. Size [BREITE]×[HÖHE] pixels, feet at bottom center. Style reference: attached image.

Das Referenzbild und eine vorhandene Flora-Grafik (z. B. `tree_dead.png` in 4×) mitgeben, damit Stil und Maßstab stimmen.

## Arbeitsweise

- Zuerst **eine** Grafik (Vorschlag: `tree_blighted.png`) und mit Claude im Chat prüfen: Raster, Palette, Größe, Glow-Ebene.
- Vorschau in 3× neben der gesunden Variante nach `docs/art/vorschau/`.
- Fertige Dateien sammelt Robin und gibt sie Claude Code zum Einbauen (Ablage `assets/environment/blight/`).
