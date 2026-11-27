extends Node3D

const ROAD := Color(0.12, 0.13, 0.14)
const SIDEWALK := Color(0.48, 0.47, 0.42)
const GRASS := Color(0.24, 0.39, 0.20)
const WALLS := [Color(0.78, 0.69, 0.54), Color(0.72, 0.74, 0.68), Color(0.82, 0.78, 0.68), Color(0.62, 0.67, 0.68)]

func _ready() -> void:
    _make_environment()
    _make_terrain()
    _make_roads()
    _make_buildings()
    _make_trees()
    _make_npcs()
    _make_places()

func terrain_height(x: float, z: float) -> float:
    var edge := clampf((maxf(absf(x), absf(z)) - 34.0) / 58.0, 0.0, 1.0)
    var hills := 1.7 + sin(x * 0.075) * 0.75 + cos(z * 0.061) * 0.55
    return edge * hills

func _make_environment() -> void:
    var world_env := WorldEnvironment.new()
    var env := Environment.new()
    env.background_mode = Environment.BG_SKY
    env.sky = Sky.new()
    env.sky.sky_material = ProceduralSkyMaterial.new()
    env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
    env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
    env.ambient_light_energy = 0.75
    world_env.environment = env
    add_child(world_env)
    var sun := DirectionalLight3D.new()
    sun.rotation_degrees = Vector3(-48, -32, 0)
    sun.light_energy = 1.1
    sun.shadow_enabled = true
    add_child(sun)

func _make_terrain() -> void:
    var surface := SurfaceTool.new()
    surface.begin(Mesh.PRIMITIVE_TRIANGLES)
    var half := 110.0
    var step := 4.0
    var count := int((half * 2.0) / step)
    for z in range(count):
        for x in range(count):
            var x0 := -half + float(x) * step
            var z0 := -half + float(z) * step
            var x1 := x0 + step
            var z1 := z0 + step
            var a := Vector3(x0, terrain_height(x0, z0), z0)
            var b := Vector3(x1, terrain_height(x1, z0), z0)
            var c := Vector3(x0, terrain_height(x0, z1), z1)
            var d := Vector3(x1, terrain_height(x1, z1), z1)
            surface.add_vertex(a)
            surface.add_vertex(c)
            surface.add_vertex(b)
            surface.add_vertex(b)
            surface.add_vertex(c)
            surface.add_vertex(d)
    surface.generate_normals()
    var mesh := surface.commit()
    var material := StandardMaterial3D.new()
    material.albedo_color = GRASS
    material.roughness = 1.0
    mesh.surface_set_material(0, material)
    var terrain_body := StaticBody3D.new()
    terrain_body.name = "SouthDistrictTerrain"
    var terrain_mesh := MeshInstance3D.new()
    terrain_mesh.mesh = mesh
    terrain_body.add_child(terrain_mesh)
    var collision := CollisionShape3D.new()
    collision.shape = mesh.create_trimesh_shape()
    terrain_body.add_child(collision)
    add_child(terrain_body)

func _make_roads() -> void:
    _box("Main road east-west", Vector3(0, 0.06, 0), Vector3(200, 0.12, 11), ROAD)
    _box("Main road north-south", Vector3(0, 0.07, 0), Vector3(11, 0.13, 200), ROAD)
    _box("Sidewalk north", Vector3(0, 0.13, -6.5), Vector3(200, 0.18, 2), SIDEWALK)
    _box("Sidewalk south", Vector3(0, 0.13, 6.5), Vector3(200, 0.18, 2), SIDEWALK)
    _box("Sidewalk east", Vector3(6.5, 0.13, 0), Vector3(2, 0.18, 200), SIDEWALK)
    _box("Sidewalk west", Vector3(-6.5, 0.13, 0), Vector3(2, 0.18, 200), SIDEWALK)
    for i in range(-9, 10):
        _box("Road marking", Vector3(float(i) * 10.0, 0.14, 0), Vector3(4, 0.025, 0.14), Color(0.88, 0.84, 0.68))

