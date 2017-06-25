extends Node
# ------------------------------------------------------------------- const(s)
const MOTION_REEL_LIST = [
	{"filename": "res://res/chara/motion/motion_data_1.json", "size": 636},
	{"filename": "res://res/chara/motion/motion_data_2.json", "size": 945},
	{"filename": "res://res/chara/motion/motion_data_3.json", "size": 720}
]
const EFX_SCREEN_LIST = [
	"efx_screen/off",
	"efx_screen/mosaic",
	"efx_screen/sepia",
	"efx_screen/negative",
	"efx_screen/normalize",
	"efx_screen/wave"
]
const model_common_class = preload("res://scr/lib/model_common.gd")
const model_extra_class = preload("res://scr/lib/model_extra.gd")
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
var o_im = null
var o_ma = FixedMaterial.new()

var model_common = null
var model_extra = null
var current_motion_reel = []
var current_frame = 0
var current_joint_type = ""
var dict_o_ui = {}

var mouse_drag = false
var mouse_drag_pos = Vector2(0, 0)
var mouse_drag_rot = 0
var mouse_drag_len = 1


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

	get_node("ui/scr_position").set_min(0)
	get_node("ui/scr_position").set_max(dict_item.size - 1)
	get_node("ui/scr_position").set_value(0)

	current_frame = 0


# ============================================================================
func set_remap_value(dict_rot):

	for axis_name in ["x", "y", "z"]:
		var slider = "ui/slider_%s" % [axis_name]
		var input1 = "ui/slider_%s/input_%s" % [axis_name, axis_name]

		get_node(slider).set_value(dict_rot[axis_name])
		get_node(input1).set_text(str(dict_rot[axis_name]))


# ============================================================================
func evt_item_selected_joint(index):

	current_joint_type = get_node("ui/itemlist_joint").get_item_text(index)

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

	get_node("ui/slider_w").set_value(model_common.joint_adj["W_SCALE"])
	get_node("ui/slider_w/input_w").set_text(str(model_common.joint_adj["W_SCALE"]))

	get_node("ui/slider_h").set_value(model_common.joint_adj["H_SCALE"])
	get_node("ui/slider_h/input_h").set_text(str(model_common.joint_adj["H_SCALE"]))


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

	model_common.update_axis_src(pose, get_node("ui/chk_kinect_joint").is_pressed())
	model_common.update_pose(pose, get_node("ui/chk_model").is_pressed())
	model_common.update_axis_dst(pose, get_node("ui/chk_model_joint").is_pressed())

	#model_extra.update(model_common.model, model_common.skeleton)

	# frame update
	get_node("ui/label_frame").set_text(str(current_frame))
	get_node("ui/label_fps").set_text(str(Performance.get_monitor(Performance.TIME_FPS)))

	if get_node("ui/btn_auto").is_pressed() == true:
		get_node("ui/scr_position").set_value(current_frame)
		current_frame += 1

	"""
	o_im.set_material_override(o_ma)
	o_im.clear()
	o_im.begin(Mesh.PRIMITIVE_LINES)
	o_im.add_vertex(Vector3(-10, 0, 0))
	o_im.add_vertex(Vector3(10, 0, 0))
	o_im.add_vertex(Vector3(0, 0, -10))
	o_im.add_vertex(Vector3(0, 0, 10))
	o_im.end()
	"""


# ============================================================================
func create_camera_pos(length, deg):
	var vct_result = Vector3(sin(deg2rad(deg)), 0, cos(deg2rad(deg))) * length

	return vct_result


