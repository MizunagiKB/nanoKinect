extends Node
# ------------------------------------------------------------------- const(s)
const RESOURCE_BASE_URI = "res://res/chara/%s/%s"
const KINECT_SCALE = 3
const MAX_QUEUE_SIZE = 2

# ------------------------------------------------------------------- param(s)
var o_model = null
var model_name = null
var skeleton = null
var joint_map = {}
var joint_adj = {}

var AXIS_ARROW = preload("res://res/chara_axis/axis_arrow.scn")
var axis_src = {}
var axis_dst = {}

var dict_quat_history = {}


# ------------------------------------------------------------------- class(s)
class CQuatQueue:
	var list_quat = []
	func push(quatData):
		self.list_quat.push_front(quatData)
		if self.list_quat.size() > MAX_QUEUE_SIZE:
			self.list_quat.pop_back()

	func calc_avg():
		if self.list_quat.size() > 0:
			if self.list_quat.size() == 1:
				return self.list_quat[0]
			else:

				var iq = Vector3(0, 0, 0)
				for q in self.list_quat:
					var r = acos(q.w)
					iq += Vector3(
						(q.x / sin(r)) * r,
						(q.y / sin(r)) * r,
						(q.z / sin(r)) * r
					) * (1.0 / self.list_quat.size())
#					break

#				iq /= self.list_quat.size()
				var r = sqrt(iq.x * iq.x + iq.y * iq.y + iq.z * iq.z)

				#print(self.list_quat[0].slerp(self.list_quat[1], 0.5))
				#print(Quat(Vector3(iq.x / -r, iq.y / -r, iq.z / -r), r * 2))
				#print("----")

				#return self.list_quat[0].slerp(self.list_quat[1], 0.5)
				return Quat(Vector3(iq.x / r, iq.y / r, iq.z / r) * -1, r * 2)

# ---------------------------------------------------------------- function(s)
# ============================================================================
func create_joint_vct3(pose_joint):
	return Vector3(
		pose_joint.pos.x * -1,
		pose_joint.pos.y,
		pose_joint.pos.z * -1
	)


# ============================================================================
func create_joint_quat(pose_joint):
	return Quat(
		pose_joint.quat.x * -1,
		pose_joint.quat.y,
		pose_joint.quat.z * -1,
		pose_joint.quat.w
	)


# ============================================================================
func update_pose_joint(pose_joint, dict_joint_collection):

	if joint_map.map[pose_joint.joint_type].child.size() != 1:
		return

	var child_name = joint_map.map[pose_joint.joint_type].child[0]
	var vct_pos = create_joint_vct3(pose_joint)

	var quat_x = Quat(Vector3(1, 0, 0), deg2rad(joint_adj[pose_joint.joint_type][0]))
	var quat_y = Quat(Vector3(0, 1, 0), deg2rad(joint_adj[pose_joint.joint_type][1]))
	var quat_z = Quat(Vector3(0, 0, 1), deg2rad(joint_adj[pose_joint.joint_type][2]))
	var alias_name = joint_map.map[pose_joint.joint_type].alias
	var bone_index = skeleton.find_bone(alias_name)

	dict_quat_history[pose_joint.joint_type].push(dict_joint_collection[child_name].quat)
	var quat_rot = dict_quat_history[pose_joint.joint_type].calc_avg()

	if bone_index != -1:

		var tf_pose_old = skeleton.get_bone_global_pose(bone_index)
		var tf_pose_new = Transform(quat_rot * quat_x * quat_y * quat_z)

		if pose_joint.joint_type == "SPINE_BASE":
			tf_pose_new.origin.x = vct_pos.x * joint_adj.W_SCALE
			tf_pose_new.origin.y = vct_pos.y * joint_adj.H_SCALE
			tf_pose_new.origin.z = vct_pos.z * joint_adj.W_SCALE
		else:
			tf_pose_new.origin = tf_pose_old.origin

		skeleton.set_bone_global_pose(bone_index, tf_pose_new)


