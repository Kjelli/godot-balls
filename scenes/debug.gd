extends Node2D

func _ready() -> void:
	pass

func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("Restart"):
		get_tree().reload_current_scene()
	
