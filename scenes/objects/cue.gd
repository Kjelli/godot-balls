@tool
class_name Cue
extends Sprite2D

var cue_angle := 0.0
var cue_basis := Basis.IDENTITY

var spin_speed := 2.0 :
	get(): 
		return spin_speed
	set(value): 
		spin_speed = value
		
var alpha := 1.0 :
	get(): 
		return alpha
	set(value): 
		alpha = value
		material.set_shader_parameter("alpha", alpha)
		
func _process(delta: float) -> void:
	cue_angle += spin_speed * delta
	cue_basis = Basis(Vector3.RIGHT, cue_angle)
	material.set_shader_parameter("rotation_basis", cue_basis)
