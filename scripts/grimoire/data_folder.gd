class_name DataFolder

## Lädt alle .tres-Dateien eines Ordners. So ist neuer Inhalt (Kapitel,
## Seiten, Disziplinen …) nur eine neue Datei, kein neuer Code.
## list_directory funktioniert auch im exportierten Spiel, anders als ein
## einfaches Durchsuchen des Ordners.


static func load_all(folder: String) -> Array[Resource]:
	var result: Array[Resource] = []
	for file in ResourceLoader.list_directory(folder):
		if file.ends_with(".tres"):
			result.append(load(folder + file))
	return result
