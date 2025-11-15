extends Node2D


var dustBunny = preload("res://Bunny/dust_bunny.tscn")

var scene_name = "world"
var spawned_bunnies := []

var normal_positions = [
	Vector2(827, 1045),
	Vector2(605, 695),
	Vector2(2425, 1039),
	Vector2(1285, 1033)
]

var big_positions = Vector2(1000, 1060)



func _ready() -> void:
	# list of mobs for the scene
	var mobs_to_register := [
		{ "id": "dust1", "scene": dustBunny, "pos": Vector2(827,1045)},
		{ "id": "dust2", "scene": dustBunny, "pos": Vector2(605, 695)},
		{ "id": "dust3", "scene": dustBunny, "pos": Vector2(2425, 1039)},
		{ "id": "dust4", "scene": dustBunny, "pos": Vector2(1285, 1033)},
		{ "id": "big1", "scene": dustBunny, "pos": Vector2(1000, 1060), "scale": Vector2(1.2,1.2), "alive": null}
	]
	
	MobManager.register_scene(scene_name, mobs_to_register)
	
	spawned_bunnies = MobManager.spawn_mobs(scene_name, self)
