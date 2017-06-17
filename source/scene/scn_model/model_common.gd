extends Node

var joint_map = {}
var joint_adjust = {}
var skeleton = null


# ============================================================================
func create_joint_vct3(pose_joint):
	return Vector3(
		pose_joint.pos.x * -1,
		pose_joint.pos.z * -1,
		pose_joint.pos.y * -1
	)


# ============================================================================
func create_joint_quat(pose_joint):
	return Quat(
		pose_joint.quat.x * -1,
		pose_joint.quat.z * -1,
		pose_joint.quat.y * -1,
		pose_joint.quat.w
	)


# ============================================================================
func update_pose_joint(pose_joint, dict_joint_collection):

	if joint_map.map[pose_joint.joint_type].child.size() != 1:
		return

	var child_name = joint_map.map[pose_joint.joint_type].child[0]
	var vct_pos = create_joint_vct3(pose_joint)
	var quat_rot = dict_joint_collection[child_name].quat

	var quat_x = Quat(Vector3(1, 0, 0), deg2rad(joint_adjust[pose_joint.joint_type][0]))
	var quat_y = Quat(Vector3(0, 1, 0), deg2rad(joint_adjust[pose_joint.joint_type][2]))
	var quat_z = Quat(Vector3(0, 0, 1), deg2rad(joint_adjust[pose_joint.joint_type][1]))

	var tf_pose_old = skeleton.get_bone_global_pose(
		skeleton.find_bone(pose_joint.joint_type)
	)
	var tf_pose_new = Transform(quat_rot * quat_x * quat_y * quat_z)

	if pose_joint.joint_type == "SPINE_BASE":
		tf_pose_new.origin = vct_pos * 4
	else:
		tf_pose_new.origin = tf_pose_old.origin

	skeleton.set_bone_global_pose(
		skeleton.find_bone(pose_joint.joint_type),
		tf_pose_new
	)


# ============================================================================
func update_pose(pose):

	var dict_joint_collection = build_joint_collection(pose)

	for pose_joint in pose:
		if pose_joint.joint_type in joint_map.map.keys():
			update_pose_joint(pose_joint, dict_joint_collection)


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
func joint_map_load(o_model, resource_name):

	var h_reader = File.new()
	h_reader.open(resource_name, File.READ)

	joint_map = {}
	joint_map.parse_json(h_reader.get_as_text())

	h_reader.open("res://scene/scn_model/hutyakiti/joint_adjust.json", File.READ)

	joint_adjust = {}
	joint_adjust.parse_json(h_reader.get_as_text())

	skeleton = o_model.get_node("hutyakiti_haton_normalVer/Root/Skeleton")

	return true


# ============================================================================
func _init():

	print("READY")



# [EOF]
