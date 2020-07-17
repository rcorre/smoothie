extends EditorSpatialGizmo
class_name SmoothieGizmo

var axis_lock: Vector3  # set by the main plugin

func redraw():
	clear()
	var spatial := get_spatial_node()
	var points = [axis_lock * -1000, axis_lock * 1000]
	var axis = "x_axis" if axis_lock.x else "y_axis" if axis_lock.y else "z_axis"
	add_lines(points, get_plugin().get_material(axis, self))
