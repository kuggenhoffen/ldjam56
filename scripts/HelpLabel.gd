extends Label


var is_paused: bool = false
var paused_time: float = 0.0

# Called when the node enters the scene tree for the first time.
func _ready():
	is_paused = get_tree().is_paused()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	#print("paused: ", get_tree().is_paused())
	if is_paused != get_tree().is_paused():
		is_paused = get_tree().is_paused()
		if is_paused:
			paused_time = Time.get_ticks_msec()
	if Input.is_action_just_pressed("pause") and is_paused and Time.get_ticks_msec() > paused_time + 200:
		visible = false
		get_tree().set_pause(false)
	if Input.is_action_just_pressed("ui_cancel"):
		get_tree().quit()