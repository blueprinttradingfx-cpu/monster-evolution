extends Control
## ProceduralCreatureIcon.gd
## Generates a monster visual using shapes and shaders.

@onready var shape: TextureRect = $Shape
@onready var particles: CPUParticles2D = $Particles

func setup(data: Resource) -> void:
	if not data: return

	# Safety check for @onready nodes in case setup is called before _ready (e.g. during instantiation)
	if not shape:
		shape = get_node_or_null("Shape")
	if not particles:
		particles = get_node_or_null("Particles")

	if not shape:
		push_error("[ProceduralCreatureIcon] Required node 'Shape' not found.")
		return

	# 1. Set Shape (we'd ideally have 4-5 basic png shapes)
	# For now, we'll use the symbol if art is missing, or a fallback blob
	# shape.texture = PerformanceLayer.get_asset(data.visual_style.get("shape", "blob"))

	# 2. Apply Shader Palette
	var mat = shape.material as ShaderMaterial
	if mat:
		var archetype_color = _get_archetype_color(data.archetype)
		mat.set_shader_parameter("base_color", archetype_color)

		# More glow for higher tiers
		if data.tier >= 3:
			mat.set_shader_parameter("glow_intensity", 1.5)
			mat.set_shader_parameter("glow_color", Color.WHITE)
			particles.emitting = true
		else:
			mat.set_shader_parameter("glow_intensity", 0.0)
			particles.emitting = false

func _get_archetype_color(archetype: String) -> Color:
	match archetype:
		"Egg": return Color.ANTIQUE_WHITE
		"Blob": return Color.SKY_BLUE
		"Slime": return Color.LIME_GREEN
		"Beast": return Color.ORANGE_RED
		"Dino": return Color.DARK_SLATE_GRAY
		"Dragon": return Color.GOLD
		"Cosmic": return Color.MEDIUM_PURPLE
		_: return Color.WHITE
