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
	if key and key.pressed and not key.echo:
		if operation and key.scancode == KEY_ESCAPE:
			operation = null
			return true
		elif operation and operation.handle_key(key):
			return true
		elif key.scancode == KEY_G:
			operation = TranslateOperation.new()
			return true
		elif key.scancode == KEY_R:
			operation = RotateOperation.new()
			return true
		elif key.scancode == KEY_S:
			operation = ScaleOperation.new()
			return true
	elif mouse and operation:
		operation.motion(get_editor_interface(), mouse.relative * MOUSE_SENSITIVITY)
		return true
	return false


class Operation:
	var total_mouse_offset := Vector2()

	func handle_key(key: InputEventKey) -> bool:
		return false

	func motion(editor: EditorInterface, dir: Vector2):
		total_mouse_offset += dir
		for node in editor.get_selection().get_transformable_selected_nodes():
			transform(node, dir, total_mouse_offset)

	func transform(node: Spatial, current: Vector2, total: Vector2):
		pass

class TranslateOperation:
	extends Operation

	func transform(node: Spatial, dir: Vector2, _total: Vector2):
		node.global_transform.origin.x += dir.x
		node.global_transform.origin.y += dir.y

class RotateOperation:
	extends Operation

	func transform(node: Spatial, dir: Vector2, _total: Vector2):
		node.rotate_x(dir.x)
		node.rotate_y(dir.y)

class ScaleOperation:
	extends Operation

	func transform(node: Spatial, _dir: Vector2, total: Vector2):
		node.scale_object_local(Vector3(total.x, 0, total.y))
