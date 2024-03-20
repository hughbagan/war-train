extends Node2D

@onready var train:TrainCar = $Train/TrainCar
@onready var camera:Camera2D = $Camera2D


func _ready():
    train.screen_exited.connect(_on_train_screen_exited)


func _on_train_screen_exited(train_position:Vector2) -> void:
    var size:float = get_viewport_rect().size.x
    var new_camera_pos = camera.position
    if train_position.x > camera.position.x+size:
        new_camera_pos.x += size
    elif train_position.x < camera.position.x:
        new_camera_pos.x -= size
    elif train_position.y > camera.position.y+size:
        new_camera_pos.y += size
    elif train_position.y < camera.position.y:
        new_camera_pos.y -= size
    else:
        return
    var camerapos_tween = get_tree().create_tween()
    camerapos_tween.tween_property(camera, "position", new_camera_pos, 0.5)
