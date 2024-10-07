@tool
extends Creature
class_name Tentaculoid

enum MoveState {
	MOVING,
	WAITING,
	DIGESTING
}

@onready var movement: Node = $Movement
@export var min_scale: float = 0.2
@export var max_scale: float = 0.8
var max_speed: float = 50
@onready var viewport: Rect2 = get_viewport_rect()
var last_heading_update: float = 0
const waiting_time: Vector2 = Vector2(3.0, 10)
const moving_time: Vector2 = Vector2(3.0, 12.0)
var move_timer: float = 0
var move_state: MoveState = MoveState.WAITING
var next_target_position: Vector2 = Vector2.ZERO

const size_levels: Array = [0.5, 0.7]

func _ready():
	levels = size_levels
	next_target_position = random_position_in_viewport()
	movement.creature = self
	base_scale = min_scale
	creature_update()
	super._ready()

func _process(delta):
	super._process(delta)
	if Engine.is_editor_hint() or lifetime <= 0:
		return
	
	move_timer -= delta
	match move_state:
		MoveState.WAITING:
			if move_timer <= 0:
				enter_state_moving()
		MoveState.MOVING:
			if Time.get_ticks_msec() >= last_heading_update + 2000:
				last_heading_update = Time.get_ticks_msec()
				next_target_position = random_position_in_viewport()
			if move_timer <= 0:
				enter_state_waiting()
		MoveState.DIGESTING:
			if move_timer <= 0:
				enter_state_moving()
	movement.do_movement(delta)

func enter_state_waiting():
	move_timer = randf() * (waiting_time.y - waiting_time.x) + waiting_time.x
	move_state = MoveState.WAITING
	movement.max_speed = 0

func enter_state_moving():
	move_timer = randf() * (moving_time.y - moving_time.x) + moving_time.x
	move_state = MoveState.MOVING
	movement.max_speed = max_speed

func enter_state_digesting():
	move_state = MoveState.DIGESTING

func _physics_process(delta):
	if Engine.is_editor_hint():
		return
	super._physics_process(delta)
	if is_dragging or lifetime <= 0:
		return
	move_and_slide()
	if move_state == MoveState.WAITING:
		if check_consume_shapecast([FleaFleck, Squiggler], 150, true, size_level) > 0:
			base_scale += 0.015
			if base_scale > max_scale:
				base_scale = max_scale
			size_level = SizeLevel.values()[levels.bsearch(base_scale)]
			creature_update()
			enter_state_digesting()

func random_position_in_viewport():
	viewport.grow(-viewport.size.y / 20)
	return viewport.position + viewport.size * Vector2(randf(), randf())

func get_creature_name():
	return "Tentaculoid"