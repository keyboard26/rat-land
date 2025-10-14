extends Area2D


var newHeart = preload("res://Collectibles/sounds/new_packet.wav")
var packetNoise = preload("res://Collectibles/sounds/packet_noise.wav")
var entered = false
var bigNoise = false
var gotten =  false

func _on_body_entered(body: Node2D) -> void:
	if body == Game.player:
		entered = true

func _on_body_exited(body: Node2D) -> void:
	if body == Game.player:
		entered = false

func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("ui_up") and entered and !gotten:
		gotten = true
		Game.jelloPackets += 1
		Game.player.pickup_item = true
		if Game.jelloPackets == 3:
			bigNoise = true
			Game.jelloPackets = 0
			Game.maxHP += 1
			Game.playerHP += 1
		
		await get_tree().create_timer(0.45).timeout
		play_sound()
		queue_free()


func play_sound():
	# normal sound
	var sfx1 = AudioStreamPlayer2D.new()
	sfx1.stream = packetNoise
	sfx1.global_position = global_position
	get_tree().current_scene.add_child(sfx1)
	sfx1.play()
	sfx1.finished.connect(func(): sfx1.queue_free())

	# big sound if collected 3 jello packets
	if bigNoise:
		var sfx2 = AudioStreamPlayer2D.new()
		sfx2.volume_db = -5
		sfx2.stream = newHeart
		sfx2.global_position = global_position
		get_tree().current_scene.add_child(sfx2)
		sfx2.play()
		sfx2.finished.connect(func(): sfx2.queue_free())
	
