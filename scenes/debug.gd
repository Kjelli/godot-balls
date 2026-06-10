extends Node2D

func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("Restart"):
		get_tree().reload_current_scene()
	
	var cue_ball := %CueBall
	var sum_speed = get_total_speed()
	if sum_speed == 0:
		cue_ball.set_ready()
	
func get_total_speed() -> float:
	if not get_tree():
		return -1
		
	var total_speed: float = 0.0
	var balls = get_tree().get_nodes_in_group("Balls")
	
	for ball in balls:
		if ball is CharacterBody2D:
			total_speed += ball.velocity.length()
			
	return total_speed
