extends Container


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	var rect: Rect2 = get_viewport_rect()
	size = rect.size
	global_position = Vector2.ZERO
