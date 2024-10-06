extends Node2D
class_name GameManager

@onready var creature_label: Label = $SelectedCreatureLabel
@export var creature_prefabs: Array[PackedScene] = [
	preload("res://prefabs/creatures/WeeWiggler.tscn"),
	preload("res://prefabs/creatures/Squiggler.tscn"),
	preload("res://prefabs/creatures/FleaFleck.tscn"),
	preload("res://prefabs/creatures/SporeSprocket.tscn"),
]
var creature_index: int = 0
var mouse_active_target: Node2D = null
var dragging_target: Node2D = null

# Called when the node enters the scene tree for the first time.
func _ready():
	set_creature_label()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if Input.is_action_just_pressed("ui_focus_next"):
		if creature_prefabs.size() > 0:
			creature_index += 1
			if creature_index >= creature_prefabs.size():
				creature_index = 0
			set_creature_label()
	if Input.is_action_just_pressed("ui_accept") or (Input.is_action_just_pressed("spawn") and mouse_active_target == null):
		if creature_index < creature_prefabs.size():
			var new_creature: Node = creature_prefabs[creature_index].instantiate()
			new_creature.visible = false
			var mouse_pos: Vector2 = get_viewport().get_mouse_position()
			if get_viewport_rect().has_point(mouse_pos):
				new_creature.global_position = mouse_pos
			else:
				new_creature.global_position = get_viewport_rect().size * Vector2(randf(), randf())
			new_creature.global_rotation = randf() * 2 * PI
			call_deferred("add_child", new_creature)
			var show_creature: Callable = new_creature.set_visible.bind(true)
			get_tree().process_frame.connect(show_creature, CONNECT_ONE_SHOT)
	if Input.is_action_just_pressed("ui_cancel"):
		get_tree().quit()
	if Input.is_action_just_pressed("spawn") and mouse_active_target != null:
		dragging_target = mouse_active_target
		dragging_target.process_mode = Node.ProcessMode.PROCESS_MODE_DISABLED
		mouse_active_target = null
	elif Input.is_action_just_released("spawn") and dragging_target != null:
		dragging_target.process_mode = Node.ProcessMode.PROCESS_MODE_INHERIT
		dragging_target = null
	elif dragging_target != null:
		dragging_target.global_position = get_viewport().get_mouse_position()

func set_creature_label():
	if creature_index < creature_prefabs.size():
		creature_label.text = creature_prefabs[creature_index].get_state().get_node_name(0)
	else:
		creature_label.text = ""

func mouse_active_target_enter(target: Creature):
	mouse_active_target = target
	print("Mouse active target: ", mouse_active_target)

func mouse_active_target_exit(target: Creature):
	if mouse_active_target == target:
		mouse_active_target = null
		print("Mouse active target: ", mouse_active_target)