tool
extends EditorPlugin

const MOUSE_SENSITIVITY := 0.01

var operation: Operation
var axis_lock: FuncRef
var gizmo_plugin := SmoothieGizmoPlugin.new()

func op_translate(input: Transform, lock: Vector3, offset: Vector3) -> Transform:
	if lock == Vector3.ZERO:
		return input.translated(offset)
	return input.translated(offset.project(lock))

func op_rotate(input: Transform, lock: Vector3, offset: Vector3) -> Transform:
	return Transform(input.basis.rotated(lock, offset.length()), input.origin)

func op_scale(input: Transform, lock: Vector3, offset: Vector3) -> Transform:
	return input.scaled(lock + lock * offset.length())

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
			operation = Operation.new(selection, funcref(self, "op_translate"))
			return true
		elif selection and key.scancode == KEY_R:
			operation = Operation.new(selection, funcref(self, "op_rotate"))
			return true
		elif selection and key.scancode == KEY_S:
			operation = Operation.new(selection, funcref(self, "op_scale"))
			return true
	elif operation and mouse:
		var motion := mouse.relative * MOUSE_SENSITIVITY
		operation.motion(camera.global_transform.basis.xform(Vector3(motion.x, -motion.y, 0)))
		return true
	elif operation and click and click.pressed and click.button_index == BUTTON_LEFT:
		operation.confirm(get_undo_redo())
		operation = null
		return true
	return false

class NodeState:
	var node: Spatial
	var original_transform: Transform

	func _init(n: Spatial, t: Transform):
		node = n
		original_transform = t

	func get_lock(lock: Vector3, local: bool) -> Vector3:
		return lock if local else original_transform.basis.xform_inv(lock)

class Operation:

	var total_mouse_offset := Vector3()
	var nodes: Array
	var axis_constraint := Vector3.ZERO
	var constraint_is_local := false
	var op: FuncRef

	func _init(selection: Array, operation: FuncRef):
		op = operation
		for n in selection:
			nodes.push_back(NodeState.new(n, n.global_transform))

	func confirm(undo: UndoRedo):
		undo.create_action("SmoothieTransform")
		for n in nodes:
			undo.add_do_property(n.node, "transform", n.node.global_transform)
			undo.add_undo_property(n.node, "transform", n.original_transform)
		undo.commit_action()
		# clear constraints so we don't leave axes highlighted
		update_constraint(Vector3.ZERO)

	func cancel():
		# clear constraints so we don't leave axes highlighted
		update_constraint(Vector3.ZERO)
		for n in nodes:
			n.node.global_transform = n.original_transform

	func update_constraint(constraint: Vector3):
		# double-pressing an axis means use the local transform
		constraint_is_local = axis_constraint == constraint and not constraint_is_local
		axis_constraint = constraint
		for n in nodes:
			(n.node.get_gizmo() as SmoothieGizmo).axis_lock = n.get_lock(axis_constraint, constraint_is_local)
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
			var total_offset := total_mouse_offset
			n.node.global_transform = op.call_func(
				n.original_transform,
				n.get_lock(axis_constraint, constraint_is_local),
				total_offset
			)