# ============================================================================
func update_pose(pose, b_show):
	""" update model joint(s)
	"""

	var dict_joint_collection = build_joint_collection(pose)

	for pose_joint in pose:
		if pose_joint.joint_type in joint_map.map.keys():
			update_pose_joint(pose_joint, dict_joint_collection)

	if b_show:
		self.o_model.show()
	else:
		self.o_model.hide()


# ============================================================================
func update_axis_src(pose, b_show):

	var dict_joint_collection = build_joint_collection(pose)

	for pose_joint in pose:
		var joint_type = pose_joint.joint_type
		var o_scene = axis_src[joint_type]
		var vct3_pos = dict_joint_collection[joint_type].vct3
		var quat_rot = dict_joint_collection[joint_type].quat

		vct3_pos *= KINECT_SCALE

		o_scene.set_transform(Transform(quat_rot))
		o_scene.set_translation(vct3_pos)
		o_scene.set_scale(Vector3(0.05, 0.05, 0.05))

		if b_show:
			o_scene.show()
		else:
			o_scene.hide()


# ============================================================================
func update_axis_dst(pose, b_show):

	var dict_joint_collection = build_joint_collection(pose)

	for pose_joint in pose:
		if pose_joint.joint_type in joint_map.map.keys():
			var alias_name = joint_map.map[pose_joint.joint_type].alias
			var bone_idx = skeleton.find_bone(alias_name)
			if bone_idx != -1:
				var tf_pose = skeleton.get_bone_global_pose(bone_idx)
				var o_scene = axis_dst[pose_joint.joint_type]

				o_scene.set_transform(tf_pose)
				o_scene.set_scale(Vector3(0.05, 0.05, 0.05))

				if b_show:
					o_scene.show()
				else:
					o_scene.hide()


# ============================================================================
func build_joint_collection(pose):
	var dict_result = {}

	for pose_joint in pose:
		var quat

		if joint_map.map[pose_joint.joint_type].child.size() > 0:
			quat = create_joint_quat(pose_joint)
		else:
			quat = null

		dict_result[pose_joint.joint_type] = {
			"vct3": create_joint_vct3(pose_joint),
			"quat": quat
		}

	for pose_joint in pose:
		if dict_result[pose_joint.joint_type].quat == null:
			dict_result[pose_joint.joint_type].quat = dict_result[joint_map.map[pose_joint.joint_type].parent].quat

	return dict_result


# ============================================================================
func adj_save():

	var h_writer = File.new()

	h_writer.open(RESOURCE_BASE_URI % [self.model_name, "joint_adj.json"], File.WRITE)
	h_writer.store_string(joint_adj.to_json())
	h_writer.close()


# ============================================================================
func model_load(o_scene_parent, model_name):

	self.o_model = load("res://res/chara/%s/model.scn" % [model_name]).instance()

	self.model_name = model_name
	skeleton = null

	joint_map = {}
	joint_adj = {}
	axis_src = {}
	axis_dst = {}

	var h_reader = File.new()

	h_reader.open(RESOURCE_BASE_URI % [self.model_name, "joint_map.json"], File.READ)
	joint_map.parse_json(h_reader.get_as_text())
	h_reader.close()

	h_reader.open(RESOURCE_BASE_URI % [self.model_name, "joint_adj.json"], File.READ)
	joint_adj.parse_json(h_reader.get_as_text())
	h_reader.close()

	skeleton = self.o_model.get_node(joint_map.skel)

	for name in joint_map.map.keys():
		var o_scene = null

		dict_quat_history[name] = CQuatQueue.new()

		o_scene = AXIS_ARROW.instance()
		o_scene.hide()
		o_scene_parent.add_child(o_scene)
		axis_src[name] = o_scene

		o_scene = AXIS_ARROW.instance()
		o_scene.hide()
		o_scene_parent.add_child(o_scene)
		axis_dst[name] = o_scene

	return self.o_model


# ============================================================================
func _init():
	pass



# [EOF]
