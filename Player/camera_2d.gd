extends Camera2D


var timer = 0
var looking_down = false

func _process(delta: float) -> void:
	if Input.is_action_pressed("ui_down"):
		timer += delta
	elif Input.is_action_just_released("ui_down"):
		timer = 0
	
	if timer >= 0.5 and !looking_down:
		if Game.player.velocity.is_zero_approx():
			look_down()
		else:
			timer = 0


func look_down():
	looking_down = true
	Game.player.looking_down = true
	var tween = get_tree().create_tween()
	tween.tween_property(self, "offset", Vector2(0, 20), 0.3)
	
	while true:
		if Input.is_action_just_released("ui_down") or not Game.player.velocity.is_zero_approx():
			break
		await get_tree().process_frame
	var tween2 = get_tree().create_tween()
	tween2.tween_property(self, "offset", Vector2(0, -40), 0.3)
	looking_down = false
	Game.player.looking_down = false
