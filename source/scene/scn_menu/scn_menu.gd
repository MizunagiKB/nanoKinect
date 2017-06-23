extends Node
# ------------------------------------------------------------------- const(s)
const SCENE_NANO_VIEWER = "res://scene/scn_nano_viewer/scn_nano_viewer.scn"
const SCENE_NANO_EDITOR = "res://scene/scn_nano_editor/scn_nano_editor.scn"


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
