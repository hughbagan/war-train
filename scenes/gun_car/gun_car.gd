class_name GunCar extends TrainCar

@onready var turret:Sprite2D = $Turret
@onready var barrel:Node2D = $Turret/Barrel
var shoot_timer:float = 0.0
var burst_timer:float = 0.0
var shoot_interval:float = 1.0 # time between rounds in seconds
var burst_interval:float = 0.25 # time between individual shots
var burst_rounds:int = 0
var burst_max:int = 2
var damage:float = 1.0


func _ready():
	super()


func _physics_process(delta):
	super(delta)

	var dir_to_mouse = global_position.direction_to(get_global_mouse_position()).normalized()
	turret.rotation = dir_to_mouse.rotated(-PI*0.5).angle()

	shoot_timer += delta
	burst_timer += delta

	if Input.is_action_pressed("shoot"):
		if shoot_timer >= shoot_interval and burst_rounds == 0:
			burst_rounds = burst_max
		elif shoot_timer >= shoot_interval and burst_rounds > 0 and burst_timer >= burst_interval:
			level_ref.add_child(Bullet.construct(
				barrel.global_position,
				dir_to_mouse,
				damage))
			burst_timer = 0.0
			burst_rounds -= 1
			if burst_rounds == 0:
				shoot_timer = 0.0
