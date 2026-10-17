extends Node2D
@onready var camera_2d: Camera2D = $Camera2D
@onready var player: CharacterBody2D = $player
@onready var player_light: PointLight2D = $PlayerLight


var min_escale_light: float = 1
var out_light = false

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	camera_2d.position = player.position
	player_light.position = player.position

	if $Timer.is_stopped() and out_light:
		$Timer.start()
	if !$Timer.is_stopped() and !out_light:
		$Timer.stop()
	
	if Input.is_action_just_pressed("reset"):
		player_light.texture_scale = 5


func _on_timer_timeout() -> void:
	player_light.texture_scale -= 0.1

func _on_area_2d_body_exited(body: Node2D) -> void:
	if body.name == "player":
		if out_light:
			out_light = false
			player_light.texture_scale = 5
		else:
			out_light = true
	

func _sink_button():
	pass
