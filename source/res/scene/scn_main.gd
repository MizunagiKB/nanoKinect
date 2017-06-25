extends Node
# ----------------------------------------------------------------------------


func _ready():

	var scene = load("res://res/scene/scn_menu.xscn").instance()

	get_node("view").add_child(scene)


# [EOF]
