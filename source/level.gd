extends Node2D

@onready var path :Array[Node] = $TrainPath.get_children()

func _draw():
	for i in range(path.size()):
		if i < path.size()-1:
			draw_line(
				path[i].global_position,
				path[i+1].global_position,
				Color(0, 0, 1.0),
				5.0)
