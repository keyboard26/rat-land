extends CharacterBody2D



var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")
var was_on_floor = true


func _ready():
	# so it only collides with the ground
	velocity = Vector2(randf_range(-300,300), randf_range(-200,-150))



func _physics_process(delta):
	if not is_on_floor():
		velocity.y += gravity * delta
	else:
		# Apply friction when on the floor
		velocity.x = lerp(velocity.x, 0.0, 0.1)
	
	move_and_slide()
	
	if not was_on_floor and is_on_floor():
		play_drop()
	
	was_on_floor = is_on_floor()

func _on_area_2d_body_entered(body: Node2D) -> void:
	if body == Game.player:
		Game.coins += 1

		play_pickup()
		queue_free()


var pickup_sounds = [
	preload("res://Collectibles/sounds/coin_collect1.wav"),
	preload("res://Collectibles/sounds/coin_collect2.wav"),
	preload("res://Collectibles/sounds/coin_collect3.wav")
]
# over complicated and weird but now the sound plays and
# the coin disappears imeadiately
func play_pickup():
	var index = randi() % pickup_sounds.size()
	
	var sfx = $PickUp
	sfx.stream = pickup_sounds[index]
	
	remove_child(sfx)
	get_tree().current_scene.add_child(sfx)
	sfx.global_position = global_position
	
	sfx.play()
	sfx.finished.connect(sfx.queue_free)


var drop_sounds = [
	preload("res://Collectibles/sounds/coindrop1.wav"),
	preload("res://Collectibles/sounds/coindrop2.wav"),
	preload("res://Collectibles/sounds/coindrop3.wav"),
]
func play_drop():
	#okay and now the actual sounds can play
	var index = randi() % drop_sounds.size()
	
	var sfx = AudioStreamPlayer2D.new()
	sfx.global_position = self.global_position
	sfx.stream = drop_sounds[index]
	
	get_tree().current_scene.add_child(sfx)
	sfx.global_position = global_position
	
	sfx.play()
	sfx.finished.connect(sfx.queue_free)
