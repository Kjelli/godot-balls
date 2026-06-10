@tool
class_name Ball
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
		
enum BallState {
	UNCONTROLLABLE,
	IDLE,
	AIMING,
	ROLLING
}

const FRICTION := 20.0
const RESTITUTION = 0.93
const BALL_STRENGTH = 5.0

@onready var sprite := %Sprite

# Texture offset (fake roll)
var scroll_speed := Vector2.ZERO
var ball_basis := Basis.IDENTITY
var ball_radius: float = 16.0

var start_position := Vector2.ZERO
var target_position := Vector2.ZERO
var power := 0.0

var ball_state := BallState.UNCONTROLLABLE :
	get(): 
		return ball_state
	set(value): 
		ball_state = value
		
		
func _ready() -> void:
	if not Engine.is_editor_hint():
		position += Vector2(
			randf_range(-0.2, 0.2),
			randf_range(-0.2, 0.2)
		)
	
	if ball_type == BallType.CUE_BALL:
		ball_state = BallState.IDLE
		
	else: 
		%Cue.queue_free()
	
	sprite.material = sprite.material.duplicate()
	_update_ball_texture()
	

func _input(event: InputEvent) -> void:
	match ball_state:
		BallState.UNCONTROLLABLE:
			return
			
		BallState.IDLE:
			if event is InputEventMouseButton and event.is_pressed():
				_start_aim()
				
		BallState.AIMING:
			if event is InputEventMouseMotion:
				_aim()

			if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
				if not event.pressed:
					_roll()

func set_ready() -> void:
	if ball_state != BallState.ROLLING or velocity.length() > 0.001:
		return
	
	ball_state = BallState.IDLE

func _start_aim() -> void:
	(%Cue as Cue).spin_speed = 0.0
	power = 0
	start_position = get_local_mouse_position()
	target_position = start_position
	ball_state = BallState.AIMING
	
	%AimLine.points[1] = %AimLine.points[0]
	
func cancel_aim() -> void:
	(%Cue as Cue).spin_speed = 0.0
	power = 0
	ball_state = BallState.IDLE

func _aim() -> void:
	target_position = target_position.lerp(get_local_mouse_position(), 0.1)
	var vector = start_position - target_position
	var length = vector.length()
	
	power = clampf(0.5 * length, 0, 100)
	
	%AimLine.points[1] = vector.normalized() * power * BALL_STRENGTH
	%CueRotation.global_rotation = vector.angle()
	%Cue.position.x = - power / 2 - 112
	
	if power >= 5:
		(%Cue as Cue).spin_speed = (power / 100) * 10.0
	else: 
		(%Cue as Cue).spin_speed = 0.0

func _roll() -> void:
	if power < 5:
		cancel_aim()
		return
	
	var translate_tween = get_tree().create_tween()
	translate_tween.tween_property(%Cue, 'position:x', -110, 0.05)
	translate_tween.play()
	await translate_tween.finished
	
	ball_state = BallState.ROLLING
	EventBus.stick_hit_ball.emit(self, power)
	velocity = (%AimLine.points[1] - %AimLine.points[0]).normalized() * power * BALL_STRENGTH

func _process(_delta: float) -> void:
	if Engine.is_editor_hint():
		return
	
	var target_alpha = 1.0 if ball_state == BallState.AIMING else 0.0
	if %AimLine:
		%AimLine.modulate.a = lerp(%AimLine.modulate.a, target_alpha, 0.2)
	if %Cue:
		(%Cue as Cue).alpha = lerp(%Cue.alpha, target_alpha, 0.2)
		
	match ball_state:
		BallState.UNCONTROLLABLE:
			return
		BallState.IDLE:
			pass	
		BallState.AIMING:
			_aim()
		BallState.ROLLING:
			pass
		
func _physics_process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
		
	velocity = velocity.move_toward(Vector2.ZERO, FRICTION * delta)
	
	if velocity.length() > 0.001:
		_move(delta)
	else:
		velocity = Vector2.ZERO

func _move(delta: float) -> void:
	var distance = (velocity.length() + ball_radius) * delta
	var move_dir = velocity.normalized()

	var axis = Vector3(move_dir.y, -move_dir.x, 0.0).normalized()
	var angle = distance / ball_radius
	var ball_rotation = Basis(axis, angle)

	ball_basis = ball_basis * ball_rotation

	sprite.material.set_shader_parameter(
		"rotation_basis",
		ball_basis
	)

	var collision = move_and_collide(velocity * delta)
	if collision:
		var other = collision.get_collider()
		var normal = collision.get_normal()
		
		if other is TileMapLayer:
			EventBus.ball_hit_wall.emit(self)
			velocity = velocity.bounce(normal)
		
		elif other is Ball:
			EventBus.ball_hit_ball.emit(self, other)
			# chaos
			var random_angle = randf_range(-0.03, 0.03)
			normal = normal.rotated(random_angle)

			var v1n = normal * velocity.dot(normal)
			var v1t = velocity - v1n

			var v2n = normal * other.velocity.dot(normal)
			var v2t = other.velocity - v2n

			velocity = (v2n * RESTITUTION) + v1t
			other.velocity = (v1n * RESTITUTION) + v2t

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
