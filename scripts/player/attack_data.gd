class_name AttackData
extends Resource

## Ein Angriff einer Digitalis-Form (leicht oder stark), als Daten. Combat
## liest nur diese Werte; welche Form wie kämpft, steht damit komplett in
## data/digitalis/<form>.tres. Balancing = Zahlen ändern.
##
## Zwei Arten, mehr braucht es vorerst nicht:
## BOLT  ein Geschoss zur Maus (Stab), optional mit Flächentreffer beim Platzen.
## SLASH ein Hieb im Bogen zur Maus (Sichel), trifft alles im Bogen einmal.

enum Kind { BOLT, SLASH }

@export var kind: Kind = Kind.BOLT
@export var damage: int = 1
# Hexenkraft pro Angriff. Alles, was Zauberei ist, kostet Hexenkraft
# (game_design.md, Abschnitt 7).
@export var power_cost: float = 1.0
# Sekunden bis zum nächsten Angriff (zählt ab dem Auslösen).
@export var cooldown: float = 0.3
# Ausholen: So lange lädt der Angriff, bevor er auslöst (0 = sofort). Gut
# lesbar, aber kurz, damit nichts unkontrollierbar wird.
@export var windup: float = 0.0
# So schnell läuft die Hexe beim Ausholen (1 = normal, 0.4 = deutlich langsamer).
@export var windup_move_factor: float = 1.0
@export var knockback: float = 90.0
# Farbe von Geschoss bzw. Hieb (Magenta = Magie).
@export var color: Color = Color("#E458B1")
# Klang beim Auslösen (Sfx-ID, leer = keiner).
@export var sound: String = ""

@export_group("Bolt")
@export var speed: float = 220.0
@export var max_distance: float = 180.0
@export var radius: float = 3.0
# 0 = trifft nur, was es berührt; sonst platzt es in diesem Umkreis.
@export var burst_radius: float = 0.0

@export_group("Slash")
# Reichweite des Hiebs von der Hexe aus (Pixel).
@export var reach: float = 30.0
# Öffnungswinkel des Bogens in Grad.
@export var arc_degrees: float = 100.0
# So lange ist der Hieb sichtbar und trifft (Sekunden).
@export var active_time: float = 0.14
# Schneidet Wildgras und Unkraut, das im Bogen steht (Sichel).
@export var cuts_wild: bool = false