# ============================================================================
func _input(event):

	if event.type == InputEvent.MOUSE_MOTION:
		if mouse_drag:
			get_node("Camera").look_at_from_pos(
				create_camera_pos(
					mouse_drag_len,
					mouse_drag_rot + (event.pos.x - mouse_drag_pos.x)
				),
				Vector3(0, 0, 0),
				Vector3(0, 1, 0)
			)

	if event.type == InputEvent.MOUSE_BUTTON:
		if event.pressed and event.button_index == BUTTON_LEFT:
			var rc = get_node("ui/ReferenceFrame").get_rect()
			if rc.has_point(event.pos):
				mouse_drag_pos = event.pos
				mouse_drag = true
		elif event.button_index == BUTTON_WHEEL_UP:
			mouse_drag_len -= 0.2
			get_node("Camera").look_at_from_pos(
				create_camera_pos(
					mouse_drag_len,
					mouse_drag_rot
				),
				Vector3(0, 0, 0),
				Vector3(0, 1, 0)
			)
		elif event.button_index == BUTTON_WHEEL_DOWN:
			mouse_drag_len += 0.2
			get_node("Camera").look_at_from_pos(
				create_camera_pos(
					mouse_drag_len,
					mouse_drag_rot
				),
				Vector3(0, 0, 0),
				Vector3(0, 1, 0)
			)
		else:
			if mouse_drag:
				mouse_drag_rot += (event.pos.x - mouse_drag_pos.x)
				mouse_drag = false


# ============================================================================
func _ready():

	o_im = get_node("ImmediateGeometry")
	o_ma.set_line_width(1)
	o_ma.set_point_size(1)
	o_ma.set_fixed_flag(FixedMaterial.FLAG_USE_POINT_SIZE, true)
	o_ma.set_flag(Material.FLAG_UNSHADED, true)

	for item in MOTION_REEL_LIST:
		get_node("ui/optbtn_motion").add_item(item["filename"])

	for efx in EFX_SCREEN_LIST:
		get_node("ui/optbtn_screen_shader").add_item(efx)

	setup_motion_data(0)

	# ------------------------------------------------------------------------

	model_common = model_common_class.new()
	var o_model = model_common.model_load(self, "TsukumoMil")

	add_child(o_model)

	model_extra = model_extra_class.new()
	model_extra.setup(o_model, model_common.skeleton)

	for name in JOINT_TYPE_FOR_EDITOR:
		get_node("ui/itemlist_joint").add_item(name)

	get_node("ui/itemlist_joint").connect("item_selected", self, "evt_item_selected_joint")

	for axis_name in ["x", "y", "z"]:
		var o_ui = CUIEvent.new()
		var slider = "ui/slider_%s" % [axis_name]
		var input1 = "ui/slider_%s/input_%s" % [axis_name, axis_name]

		o_ui.initialize(
			self,
			get_node(slider),
			get_node(input1)
		)

		dict_o_ui[axis_name] = o_ui

	evt_item_selected_joint(0)

	set_process(true)
	set_process_input(true)


# ============================================================================
func _on_btn_return_pressed():

	get_tree().change_scene("res://res/scene/scn_menu.xscn")


# ============================================================================
func _on_btn_adj_save_pressed():

	model_common.adj_save()


# ============================================================================
func _on_optbtn_motion_item_selected(index):

	setup_motion_data(index)


# ============================================================================
func _on_optbtn_screen_shader_item_selected(index):

	for efx in EFX_SCREEN_LIST:
		get_node(efx).hide()

	get_node(get_node("ui/optbtn_screen_shader").get_text()).show()


# ============================================================================
func _on_slider_w_value_changed( value ):
	get_node("ui/slider_w/input_w").set_text(str(value))

	if current_joint_type != null:
		model_common.joint_adj["W_SCALE"] = float(get_node("ui/slider_w/input_w").get_text())


# ============================================================================
func _on_slider_h_value_changed( value ):
	get_node("ui/slider_h/input_h").set_text(str(value))

	if current_joint_type != null:
		model_common.joint_adj["H_SCALE"] = float(get_node("ui/slider_h/input_h").get_text())


# ============================================================================
func _on_scr_position_value_changed( value ):
	current_frame = value



# [EOF]
