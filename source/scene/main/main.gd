extends Node
# ------------------------------------------------------------------- const(s)
const STARTUP_SCENE = "res://scene/scn_menu/scn_menu.scn"


# ------------------------------------------------------------------- param(s)
# ------------------------------------------------------------------- class(s)
# ---------------------------------------------------------------- function(s)
# ============================================================================
func _ready():
	""" scene ready
	"""

	var o_scene = load(STARTUP_SCENE).instance()

	get_node("scene").add_child(o_scene)



# [EOF]
