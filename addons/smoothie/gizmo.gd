extends EditorSpatialGizmoPlugin

func _init():
	create_material("x_axis", Color.red)
	create_material("y_axis", Color.green)
	create_material("z_axis", Color.blue)

func redraw(gizmo: EditorSpatialGizmo):
	gizmo.clear()

	var spatial = gizmo.get_spatial_node()

	var c := CylinderMesh.new()
	c.height = 100
	c.bottom_radius = 0.01
	c.top_radius = 0.01
	var arr_mesh := ArrayMesh.new()
	arr_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, c.get_mesh_arrays())
	gizmo.add_mesh(arr_mesh, false, null, get_material("x_axis", gizmo))

func get_name():
	return "SmoothieGizmo"

func has_gizmo(_s: Spatial):
	return true
