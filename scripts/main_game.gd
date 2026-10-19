extends Node2D
@onready var camera_2d: Camera2D = $Camera2D
@onready var player: CharacterBody2D = $player
@onready var player_light: PointLight2D = $PlayerLight
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var music_player = $Music
@onready var axis_clock = [$Level2/Estaticos/Reloj/Eje1,$Level2/Estaticos/Reloj/Eje2]



var changing_textures={
	"level_2": {"idle":preload("res://multimedia/Images/palanca_de_pared_up.webp"), "active":preload("res://multimedia/Images/palanca_de_pared_down.webp")}
}
var min_scale_light: float = 0.5
var max_scale_light: float = 8.0
var out_light = false
var platforms_appearing ={
	"level_1":{"button_1":{"pressed":false, "activated":false}, "button_2":{"pressed":false, "activated":false}},
	"level_2":{"button_pressed":false, "platforms_out":false}
}

var timed_puzzles={
	"level_1":{},
	"level_2":{
		"pulled":false
	}
}
var show_level = ""
var levels_showed = []
var levels_completed = []
var level_1_transition_started := false

var move_eyes_lvl_1 = false
var target_picture_lvl_1 = null
var eyes_initial_position_lvl_1 = Vector2(0, -5)
var eyes_max_distance_lvl_1 = Vector2(5, 3)
var cam_original_size
var eyes_speed_lvl_1 = 8.0
var showing_level = false
var picture_sound_played = false
var picture_audio_fading := false
var player_can_move = false
var clock_follow_target = false

var save_point : String
var to_pull = ""
var level_key = ""

var run_start = false
var camera_on_player = false

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	camera_2d.position = player.position - Vector2(-124, 64)
	animation_player.play("start_game")
	player_light.position = player.position
	$player.process_mode = PROCESS_MODE_DISABLED
	$Level2/Movibles/CajaMovible.add_to_group("Movibles")

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	music_player.position = player.position
	player_light.global_position = player.global_position

	print("camara ", camera_on_player)
	print("save_point ", save_point)
	print("level_1_Trans ", level_1_transition_started)
	if (player_can_move and camera_on_player )and (save_point == "" or save_point == "level_1_check" and !level_1_transition_started):
		camera_2d.position = player.position
		
	if run_start and camera_on_player and (save_point in levels_showed or save_point == ""):
		player.process_mode = Node.PROCESS_MODE_INHERIT
	
	if !music_player.playing:
		music_player.stream = Sounds.tracks.something_strange
		music_player.play(1)
	if music_player.get_playback_position() >= 16.0:
			music_player.play(1)
	
	_arrow_direction()
	#movimiento de ojos by IA
	if move_eyes_lvl_1 and is_instance_valid(target_picture_lvl_1):
		var audio_player = $Level1/Picture/AudioStreamPlayer2D
		
		#Verificamos si ya está sonando para NO reiniciarlo en cada frame y si salio
		if not audio_player.playing and !picture_sound_played:
			audio_player.stream = Sounds.tracks.picture_sound 
			audio_player.play(1.3)
			picture_sound_played = true
		
		var current_target = target_picture_lvl_1.global_position
		var eyes = $Level1/Picture/Eyes
		var direction = current_target - eyes.global_position
		# Limitamos el movimiento de las pupilas
		var target_position = eyes_initial_position_lvl_1 + Vector2(
			clampf(direction.normalized().x * eyes_max_distance_lvl_1.x,
				-eyes_max_distance_lvl_1.x, eyes_max_distance_lvl_1.x),
			clampf(direction.normalized().y * eyes_max_distance_lvl_1.y,
				-eyes_max_distance_lvl_1.y, eyes_max_distance_lvl_1.y)
		)
		eyes.position = eyes.position.lerp(
			target_position,
			clampf(eyes_speed_lvl_1 * delta, 0.0, 1.0))
	# Desvanecimiento del sonido si el jugador sale y se esta reproduciendo el sonido
	if !move_eyes_lvl_1:
		var audio_player = $Level1/Picture/AudioStreamPlayer2D
		if audio_player.playing and !picture_audio_fading:
			picture_audio_fading = true
			audio_player.stop()
# aca termina ojos y empieza lo de mostrar nivel:
	if showing_level and save_point == "level_1_check" and not level_1_transition_started:
		level_1_transition_started = true
		$Level1/Nubes.visible = true
		player.process_mode = Node.PROCESS_MODE_DISABLED
		var light_lvl1 = $Lvl1LightRef
		light_lvl1.visible = true
		var tween_position = create_tween()
		var tween_size = create_tween()
		tween_position.tween_property(camera_2d, "position", $Lvl1LightRef.position, 1.0)
		tween_size.tween_property(camera_2d,"zoom", Vector2(0.974, 0.891),1.0)
		await tween_position.finished
		await tween_size.finished
		if $"CameraMove timer".is_stopped():
			$"CameraMove timer".start()

