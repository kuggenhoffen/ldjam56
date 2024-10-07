@tool
extends CharacterBody2D
class_name Creature

enum SizeLevel {
	SMALL,
	MEDIUM,
	LARGE
}

@export var body_parts: Array[BodySegment]

@export var body_part_prefab: PackedScene
@export var part_count: int:
	get:
		return part_count
	set(value):
		if value >= 0:
			part_count = value
			if Engine.is_editor_hint():
				update_body_parts()

@export var body_offset: Curve:
	get:
		return body_offset
	set(value):
		if Engine.is_editor_hint() and value != null:
			if body_offset != null:
				body_offset.changed.disconnect(update_body_parts)
			value.changed.connect(update_body_parts)
		body_offset = value
@export var body_scale: Curve:
	get:
		return body_scale
	set(value):
		if Engine.is_editor_hint() and value != null:
			if body_scale != null:
				body_scale.changed.disconnect(update_body_parts)
			value.changed.connect(update_body_parts)
		body_scale = value
var target_position: Vector2
var update_body_properties_requested: bool = false
@export var remote_transform: Node2D
var base_scale: float
var game_manager: GameManager

@export var consume_shape_casts: Array[ShapeCast2D]
@export var search_shape_casts: Array[ShapeCast2D]
@export var consume_shape_cast_for_search: bool = false
var is_dragging: bool = false
var size_level: SizeLevel = SizeLevel.SMALL:
	get:
		return size_level
	set(value):
		size_level = value
		if game_manager:
			game_manager.creature_size_changed(self)
var lifetime: float = 30
var is_dead: bool = false
var levels: Array = [0.0]
var creature_type_index: int
var consumed_creatures_count: int = 0

const max_lifetimes: Array = [30, 60, 120]

# Called when the node enters the scene tree for the first time.
func _ready():
	size_level = SizeLevel.values()[levels.bsearch(base_scale)]
	lifetime = max_lifetimes[size_level]
	target_position = global_position
	var areas = find_children("*", "Area2D")
	for area in areas:
		area.input_pickable = true
		area.mouse_entered.connect(_mouse_enter)
		area.mouse_exited.connect(_mouse_exit)
		for cast in consume_shape_casts:
			cast.add_exception(area)
		for cast in search_shape_casts:
			cast.add_exception(area)
	game_manager = get_node_or_null("/root/GameManager")


func set_target_position(position: Vector2):
	target_position = position


func creature_update():
	update_body_properties()
	

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if Engine.is_editor_hint():
		return
	if update_body_properties_requested:
		update_body_properties()
		update_body_properties_requested = false
	var follow_position = target_position
	if body_parts.size() == 0 or body_parts.front().global_position.distance_squared_to(follow_position) < 1.0:
		return
	for body in body_parts:
		body_lookat(body, follow_position)
		if body_parts.front() == body:
			rotation = body.rotation
			body.global_position = follow_position
		else:
			body_follow(body, follow_position)
		follow_position = body.global_position


func _physics_process(delta):
	lifetime -= delta
	if lifetime <= 0 and !is_dead:
		is_dead = true
		game_manager.creature_died(self)
		update_body_properties()
	var modulate_amount: float = 1.0 - clampf(lifetime / max_lifetimes[0], 0.3, 1.0)
	modulate = Color(1, 1, 1, 1).lerp(Color(0, 0, 0, 1), modulate_amount)
	update_body_modulate()


func check_consume_shapecast(consume_types: Array[Variant], consume_distance: float, single: bool = false, max_consume_size: SizeLevel = SizeLevel.SMALL) -> int:
	var close_creature: Creature = null
	var consumed: int = 0
	if consume_types.is_empty():
		return 0
	for cast in consume_shape_casts:
		if cast.is_colliding():
			close_creature = get_closest_creature_from_shape_cast(cast, consume_types)
			if close_creature and not close_creature.is_dragging and global_position.distance_squared_to(close_creature.global_position) < consume_distance:
				if close_creature.size_level > max_consume_size:
					continue
				consume_creature(close_creature)
				consumed += 1
				if single:
					break
	return consumed


