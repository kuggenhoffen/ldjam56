@tool
extends Creature
class_name SporeSprocket

var viewport: Rect2
@onready var movement: Node = $Movement
@onready var creature_emitter: Node = $Emitter

@export var min_scale: float = 0.7
@export var max_scale: float = 1.0
var next_consume: float = 0
var time_until_emit: float = 0
const consume_interval: float = 20 * 1000
const emit_interval: float = 5.0

# Called when the node enters the scene tree for the first time.
func _ready():
	super._ready()
	movement.creature = self
	base_scale = min_scale + randf() * (max_scale - min_scale)
	viewport = get_viewport_rect()
	creature_update()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if Engine.is_editor_hint():
		return
	movement.do_movement(delta)
	move_and_slide()
	super._process(delta)


func _physics_process(delta):
	if time_until_emit <= 0 and Time.get_ticks_msec() > next_consume and (check_consume_shapecast([FleaFleck], 50, true) > 0 or Input.is_action_just_pressed("ui_end")):
		next_consume = Time.get_ticks_msec() + consume_interval
		time_until_emit = emit_interval
		print("SporeSprocket consumed FleaFleck")
		base_scale += 0.02
		if base_scale > max_scale:
			base_scale = max_scale
		creature_update()
	if time_until_emit > 0:
		movement.speed = 0
		print("Time until emit: ", time_until_emit)
		time_until_emit -= delta
		if time_until_emit <= 0:
			movement.speed = movement.default_speed
			creature_emitter.emit()


func random_position_in_viewport():
	viewport.grow(-viewport.size.y / 20)
	return viewport.position + viewport.size * Vector2(randf(), randf())
