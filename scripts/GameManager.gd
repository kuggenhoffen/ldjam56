extends Node2D
class_name GameManager


@onready var creature_label: Button = $SelectedCreatureLabel
@onready var target_creature_label: Label = $TargetCreatureLabel
@onready var unlocked_creature_label: Label = $UnlockLabelContainer/UnlockedLabel
@onready var unlocked_animation_player: AnimationPlayer = $UnlockLabelContainer/AnimationPlayer
@onready var tooltip_label: Label = $TooltipLabel
@onready var help_label: Label = $HelpLabel
@onready var dead_creature_emitter: CreatureEmitter = $DeadCreatureEmitter
@onready var drag_grace_timer: Timer = $DragGraceTimer
@onready var wiggler_spawn_timer: Timer = $WigglerSpawnTimer

const UNKNOWN_CREATURE_NAME: String = "??????"

var creature_types: Array[Dictionary] = [
	{
		name = "WeeWiggler",
		prefab = preload("res://prefabs/creatures/WeeWiggler.tscn"),
		spawn_cooldown = 1.0,
		large_count = 0,
		locked = false,
		locked_description = "",
		description = "A small, slow but wiggly creature\nthat can be found in the wild."
	},
	{
		name = "FleaFleck",
		prefab = preload("res://prefabs/creatures/FleaFleck.tscn"),
		spawn_cooldown = 5.0,
		large_count = 0,
		locked = false,
		locked_description = "",
		description = "FleaFlecks are small creatures that\ncan grow fairly big. They move\naround in short jumps and consume\nWeeWigglers for food."
	},
	{
		name = "SporeSprocket",
		prefab = preload("res://prefabs/creatures/SporeSprocket.tscn"),
		spawn_cooldown = 10.0,
		large_count = 0,
		locked = true,
		to_unlock = [
			{
				creature_index = 1,
				count = 4
			}
		],
		locked_description = "To unlock have 4 large FleaFlecks\nin the world at the same time.",
		description = "SporeSprockets are medium-sized creatures\nthat consume FleaFlecks and some\nlarge specimen are known to even\nfeed on Squigglers. They release\na cloud of WeeWiggler spores once\nthey have consumed their prey."
	},
	{
		name = "Squiggler",
		prefab = preload("res://prefabs/creatures/Squiggler.tscn"),
		spawn_cooldown = 15.0,
		large_count = 0,
		locked = true,
		to_unlock = [
			{
				creature_index = 1,
				count = 4
			},
			{
				creature_index = 2,
				count = 2
			}
		],
		locked_description = "To unlock have 4 large FleaFlecks and\n2 large SporeSprockets in the world.",
		description = "Squigglers are fast worm like creatures\nthat consume many types of food\ndepending on their size."
	},
	{
		name = "Tentaculoid",
		prefab = preload("res://prefabs/creatures/Tentaculoid.tscn"),
		spawn_cooldown = 15.0,
		large_count = 0,
		locked = true,
		to_unlock = [
			{
				creature_index = 1,
				count = 3
			},
			{
				creature_index = 3,
				count = 3
			}
		],
		locked_description = "To unlock have 3 large FleaFlecks\nand 3 large Squigglers in the world.",
		description = "Tentaculoids try to catch similar size\nFleaFlecks and Squigglers with their tentacles\nby waiting for them to pass by."
	}
]

var creature_spawn_cooldown_timers: Array[float] = []

var creature_index: int = 0
var mouse_active_target: Node2D = null
var dragging_target: Node2D = null
var tooltip_toggled: bool = false
const drag_grace_time: float = 0.1


# Called when the node enters the scene tree for the first time.
func _ready():
	get_tree().paused = true
	creature_spawn_cooldown_timers.clear()
	for creature in creature_types:
		creature_spawn_cooldown_timers.append(creature.spawn_cooldown)
	update_creature_label()
	drag_grace_timer.connect("timeout", deselect_active_drag_target)
	wiggler_spawn_timer.connect("timeout", spawn_wiggler)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if Input.is_action_just_pressed("next_creature"):
		if creature_types.size() > 0:
			creature_index += 1
			if creature_index >= creature_types.size():
				creature_index = 0
	if Input.is_action_just_pressed("prev_creature"):
		if creature_types.size() > 0:
			creature_index -= 1
			if creature_index < 0:
				creature_index = creature_types.size() - 1
	if Input.is_action_just_pressed("ui_accept"):
		spawn_creature_by_user(get_viewport_rect().size * Vector2(randf(), randf()), creature_index)
	if Input.is_action_just_pressed("spawn") and mouse_active_target == null:
		var mouse_pos: Vector2 = get_viewport().get_mouse_position()
		if get_viewport_rect().has_point(mouse_pos):
			spawn_creature_by_user(mouse_pos, creature_index)
	if Input.is_action_just_pressed("ui_cancel"):
		get_tree().quit()
	if Input.is_action_just_pressed("spawn") and mouse_active_target != null:
		if not is_instance_valid(mouse_active_target):
			mouse_active_target = null
		elif !mouse_active_target.is_dead:
			dragging_target = mouse_active_target
			mouse_active_target.is_dragging = true
			mouse_active_target = null
	if Input.is_action_just_pressed("ui_end"):
		unlock_creature(creature_types[creature_index])
	if Input.is_action_just_pressed("show_info"):
		tooltip_toggled = !tooltip_toggled
	if Input.is_action_just_pressed("pause") and !get_tree().paused:
		get_tree().set_pause(true)
		help_label.visible = true
		print("Pausing")
	elif Input.is_action_just_released("spawn") and dragging_target != null:
		dragging_target.is_dragging = false
		dragging_target = null
	elif dragging_target != null:
		dragging_target.global_position = get_viewport().get_mouse_position()
	for i in creature_spawn_cooldown_timers.size():
		if creature_spawn_cooldown_timers[i] > 0:
			creature_spawn_cooldown_timers[i] -= delta
	update_creature_label()
	update_active_target_label()


