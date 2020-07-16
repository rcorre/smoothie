tool
extends EditorPlugin

const MOUSE_SENSITIVITY := 0.01

var operation: Operation
var gizmo_plugin := preload("res://addons/smoothie/gizmo.gd").new()

func _enter_tree():
	set_input_event_forwarding_always_enabled()
	add_spatial_gizmo_plugin(gizmo_plugin)

func _exit_tree():
	remove_spatial_gizmo_plugin(gizmo_plugin)

func forward_spatial_gui_input(camera: Camera, event: InputEvent):
	var key := event as InputEventKey
	var mouse := event as InputEventMouseMotion
	var click := event as InputEventMouseButton
	var selection = get_editor_interface().get_selection().get_transformable_selected_nodes()
	var scene = get_editor_interface().get_edited_scene_root()
	if key and key.pressed and not key.echo and key.scancode == key.get_scancode_with_modifiers():
		if operation and key.scancode == KEY_ESCAPE:
			operation.cancel()
			operation = null
			return true
		elif operation and operation.handle_key(key):
			return true
		elif selection and key.scancode == KEY_G:
			operation = TranslateOperation.new(selection, scene)
			operation.connect("axis_constraint_changed", gizmo_plugin, "_on_axis_constraint_changed")
			return true
		elif selection and key.scancode == KEY_R:
			operation = RotateOperation.new(selection, scene)
			operation.connect("axis_constraint_changed", gizmo_plugin, "_on_axis_constraint_changed")
			return true
		elif selection and key.scancode == KEY_S:
			operation = ScaleOperation.new(selection, scene)
			operation.connect("axis_constraint_changed", gizmo_plugin, "_on_axis_constraint_changed")
			return true
	elif operation and mouse:
		var motion := mouse.relative * MOUSE_SENSITIVITY
		operation.motion(camera.global_transform.basis.xform(Vector3(motion.x, -motion.y, 0)))
		return true
	elif operation and click and click.pressed and click.button_index == BUTTON_LEFT:
		operation.confirm()
		operation = null
		return true
	return false

class NodeState:
	var node: Spatial
	var original_transform: Transform

	func _init(n: Spatial, t: Transform):
		node = n
		original_transform = t

class Operation:

	signal axis_constraint_changed(axis)

	var total_mouse_offset := Vector3()
	var nodes: Array
	var axis_constraint := Vector3.ONE
	var constraint_is_local := false

	func _init(selection: Array, scene: Node):
		for n in selection:
			nodes.push_back(NodeState.new(n, n.transform))

	func confirm():
		# clear constraints so we don't leave axes highlighted
		update_constraint(Vector3.ZERO)

	func cancel():
		# clear constraints so we don't leave axes highlighted
		update_constraint(Vector3.ZERO)
		for n in nodes:
			n.node.transform = n.original_transform

	func update_constraint(constraint: Vector3):
		# double-pressing an axis means use the local transform
		constraint_is_local = axis_constraint == constraint and not constraint_is_local
		axis_constraint = constraint
		emit_signal("axis_constraint_changed", axis_constraint, constraint_is_local)
		for n in nodes:
			n.node.update_gizmo()

	func handle_key(key: InputEventKey) -> bool:
		var on := 0 if key.shift else 1
		var off := 1 if key.shift else 0
		if key.scancode == KEY_X:
			update_constraint(Vector3(on, off, off))
			return true
		elif key.scancode == KEY_Y:
			update_constraint(Vector3(off, on, off))
			return true
		elif key.scancode == KEY_Z:
			update_constraint(Vector3(off, off, on))
			return true
		return false

	func motion(offset: Vector3):
		total_mouse_offset += offset
		for n in nodes:
			var constraint := axis_constraint
			if constraint_is_local:
				constraint = n.node.global_transform.basis.xform(axis_constraint) 
			transform(
				n.node,
				offset.project(constraint),
				total_mouse_offset.project(constraint)
			)

	func transform(node: Spatial, current: Vector3, total: Vector3):
		pass

class TranslateOperation:
	extends Operation

	func _init(selection, scene).(selection, scene):
		pass

	func transform(node: Spatial, offset: Vector3, _total: Vector3):
		node.global_transform.origin += offset

class RotateOperation:
	extends Operation

	func _init(selection, scene).(selection, scene):
		pass

	func transform(node: Spatial, offset: Vector3, _total: Vector3):
		node.rotate_x(offset.x)
		node.rotate_y(offset.y)
		node.rotate_z(offset.z)

class ScaleOperation:
	extends Operation

	func _init(selection, scene).(selection, scene):
		pass

	func transform(node: Spatial, _dir: Vector3, total: Vector3):
		node.scale_object_local(total)
