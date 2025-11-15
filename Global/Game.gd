extends Node

var player: CharacterBody2D = null 
var maxHP = 5
var playerHP = maxHP
var playerDamageAmount = 3
var playerDamageZone: Area2D
var playerDeaths = 0

var coins = 0
var showCoins = false

var respawnCoins = 0
var jelloBall: CharacterBody2D = null
var jb_scene

var changing_scene = false

var jelloPackets = 0

var big_mobs_alive := {} #dictionary keyed by scene name

var inventory
var inv_open = false



func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	inventory = load("res://inventory.tscn").instantiate()
	inventory.process_mode = Node.PROCESS_MODE_ALWAYS
	get_tree().root.add_child.call_deferred(inventory)
	inventory.hide()


func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("toggle_inventory"):
		if inv_open:
			print("call closed")
			close_inventory()
		elif !changing_scene:
			open_inventory()
			print("call open")




func change_scene(scene1: String, scene2: String) -> void:
	var spawn_pos = get_spawn_position(scene1, scene2)
	call_deferred("_do_scene_change", scene2, spawn_pos)


func _do_scene_change(scene2: String, spawn_pos: Vector2) -> void:
	# add loading screen
	changing_scene = true
	var loading = load("res://loading_screen.tscn").instantiate()
	get_tree().root.add_child(loading)
	
	# fade in loading screen
	var fade_rect = loading.get_node("ColorRect")
	var tween_in = get_tree().create_tween()
	tween_in.tween_property(fade_rect, "color:a", 1.0, 0.4)
	await tween_in.finished
	
	# detatch ball before scene change
	if jelloBall and jelloBall.get_parent():
		print("detatch ball")
		jelloBall.get_parent().remove_child(jelloBall)
		get_tree().root.add_child(jelloBall) # keep alive during scene switch
		jelloBall.hide()
	
	# change scene
	if player and player.get_parent():
		player.get_parent().remove_child(player)
	get_tree().change_scene_to_file("res://" + scene2 + ".tscn")
	await get_tree().process_frame
	# spawn player
	changing_scene = false
	spawn_player(spawn_pos)
	
	# reattach ball after scene change
	if jelloBall:
		if scene2 == jb_scene:
			while get_tree().current_scene == null:
				await get_tree().process_frame
			print("put the ball back")
			get_tree().current_scene.add_child(jelloBall)
			jelloBall.show()
	
	# fade out
	var tween_out = get_tree().create_tween()
	tween_out.tween_property(fade_rect, "color:a", 0.0, 0.4)
	await tween_out.finished
	# remove loading screen
	loading.queue_free()


func spawn_player(position: Vector2) -> void:
	if player == null:
		player = load("res://player/player.tscn").instantiate()
	player.position = position
	player.velocity = Vector2.ZERO
	player.show()
	
	while get_tree().current_scene == null:
		await get_tree().process_frame
		
	if get_tree().current_scene != null:
		await get_tree().process_frame
		var world = get_tree().current_scene
		world.add_child(player)
		
		get_cam_limits(get_tree().current_scene.name)
	
	player.get_node("Camera2D").make_current()




func spawn_ball(position: Vector2) -> void:
	if jelloBall == null:
		jelloBall = load("res://Collectibles/Jello Ball/jello_ball.tscn").instantiate()
		
		if get_tree().current_scene != null:
			await get_tree().process_frame
			var world = get_tree().current_scene
			world.add_child(jelloBall)
			
			jb_scene = fix_scene_names(get_tree().current_scene.name) 
		
	jelloBall.position = position
	jelloBall.show()	


