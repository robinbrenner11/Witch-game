# Checkliste: Basics vor den großen Erweiterungen

Stand 07.10.2026, abgeglichen mit dem Repo (letzter Commit "Kessel und Wachstumstrank").
Erst wenn diese Punkte stehen, lohnen sich Wald, NPCs, Kampf, Dungeons usw.
*(Auftrag 07.10.)* = steht schon im Coding-Auftrag `docs/prompts/coding_session_2026-10-07.md`.

## 1. Fundament – ohne das wird jede Erweiterung später teuer

- [x] **Spielstand speichern und laden** *(Auftrag 07.10.)* – bisher geht beim Schließen alles verloren
- [x] **Gartendaten außerhalb der Szene** (Autoload) *(Auftrag 07.10.)* – Voraussetzung für Speichern und Szenenwechsel
- [ ] **Ein gemeinsames Item-Register** – Samen/Ernte werden noch aus den Pflanzendaten abgeleitet, Tränke haben eigene Dateien. Vor weiteren Items: alle Items einheitlich als Datendatei (Name, Icon, Beschreibung, max. Stapelgröße, Typ: Samen/Zutat/Trank/Werkzeug)
- [ ] **Szenenwechsel** – Türen/Übergänge, Überblendung, Startpunkt pro Eingang (Unterschlupf ↔ Garten ↔ Wald)
- [x] **Pausieren** – Zeit und Spiel stoppen, solange ein Menü oder Fenster offen ist (Inventar- und Brau-Fenster; Pausemenü fehlt noch)

## 2. Bedienung – was Spielerinnen sofort vermissen würden

- [x] **Rückmeldungen auf dem Bildschirm statt in der Konsole** – "Inventar voll", "Keine Samen in der Hand" usw. laufen über `print()` und sind im Spiel unsichtbar
- [x] **Interaktions-Hinweis** – hervorheben, womit E gerade interagiert (Umriss oder kleines "E")
- [x] **Inventar-Fenster** – 24 Plätze existieren, sichtbar sind nur 8; Fenster mit Drag & Drop (gleiche Bausteine wie das Brau-Fenster) → Tab
- [ ] **Items benutzen** – eine einheitliche Aktion "ausgewähltes Item benutzen" (trinken, ausgießen, pflanzen) – teilweise: Q/Rechtsklick trinkt, E gießt aus und pflanzt
- [ ] **Items wegwerfen/entsorgen** – sonst verstopft Hexenschlamm das Inventar (entschieden: Mülleimer als Objekt in der Welt)
- [ ] **Beete anlegen und entfernen** ("Erde wecken") – Beete sind bisher fest in die Karte gesetzt

## 3. Rahmen – macht aus dem Prototyp ein Spiel

- [ ] **Hauptmenü** – Neues Spiel, Fortsetzen, Einstellungen, Beenden (bisher startet das Spiel direkt in der Welt)
- [ ] **Pausemenü (Esc)** – Fortsetzen, Einstellungen, Speichern & Beenden
- [ ] **Einstellungen** – Lautstärke, Vollbild/Fenster, später Tastenbelegung
- [ ] **Sound** – bisher keine einzige Audiodatei. Minimum: Musik (SZA-Stimmung), Nachtatmosphäre, Schritte, Ernten, Pflanzen, Kessel-Blubbern, UI-Klicks
- [ ] **Bett + Morgen-Moment** *(Auftrag 07.10.)* – Bett fertig, Morgen-Moment fehlt noch

## 4. Einstieg – damit jemand außer dir das Spiel versteht

- [ ] **Spielstart** – Ankunft im Unterschlupf, Fund des Rezeptbuchs der verstorbenen Hexe (ein paar Zeilen Text)
- [ ] **Rezeptbuch-Fenster** – bekannte Rezepte und "???"
- [ ] **Erste Ziele** – 2–3 kleine Aufgaben (pflanzen, ersten Trank brauen, schlafen), damit der Kreislauf klar wird

## 5. Kleinkram, der früh billig und spät teuer ist

- [ ] **Aktions-Animationen** – ausgießen, ernten, schnippen (bisher nur laufen/stehen)
- [ ] **Blickrichtung beim Interagieren** – nur nach vorne, nicht hinter sich
- [ ] **Einmal früh exportieren** – Windows-Build bauen und testen

## Empfohlene Reihenfolge nach dem Auftrag vom 07.10.

1. Rückmeldungen auf dem Bildschirm + Interaktions-Hinweis (schnell, großer Effekt)
2. Item-Register + Inventar-Fenster
3. Szenenwechsel
4. Menüs + Sound
5. Einstieg (Rezeptbuch, erste Ziele)
6. Danach erst: Wald, NPCs, Kampf, Begleiter …
