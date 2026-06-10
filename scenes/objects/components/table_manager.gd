extends Node

@onready var cue_ball := %CueBall
var active_moving_balls: Dictionary = {}

func _ready() -> void:
	EventBus.ball_movement_changed.connect(_on_ball_movement_changed)

func _on_ball_movement_changed(ball: Ball, is_moving: bool) -> void:
	if is_moving:
		active_moving_balls[ball] = true
	else:
		active_moving_balls.erase(ball)
	
	# If the dictionary is empty, absolute stillness has been achieved
	if active_moving_balls.is_empty():
		_handle_table_stopped()

func _handle_table_stopped() -> void:
	cue_ball.queue_ready()
