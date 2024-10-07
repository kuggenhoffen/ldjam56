@tool
extends Creature
class_name WeeWiggler

var viewport: Rect2
@onready var movement: Node = $Movement

@export var min_scale: float = 0.05
@export var max_scale: float = 0.1
var speed: float = 100.0

const size_levels: Array = [1]

# Called when the node enters the scene tree for the first time.
func _ready():
	levels = size_levels
	movement.creature = self
	base_scale = min_scale + randf() * (max_scale - min_scale)
	viewport = get_viewport_rect()
	super._ready()
	creature_update()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if Engine.is_editor_hint():
		return
	movement.do_movement(delta)
	super._process(delta)


func _physics_process(delta):
	if is_dragging:
		return
	move_and_slide()

func random_position_in_viewport():
	viewport.grow(-viewport.size.y / 20)
	return viewport.position + viewport.size * Vector2(randf(), randf())

func get_creature_name():
	return "WeeWiggler"