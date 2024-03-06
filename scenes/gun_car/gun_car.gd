class_name GunCar extends TrainCar

@onready var shoot_timer:Timer = $ShootTimer
@onready var turret:Sprite2D = $Turret
@onready var barrel:Node2D = $Turret/Barrel


func _ready():
	super()


func _physics_process(delta):
	super(delta)

	var dir_to_mouse = global_position.direction_to(get_global_mouse_position()).normalized()
	turret.rotation = dir_to_mouse.rotated(-PI*0.5).angle()
	if Input.is_action_pressed("shoot") and shoot_timer.is_stopped():
		level_ref.add_child(Bullet.construct(barrel.global_position, dir_to_mouse))
		shoot_timer.start()
