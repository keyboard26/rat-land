extends CharacterBody2D

const DASH_SPEED = 450
const SPEED = 200.0
const JUMP_VELOCITY = -400.0
const WALL_SLIDE_GRAVITY = 75

var is_wall_sliding = false
var wall_jump_timer = 0.0
var wall_jump = false
var wall_jump_pushback = 150
var speed = SPEED
var is_dashing = false
var can_dash = true
var down_dashing = false
var dash_direction
var knockback_direction = 1
var knockback = false
var is_dead = false
var was_on_floor = false
var fall_start_y = 0.0
var is_hit = false
var direction = 1
var prev_direction = 1
var invincible = false
var attack_success = false
var attack_type = "forward"
var currently_attack = false
var looking_down = false
var respawn_triggered = false

var pickup_item = false
var picking_up = false

@onready var anim = $"AnimationPlayer"

@onready var dash_timer =$"DashTimer"
@onready var dash_cooldown = $"DashCooldown"
@onready var knockback_timer = $"KnockbackTimer"

@onready var forward_attack_zone = $ForwardAttackZone
@onready var up_attack_zone = $UpAttackZone
@onready var down_attack_zone = $DownAttackZone


func _ready() -> void:
	visible = true
	
	#while true:
		#print("playerHP:", Game.playerHP, " / maxHP:", Game.maxHP)
		#await get_tree().create_timer(3).timeout

