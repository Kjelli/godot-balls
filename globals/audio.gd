extends Node2D

enum SoundType {
	StickHit,
	BallHit,
	WallHit,
	BallSunk
}

var hit_1 = preload("res://assets/sfx/hit_1.wav")
var hit_2 = preload("res://assets/sfx/hit_2.wav")
var hit_wall = preload("res://assets/sfx/wall_bounce.wav")
var stick_1 = preload("res://assets/sfx/stick.wav")
var stick_2 = preload("res://assets/sfx/stick_2.wav")
var pocket = preload("res://assets/sfx/pocket.wav")
var pocket_2 = preload("res://assets/sfx/pocket_2.wav")
var pocket_3 = preload("res://assets/sfx/pocket_3.wav")

func _ready() -> void:
	EventBus.stick_hit_ball.connect(func(a: Ball, power: float): 
		create_sound(
			SoundType.StickHit, 
			a.global_position, 
			0.5 + 0.5 * power / 100, 
			randf_range(0.9,1.1)))
	
	EventBus.ball_hit_wall.connect(func(a: Ball): 
		create_sound(
			SoundType.WallHit, 
			a.global_position, 
			sqrt(a.velocity.length()) / 10, 
			randf_range(0.9,1.1)))
	
	EventBus.ball_hit_ball.connect(func(a: Ball, b: Ball): 
		create_sound(
			SoundType.BallHit, 
			a.global_position, 
			max(a.velocity.length(), b.velocity.length()) / 100, 
			randf_range(0.9,1.1)))
		
	EventBus.ball_sunk.connect(func(a: Ball): 
		create_sound(
			SoundType.BallSunk, 
			a.global_position, 
			1, 
			randf_range(0.9,1.1)))
	
	
func create_sound(sound_type: SoundType, at_position: Vector2, volume: float = 0.0, pitch: float = 1.0):
	var audio_clone := AudioStreamPlayer2D.new()
	var scene_root = get_tree().root.get_children()[0]
	scene_root.add_child(audio_clone)
	match sound_type:
		SoundType.StickHit:
			audio_clone.stream = [stick_1].pick_random()
		SoundType.WallHit:
			audio_clone.stream = [hit_wall].pick_random()
		SoundType.BallHit:
			audio_clone.stream = [hit_1, hit_2].pick_random()
		SoundType.BallSunk:
			audio_clone.stream = [pocket, pocket_2, pocket_3].pick_random()
		_: 
			pass
	audio_clone.global_position = at_position
	audio_clone.volume_db = clampf(-40 + volume * 40, -40, 0)
	audio_clone.pitch_scale = pitch
	
	audio_clone.finished.connect(func(): audio_clone.queue_free())
	audio_clone.play()
