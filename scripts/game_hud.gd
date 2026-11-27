extends CanvasLayer

signal interact_requested

var phone_panel: PanelContainer
var meme_label: Label
var objective_label: Label
var subtitle_label: Label
var meme_index := 0
var memes := [
    "Когда вышел на пять минут, а вернулся через три часа.\n\n«Я всё контролирую»",
    "План на день: сделать дела.\nРеальность: сначала полистаю телефон.",
    "Когда сказал «я уже выхожу», но ещё даже не оделся.",
    "Южный: вышел за хлебом — встретил половину района."
]

func _ready() -> void:
    var root := Control.new()
    root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    add_child(root)

    objective_label = Label.new()
    objective_label.position = Vector2(24, 22)
    objective_label.add_theme_font_size_override("font_size", 22)
    objective_label.add_theme_color_override("font_color", Color.WHITE)
    objective_label.text = "ЗАДАНИЕ: Найди соседа во дворе"
    root.add_child(objective_label)

    var phone_button := Button.new()
    phone_button.text = "ТЕЛЕФОН"
    phone_button.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
    phone_button.offset_left = -190
    phone_button.offset_top = 22
    phone_button.offset_right = -24
    phone_button.offset_bottom = 76
    phone_button.pressed.connect(_toggle_phone)
    root.add_child(phone_button)

    phone_panel = PanelContainer.new()
    phone_panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
    phone_panel.offset_left = -210
    phone_panel.offset_top = -190
    phone_panel.offset_right = 210
    phone_panel.offset_bottom = 190
    phone_panel.visible = false
    root.add_child(phone_panel)

    var phone_layout := VBoxContainer.new()
    phone_panel.add_child(phone_layout)
    var phone_title := Label.new()
    phone_title.text = "МОЙ ТЕЛЕФОН  •  ЛЕНТА"
    phone_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    phone_title.add_theme_font_size_override("font_size", 22)
    phone_layout.add_child(phone_title)

    meme_label = Label.new()
    meme_label.custom_minimum_size = Vector2(360, 190)
    meme_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    meme_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    meme_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    meme_label.add_theme_font_size_override("font_size", 21)
    meme_label.text = memes[0]
    phone_layout.add_child(meme_label)

    var next_button := Button.new()
    next_button.text = "СЛЕДУЮЩИЙ МЕМ"
    next_button.pressed.connect(_next_meme)
    phone_layout.add_child(next_button)

    var close_button := Button.new()
    close_button.text = "УБРАТЬ ТЕЛЕФОН"
    close_button.pressed.connect(_toggle_phone)
    phone_layout.add_child(close_button)

    var subtitle_panel := PanelContainer.new()
    subtitle_panel.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
    subtitle_panel.offset_left = 18
    subtitle_panel.offset_top = -112
    subtitle_panel.offset_right = -18
    subtitle_panel.offset_bottom = -18
    root.add_child(subtitle_panel)

    subtitle_label = Label.new()
    subtitle_label.text = "История крутого чувака — версия 1.0"
    subtitle_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    subtitle_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    subtitle_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    subtitle_label.add_theme_font_size_override("font_size", 20)
    subtitle_panel.add_child(subtitle_label)

    var interact_button := Button.new()
    interact_button.text = "ВЗАИМОДЕЙСТВОВАТЬ"
    interact_button.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT)
    interact_button.offset_left = -250
    interact_button.offset_top = -180
    interact_button.offset_right = -18
    interact_button.offset_bottom = -122
    interact_button.pressed.connect(func(): interact_requested.emit())
    root.add_child(interact_button)

func _toggle_phone() -> void:
    phone_panel.visible = not phone_panel.visible

func toggle_phone() -> void:
    _toggle_phone()

func _next_meme() -> void:
    meme_index = (meme_index + 1) % memes.size()
    meme_label.text = memes[meme_index]

func set_objective(value: String) -> void:
    objective_label.text = "ЗАДАНИЕ: " + value

func set_subtitle(value: String) -> void:
    subtitle_label.text = value
