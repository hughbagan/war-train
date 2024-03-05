class_name TrainCar extends CharacterBody2D

@onready var anim:AnimatedSprite2D = $AnimatedSprite2D
@onready var agent:NavigationAgent2D = $NavigationAgent2D
@onready var tile_size:float = get_node("../../NavigationRegion2D/TileMap").tile_set.tile_size.x
@onready var map:RID = get_world_2d().navigation_map
@onready var cars:Array[Node] = get_parent().get_children()
@export var movespeed:float = 100.0


func _ready():
	call_deferred("wait_for_navserver")


func wait_for_navserver():
	await get_tree().process_frame
	agent.target_position = Vector2(global_position.x+64, global_position.y)


func _physics_process(_delta):
	var dir = velocity.normalized().round()

	# match dir:
	# 	Vector2(1, 0):
	# 		anim.play("right")
	# 	Vector2(-1, 0):
	# 		anim.play("left")
	# 	Vector2(0, 1):
	# 		anim.play("down")
	# 	Vector2(0, -1):
	# 		anim.play("up")

	if agent.is_navigation_finished() and velocity != Vector2() and cars[0] == self:
		# try to keep going straight, or turn left or right
		var next_point = global_position
		match dir:
			Vector2(1, 0):
				next_point = Vector2(next_point.x + tile_size, next_point.y)
			Vector2(-1, 0):
				next_point = Vector2(next_point.x - tile_size, next_point.y)
			Vector2(0, 1):
				next_point = Vector2(next_point.x, next_point.y + tile_size)
			Vector2(0, -1):
				next_point = Vector2(next_point.x, next_point.y - tile_size)
		next_point = round_to_tile_size(next_point)
		if not point_on_tracks(next_point):
			# assuming we hit a corner -- we need to turn!
			var point1
			var point2
			match dir:
				Vector2(1, 0), Vector2(-1, 0):
					point1 = Vector2(global_position.x, global_position.y + tile_size)
					point2 = Vector2(global_position.x, global_position.y - tile_size)
				Vector2(0, 1), Vector2(0, -1):
					point1 = Vector2(global_position.x + tile_size, global_position.y)
					point2 = Vector2(global_position.x - tile_size, global_position.y)
			point1 = round_to_tile_size(point1)
			point2 = round_to_tile_size(point2)
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

		# make the cars behind this one follow
		var car_behind:TrainCar = get_car_behind()
		if car_behind:
			car_behind.follow(round_to_tile_size(global_position))

	velocity = global_position.direction_to(agent.get_next_path_position()) * movespeed
	move_and_slide()


func round_to_tile_size(point:Vector2) -> Vector2:
	return point.snapped(Vector2(tile_size*0.5, tile_size*0.5))


func point_on_tracks(point:Vector2) -> bool:
	return (NavigationServer2D.map_get_closest_point(map, point) - point).is_zero_approx()


func get_car_behind() -> TrainCar:
	for i in range(cars.size()):
		if cars[i] == self and i < cars.size()-1:
			return cars[i+1]
	return null


func follow(target_position:Vector2) -> void:
	agent.target_position = target_position
	var car_behind:TrainCar = get_car_behind()
	if car_behind:
		car_behind.follow(round_to_tile_size(global_position))


func _on_area_2d_area_entered(area):
	if area.name == "TrainCollision":
		var switch_point = area.get_parent().get_point(tile_size)
		if point_on_tracks(switch_point):
			agent.target_position = switch_point
