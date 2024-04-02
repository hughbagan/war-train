class_name Pinata extends StaticBody2D

@onready var size:Vector2 = $AnimatedSprite2D.sprite_frames.get_frame_texture('default', 0).get_size()
var hp:int = 10
var num_drops:int = 5

func hit(_bullet_owner:Node2D, dmg:int) -> void:
    hp -= dmg
    if hp <= 0:
        for i in range(num_drops):
            var angle = ((2*PI)/num_drops)*(i+1) + (PI/2)
            var pos = Vector2(size.x/2, 0).rotated(angle)
            get_parent().add_child(Froot.construct(position + pos))
        queue_free()
