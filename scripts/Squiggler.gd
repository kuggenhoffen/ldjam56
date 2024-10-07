@tool
extends Creature
class_name Squiggler

@onready var movement: Node = $Movement

var next_direction_change: float = 0
@export var min_scale: float = 0.2
@export var max_scale: float = 0.8
var next_target_position: Vector2
var go_for_target_creature: Creature = null
var consume_timer: float = 0
const consume_interval: float = 8
var max_speed: float = 100

const size_levels: Array = [0.4, 0.7]

# Called when the node enters the scene tree for the first time.
func _ready():
	levels = size_levels
	movement.creature = self
	base_scale = min_scale
	next_target_position = random_position_in_viewport()
	creature_update()
	super._ready()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	super._process(delta)
	if Engine.is_editor_hint() or lifetime <= 0:
		return
	movement.do_movement(delta)
	if go_for_target_creature != null and not is_instance_valid(go_for_target_creature):
		go_for_target_creature = null
	elif go_for_target_creature != null and is_instance_valid(go_for_target_creature):
		next_target_position = go_for_target_creature.global_position
	if Time.get_ticks_msec() >= next_direction_change:
		go_for_target_creature = null
		# Select random position within viewport for next target direction
		next_target_position = random_position_in_viewport()
		next_direction_change = Time.get_ticks_msec() + 1000 + randf() * 4000

func _physics_process(delta):
	if Engine.is_editor_hint():
		return
	super._physics_process(delta)
	if is_dragging or lifetime <= 0:
		return

	move_and_slide()

	if consume_timer > 0:
		consume_timer -= delta
		if consume_timer <= 0:
			consume_timer = 0
			movement.max_speed = max_speed
	else:
		var eat_types: Variant = []
		match size_level:
			SizeLevel.SMALL:
				eat_types = [WeeWiggler]
			SizeLevel.MEDIUM:
				eat_types = [WeeWiggler, FleaFleck]
			SizeLevel.LARGE:
				eat_types = [FleaFleck, SporeSprocket]

		if check_consume_shapecast(eat_types, 100, true, size_level) > 0:
			base_scale += 0.01
			if base_scale > max_scale:
				base_scale = max_scale
			size_level = SizeLevel.values()[levels.bsearch(base_scale)]
			creature_update()
			consume_timer = consume_interval * randf_range(0.8, 1.0)
			movement.max_speed = max_speed * 0.5
			next_direction_change = Time.get_ticks_msec()

		var closest_creature: Creature = check_search_shapecast(eat_types, 1e6)
		if closest_creature and (go_for_target_creature == null or randi() % 4 == 0):
			go_for_target_creature = closest_creature
			next_direction_change = Time.get_ticks_msec() + 5000


func random_position_in_viewport():
	var viewport: Rect2 = get_viewport_rect()
	viewport.grow(-viewport.size.y / 20)
	return viewport.position + viewport.size * Vector2(randf(), randf())


func get_creature_name():
	return "Squiggler"