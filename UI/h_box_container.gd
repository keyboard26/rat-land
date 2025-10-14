extends HBoxContainer


@export var full_heart : Texture
@export var empty_heart: Texture
@export var heart_particles: PackedScene


var hearts := []

func _ready():
	#clear any existing children just in case
	for child in get_children():
		child.queue_free()
	hearts.clear()
	
	#make one heart per health point
	for i in range(Game.maxHP):
		var heart = TextureRect.new()
		if i < Game.playerHP:
			heart.texture = full_heart
		else:
			heart.texture = empty_heart
		heart.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		heart.custom_minimum_size = Vector2(75, 75)
		add_child(heart)
		hearts.append(heart)
		
func _process(_delta: float) -> void:
	_update_hearts()

# update when health changes
func _update_hearts():
	# Add more hearts if maxHP has increased
	while hearts.size() < Game.maxHP:
		var heart = TextureRect.new()
		heart.texture = empty_heart
		heart.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		heart.custom_minimum_size = Vector2(75, 75)
		add_child(heart, true)
		move_child(heart, 0)
		hearts.insert(0, heart)
		_play_heart_particles(heart)
		
	# Update hearts and play particles only when newly gained
	for i in range(Game.maxHP):
		if i < Game.playerHP:
			if hearts[i].texture != full_heart:
				hearts[i].texture = full_heart
				
		else:
			hearts[i].texture = empty_heart


func _play_heart_particles(heart: TextureRect):
	if heart_particles:
		var node: Node2D = heart_particles.instantiate()
		heart.get_parent().add_child(node)
		
		var heart_center = heart.get_global_rect().get_center()
		node.global_position = heart_center
		
		var particles: CPUParticles2D = node.get_node("CPUParticles2D")
		
		if particles.one_shot:
			particles.restart()
		else:
			particles.emitting = true
		
		await get_tree().create_timer(0.5).timeout
		particles.queue_free()
