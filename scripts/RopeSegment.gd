@tool
class_name RopeSegment

# Normalized distance from root
var root_distance: float
# This segments scale
var segment_scale: float
# Offset from previous segment
var segment_offset: float
var position: Vector2
var rotation: float

func _init(seg_scale: float, seg_offset: float, root_dist: float, initial_position: Vector2):
	segment_scale = seg_scale
	segment_offset = seg_offset
	root_distance = root_dist
	position = initial_position


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


func process_segment(previous_position: Vector2, affinity_rotation: float, lerp_speed: float):
	rotation = position.angle_to_point(previous_position)
	rotation = lerp_angle(rotation, affinity_rotation, lerp_speed)
	position = previous_position - segment_offset * Vector2(cos(rotation), sin(rotation))
