@tool
extends Control


# Called when the node enters the scene tree for the first time.
func _ready():
	size = get_viewport_rect().size

func _enter_tree():
	size = get_viewport_rect().size


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	size = get_viewport_rect().size
