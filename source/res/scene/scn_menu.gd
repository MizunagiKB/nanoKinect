extends Node
# ------------------------------------------------------------------- const(s)
const SCENE_NANO_VIEWER = "res://res/scene/scn_nano_viewer.xscn"
const SCENE_NANO_EDITOR = "res://res/scene/scn_nano_editor.xscn"


# ------------------------------------------------------------------- param(s)
# ------------------------------------------------------------------- class(s)
# ---------------------------------------------------------------- function(s)
# ============================================================================
func evt_btn_viewer():

	get_tree().change_scene(SCENE_NANO_VIEWER)


# ============================================================================
func evt_btn_editor():

	get_tree().change_scene(SCENE_NANO_EDITOR)


# ============================================================================
func _ready():

	get_node("btn_viewer").connect("pressed", self, "evt_btn_viewer")
	get_node("btn_editor").connect("pressed", self, "evt_btn_editor")



# [EOF]
