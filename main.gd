extends Node2D


func _ready():
	Utils.saveGame()
	Utils.loadGame()


func _on_button_pressed() -> void:
	get_tree().change_scene_to_file("res://world.tscn")
	Game.playerHP = 5
	Game.coins = 0

func _on_quit_pressed() -> void:
	get_tree().quit()
