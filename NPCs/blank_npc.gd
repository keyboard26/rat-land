extends CharacterBody2D

var can_interact = false
var is_interacting = false

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	$ColorRect.hide()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	# make it face the character
	var direction = (Game.player.position - self.position).normalized()
	if direction.x > 0:
		$AnimatedSprite2D.flip_h = false
	else:
		$AnimatedSprite2D.flip_h = true
	
	
	if can_interact and Input.is_action_just_pressed("ui_up") and !is_interacting:
		is_interacting = true
		interact()

func interact():
	$ColorRect/arrow.hide()
	$ColorRect.show()
	print("yippee")
	$AnimatedSprite2D.play("talk")
	$ColorRect/Label.text = "hello i am mr blob!"
	await get_tree().create_timer(1.5).timeout
	$ColorRect/arrow.show()
	$AnimatedSprite2D.play("default")
	
	while true:
		if Input.is_action_just_pressed("ui_up"):
			break
		await get_tree().process_frame
	
	$AnimatedSprite2D.play("talk")
	$ColorRect/Label.text = "yay second text woohoo"
	await get_tree().create_timer(2).timeout
	
	$ColorRect.hide()


func _on_interact_range_body_entered(body: Node2D) -> void:
	if body == Game.player:
		can_interact = true


func _on_interact_range_body_exited(body: Node2D) -> void:
	if body == Game.player:
		can_interact = false