#esto es el menu que se muestra
	if run_start and !camera_on_player :
		var camera_tween = create_tween()
		animation_player.play("menu_fading")
		camera_tween.tween_property(camera_2d, "position", player.position, 0.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		await camera_tween.finished
		camera_on_player = true
	
	if clock_follow_target:
		for i in range(axis_clock.size()):
			var direction = player.global_position - axis_clock[i].global_position
			axis_clock[i].global_rotation = direction.angle() + PI
			
# Inicia reduccion de luz al salir o la detiene si se entra a check point o a zona de luz
	if $Timer.is_stopped() and out_light:
		$Timer.start()
	if !$Timer.is_stopped() and !out_light:
		$Timer.stop()
	
	if Input.is_action_just_pressed("reset"):
		_reset_level()
	if Input.is_action_just_pressed("action") and to_pull!= "":
		_pulled_lever()
	
	#esto es para evitar repetir animaciones
	if platforms_appearing.level_1.button_1.pressed and !platforms_appearing.level_1.button_1.activated:
		platforms_appearing.level_1.button_1.activated = true
	
	if platforms_appearing.level_1.button_2.pressed and !platforms_appearing.level_1.button_2.activated:
		platforms_appearing.level_1.button_2.activated = true
	
	if platforms_appearing.level_2.button_pressed and !platforms_appearing.level_2.platforms_out:
		platforms_appearing.level_2.platforms_out = true
		
	if player_light.texture_scale <= min_scale_light:
		$Timer.stop()
		player_light.texture_scale = 0.3

func _on_timer_timeout() -> void:
	player_light.texture_scale *= 0.95

func _on_area_2d_body_exited(body: Node2D) -> void:
	if "lvl_1" not in levels_showed:
		showing_level = true
	if body.name == "player":
		player_light.texture_scale = max_scale_light
		if !out_light:
			out_light = true
		save_point = "level_1_check"
		for child in $Level1/PuenteLvl1.get_children():
			if "Animated" in child:
				child.play("default")

func _on_button_lvl2_area_2d_body_entered(body: Node2D) -> void:
	if body.name == "player" and !platforms_appearing.level_2.button_pressed:
		animation_player.play("button_lvl2")

func _on_button_lvl2_area_2d_body_exited(body: Node2D) -> void:
	if body.name == "player" and !platforms_appearing.level_2.button_pressed:
		animation_player.pause()
		animation_player.play_backwards("button_lvl2")

func _on_save_point_lvl_2_body_entered(body: Node2D) -> void:
	if body.name == "player":
		save_point = "level_2_check"
		$Level2/Lvl2KeyArea/Sprite2D.play("default")
		
		if !out_light:
			out_light = true
			player_light.texture_scale = max_scale_light
		if out_light:
			player_light.texture_scale = max_scale_light
	
func _reset_level():
	if save_point not in levels_completed:
		match save_point:
			"level_1_check":
				save_point = "level_1_check"
				$Level1/Lvl1KeyArea/Sprite2D.play("default")
				if !out_light:
					out_light = true
				player.position = $Level1/Lvl1Check.position
				platforms_appearing.level_1.button_1.pressed = false
				platforms_appearing.level_1.button_1.activated = false
				platforms_appearing.level_1.button_2.pressed = false
				platforms_appearing.level_1.button_2.activated = false
				animation_player.play("lvl_1_reset")
				player_light.texture_scale = max_scale_light
			"level_2_check":
				player.position = $Level2/Save_point_lvl_2.position
				player_light.texture_scale =  max_scale_light
				animation_player.play("reset_lvl_2")
				platforms_appearing.level_2.button_pressed =false
				platforms_appearing.level_2.platforms_out =false
				$Level2/DoorLvl2/DoorLvl2Sprite.play("Default")
				out_light = true
				player_light.texture_scale = max_scale_light

func _on_area_palanca_lvl_2_body_entered(body: Node2D) -> void:
	if body.name == "player":
		to_pull = "level_2"
		$Level2/Label.position = $Level2/Movibles/lever.position - Vector2(32, 50)
		$Level2/Label.visible = true

func _on_area_palanca_lvl_2_body_exited(body: Node2D) -> void:
	if body.name == "player":
		to_pull = ""
		$Level2/Label.visible = false

func _pulled_lever():
	match to_pull:
		"level_2":
			if $Level2/Lvl2Timer.is_stopped():
				$Level2/Lvl2Timer.start()
				animation_player.play("flip_lvl_2")
				$Level2/Movibles/lever/Sprite2D.texture = changing_textures.level_2.active

func _on_lvl_2_timer_timeout() -> void:
	animation_player.play_backwards("flip_lvl_2")
	$Level2/Movibles/lever/Sprite2D.texture = changing_textures.level_2.idle

func _on_lvl_2_key_area_body_entered(body: Node2D) -> void:
	if body.name == "player":
		level_key = "level_2_key"
		$Level2/Lvl2KeyArea.visible = false
		$player/Arrow.visible = false
		

func _on_open_door_lvl_2_body_entered(body: Node2D) -> void:
	if body.name == "player":
		if level_key == "level_2_key":
			save_point= ""
			level_key = ""
			levels_completed.append("level_2")
			$Level2/DoorLvl2/CollisionShape2D.position = position+ Vector2(0, 200)
			$Level2/DoorLvl2/DoorLvl2Sprite.play("Open")
			$Level2/Lvl2KeyArea.queue_free()
			$player/Arrow.visible = false

func _on_button_1_level_1_body_entered(body: Node2D) -> void:
	if body.name == "player" and !platforms_appearing.level_1.button_1.pressed:
		animation_player.play("button1_lvl1_down")

func _on_button_1_level_1_body_exited(body: Node2D) -> void:
	if body.name == "player" and !platforms_appearing.level_1.button_1.pressed:
		animation_player.pause()
		animation_player.play_backwards("button1_lvl1_down")

func _on_button_2_lvl_1_body_entered(body):
	if body.name == "player" and !platforms_appearing.level_1.button_2.pressed:
		animation_player.play("button2_lvl1_down")

func _on_button_2_lvl_1_body_exited(body):
	if body.name == "player" and !platforms_appearing.level_1.button_2.pressed:
		animation_player.pause()
		animation_player.play_backwards("button2_lvl1_down")
		
func _on_change_eyes_body_exited(body):
	if body.name == "player" and !move_eyes_lvl_1:
		move_eyes_lvl_1 = true
	elif body.name == "player" and move_eyes_lvl_1:
		move_eyes_lvl_1 = false
		$Level1/Picture/Eyes.position = eyes_initial_position_lvl_1
		picture_sound_played = false

func _on_change_eyes_body_entered(body):
	if body.name == "player" and move_eyes_lvl_1:
		target_picture_lvl_1 = player

func _on_animation_player_animation_finished(anim_name):
	match anim_name:
		"button1_lvl1_down":
			if animation_player.current_animation_length == animation_player.current_animation_position:
				platforms_appearing.level_1.button_1.pressed = true
				if !platforms_appearing.level_1.button_2.activated:
					animation_player.play("free_bridge")
		"button2_lvl1_down":
			if animation_player.current_animation_length == animation_player.current_animation_position:
				platforms_appearing.level_1.button_2.pressed = true
				if !platforms_appearing.level_1.button_2.activated:
					animation_player.play("lvl1_clouds_aparition")
		"button_lvl2":
			if animation_player.current_animation_length == animation_player.current_animation_position:
				platforms_appearing.level_2.button_pressed = true
				if !platforms_appearing.level_2.platforms_out:
					animation_player.play("platform_lvl2_aparition")
					
func _on_lvl_1_key_area_body_entered(body):
	if body.name == "player":
		level_key = "level_1_key"
		$Level1/Lvl1KeyArea.visible = false
		$player/Arrow.visible = false
		


func _on_death_zone_body_entered(body):
	if body.name == "player":
		save_point = "level_1_check"
		$Level1/Lvl1KeyArea/Sprite2D.play("default")
		if !out_light:
			out_light = true
			player_light.texture_scale = max_scale_light
func _on_open_door_lvl_1_body_entered(body):
	if body.name == "player":
		if level_key == "level_1_key":
			save_point = ""
			level_key = ""
			levels_completed.append("level_1")
			$Level1/DoorLvl1/CollisionShape2D.position = position+ Vector2(0, 200)
			$Level1/DoorLvl1/AnimatedSprite2D.play("Open")
			$Level1/Lvl1KeyArea.queue_free()
			$player/Arrow.visible = false

func _arrow_direction():
	var arrow = $player/Arrow
	var key : Node2D
	
	match save_point:
		"level_1_check":
			key = $Level1/Lvl1KeyArea
			arrow.visible = true
		"level_2_check":
			key = $Level2/Lvl2KeyArea
			arrow.visible = true
		_:
			arrow.visible = false
	
	if key != null:
		var direction = (key.global_position - player.global_position).normalized()
		arrow.global_rotation = direction.angle() + PI / 2
	if level_key != "":
		arrow.visible = false

func _on_reloj_detector_body_exited(body):
	if body.name == "player" and !clock_follow_target: 
		clock_follow_target = true
	else:
		clock_follow_target = false


func _on_play_button_pressed():
	run_start = true
	player_can_move = true

func _relocate_camera():
	if save_point == "level_1_check":
		var tween_position = create_tween()
		var tween_zoom = create_tween()
		tween_zoom.tween_property(camera_2d,"zoom", Vector2(2.5, 2.5),1.0)
		tween_position.tween_property(camera_2d, "position", player.global_position, 1.0)
		await tween_position.finished
		await tween_zoom.finished
		out_light= true
		levels_showed.append("lvl_1")
		$"CameraMove timer".stop()
		showing_level = false
		

func _on_camera_move_timer_timeout():
	_relocate_camera()
	if save_point == "level_1_check":
		var light_lvl1 = $Lvl1LightRef
		var tween_light = create_tween()
		tween_light.tween_property(light_lvl1, "scale", Vector2.ZERO, 1)
		await tween_light.finished
		light_lvl1.visible = false
		level_1_transition_started = false
		camera_on_player = true
		player_can_move = true
		player.process_mode = PROCESS_MODE_INHERIT
