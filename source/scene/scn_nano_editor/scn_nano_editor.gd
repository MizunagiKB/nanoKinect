extends Node
# ------------------------------------------------------------------- const(s)
const MOTION_REEL_LIST = [
	{"filename": "res://data/motion/motion_data_1.json", "size": 636},
	{"filename": "res://data/motion/motion_data_2.json", "size": 945},
	{"filename": "res://data/motion/motion_data_3.json", "size": 720}
]
const model_common_class = preload("res://scene/scn_model/model_common.gd")
const model_extra_class = preload("res://scene/scn_model/model_extra.gd")
const TransoformAxis = Transform(
	Vector3(1, 0, 0),
	Vector3(0, 1, 0),
	Vector3(0, 0, 1),
	Vector3(0, 0, 0)
)
const JOINT_TYPE_FOR_EDITOR = [
	"SPINE_BASE",
	"SPINE_MID",
	"SPINE_NECK",
	"SPINE_SHOULDER",

	"SHOULDER",
	"ELBOW",
	"WRIST",

	"HIP",
	"KNEE",
	"ANKLE",
]


# ------------------------------------------------------------------- param(s)
var model_common = null
var model_extra = null
var current_motion_reel = []
var current_frame = 0
var current_joint_type = ""
var dict_o_ui = {}


# ------------------------------------------------------------------- class(s)
class CUIEvent:

	var o_parent = null
	var o_slider = null
	var o_input1 = null

	func initialize(o_parent, o_slider, o_input1):
		self.o_parent = o_parent
		self.o_slider = o_slider
		self.o_input1 = o_input1
		self.o_slider.connect("value_changed", self, "value_changed")

	func value_changed(value):
		self.o_input1.set_text(str(value))
		self.o_parent.update_remap()


# ---------------------------------------------------------------- function(s)
# ============================================================================
func setup_motion_data(index):

	var dict_item = MOTION_REEL_LIST[index]

	var h_reader = File.new()
	h_reader.open(dict_item.filename, File.READ)

	var dict_reel = {}

	current_motion_reel = []
	dict_reel.parse_json(h_reader.get_as_text())
	for n_frame in range(dict_item.size):
		current_motion_reel.append(dict_reel[str(n_frame)])
	h_reader.close()

	get_node("scr_position").set_min(0)
	get_node("scr_position").set_max(dict_item.size - 1)
	get_node("scr_position").set_value(0)

	current_frame = 0


# ============================================================================
func set_remap_value(dict_rot):

	for axis_name in ["x", "y", "z"]:
		var slider = "slider_%s" % [axis_name]
		var input1 = "slider_%s/input_%s" % [axis_name, axis_name]

		get_node(slider).set_value(dict_rot[axis_name])
		get_node(input1).set_text(str(dict_rot[axis_name]))


# ============================================================================
func evt_item_selected_joint(index):

	current_joint_type = get_node("itemlist_joint").get_item_text(index)

	var joint_type = current_joint_type

	if joint_type in ["SHOULDER", "ELBOW", "WRIST", "HIP", "KNEE", "ANKLE"]:
		joint_type = "%s_RIGHT" % [current_joint_type]

	set_remap_value(
		{
			"x": model_common.joint_adj[joint_type][0],
			"y": model_common.joint_adj[joint_type][1],
			"z": model_common.joint_adj[joint_type][2]
		}
	)


