class_name TrainCar extends CharacterBody2D

@onready var level_ref:Node2D = get_node("../..")
@onready var anim:AnimatedSprite2D = $AnimatedSprite2D
@onready var agent:NavigationAgent2D = $NavigationAgent2D
@onready var tile_size:float = get_node("../../NavigationRegion2D/TileMap").tile_set.tile_size.x
@onready var map:RID = get_world_2d().navigation_map
@onready var cars:Array[Node] = get_parent().get_children()
var current_speed:float = 0.0
var target_speed:float = 0.0
var acceleration:float = 0.0
enum Throttle {HANDBRAKE=-1, BRAKE=0, HALF_AHEAD=1, FULL_AHEAD=2}
var throttle:Throttle = Throttle.BRAKE


func _ready():
	call_deferred("wait_for_navserver")


func wait_for_navserver():
	await get_tree().process_frame
	# FIXME: wont always be going to the right to start
	agent.target_position = Vector2(global_position.x+64, global_position.y)


func _physics_process(delta):
	var dir = velocity.normalized().round()

	# Throttling
	if Input.is_action_just_pressed("throttle_up"):
		if throttle < Throttle.FULL_AHEAD:
			throttle = (throttle+1) as Throttle
	if Input.is_action_just_pressed("throttle_down"):
		if throttle > Throttle.HANDBRAKE:
			throttle = (throttle-1) as Throttle
	match(throttle):
		Throttle.HANDBRAKE:
			target_speed = -30.0
			acceleration = -15.0
		Throttle.BRAKE:
			target_speed = 0.0
			if current_speed > 0.0:
				acceleration = -10.0
		Throttle.HALF_AHEAD:
			target_speed = 30.0
			if current_speed > target_speed:
				acceleration = -5.0
			else:
				acceleration = 5.0
		Throttle.FULL_AHEAD:
			target_speed = 80.0
			acceleration = 10.0
	var prev_speed := current_speed
	if current_speed != target_speed:
		current_speed += acceleration * delta
		if abs(current_speed - target_speed) < 5.0: # clamp
			current_speed = target_speed

	# Reversing (forward is default)
	if ((current_speed < 0 and prev_speed >= 0) \
	or (current_speed > 0 and prev_speed < 0)):
		if cars[0] == self:
			cars.reverse()
			var new_agent_target:Vector2 = cars[0].global_position
			match dir:
				Vector2(1, 0):
					new_agent_target.x -= tile_size
				Vector2(-1, 0):
					new_agent_target.x += tile_size
				Vector2(0, 1):
					new_agent_target.y -= tile_size
				Vector2(0, -1):
					new_agent_target.y += tile_size
				_:
					assert(false)
			print(cars)
			cars[0].agent.target_position = round_to_tile(new_agent_target)
			var car_behind:TrainCar = cars[0].get_car_behind()
			if car_behind:
				car_behind.follow_behind(round_to_tile(cars[0].global_position))
		else:
			cars.reverse()

	# Handle next track tile
	if agent.is_navigation_finished() and velocity != Vector2() and cars[0] == self:
		# try to keep going straight, or turn left or right
		var next_point = global_position
		match dir:
			Vector2(1, 0):
				next_point.x += tile_size
			Vector2(-1, 0):
				next_point.x -= tile_size
			Vector2(0, 1):
				next_point.y += tile_size
			Vector2(0, -1):
				next_point.y -= tile_size
		next_point = round_to_tile(next_point)
		if not point_on_tracks(next_point):
			# assuming we hit a corner -- we need to turn!
			var point1 = global_position
			var point2 = global_position
			match dir:
				Vector2(1, 0), Vector2(-1, 0):
					point1.y += tile_size
					point2.y -= tile_size
				Vector2(0, 1), Vector2(0, -1):
					point1.x += tile_size
					point2.x -= tile_size
			point1 = round_to_tile(point1)
			point2 = round_to_tile(point2)
			var valid1 = point_on_tracks(point1)
			var valid2 = point_on_tracks(point2)
			if (valid1 and not valid2) \
			or (valid2 and not valid1):
				if valid1:
					agent.target_position = point1
				elif valid2:
					agent.target_position = point2
			else:
				pass #assert(false)
		else:
			# continue straight
			agent.target_position = next_point

		# make the cars behind this one follow_behind
		var car_behind:TrainCar = get_car_behind()
		if car_behind:
			car_behind.follow_behind(round_to_tile(global_position))

	velocity = global_position.direction_to(agent.get_next_path_position()) * abs(current_speed)
	move_and_slide()

	# match dir:
	# 	Vector2(1, 0):
	# 		anim.play("right")
	# 	Vector2(-1, 0):
	# 		anim.play("left")
	# 	Vector2(0, 1):
	# 		anim.play("down")
	# 	Vector2(0, -1):
	# 		anim.play("up")


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


func _on_area_2d_area_entered(area):
	if area.name == "TrainCollision":
		var switch_point = area.get_parent().get_point(tile_size)
		if point_on_tracks(switch_point):
			agent.target_position = switch_point
