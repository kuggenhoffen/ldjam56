extends Node

signal movement_finished()

@export var creature: CharacterBody2D

const speed: float = 100.0
const rotation_speed: float = 2.0
var current_heading: Vector2 = Vector2.RIGHT

# Called when the node enters the scene tree for the first time.
func _ready():
	pass


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


func do_movement(delta: float):
	var direction_vector = (creature.next_target_position - creature.global_position).normalized()
	if current_heading != direction_vector:
		var heading_difference: float = current_heading.angle_to(direction_vector)
		var rotation_direction: float = sign(heading_difference)
		var rotation_amount: float = min(abs(heading_difference), rotation_speed * delta)
		current_heading = current_heading.rotated(rotation_direction * rotation_amount)
	creature.velocity = current_heading * speed
	creature.set_target_position(creature.global_position)
