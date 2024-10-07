@tool
extends Creature
class_name FleaFleck

@onready var movement: Node = $Movement

@onready var mid_cast: ShapeCast2D = $MidCast
@onready var left_cast: ShapeCast2D = $LeftCast
@onready var right_cast: ShapeCast2D = $RightCast

var viewport: Rect2
var direction_change_time: float = randf() * 2000
@export var min_scale: float = 0.1
@export var max_scale: float = 0.4
@export var min_speed: float = 100.0
@export var max_speed: float = 150.0
var speed: float = min_speed + randf() * (max_speed - min_speed)
var next_target_position: Vector2
var go_for_target_position: bool = false
const size_levels: Array = [0.4, 0.7]

# Called when the node enters the scene tree for the first time.
func _ready():
	levels = size_levels
	base_scale = min_scale
	movement.creature = self
	viewport = get_viewport_rect()
	super._ready()
	random_heading()
	creature_update()



# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	super._process(delta)
	if Engine.is_editor_hint():
		return
	movement.do_movement(delta)
	if global_position.distance_squared_to(next_target_position) <= 2.0:
		go_for_target_position = false
	if movement.velocity.length_squared() < 0.1 and (Time.get_ticks_msec() > direction_change_time):
		if go_for_target_position:
			movement.target_heading = (next_target_position - global_position).normalized()
		elif not viewport.has_point(global_position):
			random_heading()
		else:
			var new_heading: float = PI * (0.25 + (randf() - 0.5) * 2 * 0.75)
			movement.target_heading = movement.target_heading.rotated(new_heading)
		direction_change_time = Time.get_ticks_msec() + 1000 + randf() * 4000


func _physics_process(delta):
	if Engine.is_editor_hint():
		return
	super._physics_process(delta)
	if is_dragging or lifetime <= 0:
		return
		
	move_and_slide()
	var consume_level: SizeLevel = SizeLevel.MEDIUM if size_level == SizeLevel.LARGE else SizeLevel.SMALL 
	if check_consume_shapecast([WeeWiggler], 100, true, size_level) > 0:
		base_scale += 0.02
		if base_scale > max_scale:
			base_scale = max_scale
		size_level = SizeLevel.values()[levels.bsearch(base_scale)]
		creature_update()

	var closest_creature: Creature = check_search_shapecast([WeeWiggler], 1e6)
	if closest_creature and not go_for_target_position:
		go_for_target_position = true
		next_target_position = closest_creature.global_position


func random_heading():
	var pos: Vector2 = random_position_in_viewport()
	movement.target_heading = (pos - global_position).normalized()


func random_position_in_viewport():
	viewport.grow(-viewport.size.y / 20)
	return viewport.position + viewport.size * Vector2(randf(), randf())


func get_creature_name():
	return "FleaFleck"