class_name Bullet extends CharacterBody2D

@onready var level_ref:Node2D = find_parent("Level")
static var bullet_scene:Resource = load("res://scenes/bullet/bullet.tscn")
const speed:float = 1000.0
var creator:Node2D
var direction:Vector2
var damage:float


static func construct(caller:Node2D, pos:Vector2, dir:Vector2, dmg:float) -> Bullet:
    var new_bullet = bullet_scene.instantiate()
    new_bullet.creator = caller
    new_bullet.global_position = pos
    new_bullet.direction = dir
    new_bullet.damage = dmg
    return new_bullet


func _physics_process(_delta:float) -> void:
    velocity = direction * speed
    move_and_slide()
    var cols = get_slide_collision_count()
    if cols > 0:
        for i in range(cols):
            var col = get_slide_collision(i).get_collider()
            if col is Enemy:
                col.hit(creator, damage)
                queue_free()

    if level_ref.outside_camera(global_position):
        queue_free()
