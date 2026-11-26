extends Node3D

const ROAD_MAT := Color(0.12, 0.13, 0.14)
const SIDEWALK_MAT := Color(0.48, 0.47, 0.42)
const GRASS_MAT := Color(0.22, 0.38, 0.19)
const WALL_COLORS := [Color(0.78, 0.69, 0.54), Color(0.72, 0.74, 0.68), Color(0.82, 0.78, 0.68), Color(0.62, 0.67, 0.68)]

func _ready() -> void:
    _make_environment()
    _make_ground()
    _make_roads()
    _make_buildings()
    _make_trees()

func _make_environment() -> void:
    var world_env := WorldEnvironment.new()
    var env := Environment.new()
    env.background_mode = Environment.BG_SKY
    env.sky = Sky.new()
    env.sky.sky_material = ProceduralSkyMaterial.new()
    env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
    env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
    env.ambient_light_energy = 0.7
    world_env.environment = env
    add_child(world_env)
    var sun := DirectionalLight3D.new()
    sun.rotation_degrees = Vector3(-48, -32, 0)
    sun.light_energy = 1.1
    sun.shadow_enabled = true
    add_child(sun)

func _make_ground() -> void:
    _box("Ground", Vector3(0, -0.35, 0), Vector3(220, 0.5, 220), GRASS_MAT)

func _make_roads() -> void:
    _box("Main road east-west", Vector3(0, -0.06, 0), Vector3(200, 0.12, 11), ROAD_MAT)
    _box("Main road north-south", Vector3(0, -0.05, 0), Vector3(11, 0.13, 200), ROAD_MAT)
    _box("Sidewalk north", Vector3(0, 0, -6.5), Vector3(200, 0.18, 2), SIDEWALK_MAT)
    _box("Sidewalk south", Vector3(0, 0, 6.5), Vector3(200, 0.18, 2), SIDEWALK_MAT)
    _box("Sidewalk east", Vector3(6.5, 0, 0), Vector3(2, 0.18, 200), SIDEWALK_MAT)
    _box("Sidewalk west", Vector3(-6.5, 0, 0), Vector3(2, 0.18, 200), SIDEWALK_MAT)
    for i in range(-9, 10):
        _box("Road marking", Vector3(i * 10, 0.012, 0), Vector3(4, 0.025, 0.14), Color(0.88, 0.84, 0.68))

func _make_buildings() -> void:
    var positions := [Vector3(-22,0,-22),Vector3(22,0,-22),Vector3(-22,0,22),Vector3(22,0,22),Vector3(-48,0,-22),Vector3(48,0,22),Vector3(-22,0,-48),Vector3(22,0,48)]
    for i in range(positions.size()):
        var h := 7.0 if i % 3 == 0 else 4.0
        var size := Vector3(12, h, 9)
        _building("Building %02d" % i, positions[i], size, WALL_COLORS[i % WALL_COLORS.size()], i % 3 == 0)

func _building(label: String, p: Vector3, size: Vector3, color: Color, apartment: bool) -> void:
    _box(label, p + Vector3(0, size.y / 2, 0), size, color)
    _box(label + " roof", p + Vector3(0, size.y + 0.12, 0), Vector3(size.x + 0.3, 0.25, size.z + 0.3), Color(0.28, 0.29, 0.28))
    var floors := 2 if apartment else 1
    for floor in range(floors):
        for x in [-1.0, 0.0, 1.0]:
            _box("Window", p + Vector3(x * size.x * 0.27, 1.4 + floor * 2.7, size.z / 2 + 0.012), Vector3(1.0, 1.2, 0.05), Color(0.12, 0.22, 0.28))

func _make_trees() -> void:
    for x in range(-85, 90, 18):
        _tree(Vector3(x, 0, -15))
        _tree(Vector3(x, 0, 15))
    for z in range(-85, 90, 18):
        _tree(Vector3(-15, 0, z))
        _tree(Vector3(15, 0, z))

func _tree(p: Vector3) -> void:
    var trunk := MeshInstance3D.new()
    var tm := CylinderMesh.new()
    tm.top_radius = 0.18
    tm.bottom_radius = 0.22
    tm.height = 2.0
    trunk.mesh = tm
    trunk.position = p + Vector3(0, 1, 0)
    var tmat := StandardMaterial3D.new()
    tmat.albedo_color = Color(0.27, 0.16, 0.09)
    trunk.material_override = tmat
    add_child(trunk)
    var crown := MeshInstance3D.new()
    var cm := SphereMesh.new()
    cm.radius = 1.4
    cm.height = 2.8
    crown.mesh = cm
    crown.position = p + Vector3(0, 2.8, 0)
    var cmat := StandardMaterial3D.new()
    cmat.albedo_color = Color(0.13, 0.31, 0.13)
    crown.material_override = cmat
    add_child(crown)

func _box(label: String, p: Vector3, size: Vector3, color: Color) -> void:
    var body := StaticBody3D.new()
    body.name = label
    body.position = p
    var mi := MeshInstance3D.new()
    var mesh := BoxMesh.new()
    mesh.size = size
    mi.mesh = mesh
    var mat := StandardMaterial3D.new()
    mat.albedo_color = color
    mat.roughness = 0.92
    mi.material_override = mat
    body.add_child(mi)
    var collision := CollisionShape3D.new()
    var shape := BoxShape3D.new()
    shape.size = size
    collision.shape = shape
    body.add_child(collision)
    add_child(body)
