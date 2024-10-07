@tool
extends Line2D

var segments: Array[RopeSegment] = []
var animation_offset: float = 0.0
var base_scale: float = 1.0

@export var segment_length: float:
	get:
		return segment_length
	set(value):
		var new_value: bool = value != segment_length
		segment_length = value
		if new_value:
			update_segments()

@export var segment_count: int:
	get:
		return segment_count
	set(value):
		var new_value: bool = value != segment_count
		segment_count = value
		if new_value:
			update_segments()



# Called when the node enters the scene tree for the first time.
func _ready():
	update_segments()


var last_update: float = 0.0
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	process_segments()
	update_line_points()
	if Engine.is_editor_hint():
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


func update_line_points():
	var old_points: PackedVector2Array = points
	if old_points.size() != segment_count + 1:
		old_points.resize(segment_count + 1)
	old_points[0] = Vector2.ZERO
	for i in range(segments.size()):
		old_points[i + 1] = to_local(segments[i].position)
	set_points(old_points)
	

func update_segments():
	# Define points for segments
	segments.clear()
	segments.resize(segment_count)
	var parent_position: Vector2 = global_position
	var scaled_segment_length: float = segment_length * base_scale
	for i in range(segment_count):
		parent_position = parent_position + Vector2.RIGHT * scaled_segment_length
		var new_segment: RopeSegment = RopeSegment.new(1.0, scaled_segment_length, 1.0 * i / segment_count, parent_position)
		segments[i] = new_segment
	update_line_points()

func _draw():
	if not Engine.is_editor_hint():
		return
	
	var segment_position: Vector2 = Vector2.ZERO
	draw_circle(segment_position, 2, Color(0, 1, 0))
	for segment in segments:
		draw_circle(to_local(segment.position), 2, Color(1, 0, 0))
