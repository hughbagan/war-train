class_name Enemy extends CharacterBody2D

@onready var sprite:AnimatedSprite2D = $AnimatedSprite2D
@onready var size:float = sprite.sprite_frames.get_frame_texture('default', 0).get_size().x
enum States {SENTRY, FOLLOW}
var state:States = States.SENTRY
var following:Node2D
var scale_x:float = 0.0
var movespeed:float = 50.0
var hp:float = 5.0
var damage:float = 0.1


func _ready() -> void:
    scale_x = randf_range(0.0, PI)


func _process(delta) -> void:
    match(state):
        States.SENTRY:
            # make the sprite "breathe"
            scale_x += delta
            var sin_x = (sin(scale_x*2)+16)/16
            sprite.scale = Vector2(sin_x, sin_x)
        States.FOLLOW:
            # breathe faster
            scale_x += delta
            var sin_x = (sin(scale_x*8)+8)/8
            sprite.scale = Vector2(sin_x, sin_x)


func _physics_process(_delta) -> void:
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
                    var collider = col.get_collider()
                    if collider is TrainCar:
                        collider.hit(damage)


func state_follow(follow_node:Node2D) -> void:
    state = States.FOLLOW
    following = follow_node
    sprite.play()


func _on_sentry_area_body_entered(body:PhysicsBody2D) -> void:
    if body is TrainCar:
        state_follow(body)


func hit(bullet_owner:Node2D, dmg:int) -> void:
    hp -= dmg
    if hp <= 0:
        get_parent().add_child(Froot.construct(position))
        queue_free()
    state_follow(bullet_owner)
