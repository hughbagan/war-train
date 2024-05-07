class_name TrainCar extends CharacterBody2D

@onready var level_ref:Node2D = find_parent("Level")
@onready var tile_size:float = level_ref.get_node("NavigationRegion2D/Screen0").tile_set.tile_size.x
@onready var map:RID = get_world_2d().navigation_map
@onready var cars:Array[Node] = get_parent().get_children()
@onready var anim:AnimatedSprite2D = $AnimatedSprite2D
@onready var agent:NavigationAgent2D = $NavigationAgent2D
@onready var sprite:Sprite2D = $Sprite2D
const MAX_SPEED:float = 80.0
var current_speed:float = 0.0
var target_speed:float = 0.0
var acceleration:float = 0.0
var braking:bool = true
var brake_magnitude:float = 1.0
var hp:float = 100.0
var collided:bool = false
var dead:bool = false
signal level_camera_exited


func _ready() -> void:
	await level_ref.ready
	level_ref.brake_lever.brake.connect(_on_brake)
	call_deferred("wait_for_navserver")


func wait_for_navserver() -> void:
	await get_tree().process_frame
	# FIXME: wont always be going to the right to start
	agent.target_position = Vector2(global_position.x+64, global_position.y)


func _process(_delta) -> void:
	if dead:
		sprite.modulate = Color(0.5, hp/100.0, hp/100.0)
	else:
		sprite.modulate = Color(1.0, hp/100.0, hp/100.0)


func _physics_process(delta) -> void:
	if dead:
		pass

	var dir = velocity.normalized().round()

	# Adjust speed based on the brake and hostile collisions
	target_speed = round(abs(MAX_SPEED - (brake_magnitude*MAX_SPEED)))
	acceleration = (target_speed - current_speed)/4
	if collided and current_speed > (MAX_SPEED/2):
		acceleration -= 10.0 # additive
		collided = false
		current_speed += acceleration * delta
	elif current_speed != target_speed:
		current_speed += acceleration * delta
		if abs(current_speed - target_speed) < 5.0: # clamp
			current_speed = target_speed

	# Handle next track tile
	if agent.is_navigation_finished() and velocity != Vector2() and cars[0] == self:
		# try to keep going straight, or turn left or right
		var current:Vector2 = round_to_tile(global_position)
		var next_point_check:Vector2 = current
		var next_point:Vector2 = current
		match dir:
			Vector2(1, 0):
				next_point_check.x += tile_size*0.5 + 2
				next_point.x += tile_size
			Vector2(-1, 0):
				next_point_check.x -= tile_size*0.5 + 2
				next_point.x -= tile_size
			Vector2(0, 1):
				next_point_check.y += tile_size*0.5 + 2
				next_point.y += tile_size
			Vector2(0, -1):
				next_point_check.y -= tile_size*0.5 + 2
				next_point.y -= tile_size
		if not point_on_tracks(next_point_check):
			# assuming we hit a corner -- we need to turn!
			var check1 = current # peek first pixels of next tile for navmesh
			var check2 = current
			var point1 = global_position # the point to goto if check succeeds
			var point2 = global_position
			match dir:
				Vector2(1, 0), Vector2(-1, 0):
					check1.y += tile_size*0.5 + 2
					check2.y -= tile_size*0.5 + 2
					point1.y += tile_size
					point2.y -= tile_size
				Vector2(0, 1), Vector2(0, -1):
					check1.x += tile_size*0.5 + 2
					check2.x -= tile_size*0.5 + 2
					point1.x += tile_size
					point2.x -= tile_size
			point1 = round_to_tile(point1)
			point2 = round_to_tile(point2)
			var valid1 = point_on_tracks(check1)
			var valid2 = point_on_tracks(check2)
			if (valid1 and not valid2) \
			or (valid2 and not valid1):
				if valid1:
					agent.target_position = point1
				elif valid2:
					agent.target_position = point2
			else:
				assert(false) # two or no available paths
		else:
			# continue straight
			agent.target_position = next_point
		get_node("../../Point").global_position = agent.target_position

		# make the cars behind this one follow_behind
		var car_behind:TrainCar = get_car_behind()
		if car_behind:
			car_behind.follow_behind(round_to_tile(global_position))

	velocity = global_position.direction_to(agent.get_next_path_position()) * abs(current_speed)
	var cols = move_and_slide()
	if cols:
		for i in get_slide_collision_count():
			var col = get_slide_collision(i).get_collider()
			if col is Obstacle or col is Pinata:
				stop_train()

	if level_ref.outside_camera(global_position):
		emit_signal("level_camera_exited", global_position)


func round_to_tile(point:Vector2) -> Vector2:
	var x = (floor(point.x/tile_size)*tile_size) + tile_size*0.5
	var y = (floor(point.y/tile_size)*tile_size) + tile_size*0.5
	return Vector2(x, y) # middle of the tile


func point_on_tracks(point:Vector2) -> bool:
	return (NavigationServer2D.map_get_closest_point(map, point) - point).is_zero_approx()


func get_car_behind() -> TrainCar:
	for i in range(cars.size()):
		if cars[i] == self and i < cars.size()-1:
			return cars[i+1]
	return null


func follow_behind(target_position:Vector2) -> void:
	agent.target_position = target_position
	var car_behind:TrainCar = get_car_behind()
	if car_behind:
		car_behind.follow_behind(round_to_tile(global_position))


func stop_train() -> void:
	if cars[0] == self:
		for car in cars:
			car.current_speed = 0.0
			car.brake_magnitude = 1.0


func hit(dmg:float) -> void:
	# Called by something hostile
	if hp > 0.0:
		hp -= dmg
	if hp <= 0.0:
		dead = true
	for car in cars:
		car.collided = true


func _on_brake(_brake_magnitude:float) -> void:
	# Received brake signal and magnitude from the brake lever UI
	braking = _brake_magnitude > 0.1
	brake_magnitude = _brake_magnitude


func _on_area_2d_area_entered(area) -> void:
	if area is Froot:
		area.pickup()
	# if area.name == "TrainCollision":
	# 	var switch_point = area.get_parent().get_point(tile_size)
	# 	if point_on_tracks(switch_point):
	# 		agent.target_position = switch_point
