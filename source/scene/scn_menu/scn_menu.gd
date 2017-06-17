extends Node


func evt_btn_viewer():

	get_tree().change_scene("res://scene/scn_nano_viewer/scn_nano_viewer.scn")


func evt_btn_editor():

	get_tree().change_scene("res://scene/scn_nano_editor/scn_nano_editor.scn")


func _ready():

	get_node("btn_viewer").connect("pressed", self, "evt_btn_viewer")
	get_node("btn_editor").connect("pressed", self, "evt_btn_editor")



# [EOF]
