extends CharacterBody3D

@export var walk_speed := 4.5
@export var sprint_speed := 7.0
@export var jump_velocity := 4.5
@export var mouse_sensitivity := 0.0025
@export var touch_camera_sensitivity := 0.004

var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")
var camera_pivot: Node3D
var mobile_controls: Control
var game_hud
var yaw := 0.0
var pitch := -0.18
var mobile_move := Vector2.ZERO
var mobile_sprint := false
var mobile_jump_requested := false
var story_stage := 0
var stop_position := Vector3(39, 0, 12)
var neighbor_position := Vector3(14, 0, -13)

func _ready() -> void:
    _build_character()
    _build_camera()
    _setup_mobile_controls()
    _setup_game_hud()
    if OS.has_feature("pc"):
        Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _unhandled_input(event: InputEvent) -> void:
    if event is InputEventKey and event.pressed and not event.echo:
        if event.keycode == KEY_ESCAPE:
            Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
        elif event.keycode == KEY_E:
            _try_interact()
        elif event.keycode == KEY_F:
            game_hud.toggle_phone()
    if event is InputEventMouseButton and event.pressed:
        Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
    if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
        _rotate_camera(event.relative.x * mouse_sensitivity, event.relative.y * mouse_sensitivity)

func _process(_delta: float) -> void:
    if story_stage == 1 and global_position.distance_to(stop_position) < 5.0:
        story_stage = 2
        game_hud.set_objective("Вернись во двор и поговори с соседом")
        game_hud.set_subtitle("Парень на остановке: «А, ты от соседа? Он тебя уже заждался».")
    elif story_stage == 2 and global_position.distance_to(neighbor_position) < 5.0:
        story_stage = 3
        game_hud.set_objective("История первой главы завершена")
        game_hud.set_subtitle("Сосед: «Ну вот, теперь ты знаешь Южный получше. Дальше — больше!»")

func _rotate_camera(dx: float, dy: float) -> void:
    yaw -= dx
    pitch = clampf(pitch - dy, -0.85, 0.35)
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

func _setup_game_hud() -> void:
    game_hud = load("res://scripts/game_hud.gd").new()
    add_child(game_hud)
    game_hud.interact_requested.connect(_try_interact)
    game_hud.set_objective("Найди соседа во дворе")
    game_hud.set_subtitle("Южный. Обычный день, который неожиданно станет началом истории.")

func _try_interact() -> void:
    if story_stage == 0:
        for npc in get_tree().get_nodes_in_group("story_npc"):
            if npc.name == "Сосед" and global_position.distance_to(npc.global_position) < 5.0:
                story_stage = 1
                game_hud.set_objective("Дойди до остановки")
                game_hud.set_subtitle("Сосед: «Слушай, выручи — сходи к остановке, там тебя кое-кто ждёт».")
                return
        game_hud.set_subtitle("Подойди поближе к соседу во дворе, чтобы поговорить.")
    elif story_stage == 1:
        game_hud.set_subtitle("Сосед ждёт, пока ты дойдёшь до остановки.")
    elif story_stage == 2:
        game_hud.set_subtitle("Возвращайся во двор к соседу.")
    else:
        game_hud.set_subtitle("Первая глава закончена. Исследуй Южный и листай мемы в телефоне.")

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
    capsule.height = 1.8
    collision.shape = capsule
    collision.position.y = 0.9
    add_child(collision)

    var torso := MeshInstance3D.new()
    var torso_mesh := CapsuleMesh.new()
    torso_mesh.radius = 0.34
    torso_mesh.height = 1.12
    torso.mesh = torso_mesh
    torso.position.y = 1.12
    var shirt := StandardMaterial3D.new()
    shirt.albedo_color = Color(0.12, 0.16, 0.2)
    torso.material_override = shirt
    add_child(torso)

    var head := MeshInstance3D.new()
    var head_mesh := SphereMesh.new()
    head_mesh.radius = 0.23
    head.mesh = head_mesh
    head.position.y = 1.82
    var skin := StandardMaterial3D.new()
    skin.albedo_color = Color(0.72, 0.57, 0.43)
    head.material_override = skin
    add_child(head)

    var legs := MeshInstance3D.new()
    var legs_mesh := BoxMesh.new()
    legs_mesh.size = Vector3(0.48, 0.55, 0.3)
    legs.mesh = legs_mesh
    legs.position.y = 0.35
    var pants := StandardMaterial3D.new()
    pants.albedo_color = Color(0.10, 0.12, 0.15)
    legs.material_override = pants
    add_child(legs)

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
