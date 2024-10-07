extends Node

signal movement_finished(creature: Creature)

@export var creature: Creature

var target_heading: Vector2 = Vector2.RIGHT
var current_heading: Vector2 = target_heading
var velocity: Vector2 = Vector2(0, 0)
var acceleration: float = 300
var deceleration: float = 100
var max_speed: float = 200
var speed: float = 0
var accelerating_phase: bool = false

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


func do_movement(delta: float):
	if accelerating_phase:
		speed += acceleration * delta
		if speed >= creature.speed:
			speed = creature.speed
			accelerating_phase = false
	else:
		speed -= deceleration * delta
		if speed <= 0:
			speed = 0
			# Update target when creature has stopped
			if current_heading != target_heading:
				current_heading = target_heading
				accelerating_phase = true
				movement_finished.emit(creature)
	# If creature would end outside of the play area, direct it back into the play area
	if creature.outside_of_play_area():
		target_heading = (creature.random_position_in_viewport() - creature.global_position).normalized()
		current_heading = target_heading
		velocity = current_heading * speed
	velocity = current_heading * speed
	creature.velocity = velocity
	#creature.global_position += velocity * delta
	creature.set_target_position(creature.global_position)
