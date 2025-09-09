extends CharacterBody2D

const SPEED = 50
var damage = 1
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")
var chase = false
var player
@onready var anim = get_node("AnimationPlayer")
@onready var anim_sprite = $AnimatedSprite2D

func _physics_process(delta):
	#Gravity for frog
	velocity.y += gravity * delta
	if chase == true:
		if anim_sprite.animation != "death":
			anim_sprite.play("run")
		player = get_node("../../Player/Player")
		var direction = (player.position - self.position).normalized()
		if direction.x > 0:
			anim_sprite.flip_h = false
		else:
			anim_sprite.flip_h = true
		velocity.x = direction.x * SPEED
	else:
		velocity.x = 0
		if anim_sprite.animation != "death":
			anim_sprite.play("idle")
	move_and_slide()


func _on_area_2d_body_entered(body):
	if body.name == "Player":
		chase = true


func _on_area_2d_body_exited(body):
	if body.name == "Player":
		chase = false


func _on_slime_death_body_entered(body: Node2D) -> void:
	if body.name == "Player":
		chase = false
		Utils.saveGame()
		drop_coins(5)
		anim_sprite.play("death")
		body.velocity.y = -300
		await get_tree().create_timer(0.25).timeout
		self.queue_free()
		
		


func _on_player_collision_body_entered(body: Node2D) -> void:
	if body.name == "Player":
		Game.playerHP -= damage
		
		var push_dir
		if body.position.x < self.position.x:
			push_dir = -1
		else:
			push_dir = 1
		if damage <= Game.playerHP:
			body.is_hit = true
		
		body.knockback_direction = push_dir
		body.knockback_timer = 0.3
		body.velocity.y = -200

var Coins = preload("res://Collectibles/coin.tscn")

func drop_coins(amount: int):
	for i in range(amount):
		var coin = Coins.instantiate()
		var ran = randi_range(-50, 50)
		coin.global_position = global_position + Vector2(ran, -50)
		get_parent().call_deferred("add_child", coin)
		
		
		
