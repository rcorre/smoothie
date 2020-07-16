extends EditorSpatialGizmoPlugin

# which axes we are limiting motion to
# determines which axes our gizmo highlights
var axis_constraint: Vector3
var constraint_is_local: bool

func _init():
	create_material("x_axis", Color.red)
	create_material("y_axis", Color.green)
	create_material("z_axis", Color.blue)

func make_mesh(obj: Spatial, rotation_axis: Vector3) -> ArrayMesh:
	# build a thin cylinder to highlight axes
	var c := CylinderMesh.new()
	c.height = 100
	c.bottom_radius = 0.01
	c.top_radius = 0.01
	c.rings = 1
	c.radial_segments = 8
	var mesh_data := c.get_mesh_arrays()
	var mesh := ArrayMesh.new()
	for i in len(mesh_data[ArrayMesh.ARRAY_VERTEX]):
		# rotate the cylinder around the appropriate axis
		# and translate it to the global origin
		mesh_data[ArrayMesh.ARRAY_VERTEX][i] = mesh_data[ArrayMesh.ARRAY_VERTEX][i].rotated(rotation_axis, PI/2)
		if not constraint_is_local:
			mesh_data[ArrayMesh.ARRAY_VERTEX][i] = obj.to_local(mesh_data[ArrayMesh.ARRAY_VERTEX][i])

	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, mesh_data)
	return mesh

func redraw(gizmo: EditorSpatialGizmo):
	gizmo.clear()
	var spatial = gizmo.get_spatial_node()

	var obj := gizmo.get_spatial_node()
	if axis_constraint.x:
		gizmo.add_mesh(make_mesh(obj, Vector3.FORWARD), false, null, get_material("x_axis", gizmo))
	if axis_constraint.y:
		gizmo.add_mesh(make_mesh(obj, Vector3.UP), false, null, get_material("y_axis", gizmo))
	if axis_constraint.z:
		gizmo.add_mesh(make_mesh(obj, Vector3.LEFT), false, null, get_material("z_axis", gizmo))

func get_name():
	return "SmoothieGizmo"

func has_gizmo(_s: Spatial):
	return true

func _on_axis_constraint_changed(constraint: Vector3, is_local: bool):
	axis_constraint = constraint
	constraint_is_local = is_local
