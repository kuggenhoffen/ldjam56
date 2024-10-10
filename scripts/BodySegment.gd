@tool
extends CollisionShape2D
class_name BodySegment

var lerp_min: Vector2
var lerp_max: Vector2
@export var creature: Creature
@export var animate: bool = true
@export var animation_offset: float
@export var segment_offset: float
@export var segment_scale: float:
    get:
        return segment_scale
    set(value):
        segment_scale = value
        scale = Vector2.ONE * segment_scale
        lerp_min = scale
        lerp_max = scale * (Vector2.ONE + Vector2(-0.1, 0.2))


func update_body_properties():
    scale = Vector2.ONE * segment_scale
    for child in get_children():
        if child.has_method("update_properties"):
            child.update_properties(segment_scale, animation_offset)


func _process(delta):
    if not animate or Engine.is_editor_hint():
        return
    var squish_amount: float = Time.get_ticks_msec() / 100.0;
    scale = lerp(lerp_min, lerp_max, sin(squish_amount - animation_offset) * 0.5 + 0.5);
