extends Node

signal movement_finished()

@export var creature: CharacterBody2D

@export var change_direction_interval: float = 0.4
var default_speed: float = 10 + randf() * 30
var speed: float = default_speed
var current_heading: Vector2 = Vector2.RIGHT
var target_position: Vector2 = current_heading
var last_direction_change: float = 0
@export var heading_change_speed: float = 1

# Called when the node enters the scene tree for the first time.
func _ready():
	pass


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


func do_movement(delta: float):
	if (Time.get_ticks_msec() > last_direction_change + change_direction_interval):
		current_heading = current_heading.rotated((randf_range(-1, 1) * 2 * PI) * heading_change_speed)
		if creature.outside_of_play_area():
			# Direct the creature back into the play area
			current_heading = (creature.random_position_in_viewport() - creature.global_position).normalized()
		last_direction_change = Time.get_ticks_msec()
	creature.velocity = current_heading * speed
	creature.set_target_position(creature.global_position)
