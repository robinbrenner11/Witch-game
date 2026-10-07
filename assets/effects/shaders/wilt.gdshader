shader_type canvas_item;

// Welken unter der Nachtschatten-Kuppel: Die Pflanze wird entsättigt und
// kühl-dunkel eingefärbt. Ein Shader statt nur modulate, weil modulate nur
// multiplizieren, aber keine Farbe herausnehmen kann.

// Richtwert aus den Design-Entscheidungen. source_color sorgt dafür, dass
// der Farbwähler im Inspector richtig rechnet.
uniform vec3 tint : source_color = vec3(0.55, 0.62, 0.85);

void fragment() {
	// COLOR enthält hier schon die Texturfarbe.
	float gray = dot(COLOR.rgb, vec3(0.299, 0.587, 0.114));
	COLOR.rgb = vec3(gray) * tint;
}
