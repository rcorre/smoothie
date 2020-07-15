tool
extends EditorPlugin

const MOUSE_SENSITIVITY := 0.01

var operation: Operation

func _enter_tree():
	set_input_event_forwarding_always_enabled()

func _exit_tree():
	pass

func forward_spatial_gui_input(camera: Camera, event: InputEvent):
	var key := event as InputEventKey
	var mouse := event as InputEventMouseMotion
	var click := event as InputEventMouseButton
	var selection = get_editor_interface().get_selection().get_transformable_selected_nodes()
	if key and key.pressed and not key.echo:
		if operation and key.scancode == KEY_ESCAPE:
			operation.cancel()
			operation = null
			return true
		elif operation and operation.handle_key(key):
			return true
		elif selection and key.scancode == KEY_G:
			operation = TranslateOperation.new(selection)
			return true
		elif selection and key.scancode == KEY_R:
			operation = RotateOperation.new(selection)
			return true
		elif selection and key.scancode == KEY_S:
			operation = ScaleOperation.new(selection)
			return true
	elif operation and mouse:
		var motion := mouse.relative * MOUSE_SENSITIVITY
		operation.motion(camera.global_transform.basis.xform(Vector3(motion.x, -motion.y, 0)))
		return true
	elif operation and click and click.pressed and click.button_index == BUTTON_LEFT:
		operation = null  # confirm operation and keep new transforms
		return true
	return false


class NodeState:
	var node: Spatial
	var original_transform: Transform

	func _init(n: Spatial, t: Transform):
		node = n
		original_transform = t

class Operation:

	var total_mouse_offset := Vector3()
	var nodes: Array

	func _init(selection: Array):
		for n in selection:
			nodes.push_back(NodeState.new(n, n.transform))

	func cancel():
		for n in nodes:
			n.node.transform = n.original_transform

	func handle_key(key: InputEventKey) -> bool:
		return false

	func motion(offset: Vector3):
		total_mouse_offset += offset
		for n in nodes:
			transform(n.node, offset, total_mouse_offset)

	func transform(node: Spatial, current: Vector3, total: Vector3):
		pass

class TranslateOperation:
	extends Operation

	func _init(selection).(selection):
		pass

	func transform(node: Spatial, offset: Vector3, _total: Vector3):
		node.global_transform.origin += offset

class RotateOperation:
	extends Operation

	func _init(selection).(selection):
		pass

	func transform(node: Spatial, offset: Vector3, _total: Vector3):
		node.rotate_x(offset.x)
		node.rotate_y(offset.y)
		node.rotate_z(offset.z)

class ScaleOperation:
	extends Operation

	func _init(selection).(selection):
		pass

	func transform(node: Spatial, _dir: Vector3, total: Vector3):
		node.scale_object_local(total)
