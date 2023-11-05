class_name Car extends CharacterBody2D

@onready var level :Node2D = find_parent("Level")
@onready var agent :NavigationAgent2D = $NavigationAgent2D
@onready var speed_tween :Tween

var path :Array[Node] = []
var cars :Array[Car] = []
var current_node :int = 0
var current_speed :float = 0.0
var target_speed :float = current_speed
var acceleration :float = 0.0
enum Throttle {HANDBRAKE = -1, BRAKE = 0, HALF_AHEAD = 1, FULL_AHEAD = 2}
var throttle :Throttle = Throttle.BRAKE


func _ready() -> void:
	path = level.get_node("TrainPath").get_children()
	for node in get_parent().get_children():
		if node is Car:
			cars.append(node)
	# These values need to be adjusted for the actor's speed
	# and the navigation layout.
	agent.path_desired_distance = 4.0
	agent.target_desired_distance = 4.0
	# Make sure to not await during _ready.
	call_deferred("actor_setup")


func actor_setup() -> void:
	# Wait for the first physics frame so the NavigationServer can sync.
	await get_tree().physics_frame
	# Now that the navigation map is no longer empty, set the movement target.
	if self == cars[0]:
		set_movement_target(path[current_node].global_position)
		$Camera2D.enabled = true
		$Camera2D.make_current()


func set_movement_target(movement_target: Vector2) -> void:
	agent.target_position = movement_target


func _physics_process(delta) -> void:
	if Input.is_action_just_pressed("throttle_up"):
		if throttle < Throttle.FULL_AHEAD:
			throttle = (throttle + 1) as Throttle
	if Input.is_action_just_pressed("throttle_down"):
		if throttle > Throttle.HANDBRAKE:
			throttle = (throttle - 1) as Throttle

	match(throttle):
		Throttle.HANDBRAKE:
			target_speed = -50.0
			acceleration = -15.0
		Throttle.BRAKE:
			target_speed = 0.0
			if current_speed > 0:
				acceleration = -10.0
			else:
				acceleration = 5.0
		Throttle.HALF_AHEAD:
			target_speed = 30.0
			acceleration = 5.0
		Throttle.FULL_AHEAD:
			target_speed = 150.0
			acceleration = 10.0

	var prev_speed = current_speed
	if current_speed != target_speed:
		current_speed += acceleration * delta
		if abs(current_speed - target_speed) <= 5.0:
			current_speed = target_speed

	if current_speed < 0 and prev_speed > 0:
		current_node -= 1
		set_movement_target(path[current_node].global_position)
	elif current_speed > 0 and prev_speed < 0:
		current_node += 1
		set_movement_target(path[current_node].global_position)
	# Advance along the path
	elif global_position.distance_to(path[current_node].global_position) < 4.0:
		if current_speed >= 0:
			if current_node+1 <= path.size():
				current_node += 1
				set_movement_target(path[current_node].global_position)
		else:
			if current_node-1 >= 0:
				current_node -= 1
				set_movement_target(path[current_node].global_position)

#	if agent.is_navigation_finished():
#		return

	var current_agent_position: Vector2 = global_position
	var next_path_position: Vector2 = agent.get_next_path_position()
	var dir :Vector2 = (next_path_position - current_agent_position).normalized()
	velocity = dir * abs(current_speed)
	move_and_slide()

	#$Sprite2D.rotation = dir.angle()

	$Label.text = "\n"+str(throttle)+"  "+str(current_node)


func _on_area_exited(area:Area2D) -> void:
	for i in range(1, cars.size()):
		if cars[i] == self:
			if area.get_parent() == cars[i-1]: # previous car is leaving, follow it
				set_movement_target(path[current_node].global_position)

