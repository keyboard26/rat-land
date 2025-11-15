extends Node2D


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.



func _on_area_2d_body_entered(body: Node2D) -> void:
	if body == Game.player:
		Game.change_scene("world", "world_2")
		


func _on_to_fridge_body_entered(body: Node2D) -> void:
	if body == Game.player:
		Game.change_scene("world", "fridge")
