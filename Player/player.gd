extends CharacterBody2D

const DASH_SPEED = 500
const CROUCH_SPEED = 150
const SPEED = 200.0
const JUMP_VELOCITY = -350.0
const CROUCH_JUMP = -225.0
const WALL_SLIDE_GRAVITY = 75

var is_wall_sliding = false
var wall_jump_timer = 0.0
var wall_jump = false
var wall_jump_pushback = 150
var speed = SPEED
var is_dashing = false
var can_dash = true
var dash_direction
var knockback_timer = 0.0
var knockback_direction = 1
var is_dead = false
var is_crouching = false
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
	if not is_on_floor():
		velocity += get_gravity() * delta

	# Handle jump.
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		if is_crouching:
			velocity.y = CROUCH_JUMP
		else:
			velocity.y = JUMP_VELOCITY
	
	# Wall Jumping + Sliding
	if is_on_wall() and not is_on_floor() and (Input.is_action_pressed("ui_right") or Input.is_action_pressed("ui_left")):
		# have to be pushing left or right to wall slide
		is_wall_sliding = true
		$WallSlide.volume_db = 1
	else:
		# else just fall down
		$WallSlide.volume_db = -10000
		is_wall_sliding = false
	
	
	if is_on_wall() and Input.is_action_just_pressed("ui_accept"):
		if Input.is_action_pressed("ui_right"):
			# jump left from right wall
			velocity.y = JUMP_VELOCITY
			wall_jump_pushback = 100
			wall_jump = true
		elif Input.is_action_pressed("ui_left"):
			# jump right from left wall
			velocity.y = JUMP_VELOCITY
			wall_jump_pushback = -100
			wall_jump = true
	
	if wall_jump == true and wall_jump_timer <= 0:
		# timer to allow pushback to work
		wall_jump = false
		wall_jump_timer = 0.2
	
	if is_wall_sliding:
		velocity.y += WALL_SLIDE_GRAVITY * delta
		velocity.y = min(velocity.y, WALL_SLIDE_GRAVITY)
	
	
	
	# stop falling if dashing
	if is_dashing:
		velocity.y = 0
	
	
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
				
		# Crouch logic
		if Input.is_action_pressed("ui_down") and is_on_floor():
			is_crouching = true
		elif Input.is_action_just_released("ui_down"):
			if try_uncrouch():
				is_crouching = false
			else:
				is_crouching = true
		elif not Input.is_action_just_pressed("ui_down"): 
			if try_uncrouch():
				is_crouching = false
			else:
				is_crouching = true
		
		
		# Dash with a cooldown
		if Input.is_key_pressed(KEY_X) and can_dash:
			start_dash()
		
		if direction or is_dashing:
			if is_crouching:
				if is_dashing:
					speed = DASH_SPEED * 0.75
				else:
					speed = CROUCH_SPEED
				set_collision(20, 10, -10)
			else:
				if is_dashing:
					speed = DASH_SPEED
				else:
					speed = SPEED
				set_collision(34, 10, -17)
			
			if is_dashing:
				if is_wall_sliding:
					dash_direction *= -1
					direction = dash_direction
				velocity.x = dash_direction * speed
			else:
				velocity.x = direction * speed

		else:
			velocity.x = move_toward(velocity.x, 0, speed)
			
	if !currently_attack and !is_wall_sliding and !is_crouching and !is_dashing and knockback_timer <= 0:
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
		if is_crouching:
			anim.play("run-crouch")
		else:
			anim.play("run")		
	else:
		if is_crouching:
			anim.play("idle-crouch")
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
		if is_crouching:
			$LandingSounds.volume_db = -10
		else:
			$LandingSounds.volume_db = 0
		$LandingSounds.play()
		
	was_on_floor = is_on_floor()
	

func handle_attack():
	toggle_damage_collisions(attack_type)

	
	

func toggle_damage_collisions(type):
	var damage_zone_collision: CollisionShape2D
	if type == "forward":
		damage_zone_collision = $ForwardAttackZone/CollisionShape2D
		Game.playerDamageZone = $ForwardAttackZone
	if type == "up":
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

func _on_dash_timer_timeout() -> void:
	is_dashing =false
	dash_cooldown.start()

func _on_dash_cooldown_timeout() -> void:
	# flash so player knows when dash has cooled down
	var tween = get_tree().create_tween()
	tween.tween_property($"AnimatedSprite2D", "modulate:v", 1, 0.25).from(30)
	can_dash = true


func try_uncrouch():	
	#temporarily set collision shape to standing height
	set_collision(34, 10, -17)
	
	var blocked = test_move(global_transform, Vector2.ZERO)
	
	if blocked:
		#go back to crouching
		set_collision(20, 10, -10)
		is_crouching = true
		return false
	else:
		#uncrouch
		is_crouching = false
		return true
		
# change collision shape when (un)crouching
func set_collision(height:float, radius:float, y_offset: float) -> void:
	$CollisionShape2D.shape.height = height
	$CollisionShape2D.shape.radius = radius
	$CollisionShape2D.position.y = y_offset



# Sound Effect Stuff
var footsteps_sounds = [
	preload("res://Player/audio/steps/hero_fluke_bounce_6.wav"),
	preload("res://Player/audio/steps/hero_fluke_bounce_7.wav"),
	preload("res://Player/audio/steps/hero_fluke_bounce_8.wav"),
	preload("res://Player/audio/steps/hero_fluke_bounce_9.wav")
]
func play_footstep():
	if is_crouching:
		$Footsteps.volume_db = -8
	else: 
		$Footsteps.volume_db = 0
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
	if is_crouching:
		$Jump.volume_db = -10
	else: 
		$Jump.volume_db = 0
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
	
var sword_noise = [
	preload("res://Player/audio/sword slash hit.wav"),
	preload("res://Player/audio/sword slash miss.wav")
]

func play_slash():
	var index = 1
	#add something to tell if the attack hit or not
	if attack_success:
		index=0
		knockback_timer = 0.1
	$Attack.stream = sword_noise[index]
	$Attack.play()
	
	await get_tree().create_timer(0.1).timeout
	attack_success = false
