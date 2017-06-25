extends Node
# ------------------------------------------------------------------- const(s)
const MASS = 1000 * 10
const GRAVITY = 0.1 * 10
const BIAS = 0.3
const DAMPING = 1
const IMPULSE_CLAMP = 0


# ------------------------------------------------------------------- param(s)
var dict_physics_root = {}


# ------------------------------------------------------------------- class(s)
# ----------------------------------------------------------------------------
class CPhysics:
	var sbody = null
	var dict_body = {}

	func update(o_model, skeleton, tf):
#		sbody.set_translation(tf.origin)
		self.sbody.set_transform(tf)

		for name in self.dict_body.keys():
			var bone_idx = skeleton.find_bone(name)
			skeleton.set_bone_global_pose(
				bone_idx,
				self.dict_body[name].get_transform()
			)

	func add_body(o_model, skeleton, list_name, p_body, p_tf, item_index):
		if item_index == list_name.size():
			return

		var tf = skeleton.get_bone_global_pose(
			skeleton.find_bone(list_name[item_index])
		)

		var body = RigidBody.new()
		#var cube = TestCube.new()
		#cube.set_scale(Vector3(1, 1, 1) * 0.05)
		#body.add_child(cube)
		body.set_mass(MASS)
		body.set_gravity_scale(GRAVITY)
		body.look_at_from_pos(
			tf.origin,
			p_tf.origin,
			Vector3(0, 1, 0)
		)
		o_model.add_child(body)

		var box = SphereShape.new()
		box.set_radius(0.1)
		body.add_shape(box)

		var joint = PinJoint.new()
		#var joint = Generic6DOFJoint.new()
		joint.set_translation(p_tf.origin)
		joint.set_node_a(p_body.get_path())
		joint.set_node_b(body.get_path())
		joint.set_param(PinJoint.PARAM_BIAS, BIAS) #0.01-0.99
		joint.set_param(PinJoint.PARAM_DAMPING, DAMPING) #0.01-8
		joint.set_param(PinJoint.PARAM_IMPULSE_CLAMP, IMPULSE_CLAMP) #0-64
		o_model.add_child(joint)

		self.dict_body[list_name[item_index]] = body

		self.add_body(o_model, skeleton, list_name, body, tf, item_index + 1)

	func setup(o_model, skeleton, list_name):
		var item_index = 0;
		var tf = skeleton.get_bone_global_pose(
			skeleton.find_bone(list_name[item_index])
		)

		var body = StaticBody.new()
		#var cube = TestCube.new()
		#cube.set_scale(Vector3(1, 1, 1) * 0.25)
		#body.add_child(cube)
		body.set_translation(tf.origin)
		o_model.add_child(body)

		self.sbody = body

		self.add_body(o_model, skeleton, list_name, body, tf, item_index + 1)

	func setupsadf(o_model, skeleton, name):

		var box = null
		var tf = skeleton.get_bone_global_pose(skeleton.find_bone(name))
		var mass = 1000 * 100
		var grav = 0.1 * 100
		"""
		cube_s = TestCube.new()
		cube_s.set_scale(Vector3(1, 1, 1) * 0.25)
		sbody = StaticBody.new()
		sbody.set_translation(tf.origin)
		sbody.add_child(tcube_s)
		o_model.add_child(sbody)

		#

		tcube_r = TestCube.new()
		tcube_r.set_scale(Vector3(1, 1, 1) * 0.25)
		rbody = RigidBody.new()
		rbody.add_child(tcube_r)
		rbody.set_mass(mass)
		rbody.set_gravity_scale(grav)
		rbody.look_at_from_pos(
			tf.origin + Vector3(0,-1, 0),
			tf.origin + Vector3(0, 0, 0),
			Vector3(0, 0, 1)
		)

		box = BoxShape.new()
		box.set_extents(Vector3(1, 1, 1) * 0.25)
		rbody.add_shape(box)
		o_model.add_child(rbody)

		joint = PinJoint.new()
		joint.set_translation(tf.origin + Vector3(0, 0, 0))
		joint.set_node_a(sbody.get_path())
		joint.set_node_b(rbody.get_path())
		joint.set_param(PinJoint.PARAM_BIAS, 0.3) #0.01-0.99
		joint.set_param(PinJoint.PARAM_DAMPING, 1) #0.01-8
		joint.set_param(PinJoint.PARAM_IMPULSE_CLAMP, 0) #0-64

		o_model.add_child(joint)

		self.tcube_r2 = TestCube.new()
		tcube_r2.set_scale(Vector3(1, 1, 1) * 0.25)
		rbody2 = RigidBody.new()
		rbody2.add_child(tcube_r2)
		rbody2.set_mass(mass)
		rbody2.set_gravity_scale(grav)
		rbody2.look_at_from_pos(
			tf.origin + Vector3(0, -2, 0),
			tf.origin + Vector3(0, -1, 0),
			Vector3(0, 0, 1)
		)

		box = BoxShape.new()
		box.set_extents(Vector3(1, 1, 1) * 0.25)
		rbody2.add_shape(box)
		o_model.add_child(rbody2)

		joint2 = PinJoint.new()
		joint2.set_translation(tf.origin + Vector3(0, -1, 0))
		joint2.set_node_a(rbody.get_path())
		joint2.set_node_b(rbody2.get_path())
		joint2.set_param(PinJoint.PARAM_BIAS, 0.3)
		joint2.set_param(PinJoint.PARAM_DAMPING, 1)
		joint2.set_param(PinJoint.PARAM_IMPULSE_CLAMP, 0)

		o_model.add_child(joint2)
		"""


func update(o_model, skeleton):

	for idx in dict_physics_root.keys():
		dict_physics_root[idx].update(
			o_model,
			skeleton,
			skeleton.get_bone_global_pose(idx)
		)


func setup(o_model, skeleton):

	for skirt_n in range(12):
		var list_cloth = []
		for n in range(3):
			list_cloth.append(
				"Skirt%s_%s" % [str(n), str(skirt_n)]
			)

		var index = skeleton.find_bone(list_cloth[0])
		if index == -1:
			print(list_cloth)
		else:
			var phy = CPhysics.new()
			phy.setup(o_model, skeleton, list_cloth)
			dict_physics_root[index] = phy

			print(list_cloth)

	for list_joint in [
		["RightRibbon3", "RightRibbon4"],
		["RightRibbon5", "RightRibbon6"],
		["LeftRibbon3", "LeftRibbon4"],
		["LeftRibbon5", "LeftRibbon6"],
		["RightApron1", "RightApron2", "RightApron3"],
		["CenterApron1", "CenterApron2", "CenterApron3"],
		["LeftApron1", "LeftApron2", "LeftApron3"]
		]:

		var index = skeleton.find_bone(list_joint[0])
		if index != -1:

			var phy = CPhysics.new()
			phy.setup(o_model, skeleton, list_joint)
			dict_physics_root[index] = phy


func _ready():
	# Called every time the node is added to the scene.
	# Initialization here
	pass
