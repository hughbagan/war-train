class_name Level extends Node2D

@onready var brake_lever:Node2D = $UI/BrakeLever
@onready var train:TrainCar = $Train/TrainCar
@onready var camera:Camera2D = $Camera2D
@onready var camera_size:Vector2 = get_viewport_rect().size / camera.zoom
@onready var score_label:Label = $UI/ScoreLabel
@onready var time_label:Label = $UI/TimeLabel
var time:float = 0.0
var score:int = 0


func _ready() -> void:
    train.level_camera_exited.connect(_on_train_level_camera_exited)
    score_label.hide()
    if OS.is_debug_build():
        time_label.show()


func _process(delta) -> void:
    time += delta
    time_label.text = str(round(time))


func outside_camera(global_pos:Vector2) -> bool:
    return global_pos.x > camera.position.x+camera_size.x \
        or global_pos.x < camera.position.x \
        or global_pos.y > camera.position.y+camera_size.y \
        or global_pos.y < camera.position.y


func _on_train_level_camera_exited(train_position:Vector2) -> void:
    var new_camera_pos = camera.position
    if train_position.x > camera.position.x+camera_size.x:
        new_camera_pos.x += camera_size.x
    elif train_position.x < camera.position.x:
        new_camera_pos.x -= camera_size.x
    elif train_position.y > camera.position.y+camera_size.y:
        new_camera_pos.y += camera_size.y
    elif train_position.y < camera.position.y:
        new_camera_pos.y -= camera_size.y
    else:
        return
    var camerapos_tween = get_tree().create_tween()
    camerapos_tween.tween_property(camera, "position", new_camera_pos, 0.5)


func score_up(value:int) -> void:
    score += value
    score_label.text = str(score)
    score_label.show()
