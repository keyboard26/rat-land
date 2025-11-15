extends Node


# per scene dictionary of all mobs
var scene_mobs := {}


# initialization helper
func register_scene(scene_name: String, mobs: Array) -> void:
	if not scene_mobs.has(scene_name):
		scene_mobs[scene_name] = []
	
	var existing_mobs = scene_mobs[scene_name]
	
	for mob in mobs:
		# check if the mob is already there
		var mob_id = mob.get("id", null)
		var already_registered = false
		
		for existing_mob in existing_mobs:
			if existing_mob.get("id", null) == mob_id:
				already_registered = true
				break
		
		# only add if it's not already there
		if not already_registered:
			if mob.has("alive") and mob["alive"] == null:
				mob["alive"] = true
			scene_mobs[scene_name].append(mob.duplicate())



# spawns mobs into a parent node
func spawn_mobs(scene_name: String, parent_node: Node) -> Array:
	var spawned := []
	
	if not scene_mobs.has(scene_name):
		print("Not registered: ", scene_name)
		return spawned
	
	for mob_data in scene_mobs[scene_name]:
		# skip if has an alive key and is dead
		if mob_data.has("alive") and not mob_data["alive"]:
			continue
			
		# instantiate the mob
		var mob_instance = mob_data["scene"].instantiate()
		mob_instance.position = mob_data["pos"]
		if mob_data.has("scale"):
			mob_instance.scale = mob_data["scale"] # remove scale at some point =================================
		
		# connect "died" signal if the mob has it
		if mob_instance.has_signal("died") and mob_data.has("alive"):
			mob_instance.connect("died", Callable(self, "_on_mob_died").bind(scene_name, mob_data["id"]))

		
		parent_node.add_child(mob_instance)
		spawned.append(mob_instance)
	
	return spawned


# called when big mob dies
func _on_mob_died(scene_name: String, mob_id: String) -> void:
	if not scene_mobs.has(scene_name):
		return
	for mob_data in scene_mobs[scene_name]:
		if mob_data.get("id", "") == mob_id:
			mob_data["alive"] = false
			break


# respawn big mobs on player death
func respawn_big_mobs(scene_name: String) -> void:
	if not scene_mobs.has(scene_name):
		return
	for mob_data in scene_mobs[scene_name]:
		if mob_data.has("alive"):
			mob_data["alive"] = true
