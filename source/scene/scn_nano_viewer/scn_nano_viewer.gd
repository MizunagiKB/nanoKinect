extends Node


func evt_btn_return():

	get_tree().change_scene("res://scene/scn_menu/scn_menu.scn")


func _ready():

	get_node("btn_return").connect("pressed", self, "evt_btn_return")



# [EOF]
