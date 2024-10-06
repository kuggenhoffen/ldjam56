@tool
extends CharacterBody2D
class_name Creature

@export var body_parts: Array[BodySegment]

@export var body_part_prefab: PackedScene
@export var part_count: int:
	get:
		return part_count
	set(value):
		if value >= 0:
			print("Setting value: ", value)
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

# Called when the node enters the scene tree for the first time.
func _ready():
	target_position = global_position
	var areas = find_children("*", "Area2D")
	for area in areas:
		for cast in consume_shape_casts:
			cast.add_exception(area)
		for cast in search_shape_casts:
			cast.add_exception(area)
	game_manager = get_node("/root/GameManager")


func set_target_position(position: Vector2):
	target_position = position


func creature_update():
	update_body_properties()
	pass
	#update_body_part_count(part_count)

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


func check_consume_shapecast(consume_types: Array[Variant], consume_distance: float, single: bool = false) -> int:
	var close_creature: Creature = null
	var consumed: int = 0
	for cast in consume_shape_casts:
		if cast.is_colliding():
			close_creature = get_closest_creature_from_shape_cast(cast, consume_types)
			if close_creature and global_position.distance_squared_to(close_creature.global_position) < consume_distance:
				close_creature.queue_free()
				close_creature = null
				consumed += 1
				if single:
					break
	return consumed


func check_search_shapecast(search_types: Array[Variant], search_distance: float) -> Creature:
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
	print("Updating body count, new count: ", part_count, ", old: ", body_parts.size())
	print("Child count: ", get_child_count())
	for i in range(get_child_count() - 1, -1, -1):
		if get_child(i) is BodySegment:
			var to_remove = get_child(i)
			remove_child(to_remove)
			to_remove.free()
	body_parts.clear()
	for i in part_count:
		print("Add body")
		var new_body_part = body_part_prefab.instantiate()
		new_body_part.name = "BodyPart" + str(body_parts.size())
		new_body_part.creature = self
		body_parts.append(new_body_part)
		add_child(new_body_part)
		new_body_part.owner = get_tree().get_edited_scene_root()
	update_body_properties()


func update_body_properties():
	#print("Update body properties, scale: ", base_scale, " parts: ", body_parts.size())
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
		#print("segment_scale: ", body_parts[i].segment_scale, ", (body scale: ", body_scale.sample(sample_pos), ")")


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
	print("Mouse enter")
	game_manager.mouse_active_target_enter(self)


func _mouse_exit():
	print("Mouse exit")
	game_manager.mouse_active_target_exit(self)