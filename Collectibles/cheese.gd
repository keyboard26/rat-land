extends Area2D

var entered = false

func _on_body_entered(body: Node2D) -> void:
	if body.name == "Player":
		entered = true

func _on_body_exited(body: Node2D) -> void:
	if body.name == "Player":
		entered = false

func _process(_delta: float) -> void:
	if Input.is_key_pressed(KEY_C) and entered:
		if Game.playerHP < Game.maxHP:
			Game.playerHP += 1
		play_gulp()
		queue_free()


func play_gulp():
	var sfx = $CheeseGulp
	
	remove_child(sfx)
	get_tree().current_scene.add_child(sfx)
	sfx.global_position = global_position
	
	sfx.play()
	sfx.finished.connect(sfx.queue_free)
