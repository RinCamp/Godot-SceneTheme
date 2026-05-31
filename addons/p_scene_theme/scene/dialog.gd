@tool
extends Window

const CLASS_PREFIX = "SceneTheme"

@export var save_button: Button
@export var prefix: LineEdit
@export var remove_prefix_button: CheckButton

@export_group("Dialog")
@export var dialog_close_on_escape : bool = true

var file_dialog : EditorFileDialog

func _ready():
    close_requested.connect(_on_close_requested)
    save_button.pressed.connect(_on_save_button_pressed)


func _input(event: InputEvent):
    if not dialog_close_on_escape or not visible:
        return

    if event.is_action_pressed("ui_cancel"):
        get_viewport().set_input_as_handled()
        _on_close_requested()


func _on_close_requested():
    queue_free()
    if file_dialog:
        file_dialog.queue_free()


func _on_save_button_pressed():
    var selected_node = EditorInterface.get_selection().get_selected_nodes().front()

    if not selected_node or selected_node is not Control:
        print_rich("[color=LIGHT_BLUE][%s] [color=SALMON]- 当前活动节点不是 [ Control ] 类型" % [CLASS_PREFIX])
        return

    var scene_root = EditorInterface.get_edited_scene_root()
    var scene_dir : String = scene_root.scene_file_path.get_base_dir()

    file_dialog = EditorFileDialog.new()
    file_dialog.file_mode = EditorFileDialog.FILE_MODE_SAVE_FILE
    file_dialog.size = Vector2i(960,640)
    file_dialog.current_dir = scene_dir
    file_dialog.filters = ["*.tres"]
    file_dialog.current_file = selected_node.name.to_lower()
    file_dialog.display_mode = FileDialog.DISPLAY_LIST
    file_dialog.get_line_edit().caret_column = file_dialog.get_line_edit().text.length()

    file_dialog.file_selected.connect(_file_selected)
    file_dialog.canceled.connect(_on_close_requested)

    EditorInterface.popup_dialog_centered(file_dialog)


func _file_selected(_path):
    var selected_node = EditorInterface.get_selection().get_selected_nodes().front()

    var node_prefix : String = prefix.placeholder_text if prefix.text.length() == 0 else prefix.text
    var remove_prefix : bool = remove_prefix_button.button_pressed

    var _theme : Theme

    if ResourceLoader.exists(_path):
        var _resource = ResourceLoader.load(_path)
        if _resource is Theme:
            _theme = _resource
            _theme.clear()
            print_rich("[color=LIGHT_BLUE][%s] [color=LIGHT_GREEN]- 覆盖主题资源, 将移除所有类型后生成" % [CLASS_PREFIX])
        else:
            print_rich("[color=LIGHT_BLUE][%s] [color=SALMON]- 创建失败, 路径的资源类型不是 [ Theme ]" % [CLASS_PREFIX])
            print_rich("[color=LIGHT_BLUE][%s] [color=SALMON]- %s" % [CLASS_PREFIX, _path])
            return
    else:
        _theme = Theme.new()

    for node : Control in get_node_children_recursive(selected_node, Control):
        if node.owner != selected_node.owner:
            continue

        if node.name.begins_with(node_prefix) == false:
            continue

        var base_type = node.get_class()
        var theme_type = node.name

        if theme_type == base_type:
            if base_type != "Control":
                var debug_text = "[%s] - 不能使用内置类名作为主题变体 | %s" % [CLASS_PREFIX, node.name]
                print_rich("[color=LIGHT_CORAL]%s" % [debug_text])
            continue

        if remove_prefix:
            theme_type = theme_type.trim_prefix(node_prefix)

        node.theme_type_variation = theme_type
        _theme.add_type(theme_type)
        _theme.set_type_variation(theme_type, base_type)

        print_rich("[color=LIGHT_BLUE][%s] [color=GRAY]+ [ %s ] %s" % [CLASS_PREFIX, node.get_class(), theme_type])
        for prop in node.get_property_list():
            var prop_name : String = prop["name"]
            # 只处理主题覆盖
            if prop_name.begins_with("theme_override_") == false:
                continue
            if "/" not in prop_name:
                continue
            # 跳过未覆盖的主题
            if node.get(prop_name) == null:
                continue

            var category = prop_name.split("/")[0]
            var key = prop_name.split("/")[1]
            var value = node.get(prop_name)

            match category:
                "theme_override_colors":
                    _theme.set_color(key, theme_type, value)
                "theme_override_constants":
                    _theme.set_constant(key, theme_type, value)
                "theme_override_fonts":
                    _theme.set_font(key, theme_type, value)
                "theme_override_font_sizes":
                    _theme.set_font_size(key, theme_type, value)
                "theme_override_icons":
                    _theme.set_icon(key, theme_type, value)
                "theme_override_styles":
                    _theme.set_stylebox(key, theme_type, value)

    _theme.take_over_path(_path)
    ResourceSaver.save(_theme, _path)

    selected_node.theme = _theme

    print_rich("[color=LIGHT_BLUE][%s] [color=LIGHT_GREEN]- Export %s" % [CLASS_PREFIX, _path])

    _on_close_requested()


static func get_node_children_recursive(node: Node, type: Variant = null) -> Array:
    var child_list = []
    for child in node.get_children():
        child_list.append(child)
        if child.get_child_count():
            child_list.append_array(get_node_children_recursive(child))
    if type:
        var type_list = []
        for i in child_list:
            if is_instance_of(i, type):
                type_list.append(i)
        return type_list
    return child_list
