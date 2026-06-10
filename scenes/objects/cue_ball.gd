@tool
class_name CueBall
extends Ball

const BALL_STRENGTH = 5.0

enum BallState {
	UNCONTROLLABLE,
	IDLE,
	AIMING,
	ROLLING,
	SINKING,
	RESPAWNING,
	WAITING
}

var ball_state := BallState.IDLE :
	get(): 
		return ball_state
	set(value): 
		ball_state = value

@onready var spawn := self.position
 
@onready var cue := %Cue
@onready var cue_rotation := %CueRotation
@onready var aim_line := %AimLine

var is_queued_ready := false

var start_position := Vector2.ZERO
var target_position := Vector2.ZERO
var power := 0.0

func _ready() -> void:
	ball_state = BallState.IDLE
	
func _process(_delta: float) -> void:
	if Engine.is_editor_hint():
		return
	
	var target_alpha = 1.0 if ball_state == BallState.AIMING else 0.0
	aim_line.modulate.a = lerp(aim_line.modulate.a, target_alpha, 0.2)
	cue.alpha = lerp(cue.alpha, target_alpha, 0.2)
		
	match ball_state:
		BallState.UNCONTROLLABLE:
			return
		BallState.IDLE:
			pass	
		BallState.AIMING:
			_aim()
		BallState.ROLLING:
			if is_queued_ready:
				set_ready()
		BallState.RESPAWNING:
			pass
		BallState.WAITING:
			if is_queued_ready:
				_set_collision_enabled(true)
				set_ready()

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

func queue_ready() -> void:
	is_queued_ready = true

func set_ready() -> void:
	is_queued_ready = false
	ball_state = BallState.IDLE

func _start_aim() -> void:
	cue.spin_speed = 0.0
	power = 0
	start_position = get_local_mouse_position()
	target_position = start_position
	ball_state = BallState.AIMING
	
	aim_line.points[1] = aim_line.points[0]
	
func cancel_aim() -> void:
	cue.spin_speed = 0.0
	power = 0
	ball_state = BallState.IDLE

func _aim() -> void:
	target_position = target_position.lerp(get_local_mouse_position(), 0.1)
	var vector = start_position - target_position
	var length = vector.length()
	
	power = clampf(0.5 * length, 0, 100)
	
	aim_line.points[1] = vector.normalized() * power * BALL_STRENGTH
	cue_rotation.global_rotation = vector.angle()
	cue.position.x = - power / 2 - 112
	
	if power >= 5:
		cue.spin_speed = (power / 100) * 10.0
	else: 
		cue.spin_speed = 0.0

func _roll() -> void:
	if power < 5:
		cancel_aim()
		return
	
	var translate_tween = get_tree().create_tween()
	translate_tween.tween_property(cue, 'position:x', -110, 0.05)
	translate_tween.play()
	await translate_tween.finished
	
	ball_state = BallState.ROLLING
	EventBus.stick_hit_ball.emit(self, power)
	velocity = (aim_line.points[1] - aim_line.points[0]).normalized() * power * BALL_STRENGTH

func _sink() -> void:
	ball_state = BallState.SINKING
	super()
	ball_state = BallState.RESPAWNING
	_respawn()

func _respawn() -> void:
	await get_tree().create_timer(0.5).timeout
		
	var respawn_tween = create_tween().set_parallel()
	respawn_tween.tween_property(self, "position", spawn, 1).set_trans(Tween.TRANS_CUBIC)
	respawn_tween.tween_property(self, "alpha", 1.0, 1).set_trans(Tween.TRANS_CUBIC)
	respawn_tween.tween_property(self, "scale", Vector2(0.25, 0.25), 1).set_trans(Tween.TRANS_CUBIC)
	
	await respawn_tween.finished
	
	if is_queued_ready:
		_set_collision_enabled(true)
		set_ready()
	else:
		ball_state = BallState.WAITING
