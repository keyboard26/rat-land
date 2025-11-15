extends Node2D


func _ready():
	#Utils.saveGame()
	#Utils.loadGame()
	$MainMenuCam.make_current()


func _on_button_pressed() -> void:
	Game.change_scene("main", "world")
	
	await get_tree().create_timer(0.4).timeout
	Ui.show()
	
func _on_quit_pressed() -> void:
	get_tree().quit()
