@tool
extends Creature
class_name WeeWiggler

var viewport: Rect2
@onready var movement: Node = $Movement

@export var min_scale: float = 0.05
@export var max_scale: float = 0.1
var speed: float = 100.0

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


func random_position_in_viewport():
	viewport.grow(-viewport.size.y / 20)
	return viewport.position + viewport.size * Vector2(randf(), randf())
