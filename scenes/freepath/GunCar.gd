class_name FreeGunCar extends FreeTrainCar

@onready var shoot_timer: Timer = $ShootTimer


func _ready() -> void:
	super()


func _physics_process(delta: float) -> void:
	super(delta)
	if Input.is_action_pressed("shoot") and shoot_timer.is_stopped():
		add_child(Bullet.create(global_position.direction_to(get_global_mouse_position()).normalized()))
		shoot_timer.start()


func _on_area_exited(area:Area2D) -> void:
	super(area)
