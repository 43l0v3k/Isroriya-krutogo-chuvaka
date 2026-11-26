extends Control

signal move_changed(value: Vector2)
signal sprint_changed(value: bool)
signal jump_pressed
signal camera_dragged(dx: float, dy: float)

var joystick_finger := -1
var camera_finger := -1
var sprint_finger := -1
var joystick_origin := Vector2.ZERO
var joystick_value := Vector2.ZERO
var sprint_active := false
var jump_flash := 0.0

func _ready() -> void:
    mouse_filter = Control.MOUSE_FILTER_STOP
    set_process(true)

func _process(delta: float) -> void:
    jump_flash = maxf(0.0, jump_flash - delta)
    queue_redraw()

func _input(event: InputEvent) -> void:
    if event is InputEventScreenTouch:
        if event.pressed:
            _touch_down(event.index, event.position)
        else:
            _touch_up(event.index)
    elif event is InputEventScreenDrag:
        _touch_drag(event.index, event.position, event.relative)

func _touch_down(index: int, pos: Vector2) -> void:
    var s := get_viewport_rect().size
    if pos.x < s.x * 0.46 and pos.y > s.y * 0.38 and joystick_finger == -1:
        joystick_finger = index
        joystick_origin = pos
        _update_joystick(pos)
    elif pos.x > s.x * 0.55 and pos.y > s.y * 0.72:
        if pos.x > s.x * 0.78:
            jump_pressed.emit()
            jump_flash = 0.18
        else:
            sprint_finger = index
            sprint_active = true
            sprint_changed.emit(true)
    elif pos.x > s.x * 0.48 and camera_finger == -1:
        camera_finger = index

func _touch_up(index: int) -> void:
    if index == joystick_finger:
        joystick_finger = -1
        joystick_value = Vector2.ZERO
        move_changed.emit(Vector2.ZERO)
    if index == camera_finger:
        camera_finger = -1
    if index == sprint_finger:
        sprint_finger = -1
        sprint_active = false
        sprint_changed.emit(false)

func _touch_drag(index: int, pos: Vector2, relative: Vector2) -> void:
    if index == joystick_finger:
        _update_joystick(pos)
    elif index == camera_finger:
        camera_dragged.emit(relative.x * 0.004, relative.y * 0.004)

func _update_joystick(pos: Vector2) -> void:
    var delta := pos - joystick_origin
    var radius := 72.0
    joystick_value = Vector2(
        clampf(delta.x / radius, -1.0, 1.0),
        clampf(delta.y / radius, -1.0, 1.0)
    )
    if joystick_value.length() > 1.0:
        joystick_value = joystick_value.normalized()
    move_changed.emit(joystick_value)

func _draw() -> void:
    var s := get_viewport_rect().size
    var base := joystick_origin if joystick_finger != -1 else Vector2(s.x * 0.16, s.y * 0.80)
    draw_circle(base, 68.0, Color(0.08, 0.10, 0.12, 0.30))
    draw_arc(base, 68.0, 0, TAU, 48, Color(0.85, 0.9, 0.95, 0.55), 2.0)
    var knob := base + joystick_value * 48.0
    draw_circle(knob, 27.0, Color(0.82, 0.88, 0.94, 0.52))

    var sprint_pos := Vector2(s.x * 0.70, s.y * 0.83)
    draw_circle(sprint_pos, 39.0, Color(0.12, 0.16, 0.20, 0.48 if sprint_active else 0.30))
    draw_string(ThemeDB.fallback_font, sprint_pos + Vector2(-24, 5), "БЕГ", HORIZONTAL_ALIGNMENT_CENTER, 48, 16, Color.WHITE)

    var jump_pos := Vector2(s.x * 0.88, s.y * 0.82)
    draw_circle(jump_pos, 40.0, Color(0.18, 0.32, 0.48, 0.65 if jump_flash > 0 else 0.36))
    draw_string(ThemeDB.fallback_font, jump_pos + Vector2(-30, 5), "ПРЫЖОК", HORIZONTAL_ALIGNMENT_CENTER, 60, 12, Color.WHITE)
