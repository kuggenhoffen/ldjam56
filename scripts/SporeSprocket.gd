@tool
extends Creature
class_name SporeSprocket

var viewport: Rect2
@onready var movement: Node = $Movement
@onready var creature_emitter: Node = $Emitter

@export var min_scale: float = 0.5
@export var max_scale: float = 0.8
var next_consume: float = 0
var time_until_emit: float = 0
const consume_interval: float = 15
const emit_interval: float = 5.0
var timer: float = 0

const size_levels: Array = [0.4, 0.7]

# Called when the node enters the scene tree for the first time.
func _ready():
	levels = size_levels
	movement.creature = self
	movement.default_speed = 2 + randf() * 15
	movement.speed = movement.default_speed
	base_scale = min_scale
	lifetime_add = 18.0
	super._ready()
	viewport = get_viewport_rect()
	creature_update()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	super._process(delta)
	if Engine.is_editor_hint() or lifetime <= 0:
		return
	movement.do_movement(delta)


func _physics_process(delta):
	if Engine.is_editor_hint():
		return
	super._physics_process(delta)
	if is_dragging or lifetime <= 0:
		return

	move_and_slide()
	timer += delta
	var eat_types: Variant = []
	match size_level:
		SizeLevel.MEDIUM:
			eat_types = [FleaFleck]
		SizeLevel.LARGE:
			eat_types = [FleaFleck, Squiggler]
	if time_until_emit <= 0 and timer > next_consume and check_consume_shapecast(eat_types, 150, true, size_level) > 0:
		next_consume = timer + consume_interval
		time_until_emit = emit_interval
		base_scale += 0.02
		if base_scale > max_scale:
			base_scale = max_scale
		size_level = SizeLevel.values()[levels.bsearch(base_scale)]
		creature_update()
	if time_until_emit > 0:
		movement.speed = 0
		time_until_emit -= delta
		if time_until_emit <= 0:
			movement.speed = movement.default_speed
			creature_emitter.emit()


func random_position_in_viewport():
	viewport.grow(-viewport.size.y / 20)
	return viewport.position + viewport.size * Vector2(randf(), randf())


func get_creature_name():
	return "SporeSprocket"