func _physics_process(delta: float) -> void:
	if Game.changing_scene:
		velocity.x = SPEED * direction
		move_and_slide()
		return
	
	if pickup_item:
		if !picking_up: item_pickup()
		velocity.x = 0
		velocity.y = 0
		anim.play("pick-up")
		return
	
	if is_hit and !is_dead:
		play_damage()
		anim.play("hurt")
		is_hit = false
	
	# Add the gravity.
	if not is_on_floor() and not down_dashing:
		velocity += get_gravity() * delta
	elif down_dashing:
		velocity.y += 40
	
	# Handle jump.
	if Input.is_action_just_pressed("ui_accept") and is_on_floor() and !is_dead:
		velocity.y = JUMP_VELOCITY
	
	if Input.is_action_just_released("ui_accept") and velocity.y < 0.0 and !is_dead:
		velocity.y *= 0.5 
	
	
	# Wall Jumping + Sliding
	if is_on_wall_only() and not is_dashing and (Input.is_action_pressed("ui_right") or Input.is_action_pressed("ui_left")) and !is_dead:
		# have to be pushing left or right to wall slide
		is_wall_sliding = true
		$WallSlide.volume_db = 1
	else:
		# else just fall down
		$WallSlide.volume_db = -10000
		is_wall_sliding = false
	
	
	if is_on_wall_only() and Input.is_action_just_pressed("ui_accept") and knockback_timer.time_left <= 0 and !is_dead:
		if Input.is_action_pressed("ui_right") and !is_dead:
			# jump left from right wall
			velocity.y = JUMP_VELOCITY
			wall_jump_pushback = 150
			wall_jump = true
		elif Input.is_action_pressed("ui_left") and !is_dead:
			# jump right from left wall
			velocity.y = JUMP_VELOCITY
			wall_jump_pushback = -150
			wall_jump = true
	
	if wall_jump and wall_jump_timer <= 0:
		# timer to allow pushback to work
		wall_jump = false
		wall_jump_timer = 0.2
	
	if is_wall_sliding:
		velocity.y += WALL_SLIDE_GRAVITY * delta
		velocity.y = min(velocity.y, WALL_SLIDE_GRAVITY)	
	
	# stop falling if dashing
	if is_dashing and not down_dashing:
		velocity.y = 0
	elif down_dashing:
		velocity.x = 0
	
	if knockback:
		# Apply knockback
		var kb_power
		if attack_success:
			kb_power = 50
		else:
			kb_power = 300
		velocity.x = kb_power * knockback_direction
	elif wall_jump_timer > 0:
		velocity.x = -wall_jump_pushback
		wall_jump_timer -= delta
	else:
		if not is_dashing:
			direction = Input.get_axis("ui_left", "ui_right")

		if direction == -1:
			$"AnimatedSprite2D".flip_h = true
			$Effects/AnimatedSprite2D.flip_h = true
			forward_attack_zone.scale.x = -1
		elif direction == 1:
			$"AnimatedSprite2D".flip_h = false
			$Effects/AnimatedSprite2D.flip_h = false
			forward_attack_zone.scale.x = 1
				
		
		# Dash with a cooldown
		if Input.is_action_just_pressed("dash") and can_dash and !is_dead:
			if Input.is_action_pressed("ui_down") and not is_on_floor():
				velocity.x = 0
				start_down_dash()
			else:
				start_dash()
		
		if direction or is_dashing and not down_dashing and !is_dead:
			if is_dashing:
				speed = DASH_SPEED
			else:
				speed = SPEED
			
			if is_dashing and not down_dashing:
				if is_wall_sliding:
					dash_direction *= -1
					direction = dash_direction
				velocity.x = dash_direction * speed
			else:
				velocity.x = direction * speed
		elif down_dashing:
			velocity.x = 0
		else:
			velocity.x = move_toward(velocity.x, 0, speed)
			
	# to stop player from bouncing if they hit a wall while dashing
	if is_dashing and is_on_wall() and dash_timer.time_left < 0.28:
		dash_timer.emit_signal("timeout")
	
	if down_dashing and is_on_floor():
		dash_timer.emit_signal("timeout")
		
	
	
	if !currently_attack and !is_wall_sliding  and !is_dashing and !knockback and !is_dead:
		if Input.is_action_just_pressed("player_attack"):
			currently_attack = true
			if !is_on_floor() and Input.is_action_pressed("ui_down"):
				attack_type = "down"
			elif Input.is_action_pressed("ui_up"):
				if is_on_floor():
					attack_type = "up_ground"
				else:
					attack_type = "up_air"
			else:
				attack_type = "forward"
			handle_attack()
		
	
	#Animations
	if !is_dead:
		if currently_attack:
			anim.play(attack_type)
		elif knockback:
			anim.play("hurt")
		elif is_dashing:
			if down_dashing:
				anim.play("down-dash")
			else:
				anim.play("dash")
		elif down_dashing:
			anim.play("down-dash-reset")
		elif is_wall_sliding:
			# had to switch to using this bc the jump/fall
			#	animations would play over this
			$"AnimatedSprite2D".animation = "wall-slide"
			anim.play("wall-slide") # this is so the sounds play correctly
		elif not is_on_floor():
			if was_on_floor and velocity.y >= 0:
				# Walking off a ledge, start falling immediately
				anim.play("fall")
			elif velocity.y < 0:
				anim.play("jump")
			else:
				anim.play("fall")
		elif abs(velocity.x) > 0:
			if prev_direction != direction:
				anim.play("front")
				prev_direction = direction
				await get_tree().process_frame
				anim.play("run")
			else:
				anim.play("run")
		else:
			if looking_down:
				anim.play("look-down")
			else:
				anim.play("idle")
		
	# Landing sound
	if not was_on_floor and is_on_floor():
		$LandingSounds.play()
		
	was_on_floor = is_on_floor()
	
	
	if !is_dead:
		move_and_slide()
	
	
	# Player Dies
	if Game.playerHP <= 0 and !is_dead:
		is_dead = true
		$DeathNoise.play()
		anim.play("death")
		velocity.x = 150 * -direction
		velocity.y = -100
		
	if is_dead:
		velocity.y += 50 * delta
		velocity.x = move_toward(velocity.x, 0, 20*delta)
		
		move_and_slide()
	
		if is_on_floor() and !respawn_triggered:
			respawn_triggered = true
			
			await get_tree().create_timer(0.5).timeout
			Game.respawn(get_tree().current_scene.name)

func item_pickup():
	picking_up = true
	await get_tree().create_timer(1).timeout
	pickup_item = false
	picking_up = false

func handle_attack():
	play_slash(attack_type)
	toggle_damage_collisions(attack_type)


func toggle_damage_collisions(type):
	var damage_zone_collision: CollisionShape2D
	if type == "forward":
		damage_zone_collision = $ForwardAttackZone/CollisionShape2D
		Game.playerDamageZone = $ForwardAttackZone
	if type == "up_air" or type == "up_ground":
		damage_zone_collision = $UpAttackZone/CollisionShape2D
		Game.playerDamageZone = $UpAttackZone
	elif type == "down":
		damage_zone_collision = $DownAttackZone/CollisionShape2D
		Game.playerDamageZone = $DownAttackZone
	
	if damage_zone_collision:
		damage_zone_collision.disabled = false
		await get_tree().create_timer(0.25).timeout
		damage_zone_collision.disabled = true
		currently_attack = false
	else:
		await get_tree().create_timer(0.25).timeout
		currently_attack = false
		attack_type = ""



func start_dash():
	is_dashing = true
	can_dash = false
	$WhooshSound.play()
	dash_timer.start()
	
	var input_dir := Input.get_axis("ui_left", "ui_right")
	if input_dir != 0:
		dash_direction = input_dir
	else:
		if $AnimatedSprite2D.flip_h:
			dash_direction = -1
		else:
			dash_direction = 1

