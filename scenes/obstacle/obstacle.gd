class_name Obstacle extends StaticBody2D

var hp:int = 4

func hit(_bullet_owner:Node2D, dmg:int) -> void:
    hp -= dmg
    if hp <= 0:
        queue_free()
