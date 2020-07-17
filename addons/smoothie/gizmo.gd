extends EditorSpatialGizmo
class_name SmoothieGizmo

var lock: Vector3
var axis_name: String

func update_lock(new_lock: Vector3, local: bool):
	var spatial := get_spatial_node()
	axis_name = "x_axis" if new_lock.x else "y_axis" if new_lock.y else "z_axis"
	lock = spatial.global_transform.basis.xform(new_lock) if local else new_lock
	spatial.update_gizmo()

func redraw():
	clear()
	if not axis_name:
		return
	var spatial := get_spatial_node()
	var axis_dir := spatial.global_transform.basis.xform_inv(lock)
	var points = [axis_dir * 1000, -axis_dir * 1000]
	add_lines(points, get_plugin().get_material(axis_name, self))
