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
	if key and key.pressed and not key.echo:
		if operation and key.scancode == KEY_ESCAPE:
			operation.cancel()
			operation = null
			return true
		elif operation and operation.handle_key(key):
			return true
		elif key.scancode == KEY_G:
			operation = TranslateOperation.new(get_editor_interface())
			return true
		elif key.scancode == KEY_R:
			operation = RotateOperation.new(get_editor_interface())
			return true
		elif key.scancode == KEY_S:
			operation = ScaleOperation.new(get_editor_interface())
			return true
	elif operation and mouse:
		operation.motion(mouse.relative * MOUSE_SENSITIVITY)
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

	var total_mouse_offset := Vector2()
	var nodes: Array

	func _init(editor: EditorInterface):
		for n in editor.get_selection().get_transformable_selected_nodes():
			nodes.push_back(NodeState.new(n, n.transform))

	func cancel():
		for n in nodes:
			n.node.transform = n.original_transform

	func handle_key(key: InputEventKey) -> bool:
		return false

	func motion(dir: Vector2):
		total_mouse_offset += dir
		for n in nodes:
			transform(n.node, dir, total_mouse_offset)

	func transform(node: Spatial, current: Vector2, total: Vector2):
		pass

class TranslateOperation:
	extends Operation

	func _init(editor: EditorInterface).(editor):
		pass

	func transform(node: Spatial, dir: Vector2, _total: Vector2):
		node.global_transform.origin.x += dir.x
		node.global_transform.origin.y += dir.y

class RotateOperation:
	extends Operation

	func _init(editor: EditorInterface).(editor):
		pass

	func transform(node: Spatial, dir: Vector2, _total: Vector2):
		node.rotate_x(dir.x)
		node.rotate_y(dir.y)

class ScaleOperation:
	extends Operation

	func _init(editor: EditorInterface).(editor):
		pass

	func transform(node: Spatial, _dir: Vector2, total: Vector2):
		node.scale_object_local(Vector3(total.x, 0, total.y))
