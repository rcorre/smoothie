extends EditorSpatialGizmoPlugin

# which axes we are limiting motion to
# determines which axes our gizmo highlights
var axis_constraint: Vector3
var constraint_is_local: bool

func _init():
	create_material("x_axis", Color.red)
	create_material("y_axis", Color.green)
	create_material("z_axis", Color.blue)

func redraw(gizmo: EditorSpatialGizmo):
	gizmo.clear()
	var spatial = gizmo.get_spatial_node()

	var obj := gizmo.get_spatial_node()
	var trans := Transform.IDENTITY if constraint_is_local else obj.global_transform.affine_inverse()
	var points = [
		trans.xform(axis_constraint) * -100,
		trans.xform(axis_constraint) * 100
	]
	var axis = "x_axis" if axis_constraint.x else "y_axis" if axis_constraint.y else "z_axis"
	gizmo.add_lines(points, get_material(axis, gizmo))

func get_name():
	return "SmoothieGizmo"

func has_gizmo(_s: Spatial):
	return true

func _on_axis_constraint_changed(constraint: Vector3, is_local: bool):
	axis_constraint = constraint
	constraint_is_local = is_local
