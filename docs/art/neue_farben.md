# Neue Farben vom 07.10.2026

Die Palette ist gelockert: Basis und Farbsemantik bleiben, Zwischentöne sind erlaubt, damit
Verläufe natürlicher wirken (Schatten Richtung Blau/Violett, Lichter Richtung Warm).
Bereits genutzte Basisfarben (Geisterblau, Flieder, Indigo, Giftgrün usw.) sind nicht aufgeführt.

Am 07.10.2026 nach Robins OK in `hexen_palette.gpl` übernommen.

| Farbe | Hex | RGB | Genutzt in | Zweck |
|---|---|---|---|---|
| Glas leer | `#1F244A` | 31, 36, 74 | Tränke | leeres Glas, etwas heller als der Glasrand |
| Gold dunkel | `#9C6834` | 156, 104, 52 | Tränke, Bett, UI | Schattenseite von Gold |
| Gold hell | `#F4CC78` | 244, 204, 120 | Bett, UI | Glanzpunkt auf Gold |
| Eisblau hell | `#CED6F4` | 206, 214, 244 | Tränke, Kuppel | heller Geisterton, Kuppelrand |
| Lichtkern warmweiss | `#FFF6DC` | 255, 246, 220 | Tränke | heller Kern im Irrlicht/Mondlicht |
| Silber-Mondlicht | `#D6E8DE` | 214, 232, 222 | Tränke | Funke in der Mondernte |
| Glanz kalt | `#F0F4FF` | 240, 244, 255 | Kuppel | Stern auf der Kuppel |
| Nachtviolett | `#1A142E` | 26, 20, 46 | Tränke | Schattenseite der Ewigen Nacht |
| Bordeaux hell | `#962C48` | 150, 44, 72 | Tränke, Bett, UI | Glanz auf Bordeaux |
| Bordeaux tief | `#360E24` | 54, 14, 36 | Bett | Decke an der Schattenseite |
| Magenta gedaempft | `#5C1E4E` | 92, 30, 78 | UI | Runen im leeren Feld, Glimmen |
| Magenta hell rosa | `#FFD2EC` | 255, 210, 236 | UI | Blasen im glühenden Sud |
| Ebenholz 1 | `#20141E` | 32, 20, 30 | Bett | Holz, dunkelste Stufe |
| Ebenholz 2 | `#34222E` | 52, 34, 46 | Bett | Holz, Grundton |
| Ebenholz 3 | `#4E3440` | 78, 52, 64 | Bett | Holz, Lichtkante |
| Ebenholz 4 | `#684854` | 104, 72, 84 | Bett | Holz, Glanz |
| Laken Schatten | `#C6B8BE` | 198, 184, 190 | Bett | Knochen im Schatten, Richtung Flieder |
| Laken Schatten tief | `#9688A0` | 150, 136, 160 | Bett | Knochen, tiefer Schatten |
| Kessel 0 | `#181224` | 24, 18, 36 | UI-Kessel | Körper, Schatten |
| Kessel 1 | `#261E3A` | 38, 30, 58 | UI-Kessel | Körper, Grundton |
| Kessel 2 | `#383260` | 56, 50, 96 | UI-Kessel | Körper, Licht |
| Kessel 3 | `#524E8C` | 82, 78, 140 | UI-Kessel | Körper, Glanz |
| Kesselrand 0 | `#1E162C` | 30, 22, 44 | UI-Kessel | Rand, Schatten |
| Kesselrand 1 | `#423A5C` | 66, 58, 92 | UI-Kessel | Rand, Grundton |
| Kesselrand 2 | `#68608C` | 104, 96, 140 | UI-Kessel | Rand, Licht |
| Welk dunkel | `#181A28` | 24, 26, 40 | Debuff-Icon | verwelkter Stängel |
| Welk oliv | `#7C7C68` | 124, 124, 104 | Debuff-Icon | verwelkte Blätter |

Vorschlag für die Regel in CLAUDE.md (ersetzt "begrenzte Farbpalette"):

> Die Palette ist die Basis und bestimmt die Farbsemantik. Zwischentöne zwischen Palettenfarben
> und passende Ergänzungen sind erlaubt, wenn sie Verläufe natürlicher machen (Schatten Richtung
> Blau/Violett, Lichter Richtung Warm). Keine weichen Gradienten, kein Anti-Aliasing.
> Richtwert 8–12 Farben pro Grafik. Neue Töne in `docs/art/hexen_palette.gpl` nachtragen.

# Neue Farben vom 08.10.2026 (Flora)

Sechs Zwischentöne für Laub. Die Kronen brauchen eine Stufe zwischen Nachtblau und Giftgrün, damit sie
sich vom Gras abheben (kühler, Schatten Richtung Blau). Die Weide ist bewusst silbriger als die übrigen
Bäume. In `hexen_palette.gpl` nachgetragen.

| Farbe | Hex | RGB | Genutzt in | Zweck |
|---|---|---|---|---|
| Laub Schatten | `#16222E` | 22, 34, 46 | alle Kronen, Büsche, Farne | tiefster Laubschatten, Richtung Nachtblau |
| Laub dunkel | `#1D3436` | 29, 52, 54 | alle Kronen, Büsche, Farne | Laub im Schatten |
| Laub mittel | `#30624A` | 48, 98, 74 | Kronen, Farne, Gras, Moos | Stufe zwischen Giftgrün dunkel und Giftgrün |
| Weide dunkel | `#213944` | 33, 57, 68 | Weide, Nachtlavendel | silbrig-kühles Laub, Schatten |
| Weide mittel | `#3A6062` | 58, 96, 98 | Weide, Nachtlavendel | silbriges Laub |
| Weide hell | `#689288` | 104, 146, 136 | Weide | Zweigspitzen, Licht |

## Rinde je Baumart (08.10.2026)

Vorher hatten alle Bäume dieselbe lila-rosa Ebenholz-Rinde. Jetzt hat jede Art eine eigene Rinde mit 3 Tönen. Der dunkelste Ton bleibt bei allen Ebenholz 1, so passen die Bäume weiter zusammen. Der Uraltbaum (Unterschlupf) behält Ebenholz, weil er der besondere Hexenbaum ist.

| Baum | Töne (2 / 3 / 4) | Charakter |
|---|---|---|
| Eiche | `#34282C` `#4C3E3E` `#665852` | graubraun, kräftige Furchen |
| Weide | `#2E3234` `#464C48` `#62685E` | grünlich-grau, passt zum silbrigen Laub |
| Tanne | `#3C1E22` `#58302C` `#74463A` | rotbraun, warm im kühlen Nadelgrün |
| toter Baum | `#3E3846` `#5C5664` `#827C88` | ausgebleicht, silbrig |
| Holunder | `#423836` `#5E544C` `#7E7466` | hell, mit Korkwarzen |
