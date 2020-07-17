extends EditorSpatialGizmoPlugin
class_name SmoothieGizmoPlugin

func _init():
	create_material("x_axis", Color.red)
	create_material("y_axis", Color.green)
	create_material("z_axis", Color.blue)

func get_name():
	return "SmoothieGizmo"

func create_gizmo(_s: Spatial) -> EditorSpatialGizmo:
	return SmoothieGizmo.new()