func start_down_dash():
	is_dashing = true
	down_dashing = true
	can_dash = false
	$WhooshSound.play()
	dash_timer.start()
	

func _on_dash_timer_timeout() -> void:
	is_dashing = false
	dash_cooldown.start()
	if down_dashing:
		await get_tree().create_timer(0.12).timeout
		down_dashing =  false

func _on_dash_cooldown_timeout() -> void:
	#wait until the player has touched the ground/wall before letting them dash again
	while !is_on_floor():
		await get_tree().process_frame
		if is_wall_sliding:
			break
	can_dash = true
	
	
func do_knockback(damage, push_dir):
	if invincible or is_dead:
		return
	
	# apply damage and hit effects
	Game.playerHP -= damage
	if Game.playerHP > 0:
		is_hit = true
	
	knockback_direction = push_dir	
	knockback = true
	invincible = true
	
	
	knockback_timer.start()
	
	if !is_dead:
		velocity.y = -200


func _on_knockback_timer_timeout() -> void:
	knockback = false
	# player is invincible longer than the knockback lasts
	await get_tree().create_timer(0.5).timeout
	invincible = false



# Sound Effect Stuff
var footsteps_sounds = [
	preload("res://Player/audio/steps/hero_fluke_bounce_6.wav"),
	preload("res://Player/audio/steps/hero_fluke_bounce_7.wav"),
	preload("res://Player/audio/steps/hero_fluke_bounce_8.wav"),
	preload("res://Player/audio/steps/hero_fluke_bounce_9.wav")
]
func play_footstep():
	
	var index = randi() % footsteps_sounds.size()
	$Footsteps.stream = footsteps_sounds[index]
	$Footsteps.play()


var damage_sounds = [
	preload("res://Player/audio/damage/damage1.wav"),
	preload("res://Player/audio/damage/damage1.wav"),
	preload("res://Player/audio/damage/damage2.wav"),
	preload("res://Player/audio/damage/damage2.wav"),
	preload("res://Player/audio/damage/damage3.wav")
]
func play_damage():
	$Damage.pitch_scale = 1.5
	var index = randi() % damage_sounds.size()
	$Damage.stream = damage_sounds[index]
	$Damage.play()


func flash_white():
	var tween: Tween = create_tween()
	tween.tween_property($AnimatedSprite2D, "modulate:v", 1, 0.25).from(20)
	



func play_jump():
	$Jump.play()


var wall_slides = [
	preload("res://Player/audio/wall slide/wallslide1.wav"),
	preload("res://Player/audio/wall slide/wallslide2.wav"),
	preload("res://Player/audio/wall slide/wallslide3.wav"),
	preload("res://Player/audio/wall slide/wallslide4.wav")
]
func play_wall_slide():
	var index = randi() % wall_slides.size()
	$WallSlide.stream = wall_slides[index]
	$WallSlide.play()




var sword_missed = [
	preload("res://Player/audio/attacks/missed/sword_1.wav"),
	preload("res://Player/audio/attacks/missed/sword_2.wav"),
	preload("res://Player/audio/attacks/missed/sword_3.wav"),
	preload("res://Player/audio/attacks/missed/sword_4.wav"),
]

var hit_enemy = [
	preload("res://Player/audio/attacks/hit enemies/hit.wav")
]

var hit_terrain = [
	preload("res://Player/audio/attacks/hit terrain/hit_wood.wav"),
	preload("res://Player/audio/attacks/hit terrain/metal_hit.wav")
]

func play_slash(type):
	var terrain_hit = terrain_was_hit(type)
	
	if attack_success:
		$Attack.stream = hit_enemy[0]
		# put in some minor knockback here ===============================================================================================================
	elif terrain_hit != -1:
		$Attack.stream = hit_terrain[terrain_hit]
	else:
		var index = randi() % sword_missed.size()
		$Attack.stream = sword_missed[index]

	$Attack.play()
	await get_tree().create_timer(0.1).timeout
	attack_success = false

# this does not work :D ======================================================
func terrain_was_hit(type): 
	var bodies = $ForwardAttackZone.get_overlapping_bodies()
	if type == "forward":
		bodies = $ForwardAttackZone.get_overlapping_bodies()
	elif type == "up_air" or type == "up_ground":
		bodies = $UpAttackZone.get_overlapping_bodies()
	elif type == "down":
		bodies = $DownAttackZone.get_overlapping_bodies()

	for body in bodies:
		if body.name == "WoodenStuff":
			return 0
		elif body.name == "MetalStuff":
			return 1
	return -1
