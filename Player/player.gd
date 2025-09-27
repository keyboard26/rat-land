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
var knockback_timer = 0.0
var knockback_direction = 1
var is_dead = false
var was_on_floor = false
var fall_start_y = 0.0
var is_hit = false
var direction = 1
var invincible = false
var attack_success = false
var attack_type = ""
var currently_attack = false

@onready var anim = $"AnimationPlayer"

@onready var dash_timer =$"DashTimer"
@onready var dash_cooldown = $"DashCooldown"

@onready var forward_attack_zone = $ForwardAttackZone
@onready var up_attack_zone = $UpAttackZone
@onready var down_attack_zone = $DownAttackZone


func _ready() -> void:
	Game.player = self

func _physics_process(delta: float) -> void:
	if is_dead:
		return
		
	
	if is_hit:
		play_damage()
		anim.play("hurt flash")
		is_hit = false
		
	# Add the gravity.
	if not is_on_floor() and not down_dashing:
		velocity += get_gravity() * delta
	elif down_dashing:
		velocity.y += 100

	# Handle jump.
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = JUMP_VELOCITY
	
	if Input.is_action_just_released("ui_accept") and velocity.y < 0.0:
		velocity.y *= 0.5 

	
	# Wall Jumping + Sliding
	if is_on_wall_only() and not is_dashing and (Input.is_action_pressed("ui_right") or Input.is_action_pressed("ui_left")):
		# have to be pushing left or right to wall slide
		is_wall_sliding = true
		$WallSlide.volume_db = 1
	else:
		# else just fall down
		$WallSlide.volume_db = -10000
		is_wall_sliding = false
	
	
	if is_on_wall_only() and Input.is_action_just_pressed("ui_accept"):
		if Input.is_action_pressed("ui_right"):
			# jump left from right wall
			velocity.y = JUMP_VELOCITY
			wall_jump_pushback = 150
			wall_jump = true
		elif Input.is_action_pressed("ui_left"):
			# jump right from left wall
			velocity.y = JUMP_VELOCITY
			wall_jump_pushback = -150
			wall_jump = true
	
	if wall_jump == true and wall_jump_timer <= 0:
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
	
	
	if knockback_timer >0:
		# Apply knockback
		var kb_power
		if attack_success:
			kb_power = 50
		else:
			invincible = true
			kb_power = 300
		velocity.x = kb_power * knockback_direction
		knockback_timer -= delta
	elif wall_jump_timer > 0:
		velocity.x = -wall_jump_pushback
		wall_jump_timer -= delta
		invincible = false
	else:
		invincible = false
		if not is_dashing:
			direction = Input.get_axis("ui_left", "ui_right")

		if direction == -1:
			$"AnimatedSprite2D".flip_h = true
			forward_attack_zone.scale.x = -1
		elif direction == 1:
				$"AnimatedSprite2D".flip_h = false
				forward_attack_zone.scale.x = 1
				

		
		
		# Dash with a cooldown
		if Input.is_key_pressed(KEY_X) and can_dash:
			if Input.is_action_pressed("ui_down") and not is_on_floor():
				start_down_dash()
			else:
				start_dash()
		
		if direction or is_dashing and not down_dashing:
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
		else:
			velocity.x = move_toward(velocity.x, 0, speed)
			
	# to stop player from bouncing if they hit a wall while dashing
	if is_dashing and is_on_wall() and dash_timer.time_left < 0.28:
		dash_timer.emit_signal("timeout")
	
	if down_dashing and is_on_floor():
		dash_timer.emit_signal("timeout")
		
	
	
	if !currently_attack and !is_wall_sliding  and !is_dashing and knockback_timer <= 0:
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
	if currently_attack:
		anim.play(attack_type)
	elif knockback_timer > 0:
		anim.play("hurt flash")
	elif is_dashing:
		if down_dashing:
			anim.play("down-dash")
		else:
			anim.play("dash")
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
		anim.play("run")		
	else:
		anim.play("idle")
	
	
	
	# Player Dies
	if Game.playerHP <= 0:
		is_dead = true
		$DeathNoise.play()
		anim.play("death")
		await get_tree().create_timer(1).timeout
		get_tree().change_scene_to_file("res://main.tscn")
		
	if !is_dead:
		move_and_slide()
	
	# Landing sound
	if not was_on_floor and is_on_floor():
		$LandingSounds.play()
		
	was_on_floor = is_on_floor()
	

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
	is_dashing =false
	down_dashing = false
	dash_cooldown.start()

func _on_dash_cooldown_timeout() -> void:
	# flash so player knows when dash has cooled down
	#var tween = get_tree().create_tween()
	#tween.tween_property($"AnimatedSprite2D", "modulate:v", 1, 0.25).from(30)
	can_dash = true






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
		knockback_timer = 0.1
	elif terrain_hit != -1:
		$Attack.stream = hit_terrain[terrain_hit]
	else:
		var index = randi() % sword_missed.size()
		$Attack.stream = sword_missed[index]

	$Attack.play()
	await get_tree().create_timer(0.1).timeout
	attack_success = false


func terrain_was_hit(type):
	var bodies = $ForwardAttackZone.get_overlapping_bodies()
	if type == "forward":
		bodies = $ForwardAttackZone.get_overlapping_bodies()
		print(bodies)
	elif type == "up_air" or type == "up_ground":
		bodies = $UpAttackZone.get_overlapping_bodies()
		print(bodies)
	elif type == "down":
		bodies = $DownAttackZone.get_overlapping_bodies()
		print(bodies)

	for body in bodies:
		if body.name == "WoodenStuff":
			return 0
		elif body.name == "MetalStuff":
			return 1
	return -1
