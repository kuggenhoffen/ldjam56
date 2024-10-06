@tool
extends Node2D

var segments: Array[RopeSegment] = []
var animation_offset: float = 0.0
var base_scale: float = 1.0

@export var segment_length: float:
	get:
		return segment_length
	set(value):
		var new_value: bool = value != segment_length
		if new_value:
			update_segments()
		segment_length = value

@export var segment_count: int:
	get:
		return segment_count
	set(value):
		var new_value: bool = value != segment_count
		if new_value:
			update_segments()
		segment_count = value



# Called when the node enters the scene tree for the first time.
func _ready():
	update_segments()

var last_update: float = 0.0
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if true: #Engine.is_editor_hint() or Time.get_ticks_msec() > last_update + 20:
		process_segments()
		queue_redraw()
		last_update = Time.get_ticks_msec()


func update_properties(bscale: float, anim_offset: float):
	animation_offset = anim_offset
	base_scale = bscale
	update_segments()


func process_segments():
	var parent_position: Vector2 = global_position
	for segment in segments:
		segment.process_segment(parent_position, global_transform.get_rotation() + PI, (sin((Time.get_ticks_msec() / 200.0) - animation_offset) + 1) * 0.2)
		parent_position = segment.position


func update_segments():
	# Define points for segments
	segments.clear()
	var parent_position: Vector2 = global_position
	var scaled_segment_length: float = segment_length * base_scale
	for i in range(segment_count):
		parent_position = parent_position + Vector2.RIGHT * scaled_segment_length
		var new_segment: RopeSegment = RopeSegment.new(1.0, scaled_segment_length, 1.0 * i / segment_count, parent_position)
		segments.append(new_segment)


func _draw():
	if false and not Engine.is_editor_hint():
		return
	
	var segment_position: Vector2 = Vector2.ZERO
	draw_circle(segment_position, 2, Color(0, 1, 0))
	for segment in segments:
		draw_circle(to_local(segment.position), 2, Color(1, 0, 0))
