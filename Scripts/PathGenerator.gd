extends Node3D

@export var car: Node3D

@export var RES: int
@export var WIDTH: float

@export var loop: bool
@export var show_traj: bool

@export var road_mat: StandardMaterial3D
@export var line_mat: StandardMaterial3D

@onready var dots_anim = $"../UI/Control"

var curve: Curve3D

func _ready() -> void:
	curve = Curve3D.new()
	
	load_road("C:\\Users\\theem\\Documents\\programs\\TIPE python\\roads\\Monza_centerline.csv")

func load_road(file_path: String):
	curve.clear_points()
	
	var file = FileAccess.open(file_path, FileAccess.READ)
	#var content = file.get_as_text()
	while not file.eof_reached():
		var line = file.get_csv_line()
		var p = Vector3(float(line[0]),0,float(line[1]))
		
		curve.add_point(p)

func generate_mesh():
	var points = curve.tessellate_even_length(RES)
	if loop:
		points.append(points[0])
		points.append(points[1])
	
	var road_points = []
	var vertices = []
	var normals = []
	var uvs = []
	
	for i in range(points.size()-1):
		var M = points[i]
		var M2 = points[i+1]
		
		var dir = Vector3.UP.cross(M2-M).normalized()
		
		var line: Array[Vector3]
		line.append(M-dir*WIDTH)
		line.append(M+dir*WIDTH)
		road_points.append(line)
		
	for i in range(road_points.size()-1):
		vertices.append(road_points[i][0])
		vertices.append(road_points[i][1])
		vertices.append(road_points[i+1][0])
		
		vertices.append(road_points[i][1])
		vertices.append(road_points[i+1][1])
		vertices.append(road_points[i+1][0])
		
		normals.append(Vector3.UP)
		normals.append(Vector3.UP)
		normals.append(Vector3.UP)
		normals.append(Vector3.UP)
		normals.append(Vector3.UP)
		normals.append(Vector3.UP)
		
		uvs.append(Vector2(0,i))
		uvs.append(Vector2(1,i))
		uvs.append(Vector2(0,i+1))
		
		uvs.append(Vector2(1,i))
		uvs.append(Vector2(1,i+1))
		uvs.append(Vector2(0,i+1))
		
	var mesh = ArrayMesh.new()
	var arrays = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = PackedVector3Array(vertices)
	arrays[Mesh.ARRAY_NORMAL] = PackedVector3Array(normals)
	arrays[Mesh.ARRAY_TEX_UV] = PackedVector2Array(uvs)
	
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	
	var mesh_instance = MeshInstance3D.new()
	mesh_instance.mesh = mesh
	mesh_instance.material_overlay = road_mat
	
	self.add_child(mesh_instance)

func generate_traj_mesh(traj: Curve3D):
	var points = traj.tessellate_even_length()
	
	var vertices = []
	for i in range(points.size()-1):
		vertices.append(points[i] + Vector3.UP*0.1)
		vertices.append(points[i+1] + Vector3.UP*0.1)
	
	var mesh = ArrayMesh.new()
	var arrays = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = PackedVector3Array(vertices)
	
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_LINES, arrays)
	
	var mesh_instance = MeshInstance3D.new()
	mesh_instance.mesh = mesh
	mesh_instance.material_overlay = road_mat
	
	mesh_instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mesh_instance.material_overlay = line_mat
	
	call_deferred("add_child", mesh_instance)

func solve():
	var output = []
	OS.execute("CMD.exe", ["/C", "python C:\\Users\\theem\\Documents\\programs\\raceline-simulator\\solver_executer.py"], output)
	
	var points_str = output[0].replace('\r','').split('\n')
	points_str.remove_at(len(points_str)-1)
	#print(points_str)
	var traj_curve = CatmullRom3D.new()
	
	var speed_curve = Curve.new()
	speed_curve.max_domain = float(points_str[len(points_str)-1].split(',')[1])
	
	var traj_arr = []
	var speed_arr = []
	
	var traj = true
	var i = 1
	while i <= points_str.size()-1:
		var val = points_str[i].split(',')
		i += 1
		if val[0] == 'speeds':
			traj = false
			continue
		
		if traj:
			traj_arr.append(Vector3(float(val[0]),0,float(val[1])))
			traj_curve.add_point(Vector3(float(val[0]),0,float(val[1])))
		else:
			speed_arr.append(Vector2(float(val[1]), float(val[0])))
			print(val[1])
			if float(val[0]) > speed_curve.max_value:
				speed_curve.max_value = float(val[0])
	
	for k in range(traj_arr.size()):
		traj_curve.cm_add_point(traj_arr[k])
		#traj_curve.add_point(traj_arr[3*k+1], traj_arr[3*k]-traj_arr[3*k+1], traj_arr[3*k+2]-traj_arr[3*k+1])
	
	for k in range(speed_arr.size()):
		speed_curve.add_point(speed_arr[k])
	
	#for k in range(speed_arr.size()):
		#print(speed_curve.sample((float(k)/speed_arr.size())*speed_curve.max_domain))
	
	car.trajectory = traj_curve
	car.speed_curve = speed_curve
	
	if show_traj:
		generate_traj_mesh(traj_curve)

func solve_threaded():
	var thread = Thread.new()
	
	thread.start(solve)
	while thread.is_alive():
		dots_anim.visible = true
		await get_tree().process_frame
		
	thread.wait_to_finish()
	dots_anim.visible = false
