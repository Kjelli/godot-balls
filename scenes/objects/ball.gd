@tool
class_name Ball
extends CharacterBody2D

const TERRAIN_FIELD := 0
const TERRAIN_WALL := 1
const TERRAIN_HOLE := 2

const COLLISION_MASK_BALL := 1
const COLLISION_MASK_WALL := 2
const COLLISION_MASK_HOLE := 3

const FRICTION := 30.0
const RESTITUTION = 0.93

enum BallType {
	CUE_BALL,
	
	SOLID_YELLOW,
	SOLID_BLUE,
	SOLID_BLACK,
	SOLID_GREEN,
	SOLID_BROWN,
	SOLID_PINK,
	
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
	
	BallType.SOLID_YELLOW: "res://assets/sprites/balls/solid_yellow.png",
	BallType.SOLID_BLUE: "res://assets/sprites/balls/solid_blue.png",
	BallType.SOLID_BLACK: "res://assets/sprites/balls/solid_black.png",
	BallType.SOLID_GREEN: "res://assets/sprites/balls/solid_green.png",
	BallType.SOLID_BROWN: "res://assets/sprites/balls/solid_brown.png",
	BallType.SOLID_PINK: "res://assets/sprites/balls/solid_pink.png",
	
	
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


@export var ball_type: BallType = BallType.EIGHT_BALL:
	set(value):
		ball_type = value
		_update_ball_texture()
		
@onready var sprite := %Sprite

var ball_basis := Basis.IDENTITY : 
	get(): return ball_basis
	set(value):
		ball_basis = value
		sprite.material.set_shader_parameter("rotation_basis", ball_basis)
		
var alpha := 1.0 :
	get(): 
		return alpha
	set(value): 
		alpha = value
		sprite.material.set_shader_parameter("alpha", alpha)
		
var ball_radius: float = 16.0
var sink_point: Vector2
var is_moving: bool = false

func _ready() -> void:
	if not Engine.is_editor_hint():
		# chaos
		position += Vector2(
			randf_range(-0.2, 0.2),
			randf_range(-0.2, 0.2)
		)
	
	%Hat.rotation = randf_range(-PI/4, PI/4)
	
	sprite.material = sprite.material.duplicate()
	_update_ball_texture()

func _process(_delta: float) -> void:
	if Engine.is_editor_hint():
		return
		
func _physics_process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
		
	var currently_moving = velocity.length_squared() > 0.0001
	
	velocity = velocity.move_toward(Vector2.ZERO, FRICTION * delta)
	
	if velocity.length_squared() > 0.0001:
		_move(delta)
	else:
		velocity = Vector2.ZERO
		
	if currently_moving != is_moving:
		is_moving = currently_moving
		EventBus.ball_movement_changed.emit(self, is_moving)

func _move(delta: float) -> void:
	var distance = (velocity.length() + ball_radius) * delta
	var move_dir = velocity.normalized()

	var axis = Vector3(move_dir.y, -move_dir.x, 0.0).normalized()
	var angle = distance / ball_radius
	var ball_rotation = Basis(axis, angle)

	ball_basis = ball_basis * ball_rotation

	var collision = move_and_collide(velocity * delta)
	_handle_collision(collision)

func _handle_collision(collision: KinematicCollision2D) -> void:
	if not collision:
		return
		
	var other = collision.get_collider()
	var normal = collision.get_normal()
	
	if other is TileMapLayer:
		var layer := other as TileMapLayer
		
		# Convert collision point into tile coordinates
		var local_pos := layer.to_local(collision.get_position() + velocity.normalized())
		
		# Debug cross on local coordinates
		#var debug_line = Line2D.new()
		#debug_line.width = 0.2
		#debug_line.add_point(local_pos + Vector2(-2, -2))
		#debug_line.add_point(local_pos + Vector2(2, 2))
		#var debug_line2 = Line2D.new()
		#debug_line2.width = 0.2
		#debug_line2.add_point(local_pos + Vector2(2, -2))
		#debug_line2.add_point(local_pos + Vector2(-2, 2))
		#get_tree().current_scene.add_child(debug_line)
		#get_tree().current_scene.add_child(debug_line2)
		
		var cell = layer.local_to_map(local_pos)

		# Verify there is actually a tile there
		var tile_data: TileData = layer.get_cell_tile_data(cell)
		if tile_data == null:
			return

		var is_hole = tile_data.terrain == TERRAIN_HOLE

		if is_hole:
			velocity = Vector2.ZERO
			sink_point = local_pos
			_sink()
		else:
			EventBus.ball_hit_wall.emit(self)
			velocity = velocity.bounce(normal) * 0.8
	
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

func _set_collision_enabled(value: bool):
	self.set_collision_mask_value(COLLISION_MASK_HOLE, value)
	self.set_collision_layer_value(COLLISION_MASK_HOLE, value)
	self.set_collision_layer_value(COLLISION_MASK_BALL, value)
	self.set_collision_mask_value(COLLISION_MASK_BALL, value)

func _sink() -> void:
	EventBus.ball_sunk.emit(self)
	_set_collision_enabled(false)
	
	var tween = create_tween().set_parallel()
	tween.tween_property(self, "position", sink_point, 0.25) \
		.set_ease(Tween.EASE_OUT) \
		.set_trans(Tween.TRANS_QUART)
	tween.tween_property(self, "scale", Vector2(0.1, 0.1), 0.35) \
		.set_ease(Tween.EASE_OUT) \
		.set_trans(Tween.TRANS_QUART)
	tween.tween_property(self, "alpha", 0.4, 0.35) \
		.set_ease(Tween.EASE_OUT) \
		.set_trans(Tween.TRANS_QUART)
		
	await tween.finished
	

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