# ============================================================================
func update_remap():

	if current_joint_type in ["SPINE_BASE", "SPINE_MID", "SPINE_NECK", "SPINE_SHOULDER"]:
		model_common.joint_adj[current_joint_type] = [
			int(dict_o_ui.x.o_input1.get_text()),
			int(dict_o_ui.y.o_input1.get_text()),
			int(dict_o_ui.z.o_input1.get_text())
		]
	elif current_joint_type in ["SHOULDER", "ELBOW", "WRIST", "HIP", "KNEE", "ANKLE"]:
		model_common.joint_adj["%s_RIGHT" % [current_joint_type]] = [
			int(dict_o_ui.x.o_input1.get_text()),
			int(dict_o_ui.y.o_input1.get_text()),
			int(dict_o_ui.z.o_input1.get_text())
		]
		model_common.joint_adj["%s_LEFT" % [current_joint_type]] = [
			360 - int(dict_o_ui.x.o_input1.get_text()),
			360 - int(dict_o_ui.y.o_input1.get_text()),
			360 - int(dict_o_ui.z.o_input1.get_text())
		]


# ============================================================================
func _process(delta):

	if current_frame >= current_motion_reel.size():
		current_frame = 0

	var pose = current_motion_reel[current_frame]

	var dict_joint_collection = model_common.build_joint_collection(pose)

	model_common.update_axis_src(pose, get_node("chk_kinect_joint").is_pressed())
	model_common.update_pose(pose, get_node("chk_model").is_pressed())
	model_common.update_axis_dst(pose, get_node("chk_model_joint").is_pressed())

	model_extra.update(model_common.model, model_common.skeleton)

	# frame update
	get_node("label_frame").set_text(str(current_frame))
	get_node("label_fps").set_text(str(Performance.get_monitor(Performance.TIME_FPS)))

	if get_node("btn_auto").is_pressed() == true:
		get_node("scr_position").set_value(current_frame)
		current_frame += 1


# ============================================================================
func _ready():

	get_node("btn_return").connect("pressed", self, "evt_btn_return")

	for item in MOTION_REEL_LIST:
		get_node("optbtn_motion").add_item(item["filename"])

	get_node("optbtn_screen_shader").add_item("Node/off")
	get_node("optbtn_screen_shader").add_item("Node/noise")
	get_node("optbtn_screen_shader").add_item("Node/blur")
	get_node("optbtn_screen_shader").add_item("Node/mosaic")
	get_node("optbtn_screen_shader").add_item("Node/wave")

	get_node("scr_position").connect("value_changed", self, "evt_value_changed_position")

	get_node("btn_adj_save").connect("pressed", self, "evt_btn_adj_save")

	setup_motion_data(0)

	# ------------------------------------------------------------------------

	var o_model = load("res://scene/scn_model/hutyakiti/model.scn").instance()

	add_child(o_model)

	model_common = model_common_class.new()
	model_common.model_load(self, o_model, "hutyakiti")

	model_extra = model_extra_class.new()
	model_extra.setup(o_model, model_common.skeleton)

	for name in JOINT_TYPE_FOR_EDITOR:
		get_node("itemlist_joint").add_item(name)

	get_node("itemlist_joint").connect("item_selected", self, "evt_item_selected_joint")

	for axis_name in ["x", "y", "z"]:
		var o_ui = CUIEvent.new()
		var slider = "slider_%s" % [axis_name]
		var input1 = "slider_%s/input_%s" % [axis_name, axis_name]

		o_ui.initialize(
			self,
			get_node(slider),
			get_node(input1)
		)

		dict_o_ui[axis_name] = o_ui

	set_process(true)


# ============================================================================
func _on_btn_return_pressed():

	get_tree().change_scene("res://scene/scn_menu/scn_menu.scn")


# ============================================================================
func _on_btn_adj_save_pressed():

	model_common.adj_save()


# ============================================================================
func _on_optbtn_motion_item_selected(index):

	setup_motion_data(index)


# ============================================================================
func _on_optbtn_screen_shader_item_selected(index):

	get_node("Node/off").hide()
	get_node("Node/noise").hide()
	get_node("Node/blur").hide()
	get_node("Node/mosaic").hide()
	get_node("Node/wave").hide()

	get_node(get_node("optbtn_screen_shader").get_text()).show()


# ============================================================================
func evt_value_changed_position(value):
	current_frame = value



# [EOF]
