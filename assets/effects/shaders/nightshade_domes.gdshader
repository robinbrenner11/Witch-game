shader_type canvas_item;

// Nachtschatten-Aura: geisterhaft blauer Nebel über dem 3×3-Bereich jedes
// hemmenden Nachtschattens. Ein Shader für alle, damit nebeneinander liegende
// Auren zu einer Nebelglocke verschmelzen statt sich zu überlagern.
//
// Die Form (Ellipsen + weiches Minimum) stammt aus
// docs/art/plant_generators/nightshade_aura.py (field, smin). Statt Glasrand
// gibt es Nebelschwaden: Rauschen, in ganzen Pixeln verschoben und in wenige
// Stufen gerastert (Dither), damit es Pixel-Art bleibt.

// Muss zu MAX_DOMES in nightshade_domes.gd passen.
const int MAX_DOMES = 32;
const float RX = 49.0;
const float RY_DOME = 60.0;
const float RY_GROUND = 47.0;
// Wie weich die Auren ineinanderfließen (0 = harte Kante).
const float K_SMOOTH = 0.35;
// Wie stark das Rauschen den Rand ausfranst (in Feld-Einheiten).
const float EDGE_WOBBLE = 0.32;
// Wie schnell die Schwaden ziehen, in Pixeln pro Sekunde.
const vec2 DRIFT = vec2(3.0, -1.5);

const vec3 GHOST = vec3(120.0, 140.0, 185.0) / 255.0;
const vec3 PALE = vec3(206.0, 214.0, 244.0) / 255.0;
const vec3 DEEP = vec3(52.0, 70.0, 120.0) / 255.0;

// Geordnetes 4×4-Dithermuster: verteilt Zwischenstufen als Pixelmuster
// statt als weichen Verlauf.
const float BAYER[16] = float[16](
	0.0, 8.0, 2.0, 10.0,
	12.0, 4.0, 14.0, 6.0,
	3.0, 11.0, 1.0, 9.0,
	15.0, 7.0, 13.0, 5.0
);

// Mittelpunkte der Auren in Welt-Pixeln (Mitte des Beet-Tiles).
uniform vec2 centers[MAX_DOMES];
uniform int center_count = 0;
// Pochen: 0 = Ruhe, 0.5, 1 = Höhepunkt.
uniform float intensity = 0.0;

// Die Fläche wird in Weltkoordinaten gezeichnet, VERTEX ist also schon die
// Weltposition. Ein varying reicht sie an fragment() weiter.
varying vec2 world_pos;

void vertex() {
	world_pos = VERTEX;
}

float smin(float a, float b) {
	float h = max(K_SMOOTH - abs(a - b), 0.0) / K_SMOOTH;
	return min(a, b) - h * h * K_SMOOTH * 0.25;
}

// Unter 1 = innerhalb der Aura um c. Nach oben ist sie höher als nach unten.
float ellipse(vec2 p, vec2 c) {
	float ry = p.y < c.y ? RY_DOME : RY_GROUND;
	vec2 q = (p - c) / vec2(RX, ry);
	return dot(q, q);
}

float field(vec2 p) {
	float v = 99.0;
	for (int i = 0; i < center_count; i++) {
		float d = ellipse(p, centers[i]);
		v = i == 0 ? d : smin(v, d);
	}
	return v;
}

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

// Weiches Zufallsmuster: Zufallswerte auf einem Gitter, dazwischen überblendet.
float value_noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	float top = mix(hash(i), hash(i + vec2(1.0, 0.0)), f.x);
	float bottom = mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), f.x);
	return mix(top, bottom, f.y);
}

// Zwei Schichten, die verschieden schnell ziehen: große Schwaden und feine
// Fetzen. floor() verschiebt nur um ganze Pixel, so bleibt alles scharf.
float fog(vec2 p) {
	vec2 drift = floor(TIME * DRIFT);
	vec2 drift_fine = floor(TIME * -DRIFT * 0.6);
	return value_noise((p - drift) / 16.0) * 0.65 + value_noise((p - drift_fine) / 6.0) * 0.35;
}

void fragment() {
	vec2 p = floor(world_pos);
	float t = intensity;
	float n = fog(p);

	// Ausgefranster Rand: Das Rauschen schiebt die Grenze nach innen oder
	// außen. Beim Pochen dehnt sich der Nebel etwas aus.
	float g = field(p) + (n - 0.5) * EDGE_WOBBLE - 0.05 * t;
	if (g > 1.0) {
		COLOR = vec4(0.0);
	} else {
		// Am Rand dichter (Nebelwand, damit man den Bereich erkennt), innen
		// dünner mit ziehenden Schwaden.
		float rim = smoothstep(0.5, 1.0, g);
		float density = rim * 0.55 + (n - 0.35) * 0.9 + 0.1 * t;
		// In 4 Stufen rastern, Zwischenwerte per Dithermuster.
		int bx = int(mod(p.x, 4.0));
		int by = int(mod(p.y, 4.0));
		float threshold = (BAYER[by * 4 + bx] + 0.5) / 16.0;
		float steps = clamp(density, 0.0, 0.999) * 3.0;
		int level = int(floor(steps)) + (fract(steps) > threshold ? 1 : 0);

		if (level <= 0) {
			COLOR = vec4(DEEP, (22.0 + 10.0 * t) / 255.0);
		} else if (level == 1) {
			COLOR = vec4(DEEP, (48.0 + 20.0 * t) / 255.0);
		} else if (level == 2) {
			COLOR = vec4(GHOST, (68.0 + 20.0 * t) / 255.0);
		} else {
			COLOR = vec4(PALE, (90.0 + 28.0 * t) / 255.0);
		}
	}
}
