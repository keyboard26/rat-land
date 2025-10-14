extends Node2D

func _ready() -> void:
	hide()
	$AnimatedSprite2D.hide()

func slash_anim():
	show()
	$AnimatedSprite2D.show()
	$AnimatedSprite2D.play("slash")
	await get_tree().create_timer(0.2).timeout
	$AnimatedSprite2D.hide()
