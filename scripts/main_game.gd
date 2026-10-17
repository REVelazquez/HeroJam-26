extends Node2D
@onready var camera_2d: Camera2D = $Camera2D
@onready var player: CharacterBody2D = $player
@onready var player_light: PointLight2D = $PlayerLight
@onready var animation_player: AnimationPlayer = $AnimationPlayer

var changing_textures={
	"level_2": {"idle":preload("res://multimedia/palanca_de_pared_up.webp"), "active":preload("res://multimedia/palanca_de_pared_down.webp")}
}

var min_escale_light: float = 1
var out_light = false
var platforms_appearing ={
	"level_1":{},
	"level_2":{"button_pressed":false, "platforms_out":false}
}


var timed_puzzles={
	"level_1":{},
	"level_2":{
		"pulled":false
	}
}
var levels_completed = []

var save_point : String
var to_pull = ""
var level_key = ""


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	$nivel2/Movibles/CajaMovible.add_to_group("Movibles")

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	camera_2d.position = player.position
	player_light.position = player.position

	if $Timer.is_stopped() and out_light:
		$Timer.start()
	if !$Timer.is_stopped() and !out_light:
		$Timer.stop()
	
	if Input.is_action_just_pressed("reset"):
		_reset_level()
	if Input.is_action_just_pressed("action") and to_pull!= "":
		_pulled_lever()
	
	if platforms_appearing.level_2.button_pressed and !platforms_appearing.level_2.platforms_out:
		platforms_appearing.level_2.platforms_out = true

func _on_timer_timeout() -> void:
	player_light.texture_scale -= 0.1

func _on_area_2d_body_exited(body: Node2D) -> void:
	if body.name == "player":
		if out_light:
			out_light = false
			player_light.texture_scale = 5
		else:
			out_light = true

func _on_button_lvl2_area_2d_body_entered(body: Node2D) -> void:
	if body.name == "player" and $nivel2/Movibles/boton_lvl2.position.y != 518:
		animation_player.play("button_lvl2")

func _on_button_lvl2_area_2d_body_exited(body: Node2D) -> void:
	if body.name == "player" and $nivel2/Movibles/boton_lvl2.position.y != 518:
		animation_player.pause()
		animation_player.play_backwards("button_lvl2")
	elif body.name == "player" and $nivel2/Movibles/boton_lvl2.position.y == 518:
		platforms_appearing.level_2.button_pressed = true
		if !platforms_appearing.level_2.platforms_out:
			animation_player.play("platform_lvl2_aparition")
			for child in $nivel2/Estaticos/plataform_lvl2.get_children():
				if "Animated" in child.name:
					child.play("default")

func _on_save_point_lvl_2_body_entered(body: Node2D) -> void:
	if body.name == "player":
		save_point = "level_2_check"
	
func _reset_level():
	if save_point not in levels_completed:
		match save_point:
			"level_1_check":
				pass
			"level_2_check":
				player.position = $nivel2/Save_point_lvl_2.position
				player_light.texture_scale = 5.0
				animation_player.play("reset_lvl_2")
				platforms_appearing.level_2.button_pressed =false
				platforms_appearing.level_2.platforms_out =false
				

func _on_area_palanca_lvl_2_body_entered(body: Node2D) -> void:
	if body.name == "player":
		to_pull = "level_2"

func _on_area_palanca_lvl_2_body_exited(body: Node2D) -> void:
	if body.name == "player":
		to_pull = ""

func _pulled_lever():
	match to_pull:
		"level_2":
			if $nivel2/Lvl2Timer.is_stopped():
				$nivel2/Lvl2Timer.start()
				animation_player.play("flip_lvl_2")
				$nivel2/Movibles/lever/Sprite2D.texture = changing_textures.level_2.active

func _on_lvl_2_timer_timeout() -> void:
	animation_player.play_backwards("flip_lvl_2")
	$nivel2/Movibles/lever/Sprite2D.texture = changing_textures.level_2.idle

func _on_lvl_2_key_area_body_entered(body: Node2D) -> void:
	if body.name == "player":
		level_key = "level_2_key"
		$nivel2/Lvl2KeyArea.visible = false


func _on_open_door_lvl_2_body_entered(body: Node2D) -> void:
	if body.name == "player":
		if level_key == "level_2_key":
			$nivel2/DoorLvl2/Sprite2D.visible = false
			$nivel2/DoorLvl2/CollisionShape2D.position = position+ Vector2(100, 100)
