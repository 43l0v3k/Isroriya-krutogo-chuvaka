extends CharacterBody3D

@export var walk_speed := 4.5
@export var sprint_speed := 7.0
@export var jump_velocity := 4.5
@export var mouse_sensitivity := 0.0025
@export var touch_camera_sensitivity := 0.004

var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")
var camera_pivot: Node3D
var mobile_controls: Control
var yaw := 0.0
var pitch := -0.18
var mobile_move := Vector2.ZERO
var mobile_sprint := false
var mobile_jump_requested := false

func _ready() -> void:
    _build_character()
    _build_camera()
    _setup_mobile_controls()
    if OS.has_feature("pc"):
        Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _unhandled_input(event: InputEvent) -> void:
    if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
        Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
    if event is InputEventMouseButton and event.pressed:
        Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
    if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
        _rotate_camera(event.relative.x * mouse_sensitivity, event.relative.y * mouse_sensitivity)

func _rotate_camera(dx: float, dy: float) -> void:
    yaw -= dx
    pitch = clamp(pitch - dy, -0.85, 0.35)
    rotation.y = yaw
    camera_pivot.rotation.x = pitch

func _physics_process(delta: float) -> void:
    if not is_on_floor():
        velocity.y -= gravity * delta

    if (Input.is_action_just_pressed("jump") or mobile_jump_requested) and is_on_floor():
        velocity.y = jump_velocity
    mobile_jump_requested = false

    var keyboard_dir := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
    var input_dir := keyboard_dir if keyboard_dir.length() > 0.05 else mobile_move
    var direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
    var speed := sprint_speed if (Input.is_action_pressed("sprint") or mobile_sprint) else walk_speed

    if direction.length() > 0.01:
        velocity.x = direction.x * speed
        velocity.z = direction.z * speed
    else:
        velocity.x = move_toward(velocity.x, 0.0, speed * 7.0 * delta)
        velocity.z = move_toward(velocity.z, 0.0, speed * 7.0 * delta)

    move_and_slide()

func _setup_mobile_controls() -> void:
    var layer := CanvasLayer.new()
    layer.name = "MobileControlsLayer"
    add_child(layer)
    mobile_controls = Control.new()
    mobile_controls.set_script(load("res://scripts/mobile_controls.gd"))
    mobile_controls.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    layer.add_child(mobile_controls)
    mobile_controls.move_changed.connect(func(value: Vector2): mobile_move = value)
    mobile_controls.sprint_changed.connect(func(value: bool): mobile_sprint = value)
    mobile_controls.jump_pressed.connect(func(): mobile_jump_requested = true)
    mobile_controls.camera_dragged.connect(_rotate_camera)

func _build_character() -> void:
    var collision := CollisionShape3D.new()
    var capsule := CapsuleShape3D.new()
    capsule.radius = 0.36
    capsule.height = 1.75
    collision.shape = capsule
    collision.position.y = 0.88
    add_child(collision)

    var body_mesh := MeshInstance3D.new()
    var mesh := CapsuleMesh.new()
    mesh.radius = 0.36
    mesh.height = 1.75
    body_mesh.mesh = mesh
    body_mesh.position.y = 0.88
    var material := StandardMaterial3D.new()
    material.albedo_color = Color(0.12, 0.16, 0.2)
    material.roughness = 0.85
    body_mesh.material_override = material
    add_child(body_mesh)

func _build_camera() -> void:
    camera_pivot = Node3D.new()
    camera_pivot.position = Vector3(0, 1.5, 0)
    add_child(camera_pivot)

    var spring := SpringArm3D.new()
    spring.spring_length = 4.5
    spring.margin = 0.2
    camera_pivot.add_child(spring)

    var camera := Camera3D.new()
    camera.position = Vector3(0.55, 0.2, 0)
    camera.current = true
    camera.fov = 72.0
    spring.add_child(camera)
