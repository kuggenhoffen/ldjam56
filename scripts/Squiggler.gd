@tool
extends Creature

@onready var movement: Node = $Movement

var next_direction_change: float = 0
@export var min_scale: float = 0.2
@export var max_scale: float = 0.8
var next_target_position: Vector2
var go_for_target_position: bool = false

# Called when the node enters the scene tree for the first time.
func _ready():
	movement.creature = self
	base_scale = min_scale
	next_target_position = random_position_in_viewport()
	creature_update()
	super._ready()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	super._process(delta)
	if Engine.is_editor_hint():
		return
	movement.do_movement(delta)
	move_and_slide()
	if (global_position.distance_squared_to(next_target_position) <= 20.0 and go_for_target_position) or Time.get_ticks_msec() >= next_direction_change:
		go_for_target_position = false
		# Select random position within viewport for next target direction
		next_target_position = random_position_in_viewport()
		next_direction_change = Time.get_ticks_msec() + 1000 + randf() * 4000

func _physics_process(delta):
	if check_consume_shapecast([WeeWiggler], 100, true) > 0:
		print("FleaFleck consumed WeeWiggler")
		base_scale += 0.02
		if base_scale > max_scale:
			base_scale = max_scale
		creature_update()

	var closest_creature: Creature = check_search_shapecast([WeeWiggler], 1e6)
	if closest_creature and not go_for_target_position:
		go_for_target_position = true
		next_target_position = closest_creature.global_position
		next_direction_change = Time.get_ticks_msec() + 5000


func random_position_in_viewport():
	var viewport: Rect2 = get_viewport_rect()
	viewport.grow(-viewport.size.y / 20)
	return viewport.position + viewport.size * Vector2(randf(), randf())

