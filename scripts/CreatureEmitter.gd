extends Node
class_name CreatureEmitter

var root: Node2D
var parent: Node2D

@export var creature_prefab: PackedScene
@export var creature_count: int = 10

# Called when the node enters the scene tree for the first time.
func _ready():
	root = get_node("/root/GameManager")
	parent = get_parent()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func emit(pos: Variant = null, amount: Variant = null):
	if creature_prefab == null:
		return
	if pos == null:
		pos = parent.global_position
	if amount == null:
		amount = creature_count
	for i in amount:
		var creature = creature_prefab.instantiate()
		root.add_child(creature)
		creature.global_position = pos
		creature.target_position = creature.random_position_in_viewport()
		if creature.has_node("SecondaryMovement"):
			creature.movement = creature.get_node("SecondaryMovement")
			creature.movement.connect("movement_finished", on_movement_finished)
			creature.movement.current_heading = (creature.target_position - pos).normalized()
			creature.movement.max_speed *= randf_range(1.0, 2.0)
			creature.movement.deceleration *= randf_range(0.5, 1.5)
			creature.movement.accelerating_phase = true

func on_movement_finished(which: Creature):
	which.movement = which.get_node("Movement")