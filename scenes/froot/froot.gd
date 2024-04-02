class_name Froot extends Area2D

static var froot_scene:Resource = load("res://scenes/froot/froot.tscn")
@onready var level_ref:Node2D = get_node("/root/Level")


static func construct(pos:Vector2) -> Froot:
    var new_froot = froot_scene.instantiate()
    new_froot.position = pos
    return new_froot


func pickup() -> void:
    # signal instead? Not clear since Froots are created during runtime...
    level_ref.score_up(1)
    queue_free()


func _on_mouse_entered() -> void:
    pickup()
