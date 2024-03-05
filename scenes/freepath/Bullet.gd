class_name Bullet extends CharacterBody2D

const BulletScene: PackedScene = preload("res://source/Bullet.tscn")
const speed: float = 700.0
var direction: Vector2


static func create(dir: Vector2) -> Bullet:
	var new_bullet = BulletScene.instantiate()
	new_bullet.direction = dir
	return new_bullet


func _physics_process(delta):
	velocity = direction * speed
	move_and_slide()
	if get_slide_collision_count() > 0:
		for i in get_slide_collision_count():
			var col = get_slide_collision(i).get_collider()
			print("Collided with: ", col.name)
			if is_instance_of(col, Enemy):
				col.queue_free()
		queue_free()


func _on_visible_on_screen_notifier_2d_screen_exited():
	queue_free()