func consume_creature(creature: Creature):
	creature.queue_free()
	creature = null
	lifetime += 10
	if lifetime > max_lifetimes[size_level]:
		lifetime = max_lifetimes[size_level]
	consumed_creatures_count += 1
	if size_level == SizeLevel.LARGE and consumed_creatures_count % 5 == 0:
		game_manager.spawn_offspring(self)


func check_search_shapecast(search_types: Array[Variant], search_distance: float) -> Creature:
	if search_types.is_empty():
		return null
	var close_creature: Creature = null
	var shape_casts: Array[ShapeCast2D] = search_shape_casts.duplicate()
	if consume_shape_cast_for_search:
		shape_casts.append_array(consume_shape_casts)
	for cast in search_shape_casts:
		if cast.is_colliding():
			close_creature = get_closest_creature_from_shape_cast(cast, search_types, search_distance)
			if close_creature:
				search_distance = global_position.distance_squared_to(close_creature.global_position)
	return close_creature
	

func get_closest_creature_from_shape_cast(cast: ShapeCast2D, creature_types: Array[Variant] = [Creature], closest_distance: float = 1e6) -> Creature:
	var closest_creature: Creature = null
	for index in range(cast.get_collision_count()):
		var collider = cast.get_collider(index)
		if collider == null:
			continue
		var creature: Creature = collider.get_parent().creature
		if creature == null:
			continue
		for creature_type in creature_types:
			if is_instance_of(creature, creature_type):
				var distance_squared: float = global_position.distance_squared_to(creature.global_position)
				if distance_squared < closest_distance:
					closest_distance = distance_squared
					closest_creature = creature
	return closest_creature


func update_body_parts():
	if not Engine.is_editor_hint() or get_tree() == null or get_tree().get_edited_scene_root() != self:
		return
	for i in range(get_child_count() - 1, -1, -1):
		if get_child(i) is BodySegment:
			var to_remove = get_child(i)
			remove_child(to_remove)
			to_remove.free()
	body_parts.clear()
	for i in part_count:
		var new_body_part = body_part_prefab.instantiate()
		new_body_part.name = "BodyPart" + str(body_parts.size())
		new_body_part.creature = self
		body_parts.append(new_body_part)
		add_child(new_body_part)
		new_body_part.owner = get_tree().get_edited_scene_root()
	update_body_properties()


func update_body_properties():
	for i in body_parts.size():
		var sample_pos: float = (float)(i) / (body_parts.size() - 1)
		if body_parts.size() == 1:
			sample_pos = 0.0
		body_parts[i].segment_offset = body_offset.sample(sample_pos) * base_scale
		body_parts[i].segment_scale = body_scale.sample(sample_pos) * base_scale
		body_parts[i].animation_offset = (sample_pos + (sample_pos * randf())) * PI
		if Engine.is_editor_hint():
			body_parts[i].position = global_position + Vector2(-i * body_offset.sample(sample_pos), 0)
		body_parts[i].update_body_properties()
		body_parts[i].animate = (lifetime > 0)


func update_body_modulate():
	for body in body_parts:
		body.modulate = modulate


func request_update_body_properties():
	update_body_properties_requested = true


func body_lookat(body: Node2D, target: Vector2):
	var angle: float = body.global_position.angle_to_point(target)
	body.global_rotation = angle


func body_follow(body: Node2D, follow_position: Vector2):
	var angle: float = body.global_position.angle_to_point(follow_position)
	body.global_position = follow_position - body.segment_offset * Vector2(cos(angle), sin(angle))


func outside_of_play_area():
	return !get_viewport_rect().has_point(global_position)


func _mouse_enter():
	game_manager.mouse_active_target_enter(self)


func _mouse_exit():
	game_manager.mouse_active_target_exit(self)