extends Node2D

@onready var lever:Area2D = $Lever
@onready var base:Sprite2D = $Base
var mouse_on_lever:bool = false
var dragging:bool = false
signal brake


func _input(event:InputEvent) -> void:
    if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
        if mouse_on_lever:
            if not dragging and event.pressed:
                dragging = true
        if dragging and not event.pressed:
            dragging = false
    if event is InputEventMouseMotion and dragging:
        lever.rotation = clamp(base.global_position.angle_to_point(event.position) + PI*0.5, 0, PI*0.5)
        var brake_magnitude:float = lever.rotation/(PI*0.5) # [0, 1]
        emit_signal("brake", brake_magnitude)


func _on_lever_mouse_entered() -> void:
    mouse_on_lever = true


func _on_lever_mouse_exited() -> void:
    mouse_on_lever = false
