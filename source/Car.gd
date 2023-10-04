class_name Car extends CharacterBody2D

@onready var level :Node2D = find_parent("Level")
@onready var agent :NavigationAgent2D = $NavigationAgent2D

var path :Array[Node] = []
var cars :Array[Car] = []
var current_node: int = 0
var movement_speed: float = 20.0


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
	#print(self, cars)
	if self == cars[0]:
		set_movement_target(path[current_node].global_position)
		$Camera2D.make_current()
		$Camera2D.enabled = true


func set_movement_target(movement_target: Vector2) -> void:
	agent.target_position = movement_target


func _physics_process(delta) -> void:
	if agent.is_navigation_finished():
		return

	var current_agent_position: Vector2 = global_position
	var next_path_position: Vector2 = agent.get_next_path_position()
	var new_velocity: Vector2 = next_path_position - current_agent_position
	var dir = new_velocity.normalized()
	new_velocity = dir * movement_speed
	velocity = new_velocity
	move_and_slide()

	$Sprite2D.rotation = dir.angle()

	# Advance along the path
	if global_position.distance_to(path[current_node].global_position) < 4:
		if current_node+1 < path.size():
			current_node += 1
			set_movement_target(path[current_node].global_position)


func _on_area_exited(area:Area2D) -> void:
	for i in range(1, cars.size()):
		if cars[i] == self:
			if area.get_parent() == cars[i-1]: # previous car is leaving, follow it
				set_movement_target(path[current_node].global_position)

