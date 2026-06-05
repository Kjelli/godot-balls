@tool
extends CharacterBody2D

enum BallType {
	CUE_BALL,
	SOLID_1, 
	SOLID_2, 
	SOLID_3, 
	SOLID_4, 
	SOLID_5, 
	SOLID_6,   
	SOLID_7,  
	EIGHT_BALL,
	STRIPE_9, 
	STRIPE_10,
	STRIPE_11,
	STRIPE_12,  
	STRIPE_13,  
	STRIPE_14, 
	STRIPE_15   
}

const TEXTURE_MAP := {
	BallType.CUE_BALL: "res://assets/sprites/balls/cue.png",
	BallType.SOLID_1: "res://assets/sprites/balls/solid_1.png",
	BallType.SOLID_2: "res://assets/sprites/balls/solid_2.png",
	BallType.SOLID_3: "res://assets/sprites/balls/solid_3.png",
	BallType.SOLID_4: "res://assets/sprites/balls/solid_4.png",
	BallType.SOLID_5: "res://assets/sprites/balls/solid_5.png",
	BallType.SOLID_6: "res://assets/sprites/balls/solid_6.png",
	BallType.SOLID_7: "res://assets/sprites/balls/solid_7.png",
	BallType.EIGHT_BALL: "res://assets/sprites/balls/eight_ball.png",
	BallType.STRIPE_9: "res://assets/sprites/balls/stripe_9.png",
	BallType.STRIPE_10: "res://assets/sprites/balls/stripe_10.png",
	BallType.STRIPE_11: "res://assets/sprites/balls/stripe_11.png",
	BallType.STRIPE_12: "res://assets/sprites/balls/stripe_12.png",
	BallType.STRIPE_13: "res://assets/sprites/balls/stripe_13.png",
	BallType.STRIPE_14: "res://assets/sprites/balls/stripe_14.png",
	BallType.STRIPE_15: "res://assets/sprites/balls/stripe_15.png"
}

@export var ball_type: BallType = BallType.CUE_BALL:
	set(value):
		ball_type = value
		_update_ball_texture()

const MAX_SPEED := 100.0
const ACCELERATION := 250.0
const FRICTION := 20.0

@onready var sprite := %Sprite

# Texture offset (fake roll)
var scroll_speed := Vector2.ZERO
var ball_basis := Basis.IDENTITY
var ball_radius: float = 16.0

func _ready() -> void:
	sprite.material = sprite.material.duplicate()
	_update_ball_texture()

func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	
	var input_dir := Vector2.ZERO
	input_dir.x = Input.get_axis("Move Left", "Move Right")
	input_dir.y = Input.get_axis("Move Up", "Move Down")
	input_dir = input_dir.normalized()
	
	if input_dir != Vector2.ZERO:
		velocity += input_dir * ACCELERATION * delta
		velocity = velocity.limit_length(MAX_SPEED)
	else:
		velocity = velocity.move_toward(Vector2.ZERO, FRICTION * delta)
	
	if velocity.length() > 0.001:
		var distance = velocity.length() * delta
		var move_dir = velocity.normalized()

		var axis = Vector3(move_dir.y, -move_dir.x, 0.0 ).normalized()
		var angle = distance / ball_radius
		var ball_rotation = Basis(axis, angle)

		ball_basis = ball_basis * ball_rotation

		sprite.material.set_shader_parameter(
			"rotation_basis",
			ball_basis
		)
	
	move_and_slide()

func _update_ball_texture() -> void:
	if not is_node_ready():
		await ready
		
	if sprite and sprite.material:
		var texture_path = TEXTURE_MAP[ball_type]
		
		if ResourceLoader.exists(texture_path):
			var new_texture = load(texture_path)
			sprite.material.set_shader_parameter("scroll_texture", new_texture)
			sprite.material.set_shader_parameter(
				"rotation_basis",
				Basis.IDENTITY
			)
		else:
			push_warning("Missing texture for ball type: ", ball_type, " at path: ", texture_path)