func spawn_creature_by_user(pos: Vector2, index: int = 0):
	if !creature_types[index].locked and creature_spawn_cooldown_timers[index] <= 0:
		creature_spawn_cooldown_timers[index] = creature_types[index].spawn_cooldown
		spawn_creature(pos, index)

func spawn_creature(pos: Vector2, index: int = 0):
	if index < creature_types.size():
		var new_creature: Node = creature_types[index].prefab.instantiate()
		new_creature.visible = false
		new_creature.global_position = pos
		new_creature.global_rotation = randf() * 2 * PI
		new_creature.creature_type_index = index
		call_deferred("add_child", new_creature)
		var show_creature: Callable = new_creature.set_visible.bind(true)
		get_tree().process_frame.connect(show_creature, CONNECT_ONE_SHOT)

func update_creature_label():
	tooltip_label.visible = creature_label.is_hovered() or tooltip_toggled
	var unknown_creature_names: Array[String] = []
	for creature in creature_types:
		if creature.locked:
			unknown_creature_names.append(creature.name)

	if creature_index < creature_types.size():
		if creature_types[creature_index].locked:
			creature_label.text = UNKNOWN_CREATURE_NAME
			creature_label.modulate = Color.DARK_GRAY
			tooltip_label.text = creature_types[creature_index].locked_description
			for unknown_creature in unknown_creature_names:
				tooltip_label.text = tooltip_label.text.replace(unknown_creature, UNKNOWN_CREATURE_NAME)
		else:
			creature_label.text = creature_types[creature_index].name
			tooltip_label.text = creature_types[creature_index].description
			for unknown_creature in unknown_creature_names:
				tooltip_label.text = tooltip_label.text.replace(unknown_creature, UNKNOWN_CREATURE_NAME)
			if creature_spawn_cooldown_timers[creature_index] > 0:
				creature_label.text += " (cooldown: %.1f)" % creature_spawn_cooldown_timers[creature_index]
				creature_label.modulate = Color.DARK_GRAY
			else:
				creature_label.modulate = Color.WHITE
	else:
		creature_label.text = ""


func update_active_target_label():
	var active_creature: Creature = dragging_target
	if active_creature == null and mouse_active_target != null:
		active_creature = mouse_active_target
	if active_creature != null:
		var extra_info: String = ""
		if active_creature.is_dead:
			extra_info = " (dead)"
		var size_info: String = Creature.SizeLevel.keys()[active_creature.size_level].to_lower().capitalize()
		target_creature_label.text = "%s %s%s" % [size_info, active_creature.get_creature_name(), extra_info]
		target_creature_label.global_position = get_viewport().get_mouse_position() + Vector2(15, 15)
		var label_rect: Rect2 = target_creature_label.get_rect()
		var max_pos: Vector2 = target_creature_label.get_rect().position + label_rect.size
		if max_pos.x > get_viewport_rect().size.x:
			target_creature_label.global_position.x = get_viewport().get_mouse_position().x - target_creature_label.get_rect().size.x
		if max_pos.y > get_viewport_rect().size.y:
			target_creature_label.global_position.y = get_viewport().get_mouse_position().y - target_creature_label.get_rect().size.y
		target_creature_label.visible = true
	else:
		target_creature_label.visible = false

func mouse_active_target_enter(target: Creature):
	mouse_active_target = target
	drag_grace_timer.stop()

func mouse_active_target_exit(target: Creature):
	drag_grace_timer.start(drag_grace_time)

func deselect_active_drag_target():
	mouse_active_target = null

func spawn_wiggler():
	spawn_creature(get_viewport_rect().size * Vector2(randf(), randf()), 0)

func creature_died(creature: Creature):
	if creature.size_level == Creature.SizeLevel.LARGE:
		creature_types[creature.creature_type_index].large_count -= 1
		if creature_types[creature.creature_type_index].large_count <= 0:
			creature_types[creature.creature_type_index].large_count = 0
	await get_tree().create_timer(10).timeout
	dead_creature_emitter.emit(creature.global_position, (creature.size_level + 1) * 5)
	creature.queue_free()

func spawn_offspring(creature: Creature):
	spawn_creature(creature.global_position, creature.creature_type_index)

func creature_size_changed(creature: Creature):
	if creature.size_level == Creature.SizeLevel.LARGE:
		creature_types[creature.creature_type_index].large_count += 1
		check_creature_unlocks()

func check_creature_unlocks():
	for creature in creature_types:
		if creature.locked and creature.to_unlock.size() > 0:
			var unlocked: bool = true
			for unlock in creature.to_unlock:
				if creature_types[unlock.creature_index].large_count < unlock.count:
					unlocked = false
					break
			if unlocked:
				unlock_creature(creature)
				break

func unlock_creature(creature: Dictionary):
	unlocked_creature_label.text = "<- Unlocked %s" % creature.name
	unlocked_animation_player.play("Unlocked")
	creature.locked = false