func _make_buildings() -> void:
    var positions := [Vector3(-22,0,-22), Vector3(22,0,-22), Vector3(-22,0,22), Vector3(22,0,22), Vector3(-48,0,-22), Vector3(48,0,22), Vector3(-22,0,-48), Vector3(22,0,48)]
    for i in range(positions.size()):
        var p: Vector3 = positions[i]
        p.y = terrain_height(p.x, p.z)
        var h := 7.0 if i % 3 == 0 else 4.0
        var size := Vector3(12, h, 9)
        _building("Building %02d" % i, p, size, WALLS[i % WALLS.size()], i % 3 == 0)

func _building(label: String, p: Vector3, size: Vector3, color: Color, apartment: bool) -> void:
    _box(label, p + Vector3(0, size.y / 2.0, 0), size, color)
    _box(label + " roof", p + Vector3(0, size.y + 0.12, 0), Vector3(size.x + 0.3, 0.25, size.z + 0.3), Color(0.28, 0.29, 0.28))
    var floors := 2 if apartment else 1
    for floor in range(floors):
        for x in [-1.0, 0.0, 1.0]:
            _box("Window", p + Vector3(x * size.x * 0.27, 1.4 + floor * 2.7, size.z / 2.0 + 0.012), Vector3(1.0, 1.2, 0.05), Color(0.12, 0.22, 0.28))

func _make_trees() -> void:
    for x in range(-85, 90, 18):
        _tree(Vector3(float(x), terrain_height(float(x), -15.0), -15))
        _tree(Vector3(float(x), terrain_height(float(x), 15.0), 15))
    for z in range(-85, 90, 18):
        _tree(Vector3(-15, terrain_height(-15.0, float(z)), float(z)))
        _tree(Vector3(15, terrain_height(15.0, float(z)), float(z)))

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

func _make_npcs() -> void:
    _npc("Сосед", Vector3(14, terrain_height(14, -13), -13), Color(0.24, 0.34, 0.58))
    _npc("Парень на остановке", Vector3(39, terrain_height(39, 12), 12), Color(0.52, 0.30, 0.20))

func _npc(label: String, p: Vector3, color: Color) -> void:
    var npc := Node3D.new()
    npc.name = label
    npc.position = p
    npc.add_to_group("story_npc")
    add_child(npc)
    var body := MeshInstance3D.new()
    var torso := CapsuleMesh.new()
    torso.radius = 0.34
    torso.height = 1.15
    body.mesh = torso
    body.position.y = 0.95
    var mat := StandardMaterial3D.new()
    mat.albedo_color = color
    body.material_override = mat
    npc.add_child(body)
    var head := MeshInstance3D.new()
    var head_mesh := SphereMesh.new()
    head_mesh.radius = 0.24
    head.mesh = head_mesh
    head.position.y = 1.72
    var skin := StandardMaterial3D.new()
    skin.albedo_color = Color(0.72, 0.57, 0.43)
    head.material_override = skin
    npc.add_child(head)
    var legs := MeshInstance3D.new()
    var leg_mesh := BoxMesh.new()
    leg_mesh.size = Vector3(0.48, 0.65, 0.28)
    legs.mesh = leg_mesh
    legs.position.y = 0.34
    var dark := StandardMaterial3D.new()
    dark.albedo_color = Color(0.12, 0.14, 0.17)
    legs.material_override = dark
    npc.add_child(legs)

func _make_places() -> void:
    _place_label("ПАРК", Vector3(-28, terrain_height(-28, -34), -34))
    _place_label("ОСТАНОВКА", Vector3(39, terrain_height(39, 12), 12))
    _place_label("ДВОР", Vector3(14, terrain_height(14, -13), -13))

func _place_label(caption: String, p: Vector3) -> void:
    var marker := MeshInstance3D.new()
    var pole := CylinderMesh.new()
    pole.top_radius = 0.08
    pole.bottom_radius = 0.08
    pole.height = 2.2
    marker.mesh = pole
    marker.position = p + Vector3(0, 1.1, 0)
    add_child(marker)
    var label := Label3D.new()
    label.text = caption
    label.position = p + Vector3(0, 2.5, 0)
    label.font_size = 48
    label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
    add_child(label)

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
