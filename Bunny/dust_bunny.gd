extends CharacterBody2D

const SPEED = 100
var damage = 1
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")
var chase = false
var player
var player_can_attack = false
var dead = false
var health = 9
var max_health = 9
var is_roaming: bool
var knockback_timer = 0.0
var knockback_direction = 1

var player_in_range = false
var attack_timer = 0.0
var attack_cooldown = 0.5

@onready var anim = get_node("AnimationPlayer")
@onready var collision1 = $PlayerCollision.get_node("CollisionShape2D")

func _ready() -> void:
	if Game.player != null:
		player = Game.player

func _physics_process(delta):
	if !dead:
		is_roaming = true
		if chase and knockback_timer <= 0:
			if is_on_floor():
				velocity.y = -200
			else:
				velocity.y += gravity * delta
			if anim.current_animation != "death":
				anim.play("run")
			var direction = (player.position - self.position).normalized()
			if direction.x > 0:
				get_node("AnimatedSprite2D").flip_h = false
			else:
				get_node("AnimatedSprite2D").flip_h = true
			velocity.x = direction.x * SPEED
		elif knockback_timer > 0 and !dead:
			knockback_direction = position.direction_to(player.position) * -200
			velocity.x = knockback_direction.x
			velocity.y += 10 * delta
			knockback_timer -= delta
		else:
			velocity.x = 0
			velocity.y += gravity * delta * 20
			if anim.current_animation != "death":
				anim.play("idle")
	else:
		velocity.y += 50 * delta
		
	move_and_slide()
	
	if player.is_dead:
		chase = false
		player_in_range = false
	
	# attack the player
	if player_in_range and not player.is_dead:
		attack_timer -= delta
		if attack_timer <= 0 and !player.invincible:
			attack_timer = attack_cooldown
			var push_dir = sign(player.position.x - position.x)
			player.is_hit = true
			player.do_knockback(damage, push_dir)


func _on_bunny_hit_box_area_entered(area: Area2D) -> void:
	if area == Game.playerDamageZone and !dead:
		var damage_taken = Game.playerDamageAmount
		take_damage(damage_taken)
		if area.name == "DownAttackZone":
			Game.player.velocity.y = -300
		if area.name == "UpAttackZone":
			velocity.y = -150


func _on_player_collision_body_entered(body: Node2D) -> void:
	if body == player:
		player_in_range = true
		attack_timer = 0

func _on_player_collision_body_exited(body: Node2D) -> void:
	if body == player:
		player_in_range = false

func take_damage(damage_):
	health -= damage_
	player.attack_success = true
	var push_dir
	
	if player.position.x < self.position.x:
		push_dir = -1
	else:
		push_dir = 1
	
	player.knockback_direction = push_dir
		
	knockback_timer = 0.25
	anim.play("knockback")
	if health <= 0:
		health = 0
		dead = true
		die()


func _on_area_2d_body_entered(body):
	if body == player:
		play_short_squeak()
		chase = true


func _on_area_2d_body_exited(body):
	if body == player:
		var keep_chase = false
		await get_tree().create_timer(2).timeout
		
		for o_body in $AggroArea.get_overlapping_bodies():
			if o_body == player:
				keep_chase = true
		
		if !keep_chase:
			chase = keep_chase
		


func die():
	collision1.set_deferred("disabled", true)

	dead = true
	Utils.saveGame()
	drop_coins(5)
	play_squeak()
	anim.play("death")
	await get_tree().create_timer(0.3).timeout
	self.queue_free()



		


var Coins = preload("res://Collectibles/Coin/coin.tscn")

func drop_coins(amount: int):
	for i in range(amount):
		var coin = Coins.instantiate()
		var ran = randi_range(-15, 15)
		coin.global_position = global_position + Vector2(ran, -20)
		get_parent().call_deferred("add_child", coin)
		
		




# Sound Effects
var squeaks = [
	preload("res://Bunny/sounds/squeak1.wav"),
	preload("res://Bunny/sounds/squeak2.wav"),
	preload("res://Bunny/sounds/squeak3.wav")
]

func play_squeak():
	var index = randi() % squeaks.size()
	$Squeaks.volume_db = 1
	$Squeaks.stream = squeaks[index]
	$Squeaks.play()
	
var short_squeaks = [
	preload("res://Bunny/sounds/shortsqueak1.wav"),
	preload("res://Bunny/sounds/shortsqueak2.wav")
]

func play_short_squeak():
	var index = randi() % short_squeaks.size()
	$Squeaks.volume_db = 1
	$Squeaks.stream = short_squeaks[index]
	$Squeaks.play()
	

var steps = [
	preload("res://Bunny/sounds/bunnystep1.wav"),
	preload("res://Bunny/sounds/bunnystep2.mp3"),
	preload("res://Bunny/sounds/bunnystep3.wav")
]

func play_steps():
	var index = randi() % steps.size()
	$Steps.volume_db = 10
	$Steps.stream = steps[index]
	$Steps.play()
