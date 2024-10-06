@tool
extends CollisionShape2D
class_name BodySegment

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


func update_body_properties():
    scale = Vector2.ONE * segment_scale
    print("Updating body properties, scale is now: ", segment_scale)
    for child in get_children():
        if child.has_method("update_properties"):
            child.update_properties(segment_scale, animation_offset)


func _process(delta):
    if not animate or Engine.is_editor_hint():
        return
    var squish_amount: float = Time.get_ticks_msec() / 100.0;
    scale = lerp(scale, (Vector2.ONE + Vector2(-0.05, 0.08) * (sin(squish_amount - animation_offset))) * segment_scale, delta * 30.0);
