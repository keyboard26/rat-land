extends CharacterBody2D



func _on_area_2d_area_entered(area: Area2D) -> void:
	if area == Game.playerDamageZone:
		if area.name == "DownAttackZone":
			Game.player.velocity.y = -300
		
		Game.coins += Game.respawnCoins
		$AnimatedSprite2D.play("shrink")
		if Game.respawnCoins > 0: play_sounds()
		
		await get_tree().create_timer(0.6).timeout
		
		queue_free()

var pickup_sounds = [
	preload("res://Collectibles/sounds/coin_collect1.wav"),
	preload("res://Collectibles/sounds/coin_collect2.wav"),
	preload("res://Collectibles/sounds/coin_collect3.wav")
]

func play_sounds():
	var sfx = $PickUp
	var index = randi() % pickup_sounds.size()
	var numsounds = 1
	
	# play more sounds for more coins
	if Game.respawnCoins > 5 and Game.respawnCoins < 20:
		numsounds = 2
	elif Game.respawnCoins > 20 and Game.respawnCoins < 50:
		numsounds = 4
	else:
		numsounds = 7
	
	for i in range(numsounds):
		index = randi() % pickup_sounds.size()
		sfx.stream = pickup_sounds[index]
		sfx.global_position = global_position
		sfx.play()
		
		await get_tree().create_timer(0.1).timeout