func respawn(scene): 
	playerDeaths += 1
	# get rid of coins but in a fancy way but it's still ugly :(
	respawnCoins = coins
	var timerspeed = 0.05
	if coins < 6: timerspeed = 0.15
	for i in range(10):
		coins -= 1
		if coins <= 0: break
		await get_tree().create_timer(timerspeed).timeout
	coins = 0
	
	# add loading screen
	var loading = load("res://loading_screen.tscn").instantiate()
	get_tree().root.add_child(loading)
	# fade in loading screen
	var fade_rect = loading.get_node("ColorRect")
	var tween_in = get_tree().create_tween()
	tween_in.tween_property(fade_rect, "color:a", 1.0, 1)
	await tween_in.finished
	
	# add respawn ball thingy
	var ball_pos = Vector2(player.position.x, player.position.y - 25)
	spawn_ball(ball_pos)
	
	scene = fix_scene_names(scene)
	
	
	await get_tree().create_timer(.7).timeout
	
	# move the player
	player.position = get_spawn_position("respawn", scene)
	player.is_dead = false
	playerHP = maxHP
	player.respawn_triggered = false
	
	await get_tree().process_frame
	
	# respawn mobs
	var current_scene = get_tree().current_scene
	var current_name = fix_scene_names(current_scene.name)
	if current_scene:
		MobManager.respawn_big_mobs(current_name)
		
		if current_scene.has_node("Mobs"):
			var mobs_node = current_scene.get_node("Mobs")
			
			# delete all current mobs to prevent duplicates spawning
			for child in mobs_node.get_children():
				child.queue_free()
			mobs_node.spawned_bunnies = MobManager.spawn_mobs(current_name, mobs_node)
	
	# load screen fade out
	var tween_out = get_tree().create_tween()
	tween_out.tween_property(fade_rect, "color:a", 0.0, 0.4)
	await tween_out.finished
	# remove loading screen
	loading.queue_free()
	



func open_inventory():
	if inv_open: return
	
	var current = get_tree().current_scene
	if current.name == "main": return
	
	inv_open = true
	get_tree().paused = true
	
	# add to current scene
	if inventory.get_parent() != current:
		inventory.get_parent().remove_child(inventory)
		current.add_child(inventory)
	
	# fade in the inventory
	inventory.show()
	var fade = inventory.get_node("CenterContainer")
	var tween_in = inventory.create_tween()
	tween_in.tween_property(fade, "modulate:a", 1.0, 0.2)
	await tween_in.finished
	
	print("open")



func close_inventory():
	if !inv_open: return
	var fade = inventory.get_node("CenterContainer")
	
	# fade out inventory
	var tween_out = inventory.create_tween()
	tween_out.tween_property(fade, "modulate:a", 0.0, 0.2)
	await tween_out.finished
	
	inventory.hide()
	
	# detatch from current scene and add back to root
	var current = get_tree().current_scene
	if inventory.get_parent() == current:
		current.remove_child(inventory)
	get_tree().root.add_child(inventory)
	
	get_tree().paused = false
	inv_open = false
	print("close")


func get_spawn_position(scene1: String, scene2: String) -> Vector2:
	# respawning or re-opening the game puts the player
	# in the default start position for whatever
	# area they left off in
	if scene1 == "respawn" or scene1 == "main":
		if scene2 == "world":
			return Vector2(120, 1056)
		if scene2 == "world_2":
			return Vector2(2730, 1056)
	
	# positions when leaving starting area
	elif scene1 =="world":
		if scene2 == "world_2":
			return Vector2(20, 912)
		if scene2 == "fridge":
			return Vector2(144, 198)
	
	# positions when leaving world_2
	elif scene1 == "world_2":
		if scene2 == "world":
			return Vector2(2730, 1056)
		if scene2 == "uhhhh":
			return Vector2(0,0)
	
	return Vector2(0, 0) #backup just in case



func get_cam_limits(scene: String) -> void:		
	var player_cam = player.get_node("Camera2D")
	if scene == "World":
		player_cam.limit_top = 0
		player_cam.limit_right = 2750
		player_cam.limit_left = 0
	if scene == "world2":
		player_cam.limit_top = 730
		player_cam.limit_right = 1230
		player_cam.limit_left = 0
	if scene == "fridge":
		player_cam.limit_top = 20
		player_cam.limit_left = 40
		player_cam.limit_right = 705
		

func fix_scene_names(scene: String):
	if scene == "World": return "world"
	if scene == "world2": return "world_2"
	
	return scene
	
