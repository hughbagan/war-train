class_name Enemy extends CharacterBody2D

enum States {SENTRY, FOLLOW}
var state:States = States.SENTRY
var following:Node2D
@onready var sprite:Sprite2D = $Sprite2D
@onready var size:float = sprite.texture.get_size().x
var scale_x:float = 0.0
var movespeed:float = 100.0
var hp:float = 4.0
var damage:float = 1.0


func _ready():
    scale_x = randf_range(0.0, PI)


func _process(delta):
    # make the sprite "breathe"
    scale_x += delta
    var sin_x = (sin(scale_x*2)+16)/16
    sprite.scale = Vector2(sin_x, sin_x)


func _physics_process(_delta):
    match(state):
        States.SENTRY:
            pass
        States.FOLLOW:
            var dir_to_follow = global_position.direction_to(following.global_position)
            velocity = dir_to_follow.normalized() * movespeed
            move_and_slide()
            var cols = get_slide_collision_count()
            if cols > 0:
                for i in range(cols):
                    var col = get_slide_collision(i)
                    if col is TrainCar:
                        col.hit(damage)


func _on_sentry_area_body_entered(body:Node2D):
    print(body)
    if body is TrainCar:
        print("    ", body)
        state = States.FOLLOW
        following = body


func hit(dmg:int) -> void:
    hp -= dmg
    if hp <= 0:
        queue_free()
